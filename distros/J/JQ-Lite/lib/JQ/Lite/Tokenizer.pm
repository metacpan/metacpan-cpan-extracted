package JQ::Lite::Tokenizer;

use strict;
use warnings;

use JQ::Lite::Util ();

# The tokenizer deliberately recognizes only the top-level pipeline boundary.
# Filter-local syntax remains owned by the existing, compatibility-sensitive
# parser and filter implementations while those constructs are ported to ASTs.
sub tokenize {
    my ($source) = @_;

    return [] unless defined $source;

    my @parts = JQ::Lite::Util::_split_top_level_pipes($source);
    my @tokens;
    my $offset = 0;

    for my $index (0 .. $#parts) {
        my $text = $parts[$index];
        my $start = index($source, $text, $offset);
        $start = $offset if $start < 0;
        my $end = $start + length($text);

        push @tokens, {
            type  => 'FILTER',
            value => $text,
            start => $start,
            end   => $end,
        };

        if ($index < $#parts) {
            my $pipe = index($source, '|', $end);
            $pipe = $end if $pipe < 0;
            push @tokens, {
                type  => 'PIPE',
                value => '|',
                start => $pipe,
                end   => $pipe + 1,
            };
            $offset = $pipe + 1;
        }
    }

    push @tokens, {
        type  => 'EOF',
        value => undef,
        start => length($source),
        end   => length($source),
    };

    return \@tokens;
}

1;
