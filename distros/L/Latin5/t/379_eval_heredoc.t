# encoding: Latin5
# This file is encoded in Latin-5.
die "This file is not encoded in Latin-5.\n" if q{‚ } ne "\x82\xa0";

use Latin5;

print "1..12\n";

# eval <<END has eval "..."
if (eval Latin5::escape <<END) {
eval Latin5::escape " if ('éÁ' =~ /[Šá]/i) { return 1 } else { return 0 } "
END
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# eval <<END has eval qq{...}
if (eval Latin5::escape <<END) {
eval Latin5::escape qq{ if ('éÁ' =~ /[Šá]/i) { return 1 } else { return 0 } }
END
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# eval <<END has eval '...'
if (eval Latin5::escape <<END) {
eval Latin5::escape ' if (qq{éÁ} =~ /[Šá]/i) { return 1 } else { return 0 } '
END
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# eval <<END has eval q{...}
if (eval Latin5::escape <<END) {
eval Latin5::escape q{ if ('éÁ' =~ /[Šá]/i) { return 1 } else { return 0 } }
END
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# eval <<END has eval $var
my $var = q{q{ if ('éÁ' =~ /[Šá]/i) { return 1 } else { return 0 } }};
if (eval Latin5::escape <<END) {
eval Latin5::escape $var
END
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# eval <<END has eval (omit)
$_ = "if ('éÁ' =~ /[Šá]/i) { return 1 } else { return 0 }";
if (eval Latin5::escape <<END) {
eval Latin5::escape
END
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# eval <<END has eval {...}
if (eval Latin5::escape <<END) {
eval { if ('éÁ' =~ /[Šá]/i) { return 1 } else { return 0 } }
END
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# eval <<END has "..."
if (eval Latin5::escape <<END) {
if ('éÁ' =~ /[Šá]/i) { return \"1\" } else { return \"0\" }
END
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# eval <<END has qq{...}
if (eval Latin5::escape <<END) {
if ('éÁ' =~ /[Šá]/i) { return qq{1} } else { return qq{0} }
END
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# eval <<END has '...'
if (eval Latin5::escape <<END) {
if ('éÁ' =~ /[Šá]/i) { return '1' } else { return '0' }
END
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# eval <<END has q{...}
if (eval Latin5::escape <<END) {
if ('éÁ' =~ /[Šá]/i) { return q{1} } else { return q{0} }
END
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# eval <<END has $var
my $var1 = 1;
my $var0 = 0;
if (eval Latin5::escape <<END) {
if ('éÁ' =~ /[Šá]/i) { return $var1 } else { return $var0 }
END
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
