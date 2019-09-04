# encoding: Greek
# This file is encoded in Greek.
die "This file is not encoded in Greek.\n" if q{ } ne "\x82\xa0";

use Greek;

print "1..12\n";

# Greek::eval (omit) has Greek::eval "..."
$_ = <<'END';
Greek::eval " if ('ιΑ' =~ /[α]/i) { return 1 } else { return 0 } "
END
if (Greek::eval) {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# Greek::eval (omit) has Greek::eval qq{...}
$_ = <<'END';
Greek::eval qq{ if ('ιΑ' =~ /[α]/i) { return 1 } else { return 0 } }
END
if (Greek::eval) {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# Greek::eval (omit) has Greek::eval '...'
$_ = <<'END';
Greek::eval ' if (qq{ιΑ} =~ /[α]/i) { return 1 } else { return 0 } '
END
if (Greek::eval) {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# Greek::eval (omit) has Greek::eval q{...}
$_ = <<'END';
Greek::eval q{ if ('ιΑ' =~ /[α]/i) { return 1 } else { return 0 } }
END
if (Greek::eval) {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# Greek::eval (omit) has Greek::eval $var
$_ = <<'END';
Greek::eval $var2
END
my $var2 = q{ if ('ιΑ' =~ /[α]/i) { return 1 } else { return 0 } };
if (Greek::eval) {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# Greek::eval (omit) has Greek::eval (omit)
$_ = <<'END';
$_ = "if ('ιΑ' =~ /[α]/i) { return 1 } else { return 0 }";
Greek::eval
END
if (Greek::eval) {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# Greek::eval (omit) has Greek::eval {...}
$_ = <<'END';
Greek::eval { if ('ιΑ' =~ /[α]/i) { return 1 } else { return 0 } }
END
if (Greek::eval) {
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# Greek::eval (omit) has "..."
$_ = <<'END';
if ('ιΑ' =~ /[α]/i) { return "1" } else { return "0" }
END
if (Greek::eval) {
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# Greek::eval (omit) has qq{...}
$_ = <<'END';
if ('ιΑ' =~ /[α]/i) { return qq{1} } else { return qq{0} }
END
if (Greek::eval) {
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# Greek::eval (omit) has '...'
$_ = <<'END';
if ('ιΑ' =~ /[α]/i) { return '1' } else { return '0' }
END
if (Greek::eval) {
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# Greek::eval (omit) has q{...}
$_ = <<'END';
if ('ιΑ' =~ /[α]/i) { return q{1} } else { return q{0} }
END
if (Greek::eval) {
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# Greek::eval (omit) has $var
$_ = <<'END';
if ('ιΑ' =~ /[α]/i) { return $var1 } else { return $var0 }
END
my $var1 = 1;
my $var0 = 0;
if (Greek::eval) {
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
