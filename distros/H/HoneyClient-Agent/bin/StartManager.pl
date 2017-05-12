#!perl -w -Ilib

# $Id: StartManager.pl 769 2007-07-26 18:44:38Z kindlund $

use strict;
use warnings;
use Carp ();

use Data::Dumper;

# Include Hash Serialization Utility Libraries
use Storable qw(nfreeze thaw);

# Include Base64 Libraries
use MIME::Base64 qw(encode_base64 decode_base64);

# Include Getopt Parser
use Getopt::Long;

use HoneyClient::Manager;

# We expect that the user will supply a single argument to this script.
# Namely, the initial URL that they want the Agent to use.
# They can however supply multiple urls which will be processed in order

# Change to 'HoneyClient::Agent::Driver::Browser::IE' or
#           'HoneyClient::Agent::Driver::Browser::FF'
my $driver = "HoneyClient::Agent::Driver::Browser::IE";
my $config = undef;
my $maxrel = -1;
my $nexturl = "";
my $urllist= "";

# TODO: Need --help option, along with sanity checking.
# TODO: Also need a decent POD for this code.
GetOptions('driver=s'             => \$driver,
           'master_vm_config=s'   => \$config,
           'url_list=s'           => \$urllist,
           'max_relative_links:i' => \$maxrel);

# Go through the list of urls to create the array
# Anything not associated with an option is a URL
# Grab those first and then get the ones from the file specified
my @urls;
push( @urls, @ARGV ); 
if( -e $urllist ){
    open URL, $urllist;
    push(@urls, <URL>);
}

# Get the first url from the list
# Create a hashtable in the form: url => 1 for links_to_visit 
chomp @urls;
my $firsturl = shift @urls;
my %remaining_urls;
foreach(@urls){
    # We assign our initial list of URLs a priority of 1000, so that
    # they'll be (likely to be) selected first, before going to any other
    # external URLs found from subsequent drive operations.
    $remaining_urls{$_} = 1000;
}

my $agentState = HoneyClient::Manager->run(
                    driver           => $driver,
                    master_vm_config => $config,
                    agent_state      => encode_base64(nfreeze({
                        $driver => {
                            next_link_to_visit => $firsturl,
                            max_relative_links_to_visit => $maxrel,
                            links_to_visit => \%remaining_urls,
                         },
                    })), 
                 );

