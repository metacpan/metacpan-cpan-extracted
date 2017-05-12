package Kwiki::Formatter::Hatena;
use Spoon::Formatter -Base;
use mixin 'Kwiki::Installer';
use utf8;

use Kwiki::Formatter;

our $VERSION = '0.05';

const config_class => 'Kwiki::Config';
const class_id => 'formatter';
const class_title => 'Hatena Formatter';
const top_class => 'Kwiki::Formatter::Hatena::Top';
const class_prefix => 'Kwiki::Formatter::';

const all_blocks => [];
const all_phrases => [];

sub init {
    eval{ $self->hub->config->add_file('hatenaformatter.yaml'); };
}

sub formatter_classes {
    qw(
         Spoon::Formatter::WaflPhrase
         Spoon::Formatter::WaflBlock
         Line Heading Preformatted Comment
         Ulist Olist Item Table TableRow TableCell
         Strong Emphasize Underline Delete Inline MDash NDash Asis
         ForcedLink HyperLink TitledHyperLink TitledMailLink MailLink
         TitledWikiLink WikiLink
       );
}

package Kwiki::Formatter::Hatena::Top;
use base 'Spoon::Formatter::Container';
use Cache::File;
use Hatena::Formatter;
use URI::Escape qw(uri_escape_utf8);

const formatter_id => 'top';

sub html {
    my $html = $self->SUPER::html;
    $html = $self->html_unescape($html);

    my $keyword_enable = $self->hub->config->hatenaformatter_keyword_enable;
    my $cache;
    if ($keyword_enable && $self->hub->config->hatenaformatter_keyword_cache_root) {
        $cache = Cache::File->new(
            cache_root      => $self->hub->config->hatenaformatter_keyword_cache_root,
            default_expires => $self->hub->config->hatenaformatter_keyword_cache_expires,
        );
    }

    my %hatena_config = (
            text_config => {
            permalink => $self->hub->config->script_name . '?' . $self->hub->cgi->page_name,
            hatenaid_href => 'http://www.hatena.ne.jp/user?userid=%s',
        }
    );
    $hatena_config{keyword_config} = { cache => $cache, score => $self->hub->config->hatenaformatter_keyword_score }
        if $keyword_enable;

    my $formatter = Hatena::Formatter->new(%hatena_config);
    $formatter->register( hook => 'text_finalize', callback => sub {
        my($context, $option) = @_;
        my $html = $context->html;

        # add wikilink, copy from Kwiki::EscapeURI
        $html =~ s{\[([^\x01-\x2f\x3a-\x40\x5b-\x60\x7b-\x7f]+)\]}{
            my $target = $1;
            my $page_uri = $target;
            $page_uri =~ s/([^\x20-\x7e]+)/uri_escape_utf8($1)/eg;
            $target = $self->escape_html($target);
            qq(<a href="?$page_uri">$target</a>);
        }gsme;
        $context->html($html);
    });
    $formatter->process($html);

    $formatter->html;
}

package Kwiki::Formatter::Hatena;
1;

__DATA__

=head1 NAME 

Kwiki::Formatter::Hatena - Kwiki Formatter with Haten Style

=head1 SYNOPSIS

In C<config.yaml>:

    formatter_class: Kwiki::Formatter::Hatena
    hatenaformatter_keyword_cache_root: /tmp/hatenakeyword_cache_dir
    hatenaformatter_keyword_cache_expires: 1 day
    hatenaformatter_keyword_score: 20
    hatenaformatter_keyword_enable: 1

=head1 DESCRIPTION

The Kwiki format is invalidated and the Hatena format is made effective. 
The Hatena format is offered by L<Hatena::Formatter>. 

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

=head1 THANKS TO

TransFreeBSD, Naoya Ito, otsune, tokuhirom

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Hatena::Formatter>, L<Text::Hatena>, L<Hatena::Keyword>

=cut
__config/hatenaformatter.yaml__
hatenaformatter_keyword_cache_root: /tmp/hatenaformatter_cache_root
hatenaformatter_keyword_cache_expires: 1 day
hatenaformatter_keyword_score: 20
hatenaformatter_keyword_enable: 1

