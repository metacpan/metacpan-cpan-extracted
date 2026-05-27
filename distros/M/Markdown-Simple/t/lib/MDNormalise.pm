package MDNormalise;
# Port of commonmark-spec/test/normalize.py to Perl.
# Normalises HTML so semantically equivalent strings compare equal.
#
# Rules (per spec):
#   - whitespace at the start/end of tag content is stripped (block tags)
#   - runs of internal whitespace collapse to single space (block tags)
#   - text in <pre>, <code>, <script>, <style>, <textarea> is preserved verbatim
#   - attributes are sorted alphabetically
#   - attribute values normalised: " or ' quoting, &amp; -> &
#   - self-closing slash trimmed/normalised
#
# This implementation is intentionally pragmatic: it tokenises with a regex,
# normalises whitespace context-aware, and reserialises.

use strict;
use warnings;
use Encode ();
use Exporter 'import';
our @EXPORT_OK = qw(normalise);

my %PRESERVE = map { $_ => 1 } qw(pre code script style textarea);
my %BLOCK    = map { $_ => 1 } qw(
    address article aside base basefont blockquote body caption center col colgroup
    dd details dialog dir div dl dt fieldset figcaption figure footer form frame
    frameset h1 h2 h3 h4 h5 h6 head header hr html iframe legend li link main menu
    menuitem nav noframes ol optgroup option p param section source summary table
    tbody td tfoot th thead title tr track ul
);

sub _decode_entities {
    my $s = shift;
    $s =~ s/&amp;/&/g;
    $s =~ s/&lt;/</g;
    $s =~ s/&gt;/>/g;
    $s =~ s/&quot;/"/g;
    $s =~ s/&#39;/'/g;
    return $s;
}

sub _normalise_attrs {
    my $raw = shift;
    my @pairs;
    while ($raw =~ /\s*([A-Za-z_:][-A-Za-z0-9_:.]*)(?:\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+)))?/g) {
        my $name = lc $1;
        my $val  = defined $2 ? $2 : defined $3 ? $3 : defined $4 ? $4 : undef;
        $val = _decode_entities($val) if defined $val;
        push @pairs, [$name, $val];
    }
    @pairs = sort { $a->[0] cmp $b->[0] } @pairs;
    return join '', map {
        defined $_->[1]
            ? qq{ $_->[0]="$_->[1]"}
            : qq{ $_->[0]}
    } @pairs;
}

sub normalise {
    my $html = shift;
    return '' unless defined $html;

    # Markdown::Simple emits UTF-8 bytes; spec JSON is decoded to Perl
    # character strings. Decode our output (if it's flagged as bytes) so
    # comparison happens in the same domain. Latin-1 bytes that aren't
    # valid UTF-8 are passed through.
    if (!utf8::is_utf8($html)) {
        my $decoded = eval { Encode::decode('UTF-8', $html, Encode::FB_CROAK) };
        $html = $decoded if defined $decoded;
    }

    # Tokenise: tags (open/close/self), comments, raw text.
    my @tokens;
    while ($html =~ /\G(?:
            (<!--.*?-->)                          # comment
          | (<!\[CDATA\[.*?\]\]>)                 # CDATA
          | (<\?.*?\?>)                           # PI
          | (<!DOCTYPE[^>]*>)                     # doctype
          | <\s*(\/?)\s*([A-Za-z][A-Za-z0-9]*)\s*([^>]*?)(\/?)\s*>
          | ([^<]+)                               # text
        )/gxs) {
        if (defined $1) { push @tokens, ['comment', $1]; next; }
        if (defined $2) { push @tokens, ['raw',     $2]; next; }
        if (defined $3) { push @tokens, ['raw',     $3]; next; }
        if (defined $4) { push @tokens, ['raw',     $4]; next; }
        if (defined $6) {
            my ($slash, $name, $attrs, $self) = ($5, lc $6, $7, $8);
            push @tokens, [ $slash eq '/' ? 'close' : ($self eq '/' ? 'self' : 'open'),
                            $name, $attrs ];
            next;
        }
        if (defined $9) { push @tokens, ['text', $9]; next; }
    }

    # Reserialise with context-aware whitespace normalisation.
    my @preserve_stack;   # 1 if inside <pre>/<code>/etc
    my $out = '';
    for my $tok (@tokens) {
        my $kind = $tok->[0];
        if ($kind eq 'open') {
            my (undef, $name, $attrs) = @$tok;
            $out =~ s/[ \t\n\r]+\z// if $BLOCK{$name} && !@preserve_stack;
            $out .= "<$name" . _normalise_attrs($attrs) . ">";
            push @preserve_stack, $name if $PRESERVE{$name};
        }
        elsif ($kind eq 'close') {
            my (undef, $name) = @$tok;
            $out =~ s/[ \t\n\r]+\z// if $BLOCK{$name} && !@preserve_stack;
            $out .= "</$name>";
            pop @preserve_stack if @preserve_stack && $preserve_stack[-1] eq $name;
        }
        elsif ($kind eq 'self') {
            my (undef, $name, $attrs) = @$tok;
            $out .= "<$name" . _normalise_attrs($attrs) . " />";
        }
        elsif ($kind eq 'text') {
            my $t = $tok->[1];
            if (@preserve_stack) {
                $out .= $t;
            } else {
                $t =~ s/[ \t\n\r]+/ /g;
                # strip leading space if previous emit ended at a block boundary
                $t =~ s/^ // if $out =~ />\z/ || $out eq '';
                $out .= $t;
            }
        }
        elsif ($kind eq 'comment' || $kind eq 'raw') {
            $out .= $tok->[1];
        }
    }

    # Collapse remaining whitespace runs that span block boundaries.
    $out =~ s/>\s+</></g;
    $out =~ s/\A\s+//;
    $out =~ s/\s+\z//;
    return $out;
}

1;
