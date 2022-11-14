# This code can be redistributed and modified under the terms of the GNU Affero
# General Public License as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later version.
# See the "COPYING" file for details.
package HTML::Blitz::SelectorGroup;
use HTML::Blitz::pragma;

method new($class: @selectors) {
    bless {
        selectors => \@selectors,
    }, $class
}

method matches($tag, $attributes, $nth, $nth_of_type) {
    for my $selector (@{$self->{selectors}}) {
        return 1 if $selector->matches($tag, $attributes, $nth, $nth_of_type);
    }
    0
}

1
