package Evo::Di;
use Evo -Class, '-Class::Attrs ECA_REQUIRED';
use Evo 'Module::Load load; Module::Loaded is_loaded; Carp croak';

has di_stash => sub { {} };

our @CARP_NOT = ('Evo::Class::Attrs');

my sub _croak_cirk (@path) { croak "Circular dependencies detected: " . join(' -> ', @path); }
my sub _croak ($cur_key, $req_key) {
  croak qq#Can't load dependency "$cur_key" for class "$req_key"#;
}

# TODO: copypase, optimaze
sub mortal ($self, $class, %args) {
  load $class;
  my @stack = _di_list_pending($self, $class);
  my %in_stack;
  while (@stack) {
    my $cur = pop @stack;
    my @pending = _di_list_pending($self, $cur);
    if (!@pending) {
      $self->{di_stash}{$cur} = $cur->new(_di_args($self, $cur));
      next;
    }
    _croak_cirk(@stack, $cur) if $in_stack{$cur}++;
    push @stack, $cur, @pending;
  }
  $class->new(%args, _di_args($self, $class));
}

sub single ($self, $key) {
  return $self->{di_stash}{$key} if exists $self->{di_stash}{$key};
  $self->{di_stash}{$key} = $self->mortal($key);
}

sub provide ($self, %args) {
  foreach my $k (keys %args) {
    croak qq#Already has key "$k"# if exists $self->{di_stash}{$k};
    $self->{di_stash}{$k} = $args{$k};
  }
}

sub _di_list_pending ($self, $req_key) : Private {
  return unless $req_key->can('META');
  my @results;
  foreach my $slot ($req_key->META->attrs->slots) {
    next if !(my $k = $slot->{inject});

    next if exists $self->{di_stash}{$k};
    my $loaded = is_loaded($k) || eval { load($k); 1 };
    do { push @results, $k; next; } if $loaded;
    _croak($k, $req_key) if $slot->{type} == ECA_REQUIRED;
  }

  @results;
}

# only existing key/values to ->new, skip missing
sub _di_args ($self, $key) : Private {
  return unless $key->can('META');
  my @opts;

  foreach my $slot ($key->META->attrs->slots) {
    next unless my $k = $slot->{inject};
    push @opts, $slot->{name}, $self->{di_stash}{$k} if exists $self->{di_stash}{$k};
  }
  (@opts, $self->{di_stash}{"$key\@defaults"} ? $self->{di_stash}{"$key\@defaults"}->%* : ());
}


1;

# ABSTRACT: Dependency injection

__END__

=pod

=encoding UTF-8

=head1 NAME

Evo::Di - Dependency injection

=head1 VERSION

version 0.0403

=head1 DESCRIPTION

Injection is a value of C<inject> option in L<Evo::Class>. Use it this way

If you need to describe a dependency of some class, write this class

  has dep => inject 'My::Class';

This class will be build, resolved and injected

If you need to provide a global value, for example, processor cores, you can use UPPER_CASE constants. You need to provide a value for this dependency

  has cores => inject 'CORES';
  $di->provide(CORES => 8);

For convineince, there is a special C<@defaults> provider modificator. That helps to build values without C<inject> attributes

  has 'ip';
  $di->provide('My::C1@defaults' => {ip => '127.0.0.1'});

=head1 SYNOPSYS

  use Evo -Di;

  {

    package My::C1;
    use Evo -Class, -Loaded;
    has c2 => inject 'My::C2';
    has 'required';    # can be provided by My::C1@defaults

    package My::C2;
    use Evo -Class, -Loaded;
    has c3 => inject 'My::C3';

    package My::C3;
    use Evo -Class, -Loaded;
    has foo => inject 'FOO';

    package My::Mortal;
    use Evo -Class, -Loaded;
    has c1 => inject 'My::C1';
    has 'counter';

  }

  my $di = Evo::Di->new();

  # provide some value in stash wich will be available as dependency 'FOO'
  $di->provide(FOO => 'FOO value');

  # provide config using dot notation
  $di->provide('My::C1@defaults' => {required => 'OK'});

  my $c1 = $di->single('My::C1');
  say $c1 == $di->single('My::C1');
  say $c1 == $di->single('My::C1');
  say $c1->c2->c3 == $di->single('My::C3');
  say $c1->c2->c3->foo;    # FOO value

  say $c1->required;       # OK

  my $temp1 = $di->mortal('My::Mortal', counter => 1);
  my $temp2 = $di->mortal('My::Mortal', counter => 2);
  say $temp1->c1 eq $temp2->c1;    # true
  say $temp1 eq $temp2;            # false

=head1 TRIAL

This module is in early alpha stage. The implementation will be changed. The syntax probably will remain the same. Right now it can only build singletones.

=head1 ATTRIBUTES

=head2 di_stash

A hash reference containing our dependencies (single instances)

=head1 METHODS

=head2 provide($self, $key, $v)

You can put in stash any value as a dependency

  $di->provide('SOME_CONSTANT' => 33);
  say $di->single('SOME_CONSTANT'), 33;

  $di->provide('My::C1@defaults' => {ip => '127.0.0.1', port => '3000'});

=head2 single($self, $key)

If there is already a dependency with this key, return it.
If not, build it, resolving a dependencies tree. Has a protection from circular
dependencies (die if A->B->C->A)

=head2 mortal($self, $class)

Build an instance of class resolving required dependencies

=head1 AUTHOR

alexbyk.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by alexbyk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
