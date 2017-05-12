# $Id: fail.t 498 2014-04-02 19:19:15Z whynot $
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

my( $dira, $dirb, $fsra, $ftga );
my( $fafc, $faff, $rv, $serr, $msg );
my $Copy_Has_Md5hash = 1;

my $Apt_Lib = t::TestSuite::FAFTS_discover_lib;
plan
  !defined $Apt_Lib ? ( skip_all => q|not *nix, or misconfigured| ) :
  !$Apt_Lib           ?     ( skip_all => q|not Debian, or alike| ) :
  !-x qq|$Apt_Lib/copy| ? ( skip_all => q|missing method [copy:]| ) :
                                                    ( tests => 33 );

$dira = FAFTS_tempdir nick => q|dtag2c95|;
$dirb = FAFTS_tempdir nick => q|dtag85df|;
( $fafc, $serr ) = FAFTS_wrap { File::AptFetch->init( q|copy| ) };
is $serr, '', q|tag+1514 {STDERR} is empty|;
( $faff, $serr ) = FAFTS_wrap { File::AptFetch->init( q|file| ) };
is $serr, '', q|tag+5fe8 {STDERR} is empty|;

$fsra = FAFTS_tempfile
  nick => q|ftag7dd3|, dir => $dira, content => q|copy fail alpha|;
is_deeply [ FAFTS_wrap { $faff->request( $fsra, $fsra ) } ], [ '', '', '' ],
  q|tag+a184|;
is_deeply [ FAFTS_wait_and_gain $faff ], [ '', '' ], q|tag+4af0|;
$msg = $faff->{message};
FAFTS_show_message %$msg;
is_deeply [ FAFTS_wrap { $fafc->request( $fsra, $fsra ) } ], [ '', '', '' ],
  q|tag+b345|;
( $rv, $serr ) = FAFTS_wait_and_gain $fafc;
FAFTS_show_message %{$fafc->{message}};
is_deeply
{ rc => $rv,     stderr => $serr,    status => $fafc->{Status},
  uri => $fafc->{message}{uri}, size => $fafc->{message}{size} },
{ rc => '',    stderr => '',    status => 200,
  size => $msg->{size}, uri => qq|copy:$fsra|                  },
                      q|[request] succeedes with self overwrite|;
( $rv, $serr ) = FAFTS_wait_and_gain $fafc;
FAFTS_show_message %{$fafc->{message}};
is_deeply
{ rc => $rv,                                           stderr => $serr,
  status => $fafc->{Status},                       log => $fafc->{log},
  filename => $fafc->{message}{filename}, uri => $fafc->{message}{uri},
                                        size => $fafc->{message}{size} },
{ rc => '',                   stderr => '',
  status => 201,                log => [ ],
  filename => $fsra, uri => qq|copy:$fsra|,
                      size => $msg->{size}                             },
                                               q|[gain] succeedes again|;
ok -f $fsra, q|requested file is here|;
TODO:                                                                       {
    local $TODO = q|running old APT|;
    isnt -s $fsra, $msg->{size}, q|no way|;
    isnt $fafc->{message}{md5_hash}, $msg->{md5_hash}, q|[copy:] overwrites| }
is $fafc->{message}{last_modified}, $msg->{last_modified},
  q|and mtime is the same|;
is_deeply [ FAFTS_wrap { $faff->request( $fsra, $fsra ) } ], [ '', '', '' ],
  q|tag+fc10|;
( $rv, $serr ) = FAFTS_wait_and_gain $faff;
FAFTS_show_message %{$faff->{message}};
is $fafc->{message}{last_modified}, $faff->{message}{last_modified},
  q|and is actual one|;

$fsra = FAFTS_tempfile
  nick => q|ftag9dbc|, dir => $dira, content => q|copy fail bravo|;
$fsra = substr $fsra, 1;
$fsra =~ s{^[^/]*/}{}                                          until -f $fsra;
$ftga = FAFTS_tempfile nick => q|ftag9606|, dir => $dirb, unlink => !0;
is_deeply [ FAFTS_wrap { $faff->request( $fsra, $fsra ) } ], [ '', '', '' ],
  q|tag+4ee7|;
is_deeply [ FAFTS_wait_and_gain $faff ], [ '', '' ], q|tag+8e65|;
FAFTS_show_message %{$faff->{message}};
is_deeply [ FAFTS_wrap { $fafc->request( $ftga, $fsra ) } ], [ '', '', '' ],
  q|tag+1d77|;
( $rv, $serr ) = FAFTS_wait_and_gain $fafc;
FAFTS_show_message %{$fafc->{message}};
is_deeply
{ rc => $rv,                     stderr => $serr,
  status => $fafc->{Status}, log => $fafc->{log},
                    uri => $fafc->{message}{uri} },
{ rc => '',    stderr => '',
  status => 400, log => [ ],
      uri => qq|copy:$fsra|                      },
            q|[request] fails with unabsolute uri|;
isnt $fafc->{message}{message}, $faff->{message}{message},
  q|and the {$message{Message}} differs though|;

$fsra = FAFTS_tempfile
  nick => q|ftaga226|, dir => $dira, content => q|copy fail charlie|;
$ftga = FAFTS_tempfile nick => q|ftag63ce|, dir => $dirb;
$ftga = substr $ftga, 1;
$ftga =~ s{^[^/]*/}{}                                          until -f $ftga;
unlink $ftga;
is_deeply [ FAFTS_wrap { $faff->request( $fsra, $fsra ) } ], [ '', '', '' ],
  q|tag+7743|;
is_deeply [ FAFTS_wait_and_gain $faff ], [ '', '' ], q|tag+2b01|;
FAFTS_show_message %{$faff->{message}};
is_deeply [ FAFTS_wrap { $fafc->request( $ftga, $fsra ) } ], [ '', '', '' ],
  q|tag+adbc|;
( $rv, $serr ) = FAFTS_wait_and_gain $fafc;
FAFTS_show_message %{$fafc->{message}};
is_deeply
{ rc => $rv,    stderr => $serr,     status => $fafc->{Status},
  uri => $fafc->{message}{uri}, size => $fafc->{message}{size} },
{ rc => '',  stderr => '',  status => 200,
  uri => qq|copy:$fsra|, size => -s $fsra                      },
          q|[request] succeedes with unabsolute filename though|;
( $rv, $serr ) = FAFTS_wait_and_gain $fafc;
FAFTS_show_message %{$fafc->{message}};
is_deeply
{ rc => $rv,                                           stderr => $serr,
  status => $fafc->{Status},                       log => $fafc->{log},
  filename => $fafc->{message}{filename}, uri => $fafc->{message}{uri},
                                        size => $fafc->{message}{size},
                                 md5hash => $fafc->{message}{md5_hash} },
{ rc => '',                                     stderr => '',
  status => 201,                                  log => [ ],
  filename => $ftga,                   uri => qq|copy:$fsra|,
                              size => $faff->{message}{size},
  md5hash => $Copy_Has_Md5hash && $faff->{message}{md5_hash}           },
                                                 q|[gain] succeedes too|;

$fsra = FAFTS_tempfile
  nick => q|ftag168c|, dir => $dira, content => q|copy fail delta|;
$fsra = qq|/$fsra|;
$ftga = FAFTS_tempfile nick => q|ftag1357|, dir => $dirb, unlink => !0;
is_deeply [ FAFTS_wrap { $faff->request( $fsra, $fsra ) } ], [ '', '', '' ],
  q|tag+c09f|;
is_deeply [ FAFTS_wait_and_gain $faff ], [ '', '' ], q|tag+8827|;
FAFTS_show_message %{$faff->{message}};
is_deeply [ FAFTS_wrap { $fafc->request( $ftga, $fsra ) } ], [ '', '', '' ],
  q|tag+89b9|;
( $rv, $serr ) = FAFTS_wait_and_gain $fafc;
FAFTS_show_message %{$fafc->{message}};
is_deeply
{ rc => $rv,                     stderr => $serr,
  status => $fafc->{Status}, log => $fafc->{log},
                    uri => $fafc->{message}{uri} },
{ rc => '',    stderr => '',
  status => 400, log => [ ],
      uri => qq|copy:$fsra|                      },
           q|[request] fails for double slash uri|;
isnt $fafc->{message}{message}, $faff->{message}{message},
  q|and {$message{Message}} differs again|;

$fsra = FAFTS_tempfile
  nick => q|ftag1ecb|, dir => $dira, content => q|copy fail echo|;
$ftga = FAFTS_tempfile nick => q|ftag3a1c|, dir => $dirb, unlink => !0;
$ftga = qq|/$ftga|;
is_deeply [ FAFTS_wrap { $faff->request( $fsra, $fsra ) } ], [ '', '', '' ],
  q|tag+aeab|;
is_deeply [ FAFTS_wait_and_gain $faff ], [ '', '' ], q|tag+fa67|;
FAFTS_show_message %{$faff->{message}};
is_deeply [ FAFTS_wrap { $fafc->request( $ftga, $fsra ) } ], [ '', '', '' ],
  q|tag+d9c4|;
( $rv, $serr ) = FAFTS_wait_and_gain $fafc;
FAFTS_show_message %{$fafc->{message}};
is_deeply
{ rc => $rv,     stderr => $serr,    status => $fafc->{Status},
  uri => $fafc->{message}{uri}, size => $fafc->{message}{size}    },
{ rc => '',  stderr => '',  status => 200,
  uri => qq|copy:$fsra|, size => -s $fsra                         },
  q|[request] succeedes for leading double slashed filename though|;
( $rv, $serr ) = FAFTS_wait_and_gain $fafc;
FAFTS_show_message %{$fafc->{message}};
is_deeply
{ rc => $rv,                                           stderr => $serr,
  status => $fafc->{Status},                       log => $fafc->{log},
  filename => $fafc->{message}{filename}, uri => $fafc->{message}{uri},
                                        size => $fafc->{message}{size},
                                 md5hash => $fafc->{message}{md5_hash} },
{ rc => '',                                     stderr => '',
  status => 201,                                  log => [ ],
  filename => $ftga,                   uri => qq|copy:$fsra|,
                              size => $faff->{message}{size},
  md5hash => $Copy_Has_Md5hash && $faff->{message}{md5_hash}           },
                                                 q|[gain] succeedes too|;

# vim: syntax=perl
