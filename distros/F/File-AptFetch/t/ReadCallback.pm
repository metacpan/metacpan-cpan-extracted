# $Id: ReadCallback.pm 499 2014-04-19 19:24:45Z whynot $
# Copyright 2014 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;
no warnings qw| once |;

package t::ReadCallback;
use version 0.77; our $VERSION = version->declare( v0.1.1 );

@main::units =
([{ tag => q|tag+9d89| },  sub { $main::fdat = { } },  [ undef, '', { }] ],
 [{ tag => q|tag+e15c|,                  eval => [qw| filename |]},
  sub                                                           {
      $main::file = t::TestSuite::FAFTS_tempfile(
        nick => q|ftag7351|, dir => $main::dsrc, unlink => !0 );
      $main::fdat = { filename => $main::file }                  },
  [ 1,                                                        '',
    { filename => q|$file|, tmp => undef, flag => 4, tick => 5 } ]       ],
 [{ tag => q|tag+3bb8|,                  eval => [qw| filename |]},
  sub                                  { $main::fdat->{flag} = 1 },
  [ 1,                                                        '',
    { filename => q|$file|, tmp => undef, flag => 0, tick => 5 } ]       ],
 [{ tag => q|tag+9929|,                   eval => [qw| filename |]},
  sub                                                           { },
  [ '',                                                        '',
    { filename => q|$file|, tmp => undef, flag => -1, tick => 5 } ]      ],
 [{ tag => q|tag+0eeb|,                 eval => [qw| filename tmp |]},
  sub                                                              {
      $main::file = t::TestSuite::FAFTS_tempfile(
        nick => q|ftag5dd0|, dir => $main::dsrc );
      $main::fdat = { filename => $main::file }                     },
  [ 1,                                                           '',
    { filename => q|$file|, tmp => q|$file|, size => 0, back => 0,
      flag => 4,              factor => 1,              tick => 5 } ]    ],
 [{ tag => q|tag+1eea|,                  eval => [qw| filename tmp|]},
  sub                                                             { },
  [ 1,                                                           '',
    { filename => q|$file|, tmp => q|$file|, size => 0, back => 0,
      flag => 3,              factor => 1,              tick => 5 } ]    ],
 [{ tag => q|tag+25c7|,                    eval => [qw| filename tmp |]},
  sub { t::TestSuite::FAFTS_append_file( $main::file, qq|tag+6e20\n| ) },
  [ 1,                                                           '',
    { filename => q|$file|, tmp => q|$file|, size => 9, back => 0,
      flag => 4,              factor => 1,              tick => 5 }    ] ],
 [{ tag => q|tag+7932|,                 eval => [qw| filename tmp |]},
  sub                                                             { },
  [ 1,                                                           '',
    { filename => q|$file|, tmp => q|$file|, size => 9, back => 9,
      flag => 3,              factor => 1,              tick => 5 } ]    ],
 [{ tag => q|tag+9d70|,                    eval => [qw| filename tmp |]},
  sub { t::TestSuite::FAFTS_append_file( $main::file, qq|tag+4f90\n| ) },
  [ 1,                                                            '',
    { filename => q|$file|, tmp => q|$file|, size => 18, back => 9,
      flag => 4,              factor => 1,               tick => 5 }   ] ],
 [{ tag => q|tag+a29e|,                  eval => [qw| filename tmp |]},
  sub  { t::TestSuite::FAFTS_set_file( $main::file, qq|tag+86ad\n| ) },
  [ 1,                                                            '',
    { filename => q|$file|, tmp => q|$file|, size => 9, back => 18,
      flag => 4,               factor => 1,              tick => 5 } ]   ],
 [{ tag => q|tag+4fbc|,                 eval => [qw| filename tmp |]},
  sub             { t::TestSuite::FAFTS_set_file( $main::file, '' ) },
  [ 1,                                                           '',
    { filename => q|$file|, tmp => q|$file|, size => 0, back => 9,
      flag => 4,              factor => 1,              tick => 5 } ]    ],
 [{ tag => q|tag+0f84|,                  eval => [qw| filename |]},
  sub                                       { unlink $main::file },
  [ 1,                                                        '',
    { filename => q|$file|, tmp => undef, size => 0, back => 9,
      flag => 3,             factor => 1,            tick => 5 } ]       ],
 [{ tag => q|tag+3038|,                         init => !0 },
  sub                                                     {
      $main::file = t::TestSuite::FAFTS_tempfile(
        nick => q|ftag0bc6|, dir => $main::dsrc, content => qq|tag+9b87\n| );
      $main::fdat = { filename => $main::file, tick => 5 } }             ],
 [{ tag => q|tag+7cba|,                  eval => [qw| filename |]},
  sub                                       { unlink $main::file },
  [ 1,                                                        '',
    { filename => q|$file|, tmp => undef, size => 9, back => 0,
      flag => 3,            factor => 1,             tick => 5 } ]       ],
 [{ tag => q|tag+3551|,                 eval => [qw| filename tmp |]},
  sub { t::TestSuite::FAFTS_set_file( $main::file, qq|tag+e6c3\n| ) },
  [ 1,                                                           '',
    { filename => q|$file|, tmp => q|$file|, size => 9, back => 9,
      flag => 2,              factor => 1,              tick => 5 } ]    ],
 [{ tag => q|tag+c909|,                 eval => [qw| filename tmp |]},
  sub                                                              {
      $main::file = t::TestSuite::FAFTS_tempfile(
        nick => q|ftag56c6|, dir => $main::dsrc, unlink => !0 );
      $main::faux = ( File::Temp::tempfile(
        sprintf( q|%s.XXXX|, ( split m{/}, $main::file)[-1]),
        DIR => $main::dsrc                                   ) )[-1];
      t::TestSuite::FAFTS_diag( qq|\$faux: $main::faux| );
      t::TestSuite::FAFTS_set_file( $main::faux, qq|tag+e94a\n| );
      $main::fdat = { filename => $main::file }                     },
  [ 1,                                                           '',
    { filename => q|$file|, tmp => q|$faux|, size => 9, back => 0,
      flag => 4,              factor => 1,              tick => 5 } ]    ],
 [{ tag => q|tag+9f0f|,                    eval => [qw| filename tmp |]},
  sub { t::TestSuite::FAFTS_append_file( $main::faux, qq|tag+9930\n| ) },
  [ 1,                                                            '',
    { filename => q|$file|, tmp => q|$faux|, size => 18, back => 9,
      flag => 4,              factor => 1,               tick => 5 }   ] ],
 [{ tag => q|tag+90be|,                   eval => [qw| filename |]},
  sub                                                            {
      unlink $main::faux;
      t::TestSuite::FAFTS_set_file(
        $main::file, qq|tag+8e1e\ntag+e7e4\ntag+b4ee\n| )         },
  [ 1,                                                         '',
    { filename => q|$file|, tmp => undef, size => 18, back => 9,
      flag => 3,             factor => 1,             tick => 5 } ]      ],
 [{ tag => q|tag+e7c0|,                   eval => [qw| filename tmp |]},
  sub                                                               { },
  [ 1,                                                             '',
    { filename => q|$file|, tmp => q|$file|, size => 27, back => 18,
      flag => 4,               factor => 1,               tick => 5 } ]  ] );

1

# vim: syntax=perl
