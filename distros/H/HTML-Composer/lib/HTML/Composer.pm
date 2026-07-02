# MIT License
#
# Copyright (c) 2026  Rawley Fowler <rawleyfowler@proton.me>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

package HTML::Composer;

=head1 NAME

HTML::Composer - Compose validated HTML from Perl data structures

=head1 SYNOPSIS

HTML::Composer is inspired by TyXML and Hiccup to provide a data-driven HTML builder for Perl that allows
developers to compose data to validated HTML in an efficient, intuitive, high-performance way.

  use HTML::Composer;
  
  my $h = HTML::Composer->new();
  my $html = $h->html([
          head => [
              title  => ["My Site"],
              script => {
                  src  => "/js/myScript.js",
                  type => "text/javascript"
              }
          ],
          body => [
              h1  => ["Hello World!"],
              br  => {},
              div => { class => [ "p-3", "background-red" ] } => [
                  "Hello World!", h2 => ["Test 123"]
              ]
          ]
      ]
  );

This will output the following HTML:

  <!DOCTYPE html>
  <html>
    <head>
      <title>My Site</title>
      <script src="/js/myScript.js" type="text/javascript"></script>
    </head>
    <body>
      <h1>Hello World</h1>
      <br>
      <div class="p-3 background-red">
        Hello World!
        <h2>Test 123</h2>
      </div>
    </body>
  </html>

HTML elements that allow children are created like:

  [div => ["Text!", h1 => ["Text!"]]] # <div>Text!<h1>Text!</h1></div>

To provide attributes to a tag:

  [div => { class => ["p-3", "m-2"] } => ["Text!", h1 => ["Text!"]]] # <div class="p-3 m-2">Text!<h1>Text!</h1></div>

If a tag doesn't have any children, ie a <link> tag:

  [link => { href => "www.google.com" }] # <link href="www.google.com">

If a tag doesn't have any attributes:

  [br => {}] # <br>

To render just text, make sure it isn't followed up by an array, or hash:

  ["Text!"]

=cut

use strict;
use warnings;
use feature qw(state);

use Carp         qw(croak);
use HTML::Escape qw(escape_html);

use Sereal::Encoder;
use HTML::Composer::Unsafe;

my @tags_list = qw(
  a abbr address area article aside audio b base bdi bdo blockquote body
  br button canvas caption cite code col colgroup data datalist dd del
  details dfn dialog div dl dt em embed fieldset figcaption figure
  footer form h1 h2 h3 h4 h5 h6 head header hgroup hr html i iframe
  img input ins kbd label legend li link main map mark menu meta
  meter nav noscript object ol optgroup option output p param picture
  plaintext pre progress q rp rt ruby s samp script search section
  select slot small source span strong style sub summary sup table
  tbody td template textarea tfoot th thead time title tr track u
  ul var video wbr
);

my %tags_map = map { $_ => 1 } @tags_list;

=head2 new(%ARGS)

Create a new instance of HTML::Composer. Optionally, pass a cache argument, to tell
HTML::Hash to cache the result against the hash you pass. (Caching defaults to false).

  my $h = HTML::Composer->new(); # Cached instance of HTML::Composer
  $h->html(...);

  my $hc = HTML::Composer->new(cache => 0); # Don't cache templates
  $hc->html(...);

=cut

sub new {
    my ( $class, %args ) = @_;
    return bless {
        cache   => $args{cache} // 0,
        store   => {},
        encoder => Sereal::Encoder->new(
            {
                snappy            => 1,
                croak_on_bless    => 1,
                stringify_unknown => 1,
                canonical         => 1
            }
        )
    }, $class;
}

=head2 html(ARRAY)

Create a string containing the HTML page described in ARRAY. Croaks if HTML validation fails.

  my $h = HTML::Composer->new();
  my $html = $h->html([
          head => [
              title  => ["My Site"],
              script => {
                  src  => "/js/myScript.js",
                  type => "text/javascript"
              }
          ],
          body => [
              h1  => ["Hello World!"],
              br  => {},
              div => { class => [ "p-3", "background-red" ] } => [
                  "Hello World!", h2 => ["Test 123"]
              ]
          ]
      ]
  );

If you need to pass attributes to the root <html> tag you can do so with:

  my $h = HTML::Composer->new();
  my $html = $h->html({lang => 'en'} => [
          head => [
              title  => ["My Site"],
              script => {
                  src  => "/js/myScript.js",
                  type => "text/javascript"
              }
          ],
          body => [
              h1  => ["Hello World!"],
              br  => {},
              div => { class => [ "p-3", "background-red" ] } => [
                  "Hello World!", h2 => ["Test 123"]
              ]
          ]
      ]
  );

=cut

sub html {
    my ( $self, @args ) = @_;

    my $h;
    my $ha;
    if ( @args > 1 ) {
        $ha = shift(@args);
    }
    $h = shift(@args);

    my $rh  = ref($h);
    my $rha = ref($ha);

    croak "Bad value passed to HTML::Composer for"
      . "html attrs expected HASH got $rha"
      if ( $rha && $rha ne 'HASH' );
    croak "Bad value passed to HTML::Composer, expected ARRAY got $rh"
      if ( !$rh || $rh ne 'ARRAY' );

    my $s = scalar(@$h);

    # We expect 4 args, head, (head elements), body, (body elements)
    croak "Invalid number of elements in ARRAY, expected 4 got $s"
      unless $s == 4;

    my ( $hs, $hb, $bs, $bb ) = @$h;

    croak "Invalid head tag: $hs expected head" unless $hs eq 'head';
    croak "Invalid body tag: $bs expected body" unless $bs eq 'body';

    my $hr = ref($hb);
    croak "Invalid head type, expected ARRAY got $hb"
      unless $hr && $hr eq 'ARRAY';
    my $br = ref($bb);
    croak "Invalid body type, expected ARRAY got $br"
      unless $br && $br eq 'ARRAY';

    my $html = [ html => ( $ha ? $ha : () ) => $h ];

    if ( $self->{cache} ) {
        my $encoded = $self->{encoder}->encode($html);
        if ( $self->{store}->{$encoded} ) {
            return $self->{store}->{$encoded};
        }
    }

    my $root = _render( $html, "<!DOCTYPE html>" );

    if ( $self->{cache} ) {
        $self->{store}->{ $self->{encoder}->encode($html) } = $root;
    }

    return $root;
}

=head2 partial(ARRAY)

Create a string containing the HTML partial described in ARRAY. Must have one root element.

  use HTML::Composer;
  
  my $h = HTML::Composer->new;
  my $html = $h->partial([
    div => [
      "Hello, World!",
      a => { href => "https://www.google.com" } => ["www.google.com"]
    ]
  ]);
  
  say $html; # <div>Hello, World!<a href="https://www.google.com">www.google.com</a></div>

=cut

sub partial {
    my ( $self, $h ) = @_;

    croak 'partial expects a single argument of type ARRAY'
      if !ref($h) || ref($h) ne 'ARRAY';

    return _render( $h, '' );
}

=head2 unsafe(SCALAR)

Create an instance of L<HTML::Composer::Unsafe>, these objects encapsulate the value you provide,
and are not escaped by HTML::Composer when the HTML is rendered.

  use HTML::Composer;
  
  my $h = HTML::Composer->new;
  my $unsafe_text = $h->unsafe(q[document.body.addEventListener('htmx:configRequest', (event) => {})]);
  
  ref($unsafe_text) # HTML::Composer::Unsafe
  
  my $html = $h->html([
    head => [
      title => ["My Site!"],
      script => [$unsafe_text]
    ],
    body => [
      div => [
        "Hello World!"
      ]
    ]
  ]);

=cut

sub unsafe {
    my ( $self, $str ) = @_;
    return HTML::Composer::Unsafe->new($str);
}

sub _render {
    my ( $html, $root ) = @_;

    my @stack = reverse(@$html);
    my @a     = ($root);
    while (@stack) {
        my $o  = pop(@stack);
        my $ro = ref($o);
        if ( !$ro ) {    # Plain text or tag
            if ( my $rsp = ref( $stack[-1] ) ) {
                my $rsp_array = $rsp eq 'ARRAY';
                my $rsp_hash  = $rsp eq 'HASH';
                if ( $rsp && ( $rsp_array | $rsp_hash ) )
                {   # It is a tag if it has a follow up attr HASH or, body ARRAY
                    push @a, '<', my $eo = escape_html($o);

                    croak "Invalid tag: <$eo>, expected one of "
                      . join( ', ', @tags_list )
                      if !$tags_map{$eo};

                    if ( !grep { $_ eq $eo }
                        qw(br img input meta link hr col source) )
                    {
                        if ($rsp_array) {    # If no attributes
                            push @a, '>';
                            splice( @stack, scalar(@stack) - 1, 0, \$o );
                        }
                        elsif ($rsp_hash) {
                            my $rsb = ref( $stack[-2] );

                            if ( $rsb && $rsb eq 'ARRAY' ) {
                                splice( @stack, scalar(@stack) - 2, 0, \$o );
                            }
                            else {
                                splice( @stack, scalar(@stack) - 1, 0, \$o );
                            }
                        }
                    }
                    else {
                        croak "Cannot pass children to tag of type $o"
                          if ( $rsp ne 'HASH' )
                          ; # Non child elements, ie meta, link, etc (CANNOT HAVE CHILDREN)
                    }
                }
                else {
                    push @a, escape_html($o);
                }
            }
            else {
                push @a, escape_html($o);
            }
        }
        elsif ( $ro eq 'HASH' ) {    # Attributes
            for ( sort keys %$o ) {
                my $ra = ref( $o->{$_} );
                my $av = ( $ra && $ra eq 'ARRAY' )
                  ? join(
                    ' ',
                    map {
                             ref($_)
                          && ref($_) eq 'HTML::Composer::Unsafe'
                          ? $_
                          : escape_html($_)
                    } @{ $o->{$_} }
                  )
                  : ( $ra && $ra eq 'HTML::Composer::Unsafe' ) ? $o->{$_}
                  :         escape_html( $o->{$_} );
                push @a, ' ', escape_html($_), '="', $av, '"';
            }

            push @a, '>';
        }
        elsif ( $ro eq 'ARRAY' ) {    # Child elements
            my $elems = scalar @$o;
            push @stack, reverse(@$o);
        }
        elsif ( $ro eq 'SCALAR' )
        { # This is our close marker, they are pushed to be after the child elements of a tag
            my $elem = $$o;
            push @a, '</', escape_html($elem), '>';
        }
        elsif ( $ro eq 'HTML::Composer::Unsafe' ) {
            push @a, $o . '';
        }
    }

    return join( '', @a );
}

1;
