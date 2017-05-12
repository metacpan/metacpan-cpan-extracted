#!/usr/bin/perl -w

=head1 NAME

extract-links - build links database

=head1 SYNOPSIS

 extract-links [options]
 extract-links [options] URI directory
 extract-links [options] URL

=head1 DESCRIPTION

This program extracts links and builds the databases used by
link-controllers various other programs.

The first database built is the links database containing information
about the status of all of the links that are being checked.  The
second two are in cdb format and can be used as indexes for
identifying which files contain which URIs and vica versa.

=head1 FILE MODE

In file mode this goes through a directory tree.  The program requires
a base URI which is the URI which would be used to refernce the
directory in which all of the files are contained on the world wide
web.  This is used to convert internal references into full URIs which
can be used to check that the files are visible from the outside.

=head1 WWW MODE

In WWW mode the program goes through a set of World Wide Web pages
generating the databases.

The program requires a base-URL which where it starts from.  It's
default mode is to only work down from that URL, that is it will only
get URIs from WWW pages who's URL starts with the base-url

=head1 FILTERING

There are two regular expressions which can be given for filtering.
If the regular expression given with <--exclude-regex> matches the
file name then it will not be read in.  If the regular expression
given with C<--prune-regex> matches a directory name then that entire
directory and all subdirectories are excluded.

=head1 CONFIGURATION

By default, extract-links extracts and refreshes all of the
infostructures listed in the file $::infostrucs.  The file looks like

   #mode	url	directory
   www	http://myserver.example.com /var/www/html223

This is covered in detail in the LinkController reference manual.

=head1 FILES

There are several configuration

  $HOME/.link-control.pl - base configuration file

This contains configuration variables which point to further files.

  $::links - link database

  $::infostrucs - infostructure configuration file

Full details of the format of these configuration files can be found
in the LinkController reference manual.

=head1 NOTES

Unlike other programs which tend to resort to closing and re-opening
files with lists of links, or holding them all in memory, this program
uses a file containing list of links to follow the recursion in the
WWW without actually using recursive functions.  This relies on output
to an unbuffered file being available for input immediately
afterwards.

We also use a temporary database to record which links have been seen
before.  This could get LARGE.

=head1 BUGS

The HTML parsing is done by the perl html parser.  This provides
excelent and controllable results, but a custom parser carefully
written in C would be alot faster.  This program takes a long time to
run.  Since this program is run under human control this matters.  If
anyone knows of an efficient I<but good> C based parser, suggestion
would be greatfully accepted.  Direct interface compatibility with the
current Perl parser would be even better.

I think the program can get trapped in directories it can change into,
but can't read (mode o+x-w).  This should be fixed.

This program could put a large load on a given server if accidentally
let go where it shouldn't be.  This is your responsibility since it
isn't reasonable to slow it down for when it's being used on a local
machine or LAN.  Some warning should be provided.. e.g. out of local
domain check.

I don't really know if the tied database is really needed.  I want to
allow massive link collections though.

=head1 SEE ALSO

L<verify-link-control(1)>; L<extract-links(1)>; L<build-schedule>
L<link-report(1)>; L<fix-link(1)>; L<link-report.cgi(1)>; L<fix-link.cgi>
L<suggest(1)>; L<link-report.cgi(1)>; L<configure-link-control>

L<cdbmake>, L<cdbget>, L<cdbmultiget>

The LinkController manual in the distribution in HTML, info, or
postscript formats, included in the distribution.

http://scotclimb.org.uk/software/linkcont - the
LinkController homepage.

=cut

require 5.001;

use strict;
use warnings;
use Fcntl;

use Cwd;
use File::Find;

use LWP::MediaTypes;
require HTML::LinkExtor;
#use URI;
use LWP::Auth_UA;
use CDB_File::BiIndex::Generator;

use DB_File; #for temporary database
use Data::Dumper;
use MLDBM qw(DB_File); #chosen over GDBM for network byte order.

use WWW::Link;

use WWW::Link_Controller::ReadConf;
use WWW::Link_Controller::Lock;

use CDB_File::BiIndex::Generator;

use WWW::Link_Controller;
use WWW::Link_Controller::URL;

use WWW::Link_Controller::InfoStruc;

sub link_handler ($%) ;
sub findweb ($%) ;
sub make_act_on_file ($$%);
sub make_attrib_func ($$%);
sub chunk_accept_func ($) ;
sub read_infostruc_file ($$) ;

##############################################################################
#start command line processing
use Getopt::Function qw(maketrue makevalue);


$::write_links = 1; # not currently configurable, but should be

$::link_database=undef;
@::infostrucs=();
$::default_infostrucs=undef;
$::start_time=time;
$::in_uri_list=undef;
$::out_uri_list=undef;
$::verbose=0;
$::opthandler = new Getopt::Function
  [ "version V>version",
    "usage h>usage help>usage",
    "help-opt=s",
    "verbose:i v>verbose",
    "silent quiet>silent q>silent",
    "",
    "exclude-regex=s e>exclude-regex",
    "prune-regex=s p>prune-regex",
    "default-infostrucs d>default-infostrucs",
    "",
    "link-database=s l>link-database",
    "config-file=s c>config-file",
    "",
    "out-uri-list=s o>out-uri-list",
    "in-uri-list=s i>in-uri-list",
  ],{
     "default-infostrucs" => [ \&maketrue,
			  "handle all default infostrucs (as well as ones "
			     . "listed on command line)" ],
     "exclude-regex" => [ \&makevalue,
			  "Exclude expression for excluding files.",
			  "REGEX" ],
       "prune-regex" => [ \&makevalue,
			  "Regular expression for excluding entire "
			  . "directories.",
			  "REGEX" ],
     "link-database" => [ \&makevalue,
			  "Database to create link records into.",
			  "FILENAME" ],
     "out-uri-list" => [ \&makevalue,
			  "File to output the URI of each link found to",
			  "FILENAME" ],
     "in-uri-list" => [ \&makevalue,
			  "File to input URIs from to create links",
			  "FILENAME" ],
     "config-file" => [ sub {
			  print STDERR "loading extra config\n" if $::verbose;
			  eval {require $::value};
			  die "Additional config failed: $@"
			    if $@;
			  #if it's not there die anyway.
			  # compare ReadConf.pm
			},
			"Load in an additional configuration file",
			"FILENAME" ]
    };

$::opthandler->std_opts;

$::opthandler->check_opts;

sub usage() {
  print <<EOF;
extract-links [arguments] [url-base [file-base]]

EOF
  $::opthandler->list_opts;
  print <<EOF;

Extract the link and index information from a directory containing
HTML files or from a set of WWW pages with URLs which begin with the
given URL and which can be found by starting from that URL and
searching other such pages.
EOF
}

sub version() {
  print <<'EOF';
extract-links version
$Id: extract-links.pl,v 1.11 2002/02/03 21:17:36 mikedlr Exp $
EOF
}

$::links=$::link_database if defined $::link_database;
$WWW::Link_Controller::Lock::silent=1 if $::silent;

if ( @ARGV ) {
  $::default_infostrucs=0 unless defined $::default_infostrucs;
  my $url_base=shift;
  my $file_base=shift;
  my $mode = defined $file_base ? "directory" : "www";
  push @::infostrucs, $url_base;
  $::infostrucs{$url_base} =
    {
     mode => $mode,
     url_base => $url_base,
     file_base => $file_base
    };
}

$::default_infostrucs = 0
  if ( not defined $::default_infostrucs ) and $::in_uri_list;
$::default_infostrucs=1 unless defined $::default_infostrucs;

%::ignored=();
$::ignored=0;

##############################################################################
#end command line processing

#
LWP::MediaTypes::add_type("text/html" => qw(shtml));

die 'you must define the $::links configuration variable'
  unless $::links;

#if we have a communal links database then we store our links in a
#file for the link testing system to pick up.

-f $::links and not -w _ and do {
  defined $::out_uri_list or print STDERR <<EOF;
Can't write to links database.  Creating uri list in
~/.link-control-links instead.
EOF
  $::write_links = 0;
};

open (URILIST, ">$::out_uri_list") if defined $::out_uri_list;

$::checklist="/tmp/extract-links.seen.tmp.$$";

#checklist protects the system overall from recording the same
#link more than once e.g. in the urilists output and optimises
#against accessing the link database more than once for each
#link

tie %::checklist, "DB_File", $::checklist, O_RDWR|O_CREAT, 0666
  or die $!;

eval "END { unlink \$::checklist if defined \$::checklist }";


$::write_links && do {

  WWW::Link_Controller::Lock::lock($::links);
  my $linkdbm;
  print STDERR "opening link file $::links\n" if $::verbose;
  $linkdbm = tie %::link_db, "MLDBM", $::links, O_CREAT|O_RDWR, 0666, $DB_HASH
    or die "failed to open database `$::links': $!";

  $::refresh_time=$::link_db{$WWW::Link_Controller::refresh_key};

  if ( defined $::refresh_time ) {
    $::refresh_time =~ m/^(?:\d+(?:\.\d*)?|\.\d+)$/ or do {
      warn "invalid update time on database $::refresh_time";
      $::refresh_time=undef;
    };
    $::refresh_time > $::start_time and do {
      warn "update time in database in future $::refresh_time.  Updating";
      $::refresh_time=undef;
    };
  }
  $::link_db{$WWW::Link_Controller::refresh_key}=$::start_time;
};

die "you must define the \$::page_index configuration variable"
  unless defined $::page_index;
die "you must define the \$::link_index configuration variable"
  unless defined $::link_index;


$::index=new CDB_File::BiIndex::Generator
 $::page_index , $::link_index;

die "you must define the \$::infostrucs configuration variable"
  if $::default_infostrucs and not defined $::infostrucs ;


if ( $::default_infostrucs ) {
  print STDERR "loading default infostrucs\n" unless $::silent;
  WWW::Link_Controller::InfoStruc::default_infostrucs();
} else {
  print STDERR "ignoring default infostrucs\n" unless $::silent;
}

die "no infostructures to extract links from" unless @::infostrucs;
INFOS: foreach my $base_url ( @::infostrucs ) {
  my $defs = $::infostrucs{$base_url};

  my $file_base=$defs->{file_base};
  defined $file_base and not -e $file_base and die
    "file base $file_base doesn't exist for $base_url";
#  defined $directory and not -d $directory and die
#    "base directory $directory isn't a directory for $url";


 CASE: {
    my $mode=$defs->{mode};
    $mode eq "directory" && do {
      die "file_base not defined for infostructure $base_url"
	unless defined $file_base;
      -e $file_base || do {
	warn "$file_base does not exist, ignoring infostruc $base_url";
	next INFOS;
      };

      -d $file_base && do {
        $file_base = $file_base . "/" unless $file_base =~ m,/$,;
	$base_url = $base_url . "/" unless $base_url =~ m,/$,;
      };

      print STDERR <<EOF if $::verbose & 2;
About to extract links from infostructure $base_url
using $file_base as the base directory.
EOF
      my $act_on_file=make_act_on_file ($base_url,$file_base,%$defs);
      find ( $act_on_file, $file_base);
      last;
    };

    $mode eq "www" && do {
      print STDERR <<EOF if $::verbose & 2;
About to extract links from infostructure $base_url
using recursive web download.
EOF
      findweb ( $base_url, %$defs);
      last;
    };

    die "invalid mode $mode";

  }

}
print STDERR "--------------------------\n"
  . "finished extracting links; building databases\n"
  if $::verbose & 4;

$::index->finish();

if ( $::ignored and not $::silent) {
  print "Ignored $::ignored files of the following types\n";
  while (my ($type, $count)=each %::ignored) {
    my $repeat=30 - length($type) - length($count);
    $repeat=0 if $repeat < 0;
    $repeat+=5;
    print $type, "." x $repeat, $count, "\n";
  }
  print "If $::ignored seems alot then maybe you want to send in a patch?\n";
}
exit 0;


#act on file, designed to be called by File::Find for each
#file in the infostructure.

sub make_act_on_file ($$%){
  my $url_base=shift;
  my $file_base=shift;
  my %settings=@_;

  my $prune_regex = $settings{prune_re};
  my $include_regex = $settings{resource_include_re};
  my $exclude_regex = $settings{resource_exclude_re};

  return sub {

    -d && do {
      $File::Find::prune=1 if defined $prune_regex
	and $File::Find::name =~ m/$prune_regex/o;
      return 1;
    };

    #file name for this page
    my $page_name=$File::Find::name;
    #base url for this page
    my $base = $File::Find::dir . '/';
    $base =~ s/^$file_base/$url_base/;
    #url for this page
    my $page_url="$base$_";

    return if -l;
    ( defined $include_regex and not $page_url =~ m/$include_regex/ ) or
      ( defined $exclude_regex and $page_url =~ m/$exclude_regex/ ) and do {
      print STDERR "excluding $page_name\n"
	if $::verbose & 4;
      return;
    };

    # FIXME: dangerous, there could be a link to an external file which
    # means the external file should be included in the infostructure

    my $media=guess_media_type($_);
    ($media =~ /html/) or do {
      print STDERR "ignoring $page_name\n"
	if $::verbose & 4;
      $::ignored{$media}=0 unless defined $::ignored{$media};
      $::ignored{$media}++;
      $::ignored++;
      return;
    };

    my @linklist=();

    print STDERR "acting on $page_name, url $page_url\n"
      if $::verbose & 4;

    my $act_url=make_attrib_func($page_url,\@linklist, %settings);

    my $p = HTML::LinkExtor->new($act_url);

    unless ( eval { $p->parse_file($_) } ) {
      warn $@ ;
      return;
    }

    die "no url??" unless $page_url;
    page_handler($page_url, \@linklist);
  }

}


#Findweb - download pages from the internet
#
#This function starts at a url and works from there through all linked
#pages which are below that page in the URL hirearchy.
#

sub findweb ($%) {
  my $url=shift;
  my %settings=@_;

  my $basere='^' . quotemeta ($url);

  my $work_url;

  #in future this should be parameterisable for each infostructure e.g.
  #do we use robot exclusion rules etc.

  my $tmpfile="/tmp/extract-links.visited.tmp.$$";
  unlink  $tmpfile;
  -e  $tmpfile and die  "failed to remove $tmpfile";

#the visited hash protects us against reading in the same page more
#than once during this infostructure run.  thereby preventing loops.

  tie my %visited, "DB_File", $tmpfile, O_RDWR|O_CREAT, 0666
    or die $!;

  my $ua = new LWP::Auth_UA;

  my $worktmp="/tmp/extract-links.work.tmp.$$";

  open(my $workout, ">$worktmp")
    or die "couldn't open working file $worktmp for writing";
  open(my $workin, "<$worktmp")
    or die "couldn't open working $worktmp file for reading";
  autoflush $workout 1;
  print $workout "$url\n" ;

 PAGE: while (defined($work_url = <$workin>)) {
    chomp $work_url;

    defined $::exclude_regex && $work_url =~ m/$::exclude_regex/ and do {
      print STDERR "skipping $work_url\n" if $::verbose & 4;
      next PAGE;
    };
    print STDERR "looking at $work_url\n" if $::verbose & 4;

    #the following is just an optimisation which means that we don't
    #download pages that we won't process and can be got rid of if you
    #find that pages are being missed.

    unless ( ($work_url =~ m,/$, ) #a directory..
	     or ( guess_media_type($work_url) =~
		  m<html|^application/octet-stream$>
		    #something that's could come out as html
		 )
             )
    {
      print STDERR "non-readable looking url $work_url";
      next PAGE;
    }

    #1 what's the base for this file

    my $rebound=1;

    my %redirect=();

    while ($rebound) {

      if ( $visited{$work_url} ) {
	print STDERR "skipping already visited url: $work_url \n" 
	  if $::verbose & 4;
	next PAGE;
      }

      $visited{$work_url}=1;

      unless ($work_url =~ m/$basere/ ) { # we are trapped in one area.
	warn "out of bounds url $work_url";
	next PAGE;
      }

      print STDERR "going ahead with first visit to url: $work_url \n"
	unless $::silent;

      my $oldurl=$work_url;
      my $request = new HTTP::Request('GET', $work_url);

      my @linklist=();

      my $link_func = make_attrib_func($work_url, \@linklist,
				       work_url_re => $basere,
				       workfile => $workout,
				       %settings,
				      );

      my $extractor = HTML::LinkExtor->new($link_func);

      my $accept_func=chunk_accept_func($extractor);


      print STDERR "making request on $work_url\n" unless $::silent;

      #download and parse .. big chunks becuase should be on local network
      #so can expect fast response

      my $response = $ua->simple_request($request, $accept_func, 8192) ;

      if ($response->is_redirect()) {
	print STDERR "got a redirect ";
	my $where=$response->content_location();
	if ($rebound > 100) {	#who in their right mind?
	  $rebound=0;		#FIXME .. tell server person.
	  print STDERR "too many.. give up\n";
	  next PAGE;
	}
	if ($redirect{$where}) {
	  $rebound=0;		#FIXME .. tell server person.
	  print STDERR "back to where we were before.. give up\n";
	  die "redirect loop found"
	}
	print STDERR "try again\n";
	$redirect{$where}=1;
	$rebound++;
	$work_url = $where;
	die "try again";
      } else {
	$rebound=0;
      }

      # FIXME redirects?

      page_handler($work_url, \@linklist);

      # next PAGE unless $response->is_success() or $oldurl ne $work_url;
    }
  }
  unlink  $tmpfile, $worktmp;
}


sub make_attrib_func ($$%) {
  my $base_url=shift;
  my $link_array=shift;
  my %settings=@_;

  my $fh=$settings{workfile};
  my $urlre=$settings{work_url_re};

  my $include_regex = $settings{link_include_re};
  my $exclude_regex = $settings{link_exclude_re};

  #optional file handle we will print to
  # a closeure with a reference to the linklist which is
  # called repeatedly by the link extractor with the link
  # containing attributes from the page.

  my $act_attrib= sub {
    my($tag, %attr) = @_;

    #this is a closure which uses
    #$page_name
    #$page_record

    my $linkname;
    my $attr;

    #my $linkname=$attr{'href'};
  LINK: while (($attr, $linkname)=each %attr) {
      unless ( $linkname ) {
	warn "Undefined link name generated";
	next LINK;
      }
      print STDERR "extracted link $linkname\n" if
	$::verbose & 8;

      ( defined $include_regex and not $linkname =~ m/$include_regex/ ) or
	( defined $exclude_regex and $linkname =~ m/$exclude_regex/ ) and do {
	print STDERR "excluding link $linkname\n"
	  if $::verbose & 4;
	next LINK;
      };

      my ( $url, $fragment )
	= WWW::Link_Controller::URL::fixup_link_url($linkname,$base_url);

      next unless defined $url;

      push @$link_array, $url;

      link_handler ( $url, fragment => $fragment );

      #this prints the link out for use in or working URL list
      #for or web recursion process.
      print $fh $url . "\n" if defined $fh and $url =~ m/$urlre/;
    }
  }; # END definition of $act_link function
  return $act_attrib
}


sub chunk_accept_func ($){
  my $extractor=shift;
  #my %settings=@_; - no use for now

  #acceptfunc is a closeure with the link extractor which which is
  #called by the user agent with the parts of the page as they
  #are downloaded

  #it then calls the link extractor which in turn calls the $act_url
  #function

  #Redirects etc. are handled by dying immediately.  This is caught by
  #the user agent which then gives it back in the response and never
  #calls us again.

  my $func = sub  {
    my ($chunk, $response, $protocol) = @_;
    printf STDERR "Checking response\n" if $::verbose & 8;
    die "only successes implemented now" unless $response->is_success();
    unless ( $response->content_type =~ m,html$,) {
      print STDERR "Wrong content type. give up.\n";
      die "can only handle html so far" ;
    }
    $extractor->parse($chunk);
  };
  return $func;
}


sub page_handler ($$) {
  my $page_url=shift;
  my $link_list_ref=shift;
  if (@$link_list_ref) {
    print STDERR "adding links in $page_url to index\n"
      if $::verbose & 8;
    $::index->add_list_first($page_url,$link_list_ref);
  }
}

#link_handler should be called for each valid URL found.
#it will output it to the right places etc.

sub link_handler ($%) {
  my $url=shift;


  my %link_info=@_;

  my $fragment=$link_info{fragment};
  print STDERR "ignoring fragment $fragment\n"
    if $::verbose & 16 and defined $fragment;


  $::checklist{$url} && do {
    print STDERR "URL: $url already seen\n"
      if $::verbose & 32;
    return;
  };
  $::checklist{$url} = 1;

  $::write_links && do {
    my $link = $::link_db{$url};

    unless ( defined  $link) {
      print STDERR "URL: $url being added to link database\n"
	if $::verbose & 16;
      $link=WWW::Link->new($url);
    } else {
      print STDERR "URL: $url already in link database\n"
	if $::verbose & 16;
      $link->last_refresh($::start_time);
    }

    $::link_db{$url}=$link;
  };

  print URILIST $url . "\n" if defined $::out_uri_list;
}



#call tree
#
# LWP::UserAgent
# calls the chunk accept function
# which calls the HTML::LinkExtor
# which calls the attrib_func
# which calls link_handler()

# File::Find
# calls the act_on file func
# which calls the HTML::LinkExtor
# which calls the attrib_func
# which calls link_handler()
