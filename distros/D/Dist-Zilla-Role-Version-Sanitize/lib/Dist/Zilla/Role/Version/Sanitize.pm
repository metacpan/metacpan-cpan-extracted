use 5.006;    # our
use strict;
use warnings;

package Dist::Zilla::Role::Version::Sanitize;

our $VERSION = '0.002003';

# ABSTRACT: Sanitize a version from a plugin

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose::Role qw(has around);
use Moose::Util::TypeConstraints qw(enum);












sub _normalize_normal {
  my ( undef, $orig ) = @_;
  require version;
  return version->parse($orig)->normal;
}

sub _normalize_normal_3 {
  my ( undef, $orig ) = @_;
  require version;
  my $v = version->parse($orig)->normal;
  $v =~ s/\Av//msx;
  if ( $v !~ /\A\d+[.]\d+[.]\d+/msx ) {
    require Carp;
    return Carp::croak("Normalised string $v does not have a minimum of 3 parts");
  }
  return $v;
}

sub _normalize_numify {
  my ( $self, $orig ) = @_;
  require version;
  my $version = version->parse($orig)->numify;
  if ( $version =~ /(\A\d+)[.](.*$)/msx ) {
    my ( $sig, $mantissa ) = ( $1, $2 );
    my $got  = length $mantissa;
    my $want = $self->mantissa;
    if ( $got == $want ) {
      return $version;
    }
    $self->log( [ 'MANTISSA LENGTH != EXPECTED: WANTED %s, GOT %s, CORRECTING', $want, $got ] );
    if ( $want < $got ) {
      my $newman = substr $mantissa, 0, $want;
      return $sig . q[.] . $newman;
    }
    my $need = $want - $got;
    return $sig . q[.] . $mantissa . ( q[0] x $need );
  }
  require Carp;
  return Carp::croak(qq[Could not parse mantissa from numified version $version]);
}








































my %normal_forms = (
  normal   => '_normalize_normal',
  normal_3 => '_normalize_normal_3',
  numify   => '_normalize_numify',
);









has normal_form => (
  is => ro =>,
  isa => enum( [ keys %normal_forms ] ),
  is => 'ro',
  lazy    => 1,
  default => sub { return 'numify' },
);


















has mantissa => (
  is      => ro =>,
  isa     => 'Int',
  is      => 'ro',
  lazy    => 1,
  default => sub {
    ## no critic (ProhibitMagicNumbers
    return 6;
  },
);

around provide_version => sub {
  my ( $orig, $self, @args ) = @_;
  my $v      = $orig->( $self, @args );
  my $method = $normal_forms{ $self->normal_form };
  my $fixed  = $self->$method($v);
  if ( "$fixed" ne "$v" ) {
    $self->log("Version normalised from $v to $fixed");
  }
  return $fixed;
};

around dump_config => sub {
  my ( $orig, $self, @args ) = @_;
  my $config = $orig->( $self, @args );
  my $localconf = $config->{ +__PACKAGE__ } = {};

  $localconf->{normal_form} = $self->normal_form;
  $localconf->{mantissa}    = $self->mantissa;

  $localconf->{ q[$] . __PACKAGE__ . '::VERSION' } = $VERSION;
  return $config;
};

no Moose::Role;
no Moose::Util::TypeConstraints;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::Version::Sanitize - Sanitize a version from a plugin

=head1 VERSION

version 0.002003

=head1 ATTRIBUTES

=head2 C<normal_form>

Determines which L<< I<normal form>|/NORMAL FORMS >> is used.

Default is : B<< C<numify> >>

=head2 C<mantissa>

Determines the mandatory length of the C<mantissa> for the L<< C<numify>|/numify >> normal form.

Default is : B<< C<6> >>

Which yields:

      1.001001
     10.001001
    100.001001
   1000.001001

Etc.

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Dist::Zilla::Role::Version::Sanitize",
    "interface":"role"
}


=end MetaPOD::JSON

=head1 NORMAL FORMS

=head2 C<normal>

Normalizes to the notation:

    v1
    v1.2
    v1.2.3
    v1.2.3.4

=head2 C<normal_3>

Normalizes to the notation

    1.2.3
    1.2.3.4

Note: Due to the absence of the leading C<v>, 3, is the minimum number of places that can be represented in this notation.

Accidentally normalizing to

    1.2

In this form should raise a fatal exception.

=head2 C<numify>

Normalizes to the notation

    1.23456789
    | ^------^--- The Mantissa
    |
    ^------------ Integer part.

And the length for mantissa is forced by C<mantissa>, either I<truncating> to C<mantissa> length, or C<paddding> to C<mantissa> length with C<0>'s

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
