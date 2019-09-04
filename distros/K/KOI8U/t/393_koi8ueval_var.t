# encoding: KOI8U
# This file is encoded in KOI8-U.
die "This file is not encoded in KOI8-U.\n" if q{ } ne "\x82\xa0";

use KOI8U;

print "1..12\n";

my $var = '';

# KOI8U::eval $var has KOI8U::eval "..."
$var = <<'END';
KOI8U::eval " if ('้ม' =~ /[แ]/i) { return 1 } else { return 0 } "
END
if (KOI8U::eval $var) {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# KOI8U::eval $var has KOI8U::eval qq{...}
$var = <<'END';
KOI8U::eval qq{ if ('้ม' =~ /[แ]/i) { return 1 } else { return 0 } }
END
if (KOI8U::eval $var) {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# KOI8U::eval $var has KOI8U::eval '...'
$var = <<'END';
KOI8U::eval ' if (qq{้ม} =~ /[แ]/i) { return 1 } else { return 0 } '
END
if (KOI8U::eval $var) {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# KOI8U::eval $var has KOI8U::eval q{...}
$var = <<'END';
KOI8U::eval q{ if ('้ม' =~ /[แ]/i) { return 1 } else { return 0 } }
END
if (KOI8U::eval $var) {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# KOI8U::eval $var has KOI8U::eval $var
$var = <<'END';
KOI8U::eval $var2
END
my $var2 = q{ if ('้ม' =~ /[แ]/i) { return 1 } else { return 0 } };
if (KOI8U::eval $var) {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# KOI8U::eval $var has KOI8U::eval (omit)
$var = <<'END';
KOI8U::eval
END
$_ = "if ('้ม' =~ /[แ]/i) { return 1 } else { return 0 }";
if (KOI8U::eval $var) {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# KOI8U::eval $var has KOI8U::eval {...}
$var = <<'END';
KOI8U::eval { if ('้ม' =~ /[แ]/i) { return 1 } else { return 0 } }
END
if (KOI8U::eval $var) {
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# KOI8U::eval $var has "..."
$var = <<'END';
if ('้ม' =~ /[แ]/i) { return "1" } else { return "0" }
END
if (KOI8U::eval $var) {
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# KOI8U::eval $var has qq{...}
$var = <<'END';
if ('้ม' =~ /[แ]/i) { return qq{1} } else { return qq{0} }
END
if (KOI8U::eval $var) {
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# KOI8U::eval $var has '...'
$var = <<'END';
if ('้ม' =~ /[แ]/i) { return '1' } else { return '0' }
END
if (KOI8U::eval $var) {
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# KOI8U::eval $var has q{...}
$var = <<'END';
if ('้ม' =~ /[แ]/i) { return q{1} } else { return q{0} }
END
if (KOI8U::eval $var) {
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# KOI8U::eval $var has $var
$var = <<'END';
if ('้ม' =~ /[แ]/i) { return $var1 } else { return $var0 }
END
my $var1 = 1;
my $var0 = 0;
if (KOI8U::eval $var) {
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
