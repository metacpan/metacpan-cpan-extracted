# $Id: set_callback.t 506 2014-07-04 18:07:33Z whynot $
# Copyright 2014 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package main;
use version 0.77; our $VERSION = version->declare( v0.1.6 );

use t::TestSuite qw| :temp :mthd :file :diag |;
use File::AptFetch;
use Test::More;

my( $arena, $stderr, $fsrc, $ftrg, $mthd );
my( $faf, $rv, $serr );

my $Apt_Lib = t::TestSuite::FAFTS_discover_lib;
plan                        !defined $Apt_Lib ?
( skip_all => q|not *nix, or misconfigured| ) : ( tests => 37 );

( $rv, $serr ) = FAFTS_wrap                           {
    File::AptFetch::set_callback q|tag+8af5| => sub { }};
like $rv, qr{unknown callback}, q|unknown callback|;

( $rv, $serr ) = FAFTS_wrap                         {
    File::AptFetch::set_callback read => q|tag+b68a| };
like $rv, qr{neither CODE nor .undef.}, q|not CODE|;

$arena = FAFTS_tempdir nick => q|dtag0551|;
$stderr = FAFTS_tempfile nick => q|stderr|;
File::AptFetch::ConfigData->set_config( lib_method => $arena );

unless( !$ENV{FAFTS_NO_LIB} && $Apt_Lib)                              {
    t::TestSuite::FAFTS_diag q|missing APT: workarounds enabled|;
    my $cfg = FAFTS_tempfile nick => q|config|, dir => $arena;
    FAFTS_prepare_method $cfg, q|y-method|, q|/dev/null|,
      qq|Dir "$arena";|,
      qq|Dir::Etc "$arena";|,
      qq|Dir::Bin::methods "$arena";|,
      qq|APT::Architecture "foobar";|;
    File::AptFetch::ConfigData->set_config( config_source => [ $cfg ]) }

( $rv, $serr ) = FAFTS_wrap                                    {
    File::AptFetch::set_callback read => sub { die q|tag+b679| }};
is $serr, '', q|tag+c1b9 {STDERR} is empty|;
File::AptFetch::ConfigData->set_config( timeout => 3 );
File::AptFetch::ConfigData->set_config( tick    => 1 );

$fsrc = FAFTS_tempfile nick => q|ftag1c44|, dir => $arena;
$ftrg = FAFTS_tempfile nick => q|ftag33c8|, dir => $arena;
$mthd = FAFTS_prepare_method
  FAFTS_tempfile( nick => q|mtagf0bc|, dir => $arena ),
  q|w-method|, $stderr;
( $faf, $serr ) = FAFTS_wrap { File::AptFetch->init( $mthd ) };
isa_ok $faf, q|File::AptFetch|, q|tag+3066 [init]|;
is $serr, '', q|tag+f757 {STDERR} is empty|;
( $rv, $serr ) = FAFTS_wrap { $faf->request( $ftrg, $fsrc ) };
is_deeply { rv => $rv, stderr => $serr }, { rv => '', stderr => '' },
  q|tag+d66f [request]|;
( $rv, $serr ) = FAFTS_wrap { $faf->gain };
like $rv, qr{tag.b679}, q|sets [read] callback|;
undef $faf;
is FAFTS_get_file $stderr, qq|{{{TERM}}}\n|, q|tag+e7ae {STDERR} is empty|;

( $rv, $serr ) = FAFTS_wrap                         {
    File::AptFetch::set_callback
      read => undef, gain => sub { die q|tag+7175| } };
is $serr, '', q|tag+d4ff {STDERR} is empty|;

$fsrc = FAFTS_tempfile nick => q|ftag4f13|, dir => $arena;
$ftrg = FAFTS_tempfile nick => q|ftag9b47|, dir => $arena;
$mthd = FAFTS_prepare_method
  FAFTS_tempfile( nick => q|mtagf010|,                    dir => $arena ),
  q|v-method|,                        $stderr,                        200,
  q|200 URI Start|,        qq|Uri: +++$fsrc|,        q|Size: 0|,       '',
  q|201 URI Done|, qq|Uri: +++$fsrc|, q|Size: 0|, qq|Filename: $ftrg|, '';
# http://www.cpantesters.org/cpan/report/c7c66d6e-dde6-11e3-9f96-e4d5e82f99b1
# XXX:201406091515:whynot: Theory: B<init()> B<fork>s method, what spits two of three messages, then stucks ({fd}(0) and {fd}(1)).  Then B<init()> gets 1st message (method's still stuck).
( $faf, $serr ) = FAFTS_wrap { File::AptFetch->init( $mthd ) };
isa_ok $faf, q|File::AptFetch|, q|tag+bb6f [init]|;
is $serr, '', q|tag+5043 {STDERR} is empty|;
# Now request never reaches method because it's stuck.
( $rv, $serr ) = FAFTS_wrap { $faf->request( $ftrg, $fsrc ) };
is_deeply { rv => $rv, stderr => $serr }, { rv => '', stderr => '' },
  q|tag+68a6 [request]|;
# Now B<gain()> gets 2nd message and B<die>s as prescribed by B<_gain_callback()>.
( $rv, $serr ) = FAFTS_wrap { $faf->gain };
like $rv, qr{tag.7175}, q|sets [gain] callback|;
# Then method is dead already and won't read request.
my( $diag, $log ) = ( $faf->{diag}, $faf->{log} );
undef $faf;
$serr = FAFTS_get_file $stderr;
# XXX:201407032140:whynot: Resolved, problem was with F<t/v-method> being totally lame.
like $serr, qr{600 URI Acquire}, q|tag+576b {STDERR} is empty|;

$fsrc = FAFTS_tempfile nick => q|ftag5551|, dir => $arena;
$ftrg = FAFTS_tempfile nick => q|ftage821|, dir => $arena;
$mthd = FAFTS_prepare_method
  FAFTS_tempfile( nick => q|mtage3bf|, dir => $arena ),
  q|v-method|,               $stderr,              200,
  q|200 URI Start|,    qq|Uri: +++$fsrc|,   q|Size: 0|;
( $faf, $serr ) = FAFTS_wrap { File::AptFetch->init( $mthd ) };
isa_ok $faf, q|File::AptFetch|, q|tag+107c [init]|;
is $serr, '', q|tag+1328 {STDERR} is empty|;
( $rv, $serr ) = FAFTS_wrap { $faf->request( $ftrg, $fsrc ) };
is_deeply { rv => $rv, stderr => $serr }, { rv => '', stderr => '' },
  q|tag+49bc [request]|;
( $rv, $serr ) = FAFTS_wrap { $faf->gain };
like $rv, qr{timeouted$}, q|clears [read] callback|;
undef $faf;
like FAFTS_get_file $stderr, qr{600 URI Acquire},
  q|tag+5875 {STDERR} is empty|;

( $rv, $serr ) = FAFTS_wrap { File::AptFetch::set_callback gain => undef };
is $serr, '', q|tag+5b06 {STDERR} is empty|;

$fsrc = FAFTS_tempfile nick => q|ftag2529|, dir => $arena;
$ftrg = FAFTS_tempfile nick => q|ftag432a|, dir => $arena;
$mthd = FAFTS_prepare_method
  FAFTS_tempfile( nick => q|mtag7f51|, dir => $arena ),
  q|v-method|,               $stderr,              200,
  q|200 URI Start|, qq|Uri: +++$fsrc|,  q|Size: 0|, '';
( $faf, $serr ) = FAFTS_wrap { File::AptFetch->init( $mthd ) };
isa_ok $faf, q|File::AptFetch|, q|tag+656d [init]|;
is $serr, '', q|tag+1a91 {STDERR} is empty|;
( $rv, $serr ) = FAFTS_wrap { $faf->request( $ftrg, $fsrc ) };
is_deeply { rv => $rv, stderr => $serr }, { rv => '', stderr => '' },
  q|tag+788d [request]|;
( $rv, $serr ) = FAFTS_wrap { $faf->gain };
is_deeply [ $rv, $serr ], [ '', '' ], q|[gain]|;
( $rv, $serr ) = FAFTS_wrap { $faf->gain };
like $rv, qr{timeouted$}, q|clears [gain] callback|;
undef $faf;
like FAFTS_get_file $stderr, qr{600 URI Acquire},
  q|tag+656e {STDERR} is empty|;

( $rv, $serr ) = FAFTS_wrap                                      {
    File::AptFetch::set_callback select => sub { die q|tag+90fa| }};
is $serr, '', q|tag+db54 {STDERR} is empty|;

$fsrc = FAFTS_tempfile nick => q|ftag21e0|, dir => $arena;
$ftrg = FAFTS_tempfile nick => q|ftageab6|, dir => $arena;
$mthd = FAFTS_prepare_method
  FAFTS_tempfile( nick => q|mtaga183|, dir => $arena ),
  q|v-method|,              $stderr,               200,
  q|200 URI Start|,    qq|Uri: +++$fsrc|,   q|Size: 0|;
( $faf, $serr ) = FAFTS_wrap { File::AptFetch->init( $mthd ) };
like $faf, qr{tag.90fa}, q|sets [select] callback|;
is $serr, '', q|tag+3e71 {STDERR} is empty|;
undef $faf;
is FAFTS_get_file $stderr, '', q|tag+38a2 {STDERR} is empty|;

( $rv, $serr ) = FAFTS_wrap { File::AptFetch::set_callback select => undef };
is $serr, '', q|tag+03f4 {STDERR} is empty|;

$fsrc = FAFTS_tempfile nick => q|ftag971b|, dir => $arena;
$ftrg = FAFTS_tempfile nick => q|ftag8929|, dir => $arena;
$mthd = FAFTS_prepare_method
  FAFTS_tempfile( nick => q|mtag484f|, dir => $arena ),
  q|v-method|,               $stderr,              200,
  q|200 URI Start|,   qq|Uri: +++$fsrc|,    q|Size: 0|;
( $faf, $serr ) = FAFTS_wrap { File::AptFetch->init( $mthd ) };
isa_ok $faf, q|File::AptFetch|, q|tag+023b [init]|;
is $serr, '', q|tag+ea68 {STDERR} is empty|;
( $rv, $serr ) = FAFTS_wrap { $faf->request( $ftrg, $fsrc ) };
is_deeply { rv => $rv, stderr => $serr }, { rv => '', stderr => '' },
  q|tag+6f22 [request]|;
( $rv, $serr ) = FAFTS_wrap { $faf->gain };
like $rv, qr{timeouted$}, q|clears [select] callback|;
is $serr, '', q|tag+2b73 {STDERR} is empty|;
undef $faf;
like FAFTS_get_file $stderr, qr{600 URI Acquire},
  q|tag+5917 {STDERR} is empty|;

# vim: syntax=perl
