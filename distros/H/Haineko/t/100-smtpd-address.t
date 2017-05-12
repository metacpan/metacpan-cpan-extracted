use lib qw|./lib ./blib/lib|;
use strict;
use warnings;
use Haineko::SMTPD::Address;
use Test::More;

my $modulename = 'Haineko::SMTPD::Address';
my $pkgmethods = [ 'new', 'canonify' ];
my $objmethods = [ 'damn' ];
my $testobject = new $modulename( 'address' => 'kijitora@example.jp' );

isa_ok $testobject, $modulename;
can_ok $modulename, @$pkgmethods;
can_ok $testobject, @$objmethods;

CLASS_METHODS: {
    my $v = undef;
    my $emailaddrs = [
        q{"neko" <neko@example.jp>},
        q{"=?ISO-2022-JP?B?dummy?=" <neko@example.jp>},
        q{"T E S T" <neko@example.jp>},
        q{"Nanashi no gombe" <neko@example.jp>},
        q{<neko@example.jp>},
        q{<neko@example.jp> neko@example.jp},
        q{User name <neko@example.jp>},
        q{User name <neko@example.jp> NEKO@EXAMPLE.JP},
        q{neko@host <neko@example.jp>},
        q{neko@host.int <neko@example.jp>},
        q{Neko <neko@example.jp> neko@host.int},
        q{neko@example.jp (The President)},
        q{Vice President. (U.S.A.) neko@example.jp},
        q{neko@example.jp},
        q{<neko@example.jp>:},
        q{"<neko@example.jp>"},
        q{"neko@example.jp"},
        q{'neko@example.jp'},
        q{`neko@example.jp`},
        q{(neko@example.jp)},
        q{[neko@example.jp]},
        q|{neko@example.jp}|,
        q{&lt;neko@example.jp&gt;},
        q{neko@example.jp},
    ];

    $v = $modulename->new( 'address' => undef ); is $v, undef;
    $v = $modulename->new( 'address' => 'cat' ); is $v, undef;

    $v = $modulename->canonify(undef); is $v, q();
    $v = $modulename->canonify(['1']); is $v, q();

    for my $e ( @$emailaddrs ) {

        my $c = $modulename->canonify( $e );
        my $o = $modulename->new( 'address' => $c );
        my $d = $o->damn;

        is $c, 'neko@example.jp', sprintf( "%s => %s", $e, $c );
        can_ok $o, @$objmethods;

        is $o->user, 'neko', '->user => neko';
        is $o->host, 'example.jp', '->host => example.jp';
        is $o->address, 'neko@example.jp', '->address => neko@example.jp';
        is ref $d, 'HASH', '->damn returns HASH';
        is $d->{'user'}, $o->user, '->{user} => '.$d->{'user'};
        is $d->{'host'}, $o->host, '->{host} => '.$d->{'host'};
        is $d->{'address'}, $o->address, '->{address} => '.$d->{'address'};
    }
}

done_testing;
__END__
