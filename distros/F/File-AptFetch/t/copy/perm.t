# $Id: perm.t 498 2014-04-02 19:19:15Z whynot $
# Copyright 2009, 2010, 2014 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package main;
use version 0.77; our $VERSION = version->declare( v0.1.5 );

use t::TestSuite qw| :temp :mthd :diag |;
use File::AptFetch;
use Test::More;

File::AptFetch::ConfigData->set_config( timeout => 10 );
File::AptFetch::ConfigData->set_config( tick    =>  1 );

my( $dira, $dirb, $fsrc, $ftrg );
my( $fafc, $faff, $rv, $serr, $msga, $msgb );
my $Copy_Has_Md5hash = 1;
my $Apt_Lib = t::TestSuite::FAFTS_discover_lib;
plan
  !defined $Apt_Lib ? ( skip_all => q|not *nix, or misconfigured| ) :
  !$Apt_Lib           ?     ( skip_all => q|not Debian, or alike| ) :
  !-x qq|$Apt_Lib/copy| ? ( skip_all => q|missing method [copy:]| ) :
                                                    ( tests => 47 );

$dira = FAFTS_tempdir nick => q|dtag2c95|;
$dirb = FAFTS_tempdir nick => q|dtag85df|;
my $umask = umask 0072;
( $fafc, $serr ) = FAFTS_wrap { File::AptFetch->init( q|copy| ) };
umask $umask;
is $serr, '', q|tag+300f {STDERR} is empty|;
( $faff, $serr ) = FAFTS_wrap { File::AptFetch->init( q|file| ) };
is $serr, '', q|tag+47ff {STDERR} is empty|;

$fsrc = FAFTS_tempfile
  nick => q|mtagd376|, dir => $dira, content => q|copy perm alpha|;
chmod 0764, $fsrc;
$ftrg = FAFTS_tempfile nick => q|mtag17cb|, dir => $dira;
chmod 0777, $ftrg;
is_deeply [ FAFTS_wrap { $faff->request( $fsrc, $fsrc ) } ], [ '', '', '' ],
  q|tag+db1d|;
is_deeply [ FAFTS_wait_and_gain $faff ], [ '', '' ], q|tag+c82a|;
$msgb = $faff->{message};
FAFTS_show_message %$msgb;
is_deeply [ FAFTS_wrap { $fafc->request( $ftrg, $fsrc ) } ], [ '', '', '' ],
  q|tag+5a1c|;
( $rv, $serr ) = FAFTS_wait_and_gain $fafc;
$msga = $fafc->{message};
FAFTS_show_message %$msga;
is_deeply
{ rc => $rv,     stderr => $serr,    status => $fafc->{Status},
  uri => $fafc->{message}{uri}, size => $fafc->{message}{size} },
{ rc => '',  stderr => '',  status => 200,
  uri => qq|copy:$fsrc|, size => -s $fsrc                      },
  q|[request] succeedes to overwrite regular file|;
( $rv, $serr ) = FAFTS_wait_and_gain $fafc;
FAFTS_show_message %{$fafc->{message}};
is_deeply
{ rc => $rv,                                            stderr => $serr,
  status => $fafc->{Status},                        log => $fafc->{log},
  filename => $fafc->{message}{filename},  uri => $fafc->{message}{uri},
  size => $fafc->{message}{size}, md5hash => $fafc->{message}{md5_hash}    },
{ rc => '',                                                   stderr => '',
  status => 201,                                                log => [ ],
  filename => $ftrg,                                 uri => qq|copy:$fsrc|,
  size => $msgb->{size}, md5hash => $Copy_Has_Md5hash && $msgb->{md5_hash} },
                                                    q|[gain] succeedes then|;
is -s $ftrg, $msgb->{size}, q|have size|;
is_deeply [ FAFTS_wrap { $faff->request( $ftrg, $ftrg ) } ], [ '', '', '' ],
  q|tag+ad7b|;
is_deeply [ FAFTS_wait_and_gain $faff ], [ '', '' ], q|tag+f325|;
FAFTS_show_message %{$faff->{message}};
is $msgb->{last_modified}, $faff->{message}{last_modified},
  q|mtime is the same|;
is $msgb->{size}, $faff->{message}{size}, q|size is the same|;
is $msgb->{md5_hash}, $faff->{message}{md5_hash}, q|MD5 is the same|;
isnt +(stat $ftrg)[2], (stat $fsrc)[2], q|source's permissions aren't passed|;
TODO:                                                 {
    local $TODO = q|running old APT|;
    isnt +( stat $ftrg )[2] & 0777, 0604,
      q|target's permissions aren't affected by umask| }

$fsrc = FAFTS_tempfile
  nick => q|ftagf06e|, dir => $dira, content => q|copy perm bravo|;
chmod 0000, $fsrc;
$ftrg = FAFTS_tempfile nick => q|ftagb7b3|, dir => $dirb, unlink => !0;
is_deeply [ FAFTS_wrap { $fafc->request( $ftrg, $fsrc ) } ], [ '', '', '' ],
  q|tag+0cff|;
( $rv, $serr ) = FAFTS_wait_and_gain $fafc;
FAFTS_show_message %{$fafc->{message}};
is_deeply
{ rc => $rv,    stderr => $serr,     status => $fafc->{Status},
  size => $fafc->{message}{size}, uri => $fafc->{message}{uri} },
{ rc => '',  stderr => '',  status => 200,
  size => -s $fsrc, uri => qq|copy:$fsrc|                      },
  q|[request] succeedes to retrieve unreadable file|;
( $rv, $serr ) = FAFTS_wait_and_gain $fafc;
FAFTS_show_message %{$fafc->{message}};
is_deeply
{ rc => $rv,                     stderr => $serr,
  status => $fafc->{Status}, log => $fafc->{log},
                    uri => $fafc->{message}{uri} },
{ rc => '',    stderr => '',
  status => 400, log => [ ],
      uri => qq|copy:$fsrc|                      },
                              q|[gain] fails then|;
TODO:                           {
    local $TODO = q|running old APT|;
    unlike $fafc->{message}{message}, qr{\bpermission}i,
      q|message is enough|;
    ok !-f $ftrg, q|target is created|;
    isnt -s _, 0, q|and no size| }

$fsrc = FAFTS_tempfile
  nick => q|ftage5d5|, dir => $dira, content => q|copy perm charlie|;
$ftrg = FAFTS_tempfile nick => q|ftag1751|, dir => $dirb;
chmod 0000, $ftrg;
is_deeply [ FAFTS_wrap { $fafc->request( $ftrg, $fsrc ) } ], [ '', '', '' ],
  q|tag+799a|;
( $rv, $serr ) = FAFTS_wait_and_gain $fafc;
FAFTS_show_message %{$fafc->{message}};
is_deeply
{ rc => $rv,     stderr => $serr,    status => $fafc->{Status},
  uri => $fafc->{message}{uri}, size => $fafc->{message}{size} },
{ rc => '',  stderr => '',  status => 200,
  uri => qq|copy:$fsrc|, size => -s $fsrc                      },
             q|[request] succeedes to overwrite unwritable file|;
( $rv, $serr ) = FAFTS_wait_and_gain $fafc;
FAFTS_show_message %{$fafc->{message}};
is_deeply
{ rc => $rv,                     stderr => $serr,
  status => $fafc->{Status}, log => $fafc->{log},
                    uri => $fafc->{message}{uri} },
{ rc => '',    stderr => '',
  status => 201, log => [ ],
      uri => qq|copy:$fsrc|                      },
                          q|[gain] succeeds again|;
TODO:                                                                 {
    local $TODO = q|running old APT|;
    ok !!$fafc->{message}{message}, q|and I<$message{Message}> is unset|;
    isnt +(stat $ftrg)[2] & 0777, 0604, q|and permissions are overriden| }

$fsrc = FAFTS_tempfile
  nick => q|ftag7722|, dir => $dira, content => q|copy perm delta|;
$ftrg = FAFTS_tempfile nick => q|ftag911a|, dir => $dirb;
is_deeply [ FAFTS_wrap { $faff->request( $fsrc, $fsrc ) } ], [ '', '', '' ],
  q|tag+c344|;
( $rv, $serr ) = FAFTS_wait_and_gain $faff;
FAFTS_show_message %{$faff->{message}};
chmod 0333, $dira;
is_deeply [ FAFTS_wrap { $fafc->request( $ftrg, $fsrc ) } ], [ '', '', '' ],
  q|tag+f9bf|;
( $rv, $serr ) = FAFTS_wait_and_gain $fafc;
FAFTS_show_message %{$fafc->{message}};
is_deeply
{ rc => $rv,    stderr => $serr,     status => $fafc->{Status},
  uri => $fafc->{message}{uri}, size => $fafc->{message}{size} },
{ rc => '',  stderr => '',  status => 200,
  uri => qq|copy:$fsrc|, size => -s $fsrc                      },
         q|[request] succeedes with unreadable source directory|;
( $rv, $serr ) = FAFTS_wait_and_gain $fafc;
FAFTS_show_message %{$fafc->{message}};
chmod 0755, $dira;
is_deeply
{ rc => $rv,                                           stderr => $serr,
  status => $fafc->{Status},                       log => $fafc->{log},
  filename => $fafc->{message}{filename}, uri => $fafc->{message}{uri},
                                        size => $fafc->{message}{size},
                                 md5hash => $fafc->{message}{md5_hash} },
{ rc => '',                                     stderr => '',
  status => 201,                                  log => [ ],
  filename => $ftrg,                   uri => qq|copy:$fsrc|,
                              size => $faff->{message}{size},
  md5hash => $Copy_Has_Md5hash && $faff->{message}{md5_hash}           },
                                                q|[gain] succeedes then|;

$fsrc = FAFTS_tempfile
  nick => q|ftagd960|, dir => $dira, content => q|copy perm echo|;
$ftrg = FAFTS_tempfile nick => q|ftagb7fd|, dir => $dirb, unlink => !0;
chmod 0555, $dirb;
is_deeply [ FAFTS_wrap { $fafc->request( $ftrg, $fsrc ) } ], [ '', '', '' ],
  q|tag+a60|;
( $rv, $serr ) = FAFTS_wait_and_gain $fafc;
FAFTS_show_message %{$fafc->{message}};
is_deeply
{ rc => $rv,    stderr => $serr,     status => $fafc->{Status},
  uri => $fafc->{message}{uri}, size => $fafc->{message}{size} },
{ rc => '',  stderr => '',  status => 200,
  uri => qq|copy:$fsrc|, size => -s $fsrc                      },
         q|[request] succeedes with unwritable target directory|;
( $rv, $serr ) = FAFTS_wait_and_gain $fafc;
FAFTS_show_message %{$fafc->{message}};
chmod 0755, $dirb;
is_deeply
{ rc => $rv,                     stderr => $serr,
  status => $fafc->{Status}, log => $fafc->{log},
                    uri => $fafc->{message}{uri} },
{ rc => '',    stderr => '',
  status => 400, log => [ ],
      uri => qq|copy:$fsrc|                      },
                              q|[gain] fails then|;

$fsrc = FAFTS_tempfile
  nick => q|ftag683c|, dir => $dira, content => q|copy perm foxtrot|;
$ftrg = FAFTS_tempfile nick => q|ftag41bd|, dir => $dirb;
is_deeply [ FAFTS_wrap { $faff->request( $fsrc, $fsrc ) } ], [ '', '', '' ],
  q|tag+1caf|;
is_deeply [ FAFTS_wait_and_gain $faff ], [ '', '' ], q|tag+5e15|;
FAFTS_show_message %{$faff->{message}};
chmod 0555, $dirb;
is_deeply [ FAFTS_wrap { $fafc->request( $ftrg, $fsrc ) } ], [ '', '', '' ],
  q|tag+7ec0|;
( $rv, $serr ) = FAFTS_wait_and_gain $fafc;
FAFTS_show_message %{$fafc->{message}};
is_deeply
{ rc => $rv,     stderr => $serr,    status => $fafc->{Status},
  uri => $fafc->{message}{uri}, size => $fafc->{message}{size}           },
{ rc => '',  stderr => '',  status => 200,
  uri => qq|copy:$fsrc|, size => -s $fsrc                                },
  q|[request] succeedes with unwritable target directory but file present|;
( $rv, $serr ) = FAFTS_wait_and_gain $fafc;
FAFTS_show_message %{$fafc->{message}};
chmod 0755, $dirb;
is_deeply
{ rc => $rv,                     stderr => $serr,
  status => $fafc->{Status}, log => $fafc->{log},
                    uri => $fafc->{message}{uri} },
{ rc => '',    stderr => '',
  status => 400, log => [ ],
      uri => qq|copy:$fsrc|                      },
  q|[gain] fails then|;
TODO:                     {
    local $TODO = q|running old APT|;
    unlike $fafc->{message}{message}, qr{\bpermission}i,
      q|message is enough| }

$fsrc = FAFTS_tempfile
  nick => q|ftagd347|, dir => $dira, content => q|copy perm gala|;
$ftrg = FAFTS_tempfile nick => q|ftag8b17|, dir => $dirb;
chmod 0666, $dira;
is_deeply [ FAFTS_wrap { $fafc->request( $ftrg, $fsrc ) } ], [ '', '', '' ],
  q|tag+cae0|;
( $rv, $serr ) = FAFTS_wait_and_gain $fafc;
FAFTS_show_message %{$fafc->{message}};
is_deeply
{ rc => $rv,                     stderr => $serr,
  status => $fafc->{Status}, log => $fafc->{log},
                    uri => $fafc->{message}{uri}    },
{ rc => '',    stderr => '',
  status => 400, log => [ ],
      uri => qq|copy:$fsrc|                         },
  q|[request] fails with unseekable source directory|;
chmod 0755, $dira;

$fsrc = FAFTS_tempfile
  nick => q|ftag1824|, dir => $dira, content => q|copy perm hotel|;
$ftrg = FAFTS_tempfile nick => q|ftag62bc|, dir => $dirb, unlink => !0;
chmod 0666, $dirb;
is_deeply [ FAFTS_wrap { $fafc->request( $ftrg, $fsrc ) } ], [ '', '', '' ],
  q|tag+e6fa|;
( $rv, $serr ) = FAFTS_wait_and_gain $fafc;
FAFTS_show_message %{$fafc->{message}};
is_deeply
{ rc => $rv,    stderr => $serr,     status => $fafc->{Status},
  uri => $fafc->{message}{uri}, size => $fafc->{message}{size} },
{ rc => '',  stderr => '',  status => 200,
  uri => qq|copy:$fsrc|, size => -s $fsrc                      },
         q|[request] succeedes with unseekable target directory|;
( $rv, $serr ) = FAFTS_wait_and_gain $fafc;
FAFTS_show_message %{$fafc->{message}};
chmod 0755, $dirb;
is_deeply
{ rc => $rv,                     stderr => $serr,
  status => $fafc->{Status}, log => $fafc->{log},
                    uri => $fafc->{message}{uri} },
{ rc => '',    stderr => '',
  status => 400, log => [ ],
      uri => qq|copy:$fsrc|                      },
                              q|[gain] fails then|;

$fsrc = FAFTS_tempfile
  nick => q|ftagee89|, dir => $dira, content => q|copy perm india|;
$ftrg = FAFTS_tempfile nick => q|ftag0350|, dir => $dirb;
chmod 0666, $dirb;
is_deeply [ FAFTS_wrap { $fafc->request( $ftrg, $fsrc ) } ], [ '', '', '' ],
  q|tag+8cef|;
( $rv, $serr ) = FAFTS_wait_and_gain $fafc;
FAFTS_show_message %{$fafc->{message}};
is_deeply
{ rc => $rv,     stderr => $serr,    status => $fafc->{Status},
  uri => $fafc->{message}{uri}, size => $fafc->{message}{size}           },
{ rc => '',  stderr => '',  status => 200,
  uri => qq|copy:$fsrc|, size => -s $fsrc                                },
  q|[request] succeedes with unseekable target directory but file present|;
( $rv, $serr ) = FAFTS_wait_and_gain $fafc;
FAFTS_show_message %{$fafc->{message}};
chmod 0755, $dirb;
is_deeply
{ rc => $rv,                     stderr => $serr,
  status => $fafc->{Status}, log => $fafc->{log},
                    uri => $fafc->{message}{uri} },
{ rc => '',    stderr => '',
  status => 400, log => [ ],
      uri => qq|copy:$fsrc|                      },
                              q|[gain] fails then|;

# vim: syntax=perl
