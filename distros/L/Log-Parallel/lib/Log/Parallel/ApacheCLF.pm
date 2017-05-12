
package Log::Parallel::ApacheCLF;

use strict;
use warnings;
use Data::Dumper;
require Log::Parallel::Parsers;
require Exporter;
use Time::JulianDay qw(jd_timegm);;
use URI::Escape::XS qw(uri_unescape uri_escape);

our @ISA = qw(Log::Parallel::Parsers::BaseClass Exporter);
our @EXPORT = qw();

__PACKAGE__->register_parser();

our $warn_level = 1;

my $month_rx = qr/(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)/;
my $num255_rx = qr/(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]\d|\d)/;
my $ip_rx = qr/$num255_rx\.$num255_rx\.$num255_rx\.$num255_rx/;
my $host_rx = qr/(?:$ip_rx|unknown)/;
my $quoted_rx = qr/(?:[^\\"]|\\.)*/;

my %mon_num = (
	Jan	=> 1,
	Feb	=> 2,
	Mar	=> 3,
	Apr	=> 4,
	May	=> 5,
	Jun	=> 6,
	Jul	=> 7,
	Aug	=> 8,
	Sep	=> 9,
	Oct	=> 10,
	Nov	=> 11,
	Dec	=> 12,
);

sub return_parser
{
	my ($pkg, $fh, %info) = @_;
	my $filesize = $info{filesize} || 2_000_000_000;
	my $span = $info{span};
	my $start_time = $info{time};
	my $post_rx = $info{extra_rx} || qr//;
	my $pre_rx = $info{pre_rx} || qr//;
	my $pre_rx_save_match_count = $info{pre_rx_saved_match_count} || 0;

	my $safewarn = sub {
		my ($level, $err) = @_;
		return unless $level <= $warn_level;
		use bytes;
		$err =~ s/([\200-\377])/sprintf("M-%c",ord($1)&0177)/eg;
		$err =~ s/([\0-\37\177])/sprintf("^%c",ord($1)^64)/eg;
		my ($pkg, $file, $line) = caller;
		warn "$err at $file:$line processing $info{host}:$info{filename}\n";
	};


	my $line_number = 0;

	my $midnight;
	my $day = '';
	my $offset;
	my $zone = '';

	return sub {
		while (<$fh>) {

			$line_number++;

			# - - - [19/Mar/2009:00:00:03 -0700] "HEAD / HTTP/1.0" 401 - "-" "-"
			unless (

				m{
					^
					$pre_rx

					(\S+)					# server hostname, *1
					[ ]
					apache:
					[ ]
					([^]["\@/]+?)				# forward ip, *2
					[ ]
					\S+					# ident user
					[ ]
					(\S+)					# apache auth user, *3
					[ ]
					\[
						(\d\d?/$month_rx/\d\d\d\d)	# apache date, *4
						:
						(\d\d)				# apache hour, *5
						:
						(\d\d)				# apache minute, *6
						:
						(\d\d)				# apache second, *7
						[ ]
						([-+]\d\d\d\d)			# apache timezone, *8
					\]
					[ ]
					"($quoted_rx)"				# request, *9
					[ ]
					(\d+)					# apache result code, *10
					[ ]
					(\S+)					# number of bytes sent, *11
					[ ]
					"($quoted_rx)"				# referrer, *12
					[ ]
					"($quoted_rx)"				# user agent, *13

					$post_rx
				}x

			) {
				warn "Could not parse $line_number $_";
				next;
			}
			
			my @match = ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23);
			my @pre = splice(@match, 0, $pre_rx_save_match_count);
			my ($ip, $auth_user, $date, $hh, $mm, $ss, $tzoff, $request, $status, $sent, $referrer, $user_agent) = splice(@match, 0, 13);

			#print "server_host=$server_host\n";
			#print "\tip=$ip\n";
			#print "\tdate=$date\n";
			#print "\trequest=$request\n";
			#print "\tstatus=$status\n";
			#print "\tsent=$sent\n";

			my $detail = '';

			$site = '' unless $site;

			unless ($day eq $date) {
				$day = $date;
				my ($mday, $month, $year) = split(/\//, $day);
				my $mnum = $mon_num{$month} || die "month = $month ($day)";
				$midnight = jd_timegm(0, 0, 0, $mday, $mnum-1, $year);
			}
			unless ($zone eq $tzoff) {
				$tzoff =~ /^([+-])(\d\d)(\d\d)/ || die;
				$offset = ($1 eq '-' ? -1 : 1) * (60 * $2 + $3);
			}
			my $time = $midnight + $offset + $hh * 3600 + $mm * 60 + $ss;

			$ip		= '' if ! defined($ip) || $ip eq '-';
			$referrer	= '' if ! defined($referrer) || $referrer eq '-';
			$user_agent	= '' if ! defined($user_agent) || $user_agent eq '-';
			$auth_user	= '' if ! defined($auth_user) || $auth_user eq '-';

			return {
				ip		=> $ip,
				auth_user	=> $auth_user,
				server_time	=> $time,
				request		=> $request,
				status		=> $status,
				bytes_sent	=> $sent,
				referrer	=> $referrer,
				user_agent	=> $user_agent,
				@pre ? (pre_match => \@pre) : (),
				(@+ > $pre_rx_save_match_count + 13) ? (post_match => \@match ) : (),
			};
		}
		return undef;
	};
}

1;

__END__

=head1 NAME

 Log::Parallel::ApacheCLF - parse apache common log format

=head1 SYNOPSIS

 use Log::Parallel::ApacheCLF;

 my $parser = Log::Parallel::ApacheCLF->return_parser($fh, %info);

=head1 LOG PROCESSING CONFIG

sources:
  -
    name:               raw apache server logs
    hosts:              host1.domain
    path:               /var/apache_archive/%YYYY%.%MM%.%DD%{,.bz2}
    format:             ApacheCLF
    valid_from:         2009-01-01
    valid_to:           yesterday
jobs:
  -
    name:               server logs
    destination:        server logs
    source:             raw apache server logs
    path:               '%DATADIR%/%YYYY%/%MM%/%DD%/%JOBNAME%.%DURATION%.%BUCKET%.%SOURCE_BKT%'
    valid_from:         2008-01-01
    valid_to:           yesterday
    frequency:          daily
    output_format:      TSV
    use:                Log::Parallel::TSV Log::Parallel::ApacheCLF
    buckets:            20
    hosts:              host10,host11,host12,host13
    bucketizer:         $log->{server_time}

=head1 DESCRIPTION

Parse the apache web server logs in Common Log Format.   The fields from the apache logs are named as follows:

=over

=item ip

The IP address header field.  Sometimes C<->.

=item auth_user

The HTTP authenticated user.

=item server_time

The time, unix time seconds, that the server wrote the log line.

=item request

The HTTP request line.   Eg: C<GET / HTTP/1.0>.

=item status

The HTTP status code.  200, 301, etc.

=item bytes_sent

The number bytes transfered.

=item user_agent

The HTTP UserAgent.

=item refferer

The HTTP Refferrer field.

=back

This module can also be used to parse more extended Apache logs.   Create a new module and
invoke this one to do a bunch of the work.    There are three extra construction arguments
that can be used:

=over

=item pre_rx

A regular expression to match of things that come I<before> the regular
Apache log format on each line.  
If this has saved matches, they'll be returned as an array: C<pre_match>.

=item pre_rx_saved_match_count

If you have a C<pre_rx>, and if that regular expression has saved matches,
you must say how many for Log::Parallel::ApacheCLF to work.  This
is how.

=item post_rx

A regular expression to match of things that come I<after> the regular
Apache log format on each line.

If this has saved matches, they'll be returned as an array: C<post_match>.

=back

=head1 LICENSE

This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

