package Geo::Direction::Name::Spec;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.4');
use Scalar::Util qw(looks_like_number);
use Class::Inspector;
use UNIVERSAL::require;

BEGIN
{
    if ( $] >= 5.006 )
    {
        require utf8; import utf8;
    }
}

sub new {
    bless { }, $_[0];
}

sub devide_num { 32 }

sub allowed_dev { qw(4 8 16 32) }

sub default_dev { 8 }

sub default_locale { "en_US" }

sub locale {
    my $self       =   shift;
    my $class_base =   ref( $self );
    my $locale     =   shift;
    my $noerr      =   shift;
    my $errstr     =   "Locale class(subclass of Geo::Direction::Name::Locale) must be set";
    $locale        ||= $self->default_locale unless ( $self->{locale} );

    if ( $locale ) {
        $errstr = "$class_base not support this locale now: " . $locale;
        delete $self->{locale};

        ($locale)  = split(/\./,$locale);
        my ($lang) = split(/_/,$locale);

        $class_base =~ s/Spec/Locale/;

        foreach my $class (map { "$class_base\::" . $_ } ($locale, $lang)) {
            if( Class::Inspector->loaded($class) || $class->require) {
                $self->{locale} = $class->new( $self->devide_num );
                last;
            }
        }
    }
    
    croak $errstr unless ( $noerr || $self->{locale} );
    $self->{locale};
}

sub to_string   {
    my $self      = shift;
    my $direction = shift;
    my $option    = shift || {};

    my $abbr      = defined($option->{abbreviation}) ? $option->{abbreviation} : 1;
    my $devide    = $option->{devide} || $self->default_dev;

    croak ("Direction value must be a number") unless (looks_like_number($direction));
    croak ("Abbreviation parameter must be 0 or 1") if ( $abbr !~ /^[01]$/ );
    croak ("Devide parameter must be ". join( ",", $self->allowed_dev ) ) unless ( grep { $devide == $_ } $self->allowed_dev );

    $direction   += 180 / $devide;

    while ($direction < 0.0 || $direction >= 360.0) {
        $direction +=  $direction < 0 ? 360.0 : -360.0;
    }

    my $i = int($direction * $devide / 360) * ( $self->devide_num / $devide);

    $self->locale->string($i,$abbr);
}

sub from_string {
    my $self      = shift;
    my $string    = shift;
    my $option    = shift || {};

    $self->locale->direction($string);
}

1;
__END__

=head1 NAME

Geo::Direction::Name::Spec - Base class of original specification of Geo::Direction::Name.


=head1 SYNOPSIS

  package Geo::Direction::Name::Spec::Foo;
  
  use base qw(Geo::Direction::Name::Spec);
  
  ### Define original Geo::Direction::Name specification 'Foo' here.
  
  sub devide_num { 2 }
  
  sub allowed_dev { qw(2) }
  
  sub default_dev { 2 }
  
  sub default_locale { "en_US" }
  
  1;
  
  
  package Geo::Direction::Name::Locale::Foo::en_US;
  
  use base qw(Geo::Direction::Name::Locale);
  
  ### And, you must auso specify at least one locale definition of 'Foo' specification.
  
  sub dir_string {
  [
    'bar',
    'baz',
  ]
  }
  
  1;
  
  # After those
  
  use Geo::Direction::Name;
  
  my $dobj = Geo::Direction::Name->new({spec=>'foo',locale=>'en_US');
  
  print $dobj->to_string(0);                  # bar
  print $dobj->to_string(180);                # baz
  print $dobj->to_string(180,{devide => 32}); # error
  
  print $dobj->from_string('bar');  # 0.000
  print $dobj->from_string('baz');  # 180.000
  print $dobj->from_string('hoge'); # undef

=head1 DESCRIPTION

Geo::Direction::Name's default specification is, direction devide by only
4, 8, 16, 32.
But if you make original subclass of this module, you can make original 
specification of direction (like devided by 12, 24..).


=head1 CONSTRUCTER

=over 4

=item * new( )

=back


=head1 METHODS TO OVERRIDE

=over 4

=item * devide_num

Returns largest deviding number of specification.
Must be overrided by subclass.

=item * allowed_dev

Returns allowed deviding number set by array.
Must be overrided by subclass.

=item * default_dev

Returns default deviding number of specification.
Must be overrided by subclass.

=item * default_locale

Returns default locale of specification.
Must be overrided by subclass.

=back


=head1 INTERNAL METHODS

Internal called by Geo::Direction::Name

=over 4

=item * to_string

=item * from_string

=item * locale

=back


=head1 DEPENDENCIES

Scalar::Util
Class::Inspector
UNIVERSAL::require


=head1 AUTHOR

OHTSUKA Ko-hei  C<< <nene@kokogiko.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, OHTSUKA Ko-hei C<< <nene@kokogiko.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
