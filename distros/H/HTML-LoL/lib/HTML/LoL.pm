package HTML::LoL::Special;

sub new {
  my($type, $str) = @_;
  bless \$str, $type;
}

package HTML::LoL;

use strict;
use base 'Exporter';
use vars qw(@ISA @EXPORT $VERSION);

$VERSION = '1.3';
@EXPORT = qw(hl hl_noquote hl_requote hl_entity hl_bool hl_preserve);

use constant TABWIDTH => 8;

use HTML::Entities;
use HTML::Tagset;

my $hl_bool_yes = new HTML::LoL::Special('bool_yes');
my $hl_bool_no  = new HTML::LoL::Special('bool_no');
my $hl_noquote  = new HTML::LoL::Special('noquote');
my $hl_requote  = new HTML::LoL::Special('requote');
my $hl_preserve = new HTML::LoL::Special('preserve');

sub is_bool_yes {
  my $x = shift;
  return UNIVERSAL::isa($x, 'HTML::LoL::Special') && ($$x eq 'bool_yes');
}

sub is_bool_no {
  my $x = shift;
  return UNIVERSAL::isa($x, 'HTML::LoL::Special') && ($$x eq 'bool_no');
}

sub is_noquote {
  my $x = shift;
  return UNIVERSAL::isa($x, 'HTML::LoL::Special') && ($$x eq 'noquote');
}

sub is_requote {
  my $x = shift;
  return UNIVERSAL::isa($x, 'HTML::LoL::Special') && ($$x eq 'requote');
}

sub is_preserve {
  my $x = shift;
  return UNIVERSAL::isa($x, 'HTML::LoL::Special') && ($$x eq 'preserve');
}

# elements inside which it is OK to add whitespace
my %hl_wsok;
map { $hl_wsok{$_} = 1 } qw(area col colgroup frame frameset
                            head html object table tr);

# elements whose layout should not be altered
my %hl_pre;
map { $hl_pre{$_} = 1 } qw(pre style script textarea);

sub _emit {
  my($cb, $str, $columnref) = @_;
  my $result = &$cb($str);

  if ($str =~ /.*\n([^\n]*)$/s) {
    $str = $1;
    $$columnref = 0;
  }
  my @s = split(/\t/, $str);
  foreach my $s (@s) {
    $$columnref += length($s);
  }
  if (@s > 1) {
    $$columnref += (TABWIDTH * (@s - 1));
    $$columnref = int($$columnref / TABWIDTH);
    ++$$columnref;
    $$columnref *= TABWIDTH;
  }

  return $result;
}

sub _str {
  my($cb, $str, $depth, $columnref, $wsokref, $pre, $noquote) = @_;

  my $result;

  $str = &encode_entities($str) unless $noquote;
  if ($pre) {
    $result = &_emit($cb, $str, $columnref);
  } else {
    my $leading_ws = ($str =~ /^\s/s);
    my $trailing_ws = ($str =~ /\s$/s);

    $str =~ s/^\s+//s;
    $str =~ s/\s+$//s;

    my @words = split(/\s+/, $str);

    if (@words) {
      $$wsokref ||= $leading_ws;

      foreach my $word (@words) {
        if ($$wsokref) {
          if (($$columnref > 0)
              && ((1 + length($word) + $$columnref) > 72)) {
            $result = &_emit($cb, ("\n" . (' ' x ($depth + 1))), $columnref);
          } else {
            $result = &_emit($cb, ' ', $columnref);
          }
        }

        $result = &_emit($cb, $word, $columnref);

        $$wsokref = 1;
      }
    } elsif ($leading_ws || $trailing_ws) {
      $result = &_emit($cb, ' ', $columnref);
    }

    $$wsokref = $trailing_ws;
  }

  return $result;
}

sub _node {
  my($cb, $node, $depth, $columnref, $wsokref, $pre, $noquote) = @_;

  my $result;

  my @node = @$node;
  my $tag = $node[0];

  my $empty;

  if (&is_noquote($tag)) {
    $noquote = 1;
    undef $tag;
  } elsif (&is_requote($tag)) {
    $noquote = 0;
    undef $tag;
  } elsif (&is_preserve($tag)) {
    $pre = 1;
    undef $tag;
  } else {
    $tag = lc($tag);
    $empty = $HTML::Tagset::emptyElement{$tag};
    $pre ||= $hl_pre{$tag};
  }

  if ($$wsokref && !$pre) {
    $result = &_emit($cb, ("\n" . (' ' x $depth)), $columnref);
  }

  if (defined($tag)) {
    $result = &_emit($cb, "<$tag", $columnref);
    foreach my $content (@node[1 .. $#node]) {
      next unless ref($content) eq 'HASH';
      foreach my $hashitem (keys %$content) {
        my $val = $content->{$hashitem};

        if (&is_bool_yes($val)) {
          $result = &_emit($cb, " $hashitem", $columnref);
        } elsif (&is_bool_no($val)) {
          # do nothing
        } elsif (ref($val) eq 'ARRAY') {
          # the caller wants the value interpolated literally
          $result = &_emit($cb,
                           sprintf(' %s=%s', $hashitem, $val->[0]),
                           $columnref);
        } else {
          $result = &_emit($cb,
                           sprintf(' %s="%s"', $hashitem,
                                   &encode_entities($val)),
                           $columnref);
        }
      }
    }
    $result = &_emit($cb, ">", $columnref);
    $$wsokref = $hl_wsok{$tag};
  }

  foreach my $content (@node[1 .. $#node]) {
    my $ref = ref($content);
    next if ($ref eq 'HASH');

    if ($ref eq 'ARRAY') {
      $result = &_node($cb, $content, $depth + 1, $columnref, $wsokref,
                       $pre, $noquote);
    } else {
      $result = &_str($cb, $content, $depth + 1, $columnref, $wsokref,
                      $pre, $noquote);
    }

    $$wsokref ||= $hl_wsok{$tag} if defined($tag);
  }

  if (defined($tag) && !$empty) {
    if ($$wsokref) {
      $result = &_emit($cb, ("\n" . (' ' x $depth)), $columnref);
    }
    $result = &_emit($cb, "</$tag>", $columnref);
    $$wsokref = 0;
  }

  return $result;
}

sub hl {
  my $cb = $_[0];

  my $column = 0;
  my $wsok = 0;

  my $result;

  foreach my $elt (@_[1 .. $#_]) {
    if (ref($elt)) {
      $result = &_node($cb, $elt, 0, \$column, \$wsok, 0, 0);
    } else {
      $result = &_str($cb, $elt, 0, \$column, \$wsok, 0, 0);
    }
  }

  return $result;
}

sub hl_noquote  { [$hl_noquote  => @_]; }
sub hl_requote  { [$hl_requote  => @_]; }
sub hl_preserve { [$hl_preserve => @_]; }
sub hl_entity   { [$hl_noquote  => map { "&$_;" } @_]; }

sub hl_bool { $_[0] ? $hl_bool_yes : $hl_bool_no }

1;

__END__

=head1 NAME

HTML::LoL - construct HTML from pleasing Perl data structures

=head1 SYNOPSIS

  use HTML::LoL;

  &hl(sub { print shift },
      [body => {bgcolor => 'white'},
       [p => 'Document body', ...], ...]);

See EXAMPLE section below.

=head1 DESCRIPTION

This module allows you to use Perl syntax to express HTML.  The function
C<hl()> converts Perl list-of-list structures into HTML strings.

The first argument to C<hl()> is a callback function that's passed one
argument: a fragment of generated HTML.  This callback is invoked repeatedly
with successive fragments until all the HTML is generated; the callback is
responsible for assembling the fragments in the desired output location (e.g.,
a string or file).

The remaining arguments to C<hl()> are Perl objects representing HTML,
as follows:

=over 4

=item [B<TAG>, ...]

B<TAG> is a string (the name of an HTML element); remaining list items are any
of the forms described herein.  Corresponds to
E<lt>B<TAG>E<gt>...E<lt>/B<TAG>E<gt>.  If B<TAG> is an "empty element"
according to C<%HTML::Tagset::emptyElement>, then the E<lt>/B<TAG>E<gt> is
omitted.

=item [B<TAG> => {B<ATTR1> => B<VAL1>, B<ATTR2> => B<VAL2>, ...}, ...]

Corresponds to E<lt>B<TAG> B<ATTR1>="B<VAL1>" B<ATTR2>="B<VAL2>"
...E<gt>...E<lt>/B<TAG>E<gt>.
(As above, E<lt>/B<TAG>E<gt> is omitted if B<TAG> is an "empty element.")
Each B<ATTR> is a string.  Each B<VAL> is
either a string, in which case the value gets HTML-entity-encoded when copied
to the output, or a list reference containing a single string (viz. [B<VAL>])
in which case the value is copied literally.

Finally, for boolean-valued attributes, B<VAL> may be C<hl_bool(BOOLEAN)>,
where BOOLEAN is a Perl expression.  If BOOLEAN is true, the attribute is
included in the output; otherwise it's omitted.

=item Any string

Strings are copied verbatim to the output after entity-encoding.

=item C<hl_noquote(...)>

Suppresses entity-encoding of its arguments.

=item C<hl_requote(...)>

Reenables entity-encoding of its arguments (use it inside a call to
C<hl_noquote()>).

=item C<hl_preserve(...)>

Normally, HTML::LoL tries to optimize the whitespace in the HTML it emits
(without changing the meaning of the HTML).  This suppresses that behavior
within its arguments.

=item C<hl_entity(NAME)>

Includes the HTML character-entity named NAME.

=back

The return value of C<hl()> is the result of the last call to the callback
function.  This means it's possible to write

  &hl(sub { $accumulator .= shift }, ...)

to have C<hl()> return a string containing the completely rendered HTML.

=head1 EXAMPLE

  &hl(sub { print shift },
      [table => {border => 2, width => '80%'},
       [tr =>
        [td => {nowrap => &hl_bool(1)}, 'This & that'],
        [td => {nowrap => &hl_bool(0)}, '<b>This is not bold</b>'],
        [td => [b => 'But this is']],
        [td => &hl_noquote('<b>And so is this</b>')]]]);

prints:

  <table width="80%" border="2">
   <tr>
    <td nowrap>This &amp; that</td>
    <td>&lt;b&gt;This is not bold&lt;/b&gt;</td>
    <td><b>But this is</b></td>
    <td><b>And so is this</b></td>
   </tr>
  </table>

=head1 SEE ALSO

perllol(1), HTML::Tree(3)

This module was inspired by the C<new_from_lol()> function in the
HTML::Tree package by Gisle Aas and Sean M. Burke.

=head1 COPYRIGHT

Copyright 2000-2002 Bob Glickstein.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Bob Glickstein - http://www.zanshin.com/bobg/ - bobg@zanshin.com
