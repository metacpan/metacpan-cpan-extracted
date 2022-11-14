# This code can be redistributed and modified under the terms of the GNU Affero
# General Public License as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later version.
# See the "COPYING" file for details.
package HTML::Blitz::Matcher;
use HTML::Blitz::pragma;
use Scalar::Util ();

method new($class: $rules) {
    bless {
        rules     => $rules,
        ctx_stack => [
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
    my $sp = $self->{ctx_stack}[-1];
    my $nth_child = ++$sp->{nth_child};
    my $nth_child_of_type = ++$sp->{nth_child_of_type}{$tag};
    push @{$self->{ctx_stack}}, {
        nth_child         => 0,
        nth_child_of_type => {},
        on_leave          => [],
    };

    my @r;
    for my $rule (@{$self->{rules}}) {
        if ($rule->{selector}->matches($tag, $attributes, $nth_child, $nth_child_of_type)) {
            push @r, $rule->{result};
        }
    }
    _guniq @r
}

method on_leave($callback) {
    push @{$self->{ctx_stack}[-1]{on_leave}}, $callback;
}

method leave(@args) {
    my $ctx = pop @{$self->{ctx_stack}};
    if (defined(my $marker = $ctx->{marker})) {
        splice @{$self->{rules}}, $marker;
    }
    for my $cb (reverse @{$ctx->{on_leave}}) {
        $cb->(@args);
    }
}

method add_temp_rule(@temp_rules) {
    my $rules = $self->{rules};
    $self->{ctx_stack}[-1]{marker} //= @$rules;
    push @$rules, @temp_rules;
}

1
