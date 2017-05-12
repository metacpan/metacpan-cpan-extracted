=head1 NAME

HTML::TagParser - Yet another HTML document parser with DOM-like methods

=head1 SYNOPSIS

Parse a HTML file and find its <title> element's value.

    my $html = HTML::TagParser->new( "index-j.html" );
    my $elem = $html->getElementsByTagName( "title" );
    print "<title>", $elem->innerText(), "</title>\n" if ref $elem;

Parse a HTML source and find its first <form action=""> attribute's value
and find all input elements belonging to this form.

    my $src  = '<html><form action="hoge.cgi">...</form></html>';
    my $html = HTML::TagParser->new( $src );
    my $elem = $html->getElementsByTagName( "form" );
    print "<form action=\"", $elem->getAttribute("action"), "\">\n" if ref $elem;
    my @first_inputs = $elem->subTree()->getElementsByTagName( "input" );
    my $form = $first_inputs[0]->getParent();

Fetch a HTML file via HTTP, and display its all <a> elements and attributes.

    my $url  = 'http://www.kawa.net/xp/index-e.html';
    my $html = HTML::TagParser->new( $url );
    my @list = $html->getElementsByTagName( "a" );
    foreach my $elem ( @list ) {
        my $tagname = $elem->tagName;
        my $attr = $elem->attributes;
        my $text = $elem->innerText;
        print "<$tagname";
        foreach my $key ( sort keys %$attr ) {
            print " $key=\"$attr->{$key}\"";
        }
        if ( $text eq "" ) {
            print " />\n";
        } else {
            print ">$text</$tagname>\n";
        }
    }

=head1 DESCRIPTION

HTML::TagParser is a pure Perl module which parses HTML/XHTML files.
This module provides some methods like DOM interface.
This module is not strict about XHTML format
because many of HTML pages are not strict.
You know, many pages use <br> elemtents instead of <br/>
and have <p> elements which are not closed.

=head1 METHODS

=head2 $html = HTML::TagParser->new();

This method constructs an empty instance of the C<HTML::TagParser> class.

=head2 $html = HTML::TagParser->new( $url );

If new() is called with a URL,
this method fetches a HTML file from remote web server and parses it
and returns its instance.
L<URI::Fetch> module is required to fetch a file.

=head2 $html = HTML::TagParser->new( $file );

If new() is called with a filename,
this method parses a local HTML file and returns its instance

=head2 $html = HTML::TagParser->new( "<html>...snip...</html>" );

If new() is called with a string of HTML source code,
this method parses it and returns its instance.

=head2 $html->fetch( $url, %param );

This method fetches a HTML file from remote web server and parse it.
The second argument is optional parameters for L<URI::Fetch> module.

=head2 $html->open( $file );

This method parses a local HTML file.

=head2 $html->parse( $source );

This method parses a string of HTML source code.

=head2 $elem = $html->getElementById( $id );

This method returns the element which id attribute is $id.

=head2 @elem = $html->getElementsByName( $name );

This method returns an array of elements which name attribute is $name.
On scalar context, the first element is only retruned.

=head2 @elem = $html->getElementsByTagName( $tagname );

This method returns an array of elements which tagName is $tagName.
On scalar context, the first element is only retruned.

=head2 @elem = $html->getElementsByClassName( $class );

This method returns an array of elements which className is $tagName.
On scalar context, the first element is only retruned.

=head2 @elem = $html->getElementsByAttribute( $attrname, $value );

This method returns an array of elements which $attrname attribute's value is $value.
On scalar context, the first element is only retruned.

=head1 HTML::TagParser::Element SUBCLASS

=head2 $tagname = $elem->tagName();

This method returns $elem's tagName.

=head2 $text = $elem->id();

This method returns $elem's id attribute.

=head2 $text = $elem->innerText();

This method returns $elem's innerText without tags.

=head2 $subhtml = $elem->subTree();

This method returns a new object of class HTML::Parser,
with all the elements that are in the DOM hierarchy under $elem.

=head2 $elem = $elem->nextSibling();

This method returns the next sibling within the same parent.
It returns undef when called on a closing tag or on the lastChild node
of a parentNode.

=head2 $elem = $elem->previousSibling();

This method returns the previous sibling within the same parent.
It returns undef when called on the firstChild node of a parentNode.

=head2 $child_elem = $elem->firstChild();

This method returns the first child node of $elem.
It returns undef when called on a closing tag element or on a
non-container or empty container element.

=head2 $child_elems = $elem->childNodes();

This method creates an array of all child nodes of $elem and returns the array by reference.
It returns an empty array-ref [] whenever firstChild() would return undef.

=head2 $child_elem = $elem->lastChild();

This method returns the last child node of $elem.
It returns undef whenever firstChild() would return undef.

=head2 $parent = $elem->parentNode();

This method returns the parent node of $elem.
It returns undef when called on root nodes.

=head2 $attr = $elem->attributes();

This method returns a hash of $elem's all attributes.

=head2 $value = $elem->getAttribute( $key );

This method returns the value of $elem's attributes which name is $key.

=head1 BUGS

The HTML-Parser is simple. Methods innerText and subTree may be
fooled by nested tags or embedded javascript code.

The methods with 'Sibling', 'child' or 'Child' in their names do not cache their results.
The most expensive ones are lastChild() and previousSibling().
parentNode() is also expensive, but only once. It does caching.

The DOM tree is read-only, as this is just a parser.

=head1 INTERNATIONALIZATION

This module natively understands the character encoding used in document
by parsing its meta element.

    <meta http-equiv="Content-Type" content="text/html; charset=Shift_JIS">

The parsed document's encoding is converted
as this class's fixed internal encoding "UTF-8".

=head1 AUTHORS AND CONTRIBUTORS

    drry [drry]
    Juergen Weigert [jnw]
    Yusuke Kawasaki [kawasaki] [kawanet]
    Tim Wilde [twilde]

=head1 COPYRIGHT AND LICENSE

The following copyright notice applies to all the files provided in this
distribution, including binary files, unless explicitly noted otherwise.

Copyright 2006-2012 Yusuke Kawasaki

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
# ----------------------------------------------------------------

package HTML::TagParser;
use 5.008_001;
use strict;
use Symbol ();
use Carp ();
use Encode ();

our $VERSION = "0.20";

my $SEC_OF_DAY = 60 * 60 * 24;

#  [000]        '/' if closing tag.
#  [001]        tagName
#  [002]        attributes string (with trailing /, if self-closing tag).
#  [003]        content until next (nested) tag.
#  [004]        attributes hash cache.
#  [005]        innerText combined strings cache.
#  [006]        index of matching closing tag (or opening tag, if [000]=='/')
#  [007]        index of parent (aka container) tag.
#
sub new {
    my $package = shift;
    my $src     = shift;
    my $self    = {};
    bless $self, $package;
    return $self unless defined $src;

    if ( $src =~ m#^https?://\w# ) {
        $self->fetch( $src, @_ );
    }
    elsif ( $src !~ m#[<>|]# && -f $src ) {
        $self->open($src);
    }
    elsif ( $src =~ /<.*>/ ) {
        $self->parse($src);
    }

    $self;
}

sub fetch {
    my $self = shift;
    my $url  = shift;
    if ( !defined $URI::Fetch::VERSION ) {
        local $@;
        eval { require URI::Fetch; };
        Carp::croak "URI::Fetch is required: $url" if $@;
    }
    my $res = URI::Fetch->fetch( $url, @_ );
    Carp::croak "URI::Fetch failed: $url" unless ref $res;
    return if $res->is_error();
    $self->{modified} = $res->last_modified();
    my $text = $res->content();
    $self->parse( \$text );
}

sub open {
    my $self = shift;
    my $file = shift;
    my $text = HTML::TagParser::Util::read_text_file($file);
    return unless defined $text;
    my $epoch = ( time() - ( -M $file ) * $SEC_OF_DAY );
    $epoch -= $epoch % 60;
    $self->{modified} = $epoch;
    $self->parse( \$text );
}

sub parse {
    my $self   = shift;
    my $text   = shift;
    my $txtref = ref $text ? $text : \$text;

    my $charset = HTML::TagParser::Util::find_meta_charset($txtref);
    $self->{charset} ||= $charset;
    if ($charset && Encode::find_encoding($charset)) {
        HTML::TagParser::Util::encode_from_to( $txtref, $charset, "utf-8" );
    }
    my $flat = HTML::TagParser::Util::html_to_flat($txtref);
    Carp::croak "Null HTML document." unless scalar @$flat;
    $self->{flat} = $flat;
    scalar @$flat;
}

sub getElementsByTagName {
    my $self    = shift;
    my $tagname = lc(shift);

    my $flat = $self->{flat};
    my $out = [];
    for( my $i = 0 ; $i <= $#$flat ; $i++ ) {
        next if ( $flat->[$i]->[001] ne $tagname );
        next if $flat->[$i]->[000];                 # close
        my $elem = HTML::TagParser::Element->new( $flat, $i );
        return $elem unless wantarray;
        push( @$out, $elem );
    }
    return unless wantarray;
    @$out;
}

sub getElementsByAttribute {
    my $self = shift;
    my $key  = lc(shift);
    my $val  = shift;

    my $flat = $self->{flat};
    my $out  = [];
    for ( my $i = 0 ; $i <= $#$flat ; $i++ ) {
        next if $flat->[$i]->[000];    # close
        my $elem = HTML::TagParser::Element->new( $flat, $i );
        my $attr = $elem->attributes();
        next unless exists $attr->{$key};
        next if ( $attr->{$key} ne $val );
        return $elem unless wantarray;
        push( @$out, $elem );
    }
    return unless wantarray;
    @$out;
}

sub getElementsByClassName {
    my $self  = shift;
    my $class = shift;
    return $self->getElementsByAttribute( "class", $class );
}

sub getElementsByName {
    my $self = shift;
    my $name = shift;
    return $self->getElementsByAttribute( "name", $name );
}

sub getElementById {
    my $self = shift;
    my $id   = shift;
    return scalar $self->getElementsByAttribute( "id", $id );
}

sub modified {
    $_[0]->{modified};
}

# ----------------------------------------------------------------

package HTML::TagParser::Element;
use strict;

sub new {
    my $package = shift;
    my $self    = [@_];
    bless $self, $package;
    $self;
}

sub tagName {
    my $self = shift;
    my ( $flat, $cur ) = @$self;
    return $flat->[$cur]->[001];
}

sub id {
    my $self = shift;
    $self->getAttribute("id");
}

sub getAttribute {
    my $self = shift;
    my $name = lc(shift);
    my $attr = $self->attributes();
    return unless exists $attr->{$name};
    $attr->{$name};
}

sub innerText {
    my $self = shift;
    my ( $flat, $cur ) = @$self;
    my $elem = $flat->[$cur];
    return $elem->[005] if defined $elem->[005];    # cache
    return if $elem->[000];                         # </xxx>
    return if ( defined $elem->[002] && $elem->[002] =~ m#/$# ); # <xxx/>

    my $tagname = $elem->[001];
    my $closing = HTML::TagParser::Util::find_closing($flat, $cur);
    my $list    = [];
    for ( ; $cur < $closing ; $cur++ ) {
        push( @$list, $flat->[$cur]->[003] );
    }
    my $text = join( "", grep { $_ ne "" } @$list );
    $text =~ s/^\s+|\s+$//sg;
#   $text = "" if ( $cur == $#$flat );              # end of source
    $elem->[005] = HTML::TagParser::Util::xml_unescape( $text );
}

sub subTree
{
    my $self = shift;
    my ( $flat, $cur ) = @$self;
    my $elem = $flat->[$cur];
    return if $elem->[000];                         # </xxx>
    my $closing = HTML::TagParser::Util::find_closing($flat, $cur);
    my $list    = [];
    while (++$cur < $closing)
      {
        push @$list, $flat->[$cur];
      }

    # allow the getElement...() methods on the returned object.
    return bless { flat => $list }, 'HTML::TagParser';
}


sub nextSibling
{
    my $self = shift;
    my ( $flat, $cur ) = @$self;
    my $elem = $flat->[$cur];

    return undef if $elem->[000];                         # </xxx>
    my $closing = HTML::TagParser::Util::find_closing($flat, $cur);
    my $next_s = $flat->[$closing+1];
    return undef unless $next_s;
    return undef if $next_s->[000];     # parent's </xxx>
    return HTML::TagParser::Element->new( $flat, $closing+1 );
}

sub firstChild
{
    my $self = shift;
    my ( $flat, $cur ) = @$self;
    my $elem = $flat->[$cur];
    return undef if $elem->[000];                         # </xxx>
    my $closing = HTML::TagParser::Util::find_closing($flat, $cur);
    return undef if $closing <= $cur+1;                 # no children here.
    return HTML::TagParser::Element->new( $flat, $cur+1 );
}

sub childNodes
{
    my $self = shift;
    my ( $flat, $cur ) = @$self;
    my $child = firstChild($self);
    return [] unless $child;    # an empty array is easier for our callers than undef
    my @c = ( $child );
    while (defined ($child = nextSibling($child)))
      {
        push @c, $child;
      }
    return \@c;
}

sub lastChild
{
    my $c = childNodes(@_);
    return undef unless $c->[0];
    return $c->[-1];
}

sub previousSibling
{
    my $self = shift;
    my ( $flat, $cur ) = @$self;

    ## This one is expensive.
    ## We use find_closing() which walks forward.
    ## We'd need a find_opening() which walks backwards.
    ## So we walk backwards one by one and consult find_closing()
    ## until we find $cur-1 or $cur.

    my $idx = $cur-1;
    while ($idx >= 0)
      {
        if ($flat->[$idx][000] && defined($flat->[$idx][006]))
          {
            $idx = $flat->[$idx][006];  # use cache for backwards skipping
            next;
          }

        my $closing = HTML::TagParser::Util::find_closing($flat, $idx);
        return HTML::TagParser::Element->new( $flat, $idx )
          if defined $closing and ($closing == $cur || $closing == $cur-1);
        $idx--;
      }
    return undef;
}

sub parentNode
{
    my $self = shift;
    my ( $flat, $cur ) = @$self;

    return HTML::TagParser::Element->new( $flat, $flat->[$cur][007]) if $flat->[$cur][007];     # cache

    ##
    ## This one is very expensive.
    ## We use previousSibling() to walk backwards, and
    ## previousSibling() is expensive.
    ##
    my $ps = $self;
    my $first = $self;

    while (defined($ps = previousSibling($ps))) { $first = $ps; }

    my $parent = $first->[1] - 1;
    return undef if $parent < 0;
    die "parent too short" if HTML::TagParser::Util::find_closing($flat, $parent) <= $cur;

    $flat->[$cur][007] = $parent;       # cache
    return HTML::TagParser::Element->new( $flat, $parent )
}

##
## feature:
## self-closing tags have an additional attribute '/' => '/'.
##
sub attributes {
    my $self = shift;
    my ( $flat, $cur ) = @$self;
    my $elem = $flat->[$cur];
    return $elem->[004] if ref $elem->[004];    # cache
    return unless defined $elem->[002];
    my $attr = {};
    while ( $elem->[002] =~ m{
        ([^\s="']+)(\s*=\s*(?:["']((?(?<=")(?:\\"|[^"])*?|(?:\\'|[^'])*?))["']|([^'"\s=]+)['"]*))?
    }sgx ) {
        my $key  = $1;
        my $test = $2;
        my $val  = $3 || $4;
        my $lckey = lc($key);
        if ($test) {
            $key =~ tr/A-Z/a-z/;
            $val = HTML::TagParser::Util::xml_unescape( $val );
            $attr->{$lckey} = $val;
        }
        else {
            $attr->{$lckey} = $key;
        }
    }
    $elem->[004] = $attr;    # cache
    $attr;
}

# ----------------------------------------------------------------

package HTML::TagParser::Util;
use strict;

sub xml_unescape {
    my $str = shift;
    return unless defined $str;
    $str =~ s/&quot;/"/g;
    $str =~ s/&lt;/</g;
    $str =~ s/&gt;/>/g;
    $str =~ s/&amp;/&/g;
    $str;
}

sub read_text_file {
    my $file = shift;
    my $fh   = Symbol::gensym();
    open( $fh, $file ) or Carp::croak "$! - $file\n";
    local $/ = undef;
    my $text = <$fh>;
    close($fh);
    $text;
}

sub html_to_flat {
    my $txtref = shift;    # reference
    my $flat   = [];
    pos($$txtref) = undef;  # reset matching position
    while ( $$txtref =~ m{
        (?:[^<]*) < (?:
            ( / )? ( [^/!<>\s"'=]+ )
            ( (?:"[^"]*"|'[^']*'|[^"'<>])+ )?
        |
            (!-- .*? -- | ![^\-] .*? )
        ) > ([^<]*)
    }sxg ) {
        #  [000]  $1  close
        #  [001]  $2  tagName
        #  [002]  $3  attributes
        #         $4  comment element
        #  [003]  $5  content
        next if defined $4;
        my $array = [ $1, $2, $3, $5 ];
        $array->[001] =~ tr/A-Z/a-z/;
        #  $array->[003] =~ s/^\s+//s;
        #  $array->[003] =~ s/\s+$//s;
        push( @$flat, $array );
    }
    $flat;
}

## returns 1 beyond the end, if not found.
## returns undef if called on a </xxx> closing tag
sub find_closing
{
  my ($flat, $cur) = @_;

  return $flat->[$cur][006]        if   $flat->[$cur][006];     # cache
  return $flat->[$cur][006] = $cur if (($flat->[$cur][002]||'') =~ m{/$});    # self-closing

  my $name = $flat->[$cur][001];
  my $pre_nest = 0;
  ## count how many levels deep this type of tag is nested.
  my $idx;
  for ($idx = 0; $idx <= $cur; $idx++)
    {
      my $e = $flat->[$idx];
      next unless   $e->[001] eq $name;
      next if     (($e->[002]||'') =~ m{/$});   # self-closing
      $pre_nest += ($e->[000]) ? -1 : 1;
      $pre_nest = 0 if $pre_nest < 0;
      $idx = $e->[006]-1 if !$e->[000] && $e->[006];    # use caches for skipping forward.
    }
  my $last_idx = $#$flat;

  ## we move last_idx closer, in case this container
  ## has not all its subcontainers closed properly.
  my $post_nest = 0;
  for ($idx = $last_idx; $idx > $cur; $idx--)
    {
      my $e = $flat->[$idx];
      next unless    $e->[001] eq $name;
      $last_idx = $idx-1;               # remember where a matching tag was
      next if      (($e->[002]||'') =~ m{/$});  # self-closing
      $post_nest -= ($e->[000]) ? -1 : 1;
      $post_nest = 0 if $post_nest < 0;
      last if $pre_nest <= $post_nest;
      $idx = $e->[006]+1 if $e->[000] && defined $e->[006];     # use caches for skipping backwards.
    }

  my $nest = 1;         # we know it is not self-closing. start behind.

  for ($idx = $cur+1; $idx <= $last_idx; $idx++)
    {
      my $e = $flat->[$idx];
      next unless    $e->[001] eq $name;
      next if      (($e->[002]||'') =~ m{/$});  # self-closing
      $nest      += ($e->[000]) ? -1 : 1;
      if ($nest <= 0)
        {
          die "assert </xxx>" unless $e->[000];
          $e->[006] = $cur;     # point back to opening tag
          return $flat->[$cur][006] = $idx;
        }
      $idx = $e->[006]-1 if !$e->[000] && $e->[006];    # use caches for skipping forward.
    }

  # not all closed, but cannot go further
  return $flat->[$cur][006] = $last_idx+1;
}

sub find_meta_charset {
    my $txtref = shift;    # reference
    while ( $$txtref =~ m{
        <meta \s ((?: [^>]+\s )? http-equiv\s*=\s*['"]?Content-Type [^>]+ ) >
    }sxgi ) {
        my $args = $1;
        return $1 if ( $args =~ m# charset=['"]?([^'"\s/]+) #sxgi );
    }
    undef;
}

sub encode_from_to {
    my ( $txtref, $from, $to ) = @_;
    return     if ( $from     eq "" );
    return     if ( $to       eq "" );
    return $to if ( uc($from) eq uc($to) );
    Encode::from_to( $$txtref, $from, $to, Encode::XMLCREF() );
    return $to;
}

# ----------------------------------------------------------------
1;
# ----------------------------------------------------------------
