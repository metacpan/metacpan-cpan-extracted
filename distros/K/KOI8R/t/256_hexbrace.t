# encoding: KOI8R
# This file is encoded in KOI8-R.
die "This file is not encoded in KOI8-R.\n" if q{‚ } ne "\x82\xa0";

use strict;
use KOI8R;
print "1..5\n";

my $__FILE__ = __FILE__;

# ""
if ("\x{12345678}" eq "\x12\x34\x56\x78") {
    print qq{ok - 1 "\\x{12345678}" eq "\\x12\\x34\\x56\\x78" $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 "\\x{12345678}" eq "\\x12\\x34\\x56\\x78" $^X $__FILE__\n};
}

# <<HEREDOC
my $var1 = <<END;
\x{12345678}
END
my $var2 = <<END;
\x12\x34\x56\x78
END
if ($var1 eq $var2) {
    print qq{ok - 2 <<END \\x{12345678} END eq <<END \\x12\\x34\\x56\\x78 END $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 <<END \\x{12345678} END eq <<END \\x12\\x34\\x56\\x78 END $^X $__FILE__\n};
}

# m//
if ("\x12\x34\x56\x78" =~ /\x{12345678}/) {
    print qq{ok - 3 "\\x12\\x34\\x56\\x78" =~ /\\x{12345678}/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 "\\x12\\x34\\x56\\x78" =~ /\\x{12345678}/ $^X $__FILE__\n};
}

# s///
my $var = "\x12\x34\x56\x78";
if ($var =~ s/\x{12345678}//) {
    print qq{ok - 4 "\\x12\\x34\\x56\\x78" =~ s/\\x{12345678}// $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 "\\x12\\x34\\x56\\x78" =~ s/\\x{12345678}// $^X $__FILE__\n};
}

# split //
@_ = split(/\x{12345678}/,"AAA\x12\x34\x56\x78BBB\x12\x34\x56\x78CCC");
if (scalar(@_) == 3) {
    print qq{ok - 5 split(/\\x{12345678}/,"AAA\\x12\\x34\\x56\\x78BBB\\x12\\x34\\x56\\x78CCC") == 3 $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 split(/\\x{12345678}/,"AAA\\x12\\x34\\x56\\x78BBB\\x12\\x34\\x56\\x78CCC") == 3 $^X $__FILE__\n};
}

__END__
