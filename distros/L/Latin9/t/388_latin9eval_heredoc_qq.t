# encoding: Latin9
# This file is encoded in Latin-9.
die "This file is not encoded in Latin-9.\n" if q{��} ne "\x82\xa0";

use Latin9;

print "1..12\n";

# Latin9::eval <<"END" has Latin9::eval "..."
if (Latin9::eval <<"END") {
Latin9::eval " if ('��' =~ /[��]/i) { return 1 } else { return 0 } "
END
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# Latin9::eval <<"END" has Latin9::eval qq{...}
if (Latin9::eval <<"END") {
Latin9::eval qq{ if ('��' =~ /[��]/i) { return 1 } else { return 0 } }
END
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# Latin9::eval <<"END" has Latin9::eval '...'
if (Latin9::eval <<"END") {
Latin9::eval ' if (qq{��} =~ /[��]/i) { return 1 } else { return 0 } '
END
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# Latin9::eval <<"END" has Latin9::eval q{...}
if (Latin9::eval <<"END") {
Latin9::eval q{ if ('��' =~ /[��]/i) { return 1 } else { return 0 } }
END
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# Latin9::eval <<"END" has Latin9::eval $var
my $var = q{q{ if ('��' =~ /[��]/i) { return 1 } else { return 0 } }};
if (Latin9::eval <<"END") {
Latin9::eval $var
END
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# Latin9::eval <<"END" has Latin9::eval (omit)
$_ = "if ('��' =~ /[��]/i) { return 1 } else { return 0 }";
if (Latin9::eval <<"END") {
Latin9::eval
END
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# Latin9::eval <<"END" has Latin9::eval {...}
if (Latin9::eval <<"END") {
Latin9::eval { if ('��' =~ /[��]/i) { return 1 } else { return 0 } }
END
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# Latin9::eval <<"END" has "..."
if (Latin9::eval <<"END") {
if ('��' =~ /[��]/i) { return \"1\" } else { return \"0\" }
END
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# Latin9::eval <<"END" has qq{...}
if (Latin9::eval <<"END") {
if ('��' =~ /[��]/i) { return qq{1} } else { return qq{0} }
END
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# Latin9::eval <<"END" has '...'
if (Latin9::eval <<"END") {
if ('��' =~ /[��]/i) { return '1' } else { return '0' }
END
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# Latin9::eval <<"END" has q{...}
if (Latin9::eval <<"END") {
if ('��' =~ /[��]/i) { return q{1} } else { return q{0} }
END
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# Latin9::eval <<"END" has $var
my $var1 = 1;
my $var0 = 0;
if (Latin9::eval <<"END") {
if ('��' =~ /[��]/i) { return $var1 } else { return $var0 }
END
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
