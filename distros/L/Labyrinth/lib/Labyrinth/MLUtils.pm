package Labyrinth::MLUtils;

use warnings;
use strict;
use utf8;

use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT @EXPORT_OK);
$VERSION = '5.32';

=head1 NAME

Labyrinth::MLUtils - Markup Language Utilities for Labyrinth.

=head1 SYNOPSIS

  use Labyrinth::MLUtils;

=cut

# -------------------------------------
# Export Details

require Exporter;
@ISA = qw(Exporter);
%EXPORT_TAGS = ( 'all' => [ qw(
        LegalTag LegalTags CleanTags
        CleanHTML SafeHTML CleanLink CleanWords LinkTitles
        DropDownList DropDownListText
        DropDownRows DropDownRowsText
        DropDownMultiList DropDownMultiRows
        ErrorText ErrorSymbol
        LinkSpam

        create_inline_styles
        demoroniser
        process_html escape_html
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT    = ( @{ $EXPORT_TAGS{'all'} } );

# -------------------------------------
# Library Modules

use Encode::ZapCP1252;
use HTML::Entities;
use Regexp::Common  qw /profanity/;

use Labyrinth::Audit;
use Labyrinth::Variables;

# -------------------------------------
# Variables

my $DEFAULTTAGS = 'p,a,br,b,strong,center,hr,ol,ul,li,i,img,u,em,strike,h1,h2,h3,h4,h5,h6,table,thead,tr,th,tbody,td,sup,address,pre';
my ($HTMLTAGS,%HTMLTAGS);

# -------------------------------------
# The Public Interface Subs

=head1 FUNCTIONS

=head2 HTML Tag handling

=over 4

=item LegalTag

Returns TRUE or FALSE as to whether the given HTML tag is accepted by the
system.

=item LegalTags

Returns the list of HTML tags that are accepted by the system.

=item CleanTags

For a given text string, attempts to clean the use of any HTML tags. Any HTML
tags found that are not accepted by the system are encoded into HTML entities.

=item CleanHTML

For a given text string, removes all existence of any HTML tag. Mostly used in
input text box cleaning.

=item SafeHTML

For a given text string, encodes all HTML tags to HTML entities. Mostly used in
input textarea edit preparation.

=item CleanLink

Attempts to remove known spam style links.

=item CleanWords

Attempts to remove known profanity words.

=item LinkTitles

Given a XHTML snippet, will look for basic links and add title attributes.
Titles are of rhe format 'External Site: $domain', where $domain is the domain
used in the link.

=back

=cut

sub LegalTag {
    my $tag = lc shift;

    my %tags = _buildtags();
    return 1    if($tags{$tag});
    return 0;
}

sub LegalTags {
    my %tags = _buildtags();
    my $tags = join(", ", sort keys %tags);
    $tags =~ s/, ([^,]+)$/ and $1/;
    return $tags;
}

sub CleanTags {
    my $text = shift;
    return ''   unless($text);

    $text =~ s!</?(span|tbody)[^>]*>!!sig;
    $text =~ s!<(br|hr)>!<$1 />!sig;
    $text =~ s!<p>(?:\s|&nbsp;)+(?:</p>)?<(table|p|ul|ol|div|pre)!<$1!sig;
    $text =~ s!\s+&\s+! &amp; !sg;
    $text =~ s!&[lr]squo;!&quot;!mg;
    $text =~ s{&(?!\#\d+;|[a-z0-9]+;)}{&amp;}sig;

    # decode TinyMCE encodings
    $text =~ s!&lt;(.*?)&gt;!<$1>!sig;

    # clean paragraphs
    $text =~ s!</p>\s+<p>!</p><p>!sig;
    $text =~ s!\s*<br /><br />\s*!</p><p>!sig;

    my %tags = _buildtags();
    my @found = ($text =~ m!</?(\w+)(?:\s+[^>]*)?>!gm);
    for my $tag (@found) {
        $tag = lc $tag;
        next    if($tags{$tag});

        $text =~ s!<(/?$tag(?:[^>]*)?)>!&lt;$1&gt;!igm;
        $tags{$tag} = 1;
    }

    process_html($text,0,1);
}

sub CleanHTML {
    my $text = shift;
    return ''   unless($text);

    $text =~ s!<[^>]+>!!gm; # remove any tags
    $text =~ s!\s{2,}! !mg;
    $text =~ s!&[lr]squo;!&quot;!mg;
    $text =~ s{&(?!\#\d+;|[a-z0-9]+;)}{&amp;}sig;

    process_html($text,0,0);
}

sub SafeHTML {
    my $text = shift;
    return ''   unless($text);

    $text =~ s!<!&lt;!gm;
    $text =~ s!>!&gt;!gm;
    $text =~ s!\s+&\s+! &amp; !mg;
    $text =~ s!&[lr]squo;!&quot;!mg;
    $text =~ s{&(?!\#\d+;|[a-z0-9]+;)}{&amp;}sig;

    process_html($text,0,0);
}

sub CleanLink {
    my $text = shift;
    return ''   unless($text);

    # remove embedded script tags
    $text =~ s!<script.*?/script>!!gis; # open and close script tags
    $text =~ s!<script.*!!gis;          # open, but no close, remove to the end of string
    $text =~ s!.*/script>!!gis;         # close, but on open, removed from te beginning of string

    # remove anything that looks like a link
    $text =~ s!https?://[^\s]*!!gis;
    $text =~ s!<a.*?/a>!!gis;
    $text =~ s!\[url.*?url\]!!gis;
    $text =~ s!\[link.*?link\]!!gis;
#    $text =~ s!$settings{urlregex}!!gis;

    CleanTags($text);
}

sub CleanWords {
    my $text = shift;

    $text =~ s/$RE{profanity}//gis;
    my $filter = join("|", map {$_->[1]} $dbi->GetQuery('array','AllBadWords'));
    $text =~ s/$filter//gis;

    return $text;
}

sub LinkTitles {
    my $text = shift;

    for my $href ($text =~ m!(<a href="https?://[^/"]+(?:/[^"]*)?">)!g) {
        my ($link1,$path,$link2) = ($href =~ m!(<a href=")((?:https?://|/)?([^/"]+)(?:/[^"]*)?)">!);
        $href =~ s!([\\\?\+\-\.()\[\]])!\\$1!sig;

        my $title;
        $title ||= $settings{pathmap}{$path}    if($settings{pathmap}{$path});
        $title ||= $settings{titlemap}{$link2}  if($settings{titlemap}{$link2});
        $title ||= "External Site: $link2";
        $text =~ s!$href!$link1$path" title="$title">!sgi;
    }

    return $text;
}

sub _buildtags {
    return %HTMLTAGS    if(%HTMLTAGS);

    if(defined $settings{htmltags} && $settings{htmltags} =~ /^\+(.*)/) {
        $settings{htmltags} = $1 . ',' . $DEFAULTTAGS;
    } elsif(!$settings{htmltags}) {
        $settings{htmltags} = $DEFAULTTAGS;
    }

    %HTMLTAGS = map {$_ => 1} split(",",$settings{htmltags});
    return %HTMLTAGS;
}

=head2 Drop Down Boxes

=over 4

=item DropDownList($opt,$name,@items)

Returns a dropdown selection box given a list of numbers. Can optionally pass
a option value to be pre-selected. The name of the form element is used as
both the element name and id.

=item DropDownListText($opt,$name,@items)

Returns a dropdown selection box given a list of strings. Can optionally pass
a option value to be pre-selected. The name of the form element is used as
both the element name and id.

=item DropDownRows($opt,$name,$index,$value,@items)

Returns a dropdown selection box given a list of rows. Can optionally pass
a option value to be pre-selected. The name of the form element is used as
both the element name and id. The 'index' and 'value' refence the field names
within each row hash.

=item DropDownRowsText($opt,$name,$index,$value,@items)

Returns a dropdown selection box given a list of strings. Can optionally pass
a option value to be pre-selected. The name of the form element is used as
both the element name and id. The 'index' and 'value' refence the field names
within each row hash.

=item DropDownMultiList($opts,$name,$count,@items)

Returns a dropdown multi-selection box given a list of strings. The name of the
form element is used as both the element name and id. The default number of
rows visible is 5, but this can be changed by providing a value for 'count'.

Can optionally pass an option value to be pre-selected. The option can be a
comma separated list (as a single string) of values or an arrayref to a list
of values.

=item DropDownMultiRows($opts,$name,$index,$value,$count,@items)

Returns a dropdown multi-selection box given a list of rows. The name of the
form element is used as both the element name and id. The default number of
rows visible is 5, but this can be changed by providing a value for 'count'.
The 'index' and 'value' refence the field names within each row hash.

Can optionally pass an option value to be pre-selected. The option can be a
comma separated list (as a single string) of values or an arrayref to a list
of values.

=back

=cut

sub DropDownList {
    my ($opt,$name,@items) = @_;
	$opt = undef	if(defined $opt && $opt !~ /^\d+$/);	# opt must be a number

    return  qq|<select id="$name" name="$name">| .
            join("",(map { qq|<option value="$_"|.
                    (defined $opt && $opt == $_ ? ' selected="selected"' : '').
                    ">$_</option>" } @items)) .
            "</select>";
}

sub DropDownListText {
    my ($opt,$name,@items) = @_;

    return  qq|<select id="$name" name="$name">| .
            join("",(map { qq|<option value="$_"|.
                    (defined $opt && $opt eq $_ ? ' selected="selected"' : '').
                    ">$_</option>" } @items)) .
            "</select>";
}

sub DropDownRows {
    my ($opt,$name,$index,$value,@items) = @_;
	$opt = undef	if(defined $opt && $opt !~ /^\d+$/);	# opt must be a number

    return  qq|<select id="$name" name="$name">| .
            join("",(map { qq|<option value="$_->{$index}"|.
                    (defined $opt && $opt == $_->{$index} ? ' selected="selected"' : '').
                    ">$_->{$value}</option>" } @items)) .
            "</select>";
}

sub DropDownRowsText {
    my ($opt,$name,$index,$value,@items) = @_;

    return  qq|<select id="$name" name="$name">| .
            join("",(map { qq|<option value="$_->{$index}"|.
                    (defined $opt && $opt eq $_->{$index} ? ' selected="selected"' : '').
                    ">$_->{$value}</option>" } @items)) .
            "</select>";
}

sub DropDownMultiList {
    my ($opts,$name,$count,@items) = @_;
    my %opts;

    if(defined $opts) {
        if(ref($opts) eq 'ARRAY') {
            %opts = map {$_ => 1} @$opts;
        } elsif($opts =~ /,/) {
            %opts = map {$_ => 1} split(/,/,$opts);
        } elsif($opts) {
            %opts = ("$opts" => 1);
        }
    }

    return  qq|<select id="$name" name="$name" multiple="multiple" size="$count">| .
            join("",(map { qq|<option value="$_"|.
                    (defined $opts && $opts{$_} ? ' selected="selected"' : '').
                    ">$_</option>" } @items)) .
            "</select>";
}

sub DropDownMultiRows {
    my ($opts,$name,$index,$value,$count,@items) = @_;
    my %opts;

    if(defined $opts) {
        if(ref($opts) eq 'ARRAY') {
            %opts = map {$_ => 1} @$opts;
        } elsif($opts =~ /,/) {
            %opts = map {$_ => 1} split(/,/,$opts);
        } elsif($opts) {
            %opts = ("$opts" => 1);
        }
    }

    return  qq|<select id="$name" name="$name" multiple="multiple" size="$count">| .
            join("",(map { qq|<option value="$_->{$index}"|.
                    (defined $opts && $opts{$_->{$index}} ? ' selected="selected"' : '').
                    ">$_->{$value}</option>" } @items)) .
            "</select>";
}

=head2 Error Functions

=over 4

=item ErrorText

Returns the given error string in a HTML span tag, with the configured error
class, which by default is called "alert". In your CSS sytle sheet you will 
need to specify an appropriate class declaration, such as:

  .alert { color: red; font-weight: bold; }

Set the value of 'errorclass' in your site config file to change the class
name used.

=item ErrorSymbol

Flags to the system that an error has occured and returns the configured error
symbol, which by is the 'empty' symbol '&#8709;', which can then be used as the
error field indicator.

Set the value of 'errorsymbol' in your site config file to change the symbol
used.

=back

=cut

sub ErrorText {
    my $text = shift;
    $settings{errorclass} ||= 'alert';
    return qq!<span class="$settings{errorclass}">$text</span>!;
}

sub ErrorSymbol {
    $tvars{errmess} = 1;
    $tvars{errcode} = 'ERROR';
    return $settings{errorsymbol} || '&#8709;';
}

=head2 Protection Functions

=over 4

=item LinkSpam

Checks whether any links exist in the given text that could indicate comment spam.

=back

=cut

sub LinkSpam {
    my $text = shift;
    return 1   if($text =~ m!https?://[^\s]*!is);
    return 1   if($text =~ m!<a.*?/a>!is);
    return 1   if($text =~ m!\[url.*?url\]!is);
    return 1   if($text =~ m!\[link.*?link\]!is);
    return 1   if($text =~ m!$settings{urlregex}!is);
    return 0;
}

=head2 CSS Handling Code

=over 4

=item create_inline_styles ( HASHREF )

Create inline CSS style sheet block. Key value pairs should match the label
(tag, identifier or class patterns) and its contents. For example:

  my %css = ( '#label p' => 'font-weight: normal; color: #fff;' );

or

  my %css = ( '#label p' => { 'font-weight' => 'normal', 'color' => '#fff' } );


The exception to this is the label 'media', which can be used to specify the
medium for which the CSS will be used. Typically these are 'screen' or 'print'.

=back

=cut

sub create_inline_styles {
    my $hash = shift || return;
    my $media = $hash->{media} ? ' media="' . $hash->{media} . '"' : '';

    my $text = qq|<style type="text/css"$media>\n|;
    for my $key (sort keys %$hash) {
        next    if($key eq 'media');
        $text .= qq|$key {|;
        if(ref($hash->{$key}) eq 'HASH') {
            for my $attr (keys %{$hash->{$key}}) {
                $text .= qq| $attr: $hash->{$key}->{$attr};|
            }
        } elsif(ref($hash->{$key}) eq 'ARRAY') {
            $text .= ' ' . join(',', @{$hash->{$key}});
        } else {     
            $text .= qq| $hash->{$key}|;
        }
        $text .= qq| }\n|;
    }
    $text .= qq|</style>\n|;
    return $text;
}

=head2 HTML Demoroniser Code

=over 4

=item demoroniser ( INPUT )

Given a string, will replace the Microsoft "smart" characters with sensible
ACSII versions.

=back

=cut

sub demoroniser {
	my $str	= shift;

	zap_cp1252($str);

	$str =~ s/\xE2\x80\x9A/,/g;		# 82
	$str =~ s/\xE2\x80\x9E/,,/g;	# 84
	$str =~ s/\xE2\x80\xA6/.../g;	# 85

	$str =~ s/\xCB\x86/^/g;			# 88

	$str =~ s/\xE2\x80\x98/`/g;		# 91
	$str =~ s/\xE2\x80\x99/'/g;		# 92
	$str =~ s/\xE2\x80\x9C/"/g;		# 93
	$str =~ s/\xE2\x80\x9D/"/g;		# 94
	$str =~ s/\xE2\x80\xA2/*/g;		# 95
	$str =~ s/\xE2\x80\x93/-/g;		# 96
	$str =~ s/\xE2\x80\x94/-/g;		# 97

	$str =~ s/\xE2\x80\xB9/</g;		# 8B
	$str =~ s/\xE2\x80\xBA/>/g;		# 9B

	return $str;
}

=head2 HTML Handling Code

The following functions disassemble and reassemble the HTML code snippets, 
validating and cleaning the code to fix any errors that may exist between the
template and content of the database.

=over 4

=item process_html ( INPUT [,LINE_BREAKS [,ALLOW]] )

=item escape_html ( INPUT )

=item unescape_html ( INPUT )

=item cleanup_attr_style

=item cleanup_attr_number

=item cleanup_attr_multilength

=item cleanup_attr_text

=item cleanup_attr_length

=item cleanup_attr_color

=item cleanup_attr_uri

=item cleanup_attr_tframe

=item cleanup_attr_trules

=item cleanup_html

=item cleanup_tag

=item cleanup_close

=item cleanup_cdata

=item cleanup_no_number

=item check_url_valid

=item cleanup_attr_inputtype

=item cleanup_attr_method

=item cleanup_attr_scriptlang

=item cleanup_attr_scripttype

=item strip_nonprintable

=back

=cut

# Configuration
my $allow_html  = 0;
my $line_breaks = 1;
# End configuration

##################################################################
#
# HTML handling code
#
# The code below provides some functions for manipulating HTML.
#
#  process_html ( INPUT [,LINE_BREAKS [,ALLOW]] )
#
#    Returns a modified version of the HTML string INPUT, with
#    any potentially malicious HTML constructs (such as java,
#    javascript and IMG tags) removed.
#
#    If the LINE_BREAKS parameter is present and true then
#    line breaks in the input will be converted to html <br />
#    tags in the output.
#
#    If the ALLOW parameter is present and true then most
#    harmless tags will be left in, otherwise all tags will be
#    removed.
#
#  escape_html ( INPUT )
#
#    Returns a copy of the string INPUT with any HTML
#    metacharacters replaced with character escapes.
#
#  unescape_html ( INPUT )
#
#    Returns a copy of the string INPUT with HTML character
#    entities converted to literal characters where possible.
#    Note that some entites have no 8-bit character equivalent,
#    see "http://www.w3.org/TR/xhtml1/DTD/xhtml-symbol.ent"
#    for some examples.  unescape_html() leaves these entities
#    in their encoded form.
#

use vars qw(%html_entities $html_safe_chars %escape_html_map $escape_html_map);
use vars qw(%safe_tags %safe_style %tag_is_empty %closetag_is_optional
            %closetag_is_dependent %force_closetag %transpose_tag 
            $convert_nl %auto_deinterleave $auto_deinterleave_pattern);

# check the validity of a URL.

sub process_html {
    my ($text, $line_breaks, $allow_html) = @_;

    # cleanup erroneous XHTML patterns
    if($text) {
        $text =~ s!</pre><pre>!<br />!gsi;
        $text =~ s!<ul>\s*<br />!<ul>!gsi;
        $text =~ s!<br />\s*</ul>!</ul>!gsi;
        $text =~ s!<ul>\s*</ul>!!gsi;
        $text =~ s!<ol>\s*</ol>!!gsi;
    }

    # clean text of any nasties
    #$text =~ s/[\x201A\x2018\x2019`]/&#39;/g;   # nasty single quotes
    #$text =~ s/[\x201E\x201C\x201D]/&quot;/g;   # nasty double quotes

    cleanup_html( $text, $line_breaks, ($allow_html ? \%safe_tags : {}));
}

BEGIN
{
    %html_entities = (
        'lt'     => '<',
        'gt'     => '>',
        'quot'   => '"',
        'amp'    => '&',

        'nbsp'   => "\240", 'iexcl'  => "\241",
        'cent'   => "\242", 'pound'  => "\243",
        'curren' => "\244", 'yen'    => "\245",
        'brvbar' => "\246", 'sect'   => "\247",
        'uml'    => "\250", 'copy'   => "\251",
        'ordf'   => "\252", 'laquo'  => "\253",
        'not'    => "\254", 'shy'    => "\255",
        'reg'    => "\256", 'macr'   => "\257",
        'deg'    => "\260", 'plusmn' => "\261",
        'sup2'   => "\262", 'sup3'   => "\263",
        'acute'  => "\264", 'micro'  => "\265",
        'para'   => "\266", 'middot' => "\267",
        'cedil'  => "\270", 'supl'   => "\271",
        'ordm'   => "\272", 'raquo'  => "\273",
        'frac14' => "\274", 'frac12' => "\275",
        'frac34' => "\276", 'iquest' => "\277",

        'Agrave' => "\300", 'Aacute' => "\301",
        'Acirc'  => "\302", 'Atilde' => "\303",
        'Auml'   => "\304", 'Aring'  => "\305",
        'AElig'  => "\306", 'Ccedil' => "\307",
        'Egrave' => "\310", 'Eacute' => "\311",
        'Ecirc'  => "\312", 'Euml'   => "\313",
        'Igrave' => "\314", 'Iacute' => "\315",
        'Icirc'  => "\316", 'Iuml'   => "\317",
        'ETH'    => "\320", 'Ntilde' => "\321",
        'Ograve' => "\322", 'Oacute' => "\323",
        'Ocirc'  => "\324", 'Otilde' => "\325",
        'Ouml'   => "\326", 'times'  => "\327",
        'Oslash' => "\330", 'Ugrave' => "\331",
        'Uacute' => "\332", 'Ucirc'  => "\333",
        'Uuml'   => "\334", 'Yacute' => "\335",
        'THORN'  => "\336", 'szlig'  => "\337",

        'agrave' => "\340", 'aacute' => "\341",
        'acirc'  => "\342", 'atilde' => "\343",
        'auml'   => "\344", 'aring'  => "\345",
        'aelig'  => "\346", 'ccedil' => "\347",
        'egrave' => "\350", 'eacute' => "\351",
        'ecirc'  => "\352", 'euml'   => "\353",
        'igrave' => "\354", 'iacute' => "\355",
        'icirc'  => "\356", 'iuml'   => "\357",
        'eth'    => "\360", 'ntilde' => "\361",
        'ograve' => "\362", 'oacute' => "\363",
        'ocirc'  => "\364", 'otilde' => "\365",
        'ouml'   => "\366", 'divide' => "\367",
        'oslash' => "\370", 'ugrave' => "\371",
        'uacute' => "\372", 'ucirc'  => "\373",
        'uuml'   => "\374", 'yacute' => "\375",
        'thorn'  => "\376", 'yuml'   => "\377",
    );

    #
    # Build a map for representing characters in HTML.
    #
    $html_safe_chars = '()[]{}/?.,\\|;:@#~=+-_*^%$! ' . "\'\r\n\t";
    $escape_html_map = qr{[\w\(\)\[\]\{\}\/\?\.\,\\\|;:\@#~=\+\-\*\^\%\$\!\s\']+};
    %escape_html_map =
        map {$_,$_} ( 'A'..'Z', 'a'..'z', '0'..'9',
        split(//, $html_safe_chars)
        );
    foreach my $ent (keys %html_entities) {
        $escape_html_map{$html_entities{$ent}} = "&$ent;";
    }
    foreach my $c (0..255) {
        unless ( exists $escape_html_map{chr $c} ) {
        $escape_html_map{chr $c} = sprintf '&#%d;', $c;
    }
}

#
# Tables for use by cleanup_html() (below).
#
# The main table is %safe_tags, which is a hash by tag name of
# all the tags that it's safe to leave in.  The value for each
# tag is another hash, and each key of that hash defines an
# attribute that the tag is allowed to have.
#
# The values in the tag attribute hash can be undef (for an
# attribute that takes no value, for example the nowrap
# attribute in the tag <td align="left" nowrap>) or they can
# be coderefs pointing to subs for cleaning up the attribute
# values.
#
# These subs will called with the attribute value in $_, and
# they can return either a cleaned attribute value or undef.
# If undef is returned then the attribute will be deleted
# from the tag.
#
# The list of tags and attributes was taken from
# "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"
#
# The %tag_is_empty table defines the set of tags that have
# no corresponding close tag.
#
# cleanup_html() moves close tags around to force all tags to
# be closed in the correct sequence.  For example, the text
# "<h1><i>foo</h1>bar</i>" will be converted to the text
# "<h1><i>foo</i></h1>bar".
#
# The %auto_deinterleave table defines the set of tags which
# should be automatically reopened if they're closed early
# in this way.  All the tags involved must be in
# %auto_deinterleave for the tag to be reopened.  For example,
# the text "<b>bb<i>bi</b>ii</i>" will be converted into the
# text "<b>bb<i>bi</i></b><i>ii</i>" rather than into the
# text "<b>bb<i>bi</i></b>ii", because *both* "b" and "i" are
# in %auto_deinterleave.
#
    %tag_is_empty = (
        'hr' => 1, 'link' => 1, 'param' => 1, 'img'      => 1,
        'br' => 1, 'area' => 1, 'input' => 1, 'basefont' => 1
    );
    %closetag_is_optional = ( );
    %closetag_is_dependent = ( );
    %force_closetag = (
        'pre'   => { 'p' => 1, 'h1' => 1, 'h2' => 1, 'h3' => 1, 'h4' => 1, 'h5' => 1, 'h6' => 1, 'pre' => 1, 'ul' => 1, 'ol' => 1 },
        'p'     => { 'p' => 1, 'h1' => 1, 'h2' => 1, 'h3' => 1, 'h4' => 1, 'h5' => 1, 'h6' => 1, 'pre' => 1, 'ul' => 1, 'ol' => 1 },
        'h1'    => { 'p' => 1, 'h1' => 1, 'h2' => 1, 'h3' => 1, 'h4' => 1, 'h5' => 1, 'h6' => 1, 'pre' => 1, 'ul' => 1, 'ol' => 1 },
        'h2'    => { 'p' => 1, 'h1' => 1, 'h2' => 1, 'h3' => 1, 'h4' => 1, 'h5' => 1, 'h6' => 1, 'pre' => 1, 'ul' => 1, 'ol' => 1 },
        'h3'    => { 'p' => 1, 'h1' => 1, 'h2' => 1, 'h3' => 1, 'h4' => 1, 'h5' => 1, 'h6' => 1, 'pre' => 1, 'ul' => 1, 'ol' => 1 },
        'h4'    => { 'p' => 1, 'h1' => 1, 'h2' => 1, 'h3' => 1, 'h4' => 1, 'h5' => 1, 'h6' => 1, 'pre' => 1, 'ul' => 1, 'ol' => 1 },
        'h5'    => { 'p' => 1, 'h1' => 1, 'h2' => 1, 'h3' => 1, 'h4' => 1, 'h5' => 1, 'h6' => 1, 'pre' => 1, 'ul' => 1, 'ol' => 1 },
        'h6'    => { 'p' => 1, 'h1' => 1, 'h2' => 1, 'h3' => 1, 'h4' => 1, 'h5' => 1, 'h6' => 1, 'pre' => 1, 'ul' => 1, 'ol' => 1 },
        'table' => { 'p' => 1, 'h1' => 1, 'h2' => 1, 'h3' => 1, 'h4' => 1, 'h5' => 1, 'h6' => 1, 'pre' => 1, 'ul' => 1, 'ol' => 1 },
        'ul'    => { 'p' => 1, 'h1' => 1, 'h2' => 1, 'h3' => 1, 'h4' => 1, 'h5' => 1, 'h6' => 1 },
        'ol'    => { 'p' => 1, 'h1' => 1, 'h2' => 1, 'h3' => 1, 'h4' => 1, 'h5' => 1, 'h6' => 1 },
        'li'    => { 'p' => 1, 'h1' => 1, 'h2' => 1, 'h3' => 1, 'h4' => 1, 'h5' => 1, 'h6' => 1, 'li' => 1 },
        'form'  => { 'p' => 1, 'h1' => 1, 'h2' => 1, 'h3' => 1, 'h4' => 1, 'h5' => 1, 'h6' => 1 },
    );
    %transpose_tag = ( 'b' => 'strong', 'u' => 'em' );
    %auto_deinterleave = map {$_,1} qw(
        tt i b big small u s strike font basefont
        em strong dfn code q sub sup samp kbd var
        cite abbr acronym span
    );
    $auto_deinterleave_pattern = join '|', keys %auto_deinterleave;
    my %attr = (
        'style'         => \&cleanup_attr_style,
        'name'          => \&cleanup_attr_text,
        'id'            => \&cleanup_attr_text,
        'class'         => \&cleanup_attr_text,
        'title'         => \&cleanup_attr_text,
        'onmouseover'   => \&cleanup_attr_text,
        'onmouseout'    => \&cleanup_attr_text,
        'onclick'       => \&cleanup_attr_text,
        'onfocus'       => \&cleanup_attr_text,
        'ondblclick'    => \&cleanup_attr_text,
    );
    my %font_attr = (
        %attr,
        size  => sub { /^([-+]?\d{1,3})$/    ? $1 : undef },
        face  => sub { /^([\w\-, ]{2,100})$/ ? $1 : undef },
        color => \&cleanup_attr_color,
    );
    my %insdel_attr = (
        %attr,
        'cite'     => \&cleanup_attr_uri,
        'datetime' => \&cleanup_attr_text,
    );
    my %texta_attr = (
        %attr,
        align => sub { s/middle/center/i;
            /^(left|center|right|justify)$/i ? lc $1 : undef
        },
    );
    my %cellha_attr = (
        align   => sub { s/middle/center/i;
            /^(left|center|right|justify|char)$/i
            ? lc $1 : undef
        },
        char    => sub { /^([\w\-])$/ ? $1 : undef },
        charoff => \&cleanup_attr_length,
    );
    my %cellva_attr = (
        valign => sub { s/center/middle/i;
            /^(top|middle|bottom|baseline)$/i ? lc $1 : undef
        },
    );
    my %cellhv_attr = ( %attr, %cellha_attr, %cellva_attr );
    my %col_attr = (
        %attr,
        width => \&cleanup_attr_multilength,
        span =>  \&cleanup_attr_number,
        %cellhv_attr,
    );
    my %thtd_attr = (
        %attr,
        abbr    => \&cleanup_attr_text,
        axis    => \&cleanup_attr_text,
        headers => \&cleanup_attr_text,
        scope   => sub { /^(row|col|rowgroup|colgroup)$/i ? lc $1 : undef },
        rowspan => \&cleanup_attr_number,
        colspan => \&cleanup_attr_number,
        %cellhv_attr,
        nowrap  => undef,
        bgcolor => \&cleanup_attr_color,
        width   => \&cleanup_attr_number,
        height  => \&cleanup_attr_number,
    );
    my $none = {};
    %safe_tags = (
        # FORM CONTROLS
        'form'       => { %attr,
                'method'    => \&cleanup_attr_method,
                'action'    => \&cleanup_attr_text,
                'enctype'   => \&cleanup_attr_text,
                'onsubmit'  => \&cleanup_attr_text,
        },
        'button'     => { %attr,
                'type'      => \&cleanup_attr_inputtype,
        },
        'input'      => { %attr,
                'type'      => \&cleanup_attr_inputtype,
                'size'      => \&cleanup_attr_number,
                'maxlength'	=> \&cleanup_attr_number,
                'value'     => \&cleanup_attr_text,
                'checked'   => \&cleanup_attr_text,
                'readonly'  => \&cleanup_attr_text,
                'disabled'  => \&cleanup_attr_text,
                'src'       => \&cleanup_attr_uri,
                'width'     => \&cleanup_attr_length,
                'height'    => \&cleanup_attr_length,
                'alt'       => \&cleanup_attr_text,
                'onchange'  => \&cleanup_attr_text,
        },
        'select'     => { %attr,
                'size'      => \&cleanup_attr_number,
                'title'     => \&cleanup_attr_text,
                'value'     => \&cleanup_attr_text,
                'multiple'  => \&cleanup_attr_text,
                'disabled'  => \&cleanup_attr_text,
                'onchange'  => \&cleanup_attr_text,
        },
        'option'     => { %attr,
                'value'     => \&cleanup_attr_text,
                'selected'  => \&cleanup_attr_text,
        },
        'textarea'   => { %attr,
                'rows'      => \&cleanup_attr_number,
                'cols'      => \&cleanup_attr_number,
        },
        'label'      => { %attr,
                'for'       => \&cleanup_attr_text,
        },

        # LAYOUT STYLE
        'style'     => {
                'type'      => \&cleanup_attr_text,
        },
        'br'         => { 'clear' => sub { /^(left|right|all|none)$/i ? lc $1 : undef }
        },
        'hr'         => \%attr,
        'em'         => \%attr,
        'strong'     => \%attr,
        'dfn'        => \%attr,
        'code'       => \%attr,
        'samp'       => \%attr,
        'kbd'        => \%attr,
        'var'        => \%attr,
        'cite'       => \%attr,
        'abbr'       => \%attr,
        'acronym'    => \%attr,
        'q'          => { %attr, 'cite' => \&cleanup_attr_uri },
        'blockquote' => { %attr, 'cite' => \&cleanup_attr_uri },
        'sub'        => \%attr,
        'sup'        => \%attr,
        'tt'         => \%attr,
        'i'          => \%attr,
        'b'          => \%attr,
        'big'        => \%attr,
        'small'      => \%attr,
        'u'          => \%attr,
        's'          => \%attr,
        'font'       => \%font_attr,
        'h1'         => \%texta_attr,
        'h2'         => \%texta_attr,
        'h3'         => \%texta_attr,
        'h4'         => \%texta_attr,
        'h5'         => \%texta_attr,
        'h6'         => \%texta_attr,
        'p'          => \%texta_attr,
        'div'        => \%texta_attr,
        'span'       => \%texta_attr,
        'ul'         => { %attr,
                'type'    => sub { /^(disc|square|circle)$/i ? lc $1 : undef },
                'compact' => undef,
        },
        'ol'         => { %attr,
                'type'    => \&cleanup_attr_text,
                'compact' => undef,
                'start'   => \&cleanup_attr_number,
        },
        'li'         => { %attr,
                'type'  => \&cleanup_attr_text,
                'value' => \&cleanup_no_number,
        },
        'dl'         => { %attr, 'compact' => undef },
        'dt'         => \%attr,
        'dd'         => \%attr,
        'address'    => \%attr,
        'pre'        => { %attr, 'width' => \&cleanup_attr_number },
        'center'     => \%attr,
        'nobr'       => $none,

        # FUNCTIONAL TAGS
        'iframe'     => { %attr,
                'src'       => \&cleanup_attr_uri,
                'width'     => \&cleanup_attr_length,
                'height'    => \&cleanup_attr_length,
                'border'    => \&cleanup_attr_number,
                'alt'       => \&cleanup_attr_text,
                'align'     => sub { s/middle/center/i;
                                    /^(left|center|right)$/i ? lc $1 : undef
                },
                'title'     => \&cleanup_attr_text,
        },
        'img'        => { %attr,
                'src'       => \&cleanup_attr_uri,
                'width'     => \&cleanup_attr_length,
                'height'    => \&cleanup_attr_length,
                'border'    => \&cleanup_attr_number,
                'alt'       => \&cleanup_attr_text,
                'align'     => sub { s/middle/center/i;
                                    /^(left|center|right)$/i ? lc $1 : undef
                },
                'title'     => \&cleanup_attr_text,
                'usemap'    => \&cleanup_attr_text,
        },
        'map'        => { %attr,
        },
        'area'       => { %attr,
                'shape'     => \&cleanup_attr_text,
                'coords'    => \&cleanup_attr_text,
                'href'      => \&cleanup_attr_uri,
        },
        'table'      => { %attr,
                'frame'       => \&cleanup_attr_tframe,
                'rules'       => \&cleanup_attr_trules,
                %texta_attr,
                'bgcolor'     => \&cleanup_attr_color,
                'width'       => \&cleanup_attr_length,
                'cellspacing' => \&cleanup_attr_length,
                'cellpadding' => \&cleanup_attr_length,
                'border'      => \&cleanup_attr_number,
                'summary'     => \&cleanup_attr_text,
        },
        'caption'    => { %attr,
                'align' => sub { /^(top|bottom|left|right)$/i ? lc $1 : undef },
        },
        'colgroup'   => \%col_attr,
        'col'        => \%col_attr,
        'thead'      => \%cellhv_attr,
        'tfoot'      => \%cellhv_attr,
        'tbody'      => \%cellhv_attr,
        'tr'         => { %attr,
                bgcolor => \&cleanup_attr_color,
                %cellhv_attr,
        },
        'th'         => \%thtd_attr,
        'td'         => \%thtd_attr,
        'ins'        => \%insdel_attr,
        'del'        => \%insdel_attr,
        'a'          => { %attr,
                href    => \&cleanup_attr_uri,
                style   => \&cleanup_attr_text,
                target  => \&cleanup_attr_text,
                rel     => \&cleanup_attr_text,
        },

        'script'     => {
                language => \&cleanup_attr_scriptlang,
                type     => \&cleanup_attr_scripttype,
                src      => \&cleanup_attr_uri,
        },
        'noscript'   => { %attr,
        },
        'link'       => { %attr,
                href        => \&cleanup_attr_uri,
                'rel'       => \&cleanup_attr_text,
                'type'      => \&cleanup_attr_text,
                'media'     => \&cleanup_attr_text,
        },
        'object'     => { %attr,
                'width'     => \&cleanup_attr_length,
                'height'    => \&cleanup_attr_length,
                style       => \&cleanup_attr_text,
                type        => \&cleanup_attr_text,
                data        => \&cleanup_attr_text,
                classid     => \&cleanup_attr_text,
                codebase    => \&cleanup_attr_text,
        },
        'param'     => {
                name    => \&cleanup_attr_text,
                value   => \&cleanup_attr_text,
        },
        'embed'     => { %attr,
                'src'               => \&cleanup_attr_uri,
                'bgcolor'           => \&cleanup_attr_color,
                'width'             => \&cleanup_attr_length,
                'height'            => \&cleanup_attr_length,
                'pluginspage'       => \&cleanup_attr_uri,
                flashvars           => \&cleanup_attr_text,
                type                => \&cleanup_attr_text,
                quality             => \&cleanup_attr_text,
                allowScriptAccess   => \&cleanup_attr_text,
                allowNetworking     => \&cleanup_attr_text,
        },
    );

    %safe_style = (
        'animation'                     => \&cleanup_attr_text,
        'animation-name'                => \&cleanup_attr_text,
        'animation-duration'            => \&cleanup_attr_text,
        'animation-timing-function'     => \&cleanup_attr_text,
        'animation-delay'               => \&cleanup_attr_text,
        'animation-iteration-count'     => \&cleanup_attr_text,
        'animation-direction'           => \&cleanup_attr_text,
        'animation-play-state'          => \&cleanup_attr_text,
        'appearance'                    => \&cleanup_attr_text,
        'backface-visibility'           => \&cleanup_attr_text,
        'background'                    => \&cleanup_attr_text,
        'background-attachment'         => \&cleanup_attr_text,
        'background-color'              => \&cleanup_attr_color,
        'background-image'              => \&cleanup_attr_text,
        'background-position'           => \&cleanup_attr_text,
        'background-repeat'             => \&cleanup_attr_text,
        'background-clip'               => \&cleanup_attr_text,
        'background-origin'             => \&cleanup_attr_text,
        'background-size'               => \&cleanup_attr_text,
        'border'                        => \&cleanup_attr_text,
        'border-bottom'                 => \&cleanup_attr_text,
        'border-bottom-color'           => \&cleanup_attr_color,
        'border-bottom-style'           => \&cleanup_attr_text,
        'border-bottom-width'           => \&cleanup_attr_length,
        'border-collapse'               => \&cleanup_attr_text,
        'border-color'                  => \&cleanup_attr_color,
        'border-left'                   => \&cleanup_attr_text,
        'border-left-color'             => \&cleanup_attr_color,
        'border-left-style'             => \&cleanup_attr_text,
        'border-left-width'             => \&cleanup_attr_length,
        'border-right'                  => \&cleanup_attr_text,
        'border-right-color'            => \&cleanup_attr_color,
        'border-right-style'            => \&cleanup_attr_text,
        'border-right-width'            => \&cleanup_attr_length,
        'border-spacing'                => \&cleanup_attr_text,
        'border-style'                  => \&cleanup_attr_text,
        'border-top'                    => \&cleanup_attr_text,
        'border-top-color'              => \&cleanup_attr_color,
        'border-top-style'              => \&cleanup_attr_text,
        'border-top-width'              => \&cleanup_attr_length,
        'border-width'                  => \&cleanup_attr_length,
        'border-bottom-left-radius'     => \&cleanup_attr_text,
        'border-bottom-right-radius'    => \&cleanup_attr_text,
        'border-image'                  => \&cleanup_attr_text,
        'border-image-outset'           => \&cleanup_attr_text,
        'border-image-repeat'           => \&cleanup_attr_text,
        'border-image-slice'            => \&cleanup_attr_text,
        'border-image-source'           => \&cleanup_attr_text,
        'border-image-width'            => \&cleanup_attr_length,
        'border-radius'                 => \&cleanup_attr_text,
        'border-top-left-radius'        => \&cleanup_attr_text,
        'border-top-right-radius'       => \&cleanup_attr_text,
        'bottom'                        => \&cleanup_attr_text,
        'box'                           => \&cleanup_attr_text,
        'box-align'                     => \&cleanup_attr_text,
        'box-direction'                 => \&cleanup_attr_text,
        'box-flex'                      => \&cleanup_attr_text,
        'box-flex-group'                => \&cleanup_attr_text,
        'box-lines'                     => \&cleanup_attr_text,
        'box-ordinal-group'             => \&cleanup_attr_text,
        'box-orient'                    => \&cleanup_attr_text,
        'box-pack'                      => \&cleanup_attr_text,
        'box-sizing'                    => \&cleanup_attr_text,
        'box-shadow'                    => \&cleanup_attr_text,
        'caption-side'                  => \&cleanup_attr_text,
        'clear'                         => \&cleanup_attr_text,
        'clip'                          => \&cleanup_attr_text,
        'color'                         => \&cleanup_attr_color,
        'column'                        => \&cleanup_attr_text,
        'column-count'                  => \&cleanup_attr_text,
        'column-fill'                   => \&cleanup_attr_text,
        'column-gap'                    => \&cleanup_attr_text,
        'column-rule'                   => \&cleanup_attr_text,
        'column-rule-color'             => \&cleanup_attr_text,
        'column-rule-style'             => \&cleanup_attr_text,
        'column-rule-width'             => \&cleanup_attr_length,
        'column-span'                   => \&cleanup_attr_text,
        'column-width'                  => \&cleanup_attr_length,
        'columns'                       => \&cleanup_attr_text,
        'content'                       => \&cleanup_attr_text,
        'counter-increment'             => \&cleanup_attr_text,
        'counter-reset'                 => \&cleanup_attr_text,
        'cursor'                        => \&cleanup_attr_text,
        'direction'                     => \&cleanup_attr_text,
        'display'                       => \&cleanup_attr_text,
        'empty-cells'                   => \&cleanup_attr_text,
        'float'                         => \&cleanup_attr_text,
        'font'                          => \&cleanup_attr_text,
        'font-family'                   => \&cleanup_attr_text,
        'font-size'                     => \&cleanup_attr_text,
        'font-style'                    => \&cleanup_attr_text,
        'font-variant'                  => \&cleanup_attr_text,
        'font-weight'                   => \&cleanup_attr_length,
        '@font-face'                    => \&cleanup_attr_text,
        'font-size-adjust'              => \&cleanup_attr_text,
        'font-stretch'                  => \&cleanup_attr_text,
        'grid-columns'                  => \&cleanup_attr_text,
        'grid-rows'                     => \&cleanup_attr_text,
        'hanging-punctuation'           => \&cleanup_attr_text,
        'height'                        => \&cleanup_attr_length,
        'icon'                          => \&cleanup_attr_text,
        '@keyframes'                    => \&cleanup_attr_text,
        'left'                          => \&cleanup_attr_length,
        'letter-spacing'                => \&cleanup_attr_text,
        'line-height'                   => \&cleanup_attr_text,
        'list-style'                    => \&cleanup_attr_text,
        'list-style-image'              => \&cleanup_attr_text,
        'list-style-position'           => \&cleanup_attr_text,
        'list-style-type'               => \&cleanup_attr_text,
        'margin'                        => \&cleanup_attr_text,
        'margin-bottom'                 => \&cleanup_attr_length,
        'margin-left'                   => \&cleanup_attr_length,
        'margin-right'                  => \&cleanup_attr_length,
        'margin-top'                    => \&cleanup_attr_length,
        'max-height'                    => \&cleanup_attr_length,
        'max-width'                     => \&cleanup_attr_length,
        'min-height'                    => \&cleanup_attr_length,
        'min-width'                     => \&cleanup_attr_length,
        'nav'                           => \&cleanup_attr_text,
        'nav-down'                      => \&cleanup_attr_text,
        'nav-index'                     => \&cleanup_attr_text,
        'nav-left'                      => \&cleanup_attr_text,
        'nav-right'                     => \&cleanup_attr_text,
        'nav-up'                        => \&cleanup_attr_text,
        'opacity'                       => \&cleanup_attr_text,
        'outline'                       => \&cleanup_attr_text,
        'outline-color'                 => \&cleanup_attr_color,
        'outline-offset'                => \&cleanup_attr_text,
        'outline-style'                 => \&cleanup_attr_text,
        'outline-width'                 => \&cleanup_attr_length,
        'overflow'                      => \&cleanup_attr_text,
        'overflow-x'                    => \&cleanup_attr_text,
        'overflow-y'                    => \&cleanup_attr_text,
        'padding'                       => \&cleanup_attr_text,
        'padding-bottom'                => \&cleanup_attr_length,
        'padding-left'                  => \&cleanup_attr_length,
        'padding-right'                 => \&cleanup_attr_length,
        'padding-top'                   => \&cleanup_attr_length,
        'page-break'                    => \&cleanup_attr_text,
        'page-break-after'              => \&cleanup_attr_text,
        'page-break-before'             => \&cleanup_attr_text,
        'page-break-inside'             => \&cleanup_attr_text,
        'perspective'                   => \&cleanup_attr_text,
        'perspective-origin'            => \&cleanup_attr_text,
        'position'                      => \&cleanup_attr_text,
        'punctuation-trim'              => \&cleanup_attr_text,
        'quotes'                        => \&cleanup_attr_text,
        'resize'                        => \&cleanup_attr_text,
        'right'                         => \&cleanup_attr_length,
        'rotation'                      => \&cleanup_attr_text,
        'rotation-point'                => \&cleanup_attr_text,
        'table-layout'                  => \&cleanup_attr_text,
        'target'                        => \&cleanup_attr_text,
        'target-name'                   => \&cleanup_attr_text,
        'target-new'                    => \&cleanup_attr_text,
        'target-position'               => \&cleanup_attr_text,
        'text'                          => \&cleanup_attr_text,
        'text-align'                    => \&cleanup_attr_text,
        'text-decoration'               => \&cleanup_attr_text,
        'text-indent'                   => \&cleanup_attr_text,
        'text-justify'                  => \&cleanup_attr_text,
        'text-outline'                  => \&cleanup_attr_text,
        'text-overflow'                 => \&cleanup_attr_text,
        'text-shadow'                   => \&cleanup_attr_text,
        'text-transform'                => \&cleanup_attr_text,
        'text-wrap'                     => \&cleanup_attr_text,
        'top'                           => \&cleanup_attr_length,
        'transform'                     => \&cleanup_attr_text,
        'transform-origin'              => \&cleanup_attr_text,
        'transform-style'               => \&cleanup_attr_text,
        'transition'                    => \&cleanup_attr_text,
        'transition-property'           => \&cleanup_attr_text,
        'transition-duration'           => \&cleanup_attr_text,
        'transition-timing-function'    => \&cleanup_attr_text,
        'transition-delay'              => \&cleanup_attr_text,
        'vertical-align'                => \&cleanup_attr_text,
        'visibility'                    => \&cleanup_attr_text,
        'width'                         => \&cleanup_attr_length,
        'white-space'                   => \&cleanup_attr_text,
        'word-spacing'                  => \&cleanup_attr_text,
        'word-break'                    => \&cleanup_attr_text,
        'word-wrap'                     => \&cleanup_attr_text,
        'z-index'                       => \&cleanup_attr_text
    );
}


sub cleanup_attr_style {
    my @clean = ();
    foreach my $elt (split /;/, $_) {
        next if $elt =~ m#^\s*$#;
        if ( $elt =~ m#^\s*([\w\-]+)\s*:\s*(.+?)\s*$#s ) {
            my ($key, $val) = (lc $1, $2);
            local $_ = $val;
            my $sub = $safe_style{$key};
            if (defined $sub) {
                my $cleanval = &{$sub}();
                if (defined $cleanval) {
                    push @clean, "$key:$val";
                }
            }
        }
    }
    return join '; ', @clean;
}
sub cleanup_attr_number {
    /^(\d+)$/ ? $1 : undef;
}
sub cleanup_attr_method {
    /^(get|post)$/i ? lc $1 : 'post';
}
sub cleanup_attr_inputtype {
    /^(text|password|checkbox|radio|submit|reset|file|hidden|image|button)$/i ? lc $1 : undef;
}
sub cleanup_attr_multilength {
    /^(\d+(?:\.\d+)?[*%]?)$/ ? $1 : undef;
}
sub cleanup_attr_text {
    tr/-a-zA-Z0-9_()[]{}\/?.,\\|;:&@#~=+*^%$'! \xc0-\xff//dc;
    $_;
}
sub cleanup_attr_length {
    /^(\d+(\%|px|em)?)$/ ? $1 : undef;
}
sub cleanup_attr_color {
    /^(\w{2,20}|#[\da-fA-F]{3}|#[\da-fA-F]{6})$/ or die "color <<$_>> bad";
    /^(\w{2,20}|#[\da-fA-F]{3}|#[\da-fA-F]{6})$/ ? $1 : undef;
}
sub cleanup_attr_uri {
    check_url_valid($_) ? $_ : undef;
}
sub cleanup_attr_tframe {
    /^(void|above|below|hsides|lhs|rhs|vsides|box|border)$/i
    ? lc $1 : undef;
}
sub cleanup_attr_trules {
    /^(none|groups|rows|cols|all)$/i ? lc $1 : undef;
}

sub cleanup_attr_scriptlang {
    /^(javascript)$/i ? lc $1 : undef;
}
sub cleanup_attr_scripttype {
    /^(text\/javascript)$/i ? lc $1 : undef;
}

use vars qw(@stack $safe_tags $convert_nl);
sub cleanup_html {
    local ($_, $convert_nl, $safe_tags) = @_;
    local @stack = ();

    return ''   unless($_);

    my $ignore_comments = 0;
    if($ignore_comments) {
        s[
            (?: <!--.*?-->                                   ) |
            (?: <[?!].*?>                                    ) |
            (?: <([a-z0-9]+)\b((?:[^>'"]|"[^"]*"|'[^']*')*)> ) |
            (?: </([a-z0-9]+)>                               ) |
            (?: (.[^<]*)                                     )
        ][
            defined $1 ? cleanup_tag(lc $1, $2)              :
            defined $3 ? cleanup_close(lc $3)                :
            defined $4 ? cleanup_cdata($4)                   :
            ''
        ]igesx;
    } else {
        s[
            (?: (<!--.if.*?endif.-->)                        ) |
            (?: <!--.*?-->                                   ) |
            (?: <[?!].*?>                                    ) |
            (?: <([a-z0-9]+)\b((?:[^>'"]|"[^"]*"|'[^']*')*)> ) |
            (?: </([a-z0-9]+)>                               ) |
            (?: (.[^<]*)                                     )
        ][
            defined $1 ? $1                                  :
            defined $2 ? cleanup_tag(lc $2, $3)              :
            defined $4 ? cleanup_close(lc $4)                :
            defined $5 ? cleanup_cdata($5)                   :
            ''
        ]igesx;
    }

    # Close anything that was left open
    $_ .= join '', map "</$_->{NAME}>", @stack;

    # Where we turned <i><b>foo</i></b> into <i><b>foo</b></i><b></b>,
    # take out the pointless <b></b>.
    1 while s#<($auto_deinterleave_pattern)\b[^>]*>(&nbsp;|\s)*</\1>##go;

    # cleanup p elements
    s!\s+</p>!</p>!g;
    s!<p></p>!!g;

    # Element pre is not declared in p list of possible children
    s!<p>\s*(<pre>.*?</pre>)\s*</p>!$1!g;

    return $_;
}

sub cleanup_tag {
    my ($tag, $attrs) = @_;
    unless (exists $safe_tags->{$tag}) {
        return '';
    }

    # for XHTML conformity
    $tag = $transpose_tag{$tag} if($transpose_tag{$tag});

    my $html = '';
    if($force_closetag{$tag}) {
        while (scalar @stack and $force_closetag{$tag}{$stack[0]{NAME}}) {
            $html = cleanup_close($stack[0]{NAME});
        }
    }

    my $t = $safe_tags->{$tag};
    my $safe_attrs = '';
    while ($attrs =~ s#^\s*(\w+)(?:\s*=\s*(?:([^"'>\s]+)|"([^"]*)"|'([^']*)'))?##) {
        my $attr = lc $1;
        my $val = ( defined $2 ? $2                :
                    defined $3 ? unescape_html($3) :
                    defined $4 ? unescape_html($4) :
                    '$attr'
        );
        unless (exists $t->{$attr}) {
            next;
        }
        if (defined $t->{$attr}) {
            local $_ = $val;
            my $cleaned = &{ $t->{$attr} }();
            if (defined $cleaned) {
                $safe_attrs .= qq| $attr="${\( escape_html($cleaned) )}"|;
            }
        } else {
            $safe_attrs .= " $attr";
        }
    }

    my $str;
    if (exists $tag_is_empty{$tag}) {
        $str = "$html<$tag$safe_attrs />";
    } elsif (exists $closetag_is_optional{$tag}) {
        $str = "$html<$tag$safe_attrs>";
#   } elsif (exists $closetag_is_dependent{$tag} && $safe_attrs =~ /$closetag_is_dependent{$tag}=/) {
#       return "$html<$tag$safe_attrs />";
    } else {
        my $full = "<$tag$safe_attrs>";
        unshift @stack, { NAME => $tag, FULL => $full };
        $str = "$html$full";
    }
#LogDebug("cleanup_tag: str=$str");
    return $str;
}

sub cleanup_close {
    my $tag = shift;

    # for XHTML conformity
    $tag = $transpose_tag{$tag} if($transpose_tag{$tag});

    # Ignore a close without an open
    unless (grep {$_->{NAME} eq $tag} @stack) {
        return '';
    }

    # Close open tags up to the matching open
    my @close = ();
    while (scalar @stack and $stack[0]{NAME} ne $tag) {
        push @close, shift @stack;
    }
    push @close, shift @stack;

    my $html = join '', map {"</$_->{NAME}>"} @close;

    # Reopen any we closed early if all that were closed are
    # configured to be auto deinterleaved.
    unless (grep {! exists $auto_deinterleave{$_->{NAME}} } @close) {
        pop @close;
        $html .= join '', map {$_->{FULL}} reverse @close;
        unshift @stack, @close;
    }

    return $html;
}

sub cleanup_cdata {
    local $_ = shift;

    return $_   if(scalar @stack and $stack[0]{NAME} eq 'script');

    s[ (?: & ( 
        [a-zA-Z0-9]{2,15}       |
        [#][0-9]{2,6}           |
        [#][xX][a-fA-F0-9]{2,6} | ) \b ;?
        ) | ($escape_html_map) | (.)
    ][
        defined $1 ? "&$1;" : defined $2 ? $2 : $3
    ]gesx;

    # substitute newlines in the input for html line breaks if required.
    s%\cM?\n%<br />\n%g if $convert_nl;

    return $_;
}

# subroutine to escape the necessary characters to the appropriate HTML
# entities

sub escape_html {
    my $str = shift or return '';
    $str = encode_entities($str);
    $str =~ s/&amp;(#x?\d+;)/&$1/g;  # avoid double encoding of hex/dec characters
    return $str;
}

# subroutine to unescape escaped HTML entities.  Note that some entites
# have no 8-bit character equivalent, see
# "http://www.w3.org/TR/xhtml1/DTD/xhtml-symbol.ent" for some examples.
# unescape_html() leaves these entities in their encoded form.

sub unescape_html {
    my $str = shift or return '';
    $str = decode_entities($str);
    return strip_nonprintable($str);
}

sub check_url_valid {
  my $url = shift;

  $url = "$tvars{cgipath}/$tvars{script}$url"    if($url =~ /^\?/);

  # allow in page URLs
  return 1 if $url =~ m!^\#!;

  # allow relative URLs with sane values
  return 1 if $url =~ m!^[a-z0-9_\-\.\,\+\/#]+$!i;

  # allow mailto email addresses
  return 1 if $url =~ m#mailto:([-+=\w\'.\&\\//]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([a-zA-Z0-9\-]+\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)#i;

  # allow javascript calls
  return 1 if $url =~ m#^javascript:#i;

#  $url =~ m< ^ ((?:ftp|http|https):// [\w\-\.]+ (?:\:\d+)?)?
#               (?: /? [\w\-.!~*'(|);/\@+\$,%#]*   )?
#               (?: \? [\w\-.!~*'(|);/\@&=+\$,%#]* )?
#             $
#           >x ? 1 : 0;
  return $url =~ m< ^ $settings{urlregex} $ >x ? 1 : 0;
}

sub strip_nonprintable {
  my $text = shift;
  return '' unless defined $text;

  $text=~ tr#\t\n\040-\176\241-\377# #cs;
  return $text;
}

#
# End of HTML handling code
#
##################################################################

1;

__END__

=head1 SEE ALSO

  Labyrinth

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
