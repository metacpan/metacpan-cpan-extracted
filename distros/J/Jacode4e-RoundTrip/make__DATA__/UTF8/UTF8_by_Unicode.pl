######################################################################
#
# UTF8_by_Unicode.pl
#
# Copyright (c) 2018 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# UTF-8, a transformation format of ISO 10646
# https://www.rfc-editor.org/rfc/rfc3629.txt

use strict;

sub UTF8_by_Unicode {
    my($Unicode) = @_;

    return join('', map { _UTF8_by_Unicode($_) } split(/\+/, $Unicode));
}

sub _UTF8_by_Unicode {
    my($Unicode) = @_;

    if ($Unicode =~ /^[0123456789ABCDEF]{2}$/) {
        return $Unicode;
    }
    elsif ($Unicode =~ /^[0123456789ABCDEF]{4}$/) {
    }
    elsif ($Unicode =~ /^[0123456789ABCDEF]{5}$/) {
        $Unicode = '0' . $Unicode;
    }
    elsif ($Unicode =~ /^(?:0[123456789ABCDEF]|10)[0123456789ABCDEF]{4}$/) {
    }
    else {
        die "Unicode=($Unicode)";
    }

    #   Char. number range  |        UTF-8 octet sequence
    #      (hexadecimal)    |              (binary)
    #   --------------------+---------------------------------------------
    #   0000 0000-0000 007F | 0xxxxxxx
    #   0000 0080-0000 07FF | 110xxxxx 10xxxxxx
    #   0000 0800-0000 FFFF | 1110xxxx 10xxxxxx 10xxxxxx
    #   0001 0000-0010 FFFF | 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx

    my @b = map { split(//,hex2bin($_)) } split(//,$Unicode);
    my $utf8 = '';
    if (0) {
    }
    elsif ((length($Unicode) == 4) and ('0000' le $Unicode) and ($Unicode le '007F')) {

        # 000000000  011 1111
        # 012345678  901 2345
        # *********  VVV VVVV
        #           0xxx xxxx

        $utf8 = join('', map { bin2hex($_) }
            join('', '0',@b[ 9,10,11]), join('', @b[12,13,14,15]),
        );
    }
    elsif ((length($Unicode) == 4) and ('0080' le $Unicode) and ($Unicode le '07FF')) {

        # 00000    0 0000   11 1111
        # 01234    5 6789   01 2345
        # *****    V VVVV   VV VVVV
        #       110x xxxx 10xx xxxx

        $utf8 = join('', map { bin2hex($_) }
            join('', '110',$b[    5]), join('', @b[ 6, 7, 8, 9]),
            join('', '10', @b[10,11]), join('', @b[12,13,14,15]),
        );
    }
    elsif ((length($Unicode) == 4) and ('0800' le $Unicode) and ($Unicode le 'FFFF')) {

        #      0000   00 0000   11 1111
        #      0123   45 6789   01 2345
        #      VVVV   VV VVVV   VV VVVV
        # 1110 xxxx 10xx xxxx 10xx xxxx

        $utf8 = join('', map { bin2hex($_) }
            join('', '1110'),         join('', @b[ 0, 1, 2, 3]),
            join('', '10',@b[ 4, 5]), join('', @b[ 6, 7, 8, 9]),
            join('', '10',@b[10,11]), join('', @b[12,13,14,15]),
        );
    }
    elsif ((length($Unicode) == 6) and ('010000' le $Unicode) and ($Unicode le '10FFFF')) {

        #  000       000   00 0011   11 1111   11 2222
        #  012       345   67 8901   23 4567   89 0123
        #  ***       VVV   VV VVVV   VV VVVV   VV VVVV
        #      1111 0xxx 10xx xxxx 10xx xxxx 10xx xxxx

        $utf8 = join('', map { bin2hex($_) }
            join('', '1111'),         join('', '0',@b[    3, 4, 5]),
            join('', '10',@b[ 6, 7]), join('',     @b[ 8, 9,10,11]),
            join('', '10',@b[12,13]), join('',     @b[14,15,16,17]),
            join('', '10',@b[18,19]), join('',     @b[20,21,22,23]),
        );
    }
    else {
        die;
    }

    if ($utf8 !~ /^([0123456789ABCDEF]{2}){1,4}$/) {
        die "UTF=($utf8)";
    }
    return $utf8;
}

sub hex2bin {
    if (defined(my $bin = {qw(
        0 0000
        1 0001
        2 0010
        3 0011
        4 0100
        5 0101
        6 0110
        7 0111
        8 1000
        9 1001
        A 1010
        B 1011
        C 1100
        D 1101
        E 1110
        F 1111
    )}->{$_[0]})) {
        return $bin;
    }
    else {
        die;
    }
}

sub bin2hex {
    if (defined(my $hex = { qw(
        0000 0
        0001 1
        0010 2
        0011 3
        0100 4
        0101 5
        0110 6
        0111 7
        1000 8
        1001 9
        1010 A
        1011 B
        1100 C
        1101 D
        1110 E
        1111 F
    )}->{$_[0]})) {
        return $hex;
    }
    else {
        die;
    }
}

1;

__END__
