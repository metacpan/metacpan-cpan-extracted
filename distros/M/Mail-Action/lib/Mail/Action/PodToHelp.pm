package Mail::Action::PodToHelp;

use strict;
use base 'Pod::Simple::Text';

use vars '$VERSION';
$VERSION = '0.46';

sub show_headings
{
    my $parser = shift;
    $parser->{_show_headings} = { map { $_ => 1 } @_ };
}

sub start_head1
{
    my $parser = shift;
    $parser->{_in_head1} = 1;
    $parser->SUPER::start_head1( @_ );
}

sub start_item_bullet
{
    my $parser = shift;
    return unless $parser->{_show};
    $parser->SUPER::start_item_bullet( @_ );
}

sub end_item_bullet
{
    my $parser = shift;
    return unless $parser->{_show};
    $parser->SUPER::end_item_bullet( @_ );
}

sub handle_text
{
    my ($parser, $text) = @_;

    if ( $parser->{_in_head1} )
    {
        $parser->{_show} = exists $parser->{_show_headings}{$text} ? 1 : 0;
    }

    return unless $parser->{_show};
    $parser->SUPER::handle_text( $text );
}

sub end_head1
{
    my $parser = shift;
    $parser->{_in_head1} = 0;
    $parser->SUPER::end_head1( @_ );
}

1;
__END__

=head1 NAME

Mail::SimpleList::PodToHelp - module to produce help messages from the MSL docs

=head1 DESCRIPTION

This is a subclass of C<Pod::Simple>.  It overrrides the following methods:

=over 4

=item C<start_head1()>

Marks that the parser has encountered a first-level heading.

=item C<end_head1()>

Marks that the parser is outside of a first-level heading.

=item C<start_item_bullet()>

Ignores any bullets unless the parser should show them.

=item C<end_item_bullet()>

Ignores any bullets unless the parser should show them.

=item C<handle_text()>

Tells the parser to handle the text if it is in a section with the appropriate
heading.  Otherwise, handles nothing.

That is -- if the parser has encountered the text of a first level heading for which it should show the text, sets a flag.  Otherwise, unsets the flag.

=item C<show_headings()>

Tells the parser to show all POD under the headings provided.

=back

=head1 SEE ALSO

L<Pod::Simple>, L<Pod::Simple::Text>

=head1 COPYRIGHT

Copyright (c) 2003 - 2009 chromatic.  Some rights reserved.  You may use,
modify, and distribute this module under the same terms as Perl 5.10 itself.
