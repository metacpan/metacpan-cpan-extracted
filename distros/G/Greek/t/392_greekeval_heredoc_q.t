# encoding: Greek
# This file is encoded in Greek.
die "This file is not encoded in Greek.\n" if q{ } ne "\x82\xa0";

use Greek;

print "1..12\n";

# Greek::eval <<'END' has Greek::eval "..."
if (Greek::eval <<'END') {
Greek::eval " if ('ιΑ' =~ /[α]/i) { return 1 } else { return 0 } "
END
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# Greek::eval <<'END' has Greek::eval qq{...}
if (Greek::eval <<'END') {
Greek::eval qq{ if ('ιΑ' =~ /[α]/i) { return 1 } else { return 0 } }
END
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# Greek::eval <<'END' has Greek::eval '...'
if (Greek::eval <<'END') {
Greek::eval ' if (qq{ιΑ} =~ /[α]/i) { return 1 } else { return 0 } '
END
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# Greek::eval <<'END' has Greek::eval q{...}
if (Greek::eval <<'END') {
Greek::eval q{ if ('ιΑ' =~ /[α]/i) { return 1 } else { return 0 } }
END
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# Greek::eval <<'END' has Greek::eval $var
my $var = q{ if ('ιΑ' =~ /[α]/i) { return 1 } else { return 0 } };
if (Greek::eval <<'END') {
Greek::eval $var
END
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# Greek::eval <<'END' has Greek::eval (omit)
$_ = "if ('ιΑ' =~ /[α]/i) { return 1 } else { return 0 }";
if (Greek::eval <<'END') {
Greek::eval
END
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# Greek::eval <<'END' has Greek::eval {...}
if (Greek::eval <<'END') {
Greek::eval { if ('ιΑ' =~ /[α]/i) { return 1 } else { return 0 } }
END
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# Greek::eval <<'END' has "..."
if (Greek::eval <<'END') {
if ('ιΑ' =~ /[α]/i) { return "1" } else { return "0" }
END
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# Greek::eval <<'END' has qq{...}
if (Greek::eval <<'END') {
if ('ιΑ' =~ /[α]/i) { return qq{1} } else { return qq{0} }
END
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# Greek::eval <<'END' has '...'
if (Greek::eval <<'END') {
if ('ιΑ' =~ /[α]/i) { return '1' } else { return '0' }
END
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# Greek::eval <<'END' has q{...}
if (Greek::eval <<'END') {
if ('ιΑ' =~ /[α]/i) { return q{1} } else { return q{0} }
END
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# Greek::eval <<'END' has $var
my $var1 = 1;
my $var0 = 0;
if (Greek::eval <<'END') {
if ('ιΑ' =~ /[α]/i) { return $var1 } else { return $var0 }
END
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
