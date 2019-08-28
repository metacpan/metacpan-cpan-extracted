# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{ㄲ} ne "\xa4\xa2";

use strict;
use KSC5601;
print "1..11\n";

my $__FILE__ = __FILE__;

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if ($' eq 'XYZ456') {
        print qq{ok - 1 \$' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 \$' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 \$' $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if ("$'" eq 'XYZ456') {
        print qq{ok - 2 "\$'" $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 2 "\$'" $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 2 "\$'" $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if (qq{$'} eq 'XYZ456') {
        print qq{ok - 3 qq{\$'} $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 3 qq{\$'} $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 3 qq{\$'} $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if (<<END eq "XYZ456\n") {
$'
END
        print qq{ok - 4 <<END\$'END $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 4 <<END\$'END $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 4 <<END\$'END $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if (<<"END" eq "XYZ456\n") {
$'
END
        print qq{ok - 5 <<"END"\$'END $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 5 <<"END"\$'END $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 5 <<"END"\$'END $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if ('AABABCXXYXYZ456' =~ /($')/) {
        if ($& eq 'XYZ456') {
            print qq{ok - 6 /\$'/ $^X $__FILE__\n};
        }
        else {
            print qq{not ok - 6 /\$'/ $^X $__FILE__\n};
        }
    }
    else {
        print qq{not ok - 6 /\$'/ $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 6 /\$'/ $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if ('AABABCXXYXYZ456' =~ m/($')/) {
        if ($& eq 'XYZ456') {
            print qq{ok - 7 m/\$'/ $^X $__FILE__\n};
        }
        else {
            print qq{not ok - 7 m/\$'/ $^X $__FILE__\n};
        }
    }
    else {
        print qq{not ok - 7 m/\$'/ $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 7 m/\$'/ $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    $_ = 'AABABCXXYXYZ456';
    if ($_ =~ s/($')/jkl/) {
        if ($_ eq 'AABABCXXYjkl') {
            print qq{ok - 8 s/\$'// $^X $__FILE__\n};
        }
        else {
            print qq{not ok - 8 s/\$'// $^X $__FILE__\n};
        }
    }
    else {
        print qq{not ok - 8 s/\$'// $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 8 s/\$'// $^X $__FILE__\n};
}

$_ = ',123,';
if ($_ =~ m/([0-9]+)/) {
    @_ = split(/$'/,'AAA,BBB,CCC,DDD');
    if (join('+',@_) eq 'AAA+BBB+CCC+DDD') {
        print qq{ok - 9 split(/$'/) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 9 split(/$'/) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 9 split(/$'/) $^X $__FILE__\n};
}

$_ = ',123,';
if ($_ =~ m/([0-9]+)/) {
    @_ = split(m/$'/,'AAA,BBB,CCC,DDD');
    if (join('+',@_) eq 'AAA+BBB+CCC+DDD') {
        print qq{ok - 10 split(m/$'/) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 10 split(m/$'/) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 10 split(m/$'/) $^X $__FILE__\n};
}

$_ = ',123,';
if ($_ =~ m/([0-9]+)/) {
    @_ = split(qr/$'/,'AAA,BBB,CCC,DDD');
    if (join('+',@_) eq 'AAA+BBB+CCC+DDD') {
        print qq{ok - 11 split(qr/$'/) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 11 split(qr/$'/) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 11 split(qr/$'/) $^X $__FILE__\n};
}

__END__

