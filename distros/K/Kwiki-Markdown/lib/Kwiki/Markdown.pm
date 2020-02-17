package Kwiki::Markdown;
use v5.6.1;
use Text::Markdown 'markdown';
our $VERSION = '0.02';

use constant
    class_id     => 'formatter',
    class_title  => 'Kwiki Markdown Formatter';

sub new { bless {} }
sub init {}

sub text_to_html {
    my $self = shift;
    return markdown(shift);
}

__END__

=head1 NAME

Kwiki::Markdown - A Markdown formatter for Kwiki.

=head1 SYNOPSIS

This module provides a markdown formatter class for Kwiki.
For more information about markdown syntax, please see
its official website: L<http://daringfireball.net/projects/markdown/>.

To install this module, please edit C<config.yaml> and add this line
to the bottom:

    formatter_class: Kwiki::Markdown

Please be aware of that this plugin is not compatible with lots of plugins
that provide extra wafl block or wafl phrases, as long as those plugins
hooking on Kwiki::Formatter::* sub-classes.

=head1 SEE ALSO

L<Text::Markdown>

=head1 AUTHOR

Kang-min Liu <gugod@gugod.org>.

=head1 LICENCE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut

