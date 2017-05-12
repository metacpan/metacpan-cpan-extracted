package Kwiki::Formatter;
use Spoon::Formatter -Base;
use mixin 'Kwiki::Installer';

const config_class => 'Kwiki::Config';
const class_id => 'formatter';
const class_title => 'Kwiki Formatter';
const top_class => 'Kwiki::Formatter::Top';
const class_prefix => 'Kwiki::Formatter::';
const all_blocks => [qw(comment wafl_block hr heading ul ol pre table p)];
const all_phrases => [qw(
    asis wafl_phrase forced 
    titlehyper titlewiki titlemailto 
    hyper wiki mailto 
    ndash mdash strong em u tt del
)];
const css_file => 'formatter.css';

sub init {
    $self->hub->css->add_file($self->css_file);
}

sub formatter_classes {             
    qw(
        Spoon::Formatter::WaflPhrase
        Spoon::Formatter::WaflBlock
        Line Heading Paragraph Preformatted Comment
        Ulist Olist Item Table TableRow TableCell
        Strong Emphasize Underline Delete Inline MDash NDash Asis
        ForcedLink HyperLink TitledHyperLink TitledMailLink MailLink 
        TitledWikiLink WikiLink
    );
}

################################################################################
# Blocks
################################################################################
package Kwiki::Formatter::Top;
use base 'Spoon::Formatter::Container';
const formatter_id => 'top';

################################################################################
package Kwiki::Formatter::Comment;
use base 'Spoon::Formatter::Unit';
const formatter_id => 'comment';

const html_start => "<!-- \n";
const html_end => " -->\n";

sub match {
    return unless $self->text =~ /^((?:#[\ \t].*\n)+)/m;
    $self->set_match;
}

sub text_filter {
    my $comment = shift;
    $comment =~ s/^# //gm;
    $comment =~ s/-/&#45;/g;
    return $comment;
}

################################################################################
package Kwiki::Formatter::Line;
use base 'Spoon::Formatter::Unit';
const formatter_id => 'hr';
const pattern_block => qr/^----+\s*\n/m;
const html => "<hr />\n";

################################################################################
package Kwiki::Formatter::Heading;
use base 'Spoon::Formatter::Block';
const formatter_id => 'heading';
field 'level'; 

sub html_start { '<h' . $self->level . '>' }
sub html_end { '</h' . $self->level . ">\n" }

sub match {
    return unless $self->text =~ /^(={1,6})\s+(.*?)(\s+=+)?\s*\n+/m;
    $self->level(length($1));
    $self->set_match($2);
}

################################################################################
package Kwiki::Formatter::Paragraph;
use base 'Spoon::Formatter::Block';
const formatter_id => 'p';
const pattern_block => 
  qr/((?:^(?!(?:[\=\*\0]+ |[\#\|\s]|\.\w+\s*\n|-{4,}\s*\n)).*\S.*\n)+(^\s*\n)*)/m;

const html_start => "<p>\n";
const html_end => "</p>\n";

################################################################################
package Kwiki::Formatter::List;
use base 'Spoon::Formatter::Container';
const contains_blocks => [qw(li)];
field 'level';
field 'start_level';
field 'tag_stack' => [];

sub match {
    my $bullet = $self->bullet;
    return unless 
      $self->text =~ /((?:^($bullet).*\n)(?:^\2(?!$bullet).*\n)*)/m;
    $self->set_match;
    ($bullet = $2) =~ s/\s//g;
    $self->level(length($bullet));
    return 1;
}

sub html_start {
    my $next = $self->next_unit;
    my $tag_stack = $self->tag_stack;
    $next->tag_stack($tag_stack)
      if ref($next) and $next->isa('Kwiki::Formatter::List');
    my $level = defined $self->start_level
      ? $self->start_level : $self->level;
    push @$tag_stack, ($self->html_end_tag) x $level;
    return ($self->html_start_tag x $level) . "\n";
}

sub html_end {
    my $level = $self->level;
    my $tag_stack = $self->tag_stack;
    my $next = $self->next_unit;
    my $newline = "\n";
    if (ref($next) and $next->isa('Kwiki::Formatter::List')) {
        my $next_level = $next->level;
        if ($level < $next_level) {
            $next->start_level($next_level - $level);
            $level = 0;
        }
        else {
            $next->start_level(0);
            $level = $level - $next_level;
            $newline = '';
        }
        if ($self->level - $level == $next->level and
            $self->formatter_id ne $next->formatter_id
           ) {
            $level++;
            $next->start_level($next->start_level + 1);
        }
    }
    return join('', reverse splice(@$tag_stack, 0 - $level, $level))
      . $newline;
}

################################################################################
package Kwiki::Formatter::Ulist;
use base 'Kwiki::Formatter::List';
const formatter_id => 'ul';
const html_start_tag => '<ul>';
const html_end_tag => '</ul>';
const bullet => '\*+\ +';

################################################################################
package Kwiki::Formatter::Olist;
use base 'Kwiki::Formatter::List';
const formatter_id => 'ol';
const html_start_tag => '<ol>';
const html_end_tag => '</ol>';
const bullet => '0+\ +';

################################################################################
package Kwiki::Formatter::Item;
use base 'Spoon::Formatter::Block';
const formatter_id => 'li';
const html_start => "<li>";
const html_end => "</li>\n";
const bullet => '[0\*]+\ +';

sub match {
    my $bullet = $self->bullet;
    return unless 
      $self->text =~ /^$bullet(.*)\n/m;
    $self->set_match;
}

################################################################################
package Kwiki::Formatter::Preformatted;
use base 'Spoon::Formatter::Unit';
const formatter_id => 'pre';
const html_start => qq{<pre class="formatter_pre">};
const html_end => "</pre>\n";

sub match {
    return unless $self->text =~ /((?:^ +\S.*?\n|^ *\n)+)/m;
    my $text = $1;
    $self->set_match;
    return unless $text =~ /\S/;
    return 1;
}

sub text_filter {
    my $text = shift;
    $text =~ s/(?<=\n)\s*$//mg;
    my $indent;
    for ($text =~ /^( +)/gm) {
        $indent = length()
          if not defined $indent or
             length() < $indent;
    }
    $text =~ s/^ {$indent}//gm;
    $text;
}

################################################################################
# XXX Support colspan
package Kwiki::Formatter::Table;
use base 'Spoon::Formatter::Container';
const formatter_id => 'table';
const contains_blocks => [qw(tr)];
const pattern_block => qr/((^\|.*?\|\n)+)/sm;
const html_start => qq{<table class="formatter_table">\n};
const html_end => "</table>\n";

################################################################################
package Kwiki::Formatter::TableRow;
use base 'Spoon::Formatter::Container';
const formatter_id => 'tr';
const contains_blocks => [qw(td)];
const pattern_block => qr/(^\|.*?\|\n)/sm;
const html_start => "<tr>\n";
const html_end => "</tr>\n";

################################################################################
package Kwiki::Formatter::TableCell;
use base 'Spoon::Formatter::Unit';
const formatter_id => 'td';
field contains_blocks => [];
field contains_phrases => [];
const table_blocks => [qw(wafl_block hr heading ul ol pre p)];
sub table_phrases { $self->hub->formatter->all_phrases }
const html_start => "<td>";
const html_end => "</td>\n";

sub match {
    return unless $self->text =~ /(\|(\s*.*?\s*)\|)(.*)/sm;
    $self->start_offset($-[1]);
    $self->end_offset($3 eq "\n" ? $+[3] : $+[2]);
    my $text = $2;
    $text =~ s/^[ \t]*\n?(.*?)[ \t]*$/$1/;
    $self->text($text);
    if ($text =~ /\n/) {
        $self->contains_blocks($self->table_blocks);
    }
    else {
        $self->contains_phrases($self->table_phrases);
    }
    return 1;
}

################################################################################
# Phrase Classes
################################################################################
package Kwiki::Formatter::Strong;
use base 'Spoon::Formatter::Phrase';
use Kwiki ':char_classes';
const formatter_id => 'strong';
const pattern_start => qr/(^|(?<=[^$ALPHANUM]))\*(?=\S)/;
const pattern_end => qr/\*(?=[^$ALPHANUM]|\z)/;
const html_start => "<strong>";
const html_end => "</strong>";

################################################################################
package Kwiki::Formatter::Emphasize;
use base 'Spoon::Formatter::Phrase';
use Kwiki ':char_classes';
const formatter_id => 'em';
const pattern_start => qr/(^|(?<=[^$ALPHANUM]))\/(?=\S[^\/]*\/(?=\W|\z))/;
const pattern_end => qr/\/(?=[^$ALPHANUM]|\z)/;
const html_start => "<em>";
const html_end => "</em>";

################################################################################
package Kwiki::Formatter::Underline;
use base 'Spoon::Formatter::Phrase';
use Kwiki ':char_classes';
const formatter_id => 'u';
const pattern_start => qr/(^|(?<=[^$ALPHANUM]))_(?=\S)/;
const pattern_end => qr/_(?=[^$ALPHANUM]|\z)/;
const html_start => "<u>";
const html_end => "</u>";

################################################################################
package Kwiki::Formatter::Inline;
use base 'Spoon::Formatter::Unit';
use Kwiki ':char_classes';
const formatter_id => 'tt';
const pattern_start => qr/(^|(?<=[^$ALPHANUM]))\[\=/;
const pattern_end => qr/\](?=[^$ALPHANUM]|\z)/;
const html_start => "<tt>";
const html_end => "</tt>";

################################################################################
package Kwiki::Formatter::Delete;
use base 'Spoon::Formatter::Phrase';
use Kwiki ':char_classes';
const formatter_id => 'del';
const pattern_start => qr/(^|(?<=[^$ALPHANUM]))-(?=[^\-\s])/;
const pattern_end => qr/-(?=[^$ALPHANUM]|\z)/;
const html_start => '<del>';
const html_end => '</del>';

################################################################################
# Empty Phrases (search & replace)
################################################################################
package Kwiki::Formatter::MDash;
use base 'Spoon::Formatter::Unit';
const formatter_id => 'mdash';
const pattern_start => qr/\-{3}(?=[^-])/;
const html => '&#8212;';

################################################################################
package Kwiki::Formatter::NDash;
use base 'Spoon::Formatter::Unit';
const formatter_id => 'ndash';
const pattern_start => qr/\-{2}(?=[^-])/;
const html => '&#8211;';

################################################################################
# Much Ado about Linking
################################################################################
package Kwiki::Formatter::ForcedLink;
use base 'Spoon::Formatter::Unit';
use Kwiki ':char_classes';
const formatter_id => 'forced';
const pattern_start => qr/\[([$WORD]+)\]/;

sub html {
    $self->matched =~ $self->pattern_start;
    my $target = $1;
    my $script = $self->hub->config->script_name;
    my $text = $self->escape_html( $target );
    my $page = $self->hub->pages->new_from_name($target);
    return $target unless $page;
    my $class = $page->exists
      ? '' : ' class="empty"';
    return qq(<a href="$script?$target"$class>$target</a>);
}

################################################################################
package Kwiki::Formatter::HyperLink;
use base 'Spoon::Formatter::Unit';
const formatter_id => 'hyper';
our $pattern = qr{\w+:(?://|\?)\S+?(?=[),.:;]?\s|$)};
const pattern_start => qr/$pattern|!$pattern/;

sub html {
    my $text = $self->escape_html($self->matched);
    return $text if $text =~ s/^!//;
    return qq(<img src="$text" />)
      if $text =~ /(?:jpe?g|gif|png)$/i;
    return qq(<a href="$text">$text</a>);
}

################################################################################
package Kwiki::Formatter::TitledHyperLink;
use base 'Spoon::Formatter::Unit';
const formatter_id => 'titlehyper';
const pattern_start => 
  qr{\[(?:\s*([^\]]+)\s+)?(\w+:(?://|\?)[^\]\s]+)(?:\s+([^\]]+)\s*)?\]};

sub html {
    my $text = $self->escape_html($self->matched);
    my ($title1, $target, $title2) = ($text =~ $self->pattern_start);
    $title1 = '' unless defined $title1;
    $title2 = '' unless defined $title2;
    $target =~ s{^\w+:(?!//)}{};
    my $title = $title1 . ' ' . $title2;
    $title =~ s/^\s*(.*?)\s*$/$1/;
    $title = $target 
      unless $title =~ /\S/;
    return qq(<a href="$target">$title</a>);
}

################################################################################
package Kwiki::Formatter::WikiLink;
use base 'Spoon::Formatter::Unit';
use Kwiki ':char_classes';
const formatter_id => 'wiki';
our $pattern = qr/[$UPPER](?=[$WORD]*[$UPPER])(?=[$WORD]*[$LOWER])[$WORD]+/;
const pattern_start => qr/$pattern|!$pattern/;

sub html {
    my $page_name = $self->escape_html($self->matched);
    return $page_name
      if $page_name =~ s/^!//;
    my $page = $self->hub->pages->new_from_name($page_name);
    return $page_name unless $page;
    return $page->kwiki_link;
}

################################################################################
package Kwiki::Formatter::TitledWikiLink;
use base 'Spoon::Formatter::Unit';
use Kwiki ':char_classes';
const formatter_id => 'titlewiki';
const pattern_start => 
  qr/\[([^\]]*)\s+([$UPPER](?=[$WORD]*[$UPPER])(?=[$WORD]*[$LOWER])[$WORD]+)\]/;

sub html {
    my $text = $self->escape_html($self->matched);
    my ($label, $page_name) = ($text =~ $self->pattern_start);
    my $page = $self->hub->pages->new_from_name($page_name);
    return $label unless $page;
    return $page->kwiki_link($label);
}

################################################################################
package Kwiki::Formatter::MailLink;
use base 'Spoon::Formatter::Unit';
use Kwiki ':char_classes';
const formatter_id => 'mailto';
our $pattern = qr/[$ALPHANUM][$WORD\+\-\.]*@[$WORD][$WORD\-\.]+/;
const pattern_start => qr/$pattern|!$pattern/;

sub html {
    my $text = $self->escape_html( $self->matched );
    return $text if $text =~ s/^!//;
    my $dot = ($text =~ s/(\.+)$//) ? $1 : '';
    return qq(<a href="mailto:$text">$text</a>$dot);
}

################################################################################
package Kwiki::Formatter::TitledMailLink;
use base 'Spoon::Formatter::Unit';
use Kwiki ':char_classes';
const formatter_id => 'titlemailto';
const pattern_start => 
    qr/\[([^\]]+)\s+([$ALPHANUM][$WORD\+\-\.]*@[$WORD][$WORD\-\.]+)\]/;

sub html {
    my $text = $self->escape_html($self->matched);
    my ($title, $addr) = ($text =~ $self->pattern_start);
    my $dot = ($addr =~ s/(\.+)$//) ? $1 : '';
    return qq(<a href="mailto:$addr">$title</a>$dot);
}

################################################################################
package Kwiki::Formatter::Asis;
use base 'Spoon::Formatter::Unit';
const formatter_id => 'asis';
const pattern_start => qr/\{\{/;
const pattern_end => qr/\}\}/;

package Kwiki::Formatter;
__DATA__

=head1 NAME 

Kwiki::Formatter - Kwiki Formatter Base Class

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
__css/formatter.css__
pre.formatter_pre {
    font-family: monospace;
    background-color: #eee;
    padding: 2px;
    padding-left: 10px;
    margin-left: 20px;
    margin-right: 20px;
}

table.formatter_table {
    border-collapse: collapse;
    margin-bottom: .2em;
}

table.formatter_table td {
    border: 1px;
    border-style: solid;
    padding: .2em;
    vertical-align: top;
}

span.wafl_error {
    color: #f00;
    text-decoration: underline;

