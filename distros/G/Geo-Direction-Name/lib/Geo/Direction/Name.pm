package Geo::Direction::Name;

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
    my ( $class, $opt ) = @_;

    my $self = bless {}, $class;

    my $spec;
    my $locale;
    if ( $opt && ref($opt) ) {
        $spec   = $opt->{spec};
        $locale = $opt->{locale};
    } else {
        # For backward compatibility
        $locale = $opt;
    }

    $self->spec(   $spec );
    $self->locale( $locale );

    $self;
}

sub spec   {
    my $self   =   shift;
    my $spec   =   shift;
    my $noerr  =   shift;
    my $errstr =   "Specification class(subclass of Geo::Direction::Name::Spec) must be set";
    $spec      ||= 'default' unless ( $self->{spec} );
    
    if ( $spec ) {
        $errstr = "Geo::Direction::Name not support this specification now: " . $spec;
        delete $self->{spec};
        my $class = __PACKAGE__ . '::Spec' . ( $spec eq 'default' ? '' : '::' . ucfirst($spec) ) ;
        if( Class::Inspector->loaded($class) || $class->require ) {
            $self->{spec} = $class->new;
        }
    }

    croak $errstr unless ( $noerr || $self->{spec} );
    $self->{spec};
}

sub locale {
    my $self   = shift;

    $self->spec->locale( @_ );
}
 
sub to_string   {
    my $self      = shift;

    $self->spec->to_string( @_ );
}

sub from_string {
    my $self      = shift;

    $self->spec->from_string( @_ );
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Geo::Direction::Name - Transform direction name and degree each other.


=head1 SYNOPSIS

  use Geo::Direction::Name;
  
  my $dobj = Geo::Direction::Name->new();
  
  # Get dierction name from degree
  print $dobj->to_string(11.250);  # N
  print $dobj->to_string(236.250); # SW
  
  # You can get long name by setting abbreviation option to 0 (1 is default)
  print $dobj->to_string(11.250,{abbreviation => 0});  # North
  print $dobj->to_string(236.250,{abbreviation => 0}); # Southwest
  
  # You can get more precision name by setting devide option (4, 8, 16 or 32. 8 is default)
  print $dobj->to_string(11.250,{devide => 4});   # N
  print $dobj->to_string(236.250,{devide => 4});  # W
  print $dobj->to_string(11.250,{devide => 16});  # NNE
  print $dobj->to_string(236.250,{devide => 16}); # WSW
  print $dobj->to_string(11.250,{devide => 32});  # NbE
  print $dobj->to_string(236.250,{devide => 32}); # SWbW
  
  # Create direction degree from name
  print $dobj->from_string('North'); # 0
  print $dobj->from_string('SWbW'}); # 236.25
  
  # Use other locale (default: en_US)
  my $dja = Geo::Direction::Name->new("ja_JP");
  my $dko = Geo::Direction::Name->new("ko_KR");
  
  print $dja->to_string(11.250,{devide => 4});   # 北
  print $dja->to_string(236.250,{devide => 32}); # 南西微西
  print $dko->to_string(11.250,{devide => 4});   # 북
  print $dko->to_string(236.250,{devide => 32}); # 남서미서
  
  print $dja->from_string('北');        # 0
  print $dja->from_string('南西微西'}); # 236.25
  print $dko->from_string('북');        # 0
  print $dko->from_string('남서미서'}); # 236.25


=head1 DESCRIPTION

Geo::Direction::Name transforms direction name and direction in degree
each other.
It can also manage many locales, but now supports only en_US, ja_JP and
ko_KR.


=head1 CONSTRUCTER

=over 4

=item * new( [LOCALE] )

Old interface (Backward compatible).
Return the Geo::Direction::Name object.
LOCALE is optional, default is "en_US".

=item * new( [OPTION] )

New interface.
OPTION is hash reference, could be set two values.
Default specification is used.

=over 8

=item * spec

Set original spec name if want.
If not set, use default specification.

=item * locale

Set locale.

=back

=back


=head1 METHODS

=over 4

=item * to_string( DEGREE, [ OPTION ] )

Transform direction DEGREE to direction name in specified locale.
OPTION is optional hash reference, could be set two values.

=over 8

=item * abbreviation

If set this value to 0, you can get long name of direction (like 'North', 'Northeast by east' ...).
Default is 1.

=item * devide

Set how many parts to devide 360 degrees.
You can set only 4, 8, 16 or 32.
Default is 8.

After version 0.0.4, you can set other deviding number by using non-default specification.


=back

=item * from_string( STRING )

Transform direction name (STRING) to direction degree by specified locale.

=back


=head1 INTERNAL METHODS

=over 4

=item * spec

=item * locale

=item * load

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
