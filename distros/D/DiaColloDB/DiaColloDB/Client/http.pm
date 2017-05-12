## -*- Mode: CPerl -*-
## File: DiaColloDB::Client::http.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db: client: remote http server

package DiaColloDB::Client::http;
use DiaColloDB::Client;
use URI;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Request::Common; ##-- for POST()
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(DiaColloDB::Client);

##==============================================================================
## Constructors etc.

## $cli = CLASS_OR_OBJECT->new(%args)
## $cli = CLASS_OR_OBJECT->new($url, %args)
## + %args, object structure:
##   (
##    ##-- DiaColloDB::Client: options
##    url  => $url,       ##-- local url
##    ##
##    ##-- DiaColloDB::Client::http: options
##    user => $user,          ##-- for LWP::UserAgent basic authentication
##    password => $password,  ##-- for LWP::UserAgent basic authentication
##    logRequest => $log,     ##-- log-level for HTTP requests (default:'debug')
##    ##
##    ##-- DiaColloDB::Client::http: guts
##    ua   => $ua,        ##-- underlying LWP::UserAgent
##   )

## %defaults = $CLASS_OR_OBJ->defaults()
##  + called by new()
sub defaults {
  return (
	  logRequest=>'debug',
	 );
}



##==============================================================================
## I/O: open/close

## $cli_or_undef = $cli->open_http($http_url,%opts)
## $cli_or_undef = $cli->open_http()
##  + opens a local file url
##  + may re-bless() $cli into an appropriate package
##  + OVERRIDE in subclasses supporting file urls
sub open_http {
  my ($cli,$url,%opts) = @_;
  $cli = $cli->new() if (!ref($cli));
  $cli->close() if ($cli->opened);
  $url //= $cli->{url};
  my $uri = URI->new($url);
  if ((my $path=$uri->path) !~ m/profile/) {
    $path .= "/" if ($path !~ m{/$});
    $path .= "profile.perl";
    $uri->path($path);
  }
  if ($uri->query) {
    my %qf  = $uri->query_form();
    @$cli{keys %qf} = values %qf;
  }
  $cli->{url}    = $uri->as_string;
  $cli->{ua}   //= LWP::UserAgent->new();
  return $cli;
}

## $cli_or_undef = $cli->close()
##  + default just returns $cli
sub close {
  my $cli = shift;
  $cli->{db}->close() if ($cli->{db});
  return $cli;
}

## $bool = $cli->opened()
##  + default just checks for $cli->{url}
sub opened {
  return ref($_[0]) && $_[0]{ua};
}

##==============================================================================
## Profiling

##--------------------------------------------------------------
## Profiling: Generic: HTTP wrappers

## $obj_or_undef = $cli->jget($url,\%query_form,$class)
##  + wrapper for http json GET requests
sub jget {
  my ($cli,$url,$form,$class) = @_;
  my $uri = URI->new($url // $cli->{url});
  $uri->query_form( {%{$cli->{params}//{}}, %$form} );
  my $req = HTTP::Request->new('GET',"$uri");
  $req->authorization_basic($cli->{user}, $cli->{password}) if (defined($cli->{user}) && defined($cli->{password}));
  $cli->vlog($cli->{logRequest}, "GET $uri");
  my $rsp = $cli->{ua}->request($req);
  if (!$rsp->is_success) {
    $cli->{error} = $rsp->status_line;
    return undef;
  }
  my $cref = $rsp->content_ref;
  return $class->loadJsonString($cref,utf8=>!utf8::is_utf8($$cref));
}

## $obj_or_undef = $cli->jpost($url,\%query_form,$class)
##  + wrapper for json http POST requests
sub jpost {
  my ($cli,$url,$form,$class) = @_;
  $url //= $cli->{url};
  my $req = POST($url, Content => {%{$cli->{params}//{}}, %$form});
  $req->authorization_basic($cli->{user}, $cli->{password}) if (defined($cli->{user}) && defined($cli->{password}));
  $cli->vlog($cli->{logRequest}, "POST $url");
  #$cli->trace("REQUEST = ", $req->as_string);
  my $rsp = $cli->{ua}->request($req);
  if (!$rsp->is_success) {
    $cli->{error} = $rsp->status_line;
    return undef;
  }
  my $cref = $rsp->content_ref;
  return $class->loadJsonString($cref,utf8=>!utf8::is_utf8($$cref));
}

##--------------------------------------------------------------
## dbinfo

## \%info = $cli->dbinfo()
##   + adds 'url' key
sub dbinfo {
  my $cli = shift;
  (my $url = $cli->{url}) =~ s{/profile.*$}{};
  my $info = $cli->jget("$url/info.perl", {},'DiaColloDB::Persistent');
  $info->{url} = "$url/";
  return $info;
}

##--------------------------------------------------------------
## Profiling: Generic

## $mprf_or_undef = $cli->profile($relation, %opts)
##  + get a relation profile for selected items as a DiaColloDB::Profile::Multi object
##  + %opts: as for DiaColloDB::profile()
##  + sets $cli->{error} on error
sub profile {
  my ($cli,$rel,%opts) = @_;
  delete @opts{qw(alemma adate aslice blemma bdate bslice)};
  return $cli->jget($cli->{url}, {profile=>$rel, %opts, format=>'json'},'DiaColloDB::Profile::Multi');
}

##--------------------------------------------------------------
## Profiling: extend (pass-2 for multi-clients)

## $mprf = $cli->extend($relation, %opts)
##  + get an extension-profile for selected items as a DiaColloDB::Profile::Multi object
##  + %opts: as for DiaColloDB::extend()
##  + sets $cli->{error} on error
sub extend {
  my ($cli,$rel,%opts) = @_;
  delete @opts{(qw(alemma adate aslice blemma bdate bslice),
		qw(eps score kbest cutoff global),
		qw(onepass),
	       )};
  return $cli->jpost($cli->{url}, {profile=>"extend-$rel", %opts, format=>'json'},'DiaColloDB::Profile::Multi');
}

##--------------------------------------------------------------
## Profiling: Comparison (diff)

## $mprf = $cli->compare($relation, %opts)
##  + get a relation comparison profile for selected items as a DiaColloDB::Profile::MultiDiff object
##  + %opts: as for DiaColloDB::compare()
sub compare {
  my ($cli,$rel,%opts) = @_;
  return $cli->jget($cli->{url}, {profile=>"d$rel", %opts, format=>'json'},'DiaColloDB::Profile::MultiDiff');
}

##==============================================================================
## Footer
1;

__END__




