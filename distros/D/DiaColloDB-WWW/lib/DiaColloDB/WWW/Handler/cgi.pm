##-*- Mode: CPerl -*-

## File: DiaColloDB::WWW::Handler::cgi.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description:
##  + DiaColloDB::WWW::Server URI handler for template-toolkit files via cgi
##  + adapted from DTA::CAB::Server::HTTP::Handler::CGI ( svn+ssh://odo.dwds.de/home/svn/dev/DTA-CAB/trunk/CAB/Server/HTTP/Handler/CGI.pm )
##======================================================================

package DiaColloDB::WWW::Handler::cgi;
use DiaColloDB::WWW::Handler;
use HTTP::Status;
use File::Basename qw(basename);
use URI::Escape qw(uri_escape uri_escape_utf8);
use Carp;
use strict;

our @ISA = qw(DiaColloDB::WWW::Handler);

##--------------------------------------------------------------
## Methods

## $h = $class_or_obj->new(%options)
## + %options:
##   (
##    template  => $ttkfile,          ##-- ttk template for instantiation (REQUIRED)
##   )
sub new {
  my $that = shift;
  my $h =  bless {
		  template => undef,
		  @_,
		 }, ref($that)||$that;
  return $h;
}

## $rsp = $h->run($server, $clientConn, $httpRequest)
sub run {
  my ($h,$srv,$csock,$hreq) = @_;

  ##-- load config
  local (%::dstar) = qw();
  {
    package main;
    my ($rcfile);
    if (-r ($rcfile="$srv->{wwwdir}/dstar.rc")) {
      do "$rcfile" or $h->logconfess("run(): failed to load dstar config file '$rcfile': $@");
    }
    if (-r ($rcfile="$srv->{wwwdir}/local.rc")) {
      do "$rcfile" or $h->logconfess("run(): failed to load local config file '$rcfile': $@");
    }
    $::dstar{corpus} ||= $srv->{dburl};
  }

  ##-- setup dbcgi object
  my $dbcgi =  DiaColloDB::WWW::CGI->new(%{$srv->{cgiArgs}//{}})
    or $h->logconfess("could not create DiaColloDB::WWW::CGI object: $!");
  $dbcgi->t_start(); ##-- re-start package-global timer (hack; this should really be object-local)
  $dbcgi->{ttk_vars}{DIACOLLO_DBURL} = $srv->{dburl};
  $dbcgi->{ttk_vars}{dstar}{$_}      = $::dstar{$_} foreach (keys %::dstar);
  $dbcgi->fromRequest($hreq,$csock)
    or $h->logconfess("run(): failed to setup {dbcgi} object from HTTP::Request");

  ##-- run dbcgi template
  my $ttkey = $dbcgi->ttk_key(basename($h->{template}, '.ttk'));
  my $israw = $dbcgi->{ttk_rawkeys}{$ttkey};
  my ($content,$status);
  eval {
    $dbcgi->ttk_process($h->{template}, $dbcgi->vars,
			($israw ? ({ENCODING=>undef},{binmode=>':raw'}) : (undef,undef)),
			\$content);
    $status = RC_OK;
  };
  if ($@) {
    ($status,$content) = (RC_INTERNAL_SERVER_ERROR, join('',$dbcgi->htmlerror(undef,$@)));
  } elsif (!$content) {
    ($status,$content) = (RC_INTERNAL_SERVER_ERROR, join('',$dbcgi->htmlerror(undef,"template '$h->{template}' returned no content")));
  }

  ##-- construct HTTP::Response
  utf8::encode($content) if (utf8::is_utf8($content));
  my ($headers);
  if ($content =~ s/^(.*?)(?:\x{0d}\x{0a}){2}//s) {
    my $headstr = $1;
    $headers = [ map {split(/\s*:\s*/,$_,2)} split(/\x{0d}\x{0a}/,$headstr) ];
  }
  my $rsp = $h->response($status, undef, $headers//[]);
  $rsp->content_ref(\$content);
  return $rsp;
}


## undef = $h->finish($server, $clientSocket)
##  + clean up handler state after run() (dummy, inherited)


1; ##-- be happy

__END__
