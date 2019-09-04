# encoding: Latin10
# This file is encoded in Latin-10.
die "This file is not encoded in Latin-10.\n" if q{ } ne "\x82\xa0";

use Latin10;

print "1..12\n";

# Latin10::eval (omit) has Latin10::eval "..."
$_ = <<'END';
Latin10::eval " if ('้ม' =~ /[แ]/i) { return 1 } else { return 0 } "
END
if (Latin10::eval) {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# Latin10::eval (omit) has Latin10::eval qq{...}
$_ = <<'END';
Latin10::eval qq{ if ('้ม' =~ /[แ]/i) { return 1 } else { return 0 } }
END
if (Latin10::eval) {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# Latin10::eval (omit) has Latin10::eval '...'
$_ = <<'END';
Latin10::eval ' if (qq{้ม} =~ /[แ]/i) { return 1 } else { return 0 } '
END
if (Latin10::eval) {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# Latin10::eval (omit) has Latin10::eval q{...}
$_ = <<'END';
Latin10::eval q{ if ('้ม' =~ /[แ]/i) { return 1 } else { return 0 } }
END
if (Latin10::eval) {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# Latin10::eval (omit) has Latin10::eval $var
$_ = <<'END';
Latin10::eval $var2
END
my $var2 = q{ if ('้ม' =~ /[แ]/i) { return 1 } else { return 0 } };
if (Latin10::eval) {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# Latin10::eval (omit) has Latin10::eval (omit)
$_ = <<'END';
$_ = "if ('้ม' =~ /[แ]/i) { return 1 } else { return 0 }";
Latin10::eval
END
if (Latin10::eval) {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# Latin10::eval (omit) has Latin10::eval {...}
$_ = <<'END';
Latin10::eval { if ('้ม' =~ /[แ]/i) { return 1 } else { return 0 } }
END
if (Latin10::eval) {
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# Latin10::eval (omit) has "..."
$_ = <<'END';
if ('้ม' =~ /[แ]/i) { return "1" } else { return "0" }
END
if (Latin10::eval) {
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# Latin10::eval (omit) has qq{...}
$_ = <<'END';
if ('้ม' =~ /[แ]/i) { return qq{1} } else { return qq{0} }
END
if (Latin10::eval) {
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# Latin10::eval (omit) has '...'
$_ = <<'END';
if ('้ม' =~ /[แ]/i) { return '1' } else { return '0' }
END
if (Latin10::eval) {
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# Latin10::eval (omit) has q{...}
$_ = <<'END';
if ('้ม' =~ /[แ]/i) { return q{1} } else { return q{0} }
END
if (Latin10::eval) {
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# Latin10::eval (omit) has $var
$_ = <<'END';
if ('้ม' =~ /[แ]/i) { return $var1 } else { return $var0 }
END
my $var1 = 1;
my $var0 = 0;
if (Latin10::eval) {
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
