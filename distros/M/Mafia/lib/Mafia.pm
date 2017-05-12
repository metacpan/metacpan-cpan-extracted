package Mafia;

use 5.010001;
use strict;
use warnings;
use parent qw/Exporter/;

use constant;
use Storable qw/dclone/;

our $VERSION = '0.001005';

sub defconst { constant->import($_ => $_) for @_ }

BEGIN {
	# Roles
	defconst qw/vanilla goon doctor vigilante roleblocker jailkeeper gunsmith tracker watcher bodyguard rolecop cop sk hider/;

	# Factions
	defconst qw/mafia town/;

	# Extra traits
	defconst qw/miller godfather weak macho bulletproof/;

	# Messages
	defconst qw/MSG_NIGHT MSG_DAY MSG_PLAYERS_ALIVE MSG_DEATH MSG_GUNCHECK MSG_NORESULT MSG_TRACK MSG_WATCH MSG_COP MSG_ROLECOP/;

	# Action types
	defconst qw/ACT_KILL ACT_LYNCH ACT_PROTECT ACT_GUARD ACT_ROLEBLOCK ACT_GUNCHECK ACT_TRACK ACT_WATCH ACT_ROLECOP ACT_COP ACT_TRACK_RESULT ACT_WATCH_RESULT ACT_HIDE/;
}

use constant +{ ## no critic (Capitalization)
	townie => town,
	ROLE => [vanilla, goon, doctor, vigilante, roleblocker, jailkeeper, gunsmith, tracker, watcher, bodyguard, rolecop, cop, sk, hider],
	FACTION => [mafia, town],
	FLAG => [miller, godfather, weak, macho, bulletproof],
	ACTION_ORDER => [ACT_HIDE, ACT_ROLEBLOCK, ACT_PROTECT, ACT_GUARD, ACT_GUNCHECK, ACT_ROLECOP, ACT_COP, ACT_TRACK, ACT_WATCH, ACT_KILL, ACT_LYNCH, ACT_TRACK_RESULT, ACT_WATCH_RESULT],
	INVESTIGATIVE_ACTIONS => [ACT_GUNCHECK, ACT_TRACK, ACT_WATCH, ACT_ROLECOP, ACT_COP],
	GUNROLES => [vigilante, gunsmith],
};

my %ROLE_HASH = map { $_ => 1 } @{ROLE()};
my %FACTION_HASH = map { $_ => 1 } @{FACTION()};
my %FLAG_HASH = map { $_ => 1 } @{FLAG()};
my %INVESTIGATIVE_ACTIONS_HASH = map { $_ => 1 } @{INVESTIGATIVE_ACTIONS()};
my %GUNROLES_HASH = map { $_ => 1 } @{GUNROLES()};

our @EXPORT = do {
	no strict 'refs'; ## no critic (ProhibitNoStrict)
	grep { $_ !~ [qw/import/] and exists &$_ } keys %{__PACKAGE__ . '::'};
};

################################################## Helper subs

sub import {
	strict->import;
	goto &Exporter::import;
}

my (%players, %tplayers, @actions);
my $daycnt = 0;
my $nightcnt = 0;
my $isday = 0;
my $first = 1;

sub clean{
	%players = ();
	%tplayers = ();
	@actions = ();
	$daycnt = 0;
	$nightcnt = 0;
	$isday = 0;
	$first = 1;
}

sub uniq {
	my %hash = map { $_ => 1 } @_;
	keys %hash
}

sub phase {
	return "Day $daycnt" if $isday;
	return "Night $nightcnt" unless $isday;
}

sub rolename { ## no critic (RequireArgUnpacking)
	my %player = %{$players{$_[0]}};
	my ($faction, $role) = ($player{faction}, $player{role});
	if (defined $faction && $faction eq town && $role eq vanilla) {
		undef $faction;
		$role = 'Vanilla Townie';
	}
	my @tokens = ();
	push @tokens, ucfirst $faction if $faction;
	for my $flag (@{FLAG()}) {
		push @tokens, ucfirst $flag if $player{$flag}
	}
	push @tokens, ucfirst $role unless $role eq goon && $player{godfather};
	"@tokens"
}

sub msg {
	my ($type, @args) = @_;
	my %msg_lut = (
		MSG_NIGHT => sub {
			my ($night) = @args;
			say '' unless $first;
			$first = 0;
			say "It is Night $night";
		},

		MSG_DAY => sub {
			my ($day) = @args;
			say '' unless $first;
			$first = 0;
			say "It is Day $day";
		},

		MSG_PLAYERS_ALIVE => sub {
			@args = sort @args;
			say 'Players alive: ', join ', ', @args
		},

		MSG_DEATH => sub {
			my %args = @args;
			my ($who, $reason) = @args{'target', 'reason'};
			my $phase = phase;
			my $rolename = rolename $who;
			say "$who ($rolename) — $reason $phase";
		},

		MSG_GUNCHECK => sub {
			my %args = @args;
			my ($gunsmith, $who, $hasgun) = @args{'source', 'target', 'result'};
			say "$gunsmith: $who has a gun" if $hasgun;
			say "$gunsmith: $who does not have a gun" unless $hasgun;
		},

		MSG_NORESULT => sub {
			my %args = @args;
			my ($who) = $args{'source'};
			say "$who: No result"
		},

		MSG_TRACK => sub {
			my %args = @args;
			my ($tracker, $who, $result) = @args{'source', 'target', 'result'};
			my @result = @{$result};
			local $, = ', ';
			say "$tracker: $who did not visit anyone" unless scalar @result;
			say "$tracker: $who visited: @result" if scalar @result;
		},

		MSG_WATCH => sub {
			my %args = @args;
			my ($watcher, $who, $result) = @args{'source', 'target', 'result'};
			my @result = @{$result};
			local $, = ', ';
			say "$watcher: $who was not visited by anyone" unless scalar @result;
			say "$watcher: $who was visited by: @result" if scalar @result;
		},

		MSG_ROLECOP => sub {
			my %args = @args;
			my ($rolecop, $who, $role) = @args{'source', 'target', 'result'};
			say "$rolecop: $who\'s role is: $role"
		},

		MSG_COP => sub {
			my %args = @args;
			my ($cop, $who, $ismafia) = @args{'source', 'target', 'result'};
			say "$cop: $who is mafia" if $ismafia;
			say "$cop: $who is not mafia" unless $ismafia;
		},
	);

	$msg_lut{$type}->();
}

sub putaction {
	my ($delay,  $type, %args) = @_;
	$actions[$delay]->{$type} //= [];
	if (exists $args{target} && exists $args{source} && $players{$args{target}}{faction} eq mafia && $players{$args{source}}{weak}) {
		putaction($delay, ACT_KILL, target => $args{source}, reason => 'targeted scum');
	}
	push @{$actions[$delay]->{$type}}, \%args
}

sub doaction { ## no critic (ProhibitExcessComplexity)
	my ($type, $args) = @_;
	my %args = %$args;
	my $source = $args{source};
	my $target = $args{target};
	if (defined $source && defined $target) {
		# Watcher and tracker variables
		$tplayers{$source}{targets} //= [];
		push @{$tplayers{$source}{targets}}, $target;
		$tplayers{$target}{sources} //= [];
		push @{$tplayers{$target}{sources}}, $source;

		# Copy this action to everybody hiding behind $target
		if (exists $tplayers{$target}{hiders}) {
			for my $target (@{$tplayers{$target}{hiders}}) {
				my %new_args = %args;
				$new_args{target} = $target;
				$new_args{hidepierce} = 1;
				doaction($type, \%new_args);
			}
		}

		# Check if the action should be blocked
		my $strongkill = $type eq ACT_KILL && $args{strong};
		my $roleblocked = $tplayers{$source}{roleblocked};
		my $hidden = $tplayers{$target}{hidden};
		my $hidepierce = $args{hidepierce};
		if ($source && (( $roleblocked && !$strongkill ) || ($hidden && !$hidepierce) )) {
			msg MSG_NORESULT, %args if $INVESTIGATIVE_ACTIONS_HASH{$type};
			return
		}
	}

	my %act_lut = (
		ACT_KILL => sub {
			break if $tplayers{$target}{bulletproof} && defined $source;
			if ($tplayers{$target}{guard_count} && defined $source) {
				$tplayers{$target}{guard_count}--;
				# Copy this action to the first guard
				$args{target} = shift @{$tplayers{$target}{guards}};
				@_ = ($type, %args);
				goto &doaction;
			}
			if ($tplayers{$target}{protection} && !$args{strong}) {
				$tplayers{$target}{protection}--;
				break
			}
			msg MSG_DEATH, %args;
			delete $players{$target}
		},

		ACT_LYNCH => sub {
			if ($tplayers{$target}{guard_count}) {
				$tplayers{$target}{guard_count}--;
				$args{target} = shift @{$tplayers{$target}{guards}};
				$target=$args{target};
			}
			if ($tplayers{$target}{protection}) {
				$tplayers{$target}{protection}--;
				break
			}
			msg MSG_DEATH, %args, reason => 'lynched';
			delete $players{$target}
		},

		ACT_PROTECT => sub {
			my $count = $args{count} // 1;
			$tplayers{$target}{protection} += $count unless $tplayers{$target}{macho}
		},

		ACT_ROLEBLOCK => sub {
			$tplayers{$target}{roleblocked} = 1
		},

		ACT_GUNCHECK => sub {
			my $role = $players{$target}{role};
			my $hasgun = $GUNROLES_HASH{$role} || ($players{$target}{faction} eq mafia && $role ne doctor);
			msg MSG_GUNCHECK, %args, result => $hasgun
		},

		ACT_TRACK_RESULT => sub {
			msg MSG_TRACK, %args, result => [ uniq @{$tplayers{$target}{targets} // []} ];
		},

		ACT_WATCH_RESULT => sub {
			msg MSG_WATCH, %args, result => [ uniq @{$tplayers{$target}{sources} // []} ];
		},

		ACT_GUARD => sub {
			$tplayers{$target}{guard_count}++;
			$tplayers{$target}{guards} //= [];
			push @{$tplayers{$target}{guards}}, $source;
		},

		ACT_ROLECOP => sub {
			my $result = $players{$target}{role};
			$result = vanilla if $result eq goon;
			msg MSG_ROLECOP, %args, result => ucfirst $result
		},

		ACT_COP => sub {
			my $result = $players{$target}{faction} eq mafia;
			$result = 1 if $players{$target}{miller};
			$result = 0 if $players{$target}{godfather};
			msg MSG_COP, %args, result => $result
		},

		ACT_HIDE => sub {
			$tplayers{$source}{hidden} = 1;
			$tplayers{$target}{hiders} //= [];
			push @{$tplayers{$target}{hiders}}, $source
		},
	);

	$act_lut{$type}->();
}

sub process_phase_change {
	%tplayers = %{dclone \%players};
	my $actions = shift @actions;
	for my $type (@{ACTION_ORDER()}) {
		doaction $type, $_ for @{$actions->{$type}}
	}
}

################################################## User subs

sub player {
	my ($name, @args) = @_;
	my %player;
	for my $trait (@args) {
		$player{role} = $trait    if $ROLE_HASH{$trait};
		$player{faction} = $trait if $FACTION_HASH{$trait};
		$player{$trait} = 1       if $FLAG_HASH{$trait};
	}

	$players{$name} = \%player;
}

sub day {
	process_phase_change;
	$isday = 1;
	msg MSG_DAY, ++$daycnt;
	msg MSG_PLAYERS_ALIVE, keys %players;
}

sub night {
	process_phase_change;
	$isday = 0;
	msg MSG_NIGHT, ++$nightcnt;
	msg MSG_PLAYERS_ALIVE, keys %players;
}

sub lynch {
	my ($who) = @_;
	putaction 0, ACT_LYNCH, target => $who;
}

sub factionkill {
	my ($killer, $who, $reason, @args) = @_;
	putaction 0, ACT_KILL, target => $who, source => $killer, reason => $reason, @args;
}

sub protect {
	my ($doctor, $who) = @_;
	putaction 0, ACT_PROTECT, target => $who, source => $doctor;
}

sub vig {
	my ($vig, $who, $reason, @args) = @_;
	putaction 0, ACT_KILL, target => $who, source => $vig, reason => $reason, @args;
}

sub roleblock {
	my ($roleblocker, $who) = @_;
	putaction 0, ACT_ROLEBLOCK, target => $who, source => $roleblocker;
}

sub jailkeep {
	my ($jailkeeper, $who) = @_;
	putaction 0, ACT_ROLEBLOCK, target => $who, source => $jailkeeper;
	putaction 0, ACT_PROTECT, target => $who, source => $jailkeeper, count => 1000;
}

sub guncheck {
	my ($gunsmith, $who) = @_;
	putaction 0, ACT_GUNCHECK, target => $who, source => $gunsmith;
}

sub track {
	my ($tracker, $who) = @_;
	putaction 0, ACT_TRACK, target => $who, source => $tracker;
	putaction 0, ACT_TRACK_RESULT, target => $who, source => $tracker;
}

sub watch {
	my ($watcher, $who) = @_;
	putaction 0, ACT_WATCH, target => $who, source => $watcher;
	putaction 0, ACT_WATCH_RESULT, target => $who, source => $watcher;
}

sub guard {
	my ($guard, $who) = @_;
	putaction 0, ACT_GUARD, target => $who, source => $guard;
}

sub rolecopcheck {
	my ($rolecop, $who) = @_;
	putaction 0, ACT_ROLECOP, target => $who, source => $rolecop;
}

sub copcheck {
	my ($cop, $who) = @_;
	putaction 0, ACT_COP, target => $who, source => $cop;
}

sub skill {
	my ($sk, $who, $reason, @args) = @_;
	putaction 0, ACT_KILL, target => $who, source => $sk, reason => $reason, @args;
}

sub hide {
	my ($hider, $who) = @_;
	putaction 0, ACT_HIDE, target => $who, source => $hider;
}

1;
__END__

=encoding utf-8

=head1 NAME

Mafia - easily moderate Mafia games

=head1 SYNOPSIS

  #!/usr/bin/perl -w
  use Mafia;

  player 'Banana Bob', cop, town;
  player 'Dragon Phoenix', vanilla, townie;
  player 'Gammie', mafia, goon;
  player 'gslamm', vanilla, townie;
  player 'Untrod Tripod', mafia, goon;
  player 'Werebear', vanilla, townie;
  player 'willows_weep', town, doctor;

  day;
  lynch 'Untrod Tripod';

  night;
  factionkill 'Gammie', 'willows_weep', 'shot';
  copcheck 'Banana Bob', 'gslamm';

  day;
  lynch 'Gammie';

  night;

=head1 DESCRIPTION

Mafia.pm is a Perl extension for easily moderating Mafia games. You don't even need to know Perl to use it (see L<"WHAT YOU NEED TO KNOW"> for details).

=head1 WHAT YOU NEED TO KNOW

A typical script starts with the following two lines

  #!/usr/bin/perl -w
  use Mafia;

The rest of the script is a series of function calls that describe the players and their actions.

A function call looks like this:

  function_name first_argument, second_argument, ...

Each argument is either a number, a string (which is a sequence of characters between single or double quotes, such as C<'badguy'>, C<'qwrf'>) or a constant (such as C<mafia>, C<vanilla>, C<bulletproof>).

Example calls:

  player 'Somebody', mafia, goon; # player is the function, 'Somebody' is a string, mafia and goon are constants.
  lynch 'Nobody'; # lynch is the function, 'Nobody' is a string.
  day; # day is the function. There are no arguments.

=head1 FUNCTIONS

=over

=item B<player> I<name>, I<trait>, ...

Defines a new player named I<name> and its traits (role, faction, role modifiers).

Roles: C<vanilla, goon, doctor, vigilante, roleblocker, jailkeeper, gunsmith, tracker, watcher, bodyguard, rolecop, cop, sk, hider>.

Factions: C<mafia, town>. C<townie> is a synonim for C<town>.

Other attributes: C<miller, godfather, weak, macho, bulletproof>

These traits may be specified in any order.

Example usage:

  player 'alice', town, bulletproof, miller, vigilante; # Alice is a NK-Immune Miller Vig
  player 'bob', town, weak, doctor; # Bob is a Town Weak Doctor
  player 'eve', mafia, godfather, goon; # Eve is a Mafia Godfather

=item B<day>

Defines the start of a new Day. All actions in the previous Night are now resolved.

=item B<night>

Defines the start of a new Night. All actions in the previous Day are now resolved.

=item B<lynch> I<player>

Notes that I<player> was lynched.

=item B<factionkill> I<killer>, I<player>, I<flavour>, [ strong => 1 ]

Notes that I<killer> killed I<player> with flavour I<flavour>. Append C<< strong => 1 >> if the kill should ignore roleblocks and doctor/jailkeeper protections. Use this for mafia kills.

Example usage:

  factionkill 'eve', 'alice', 'strangled to death';
  factionkill 'eve', 'bob', 'brutally murdered', strong => 1; # This is a strongman kill

=item B<protect> I<doctor>, I<player>

Notes that I<doctor> protected I<player>.

=item B<vig> I<vigilante>, I<player>, I<flavour>, [ strong => 1 ]

Notes that I<killer> killed I<player> with flavour I<flavour>. Append C<< strong => 1 >> if the kill should ignore roleblocks and doctor/jailkeeper protections. Use this for Vigilante/Juggernaut kills.

Example usage:

  vig 'chuck', 'bob', 'shot';
  vig 'chuck', 'bob', 'shot seven times', strong => 1; # This is a Juggernaut (Strongman Vigilante) kill

=item B<roleblock> I<roleblocker>, I<player>

Notes that I<roleblocker> roleblocked I<player>.

=item B<jailkeep> I<jailkeeper>, I<player>

Notes that I<jailkeeper> roleblocked and protected I<player>.

=item B<guncheck> I<gunsmith>, I<player>

Notes that I<gunsmith> checked if I<player> has a gun.

=item B<track> I<tracker>, I<player>

Notes that I<tracker> tracked I<player>.

=item B<watch> I<watcher>, I<player>

Notes that I<watcher> watched I<player>.

=item B<guard> I<bodyguard>, I<player>

Notes that I<bodyguard> guarded I<player>

=item B<rolecopcheck> I<rolecop>, I<player>

Notes that I<rolecop> checked the role of I<player>

=item B<copcheck> I<cop>, I<player>

Notes that I<cop> checked whether I<player> is mafia.

=item B<skill> I<SK>, I<player>, I<flavour>, [ strong => 1 ]

Notes that I<SK> killed player with flavour I<flavour>. Append C<< strong => 1 >>> if the kill should ignore roleblocks and doctor/jailkeeper protections. Use this for Serial Killer kills.

=item B<hide> I<hider>, I<player>

Notes that I<hider> hid behind I<player>.

=back

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2017 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
