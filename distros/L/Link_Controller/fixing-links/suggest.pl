#!/usr/bin/perl

=head1 NAME

suggest - suggest alternatives to a link

=head1 SYNOPSIS

suggest first-link-name suggestion....

=head1 DESCRIPTION

This program records alternatives to a link in a database.  It is
designed to be able to run SUID and record these suggestions in a
central database where anyone can access them.

It accepts no command line options beyond the first link name and the
suggestions.

No attempt is made to guard against suggestions which are useless or
which point to sites which might upset the user.  Possibly we should
log what suggestions are made.

This program trusts the database who's filename is built into it.

=head1 SEE ALSO

L<verify-link-control(1)>; L<extract-links(1)>; L<build-schedule>
L<link-report(1)>; L<fix-link(1)>; L<link-report.cgi(1)>; L<fix-link.cgi>
L<suggest(1)>; L<link-report.cgi(1)>; L<configure-link-control>

The LinkController manual in the distribution in HTML, info, or
postscript formats, included in the distribution.

http://scotclimb.org.uk/software/linkcont - the
LinkController homepage.

=cut

use Fcntl;
use DB_File;
use MLDBM qw(DB_File);
use WWW::Link;
use strict;
use vars qw($linkdatabase $link $changed);

#Configuration - we go through %ENV, so you'd better not be running SUID
#eval to ignore if a file doesn't exist.. e.g. the system config

use WWW::Link_Controller::ReadConf;

use Getopt::Function; #don't need yet qw(maketrue makevalue);

$::opthandler = new Getopt::Function 
  [ "version V>version",
    "usage h>usage help>usage",
    "help-opt=s",
    "verbose:i v>verbose",
  ],  {};

$::opthandler->std_opts;

$::opthandler->check_opts;

@::changelist = @ARGV;

sub usage() {
  print <<EOF;
suggest original-url new-url

EOF
  $::opthandler->list_opts;
  print <<EOF;

Make a suggestion for a URL for a link which could replace a broken one.
EOF
}

sub version() {
  print <<'EOF';
suggest version 
$Id: suggest.pl,v 1.7 2001/11/22 15:33:21 mikedlr Exp $
EOF
}


# Our entire aim is to write to a database which the real user should
# have no write access to.  We should probably check that they have
# read access.  We should certainly check that the directory is secure
# and that the database is not a symlink.

#FIXME filechecks

die 'you must define the $::links configuration variable' 
    unless $::links;
$::linkdbm = tie %::links, "MLDBM", $links, O_RDWR, 0666, $::DB_HASH
    or die $!;

my $oldurl=shift;

my $link=$::links{$oldurl} or die "couldn't find a link for your original url";
my $changed=0;
my $newurl;
while ( $newurl=shift ) {
  if ( $link->add_suggestion($newurl) ) {
    print "Link suggestion accepted.  Thank you\n";
    #FIXME logging of who and when.
    $changed ++;
  } else {
    print "Already knew about that suggestion.  Thanks though.\n";
  }
}
$::links{$oldurl}=$link if $changed;



