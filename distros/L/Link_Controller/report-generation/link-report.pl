#!/usr/bin/perl -w

=head1 NAME

link-report - report status of links using databases

=head1 DESCRIPTION

This program goes through an entire database of links and reports
information about those links which match given criteria.  It can
optionally relate these to the locations of these links in files.  It
can give the output in several formats.

No actions are carried out to get further information than that which
is in the database.  This means that if a URI isn't listed in the link
database, a warning is printed, but nothing else.

Distributed along with this program is a file for emacs which can use
this to build a list of files for editing called link-report-dired.
This can be very useful for fixing all broken links.

=head1 SELECTING LINKS TO REPORT

This bit is where we really miss in the design by not doing it against
an SQL database.  When (and if) that comes then we can add alot more
power here more simply.

There are three modes for selection

=over 4

=item *

by URI

=item *

by regex on the URI --uri-include --uri-exclude

=item *

by regex on the page name --page-include --page-exclude

=back

These select which links are to be examined.  Then there are options
on the state of the link which choose which links to actually put out
information about.

By default redirected and broken links are output.  If any of these
options are called then only the specified links are output.

=over 4

=item --all-links

print out links in all states

=item --not-perfect

print out all links which were broken even on one check.

=item --redirected

print out links which were redirected

=back

=head1 CONTROLLING THE REPORT FORMAT

The list of broken links can be put out in several formats.  By
defualt it is in plain text with a description of the problem and a
list of broken pages following under each link.  Alternatively other
formats are possible.  These are selected through command line
options as follows.

=over 4

=item --long-list

Instead of listing the urls of the pages where broken links are, this
converts each link to a file name and does a listing of the file.

=item --html

This outputs a basic HTML format report which is otherwise similar to
the default text report.

=item --uri-report

This report simply lists URIs of the selected links from
LinkControllers database.  This provides a better format for
interfacing to other programs.

=back

=head1 TODO

Much detailed control of the kind of links reported should be provided
(e.g. how many times detected broken etc.).  This should be done as a
more advanced database system is integrated.

If there's any specific, reasonably simple, reporting option you would
like added then please send a request to the bug reporting address
explaining what this report would be used for.

=head1 BUGS

If reporting options which don't make sense together are given then
the reporting probably won't make much sense, though it should still
work.


=head1 SEE ALSO

L<verify-link-control(1)>; L<extract-links(1)>; L<build-schedule>
L<link-report(1)>; L<fix-link(1)>; L<link-report.cgi(1)>; L<fix-link.cgi>
L<suggest(1)>; L<link-report.cgi(1)>; L<configure-link-control>

The LinkController manual in the distribution in HTML, info, or
postscript formats, included in the distribution.  This includes
information about using link-report to `interface' to databases.

http://scotclimb.org.uk/software/linkcont/ - the LinkController
homepage.

=cut


use strict;
use Fcntl;
use DB_File;
use MLDBM qw(DB_File);
use CDB_File::BiIndex 0.026;
use WWW::Link;
use WWW::Link::Selector;
use WWW::Link_Controller::InfoStruc;
use vars qw($linkdbm);


$::verbose=1023;

#Configuration - we go through %ENV, so you'd better not be running SUID
#eval to ignore if a file doesn't exist.. e.g. the system config
use WWW::Link_Controller::ReadConf;

##############################################################################
#start command line processing
use Getopt::Function qw(maketrue makevalue);

use vars qw($not_perfect $redirected $since);

$::ignore_missing=0;
$::pages=1;
$::verbose=0;
$::not_perfect=0;
$::okay=0;
$::good=0;
$::since=0;
$::html=0;
$::long_list=0;
@::uri_exc=();
@::uri_inc=();
@::page_exc=();
@::page_inc=();
@::uris=();
$::uri_list=0;
$::uri_report=0;

$::opthandler = new Getopt::Function
  [ "version V>version",
    "usage h>usage help>usage",
    "help-opt=s",
    "verbose:i v>verbose",
    "",
    "uri=s U>uri",
    "uri-file=s f>uri",
    "uri-exclude=s E>uri-exclude",
    "uri-include=s I>uri-include",
    "page-exclude=s e>page-exclude",
    "page-include=s i>page-include",
    "",
    "all-links a>all-links",
    "broken b>broken",
    "not-perfect n>not-perfect",
    "redirected r>redirected",
    "okay o>okay",
    "disallowed d>disallowed",
    "unsupported u>unsupported",
    "ignore-missing m>ignore-missing",
    "good g>good",
    "",
    "no-pages N>no-pages",
    "config-file=s",
    "link-index=s",
    "link-database=s",
    #      "uri-base=s",
    #      "file-base=s",
    "",
    "long-list l>long-list",
    "uri-report R>uri-report",
    "html H>html",
  ],
  {
   "uri-exclude" => [ sub { push @::uri_exc, $::value; },
		      "Add a regular expressions for URIs to ignore.",
		      "EXCLUDE RE" ],
   "uri-include" => [ sub { push @::uri_inc, $::value; },
		      "Give regular expression for URIs to check (if this "
		      . "option is given others aren't checked).",
		      "INCLUDE RE" ],
   "page-exclude" => [ sub { push @::page_exc, $::value; },
		       "Add a regular expressions for pages to ignore.",
		       "EXCLUDE RE" ],
   "page-include" => [ sub { push @::page_inc, $::value; },
		       "Give regular expression for URIs to check (if this "
		       . "option is given others aren't checked).",
		       "INCLUDE RE" ],
   #     "since" => [ \&makevalue,	#FIXME process time strings
   #  		"Only list links who's status has changed since the "
   #  		. "given time.",
   #  		"TIME" ],

   "all-links" => [ \&maketrue,
		    "Report information about every URI." ],
   "broken" => [ \&maketrue,
		 "Report links which are considered broken." ],
   "not-perfect" => [ \&maketrue,
		      "Report any URI which wasn't okay at last test." ],
   "okay" => [ \&maketrue,
	       "Report links which have been tested okay." ],
   "good" => [ \&maketrue,
	       "Report links which are probably worth listing." ],
   "redirected" => [ \&maketrue,
		     "Report links which are redirected." ],
   "disallowed" => [ \&maketrue,
		     "Report links for which testing isn't allowed." ],
   "unsupported" => [ \&maketrue,
		      "Report links which we don't know how to test." ],
   "ignore-missing" => [ \&maketrue,
			 "Don't complain about links which aren't in "
			 . "the database." ],
   "uri-file" => [ sub { print "reading urifile $::value" if $::verbose;
                         open URIS, "<$::value"; my @uris=<URIS>; close URIS;
			 foreach (@uris) {
			   s/\s*$//; s/\s*//;
			 }
			 push @::uris, @uris;
			 $::uri_list=1;
		       },
		   "Read all URIs in a file (one URI per line).",
		   "FILENAME"],
   "uri" => [ sub { push @::uris, split /\s+/, $::value; $::uri_list=1; },
	      "Give URIs which are to be reported on.",
	      "URIs"],
   "no-pages" => [ \&maketrue,
		   "Report without page list.",
		 ],
   "config-file" => [ sub {
			eval {require $::value};
			die "Additional config failed: $@"
			  if $@; #if it's not there die anyway. compare Config.pm
		      },
		      "Load in an additional configuration file",
		      "FILENAME" ],
   "link-index" => [ sub { $::link_index=$::value; },
		     "Use the given file as the index of which file has "
		     . "what link.",
		     "FILENAME" ],
   "link-database" => [ sub { $::links=$::value; },
			"Use the given file as the dbm containing links.",
			"FILENAME" ],

   #     "uri-base" => [ \&makevalue,	#FIXME process time strings
   #  		   "Regex for base of the infostructure (first part of s///).",
   #  		   "REGEX" ],
   #     "file-base" => [ \&makevalue,	#FIXME process time strings
   #  		    "The base of files to be used (second part of s///).",
   #  		    "STRING" ],
   "uri-report" => [ \&maketrue,
		     "Print URIs on separate lines for each link." ],
   "html" => [ \&maketrue,
	       "Report status of links in html format." ],
   "long-list" => [ sub { $::long_list=1; $::pages=1; },
		    "Where possible, identify the file and long list it "
		    . "(implies infostructure).  This is used for emacs "
		    . "link-report-dired." ],
  };
$::opthandler->std_opts;

$::opthandler->check_opts;

sub usage() {
  print <<EOF;
link-report [options]

EOF
  $::opthandler->list_opts;
  print <<EOF;

Report on the status of links, getting the links either from the
database, from the index file or from the command line.
EOF
}

sub version() {
  print <<'EOF';
link-report version
$Id: link-report.pl,v 1.26 2002/02/09 16:31:19 mikedlr Exp $
EOF
}

$WWW::Link::Reporter::verbose=0;
if ($::verbose) {
  $WWW::Link::Reporter::verbose=0xFF;
}

$WWW::Link_Controller::InfoStruc::verbose=0xFFF if $::verbose;

$::default_infostrucs=1 unless defined $::default_infostrucs;

die "you must define the \$::infostrucs configuration variable"
  if $::default_infostrucs and not defined $::infostrucs ;

WWW::Link_Controller::InfoStruc::default_infostrucs()
  if $::default_infostrucs;


##############################################################################
#consistency checks

if (@::uris) {
  die "If you specify URIs then we can't use exclude or include regexes"
    if (@::uri_exc || @::uri_inc 
	|| @::page_exc || @::page_exc);
}

die  "Page and URI exclude are incompatible.  Maybe you can help?"
  if (@::uri_exc || @::uri_inc 
      and @::page_exc || @::page_exc);

##############################################################################
#end command line processing

die 'you must define the $::links configuration variable'
  unless $::links;
$::linkdbm = tie %::links, "MLDBM", $::links, O_RDONLY, 0666, $::DB_HASH
  or die $!;

(@::uri_exc || @::uri_inc) and
  $::include=WWW::Link::Selector::gen_include_exclude @::uri_exc, @::uri_inc;

(@::page_exc || @::page_inc) and
  $::include=WWW::Link::Selector::gen_include_exclude @::page_exc, @::page_inc;

$::include=sub {return 1} unless $::include;


($::pages) && do {
  die 'you must define the $::link_index configuration variable'
    unless $::link_index;
  die 'you must define the $::page_index configuration variable'
    unless $::page_index;
  $::index = undef;
  $::index = new CDB_File::BiIndex ($::page_index, $::link_index);
};

my $form_count=0;
foreach my $opt ( \$::uri_report, \$::html, \$::long_list) {
  $$opt && $form_count++;
}
$form_count > 1 && do {
  die "only one format argument allowed (--uri-report --html --long-list)\n";
};

CASE: {
  $::uri_report && do {
    require WWW::Link::Reporter::URI;
    $::reporter=new WWW::Link::Reporter::URI;
    last CASE;
  };

  $::html && do {
    require WWW::Link::Reporter::HTML;
    $::reporter=new WWW::Link::Reporter::HTML (\*STDOUT, $::index);
    last CASE;
  };

  $::long_list && do {
    require WWW::Link::Reporter::LongList;
    die "you need to provide an index for long listing" unless $::index;
    my $trans_sub=\&WWW::Link_Controller::InfoStruc::url_to_file;
    $::reporter=new WWW::Link::Reporter::LongList ($trans_sub, $::index);
    last CASE;
  };

  require WWW::Link::Reporter::Text;
  $::reporter=new WWW::Link::Reporter::Text $::index;
}

if ($::all_links || $::broken || $::not_perfect || $::okay || $::redirected
    || $::ignore_missing || $::disallowed || $::unsupported || $::good) {
  $::reporter->all_reports(0);
  $::all_links && $::reporter->all_reports(1);
  $::not_perfect and do {
    $::reporter->report_not_perfect(1);
  };
  $::good and do {
    $::reporter->report_good(1);
  };
  $::reporter->report_broken(1) if $::broken;
  $::reporter->report_redirected(1) if $::redirected;
  $::reporter->report_disallowed(1) if $::disallowed;
  $::reporter->report_unsupported(1) if $::unsupported;
  $::reporter->report_okay(1) if $::okay;
} else {
  #DWIM defaults
 CASE: {
    $::reporter->all_reports(0);
    $::uri_report && do {
      $::reporter->report_broken(1) if $::broken;
      last CASE;
    };
    $::reporter->default_reports();
  }
}

CASE: {
  ($::uri_list ) && do {
    print STDERR "Reporting on specific URIs:", join (" ", @::uris), "\n"
      if $::verbose & 16;
    $::selectfunc =
      WWW::Link::Selector::generate_url_func (\%::links,$::reporter,@::uris );
    last CASE;
  };
  (@::page_exc || @::page_inc ) && do {
    die "page filtering only works in page mode" unless $::index;
    print STDERR "Reporting on filtered pages from the database.\n"
      if $::verbose & 16;
    $::selectfunc =
      WWW::Link::Selector::generate_index_select_func
	  ( \%::links, $::reporter, $::include, $::index, );
    last CASE;
  };
  print STDERR "Reporting on filtered URIs direct from database.\n"
    if $::verbose & 16;
  $::selectfunc =
    WWW::Link::Selector::generate_select_func
	( \%::links, $::reporter, $::include, $::index, );
}

$WWW::Link::Selector::ignore_missing = $::ignore_missing;

$::reporter->heading;
&$::selectfunc;
$::reporter->footer;

print STDERR "finished reporting on links\n"
  if $::verbose;
