#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;

use IO::Socket::INET;

use GSSAPI;
use MIME::Base64;

my %opt;

unless(GetOptions(\%opt, qw(prodid=s hostname=s port=s mutual))) {
  print "$0 needs arguments, provide at least -prodid and -hostname, optionally -port (defauly 10000) or -mutual (for two sided authentication)\n";
  exit(1);
}

if(! $opt{hostname}) {
  die "$0: must specify -hostname\n";
}

if(! $opt{prodid}) {
  die "$0: must specify -prodid\n";
}

if(! $opt{port}) {
  warn "$0: -port not specified, defaulting to 10000\n";
  $opt{port} = 10000;
}

if(! $opt{prodid}) {
  $opt{prodid} = "host";
}

warn "$0: using [$opt{prodid}\@$opt{hostname}:$opt{port}]\n";


#
# GSSAPI::Name->import produces $gss_server_name
# which is then passed in to GSSAPI::Context::init
# $gss_server_name represents the principcal name
# of the app server to which we are authenticating
#

my $server_name = "$opt{prodid}\@$opt{hostname}";
my $status = GSSAPI::Name->import(my $gss_server_name, $server_name, gss_nt_service_name);
$status || gss_exit("CLIENT::Unable to import server name: $server_name", $status);

$status = $gss_server_name->display(my $display_name, my $type);
print "CLIENT::principal [$server_name] means going to communicate with server name [$display_name]\n";

my $gss_input_token = q{};

my $socket = IO::Socket::INET->new
  (
   PeerAddr                 => $opt{hostname},
   PeerPort                 => $opt{port},
   Proto                    => 'tcp',
   Type                     => SOCK_STREAM,
  );

die "socket/connect: $!\n" unless ($socket);

#
# The main purpose of GSSAPI::Context::init is to produce
# an authentication token ($gss_output_token) which will
# be sent by the app client to app server. Note the output
# is binary data.
#

my $gss_auth_flags;
if($opt{mutual}) {
  $gss_auth_flags = GSS_C_MUTUAL_FLAG;
} else {
  $gss_auth_flags = 0;
}

my $client_context;

my $counter = 0;
my $error = 0;

do {
    $counter++;

    $status = GSSAPI::Context::init($client_context,           # output context
				    GSS_C_NO_CREDENTIAL,
				    $gss_server_name,          # authenticate to this name
				    GSS_C_NO_OID,              # use default mechanism (krb5)
				    $gss_auth_flags,           # input flags
				    0,                         # input time
				    GSS_C_NO_CHANNEL_BINDINGS, # no channel binding
				    $gss_input_token,          # input token
				    my $out_mech,
				    my $gss_output_token,
				    my $out_flags,
				    my $out_time);

    $status || gss_exit("CLIENT::Unable to initialize security context", $status);

    print "CLIENT::gss_init_sec_context success\n";

    # The GSS protocol can do mutual authentication. If this is requested, the token
    # that we generate in the first pass will indicate this to the server. The major
    # status will have the GSS_S_CONTINUE_NEEDED bit set to indicate that we are
    # expecting a reply with a server identity token. This loop will continue until
    # that bit is no longer set. It should go through only once (non-mutual) or twice
    # (mutual).

    if ($counter == 1) {
	print "CLIENT::going to identify client to server\n";
    } elsif ($counter == 2) {
	print "CLIENT::confirmed server identity from mutual token\n";
        my $server_name;
	$status = $gss_server_name->display($server_name);
        $status || gss_exit("CLIENT::Unable to display server name", $status);
        print "CLIENT::authenticated server name is $server_name\n" if $server_name;

    } else {
	print "CLIENT::iteration [$counter] successful, but should not be here\n";
    }

    if($gss_output_token) {
	print "CLIENT::have token to send ...\n";
	print "CLIENT::GSS token length is " . length($gss_output_token) . "\n";

	#
	# $gss_output_token is binary data
	#

	print $socket encode_base64($gss_output_token, '') . "\n";
	print "CLIENT::sent token to server\n";
    }

    if ($status->major & GSS_S_CONTINUE_NEEDED) {
	print "CLIENT::Mutual auth requested ...\n";
	$gss_input_token = <$socket>;
	if ($gss_input_token) {
	    print "CLIENT::got mutual auth token from server\n";
	    $gss_input_token = decode_base64($gss_input_token);
	    print "CLIENT::mutual auth token length is " . length($gss_input_token) . "\n";
	} else {
	    print "CLIENT::server did not send needed continue token back\n";
	    $error = 1;
	}
    }
} while (!$error and $status->major & GSS_S_CONTINUE_NEEDED);

$socket->shutdown(2);

exit(0);

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
  exit(1);
}

