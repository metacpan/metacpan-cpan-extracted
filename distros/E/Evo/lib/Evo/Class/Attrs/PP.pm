package Evo::Class::Attrs::PP;
use Evo '-Export; Carp croak confess';
use constant {ECA_OPTIONAL => 0, ECA_DEFAULT => 1, ECA_DEFAULT_CODE => 2, ECA_REQUIRED => 3,
  ECA_LAZY => 4,};

export qw(
  ECA_OPTIONAL ECA_DEFAULT ECA_DEFAULT_CODE ECA_REQUIRED ECA_LAZY
);

my sub _croak_bad_value ($val, $name, $msg) {
  $msg //= '';
  croak qq{Bad value "$val" for attribute "$name": $msg};
}

sub new { bless [], shift }

sub exists ($self, $name) {
  do { return 1 if $_->{name} eq $name }
    for @$self;
  return;
}

sub slots ($self) {
  @$self;
}

my sub _find_index ($self, $name) {
  my $index = 0;
  do { last if $_->{name} eq $name; $index++ }
    for @$self;
  $index;
}

sub _reg_attr ($self, %opts) {
  $self->[_find_index($self, $opts{name})] = my $attr = \%opts;
}

sub _gen_attr ($self, %opts) {
  my ($name, $check, $ro) = @opts{qw(name check ro)};
  my $lazy = $opts{type} == ECA_LAZY ? $opts{value} : undef;

  # simplest and popular
  if (!$ro && !$lazy && !$check) {
    return sub {
      return $_[0]{$name} if @_ == 1;
      $_[0]{$name} = $_[1];
      $_[0];
    };
  }

  # more complex. we can optimize it by splitting to 6 other. but better use XS
  return sub {
    if (@_ == 1) {
      return $_[0]{$name} if exists $_[0]{$name};
      return unless $lazy;
      return $_[0]{$name} = $lazy->($_[0]);
    }
    croak qq{Attribute "$name" is readonly} if $ro;
    if ($check) {
      my ($ok, $msg) = $check->(my $val = $_[1]);
      _croak_bad_value($val, $name, $msg) if !$ok;
    }
    $_[0]{$name} = $_[1];
    $_[0];
  };
}

sub gen_attr ($self, %opts) {
  $self->_reg_attr(%opts);
  $self->_gen_attr(%opts);
}


sub gen_new($self) {

  sub ($class, %opts) {
    no strict 'refs';    ## no critic
    $class = ref $class || $class;
    my $attrs = ${"${class}::EVO_CLASS_ATTRS"} || croak "Not an Evo class, no ATTRS";
    my $obj = {};

    # iterate known attrs
    foreach my $slot (@$attrs) {
      my ($name, $type, $value, $check) = @$slot{qw(name type value check)};

      if (exists $opts{$name}) {
        if ($check) {
          my ($ok, $err) = $check->(my $val = $opts{$name});
          _croak_bad_value($opts{$name}, $name, $err) if !$ok;
        }
        $obj->{$name} = delete $opts{$name};
        next;
      }

      # required and default are mutually exclusive
      if ($type == ECA_REQUIRED) {
        croak qq#Attribute "$name" is required#;
      }
      elsif ($type == ECA_DEFAULT) {
        $obj->{$name} = $value;
      }
      elsif ($type == ECA_DEFAULT_CODE) {
        $obj->{$name} = $value->($class);
      }
    }

    croak "Unknown attributes: " . join(',', keys %opts) if (keys %opts);

    bless $obj, $class;
  };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Evo::Class::Attrs::PP

=head1 VERSION

version 0.0403

=head1 AUTHOR

alexbyk.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by alexbyk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
