#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use FindBin;

use Config;
use File::Glob qw(bsd_glob);
use Test::More;

use Doit;

my $man3ext = $Config{'man3ext'};
my $man3path = "$FindBin::RealBin/../blib/man3";
my $has_blib_man3 = -d $man3path;
plan skip_all => "manifypods probably not called" if !$has_blib_man3;
plan 'no_plan';

my $doit = Doit->init;

if ($man3ext !~ m{^(3|3pm)$}) {
    # Seen ".0" on some smoker systems:
    # http://www.cpantesters.org/cpan/report/0490cdd2-70ce-11e9-9066-e374b0ba08e8
    diag "Non-standard man3 extension: .$man3ext instead of .3";
}

my $troff_rx = qr{(
		      troff      # e.g. Linux file(1)
		  |   \[nt\]roff # e.g. Solaris file(1)
		  )}x;

ok -s bsd_glob("$man3path/Doit.$man3ext*"),     'non-empty manpage for Doit'
    or diag($doit->info_qx(qw(ls -al), $man3path));
ok -s bsd_glob("$man3path/Doit*Deb.$man3ext*"), 'non-empty manpage for Doit::Deb'
    or diag($doit->info_qx(qw(ls -al), $man3path));

my $file_prg = $doit->which('file');
SKIP: {
    skip "file command not installed", 1 if !$file_prg;
    like get_filetype(bsd_glob("$man3path/Doit.$man3ext*")),     $troff_rx, 'Doit manpage looks like a manpage';
    like get_filetype(bsd_glob("$man3path/Doit*Deb.$man3ext*")), $troff_rx, 'Doit::Deb manpage looks like a manpage';
}

sub get_filetype {
    my($file) = @_;
    chomp(my($filetype) = $doit->info_qx({quiet => 1}, $file_prg, $file));
    if ($filetype =~ /ReStructuredText file, (UTF-8 Unicode|ASCII) text/) {
	skip "Mis-detection of file type in debian:bullseye and ubuntu:20.04, see https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=949878", 1;
    }
    $filetype;
}

__END__
