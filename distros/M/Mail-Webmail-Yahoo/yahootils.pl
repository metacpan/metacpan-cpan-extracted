#!/usr/bin/perl -w

#  (C)  Simon Drabble   2003,2003
#  sdrabble@cpan.org	 2002/03/22
#  $Id: yahootils.pl,v 1.4 2003/10/10 15:44:03 simon Exp $
#


use strict;

use Mail::Webmail::Yahoo;
use Getopt::Long;


# With only username & password arguments, acts like 'snagmail.pl'.


my %opts;
# All options are called in long-opt format (--option)
#
#  FUTURE actions (not implemented yet)
#    list  : Lists Subject:/From:/Date: in specified folders
#    search: Yeah!
#    delete: Deletes messages by (search?) criteria



# Set send flags - may be overridden on cmd-line
$opts{flags} = $ENV{MWY_SEND_FLAGS} || '';

$opts{get_folders}   = [];
$opts{empty_folders} = [];
$opts{to}  = [];
$opts{cc}  = [];
$opts{bcc} = [];
$opts{flags}= 0;

# Parse @ARGV..
GetOptions(
# General options
		'username=s' => \$opts{user},
		'password:s' => \$opts{pass}, # password can be passed via STDIN
#		'action=s'   => \$opts{action}, ***DEPRECATED***
		'cookies=s'  => \$opts{cookies},
		'trace=i'    => \$opts{trace},
		'debug!'     => \$opts{debug},

# Action options
		'send'       => sub { $opts{actions}->{send} = 1 },
		'get:s'      => sub {
				$opts{actions}->{get} = 1;
				push @{$opts{get_folders}},   $_[1] || $ENV{MWY_INBOX} || 'Inbox';
				},
		'empty:s'    => sub {
				$opts{actions}->{empty} = 1;
				push @{$opts{empty_folders}}, $_[1] || $ENV{MWY_TRASH} || 'Trash';
				},
		'folders'    => sub { $opts{actions}->{folders} = 1},
		
# Action-specific options
#		'folder=s'   => \$opts{folder}, ***DEPRECATED***
		'to=s'       =>  $opts{to},
		'cc=s'       =>  $opts{cc},
		'bcc=s'      =>  $opts{bcc},
		'subject=s'  => \$opts{subject},
		'message=s'  => \$opts{message},
		'flag=s'     => sub {
				my $v = $_[1];
				if ($v =~ /^\d+$/) {	# Numeric flags ok
					$opts{flags} |= $v;
				} else {              # as are things like 'MOVE_ON_READ'
					for my $f (YAHOO_MSG_FLAGS) {
						if (uc $v eq $f) {
							$opts{flags} |= &{\&{uc $v}}; # constants are really functions
						}
					} # loop through possible flags
				} # non-numeric flag passed
			},
		'moveto=s'   => \$opts{moveto},

# Utility options
		'help'       => sub { &usage;      exit },
		'examples'   => sub { &examples;   exit },
		'list-flags' => sub { &list_flags; exit },
	); # end of GetOptions


&usage, die"\n" unless $opts{user};

# Allow the password to be entered via stdin - hides it from the command line.
# Beware of shoulder-surfers!
if (!$opts{pass}) {
	print "Password: ";
	my $p = <STDIN>;
	chomp $p;
	$opts{pass} = $p or &usage, die;
}


# Set up some defaults..
$opts{cookies} ||= '~/.webmail-cookies';
unless ($opts{actions}) {
	$opts{actions} = {get => 1};
	push @{$opts{get_folders}}, $ENV{MWY_INBOX} || 'Inbox';
}


# Defines what-to-do-with-which
my $dispatch = {
	empty    => \&do_empty,
	get      => \&do_get,
	send     => \&do_send,
	folders  => \&do_folders,
};


# Check all actions before continuing..
for (keys %{$opts{action}}) {
	&usage, die"\n" unless $dispatch->{$_};
}



# Login first
my $yahoo = new Mail::Webmail::Yahoo(
		username => $opts{user},
		password => $opts{pass},
		cookie_file => $opts{cookies},
		) or die $@;

$| = 1;


# Set the trace level
$yahoo->trace($opts{trace} || 0);

# Finally perform the require actions
for (keys %{$opts{actions}}) {
	&{$dispatch->{$_}}($yahoo, \%opts);
}

# ..and we're done
exit;


sub usage
{
	print qq{
$0 --user <username> [--pass <password>] [--options]
  General options (apply to all actions)  (+ = mandatory)
    user   : username+
    pass   : password+ (may be supplied via STDIN)
    cookies: where to load/store cookies (default= ~/.webmail-cookies)
    trace  : sets the Yahoo.pm trace level
    debug  : sets the MessageParser.pm debug level (Not yet implemented fully)

    help   : Display this screen and exit
  examples : Display a list of examples and exit
 list-flags: Display a list of flags understood by Yahoo.pm and exit
 
  Action-specific options (* = may be repeated) [used by which actions]
    to     : To: field of message* [send]
    cc     : Cc: field of message* [send]
    bcc    : BCc: field of message* [send]
    subject: Subject: field of message [send]
    message: Message body [send]
    flag   : Message flags [send,get] 
    moveto : Folder to move read messages to (required unless MWY_MOVETO)
 
  Valid actions
    send : Sends a message :)
    get  : Gets all messages within folders
    empty: Empties specified folders -- NOT the same as delete!
  folders: Displays a list of folders
 

  Also the following ENV vars are recognised, which may be overridden by the
  above options:
 
  MWY_SEND_FLAGS   : Default flags used when sending
  MWY_INBOX        : If --get specified without a folder
  MWY_TRASH        : If --empty specified without a folder to empty
  MWT_MOVETO       : If --moveto specified without a target folder
  
  Flags passed in via --flag or stored in MWY_SEND_FLAGS may be specified as
  either a numeric value, or as Mail::Webmail::Yahoo flag constants, for
  example, DELETE_ON_READ ATTACH_SIG.
};	
}



sub examples
{
	print <<"EOT";
For clarity, --user and --pass parameters are shown as [user] in some examples.

Examples:

To download your Inbox, the following are normally equivalent:
  $0 --user Yahooser --pass xxxx
  $0 --user Yahooser --pass xxxx --get
  $0 --user Yahooser --pass xxxx --get Inbox
  MWY_INBOX=Inbox $0 --user Yahooser --pass xxxx
  MWY_INBOX=Inbox $0 --user Yahooser --pass xxxx --get

The same thing, deleting downloaded messages:
  $0 [user] --flag DELETE_ON_READ

To send a simple message:
  $0 [user] --send \\
		--to user\@server.com \\
		--subject 'Make \$\$\$ fast!' \\
		--message "I'll show you how"

The same thing, saving a copy to the 'Sent' folder:
  $0 [user] --send \\
		--to user\@server.com \\
		--subject 'Make \$\$\$ fast!' \\
		--message "I'll show you how" \\
		--flag SAVE_COPY_TO_SENT_FOLDER

Or, equivalent:
  $0 [user] --send \\
		--to user\@server.com \\
		--subject 'Make \$\$\$ fast!' \\
		--message "I'll show you how" \\
		--flag 1


EOT
}



sub list_flags
{
	print 'Flag', ' 'x 46, 'Numeric value', "\n";
	for (YAHOO_MSG_FLAGS) { printf "%-40s%s%8d\n", $_, ' 'x 10, &{\&{$_}} }
}



# Empties all folders in $args->{empty_folders}
sub do_empty
{
	my ($y, $args) = @_;

	for my $f (@{$args->{empty_folders}}) {
		if ($y->empty($f)) {
			print "$f.. emptied!\n";
		} else {
			print "$f.. $@\n";
		}
	}
}



# Downloads all messages in folders in $args->{get_folders}. Messages are
# saved to "$username_$folder"
sub do_get
{
	my ($y, $args) = @_;

	my $flags = $args->{flags} || 0;
	my $moveto = $args->{moveto} || $ENV{MWY_MOVETO};

	if ($flags & MOVE_ON_READ && $flags & DELETE_ON_READ) {
		warn "do_get: MOVE_ON_READ and DELETE_ON_READ are mutually incompatible. Messages will not be deleted when read.\n";
	  $flags ^= DELETE_ON_READ;
	}

	if ($flags & MOVE_ON_READ and !$moveto) {
		die "do_get: MOVE_ON_READ but no folder to move to!\n";
	}
	if (!($flags & MOVE_ON_READ) and $moveto) {
		warn "do_get: MOVE_ON_READ not specified, although you provided a folder.\n";
	}

	for my $folder (@{$args->{get_folders}}) {

		my @messages = $y->get_mail_messages($folder, 'all', $flags, $moveto);
		print "Message Headers in $folder: ", 0+@messages, "\n";
		print "Messages will be delivered to ./$args->{user}_$folder.\n";
		if ($flags & DELETE_ON_READ && !($flags & MOVE_ON_READ)) {
				print "Messages will be deleted from server after download.\n";
		}
		if ($moveto) {
			if ($flags & MOVE_ON_READ) {
				print "Messages will be moved to $moveto after download.\n";
			}
		}

# TODO: --output/--append for messages (default=STDOUT? - useful for passing
# into procmail etc)
		open INBOX, ">$args->{user}_$folder";
		for (@messages) { print INBOX $_->as_mbox_string }
		close INBOX;
		print "\n";

	}

}



# Sends a mail message.
sub do_send
{
	my ($y, $args) = @_;
# Require a recipient and a subject.
	unless ((@{$args->{to}}||@{$args->{cc}}||@{$args->{bcc}}) &&
			$args->{subject}) {
			die << 'EOT';
do_send: usage: --send --to=recipient --subject=Subject --message=msg_body
EOT
	}
# If not found, read message from stdin
	unless ($args->{message}) {
		while (<STDIN>) {
			last if /^\.\s*$/;
			$args->{message} .= $_;
		}
	}
	
	$y->send(
			$args->{to},                    # To
			$args->{subject},               # Subject
			$args->{message},               # Body
			$args->{cc}  || '',             # Cc
			$args->{bcc} || '',             # BCc
			$args->{flags},                 # flags
		);
}



# TODO: get message count in each folder
sub do_folders
{
	my ($y) = @_;
	print join("\n", $y->get_folder_list), "\n";
}


__END__

Actions are passed as --send, --get etc rather than --action send, since the
former allows multiple actions to be performed with only one connection to
Yahoo. The same could be achieved via making $opts{action} an arrayref, but
this would lead to problems separating out other arguments, for example:

  --action get --folder Inbox --action empty --folder Trash

would be too reliant on the argument order.

Some actions (e.g. send and search) may have conflicting options at some time
in the future.

--send --subject "Make $$$ Fast!"
--search --subject "From a friend"

If this happens the ability to perform both these actions at once will
perforce be restricted.

