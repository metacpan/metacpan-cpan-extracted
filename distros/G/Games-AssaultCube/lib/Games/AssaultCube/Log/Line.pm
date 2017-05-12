# Declare our package
package Games::AssaultCube::Log::Line;
use strict; use warnings;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

# the factory constructor
sub new {
	my $class = shift;
	my $line = shift;
	my $subclass = shift;

	# sanity checking
	if ( ! defined $line or ! length $line ) {
		die "Please supply a valid line";
	}

	# Do we have a subclass to hand off the line?
	if ( defined $subclass ) {
		# object or coderef?
		if ( ref( $subclass ) eq 'CODE' ) {
			my $result = $subclass->( $line );
			if ( defined $result ) {
				return $result;
			}
		} else {
			my $result = $subclass->parse( $line );
			if ( defined $result ) {
				return $result;
			}
		}
	}

	# parse the line!
	return parse( $line );
}

sub create_subclass {
	my $line = shift;
	my $event = shift;
	my $data = shift;

	# Load the subclass we need
	eval "require Games::AssaultCube::Log::Line::$event";	## no critic (ProhibitStringyEval)
	if ( $@ ) {
		die "Unable to load our subclass: $@";
	}

	# Store the data
	$data->{'event'} = $event;
	$data->{'line'} = $line;

	# create the object!
	return "Games::AssaultCube::Log::Line::$event"->new( $data );
}

sub parse {
	my $text = shift;
	if ($text =~ m!^\[([\d\.]*)\]\s+(.+)$!) {
		my $ip = $1;
		my $etext = $2;
		if ($ip) {
			if ($etext =~ m!^([^\s]+)\s+(fragged|gibbed)\s+(his\s+teammate\s+)?(.+)$!) {
				return create_subclass($text,'Killed',{
					nick	=> $1,
					gib	=> $2 eq 'gibbed' ? 1 : 0,
					tk	=> defined $3 ? 1 : 0,
					victim	=> $4,
					ip	=> $ip,
				});
			} elsif ($etext =~ m!^([^\s]+)\s+says(?:\s+to\s+team\s+(\w+))?:\s+\'(.*)\'(,\s+SPAM\s+detected)?$!) {
				# TODO what should we do with $2, the team name?
				return create_subclass($text,'Says',{
					nick	=> $1,
					isteam	=> defined $2 ? 1 : 0,
					text	=> $3,
					spam	=> defined $4 ? 1 : 0,
					ip	=> $ip,
				});
			} elsif ($etext =~ m!^disconnected\s+client\s+(.*)$!) {
				return create_subclass($text,'ClientDisconnected',{
					( defined $1 ? ( nick => $1 ) : () ),
					ip	=> $ip,
					forced	=> 0,
				});
			} elsif ($etext =~ m!^disconnecting\s+client\s+([^\s]*)\s+\((.+)\)$!) {
				return create_subclass($text,'ClientDisconnected',{
					nick	=> $1,
					reason	=> $2,
					ip	=> $ip,
					forced	=> 1,
				});
			} elsif ($etext eq 'client connected') {
				return create_subclass($text,'ClientConnected',{
					ip	=> $ip,
				});
			} elsif ($etext =~ m!^([^\s]+)\s+(dropped|lost|returned|stole)\s+the\s+flag$!) {
				return create_subclass($text,'Flag' . ucfirst( $2 ),{
					nick	=> $1,
					ip	=> $ip,
				});
			} elsif ($etext =~ m!^runs\s+AC\s+(\d+)\s+\(defs:\s+(.+)\)$!) {
				return create_subclass($text,'ClientVersion',{
					version	=> $1,
					defs	=> $2,
					ip	=> $ip,
				});
			} elsif ($etext =~ m!^([^\s]+)\s+scored\s+with\s+the\s+flag\s+for\s+(\w+),\s+new\s+score\s+(-?\d+)$!) {
				return create_subclass($text,'FlagScored',{
					nick		=> $1,
					team_name	=> $2,
					score		=> $3,
					ip		=> $ip,
				});
			} elsif ($etext =~ m!^client\s+([^\s]+)\s+(failed\s+to\s+)?call(?:ed)?\s+a\s+vote:\s+(.*)$!) {
				my $nick = $1;
				my $failure = $2;
				my $vote = $3;
				if ( defined $failure ) {
					$failure = 1;
				} else {
					$failure = 0;
				}

				# parse the vote...
				if (! length $vote) {
					return create_subclass($text,'CallVote',{
						nick		=> $nick,
						type		=> 'invalid',
						failure		=> 1,
						target		=> 'invalid',
						failure_reason	=> 'empty vote',
						ip		=> $ip,
					});
				} elsif ($vote =~ m!^load\s+map\s+\'(.*)\'\s+in\s+mode\s+\'(.+)\'(?:\s+\((.+)\))?$!) {
					return create_subclass($text,'CallVote',{
						nick	=> $nick,
						type	=> 'loadmap',
						failure	=> $failure,
						target	=> $1 . ' - ' . $2,
						ip	=> $ip,
						( defined $3 ? ( failure_reason => $3 ) : () ),
					});
				} elsif ($vote =~ m!^(\w+)\s+player\s+([^\s]*)(?:\s+to\s+the\s+enemy\s+team)?(?:\s+\((.+)\))?$!) {
					return create_subclass($text,'CallVote',{
						nick	=> $nick,
						type	=> $1,
						failure	=> $failure,
						target	=> $2,
						ip	=> $ip,
						( defined $3 ? ( failure_reason => $3 ) : () ),
					});
				} elsif ($vote =~ m!^shuffle\s+teams(?:\s+\((.+)\))?$!) {
					return create_subclass($text,'CallVote',{
						nick	=> $nick,
						type	=> 'shuffle',
						failure	=> $failure,
						target	=> 'teams',
						ip	=> $ip,
						( defined $2 ? ( failure_reason => $2 ) : () ),
					});
				} elsif ($vote =~ m!^(enable|disable|remove|stop)\s+([^\(]+)(?:\s+\((.+)\))?$!) {
					return create_subclass($text,'CallVote',{
						nick	=> $nick,
						type	=> $1,
						failure	=> $failure,
						target	=> $2,
						ip	=> $ip,
						( defined $3 ? ( failure_reason => $3 ) : () ),
					});
				} elsif ($vote =~ m!^change\s+(.+)(?:\s+\((.+)\))?$!) {
					return create_subclass($text,'CallVote',{
						nick	=> $nick,
						type	=> 'change',
						failure	=> $failure,
						target	=> $1,
						ip	=> $ip,
						( defined $2 ? ( failure_reason => $2 ) : () ),
					});
				} elsif ($vote =~ m!^set\s+(.+)(?:\s+\((.+)\))?$!) {
					return create_subclass($text,'CallVote',{
						nick	=> $nick,
						type	=> 'set',
						failure	=> $failure,
						target	=> $1,
						ip	=> $ip,
						( defined $2 ? ( failure_reason => $2 ) : () ),
					});
				} elsif ($vote =~ m!^\((.+)\)$!) {
					return create_subclass($text,'CallVote',{
						nick		=> $nick,
						type		=> 'invalid',
						failure		=> $failure,
						target		=> 'invalid',
						failure_reason	=> $1,
						ip		=> $ip,
					});
				} else {
					die "unknown vote type: $text - $vote";
				}
			} elsif ($etext =~ m!^(.+)\s+suicided$!) {
				return create_subclass($text,'Suicide',{
					nick	=> $1,
					ip	=> $ip,
				});
			} elsif ($etext =~ m!^([^\s]+)\s+changed\s+his\s+name\s+to\s+(.+)$!) {
				return create_subclass($text,'ClientNickChange',{
					oldnick	=> $1,
					nick	=> $2,
					ip	=> $ip,
				});
			} elsif ($etext =~ m!^([^\s]+)\s+scored,\s+carrying\s+for\s+(\d+)\s+seconds,\s+new\s+score\s+(\d+)$!) {
				return create_subclass($text,'FlagScoredKTF',{
					nick	=> $1,
					carried	=> $2,
					score	=> $3,
					ip	=> $ip,
				});
			} elsif ($etext =~ m!^set\s+role\s+of\s+player\s+([^\s]+)\s+to\s+(\w+)(?:\s+player)?$!) {
				# AC prints "normal" instead of "default", argh!
				my $role = 'ADMIN';
				if ( $2 eq 'normal' ) {
					$role = 'DEFAULT';
				}

				return create_subclass($text,'ClientChangeRole',{
					nick		=> $1,
					role_name	=> $role,
					ip		=> $ip,
				});
			} elsif ($etext =~ m!^player\s+([^\s]+)\s+used\s+admin\s+password\s+in\s+line\s+(\d+)$!) {
				return create_subclass($text,'ClientAdmin',{
					nick		=> $1,
					password	=> $2,
					ip		=> $ip,
				});
			} elsif ($etext =~ m!^([^\s]+)\s+got\s+forced\s+to\s+pickup\s+the\s+flag$!) {
				return create_subclass($text,'FlagForcedPickup',{
					nick	=> $1,
					ip	=> $ip,
				});
			} elsif ($etext =~ m!^([^\s]+)\s+failed\s+to\s+score$!) {
				return create_subclass($text,'FlagFailedScore',{
					nick	=> $1,
					ip	=> $ip,
				});
			} elsif ($etext =~ m!^logged\s+in\s+using\s+the\s+admin\s+password\s+in\s+line\s+(\d+)(,\s+\(ban\s+removed\))?$!) {
				return create_subclass($text,'ClientAdmin',{
					password	=> $1,
					ip		=> $ip,
					( defined $2 ? ( unbanned => 1 ) : () ),
				});

			# ARGH, sometimes ac_server "overflows" and fails to print the message properly...
			} elsif ($etext =~ m!^([^\s]+)\s+says(?:\s+to\s+team\s+(\w+))?:\s+\'([^']+)$!) {
				# TODO what should we do with $2, the team name?
				return create_subclass($text,'Says',{
					nick	=> $1,
					isteam	=> defined $2 ? 1 : 0,
					text	=> $3,
					spam	=> 0,
					ip	=> $ip,
				});
			} else {
				return create_subclass($text,'Unknown',{
					ip	=> $ip,
					text	=> $etext,
				});
			}
		} else {
			return create_subclass($text,'Unknown',{});
		}
	} elsif ($text =~ m!^\s*(\d+)\s+([^\s]+)\s+(\w+)\s+(-?\d+)\s+(-?\d+)\s+(-?\d+)\s+(\w+)\s+([\d\.]+)$!) {
		return create_subclass($text,'ClientStatus',{
			cn		=> $1,
			nick		=> $2,
			team_name	=> $3,
			frags		=> $4,
			deaths		=> $5,
			flags		=> $6,
			role_name	=> ( $7 eq 'normal' ? 'DEFAULT' : 'ADMIN' ),	# AC prints "normal" instead of "default", argh!
			ip		=> $8,
		});
	} elsif ($text =~ m!^\s*(\d+)\s+([^\s]+)\s+(\w+)\s+(-?\d+)\s+(-?\d+)\s+(\w+)\s+([\d\.]+)$!) {
		return create_subclass($text,'ClientStatus',{
			cn		=> $1,
			nick		=> $2,
			team_name	=> $3,
			frags		=> $4,
			deaths		=> $5,
			role_name	=> ( $6 eq 'normal' ? 'DEFAULT' : 'ADMIN' ),	# AC prints "normal" instead of "default", argh!
			ip		=> $7,
		});
	} elsif ($text =~ m!^\s*(\d+)\s+([^\s]+)\s+(-?\d+)\s+(-?\d+)\s+(-?\d+)\s+(\w+)\s+([\d\.]+)$!) {
		return create_subclass($text,'ClientStatus',{
			cn		=> $1,
			nick		=> $2,
			team_name	=> 'NONE',
			frags		=> $3,
			deaths		=> $4,
			flags		=> $5,
			role_name	=> ( $6 eq 'normal' ? 'DEFAULT' : 'ADMIN' ),	# AC prints "normal" instead of "default", argh!
			ip		=> $7,
		});
	} elsif ($text =~ m!^\s*(\d+)\s+([^\s]+)\s+(-?\d+)\s+(-?\d+)\s+(\w+)\s+([\d\.]+)$!) {
		return create_subclass($text,'ClientStatus',{
			cn		=> $1,
			nick		=> $2,
			team_name	=> 'NONE',
			frags		=> $3,
			deaths		=> $4,
			role_name	=> ( $5 eq 'normal' ? 'DEFAULT' : 'ADMIN' ),	# AC prints "normal" instead of "default", argh!
			ip		=> $6,
		});
	} elsif ($text =~ m!^Team\s+(\w+):\s+(\d+)\s+players,\s+(-?\d+)\s+frags(?:,\s+(-?\d+)\s+flags)?$!) {
		return create_subclass($text,'TeamStatus',{
			team_name	=> $1,
			players		=> $2,
			frags		=> $3,
			( defined $4 ? ( flags => $4 ) : () ),
		});
	} elsif ($text =~ m!^Game\s+status:\s+(.+)\s+on\s+([^,]*),\s+(\d+)\s+[^,]+,\s+(\w+)$!) {
		return create_subclass($text,'GameStatus',{
			gamemode_fullname	=> ( $1 eq 'ctf' ? 'capture the flag' : $1 ),	# ctf is annoying because of our "substitution" from 'ctf' to "capture the flag"
			'map'			=> $2,
			minutes			=> $3,
			mastermode_name		=> uc( $4 ),
			finished		=> 0,
		});
	} elsif ($text =~ m!^Game\s+status:\s+(.+)\s+on\s+([^,]+),\s+game finished,\s+(\w+)$!) {
		return create_subclass($text,'GameStatus',{
			gamemode_fullname	=> ( $1 eq 'ctf' ? 'capture the flag' : $1 ),	# ctf is annoying because of our "substitution" from 'ctf' to "capture the flag"
			'map'			=> $2,
			minutes			=> 0,
			mastermode_name		=> uc( $3 ),
			finished		=> 1,
		});
	} elsif ($text =~ m!cn\s+name\s+(?:team\s+)?frag\s+death\s+(?:flags\s+)?role\s+host$!) {
		return create_subclass($text,'ScoreboardStart',{});
	} elsif ($text =~ m!^Status\s+at\s+(\d+)-(\d+)-(\d+)\s+(\d+):(\d+):(\d+):\s+(\d+)\s+remote\s+clients,\s+([\d\.]+)\s+send,\s+([\d\.]+)\s+rec\s+\(K/sec\)$!) {
		require DateTime;
		my $datetime = DateTime->new(
			year	=> $3,
			month	=> $2,
			day	=> $1,
			hour	=> $4,
			minute	=> $5,
			second	=> $6,
		);
		return create_subclass($text,'Status',{
			datetime	=> $datetime,
			players		=> $7,
			sent		=> $8,
			'recv'		=> $9,
		});
	} elsif ($text =~ m!^Game\s+start:\s+(.+)\s+on\s+([^,]+),\s+(\d+)\s+[^,]+,\s+(\d+)\s+[^,]+,\s+mastermode\s+(\d+)!) {
		return create_subclass($text,'GameStart',{
			gamemode_fullname	=> ( $1 eq 'ctf' ? 'capture the flag' : $1 ),	# ctf is annoying because of our "substitution" from 'ctf' to "capture the flag"
			'map'			=> $2,
			players			=> $3,
			minutes			=> $4,
			mastermode		=> $5,
		});
	} elsif ($text =~ m!^at-target:\s+(-?\d+),\s+(.+)\s+pick:(\d+)$!) {
		return create_subclass($text,'AutoBalance',{
			target	=> $1,
			players	=> { map { split( /:/, $_, 2 ) } split( ' ', $2 ) },
			pick	=> $3,
		});
	} elsif ($text =~ m!^the\s+server\s+reset\s+the\s+flag\s+for\s+team\s+(\w+)$!) {
		return create_subclass($text,'FlagReset',{
			team_name	=> $1,
		});
	} elsif ($text =~ m!^sending\s+request\s+to\s+(.+)...$!) {
		return create_subclass($text,'MasterserverRequest',{
			server	=> $1,
		});
	} elsif ($text =~ m!^masterserver\s+reply:\s+(.*)$!) {
		return create_subclass($text,'MasterserverReply',{
			reply	=> $1,
			success	=> 1,
		});
	} elsif ($text eq 'Registration successful. Due to caching it might take a few minutes to see the your server in the serverlist') {
		return create_subclass($text,'MasterserverReply',{
			reply	=> 'Registration successful. Due to caching it might take a few minutes to see the your server in the serverlist',
			success	=> 1,
		});
	} elsif ($text eq 'Server not registered, could not ping you. Make sure your server is accessible from the internet.') {
		return create_subclass($text,'MasterserverReply',{
			reply	=> 'Server not registered, could not ping you. Make sure your server is accessible from the internet.',
			success	=> 0,
		});
	} elsif ($text eq 'logging local AssaultCube server now..' or $text eq 'dedicated server started, waiting for clients...' or $text eq 'Ctrl-C to exit') {
		return create_subclass($text,'StartupText',{});
	} elsif ($text =~ m!^loaded\s+map\s+([^,]+),\s+(\d+)\s+\+\s+(\d+)\((\d+)\)\s+bytes\.$!) {
		# cleanup the map name
		my( $mapname, $mapsize, $cfgsize, $cfgzsize ) = ( $1, $2, $3, $4 );
		if ( $mapname =~ /([^\\\/]+)\.cgz$/ ) {
			$mapname = $1;
		} else {
			die "unable to parse mapname: $mapname";
		}

		return create_subclass($text,'LoadedMap',{
			'map'		=> $mapname,
			mapsize		=> $mapsize,
			cfgsize		=> $cfgsize,
			cfgzsize	=> $cfgzsize,
		});
	} elsif ($text =~ m!^read\s+(\d+)\s+\((\d+)\)\s+blacklist\s+entries\s+from\s+(.+)$!) {
		return create_subclass($text,'BlacklistEntries',{
			count		=> $1,
			count_secondary	=> $2,
			config		=> $3,
		});
	} elsif ($text =~ m!^read\s+(\d+)\s+admin\s+passwords\s+from\s+(.*)$!) {
		return create_subclass($text,'AdminPasswords',{
			count	=> $1,
			config	=> $2,
		});
	} elsif ($text =~ m!^looking\s+up\s+(.+)\.\.\.!) {
		return create_subclass($text,'DNSLookup',{
			host	=> $1,
		});
	} elsif ($text =~ m!^map\s+\"([^\"]+)\"\s+does\s+not\s+support\s+\"([^\"]+)\":\s+(.+)$!) {
		return create_subclass($text,'MapError',{
			'map'			=> $1,
			gamemode_fullname	=> ( $2 eq 'ctf' ? 'capture the flag' : $2 ),	# ctf is annoying because of our "substitution" from 'ctf' to "capture the flag"
			error			=> $3,
		});
	} elsif ($text =~ m!^could\s+not\s+read\s+config\s+file\s+\'(.+)\'$!) {
		return create_subclass($text,'ConfigError',{
			errortype	=> 'config read',
			what		=> $1,
		});
	} elsif ($text =~ m!^maprot\s+error:\s+map\s+\'(.+)\'\s+not\s+found$!) {
		return create_subclass($text,'ConfigError',{
			errortype	=> 'maprot missing map',
			what		=> $1,
		});
	} elsif ($text =~ m!^AssaultCube\s+fatal\s+error:\s+(.*)$!) {
		return create_subclass($text,'FatalError',{
			error	=> $1,
		});
	} elsif ($text eq 'Demo recording started.' ) {
		return create_subclass($text,'DemoStart',{});

		# Demo "Tue Feb 17 11:14:58 2009: ctf, bs_dust2_0.6, 1.32MB" recorded.
	} elsif ($text =~ m!^Demo\s+"\w+\s+(\w+)\s+(\d+)\s+(\d+):(\d+):(\d+)\s+(\d+):\s+([^\,]+),\s+([^\,]+),\s+([\d\.]+)(MB|kB)"\s+recorded.$!) {
		require DateTime;
		my $datetime = DateTime->new(
			year	=> $6,
			month	=> month2num( $1 ),
			day	=> $2,
			hour	=> $3,
			minute	=> $4,
			second	=> $5,
		);

		# Figure out the size, ack!
		my $size;
		if ( $10 eq 'MB' ) {
			$size = int( $9 * 1024 * 1024 );
		} else {
			$size = int( $9 * 1024 );
		}

		return create_subclass($text,'DemoStop',{
			datetime		=> $datetime,
			gamemode_fullname	=> $7,
			'map'			=> $8,
			size			=> $size,
		});
	} else {
		return create_subclass($text,'Unknown',{
			text	=> $text,
		});
	}
}

# TODO find a suitable module for this! ( DateTime::Format::xyz )
# We need this for the DemoStop DateTime conversions...
{
	my %month_num = (
		'Jan'	=> 1,
		'Feb'	=> 2,
		'Mar'	=> 3,
		'Apr'	=> 4,
		'May'	=> 5,
		'Jun'	=> 6,
		'Jul'	=> 7,
		'Aug'	=> 8,
		'Sep'	=> 9,
		'Oct'	=> 10,
		'Nov'	=> 11,
		'Dec'	=> 12,
	);
	sub month2num {
		return $month_num{ +shift };
	}
}

1;
__END__

=for stopwords Torsten Raudssus
=head1 NAME

Games::AssaultCube::Log::Line - Parses an AssaultCube server log line

=head1 SYNOPSIS

	use Games::AssaultCube::Log::Line;
	open( my $fh, "<", "logfile.log" ) or die "Unable to open logfile: $!";
	while ( my $line = <$fh> ) {
		$line =~ s/(?:\n|\r)+//;
		next if ! length $line;
		my $log = Games::AssaultCube::Log::Line->new( $line );

		# play with the data
		print "LOG: " . $log->event . " happened\n";
	}
	close( $fh ) or die "Unable to close logfile: $!";

=head1 ABSTRACT

Parses an AssaultCube server log line

=head1 DESCRIPTION

This module takes an AssaultCube logfile line as parameter and converts this into an easily-accessed
object. Please look at the subclasses for all possible event types. This is the factory which handles
the "generic" stuff and the parsing. The returned object actually is a subclass which inherits from
L<Games::AssaultCube::Log::Line::Base> and contains the various accessors suited for that event type.

You would need to set up the "fluff" to read the logfile and feed lines into this parser as shown in the
SYNOPSIS.

=head2 Constructor

The constructor for this class is the "new()" method. The constructor accepts only one argument, the
log line to parse. The constructor will return an object or die() if the line is undef/zero-length.

Furthermore, you can supply an optional second argument: the subclass parser. It can be an object or a
coderef. Please review the notes below, L</"Subclassing the parser">.

It is important to remember that this class is simply a "factory" that parses the log line and hands the
data off to the appropriate subclass. It is this subclass that is actually returned from the constructor.
This means this class has no methods/subs/attributes attached to it and you should study the subclasses for
details :)

=head2 Subclassing the parser

Since AssaultCube is open source, it is feasible for people to modify the server code to output other
forms of logs. It makes sense for us to provide a way for others to make use of this code, and extend
it to take their log format into account. What follows will be a description on how this is achieved.

In order to subclass the parser, all you need to do is provide either an object or a coderef to the
constructor. It will be called before executing the normal parsing code contained in this class. If it's
an object, the "parse()" method will be called on it; otherwise the coderef will be called.

The subclass can either return undef or a defined result. If it returns undef then we will continue with the
normal code. If it was defined, then it will be returned directly to the caller, bypassing the parsing
code. That way your subclass can return anything, from an object to a hashref to a simple "1". The implication
of this is that your subclass will be called every time this class is instantiated. The arguments is simply
the line to be parsed, just like the constructor of this class. From there your subclass can use the
L<Games::AssaultCube::Log::Line::Base> object if desired for it's events or anything else.

NOTE: Since the subclass would process every line, it is desirable to be very fast. It would be smart to
design your log extensions so they are immediately detected by the subclass. A normal AssaultCube log line
would look something like:

	Team RVSF:  9 players,   63 frags,    0 flags
	Status at 18-02-2009 10:02:56: 19 remote clients, 84.3 send, 5.2 rec (K/sec)
	[199.203.37.253] abcde fragged fghi

It would be extremely beneficial if your "extended" log format includes an easily-recognizable prefix. Some
examples would be something like this:

	*LOG* Player "abcde" scored a 10-kill streak
	|EXTLOG| Server restarted
	== Player fghi captured the flag at 3:45 into the game

Then, your subclass's parse() method could check the first few characters of the line and immediately return
before doing any extensive regex/split/code on it. Here's a sample parse() method for a subclass that uses
the object style and the "==" extended log prefix:

	sub parse {
		my( $self, $line ) = @_;
		if ( substr( $line, 0, 2 ) ne '==' ) {
			return;
		} else {
			# Process our own extended log format
			# Be sure to return a defined result!
			return 1;
		}
	}

We assume that if you know enough to extend the AssaultCube sources and add your own logs, you know enough
to not cause conflicts in the log formats :) Have fun playing around with AssaultCube!

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Torsten Raudssus E<lt>torsten@raudssus.deE<gt>

Props goes to the BS clan for the support!

This project is sponsored by L<http://cubestats.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

UNKNOWN log lines: ( none as of now, ha! )

Parsing 7666 logfiles...
The events in descending order:
	[Killed] -> 6685565
	[ClientStatus] -> 1850559
	[Says] -> 511759
	[TeamStatus] -> 464180
	[ClientDisconnected] -> 448772
	[ClientConnected] -> 348626
	[GameStatus] -> 265458
	[ScoreboardStart] -> 264980
	[FlagStole] -> 262218
	[Status] -> 252995
	[ClientVersion] -> 196760
	[FlagLost] -> 174810
	[FlagReturned] -> 140226
	[FlagScored] -> 69272
	[GameStart] -> 40216
	[Suicide] -> 30879
	[AutoBalance] -> 22432
	[CallVote-loadmap] -> 19789
	[FlagReset] -> 16775
	[ClientNickChange] -> 16334
	[CallVote-kick] -> 15584
	[MasterserverReply] -> 12085
	[MasterserverRequest] -> 12038
	[StartupText] -> 9094
	[CallVote-ban] -> 6625
	[LoadedMap] -> 4286
	[FlagScoredKTF] -> 4220
	[CallVote-shuffle] -> 4144
	[CallVote-force] -> 1460
	[ClientChangeRole] -> 1224
	[ClientAdmin] -> 1092
	[BlacklistEntries] -> 761
	[CallVote-enable] -> 745
	[AdminPasswords] -> 682
	[CallVote-remove] -> 674
	[FlagDropped] -> 596
	[FlagForcedPickup] -> 548
	[DNSLookup] -> 498
	[CallVote-invalid] -> 413
	[MapError] -> 218
	[FlagFailedScore] -> 157
	[CallVote-disable] -> 140
	[ConfigError] -> 114
	[FatalError] -> 84
	[CallVote-change] -> 46
	[CallVote-stop] -> 11
	[CallVote-set] -> 2
Thank you for waiting!

real	25m16.932s
user	23m28.120s
sys	0m5.220s
