#!/usr/bin/perl -w
#
# $Id: get_public_keys.t,v 1.9 2001/05/03 06:00:06 ftobin Exp $
#

use strict;
use English qw( -no_match_vars );

use lib './t';
use MyTest;
use MyTestSpecific;

use GnuPG::PrimaryKey;
use GnuPG::SubKey;

my ( $given_key, $handmade_key );

TEST
{
    reset_handles();

    my @returned_keys = $gnupg->get_public_keys_with_sigs( '0xF950DA9C' );

    return 0 unless @returned_keys == 1;

    $given_key = shift @returned_keys;

    my $pubkey_data = [
     Math::BigInt->from_hex('0x'.
      '88FCAAA5BCDCD52084D46143F44ED1715A339794641158DE03AA2092AFD3174E3DCA2CB7DF2DDC6FEDF7C3620F5A8BDAD06713E6153F8748DD76CB97305F30CBA8F8801DB47FAC11EED725F55672CB9BDAD629178A677CBB089B3E8AE0D9A9AD7741697A35F2868C62D25670994A92D810480173DC24263EEA0F103A43C0B64B'),
     Math::BigInt->from_hex('0x'.
      '8F2A3842C70FF17660CBB78C78FC93F534AB9A17'),
     Math::BigInt->from_hex('0x'.
      '83E348C2AA65F56DE84E8FDCE6DA7B0991B1C75EC8CA446FA85869A43350907BFF36BE512385E8E7E095578BB2138C04E318495873218286DE2B8C86F36EA670135434967AC798EBA28581F709F0C6B696EB512D3E561E381A06E4B5239BCC655015F9A926C74E4B859B26EAD604F208A556511A76A40EDCD9C38E6BD82CCCB4'),
     Math::BigInt->from_hex('0x'.
      '80DE04C85E30C9D62C13F90CFF927A84A5A59D0900B3533D4D6193FEF8C5DAEF9FF8A7D5F76B244FBC17644F50D524E0B19CD3A4B5FC2D78DAECA3FE58FA1C1A64E6C7B96C4EE618173543163A72EF954DFD593E84342699096E9CA76578AC1DE3D893BCCD0BF470CEF625FAF816A0F503EF75C18C6173E35C8675AF919E5704')
    ];

    $handmade_key = GnuPG::PrimaryKey->new
      ( length                 => 1024,
        algo_num               => 17,
        hex_id                 => '53AE596EF950DA9C',
        creation_date          => 949813093,
        creation_date_string   => '2000-02-06',
        owner_trust            => '-',
        usage_flags            => 'scaESCA',
        pubkey_data            => $pubkey_data,
      );

    $handmade_key->fingerprint
      ( GnuPG::Fingerprint->new( as_hex_string =>
                                 '93AFC4B1B0288A104996B44253AE596EF950DA9C',
                               )
      );


    my $uid0 = GnuPG::UserId->new( as_string =>  'GnuPG test key (for testing purposes only)',
                                   validity => '-');
    $uid0->push_signatures(
      GnuPG::Signature->new(
                            date => 1177086597,
                            algo_num => 17,
                            is_exportable => 1,
                            user_id_string => 'GnuPG test key (for testing purposes only)',
                            date_string => '2007-04-20',
                            hex_id => '53AE596EF950DA9C',
                            sig_class => 0x13,
                            validity => '!'),
      GnuPG::Signature->new(
                            date => 953180097,
                            algo_num => 17,
                            is_exportable => 1,
                            user_id_string => 'Frank J. Tobin <ftobin@neverending.org>',
                            date_string => '2000-03-16',
                            hex_id => '56FFD10A260C4FA3',
                            sig_class => 0x10,
                            validity => '!'),
      GnuPG::Signature->new(
                            date => 949813093,
                            algo_num => 17,
                            is_exportable => 1,
                            user_id_string => 'GnuPG test key (for testing purposes only)',
                            date_string => '2000-02-06',
                            hex_id => '53AE596EF950DA9C',
                            sig_class => 0x13,
                            validity => '!'));

    my $uid1 = GnuPG::UserId->new( as_string =>  'Foo Bar (1)',
                                   validity => '-');
    $uid1->push_signatures(
      GnuPG::Signature->new(
                            date => 1177086330,
                            algo_num => 17,
                            is_exportable => 1,
                            user_id_string => 'GnuPG test key (for testing purposes only)',
                            date_string => '2007-04-20',
                            hex_id => '53AE596EF950DA9C',
                            sig_class => 0x13,
                            validity => '!'),
      GnuPG::Signature->new(
                            date => 953180103,
                            algo_num => 17,
                            is_exportable => 1,
                            user_id_string => 'Frank J. Tobin <ftobin@neverending.org>',
                            date_string => '2000-03-16',
                            hex_id => '56FFD10A260C4FA3',
                            sig_class => 0x10,
                            validity => '!'),
      GnuPG::Signature->new(
                            date => 953179891,
                            algo_num => 17,
                            is_exportable => 1,
                            user_id_string => 'GnuPG test key (for testing purposes only)',
                            date_string => '2000-03-16',
                            hex_id => '53AE596EF950DA9C',
                            sig_class => 0x13,
                            validity => '!'));



    $handmade_key->push_user_ids($uid0, $uid1);

    my $subkey_signature = GnuPG::Signature->new
      ( validity       => '!',
        algo_num       => 17,
        hex_id         => '53AE596EF950DA9C',
        date           => 1177086380,
        date_string    => '2007-04-20',
        user_id_string => 'GnuPG test key (for testing purposes only)',
        sig_class      => 0x18,
        is_exportable  => 1,
      );

    my $uid2_signature = GnuPG::Signature->new
      ( validity       => '!',
        algo_num       => 17,
        hex_id         => '53AE596EF950DA9C',
        date           => 953179891,
        date_string    => '2000-03-16',
      );

    my $ftobin_signature = GnuPG::Signature->new
      ( validity       => '!',
        algo_num       => 17,
        hex_id         => '56FFD10A260C4FA3',
        date           => 953180097,
        date_string    => '2000-03-16',
        );

    my $designated_revoker_sig = GnuPG::Signature->new
      ( validity       => '!',
        algo_num       => 17,
        hex_id         => '53AE596EF950DA9C',
        date           => 978325209,
        date_string    => '2001-01-01',
        sig_class      => 0x1f,
        is_exportable  => 1
        );

    my $revoker = GnuPG::Revoker->new
      ( algo_num       => 17,
        class          => 0x80,
        fingerprint    => GnuPG::Fingerprint->new( as_hex_string =>
                                                   '4F863BBBA8166F0A340F600356FFD10A260C4FA3'),
        );
    $revoker->push_signatures($designated_revoker_sig);

    my $subkey_pub_data = [
     Math::BigInt->from_hex('0x'.
      '8831982DADC4C5D05CBB01D9EAF612131DDC9C24CEA7246557679423FB0BA42F74D10D8E7F5564F6A4FB8837F8DC4A46571C19B122E6DF4B443D15197A6A22688863D0685FADB6E402316DAA9B560D1F915475364580A67E6DF0A727778A5CF3'),
     Math::BigInt->from_hex('0x'.
      '6'),
     Math::BigInt->from_hex('0x'.
      '2F3850FF130C6AC9AA0962720E86539626FAA9B67B33A74DFC0DE843FF3E90E43E2F379EE0182D914FA539CCCF5C83A20DB3A7C45E365B8A2A092E799A3DFF4AD8274EB977BAAF5B1AFB2ACB8D6F92454F01682F555565E73E56793C46EF7C3E')
    ];

    my $subkey = GnuPG::SubKey->new
      ( validity                 => 'u',
        length                   => 768,
        algo_num                 => 16,
        hex_id                   => 'ADB99D9C2E854A6B',
        creation_date            => 949813119,
        creation_date_string     => '2000-02-06',
        usage_flags              => 'e',
        pubkey_data              => $subkey_pub_data,
      );


    $subkey->fingerprint
      ( GnuPG::Fingerprint->new( as_hex_string =>
                                 '7466B7E98C4CCB64C2CE738BADB99D9C2E854A6B'
                               )
      );

    $subkey->push_signatures( $subkey_signature );

    $handmade_key->push_subkeys( $subkey );
    $handmade_key->push_revokers( $revoker );

    $handmade_key->compare( $given_key );
};

TEST
{
    my $subkey1 = $given_key->subkeys()->[0];
    my $subkey2 = $handmade_key->subkeys()->[0];

    bless $subkey1, 'GnuPG::SubKey';

    my $equal = $subkey1->compare( $subkey2 );

    warn 'subkeys fail comparison; this is a known issue with GnuPG 1.0.1'
      if not $equal;

    return $equal;
};


TEST
{
    $handmade_key->compare( $given_key, 1 );
};
