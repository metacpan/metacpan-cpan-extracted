#!/usr/bin/perl -w
#!/usr/bin/perl -Tw

=head1 NAME

link-report.cgi - provide an interface for querying the database of links

=head1 DESCRIPTION

This system provides a (deliberately simple) way to query the database
of links and see what is available.  It is designed to be called as a
cgi script and as such should be run from an http server.  It will
output all of the requested information as an HTML document preceded
by HTTP headers.

This program is normally run from a hardwired script created by
configure-link-cgi.  These scripts set the various configuration
variables described below.

=head1 CONFIGURATION

There are two options for configuring this program.  Since the program
is designed to be run as a CGI, instead of accepting command line
options, it normally expects to be run with configuration variables
already defined.  A suitable script which does this can be generated
with B<configure-link-cgi>.

The programs configuration comes from the file .cgi-infostruc.pl in the
directory where it is run.  If you want it to use a different
configuration file you should take a copy of the program and change
this in the source.  Usage is arranged like this because it seems more
secure.

=cut

=head1 PARAMETERS

The following parameters can be passed from the cgi form

=head2 infostructure

If the value evaluates true in perl (isn't 0 or the empty string) the
report will report on links within the infostructure.  Otherwise the
report will be against the full database.

=head2 repair

If the value evaluates true in perl (isn't 0 or the empty string) the
report will actually be a series of forms which can be used for
repairing the infostructure via the fix-link.cgi cgi-bin.

=head2 urllist

The value will be taken as a space separated list of urls which can be
examined.

=head1 BUGS

The program should say something like no links found when it is
generating zero output.

=head1 SEE ALSO

L<verify-link-control(1)>; L<extract-links(1)>; L<build-schedule>
L<link-report(1)>; L<fix-link(1)>; L<link-report.cgi(1)>; L<fix-link.cgi>
L<suggest(1)>; L<link-report.cgi(1)>; L<configure-link-control>

The LinkController manual in the distribution in HTML, info, or
postscript formats, included in the distribution.

http://scotclimb.org.uk/software/linkcont/ - the
LinkController homepage.

=cut

BEGIN {
  $ENV{PATH} = "/bin:/usr/bin";
  delete @ENV{qw(HOME IFS CDPATH ENV BASH_ENV)};   # Make %ENV safer
}

use Cwd;
use strict;
use vars qw($linkdbm $fixed_config);
#use CGI::Out;
use CGI::Carp;
use CGI::Request;
#use HTML::Stream;
use Fcntl;
use DB_File;
use Data::Dumper;
use MLDBM qw(DB_File);
use CGI::Response;
use WWW::Link;
use WWW::Link::Reporter::RepairForm;
use WWW::Link::Reporter::HTML;
use WWW::Link::Selector;
use CDB_File::BiIndex 0.026;

$::verbose=0 unless defined $::verbose;
$WWW::Link::Selector::verbose = 0xFF if $::verbose;

#if the config files are to be previously overridden then this must
#have already been "used"
#   Read this yourself..
#use WWW::Link_Controller::ReadConf;

#FIXME
#Configuration - here we bypass tainting
# this basically means we trust the directory we are called in.. unwise!!
# this should never be an issue in a normal CGI which will be run from
# the user's hardwired script..

BEGIN {
  print STDERR "links before $::links\n" if $::verbose;
  $DB::single = 1;
  my $icwd=cwd();
  print STDERR "icwd: $icwd\n" if $::verbose;
  (my $cwd) = ($icwd =~ m/(.*)/) ; #force launder
  print STDERR "cwd: $cwd\n" if $::verbose;
  if ((! $fixed_config) && -r ".cgi-infostruc.pl") {
    my $file=$cwd . "/.cgi-infostruc.pl";
    defined (do $file) || do {
      die "parse of $file failed: $@" if $@;
      die "couldn't open $file: $!"
    }
  } else {
    warn "using default configuration" if $::verbose;
  }

  print STDERR "links after $::links\n" if $::verbose;
};


$DB::single = 0; #for a little peace
$DB::single = 1;

print &CGI::Response::ContentType("text/html");

$::req = new CGI::Request;

#use vars qw($hstr);
#$::hstr = new HTML::Stream; #only used for error reports and debugging.

#our query should be one of
# a query about specific urls with a urllist
# a query about an infostructure with in infostructure list
# a query about the entire database with a selection method.

die 'you must define the $::links configuration variable'
    unless $::links;

print STDERR "Opening link database $::links\n"
  if $::verbose & 16;

$::linkdbm = tie %::links, "MLDBM", $::links, O_RDONLY, 0666, $::DB_HASH
  or die "opening link file $::links: $!";


$::index = undef;

#get configuration on what we should report.. by default only broken links

if ($::urls = $::req->param("urllist") ) {
  print STDERR "got urls $::urls\n"
    if $::verbose & 16;
  $::reporter=new WWW::Link::Reporter::HTML \*STDOUT, $::index;

  $::selectfunc = 
    WWW::Link::Selector::generate_url_func ( \%::links, $::reporter,
					     @$::urls );
  $::reporter->all_reports(1); #report all links
} else {

  if ( $::req->param('infostructure') ) {
    die 'you must define the $::link_index configuration variable'
      unless $::link_index;
    die 'you must define the $::page_index configuration variable'
      unless $::link_index;
    print STDERR "dealing with infostructure: $::page_index, $::link_index\n"
      if $::verbose & 16;
    $::index = new CDB_File::BiIndex $::page_index, $::link_index;
    #FIXME... we should check if we have a known user or something.
    if ( $::req->param('repair') ) {
      die 'must define $::fixlink_cgi configuration variable for repairs'
	unless $::fixlink_cgi;
      $::reporter=
	new WWW::Link::Reporter::RepairForm $::fixlink_cgi, $::index;
    } else {
      $::reporter=new WWW::Link::Reporter::HTML \*STDOUT, $::index;
    }
  } else {
    $::reporter=new WWW::Link::Reporter::HTML \*STDOUT, $::index;
  }

  $::reporter->all_reports(0); #report no links
  $::reporter->{"report_broken"}=1; #report broken links
  $::reporter->{"report_redirected"}=1; #report broken links

  if ($::url_regex) {
    $::include = sub { return 1 if $_[0] =~ m/$::url_regex/o; };
  }  else {
    $::include = sub { return 1 ; };
  }

  $::selectfunc = WWW::Link::Selector::generate_select_func ( \%::links,
							 $::reporter,
							 $::include,
							 $::index,
						       );
}

#fixme :- page size limits?

$::reporter->heading;

# $::hstr->PRE();
# $::hstr->t(&Dumper($::req));
# $::hstr->_PRE();

&$::selectfunc;

$::reporter->footer;

exit;
