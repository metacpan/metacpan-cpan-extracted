# encoding: KOI8R
# This file is encoded in KOI8-R.
die "This file is not encoded in KOI8-R.\n" if q{ } ne "\x82\xa0";

use KOI8R;

print "1..12\n";

# KOI8R::eval <<'END' has KOI8R::eval "..."
if (KOI8R::eval <<'END') {
KOI8R::eval " if ('้ม' =~ /[แ]/i) { return 1 } else { return 0 } "
END
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# KOI8R::eval <<'END' has KOI8R::eval qq{...}
if (KOI8R::eval <<'END') {
KOI8R::eval qq{ if ('้ม' =~ /[แ]/i) { return 1 } else { return 0 } }
END
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# KOI8R::eval <<'END' has KOI8R::eval '...'
if (KOI8R::eval <<'END') {
KOI8R::eval ' if (qq{้ม} =~ /[แ]/i) { return 1 } else { return 0 } '
END
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# KOI8R::eval <<'END' has KOI8R::eval q{...}
if (KOI8R::eval <<'END') {
KOI8R::eval q{ if ('้ม' =~ /[แ]/i) { return 1 } else { return 0 } }
END
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# KOI8R::eval <<'END' has KOI8R::eval $var
my $var = q{ if ('้ม' =~ /[แ]/i) { return 1 } else { return 0 } };
if (KOI8R::eval <<'END') {
KOI8R::eval $var
END
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# KOI8R::eval <<'END' has KOI8R::eval (omit)
$_ = "if ('้ม' =~ /[แ]/i) { return 1 } else { return 0 }";
if (KOI8R::eval <<'END') {
KOI8R::eval
END
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# KOI8R::eval <<'END' has KOI8R::eval {...}
if (KOI8R::eval <<'END') {
KOI8R::eval { if ('้ม' =~ /[แ]/i) { return 1 } else { return 0 } }
END
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# KOI8R::eval <<'END' has "..."
if (KOI8R::eval <<'END') {
if ('้ม' =~ /[แ]/i) { return "1" } else { return "0" }
END
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# KOI8R::eval <<'END' has qq{...}
if (KOI8R::eval <<'END') {
if ('้ม' =~ /[แ]/i) { return qq{1} } else { return qq{0} }
END
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# KOI8R::eval <<'END' has '...'
if (KOI8R::eval <<'END') {
if ('้ม' =~ /[แ]/i) { return '1' } else { return '0' }
END
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# KOI8R::eval <<'END' has q{...}
if (KOI8R::eval <<'END') {
if ('้ม' =~ /[แ]/i) { return q{1} } else { return q{0} }
END
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# KOI8R::eval <<'END' has $var
my $var1 = 1;
my $var0 = 0;
if (KOI8R::eval <<'END') {
if ('้ม' =~ /[แ]/i) { return $var1 } else { return $var0 }
END
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
