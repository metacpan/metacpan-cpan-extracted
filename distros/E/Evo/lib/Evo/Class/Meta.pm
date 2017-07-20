package Evo::Class::Meta;
use Evo 'Carp croak; Scalar::Util reftype; -Internal::Util; Module::Load ()';
use Evo '/::Attrs *; /::Syntax *';

our @CARP_NOT = qw(Evo::Class);

sub register ($me, $package) {
  no strict 'refs';    ## no critic
  no warnings 'once';

  ${"${package}::EVO_CLASS_ATTRS"} ||= Evo::Class::Attrs->new;

  ${"${package}::EVO_CLASS_META"}
    ||= bless {package => $package, private => {}, methods => {}, reqs => {}, overridden => {}},
    $me;
}

sub find_or_croak ($self, $package) {
  no strict 'refs';    ## no critic
  ${"${package}::EVO_CLASS_META"}
    or croak qq#$package isn't Evo::Class; "use parent '$package';" for external classes#;
}

sub package($self) { $self->{package} }

sub attrs($self) {
  no strict 'refs';    ## no critic
  my $package = $self->{package};
  ${"${package}::EVO_CLASS_ATTRS"};
}

sub methods($self) { $self->{methods} }
sub reqs($self)    { $self->{reqs} }

sub overridden($self) { $self->{overridden} }
sub private($self)    { $self->{private} }

sub mark_as_overridden ($self, $name) {
  $self->overridden->{$name} = 1;
  $self;
}

sub is_overridden ($self, $name) {
  $self->overridden->{$name};
}

sub mark_as_private ($self, $name) {
  $self->private->{$name} = 1;
}

sub is_private ($self, $name) {
  $self->private->{$name};
}

# first check methods (marked as method or inherited), if doesn't exists, try to determine if there is a sub in package
# if a sub is compiled in the same package, it's a public, if not(imported or xsub), and not exported function - it's private

sub is_method ($self, $name) {
  return 1 if $self->methods->{$name};
  my $pkg = $self->package;

  {
    no strict 'refs';    ## no critic
    no warnings 'once';
    my $meta = ${"${pkg}::EVO_EXPORT_META"};
    return if $meta && $meta->symbols->{$name};
  }

  my $code = Evo::Internal::Util::names2code($pkg, $name) or return;
  my ($realpkg, $realname, $xsub) = Evo::Internal::Util::code2names($code);
  return !$xsub && $realpkg eq $pkg;
}

sub is_attr ($self, $name) {
  $self->attrs->exists($name);
}

sub _check_valid_name ($self, $name) {
  croak(qq{"$name" is invalid name}) unless Evo::Internal::Util::check_subname($name);
}

sub _check_exists ($self, $name) {
  my $pkg = $self->package;
  croak qq{$pkg already has attribute "$name"} if $self->is_attr($name);
  croak qq{$pkg already has method "$name"}    if $self->is_method($name);
}

sub _check_exists_valid_name ($self, $name) {
  _check_valid_name($self, $name);
  _check_exists($self, $name);
}

sub _reg_parsed_attr ($self, %opts) {
  my $name = $opts{name};
  _check_exists_valid_name($self, $name);
  my $pkg = $self->package;
  croak qq{$pkg already has subroutine "$name"} if Evo::Internal::Util::names2code($pkg, $name);

  my $sub = $self->attrs->gen_attr(%opts);    # register
  Evo::Internal::Util::monkey_patch $pkg, $name, $sub if $opts{method};
}

sub _reg_parsed_attr_over ($self, %opts) {
  my $name = $opts{name};
  _check_valid_name($self, $name);
  $self->mark_as_overridden($name);
  my $sub = $self->attrs->gen_attr(%opts);    # register
  my $pkg = $self->package;
  Evo::Internal::Util::monkey_patch_silent $pkg, $name, $sub if $opts{method};
}

sub reg_attr ($self, $name, @attr) {
  my %opts = $self->parse_attr($name, @attr);
  $self->_reg_parsed_attr(%opts);
}

sub reg_attr_over ($self, $name, @attr) {
  my %opts = $self->parse_attr($name, @attr);
  $self->_reg_parsed_attr_over(%opts);
}

# means register external sub as method. Because every sub in the current package
# is public by default
sub reg_method ($self, $name) {
  _check_exists_valid_name($self, $name);
  my $pkg = $self->package;
  my $code = Evo::Internal::Util::names2code($pkg, $name) or croak "$pkg::$name doesn't exist";
  $self->methods->{$name}++;
}

sub _public_attrs_slots($self) {
  grep { !$self->is_private($_->{name}) } $self->attrs->slots;
}

# not marked as private
# was compiled in the same package, not constant, not exported lib
sub _public_methods_map($self) {
  my $pkg = $self->package;
  map { ($_, Evo::Internal::Util::names2code($pkg, $_)) }
    grep { !$self->is_private($_) && $self->is_method($_) }
    Evo::Internal::Util::list_symbols($pkg);
}

sub public_attrs($self) {
  map { $_->{name} } $self->_public_attrs_slots;
}

sub public_methods($self) {
  my %map = $self->_public_methods_map;
  keys %map;
}


sub extend_with ($self, $source_p) {
  $source_p = Evo::Internal::Util::resolve_package($self->package, $source_p);
  Module::Load::load($source_p);
  my $source  = $self->find_or_croak($source_p);
  my $dest_p  = $self->package;
  my %reqs    = $source->reqs()->%*;
  my %methods = $source->_public_methods_map();

  my @new_attrs;
  foreach my $name (keys %reqs) { $self->reg_requirement($name); }

  foreach my $slot ($source->_public_attrs_slots) {
    next if $self->is_overridden($slot->{name});
    $self->_reg_parsed_attr(%$slot);
    push @new_attrs, $slot->{name};
  }

  foreach my $name (keys %methods) {
    next if $self->is_overridden($name);
    croak qq/$dest_p already has a subroutine with name "$name"/
      if Evo::Internal::Util::names2code($dest_p, $name);
    _check_exists($self, $name);    # prevent patching before check
    Evo::Internal::Util::monkey_patch $dest_p, $name, $methods{$name};
    $self->reg_method($name);
  }

  no strict 'refs';                 ## no critic
  push @{"${dest_p}::ISA"}, $source_p;
  @new_attrs;
}


sub reg_requirement ($self, $name) {
  $self->reqs->{$name}++;
}

sub requirements($self) {
  (keys($self->reqs->%*), $self->public_attrs, $self->public_methods);
}

sub check_implementation ($self, $inter_class) {
  $inter_class = Evo::Internal::Util::resolve_package($self->package, $inter_class);
  Module::Load::load($inter_class);
  my $class = $self->package;
  my $inter = $self->find_or_croak($inter_class);
  my @reqs  = sort $inter->requirements;

  my @not_exists = grep { !($self->is_attr($_) || $class->can($_)); } @reqs;
  return $self if !@not_exists;

  croak qq/Bad implementation of "$inter_class", missing in "$class": /, join ';', @not_exists;
}

# -- class methods for usage from other modules too


# rtype: default, default_code, required, lazy, relaxed
# rvalue is used as meta for required(di), default and lazy
# check?
# is_ro?

sub parse_attr ($me, $name, @attr) {
  my @scalars = grep { $_ ne SYNTAX_STATE } @attr;
  croak "expected 1 scalar, got: " . join ',', @scalars if @scalars > 1;
  my %state = syntax_reset;

  croak qq#"optional" flag makes no sense with default("$scalars[0]")#
    if $state{optional} && @scalars;
  croak qq#"lazy" requires code reference#
    if $state{lazy} && (reftype($scalars[0]) // '') ne 'CODE';
  croak qq#default("$scalars[0]") should be either a scalar or a code reference#
    if @scalars && ref($scalars[0]) && reftype($scalars[0]) ne 'CODE';


  my $type;
  if    ($state{optional}) { $type = ECA_OPTIONAL if $state{optional}; }
  elsif ($state{lazy})     { $type = ECA_LAZY     if $state{lazy}; }
  elsif (@scalars) { $type = ref($scalars[0]) ? ECA_DEFAULT_CODE : ECA_DEFAULT; }
  else             { $type = ECA_REQUIRED; }

  return (
    name   => $name,
    type   => $type,
    value  => $scalars[0],
    check  => $state{check},
    ro     => !!$state{ro},
    inject => $state{inject},
    method => !$state{no_method},
  );
}

sub info($self) {
  my %info = (
    public => {
      methods => [sort $self->public_methods],
      attrs   => [sort $self->public_attrs],
      reqs    => [sort keys($self->reqs->%*)],
    },
    overridden => [sort keys($self->overridden->%*)],
    private    => [sort keys($self->private->%*)],
  );
  \%info;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Evo::Class::Meta

=head1 VERSION

version 0.0405

=head1 SYNOPSYS

  use Evo;
  {

    package Foo::Bar;
    use Evo::Class;
  }

  say Foo::Bar->META;
  say Foo::Bar->META->attrs;
  say $Foo::Bar::EVO_CLASS_META;
  say $Foo::Bar::EVO_CLASS_META->attrs;
  say $Foo::Bar::EVO_CLASS_META->{attrs};

  Foo::Bar->META->reg_attr('foo');
  use Data::Dumper;
  say Dumper (Foo::Bar->META->attrs->slots);

=head1 METHODS

=head2 register

Register a meta instance only once. The second invocation will return the same instance.
But if it will be called from another subclass, die. This is a protection from the fool

Meta is stored in C<$Some::Class::EVO_CLASS_META> global variable and lives as long as a package.

=head2 attrs

Returns an inctance of attributes generator L<Evo::Class::Attrs>

=head1 IMPLEMENTATION NOTES

=head2 overridden

"overridden" means this symbol will be skept during L</extend_with> so if you marked something as overridden, you should define method or sub yourself too.  This is not a problem with C<sub foo : Over {}> or L</reg_attr_over> because it marks symbol as overridden and also registers a symbol.

BUT!!!
L</reg_attr_over> should be called

=head2 private

Mark something as private (even if it doesn't exist) to skip at from L</public_*>. But better use C<my sub foo {}> feature

=head2 reg_method

All methods compiled in the class are public by default. But what to do if you make a method by monkey-patching or by extending? Use C</reg_method>

  package Foo;
  use Evo 'Scalar::Util(); -Class::Meta';
  my $meta = Evo::Class::Meta->register(__PACKAGE__);

  no warnings 'once';
  *lln = \&Scalar::Util::looks_like_number;

  # nothing, because lln was compiled in Scalar::Util
  say $meta->public_methods;

  # fix this
  $meta->reg_method('lln');
  say $meta->public_methods;

=head2 check_implementation

If implementation requires "attribute", L</reg_attr> should be called before checking implementation

=head2 mark_as_private

If you want to hide method, you should use C<my sub> feature. But sometimes this also will help. It doesn't hide you method from being executed, it hides it from inheritance

  package Foo;
  use Evo -Class;
  sub foo { }

  local $, = ' ';
  say 'LIST: ', META->public_methods;

  META->mark_as_private('foo');    # hide foo
  say 'LIST: ', META->public_methods;

But C<foo> is still available via C<Foo::-E<gt>foo>

=head1 DUMPING (EXPERIMENTAL)

  package My::Foo;
  use Evo -Class;
  has 'foo';

  use Data::Dumper;
  say Dumper __PACKAGE__->META->info;

=head1 AUTHOR

alexbyk.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by alexbyk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
