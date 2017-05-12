#!perl -T ## no critic (TidyCode)

use strict;
use warnings;

our $VERSION = 0;

require Locale::Utils::PlaceholderMaketext;

my $obj = Locale::Utils::PlaceholderMaketext->new;

# no strict
# undef converted to q{}
() = print
    $obj->expand_gettext(
        '%% foo %1 bar',
        undef,
    ),
    "\n";

# no strict
# undef converted to 0
() = print
    $obj->expand_gettext(
        'bar %quant(%1,singular,plural,zero) baz',
        undef,
    ),
    "\n";

$obj->is_strict(1);

for (undef, 0 .. 2, '3234567.890') {
    () = print
        $obj->expand_gettext(
            'foo %1 bar %quant(%2,singular,plural,zero) baz',
            'and',
            $_,
        ),
        "\n";
}

for (undef, 0 .. 2, '3234567.890') {
    () = print
        $obj->expand_gettext(
            'foo %1 bar %*(%2,singular,plural,zero) baz',
            'and',
            $_,
        ),
        "\n";
}

# $Id: 12_expand_gettext.pl 567 2015-02-02 07:32:47Z steffenw $

__END__

Output:

% foo  bar
bar zero baz
foo and bar %quant(%2,singular,plural,zero) baz
foo and bar zero baz
foo and bar 1 singular baz
foo and bar 2 plural baz
foo and bar 3234567.890 plural baz
foo and bar %*(%2,singular,plural,zero) baz
foo and bar zero baz
foo and bar 1 singular baz
foo and bar 2 plural baz
foo and bar 3234567.890 plural baz
