#!perl -T ## no critic (TidyCode)

use strict;
use warnings;

our $VERSION = 0;

use charnames qw(:full); # for \N{...}
require Locale::Utils::PlaceholderBabelFish;

# code to format numeric values
my $modifier_code = sub {
    my ($value, $attributes) = @_; # $function_name not used

    if ( $attributes =~ m{ \b numf \b }xms ) {
        # set the , between 3 digits
        while ( $value =~ s{(\d+) (\d{3})}{$1,$2}xms ) {}
        # German number format
        $value =~ tr{.,}{,.};
    }
    $value = Locale::Utils::PlaceholderBabelFish
        ->default_modifier_code
        ->($value, $attributes);

    return $value;
};

my $obj = Locale::Utils::PlaceholderBabelFish->new;

# no strict
# undef converted to q{}
() = print
    $obj->expand_babel_fish(
        'foo #{name} bar',
        name => undef, # as hash
    ),
    "\n";

$obj->is_strict(1);
() = print
    $obj->expand_babel_fish(
        'foo #{name} bar',
        { name => undef }, # or hash reference
    ),
    "\n";

for ( undef, 0 .. 2, '3234567.890', 4_234_567.890 ) { ## no critic (MagicNumbers)
    () = print
        $obj->expand_babel_fish(
            'foo #{count} bar ((#{count} singular|#{count} plural)) baz',
            $_, # short writing for count => $_ or { count => $_ }
        ),
        "\n";
}

# formatted numeric
$obj->modifier_code($modifier_code);

for ( undef, 0 .. 2, '3234567.890', 4_234_567.890 ) { ## no critic (MagicNumbers)
    () = print
        $obj->expand_babel_fish(
            # same placeholder for _1 and _2
            'foo #{count :numf} bar ((#{count :numf} singular|#{count :numf} plural)) baz',
            $_,
        ),
        "\n";
}

# use numf and html from default modifier code
() = print
    $obj->expand_babel_fish(
        # same placeholder for _1 and _2
        'foo <strong>#{count :numf :html}</strong> bar #{text :html} baz',
        count => 1234.56,
        text  => '<text>',
    ),
    "\n";

# $Id: 01_expand_babel_fish.pl 631 2015-11-02 08:09:16Z steffenw $

__END__

Output:

foo  bar
foo #{name} bar
foo #{count} bar ((#{count} singular|#{count} plural)) baz
foo 0 bar 0 plural baz
foo 1 bar 1 singular baz
foo 2 bar 2 plural baz
foo 3234567.890 bar 3234567.890 plural baz
foo 4234567.89 bar 4234567.89 plural baz
foo #{count :numf} bar ((#{count :numf} singular|#{count :numf} plural)) baz
foo 0 bar 0 plural baz
foo 1 bar 1 singular baz
foo 2 bar 2 plural baz
foo 3.234.567,890 bar 3.234.567,890 plural baz
foo 4.234.567,89 bar 4.234.567,89 plural baz
foo <strong>1.234,56</strong> bar &lt;text&gt; baz
