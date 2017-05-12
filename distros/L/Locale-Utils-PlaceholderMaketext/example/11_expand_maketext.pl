#!perl -T ## no critic (TidyCode)

use strict;
use warnings;

our $VERSION = 0;

use charnames qw(:full); # for \N{...}
require Locale::Utils::PlaceholderMaketext;

# code to format numeric values
my $formatter_code = sub {
    my ($value, $type) = @_; # $function_name not used

    $type eq 'numeric'
        or return $value;
    # set the , between 3 digits
    while ( $value =~ s{(\d+) (\d{3})}{$1,$2}xms ) {}
    # German number format
    $value =~ tr{.,}{,.};

    return $value;
};

my $obj = Locale::Utils::PlaceholderMaketext->new;

# no strict
# undef converted to q{}
() = print
    $obj->expand_maketext(
        'foo [_1] bar',
        undef,
    ),
    "\n";

# no strict
# undef converted to 0
() = print
    $obj->expand_maketext(
        'bar [quant,_1,singular,plural,zero] baz',
        undef,
    ),
    "\n";

$obj->is_strict(1);

for (undef, 0 .. 2, '3234567.890', 4_234_567.890) { ## no critic (MagicNumbers)
    () = print
        $obj->expand_maketext(
            '~~ foo ~[[_1]~] bar [quant,_2,singular,plural,zero] baz',
            # same placeholder for _1 and _2
            $_,
            $_,
        ),
        "\n";
}

# formatted numeric
$obj->formatter_code($formatter_code);

for (undef, 0 .. 2, '3234567.890', 4_234_567.890) { ## no critic (MagicNumbers)
    () = print
        $obj->expand_maketext(
            # same placeholder for _1 and _2
            'foo [_1] bar [*,_2,singular,plural,zero] baz',
            $_,
            $_,
        ),
        "\n";
}

# space
$obj->space("\N{NO-BREAK SPACE}");
() = print
    $obj->expand_maketext("unicode space [quant,_1,singular,plural]\n", 1),
    $obj->expand_maketext("unicode space [quant,_1,singular,plural]\n", 2);
$obj->reset_space;
() = print
    $obj->expand_maketext("default space [quant,_1,singular,plural]\n", 1),
    $obj->expand_maketext("default space [quant,_1,singular,plural]\n", 2);

# $Id: 11_expand_maketext.pl 567 2015-02-02 07:32:47Z steffenw $

__END__

Output:

foo  bar
bar zero baz
~ foo [[_1]] bar [quant,_2,singular,plural,zero] baz
~ foo [0] bar zero baz
~ foo [1] bar 1 singular baz
~ foo [2] bar 2 plural baz
~ foo [3234567.890] bar 3234567.890 plural baz
~ foo [4234567.89] bar 4234567.89 plural baz
foo [_1] bar [*,_2,singular,plural,zero] baz
foo 0 bar zero baz
foo 1 bar 1 singular baz
foo 2 bar 2 plural baz
foo 3.234.567,890 bar 3.234.567,890 plural baz
foo 4.234.567,89 bar 4.234.567,89 plural baz
unicode space 1\N{NO-BREAK SPACE}singular
unicode space 2\N{NO-BREAK SPACE}plural
default space 1 singular
default space 2 plural
