#!/usr/bin/env perl
use strict;
use warnings;
use threads;
use threads::shared;
use Socket::Class;
use Time::HiRes;

use diagnostics;

local $| = 1;
	

my $version = 3;
my $default_host = "127.0.0.1";

$SIG{'INT'} = \&quit;
$SIG{'TERM'} = \&quit;

our $global_client;
our $RUNNING = 1;
our $only_one_question = 0;
our $ready_for_new_question = 1;

sub quit {
	$RUNNING = 0;
	$$global_client->free();
    exit(0);
}

sub print_welcome {
	print " JEliza shell client rev." . $version . "\n\n -> Connecting...\n";
}

sub get_host {
	my $host = shift;
	if ($host ne "") {
		return $host;
	}
	
	print " -> Host (default " . $default_host . "): ";
	$host = <STDIN>;
	chop($host);
	return $host;
}

sub create_socket {
	my $host = shift;
	if ($host eq "") {
		$host = $default_host;
	}
	
	my $client = Socket::Class->new(
     	'remote_addr' => $host,
    	'remote_port' => 5173,
    	'blocking' => 0
	) or die Socket::Class->error;
	$global_client = \$client;
	$client->writeline("Mensch\n");
	$client->writeline("Mensch\n");
	return \$client;
}

sub exit_if {
	my ($client, $exit) = @_;
	
	if ($exit) {
		$$client->writeline("EXIT:.\n");
		print "exit.\n";
		exit;
	}
}

sub answer_if {
	my ($client, $text) = @_;

	if ($text eq "") {
		print "\nMensch: ";
		$ready_for_new_question = 0;
		$text = <STDIN>;
		chomp($text);
		$ready_for_new_question = 1;
	}

	if ($text ne "") {
		$text =~ s/[:]/::/igm;
		$$client->writeline("QUESTION:" . $text . "\n");
	}
}

sub microtime {
	my( $sec, $usec ) = &Time::HiRes::gettimeofday();
	return $sec;
}

sub client_thread {
	my ($sock) = @_;
	my $trhd = threads->self;
	my $tid = $trhd->tid;
	my $got;
	my $buf;
	my $line;
	my $already_asked_for_word_type = "";
	my $already_asked_for_genus = "";
	my $already_asked_for_noun_or_not = "";
	while( $RUNNING ) {
		my $t1 = microtime();
		my $display = "";
		my $first_time = 1;
		
		while (microtime() < $t1*5 || $first_time) {
			if (!$sock->is_readable(3) && !$first_time) {
				last;
			}
			$buf = "";
			$line = "";
			while ($buf ne "\n") {
				$line .= $buf;
				unless ($sock->is_readable(3)) {
					last;
				}
				$got = $sock->read($buf, 1);
				if (!defined $got) {
					# error
					warn $sock->error;
					last;
				}
				elsif (!$got) {
					$trhd->yield();
					$sock->wait(1);
					next;
				}
			}
			
#			print $line . "\n";
			if ($line =~ /DISPLAY/) {
				$line =~ s@DISPLAY:@@g;
				$line =~ s@<br>@\n@g;
				$line =~ s@<b>@@g;
				$line =~ s@::</b>@:@g;
				
				$display = $line;
				$t1 = microtime();
				$first_time = 0;

				$already_asked_for_noun_or_not = "";
				$already_asked_for_genus = "";
				$already_asked_for_word_type = "";
			}
			if ($line =~ /CLEAN_WORD_TYPE/) {
				$already_asked_for_word_type = "";
			}
			if ($line =~ /GET_WORD_TYPE/) {
				$line =~ s@GET_WORD_TYPE:@@g;
				if ($already_asked_for_word_type ne $line) { #$already_asked_for_word_type || 
					$already_asked_for_word_type = $line;
					
					print `clear`;
					print "
 Which word type is '" . $line . "'?
 
 1. verb
 2. noun oder name
 3. adjective oder adverb
 4. pronoun
 5. question word or conjunction
 6. preposition
 7. interjection
 
 Please enter the number above.
 
 Number:\n";
					
					my $num = <STDIN>;
					chomp $num;
					$num = 2 if ($num =~ /4/);
					
					print "Word type sent to server:" . $num . "\n";
					$sock->writeline("HERE_IS_WORD_TYPE:" . $num);
				}
			}
			else {
				$already_asked_for_word_type = "";
			}
			if ($line =~ /CLEAN_GENUS/) {
				$already_asked_for_genus = "";
			}
			if ($line =~ /GET_GENUS/) {
				$line =~ s@GET_GENUS:@@g;
				if ($already_asked_for_genus ne $line) { #$already_asked_for_genus || 
					$already_asked_for_genus = $line;
					
					print `clear`;
					print "
 Which gender is '" . $line . "'?
 
 1. male
 2. female
 3. neuter
 
 Please enter the number above.
 
 Number:\n";
					
					my $num = <STDIN>;
					chomp $num;
					$num = 2 if ($num =~ /4/);
					
					print "Gender sent to server:" . $num . "\n";
					$sock->writeline("HERE_IS_GENUS:" . $num);
				}
			}
			if ($line =~ /CLEAN_NOUN_OR_NOT/) {
				$already_asked_for_noun_or_not = "";
			}
			if ($line =~ /GET_NOUN_OR_NOT/) {
				$line =~ s@GET_NOUN_OR_NOT:@@g;
				if ($already_asked_for_noun_or_not ne $line) {
					$already_asked_for_noun_or_not = $line;
					
					print `clear`;
					print "
 Is '" . $line . "' meant as a noun here?
 
 1. '" . $line . "' is a noun
 2. '" . $line . "' is not a noun
 
 Please enter the number above.
 
 Number:\n";
					
					my $num = <STDIN>;
					chomp $num;
					
					print "Answer sent to server:" . $num . "\n";
					$sock->writeline("HERE_IS_NOUN_OR_NOT:" . $num);
					print "HERE_IS_NOUN_OR_NOT:" . $num . "\n";
					print `clear`;
					print $display . "\n";
					print "Please wait...\n";
				}
			}
			else {
				$already_asked_for_noun_or_not = "";
			}
		}
		
		print `clear`;
		print $display . "\n";
		unless ($only_one_question) {
			answer_if(\$sock, "");
		}
	}
	$sock->free();
	$trhd->detach() if $RUNNING;
	return 1;
}

sub parse_args {
	my $ip = "";
	my $text = "";
	my $exit = 0;
	foreach my $n (0 .. $#ARGV) {
		my $arg = $ARGV[$n];
		my $prev_arg = "";
		if ($n != 0) {
			$prev_arg = $ARGV[$n-1];
		}
		
		if ($prev_arg =~ /--ip/) {
			$ip = $arg;
		}
		if ($prev_arg =~ /--text/) {
			$text = $arg;
		}
		if ($prev_arg =~ /--exit/ || $arg =~ /--exit/) {
			$exit = 1;
		}
	}
	unless ($text eq "") {
		$only_one_question = 1;
	}
	
	my @ret = ($ip, $text, $exit);
	return @ret;
}

sub loop {
	my $client = shift;
	client_thread($$client);

#	while( $RUNNING ) {
#		$$global_client->wait( 100 );
#	}
}

sub main {
	print_welcome();
	
	my ($host, $text, $exit) = parse_args();
	
	$host = get_host($host);
	my $client = create_socket($host);
	
	exit_if($client, $exit);
	answer_if($client, $text);
	
	loop($client);
}

main();

exit;
  
