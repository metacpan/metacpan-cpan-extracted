#!perl

use strict;
use warnings;

#use Sys::Hostname;
#use LWP;

# n.b. THE TESTING SERVER IS NOT CURRENTLY OPERATIONAL

#BEGIN { die "Cannot run tests with test_config" unless (-f 't/test_config'); }

#open(FILE,'< t/test_config');
#my $user = <FILE>; chomp $user;
#my $password = <FILE>; chomp $password;

use Test::More tests => 1;

#my $string = hostname().join(':',localtime(time()));

BEGIN { use_ok( 'Jabber::SimpleSend',qw( send_jabber_message ) ) }

#send_jabber_message({
#                       user     => $user,
#                       password => $password,
#                       target   => 'jsst@jabber.mccarroll.org.uk',
#                       subject  => 'testing',
#                       message  => $string});


#print STDERR "\nSleeping for 5 seconds to allow the bot to do its work\n";
#sleep 5; # give it some

#my $url = 'http://www.mccarroll.org.uk/~gem/jsst';
#my $ua = LWP::UserAgent->new;
#my $response = $ua->get($url);
#my $results = {};
#ok($response->is_success);
#ok($response->content =~ m/$string/);
