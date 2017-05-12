#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Sys::Hostname;

use IO::Socket::INET;

use GSSAPI;
use MIME::Base64;


my %opt;

#
# Arguments:
#   kname syntax is prodid@hostname or prodid@servicename
#         e.g.: host@server1
#         e.g.: mqm@mqserver1
#

unless (GetOptions(\%opt, qw(keytabfile=s hostname=s port=s))) {
    exit(1);
}

if(! $opt{port}) {
    warn "$0: -port not specified, defaulting to 10000\n";
    $opt{port} = 10000;
}

if(! $opt{hostname}) {
    $opt{hostname} = hostname();
    warn "$0: -name not specified, using hostname result [" . $opt{hostname} . "]\n";
}
warn "$0: using [" . $opt{hostname} .':' .$opt{port} . "]\n";
#
# Servers need keytab files, the only standard so far is /etc/krb5.keytab.
# That's the file meant to contain keys for the local machine. It is readable
# only by root for security reasons. In this case the name is host@machinename.
#

$ENV{KRB5_KTNAME} = "FILE:" . $opt{keytabfile};
if (! -r $opt{keytabfile}) {
    die "Cannot read ". $opt{keytabfile} .": $!";
}

print "SERVER set environment variable KRB5_KTNAME to " . $ENV{KRB5_KTNAME} . "\n";

my $listen_socket = IO::Socket::INET->new (
			   Listen    => 16,
			   LocalHost => $opt{hostname},
			   LocalPort => $opt{port},
			   ReuseAddr => 1,
			   Proto     => 'tcp',
			);

die "Unable to create listen socket: $!" unless $listen_socket;

print "Listening on port $opt{port} ...\n";

my $error = 0;

while (! $error) {

    my $server_context;
    print "\nSERVER::waiting for request ...\n";
    my $client_socket = $listen_socket->accept();
    unless ($client_socket) {
	warn "SERVER::accept failed: $!";
	next;
    }

    print "SERVER::accepted connection from client ...\n";
    my $gss_input_token = <$client_socket>;

    $gss_input_token = decode_base64($gss_input_token);
    print "SERVER::received token (length is " . length($gss_input_token) . "):\n";

    if (length($gss_input_token) ) {
	my $status = GSSAPI::Context::accept(
			$server_context,
			GSS_C_NO_CREDENTIAL,
			$gss_input_token,
			GSS_C_NO_CHANNEL_BINDINGS,
			my $gss_client_name,
			my $out_mech,
			my $gss_output_token,
			my $out_flags,
			my $out_time,
			my $gss_delegated_cred);

	$status or  gss_exit("Unable to accept security context", $status);
        my $client_name;
	$status = $gss_client_name->display($client_name);
        $status or  gss_exit("Unable to display client name", $status);
	print "SERVER::authenticated client name is $client_name\n" if $client_name;

	if($gss_output_token) {
	    print "SERVER::Have mutual token to send ...\n";
	    print "SERVER::GSS token size: " . length($gss_output_token) . "\n";

	    #
	    # $gss_output_token is binary data
	    #

	    my $enc_token = encode_base64($gss_output_token, '');

	    print $client_socket "$enc_token\n";
	    print "SERVER::sent token (length is " . length($gss_output_token) . ")\n";
	}
   }
   # $server_context->DESTROY() if $server_context;
}

print "SERVER::exiting after error\n";

################################################################################

sub gss_exit {
  my $errmsg = shift;
  my $status = shift;

  my @major_errors = $status->generic_message();
  my @minor_errors = $status->specific_message();

  print STDERR "$errmsg:\n";
  foreach my $s (@major_errors) {
    print STDERR "  MAJOR::$s\n";
  }
  foreach my $s (@minor_errors) {
    print STDERR "  MINOR::$s\n";
  }
  return 1;
}
