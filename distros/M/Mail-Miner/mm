#!/usr/bin/perl
use strict;
use Mail::Miner;
use Mail::Miner::Mail;
use Mail::Miner::Attachment;
use Getopt::Long;
my %options;

GetOptions (\%options, 
    "detach=i", 
    "summary", 
    "verbose",
    "help",
    "debug",
    (map {$_.$Mail::Miner::Mail::basic{$_}{type} } 
        keys %Mail::Miner::Mail::basic),
    (map {$_->{keyword}.$_->{type}}
        values %Mail::Miner::recognisers)
) or exit 1;

$Mail::Miner::Message::DEBUG =1 if $options{debug};
delete $options{debug};
help() if $options{help};

if ($options{detach}) {
    Mail::Miner::Attachment::detach($options{detach});
} else {
    my $summary = delete $options{summary};
    my $verbose = delete $options{verbose};
    my @matches = Mail::Miner::Mail->select(%options);
    my @recog;
    if (@recog = grep {$Mail::Miner::plugins{$_}} keys %options) { # Recog search
        $summary = !$verbose;
    }
    if ($summary) {
        Mail::Miner::Mail->display_summary(\@recog,@matches);
    } else {
        Mail::Miner::Mail->display_verbose(@matches)
    }
}

sub help {
    print <<EOF;
This is mm, version $Mail::Miner::VERSION

Usage:
 mm --detach 1234 # Detach attachment 1234
 mm [options]     # Find and report messages from the database

Presently available options include:

 --debug - Provide debugging output
 --summary - Give a brief listing of the output
 --verbose - Force a mailbox format output
 --help - You're reading it

EOF

for (keys %Mail::Miner::Mail::basic) { 
    print " --$_ - ".$Mail::Miner::Mail::basic{$_}{help}."\n";
}
for (values %Mail::Miner::recognisers) {
    print " --".$_->{keyword}." - ". $_->{help}."\n";
}

exit 0;
}
