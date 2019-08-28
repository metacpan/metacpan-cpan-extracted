# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{¤¢} ne "\xa4\xa2";

use KSC5601;
print "1..3\n";

my $__FILE__ = __FILE__;

$text = '£É£Ï¡¥£Ó£Ù£Ó¡§£²£²£µ£µ£µ£¸¡§£¹£µ¡Ý£±£°¡Ý£°£³¡§¡Ý£á¡Ý£ó£è¡§£ï£ð£ô£é£ï£î£á£ì';

local $^W = 0;

# 7.7 split±é»»»Ò(¥ê¥¹¥È¥³¥ó¥Æ¥­¥¹¥È)
@_ = split(/¡§/, $text);
if (join('', map {"($_)"} @_) eq "(£É£Ï¡¥£Ó£Ù£Ó)(£²£²£µ£µ£µ£¸)(£¹£µ¡Ý£±£°¡Ý£°£³)(¡Ý£á¡Ý£ó£è)(£ï£ð£ô£é£ï£î£á£ì)") {
    print qq{ok - 1 \@_ = split(/¡§/, \$text); $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 \@_ = split(/¡§/, \$text); $^X $__FILE__\n};
}

# 7.7 split±é»»»Ò(¥¹¥«¥é¥³¥ó¥Æ¥­¥¹¥È)
my $a = split(/¡§/, $text);
if (join('', map {"($_)"} @_) eq "(£É£Ï¡¥£Ó£Ù£Ó)(£²£²£µ£µ£µ£¸)(£¹£µ¡Ý£±£°¡Ý£°£³)(¡Ý£á¡Ý£ó£è)(£ï£ð£ô£é£ï£î£á£ì)") {
    print qq{ok - 2 \$a = split(/¡§/, \$text); $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 \$a = split(/¡§/, \$text); $^X $__FILE__\n};
}

# 7.7 split±é»»»Ò(void¥³¥ó¥Æ¥­¥¹¥È)
split(/¡§/, $text);
if (join('', map {"($_)"} @_) eq "(£É£Ï¡¥£Ó£Ù£Ó)(£²£²£µ£µ£µ£¸)(£¹£µ¡Ý£±£°¡Ý£°£³)(¡Ý£á¡Ý£ó£è)(£ï£ð£ô£é£ï£î£á£ì)") {
    print qq{ok - 3 (void) split(/¡§/, \$text); $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 (void) split(/¡§/, \$text); $^X $__FILE__\n};
}

__END__
