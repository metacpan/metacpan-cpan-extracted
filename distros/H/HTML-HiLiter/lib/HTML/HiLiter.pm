package HTML::HiLiter;
use Moose;
use 5.008003;    # Search::Tools requires this
with 'Search::Tools::ArgNormalizer';
use Carp;
use Search::Tools::QueryParser;
use Search::Tools::HiLiter;
use Search::Tools::UTF8;
use Data::Dump qw( dump );
use HTML::Parser;
use HTML::Tagset;

# HTML::Tagset::isHeadElement doesn't define these,
# so we add them here
$HTML::Tagset::isHeadElement{'head'}++;
$HTML::Tagset::isHeadElement{'html'}++;

sub _init_debug { return $ENV{PERL_DEBUG} || 0 }

has 'debug' => (
    is      => 'rw',
    isa     => 'Maybe[Int]',
    lazy    => 1,
    builder => '_init_debug',
);
has 'hiliter' => (
    is      => 'rw',
    isa     => 'Search::Tools::HiLiter',
    lazy    => 1,
    builder => '_init_hiliter',
);
has 'query' => (
    is  => 'rw',
    isa => 'Search::Tools::Query',
);
has 'buffer_limit' => ( is => 'rw', isa => 'Int',  default => sub { 2**16 } );
has 'print_stream' => ( is => 'rw', isa => 'Bool', default => sub {1} );
has 'fh' => ( is => 'rw', isa => 'FileHandle', default => sub { \*STDOUT } );
has 'style_header' => ( is => 'rw', isa => 'Maybe[Str]', );

# Search::Tools::HiLilter attributes we want to proxy through
has 'tag' => ( is => 'rw', isa => 'Str', default => sub {'span'} );
for my $attr (qw( class style colors text_color tty )) {
    has $attr => ( is => 'rw' );
}

our $VERSION = '0.201';

# some global debugging vars
my $open_comment  = "\n<!--\n";
my $close_comment = "\n-->\n";

################################################################################
# char tables below are from pre 0.14. keeping here for reference, just in case.
#
#
# a subset of chars per SWISH
#$ISO_ext
#    = 'ªµºÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ';

######################################################################################
# http://www.pemberley.com/janeinfo/latin1.html
# The CP1252 characters that are not part of ANSI/ISO 8859-1, and that should therefore
# always be encoded as Unicode characters greater than 255, are the following:

# Windows   Unicode    Char.
#  char.   HTML code   test         Description of Character
#  -----     -----     ---          ------------------------
#ALT-0130   &#8218;   â    Single Low-9 Quotation Mark
#ALT-0131   &#402;    Ä    Latin Small Letter F With Hook
#ALT-0132   &#8222;   ã    Double Low-9 Quotation Mark
#ALT-0133   &#8230;   É    Horizontal Ellipsis
#ALT-0134   &#8224;        Dagger
#ALT-0135   &#8225;   à    Double Dagger
#ALT-0136   &#710;    ö    Modifier Letter Circumflex Accent
#ALT-0137   &#8240;   ä    Per Mille Sign
#ALT-0138   &#352;    ?    Latin Capital Letter S With Caron
#ALT-0139   &#8249;   Ü    Single Left-Pointing Angle Quotation Mark
#ALT-0140   &#338;    Î    Latin Capital Ligature OE
#ALT-0145   &#8216;   Ô    Left Single Quotation Mark
#ALT-0146   &#8217;   Õ    Right Single Quotation Mark
#ALT-0147   &#8220;   Ò    Left Double Quotation Mark
#ALT-0148   &#8221;   Ó    Right Double Quotation Mark
#ALT-0149   &#8226;   ¥    Bullet
#ALT-0150   &#8211;   Ð    En Dash
#ALT-0151   &#8212;   Ñ    Em Dash
#ALT-0152   &#732;    ÷    Small Tilde
#ALT-0153   &#8482;   ª    Trade Mark Sign
#ALT-0154   &#353;    ?    Latin Small Letter S With Caron
#ALT-0155   &#8250;   Ý    Single Right-Pointing Angle Quotation Mark
#ALT-0156   &#339;    Ï    Latin Small Ligature OE
#ALT-0159   &#376;    Ù    Latin Capital Letter Y With Diaeresis
#
#######################################################################################

# NOTE that all the Char tests will likely fail above unless your terminal/editor
# supports Unicode

# browsers should support these numbers, and in order for perl < 5.8 to work correctly,
# we add the most common if missing

#%unicodes = (
#    8218 => "'",
#    402  => 'f',
#    8222 => '"',
#    8230 => '...',
#    8224 => 't',
#    8225 => 't',
#    8216 => "'",
#    8217 => "'",
#    8220 => '"',
#    8221 => '"',
#    8226 => '*',
#    8211 => '-',
#    8212 => '-',
#    732  => '~',
#    8482 => '(TM)',
#    376  => 'Y',
#    352  => 'S',
#    353  => 's',
#    8250 => '>',
#    8249 => '<',
#    710  => '^',
#    338  => 'OE',
#    339  => 'oe',
#);
#
#for ( keys %unicodes ) {
#
#    # quotemeta required since build_regexp will look for the \
#    my $ascii = quotemeta( $unicodes{$_} );
#    next if length $ascii > 2;
#
#    #warn "pushing $_ into $ascii\n";
#    push( @{ $codeunis{$ascii} }, $_ );
#}

################################################################################

sub BUILD {
    my $self = shift;

    $self->{debug} ||= 0;

    #dump $self;
    $self->_setup_back_compat();
    $self->_setup();

    #dump $self;

    return $self;
}

sub _setup_back_compat {
    my $self = shift;

    if ( defined( $self->{Print} ) && $self->{Print} == 0 ) {
        $self->{print_stream} = 0;
    }
    if ( exists $self->{TagFilter} ) {
        $self->{tag_filter} = delete $self->{TagFilter};
    }
    if ( exists $self->{TextFilter} ) {
        $self->{text_filter} = delete $self->{TextFilter};
    }
    if ( exists $self->{HiTag} ) {
        $self->{tag} = delete $self->{HiTag};
    }
    if ( exists $self->{HiClass} ) {
        $self->{class} = delete $self->{HiClass};
    }
    if ( exists $self->{Colors} ) {
        $self->{colors} = delete $self->{Colors};
    }
    if ( exists $self->{Links} ) {
        $self->{hilite_links} = delete $self->{Links};
    }

    if ( exists $self->{noplain} ) {
        carp
            "'noplain' is deprecated, and is always performed automatically.";
    }

}

sub _setup {
    my $self = shift;

    if ( exists $self->{parser} && $self->{parser} == 0 ) {
        croak
            "use Search::Tools::HiLiter directly instead of HTML::HiLiter without a parser";
    }

    $self->{_terms_regex} = $self->{query}->terms_as_regex;
}

sub _init_hiliter {
    my $self = shift;
    return Search::Tools::HiLiter->new(
        tag        => $self->tag,
        class      => $self->class,
        colors     => $self->colors,
        style      => $self->style,
        text_color => $self->text_color,
        query      => $self->query,
        tty        => $self->tty,
        debug      => $self->debug,
    );
}

sub _handle_tag {
    my ($self,   $parser,     $tag,  $tagname, $offset,
        $length, $offset_end, $attr, $text
    ) = @_;

    my $is_end_tag = $tag =~ m/^\//;

    # $tag has ! for declarations and / for endtags
    # $tagname is just bare tagname

    if ( $self->debug >= 3 ) {
        print { $self->{fh} } $open_comment;
        print { $self->{fh} } "\n" . '=' x 20 . "\n";
        print { $self->{fh} } "Tag          :$tag:\n";
        print { $self->{fh} } "TagName      :$tagname:\n";
        print { $self->{fh} } "Offset       :$offset\n";
        print { $self->{fh} } "Length       :$length\n";
        print { $self->{fh} } "Offset_end   :$offset_end\n";
        print { $self->{fh} } "Text         :$text\n";
        print { $self->{fh} } "Attr         :" . dump($attr) . "\n";
        print { $self->{fh} } "skipping_tag :$self->{_skipping_tag}:\n";
        print { $self->{fh} } "is_end_tag   :$is_end_tag\n";
        print { $self->{fh} } $close_comment;
    }

    # turn HiLiting ON if we are not inside the <head> tagset.
    # this prevents us from hiliting a <title> for example.
    if ( !$self->{_is_hiliting} ) {
        if ( !exists $HTML::Tagset::isHeadElement{$tagname} ) {
            $self->debug and carp "turning is_hiliting on for <$tag>";
            $self->{_is_hiliting} = 1;
        }
        else {

            $self->_meta_charset_check( $tag, $attr, \$text );

            # still in <head> section. handle and continue.
            if ( $self->{print_stream} ) {
                print { $self->{fh} } $text;
            }
            else {
                $self->{output_buffer} .= $text;
            }
            return;
        }
    }

    if ($is_end_tag) {
        $self->_handle_end_tag( $parser, $tag, $tagname, $offset, $length,
            $offset_end, $attr, $text );
    }
    else {
        $self->_handle_start_tag( $parser, $tag, $tagname, $offset, $length,
            $offset_end, $attr, $text );
    }
}

sub _meta_charset_check {
    my ( $self, $tag, $attr, $text ) = @_;

    # if this is a meta tag, check for encoding. we want to make sure
    # we do not declare anything other than utf-8 or ascii in the output,
    # since Search::Tools::HiLiter always returns utf-8.
    if ( lc($tag) eq 'meta' ) {
        if ( exists $attr->{'http-equiv'} or exists $attr->{'HTTP-EQUIV'} ) {
            if ( exists $attr->{content} or exists $attr->{CONTENT} ) {
                my $name    = $attr->{'http-equiv'} || $attr->{'HTTP-EQUIV'};
                my $content = $attr->{content}      || $attr->{CONTENT};
                if (   lc($name) eq 'content-type'
                    && lc($content) !~ m/ascii|utf-8/i )
                {
                    $$text
                        = qq(<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>);
                }
            }
        }
    }
}

sub _handle_end_tag {
    my ($self,   $parser,     $tag,  $tagname, $offset,
        $length, $offset_end, $attr, $text
    ) = @_;

    if ( $self->{_skipping_tag} eq $tagname ) {

        # should be endtag
        $self->{_skipping_tag} = '';
    }

    $self->{_buffer} .= $text;

    if ( !$HTML::Tagset::isPhraseMarkup{$tagname} or lc($tag) eq '/head' ) {
        $self->_flush_buffer();
    }

}

sub _matches_any_term {
    my $self = shift;
    my $buf  = shift;

    $self->debug and carp "check '$buf' against $self->{_terms_regex}";

    return $buf =~ m/$self->{_terms_regex}/;
}

sub _flush_buffer {
    my ($self) = @_;

    if ( !length $self->{_buffer} ) {
        return;
    }

    # if we have a buffer limit defined and the current $buffer
    # length exceeds that limit, deal with it immediately
    # and don't highlight
    if ((   $self->{buffer_limit}
            && length( $self->{_buffer} ) > $self->{buffer_limit}
        )
        || ( !$self->{_is_hiliting} )
        )
    {
        if ( $self->{print_stream} ) {
            print { $self->{fh} } $self->{_buffer};
        }
        else {
            $self->{output_buffer} .= $self->{_buffer};
        }
    }
    else {

        # otherwise, call the hiliter on $buffer
        # this is the main event

        $self->debug and carp "flushing buffer";

        my $hilited;

        if ( $self->_matches_any_term( $self->{_decoded_buffer} ) ) {
            $hilited = $self->apply_hiliting( $self->{_buffer} );
        }
        else {
            $hilited = $self->{_buffer};
        }

        # remove any markers we inserted to skip hiliting.
        # doing it in 2 expressions instead of |'d together single expre
        # is much faster, nytprof tells me.
        $hilited =~ s/\002//g;
        $hilited =~ s/\003//g;

        if ( $self->{print_stream} ) {
            print { $self->{fh} } $hilited;
        }
        else {
            $self->{output_buffer} .= $hilited;
        }

    }

    $self->{_buffer} = '';
}

sub _handle_start_tag {
    my ($self,   $parser,     $tag,  $tagname, $offset,
        $length, $offset_end, $attr, $text
    ) = @_;

    if ( $attr->{nohiliter} ) {

        # we want to not highlight this tag's contents

        $self->{_skipping_tag} = $tagname;

        #warn "skipping <$tag> with nohiliter\n";

    }

    # if we encounter an inline tag, add it to the buffer
    # for later evaluation
    # PhraseMarkup is closest to libxml2 'inline' definition
    if ( $HTML::Tagset::isPhraseMarkup{$tagname} ) {

        my $tag_filter = $self->{tag_filter};
        my $reassemble
            = defined $tag_filter
            ? $tag_filter->(
            $parser, $tag, $tagname, $offset, $length, $offset_end, $attr,
            $text
            )
            : $text;

        warn "$open_comment adding :$reassemble: to buffer $close_comment"
            if $self->debug >= 3;

        # add to the buffer for later evaluation as a potential match
        $self->{_buffer} .= $reassemble;

        #warn "INLINEBUFFER:$buffer:INLINEBUFFER";

        return;

    }

    # flush the buffer before handling this tag.
    $self->_flush_buffer();

    # now handle this tag
    $self->_reset_state();

    # use reassemble to futz with attribute values or tagnames
    # before printing them.
    # otherwise, default to what we have in original HTML
    #
    # NOTE: this is where we could change HREF values, for example

    my $tag_filter = $self->{tag_filter};
    my $reassemble
        = defined $tag_filter
        ? $tag_filter->(
        $parser, $tag, $tagname, $offset, $length, $offset_end, $attr, $text
        )
        : $text;

    if ( $self->{print_stream} ) {
        print { $self->{fh} } $reassemble;
    }
    else {
        $self->{_buffer} .= $reassemble;
    }

    # if this is the opening <head> tag,
    # add the <style> declarations for the hiliting
    # this lets later <link css> tags in a doc
    # override our local <style>

    if ( lc($tag) eq 'head' ) {
        if ( $self->{print_stream} ) {
            print { $self->{fh} } $self->{style_header}
                if $self->{style_header};
        }
        else {
            $self->{_buffer} .= $self->{style_header}
                if $self->{style_header};
        }
    }

}

sub _handle_text {
    my ( $self, $parser, $decoded_text, $text, $offset, $length ) = @_;
    my $text_filter = $self->{text_filter};
    my $filtered
        = defined $text_filter
        ? $text_filter->( $parser, $decoded_text, $text, $offset, $length )
        : $text;

    if ( !$self->{_is_hiliting} ) {

        # still in <head> section. handle and continue.
        if ( $self->{print_stream} ) {
            print { $self->{fh} } $filtered;
        }
        else {
            $self->{output_buffer} .= $filtered;
        }
        return;
    }

    # remember decoded to eval before calling hilite()
    # this replaces the addtional 'tagless' algorithm
    # that hilite() was doing
    $self->{_decoded_buffer} .= $decoded_text;

    if ( $self->{_skipping_tag} ) {

      # we don't want to highlight this text but we do want to output it later
      # so delimit the text with the NULL character and skip that fragment
      # in hilite()

        $self->{_buffer} .= "\002" . $filtered . "\003";
    }
    else {
        $self->{_buffer} .= $filtered;
    }

    if ( $self->debug >= 3 ) {
        print { $self->{fh} } $open_comment
            . "text         :$text:\n"
            . "filtered     :$filtered:\n";
        print { $self->{fh} } "Added text to buffer\n"
            if $self->{_is_hiliting};
        print { $self->{fh} } "decoded      :$decoded_text:\n"
            . "Offset       :$offset\n"
            . "Length       :$length\n"
            . $close_comment;
    }

}

sub _check_count {
    my $self = shift;

    # return total count for all keys
    my $done;
    for ( sort keys %{ $_[0] } ) {
        $done += $_[0]->{$_};
        if ( $self->debug >= 1 and $_[0]->{$_} > 0 ) {
            print { $self->{fh} }
                "$open_comment $_[0]->{$_} remaining to hilite for: $_ $close_comment";
        }
    }
    return $done;
}

sub Queries {
    croak "Queries() is deprecated. Set the 'query' param in new()";
}

sub _reset_state {
    my $self = shift;
    $self->{_buffer}         = '';
    $self->{_skipping_tag}   = '';
    $self->{_decoded_buffer} = '';
    return $self;
}

sub _reset_output_buffer {
    my $self = shift;
    $self->{output_buffer} = '';
    return $self;
}

sub _handle_default {
    my ( $self, $parser, $text ) = @_;
    if ( $self->{print_stream} ) {
        print { $self->{fh} } $text;
    }
    else {
        $self->{_buffer} .= $text;
    }
}

*Run = \&run;

sub run {
    my $self   = shift;
    my $string = shift;
    if ( !defined $string ) {
        croak "file or string required";
    }
    $self->{_is_hiliting} = 0;
    $self->_reset_output_buffer;
    $self->_reset_state;

    my $parser = HTML::Parser->new(
        unbroken_text => 1,
        api_version   => 3,
        text_h        => [
            sub { $self->_handle_text(@_) },
            'self,dtext,text,offset,length'
        ],
        start_h => [
            sub { $self->_handle_tag(@_) },
            'self,tag,tagname,offset,length,offset_end,attr,text'
        ],
        end_h => [
            sub { $self->_handle_tag(@_) },
            'self,tag,tagname,offset,length,offset_end,undef,text'
        ],
        default_h => [ sub { $self->_handle_default(@_) }, 'self,text' ]
    );

    my $return;
    if ( !ref($string) && -e $string ) {
        $return = $parser->parse( to_utf8( Search::Tools->slurp($string) ) );
    }
    elsif ( $string =~ m/^https?:\/\//i ) {
        $return = $parser->parse( to_utf8( $self->_get_url($string) ) );
    }
    elsif ( ref $string eq 'SCALAR' ) {
        $return = $parser->parse( to_utf8($$string) );
    }
    else {
        croak
            "$string is neither a file nor a filehandle nor a scalar ref!\n";
    }

    if ( !$return ) {
        $self->{error} = $!;    # TODO correct error msg?
    }
    if ( !$self->{print_stream} ) {
        $self->{output_buffer} .= "\n";
    }
    else {
        print { $self->{fh} }
            "\n";               # does parser intentionlly chomp last line?
    }

    # reset parser -- TODO need this since it goes out of scope here?
    $parser->eof;

    return $self->{output_buffer} || $return;
}

sub apply_hiliting {
    my $self = shift;
    my $str  = shift;
    if ( !defined $str ) {
        croak "string required";
    }
    return $self->hiliter->light($str);
}

sub _get_url {

    require HTTP::Request;
    require LWP::UserAgent;

    my $self = shift;
    my $url = shift || return;

    my ( $http_ua, $request, $response, $content_type, $buf, $size );

    $http_ua  = LWP::UserAgent->new;
    $request  = HTTP::Request->new( GET => $url );
    $response = $http_ua->request($request);
    $content_type ||= '';
    if ( $response->is_error ) {
        warn "Error: Couldn't get '$url': response code "
            . $response->code . "\n";
        return;
    }

    if ( $response->headers_as_string =~ m/^Content-Type:\s*(.+)$/im ) {
        $content_type = $1;
        $content_type =~ s/^(.*?);.*$/$1/;  # ignore possible charset value???
    }

    $buf  = $response->content;
    $size = length($buf);

    $url = $response->base;
    return ( $buf, $url, $response->last_modified, $size, $content_type );

}

1;

__END__

=pod

=head1 NAME

HTML::HiLiter - highlight words in an HTML document just like a felt-tip HiLiter

=head1 SYNOPSIS

 use HTML::HiLiter;
 
 my $hiliter = new HTML::HiLiter(
  word_characters   =>  '\w\-\.',
  ignore_first_char =>  '\-\.',
  ignore_last_char  =>  '\-\.',
  tag               =>	'span',
  colors            =>	[ qw(#FFFF33 yellow pink) ],
  tag_filter        =>	\&yourtagcode(),
  text_filter       =>	\&yourtextcode(),
  query             =>  'foo bar or "some phrase"',
 );
 
 $hiliter->run($some_file_or_URL);

=head1 DESCRIPTION

HTML::HiLiter is designed to make highlighting search queries
in HTML easy and accurate. HTML::HiLiter was designed for CrayDoc 4, the
Cray documentation server.

As of verison 0.14, HTML::HiLiter has been completely re-written with a new API,
using Search::Tools.

=head1 REQUIREMENTS

The following are required:

=over

=item

Perl version 5.8.3 or later (for proper UTF-8 support).

=item

Search::Tools 0.25 or later.

=item

HTML::Parser

=back

Required to use the HTTP option in the run() method:

=over

=item

HTTP::Request 

=item

LWP::UserAgent

=back

=head1 FEATURES

A cornucopia of features.

=over

=item *

HTML::HiLiter parses HTML chunk by chunk, buffering all text
within an HTML block element before applying highlighting to the buffer.

The default behavior is to print() all the HTML, highlighted or not,
as soon as it is evaluated. You can change that behavior with the 
B<print_stream> parameter in new(), which will instead cache all the HTML
and return it as a scalar string from run().

Otherwise, you can direct the print() to a filehandle with the
fh() param/method.

=item *

Turn highlighting off on a per-tagset basis with the custom HTML "nohiliter" attribute. 
Set the attribute to a b<true> value (like 1) to turn off
highlighting for the duration of that tag.

=item *

Ample debugging. Set the B<debug> param to a level between 1 and 3,
and lots of debugging info will be printed within HTML comments <!-- -->.

=item *

Smart context. Won't highlight across an HTML block element like a <p></p> 
tagset or a <div></div> tagset. (IMHO, your indexing software shouldn't consider 
matches for phrases that span across those tags either.)

=item *

Rotating colors. Each query gets a unique color. The default is four different 
colors, which will repeat if you have more than four terms in a single 
query. You can define more or different colors in the new() object call.

=item *

CSS support. You can alter the highlighting markup used with the B<tag>, B<class>,
B<style> and B<text_color> parameters. See the documentation for Search::Tools::HiLiter.

=back

=head1 METHODS

=head2 new()

Create a HiLiter object.

Any parameter that can be passed to Search::Tools::HiLiter can be passed to HTML::HiLiter.
In addition, the following HTML::HiLiter-specific parameters are supported:

=over

=item fh

The filehandle to send output to. Defaults to STDOUT. If print_stream is false,
will buffer instead of printing.

=item hiliter

Set a Search::Tools::HiLiter object for HTML::HiLiter to use. If you do not set one,
one will be created based on the other parameters you pass.

=item tag_filter

A CODE reference of your choosing for filtering HTML tags as they pass through the
HTML::Parser. See L<FILTERS>.

=item text_filter

A CODE reference of your choosing for filtering HTML text as it passes through the
HTML::Parser. See L<FILTERS>.

=item buffer_limit

When the number of characters in the HTML buffer exceeds the value of buffer_limit,
the buffer is printed without highlighting being attempted. The default is 2**16
characters. Make this higher at your peril. Most HTML will not exceed more than that
n a <p> tagset, for example.

=item print_stream

Default value true (1). Print highlighted HTML as the HTML::Parser encounters it.
If true, use a select() in your script to print somewhere besides the
perl default of STDOUT. 

NOTE: Set this to 0 (B<false>) only if you are highlighting small chunks of HTML
(i.e., smaller than I<buffer_limit>). See run().

=back

=head2 BUILD 

Called internally by new().

=head2 query

Get the Search::Tools::Query object created in new().

=head2 style_header( I<html> )

If set, I<html> will be applied just after the opening <head> tag while parsing.
This is to allow insertion of CSS or other head-appropriate markup.

=head2 apply_hiliting( I<string> )

Passes I<string> through Search::Tools::HiLiter->light() and returns I<string>
highlighted.

=head2 Queries

This method is deprecated. See the B<query> param to new() instead.

=head2 run( I<$file | $url | \$html> )

run() takes either a file name, a URL (indicated by a leading 'http://'),
or a scalar reference to a string of HTML text.

=head2 Run

For backwards compatability, Run() is an alias for run().

=head1 FILTERS

I<text_filter> and I<tag_filter> are two optional parameters that allow you to filter
the contents of your HTML beyond normal highlighting. Each parameter takes a CODE
reference.

I<text_filter> should expect these parameters in this order:

I<parserobj>, I<dtext>, I<text>, I<offset>, I<length>

I<tag_filter> should expect these parameters in this order:

I<parserobj>, I<tag>, I<tagname>, I<offset>, I<length>, I<offset_end>, I<attr>, I<text>

Both should return a scalar string of text. I<tag_filter> should return a set of attributes. 
I<text_filter> may return whatever you want. See L<EXAMPLES> and the L<HTML::Parser> documentation 
for what these parameters mean and for more about writing filters.


=head1 EXAMPLES

See F<examples/> directory in source distribution.


=head1 HISTORY

Yet another highlighting module?

My goal was complete, exhaustive, tear-your-hair-out efforts to highlight HTML.
No other modules I found on the web supported nested tags within words and phrases,
or character entities. Cray uses the standard DocBook stylesheets from Norm Walsh et al,
to generate HTML. These stylesheets produce valid HTML but often fool the other
highlighters I found.

The problem became most evident when we started using Swish-e. Swish-e does such
a good job at converting entities and doing phrase matching that we found ourselves
in a dilemma: Swish-e often gave valid search results that mere mortal highlighters
could not match in the source HTML -- not even the SWISH::*Highlight modules.

With the exception of the 'nohiliter' attribute,
I think I follow the W3C HTML 4.01 specification. Please prove me wrong.

B<Prime Example> of where this module overcomes other attempts by other modules.

The query 'bold in the middle' should match this HTML:

   <p>some phrase <b>with <i>b</i>old</b> in&nbsp;the middle</p>

GOOD highlighting:

   <p>some phrase <b>with <i><span>b</span></i><span>old</span></b><span>
   in&nbsp;the middle</span></p>

BAD highlighting:

   <p>some phrase <b>with <span><i>b</i>bold</b> in&nbsp;the middle</span></p>


No module I tried in my tests could even find that as a match (let alone perform
bad highlighting on it), even though indexing programs like Swish-e would consider
a document with that HTML a valid match.

=head2 Should you use this module?

I would suggest 
B<not> using HTML::HiLiter if your HTML is fairly simple, since in 
HTML::HiLiter, speed has been sacrificed for accuracy and rich features.
Check out L<HTML::Highlight> instead.

Unlike other highlighting code I've found, HTML::HiLiter supports nested tags and
character entities, such as might be found in technical documentation or HTML
generated from some other source (like DocBook SGML or XML). 

The goal is server-side highlighting that looks as if you used a felt-tip marker
on the HTML page. You shouldn't need to know what the underlying tags and entities and
encodings are: you just want to easily highlight some text B<as your browser presents it>.

=head1 TODO

=over

=item *

More tests.

=item *

Restore highlighting of link text, which was dropped in 0.14 with the Search::Tools rewrite.
Highlight IMG tags where ALT attribute matches query??

=back

=head1 KNOWN BUGS AND LIMITATIONS

Will not highlight literal parentheses ().

Phrases that contain stopwords may not highlight correctly. It's more a problem of *which*
stopword the original doc used and is not an intrinsic problem with the HiLiter, but
noted here for completeness' sake.

=head1 AUTHOR

Peter Karman, karman@cray.com

Thanks to the Swish-e developers, in particular Bill Moseley for graciously
sharing time, advice and code examples.

Comments and suggestions are welcome.

=head1 COPYRIGHT

 ###############################################################################
 #    CrayDoc 4
 #    Copyright (C) 2004 Cray Inc swpubs@cray.com
 #
 #    This program is free software; you can redistribute it and/or modify
 #    it under the terms of the GNU General Public License as published by
 #    the Free Software Foundation; either version 2 of the License, or
 #    (at your option) any later version.
 #
 #    This program is distributed in the hope that it will be useful,
 #    but WITHOUT ANY WARRANTY; without even the implied warranty of
 #    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 #    GNU General Public License for more details.
 #
 #    You should have received a copy of the GNU General Public License
 #    along with this program; if not, write to the Free Software
 #    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 ###############################################################################


=head1 SUPPORT

Send email to swpubs@cray.com.

=head1 SEE ALSO

L<Search::Tools>, L<HTML::Parser>

=cut
