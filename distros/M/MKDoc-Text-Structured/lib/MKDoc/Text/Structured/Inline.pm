package MKDoc::Text::Structured::Inline;
use URI::Find;
use warnings;
use strict;

our $Text    = '';

our $LongestWord = 78;
our $NoFollow = 0;

=head1 NAME

MKDoc::Text::Structured::Inline - convert text to HTML without handling block-level tags

=head1 SYNOPSIS

  my $text = some_structured_text();
  my $this = MKDoc::Text::Structured::Inline::process ($text);
  my $that = MKDoc::Text::Structured::Inline::process_entities_only ($text);

=head1 SUMMARY

L<MKDoc::Text::Structured::Inline> is used by L<MKDoc::Text::Structured> to
generate inline HTML elements such as hyperlinks, emphasis and entities.

This module is also useful directly when the full block-level rendering of
L<MKDoc::Text::Structured> is unwanted.

=head1 USAGE

=head2 Processing text and adding HTML tags

For example, when processing text that is going to end up in an <h1> header,
you wouldn't want any block level tags generated:

  $header = "< My (c) symbol should be *bold* > -- and http://example.com/ 'linked'";
  $header = MKDoc::Text::Structured::Inline::process ($title);

$header is now:

  &lt; My &copy; symbol should be <strong>bold</strong> &gt; &mdash; and <a href="http://example.com/">http://example.com/<a> &lsquo;linked&rsquo;

=cut

sub process
{
    local $Text;
    $Text = shift;
    $Text   =  " $Text ";
    $Text   =~ s/\n/ /gsm;

    _make_entities();

    $Text =~ s/&gt;/ &gt;/g;
    # automagically finds hyperlinks
    my $finder = URI::Find->new (
        sub {
            my ($uri, $orig_uri) = @_;
            $orig_uri =~ s/^mailto://;

            # http://googleblog.blogspot.com/2005/01/preventing-comment-spam.html
            if ($NoFollow)
            {
                return qq|<a href="$uri" rel="nofollow">$orig_uri</a>|;
            }
            else
            {
                return qq|<a href="$uri">$orig_uri</a>|;
            }
        }
    );
    $finder->find (\$Text);
    $Text =~ s/ &gt;/&gt;/g;

    # abbreviations
    while ($Text =~ s/([[:upper:]][[:upper:]]+)\s+(\(.*?\))/_make_abbr_implicit ($1, $2)/e) {}; # implicit
    while ($Text =~ s/([[:upper:]][[:upper:]]+)(\(.*?\))/_make_abbr_explicit ($1, $2)/e)    {}; # explicit
    _make_simplequotes();
    _make_doublequotes();
    _make_strong();
    _make_em();
    _make_smilies();
    _break_long_words();

    $Text =~ s/^ //;
    $Text =~ s/ $//;
    return $Text;
}

=pod

=head2 Processing text without adding tags

Another example, if you were processing text that will end up in an HTML
<title> tag, this tag should never contain any other tags, so you should use
the MKDoc::Text::Structured::Inline::process_entities_only() method:

  $title = "< My (c) symbol shouldn't be *bold* > -- or http://example.com/ 'linked'";
  $title = MKDoc::Text::Structured::Inline::process_entities_only ($title);

$title is now:

  &lt; My &copy; symbol shouldn't be *bold* &mdash; &gt; or http://example.com/ &lsquo;linked&rsquo;

=cut

sub process_entities_only
{
    local $Text;
    $Text = shift;
    $Text = " $Text ";
    $Text =~ s/\n/ /gsm;

    _make_entities();
    _make_simplequotes();
    _make_doublequotes();
    _break_long_words();
    
    $Text =~ s/^ //;
    $Text =~ s/ $//;
    return $Text;
}


sub _make_entities
{
    $Text   =~ s/&/&amp;/g;
    $Text   =~ s/</&lt;/g;
    $Text   =~ s/>/&gt;/g;
    $Text   =~ s/"/&quot;/g;

    $Text =~ s/(?<=(?:\s|\n))--(?=(?:\s|\n))/\&mdash;/g;                                 # --    becomes em-dash 
    $Text =~ s/(?<=(?:\s|\n))-(?=(?:\s|\n))/\&ndash;/g;                                  # -     becomes en-dash
    $Text =~ s/(?<!\.)\.\.\.(?!\.)/\&hellip;/g;                                          # ...   becomes ellipsis

    $Text =~ s/\(tm\)(?=(?:\s|\n|\p{IsPunct}))/\&trade;/gi;                              # (tm)  becomes trademark
    $Text =~ s/\(r\)(?=(?:\s|\n|\p{IsPunct}))/\&reg;/gi;                                 # (r)   becomes registered
    $Text =~ s/\(c\)(?=(?:\s|\n|\p{IsPunct}))/\&copy;/gi;                                # (c)   becomes copyright
    $Text =~ s/(?<=(?:\s|\n))(\d+)\s*x\s*(\d+)(?=(?:\s|\n|\p{isPunct}))/$1\&times;$2/g;  # x     becomes dimension
}


sub _make_abbr_implicit
{
    my $abbr  = shift;
    my $brack = shift;
    my $title = $brack;
    $title =~ s/^\s*\(\s*//;
    $title =~ s/\s*\)\s*$//;
    return qq|<abbr title="$title">$abbr</abbr> ($title)|;
}


sub _make_abbr_explicit
{
    my $abbr  = shift;
    my $brack = shift;
    my $title = $brack;
    $title =~ s/^\s*\(\s*//;
    $title =~ s/\s*\)\s*$//;
    return qq|<abbr title="$title">$abbr</abbr>|;
}


sub _make_simplequotes
{
    $Text = join '', map {
	my $stuff = $_;
	$stuff = " $stuff ";
	while ($stuff =~ s/
(?<=(?:\s|\n))                            # must start with space or carriage return
\'                                        # simple quote 
([^ \t\n\']|[^ \t\n\'].*?[^ \t\n\'])      # stuff to capture and smart-quotize
\'                                        # simple quote
(?=(?:<|\s|\n|\p{IsPunct}(?:\s|\n|<)))    # must be followed by space, \n or (punctuation + space or \n)
/_make_simplequotes_wrap ($1)/xes) {}
	
	$stuff =~ s/^ //;
	$stuff =~ s/ $//;
	$stuff;
    } _tokenize ($Text);
}


sub _make_simplequotes_wrap
{
    my $stuff = shift;
    local $Text = $stuff;
    return "&lsquo;$Text&rsquo;";
}



sub _make_doublequotes
{
    $Text = join '', map {
	my $stuff = $_;
	$stuff = " $stuff ";
        $stuff =~ s/"/<QUOT>/g;
        $stuff =~ s/&quot;/"/g;
	while ($stuff =~ s/
(?<=(?:\s|\n))                            # must start with space or carriage return
\"                                        # double quote 
([^ \t\n\"]|[^ \t\n\"].*?[^ \t\n\"])            # stuff to capture and smart-quotize
\"                                        # double quote
(?=(?:<|\s|\n|\p{IsPunct}(?:\s|\n|<)))    # must be followed by space, \n or (punctuation + space or \n)
/_make_doublequotes_wrap ($1)/xes) {}
	
	$stuff =~ s/^ //;
	$stuff =~ s/ $//;
        $stuff =~ s/"/&quot;/g;
        $stuff =~ s/<QUOT>/"/g;
	$stuff;
    } _tokenize ($Text);
}


sub _make_doublequotes_wrap
{
    my $stuff = shift;
    local $Text = $stuff;
    return "&ldquo;$Text&rdquo;";
}


sub _make_strong
{
    $Text = join '', map {
	my $stuff = $_;
	$stuff = " $stuff ";
	while ($stuff =~ s/
(?<=(?:\s|\n))                            # must start with space or carriage return
\*                                        # star
(\S|\S.*?\S)                              # stuff to capture and emphasize
\*                                        # star
(?=(?:<|\s|\n|\p{IsPunct}(?:\s|\n|<)))    # must be followed by space, \n or (punctuation + space or \n)
/_make_strong_wrap ($1)/xes) {}
	
	$stuff =~ s/^ //;
	$stuff =~ s/ $//;
	$stuff;
    } _tokenize ($Text);
}


sub _make_strong_wrap
{
    my $stuff = shift;
    local $Text = $stuff;
    _make_em ($Text);
    return "<strong>$Text</strong>";
}


sub _make_em
{
    $Text = join '', map {
	my $stuff = $_;
	$stuff = " $stuff ";
	while ($stuff =~ s/
(?<=(?:\s|\n))                            # must start with space or carriage return
_                                         # underscore
(\S|\S.*?\S)                              # stuff to capture and emphasize
_                                         # underscore
(?=(?:<|\s|\n|\p{IsPunct}(?:\s|\n)))      # must be followed by space, \n or (punctuation + space or \n)
/_make_em_wrap ($1)/xes) {}

	$stuff =~ s/^ //;
	$stuff =~ s/ $//;
	$stuff;
    } _tokenize ($Text);
}


sub _make_em_wrap
{
    my $stuff = shift;
    
    local $Text = $stuff;
    _make_strong ($Text);
    return "<em>$Text</em>";
}


sub _make_smilies
{
    $Text = join '', map {
	my $stuff = $_;
        $stuff =~ s/:-\)/<span class="smiley-happy">:-)<\/span>/g unless ($stuff =~ /^</);
        $stuff =~ s/:-\(/<span class="smiley-sad">:-(<\/span>/g unless ($stuff =~ /^</);
        # don't do ;-) think about what happens with &-)
        $stuff;
    } _tokenize ($Text);
}


sub _break_long_words
{
    $Text = join '', map {
	my $stuff = $_;
        $stuff = _insert_spaces ($stuff, $LongestWord) unless ($stuff =~ /^</);
	$stuff;
    } _tokenize ($Text);
}


sub _insert_spaces
{
    my $text = shift;
    my $length = shift || return $text;
    # we can break continuous non-space text after "/", ";" or "-"
    $text =~ s/(\S{$length}[\/;-])(?=\S)/$1 /g;
    # we can break continuous non-space text so long as it doesn't contain an ampersand
    $text =~ s/([^[:space:]&]{$length})(?=\S)/$1 /g;
    return $text;
}


sub _tokenize
{
    my $text = shift;
    my @res  = $text =~ /([^<]+)|(<.+?>)/g;
    return grep { defined $_ } @res;
}


1;


__END__
