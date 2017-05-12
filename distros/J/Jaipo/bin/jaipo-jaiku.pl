#!/usr/bin/perl
#
# Jaipo - JAIku commandline POster
# Version: 0.0.6
# Original Author: BlueT<BlueT@BlueT.org>
# CC-BY

# Dependency - Needs
# Net/Jaiku.pm (base on JSON/Any.pm)
#					LWP/UserAgent.pm
#					Params/Validate.pm



#use utf8;
#~ use Data::Dumper;
use Net::Jaiku;
use feature qw(:5.10);


# If and only if you don't want to use Per-User settings,
# uncomment the following two lines and fill in the neccessary informations.
#$ID = "My-Login-ID"		# your login ID 
#$API_KEY = "My-API-Key"	# plz check http://api.jaiku.com/ to get your API key


#####
# Read cli args
#####

$message = shift;
$location = shift;
$comment = shift;
#print $message and exit;


#####
# Identify command
#####

# Guessing you you wanna do.
if ($message =~ /^r$/){
	$location? $reply = 1 : $read = 1;
} elsif ($message =~ /^l$/) {
	$loc = 1;
} elsif ($message =~ /^c$/) {
	$check = 1;
} elsif ($message =~ /^i$/) {
	$info = 1;
} elsif ($message =~ /^f$/) {
	$friend = 1;
} else { $send_msg = 1 }


#####
# read User ID and API Key
#####

$ID ||= &id_key()->[0];
$API_KEY ||= &id_key()->[1];

#~ print "ID: $ID, KEY: $API_KEY\n";


#####
# Initialize Net::Jaiku
#####

say "\nInitialing connection.\n";
my $jaiku = new Net::Jaiku(
	username => $ID,
	userkey  => $API_KEY
);


#####
# Prepare to call the right method
#####

# Do what you want.
# Use case.
if ($send_msg) {
	say "\033[1mplz type your message (or not :p):\033[0m ";
	$message ||= <STDIN>;
	
	### my $rv = send_msg($message, "jaiku");
	#
	say "\033[1mSending message...\033[0m\n";
	my $rv = $jaiku->setPresence(
		message => $message
	);
	#
	###
	
	$rv? say "\033[1mMessage Post.\033[0m\n" : say "\033[1mMessage not posted, something wrong with your network or msg too long?\033[0m\n";
} elsif ($loc) {
	
	### my $rv = set_location($message, "jaiku");
	#
	my $rv = $jaiku->setPresence(
		location => $location
	);
	#
	###
	
	$rv? say "\033[1mOkay, you moved to a new place.\033[0m\n" : say "\033[1mSet location failed, you're still at where you were...\033[0m\n";
} elsif ($check) {
	
	# check if there's any unread message
	# this fuction only compare the last IDs with IDs in $HOST/.jaipo/last-id.log
	# the only way to update IDs in log is to $ jaipo r
	my $feeds = $jaiku->getContactsFeed();
	my $post = shift @{$feeds->stream};
	my $have_new = &compare_id($post->id,$post->comment_id);
	
	$have_new? say "\033[1mYou've Got Male!\033[0m\n\n\nOops... I mean mail...\n" : say "You're alone, lonely, you don't have friend... anyway you don't have any new msg.\n";
	
} elsif ($read) {
	
	my ($last_id,$last_comment_id);
	
	my $feeds = $jaiku->getContactsFeed();
	#~ print Dumper $feeds; exit;
	for my $post ( reverse @{$feeds->stream}) {
		
		say "\033[1mPostID:\033[0m " . ($post->id? $post->id : "\t\t") . "\t";
		say "\033[1mUserNick:\033[0m " . $post->user->nick . " ( ". ($post->user->first_name? $post->user->first_name : $post->user->nick =~ /^#/?"_Channel_":"N/A" ) ." ". $post->user->last_name ." )\n";
		say "\033[1mPost Time:\033[0m " . $post->created_at_relative . "\n";
		
		
		say $post->{'title'} . "\n\n";
		say "\033[1m". $post->comments . " Comments\033[0m\n" if $post->comments;
		
		if ($post->comment_id) {
			
			my $origID = $post->url;
			$origID =~ s/^[\w\W]+?\/(\d+)#c-\d+$/$1/;
			
			say "\t\033[1mOringinal post\033[0m (ID: " . $origID ." ): " .$post->entry_title ."\n";
			say "\t\033[1mComment content\033[0m (ID: ". $post->comment_id ." ):\n";
			say "\t$_\n" for split/\n/,$post->content;
			
		}
		say "-" x 8 . "\n\n";
		
		($last_id, $last_comment_id) = ($post->id, $post->comment_id);
		$total_posts++;
		
	}
	say "\033[1mTotal $total_posts Posts.\033[0m\n";
	
	&log_id($last_id, $last_comment_id) or die $!;
	
} elsif ($info) {
	
	my $userinfo = $jaiku->getUserInfo(
		user => $location
	);
	say Dumper $userinfo;
	
} elsif ($friend) {
	
	my $friends = $jaiku->getUserInfo(
		user => $location
	)->contacts;
	#~ print Dumper $friends;
	my $count;
	for my $contact (@$friends) {
		#~ print Dumper $contact;
		my $url = $contact->url;
		$url =~ s{\\/}{/}gi;
		say ++$count ."\.\t".($contact->nick =~ /^#/? "" : "\033[1m").$contact->nick .($contact->nick =~ /^#/? "" : "\033[0m").&tabs($contact->nick)."$url". &tabs($contact->nick) ."( ". ($contact->nick =~ /^#/? "_Channel_" : $contact->first_name ." ". $contact->last_name) ." )\n";
	};
	
} elsif ($reply) {
	say "\033[1mSorry, the reply/comment function does not supported by Official Jaiku API yet...\033[0m\n";
} else { say "\033[1mIf you see this message, it means that you're doing some black magic. Plz contact BlueT<at>BlueT.org ASAP!\033[0m\n"; }

#####

sub log_id {
	# write those id to a file, so that we can check later
	if (not -e "$ENV{HOME}/.jaipo") {
		say "\nThis is the \033[1mfirst time\033[0m you try me?\n";
		mkdir("$ENV{HOME}/.jaipo") or die $!;
	}
	if (not -e "$ENV{HOME}/.jaipo/last-id.log") {
		say "\033[1mThis might be kinda hurt\033[0m..........just kidding :p\n";
	}
	open LOG, ">$ENV{HOME}/.jaipo/last-id.log" or die $!;
	#~ print LOG "$_\n" for @_;
	#~ print "Current: $_[0]-$_[1]";
	say LOG "$_[0]-$_[1]";
	close LOG;
}

sub compare_id {
	# compare the (PostID, CommentID)
	my @old_id;
	if (not -e "$ENV{HOME}/.jaipo" or not -e "$ENV{HOME}/.jaipo/last-id.log") {
		say "\nYou \033[1mCan Not\033[0m check about if I have \033[1mAnything NEW For You\033[0m without \033[1mTouching Me First!!\033[0m\n";
		say "So Now, Plz read me by using \033[1m \$ jaipo r\033[0m  before you wanna do anything : 3\n";
		exit;
	}
	open LOG, "<$ENV{HOME}/.jaipo/last-id.log" or die $!;
	@old_id = split/-/,$_ for <LOG>;
	close LOG;
	( $old_id[0] == $_[0] and $old_id[1] == $_[1] ) ? 0 : 1 ;
}

sub id_key {
	# check user name and API key
	my @user_login;
	if (not -e "$ENV{HOME}/.jaipo" or not -e "$ENV{HOME}/.jaipo/user.login") {
		say "no user.login config file\n";
		exit;
	}
	open USER, "<$ENV{HOME}/.jaipo/user.login" or die $!;
	while (<USER>) {chomp; push @user_login, $_};
	close USER;
	return \@user_login;
}

sub tabs {
	my $string = shift;
	length $string < 8 ? return "\t\t\t" : length $string < 18 ? return "\t\t" : return "\t" ;;
}

1;

__END__

Your ~/.jaipo/user.login needs the following two lines.

My-Login-ID		# your login ID 
My-API-Key		# plz check http://api.jaiku.com/ to get your API key
