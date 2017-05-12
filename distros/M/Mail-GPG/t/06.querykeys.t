#!/usr/bin/perl
# PERLBOTIX<ätt>cpan.org,  May 2015

package Mail::GPG::Test;

use strict;
use utf8;
use Test::More;
use MIME::Parser;

SKIP: {
  if ( qx[gpg --version 2>&1 && echo GPGOK] !~ /GPGOK/ ) {
    plan skip_all => "No gpg found in PATH";
  }

  BEGIN { plan tests => 29;           }
  BEGIN { use_ok ("Mail::GPG::Test"); }


  # Hint: UTF8-file: ö = \x{c3b6}
  my @test_cases = (
                    {
                     name => "GPGv1 - extracting valid keys",
                     input => <<'TEST',
tru:t:1:1431088683:0:3:1:5
pub:-:1024:17:062F00DAE20F5035:2004-02-10:::-:Jörn Reder Mail\x3a\x3aGPG Test Key <mailgpg@localdomain>::scaESCA:
sub:-:1024:16:6C187D0F196ED9E3:2004-02-10::::::e:
TEST

                      expected => [
                                   ['E20F5035',         'Jörn Reder Mail::GPG Test Key <mailgpg@localdomain>'],
                                   ['062F00DAE20F5035', 'Jörn Reder Mail::GPG Test Key <mailgpg@localdomain>'],
                                  ],

                    },

                    {
                     name => "GPGv2 - extracting valid keys",
                     input => <<'TEST',
tru:t:1:1429473192:0:3:1:5
pub:-:1024:17:062F00DAE20F5035:1076425915:::-:::scaESCA:
uid:-::::1076425915::588869ADE077B8FB05788A99565AEED15AED8231::Jörn Reder Mail\x3a\x3aGPG Test Key <mailgpg@localdomain>:
sub:-:1024:16:6C187D0F196ED9E3:1076425917::::::e:
TEST

                     expected => [
                                  [ 'E20F5035',         'Jörn Reder Mail::GPG Test Key <mailgpg@localdomain>',
                                    '196ED9E3',         'Jörn Reder Mail::GPG Test Key <mailgpg@localdomain>'],
                                  [ '062F00DAE20F5035', 'Jörn Reder Mail::GPG Test Key <mailgpg@localdomain>',
                                    '6C187D0F196ED9E3', 'Jörn Reder Mail::GPG Test Key <mailgpg@localdomain>'],
                                 ],
                    },

                    {
                     name => "Expired keys only.",
                     input => <<'TEST',
pub:e:1024:1:E3A5C360307E3D54:1142955357:1399122021::-:SuSE Package Signing Key <build@suse.de>:
sig:::1:E3A5C360307E3D54:1272978021:::::[selfsig]::13x:
TEST

                     expected => [
                                  [],
                                  []
                                 ],
                    },

                    {
                     name => "Some expired subkeys and some expired user IDs.",
                     input => <<'TEST',
pub:-:1024:17:999F00DAE20F5123:1076425915:::-:::scaESCA:
uid:e::::1076425311::123456ADE077B8FB05788A97565AEED15AED4320::Expired Test Key <old@localdomain>:
uid:e::::1077425311::123456ADE077B8FB05788A97565AEED15AED4321::Expired Test Key <old@localdomain>:
uid:e::::1078425311::123456ADE077B8FB05788A97565AEED15AED4322::Expired Test Key <old@localdomain>:
uid:e::::1079425311::123456ADE077B8FB05788A97565AEED15AED4323::Expired Test Key <old@localdomain>:
uid:-::::1900425311::123456ADE077B8FB05788A97565AEED15AED4324::Valid Test Key   <new@localdomain>:
sub:e:1024:16:CAFE111F196ED111:1076425917::::::e:
sub:e:1024:16:CAFE222F196ED222:1076425917::::::e:
sub:-:1024:16:CAFE333F196ED333:1076425917::::::e:
TEST

                     expected => [
                                  [ 'E20F5123',         'Valid Test Key   <new@localdomain>',
                                    '196ED333',         'Valid Test Key   <new@localdomain>' ],
                                  [ '999F00DAE20F5123', 'Valid Test Key   <new@localdomain>',
                                    'CAFE333F196ED333', 'Valid Test Key   <new@localdomain>' ]
                                 ],
                    },

                    {
                     name => "Some expired subkeys and some expired user IDs, but more than one user ID. ",
                     input => <<'TEST',
pub:-:1024:17:999F00DAE20F5123:1076425915:::-:::scaESCA:
uid:d::::1076425311::123456ADE077B8FB05788A97565AEED15AED4320::Expired Test Key <user1@localdomain>:
uid:i::::1077425311::123456ADE077B8FB05788A97565AEED15AED4321::Expired Test Key <user2@localdomain>:
uid:r::::1078425311::123456ADE077B8FB05788A97565AEED15AED4322::Expired Test Key <user3@localdomain>:
uid:-::::1900000001::123456ADE077B8FB05788A97565AEED15AED4323::Valid Test Key   <userX@localdomain>:
uid:-::::1900500000::123456ADE077B8FB05788A97565AEED15AED4324::Valid Test Key   <new@localdomain>:
sub:e:1024:16:CAFE111F196ED111:1076425917::::::e:
sub:e:1024:16:CAFE222F196ED222:1076425917::::::e:
sub:-:1024:16:CAFE333F196ED333:1076425917::::::e:
TEST

                     expected => [
                                  [
                                   'E20F5123',         'Valid Test Key   <userX@localdomain>',
                                   'E20F5123',         'Valid Test Key   <new@localdomain>',
                                   '196ED333',         'Valid Test Key   <userX@localdomain>',
                                   '196ED333',         'Valid Test Key   <new@localdomain>'
                                  ],
                                  [ '999F00DAE20F5123', 'Valid Test Key   <userX@localdomain>',
                                    '999F00DAE20F5123', 'Valid Test Key   <new@localdomain>',
                                    'CAFE333F196ED333', 'Valid Test Key   <userX@localdomain>',
                                    'CAFE333F196ED333', 'Valid Test Key   <new@localdomain>'
                                  ]
                                 ],
                    }
                   );


  foreach my $use_long_key_ids ( 0, 1 ) {
    my $tc_variant = "[" . ( $use_long_key_ids ? "long ":"short" ) . " keys] ";

    my $test = Mail::GPG::Test->new( use_long_key_ids => $use_long_key_ids );
    ok($test->init, "$tc_variant Mail::GPG::Test->init");

    my $mg = $test->get_mail_gpg;
    ok($mg, "$tc_variant Mail::GPG->new");

    my (@res) = $mg->_parse_key_list( "\n" );
    is (@res, 0, "$tc_variant Empty input.");

    @res = $mg->_parse_key_list( "some junk" );
    is (@res, 0, "$tc_variant Some junk.");

    for my $tc (@test_cases) {
      @res = $mg->_parse_key_list( $tc->{input},
                                   verbose => $ENV{TEST_DEBUG},
                                   debug   => $ENV{TEST_DEBUG},
                                 );
      is_deeply( \@res, $tc->{expected}->[$use_long_key_ids], $tc_variant . ' [legacy ] ' . $tc->{name})
        or diag explain \@res;


      @res = $mg->_parse_key_list( $tc->{input},
                                   verbose => $ENV{TEST_DEBUG},
                                   debug   => $ENV{TEST_DEBUG},
                                   coerce  => 1,
                                 );

      is_deeply( \@res, _coerce( @{ $tc->{expected}->[$use_long_key_ids] }) , $tc_variant . ' [coerced] ' . $tc->{name} )
        or diag explain \@res;
    }

  }
}



#-- helper sub _coerce() that coerces the lagacy result into a compact result.
#
#-- legacy result:
#( '999F00DAE20F5123', 'Valid Test Key   <userX@localdomain>',
#  '999F00DAE20F5123', 'Valid Test Key   <new@localdomain>',
#  'CAFE333F196ED333', 'Valid Test Key   <userX@localdomain>',
#  'CAFE333F196ED333', 'Valid Test Key   <new@localdomain>'
#(
#  is coerced into:
#( '999F00DAE20F5123', [ 'Valid Test Key   <userX@localdomain>', 'Valid Test Key   <new@localdomain>'  ],
#  'CAFE333F196ED333', [ 'Valid Test Key   <userX@localdomain>', 'Valid Test Key   <new@localdomain>'  ]
#)


sub _coerce {
  my ( @legacy_result ) = @_;
  my @coerced;
  my $last_id  = "?";
  my $pairwise = sub{ return ( shift @legacy_result, shift @legacy_result ) };

  while ( @legacy_result ) {
    my ( $id, $email ) = $pairwise->();

    if ( $id  ne  $last_id ) {
      push @coerced, $id, [ $email ];
      $last_id = $id;
    } else {
      push @{ $coerced[-1] }, $email;
    }
  }

  return \@coerced;
}
