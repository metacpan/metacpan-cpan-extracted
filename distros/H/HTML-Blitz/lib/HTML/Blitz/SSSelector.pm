# This code can be redistributed and modified under the terms of the GNU Affero
# General Public License as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later version.
# See the "COPYING" file for details.
package HTML::Blitz::SSSelector;
use HTML::Blitz::pragma;
use HTML::Blitz::SelectorType qw(
    ST_FALSE
    ST_TAG_NAME
    ST_ATTR_HAS
    ST_ATTR_EQ
    ST_ATTR_PREFIX
    ST_ATTR_SUFFIX
    ST_ATTR_INFIX
    ST_ATTR_LIST_HAS
    ST_ATTR_LANG_PREFIX
    ST_NTH_CHILD
    ST_NTH_CHILD_OF_TYPE
);

our $VERSION = '0.07';

method new($class: :$simple_selectors, :$link_type) {
    bless {
        simplesel => \@$simple_selectors,
        link_type => $link_type,
    }, $class
}

method link_type() {
    $self->{link_type}
}

method matches($tag, $attributes, $nth, $nth_of_type) {
    for my $sel (@{$self->{simplesel}}) {
        my $match;
        my $type = $sel->{type};
        if ($type eq ST_FALSE) {
            $match = 0;
        } elsif ($type eq ST_TAG_NAME) {
            $match = $sel->{name} eq '*' || $sel->{name} eq $tag;
        } elsif ($type eq ST_ATTR_HAS) {
            $match = exists $attributes->{$sel->{attr}};
        } elsif ($type eq ST_ATTR_EQ) {
            my $attr = $sel->{attr};
            $match = exists $attributes->{$attr} && $attributes->{$attr} eq $sel->{value};
        } elsif ($type eq ST_ATTR_PREFIX) {
            my $attr = $sel->{attr};
            my $value = $sel->{value};
            $match = exists $attributes->{$attr} && substr($attributes->{$attr}, 0, length $value) eq $value;
        } elsif ($type eq ST_ATTR_SUFFIX) {
            my $attr = $sel->{attr};
            my $value = $sel->{value};
            $match = exists $attributes->{$attr} && substr($attributes->{$attr}, -length $value) eq $value;
        } elsif ($type eq ST_ATTR_INFIX) {
            my $attr = $sel->{attr};
            my $value = $sel->{value};
            $match = exists $attributes->{$attr} && index($attributes->{$attr}, $value) >= 0;
        } elsif ($type eq ST_ATTR_LIST_HAS) {
            my $attr = $sel->{attr};
            my $value = $sel->{value};
            $match = exists $attributes->{$attr} && do {
                my $r = 0;
                for my $elem ($attributes->{$attr} =~ /[^ \t\n\r\f]+/g) {
                    if ($elem eq $value) {
                        $r = 1;
                        last;
                    }
                }
                $r
            };
        } elsif ($type eq ST_ATTR_LANG_PREFIX) {
            my $attr = $sel->{attr};
            my $value = $sel->{value};
            $match = exists $attributes->{$attr} && $attributes->{$attr} =~ /\A\Q$value\E(?![^\-])/;
        } elsif ($type eq ST_NTH_CHILD || $type eq ST_NTH_CHILD_OF_TYPE) {
            my $x = $type eq ST_NTH_CHILD ? $nth : $nth_of_type;
            my $ka = $sel->{a};
            my $kb = $sel->{b};
            my $d = $x - $kb;
            $match = $d == 0 || ($ka != 0 && ($d < 0) == ($ka < 0) && $d % $ka == 0);
        } else {
            die "Internal error: invalid simple selector type '$type'";
        }

        if ($sel->{negated}) {
            $match = !$match;
        }

        $match or return 0;
    }

    1
}

1
