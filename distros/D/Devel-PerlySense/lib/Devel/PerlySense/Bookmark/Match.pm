=head1 NAME

Devel::PerlySense::Bookmark::Match - A Bookmark match

=head1 DESCRIPTION

A match has a Location (file + line), and a corresponding Definition
that caused it to match.

=cut





use strict;
use warnings;
use utf8;

package Devel::PerlySense::Bookmark::Match;
$Devel::PerlySense::Bookmark::Match::VERSION = '0.0220';




use Spiffy -Base;
use Carp;
use Data::Dumper;

use Devel::PerlySense;
use Devel::PerlySense::Document::Location;





=head1 PROPERTIES

=head2 oLocation

The Document::Location where this match matched.

=cut
field "oLocation" => undef;





=head2 oDefinition

Bookmark::Definition that was used to match this.

=cut
field "oDefinition" => undef;





=head2 line

The source line where the match matched.

Default: ""

=cut
field "line" => "";





=head2 text

The textual match that was captured (or the entire line).

Default: ""

=cut
field "text" => "";





=head1 METHODS

=head2 new(file, row, line, text, oDefinition)

Create new PerlySense::Bookmark::Match object.

=cut
sub new {
    my ($file, $row, $line, $text, $oDefinition) = Devel::PerlySense::Util::aNamedArg(["file", "row", "line", "text", "oDefinition"], @_);

    $self = bless {}, $self;    #Create the object. It looks weird because of Spiffy
    $self->oLocation(Devel::PerlySense::Document::Location->new(
        file => $file,
        row => $row,
        col => 0,  #When a col is needed, add it here
    ));
    $self->oDefinition($oDefinition);
    $self->line($line);
    $self->text($text);

    return($self);
}





1;





__END__

=encoding utf8

=head1 AUTHOR

Johan Lindstrom, C<< <johanl@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-devel-perlysense@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-PerlySense>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Johan Lindstrom, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
