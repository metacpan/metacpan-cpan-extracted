package HTML::Encoding;
use strict;
use warnings;

use HTML::Parser        qw();
use HTTP::Headers::Util qw(split_header_words);
use Encode              qw();

use base qw(Exporter);

our $VERSION = '0.61';

our @EXPORT_OK =
qw/
    &encoding_from_meta_element
    &xml_declaration_from_octets
    &encoding_from_first_chars
    &encoding_from_xml_declaration
    &encoding_from_byte_order_mark
    &encoding_from_content_type
    &encoding_from_xml_document
    &encoding_from_html_document
    &encoding_from_http_message
/;

our $DEFAULT_ENCODINGS = [qw/
  ISO-8859-1
  UTF-16LE
  UTF-16BE
  UTF-32LE
  UTF-32BE
  UTF-8
/];

our %MAP =
(
    BM => "\x{FEFF}",
    CR => "\x{000D}",
    LF => "\x{000A}",
    SP => "\x{0020}",
    TB => "\x{0009}",
    QS => "\x{003F}",
    NL => "\x{0085}",
    LS => "\x{2028}",
    LT => "<", # fixme
    GT => ">", # fixme
);

sub _my_encode
{
    my $seq;
    
    eval
    {
        $seq = Encode::encode($_[0],
                              $_[1],
                              $_[2]);
    };
    
    return $seq unless $@;
    return;
}

sub _my_decode
{
    my $str;

    eval
    {
        $str = Encode::decode($_[0],
                              $_[1],
                              $_[2]);
    };
    
    return $str unless $@;
    return;
}

sub _make_character_map
{
    my $encoding = shift;
    my %data;
    
    foreach my $sym (keys %MAP)
    {
        my $seq = _my_encode($encoding, "$MAP{$sym}", Encode::FB_CROAK);
        $data{$sym} = $seq if defined $seq;
    }
    
    \%data;
}

# cache for U+XXXX octet sequences
our %CHARACTER_MAP_CACHE = ();

sub _get_character_map
{
    my $encoding = shift;
    
    # read from cache
    return $CHARACTER_MAP_CACHE{$encoding}
      if exists $CHARACTER_MAP_CACHE{$encoding};
    
    # new cache entry
    my $map = _make_character_map($encoding);
    $CHARACTER_MAP_CACHE{$encoding} = $map;
    
    # return new entry
    return $map;
}

sub encoding_from_meta_element
{
    my $text = shift;
    my $enco = shift;

    return unless defined $text;
    return unless length $text;

    return unless defined $enco;
    return unless length $enco;

    my $pars = HTML::Parser->new
    (
        api_version => 3,
        @_
    );
    
    my $meta = [];
    my $leng = length $text;
    my $size = 8192;
    my $data = '';
    my $utf8 = '';
    my $i = 0;

    # todo: should finish when <body> or logically body//*

    $pars->report_tags(qw/meta head/);
    $pars->handler(start => $meta, "tagname,attr");
    $pars->handler
    (
       end => sub { $_[0]->eof if $_[1] eq "head" },
       "self,tagname"
    );
    
    $pars->parse(sub
    {
        return if $i > $leng;
        $data .= substr $text, $i, $size;
        $i += $size;
        _my_decode($enco, $data, Encode::FB_QUIET);
    });

    my @resu;
    
    foreach (grep { $_->[0] eq "meta" } @$meta)
    {
        my %hash = %{$_->[1]};
        next unless defined $hash{'content'};
        next unless exists $hash{'http-equiv'};
        next unless lc $hash{'http-equiv'} eq "content-type";
        my $char = encoding_from_content_type($hash{'content'});
        push @resu, $char if defined $char and length $char;
    }
    
    return unless @resu;
    return wantarray ? @resu : $resu[0];
}

sub xml_declaration_from_octets
{
    my $text = shift;
    my %o = @_;
    my $encodings = $o{encodings} || $DEFAULT_ENCODINGS;
    my %resu;
    
    return unless defined $text;
    return unless length $text;

    foreach my $e (@$encodings)
    {
        my $map = _get_character_map($e);

        # search for >
        my $end = index $text, $map->{GT};

        # search for <?
        my $str = index $text, $map->{LT} . $map->{QS};
        
        # skip this encoding unless ...
        next unless $end > 0 and $str >= 0 and $end > $str;

        # extract tentative XML declaration
        my $decl = substr $text, $str, $end - $str + 1;
        
        # decode XML declaration
        my $deco = _my_decode($e, $decl, Encode::FB_CROAK);
        
        # skip encoding if decoding failed
        next unless defined $deco;
        
        $resu{$deco}++;
    }
    
    # No XML declarations found
    return unless keys %resu;

    # sort by number of matches, most match first
    my @sort = sort { $resu{$b} <=> $resu{$a} } keys %resu;
    
    # in array context return all encodings,
    # in scalar context return best match.
    return wantarray ? @sort : $sort[0];
}

sub encoding_from_first_chars
{
    my $text = shift;
    my %o = @_;
    my $encodings = $o{encodings} || $DEFAULT_ENCODINGS;
    my $whitespace = $o{whitespace} || [qw/CR LF TB SP/];

    return unless defined $text;
    return unless length $text;
    
    my %resu;
    foreach my $e (@$encodings)
    {
        my $m = _get_character_map($e);
        my $i = index $text, $m->{LT};
        next unless $i >= 0;
        my $t = substr $text, 0, $i;
        
        my @y;

        # construct \xXX\xXX string from octets, might make sense to
        # have this in the map construction process
        push@y,"(?:".join("",map{sprintf"\\x%02x",ord}split//,$m->{$_}).")"
          foreach grep defined, @$whitespace;

        my $x = join "|", @y;
        $t =~ s/^($x)+//g;
        
        $resu{$e} = $i + length $m->{LT} unless length $t;
    }
    
    # ...
    return unless keys %resu;
    
    # sort by match length, longest match first
    my @sort = sort { $resu{$b} <=> $resu{$a} } keys %resu;
    
    # in array context return all encodings,
    # in scalar context return best match.
    return wantarray ? @sort : $sort[0];
}

sub encoding_from_xml_declaration
{
    my $decl = shift;

    return unless defined $decl;
    return unless length $decl;

    # todo: move this to some better place...
    my $ws = qr/[\x09\x85\x20\x0d\x0a\x{2028}]*/;
    
    # skip if not an XML declaration
    return unless $decl =~ /^<\?xml$ws/i;

    # attempt to extract encoding pseudo attribute
    return unless $decl =~ /encoding$ws=$ws'([^']+)'/i or
                  $decl =~ /encoding$ws=$ws"([^"]+)"/i;

    # no encoding pseudo-attribute
    return unless defined $1;
    my $enco = $1;

    # strip leading/trailing whitespace/quotes
    $enco =~ s/^[\s'"]+|[\s'"]+$//g;
    
    # collapse white-space
    $enco =~ s/\s+/ /g;
    
    # treat empty charset as if it were unspecified
    return unless length $enco;

    return $enco;
}

sub encoding_from_byte_order_mark
{
    my $text = shift;
    my %o = @_;
    my $encodings = $o{encodings} || $DEFAULT_ENCODINGS;
    my %resu;

    return unless defined $text;
    return unless length $text;

    foreach my $e (@$encodings)
    {
        my $map = _get_character_map($e);
        my $bom = $map->{BM};
        
        # encoding cannot encode U+FEFF
        next unless defined $bom;
        
        # remember match length
        $resu{$e} = length $bom if $text =~ /^(\Q$bom\E)/;
    }

    # does not start with BOM
    return unless keys %resu;
    
    # sort by match length, longest match first
    my @sort = sort { $resu{$b} <=> $resu{$a} } keys %resu;
    
    # in array context return all encodings,
    # in scalar context return best match.
    return wantarray ? @sort : $sort[0];
}

sub encoding_from_content_type
{
    my $text = shift;

    # nothing to do...
    return unless defined $text and length $text;
    
    # downgrade Unicode strings
    $text = Encode::encode_utf8($text) if Encode::is_utf8($text);
    
    # split parameters, only look at the first set
    my %data = @{(split_header_words($text))[0]};
    
    # extract first charset parameter if any
    my $char;
    foreach my $param (keys %data) {
      $char = $data{$param} and last if 'charset' eq lc $param;
    }

    # no charset parameter    
    return unless defined $char;
    
    # there are no special escapes so just remove \s
    $char =~ tr/\\//d;
    
    # strip leading/trailing whitespace/quotes
    $char =~ s/^[\s'"]+|[\s'"]+$//g;
    
    # collapse white-space
    $char =~ s/\s+/ /g;
    
    # treat empty charset as if it were unspecified
    return unless length $char;
    
    return $char
}

sub encoding_from_xml_document
{
    my $text = shift;
    my %o = @_;
    my $encodings = $o{encodings} || $DEFAULT_ENCODINGS;
    my %resu;
    
    return unless defined $text;
    return unless length $text;
    
    my @boms = encoding_from_byte_order_mark($text, encodings => $encodings);

    # BOM determines encoding
    return wantarray ? (bom => \@boms) : $boms[0] if @boms;
    
    # no BOM
    my @decls = xml_declaration_from_octets($text, encodings => $encodings);
    foreach my $decl (@decls)
    {
        my $enco = encoding_from_xml_declaration($decl);
        $resu{$enco}++ if defined $enco and length $enco;
    }

    return unless keys %resu;
    my @sort = sort { $resu{$b} <=> $resu{$a} } keys %resu;
    
    # in array context return all encodings,
    # in scalar context return best match.
    return wantarray ? (xml => \@sort) : $sort[0];
}

sub encoding_from_html_document
{
    my $text = shift;
    my %o = @_;
    my $encodings = $o{encodings} || $DEFAULT_ENCODINGS;
    my $popts = $o{parser_options} || {};
    my $xhtml = exists $o{xhtml} ? $o{xhtml} : 1;
    
    return unless defined $text;
    return unless length $text;
    
    if ($xhtml)
    {
        my @xml = wantarray
                    ? encoding_from_xml_document($text, encodings => $encodings)
                    : scalar encoding_from_xml_document($text, encodings => $encodings);
        
        return wantarray
          ? @xml
          : $xml[0]
            if @xml and defined $xml[0];
    }
    else
    {
        my @boms = encoding_from_byte_order_mark($text, encodings => $encodings);

        # BOM determines encoding
        return wantarray ? (bom => \@boms) : $boms[0] if @boms;
    }

    # no BOM
    my @resu;
    
    # sanity check to exclude e.g. UTF-32
    my @first = encoding_from_first_chars($text, encodings => $encodings);
    
    # fall back to provided encoding list
    @first = @$encodings unless @first;
    
    foreach my $try (@first)
    {
        push @resu, encoding_from_meta_element($text, $try, %$popts);
    }

    return unless @resu;
    return wantarray ? (meta => \@resu) : $resu[0];
}

sub encoding_from_http_message
{
    my $mess      = shift;
    my %o         = @_;

    my $encodings = $o{encodings}        || $DEFAULT_ENCODINGS;
    my $is_html   = $o{is_html}          || qr{^text/html$}i;
    my $is_xml    = $o{is_xml}           || qr{^.+/(?:.+\+)?xml$}i;
    my $is_t_xml  = $o{is_text_xml}      || qr{^text/(?:.+\+)?xml$}i;
    my $html_d    = $o{html_default}     || "ISO-8859-1";
    my $xml_d     = $o{xml_default}      || "UTF-8";
    my $txml      = $o{text_xml_default};
    
    my $xhtml     = exists $o{xhtml}   ? $o{xhtml}   : 1;
    my $default   = exists $o{default} ? $o{default} : 1;
    
    my $type      = $mess->header('Content-Type');
    my $charset   = encoding_from_content_type($type);
    
    if ($mess->content_type =~ $is_xml)
    {
        return wantarray ? (protocol => $charset) : $charset
          if defined $charset;
          
        # special case for text/xml at user option
        return wantarray ? (protocol_default => $txml) : $txml
          if defined $txml and $mess->content_type =~ $is_t_xml;
          
        if (wantarray)
        {
            my @xml = encoding_from_xml_document($mess->content, encodings => $encodings);
            return @xml if @xml;
        }
        else
        {
            my $xml = scalar encoding_from_xml_document($mess->content, encodings => $encodings);
            return $xml if defined $xml;
        }
        
        return wantarray ? (default => $xml_d) : $xml_d if defined $default;
    }
    
    if ($mess->content_type =~ $is_html)
    {
        return wantarray ? (protocol => $charset) : $charset
          if defined $charset;
          
        if (wantarray)
        {
            my @html = encoding_from_html_document($mess->content, encodings => $encodings, xhtml => $xhtml);
            return @html if @html;
        }
        else
        {
            my $html = scalar encoding_from_html_document($mess->content, encodings => $encodings, xhtml => $xhtml);
            return $html if defined $html;
        }

        return wantarray ? (default => $html_d) : $html_d if defined $default;
    }
    
    return
}

1;

__END__

=pod

=head1 NAME

HTML::Encoding - Determine the encoding of HTML/XML/XHTML documents

=head1 SYNOPSIS

  use HTML::Encoding 'encoding_from_http_message';
  use LWP::UserAgent;
  use Encode;
  
  my $resp = LWP::UserAgent->new->get('http://www.example.org');
  my $enco = encoding_from_http_message($resp);
  my $utf8 = decode($enco => $resp->content);

=head1 WARNING

The interface and implementation are guranteed to change before this
module reaches version 1.00! Please send feedback to the author of
this module.

=head1 DESCRIPTION

HTML::Encoding helps to determine the encoding of HTML and XML/XHTML
documents...

=head1 DEFAULT ENCODINGS

Most routines need to know some suspected character encodings which
can be provided through the C<encodings> option. This option always
defaults to the $HTML::Encoding::DEFAULT_ENCODINGS array reference
which means the following encodings are considered by default:

  * ISO-8859-1
  * UTF-16LE
  * UTF-16BE
  * UTF-32LE
  * UTF-32BE
  * UTF-8

If you change the values or pass custom values to the routines note
that L<Encode> must support them in order for this module to work
correctly.

=head1 ENCODING SOURCES

C<encoding_from_xml_document>, C<encoding_from_html_document>, and
C<encoding_from_http_message> return in list context the encoding
source and the encoding name, possible encoding sources are

  * protocol         (Content-Type: text/html;charset=encoding)
  * bom              (leading U+FEFF)
  * xml              (<?xml version='1.0' encoding='encoding'?>)
  * meta             (<meta http-equiv=...)
  * default          (default fallback value)
  * protocol_default (protocol default)

=head1 ROUTINES

Routines exported by this module at user option. By default, nothing
is exported.

=over 2

=item encoding_from_content_type($content_type)

Takes a byte string and uses L<HTTP::Headers::Util> to extract the
charset parameter from the C<Content-Type> header value and returns
its value or C<undef> (or an empty list in list context) if there
is no such value. Only the first component will be examined
(HTTP/1.1 only allows for one component), any backslash escapes in
strings will be unescaped, all leading and trailing quote marks
and white-space characters will be removed, all white-space will be
collapsed to a single space, empty charset values will be ignored
and no case folding is performed.

Examples:

  +-----------------------------------------+-----------+
  | encoding_from_content_type(...)         | returns   |
  +-----------------------------------------+-----------+
  | "text/html"                             | undef     |
  | "text/html,text/plain;charset=utf-8"    | undef     |
  | "text/html;charset="                    | undef     |
  | "text/html;charset=\"\\u\\t\\f\\-\\8\"" | 'utf-8'   |
  | "text/html;charset=utf\\-8"             | 'utf\\-8' |
  | "text/html;charset='utf-8'"             | 'utf-8'   |
  | "text/html;charset=\" UTF-8 \""         | 'UTF-8'   |
  +-----------------------------------------+-----------+

If you pass a string with the UTF-8 flag turned on the string will
be converted to bytes before it is passed to L<HTTP::Headers::Util>.
The return value will thus never have the UTF-8 flag turned on (this
might change in future versions).

=item encoding_from_byte_order_mark($octets [, %options])

Takes a sequence of octets and attempts to read a byte order mark
at the beginning of the octet sequence. It will go through the list
of $options{encodings} or the list of default encodings if no
encodings are specified and match the beginning of the string against
any byte order mark octet sequence found.

The result can be ambiguous, for example qq(\xFF\xFE\x00\x00) could
be both, a complete BOM in UTF-32LE or a UTF-16LE BOM followed by a
U+0000 character. It is also possible that C<$octets> starts with
something that looks like a byte order mark but actually is not.

encoding_from_byte_order_mark sorts the list of possible encodings
by the length of their BOM octet sequence and returns in scalar
context only the encoding with the longest match, and all encodings
ordered by length of their BOM octet sequence in list context.

Examples:

  +-------------------------+------------+-----------------------+
  | Input                   | Encodings  | Result                |
  +-------------------------+------------+-----------------------+
  | "\xFF\xFE\x00\x00"      | default    | qw(UTF-32LE)          |
  | "\xFF\xFE\x00\x00"      | default    | qw(UTF-32LE UTF-16LE) |
  | "\xEF\xBB\xBF"          | default    | qw(UTF-8)             |
  | "Hello World!"          | default    | undef                 |
  | "\xDD\x73\x66\x73"      | default    | undef                 |
  | "\xDD\x73\x66\x73"      | UTF-EBCDIC | qw(UTF-EBCDIC)        |
  | "\x2B\x2F\x76\x38\x2D"  | default    | undef                 |
  | "\x2B\x2F\x76\x38\x2D"  | UTF-7      | qw(UTF-7)             |
  +-------------------------+------------+-----------------------+

Note however that for UTF-7 it is in theory possible that the U+FEFF
combines with other characters in which case such detection would fail,
for example consider:

  +--------------------------------------+-----------+-----------+
  | Input                                | Encodings | Result    |
  +--------------------------------------+-----------+-----------+
  | "\x2B\x2F\x76\x38\x41\x39\x67\x2D"   | default   | undef     |
  | "\x2B\x2F\x76\x38\x41\x39\x67\x2D"   | UTF-7     | undef     |
  +--------------------------------------+-----------+-----------+

This might change in future versions, although this is not very
relevant for most applications as there should never be need to use
UTF-7 in the encoding list for existing documents.

If no BOM can be found it returns C<undef> in scalar context and an
empty list in list context. This routine should not be used with
strings with the UTF-8 flag turned on. 

=item encoding_from_xml_declaration($declaration)

Attempts to extract the value of the encoding pseudo-attribute in an XML
declaration or text declaration in the character string $declaration. If
there does not appear to be such a value it returns nothing. This would
typically be used with the return values of xml_declaration_from_octets.
Normalizes whitespaces like encoding_from_content_type.

Examples:

  +-------------------------------------------+---------+
  | encoding_from_xml_declaration(...)        | Result  |
  +-------------------------------------------+---------+
  | "<?xml version='1.0' encoding='utf-8'?>"  | 'utf-8' |
  | "<?xml encoding='utf-8'?>"                | 'utf-8' |
  | "<?xml encoding=\"utf-8\"?>"              | 'utf-8' |
  | "<?xml foo='bar' encoding='utf-8'?>"      | 'utf-8' |
  | "<?xml encoding='a' encoding='b'?>"       | 'a'     |
  | "<?xml encoding=' a    b '?>"             | 'a b'   |
  | "<?xml-stylesheet encoding='utf-8'?>"     | undef   |
  | " <?xml encoding='utf-8'?>"               | undef   |
  | "<?xml encoding =\x{2028}'utf-8'?>"       | 'utf-8' |
  | "<?xml version='1.0' encoding=utf-8?>"    | undef   |
  | "<?xml x='encoding=\"a\"' encoding='b'?>" | 'a'     |
  +-------------------------------------------+---------+

Note that encoding_from_xml_declaration() determines the encoding even
if the XML declaration is not well-formed or violates other requirements
of the relevant XML specification as long as it can find an encoding
pseudo-attribute in the provided string. This means XML processors must
apply further checks to determine whether the entity is well-formed, etc.

=item xml_declaration_from_octets($octets [, %options])

Attempts to find a ">" character in the byte string $octets using the
encodings in $encodings and upon success attempts to find a preceding
"<" character. Returns all the strings found this way in the order of
number of successful matches in list context and the best match in
scalar context. Should probably be combined with the only user of this
routine, encoding_from_xml_declaration... You can modify the list of
suspected encodings using $options{encodings};

=item encoding_from_first_chars($octets [, %options])

Assuming that documents start with "<" optionally preceded by whitespace
characters, encoding_from_first_chars attempts to determine an encoding
by matching $octets against something like /^[@{$options{whitespace}}]*</
in the various suspected $options{encodings}.

This is useful to distinguish e.g. UTF-16LE from UTF-8 if the byte string
does not start with a byte order mark nor an XML declaration (e.g. if the
document is a HTML document) to get at least a base encoding which can be
used to decode enough of the document to find <meta> elements using
encoding_from_meta_element. $options{whitespace} defaults to qw/CR LF SP TB/.
Returns nothing if unsuccessful. Returns the matching encodings in order
of the number of octets matched in list context and the best match in
scalar context.

Examples:

  +---------------+----------+---------------------+
  | String        | Encoding | Result              |
  +---------------+----------+---------------------+
  | '<!DOCTYPE '  | UTF-16LE | UTF-16LE            |
  | ' <!DOCTYPE ' | UTF-16LE | UTF-16LE            |
  | '...'         | UTF-16LE | undef               |
  | '...<'        | UTF-16LE | undef               |
  | '<'           | UTF-8    | ISO-8859-1 or UTF-8 |
  | "<!--\xF6-->" | UTF-8    | ISO-8859-1 or UTF-8 |
  +---------------+----------+---------------------+

=item encoding_from_meta_element($octets, $encname [, %options])

Attempts to find <meta> elements in the document using HTML::Parser.
It will attempt to decode chunks of the byte string using $encname
to characters before passing the data to HTML::Parser. An optional
%options hash can be provided which will be passed to the HTML::Parser
constructor. It will stop processing the document if it encounters

  * </head>
  * encoding errors
  * the end of the input
  * ... (see todo)

If relevant <meta> elements, i.e. something like

  <meta http-equiv=Content-Type content='...'>
  
are found, uses encoding_from_content_type to extract the charset
parameter. It returns all such encodings it could find in document
order in list context or the first encoding in scalar context (it
will currently look for others regardless of calling context) or
nothing if that fails for some reason.

Note that there are many edge cases where this does not yield in
"proper" results depending on the capabilities of the HTML::Parser
version and the options you pass for it, for example,

  <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" [
    <!ENTITY content_type "text/html;charset=utf-8">
  ]>
  <meta http-equiv="Content-Type" content="&content_type;">
  <title></title>
  <p>...</p>

This would likely not detect the C<utf-8> value if HTML::Parser
does not resolve the entity. This should however only be a concern
for documents specifically crafted to break the encoding detection.

=item encoding_from_xml_document($octets, [, %options])

Uses encoding_from_byte_order_mark to detect the encoding using a
byte order mark in the byte string and returns the return value of
that routine if it succeeds. Uses xml_declaration_from_octets and
encoding_from_xml_declaration and returns the encoding for which
the latter routine found most matches in scalar context, and all
encodings ordered by number of occurences in list context. It
does not return a value of neither byte order mark not inbound
declarations declare a character encoding.

Examples:

  +----------------------------+----------+-----------+----------+
  | Input                      | Encoding | Encodings | Result   |
  +----------------------------+----------+-----------+----------+
  | "<?xml?>"                  | UTF-16   | default   | UTF-16BE |
  | "<?xml?>"                  | UTF-16LE | default   | undef    |
  | "<?xml encoding='utf-8'?>" | UTF-16LE | default   | utf-8    |
  | "<?xml encoding='utf-8'?>" | UTF-16   | default   | UTF-16BE |
  | "<?xml encoding='cp37'?>"  | CP37     | default   | undef    |
  | "<?xml encoding='cp37'?>"  | CP37     | CP37      | cp37     |
  +----------------------------+----------+-----------+----------+

Lacking a return value from this routine and higher-level protocol
information (such as protocol encoding defaults) processors would
be required to assume that the document is UTF-8 encoded.

Note however that the return value depends on the set of suspected
encodings you pass to it. For example, by default, EBCDIC encodings
would not be considered and thus for

  <?xml version='1.0' encoding='cp37'?>
  
this routine would return the undefined value. You can modify the
list of suspected encodings using $options{encodings}.

=item encoding_from_html_document($octets, [, %options])

Uses encoding_from_xml_document and encoding_from_meta_element to
determine the encoding of HTML documents. If $options{xhtml} is
set to a false value uses encoding_from_byte_order_mark and 
encoding_from_meta_element to determine the encoding. The xhtml
option is on by default. The $options{encodings} can be used to
modify the suspected encodings and $options{parser_options} can
be used to modify the HTML::Parser options in
encoding_from_meta_element (see the relevant documentation).

Returns nothing if no declaration could be found, the winning
declaration in scalar context and a list of encoding source
and encoding name in list context, see ENCODING SOURCES.

...

Other problems arise from differences between HTML and XHTML syntax
and encoding detection rules, for example, the input could be

  Content-Type: text/html

  <?xml version='1.0' encoding='utf-8'?>
  <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN"
  "http://www.w3.org/TR/html4/strict.dtd">
  <meta http-equiv = "Content-Type"
           content = "text/html;charset=iso-8859-2">
  <title></title>
  <p>...</p>

This is a perfectly legal HTML 4.01 document and implementations
might be expected to consider the document ISO-8859-2 encoded as
XML rules for encoding detection do not apply to HTML documents.
This module attempts to avoid making decisions which rules apply
for a specific document and would thus by default return 'utf-8'
for this input.

On the other hand, if the input omits the encoding declaration,

  Content-Type: text/html

  <?xml version='1.0'?>
  <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN"
  "http://www.w3.org/TR/html4/strict.dtd">
  <meta http-equiv = "Content-Type"
           content = "text/html;charset=iso-8859-2">
  <title></title>
  <p>...</p>

It would return 'iso-8859-2'. Similar problems would arise from
other differences between HTML and XHTML, for example consider

  Content-Type: text/html

  <?foo >
  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
      "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
  <html ...
  ?>
  ...
  <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN">
  ...
  
If this is processed using HTML rules, the first > will end the
processing instruction and the XHTML document type declaration
would be the relevant declaration for the document, if it is
processed using XHTML rules, the ?> will end the processing
instruction and the HTML document type declaration would be the
relevant declaration.

IOW, an application would need to assume a certain character
encoding (family) to process enough of the document to determine
whether it is XHTML or HTML and the result of this detection would
depend on which processing rules are assumed in order to process it.
It is thus in essence not possible to write a "perfect" detection
algorithm, which is why this routine attempts to avoid making any
decisions on this matter.

=item encoding_from_http_message($message [, %options])

Determines the encoding of HTML / XML / XHTML documents enclosed
in HTTP message. $message is an object compatible to L<HTTP::Message>,
e.g. a L<HTTP::Response> object. %options is a hash with the following
possible entries:

=over 2

=item encodings

array references of suspected character encodings, defaults to
C<$HTML::Encoding::DEFAULT_ENCODINGS>.

=item is_html

Regular expression matched against the content_type of the message
to determine whether to use HTML rules for the entity body, defaults
to C<qr{^text/html$}i>.

=item is_xml

Regular expression matched against the content_type of the message
to determine whether to use XML rules for the entity body, defaults
to C<qr{^.+/(?:.+\+)?xml$}i>.

=item is_text_xml

Regular expression matched against the content_type of the message
to determine whether to use text/html rules for the message, defaults
to C<qr{^text/(?:.+\+)?xml$}i>. This will only be checked if is_xml
matches aswell.

=item html_default

Default encoding for documents determined (by is_html) as HTML,
defaults to C<ISO-8859-1>.

=item xml_default

Default encoding for documents determined (by is_xml) as XML,
defaults to C<UTF-8>.

=item text_xml_default

Default encoding for documents determined (by is_text_xml) as text/xml,
defaults to C<undef> in which case the default is ignored. This should
be set to C<US-ASCII> if desired as this module is by default
inconsistent with RFC 3023 which requires that for text/xml documents
without a charset parameter in the HTTP header C<US-ASCII> is assumed.

This requirement is inconsistent with RFC 2616 (HTTP/1.1) which requires
to assume C<ISO-8859-1>, has been widely ignored and is thus disabled by
default.

=item xhtml

Whether the routine should look for an encoding declaration in the
XML declaration of the document (if any), defaults to C<1>.

=item default

Whether the relevant default value should be returned when no other
information can be determined, defaults to C<1>.

=back

This is furhter possibly inconsistent with XML MIME types that differ
in other ways from application/xml, for example if the MIME Type does
not allow for a charset parameter in which case applications might be
expected to ignore the charset parameter if erroneously provided.

=back

=head1 EBCDIC SUPPORT

By default, this module does not support EBCDIC encodings. To enable
support for EBCDIC encodings you can either change the
$HTML::Encodings::DEFAULT_ENCODINGS array reference or pass the
encodings to the routines you use using the encodings option, for
example

  my @try = qw/UTF-8 UTF-16LE cp500 posix-bc .../;
  my $enc = encoding_from_xml_document($doc, encodings => \@try);

Note that there are some subtle differences between various EBCDIC
encodings, for example C<!> is mapped to 0x5A in C<posix-bc> and
to 0x4F in C<cp500>; these differences might affect processing in
yet undetermined ways.

=head1 TODO

  * bundle with test suite
  * optimize some routines to give up once successful
  * avoid transcoding for HTML::Parser if e.g. ISO-8859-1
  * consider adding a "HTML5" modus of operation?

=head1 SEE ALSO

  * http://www.w3.org/TR/REC-xml/#charencoding
  * http://www.w3.org/TR/REC-xml/#sec-guessing
  * http://www.w3.org/TR/xml11/#charencoding
  * http://www.w3.org/TR/xml11/#sec-guessing
  * http://www.w3.org/TR/html4/charset.html#h-5.2.2
  * http://www.w3.org/TR/xhtml1/#C_9
  * http://www.ietf.org/rfc/rfc2616.txt
  * http://www.ietf.org/rfc/rfc2854.txt
  * http://www.ietf.org/rfc/rfc3023.txt
  * perlunicode
  * Encode
  * HTML::Parser

=head1 AUTHOR / COPYRIGHT / LICENSE

  Copyright (c) 2004-2008 Bjoern Hoehrmann <bjoern@hoehrmann.de>.
  This module is licensed under the same terms as Perl itself.

=cut
