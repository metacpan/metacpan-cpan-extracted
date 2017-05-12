package Jifty::Plugin::Wikitext;
use strict;
use warnings;
use base 'Jifty::Plugin';

our $VERSION = '0.01';

1;

__END__

=head1 NAME

Jifty::Plugin::Wikitext - Wikitext field renderer

=head1 USAGE

Add the following to your site_config.yml

 framework:
   Plugins:
     - Wikitext: {}

Then for any form field that should be rendered as wikitext, use
C<render as 'wikitext'>, like so:

    column content =>
        render as 'wikitext';

=head1 SEE ALSO

L<Jifty::Plugin::Userpic>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 Best Practical Solutions

This is free software and may be modified and distributed under the same terms as Perl itself.

=cut

