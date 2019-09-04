# encoding: Latin7
# This file is encoded in Latin-7.
die "This file is not encoded in Latin-7.\n" if q{ } ne "\x82\xa0";

use Latin7;

print "1..12\n";

# Latin7::eval <<END has Latin7::eval "..."
if (Latin7::eval <<END) {
Latin7::eval " if ('éĮ' =~ /[į]/i) { return 1 } else { return 0 } "
END
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# Latin7::eval <<END has Latin7::eval qq{...}
if (Latin7::eval <<END) {
Latin7::eval qq{ if ('éĮ' =~ /[į]/i) { return 1 } else { return 0 } }
END
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# Latin7::eval <<END has Latin7::eval '...'
if (Latin7::eval <<END) {
Latin7::eval ' if (qq{éĮ} =~ /[į]/i) { return 1 } else { return 0 } '
END
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# Latin7::eval <<END has Latin7::eval q{...}
if (Latin7::eval <<END) {
Latin7::eval q{ if ('éĮ' =~ /[į]/i) { return 1 } else { return 0 } }
END
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# Latin7::eval <<END has Latin7::eval $var
my $var = q{q{ if ('éĮ' =~ /[į]/i) { return 1 } else { return 0 } }};
if (Latin7::eval <<END) {
Latin7::eval $var
END
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# Latin7::eval <<END has Latin7::eval (omit)
$_ = "if ('éĮ' =~ /[į]/i) { return 1 } else { return 0 }";
if (Latin7::eval <<END) {
Latin7::eval
END
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# Latin7::eval <<END has Latin7::eval {...}
if (Latin7::eval <<END) {
Latin7::eval { if ('éĮ' =~ /[į]/i) { return 1 } else { return 0 } }
END
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# Latin7::eval <<END has "..."
if (Latin7::eval <<END) {
if ('éĮ' =~ /[į]/i) { return \"1\" } else { return \"0\" }
END
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# Latin7::eval <<END has qq{...}
if (Latin7::eval <<END) {
if ('éĮ' =~ /[į]/i) { return qq{1} } else { return qq{0} }
END
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# Latin7::eval <<END has '...'
if (Latin7::eval <<END) {
if ('éĮ' =~ /[į]/i) { return '1' } else { return '0' }
END
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# Latin7::eval <<END has q{...}
if (Latin7::eval <<END) {
if ('éĮ' =~ /[į]/i) { return q{1} } else { return q{0} }
END
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# Latin7::eval <<END has $var
my $var1 = 1;
my $var0 = 0;
if (Latin7::eval <<END) {
if ('éĮ' =~ /[į]/i) { return $var1 } else { return $var0 }
END
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
