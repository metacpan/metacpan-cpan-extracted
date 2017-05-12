#!/usr/bin/env perl

use common::sense;

use Device::Hue;
use Device::Hue::LightSet;

	my $hue = Device::Hue->new({
#		'bridge'	=> 'http://.....',
#		'key'		=> '.....',
	});

	$hue->debug(1);

	my $commands = {

		'light'		=> 'number',
		'lights'	=> 'number,<number>',
		'on'		=> undef,
		'off'		=> undef,
		'wait'		=> 'seconds',
		'trtime'	=> 'seconds',
		'bri'		=> 'integer',
		'kelvin'	=> 'integer',
	};

	exit(help()) unless @ARGV;

	my @cmds = @ARGV;

	while (scalar @cmds) {

                my $cmd = shift @cmds;

                # check command
                exit(help("Unknown command: $cmd\n"))
                        unless grep { $cmd eq $_ } keys %$commands;

                # fetch command option if required
                my $what = shift @cmds
                        if defined $commands->{$cmd};
        }
	

	my $light = undef;

	while (scalar @ARGV) {

		my $cmd = shift;
		my $arg = shift if defined $commands->{$cmd};

		my $rc = job($cmd, $arg);
	}

	$light->commit
		if defined $light
		and $light->in_transaction;
	

sub job
{
        my ($cmd, $arg) = @_;

	if ($cmd eq 'wait') {

		$light->commit
			if defined $light
			and $light->in_transaction;

		sleep $arg;
		return;

	} elsif ($cmd eq 'light' || $cmd eq 'lights') {

		$light->commit
			if defined $light
			and $light->in_transaction;

		$light = Device::Hue::LightSet->create(map { $hue->light($_); } split(/,/, $arg));
		$light->begin;
		return;
	}

	die unless defined $light;

	if ($cmd eq 'on') {

		$light->on;		

	} elsif ($cmd eq 'off') {

		$light->off;

	} elsif ($cmd eq 'trtime') {

		$light->transitiontime($arg * 10);

	} elsif ($cmd eq 'kelvin') {

		$light->ct_k($arg);

	} elsif ($cmd eq 'bri') {

		$light->bri($arg);

	} elsif ($cmd eq 'begin') {

		$light->begin;

	} elsif ($cmd eq 'commit') {

		$light->commit;
	}
}


sub help
{
        print @_;

        print "\nUsage:\n\n";

        foreach (sort keys %$commands) {
                print "\t$_\t[", join(',', @{$commands->{$_}}), "]\n"
                        if defined $commands->{$_}
                        and ref($commands->{$_}) eq 'ARRAY';

                printf "\t$_\t<%s>\n", $commands->{$_}
                        if defined $commands->{$_};

                print "\t$_\n"
                        if not defined $commands->{$_};
        }

	print "\nexample: hue.pl light 3 on bri 10 wait 5 bri 150\n";
	print "\n         hue.pl light 1,3 bri 10 kelvin 3000 on light 2 bri 100 on light 1,2 off\n";
	print "\n";
}
