# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Portal.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

BEGIN {
    our %tr_err = (
        fr => 'French',

        # Not yet maintained
        ro => 'Romanian',
    );
    our %tr_msg = ( fr => 'French', );
}

use Test::More tests => 8 + ( keys(%tr_err) * 2 ) + ( keys(%tr_msg) * 2 );

BEGIN { use_ok('Lemonldap::NG::Portal::Simple') }

ok( my @en = @{&Lemonldap::NG::Portal::_i18n::error_en},
    'English translation' );
ok( $#en > 21, 'Translation count' );

foreach ( keys %tr_err ) {
    my @tmp;
    ok( @tmp = @{ &{"Lemonldap::NG::Portal::_i18n::error_$_"} },
        "$tr_err{$_} translation" );
    ok( $#tmp == $#en, "$tr_err{$_} translation count (" . scalar(@tmp) . ')' );
}

my $p1 = bless {}, 'Lemonldap::NG::Portal::Simple';
$p1->{error} = 10;
$p1->{lang} = [ 'en', 'fr' ];
my $p2 = bless {}, 'Lemonldap::NG::Portal::Simple';
$p2->{error} = 5;
$p2->{lang}  = [];
my $p3 = bless {}, 'Lemonldap::NG::Portal::Simple';
$p3->{error} = 10;
$p3->{lang} = [ 'fr', 'es', 'en' ];

ok( $p1->error() eq $p2->error(10), 'HTTP_ACCEPT_LANGUAGE mechanism 1' );
ok( $p1->error() ne $p2->error(),   'HTTP_ACCEPT_LANGUAGE mechanism 2' );
ok( $p1->error() ne $p3->error(),   'HTTP_ACCEPT_LANGUAGE mechanism 3' );

ok( @en = @{&Lemonldap::NG::Portal::_i18n::msg_en},
    'English messages translation' );
ok( $#en > 19, 'Messages translation count' );

foreach ( keys %tr_msg ) {
    my @tmp;
    ok( @tmp = @{ &{"Lemonldap::NG::Portal::_i18n::msg_$_"} },
        "$tr_msg{$_} messages translation" );
    ok( $#tmp == $#en,
        "$tr_msg{$_} messages translation count (" . scalar(@tmp) . ')' );
}
