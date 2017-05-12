package Don::Mendo::Linea;

use warnings;
use strict;
use Carp;

our $VERSION = "0.0.3";

# Other recommended modules (uncomment to use):
#  use IO::Prompt;
#  use Perl6::Export;
#  use Perl6::Slurp;
#  use Perl6::Say;


# Module implementation here
sub new {
    my $class = shift;
    my $character = shift || croak "No person";
    my $line = shift || croak "Nothing to say";
    
    my $self = { _personaje => $character,
		 _line => $line };

    bless $self, $class;    
    return $self;
	
}

sub say {
    my $self = shift;
    return $self->{'_line'};
}

sub character {
    my $self = shift;
    return $self->{'_personaje'};
}

sub follows {
    my $self = shift;
    $self->{'_follows'} = shift;
}

sub followed_by {
  my $self = shift;
  if ( $self->{'_follows'} ) {
      return $self->{'_follows'}->character();
  } else {
      return;
  }
}

1; # Magic true value required at end of module


=head1 NAME

Don::Mendo::Linea - A single bit of a dialogue in a play

=head1 VERSION

This document describes Don::Mendo::Linea version 0.0.3.


=head1 SYNOPSIS

    use Don::Mendo;
    use Don::Mendo::Linea;

    my $don_mendo = new Don::Mendo;
    my $primera_jornada = $don_mendo->jornadas()->[0];
    my $lines = $primera_jornada->lines_for_character();
    my $first_line = $lines->[0];
    print $first_line->character(), " ", $first_line->say(), 

  
=head1 DESCRIPTION

A single bit in a play: who says the bit, and its (possibly formatted) content.


=head1 INTERFACE 

=head2 new( $character, $content)

Creates the line; needs who said it and what

=head2 say()

Returns the dialog fragment

=head2 character()

Returns the actor

=head2 follows( $next_line )

Sets the line that follows this one.

=head2 followed_by()

Returns the name of the character that will issue the next line

=head1 CONFIGURATION AND ENVIRONMENT

None known. A bit of mastery and playfulness, I guess.


=head1 DEPENDENCIES

Caffeine and beer.


=head1 INCOMPATIBILITIES

Incompatible with serious people.


=head1 BUGS AND LIMITATIONS

Limited to a single play... might be more general, but then it
wouldn't be "The revenge of Don Mendo", but the revenge of somebody else.

Please report any bugs or feature requests to
C<bug-don-mendo@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

JJ Merelo  C<< <jj@merelo.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, JJ Merelo C<< <jj@merelo.net> >>. All rights reserved.

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

=cut 
