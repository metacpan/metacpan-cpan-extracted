#!/usr/bin/perl
# Copyright Felipe Gasper 2021

use strict;
use warnings;

use DNS::Unbound;
use Net::DNS::Packet;
use Mail::SPF::Iterator;

use Getopt::Long qw(:config posix_default bundling);

#### Options
my ($resolver,$spfdfl,$pass_all);
GetOptions(
    'd|debug' => sub { Mail::SPF::Iterator->import( Debug => 1 ) },
    'h|help' => sub { usage() },
    'spfdfl=s' => \$spfdfl,
    'passall=s' => \$pass_all,
) or usage();

my $dns = DNS::Unbound->new();

my ($ip, $sender, $helo, $local) = @ARGV;
($ip && $sender) or usage();

my $spf = Mail::SPF::Iterator->new(
    $ip, $sender, $helo || q<>, $local,
    {
        default_spf => $spfdfl,
        pass_all => $pass_all,
    },
);

my ($result, @ans) = $spf->next; # initial query

while ( !$result ) {

    my @queries = @ans or die "no queries";

    for my $q (@queries) {
        my $query_id = $q->header()->id();
        my $question = ($q->question())[0];

        my ($name, $type) = map { $question->$_() } qw( name type );

        my $answer = $dns->resolve($name, $type);

        my $packet = Net::DNS::Packet->new( \$answer->answer_packet() );

        # $packet needs to have the same ID as the one from $q,
        # or else Mail::SPF::Iterator won’t recognize this result.
        $packet->header()->id($query_id);

        ($result,@ans) = $spf->next($packet);

        last if $result || @ans;
    }
}

print "Received-SPF: ".$spf->mailheader."\n";
print "Explanation: ".($spf->result)[3]."\n" if $result eq SPF_Fail;

#### USAGE
sub usage { die <<USAGE; }

This script demonstrates use of DNS::Unbound in blocking mode to run
Mail::SPF::Iterator’s queries.

Usage: $0 [options] Ip Sender [Helo] [Localname]
lookup SPF result, returns SPF-Received header

Example: $0 10.0.3.4 user\@example.com smtp.example.com smtp.example.local

Options:
 -d|--debug          enable debugging
 -h|--help           this help
 --spfdfl txt        use given SPF rule if none given for domain
 --pass_all policy   use given policy (like SoftFail) if rule matches all

USAGE
