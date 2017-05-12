package Don::Mendo::Jornada;

use warnings;
use strict;
use Carp;

our $VERSION = "0.0.4";

# Other recommended modules (uncomment to use):
#  use IO::Prompt;
#  use Perl6::Export;
#  use Perl6::Slurp;
#  use Perl6::Say;

use Don::Mendo::Linea;

# Module implementation here
sub new {
    my $class = shift;
    my $text = shift || croak "No text here!";
    my @parts = split(/\n\n/, $text );
    my $this_part = shift @parts;
    my $intro;
    while ( $this_part !~ / {5}[A-ZÑÍÁ y,]+\.–/ && @parts ) {
	$intro .= $this_part;
	$this_part = shift @parts;
    }
    unshift( @parts, $this_part);
    my $lines = join( "\n\n", @parts );
    my $self = { _text => $text,
		 _intro => $intro,
		 _linestext => $lines };

    my @bits = ( $lines =~ / {5}([A-ZÑÍÁ y,]+)\.– (.+?)\n\n\n/gs );

    my $last_line;
    while (@bits ) {
	my $actor = shift @bits;
	my $this_line = shift @bits;
	if ( $this_line =~ /\.– / ){ #Missed split lines
	    my ($new_linea, $new_actor, $otra_linea) = 
		($this_line =~ /(.+?) {5}([A-ZÑÍÁ y,]+)\.– (.+)/gs);
	    unshift @bits, ($new_actor, $otra_linea);
	    $this_line = $new_linea;
	}
	my $line = new Don::Mendo::Linea( $actor, $this_line );
	push @{$self->{'_lines'}}, $line;
	if ( $last_line ) {
	    $last_line->follows( $line );
	} else {
	    $self->{'_first_line'} = $line;
	}
	$last_line = $line;
    }
    bless $self, $class;    
	
}

sub start {
  my $self =shift;
  return $self->{'_first_line'};
}

sub text {
    my $self = shift;
    return $self->{'text'};
}

sub lines_for_character {
    my $self = shift;
    my $character = uc( shift );
    return $self->{'_lines'} if !$character;
    my @these_lines;
    for my $l (@{$self->{'_lines'}}) {
	push(@these_lines, $l) if ($l->character() eq $character);
    }
    return \@these_lines;
}

sub tell {
    my $self = shift;
    my $line = $self->{'_first_line'};
    my $text;
    do {
	$text .= "\t".$line->character()." - ".$line->say()."\n\n";
    }while ($line = $line->{'_follows'});
    return $text;
}

sub actors{
    my $self = shift;
    my %actors;
    for my $l ( @{$self->{'_lines'}} ) {
	if ( !$actors{$l->character()} ) {
	    $actors{$l->character()} = $l;
	}
    }
    return \%actors;
}

1; # Magic true value required at end of module


=head1 NAME

Don::Mendo::Jornada - Each one of the acts of the Don Mendo play

=head1 VERSION

This document describes Don::Mendo::Jornada version 0.0.3.


=head1 SYNOPSIS

    use Don::Mendo::Jornada;

  
=head1 DESCRIPTION

A "jornada" is the equivalent of an act, a part of the play taking
    place in a single setup. Don Mendo has 4 acts, first one in
    Magdalena's tower, second one in Don Mendo's prison, third one in
    the king's camp, and the last in the cave.

=head1 INTERFACE 

=head2 new( $text ) 

Creates a new one, and sets up lines and bits and pieces inside

    my $jornada = new Don::Mendo::Jornada( $text );

=head2 start()

Returns the first character line (C<Don::Mendo::Line>)

=head2 text()

Returns the raw text of the jornada

=head2 lines_for_character( [ $actor ] )

Returns the lines for a particular actor, or all of them if void

=head2 tell()

Follows narrative returning the whole text

=head2 actors()

Returns a hash with the names of the actors and their first line


=head1 CONFIGURATION AND ENVIRONMENT
  
Don::Mendo requires no configuration files or environment variables.


=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

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
