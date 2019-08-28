# encoding: KPS9566
# This file is encoded in KPS9566.
die "This file is not encoded in KPS9566.\n" if q{‚ } ne "\x82\xa0";

use strict;
use KPS9566;
print "1..11\n";

my $__FILE__ = __FILE__;

eval {
    require English;
    English->import;
};
if ($@) {
    for (1..11) {
        print qq{ok - $_ # PASS $^X $__FILE__\n};
    }
    exit;
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if (${PREMATCH} eq 'ABC') {
        print qq{ok - 1 \${PREMATCH} $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 \${PREMATCH} $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 \${PREMATCH} $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if ("${PREMATCH}" eq 'ABC') {
        print qq{ok - 2 "\${PREMATCH}" $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 2 "\${PREMATCH}" $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 2 "\${PREMATCH}" $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if (qq{${PREMATCH}} eq 'ABC') {
        print qq{ok - 3 qq{\${PREMATCH}} $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 3 qq{\${PREMATCH}} $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 3 qq{\${PREMATCH}} $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if (<<END eq "ABC\n") {
${PREMATCH}
END
        print qq{ok - 4 <<END\${PREMATCH}END $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 4 <<END\${PREMATCH}END $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 4 <<END\${PREMATCH}END $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if (<<"END" eq "ABC\n") {
${PREMATCH}
END
        print qq{ok - 5 <<"END"\${PREMATCH}END $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 5 <<"END"\${PREMATCH}END $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 5 <<"END"\${PREMATCH}END $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if ('AABABCXXYXYZ' =~ /(${PREMATCH})/) {
        if ($& eq 'ABC') {
            print qq{ok - 6 /\${PREMATCH}/ $^X $__FILE__\n};
        }
        else {
            print qq{not ok - 6 /\${PREMATCH}/ $^X $__FILE__\n};
        }
    }
    else {
        print qq{not ok - 6 /\${PREMATCH}/ $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 6 /\${PREMATCH}/ $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if ('AABABCXXYXYZ' =~ m/(${PREMATCH})/) {
        if ($& eq 'ABC') {
            print qq{ok - 7 m/\${PREMATCH}/ $^X $__FILE__\n};
        }
        else {
            print qq{not ok - 7 m/\${PREMATCH}/ $^X $__FILE__\n};
        }
    }
    else {
        print qq{not ok - 7 m/\${PREMATCH}/ $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 7 m/\${PREMATCH}/ $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    $_ = 'AABABCXXYXYZ';
    if ($_ =~ s/(${PREMATCH})/jkl/) {
        if ($_ eq 'AABjklXXYXYZ') {
            print qq{ok - 8 s/\${PREMATCH}// $^X $__FILE__\n};
        }
        else {
            print qq{not ok - 8 s/\${PREMATCH}// $^X $__FILE__\n};
        }
    }
    else {
        print qq{not ok - 8 s/\${PREMATCH}// $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 8 s/\${PREMATCH}// $^X $__FILE__\n};
}

$_ = ',123,456,789';
if ($_ =~ m/([0-9]+)/) {
    @_ = split(/${PREMATCH}/,'AAA,BBB,CCC,DDD');
    if (join('+',@_) eq 'AAA+BBB+CCC+DDD') {
        print qq{ok - 9 split(/${PREMATCH}/) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 9 split(/${PREMATCH}/) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 9 split(/${PREMATCH}/) $^X $__FILE__\n};
}

$_ = ',123,456,789';
if ($_ =~ m/([0-9]+)/) {
    @_ = split(m/${PREMATCH}/,'AAA,BBB,CCC,DDD');
    if (join('+',@_) eq 'AAA+BBB+CCC+DDD') {
        print qq{ok - 10 split(m/${PREMATCH}/) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 10 split(m/${PREMATCH}/) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 10 split(m/${PREMATCH}/) $^X $__FILE__\n};
}

$_ = ',123,456,789';
if ($_ =~ m/([0-9]+)/) {
    @_ = split(qr/${PREMATCH}/,'AAA,BBB,CCC,DDD');
    if (join('+',@_) eq 'AAA+BBB+CCC+DDD') {
        print qq{ok - 11 split(qr/${PREMATCH}/) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 11 split(qr/${PREMATCH}/) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 11 split(qr/${PREMATCH}/) $^X $__FILE__\n};
}

__END__

