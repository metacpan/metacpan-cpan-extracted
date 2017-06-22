##-*- Mode: CPerl; coding: utf-8; -*-
##
## File: DiaColloDB/WWW/CGI.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, www wrappers: (f)cgi handler
##  + adapted from DbCgi.pm ( svn+ssh://odo.dwds.de/home/svn/dev/dbcgi/trunk/DbCgi.pm )

package DiaColloDB::WWW::CGI;
use DiaColloDB;
use DiaColloDB::Logger;
use CGI qw(:standard :cgi-lib);
use URI;
use URI::Escape qw(uri_escape_utf8);
use HTTP::Status;
use Encode qw(); #qw(encode decode encode_utf8 decode_utf8);
use File::Basename qw(basename dirname);
use File::ShareDir qw(); ##-- for shared template data
use Cwd qw(getcwd abs_path);
#use LWP::UserAgent;
use Template;
use JSON qw();
use Time::HiRes qw();
use utf8;
use Carp;
use strict;

BEGIN {
  #binmode(STDIN, ':utf8');
  #binmode(STDOUT,':utf8');
  binmode(STDERR,':utf8');
}

*isa = \&UNIVERSAL::isa;
*can = \&UNIVERSAL::can;

##======================================================================
## globals

our $VERSION = "0.02.002";
our @ISA  = qw(DiaColloDB::Logger);

##======================================================================
## constructors etc.

## $dbcgi = $that->new(%args)
##  + %args, object structure:
##    (
##     ##-- basic stuff
##     prog => basename($0),
##     ##
##     ##-- underlying CGI module
##     cgipkg => 'CGI',
##     ##
##     ##-- CGI params
##     defaults => {},
##     vars     => undef,
##     charset  => 'utf-8',
##     nodecode => {}, ##-- vars not to decode
##     ##
##     ##-- CGI environment stuff : see getenv() method
##     remote_addr => undef,
##     remote_user => undef,
##     request_method => undef,
##     request_uri => undef,
##     request_query => undef,
##     http_referer => undef,
##     http_host    => undef,
##     server_addr  => undef,
##     server_port  => undef,
##     ##
##     ##-- template toolkit stuff
##     ttk_package => (ref($that)||$that),
##     ttk_vars    => {},			##-- template vars
##     ttk_config  => {ENCODING=>'utf8'},	##-- options for Template->new()
##     ttk_process => {binmode=>':utf8'},	##-- options for Template->process()
##     ttk_dir     => abs_path(dirname($0)),
##     ttk_key     => undef,		##-- current template basename
##     ttk_rawkeys => {			##-- pseudo-set of raw keys
##     profile=>1,
##     },
##     ##
##     ##-- File::ShareDir stuff (fallbacks for ttk_dir)
##     ttk_sharedir => File::ShareDir::dist_dir("DiaColloDB-WWW")."/htdocs",
##    )
sub new {
  my $that = shift;
  my $dbcgi = bless({
		     ##-- basic stuff
		     prog => basename($0),
		     ##
		     ##-- underlying CGI module
		     cgipkg => 'CGI',
		     ##
		     ##-- CGI params
		     defaults => {},
		     vars     => undef,
		     charset  => 'utf-8',
		     nodecode => {}, ##-- vars not to decode
		     ##
		     ##-- CGI environment stuff : see getenv() method
		     remote_addr => undef,
		     remote_user => undef,
		     request_method => undef,
		     request_uri => undef,
		     request_query => undef,
		     http_referer => undef,
		     http_host    => undef,
		     server_addr  => undef,
		     server_port  => undef,
		     ##
		     ##-- template toolkit stuff
		     ttk_package => (ref($that)||$that),
		     ttk_vars    => {},			##-- template vars
		     ttk_config  => {ENCODING=>'utf8'},	##-- options for Template->new()
		     ttk_process => {binmode=>':utf8'},	##-- options for Template->process()
		     ttk_dir     => abs_path(dirname($0)),
		     ttk_key     => undef,		##-- current template basename
		     ttk_rawkeys => {			##-- pseudo-set of raw keys
				     profile=>1,
				    },
		     ##
		     ##-- File::ShareDir stuff (fallbacks for ttk_dir)
		     ttk_sharedir => File::ShareDir::dist_dir("DiaColloDB-WWW")."/htdocs",
		     ##
		     ##-- user args
		     @_,
		    }, ref($that)||$that);

  ##-- CGI package
  if ($dbcgi->{cgipkg}) {
    eval "use $dbcgi->{cgipkg} qw(:standard :cgi-lib);";
    $dbcgi->logconfess("new(): could not use {cgipkg} $dbcgi->{cgipkg}: $@") if ($@);
  }

  ##-- environment defaults
  $dbcgi->_getenv();

  return $dbcgi;
}

## @keys = $dbcgi->_param()
## $val  = $dbcgi->_param($name)
sub _param {
  my $dbcgi = shift;
  return $dbcgi->cgi('param',@_);
}

## $dbcgi = $dbcgi->_reset()
##  + resets CGI environment
sub _reset {
  my $dbcgi = shift;
  delete @$dbcgi{(qw(vars),
		qw(remote_addr remote_user),
		qw(request_method request_uri request_query),
		qw(http_referer http_host server_addr server_port),
	       )};
  return $dbcgi;
}

## $dbcgi = $dbcgi->_getenv()
sub _getenv {
  my $dbcgi = shift;
  $dbcgi->{remote_addr} = ($ENV{REMOTE_ADDR}||'0.0.0.0');
  $dbcgi->{remote_user} = ($ENV{REMOTE_USER} || getpwuid($>));
  $dbcgi->{request_method} = ($ENV{REQUEST_METHOD}||'GET');
  $dbcgi->{request_uri} = ($ENV{REQUEST_URI} || $0);
  $dbcgi->{request_query} = $ENV{QUERY_STRING};
  $dbcgi->{http_referer} = $ENV{HTTP_REFERER};
  $dbcgi->{http_host} = $ENV{HTTP_HOST};
  $dbcgi->{server_addr} = $ENV{SERVER_ADDR};
  $dbcgi->{server_port} = $ENV{SERVER_PORT};
  return $dbcgi;
}

## $dbcgi = $dbcgi->fromRequest($httpRequest,$csock)
##  + sets up $dbcgi from an HTTP::Request object
sub fromRequest {
  my ($dbcgi,$hreq,$csock) = @_;

  ##-- setup pseudo-environment
  my $uri = $hreq->uri;
  my @path = grep {$_ ne ''} $uri->path_segments;
  $dbcgi->{prog}        = $path[$#path] || 'index';
  $dbcgi->{remote_addr} = $ENV{REMOTE_ADDR} = $csock ? $csock->peerhost : '0.0.0.0';
  $dbcgi->{remote_port} = $ENV{REMOTE_PORT} = $csock ? $csock->peerport : '0';
  $dbcgi->{remote_user} = $ENV{REMOTE_USER} = '';
  $dbcgi->{request_method} = $ENV{REQUEST_METHOD} = $hreq->method;
  $dbcgi->{request_uri}   = $ENV{REQUEST_URI} = $uri->as_string;
  $dbcgi->{request_query} = $ENV{REQUEST_QUERY} = $uri->query;
  $dbcgi->{http_referer}  = $ENV{HTTP_REFERER} = $hreq->referer;
  $dbcgi->{http_host}   = $ENV{HTTP_HOST} = $uri->host || $csock->sockhost;
  $dbcgi->{server_addr} = $ENV{SERVER_ADDR} = $csock ? $csock->sockaddr : '0.0.0.0';
  $dbcgi->{server_port} = $ENV{SERVER_PORT} = $csock ? $csock->sockport : '0';

  ##-- setup variables
  my %vars = $uri->query_form;
  my $addVars = sub {
    my $add = shift;
    foreach (grep {defined $add->{$_}} keys %$add) {
      if (!exists($vars{$_})) {
	$vars{$_} = $add->{$_};
      } else {
	$vars{$_} = [ $vars{$_} ] if (!ref($vars{$_}));
	push(@{$vars{$_}}, ref($add->{$_}) ? @{$add->{$_}} : $add->{$_});
      }
    }
  };
  if ($hreq->method eq 'POST') {
    if ($hreq->content_type eq 'application/x-www-form-urlencoded') {
      ##-- POST: x-www-form-urlencoded
      $addVars->( {URI->new('?'.$hreq->content)->query_form} );
    }
    elsif ($hreq->content_type eq 'multipart/form-data') {
      ##-- POST: multipart/form-data: parse by hand
      foreach my $part ($hreq->parts) {
	my $pdis = $part->header('Content-Disposition');
	if ($pdis =~ /^form-data\b/) {
	  ##-- POST: multipart/form-data: part: form-data; name="PARAMNAME"
	  if ($pdis =~ /\bname=[\"\']?([\w\-\.\,\+]*)[\'\"]?/) {
	    $addVars->({ $1 => $part->content });
	    next;
	  }
	}
	##-- POST: multipart/form-data: part: anything other than 'form-data; name="PARAMNAME"'
	$addVars->({ POSTDATA => $part->content });
      }
    }
    elsif ($hreq->content_length > 0) {
      ##-- POST: anything else: use POSTDATA
      $addVars->({ POSTDATA => $hreq->content });
    }
  }
  $dbcgi->vars(\%vars);

  return $dbcgi;
}


## \%vars = $dbcgi->vars()
## \%vars = $dbcgi->vars(\%vars)
##   + get/set CGI variables, instantiating $dbcgi->{defaults} if present
sub vars {
  my ($dbcgi,$vars) = @_;
  return $dbcgi->{vars} if (defined($dbcgi->{vars}) && !defined($vars));
  $vars ||= $dbcgi->cgi('param') ? { %{$dbcgi->cgi('Vars')} } : {};

  if (($dbcgi->{cgipkg}//'CGI') ne 'CGI' || defined($vars->{POSTDATA})) {
    ##-- parse params from query string; required e.g. for CGI::Fast or non-form POST requests (which set POSTDATA)
    my $uri  = URI->new($dbcgi->{request_uri});
    my %urif = $uri->query_form();
    @$vars{keys %urif} = values %urif;
  }

  foreach (grep {!exists($vars->{$_}) && defined($dbcgi->{defaults}{$_})} keys %{$dbcgi->{defaults}||{}}) {
    ##-- defaults
    $vars->{$_} = $dbcgi->{defaults}{$_}
  }
  my ($tmp);
  foreach (keys %$vars) {
    ##-- decode (annoying temporary variable hack hopefully ensures that utf8 flag is set!)
    $tmp = $vars->{$_};
    $tmp =~ s/\x{0}/ /g;
    if ($dbcgi->{charset} && !utf8::is_utf8($tmp) && !exists($dbcgi->{nodecode}{$_})) {
      $tmp = Encode::decode($dbcgi->{charset},$tmp);
      #$dbcgi->trace("decode var '$_':\n+ OLD=$vars->{$_}\n+ NEW=$tmp\n");
      $vars->{$_} = $tmp;
    }
  }
  return $dbcgi->{vars} = $vars;
}

##======================================================================
## config loading (optional)

## $dbcgi = $dbcgi->load_config($filename)
##  + clobers %$dbcgi keys from JSON filename
sub load_config {
  my ($dbcgi,$file) = @_;
  open(RC,"<:raw",$file)
    or $dbcgi->logconfess("load_config(): failed for '$file': $!");
  local $/ = undef;
  my $buf = <RC>;
  close RC
    or $dbcgi->logconfess("load_config(): close failed for '$file': $!");
  my $data = JSON::from_json($buf,{utf8=>1,relaxed=>1})
    or $dbcgi->logconfess("load_config(): from_json() failed for config data from '$file': $!");
  @$dbcgi{keys %$data} = values %$data;
  return $dbcgi;
}

##======================================================================
## Template Toolkit stuff

## $key = $dbcgi->ttk_key($key)
## $key = $dbcgi->ttk_key()
##  + returns current template key
##  + default is basename($dbcgi->{prog}) without final extension
sub ttk_key {
  my ($dbcgi,$key) = @_;
  ($key=basename($dbcgi->{prog})) =~ s/\.[^\.]*\z// if (!$key);
  return $key;
}

## @paths = $dbcgi->ttk_include()
## $paths = $dbcgi->ttk_include()
##  + returns ttk search path @$dbcgi->{qw(ttk_dir ttk_sharedir)}
##  + in scalar context returns ":"-separated list
sub ttk_include {
  my $dbcgi = shift;
  my @dirs = map {s/\/+\z//; abs_path($_)} grep {defined($_) && $_ ne ''} @$dbcgi{qw(ttk_dir ttk_sharedir)};
  return wantarray ? @dirs : join(":",@dirs);
}

## $file = $dbcgi->ttk_file()
## $file = $dbcgi->ttk_file($key)
##  + returns template filename for template key (basename) $key
##  + $key defaults to $dbcgi->{prog} without final extension
##  + searches in $dbcgi->{ttk_dir} or $dbcgi->{ttk_sharedir}
sub ttk_file {
  my ($dbcgi,$key) = @_;
  (my $dir  = $dbcgi->{ttk_dir} || '.') =~ s/\/+\z//;
  $key      = $dbcgi->ttk_key($key);
  my $file  = "$key.ttk";
  my @dirs  = $dbcgi->ttk_include();
  foreach (@dirs) {
    return "$_/$file" if (-f "$_/$file");
  }
  $dbcgi->logconfess("ttk_file(): could not find template file '$file' in ttk search path ".$dbcgi->ttk_include);
}

## $t = $dbcgi->ttk_template(\%templateConfigArgs)
##  + returns a new Template object with default args set
sub ttk_template {
  my ($dbcgi,$targs) = @_;
  my $t = Template->new(
			INTERPOLATE=>1,
			PRE_CHOMP=>0,
			POST_CHOMP=>1,
			EVAL_PERL=>1,
			ABSOLUTE=>1,
			RELATIVE=>1,
			INCLUDE_PATH =>scalar($dbcgi->ttk_include),
			%{$dbcgi->{ttk_config}||{}},
			%{$targs||{}},
		       );
  return $t;
}

## $data  = $dbcgi->ttk_process($srcFile, \%templateVars, \%templateConfigArgs, \%templateProcessArgs)
## $dbcgi = $dbcgi->ttk_process($srcFile, \%templateVars, \%templateConfigArgs, \%templateProcessArgs, $outfh)
## $dbcgi = $dbcgi->ttk_process($srcFile, \%templateVars, \%templateConfigArgs, \%templateProcessArgs, \$outbuf)
##  + process a template $srcFile, returns generated $data
sub ttk_process {
  my ($dbcgi,$src,$tvars,$targs,$pargs,$output) = @_;
  my $outbuf = '';
  my $t = $dbcgi->ttk_template($targs);
  $t->process($src,
	      {package=>$dbcgi->{ttk_package}, version=>$VERSION, ENV=>{%ENV}, %{$dbcgi->{ttk_vars}||{}}, cdb=>$dbcgi, %{$tvars||{}}},
	      (defined($output) ? $output : \$outbuf),
	      %{$dbcgi->{ttk_process}||{}},
	      %{$pargs||{}},
	     )
    or $dbcgi->logconfess("ttk_process(): template error: ".$t->error);
  return defined($output) ? $dbcgi : $outbuf;
}

##======================================================================
## CGI stuff: generic

## @error = $dbcgi->htmlerror($status,@message)
##  + returns a print()-able HTML error
sub htmlerror {
  my ($dbcgi,$status,@msg) = @_;
  $status = 500 if (!defined($status)); ##-- RC_INTERNAL_SERVER_ERROR
  my $title = 'Error: '.$status.' '.status_message($status);
  charset($dbcgi->{charset});
  my $msg = join(($,//''), @msg);
  $msg =~ s/\beval\s*\'(?:\\.|[^\'])*\'/eval '...'/sg; ##-- suppress long eval '...' messsages
  return
    (header(-status=>$status),
     start_html($title),
     h1($title),
     pre("\n",escapeHTML($msg),"\n"),
     end_html,
    );
}

## @whatever = $dbcgi->cgi($method, @args)
##  + call a method from the CGI package $dbcgi->{cgipkg}->can($method)
sub cgi {
  my ($dbcgi,$method)=splice(@_,0,2);
  CGI::charset($dbcgi->{charset}) if ($dbcgi->{charset});
  my ($sub);
  if (ref($method)) {
    return $method->(@_);
  }
  elsif ($sub=$dbcgi->{cgipkg}->can($method)) {
    return $sub->(@_);
  }
  elsif ($sub=CGI->can($method)) {
    return $sub->(@_);
  }
  $dbcgi->logconfess("cgi(): unknown method '$method' for cgipkg='$dbcgi->{cgipkg}'");
}

## undef = $dbcgi->cgi_main()
## undef = $dbcgi->cgi_main($ttk_key)
##  + wraps a template-instantiation for $ttk_key, by default basename($0)
sub cgi_main {
  my ($dbcgi,$key) = @_;
  my @content;
  my $israw = $dbcgi->{ttk_rawkeys}{$dbcgi->ttk_key($key)};
  eval {
    @content = $dbcgi->ttk_process($dbcgi->ttk_file($key), $dbcgi->vars, ($israw ? {ENCODING=>undef} : undef), ($israw ? {binmode=>':raw'} : undef));
  };
  if ($@) {
    $israw   = 0;
    @content = $dbcgi->htmlerror(undef, $@);
  }
  elsif (!@content || !defined($content[0])) {
    $israw   = 0;
    @content = $dbcgi->htmlerror(undef, "template '$key' returned no content");
  }

  if ($dbcgi->{charset}) {
    charset($dbcgi->{charset});
    binmode(\*STDOUT, ($israw ? ":raw" : ":encoding($dbcgi->{charset})"));
  }
  print @content;
}

## undef = $dbcgi->fcgi_main()
## undef = $dbcgi->fcgi_main($ttk_key)
##  + wraps a template-instantiation for $ttk_key, by default basename($0)
sub fcgi_main {
  my ($dbcgi,$key) = @_;
  require CGI::Fast;
  CGI::Fast->import(':standard');
  $dbcgi->{cgipkg} = 'CGI::Fast';
  while (CGI::Fast->new()) {
    $dbcgi->_getenv();
    $dbcgi->cgi_main($key);
    $dbcgi->_reset();
  }
}

##======================================================================
## Template stuff: useful aliases

sub remoteAddr { return $_[0]{remote_addr}; }
sub remoteUser { return $_[0]{remote_user}; }
sub requestMethod { return $_[0]{request_method}; }
sub requestUri { return $_[0]{request_uri}; }
sub requestQuery { return $_[0]{request_query}; }
sub httpReferer { return $_[0]{http_referer}; }
sub httpHost { return $_[0]{http_host}; }
sub serverAddr { return $_[0]{server_addr}; }
sub serverPort { return $_[0]{server_port} || ($ENV{HTTPS} ? 443 : 80); }

## $uri    = $dbcgi->uri()
## $uri    = $dbcgi->uri($uri)
sub uri {
  return URI->new($_[1]) if (defined $_[1]);
  my $dbcgi = shift;
  my $host = $dbcgi->httpHost // '';
  my $port = $dbcgi->serverPort;
  my $scheme = ($ENV{HTTPS} ? 'https' : 'http');
  return URI->new(
		  #($host ? "http://$host" : "file://")
		  ($host ? "${scheme}://$host" : "file://") ##-- guess scheme from HTTPS environment variable
		  .($port==($scheme eq 'https' ? 443 : 80) ? '' : ":$port")
		  .$dbcgi->requestUri
		 );
}

## $scheme = $dbcgi->uriScheme($uri?)
## $opaque = $dbcgi->uriOpaque($uri?)
## $path   = $dbcgi->uriPath($uri?)
## $frag   = $dbcgi->uriFragment($uri?)
## $canon  = $dbcgi->uriCanonical($uri?)
## $abs    = $dbcgi->uriAbs($uri?);
sub uriScheme { $_[0]->uri($_[1])->scheme; }
sub uriPath { $_[0]->uri($_[1])->path; }
sub uriFragment { $_[0]->uri($_[1])->fragment; }
sub uriCanonical { $_[0]->uri($_[1])->canonical->as_string; }
sub uriAbs { $_[0]->uri($_[1])->abs->as_string; }

## $dir = $dbcgi->uriDir($uri?)
sub uriDir {
  my $uri = $_[0]->uri($_[1])->as_string;
  $uri =~ s{[?#].*$}{};
  $uri =~ s{/+[^/]*$}{};
  return $uri;
}

## $auth   = $dbcgi->uriAuthority($uri?)
## $pquery = $dbcgi->uriPathQuery($uri?)
## \@segs   = $dbcgi->uriPathSegments($uri?)
## $query  = $dbcgi->uriQuery($uri?)
## \%form  = $dbcgi->uriQueryForm($uri?)
## \@kws    = $dbcgi->uriQueryKeywords($uri?)
sub uriAuthority { $_[0]->uri($_[1])->authority; }
sub uriPathQuery { $_[0]->uri($_[1])->path_query; }
sub uriPathSegments { [$_[0]->uri($_[1])->path_segments]; }
sub uriQuery { $_[0]->uri($_[1])->query; }
sub uriQueryForm { {$_[0]->uri($_[1])->query_form}; }
sub uriQueryKeywords { [$_[0]->uri($_[1])->query_keywords]; }

## $userinfo = $dbcgi->uriUserInfo($uri?)
## $host     = $dbcgi->uriHost($uri?)
## $port     = $dbcgi->uriPort($uri?)
sub userinfo { $_[0]->uri($_[1])->userinfo; }
sub uriHost { $_[0]->uri($_[1])->host; }
sub uriPort { $_[0]->uri($_[1])->port; }

## $uristr = quri($base, \%form)
sub quri {
  shift if (isa($_[0],__PACKAGE__));
  my ($base,$form)=@_;
  my $uri=URI->new($base);
  $uri->query_form($uri->query_form, map {utf8::is_utf8($_) ? Encode::encode_utf8($_) : $_} %{$form||{}});
  return $uri->as_string;
}

## $urisub = uuri($base, \%form)
## $uristr = $urisub->(\%form)
sub uuri {
  shift if (isa($_[0],__PACKAGE__));
  my $qbase = quri(@_);
  return sub { quri($qbase,@_); };
}

## $sqstring = sqstring($str)
sub sqstring {
  shift if (isa($_[0],__PACKAGE__));
  (my $s=shift) =~ s/([\\\'])/\\$1/g; "'$s'"
}

## $str = sprintf_(...)
sub sprintf_ {
  shift if (isa($_[0],__PACKAGE__));
  return CORE::sprintf($_[0],@_[1..$#_]);
}

## $mtime = $dbcgi->mtime($filename)
sub mtime {
  my $dbcgi = shift;
  my $file = shift;
  $file =~ s/^.*?=(\w+).*$/$1/ if ($file =~ /^dbi:/); ##-- trim dsns
  my @stat = stat($file);
  return $stat[9];
}

## $str = $dbcgi->timestamp()
##  + gets localtime timestamp
sub timestamp {
  #my $dbcgi = shift;
  return POSIX::strftime('%Y-%m-%d %H:%M:%S', localtime());
}

## $json_str = PACKAGE->to_json($data)
## $json_str = PACKAGE::to_json($data)
## $json_str = PACKAGE->to_json($data,\%opts)
## $json_str = PACKAGE::to_json($data,\%opts)
sub to_json {
  shift if (isa($_[0],__PACKAGE__));
  return JSON::to_json($_[0]) if (@_==1);
  return JSON::to_json($_[0],$_[1]);
}

## $json_str = PACKAGE->from_json($data)
## $json_str = PACKAGE::from_json($data)
sub from_json {
  shift if (isa($_[0],__PACKAGE__));
  return JSON::from_json(@_);
}

## \@timeofday = PACKAGE->gettimeofday()
## \@timeofday = PACKAGE::gettimeofday()
sub gettimeofday {
  shift if (isa($_[0],__PACKAGE__));
  return [Time::HiRes::gettimeofday()];
}

## $secs = PACKAGE->tv_interval($t0,$t1)
## $secs = PACKAGE::tv_interval($t0,$t1)
sub tv_interval {
  shift if (isa($_[0],__PACKAGE__));
  return Time::HiRes::tv_interval(@_);
}

## \@timeofday = PACKAGE->t_start()
## \@timeofday = PACKAGE->t_start()
##  + sets package variable $t_started
our $t_started = [Time::HiRes::gettimeofday];
sub t_start {
  shift if (isa($_[0],__PACKAGE__));
  $t_started = [Time::HiRes::gettimeofday];
}

## $secs = PACKAGE->t_elapsed()
## $secs = PACKAGE->t_elapsed($t1)
## $secs = PACKAGE->t_elapsed($t0,$t1)
## $secs = PACKAGE::t_elapsed()
## $secs = PACKAGE::t_elapsed($t1)
## $secs = PACKAGE::t_elapsed($t0,$t1)
sub t_elapsed {
  shift if (isa($_[0],__PACKAGE__));
  my ($t0,$t1) = @_;
  return tv_interval($t_started,[Time::HiRes::gettimeofday]) if (!@_);
  return tv_interval($t_started,$_[0]) if (@_==1);
  return tv_interval($_[0],$_[1]);
}

## $enc = PACKAGE->encode_utf8($str, $force=0)
## $enc = PACKAGE::encode_utf8($str, $force=0)
##  + encodes only if $force is true or if not already flagged as a byte-string
sub encode_utf8 {
  shift if (isa($_[0],__PACKAGE__));
  return $_[0] if (!$_[1] && !utf8::is_utf8($_[0]));
  return Encode::encode_utf8($_[0]);
}

## $enc = PACKAGE->decode_utf8($str, $force=0)
## $enc = PACKAGE::decode_utf8($str, $force=0)
##  + decodes only if $force is true or if not flagged as a byte-string
sub decode_utf8 {
  shift if (isa($_[0],__PACKAGE__));
  return $_[0] if (!$_[1] && utf8::is_utf8($_[0]));
  return Encode::decode_utf8($_[0]);
}

1; ##-- be happy

__END__
