# $Id: fail.t 498 2014-04-02 19:19:15Z whynot $
# Copyright 2009, 2010, 2014 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package main;
use version 0.77; our $VERSION = version->declare( v0.1.4 );

use t::TestSuite qw| :temp :mthd :diag |;
use File::AptFetch;
use Test::More;

File::AptFetch::ConfigData->set_config( timeout => 10 );
File::AptFetch::ConfigData->set_config( tick    =>  1 );

my( $dira, $dirb, $fsrc );
my( $faf, $rv, $serr, $msg );

my $Apt_Lib = t::TestSuite::FAFTS_discover_lib;
plan
  !defined $Apt_Lib ? ( skip_all => q|not *nix, or misconfigured| ) :
  !$Apt_Lib           ?     ( skip_all => q|not Debian, or alike| ) :
  !-x qq|$Apt_Lib/copy| ? ( skip_all => q|missing method [file:]| ) :
                                                    ( tests => 30 );

$dira = FAFTS_tempdir nick => q|dtag7c0d|;
$dirb = FAFTS_tempdir nick => q|dtag07d6|;
( $faf, $serr ) = FAFTS_wrap { File::AptFetch->init( q|file| ) };
is $serr, '', q|tag+3821 {STDERR} is empty|;

$fsrc = FAFTS_tempfile
  nick => q|ftag3319|, dir => $dira, content => q|file fail alpha|;
$fsrc = substr $fsrc, 1;
$fsrc =~ s{^[^/]*/}{}                                          until -f $fsrc;
is_deeply [ FAFTS_wrap { $faf->request( $fsrc, $fsrc ) } ], [ '', '', '' ],
  q|tag+856d|;
( $rv, $serr ) = FAFTS_wait_and_gain $faf;
FAFTS_show_message %{$faf->{message}};
is_deeply
{ rc => $rv, stderr => $serr, status => $faf->{Status}, log => $faf->{log},
  filename => $faf->{message}{filename},       uri => $faf->{message}{uri},
  size => $faf->{message}{size},      md5hash => $faf->{message}{md5_hash} },
{ rc => '', stderr => '', status => 400, log => [ ],
  filename => undef,          uri => qq|file:$fsrc|,
  size => undef,                   md5hash => undef                        },
                                                q|fails with unabsolute uri|;
ok $faf->{message}{message}, q|{$message{Message}} is set|;

$fsrc = FAFTS_tempfile
  nick => q|ftag7cbe|, dir => $dira, content => q|file fail bravo|;
$fsrc =~ s{/([^/]+)/([^/]+)$}{/$1/../$1/$2};
is_deeply [ FAFTS_wrap { $faf->request( $fsrc, $fsrc ) } ], [ '', '', '' ],
  q|tag+5562|;
( $rv, $serr ) = FAFTS_wait_and_gain $faf;
FAFTS_show_message %{$faf->{message}};
is_deeply
{ rc => $rv, stderr => $serr, status => $faf->{Status}, log => $faf->{log},
  filename => $faf->{message}{filename},       uri => $faf->{message}{uri},
  size => $faf->{message}{size},      md5hash => $faf->{message}{md5_hash} },
{ rc => '',      stderr => '',      status => 201,      log => [ ],
  filename => $fsrc,                         uri => qq|file:$fsrc|,
  size => -s $fsrc, md5hash => q|27810fd56896b89964cb05cf3b5ae26f|         },
                                            q|relative uri succeedes though|;

$fsrc = FAFTS_tempfile nick => q|ftag4697|, dir => $dira, unlink => !0;
is_deeply [ FAFTS_wrap { $faf->request( $fsrc, $fsrc ) } ], [ '', '', '' ],
  q|tag+5a5d|;
( $rv, $serr ) = FAFTS_wait_and_gain $faf;
FAFTS_show_message %{$faf->{message}};
is_deeply
{ rc => $rv, stderr => $serr, status => $faf->{Status}, log => $faf->{log},
  filename => $faf->{message}{filename},       uri => $faf->{message}{uri},
  size => $faf->{message}{size},      md5hash => $faf->{message}{md5_hash} },
{ rc => '', stderr => '', status => 400, log => [ ],
  filename => undef,          uri => qq|file:$fsrc|,
  size => undef,                   md5hash => undef                        },
                                               q|fails with unlocatable uri|;
ok $faf->{message}{message}, q|{$message{Message}} is set|;

$fsrc = FAFTS_tempfile
  nick => q|ftagaab5|, dir => $dira, content => q|file fail charlie|;
chmod 0000, $fsrc;
is_deeply [ FAFTS_wrap { $faf->request( $fsrc, $fsrc ) } ], [ '', '', '' ],
  q|tag+f5ea|;
( $rv, $serr ) = FAFTS_wait_and_gain $faf;
FAFTS_show_message %{$faf->{message}};
is_deeply
{ rc => $rv, stderr => $serr, status => $faf->{Status}, log => $faf->{log},
  filename => $faf->{message}{filename},       uri => $faf->{message}{uri},
  size => $faf->{message}{size},      md5hash => $faf->{message}{md5_hash} },
{ rc => '',  stderr => '',   status => 201,  log => [ ],
  filename => $fsrc,              uri => qq|file:$fsrc|,
  size => -s $fsrc, md5hash => $t::TestSuite::Empty_MD5                    },
                                            q|succeedes with unreadable uri|;

$fsrc = FAFTS_tempfile
  nick => q|ftag90c2|, dir => $dira, content => q|file fail delta|;
$fsrc = qq|/$fsrc|;
is_deeply [ FAFTS_wrap { $faf->request( $fsrc, $fsrc ) } ], [ '', '', '' ],
  q|tag+4202|;
( $rv, $serr ) = FAFTS_wait_and_gain $faf;
FAFTS_show_message %{$faf->{message}};
is_deeply
{ rc => $rv, stderr => $serr, status => $faf->{Status}, log => $faf->{log},
  filename => $faf->{message}{filename},       uri => $faf->{message}{uri},
  size => $faf->{message}{size},      md5hash => $faf->{message}{md5_hash} },
{ rc => '', stderr => '', status => 400, log => [ ],
  filename => undef,          uri => qq|file:$fsrc|,
  size => undef,                   md5hash => undef                        },
                                 q|then fails with leading-double-slash uri|;
like $faf->{message}{message}, qr{_ftagaab5_},
  q|{$message{message}} is about past|;
like $faf->{message}{uri}, qr{_ftag90c2_},
  q|{$message{uri}} is about present|;
unlike $faf->{message}{message}, qr{invalid uri}i,
  q|{$message{message}} isn't about double slash|;
$msg = $faf->{message}{message};

$fsrc = FAFTS_tempfile
  nick => q|ftaga6cb|, dir => $dira, content => q|file fail echo|;
$fsrc = qq|/$fsrc|;
is_deeply [ FAFTS_wrap { $faf->request( $fsrc, $fsrc ) } ], [ '', '', '' ],
  q|tag+c344|;
( $rv, $serr ) = FAFTS_wait_and_gain $faf;
FAFTS_show_message %{$faf->{message}};
is_deeply
{ rc => $rv, stderr => $serr, status => $faf->{Status}, log => $faf->{log},
  filename => $faf->{message}{filename},       uri => $faf->{message}{uri},
  size => $faf->{message}{size},      md5hash => $faf->{message}{md5_hash} },
{ rc => '', stderr => '', status => 400, log => [ ],
  filename => undef,          uri => qq|file:$fsrc|,
  size => undef,                   md5hash => undef                        },
                                            q|fails again with double-slash|;
ok $faf->{message}{message}, q|{$message{message}} is set|;
isnt $faf->{message}{message}, $msg,
  q|and {message{Message}} differs with previous|;

is_deeply [ FAFTS_wrap { $faf->request( $dirb, $dirb ) } ], [ '', '', '' ],
  q|tag+5bc5|;
( $rv, $serr ) = FAFTS_wait_and_gain $faf;
FAFTS_show_message %{$faf->{message}};
is_deeply
{ rc => $rv, stderr => $serr, status => $faf->{Status}, log => $faf->{log},
  filename => $faf->{message}{filename},       uri => $faf->{message}{uri},
  size => $faf->{message}{size},      md5hash => $faf->{message}{md5_hash} },
{ rc => '',  stderr => '',   status => 201,  log => [ ],
  filename => $dirb,              uri => qq|file:$dirb|,
# XXX: Hmmm,..
  size => -s $dirb, md5hash => $t::TestSuite::Empty_MD5                    },
                                                 q|succeedes with directory|;

$fsrc = FAFTS_tempdir nick => q|dtagff14|, dir => $dira;
$fsrc = qq|$fsrc/|;
is_deeply [ FAFTS_wrap { $faf->request( $fsrc, $fsrc ) } ], [ '', '', '' ],
  q|tag+8383|;
( $rv, $serr ) = FAFTS_wait_and_gain $faf;
FAFTS_show_message %{$faf->{message}};
is_deeply
{ rc => $rv, stderr => $serr, status => $faf->{Status}, log => $faf->{log},
  filename => $faf->{message}{filename},       uri => $faf->{message}{uri},
  size => $faf->{message}{size},      md5hash => $faf->{message}{md5_hash} },
{ rc => '',  stderr => '',   status => 201,  log => [ ],
  filename => $fsrc,              uri => qq|file:$fsrc|,
# XXX: Hmmm,..
  size => -s $fsrc, md5hash => $t::TestSuite::Empty_MD5                    },
                                            q|succeedes with trailing slash|;

$fsrc = FAFTS_tempdir nick => q|dtag73b1|, dir => $dira;
$fsrc = qq|/$fsrc/|;
is_deeply [ FAFTS_wrap { $faf->request( $fsrc, $fsrc ) } ], [ '', '', '' ],
  q|tag+f9cd|;
( $rv, $serr ) = FAFTS_wait_and_gain $faf;
FAFTS_show_message %{$faf->{message}};
is_deeply
{ rc => $rv, stderr => $serr, status => $faf->{Status}, log => $faf->{log},
  filename => $faf->{message}{filename},       uri => $faf->{message}{uri},
  size => $faf->{message}{size},      md5hash => $faf->{message}{md5_hash} },
{ rc => '', stderr => '', status => 400, log => [ ],
  filename => undef,          uri => qq|file:$fsrc|,
  size => undef,                   md5hash => undef                        },
                                q|fails with leading-double-slash directory|;
like $faf->{message}{message}, qr{read error}i,
  q|{$message{message}} has nothing to do with double-slash|;

$fsrc = FAFTS_tempdir nick => q|dtag1532|, dir => $dira;
$fsrc = qq|/$fsrc/|;
is_deeply [ FAFTS_wrap { $faf->request( $fsrc, $fsrc ) } ], [ '', '', '' ],
  q|tag+ad9d|;
( $rv, $serr ) = FAFTS_wait_and_gain $faf;
FAFTS_show_message %{$faf->{message}};
is_deeply
{ rc => $rv, stderr => $serr, status => $faf->{Status}, log => $faf->{log},
  filename => $faf->{message}{filename},       uri => $faf->{message}{uri},
  size => $faf->{message}{size},      md5hash => $faf->{message}{md5_hash} },
{ rc => '', stderr => '', status => 400, log => [ ],
  filename => undef,          uri => qq|file:$fsrc|,
  size => undef,                   md5hash => undef                        },
                          q|fails with leading-double-slash directory again|;
like $faf->{message}{message}, qr{invalid uri}i,
  q|{$message{message}} talks about uris now|;

# vim: syntax=perl
