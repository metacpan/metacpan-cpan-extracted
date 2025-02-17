# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{��} ne "\xa4\xa2";

use strict;
use KSC5601;
print "1..11\n";

my $__FILE__ = __FILE__;

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/p) {
    if (${^MATCH} eq '123') {
        print qq{ok - 1 \${^MATCH} $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 \${^MATCH} $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 \${^MATCH} $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/p) {
    if ("${^MATCH}" eq '123') {
        print qq{ok - 2 "\${^MATCH}" $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 2 "\${^MATCH}" $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 2 "\${^MATCH}" $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/p) {
    if (qq{${^MATCH}} eq '123') {
        print qq{ok - 3 qq{\${^MATCH}} $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 3 qq{\${^MATCH}} $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 3 qq{\${^MATCH}} $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/p) {
    if (<<END eq "123\n") {
${^MATCH}
END
        print qq{ok - 4 <<END\${^MATCH}END $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 4 <<END\${^MATCH}END $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 4 <<END\${^MATCH}END $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/p) {
    if (<<"END" eq "123\n") {
${^MATCH}
END
        print qq{ok - 5 <<"END"\${^MATCH}END $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 5 <<"END"\${^MATCH}END $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 5 <<"END"\${^MATCH}END $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/p) {
    if ('987123456' =~ /(${^MATCH})/) {
        if (${^MATCH} eq '123') {
            print qq{ok - 6 /\${^MATCH}/ $^X $__FILE__\n};
        }
        else {
            print qq{not ok - 6 /\${^MATCH}/ $^X $__FILE__\n};
        }
    }
    else {
        print qq{not ok - 6 /\${^MATCH}/ $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 6 /\${^MATCH}/ $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/p) {
    if ('987123456' =~ m/(${^MATCH})/) {
        if (${^MATCH} eq '123') {
            print qq{ok - 7 m/\${^MATCH}/ $^X $__FILE__\n};
        }
        else {
            print qq{not ok - 7 m/\${^MATCH}/ $^X $__FILE__\n};
        }
    }
    else {
        print qq{not ok - 7 m/\${^MATCH}/ $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 7 m/\${^MATCH}/ $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/p) {
    $_ = '987123456';
    if ($_ =~ s/(${^MATCH})/jkl/) {
        if ($_ eq '987jkl456') {
            print qq{ok - 8 s/\${^MATCH}// $^X $__FILE__\n};
        }
        else {
            print qq{not ok - 8 s/\${^MATCH}// $^X $__FILE__\n};
        }
    }
    else {
        print qq{not ok - 8 s/\${^MATCH}// $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 8 s/\${^MATCH}// $^X $__FILE__\n};
}

$_ = '123,456,789';
if ($_ =~ m/(,)/p) {
    @_ = split(/${^MATCH}/,'AAA,BBB,CCC,DDD');
    if (join('+',@_) eq 'AAA+BBB+CCC+DDD') {
        print qq{ok - 9 split(/${^MATCH}/) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 9 split(/${^MATCH}/) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 9 split(/${^MATCH}/) $^X $__FILE__\n};
}

$_ = '123,456,789';
if ($_ =~ m/(,)/p) {
    @_ = split(m/${^MATCH}/,'AAA,BBB,CCC,DDD');
    if (join('+',@_) eq 'AAA+BBB+CCC+DDD') {
        print qq{ok - 10 split(m/${^MATCH}/) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 10 split(m/${^MATCH}/) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 10 split(m/${^MATCH}/) $^X $__FILE__\n};
}

$_ = '123,456,789';
if ($_ =~ m/(,)/p) {
    @_ = split(qr/${^MATCH}/,'AAA,BBB,CCC,DDD');
    if (join('+',@_) eq 'AAA+BBB+CCC+DDD') {
        print qq{ok - 11 split(qr/${^MATCH}/) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 11 split(qr/${^MATCH}/) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 11 split(qr/${^MATCH}/) $^X $__FILE__\n};
}

__END__

