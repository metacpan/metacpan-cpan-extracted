#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
# use Test::Ping;
# use Test::Output;
# use Fennec class => Log::Dispatch::Email::Async;
use lib './lib/';

#	for gmail.com accounts:
#	   sign in to gmail
#	   go to <https://myaccount.google.com/u/0/security#connectedapps>
#	   set 'Allow less secure apps: ON'\n"

my $args = {
	# genral 
		delay			=> '',					# delay between send/receive in secs
		tc				=> '3',					# number of threads to create
		delete		=> '1',					# delete email after checking
	# send emails - smtp 
		smtp_user	=> '',					# REQUIRED; sender's username
		smtp_pass	=> '',					# REQUIRED; sender's password
		to_addrs		=> '',					# REQUIRED; receiver addresses
		smtp_srvr	=> 'smtp.gmail.com',	# smtp server
		smtp_port	=> '587',				# smtp port
		auth			=> 'LOGIN',				# auth type
		tls			=> '1',					# tls required
	# verify sents - imap
	 	imap_users	=> '',					# REQUIRED; receiver usernames
		imap_pass	=> '',					# REQUIRED; receiver passwords
		imap_srvr	=> 'imap.gmail.com',	# imap server
		imap_port	=> '993',				# imap port
		use_ssl		=> '1',					# use ssl
		imap_folder	=> 'INBOX',				# imap folder
};

plan skip_all => "emailing details required; set in $0"
    unless(	$args->{delay} 
    	and	$args->{smtp_user}
    	and	$args->{smtp_pass}
    	and	$args->{to_addrs}
    	and	$args->{imap_users}
    	and	$args->{imap_pass}
    );

use_ok( 'Log::Dispatch::Email::Async' ) || print "Bail out!\n";			#  1

diag( "\nTesting Log::Dispatch::Email::Async $Log::Dispatch::Email::Async::VERSION, Perl $], $^X" );

# object
my $email = Log::Dispatch::Email::Async->new(
	# Log::Dispatch::Email::Async
		timeout			=> 30,
		thread_count	=> $args->{tc},
		stack_size		=>	4,
		debug_mode		=> 0,
	# Mail::Sender
		smtp => $args->{smtp_srvr},
		port => $args->{smtp_port},
		auth => $args->{auth},
		tls_required => $args->{tls},
		authid => $args->{smtp_user},
		authpwd => $args->{smtp_pass},
	# Log::Dispatch::Email
		buffered			=> 0,
		subject			=> "module testing log message from 'Log::Dispatch::Email::Async'",
		from				=> 'rats@sambaad.in',
		to					=> $args->{to_addrs},
	# Log::Dispatch::Output
		name				=> 'AsyncEmailModuleTesting',
		min_level		=> 5,
);

ok( defined $email, "module defined" );												#  2
isa_ok( $email, 'Log::Dispatch::Email::Async' );									#  3
can_ok( 'Log::Dispatch::Email::Async', qw/new send_email DESTROY/ );			#  4

# threads
is( $email->{thread_count}, $args->{tc}, "thread count is $args->{tc}" );	#  5
is( $#{$email->{thread}}, $args->{tc}, "has $args->{tc} threads" ); 			#  6
is( $email->{thread}[$_]->tid, $_, "thread $_ is active" ) 
	for 1 .. $email->{thread_count};														#  6 + $args->{tc} 

my $imaps = sncParams( $args );
my $sc_args = { email => $email, args => $args, imap_addrs => $imaps };

my $ec = 0;
ok( sendAndCheck( $sc_args, { 
	msg => "Message No. ". ++$ec 
} ), 'default subject, default single to' );											# 10 
ok( sendAndCheck( $sc_args, { 
	subject => "Message No. ". ++$ec, 
	msg => "Message No.$ec" 
} ), 'custom subject, default single to' );											# 11
ok( sendAndCheck( $sc_args, { 
	subject => "Message No. ". ++$ec, 
	to => [ $args->{to_addrs}[0] ], 
	msg => "Message No.$ec" 
} ), 'custom subject, custom single to' );											# 12
is( sendAndCheck( $sc_args, { 
	subject => "Message No. ". ++$ec, 
	to => $args->{to_addrs}, 
	msg => "Message No.$ec" 
} ), scalar(keys(%{$imaps})), 'custom subject, custom multiple to' );		# 13

TODO: {
	local $TODO = "not implemented yet";

	ok( undef, "load test with multiple emails, threads" );							# 14

	ok( undef, "load via Log4perl" );														# 15

	ok( undef, "test DESTROY - Test::Output for out/err msgs" );					# 16
}

done_testing( );

#  -----------------------------------------------------------------------------------
use Net::IMAP::Simple;
sub sendAndCheck {
	my ( $args, $msg ) = @_;

	my $message = $msg->{msg};
	$message = join( ", ", @{$msg->{to}} ) . "\n\n" . $message if defined $msg->{to};
	$message = $msg->{subject} . "\n\n" . $message if defined $msg->{subject};
	$args->{email}->send_email( message => $message );

	sleep $args->{args}{delay};

	my $tos = $msg->{to} || $args->{args}{to_addrs};

	my $matches = 0;
	for my $n ( 0 .. $#{$tos} ) {
		my $addr = $tos->[$n];
		my $rcvr = $args->{imap_addrs}{$addr};
		last unless $rcvr;

		my $imap = Net::IMAP::Simple->new( $rcvr->{srvr}, port => $rcvr->{port}, use_ssl => $rcvr->{ssl} )
			 or	die "cannot connect to imap server: $Net::IMAP::Simple::errstr\n";
		$imap->login( $rcvr->{user} => $rcvr->{pwd} ) or
			die "cannot login to Gmail: " . $imap->errstr . "\n";
		my $nm = $imap->select( $rcvr->{fldr} ) or
			die "cannot select folder $rcvr->{fldr}: " . $imap->errstr . "\n";

		my ( $mno ) = $imap->search_body( $msg->{msg} );
		if ( defined $mno ) {
			$matches += 1;
			$imap->delete($mno) if $args->{args}{delete};
		}
	}
	return $matches;
}
#  -----------------------------------------------------------------------------------
sub sncParams {
	my $args = shift;

	$args->{to_addrs}  = [ split /[, ;]+/, $args->{to_addrs} ];
	my @users = split /[, ;]+/, $args->{imap_users};
	my @pwds = split /[, ;]+/, $args->{imap_pass};
	my @srvrs = split /[, ;]+/, $args->{imap_srvr};
	my @ports = split /[, ;]+/, $args->{imap_port};
	my @ssls = split /[, ;]+/, $args->{use_ssl};
	my @fldrs = split /[, ;]+/, $args->{imap_folder};

	my $imaps = {};
	for my $n ( 0 .. $#{$args->{to_addrs}} ) {
		my $addr = $args->{to_addrs}[$n];
		$imaps->{$addr} = {};
		delete $imaps->{$addr}, last unless $users[$n];
		$imaps->{$addr}{user} = $users[$n];
		delete $imaps->{$addr}, last unless $pwds[$n];
		$imaps->{$addr}{pwd} = $pwds[$n];
		delete $imaps->{$addr}, last unless $srvrs[$n];
		$imaps->{$addr}{srvr} = $srvrs[$n];
		delete $imaps->{$addr}, last unless $ports[$n];
		$imaps->{$addr}{port} = $ports[$n];
		delete $imaps->{$addr}, last unless $ssls[$n];
		$imaps->{$addr}{ssl} = $ssls[$n];
		delete $imaps->{$addr}, last unless $fldrs[$n];
		$imaps->{$addr}{fldr} = $fldrs[$n];
	}
	return $imaps;
}
#  -----------------------------------------------------------------------------------
	# sub gatherTestEmailAccountInfo {
	# 	my ( $dly, $msg ) = @_;
	# 	my $ia = [
	# 		[ "\nfor gmail.com accounts:\n   sign in to gmail\n   go to <https://myaccount.google.com/u/0/security#connectedapps>\n   set 'Allow less secure apps: ON'\n"],
	# 		[ "Gathering email accounts information:" ],
	# 			[ 'tc', "number of threads to create", '3', $dly, $msg, ],
	# 			[ 'delay', "delay between send/receive in secs", '10', $dly, $msg, ],
	# 			[ 'delete', 'delete email after checking', 1, $dly, $msg, ],
	# 			[ 'domain', "email sever domain", "gmail.com", $dly, $msg, ],
	# 		[ 'Sending emails'],
	# 			[ 'smtp_user', "sender's username", '', $dly, $msg, ],
	# 			[ 'smtp_pass', "sender's password", '', $dly, $msg, ],
	# 		 	[ 'to_addrs', 'receiver addresses', '', $dly, $msg, ],
	# 			[ 'smtp_srvr', 'smtp server', "smtp.<domain>", $dly, $msg, ],
	# 			[ 'smtp_port', 'smtp port', '587', $dly, $msg, ],
	# 			[ 'auth', 'auth', 'LOGIN', $dly, $msg, ],
	# 			[ 'tls', 'tls required', '1', $dly, $msg, ],
	# 		[ 'Fetching emails - to verify proper sending' ],
	# 		 	[ 'imap_users', 'receiver usernames', '', $dly, $msg, ],
	# 			[ 'imap_pass', 'receiver passwords', '', $dly, $msg, ],
	# 			[ 'imap_srvr', 'imap server', "imap.<domain>", $dly, $msg, ],
	# 			[ 'imap_port', 'imap port', '993', $dly, $msg, ],
	# 			[ 'use_ssl', 'use ssl', '1', $dly, $msg, ],
	# 			[ 'imap_folder', 'imap folder', 'INBOX', $dly, $msg, ],
	# 		[ "Completed gathering email accounts information.\n" ],	
	# 	];
	# 	my $ih = {};
	# 	for my $line ( @$ia ) {
	# 		print( "$line->[0]\n" ), next if $#$line == 0;
	# 		$line->[2] =~ s/<([^>]+)>/$ih->{$1}/;
	# 		$ih->{$line->[0]} = ask( @$line[1..4] );
	# 		return unless defined $ih->{$line->[0]};
	# 	} 
	# 	return $ih;
	# }
	# #  -----------------------------------------------------------------------------------
	# use Term::ReadKey;
	# use Time::HiRes;
	# sub ask {
	# 	my ( $p, $as, $d, $sw ) = @_;

	# 	$p = "        $p" unless $p =~ /^confirm /;
	# 	$d ||= 5;
	# 	my $dly = $d * 10;
	# 	my $die = "No respomse in $d secs.";
	# 	$die .= "  $sw" if $sw;

	# 	ReadMode 3;
	# 	$| = 1;
	# 	my $c = '';
	# 	my $al = '';

	# 	eval {
	# 		local $SIG{ALRM} = sub {
	# 			$dly--	? printf( "\r%s(%d)%s%s", $p, int($dly/10), $as?" [$as]: ":": ", $al )
	# 					: die "\n\t$die\n"; 
	# 			Time::HiRes::ualarm(100_000);
	# 		};
	# 		Time::HiRes::ualarm(100_000);
	# 		while ( $c ne "\n" ) {
	# 			$c = getc;
	# 			$al .= $c;
	# 			$dly = $d * 10;
	# 		}
	# 		alarm 0;
	# 	};
	# 	ReadMode 0;
	# 	chomp $al;
	# 	printf( "\r%s(%d)%s%s\n", $p, int($dly/10), $as?" [$as]: ":": ", $al ? $al : $as );
	# 	if ( $@ ) { 
	# 		print $@; 
	# 		return undef; 
	# 	} elsif ( $al ) {	
	# 		$p =~ s/^       /confirm/ if $p =~ /^       /;
	# 		return ask( $p, $al, $d, $sw );
	# 	} elsif ( $as ) {	
	# 		return $as;
	# 	} 	else { 
	# 		print "$sw\n";
	# 		return undef;
	# 	}
	# }
#  -----------------------------------------------------------------------------------
