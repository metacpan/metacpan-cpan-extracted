package DhMakePerl::PodParser;

use strict;
use warnings;

our $VERSION = '0.51';

use base qw(Pod::Parser);

=head1 NAME

DhMakePerl::PodParser - internal helper module for DhMakePerl

=head1 SYNOPSIS

DhMakePerl::PodParser is used by DhMakePerl to extract some
information from the module-to-be-packaged. It sub-classes from
L<Pod::Parser> - Please refer to it for further documentation.

=head1 METHODS

=over

=item set_names

Defines the names of the sections that should be fetched from the POD

=cut

sub set_names {
    my ( $parser, @names ) = @_;
    foreach my $n (@names) {
        $parser->{_deb_}->{$n} = undef;
    }
}

=item get

Gets the contents for the specified POD section. The single argument should be
one of the values given to L</set_names>.

=cut

sub get {
    my ( $parser, $name ) = @_;
    $parser->{_deb_}->{$name};
}

=item cleanup

Empties the information held by the parser object

=cut

sub cleanup {
    my $parser = shift;
    delete $parser->{_current_};
    foreach my $k ( keys %{ $parser->{_deb_} } ) {
        $parser->{_deb_}->{$k} = undef;
    }
}

=item command

Overrides base class' L<Pod::Parser> L<command|Pod::Parser/command> method.

Gets each of the POD's commands
(sections), and defines how it should react to each of them. In this
particular implementation, it basically filters out anything except
for the C<=head> sections defined in L</set_names>.

=cut

sub command {
    my ( $parser, $command, $paragraph, $line_num ) = @_;
    $paragraph =~ s/\s+$//s;
    if ( $command =~ /head/ && exists( $parser->{_deb_}->{$paragraph} ) ) {
        $parser->{_current_} = $paragraph;
        $parser->{_lineno_}  = $line_num;
    }
    else {
        delete $parser->{_current_};
    }

    #print "GOT: $command -> $paragraph\n";
}

=item add_text

Hands back the text it received as it occurred in the input stream (see the
L<Pod::Parser>'s documentation for L<verbatim|Pod::Parser/verbatim>,
L<textblock|Pod::Parser/textblock> and
L<interior_sequence|Pod::Parser/interior_sequence>).

Content is ignored if more than 15 lines away from the section start.

=cut

sub add_text {
    my ( $parser, $paragraph, $line_num ) = @_;
    return unless exists $parser->{_current_};
    return if ( $line_num - $parser->{_lineno_} > 15 );
    $paragraph =~ s/^\s+//s;
    $paragraph =~ s/\s+$//s;
    $paragraph = $parser->interpolate( $paragraph, $line_num );
    $parser->{_deb_}->{ $parser->{_current_} } .= "\n\n" . $paragraph;

    #print "GOT: $paragraph'\n";
}

=item verbatim

Called by L<Pod::Parser> for verbatim paragraphs. Redirected to L</add_text>.

=cut

sub verbatim { shift->add_text(@_) }

=item textblock

Called by L<Pod::Parser> for ordinary text paragraphs. Redirected to
L</add_text>.

=cut

sub textblock { shift->add_text(@_) }

=item interior_sequence

L<interior_sequence()|Pod::Parser/interior_sequence()> is called by
L<Pod::Parser> when, eh, an interior sequence occurs in the text. Interior
sequences are things like IE<lt>...E<gt>.

This implementation decodes C<gt>, C<lt>, C<sol>, C<verbar> and numeric
character codes, all used by C<E> escape.

=cut

sub interior_sequence {
    my ( $parser, $seq_command, $seq_argument ) = @_;
    if ( $seq_command eq 'E' ) {
        my %map = ( 'gt' => '>', 'lt' => '<', 'sol' => '/', 'verbar' => '|' );
        return $map{$seq_argument} if exists $map{$seq_argument};
        return chr($seq_argument) if ( $seq_argument =~ /^\d+$/ );

        # html names...
    }
    return $seq_argument;
}

1;

=back

=head1 SEE ALSO

L<Pod::Parser>

=head1 AUTHOR

=over 4

=item Paolo Molaro

=item Documentation added by Gunnar Wolf and Damyan Ivanov

=back

=head1 COPYRIGHT & LICENSE

=over 4

=item Copyright (C) 2001, Paolo Molaro <lupus@debian.org>

=item Copyright (C) 2008, Gunnar Wolf <gwolf@debian.org>

=item Copyright (C) 2008, Damyan Ivanov <dmn@debian.org>

=back

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 51 Franklin
Street, Fifth Floor, Boston, MA 02110-1301 USA.

=cut
