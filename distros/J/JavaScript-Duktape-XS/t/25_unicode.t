use strict;
use warnings;

use Test::More;

my $CLASS = 'JavaScript::Duktape::XS';

sub main {
    use_ok($CLASS);

    my $ff = "\xff";
    my $e_acute_utf8 = "\xc3\xa9";

    for my $upgrade_yn ( 0, 1 ) {
        my $_ff = $ff;

        my $xform_fn = $upgrade_yn ? 'upgrade' : 'downgrade';
        utf8->can($xform_fn)->($_ff);

        my $_e_acute_utf8 = $e_acute_utf8;
        utf8->can($xform_fn)->($_e_acute_utf8);

        my $vm = $CLASS->new();

        $vm->set( mystr => $_e_acute_utf8 );
        $vm->set( myhash => { $_ff => $_ff } );

        my $got = $vm->eval( q<[mystr, mystr.charCodeAt(0), myhash, myhash["\u00ff"].charCodeAt(0)]> );

        is_deeply(
            $got,
            [ $e_acute_utf8, 0xc3, { $ff => $ff }, 0xff ],
            "round-trip as expected (utf8::$xform_fn)",
        ) or diag explain $got;
    }

    {
        my $a_line = "\x{100}";

        my $vm = $CLASS->new();

        $vm->set( mystr => $a_line );
        $vm->set( myhash => { $a_line => $a_line } );

        my $got = $vm->eval( q<[mystr, mystr.charCodeAt(0), myhash, myhash[mystr].charCodeAt(0)]> );

        is_deeply(
            $got,
            [ $a_line, 0x100, { $a_line => $a_line }, 0x100 ],
            "wide character round-trips as expected",
        ) or diag explain $got;
    }

    done_testing;
    return 0;
}

exit main();
