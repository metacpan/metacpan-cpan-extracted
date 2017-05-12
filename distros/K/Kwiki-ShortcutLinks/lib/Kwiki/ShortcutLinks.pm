package Kwiki::ShortcutLinks;
use strict;
use warnings;
use Kwiki::Plugin '-Base';
use Kwiki::Installer '-base';

#use Kwiki::ShortcutLinks::Config;

our $VERSION = 0.03;

const class_title => 'Shortcut Links';
const class_id    => 'shortcut_links';

field shortcuts => undef;

sub register {
    my $registry = shift;

    my %config = Kwiki::ShortcutLinks::Config->new->all;
    
    foreach my $key (keys %config) {
	$registry->add(wafl => $key => 'Kwiki::ShortcutLinks::Wafl');
	$registry->add(shortcut_links => $key => $config{$key});
    }
}

package Kwiki::ShortcutLinks::Wafl;
use Spoon::Formatter ();
use base 'Spoon::Formatter::WaflPhrase';

sub html {
    my $text = $self->arguments;
    my $key  = $self->method;
    my $shortcut = $self->hub->registry->lookup->{shortcut_links}{$key}[1];

    my ($url_prefix, $link_prefix) = ($shortcut =~ /^(\S+)\s*(.*)?$/);
    my ($url_param,  $link_text)   = ($text =~ /\A(.+?)(?:\|(.*))?\Z/);

    $link_text ||= ($link_prefix ? "$link_prefix " : '')
                 . $self->html_escape($url_param);

    my $url = $url_prefix;
    $url_param = $self->uri_escape($url_param);
    $url .= "%s" unless ($url =~ /%s/);
    $url =~ s/%s/$url_param/g;

    qq{<a href="$url">$link_text</a>};
}

package Kwiki::ShortcutLinks::Config;
use Spoon::Config '-Base';

const class_title => 'Shortcut Links Configuration';
const class_id => 'shortcut_links_config';
const config_file => 'shortcuts.yaml';

sub default_configs { $self->config_file }
sub default_config  { return { }; }

package Kwiki::ShortcutLinks;

1;

__DATA__

=head1 NAME 

Kwiki::ShortcutLinks - WAFL-phrase shortcuts for arbitrary web links

=head1 SYNOPSIS

 $ cpan Kwiki::ShortcutLinks
 $ cd /path/to/kwiki
 $ echo "Kwiki::ShortcutLinks" >> plugins
 $ kwiki -update
 $ vi shortcuts.yaml
 $ kwiki -update

=head1 DESCRIPTION

This plugin allows the Kwiki maintainer to define a series of short-cut 
wafl phrases via a simple config file.

When the plugin is installed and added to Kwiki via C<kwiki -update>,
a default C<shortcuts.yaml> file is created.  This can be edited and
added to as necessary.  C<kwiki -update> must be run again after
adding, renaming or deleting shortcuts.

The example entry:

  google:   http://www.google.com/search?q=

adds support for the wafl phrase C<{google:...}>, for example:

  Search Google for: {google:Kwiki}

will render as:

  Search Google for: <a href="http://www.google.com/search?q=Kwiki">Kwiki</a>

If the short-cut definition contains extra words, these will be
prepended to the rendered link.  For example:

  rt:       http://ticket-serv/Ticket/Display.html?id= RT Ticket

will render C<{rt:1234}> as:

  <a href="http://ticket-serv/Ticket/Display.html?id=1234">RT Ticket 1234</a>

If you follow the shortcut argument by a pipe and some more text, that text
will be used for the link text, instead of the argument and any leader.  So,
for the above definition of C<rt>, C<{rt:1234|A Hateful Problem}> would render
as:

  <a href="http://ticket-serv/Ticket/Display.html?id=1234">A Hateful Problem</a>

The shortcut can contain the string C<%s>, which will be replaced by
the wafl phrase arguments.  (If there is no C<%s>, the arguments are
appended to the shortcut expansion, as in the examples above.)  So the
config entry:

  wikipedia: http://www.wikipedia.org/w/wiki.phtml?search=%s&go=Go

and the shortcut C<{wikipedia:Cambridge}> will render as

  <a href="http://www.wikipedia.org/w/wiki.phtml?search=Cambridge&go=Go">Cambridge</a>

=head1 AUTHORS

Michael Gray <mjg17@eng.cam.ac.uk>

Thanks to Alexander Goller for the C<%s> suggestion,
C<extra_shortcuts.yaml> and his general support.
Thanks to Ricardo Signes for the pipe patch to allow link text 
to be overridden.

=head1 SEE ALSO

L<Kwiki>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Michael Gray

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__!shortcuts.yaml__
google: http://www.google.com/search?q=
googleuk: http://www.google.co.uk/search?q=
__!extra_shortcuts.yaml__
# Cut-n-paste into shortcuts.yaml as needed
# Thanks to Alexander Goller for these
acron: http://www.chemie.de/tools/acronym.php3?language=e&acronym=%s
altavista: http://www.altavista.com/cgi-bin/query?pg=q&kl=XX&stype=stext&q=%s
cpan: http://search.cpan.org/search?mode=all&query=%s
ctan: http://www.ctan.org/tools/filesearch?action=/search/&filename=%s
dmoz: http://search.dmoz.org/cgi-bin/search?search=%s
docbook: http://www.docbook.org/tdg/en/html/%s.html
foldoc: http://foldoc.doc.ic.ac.uk/foldoc/foldoc.cgi?query=%s
freshmeat: http://freshmeat.net/search/?q=%s
google: http://www.google.com/search?q=%s&ie=UTF-8&oe=UTF-8
googlegroups: http://groups.google.com/groups?oi=djq&as_q=%s
googleimages: http://images.google.com/images?q=%s
googlefl: http://www.google.com/search?q=%s&btnI=I%27m+Feeling+Lucky&ie=UTF-8&oe=UTF-8
googlenews: http://news.google.com/news?q=%s&ie=UTF-8&oe=UTF-8
imdb: http://imdb.com/Find?%s
dict: http://dict.leo.org/?search=%s
sourceforge: http://sourceforge.net/search/?type_of_search=soft&exact=0&words=%s
wikipedia: http://www.wikipedia.org/w/wiki.phtml?search=%s&go=Go
