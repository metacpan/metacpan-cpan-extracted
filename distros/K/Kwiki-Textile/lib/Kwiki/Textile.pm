package Kwiki::Textile;
use v5.6.1;
use Text::Textile 'textile';
our $VERSION = '0.01';

use constant
    class_id     => 'formatter',
    class_title  => 'Kwiki Textile Formatter';

sub new { bless {} }
sub init {}

sub text_to_html {
    my $self = shift;
    return textile(shift);
}

__END__

=head1 NAME

Kwiki::Textile - A Textile formatter for Kwiki.

=head1 SYNOPSIS

This module provides a markdown formatter class for Kwiki.
For more information about markdown syntax, please see
its official website: L<http://www.textism.com/tools/textile/>

To install this module, please edit C<config.yaml> and add this line
to the bottom:

    formatter_class: Kwiki::Textile

Please be aware of that this plugin is not compatible with lots of plugins
that provide extra wafl block or wafl phrases, as long as those plugins
hooking on Kwiki::Formatter::* sub-classes.

=head1 SEE ALSO

L<Text::Textile>

=head1 COPYRIGHT

Copyright 2006 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut

