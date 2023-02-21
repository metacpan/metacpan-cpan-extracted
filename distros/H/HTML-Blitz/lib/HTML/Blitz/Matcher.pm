# This code can be redistributed and modified under the terms of the GNU Affero
# General Public License as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later version.
# See the "COPYING" file for details.
package HTML::Blitz::Matcher;
use HTML::Blitz::pragma;
use HTML::Blitz::SelectorType qw(
    LT_DESCENDANT
    LT_CHILD
    LT_SIBLING
    LT_ADJACENT_SIBLING
);
use Scalar::Util ();

use constant {
    INTBITS => length(sprintf '%b', ~0),
};

our $VERSION = '0.06';

method new($class: $rules) {
    bless {
        slices    => [
            map [ $_, { cur => 0, stack => [{ extra_bits => 0 }] } ], @$rules
        ],
        doc_state => [
            {
                nth_child         => 0,
                nth_child_of_type => {},
                on_leave          => [],
            },
        ],
    }, $class
}

fun _guniq(@values) {
    my ($seen_undef, %seen_ref, %seen_str);
    grep
        !(
            ref($_) ? $seen_ref{Scalar::Util::refaddr $_} :
            defined($_) ? $seen_str{$_} :
            $seen_undef
        )++,
        @values
}

method enter($tag, $attributes) {
    my $doc_state = $self->{doc_state};
    my $dsp = $doc_state->[-1];
    my $nth_child = ++$dsp->{nth_child};
    my $nth_child_of_type = ++$dsp->{nth_child_of_type}{$tag};
    push @$doc_state, {
        nth_child         => 0,
        nth_child_of_type => {},
        on_leave          => [],
    };

    my @ret;

    for my $slice (@{$self->{slices}}) {
        my ($glass, $goop) = @$slice;
        my $cur = $goop->{cur};
        my $stack = $goop->{stack};
        my $sp = $stack->[-1];
        my $extra_volatile = $sp->{extra_volatile};
        $sp->{extra_volatile} = [];

        push @$stack, my $sp_next = {
            extra_bits => 0,
        };
        my $cur_next;

        for my $i ($cur, @{$sp->{extra}}, @$extra_volatile) {
            my $sss = $glass->[$i];
            $sss->matches($tag, $attributes, $nth_child, $nth_child_of_type)
                or next;

            my $link = $sss->link_type;
            my $k = $i + 1;
            my $bit_shift = $k - $cur - 1;
            $bit_shift < INTBITS
                or die "Internal error: Too many combinators in a single selector (" . ($bit_shift + 1) . " exceeds limit of " . INTBITS . ")";
            my $bit = 1 << $bit_shift;

            if (!defined $link) {
                push @ret, $glass->[$k];
            } elsif ($link eq LT_DESCENDANT) {
                $cur_next = $k;
            } elsif ($link eq LT_CHILD) {
                if (!($sp_next->{extra_bits} & $bit)) {
                    $sp_next->{extra_bits} |= $bit;
                    push @{$sp_next->{extra}}, $k;
                }
            } elsif ($link eq LT_SIBLING) {
                if (!($sp->{extra_bits} & $bit)) {
                    $sp->{extra_bits} |= $bit;
                    push @{$sp->{extra}}, $k;
                }
            } elsif ($link eq LT_ADJACENT_SIBLING) {
                push @{$sp->{extra_volatile}}, $k;
            } else {
                die "Internal error: unexpected selector combinator '$link'";
            }
        }

        if (defined $cur_next) {
            $stack->[-1] = {
                cur        => $cur,
                extra_bits => 0,
            };
            $goop->{cur} = $cur_next;
        }
    }

    _guniq @ret
}

method leave(@args) {
    my $dsp = pop @{$self->{doc_state}};
    if (defined(my $marker = $dsp->{marker})) {
        splice @{$self->{slices}}, $marker;
    }

    for my $slice (@{$self->{slices}}) {
        my $goop = $slice->[1];
        my $stack = $goop->{stack};
        my $sp_prev = pop @$stack;
        if (defined(my $cur = $sp_prev->{cur})) {
            $goop->{cur} = $cur;
        }
    }

    for my $cb (reverse @{$dsp->{on_leave}}) {
        $cb->(@args);
    }
}

method on_leave($callback) {
    push @{$self->{doc_state}[-1]{on_leave}}, $callback;
}

method add_temp_rule(@temp_rules) {
    my $slices = $self->{slices};
    $self->{doc_state}[-1]{marker} //= @$slices;
    push @$slices, map [ $_, { cur => 0, stack => [{ extra_bits => 0 }] } ], @temp_rules;
}

1
