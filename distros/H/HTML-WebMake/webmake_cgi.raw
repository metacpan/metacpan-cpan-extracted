#!/usr/bin/perl -w

# ---------------------------------------------------------------------------

# set this to the directory under which WebMake can edit files.
# $FILE_BASE = '/home/jm/public_html';
$FILE_BASE = '/home/jm/ftp/wmtest';

# set this, if WebMake is not installed in the std locations.
$WEBMAKE = '/home/jm/ftp/webmake';

# set this to use CVS. Alternatively, do a "cvs login" and a "cvs checkout"
# in the $FILE_BASE directory beforehand and this will be picked up.
# $CVSROOT = '/local/cvs/public_html';	# local cvs dir

# need to fix the path to include the "cvs" binary? do it here
$ENV{'PATH'} .= ":/usr/local/bin";
$ENV{'CVS_RSH'} = 'ssh';

# ---------------------------------------------------------------------------

if (defined $WEBMAKE) {
  push (@INC, "$WEBMAKE/lib"); push (@INC, "$WEBMAKE/site_perl");
}
if (defined $CVSROOT) { $ENV{'CVSROOT'} = $CVSROOT; }

use CGI qw(-private_tempfiles);
use CGI::Carp 'fatalsToBrowser';
$CGI::POST_MAX = 1024*1024*2;

require HTML::WebMake::CGI::Edit;
require HTML::WebMake::CGI::Del;
require HTML::WebMake::CGI::Dir;
require HTML::WebMake::CGI::Site;
require HTML::WebMake::CGI::FindWmkf;

my $q = new CGI();

my $handler;
if ($q->cgi_error()) {
  print header(-status=>cgi_error()); exit;
}

# replace __HOST__ with the URL's hostname in FILE_BASE if present.
# This allows multiple sites to be edited with only one script, as
# long as they all ScriptAlias the same directory.
if ($FILE_BASE =~ /__HOST__/) {
  my $myurl = $q->url();
  if ($myurl !~ m,^[a-zA-Z0-9]+://([^/]+)/,) {
    die "no hostname in URL";
  }

  my $host = $1; $host =~ s/:\d+$//;
  $FILE_BASE =~ s/__HOST__/${host}/g;
}

if (!$q->param('wmkf')) {
  $handler = new HTML::WebMake::CGI::FindWmkf($q);
} elsif (defined ($q->param('edit'))) {
  $handler = new HTML::WebMake::CGI::Edit($q);
} elsif (defined ($q->param('del'))) {
  $handler = new HTML::WebMake::CGI::Del($q);
} elsif (defined ($q->param('site'))
	|| defined ($q->param('Update'))
	|| defined ($q->param('Commit'))
	|| defined ($q->param('build')))
{
  $handler = new HTML::WebMake::CGI::Site($q);
} else {
  $handler = new HTML::WebMake::CGI::Dir($q);
}

$handler->set_file_base($FILE_BASE);
$handler->run();
# my $path = $q->path_info();
exit;
