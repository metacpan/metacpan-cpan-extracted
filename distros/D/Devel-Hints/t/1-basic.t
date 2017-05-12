use strict;
use Config;
use Test::More tests => 18;
use ok 'Devel::Hints', ':all';

LABEL:
is(cop_label(), 'LABEL', 'cop_label');

is(cop_file(), __FILE__, 'cop_file');

is(cop_filegv(), \$::{'_<' . __FILE__}, 'cop_filegv');

{
    package Foo;
    main::is(main::cop_stashpv(), __PACKAGE__, 'cop_stashpv');
}

{
    no strict 'refs';
    package Bar;
    main::is_deeply(main::cop_stash(), \%{__PACKAGE__ . '::'}, 'cop_stash');
}

ok(cop_seq(), 'cop_seq');

no warnings 'deprecated';
$[ = 10;
is(cop_arybase(), 10, 'cop_arybase');

is(cop_line(), __LINE__, 'cop_line');

SKIP: {
    skip('cop_warnings() not available', 3) unless defined cop_warnings();

    use warnings;
    is(cop_warnings(0), 16, 'cop_warnings');

    {
        no warnings 'once';
        my $x;
        BEGIN { $x = ${^WARNING_BITS} };
        is(cop_warnings(0), $x, 'cop_warnings - lexical');
        is(cop_warnings(1), 16, 'cop_warnings(1)');
    }
}


SKIP: {
    skip('cop_io() not available', 6) unless defined cop_io();

    no open;
    is(cop_io(0), "", 'cop_io - empty string when not set');

    {
use open IN => ':raw', OUT => ':raw';
is(cop_io(0), ":raw\0:raw", 'cop_io');

{
    use open IN => ':crlf', OUT => ':crlf';
    is(cop_io(1), ":raw\0:raw", 'cop_io(1) on block');
}

{ { {
use open IN => ':crlf', OUT => ':crlf';
is(show_io(), ":crlf\0:crlf", 'cop_io(1) on blocks');
} } }

{
use open IN => ':crlf', OUT => ':crlf';
is(show_io(), ":crlf\0:crlf", 'cop_io(1) on sub');
}

{
use open IN => ':crlf', OUT => ':crlf';
is(show_io_2(), ":crlf\0:crlf", 'cop_io(2) on block');
}
    }

}

1;

sub show_io { return cop_io(1) }
sub show_io_2 { { return cop_io(2) } }
