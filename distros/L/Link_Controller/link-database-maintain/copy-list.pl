#!/home1/mikedlr/bin/perl -w
#!/usr/bin/perl -w

=head1 NAME

copy-list - copy a list of links from one database to another

=head1 SYNOPSIS

copy-list link-database-filename listfile ....

=head1 DESCRIPTION

This program simply copies over a list of links from the old version
of the database to the new.  It moves the old version to a file of the
same name, but with C<.bak> appended.

This program can be used to clean up the database by only keeping
links which are currently in use.  This may not always be advisable
though because a page may be curently deleted but be going to be
re-instated which will mean all of it's links would need to return to
the database in which case all of the links in that page will have to
be checked again from the beginning which will take a long time.

=head1 SEE ALSO

L<verify-link-control(1)>; L<extract-links(1)>; L<build-schedule>
L<link-report(1)>; L<fix-link(1)>; L<link-report.cgi(1)>; L<fix-link.cgi>
L<suggest(1)>; L<link-report.cgi(1)>; L<configure-link-control>

The LinkController manual in the distribution in HTML, info, or
postscript formats, included in the distribution.

http://scotclimb.org.uk/software/linkcont - the
LinkController homepage.

=cut

require 5.001;

use strict;

use Fcntl;
use DB_File;
use Data::Dumper;
use MLDBM qw(DB_File); #chosen over GDBM for network byte order.
#use MLDBM; 
use URI;

use WWW::Link;
use WWW::Link_Controller;
use WWW::Link_Controller::Lock;
use WWW::Link_Controller::ReadConf;

use vars qw($olddbm $linkdbm);


##############################################################################
#start command line processing
use Getopt::Function qw(maketrue makevalue);

$::verbose=0;
$::old_database=undef;
$::new_database=undef;
$::opthandler = new Getopt::Function
  [ "version V>version",
    "usage h>usage help>usage",
    "help-opt=s",
    "verbose:i v>verbose",
    "",
    "old-database=s o>old-database",
    "new-database=s n>new-database",
  ],  {
    "old-database" => [ \&makevalue, 
		        "Copy links from given old database file.",
		        "FILENAME" ],
    "new-database" => [ \&makevalue, 
		        "Copy links to given new database file.",
		        "FILENAME" ],
  };

$::opthandler->std_opts;

$::opthandler->check_opts;

sub usage() {
  print <<'EOF';
copy-list.pl [options] link_database_file list_of_links

EOF
  $::opthandler->list_opts;
print <<'EOF';

Copy the links given in the list_of_links file (or STDIN) to the new
version of the database, renaming the old version by appending .bak
(unless the -o option is used).
EOF
}
sub version() {
  print <<'EOF';
copy-list version 
$Id: copy-list.pl,v 1.7 2002/01/02 22:53:15 mikedlr Exp $
EOF
}

CASE: {
  defined $::new_database and last;

  @ARGV && do {
    $::new_database =shift;
    die "excess command line arguments" if @ARGV;
    last;
  };

  defined $::links && do {
    $::new_database = $::links;
    last;
  };

  die "no idea which database to copy to";

}


##############################################################################
#end command line processing

#If your filesystem can't cope with long names REPLACE IT.  Same goes
#for the operating system.
$::old_data=0;

#FIXME, locking using the old database!!!????
WWW::Link_Controller::Lock::lock($::new_database);
if ($::old_database) {
  $::olddbm = tie ( %::old_links, "MLDBM", $::old_database, O_RDONLY,
		    0666, $DB_HASH )
	  or die "old links failed: $!";
} else {
  #calmly and casually trash any similarly named files .. oh hell  #FIXME
  #and feel really superior and moral if you wish.
  rename $::new_database, $::new_database . '.bak' 
    and ( $::olddbm = tie ( %::old_links, "MLDBM", $::new_database . '.bak' ,
			    O_RDONLY, 0666, $DB_HASH )
	  or die "old links failed: $!" )
      and $::old_data=1;
}

# FIXME what checks and safety should we have about permissions and
# validity of old database.

$::linkdbm = tie %::links, "MLDBM", $::new_database, O_CREAT|O_RDWR, 0666, $DB_HASH
  or die $!;

URLLINE: while ( <> ) {
  chomp; 
  my $url=$_;
  print STDERR "acting on $url\n"
    if $::verbose & 4;
  unless ( defined $::links{$url} ) {
    if ( $::old_data && defined $::old_links{$url} ) {
      $::links{$url}=$::old_links{$url}; 
      next URLLINE;
    }
    my $newlink=new WWW::Link $url;
    $::links{$url}=$newlink; 
  }
}

#FIXME: this should probably be optional;

foreach my $special_key ( @WWW::Link_Controller::special_keys ) {
  $::links{$special_key}=$::old_links{$special_key}
    if ( defined $::old_links{$special_key} );
}









