use strict;
use warnings;

use Test::More;

if ( !eval { require XML::XPath; require XML::Simple; XML::Simple->VERSION( '2.18' ) } ) {
    plan skip_all =>
        'XML::XPath and XML::Simple (2.18) are required to use the database feature';
}
else {
    plan tests => 6;
}

use_ok( 'Games::NES::ROM::Database' );

my $db = Games::NES::ROM::Database->new;

isa_ok( $db, 'Games::NES::ROM::Database' );

my $expected = {
    cartridge => {
        sha1   => '71FDB80C3583010422652CC5AAE8E2E4131E49F3',
        dump   => 'bad',
        system => 'Famicom',
        crc    => '8E2BD25C',
        board  => {
            pad => {
                h => '1',
                v => '0'
            },
            prg    => { size => '32k' },
            chr    => { size => '8k' },
            mapper => '0'
        }
    }
};

{
    my $info = $db->find_by_crc( '8e2bd25c' );
    is_deeply( $info, $expected, 'by CRC' );
}

{
    my $info = $db->find_by_sha1( '71fdb80c3583010422652cc5aae8e2e4131e49f3' );
    is_deeply( $info, $expected, 'by SHA-1' );
}

{
    my $rom = MockROM->new;
    my $info = $db->find_by_rom( $rom );
    is_deeply( $info, $expected, 'by ROM object' );
}

{
    ok( !defined $db->find_by_crc( 'DNE' ), 'entry does not exist' );
}

package MockROM;

sub new {
    bless {}, shift;
}

sub crc {
    return '8e2bd25c';
}

1;
