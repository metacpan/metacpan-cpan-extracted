# encoding: KPS9566
# This file is encoded in KPS9566.
die "This file is not encoded in KPS9566.\n" if q{あ} ne "\x82\xa0";

use KPS9566;

print "1..12\n";

my $var = '';

# eval $var has eval "..."
$var = <<'END';
eval KPS9566::escape " if ('アソ' !~ /A/) { return 1 } else { return 0 } "
END
if (eval KPS9566::escape $var) {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# eval $var has eval qq{...}
$var = <<'END';
eval KPS9566::escape qq{ if ('アソ' !~ /A/) { return 1 } else { return 0 } }
END
if (eval KPS9566::escape $var) {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# eval $var has eval '...'
$var = <<'END';
eval KPS9566::escape ' if (qq{アソ} !~ /A/) { return 1 } else { return 0 } '
END
if (eval KPS9566::escape $var) {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# eval $var has eval q{...}
$var = <<'END';
eval KPS9566::escape q{ if ('アソ' !~ /A/) { return 1 } else { return 0 } }
END
if (eval KPS9566::escape $var) {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# eval $var has eval $var
$var = <<'END';
eval KPS9566::escape $var2
END
my $var2 = q{ if ('アソ' !~ /A/) { return 1 } else { return 0 } };
if (eval KPS9566::escape $var) {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# eval $var has eval (omit)
$var = <<'END';
eval KPS9566::escape
END
$_ = "if ('アソ' !~ /A/) { return 1 } else { return 0 }";
if (eval KPS9566::escape $var) {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# eval $var has eval {...}
$var = <<'END';
eval { if ('アソ' !~ /A/) { return 1 } else { return 0 } }
END
if (eval KPS9566::escape $var) {
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# eval $var has "..."
$var = <<'END';
if ('アソ' !~ /A/) { return "1" } else { return "0" }
END
if (eval KPS9566::escape $var) {
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# eval $var has qq{...}
$var = <<'END';
if ('アソ' !~ /A/) { return qq{1} } else { return qq{0} }
END
if (eval KPS9566::escape $var) {
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# eval $var has '...'
$var = <<'END';
if ('アソ' !~ /A/) { return '1' } else { return '0' }
END
if (eval KPS9566::escape $var) {
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# eval $var has q{...}
$var = <<'END';
if ('アソ' !~ /A/) { return q{1} } else { return q{0} }
END
if (eval KPS9566::escape $var) {
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# eval $var has $var
$var = <<'END';
if ('アソ' !~ /A/) { return $var1 } else { return $var0 }
END
my $var1 = 1;
my $var0 = 0;
if (eval KPS9566::escape $var) {
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
