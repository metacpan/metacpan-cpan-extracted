# $Id: copy.pl 505 2014-06-12 20:42:49Z whynot $
# Copyright 2014 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package main;
use version 0.77; our $VERSION = version->declare( v0.1.2 );

use t::TestSuite qw| :temp :mthd |;
use t::visual::TestSuite;
use File::AptFetch::Simple;

our %opts;
my( $dsrc, $dtrg, $fsrc );
my( $fafs, $rv, $serr );

my $TS_Conf = t::TestSuite::FAFTS_discover_config;

=pod

Does two long shots using (if provided) global and local options overrides;
then makes double-shot.
Options:

=over

=item I<--global beat=$bbool>

=item I<--local beat=$bbool>

Applies I<beat> option of B<< F::AF::S->request() >> I<%opts>.

=item I<--global wink=$wbool>

=item I<--local wink=$wbool>

Applies I<wink> option of B<< F::AF::S->request() >> I<%opts>.

=back

Required config section is I<%TSC{copy_slow}>.
Used keys are:

=over

=item I<$TSC{copy_slow}{block}>

Ignored -- invoking is manual, so block yourself.

=item I<$TSC{copy_slow}{source}>

Collection of copy source configuration items.

=item I<$TSC{copy_slow}{source}{dir}>

Dirname where source file must be placed.

=item I<$TSC{copy_slow}{source}{size}>

Size of source file to create.

=item I<$TSC{copy_slow}{target}>

Collection of copy target configuration items.

=item I<$TSC{copy_slow}{target}{dir}>

Dirname where target file must be located.
Should be on different devices.
USB-sticks are prefered, especially for writing.
Reading might be fine too.

=back

=cut

my( %gopts, %lopts );
$gopts{wink} = $opts{global}{wink}              if exists $opts{global}{wink};
$gopts{beat} = $opts{global}{beat}              if exists $opts{global}{beat};
$lopts{wink} = $opts{local}{wink}                if exists $opts{local}{wink};
$lopts{beat} = $opts{local}{beat}                if exists $opts{local}{beat};
$TS_Conf->{copy_slow}{source}{size} /= 8;

$dsrc = FAFTS_tempdir
  nick => q|dtag9b89|, dir => $TS_Conf->{copy_slow}{source}{dir};
$dtrg = FAFTS_tempdir
  nick => q|dtag714f|, dir => $TS_Conf->{copy_slow}{target}{dir};

$fsrc = FAFTS_tempfile nick => q|ftabf45a|,       dir => $dsrc,
  content => q|tag+12e3| x $TS_Conf->{copy_slow}{source}{size};
$fafs = File::AptFetch::Simple->request(
{ method => q|copy|, location => $dtrg, %gopts }, $fsrc );

$fsrc = FAFTS_tempfile nick => q|ftag98f0|,       dir => $dsrc,
  content => q|tag+254f| x $TS_Conf->{copy_slow}{source}{size};
$fafs = $fafs->request( { %lopts }, $fsrc );

$fsrc =
[ FAFTS_tempfile( nick => q|ftag9f94|,              dir => $dsrc,
    content => q|tag+d319| x $TS_Conf->{copy_slow}{source}{size} ),
  FAFTS_tempfile( nick => q|ftag19f4|,              dir => $dsrc,
    content => q|tag+182a| x $TS_Conf->{copy_slow}{source}{size} ) ];
$fafs->request( { %lopts }, @$fsrc );

# vim: syntax=perl
