package Kwiki::ForeignLinkGlyphs;
use strict;
use warnings;

use Kwiki::Plugin '-Base';
use mixin 'Kwiki::Installer';

our $VERSION = '0.02';

const class_id => 'foreignlinkglyphs';
const class_title => 'glyphs for foreign links';
const config_file => 'foreignlinkglyphs.yaml';

sub register {
    my $registry = shift;
    $registry->add(preload => 'foreignlinkglyphs');
}

field 'old_hyper';
field 'old_titlehyper';

sub init {
    super;
    my $formatter = $self->hub->load_class('formatter');
    $formatter->table->{hyper} = 'Kwiki::ForeignLinkGlyphs::Hyperlink';
    $formatter->table->{titlehyper} = 'Kwiki::ForeignLinkGlyphs::TitledHyperlink';
}

sub transform {
    my $link = shift;
    my $src = $self->config->foreignlinkglyph_image;
    my $target = $self->config->foreignlinkglyph_new_window =~
        /yes|1|true/i ? ' target="_new"' : '';
    $link =~ s{
      <a([^>]+)>  ([^<]+) </a>  $
      }{<a$1$target>$2</a><img src="$src" alt="" border="0" />}x;
    return $link;
}

package Kwiki::ForeignLinkGlyphs::Hyperlink;
use base 'Kwiki::Formatter::HyperLink';

sub html {
    $self->hub->foreignlinkglyphs->transform( $self->SUPER::html(@_) );
}      

package Kwiki::ForeignLinkGlyphs::TitledHyperlink;
use base 'Kwiki::Formatter::TitledHyperLink';

sub html {
    $self->hub->foreignlinkglyphs->transform( $self->SUPER::html(@_) );
}      

package Kwiki::ForeignLinkGlyphs;
1;
__DATA__

=head1 NAME 

Kwiki::ForeignLinkGlyphs - display an image after links that aren't local

=head1 SYNOPSIS

 $ cd /path/to/kwiki
 $ kwiki -add Kwiki::ForeignLinkGlyphs

=head1 DESCRIPTION

L<AxKit::XSP::Wiki> has a nifty feature where it places a tiny little arrow after non-wiki links. The arrow is useful for identifying links that would direct the user off the wiki.

=head2 Configuration Directives

=over 4

=item * foreignlinkglyph_image

This will be the contents of the C<src> attribute in the C<E<lt>imgE<gt>> tag placed after foreign links. The image F<foreignlinkglyph.png> included with this distribution is the default.

=item * foreignlinkglyph_new_window

Set this to "yes" if you would like foreign links to open in a new browser window.

=back

=head1 AUTHORS

Ian Langworth <ian@cpan.org>

=head1 SEE ALSO

L<Kwiki>, L<AxKit::XSP::Wiki> used by L<http://www.axkit.org/wiki/>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ian Langworth

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The file F<foreignlinkglyph.png>, included with this distribution, is copyright its respective author.

=cut

__config/foreignlinkglyphs.yaml__
foreignlinkglyph_image: plugin/foreignlinkglyphs/foreignlinkglyph.png
foreignlinkglyph_new_window: no

__plugin/foreignlinkglyphs/.htaccess__
Allow from all

__plugin/foreignlinkglyphs/foreignlinkglyph.png__
iVBORw0KGgoAAAANSUhEUgAAAAYAAAAGAQMAAAGtBU2dAAAABlBMVEX/AAD///9BHTQRAAAAB3RJ
TUUH0gsbCAwXQp9teAAAABV0RVh0U29mdHdhcmUAWFBhaW50IDIuNi4yxFiwnAAAABpJREFUeJxj
aGBgYDjAAAINYJjA8IChg2EOADOMBSV4TVvKAAAAAElFTkSuQmCC
