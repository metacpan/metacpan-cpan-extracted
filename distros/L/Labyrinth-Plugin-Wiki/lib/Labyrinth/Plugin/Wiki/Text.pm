package Labyrinth::Plugin::Wiki::Text;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '1.06';

=head1 NAME

Labyrinth::Plugin::Wiki::Text - Wiki text handler for Labyrinth framework.

=head1 DESCRIPTION

Contains all the Wiki text rendering code for Labyrinth.

=cut

# -------------------------------------
# Library Modules

use base qw(Labyrinth::Plugin::Base);

use Labyrinth::Audit;
use Labyrinth::DBUtils;
use Labyrinth::MLUtils;
use Labyrinth::Support;
use Labyrinth::Users;
use Labyrinth::Variables;

# -------------------------------------
# Variables

                                # preset with restricted pages
my %wiki_links = map {$_ => 1}  qw(People Login Search RecentChanges);

my ($LinkPattern,$SitePattern,$UrlPattern,$UriPattern,$MailPattern,$SendPattern);

# HTML tag lists
                    # Single tags (that do not require a closing /tag)
my @HtmlSingle =    qw(br hr);
                    # Tags that must be in <tag> ... </tag> pairs:
my @HtmlPairs  = (  qw(b i p u h1 h2 h3 h4 h5 h6 code em strike strong blockquote ol ul li dt dd tr td th),
                    @HtmlSingle);  # All singles can also be pairs

# -------------------------------------
# Public Methods

=head1 PUBLIC INTERFACE METHODS

=over 4

=item Render

Controls the process of rendering a given page.

=item InitLinkPatterns

Prepares patterns used to translate wiki links into HTML links.

=item Wiki2HTML

Translate WikiFormat into XHTML.

=item CommonMarkup

Looks for and translates common WikiFormat markup into XHTML.

=item WikiLink

Looks for and translates WikiFormat links into XHTML.

=item WikiHeading

Translate WikiFormat heading into XHTML.

=cut

sub Render {
    my $self    = shift;
    my $hash    = shift;
    my $title   = $cgiparams{pagename};
    my $content = $hash->{content};

    InitLinkPatterns()  unless($LinkPattern);

    $content = Wiki2HTML($content);

    # reposition top level heading
    if($content =~ s!^<h1>(.*?)</h1>!!) {
        $title = $1;
    }

    return $title,$content;
}

sub InitLinkPatterns {
  my $UpperLetter = '[A-Z\xc0-\xde]';
  my $LowerLetter = '[a-z\xdf-\xff]';
  my $AnyLetter   = '[A-Za-z\xc0-\xff_0-9\$]';
  my $AnyString   = '[A-Za-z\xc0-\xff_0-9 \-\&\'~.,\?\(\)\"!\$:\/]';

  # Main link pattern: lowercase between uppercase, then anything
  my $LpA = $UpperLetter . $AnyLetter . '*';
  my $LpB = $AnyLetter   . $AnyString . '*';
  my $LpC = $AnyLetter                . '*:' . $AnyString . '*';

  $LinkPattern = qr!\[\[($LpA|$LpC)\]\]!;
  $SitePattern = qr!\[\[($LpA|$LpC)\|($LpB)\]\]!;

  $UrlPattern = qr!\[($settings{urlregex})\]!;
  $UriPattern = qr!\[($settings{urlregex})[ \|]($LpB)\]!;

  $MailPattern = qr!\[(?:mailto:)?($settings{emailregex})\]!;
  $SendPattern = qr!\[(?:mailto:)?($settings{emailregex})[ |]($LpB)\]!;
}

sub Wiki2HTML {
    my ($text) = @_;
    my (@stack, $code, $oldcode, $parse);
    my $depth = 0;
    my $html = '';

    $code = 'p';                  # we assume a paragraph starts
    $text =~ s/\r\n?/\n/g;
    for (split(/\n/, $text)) {    # Process lines one-at-a-time
        $_ .= "\n";
        $parse = 2;
        if (s/^(\*+)/<li>/) {
            $code = "ul";
            $depth = length $1;
        } elsif (s/^(\#+)/<li>/) {
            $code = "ol";
            $depth = length $1;
        } elsif (s/^![ \t]//) {
            $code = "pre";
            $depth = 1;
            $parse = 0;
        } elsif (s/^([ \t]{2})//) {
            $code = "pre";
            $depth = 1;
            $parse = 1;
        } elsif (s/^(\" )//) {
            $code = "blockquote";
            $depth = 1;
        } else {
            $code = "p";
            $depth = 0;
        }
        while (@stack > $depth) {     # Close tags as needed
            $html .= '</' . pop(@stack) . ">\n";
        }
        if ($depth > 0) {
#            $depth = $IndentLimit    if ($depth > $IndentLimit);
            if (@stack) {    # Non-empty stack
                $oldcode = pop(@stack);
                if ($oldcode ne $code) {
                    $html .= "</$oldcode><$code>\n";
                }
                push(@stack, $code);
            }
            while (@stack < $depth) {
                push(@stack, $code);
                $html .= "<$code>\n";
            }
        }

        if($code eq 'pre') {
            s!^\s*$!<br />\n!;  # Blank lines become new lines
        } else {
            s!^\s*$!<p>!;     # Blank lines become new paragraphs
        }
        $html .= CommonMarkup($_, $parse);
    }
    while (@stack > 0) {             # Clear stack
        $html .= '</' . pop(@stack) . ">\n";
    }

    $html = process_html($html,0,1);

#    $html =~ s!<p>(.*?)\s*<(ul|ol|h[1-6]|pre|p)>!<p>$1</p>\n<$2>!gs;    # close <p>'s.
#    $html =~ s!<p>(.*?)\s*$!<p>$1</p>!gs;               # close final <p>.
#    $html =~ s!\s*</p>\s*</p>!</p>!gs;                  # remove extra close paragraphs
#    $html =~ s!<p>\s*</p>!!gs;                          # remove black paragraphs
#    $html =~ s/(\s|<p>)*<p>\s*/\n<p>/gs;                # multiple blank lines fold into one.
#    $html =~ s/\s*<p>\s*<(ul|ol|h[1-6]|pre)/\n<$1/gs;   # remove unnecessary <p>'s.
#    $html =~ s!([^>\s]+)\s*<p>!$1</p>\n<p>!gs;          # close paragraphs.
#    $html =~ s!\s*</p>\s*<p!</p>\n<p!gs;                # separate paragraphs for readability.

    LogDebug("html=[$html]");
    return $html;
}

# 2 = Full parser
# 1 = Link only parsing
# 0 = no parsing

sub CommonMarkup {
  my ($text, $parse) = @_;
  local $_ = $text;

  if ($parse > 1) {
    s!\&lt;pre\&gt;((.|\n)*?)\&lt;\/pre\&gt;!<pre>$1</pre>!ig;
    s!\&lt;code\&gt;((.|\n)*?)\&lt;\/code\&gt;!<code>$1</code>!ig;

    my $t;
    for $t (@HtmlPairs) {
      s!\&lt;$t(\s[^<>]+?)?\&gt;(.*?)\&lt;\/$t\&gt;!<$t$1>$2<\/$t>!gis;
    }
    for $t (@HtmlSingle) {
      s!\&lt;$t(\s[^<>]+?)?\&gt;!<$t$1>!gi;
    }

    # The quote markup patterns avoid overlapping tags (with 5 quotes)
    # by matching the inner quotes for the strong pattern.
    s/!!(.*?)!!/<code>$1<\/code>/g; #'
    s/('*)'''(.*?)'''/$1<strong>$2<\/strong>/g; #'
    s/''(.*?)''/<em>$1<\/em>/g;
    s/(^|\n)\s*(\=+)\s+([^\n]+)\s+\=+/WikiHeading($1, $2, $3)/geo;

    s!\&lt;br\&gt;!<br />!g;
    s!----+!<hr noshade="noshade" size="1" />!g;
    s!====+!<hr noshade="noshade" size="2" />!g;
  }

  if($parse > 0) {
    s!$SitePattern!WikiLink($1,$2)!eg;
    s!$LinkPattern!WikiLink($1,$1)!eg;

    s!$UriPattern!<a href="$1">$2</a>!g;
    s!$UrlPattern!<a href="$1">$1</a>!g;

    s!$SendPattern!<a href="mailto:$1">$2</a>!g;
    s!$MailPattern!<a href="mailto:$1">$1</a>!g;
  }

  return $_;
}

sub WikiLink {
    my ($page,$name) = @_;

    if($page =~ /cpan:~(.*)/) {
        $page =~ s!cpan:~!!;
        $name =~ s!cpan:~!!;
        return qq!<a href="http://search.cpan.org/~$page">$name</a>!;
    } elsif($page =~ /cpan:(.*)/) {
        $page =~ s!cpan:!!;
        $name =~ s!cpan:!!;
        return qq!<a href="http://search.cpan.org/dist/$page">$name</a>!;
    } elsif($page =~ /perldoc:(.*)/) {
        $page =~ s!perldoc:!!;
        $name =~ s!perldoc:!!;
        return qq!<a href="http://perldoc.perl.org?$page">$name</a>!;
    } elsif($page =~ /user:(\d+|[\w ]+)/) {
        $name = undef   if($page eq $name);
        return _mapuser($1,$name);
    } elsif($page =~ /image:(\d+)/) {
        return _mapimage(id => $1);
    } elsif($page =~ /image:(.*)/) {
        return _mapimage(name => $1);
    } elsif($page =~ /media:(\d+)/) {
        return _mapmedia(id => $1);
    } elsif($page =~ /media:(.*)/) {
        return _mapmedia(name => $1);
    }

    $wiki_links{$page} ||= do {
        my @rows = $dbi->GetQuery('hash','CheckWikiPage',$page);
        @rows ? 1 : 0;
    };

    if($wiki_links{$page}) {
        return qq!<a href="/wiki/$page">$name</a>!
    }

    return qq!<a href="/wiki/$page">$name</a>?!
}

sub WikiHeading {
  my ($pre, $depth, $text) = @_;

  $depth = length($depth) - 1;
  $depth = 6  if ($depth > 6);
  return $pre . "<h$depth>$text</h$depth>\n";
}

# -------------------------------------
# Private Methods

sub _mapuser {
    my $id = shift;
    my $nm = $id;

    if($id =~ /^\d+$/) {
        $nm = UserName($id);
    } else {
        $id = UserID($id);
    }

    return qq!<a href="/user/$id" title="User:$nm">$nm</a>!;
}

sub _mapimage {
    my %hash = @_;
    my @rows;

    if($hash{id}) {
        @rows = $dbi->GetQuery('hash','GetImageByID',$hash{id});
    } else {
        @rows = $dbi->GetQuery('hash','GetImageByName',$hash{id});
    }

    return  unless(@rows);
    return qq!<img src="$tvars{webpath}/images/$rows[0]->{link}" alt="$rows[0]->{tag}" />!;
}

sub _mapmedia {
    my %hash = @_;
    my @rows;

    if($hash{id}) {
        @rows = $dbi->GetQuery('hash','GetImageByID',$hash{id});
    } else {
        @rows = $dbi->GetQuery('hash','GetImageByName',$hash{id});
    }

    return  unless(@rows);
    return qq!<a href="$tvars{webpath}/images/$rows[0]->{link}" title="$rows[0]->{tag}">$rows[0]->{tag}</a>!;
}

1;

__END__

=back

=head1 SEE ALSO

L<Labyrinth>

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2008-2014 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
