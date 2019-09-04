# encoding: Latin7
# This file is encoded in Latin-7.
die "This file is not encoded in Latin-7.\n" if q{ } ne "\x82\xa0";

use Latin7;

print "1..12\n";

# eval (omit) has eval "..."
$_ = <<'END';
eval Latin7::escape " if ('éĮ' =~ /[į]/i) { return 1 } else { return 0 } "
END
if (eval Latin7::escape) {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# eval (omit) has eval qq{...}
$_ = <<'END';
eval Latin7::escape qq{ if ('éĮ' =~ /[į]/i) { return 1 } else { return 0 } }
END
if (eval Latin7::escape) {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# eval (omit) has eval '...'
$_ = <<'END';
eval Latin7::escape ' if (qq{éĮ} =~ /[į]/i) { return 1 } else { return 0 } '
END
if (eval Latin7::escape) {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# eval (omit) has eval q{...}
$_ = <<'END';
eval Latin7::escape q{ if ('éĮ' =~ /[į]/i) { return 1 } else { return 0 } }
END
if (eval Latin7::escape) {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# eval (omit) has eval $var
$_ = <<'END';
eval Latin7::escape $var2
END
my $var2 = q{ if ('éĮ' =~ /[į]/i) { return 1 } else { return 0 } };
if (eval Latin7::escape) {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# eval (omit) has eval (omit)
$_ = <<'END';
$_ = "if ('éĮ' =~ /[į]/i) { return 1 } else { return 0 }";
eval Latin7::escape
END
if (eval Latin7::escape) {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# eval (omit) has eval {...}
$_ = <<'END';
eval { if ('éĮ' =~ /[į]/i) { return 1 } else { return 0 } }
END
if (eval Latin7::escape) {
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# eval (omit) has "..."
$_ = <<'END';
if ('éĮ' =~ /[į]/i) { return "1" } else { return "0" }
END
if (eval Latin7::escape) {
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# eval (omit) has qq{...}
$_ = <<'END';
if ('éĮ' =~ /[į]/i) { return qq{1} } else { return qq{0} }
END
if (eval Latin7::escape) {
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# eval (omit) has '...'
$_ = <<'END';
if ('éĮ' =~ /[į]/i) { return '1' } else { return '0' }
END
if (eval Latin7::escape) {
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# eval (omit) has q{...}
$_ = <<'END';
if ('éĮ' =~ /[į]/i) { return q{1} } else { return q{0} }
END
if (eval Latin7::escape) {
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# eval (omit) has $var
$_ = <<'END';
if ('éĮ' =~ /[į]/i) { return $var1 } else { return $var0 }
END
my $var1 = 1;
my $var0 = 0;
if (eval Latin7::escape) {
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
