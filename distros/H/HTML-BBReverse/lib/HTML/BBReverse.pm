package HTML::BBReverse;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = "0.07";

sub new {
  my $self = shift;
  my $class = ref($self) || $self;
  my %args;
  $#_ % 2 ? %args = @_ : warn "Odd argument list at " . __PACKAGE__ . "::new";
  
  my %options = (
    allowed_tags => [ qw( b i u code url size color img quote list email html ) ],
    reverse_for_edit => 1,
    in_paragraph => 0,
    no_jslink => 1,
  );
  return bless { %options, %args}, $class;
}


sub parse {
  my $self = shift;
  local $_ = shift;

  (return '') if !$_;
  my %alwd; 
  foreach my $tag (@{$self->{allowed_tags}}) { $alwd{$tag} = 1 } 
  
  s/\&/\&amp\;/g;
  s/</\&lt\;/g;
  s/>/\&gt\;/g;
  s/\r?\n/<br \/>\n/g;
 # first convert the code, list and html-tags, which can't be parsed with a simple regular expression
  $_ = $self->_bb2html($_, $alwd{code}, $alwd{list}, $alwd{html}) if $alwd{code} || $alwd{list} || $alwd{html};
  if($alwd{b}) {
    s/\[b\]/<b>/ig;
    s/\[\/b\]/<\/b>/ig;
  } if($alwd{i}) {
    s/\[i\]/<i>/ig;
    s/\[\/i\]/<\/i>/ig;
  } if($alwd{u}) {
    s/\[u\]/<span style=\"text-decoration: underline\">/ig;
    s/\[\/u\]/<\/span><!--1-->/ig;
  } if($alwd{img}) {
    s/\[img\]([^"\[]+)\[\/img\]/"<img src=\"" . $self->_fix_jslink($1) . "\" alt=\"\" \/>"/eig; #"
    s/\[img=([^"\]]+)\]([^"\[]+)\[\/img\]/"<img src=\"" . $self->_fix_jslink($1) . "\" alt=\"$2\" title=\"$2\" \/>"/eig; #"
  } if($alwd{url}) {
    s/\[url=([^\]"]+)\]/"<a href=\"" . $self->_fix_jslink($1) . "\">"/ieg; 
    s/\[\/url\]/<\/a>/ig;
  } if($alwd{email}) {
    s/\[email\]([^"\[]+)\[\/email\]/<a href=\"mailto: $1\">$1<\/a>/ig; #"
  } if($alwd{size}) {
    s/\[size=([0-9]{1,2})\]/<span style=\"font-size: $1px\">/ig;
    s/\[\/size\]/<\/span><!--2-->/ig;
  } if($alwd{color}) {
    s/\[color=([^"\]\s]+)\]/<span style=\"color: $1\">/ig;  #"
    s/\[\/color\]/<\/span><!--3-->/ig;
  } if($alwd{quote}) {
    s/\[quote\]/<span class=\"bbcode_quote_header\">Quote: <span class=\"bbcode_quote_body\">/ig;
    s/\[quote=([^<\]]+)\]/<span class=\"bbcode_quote_header\">$1 wrote: <span class=\"bbcode_quote_body\">/ig;
    s/\[\/quote\]/<\/span><\/span>/ig;
  }
  s/\&#91\;/[/g;
  s/\&#93\;/]/g;
#  s/\r?\n$//;
#  s/\s$//;
  return $_;
}
sub _fix_jslink {
  my $self = shift;
  my $lnk = shift;
  $lnk =~ s/^[\s\t]*javascript://g if $self->{no_jslink};
  return $lnk;
}

sub reverse {
  my $self = shift;
  local $_ = shift;

  (return '') if !$_;
  my %alwd;
  foreach my $tag (@{$self->{allowed_tags}}) { $alwd{$tag} = 1 } 

  $_ = $self->_html2bb($_, $alwd{code}, $alwd{list}, $alwd{html}) if $alwd{code} || $alwd{list} || $alwd{html};
  if($alwd{b}) {
    s/<b>/[b]/g;
    s/<\/b>/[\/b]/g;
  } if($alwd{i}) {
    s/<i>/[i]/g;
    s/<\/i>/[\/i]/g;
  } if($alwd{u}) {
    s/<span style=\"text-decoration: underline\">/[u]/g;
    s/<\/span><!--1-->/[\/u]/g;
  } if($alwd{img}) {
    s/<img src=\"([^"\[]+)\" alt=\"\" \/>/\[img\]$1\[\/img\]/g; #" 
    s/<img src=\"([^"\[]+)\" alt=\"([^"\[]+)\" title=\"\2\" \/>/\[img=$1\]$2\[\/img\]/g; #" 
  } if($alwd{email}) {
    s/<a href=\"mailto: ([^\["]+)\">\1<\/a>/\[email\]$1\[\/email\]/g; #"
  } if($alwd{url}) {
    s/<a href=\"([^\]"]+)\">/\[url=$1\]/g; #"
    s/<\/a>/\[\/url\]/g;
  } if($alwd{size}) {
    s/<span style=\"font-size: ([0-9]{1,2})px\">/\[size=$1\]/g;
    s/<\/span><!--2-->/\[\/size\]/g;
  } if($alwd{color}) {
    s/<span style=\"color: ([^"\]\s]+)\">/\[color=$1\]/g; #" 
    s/<\/span><!--3-->/\[\/color\]/g;
  } if($alwd{quote}) {
    s/<span class=\"bbcode_quote_header\">Quote: <span class=\"bbcode_quote_body\">/\[quote\]/g;
    s/<span class=\"bbcode_quote_header\">([^<\]]+) wrote: <span class=\"bbcode_quote_body\">/\[quote=$1\]/g;
    s/<\/span><\/span>/\[\/quote\]/g;
  }
  s/<br \/>\r?\n/\n/g;
  if(!$self->{reverse_for_edit}) {
    s/\&gt\;/>/g;
    s/\&lt\;/</g;
    s/\&amp\;/\&/g;
  }
  
  return $_;
}



## Parses the BB code, list and html tags
sub _bb2html {
  my $self = shift;
  my $str = shift;
  my($acode, $alist, $ahtml) = @_;
  my $return = "";
  
  my $incode = 0; my $inhtml = 0;
  my $inlist = 0; my $liststart = 0;
  while($str =~ /\[(\/?)(code|list|html|\*)=?([^\]])*\](.*)$/ims) {
    $str = $4;
    my($be4, $end, $tag, $opt, $done, $app) = ($`, ($1 eq '/' ? 1 : 0), $2, $3, 0, 0);
   # Parse the stuff before the tag... (if any)
    if($be4 && $incode) {
      if(lc($tag) ne 'code' && !$end) {
        $be4 .= _appendtag($end, $tag, $opt);
        $app++;
      }
      $be4 =~ s/\[/\&#91\;/g;
      $be4 =~ s/\]/\&#93\;/g;
    } elsif($be4 && $inlist && $inlist != $liststart) {
      $be4 = '';
    } elsif($be4 && $inhtml) {
      if(lc($tag) ne 'html' && !$end) {
        $be4 .= _appendtag($end, $tag, $opt);
        $app++;
      }
      $be4 =~ s/<br \/>\r?\n/\n/g;
      $be4 =~ s/\&gt\;/>/g;
      $be4 =~ s/\&lt\;/</g;
      $be4 =~ s/\&amp\;/\&/g;
      $be4 =~ s/\[/\&#91\;/g;
      $be4 =~ s/\]/\&#93\;/g;
    }
    $return .= $be4 if $be4;
   # The [code]-tag
    if($acode && !$inhtml) {
      if(!$incode && lc($tag) eq 'code' && !$end) {
        $return .= "<span class=\"bbcode_code_header\">Code: <span class=\"bbcode_code_body\">";
        $incode = 1;
        $done++;
      } elsif($incode && lc($tag) eq 'code' && $end) {
        $return .= "</span> </span>";
        $incode = 0;
        $done++;
      }
    }
   # The [list] and [*]-tags
    if($alist && !$incode && !$inhtml) {
      if(lc($tag) eq 'list' && !$end) {
        $return .= '</p>' if !$inlist && $self->{in_paragraph};
        $return .= '<ul>' if !$opt;
        $return .= '<ul style="list-style-type: decimal">' if $opt && $opt eq '1';
        $return .= '<ul style="list-style-type: lower-roman">' if $opt && lc($opt) eq 'a';
        $return .= "\n";
        $inlist++;
        $done++;
      } elsif(lc($tag) eq 'list' && $end) {
        $return .= '</li></ul>';
        $return .= '<p>' if $inlist == 1 && $self->{in_paragraph};
        $liststart = --$inlist;
        $done++;
      } elsif(lc($tag) eq '*') {
        $return .= '</li>' if $liststart == $inlist;
        $return .= '<li>';
        $liststart = $inlist;
        $done++;
      }
    }
   # The [html]-tag
    if($ahtml && !$incode) {
      if(!$inhtml && lc($tag) eq 'html' && !$end) {
        $return .= "<!--BB-html-->";
        $inhtml = 1;
        $done++;
      } elsif($inhtml && lc($tag) eq 'html' && $end) {
        $return .= "<!--/BB-html-->";
        $inhtml = 0;
        $done++;
      }
    }
   # When nothing is done with the tag, just add it... (fixes bug added in 0.05)
    $return .= _appendtag($end, $tag, $opt) if !$done && !$app;
  }
  return $return . $str;
}
sub _appendtag {
  my $tag = '[';
  $tag .= '/' if $_[0];
  $tag .= $_[1];
  $tag .= "=$_[2]" if $_[2];
  return "$tag]";
}


sub _html2bb {
  my $self = shift;
  my $str = shift;
  my($acode, $alist, $ahtml) = @_;
  my $return = "";
  
  my $incode = 0; my $inhtml = 0;
  my $inlist = 0;
  $str =~ s/(?:<\/p>|<p>|<\/li>)//g;
 # And this definately is one of the most ugly RegEx-es I've ever written
  while($str =~ /(<span\ class="bbcode_code_header">Code:\ <span\ class="bbcode_code_body">|<\/span>\ <\/span>
    |<ul>|<ul\ style="list-style-type:\ decimal">|<ul\ style="list-style-type:\ lower-roman">|<li>|<\/ul>
    |<!--BB-html-->|<!--\/BB-html-->)(.*)$/xms)
  {
    $str = $2;
    my($be4, $code, $done) = ($`, $1, 0);
   # Parse the stuff before the tag... (if any)
    if($be4 && $inhtml) {
      $be4 .= $code if $code ne '<!--/BB-html-->';
      $be4 =~ s/\&/\&amp\;/g;
      $be4 =~ s/</\&lt\;/g;
      $be4 =~ s/>/\&gt\;/g;
    }
    $return .= $be4 if $be4;
   # The code-tag
    if($acode && !$inhtml) {
      if(!$incode && $code eq '<span class="bbcode_code_header">Code: <span class="bbcode_code_body">') {
        $return .= '[code]';
        $incode = 1;
        $done++;
      } elsif($incode && $code eq '</span> </span>') {
        $return .= '[/code]';
        $incode = 0;
        $done++;
      }
    }
   # The list-tags
    if($alist && !$incode && !$inhtml) {
      if($code eq '<ul>' || $code eq '<ul style="list-style-type: decimal">' || $code eq '<ul style="list-style-type: lower-roman">') {
        $return .= '[list]' if $code eq '<ul>';
        $return .= '[list=1]' if $code eq '<ul style="list-style-type: decimal">';
        $return .= '[list=a]' if $code eq '<ul style="list-style-type: lower-roman">';
        $inlist++;
        $done++;
      } elsif($code eq '</ul>') {
        $return .= '[/list]';
        $inlist--;
        $done++;
      } elsif($code eq '<li>') {
        $return .= '[*]';
        $done++;
      }
    }
   # The html-tag
    if($ahtml && !$incode) {
      if(!$inhtml && $code eq '<!--BB-html-->') {
        $return .= '[html]';
        $inhtml = 1;
        $done++;
      } elsif($inhtml && $code eq '<!--/BB-html-->') {
        $return .= '[/html]';
        $inhtml = 0;
        $done++;
      }
    }
    $return .= $code if !$done && $code ne '<!--/BB-html-->';
  }
  return $return . $str;
}

1;

__END__

=head1 NAME

HTML::BBReverse - Perl module to convert HTML to BBCode and back

=head1 VERSION

This document describes version 0.06 of HTML::BBReverse, released
2006-02-15.

This module is still beta, but should work as expected.

=head1 SYNOPSIS

  use HTML::BBReverse
  
  my $bbr = HTML::BBReverse->new();
  
  # convert BBCode into HTML
  my $html = $bbr->parse($bbcode);
  # convert generated HTML back to BBCode
  my $bbcode = $bbr->reverse($html);

=head1 DESCRIPTION

C<HTML::BBReverse> is a pure perl module for converting BBCode to HTML and is
able to convert the generated HTML back to BBCode.

And why would you want to reverse the generated HTML? Well, when you have a
nice dynamic website where you and/or visitors can post messages, and in
those messages BBCode is used for markup. In normal cases, your website has
a lot more pageviews than edits, and saving all those messages as HTML will
be a lot faster than saving them as the original BBCode and parsing them to
HTML for every visit.

So now all BBCode gets converted to HTML before it will be saved, but what
if you want to edit a message? Just reverse the generated HTML back to
BBCode, edit your message, and save it as HTML again.

=head2 METHODS

The following methods can be used

=head3 new

  my $bbr = HTML::BBReverse->new(
    allowed_tags => [
      qw( b i u code url size color img quote list email html )
    ],
    reverse_for_edit => 1,
    in_paragraph => 0,
    no_jslink => 1,
  );

C<new> creates a new HTML::BBReverse object using the configuration passed to
it. 

=head4 options

The following options can be passed to C<new>:

=over 4

=item allowed_tags

Specifies which BBCode tags will be parsed, for the current supported tags, see
L<the list of supported tags|/"SUPPORTED TAGS"> below. Defaults to all
supported tags.

=item reverse_for_edit

When set to a positive value, the C<reverse> method will parse C<&>, C<E<gt>> and
C<E<lt>> to their HTML entity equivalent. This option is useful when reversing
HTML to BBCode for editing in a browser, in a normal C<textarea>. When set to
zero, the C<reverse> method should just ignore these characters. Defaults to 1.

=item in_paragraph

Specifies wether the generated HTML is used between HTML paragraphs (C<E<lt>pE<gt>>
and C<E<lt>/pE<gt>>), and adds a C<E<lt>/pE<gt>> in front of and a C<E<lt>pE<gt>>
after every list. (XHTML 1.0 strict document types do not allow lists in
paragraphs) Defaults to 0.

=item no_jslink

When true, URLs starting with C<javascript:> will be disabled for the C<[url]>
and C<[img]> tags. Enabled by default.

=back

=head3 parse

Parses BBCode text supplied as a single scalar string and returns the HTML as a
single scalar string. See L<Supported tags|/"SUPPORTED TAGS"> below for the
supported tags and their usage.

=head3 reverse

Parses HTML generated from C<parse> supplied as a single scalar string and
returns BBCode as a single scalar string.
B<Note that this method can only be used to reverse HTML generated by the
C<parse> method of this module, it won't be able to parse just any HTML to
BBCode>

=head2 SUPPORTED TAGS

The following BBCode tags are supported:

=over 4

=item b, i, u

Standard markup tags, any text between C<[b]> and C<[/b]> will be B<bold>,
text between C<[i]> and C<[/i]> will be italic and text between C<[u]> and
C<[/u]> will be underlined. For example:

  [i]italic[/i]
  [b]bold[/b]
  [u]underlined[/u]

Will be C<parse>d to:

  <i>italic</i>
  <b>bold</b>
  <span style="text-decoration: underline">underlined</span>

Note that the HTML C<E<lt>uE<gt>> and C<E<lt>/uE<gt>> tags are not used for
underlining, this is because they are deprecated and not allowed in XHTML
1.0 Strict.

=item img

Adds an image, can be used in two ways, one for an image without description
and one for an image with description. For example:

  [img]/path/to/image.jpg[/img]
  [img=image.jpg]description[/img]

Will be C<parse>d to:

  <img src="/path/to/image.jpg" alt="" />
  <img src="image.jpg" alt="description" title="description" />

The description should be a small one-line description of the image.

=item quote

Used to quote someone (or something), syntax is similar to the
C<img> tag. Optional argument specifies the quoted author.
For example:

  [quote]Who said this?[/quote]
  
  [quote=Bill Gates]
   The great thing about a computer notebook is that no matter 
   how much you stuff into it, it doesn't get bigger or heavier.
  [/quote]

Will be C<parse>d to:

  <span class="bbcode_quote_header">Quote:
   <span class="bbcode_quote_body">Who said this?</span></span>
  
  <span class="bbcode_quote_header">Bill Gates wrote:
   <span class="bbcode_quote_body">
   The great thing about a computer notebook is that no matter 
   how much you stuff into it, it doesn't get bigger or heavier.
  </span></span>

=item url

  [url=/some/url]link text[/url]

Creates a clickable link, argument is required. The above example
will generate the following HTML:

  <a href="/some/url">link text</a>

=item email

  [email]email@example.org[/email]

Creates a clickable C<mailto:> link. The above example will
generate the following HTML:

  <a href="mailto:email@example.org">
   email@example.org</a>

=item size

  [size=30]huge[/size]

The C<size> tag controls the size of the text in pixels. The
above example will generate the following HTML:

  <span style="font-size: 30px">huge</span><!--2-->

Note the C<E<lt>!--2--E<gt>>, this HTML-comment is added for
C<reverse> to see the difference between the same end-tags.

=item color

  [color=red]Red[/color]

Changes the color of the text, the color can be in any
acceptable HTML-format: color-names or hex-codes (preceded with
a C<#>). The above example will generate the following HTML:

  <span style="color: red">Red</span><!--3-->

=item list

The C<list> tag can be used to create lists of various types.
Between the C<[list]> and C<[/list]> tags can the special
C<[*]> tag be used to specify an item. The C<[list]> tag itself
accepts one optional argument to specify the style of the list,
which can be one of the following:

  [list]    normal, dotted, list
  [list=1]  numbered list
  [list=a]  alphabetic list

For example:

  [list]
   [*]item 1
   [*]item 2
  [/list]

Will generate a simple dotted list, created with the
following HTML:

  <ul>
   <li>item 1<br />
   </li><li>item 2<br />
  </ul>

Note that anything between the C<[list]> tag and the first
item will be ignored and replaced with a newline (C<\n>).

=item code

The C<code> tag can be used to insert code, anything between
the C<[code]> and C<[/code]> tags will be ignored, For example:

  [code]
   [b]This isn't bold text[/b]
  [/code]

Will be C<parse>d to:

  <span class="bbcode_code_header">Code:
   <span class="bbcode_code_body"><br />
   [b]This isn't bold text[/b]
  </span> </span>

=item html

The C<html> tag can be used to insert raw html, anything
between the C<[html]> and C<[/html]> tags will be treated
as HTML and will not be parsed. For example:

  [html]
   And this is <b>raw</b> HTML :)
  [/html]

Will be C<parse>d to:

  <!--BB-html-->
   And this is <b>raw</b> HTML :)
  <!--/BB-html--> 

Note the C<E<lt>!--BB-html--E<gt>> and C<E<lt>!--/BB-html--E<gt>>
tags, these are used by C<reverse> to determine what should
be treated as HTML.

=back

=head3 Nesting tags

All tags (except of course C<code> and C<html>) can be nested,
please note though that wrong nested BBCode will not automatically
be corrected, and will generate wrong HTML. See L<Caveats|/"CAVEATS">
below.

=head1 SEE ALSO

L<http://dev.yorhel.nl/HTML-BBReverse/>,
L<http://www.phpbb.com/phpBB/faq.php?mode=bbcode>,
L<HTML::BBCode|HTML::BBCode>, L<BBCode::Parser|BBCode::Parser>

=head1 CAVEATS

=head2 Laziness

HTML::BBReverse is a lazy module, which simply means it does not check any
syntax, and just converts any BBCode to HTML (or back), even when the input
contains errors like wrong nested tags or even close tags without start
tags or start tags without close tags. Therefore, wrong input means
wrong output. Note though that reversing HTML which is generated with
C<parse> with 'wrong' BBCode as input, should still give the same 'wrong'
BBCode as output.

=head2 Lists formatting

The space between a code start tag (C<[code]>) and the first item (C<[*]>)
will be completely ignored, and replaced with a linebreak. For example:
When you C<parse>

  [list]some
  text or [b]bbcode[/b]
  here[*]item[/list]

to HTML, and C<reverse> it back to BBCode, it will give the following
output:

  [list]
  [*]item[/list]

This 'feature' (some might call it a bug) is added because it is not allowed
to have content between C<E<lt>ulE<gt>> and the first C<E<lt>liE<gt>> in
(X)HTML.

=head1 BUGS

No known bugs, but that doesn't mean there aren't any. If you find a bug
please report it at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=HTML-BBReverse>
or contact the author.

=head1 TODO

HTML::BBReverse is still in development, and new functions will probably be
added.

=over 4

=item Syntax checking

An extra method which checks the syntax of BBCode and maybe the generated
HTML, and an option to C<new> where you can configure wether the syntax
should be checked before a C<parse> of C<reverse>, and what to do if there
is a syntax error.

=item Automatically parse URLs and e-mails

An extra option to C<new> which specifies wether C<parse> should automatically
parse URLs and e-mail addresses to clickable links.

=back

If you think of a useful feature which you would like to see in C<HTML::BBCode>,
just contact the author!

Of course HTML::BBReverse also needs a little more testing and bugfixes
before it will be considered stable.

=head1 AUTHOR

Y. Heling, E<lt>yorhel@cpan.orgE<gt>, (L<http://www.yorhel.nl/>)

=head1 CREDITS

I would like to thank the following people:

=over 4

=item * Thijs Wijnmaalen (L<http://thijs.wijnmaalen.name/>) for helping to refine the idea

=item * M. Blom for pointing out some bugs

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2006 by Y. Heling

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
