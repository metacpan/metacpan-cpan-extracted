# encoding: Latin10
# This file is encoded in Latin-10.
die "This file is not encoded in Latin-10.\n" if q{��} ne "\x82\xa0";

use Latin10;

print "1..12\n";

my $var = '';

# Latin10::eval $var has Latin10::eval "..."
$var = <<'END';
Latin10::eval " if ('��' =~ /[��]/i) { return 1 } else { return 0 } "
END
if (Latin10::eval $var) {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# Latin10::eval $var has Latin10::eval qq{...}
$var = <<'END';
Latin10::eval qq{ if ('��' =~ /[��]/i) { return 1 } else { return 0 } }
END
if (Latin10::eval $var) {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# Latin10::eval $var has Latin10::eval '...'
$var = <<'END';
Latin10::eval ' if (qq{��} =~ /[��]/i) { return 1 } else { return 0 } '
END
if (Latin10::eval $var) {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# Latin10::eval $var has Latin10::eval q{...}
$var = <<'END';
Latin10::eval q{ if ('��' =~ /[��]/i) { return 1 } else { return 0 } }
END
if (Latin10::eval $var) {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# Latin10::eval $var has Latin10::eval $var
$var = <<'END';
Latin10::eval $var2
END
my $var2 = q{ if ('��' =~ /[��]/i) { return 1 } else { return 0 } };
if (Latin10::eval $var) {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# Latin10::eval $var has Latin10::eval (omit)
$var = <<'END';
Latin10::eval
END
$_ = "if ('��' =~ /[��]/i) { return 1 } else { return 0 }";
if (Latin10::eval $var) {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# Latin10::eval $var has Latin10::eval {...}
$var = <<'END';
Latin10::eval { if ('��' =~ /[��]/i) { return 1 } else { return 0 } }
END
if (Latin10::eval $var) {
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# Latin10::eval $var has "..."
$var = <<'END';
if ('��' =~ /[��]/i) { return "1" } else { return "0" }
END
if (Latin10::eval $var) {
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# Latin10::eval $var has qq{...}
$var = <<'END';
if ('��' =~ /[��]/i) { return qq{1} } else { return qq{0} }
END
if (Latin10::eval $var) {
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# Latin10::eval $var has '...'
$var = <<'END';
if ('��' =~ /[��]/i) { return '1' } else { return '0' }
END
if (Latin10::eval $var) {
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# Latin10::eval $var has q{...}
$var = <<'END';
if ('��' =~ /[��]/i) { return q{1} } else { return q{0} }
END
if (Latin10::eval $var) {
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# Latin10::eval $var has $var
$var = <<'END';
if ('��' =~ /[��]/i) { return $var1 } else { return $var0 }
END
my $var1 = 1;
my $var0 = 0;
if (Latin10::eval $var) {
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
