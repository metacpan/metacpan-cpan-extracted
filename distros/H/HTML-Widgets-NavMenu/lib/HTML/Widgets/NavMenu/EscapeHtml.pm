package HTML::Widgets::NavMenu::EscapeHtml;

use strict;
use warnings;

use base qw(Exporter);

use vars qw(@EXPORT);

=head1 NAME

HTML::Widgets::NavMenu::EscapeHtml - provides a function to escape HTML.

=head1 SYNOPSIS

    use HTML::Widgets::NavMenu::EscapeHtml;

    my $escaped_html = escape_html($html);

=head2 escape_html()

Escapes the HTML.

=cut

@EXPORT=(qw(escape_html));

sub escape_html
{
    my $string = shift;
    $string =~ s{&}{&amp;}gso;
    $string =~ s{<}{&lt;}gso;
    $string =~ s{>}{&gt;}gso;
    $string =~ s{"}{&quot;}gso;
    return $string;
}

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=cut

1;

