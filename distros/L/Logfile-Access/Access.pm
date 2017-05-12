package Logfile::Access;

# $Id: Access.pm,v 1.30 2004/10/25 18:58:12 root Exp $

use 5.008;
use strict;
use warnings;

use URI;
use URI::Escape;
use Locale::Country;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Logfile::Access ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '1.30';

# Preloaded methods go here.

use constant MIME_TYPE_CONFIG_FILENAME => "/etc/httpd/conf/mime.types";

sub new
{

  my $self = {};
  my $loop = 1;

  my @column;
  if (scalar @_ > 1)
  {
    foreach my $key (@column)
    {
      $self->{$key} = $_[$loop++];
      }
    }
  bless($self);
  $self->load_mime_types;
  return $self;
  }

my %mime_type;
sub load_mime_types
{
  return if %mime_type;
  if (open (IN, MIME_TYPE_CONFIG_FILENAME))
  {
    while (<IN>)
    {
      next if $_ =~ /^ *\#/;
      $_ =~ s/\n|\r//g;
      my @data = split (/( |\t)+/, $_);
      my $mime_type = shift @data;
      foreach my $extension (@data)
      {
        next if $extension !~ /\w/;
        $mime_type{$extension} = $mime_type;
        }
      }
    close IN;
    }
  else
  {
    warn "unable to open " . MIME_TYPE_CONFIG_FILENAME . "\n";
    }
  }

use constant REGEX_IP => q{(\S+)};
use constant REGEX_DATE => q{(\d{2})\/(\w{3})\/(\d{4})};
use constant REGEX_TIME => q{(\d{2}):(\d{2}):(\d{2})};
use constant REGEX_OFFSET => q{([+\-]\d{4})};
use constant REGEX_METHOD => q{(\S+)};
use constant REGEX_OBJECT => q{([^ ]+)};
use constant REGEX_PROTOCOL => q{(\w+\/[\d\.]+)};
use constant REGEX_STATUS => q{(\d+|\-)};
use constant REGEX_CONTENT_LENGTH => q{(\d+|\-)};
use constant REGEX_HTTP_REFERER => q{([^"]+)};
use constant REGEX_HTTP_USER_AGENT => q{([^"]+)};
use constant REGEX_COOKIE => q{([^"]+)};

sub parse_iis
{
  my $class = "parse";
  my $self = shift;
  my $row = shift;

#1998-11-19 22:48:39 206.175.82.5 - 208.201.133.173 GET /global/images/navlineboards.gif - 200 540 324 157 HTTP/1.0 Mozilla/4.0+(compatible;+MSIE+4.01;+Windows+95) USERID=CustomerA;+IMPID=01234 http://www.loganalyzer.net
  if ($row =~ /^(\d{4})-(\d{2})-(\d{2}) @{[REGEX_TIME]} @{[REGEX_IP]} @{[REGEX_IP]} @{[REGEX_METHOD]} @{[REGEX_OBJECT]} (\S+) @{[REGEX_STATUS]} (\d+) (\d+) (\d+) (\d+) @{[REGEX_PROTOCOL]} @{[REGEX_HTTP_USER_AGENT]} @{[REGEX_COOKIE]} @{[REGEX_HTTP_REFERER]} *$/)
  {
    $self->{"date"} = join("/", $1, $2, $3);
    $self->{"year"} = $1;
    $self->{"month"} = $2;
    $self->{"mday"} = $3;

    $self->{"time"} = join(":", $4, $5, $6);
    $self->{"hour"} = $4;
    $self->{"minute"} = $5;
    $self->{"second"} = $6;
    }
  else
  {
    return 0;
    }

  return $self->{$class}
  }

sub parse
{
  my $class = "parse";
  my $self = shift;
  my $row = shift;

  $row =~ s/\n|\r//g;

  if (
    ($row =~ /^@{[REGEX_IP]} (\S+) (\S+) \[@{[REGEX_DATE]}:@{[REGEX_TIME]} @{[REGEX_OFFSET]}\] \"@{[REGEX_METHOD]} @{[REGEX_OBJECT]} @{[REGEX_PROTOCOL]}\" @{[REGEX_STATUS]} @{[REGEX_CONTENT_LENGTH]} *$/)
    ||
    ($row =~ /^@{[REGEX_IP]} (\S+) (\S+) \[@{[REGEX_DATE]}:@{[REGEX_TIME]} @{[REGEX_OFFSET]}\] \"@{[REGEX_METHOD]} @{[REGEX_OBJECT]} @{[REGEX_PROTOCOL]}\" @{[REGEX_STATUS]} @{[REGEX_CONTENT_LENGTH]} \"?@{[REGEX_HTTP_REFERER]}\"? \"?@{[REGEX_HTTP_USER_AGENT]}\"?$/)
    )
  {
    $self->{"remote_host"} = $1;
    $self->{"logname"} = $2;
    $self->{"user"} = $3;
    $self->{"date"} = join("/", $4, $5, $6);
    $self->{"mday"} = $4;
    $self->{"month"} = $5;
    $self->{"year"} = $6;
    $self->{"time"} = join(":", $7, $8, $9);
    $self->{"hour"} = $7;
    $self->{"minute"} = $8;
    $self->{"second"} = $9;
    $self->{"offset"} = $10;
    $self->{"method"} = $11;
    $self->{"object"} = $12;
    $self->{"protocol"} = $13;
    $self->{"response_code"} = $14;
    $self->{"content_length"} = $15;
    $self->{"http_referer"} = $16;
    $self->{"http_user_agent"} = $17;
    return 1;
    }
  else
  {
    #die $row;
    return 0;
    }
  #if (@_) {$self->{$class} = shift}
  #return $self->{$class}
  }

sub print
{
  my $class = "print";
  my $self = shift;

  my $datetime = "[" . $self->{"date"} . ":" . $self->{"time"} . " " . $self->{"offset"} . "]";
  my $object = "\"" . join(" ", $self->{"method"}, $self->{"object"}, $self->{"protocol"}) . "\"";
  print join(" ", $self->{"remote_host"}, $self->{"logname"}, $self->{"user"}, $datetime, $object, $self->{"response_code"}, $self->{"content_length"}, "\n");

  if (@_) {$self->{$class} = shift}
  return $self->{$class}
  }

## REMOTE HOST RELATED FUNCTIONS
sub class_a
{
  my $self = shift;
  
  my $host = $self->remote_host;
  if ($host =~ /^(\d{1,3}\.)(\d{1,3}\.){2}(\d+)(:\d+)?$/)
  {
    return $1;
    }
  }

sub class_b
{
  my $self = shift;
  
  my $host = $self->remote_host;
  if ($host =~ /^((\d{1,3}\.){2})(\d{1,3}\.)(\d+)(:\d+)?$/)
  {
    return $1;
    }
  }

sub class_c
{
  my $self = shift;
  
  my $host = $self->remote_host;
  if ($host =~ /^((\d{1,3}\.){3})(\d+)(:\d+)?$/)
  {
    return $1;
    }
  }

sub tld
{
  my $class = "tld";
  my $self = shift;

  
  if (my $host = $self->{"remote_host"})
  {
    if ($host =~ /\.([a-z]{2,5})$/i)
    {
      my $tld = $1;
      $tld =~ tr/A-Z/a-z/;
      return $tld;
      }
    }
  }

sub country_name
{
  my $class = "country_name";
  my $self = shift;

  my $host = $self->{"remote_host"};
  my $tld = $self->tld;
  $self->{$class} = code2country($tld);
  return $self->{$class};
  }

sub domain
{
  my $self = shift;

  my $host = $self->remote_host;
  $host =~ s/:\d+$//;
  
  return if $host =~ /\.\d+(:\d+)?$/;
  do 
  {
    $host =~ s/^([^\.]*\.)// || return $host;
    }
  until $host =~ /^[\w\-]+\.[\w]+$/;
  return $host;
  }

sub remote_port
{
  ## THIS IS A USELESS PIECE OF CODE, REMOTE_HOSTS NEVER HAVE PORT NUMBER
  my $class = "remote_port";
  my $self = shift;

  my $host = $self->{"remote_host"};
  return $1 if $host =~ /:(\d+)\b$/;
  }

sub remote_host
{
  my $class = "remote_host";
  my $self = shift;
  if (@_) {$self->{$class} = shift}
  return $self->{$class}
  }

sub logname
{
  my $class = "logname";
  my $self = shift;
  if (@_) {$self->{$class} = shift}
  return $self->{$class}
  }

sub user
{
  my $class = "user";
  my $self = shift;
  if (@_) {$self->{$class} = shift}
  return $self->{$class}
  }

sub date
{
  my $class = "date";
  my $self = shift;
  if (@_) {$self->{$class} = shift}
  return $self->{$class}
  }

sub fix_mday
{
  ## BUG: DOES NOT SUPPORT LEAP YEAR
  my $self = shift;
  my $mday = shift;

  $mday = int($mday);
  $mday = 1 if $mday < 1;
  $mday = 31 if $mday > 31;

  if ($self->{"month"} =~ /^(jan|mar|may|jul|aug|oct|dec)$/i)
  {
    $mday = 31 if $mday > 31;
    }
  elsif ($self->{"month"} =~ /^(apr|jun|sep|nov)$/i)
  {
    $mday = 30 if $mday > 30;
    }
  elsif ($self->{"month"} =~ /^(feb)$/i)
  {
    $mday = 29 if $mday > 29;
    }
  
  return $mday;
  }

sub mday
{
  my $class = "mday";
  my $self = shift;
  if (@_) 
  {
    $self->{$class} = shift;
    $self->{$class} = fix_mday($self, $self->{$class});
    $self->{"date"} = sprintf("%2.2d/%3.3s/%4.4d", $self->{"mday"}, $self->{"month"}, $self->{"year"});
    }
  return $self->{$class}
  }

sub fix_month
{
  my $month = shift;

  if ($month =~ /^\d+$/)
  {
    $month %= 12; 
    $month = 12 if $month == 0; 
    }

  if ($month =~ /^(jan|0?1)$/i)
  {
    $month = "Jan";
    }
  elsif ($month =~ /^(feb|0?2)$/i)
  {
    $month = "Feb";
    }
  elsif ($month =~ /^(mar|0?3)$/i)
  {
    $month = "Mar";
    }
  elsif ($month =~ /^(apr|0?4)$/i)
  {
    $month = "Apr";
    }
  elsif ($month =~ /^(may|0?5)$/i)
  {
    $month = "May";
    }
  elsif ($month =~ /^(jun|0?6)$/i)
  {
    $month = "Jun";
    }
  elsif ($month =~ /^(jul|0?7)$/i)
  {
    $month = "Jul";
    }
  elsif ($month =~ /^(aug|0?8)$/i)
  {
    $month = "Aug";
    }
  elsif ($month =~ /^(sep|0?9)$/i)
  {
    $month = "Sep";
    }
  elsif ($month =~ /^(oct|10)$/i)
  {
    $month = "Oct";
    }
  elsif ($month =~ /^(nov|11)$/i)
  {
    $month = "Nov";
    }
  elsif ($month =~ /^(dec|12)$/i)
  {
    $month = "Dec";
    }
  }

sub month
{
  my $class = "month";
  my $self = shift;
  if (@_) 
  {
    $self->{$class} = shift;
    $self->{$class} = fix_month($self->{$class});
    $self->{"date"} = sprintf("%2.2d/%3.3s/%4.4d", $self->{"mday"}, $self->{"month"}, $self->{"year"});
    }
  return $self->{$class}
  }

sub fix_year
{
  my $year = shift;

  ## CLEAN UP DATA
  $year =~ s/\D//g;
  $year = int($year);
  $year =~ s/^(\d{4}).*$/$1/;

  ## ALLOW FOR SHORTCUTS
  $year = 1900 + $year if (($year >= 38) && ($year < 100));
  $year = 2000 + $year if (($year >= 00) && ($year < 38));

  $year = sprintf("%4.4d", $year);
  return $year;
  }

sub year
{
  my $class = "year";
  my $self = shift;
  if (@_) 
  {
    $self->{$class} = shift;
    $self->{$class} = fix_year($self->{$class});
    $self->{"date"} = sprintf("%2.2d/%3.3s/%4.4d", $self->{"mday"}, $self->{"month"}, $self->{"year"});
    }
  return $self->{$class}
  }

sub time
{
  my $class = "time";
  my $self = shift;
  if (@_) {$self->{$class} = shift}
  return $self->{$class}
  }

sub fix_time
{
  my $value = shift;
  $value = "00" if (($value < 0) || ($value > 23));
  $value = int($value);
  return $value;
  }

sub hour
{
  my $class = "hour";
  my $self = shift;
  if (@_) 
  {
    $self->{$class} = shift;
    $self->{$class} = fix_time($self->{$class});
    $self->{"time"} = sprintf("%2.2d:%2.2d:%2.2d", $self->{"hour"}, $self->{"minute"}, $self->{"second"});
    }
  return $self->{$class}
  }

sub minute
{
  my $class = "minute";
  my $self = shift;
  if (@_) 
  {
    $self->{$class} = shift;
    $self->{$class} = fix_time($self->{$class});
    $self->{"time"} = sprintf("%2.2d:%2.2d:%2.2d", $self->{"hour"}, $self->{"minute"}, $self->{"second"});
    }
  return $self->{$class}
  }

sub second
{
  my $class = "second";
  my $self = shift;
  if (@_) 
  {
    $self->{$class} = shift;
    $self->{$class} = fix_time($self->{$class});
    $self->{"time"} = sprintf("%2.2d:%2.2d:%2.2d", $self->{"hour"}, $self->{"minute"}, $self->{"second"});
    }
  return $self->{$class}
  }

sub offset
{
  my $class = "offset";
  my $self = shift;
  if (@_) {$self->{$class} = shift}
  return $self->{$class}
  }

sub method
{
  my $class = "method";
  my $self = shift;
  if (@_) {$self->{$class} = shift}
  return $self->{$class}
  }

## OBJECT SPECIFIC ROUTINES
sub scheme
{
  my $class = "scheme";
  my $self = shift;

  my $uri = URI->new($self->{"object"});
  return $uri->scheme;
  }

sub query_string
{
  my $class = "query_string";
  my $self = shift;

  my $uri = URI->new($self->{"object"});
  return $uri->query;
  }

sub path 
{
  my $class = "path";
  my $self = shift;

  my $uri = URI->new($self->{"object"});
  return $uri->path;
  }

sub mime_type
{
  my $self = shift;

  my $object = $self->path;
  if ($object =~ /\.(\w+)$/)
  {
    my $extension = $1;
    $extension =~ tr/A-Z/a-z/;
    return $mime_type{$extension};
    }
  }

sub unescape_object
{
  my $self = shift;

  my $object = $self->{"object"};
  return uri_unescape($object);
  }

sub escape_object
{
  my $self = shift;

  my $object = $self->{"object"};
  return uri_escape($object);
  }

sub object
{
  my $class = "object";
  my $self = shift;
  if (@_) {$self->{$class} = shift}
  uri_unescape($self->{$class});
  return $self->{$class}
  }

sub protocol
{
  my $class = "protocol";
  my $self = shift;
  if (@_) {$self->{$class} = shift}
  return $self->{$class}
  }

sub response_code
{
  my $class = "response_code";
  my $self = shift;
  if (@_) {$self->{$class} = shift}
  return $self->{$class}
  }

sub content_length
{
  my $class = "content_length";
  my $self = shift;
  if (@_) {$self->{$class} = shift}
  return $self->{$class}
  }

sub http_referer
{
  my $class = "http_referer";
  my $self = shift;
  if (@_) {$self->{$class} = shift}
  return $self->{$class}
  }

sub http_user_agent
{
  my $class = "http_user_agent";
  my $self = shift;
  if (@_) {$self->{$class} = shift}
  return $self->{$class}
  }


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Logfile::Access - Perl extension for common log format web server logs

=head1 SYNOPSIS

  use Logfile::Access;

        my $log = new Logfile::Access;

        open (IN, $filename);
        while (<IN>)
        {
          $log->parse($_);
          warn $log->remote_host;
          }
        close IN;

=head1 ABSTRACT

	A module for parsing common log format web server access log files.

=head1 DESCRIPTION

	new() - defines new logfile row object

	load_mime_types() - loads mime types for filename extensions
  
	parse() - parses a common log format row

	print() - outputs the data to a common log format row

=head2 remote_host related functions

	class_a() - returns the Class A of the remote_host

	class_b() - returns the Class B of the remote_host

	class_c() - returns the Class C of the remote_host

	tld() - returns the top level domain of the remote_host

	country_name() - returns the country name

	domain() - return the domain of the remote_host

	remote_host() - returns / sets the remote host

=head2 authentication related functions

	logname() - returns / sets the logname

	user() - returns / sets the user name

=head2 date and time related functions

	date() - returns / sets the CLF date

	mday() - returns / sets the day of the month

	month() - returns / sets the abbreviated name of the month

	year() - returns / sets the year

	time() - returns / sets the time

	hour() - returns / sets the hour

	minute() - returns / sets the minute

	second() - returns / sets the seconds

	offset() - returns / sets the GMT offset

=head2 request object related functions

	method() - returns / sets the request method

	scheme() - returns the request object scheme

	query_string() - returns the query string from the requets object

	path() - returns the object path

	mime_type() - returns the object mime type

	unescape_object() - returns the unescaped object string

	escape_object() - returns the escaped object string

	object() - returns / sets the requets object

	protocol() - returns / sets the request protocol

=head2 response code related functions

	response_code() - returns / sets the numeric response code

	content_length() - returns / sets the content length in bytes

	http_referer() - returns / sets the http referer

	http_user_agent() - returns / sets the http user agent string


=head2 EXPORT

None by default.



=head1 PREREQUISITES

        use Locale::Country;
        use URI;
        use URI::Escape;

=head1 SEE ALSO

http://www.apache.org/

=head1 AUTHOR

David Tiberio, E<lt>dtiberio5@hotmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 David Tiberio, dtiberio5@hotmail.com

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
