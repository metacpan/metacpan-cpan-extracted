package HTML::Untidy;
# ABSTRACT: yet another way to write HTML quickly and programmatically
$HTML::Untidy::VERSION = '0.01';

use strict;
use warnings;
use parent 'Exporter';
use HTML::Escape 'escape_html';

my @BASE = qw(element class attr prop text raw note);

# source: https://developer.mozilla.org/en-US/docs/Web/HTML/Element
my @TAGS = qw(
  a abbr address area article aside audio
  b base bdi bdo blockquote body br button
  canvas caption cite code col colgroup
  data datalist dd del details dfn dialog div dl dt
  em embed
  fieldset figcaption figure footer form
  h1 h2 h3 h4 h5 h6 head header hgroup hr html
  i iframe img input ins
  kbd
  label legend li link
  main map mark menu menuitem meta meter
  nav noframes noscript
  object ol optgroup option output
  p param picture pre progress
  q
  rp rt rtc ruby
  s samp script section select slot small source span strong style sub summary sup
  table tbody td template textarea tfoot th thead time title tr track
  u ul
  var video
  wbr
);

my @COMMON = qw(
  html head body title meta link script style
  h1 h2 h3 h4 h5 h6
  div p hr pre nav code img a b i u em strong sup sub small
  table tbody thead tr th td
  ul dl ol li dd dt
  form input textarea select option button label
  canvas
);

our @EXPORT_OK = (@BASE, @TAGS);

our %EXPORT_TAGS = (
  base   => [@BASE],
  common => [@BASE, @COMMON],
  all    => [@BASE, @TAGS],
);

our @CLASS;
our @ATTR;
our @PROP;
our @BODY;
our $INDENT = 0;

my $DEPTH = 0;

sub install_sub{
  no strict 'refs';
  my ($name, $code) = @_;
  *{"${name}"} = $code;
}

sub e ($){
  goto \&escape_html;
}

sub indent {
  return ' ' x ($DEPTH * $INDENT);
}

sub element ($&){
  my ($tag, $code) = @_;

  my $html = do {
    local @CLASS;
    local @ATTR;
    local @PROP;
    local @BODY;

    ++$DEPTH;
    my $inner_html = $code->();
    --$DEPTH;

    if ($inner_html) {
      push @BODY, $inner_html;
    }

    my @attrs;
    for (my $i = 0; $i < @ATTR; $i += 2) {
      push @attrs, qq{$ATTR[$i]="$ATTR[$i + 1]"};
    }

    my $attr  = ''; $attr  = ' ' . join ' ', @attrs if @attrs;
    my $prop  = ''; $prop  = ' ' . join ' ', @PROP  if @PROP;
    my $class = ''; $class = sprintf ' class="%s"', join ' ', @CLASS if @CLASS;

    if (@BODY) {
      my $open  = sprintf '%s<%s%s%s%s>', indent, $tag, $class, $attr, $prop;
      my $close = sprintf '%s</%s>',      indent, $tag;
      join("\n", $open, join("\n", @BODY), $close);
    }
    else {
      sprintf q{%s<%s%s%s%s></%s>}, indent, $tag, $class, $attr, $prop, $tag;
    }
  };

  my $void = !defined wantarray;

  # At root of tag stack or called in non-void context
  if ($DEPTH == 0 || !$void) {
    return $html;
  }
  # Inner-tag body call in void context
  else {
    push @BODY, $html;
    return;
  }
}

sub class (@){ push @CLASS, map{ e $_ } map{ split /\s+/, $_ } @_; return; }
sub prop  (@){ push @PROP, map{ e $_ } @_; return; }
sub text  (@){ push @BODY, map{ indent . e $_ } @_; return; }
sub raw   (@){ push @BODY, map{ indent . $_ } @_; return; }
sub note  (@){ push @BODY, map{ indent . '<!-- ' . e($_) . ' -->' } @_; return }

sub attr (@){
  for (my $i = 0; $i < @_; $i += 2) {
    push @ATTR, e $_[$i], e $_[$i + 1];
  }

  return;
}

foreach my $tag (@TAGS){
  install_sub($tag, sub(&){ unshift @_, $tag; goto \&element; });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Untidy - yet another way to write HTML quickly and programmatically

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use HTML::Untidy;

  sub bootstrap4_modal {
    my ($content, $indent) = @_;

    # Set number of spaces to indent
    local $HTML::Untidy::INDENT = $indent || 0;

    div {
      class 'modal';

      div {
        class 'modal-dialog';

        div {
          class 'modal-header';
          h5 { class 'modal-title'; text 'Modal title' };
          button { class 'close'; attr 'type' => 'button', 'data-dismiss' => 'modal'; raw '&times;'; };
        };

        div { class 'modal-body'; raw $content; };

        div {
          class 'modal-footer';
          button { class 'btn btn-primary'; attr 'type' => 'button'; text 'Save changes'; };
          button { class 'btn btn-secondary'; attr 'type' => 'button', 'data-dismiss' => 'modal'; text 'Close'; };
        };
      };
    };
  }

  my $modal = bootstrap4_modal('Here is my modal!', 2);

  # Resulting string:
  #
  # <div class="modal">
  #   <div class="modal-dialog">
  #     <div class="modal-header">
  #       <h5 class="modal-title">
  #         Modal title
  #       </h5>
  #       <button class="close" type="button" data-dismiss="modal">
  #         &times;
  #       </button>
  #     </div>
  #     <div class="modal-body">
  #       Here is my modal!
  #     </div>
  #     <div class="modal-footer">
  #       <button class="btn btn-primary" type="button">
  #         Save changes
  #       </button>
  #       <button class="btn btn-secondary" type="button" data-dismiss="modal">
  #         Close
  #       </button>
  #     </div>
  #   </div>
  # </div>

=head1 DESCRIPTION

This is adapted from a series of short scripts I had written for use in vim. I
figured someone else might find them useful so I cleaned them up a bit and
spent the rest of the afternoon trying to figure out what the hell to call it.

=head1 NAME

HTML::Untidy

=head1 PURPOSE

Sometimes I don't want to have a proper separation of concerns. Sometimes I
just want to generate HTML programmatically and easily from perl because I hate
writing HTML or I want to build a page from componentized parts.

Isn't this just L<CGI::HTML::Functions>? Yeah, kinda. But so are React and Vue.
Complain and maybe I'll write
L<Inline::HTML|https://reactjs.org/docs/introducing-jsx.html>.

I think I got all of the HTML5 tags added. If there are any I missed, it's
simple enough to add your own.

  *blink   = sub(&){ unshift @_, 'blink';   goto \&element; });
  *marquee = sub(&){ unshift @_, 'marquee'; goto \&element; });

=head1 EXPORTED SUBROUTINES

=head2 :base

Base functions everything else is built from.

=head3 element

Accepts a tag name and subroutine to generate its components. In scalar
context, returns a formatted string of HTML. In void context within another
call to C<element>, the generated string is appended to the parent element.

=head3 class

Accepts a list of strings to use as the class list for the element. Multiple
classes may share the same string, separated by whitespace. No deduplication is
done on these.

=head3 attr

Takes key/value pairs as a hash and generates attributes. Again, no
deduplication, and the attributes are displayed in the order in which they are
passed.

=head3 prop

Adds a property which has no value (e.g. C<disabled> or C<hidden>).

=head3 text

Adds escaped text to the body of the tag.

=head3 raw

Adds unescaped text to the body of the tag.

=head3 note

Adds an HTML comment to the body of the tag.

=head3 indentation

If you want indentation, set C<$HTML::Untidy::INDENT> to the number of
spaces you want per level.

  local $HTML::Untidy::INDENT = 2;
  
  element 'div', sub{
    element 'button', sub{
      class 'btn btn-primary';
      attr id => 'some-button', 'data-toggle' => 'modal', 'data-target' => 'my-modal-id';

      if ($some_condition) {
        text 'Click me';
      }
      else {
        prop 'disabled' if $some_condition;
        text "Don't click me";
      }
    };
  };

=head2 :common

Exports the following curried aliases of L</element> for the most commonly used
HTML tags.

  html head body title meta link script style h1 h2 h3 h4 h5 h6 div p hr pre nav
  code img a b i u em strong sup sub small table tbody thead tr th td ul dl ol
  li dd dt form input textarea select option button label canvas

=head2 :all

Exports every HTML5 tag I could find.

  a abbr address area article aside audio b base bdi bdo blockquote body br
  button canvas caption cite code col colgroup data datalist dd del details dfn
  dialog div dl dt em embed fieldset figcaption figure footer form h1 h2 h3 h4
  h5 h6 head header hgroup hr html i iframe img input ins kbd label legend li
  link main map mark menu menuitem meta meter nav noframes noscript object ol
  optgroup option output p param picture pre progress q rp rt rtc ruby s samp
  script section select slot small source span strong style sub summary sup
  table tbody td template textarea tfoot th thead time title tr track u ul var
  video wbr

=head1 SEE ALSO

=over

=item L<HTML::Builder>

=back

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 LICENSE

Perl5

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
