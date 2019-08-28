# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{ㄲ} ne "\xa4\xa2";

use KSC5601;

print "1..12\n";

# KSC5601::eval (omit) has KSC5601::eval "..."
$_ = <<'END';
KSC5601::eval " if ('⇔∧' !~ /⇒/) { return 1 } else { return 0 } "
END
if (KSC5601::eval) {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# KSC5601::eval (omit) has KSC5601::eval qq{...}
$_ = <<'END';
KSC5601::eval qq{ if ('⇔∧' !~ /⇒/) { return 1 } else { return 0 } }
END
if (KSC5601::eval) {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# KSC5601::eval (omit) has KSC5601::eval '...'
$_ = <<'END';
KSC5601::eval ' if (qq{⇔∧} !~ /⇒/) { return 1 } else { return 0 } '
END
if (KSC5601::eval) {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# KSC5601::eval (omit) has KSC5601::eval q{...}
$_ = <<'END';
KSC5601::eval q{ if ('⇔∧' !~ /⇒/) { return 1 } else { return 0 } }
END
if (KSC5601::eval) {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# KSC5601::eval (omit) has KSC5601::eval $var
$_ = <<'END';
KSC5601::eval $var2
END
my $var2 = q{ if ('⇔∧' !~ /⇒/) { return 1 } else { return 0 } };
if (KSC5601::eval) {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# KSC5601::eval (omit) has KSC5601::eval (omit)
$_ = <<'END';
$_ = "if ('⇔∧' !~ /⇒/) { return 1 } else { return 0 }";
KSC5601::eval
END
if (KSC5601::eval) {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# KSC5601::eval (omit) has KSC5601::eval {...}
$_ = <<'END';
KSC5601::eval { if ('⇔∧' !~ /⇒/) { return 1 } else { return 0 } }
END
if (KSC5601::eval) {
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# KSC5601::eval (omit) has "..."
$_ = <<'END';
if ('⇔∧' !~ /⇒/) { return "1" } else { return "0" }
END
if (KSC5601::eval) {
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# KSC5601::eval (omit) has qq{...}
$_ = <<'END';
if ('⇔∧' !~ /⇒/) { return qq{1} } else { return qq{0} }
END
if (KSC5601::eval) {
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# KSC5601::eval (omit) has '...'
$_ = <<'END';
if ('⇔∧' !~ /⇒/) { return '1' } else { return '0' }
END
if (KSC5601::eval) {
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# KSC5601::eval (omit) has q{...}
$_ = <<'END';
if ('⇔∧' !~ /⇒/) { return q{1} } else { return q{0} }
END
if (KSC5601::eval) {
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# KSC5601::eval (omit) has $var
$_ = <<'END';
if ('⇔∧' !~ /⇒/) { return $var1 } else { return $var0 }
END
my $var1 = 1;
my $var0 = 0;
if (KSC5601::eval) {
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
