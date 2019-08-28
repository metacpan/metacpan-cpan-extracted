# encoding: KPS9566
# This file is encoded in KPS9566.
die "This file is not encoded in KPS9566.\n" if q{あ} ne "\x82\xa0";

use KPS9566;

print "1..12\n";

# KPS9566::eval "..." has KPS9566::eval "..."
if (KPS9566::eval " KPS9566::eval \" if ('アソ' !~ /A/) { return 1 } else { return 0 } \" ") {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# KPS9566::eval "..." has KPS9566::eval qq{...}
if (KPS9566::eval " KPS9566::eval qq{ if ('アソ' !~ /A/) { return 1 } else { return 0 } } ") {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# KPS9566::eval "..." has KPS9566::eval '...'
if (KPS9566::eval " KPS9566::eval ' if (qq{アソ} !~ /A/) { return 1 } else { return 0 } ' ") {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# KPS9566::eval "..." has KPS9566::eval q{...}
if (KPS9566::eval " KPS9566::eval q{ if ('アソ' !~ /A/) { return 1 } else { return 0 } } ") {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# KPS9566::eval "..." has KPS9566::eval $var
my $var = q{q{ if ('アソ' !~ /A/) { return 1 } else { return 0 } }};
if (KPS9566::eval " KPS9566::eval $var ") {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# KPS9566::eval "..." has KPS9566::eval (omit)
$_ = "if ('アソ' !~ /A/) { return 1 } else { return 0 }";
if (KPS9566::eval " KPS9566::eval ") {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# KPS9566::eval "..." has KPS9566::eval {...}
if (KPS9566::eval " KPS9566::eval { if ('アソ' !~ /A/) { return 1 } else { return 0 } } ") {
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# KPS9566::eval "..." has "..."
if (KPS9566::eval " if ('アソ' !~ /A/) { return \"1\" } else { return \"0\" } ") {
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# KPS9566::eval "..." has qq{...}
if (KPS9566::eval " if ('アソ' !~ /A/) { return qq{1} } else { return qq{0} } ") {
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# KPS9566::eval "..." has '...'
if (KPS9566::eval " if ('アソ' !~ /A/) { return '1' } else { return '0' } ") {
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# KPS9566::eval "..." has q{...}
if (KPS9566::eval " if ('アソ' !~ /A/) { return q{1} } else { return q{0} } ") {
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# KPS9566::eval "..." has $var
my $var1 = 1;
my $var0 = 0;
if (KPS9566::eval " if ('アソ' !~ /A/) { return $var1 } else { return $var0 } ") {
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
