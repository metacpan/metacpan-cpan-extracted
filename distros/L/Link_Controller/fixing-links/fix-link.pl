#!/usr/bin/perl -w

=head1 NAME

fix-link - identify files affected by a link change and fix them

=head1 SYNOPSIS

fixlink-as-text.pl [arguments] old-link new-link

=head1 DESCRIPTION

This program is designed to change one uri to another one throughout
an infostructure (group of interlinked files).  Normally the program
uses an index built up for link testing to make this operation fast by
examining only those files which have links needing changed.

B<This program is not designed to run SUID.  Instead the user is meant
to have access to the files that are to be changed.>


=head1 FILE LOCATION MODES

=head2 Find Files by directory

Goes through all of the files in a directory.  It changes checks all
files to see if they need to be changed.

=head2 Find Files by index file

Goes through the index file looking for all URIs that need to be
corrected then corrects those.

=head1 SUBSTITUTION MODES

=head2 Do simple textual substitutions

Here we just substitute string for string.  See "HOW IT WORKS" below.

=head2 Do file parsing to find uris

Not yet implemented.  Here we go through each file parsing it
properly.  This is the only way for binary formats.

=head1 RELATIVE LINKS

With the B<--relative> option we can search for relative links.  This
is more dangerous (more chance of a false match) and slower, but will
be needed if you move files within your own web pages and need to
correct links to them.

=head1 HOW IT WORKS

This discussion covers how we do substitution in HTML documents.  It's
a bit out of date.

The proper way to do this is to parse each bit of the document, then
identify the links, convert them to the most cannonical form possible
and compare them to the original uri.  If they match then replace them
with the new one (possibly in a relative form).

This is great if:-
  a) your document is not broken

  b) you don't have any links outside the link text (more common than
  you would like to imagine, think of every `we have changed to a new
  site' notice)

So we resort to the following brute force approach:-

  a) if it looks like the original absolute link substitute it no
  matter what.

  b) if it looks like the relative form and seems to be in an
  attribute substitute it and warn what we are doing.

  c) if it looks like the relative form, but isn't in an attribute
  then bitch about it, but do nothing.

Your files should

  a) have the right level of quoting

  b) not have any uris containing [stuff]/fred/../[stuff]

=head1 TODO

Add extra formats.


=head1 SEE ALSO

L<verify-link-control(1)>; L<extract-links(1)>; L<build-schedule>
L<link-report(1)>; L<fix-link(1)>; L<link-report.cgi(1)>; L<fix-link.cgi>
L<suggest(1)>; L<link-report.cgi(1)>; L<configure-link-control>

The LinkController manual in the distribution in HTML, info, or
postscript formats, included in the distribution.

http://scotclimb.org.uk/software/linkcont/ - the
LinkController homepage.

=cut

use strict;

use CDB_File::BiIndex 0.026;
use DB_File;
use File::Find;
use File::Copy;
use Fcntl;
use MLDBM qw(DB_File);
use WWW::Link::Repair;
use WWW::Link::Repair::Substitutor;
use WWW::Link_Controller::InfoStruc;
use URI;

use WWW::Link_Controller::ReadConf;

#controls - not really configurations right now.

#$::secret_suggestions=0; #whether the user wants to tell others about changes

use vars qw();

use Getopt::Function qw(maketrue makevalue);
$::verbose=0;
$::tree=0;
$::base=undef;
$::relative=undef;
$::opthandler = new Getopt::Function
  [ "version V>version",
    "usage h>usage help>usage",
    "help-opt=s",
    "verbose:i v>verbose",
    "silent q>silent quiet>silent",
    "no-warn",
    "",
#    "link-index=s",
    "directory=s",
    "",
    "relative r>relative",
    "tree t>tree",
    "base=s b>base",
    "",
    "config-file=s",
  ],  {
#         "link-index" => [ sub { $::link_index=$::value; },
#  			 "Use the given file as the index of which file has "
#  			 . "what link.",
#  			 "FILENAME" ],
       "directory" => [ \&makevalue,
			 "correct all files in the given directory.",
			 "DIRNAME" ],
#   "mode" => [ sub { $::link_index=$::value; },
#  		  "Use the given file as the index of which file has "
#  		  . "what link.",
#  		  "FILENAME" ],
       "tree" => [ \&maketrue,
		   "Fix the link and any others based on it." ],
       "no-warn" => [ sub { $::no_warn = 1; },
		      "Avoid issuing warnings about non-fatal problems." ],
       "relative" => [ \&maketrue,
		       "Fix relative links (expensive??)." ],
       "base" => [ \&makevalue,
		   "Base URI of the document or directory to be fixed.",
		   "FILENAME" ],
       "config-file" => [ sub {
			    eval {require $::value};
			    die "Additional config failed: $@"
			      if $@; #if it's not there die anyway. compare Config.pm
			  },
			  "Load in an additional configuration file",
			  "FILENAME" ],
  };

$::opthandler->std_opts;

$::opthandler->check_opts;

sub usage() {
  print <<'EOF';
fix-link [options] old-link new-link

EOF
  $::opthandler->list_opts;
print <<'EOF';

Replace any occurences of OLD-LINK with NEW-LINK using link index file
to locate which files OLD-LINK occurs in.
EOF
}

sub version() {
  print <<'EOF';
fix-link version
$Id: fix-link.pl,v 1.22 2002/02/03 21:18:46 mikedlr Exp $
EOF
}

$WWW::Link::Repair::no_warn=1 if $::no_warn;
$WWW::Link::Repair::verbose=0xFFF if $::verbose;
$WWW::Link::Repair::Substitutor::verbose=0xFFF if $::verbose;
$WWW::Link_Controller::InfoStruc::verbose=0xFFF if $::verbose;

my $origuri=shift;
die "missing arguments, giving up\n" unless @ARGV;
my $newuri=shift;

#FIXME: CHANGE EVERYTHING TO USE URI RATHER THAN URL
#make the uris absolute.

if (defined $::base) {
  my $origuri_obj = new URI $origuri;
  my $newuri_obj = new URI $newuri;

  my $orig_abs = $origuri_obj->abs($::base);
  my $new_abs = $newuri_obj->abs($::base);

  $origuri = $orig_abs->as_string();
  $newuri = $new_abs->as_string();
}

print STDERR "going to change $origuri to $newuri\n" if $::verbose;

$::file_subs= WWW::Link::Repair::Substitutor::gen_file_substitutor
    ($origuri, $newuri, ($::tree ? ( tree_mode => 1 ) : () ),
     ($::relative ? ( relative => 1 , 
		      file_to_url => \&WWW::Link_Controller::InfoStruc::file_to_url)
                  : () ),
     );

$::default_infostrucs=1 unless defined $::default_infostrucs;

die "you must define the \$::infostrucs configuration variable"
  if $::default_infostrucs and not defined $::infostrucs ;

WWW::Link_Controller::InfoStruc::default_infostrucs()
  if $::default_infostrucs;

unless ( $::directory  ) {

  #we could create new links as we go along.  We could delete old ones
  #but I don't see why..  Best that I can see is to output a list of
  #any new URLs we create..
  #
  #    die 'you must define the $::links configuration variable'
  #      unless $::links;
  #    tie %::links, MLDBM, $::links, O_RDONLY, 0666, $DB_HASH
  #      or die $!;
  # we go RDONLY but if we want to make suggestions that will have to change

  die 'you must define the $::link_index configuration variable'
    unless $::link_index;
  die 'you must define the $::page_index configuration variable'
    unless $::page_index;
  $::index = new CDB_File::BiIndex $::page_index, $::link_index;

  print STDERR "using index to find files\n" if $::verbose;
  my $trans_sub=\&WWW::Link_Controller::InfoStruc::url_to_file;
  my $fixed=WWW::Link::Repair::infostructure($origuri, $::index, $trans_sub,
					     $::file_subs, $::tree);
  unless ( $::silent ) {
    if ( $fixed or $::relative ) {
      print "fix-link finished: made $fixed substitutions\n";
    } else {
      print "fix-link finished: made no substitutions.. try --relative?\n"
    }
  }
} else {
  print STDERR "searching through directory $::directory\n" if $::verbose;
  my $fixed=WWW::Link::Repair::directory($::file_subs, $::directory);
  print "fix-link finished: made $fixed substitutions\n"
    unless $::silent;
}

exit;
