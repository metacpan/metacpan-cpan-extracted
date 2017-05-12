#!/usr/bin/perl

=head1 NAME 

check-page - check the links in a single HTML page and report problems

=head1 DESCRIPTION

This program reads an HTML page, from the command line arguments and
reports errors in it.  It gives the line number of the error.  One
useful feature is that the output is in the same format as various
other utilities (such as the gnu ones) which means that your editor
may well be able to understand it and move you to the correct line.

In emacs, you can use this by using the following sequence

   M-x compile RET check-page [filename] RET

Which will check the page and record the errors.  You can then use

   M-`

from within the file you are trying to get to the next error.  For
more information about this see the emacs help on compiling.

=head1 SEE ALSO

L<verify-link-control(1)>; L<extract-links(1)>; L<build-schedule>
L<link-report(1)>; L<fix-link(1)>; L<link-report.cgi(1)>; L<fix-link.cgi>
L<suggest(1)>; L<link-report.cgi(1)>; L<configure-link-control>

The LinkController manual in the distribution in HTML, info, or
postscript formats, included in the distribution.

http://scotclimb.org.uk/software/linkcont/ - the
LinkController homepage.

=cut

use Fcntl;
use DB_File;
use MLDBM qw(DB_File);
use HTML::LinkExtor;
use WWW::Link::Reporter::Compile;

#Configuration - we go through %ENV, so you'd better not be running SUID
#eval to ignore if a file doesn't exist.. e.g. the system config

use WWW::Link_Controller::ReadConf;
use WWW::Link_Controller::InfoStruc;
use WWW::Link_Controller::URL;


##############################################################################
#start command line processing
use Getopt::Function qw(maketrue makevalue);

use vars qw($not_perfect $redirect $since);

$::redirect=0;
$::ignore_missing=0;
$::verbose=0;

$::opthandler = new Getopt::Function 
  [ "version V>version",
    "usage h>usage help>usage",
    "help-opt=s",
    "verbose:i v>verbose",
    "",
    "redirect r>redirect",
    "ignore-missing m>ignore-missing",
    "",
    "link-index=s",
    "link-database=s",
  ],
  {
     "redirect" => [ \&maketrue,
		     "Report links which are redirected." ],
  "ignore-missing" => [ \&maketrue,
		     "Don't complain about links which aren't in database." ],

   "link-index" => [ sub { $::link_index=$::value; },
		     "Use the given file as the index of which file has "
		     . "what link.",
		     "FILENAME" ],
"link-database" => [ sub { $::links=$::value; },
		     "Use the given file as the dbm containing links.",
		     "FILENAME" ],

  };
$::opthandler->std_opts;

$::opthandler->check_opts;

sub usage() {
  print <<EOF;
check-page [options] filename...

EOF
  $::opthandler->list_opts;

  print <<EOF;

Check an HTML page against the information in the link database (\$::links:- 
$::links).
EOF
}

sub version() {
  print <<'EOF';
check-page version 
$Id: check-page.pl,v 1.9 2002/02/03 21:20:41 mikedlr Exp $
EOF
}

##############################################################################
#end command line processing

$::default_infostrucs=1 unless defined $::default_infostrucs;

die "you must define the \$::infostrucs configuration variable"
  if $::default_infostrucs and not defined $::infostrucs ;

WWW::Link_Controller::InfoStruc::default_infostrucs()
  if $::default_infostrucs;

die 'you must define the $::links configuration variable' 
    unless $::links;
$::linkdbm = undef;
$::linkdbm = tie %::links, "MLDBM", $::links, O_RDONLY, 0666, $DB_HASH
  or die $!;

my $reporter = new WWW::Link::Reporter::Compile;
$reporter->all_reports(1);
$reporter->{"report_okay"}=0;


my $base_url=undef;
my $file=undef;
$linkfunc = sub {
  my($tag, %attr) = @_;
LINK: while (my ($attr, $linkname)=each %attr) {
    unless ( $linkname ) {
      warn "Undefined link name generated";
      next LINK;
    }
    my ( $uri, $fragment )
      = WWW::Link_Controller::URL::fixup_link_url($linkname,$base_url);
    defined $uri or do {
      reporter->invalid($linkname);
    };
    print STDERR "examining link $uri\n" if
	$::verbose & 8;
    my $link=$::links{$uri};
    unless (defined $link) {
      $reporter->not_found($uri) unless $::ignore_missing;
      next LINK;
    }
    $reporter->examine($link);
  }
};

#FIXME now wouldn't it be really nice to use an html validator and
#get all of the problems at the same time..

my $p = HTML::LinkExtor->new($linkfunc);

# we force this to work line by line..  This should mean that error
# messages come out at the end of any tag

foreach $file ( @ARGV) {
  print STDERR "file is $file " if $::verbose;
  $reporter->filename($file);
  $base_url=WWW::Link_Controller::InfoStruc::file_to_url($file);
  print STDERR "url is $base_url\n" if $::verbose;
  open IN, $file;
  while (my $line=<IN> ) {
    $p->parse($line);
  }
  close IN ; #reset line numbers
  $p->eof();   #force link extractor to finish
}
