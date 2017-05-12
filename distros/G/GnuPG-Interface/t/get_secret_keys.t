#!/usr/bin/perl -w
#
# $Id: get_secret_keys.t,v 1.9 2001/05/03 06:00:06 ftobin Exp $
#

use strict;
use English qw( -no_match_vars );

use lib './t';
use MyTest;
use MyTestSpecific;

use GnuPG::PrimaryKey;

my ( $given_key, $handmade_key );

TEST
{
    reset_handles();

    my @returned_keys = $gnupg->get_secret_keys( '0xF950DA9C' );

    return 0 unless @returned_keys == 1;

    $given_key = shift @returned_keys;

    $handmade_key = GnuPG::PrimaryKey->new
      ( length                 => 1024,
        algo_num               => 17,
        hex_id                 => '53AE596EF950DA9C',
        creation_date          => 949813093,
        creation_date_string   => '2000-02-06',
        owner_trust            => '', # secret keys do not report ownertrust?
        usage_flags            => 'scaESCA',
      );

    $handmade_key->fingerprint
      ( GnuPG::Fingerprint->new( as_hex_string =>
                                 '93AFC4B1B0288A104996B44253AE596EF950DA9C',
                               )
      );

    $handmade_key->push_user_ids(
      GnuPG::UserId->new( as_string => 'GnuPG test key (for testing purposes only)',
                          validity => ''), # secret keys do not report uid validity?
      GnuPG::UserId->new( as_string => 'Foo Bar (1)',
                          validity => '')); # secret keys do not report uid validity?


    my $subkey = GnuPG::SubKey->new
      ( validity                 => 'u',
        length                   => 768,
        algo_num                 => 16,
        hex_id                   => 'ADB99D9C2E854A6B',
        creation_date            => 949813119,
        creation_date_string     => '2000-02-06',
        usage_flags              => 'e',
      );

    $subkey->fingerprint
      ( GnuPG::Fingerprint->new( as_hex_string =>
                                 '7466B7E98C4CCB64C2CE738BADB99D9C2E854A6B',
                               )
      );

    $handmade_key->push_subkeys( $subkey );

    $handmade_key->compare( $given_key );
};


TEST
{
    $handmade_key->compare( $given_key, 1 );
};
