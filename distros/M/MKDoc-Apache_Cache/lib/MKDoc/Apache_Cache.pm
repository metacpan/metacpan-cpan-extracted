package MKDoc::Apache_Cache::Capture;
use base qw /Apache::RegistryNG Apache/;
use bytes;

sub new
{
    my ($class, $r) = @_;
    $r ||= Apache->request();
    
    tie *STDOUT, $class, $r;
    return tied *STDOUT;
}


sub print
{
    my $self = shift;
    $self->{_data} ||= '';
    $self->{_data} .= join ('', @_);
}


sub data
{
    my $self = shift;
    return $self->{_data}; 
}


sub TIEHANDLE
{
    my ($class, $r) = @_;
    return bless { r => $r, _r => $r, _data => undef }, $class;
}


sub PRINT
{
    shift->print (@_);
}


package MKDoc::Apache_Cache;
use base qw /Apache::RegistryNG/;
use strict;
use warnings;
use Apache;
use Apache::Constants;
use MKDoc::Control_List;
use Cache::FileCache;
use File::Spec;
use vars qw /$Request/;
use CGI;
use Compress::Zlib;
use Digest::MD5;

our $VERSION = '0.71';


sub handler ($$)
{
    my ($class, $r) = (@_ >= 2) ? (shift, shift) : (__PACKAGE__, shift);
    
    # Makes $MKDoc::Apache_Cache::Request available
    local $Request = $r;
    
    my @args = do {
        no warnings;
        no strict;
        ( $class->_control_list_process() );
    };

    my ($ret, $data) = $class->_do_cached (@args);

    # bug:
    # 200 at /usr/local/lib/perl5/site_perl/5.8.0/MKDoc/Apache_Cache.pm line 66.
    # Status: 404 Not Found
    # Content-Type: text/html
    # =======================
    # this is the bugfix
    $data ||= '';
    my ($n_ret) = $data =~ /Status\:\s+(\d+)/;
    $n_ret ||= $ret;

    # if the client doesn't support gzip, fix the headers,
    # ungzip && send.
    $ENV{HTTP_ACCEPT_ENCODING} ||= '';
    lc $ENV{'HTTP_ACCEPT_ENCODING'} !~ /gzip/ and do {

        my ($headers, $body) = split /\r?\n\r?\n/, $data, 2;
        $body ||= '';
        $headers = join "\r\n",
                   grep !/content-length\:/i,
                   grep !/content-encoding\:/i,
                   grep !/vary\:/i,
                   split /\r?\n/, $headers;
        $body = Compress::Zlib::memGunzip ($body);
        $headers .= "\r\nContent-Length: " . length ($body) if ($body);
        $data = $headers . "\r\n\r\n" . $body;
    };

    $ENV{REQUEST_METHOD} =~ /HEAD/i and do {
        $data =~ s/\r?\ncontent-length\:.*//i;
        $data =~ s/\r?\netag\:.*//i;
    };

    $r->print ($data);
    return $n_ret;
}


sub _do_cached
{
    my $class      = shift;
    
    my $timeout    = shift || return $class->_do_request();
    my $identifier = shift || $class->_default_identifier();

    $timeout = _expiration_time ($timeout);
    
    my $cache_obj  = $class->_cache_object();
    my $cached     = $cache_obj->get ($identifier) || do {

	my ($ret, $data) = $class->_do_request();

        # don't cache unless the return code is 200
        return ($ret, $data) unless ($ret == 200);

        # cookies usually mean non cacheable content
        return ($ret, $data) if ($data =~ /\nSet-Cookie:.+/);

        # add expires: header to be stored in the cached file
        my $expires = _http_date ($timeout + time());
        $data =~ s/\r?\n\r?\n/\r\nExpires: $expires\r\n\r\n/;

        $cache_obj->set ($identifier, "$ret\n$data", $timeout);
	"$ret\n$data";
    };
   
    return split /\n/, $cached, 2;
}


sub _do_request
{
    my $class  = shift;
    my $fake_r = MKDoc::Apache_Cache::Capture->new ($Request);
    my $ret    = $class->SUPER::handler ($fake_r);
    return ($ret, _make_cache_friendly ($fake_r->data()));
}


sub _default_identifier
{
    my $class = shift;
    return "$ENV{REQUEST_METHOD}:" . CGI->new()->self_url();
}


sub _control_list_process
{
    my $class = shift;
    my $key   = 'MKDoc_Apache_Cache_CONFIG';
    my $file  = Apache->request->dir_config ($key) || $ENV{$key} || '/etc/mkdoc-apache-cache.conf';
    -e $file && -f $file || do {
	warn "Cannot stat $file - skipping";
	return ();
    };
    
    my $ctrl  = new MKDoc::Control_List ( file => $file );
    return $ctrl->process();
}


sub _cache_object
{
    my $class = shift;
    my %args  = ();
    
    $class->_cache_object_option ('namespace', \%args);
    $class->_cache_object_option ('default_expires_in', \%args);
    $class->_cache_object_option ('auto_purge_interval', \%args);
    $class->_cache_object_option ('auto_purge_on_set', \%args);
    $class->_cache_object_option ('auto_purge_on_get', \%args);
    $class->_cache_object_option ('cache_root', \%args);
    $class->_cache_object_option ('cache_depth', \%args);
    $class->_cache_object_option ('directory_umask', \%args);
    
    return new Cache::FileCache ( \%args );
}


sub _cache_object_option
{
    my $self = shift;
    my $opt  = shift;
    my $args = shift;
    my $key  = 'MKDoc_Apache_Cache_' . uc ($opt);
    my $val  = Apache->request->dir_config ($key) || $ENV{$key};
    $key eq 'MKDoc_Apache_Cache_CACHE_ROOT' and do { $val ||= File::Spec->tmpdir() };

    defined $val and do { $args->{$opt} = $val };
}


# borrowed from http://www.mnot.net/cgi_buffer/ 
# --------------------------------------------------------------------------------
# (c) 2000 Copyright Mark Nottingham
# <mnot@pobox.com>
#
# This software may be freely distributed, modified and used,
# provided that this copyright notice remain intact.
#
# This software is provided 'as is' without warranty of any kind.
#
# Note from JM: This has been heavily modified from the original, which uses
# deprecated libs, doesn't compile under 'use strict', and doesn't care about
# unicode.
sub _make_cache_friendly
{
    my $buf = shift;
    $buf ||= '';
    my ($headers, $body) = split /\r?\n\r?\n/, $buf, 2;
    $headers ||= '';
    $body ||= '';
    my @o = ();

    # Figure out some kind of content_type
    my ($content_type) = grep /^content-type\:/i, split (/\r?\n/, $headers);
    $content_type ||= 'application/octet-stream';

    # Gzip body if content type probably needs gzipping
 
    # Vary: Accept-Encoding is here to tell proxies to keep a separate
    # cache for every different Accept-Encoding that is being sent.
    $content_type !~ /zip/ and $content_type =~ /(text|xml)/ and do {
        $body = Compress::Zlib::memGzip ($body);
        push @o, "Content-Encoding: gzip";
        push @o, "Vary: Accept-Encoding";
    };

    # Compute ETag
    push @o, "ETag: " . Digest::MD5::md5_hex ($body) if ($body);

    # Compute Content-Length
    push @o, "Content-Length: " . length ($body) if ($body);

    push @o, $headers;
    push @o, "";
    push @o, $body;
    return join "\r\n", @o;
}


# borrowed from http://search.cpan.org/src/RSE/lcwa-1.0.0/lib/lwp/lib/HTTP/Date.pm
# --------------------------------------------------------------------------------
our @DoW = qw(Sun Mon Tue Wed Thu Fri Sat);
our @MoY = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

sub _http_date (;$)
{
   my $time = shift;
   $time = time unless defined $time;
   my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime($time);
   sprintf("%s, %02d %s %04d %02d:%02d:%02d GMT",
	   $DoW[$wday],
	   $mday, $MoY[$mon], $year+1900,
	   $hour, $min, $sec);
}
# --------------------------------------------------------------------------------


# borrowed / modded from Cache::BaseCache
# --------------------------------------------------------------------------------
our $EXPIRES_NOW      = 'now';
our $EXPIRES_NEVER    = 'never';
our %Expiration_Units = ( map(($_,             1), qw(s second seconds sec)),
                          map(($_,            60), qw(m minute minutes min)),
                          map(($_,         60*60), qw(h hour hours)),
                          map(($_,      60*60*24), qw(d day days)),
                          map(($_,    60*60*24*7), qw(w week weeks)),
                          map(($_,   60*60*24*30), qw(M month months)),
                          map(($_,  60*60*24*365), qw(y year years)) );
sub _expiration_time
{
  my ($p_expires_in) = @_;
  uc ($p_expires_in) eq uc ($EXPIRES_NOW)   and return 0; 
  uc ($p_expires_in) eq uc ($EXPIRES_NEVER) and return;
  $p_expires_in =~ /^\s*([+-]?(?:\d+|\d*\.\d*))\s*$/ and return $p_expires_in;
  $p_expires_in =~ /^\s*([+-]?(?:\d+|\d*\.\d*))\s*(\w*)\s*$/ and
      exists $Expiration_Units{$2} and
      return $Expiration_Units{$2} * $1;
  
  return 0;
}
# --------------------------------------------------------------------------------


1;


__END__


=head1 NAME

MKDoc::Apache_Cache - Extra speed for Apache::Registry scripts


=head1 SYNOPSIS

In your httpd.conf file instead of having:

    PerlHandler Apache::Registry

You have something like:

    PerlSetEnv  MKDoc_Apache_Cache_CONFIG           /opt/groucho/cache_policy.txt
    PerlSetEnv  MKDoc_Apache_Cache_CACHE_ROOT       /opt/groucho/cache
    PerlSetEnv  MKDoc_Apache_Cache_NAMESPACE        apache_cache
    PerlHandler MKDoc::Apache_Cache

You also need to define your cache policies in the cache_policy.txt file,
otherwise it won't cache anything.


=head1 SUMMARY

L<MKDoc::Apache_Cache> is a drop-in replacement for Apache::Registry. It lets you very
fine caching policies using the L<MKDoc::Control_List> module and uses L<Cache::FileCache>
as its caching backend.


=head1 DEFINING CACHING POLICIES

The cache_policy.txt (or whatever you choose to call it) file is split into three
parts: conditions, return values, and the policies themselves.


=head2 Defining conditions

Conditions are the building blocks of your rules, they are either true or false.

You can define a condition as follows:

  CONDITION <condition_name> <perl_expression>

condition_name must be a simple string such_as_this_one.

perl_expression can be any Perl expression as long as it's on one line.

Example:

  CONDITION is_slash      $ENV{PATH_INFO} =~ /\/$/
  CONDITION is_sitemap    $ENV{PATH_INFO} =~ /\.sitemap.html$/
  CONDITION is_chris      $ENV{REMOTE_USER} eq 'chris'

In this case we've defined three conditions:

'is_slash' will be true when the request points to a URI which ends by a slash.

'is_sitemap' will be true when the requests points to a URI which -presumably-
will display a dynamically generated sitemap.

'is_chris' will be true when the authenticated user is chris.


=head2 Defining return values

Now we've got two conditions, we can define some cache times. The syntax is as follows:

  RET_VALUE <ret_value_name> <perl_expression>

The value returned by <perl_expression> must be something that L<Cache::Cache> can understand,
namely (from perldoc Cache::Cache):

The valid units are s, second, seconds, sec, m, minute, minutes, min, h, hour, hours, w, week,
weeks, M, month, months, y, year, and years.  Additionally, $EXPIRES_NOW can be represented as
"now" and $EXPIRES_NEVER can be represented as "never".

So for example:

  RET_VALUE ten_minutes "10 min"
  RET_VALUE one_day     "24 hours"
  RET_VALUE never       "never"


=head2 Defining cache policies

Let's say that in general, you want to cache URIs which end by a slash for 10 minutes.

URIs which point to sitemap need to be cached for a day since they are very CPU intensive.

But the user 'chris' needs to see the sitemap always up to date since he's working on the
site, so for chris the sitemap musn't be cached.

You would do it as follows:

  RULE never        WHEN is_sitemap is_chris
  RULE one_day      WHEN is_sitemap
  RULE ten_minutes  WHEN is_slash

This translates as:

IF is_sitemap AND is_chris are true, never cache

ELSE IF is_sitemap is true, cache for a day

ELSE IF is_slash is true, cache for ten minutes

ELSE don't cache.

See also L<MKDoc::Control_List> for more examples of crazy rules.


=head1 EXPORTS

None.


=head1 KNOWN BUGS

None, which probably means plenty of unknown bugs :)


=head1 ABOUT

MKDoc is a web content management system written in Perl which focuses on
standards compliance, accessiblity and usability issues, and multi-lingual
websites.

At MKDoc Ltd we have decided to gradually break up our existing commercial
software into a collection of completely independent, well-documented,
well-tested open-source CPAN modules.

Ultimately we want MKDoc code to be a coherent collection of module
distributions, yet each distribution should be usable and useful in itself.

L<MKDoc::Apache_Cache> is part of this effort.

You could help us and turn some of MKDoc's code into a CPAN module.
You can take a look at the existing code at http://download.mkdoc.org/.

If you are interested in some functionality which you would like to
see as a standalone CPAN module, send an email to <mkdoc-modules@lists.webarch.co.uk>.


=head1 AUTHOR

Copyright 2003 - MKDoc Holdings Ltd.

Author: Jean-Michel Hiver

This module is free software and is distributed under the same license as Perl
itself. Use it at your own risk.


=head1 SEE ALSO

Help us open-source MKDoc. Join the mkdoc-modules mailing list:

  mkdoc-modules@lists.webarch.co.uk

=cut
