# Declare our package
package Games::AssaultCube::Utils;
use strict; use warnings;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

# set ourself up for exporting
use base qw( Exporter );
our @EXPORT_OK = qw( default_port stripcolors htmlcolors tostr getpongflag get_ac_pingport
	getint getstring parse_pingresponse parse_masterserverresponse
	get_gamemode get_gamemode_name get_gamemode_from_name get_gamemode_fullname get_gamemode_from_fullname
	get_team_from_name get_team_name get_role_from_name get_role_name
	get_mastermode_from_name get_mastermode_name get_gun_from_name get_gun_name
	get_disconnect_reason_name get_disconnect_reason_from_name
);

sub get_ac_pingport {
	my $port = shift;
	return if ! defined $port;

	# from protocol.h
	# #define CUBE_SERVINFO_PORT(serverport) (serverport+1)
	return $port + 1;
}

{
	# from protocol.h
	# enum { DISC_NONE = 0, DISC_EOP, DISC_CN, DISC_MKICK, DISC_MBAN, DISC_TAGT, DISC_BANREFUSE, DISC_WRONGPW, DISC_SOPLOGINFAIL, DISC_MAXCLIENTS, DISC_MASTERMODE, DISC_AUTOKICK, DISC_AUTOBAN, DISC_DUP, DISC_NUM };
	# static const char *disc_reasons[] = { "normal", "end of packet", "client num", "kicked by server operator", "banned by server operator", "tag type", "connection refused due to ban", "wrong password", "failed admin login", "server FULL - maxclients", "server mastermode is \"private\"", "auto kick - did your score drop below the threshold?", "auto ban - did your score drop below the threshold?", "duplicate connection" };
	my %reason_name = (
		0	=> 'normal',
		1	=> 'end of packet',
		2	=> 'client num',
		3	=> 'kicked by server operator',
		4	=> 'banned by server operator',
		5	=> 'tag type',
		6	=> 'connection refused due to ban',
		7	=> 'wrong password',
		8	=> 'failed admin login',
		9	=> 'server FULL - maxclients',
		10	=> 'server mastermode is "private"',
		11	=> 'auto kick - did your score drop below the threshold?',
		12	=> 'auto ban - did your score drop below the threshold?',
		13	=> 'duplicate connection',
	);
	my %name_reason = map { $reason_name{ $_ } => $_ } keys %reason_name;

	sub get_disconnect_reason_name {
		my $reason = shift;
		return unless defined $reason;
		if ( exists $reason_name{ $reason } ) {
			return $reason_name{ $reason };
		} else {
			return;
		}
	}

	sub get_disconnect_reason_from_name {
		my $reason = lc( shift );
		return unless defined $reason;
		if ( exists $name_reason{ $reason } ) {
			return $name_reason{ $reason };
		} else {
			return;
		}
	}
}

sub get_gamemode {
	my $m = shift;

	# try the fullname first?
	my $result = get_gamemode_from_fullname( $m );
	if ( defined $result ) {
		return $result;
	} else {
		# try the acronym?
		return get_gamemode_from_name( $m );
	}
}

{
	# from entity.h
	# enum { GUN_KNIFE = 0, GUN_PISTOL, GUN_SHOTGUN, GUN_SUBGUN, GUN_SNIPER, GUN_ASSAULT, GUN_GRENADE, GUN_AKIMBO, NUMGUNS };
	my %gun_name = (
		0	=> 'KNIFE',
		1	=> 'PISTOL',
		2	=> 'SHOTGUN',
		3	=> 'SUBMACHINE',
		4	=> 'SNIPER',
		5	=> 'ASSAULT',
		6	=> 'GRENADE',
		7	=> 'AKIMBO',
	);
	my %name_gun = map { $gun_name{ $_ } => $_ } keys %gun_name;

	sub get_gun_from_name {
		my $gun = uc( shift );
		return unless defined $gun;
		if ( exists $name_gun{ $gun } ) {
			return $name_gun{ $gun };
		} else {
			return;
		}
	}

	sub get_gun_name {
		my $gun = shift;
		return unless defined $gun;
		if ( exists $gun_name{ $gun } ) {
			return $gun_name{ $gun };
		} else {
			return;
		}
	}
}

{
	# from entity.h
	#define TEAM_CLA 0
	#define TEAM_RVSF 1
	my %team_name = (
		0	=> 'CLA',
		1	=> 'RVSF',
		2	=> 'NONE',
	);
	my %name_team = map { $team_name{ $_ } => $_ } keys %team_name;

	sub get_team_from_name {
		my $team = uc( shift );
		return unless defined $team;
		if ( exists $name_team{ $team } ) {
			return $name_team{ $team };
		} else {
			return;
		}
	}

	sub get_team_name {
		my $team = shift;
		return unless defined $team;
		if ( exists $team_name{ $team } ) {
			return $team_name{ $team };
		} else {
			return;
		}
	}
}

{
	# from entity.h
	# enum { CR_DEFAULT = 0, CR_ADMIN };
	my %role_name = (
		0	=> 'DEFAULT',
		1	=> 'ADMIN',
	);
	my %name_role = map { $role_name{ $_ } => $_ } keys %role_name;

	sub get_role_from_name {
		my $role = uc( shift );
		return unless defined $role;
		if ( exists $name_role{ $role } ) {
			return $name_role{ $role };
		} else {
			return;
		}
	}

	sub get_role_name {
		my $role = shift;
		return unless defined $role;
		if ( exists $role_name{ $role } ) {
			return $role_name{ $role };
		} else {
			return;
		}
	}
}

{
	# from protocol.h
	# enum { MM_OPEN, MM_PRIVATE, MM_NUM };
	my %mode_name = (
		0	=> 'OPEN',
		1	=> 'PRIVATE',
		2	=> 'NUM',
	);
	my %name_mode = map { $mode_name{ $_ } => $_ } keys %mode_name;

	sub get_mastermode_from_name {
		my $mode = uc( shift );
		return unless defined $mode;
		if ( exists $name_mode{ $mode } ) {
			return $name_mode{ $mode };
		} else {
			return;
		}
	}

	sub get_mastermode_name {
		my $mode = shift;
		return unless defined $mode;
		if ( exists $mode_name{ $mode } ) {
			return $mode_name{ $mode };
		} else {
			return;
		}
	}
}

# parses a HTTP::Response object from the Masterserver
sub parse_masterserverresponse {
	my $response = shift;

	# construct the arrayref of hashrefs of servers, zOMG!
	my $result = [];

	# go through the content, and add server/port to the result
	foreach my $l ( split( /[\r\n]+/, $response->content ) ) {
		if ( ! length $l ) { next }

		# TODO make this more robust but what the heck!
		if ( $l =~ /^addserver\s+(\S+)\s+(\d+)\;$/ ) {
			my $server = {
				'ip'	=> $1,
				'port'	=> $2,
			};
			push( @$result, $server );
		} else {
			die "Unknown string in response: $l";
		}
	}

	# all done!
	return $result;
}

# the default AssaultCube server port
sub default_port {
	return 28763;
}

# based on the PHP code, thanks PxL!
sub tostr {
	my $hs = shift;
	my $rsp = '';
	for(my $i = 0; $i < length($hs); $i+=2) {
		$rsp .= chr(hex(substr($hs,$i).substr($hs,$i+1)));
	}
	return $rsp;
}

sub getint {
	my $str = shift;

# from protocol.cpp
#int getint(ucharbuf &p)
#{
#    int c = (char)p.get();
#    if(c==-128) { int n = p.get(); n |= char(p.get())<<8; DEBUGVAR(n); return n; }
#    else if(c==-127) { int n = p.get(); n |= p.get()<<8; n |= p.get()<<16; n |= (p.get()<<24); DEBUGVAR(n); return n; }
#    else
#    {
#        DEBUGVAR(c);
#        return c;
#    }
#}

	if ( ! length $$str ) {
		return;
	}

	my $c = ord( substr( $$str, 0, 1 ) );
	if ( $c == 128 ) {
		my $n = ord( substr( $$str, 1, 1 ) );
		$n |= ( ord( substr( $$str, 2, 1 ) ) << 8 );

		# cleanup the string
		$$str = substr( $$str, 3 );
		return $n;
	} elsif ( $c == 127 ) {
		my $n = ord( substr( $$str, 1, 1 ) );
		$n |= ( ord( substr( $$str, 2, 1 ) ) << 8 );
		$n |= ( ord( substr( $$str, 3, 1 ) ) << 16 );
		$n |= ( ord( substr( $$str, 4, 1 ) ) << 24 );

		# cleanup the string
		$$str = substr( $$str, 5 );
		return $n;
	} else {
		# cleanup the string
		$$str = substr( $$str, 1 );
		return $c;
	}
}

sub getstring {
	my $str = shift;

# from protocol.cpp
#void getstring(char *text, ucharbuf &p, int len)
#{
#    char *t = text;
#    do
#    {
#        if(t>=&text[len]) { text[len-1] = 0; return; }
#        if(!p.remaining()) { *t = 0; return; }
#        *t = getint(p);
#    }
#    while(*t++);
#    DEBUGVAR(text);
#}

	if ( ! length $$str ) {
		return;
	}

	my $ret = '';
	my $i = 0;
	while ( ord( substr( $$str, $i, 1 ) ) != 0 ) {
		$ret .= substr( $$str, $i, 1 );
		$i++;
	}

	# cleanup the string
	$$str = substr( $$str, $i + 1 );
	return $ret;
}

{
	# from protocol.cpp
	#const char *modefullnames[] =
	#{
	#    "demo playback",
	#    "team deathmatch", "coopedit", "deathmatch", "survivor",
	#    "team survivor", "ctf", "pistol frenzy", "bot team deathmatch", "bot deathmatch", "last swiss standing",
	#    "one shot, one kill", "team one shot, one kill", "bot one shot, one kill", "hunt the flag", "team keep the flag", "keep the flag"
	#};

	my %mode_name = (
		0	=> 'demo playback',
		1	=> 'team deathmatch',
		2	=> 'coopedit',
		3	=> 'deathmatch',
		4	=> 'survivor',
		5	=> 'team survivor',
		6	=> 'capture the flag',	# this is expanded, because I felt "ctf" was silly
		7	=> 'pistol frenzy',
		8	=> 'bot team deathmatch',
		9	=> 'bot deathmatch',
		10	=> 'last swiss standing',
		11	=> 'one shot, one kill',
		12	=> 'team one shot, one kill',
		13	=> 'bot one shot, one kill',
		14	=> 'hunt the flag',
		15	=> 'team keep the flag',
		16	=> 'keep the flag',
	);
	my %name_mode = map { $mode_name{ $_ } => $_ } keys %mode_name;
	$name_mode{'ctf'} = 6;	# added so we have full round-trip between perl + AC

	sub get_gamemode_fullname {
		my $m = shift;
		return unless defined $m;
		if ( exists $mode_name{ $m } ) {
			return $mode_name{ $m };
		} else {
			return;
		}
	}

	sub get_gamemode_from_fullname {
		my $m = lc( shift );
		return unless defined $m;
		if ( exists $name_mode{ $m } ) {
			return $name_mode{ $m };
		} else {
			return;
		}
	}
}

{
	# from protocol.cpp
	#const char *modeacronymnames[] =
	#{
	#    "DEMO",
	#    "TDM", "coop", "DM", "SURV", "TSURV", "CTF", "PF", "BTDM", "BDM", "LSS",
	#    "OSOK", "TOSOK", "BOSOK", "HTF", "TKTF", "KTF"
	#};

	my %mode_name = (
		0	=> 'DEMO',
		1	=> 'TDM',
		2	=> 'COOP',	# uppercased for consistency...
		3	=> 'DM',
		4	=> 'SURV',
		5	=> 'TSURV',
		6	=> 'CTF',
		7	=> 'PF',
		8	=> 'BTDM',
		9	=> 'BDM',
		10	=> 'LSS',
		11	=> 'OSOK',
		12	=> 'TOSOK',
		13	=> 'BOSOK',
		14	=> 'HTF',
		15	=> 'TKTF',
		16	=> 'KTF',
	);
	my %name_mode = map { $mode_name{ $_ } => $_ } keys %mode_name;

	sub get_gamemode_name {
		my $m = shift;
		return unless defined $m;
		if ( exists $mode_name{ $m } ) {
			return $mode_name{ $m };
		} else {
			return;
		}
	}

	sub get_gamemode_from_name {
		my $m = uc( shift );
		return unless defined $m;
		if ( exists $name_mode{ $m } ) {
			return $name_mode{ $m };
		} else {
			return;
		}
	}
}

sub getpongflag {
	my $pong = shift;

	# FIXME convert this to proper enums

# from protocol.h
#enum { PONGFLAG_PASSWORD = 0, PONGFLAG_BANNED, PONGFLAG_BLACKLIST, PONGFLAG_MASTERMODE = 6, PONGFLAG_NUM };

# from serverbrowser.cpp
#        if(si->pongflags > 0)
#        {
#            const char *sp = "";
#            int mm = si->pongflags >> PONGFLAG_MASTERMODE;
#            if(si->pongflags & (1 << PONGFLAG_BANNED))
#                sp = "you are banned from this server";
#            if(si->pongflags & (1 << PONGFLAG_BLACKLIST))
#                sp = "you are blacklisted on this server";
#            else if(si->pongflags & (1 << PONGFLAG_PASSWORD))
#                sp = "this server is password-protected";
#            else if(mm) sp = mmfullname(mm);
#            s_sprintf(si->description)("%s  \f1(%s)", si->sdesc, sp);
#        }
#
#	// from protocol.cpp
#	const char *mmfullnames[] = { "open", "private" };

	if ( defined $pong and $pong > 0 ) {
		my $mm = $pong >> 6;
		if ( $pong & ( 1 << 1 ) ) {
			return "you are banned from this server";
		} elsif ( $pong & ( 1 << 2 ) ) {
			return "you are blacklisted on this server";
		} elsif ( $pong & ( 1 << 0 ) ) {
			return "this server is password-protected";
		} else {
			if ( $mm ) {
				if ( $mm == 1 ) {
					return "open";
				} elsif ( $mm == 2 ) {
					return "private";
				} else {
					return "UNKNOWN";
				}
			} else {
				return "UNKNOWN";
			}
		}
	} else {
		return "none";
	}
}

sub stripcolors {
	my $str = shift;

	# From AC docs/colouredtext.txt
	# also, look at the PHP code for reference :)

	my $output = '';
	my $foundcolor = 0;
	foreach my $c ( split( //, $str ) ) {
		if ( $foundcolor ) {
			# skip the damn thing
			$foundcolor = 0;
		} elsif ( ord( $c ) == 12 ) {
			$foundcolor++
		} else {
			$output .= $c;
		}
	}

	return $output;
}

{
	# From AC docs/colouredtext.txt
	# also, look at the PHP code for reference :)
#	$html_colors = array(
#		"<span style='color: #00ee00'>",
#		"<span style='color: #0000ee'>",
#		"<span style='color: #f7de12'>",
#		"<span style='color: #ee0000'>",
#		"<span style='color: #767676'>",
#		"<span style='color: #eeeeee'>",
#		"<span style='color: #824f03'>",
#		"<span style='color: #9a0000'>"
#	);

	my %htmlcolors = (
		0	=> '<font color="#00ee00">',
		1	=> '<font color="#0000ee">',
		2	=> '<font color="#f7de12">',
		3	=> '<font color="#ee0000">',
		4	=> '<font color="#767676">',
		5	=> '<font color="#eeeeee">',
		6	=> '<font color="#824f03">',
		7	=> '<font color="#9a0000">',
	);

	sub htmlcolors {
		my $str = shift;

		my $found = 0;
		my $incolor = 0;
		my $ret = '';
		my @chars = split( //, $str );
		foreach my $i ( 0 .. $#chars ) {
			if ( $found ) {
				if ( exists $htmlcolors{ $chars[$i] } and defined $chars[$i+1] ) {
					$ret .= $htmlcolors{ $chars[$i] };
					$incolor = 1;
				} else {
					warn "unknown AC color code: $chars[$i]";
				}
				$found = 0;
			} elsif ( ord( $chars[$i] ) == 12 ) {
				if ( $incolor ) {
					$ret .= '</font>';
					$incolor = 0;
				}
				$found = 1;
			} else {
				$ret .= $chars[$i];
			}
		}
		if ( $found ) {
			$ret .= '</font>';
		}

		return $ret;
	}
}

sub parse_pingresponse {
	my $r = shift;

# from serverbrowser.cpp
#ucharbuf p(ping, len);
#        si->lastpingmillis = totalmillis;
#        int pingtm = pingbuf[(getint(p) - 1) % PINGBUFSIZE];
#        si->ping = pingtm ? totalmillis - pingtm : 9997;
#        int query = getint(p);
#        si->protocol = getint(p);
#        if(si->protocol!=PROTOCOL_VERSION) si->ping = 9998;
#        si->mode = getint(p);
#        si->numplayers = getint(p);
#        si->minremain = getint(p);
#	 getstring(text, p);
#        filtertext(si->map, text, 1);
#        getstring(text, p);
#        filterservdesc(si->sdesc, text);
#        s_strcpy(si->description, si->sdesc);
#        si->maxclients = getint(p);
#	 if(p.remaining())
#        {
#            si->pongflags = getint(p);
#            if(p.remaining() && getint(p) == query)
#            {

	my %data;

	$data{'pingtime'}	= getint( \$r );
	$data{'query'}		= getint( \$r );
	$data{'protocol'}	= getint( \$r );
	$data{'gamemode'}	= getint( \$r ) + 1;	# for some reason, AC returns mode - 1
	$data{'players'}	= getint( \$r );
	$data{'minutes_left'}	= getint( \$r );
	$data{'map'}		= getstring( \$r );
	$data{'desc'}		= getstring( \$r );
	$data{'max_players'}	= getint( \$r );

	# sometimes we don't get pongflags
	if ( length( $r ) ) {
		$data{'pong'}		= getint( \$r );

		# sometimes there is no player data...
		if ( length( $r ) ) {
			my $query = getint( \$r );
			if ( defined $query ) {
				if ( $query == 0 ) {
					# no extra data
				} elsif ( $query == 1 ) {
					while ( length( $r ) ) {
						my $player = getstring( \$r );
						if ( defined $player and $player ne '' ) {
							push( @{ $data{'player_list'} }, $player );
						}
					}
				} else {
					# unknown PINGMODE
					die "unknown PINGMODE: $query";
				}
			}
		}
	}

	return \%data;
}

1;
__END__

=for stopwords todo

=head1 NAME

Games::AssaultCube::Utils - Various utilities for the AssaultCube modules

=head1 SYNOPSIS

	use Games::AssaultCube::Utils qw( default_port );
	print "The default AssaultCube server port is: " . default_port() . "\n";

=head1 ABSTRACT

This module holds the various utility functions used in the AssaultCube modules.

=head1 DESCRIPTION

This module holds the various utility functions used in the AssaultCube modules. Normally you wouldn't
need to use this directly.

TODO: More documentation about the functions here :)

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to Getty and the BS clan for the support!

This project is sponsored by L<http://cubestats.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
