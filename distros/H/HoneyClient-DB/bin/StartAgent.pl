#!perl -w -Ilib

# $Id: StartAgent.pl 409 2007-05-30 03:12:01Z kindlund $

use strict;
use warnings;
use Carp ();

use HoneyClient::Util::Config qw(getVar);
use HoneyClient::Agent;
use HoneyClient::Util::SOAP qw(getClientHandle);
use Data::Dumper;
use MIME::Base64 qw(decode_base64 encode_base64);
use Storable qw(thaw nfreeze);
use Log::Log4perl qw(:easy);

# The global logging object.
our $LOG = get_logger();

our ($stub, $som);
our $URL = HoneyClient::Agent->init();

our $agentState = undef;
my $tempState = undef;
our $faultDetected = 0;

print "URL: " . $URL. "\n";

sub _watchdogFaultHandler {

    # Extract arguments.
    my ($class, $res) = @_;

    # Construct error message.
    # Figure out if the error occurred in transport or over
    # on the other side.
    my $errMsg = $class->transport->status; # Assume transport error.

    if (ref $res) {
        $errMsg = $res->faultcode . ": ".  $res->faultstring . "\n";
    }

    if (!$faultDetected) {
        $LOG->error("Watchdog fault detected, recovering Agent daemon.");
        $faultDetected = 1;
    }
    # XXX: Reenable this, eventually.
    $LOG->error(__PACKAGE__ . "->_watchdogFaultHandler(): Error occurred during processing.\n" . $errMsg);
    Carp::carp __PACKAGE__ . "->_watchdogFaultHandler(): Error occurred during processing.\n" . $errMsg;


    # Regardless of the error, destroy the Agent process and reinitialize it.
    # XXX: Sanity check this, eventually.
    HoneyClient::Agent->destroy();

    # Wait for a small amount of time, in order for the killed process to release
    # its control of the bound TCP port.
    sleep 5;

    $URL = HoneyClient::Agent->init();

    # Restore state information.
    $som = $stub->updateState(encode_base64(nfreeze($agentState)));
}

$stub = getClientHandle(address   => 'localhost',
                        namespace => 'HoneyClient::Agent',
                        fault_handler => \&_watchdogFaultHandler);
                
for (;;) {
    # TODO: Make this a programmatic value.
    sleep (5);
    $som = $stub->getState();
    if (defined($som) and (ref($som) eq "SOAP::SOM")) {
        $tempState = $som->result();
        if (defined($tempState)) {
            # Make sure the new state is parsable, before saving it.
            eval {
                $tempState = thaw(decode_base64($tempState));
            };
            if (!$@) {
                $agentState = $tempState;
            }
        }
    }
}

HoneyClient::Agent->destroy();
