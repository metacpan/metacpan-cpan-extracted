package Kwiki::PrinterFriendly;
use Kwiki::Plugin -Base;
use Kwiki::Installer '-base';
use strict;
use warnings;

our $VERSION = '0.13';

const class_id => 'printer_friendly';
const class_title => 'Printer Friendly';
const screen_template => 'printer_friendly_screen.html';
const cgi_class => 'Kwiki::PrinterFriendly::CGI';

sub register {
    my $registry = shift;
    $registry->add(action => 'printer_friendly');
    $registry->add(toolbar => 'printer_friendly_button', 
                   template => 'printer_friendly_button.html',
		   show_for => ['display', 'revisions']
                  );
}

sub printer_friendly {
  my $page = $self->pages->current;
  my $content = $self->cgi->revision_id
    ? $self->hub->archive->fetch($page, $self->cgi->revision_id)
      : $page->content;
  my $html = $self->hub->formatter->text_to_html($content);
  $self->render_screen(
		       page_html => $html,
		       screen_title => $page->title,
		       site_title => $page->title,
		       page_content => $content,
		       page_time => $page->modified_time,
		      );
}

package Kwiki::PrinterFriendly::CGI;
use base 'Kwiki::CGI';
cgi 'revision_id';
package Kwiki::PrinterFriendly;

=head1 NAME 

Kwiki::PrinterFriendly - A Kwiki plugin to format pages for printing

=head1 SYNOPSIS

Provides an printer friendly display of the current page.

=head1 REQUIRES

   Kwiki 

=head1 INSTALLATION

   perl Makefile.PL
   make
   make test
   make install

   cd ~/where/your/kwiki/is/located
   echo "Kwiki::PrinterFriendly" >>plugins

   kwiki -update

=head1 UPGRADING

You should always run 'kwiki -update' after upgrading Kwiki::PrinterFriendly

=head1 CONFIGURATION

In config.yaml, following are necessary for proper functioning:

=over

=item toolbar_order

Add the item printer_friendly_button in the position where you
want the printer icon to appear

=item printer_icon

Included in this distribution is a sample icon, printer.png.  To use it, put

   printer_icon: printer.png

in your config.yaml file.  If you have a better one, just put it in
the top of your Kwiki directory.

=back

=head1 ACKNOWLEDGEMENTS

This is a hacked together version of Kwiki::Edit,
Kwiki::RecentChangesRSS, and various bits and pieces from other
modules.  Thanks to James Peregrino and Brian Ingerson for doing
the heavy lifting.

=head1 AUTHOR

Henry Laxen <nadine.and.henry@pobox.com>

=head1 COPYRIGHT

Copyright (c) 2004. Henry Laxen. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

__DATA__
__template/tt2/printer_friendly_button.html__
[% rev_id = hub.have_plugin('revisions') ? hub.revisions.revision_id : 0 %]
<a href="[% script_name %]?action=printer_friendly;page_name=[% page_uri %][% IF rev_id %];revision_id=[% rev_id %][% END %]" accesskey="N" title="Printer Friendly">
[% INCLUDE printer_friendly_button_icon.html %]
</a>
__template/tt2/printer_friendly_button_icon.html__
<!-- BEGIN printer_button_icon.html -->
<img src="icons/gnome/image/printer.png" alt="Printer Friendly" />
<!-- END printer_button_icon.html -->
__template/tt2/printer_friendly_screen.html__
[%- INCLUDE kwiki_doctype.html %]
[% INCLUDE kwiki_begin.html %]
<!-- BEGIN printer_friendly_screen -->
<div id="printer_friendly">
[% page_html -%]
</div>
<!-- END printer_friendly_screen -->
[% INCLUDE kwiki_end.html -%]
__icons/gnome/image/printer.png__
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QA/wD/
AP+gvaeTAAAACXBIWXMAAAsRAAALEQF/ZF+RAAAAB3RJTUUH1QUCEzMZYq6w
HgAAAeVJREFUOMutk79vUlEUxz/vPeRHUis/RsYWmdnYSMSauLTGDROaMmic
2P0X2JgNOhExDpoQJx4k4mCplb/AjTDYvAANUOC9xz0uBYrSyOBJTu7NPfd+
zyfnnAv/2TKAbOGZ2wTkX2ZZ1kIEAM8mlWKxSDqdBqBWq+H3+0kkEgAEg8G1
u9oGAizLQim1FtB1HYDBYEAsFlu+3UhQKpXwer0AZLPZn4VCYT+VSgEQj8e3
I7jN/iTQb8QSi025XF4eVqtV6vU6pmlimiaj0QiA3Mlx5iZBAmibtRr9QZ+9
vX16vd5f2QOBAJXKO2Kx++TzeXInx8+W6M1mUxzHERER27aXq+M44jiO2LYt
0+lURqOhNBp1efvmtQCyLGIymcR1XS4uflGpvCeXy9HpdAiFQkynEzyGgRKF
69iMR0Mi4TDRaHTVhR/n59zb3cHn83N0dMig32f37g6OPUNEmKs5ohSaptNu
t4lEwnS73ZWA3+fjtHXG1y91hsMxH2oNnqZTfPz0mSeHj5krha7r6LrBg/TB
chgXRZTvZy3G4yGz2Qx7ZqMQ1FyhAa6aY9sOdzwGhmGgaTqWZfH8xcsVQev0
G5ZlEQgEQIPJZHI9GFxn07i8HCAiuK7L1dVkrUOJLX/hmj86ePjqN/ROJdv5
GWdSAAAAAElFTkSuQmCC
