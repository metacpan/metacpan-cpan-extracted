package Kwiki::Infobox;

=head1 NAME

Kwiki::Infobox - Slash-like Infobox plugin for Kwiki

=head1 DESCRIPTION

Kwiki::Infobox is a L<Kwiki> plugin that provide slash-like infoboxes
around your page countent. User can use either wafl-block or wafl-phrase
syntax to freely add infoboxes. Like:

    {infobox: CommonInfoBox}

This wafl-phrase would use the content of the page CommonInfoBox ,
render it, and place into infobox. If you want to instantly add
some text into infobox only for this page, use wafl-block like this:

    .infoblock
    Some quick content here.
    .infoblock

For site admins, beside installing this plugin, please add

    [% hub.infobox.html %]

somewhere in your kwiki_screen.html. And of course you'll have to
setup css so that your new page looks neat. These issues will
probabally be worked out someday in the future, so far I have no good
idea about how to do this magically. Please discuss with me.

=cut

use Kwiki::Plugin -Base;
our $VERSION = '0.03';

const class_id => 'infobox';
const class_title => 'Kwiki Infobox';

sub register {
    my $registry = shift;
    $registry->add(wafl => infoblock => 'Kwiki::Infobox::WaflBlock');
    $registry->add(wafl => infoblock_right => 'Kwiki::Infobox::WaflBlockRight');
    $registry->add(wafl => infobox => 'Kwiki::Infobox::WaflPhrase');
    $registry->add(wafl => infobox_right => 'Kwiki::Infobox::WaflPhraseRight');
}

sub html {
    my $content = $self->pages->current->content;
    my $html;
    while($content =~ /{infobox:\s*(.+)\s*}/g) {
	my $boxpage = $self->pages->new_page($1)->content;
	$html .= "<div class=\"infobox\">".
	    $self->hub->formatter->text_to_html($boxpage)
		. "</div>";
    }

    while($content =~ /\n.infoblock\n(.+\n).infoblock/sg) {
	$html .= "<div class=\"infoblock\">" .
	    $self->hub->formatter->text_to_html($1)
		. "</div>";
    }
    return $html;
}

sub left { $self->html(@_) };

sub right {
    my $content = $self->pages->current->content;
    my $html;
    my ($box) = $content =~ /{infobox_right:\s*(.+)\s*}/;
    if($box) {
	my $boxpage = $self->pages->new_page($box)->content;
	$html .= "<div class=\"infobox\">".
	    $self->hub->formatter->text_to_html($boxpage)
		. "</div>";
    }

    my ($block) = $content =~ /\n.infoblock_right\n(.+\n).infoblock/s;
    if($block) {
	$html .= "<div class=\"infoblock\">" .
	    $self->hub->formatter->text_to_html($block)
	    . "</div>";
    }
    return $html;
}

package Kwiki::Infobox::WaflPhrase;
use base 'Spoon::Formatter::WaflPhrase';
sub to_html {'';}

package Kwiki::Infobox::WaflPhraseRight;
use base 'Spoon::Formatter::WaflPhrase';
sub to_html {'';}

package Kwiki::Infobox::WaflBlock;
use base 'Spoon::Formatter::WaflBlock';
sub to_html {'';}

package Kwiki::Infobox::WaflBlockRight;
use base 'Spoon::Formatter::WaflBlock';
sub to_html {'';}

=head1 COPYRIGHT

Copyright 2004 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut
