# $Id: ftp.pl 505 2014-06-12 20:42:49Z whynot $
# Copyright 2014 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package main;
use version 0.77; our $VERSION = version->declare( v0.1.1 );

use t::TestSuite qw| :temp :mthd |;
use t::visual::TestSuite;
use File::AptFetch::Simple;

our %opts;
my( $dsrc, $dtrg, $fsrc );
my( $fafs, $rv, $serr );

my $TS_Conf = t::TestSuite::FAFTS_discover_config;

=pod

Does two long shots using (if provided) global and local options overrides.
Options:

=over

=item I<--global beat=$bbool>

=item I<--local beat=$bbool>

Applies I<beat> option of B<< F::AF::S->request() >> I<%opts>.

=item I<--global wink=$wbool>

=item I<--local wink=$wbool>

Applies I<wink> option of B<< F::AF::S->request() >> I<%opts>.

=back

Required config section is I<%TSC{ftp_slow}>.
Used keys are:

=over

=item I<$TSC{ftp_slow}{block}>

Ignored -- invoking is manual, so block yourself.

=item I<$TSC{ftp_slow}{source}>

Hierachial part of request.
Supposed to be something big (couple handreds of megs should be fine).
No schema.

=item I<$TSC{ftp_slow}{target}>

Collection of ftp target configuration items.

=item I<$TSC{ftp_slow}{target}{dir}>

Dirname where target file must be located.
Good idea would be to put it on something slow
(just like with F<t/copy/slow.t>).

=back

=cut

my( %gopts, %lopts );
$gopts{wink} = $opts{global}{wink}              if exists $opts{global}{wink};
$gopts{beat} = $opts{global}{beat}              if exists $opts{global}{beat};
$lopts{wink} = $opts{local}{wink}                if exists $opts{local}{wink};
$lopts{beat} = $opts{local}{beat}                if exists $opts{local}{beat};

$dtrg = FAFTS_tempdir
  nick => q|dtagdbf8|, dir => $TS_Conf->{ftp_slow}{target}{dir};
$fsrc = $TS_Conf->{ftp_slow}{source};

$fafs = File::AptFetch::Simple->request(
{ method => q|ftp|, location => $dtrg, %gopts }, $fsrc );

unlink $fafs->{message}{filename};
$fafs = $fafs->request({ %lopts }, $fsrc );

# vim: syntax=perl
