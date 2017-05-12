#!/usr/bin/perl -w

package IRC::Bot::Log2;

use Moose;
extends 'IRC::Bot::Log::Extended';

use URI::Find;

augment pre_insert => sub {
    my ($self, $file_ref, $message_ref) = @_;
    
    # skip "[#catalyst 00:42] JOIN: Fayland"
    if ( $$message_ref =~ /\s+(JOIN|PART)\:\s+(\S+)$/ ) {
        $$message_ref = '';
    }
    # skip [#catalyst 05:59] MODE: +o zamolxes by: Bender
    if ( $$message_ref =~ /\s+MODE\:\s+\+[oi]/ ) {
        $$message_ref = '';
    }
    # skip "[#catalyst 03:33] Action: *GumbyNET2 cpan.testers: FAIL Catalyst-View-Jemplate-0.06 i386-linux-thread-multi 2.4.21-27.0.2.elsmp perl-5.8.6 fayland@gmail.com ("Fayland Lam") #2416326"
    if ( $$message_ref =~ /\s+cpan\.testers\:\s+FAIL/ ) {
        $$message_ref = '';
    }
    
    return unless ( length($$message_ref) );
    
    # change filename
    $$file_ref .= '.html';
    
    # HTML-lize
    $$message_ref =~ s/\</\&lt\;/isg;
    
    # find URIs
    my $finder = URI::Find->new(
        sub {
            my ( $uri, $orig_uri ) = @_;
            return qq|<a href="$uri">$orig_uri</a>|;
        }
    );
    $finder->find( $message_ref );

    # [#padre 20:25] Action: *Fayland read Kephra source code to see if there is something to borrow
    if ( $$message_ref =~ /\s+Action\:\s+\S+/ ) {
         $$message_ref =~ s/Action\:\s+/\<i\>/;
         $$message_ref .= '</i>';
    }

    $$message_ref .= "<br />";
};

package IRC::Bot2;

use Moose;
require IRC::Bot;
extends 'IRC::Bot';

after 'bot_start' => sub {
    my $self = shift;

    no warnings; 
    $IRC::Bot::log =  IRC::Bot::Log2->new(
        Path          => $self->{'LogPath'},
        split_channel => 1,
        split_day     => 1,
    );
};

package main;

use Proc::ProcessTable;
use File::Basename;
sub check_cmd_run {

    my $p = new Proc::ProcessTable( 'cache_ttys' => 1 );
    my $all = $p->table;
    my $pid = 0; # this file's pid
    my $please_kill = 0;
    foreach my $one (@$all) {
        my $basename = basename($0);
	if ( $one->cmndline =~ /perl/ and $one->state eq 'defunct' ) {
		$please_kill = 1;
	}
        if ($one->cmndline =~ /$basename/ and $one->pid != $$) {
	    $pid = $one->pid;
	    last;
        }
    }
    if ($pid and not $please_kill) {
	return 1;
    }
    kill(9, $pid) if $pid;
    return 0;
}

if ( check_cmd_run() ) {
    print "$0 is on, exits\n";
    exit;
}

# Initialize new object
my $bot = IRC::Bot2->new(
    Debug    => 0,
    Nick     => 'Fayland_logger',
    Server   => 'irc.perl.org',
    Password => '',
    Port     => '6667',
    Username => 'Fayland_Logger',
    Ircname  => 'Fayland_Logger',
    Channels => [ '#moose', '#catalyst', '#dbix-class', '#reaction', '#kiokudb', '#padre', '#mojo', '#parrot' ],
    LogPath  => '/home/faylandfoorum/irclog.foorumbbs.com/',
    NSPass   => 'nickservpass'
);

# Daemonize process
$bot->daemon();

# Run the bot
$bot->run();

1;
