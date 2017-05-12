#!/usr/bin/perl -w
##-*- Mode: CPerl; coding: utf-8; -*-

use lib qw(. lib blib/lib dclib lib/lib dclib/lib dclib/blib/lib dclib/blib/arch);
use DiaColloDB::WWW::CGI;
use utf8;
use strict;
#use CGI '-debug';
BEGIN {
  #binmode(STDIN, ':utf8');
  #binmode(STDOUT,':utf8');
  binmode(STDERR,':utf8');
}

##----------------------------------------------------------------------
## local config

our $prog    = basename($0);
our $progdir = abs_path(".");

##-- BEGIN dstar config
our %dstar = qw();
foreach my $rcfile (map {"$_/dstar.rc"} "$progdir","$progdir/..") {
  if (-r $rcfile) {
    do "$rcfile" or die("$prog: failed to load dstar config file '$rcfile': $@");
    last;
  }
}
##-- END dstar config

##-- BEGIN dstar local
foreach my $rcfile (map {"$_/local.rc"} "$progdir","$progdir/..") {
  if (-r $rcfile) {
    do "$rcfile" or die("$prog: failed to load local config file '$rcfile': $@");
    last;
  }
}
##-- END dstar local config

##-- BEGIN dstar diacollo standalone fallbacks
$dstar{corpus} = basename($progdir) if (!defined($dstar{corpus}));
##-- END dstar diacollo standalone fallbacks

##----------------------------------------------------------------------
## dbcgi guts

my $dbcgi = DiaColloDB::WWW::CGI->new(ttk_vars=>{dstar=>\%dstar});
$dbcgi->fcgi_main();
