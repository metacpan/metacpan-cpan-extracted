# encoding: Latin9
# This file is encoded in Latin-9.
die "This file is not encoded in Latin-9.\n" if q{ } ne "\x82\xa0";

use Latin9;

print "1..12\n";

# Latin9::eval {...} has Latin9::eval "..."
if (Latin9::eval { Latin9::eval " if ('éÁ' =~ /[á]/i) { return 1 } else { return 0 } " }) {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# Latin9::eval {...} has Latin9::eval qq{...}
if (Latin9::eval { Latin9::eval qq{ if ('éÁ' =~ /[á]/i) { return 1 } else { return 0 } } }) {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# Latin9::eval {...} has Latin9::eval '...'
if (Latin9::eval { Latin9::eval ' if (qq{éÁ} =~ /[á]/i) { return 1 } else { return 0 } ' }) {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# Latin9::eval {...} has Latin9::eval q{...}
if (Latin9::eval { Latin9::eval q{ if ('éÁ' =~ /[á]/i) { return 1 } else { return 0 } } }) {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# Latin9::eval {...} has Latin9::eval $var
my $var = q{ if ('éÁ' =~ /[á]/i) { return 1 } else { return 0 } };
if (Latin9::eval { Latin9::eval $var }) {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# Latin9::eval {...} has Latin9::eval (omit)
$_ = "if ('éÁ' =~ /[á]/i) { return 1 } else { return 0 }";
if (Latin9::eval { Latin9::eval }) {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# Latin9::eval {...} has Latin9::eval {...}
if (Latin9::eval { Latin9::eval { if ('éÁ' =~ /[á]/i) { return 1 } else { return 0 } } }) {
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# Latin9::eval {...} has "..."
if (Latin9::eval { if ('éÁ' =~ /[á]/i) { return "1" } else { return "0" } }) {
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# Latin9::eval {...} has qq{...}
if (Latin9::eval { if ('éÁ' =~ /[á]/i) { return qq{1} } else { return qq{0} } }) {
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# Latin9::eval {...} has '...'
if (Latin9::eval { if ('éÁ' =~ /[á]/i) { return '1' } else { return '0' } }) {
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# Latin9::eval {...} has q{...}
if (Latin9::eval { if ('éÁ' =~ /[á]/i) { return q{1} } else { return q{0} } }) {
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# Latin9::eval {...} has $var
my $var1 = 1;
my $var0 = 0;
if (Latin9::eval { if ('éÁ' =~ /[á]/i) { return $var1 } else { return $var0 } }) {
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
