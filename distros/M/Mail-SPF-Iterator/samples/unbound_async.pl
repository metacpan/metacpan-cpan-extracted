#!/usr/bin/perl
# Copyright Felipe Gasper 2021

use strict;
use warnings;

use feature 'current_sub';

use DNS::Unbound::Mojo;
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

my $dns = DNS::Unbound::Mojo->new();

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

my $big_promise = Mojo::Promise->new();

my %pending;

sub {
    my $run_spf = __SUB__;

    if ( $result ) {
        $big_promise->resolve();
        return;
    }

    my @queries = @ans or do {
        $big_promise->reject("no queries");
        return;
    };

    for my $q (@queries) {
        my $query_id = $q->header()->id();
        my $question = ($q->question())[0];

        my ($name, $type) = map { $question->$_() } qw( name type );

        my $query_p = $dns->resolve_async($name, $type);
        my $query_p_str = "$query_p";

        $pending{$query_p_str} = $query_p;

        $query_p->then( sub {
            my $answer = shift;

            delete $pending{$query_p_str};

            my $packet = Net::DNS::Packet->new( \$answer->answer_packet() );

            # $packet needs to have the same ID as the one from $q,
            # or else Mail::SPF::Iterator won’t recognize this result.
            $packet->header()->id($query_id);

            ($result,@ans) = $spf->next($packet);

            if ($result || @ans || !%pending) {
                my @still_pending = values %pending;
                %pending = ();
                $_->cancel() for @still_pending;

                $run_spf->();
            }
        } );
    }
}->();

$big_promise->wait();

print "Received-SPF: ".$spf->mailheader."\n";
print "Explanation: ".($spf->result)[3]."\n" if $result eq SPF_Fail;

#### USAGE
sub usage { die <<USAGE; }

This script demonstrates use of DNS::Unbound in non-blocking mode
(via Mojolicious) to run Mail::SPF::Iterator’s queries.

Usage: $0 [options] Ip Sender [Helo] [Localname]
lookup SPF result, returns SPF-Received header

Example: $0 10.0.3.4 user\@example.com smtp.example.com smtp.example.local

Options:
 -d|--debug          enable debugging
 -h|--help           this help
 --spfdfl txt        use given SPF rule if none given for domain
 --pass_all policy   use given policy (like SoftFail) if rule matches all

USAGE
