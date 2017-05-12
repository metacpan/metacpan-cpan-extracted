#!/usr/bin/perl -w

#-------------------------------------------------------------------------
#
# Copyright:  (c) Andrew Wilson 2001
#
#-------------------------------------------------------------------------

=head1 NAME

tagged.t - Test Mail::Address::Tagged

=head1 SYNOPSIS

  perl t/tagged.t

=head1 DESCRIPTION

Tests Mail::Address::Tagged

=head1 BUGS

Nothing Known

=head1 TODO

Nothing Known

=cut

#-------------------------------------------------------------------------
# Set up our standard testing environment
#-------------------------------------------------------------------------

use strict;
use Test::More tests => 103;

BEGIN {
  $| = 1;
  $^W = 1;
  for ( qw(
           Mail::Address::Tagged
          ) ) {
    use_ok( $_ );
  }
}

my $tmda = Mail::Address::Tagged->new(key => 'PlibbleWibble',
                                      user => 'neo',
                                      host => 'the.matrix.com',);

isa_ok($tmda, 'Mail::Address::Tagged');

#-----------------------------------------------------------------------------
# Test valid_for and set_valid_for
#-----------------------------------------------------------------------------

is($tmda->valid_for,
   432000,
   'Valid_for defaults to correct figure');

is($tmda->set_valid_for('3Y'),
   94608000,
   "set_valid_for with years works");

is($tmda->valid_for,
   94608000,
   'Valid_for returns correct figure');

is($tmda->set_valid_for('2M'),
   5184000,
   "set_valid_for with monthss works");

is($tmda->valid_for,
   5184000,
   'Valid_for returns correct figure');

is($tmda->set_valid_for('7w'),
   4233600,
   "set_valid_for with weeks works");

is($tmda->valid_for,
   4233600,
   'Valid_for returns correct figure');

is($tmda->set_valid_for('10d'),
   864000,
   "set_valid_for with days works");

is($tmda->valid_for,
   864000,
   'Valid_for returns correct figure');

is($tmda->set_valid_for('4h'),
   14400,
   "set_valid_for with hours works");

is($tmda->valid_for,
   14400,
   'Valid_for returns correct figure');

is($tmda->set_valid_for('27m'),
   1620,
   "set_valid_for with minutes works");

is($tmda->valid_for,
   1620,
   'Valid_for returns correct figure');

is($tmda->set_valid_for('123456s'),
   123456,
   "set_valid_for with seconds works");

is($tmda->valid_for,
   123456,
   'Valid_for returns correct figure');

is($tmda->set_valid_for(),
   432000,
   "set_valid_for with no argument restores default");

is($tmda->valid_for,
   432000,
   'Valid_for returns correct figure');


#-----------------------------------------------------------------------------
# Test host, user, email and key
#-----------------------------------------------------------------------------

is($tmda->user,
   'neo',
   "User is stored and returned correctly.");

is($tmda->host,
   'the.matrix.com',
   'Host is stored correctly.');

is($tmda->email,
   'neo@the.matrix.com',
   'email address is correct.');

is($tmda->key,
   'PlibbleWibble',
   'Key is correct',);

$tmda = Mail::Address::Tagged->new(key   => 'ItsLifeJimButNotAsWeKnowIt',
                                   email => 'foo@bar.com',);

is($tmda->user,
   'foo',
   "User is stored and returned correctly.");

is($tmda->host,
   'bar.com',
   'Host is stored correctly.');

is($tmda->email,
   'foo@bar.com',
   'email address is correct.');

is($tmda->key,
   'ItsLifeJimButNotAsWeKnowIt',
   'Key is correct',);

#-----------------------------------------------------------------------------
# Test keyword and set_keyword
#-----------------------------------------------------------------------------

$tmda = Mail::Address::Tagged->new(key     => '01234567890123456789',
                                   email   => 'foo@bar.com',
                                   keyword => 'wibble',);

is($tmda->keyword,
   'wibble',
   "Keyword is returned correctly");

$tmda = Mail::Address::Tagged->new(key     => '01234567890123456789',
                                   email   => 'foo@bar.com',
                                   keyword => 'monger',);

is($tmda->keyword,
   'monger',
   "Keyword is returned correctly");

$tmda = Mail::Address::Tagged->new(key     => '01234567890123456789',
                                   email   => 'foo@bar.com',);

is($tmda->keyword,
   '',
   'when the keyword is omitted from the constructor, it returns the empty string');

is($tmda->set_keyword(),
   '',
   'set with no value returns the current value');

is($tmda->keyword,
   '',
   'check value not chagned');

is($tmda->set_keyword('perl-monger'),
   'perl-monger',
   'set retuns new value');

is($tmda->keyword,
   'perl-monger',
   'check value not has chagned');

is($tmda->set_keyword(),
   'perl-monger',
   'set with no value returns the current value');

is($tmda->keyword,
   'perl-monger',
   'check value not chagned');

is($tmda->set_keyword(''),
   '',
   'set with no emptystring returns the empty string');

is($tmda->keyword,
   '',
   'check value is now the empty string');

#-----------------------------------------------------------------------------
# Test wrap
#-----------------------------------------------------------------------------

is($tmda->wrap(''),
   $tmda->email,
   'wrap returns same as email function when called with empty string');

is($tmda->wrap('-wibble'),
   'foo-wibble@bar.com',
   'wrap works when provided with a string');

#-----------------------------------------------------------------------------
# Test make confirm
#-----------------------------------------------------------------------------

my $address = $tmda->make_confirm({time => 1234567890,
                                   pid  => 9876,
                                   keyword => 'accept',});

is(substr($address, 0, 3),
   $tmda->user,
   "Confirm email address has correct user");

is(substr($address, 3, 15),
   '-confirm-accept',
   "Email address is a confirmation address of the correct type");

is(substr($address, 18, 12),
   '.1234567890.',
   "Confirm email address contains time in correct location");

is(substr($address, 30, 4),
   '9876',
   "Confirm email address contains pid in correct location");

my $HMAC = substr($address, 34, 7);
ok($HMAC =~ /.[0-9a-f]{6}/,
   "Confirm email address contains HMAC in correct location");

is(substr($address, 41),
   '@bar.com',
   "Confirm email address is for correct domain");

$address = $tmda->make_confirm({time => 1234567890,
                                pid  => 9876,
                                keyword => 'done',
                               });

# note with different keyword HMAC apears at a different location
my $new_HMAC = substr($address, 32, 7);
ok($new_HMAC =~ /.[0-9a-f]{6}/,
   "Confirm email address contains HMAC in correct location");

isnt($HMAC,
     $new_HMAC,
     "Altering keyword changeds HMAC");

$address = $tmda->make_confirm({time => 2345678901,
                                pid  => 9876,
                                keyword => 'accept',
                               });

$new_HMAC = substr($address, 34, 7);
ok($new_HMAC =~ /.[0-9a-f]{6}/,
   "Confirm email address contains HMAC in correct location");

isnt($HMAC,
     $new_HMAC,
     "Altering time changeds HMAC");

$address = $tmda->make_confirm({time => 1234567890,
                                pid  => 4567,
                                keyword => 'accept',
                               });

$new_HMAC = substr($address, 34, 7);
ok($new_HMAC =~ /.[0-9a-f]{6}/,
   "Confirm email address contains HMAC in correct location");

isnt($HMAC,
     $new_HMAC,
     "Altering pid changeds HMAC");

$address = $tmda->make_confirm({time => 1234567890,
                                pid  => 9876,
                                keyword => 'accept',
                               });

$new_HMAC = substr($address, 34, 7);
ok($new_HMAC =~ /.[0-9a-f]{6}/,
   "Confirm email address contains HMAC in correct location");

is($HMAC,
   $new_HMAC,
   "returning all value to original returns original HMAC");

#-----------------------------------------------------------------------------
# Test dated
#-----------------------------------------------------------------------------

$tmda = Mail::Address::Tagged->new(key   => 'aa12354c34df35bbb',
                                   user => 'neo',
                                   host => 'the.matrix.com',);
$tmda->set_valid_for('0s');

$address = $tmda->make_dated(442890);

is(substr($address, 0, 3),
   $tmda->user,
   "Dated email address has correct user");

is(substr($address, 3, 7),
   '-dated-',
   "Email address is a dated address");

is(substr($address, 10, 7),
   '442890.',
   "Dated email address contains time in correct location");

$HMAC = substr($address, 16, 7);
ok($HMAC =~ /.[0-9a-f]{6}/,
   "Dated email address contains HMAC in correct location");

is(substr($address, 23),
   '@the.matrix.com',
   "Dated email address is for correct domain");

# return to default valid for
$tmda->set_valid_for();
$address = $tmda->make_dated(442890);

is(substr($address, 10, 7),
   '874890.',
   "Dated email address contains time in correct location (default valid_for)");

$new_HMAC = substr($address, 16, 7);
ok($new_HMAC =~ /.[0-9a-f]{6}/,
   "Confirm email address contains HMAC in correct location (default valid_for)");

isnt($HMAC,
     $new_HMAC,
     "default valid_for changes HMAC");

my $time = time;
$address = $tmda->make_dated();

my $res = $1 if ($address =~ /^neo-dated-(\d+)/);
ok($res >= $time,
   "Dated email address contains time in correct location (no time supplied)");

$new_HMAC = substr($address, 10 + length $res, 7);
ok($new_HMAC =~ /.[0-9a-f]{6}/,
   "Confirm email address contains HMAC in correct location (no time supplied)");

isnt($HMAC,
     $new_HMAC,
     "calling without time changes HMAC");

#-----------------------------------------------------------------------------
# Test sender
#-----------------------------------------------------------------------------
my $key = 'c34df35bbb1234567890';
$tmda = Mail::Address::Tagged->new(key   => $key,
                                   email => 'mandolin@neo-classical.org',);

$address = $tmda->make_sender('Willy.Wonka@the.chocolate-factory.com');

is(substr($address, 0, 8),
   $tmda->user,
   "Sender email address has correct user");

is(substr($address, 8, 8),
   '-sender-',
   "Email address is a dated address");

$HMAC = substr($address, 16, 7);
ok($HMAC =~ /[0-9a-f]{6}/,
   "Sender email address contains HMAC in correct location");

is(substr($address, 22),
   '@neo-classical.org',
   "Sender email address is for correct domain");

$address = $tmda->make_sender('willy.wonka@the.chocolate-factory.com');
$new_HMAC = substr($address, 16, 7);
ok($new_HMAC =~ /[0-9a-f]{6}/,
   "Confirm email address contains HMAC in correct location (default valid_for)");

is($HMAC,
   $new_HMAC,
   "HMAC doesn't change depending on case of sender address");

$address = $tmda->make_sender('billy.wonka@the.chocolate-factory.com');
$new_HMAC = substr($address, 16, 7);
ok($new_HMAC =~ /[0-9a-f]{6}/,
   "Confirm email address contains HMAC in correct location (default valid_for)");

  isnt($HMAC,
     $new_HMAC,
     "HMAC changes with a subtly different sender address");

#-----------------------------------------------------------------------------
# Test for_received confirm
#-----------------------------------------------------------------------------

{

  my $key = 'c34df35bbb1234567890';
  $tmda = Mail::Address::Tagged->new(key  => $key,
                                     user => 'mandolin',
                                     host => 'neo-classical.org',);

  $tmda->set_valid_for('120s');
  my $intime  = time();
  my $inpid   = 32768;
  my $address = $tmda->make_confirm({time => $intime,
                                     pid  => $inpid,
                                     keyword => 'accept',});

  my $tmda = Mail::Address::Tagged->for_received(key     => $key,
                                                 address => $address,
                                                 sender  => 'foo@bar.com');

  isa_ok($tmda, 'Mail::Address::Tagged');

  is($tmda->candidate_time,
     $intime,
     "Time is correct (from reconstructed confirm)");

  is($tmda->candidate_pid,
     $inpid,
     "pid is correct (from reconstructed confirm)");

  is($tmda->keyword,
     'accept',
     'keyword is correct (from reconstructed confirm)');

  is($tmda->type,
     'confirm',
     "type is correct (from reconstructed confirm)");

  is($tmda->sender,
     'foo@bar.com',
     'sender is correct (from reconstructed confirm)');

  ok($tmda->valid, "HMAC checks out");

  my ($one, $two) = split "@", $address;
  my $last = chop $one;
  if ($last eq '0') {
    $last = 1;
  } else {
    $last = 0;
  }

  $address = $one.$last."@".$two;

  $tmda = Mail::Address::Tagged->for_received(key     => $key,
                                              address => $address,
                                              sender  => 'foo@bar.com');

  isa_ok($tmda, 'Mail::Address::Tagged');
  ok(!$tmda->valid, "Altered HMAC no longer checks out");

#-----------------------------------------------------------------------------
# Test for_received dated
#-----------------------------------------------------------------------------

  $tmda = Mail::Address::Tagged->new(key  => $key,
                                     user => 'mandolin',
                                     host => 'neo-classical.org',);

  $tmda->set_valid_for('120s');
  $address = $tmda->make_dated($intime - 120);

  $tmda = Mail::Address::Tagged->for_received(key     => $key,
                                              address => $address,
                                              sender  => 'foo@bar.com');

  isa_ok($tmda, 'Mail::Address::Tagged');

  is($tmda->candidate_time,
     $intime,
     "Time is correct (from reconstructed confirm)");

  is($tmda->type,
     'dated',
     "type is correct (from reconstructed confirm)");

  is($tmda->sender,
     'foo@bar.com',
     'sender is correct (from reconstructed confirm)');

  ok($tmda->valid, "HMAC checks out");
  ok(!$tmda->expired, "address has not expired");

  ($one, $two) = split "@", $address;
  $last = chop $one;
  if ($last eq '0') {
    $last = 1;
  } else {
    $last = 0;
  }

  $address = $one.$last."@".$two;

  $tmda = Mail::Address::Tagged->for_received(key     => $key,
                                              address => $address,
                                              sender  => 'foo@bar.com');

  isa_ok($tmda, 'Mail::Address::Tagged');
  ok(!$tmda->valid, "Altered HMAC no longer checks out");

  # Set the expiry date to 1 second ago
  $address = $tmda->make_dated($intime - 121);

  $tmda = Mail::Address::Tagged->for_received(key     => $key,
                                              address => $address,
                                              sender  => 'foo@bar.com');

  isa_ok($tmda, 'Mail::Address::Tagged');
  ok($tmda->valid, "HMAC checks out (address is valid)");
  ok($tmda->expired, "address has expired (valid but expired)");


#-----------------------------------------------------------------------------
# Test for_received sender
#-----------------------------------------------------------------------------

  $tmda = Mail::Address::Tagged->new(key  => $key,
                                     user => 'mandolin',
                                     host => 'neo-classical.org',);

  $address = $tmda->make_sender('foo@bar.com');

  $tmda = Mail::Address::Tagged->for_received(key     => $key,
                                              address => $address,
                                              sender  => 'foo@bar.com');

  isa_ok($tmda, 'Mail::Address::Tagged');

  is($tmda->type,
     'sender',
     "type is correct (from reconstructed confirm)");

  is($tmda->sender,
     'foo@bar.com',
     'sender is correct (from reconstructed confirm)');

  ok($tmda->valid, "HMAC checks out");

  ($one, $two) = split "@", $address;
  $last = chop $one;
  if ($last eq '0') {
    $last = 1;
  } else {
    $last = 0;
  }

  $address = $one.$last."@".$two;

  $tmda = Mail::Address::Tagged->for_received(key     => $key,
                                              address => $address,
                                              sender  => 'foo@bar.com');

  isa_ok($tmda, 'Mail::Address::Tagged');
  ok(!$tmda->valid, "Altered HMAC no longer checks out");

  # Now with different address
  $tmda = Mail::Address::Tagged->for_received(key     => $key,
                                              address => $address,
                                              sender  => 'moo@bar.com');

  isa_ok($tmda, 'Mail::Address::Tagged');

  is($tmda->type,
     'sender',
     "type is correct (from reconstructed confirm)");

  is($tmda->sender,
     'moo@bar.com',
     'sender is correct (from reconstructed confirm)');

  ok(!$tmda->valid, "HMAC doesn't match");

}
