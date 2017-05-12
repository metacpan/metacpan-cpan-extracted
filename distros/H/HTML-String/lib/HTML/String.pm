package HTML::String;

use strictures 1;
use HTML::String::Value;
use Exporter 'import';

our $VERSION = '1.000006'; # 1.0.6

$VERSION = eval $VERSION;

our @EXPORT = qw(html);

sub html {
  HTML::String::Value->new($_[0]);
}

1;

__END__

=head1 NAME

HTML::String - mark strings as HTML to get auto-escaping

=head1 SYNOPSIS

  use HTML::String;
  
  my $not_html = 'Hello, Bob & Jake';
  
  my $html = html('<h1>').$not_html.html('</h1>');
  
  print html($html); # <h1>Hello, Bob &amp; Jake</h1>

or, alternatively,

  use HTML::String::Overload;
  
  my $not_html = 'Hello, Bob & Jake';
  
  my $html = do {
    use HTML::String::Overload;
    "<h1>${not_html}</h1>";
  }
  
  print html($html); # <h1>Hello, Bob &amp; Jake</h1>

(but see the L<HTML::String::Overload> documentation for details and caveats).

See also L<HTML::String::TT> for L<Template Toolkit|Template> integration.

=head1 DESCRIPTION

Tired of trying to remember which strings in your program need HTML escaping?

Working on something small enough to not need a templating engine - or code
heavy enough to be better done with strings - but wanting to be careful about
user supplied data?

Yeah, me too, sometimes. So I wrote L<HTML::String>.

The idea here is to have pervasive HTML escaping that fails closed - i.e.
escapes everything that it isn't explicitly told not to. Since in the era
of XSS (cross site scripting) attacks it's a matter of security as well as
of not serving mangled markup, I've preferred to err on the side of
inconvenience in places in order to make it as hard as possible to screw up.

We export a single subroutine, L</html>, whose sole purpose in life
is to construct an L<HTML::String::Value> object from a string, which then
obsessively refuses to be concatenated to anything else without escaping it
unless you asked for that not to happen by marking the other thing as HTML
too.

So

  html($thing).$other_thing

will return an object where C<$thing> won't be escaped, but C<$other_thing>
will. Keeping concatenating stuff is fine; internally it's an array of parts.

Because html() will happily take something that's already wrapped into a
value object, when we print it out we can do:

  print html($final_result);

safe in the knowledge that if we got passed a value object that won't break
anything, but if by some combination of alarums, excursions and murphy
strikes we still have just a plain string by that point, the plain string
will still get escaped on the way out.

If you've got distinct blocks of code where you're assembling HTML, instead
of using L</html> a lot you can say "all strings in this block are HTML
so please mark them all to not be escaped" using L<HTML::String::Overload> -

  my $string = 'This is a "normal" string';
  
  my $html;
  
  {
    use HTML::String::Overload; # valid until the end of the block

    $html = '<foo>'.$string.'</foo>'; # the two strings are html()ified
  }

  print $html; # prints <foo>This is a &quot;normal&quot; string</foo>

Note however that due to a perl bug, you can't use backslash escapes in
a string and have it still get marked as an HTML value, so instead of

  "<h1>\n<div>"

you need to write

  "<h1>"."\n"."</div>"

at least as far as 5.16.1, which is current as I write this. See
L<HTML::String::Overload> for more details.

For integration with L<Template Toolkit|Template>, see L<HTML::String::TT>.

=head1 CHARACTERS THAT WILL BE ESCAPED

HTML::String concerns itself with characters that have special meaning in
HTML. Those which begin and end tags (< and >), those which begin an entity
(&) and those which delimit attribute values (" and '). It outputs them
in a fashion compatible with HTML 4 and newer and all versions of XHTML
(assuming support for named entities in the parser). There are no known
incompatibilities with browsers. 

HTML::String does not concern itself with other characters, it is assumed
that HTML documents will be marked with a suitable character encoding via
a Content-Type HTTP header and/or a meta element.

=head1 EXPORTS

=head2 html

  my $html = html($do_not_escape_this);

Returns an L<HTML::String::Value> object containing a single string part
marked not to be escaped.

If you need to do something clever such as specifying packages for which
to ignore escaping requests, see the L<HTML::String::Value> documentation
and write your own subroutine - this one is as simple as

  sub html {
    return HTML::String::Value->new($_[0]);
  }

so providing configuration options would likely be more complicated and
confusing than just writing the code.

=head1 AUTHOR

mst - Matt S. Trout (cpan:MSTROUT) <mst@shadowcat.co.uk>

=head1 CONTRIBUTORS

dorward - David Dorward (cpan:DORWARD) <david@dorward.me.uk>
rafl - Florian Ragwitz (cpan:FLORA) <rafl@debian.org>

=head1 COPYRIGHT

Copyright (c) 2012 the HTML::String L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
