package HTTP::ProxyTest;

use 5.006;
our $VERSION = '0.11';
# $Id: ProxyTest.pm,v 1.3 2011/08/01 21:03:09 gunnarh Exp $

=head1 NAME

HTTP::ProxyTest - Reject an HTTP request if passed via an open proxy

=head1 SYNOPSIS

    use HTTP::ProxyTest;

    proxytest(
        -nmap       =>  '/usr/local/bin/nmap',
        -whitelist  =>  '/usr/local/etc/ProxyTest_whitelist',
        -log        =>  '/var/log/open_proxy.log',
    );

=head1 DESCRIPTION

Robots that send comment spam are often hidden behind anonymous open
proxy servers. You can use C<HTTP::ProxyTest> to look for open proxies
on-the-fly and prevent such spam robots from submitting their crap.
The module is particularly useful if you don't want to bother your
web site visitors with CAPTCHAs etc.

C<HTTP::ProxyTest> tests certain ports of C<REMOTE_ADDR> that are
often used for anonymous open proxies, and denies access if an open
proxy is found, i.e. it responds with status "403 Forbidden" and
exits. The module was designed to make use of the Nmap security
scanner (L<http://nmap.org/>) in order to speed up things and/or
increase the number of ports to be considered for testing.
Consequently, if Nmap is currently not available to you, you are
advised to download and install that program.

The strong point of C<HTTP::ProxyTest>, compared to other similar CPAN
modules (see L</SEE ALSO>), is its speed. Since Nmap limits the number
of ports to test, C<HTTP::ProxyTest> can do on-the-fly testing fast
enough to cover quite a few proxy port candidates, without causing any
significant response delay. The same seems not to be true for other
modules.

=head2 Arguments

Below are the arguments that can be passed the B<proxytest()>
function, which by the way is the only function of C<HTTP::ProxyTest>
that you are supposed to call from outside the module. B<proxytest()>
takes hash style key=E<gt>value arguments (see L</SYNOPSIS>).
All the arguments are optional.

=over 4

=item B<-nmap>

Path to the nmap executable; no value by default.

If -nmap is set, C<HTTP::ProxyTest> will test those -primary ports
that Nmap reports to be either open or filtered, while it will only
test those -secondary ports that Nmap reports to be open.

If -nmap is not set, C<HTTP::ProxyTest> will test all the -primary
ports and skip the -secondary ports.

=item B<-primary>

Reference to an array of ports where the risk of carrying an open
proxy is not insignificant. Default value:

    [ 80, 3128, 8080 ]

=item B<-secondary>

Reference to an array of ports which are less likely, compared to
the -primary ports, to carry an open proxy. Default value:

    [ 808, 6588, 8000, 8088 ]

=item B<-test_url>

Web address used for proxy testing; defaults to
C<'http://gunnar.cc/proxy_test.txt'>, which is the address to a tiny
text file on my own server. Even if that address works fine when I'm
writing this, there is no guarantee that it will keep working for all
time, so you are recommended to set -test_url to a resource that you
control. Choose a URL to a tiny page on a reliable server which
includes the status line C<200 OK> in the responses.

=item B<-content_substr>

A string that shall be included in the content string of the response;
defaults to C<'y4dWP:a7w'>. To prevent false positives,
C<HTTP::ProxyTest> will not report that a host carries an open proxy,
unless it has confirmed an occurrence of -content_substr in the
response content string.

Obviously, if you set -test_url, you will most likely need to set
-content_substr as well.

=item B<-timeout>

When doing proxy testing, C<HTTP::ProxyTest> expects to establish a
server connection within -timeout seconds after a request, or else
the request is aborted. Defaults to 4.

=item B<-whitelist>

Path to a DBM database with IP addresses of hosts that passed the
proxy tests during the last week; no value by default. If you set
-whitelist, C<HTTP::ProxyTest> will maintain the database and skip
testing for hosts in the 'whitelist'.

=item B<-log>

Path to a text file where information about requests from hosts with
open proxies is logged; no value by default. 

=item B<-log_maxbytes>

Maximum size in bytes of the -log file; defaults to C<1_000_000>. If
-log is set, and when the max size is touched, C<HTTP::ProxyTest>
halves the file size by removing the oldest entries.

=back

=head1 EXAMPLES

=head2 Perl web apps

After having adapted the L</SYNOPSIS> code, you can simply insert it
e.g. before any form generating or form data processing code portion
of a Perl program. To shorten the code to be inserted in various
programs, you can place a wrapper in one of the C<@INC> directories.

    # proxytest.pl
    use HTTP::ProxyTest;
    proxytest(
        -nmap       =>  '/usr/local/bin/nmap',
        -whitelist  =>  '/usr/local/etc/ProxyTest_whitelist',
        -log        =>  '/var/log/open_proxy.log',
    );
    1;

Now you can invoke C<HTTP::ProxyTest> by just saying:

    require 'proxytest.pl';

=head2 PHP web apps

This example of how to invoke C<HTTP::ProxyTest> from PHP begins with
this script, located in one of the PHP C<include_path> directories:

    <?php
    // proxytest.php
    function proxytest() {
        $args = implode(' ', array(
            getenv('REMOTE_ADDR'),
            getenv('HTTP_HOST'),
            getenv('REQUEST_URI'),
        ));
        exec('/path/to/proxytest.pl ' . $args, $error);
        if ( count($error) ) {
            header('HTTP/1.0 403 Forbidden');
            echo ( implode( "\n", array_slice($error, 3) ) );
            exit;
        }
    }
    proxytest();
    ?>

Then we add some code to the wrapper and make it an executable Perl
script.

    #!/usr/bin/perl
    # proxytest.pl
    use HTTP::ProxyTest;
    if ( $ENV{_} and $ENV{_} eq '/path/to/proxytest.php' ) {
        @ENV{ qw/REMOTE_ADDR HTTP_HOST REQUEST_URI/ } = @ARGV;
    }
    proxytest(
        -nmap       =>  '/usr/local/bin/nmap',
        -whitelist  =>  '/usr/local/etc/ProxyTest_whitelist',
        -log        =>  '/var/log/open_proxy.log',
    );
    1;
 
Finally the single line call from a PHP program:

    include 'proxytest.php';

=head1 DEPENDENCIES

This module is dependent on the L<libwww-perl|LWP> set of modules.

Also, even if it's possible to use C<HTTP::ProxyTest> without access
to the Nmap security scanner, we'd better consider Nmap to be a
S<'soft dependency'>, a.k.a. strong recommendation.

=head1 CAVEAT

In case of C<HTTP::ProxyTest> being invoked via a server wide wrapper,
and the web server may be run as more than one user (e.g. because of
Apache suEXEC), you should pay attention to the permissions of the
DBM and log files. You may want to make sure that those files are
'world writable'.

=head1 AUTHOR, COPYRIGHT AND LICENSE

    Copyright (c) 2010-2011 Gunnar Hjalmarsson
    http://www.gunnar.cc/cgi-bin/contact.pl

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::ProxyCheck|HTTP::ProxyCheck>,
L<HTTP::CheckProxy|HTTP::CheckProxy>

=cut

use strict;
use warnings;
use Carp;
use LWP::UserAgent;
use SDBM_File;
use Fcntl qw(:DEFAULT :flock);

BEGIN {
	require Exporter;
	our @ISA = 'Exporter';
	our @EXPORT = 'proxytest';
}

local $Carp::CarpLevel = 2;
local our $useragent;
our $time = time;

sub proxytest {
	my ($ip) = $ENV{REMOTE_ADDR} =~ /^(\d+(?:\.\d+){3})$/ or return;
	my $args = &arguments or return;
	my $path = $ENV{PATH};
	$ENV{PATH} = '';
	my $white = update_whitelist( $args->{whitelist} );
	TEST: {
		last TEST if $white->{$ip};

		my $ports = portselect($ip, $args);
		foreach my $port ( @$ports ) {
			$useragent->proxy('http', "http://$ip:$port");
			my $res = $useragent->get( $args->{test_url} );
			if ( $res->is_success and
			  index( $res->content, $args->{content_substr} ) >= 0 ) {
				caught($ip, $port, $args);
				untie %$white;
				exit;
			}
		}

		$white->{$ip} = $time;
	}
	untie %$white;
	$ENV{PATH} = $path;  # don't interfere with rest of program
}

sub arguments {
	my %defaults = (
		primary         => [ 80, 3128, 8080 ],
		secondary       => [ 808, 6588, 8000, 8088 ],
		test_url        => 'http://gunnar.cc/proxy_test.txt',
		content_substr  => 'y4dWP:a7w',
		timeout         => 4,
		log_maxbytes    => 1_000_000,
	);
	my %valid_keys = (
		-nmap           => 'nmap',
		-primary        => 'primary',
		-secondary      => 'secondary',
		-test_url       => 'test_url',
		-content_substr => 'content_substr',
		-timeout        => 'timeout',
		-whitelist      => 'whitelist',
		-log            => 'log',
		-log_maxbytes   => 'log_maxbytes',
	);

	@_ % 2 == 0 or croak 'key=>value pairs are expected';

	my %args;
	while ( my $arg = shift ) {
		my $key = lc $arg;
		$valid_keys{$key} or croak "Unknown argument key '$key'";
		$args{ $valid_keys{$key} } = shift;
	}

	if ( $args{nmap} ) {
		-f $args{nmap} or croak "File '$args{nmap}' does not exist";
		-x $args{nmap} or croak "'$args{nmap}' is not an executable file";
	}

	for ('whitelist', 'log') {
		PATHCHECKS: {
			last PATHCHECKS unless $args{$_};
			my $file = $_ eq 'whitelist' ? $args{$_}.'.pag' : $args{$_};
			if ( -f $file ) {
				last PATHCHECKS if -r $file and -w _;
				croak "Argument -$_: The user this script runs as ",
				  "does not have write access to '$file'";
			}
			require File::Basename;
			my $dir = ( File::Basename::fileparse($file) )[1];
			if ( -d $dir ) {
				last PATHCHECKS if -r $dir and -w _ and -x _;
				croak "Argument -$_: The user this script runs as ",
				  "does not have write access to '$dir'";
			}
			croak "Argument -$_: Can't find any directory '$dir'";
		}
	}

	for ('primary', 'secondary') {
		if ( exists $args{$_} ) {
			ref($args{$_}) eq 'ARRAY' or croak "Argument -$_ shall be an arrayref";
			my $err = grep /\D/ || $_ < 0 || $_ > 65535, @{ $args{$_} };
			$err == 0 or croak "Argument -$_: $err elements are not valid port numbers";
		} else {
			$args{$_} = $defaults{$_};
		}
	}
	$args{primary}->[0] or $args{secondary}->[0] or
	  croak 'There should be at least one port to test';
	unless ( $args{nmap} or $args{primary}->[0] ) {
		croak 'Argument -primary may not refer to an empty list when no Nmap scanning is done';
	}

	for ('timeout', 'log_maxbytes') {
		if ( $args{$_} ) {
			$args{$_} =~ /^\d+$/ or croak "Argument -$_ shall be a positive integer";
		} else {
			$args{$_} = $defaults{$_};
		}
	}

	for ('test_url', 'content_substr') {
		$args{$_} ||= $defaults{$_};
	}
	$useragent = LWP::UserAgent->new(
		timeout => $args{timeout},
		agent => "HTTP::ProxyTest/$VERSION",
		requests_redirectable => [],
	);
	my $res = $useragent->get( $args{test_url} );
	unless ( $res->is_success ) {
		# no fatal error, since a temporary glitch
		# might be the cause of the failure
		carp 'Argument -test_url: Response status ', $res->status_line;
		return undef;
	}
	unless ( index( $res->content, $args{content_substr} ) >= 0 ) {
		croak 'Argument -content_substr: The string ',
		  "'$args{content_substr}' not found in the source of $args{test_url}";
	}

	\%args
}

sub update_whitelist {
	my $whitelist = shift;
	return {} unless $whitelist;

	tie my %white, 'SDBM_File', $whitelist, O_CREAT|O_RDWR, 0666 or die $!;
	my @oldies = grep $white{$_} < $time - 604800, keys %white;
	delete @white{ @oldies };
	\%white
}

sub portselect {
	my ($ip, $args) = @_;
	return $args->{primary} unless $args->{nmap};

	my (%count, @open, @filtered);
	my $ports = join ',', map { $count{$_}++ ? () : $_ }
	  @{ $args->{primary} }, @{ $args->{secondary} };
	my $nmap_result = qx( $args->{nmap} -PN -p $ports $ip );
	croak 'Nmap scan failed' if !$nmap_result or $?;
	while ( $nmap_result =~ m,^(\d+)/tcp\s+(open|filtered)\b,gm ) {
		my ($port, $state) = ($1, $2);
		if ( $state eq 'open' ) {
			push @open, $port;
		} elsif ( grep $_ eq $port, @{ $args->{primary} } ) {
			push @filtered, $port;
		}
	}
	[ @open, @filtered ]
}

sub caught {
	my ($ip, $port, $args) = @_;
	my $host = gethostbyaddr( pack('C4', split /\./, $ip), 2 ) || "IP $ip";
	print "Status: 403 Forbidden\n",
	      "Content-type: text/html; charset=UTF-8\n\n";
	print "<html><head><title>403 Forbidden</title></head><body>\n",
	      "<h1>403 Forbidden</h1>\n<p>The host you are using (<tt>$host</tt>) ",
	      "appears to carry an open proxy on port $port.</p>\n",
	      "</body></html>\n";
	return unless $args->{log};

	open my $log, '+>>', $args->{log} or die $!;
	flock $log, LOCK_EX;
	print $log "Date:      ", scalar localtime $time, "\n",
	           "URL:       ", ( lc substr($ENV{REQUEST_URI}, 0, 4) eq 'http' ?
	             '' : "http://$ENV{HTTP_HOST}" ), "$ENV{REQUEST_URI}\n",
	           "IP:        $ip\n";
	print $log "Host name: $host\n" unless substr($host, 3) eq $ip;
	print $log "Port:      $port\n\n";

	my $oldfh = select $log; $|++; select $oldfh;
	return unless -s $log > $args->{log_maxbytes};

	seek $log, $args->{log_maxbytes} / 2, 0;
	my $latest = do { local $/; <$log> };
	$latest =~ s/.+?\n\n//s;
	seek $log, 0, 0;
	truncate $log, 0;
	print $log $latest;
}

1;

