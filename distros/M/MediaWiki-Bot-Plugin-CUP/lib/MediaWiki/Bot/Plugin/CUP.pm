package MediaWiki::Bot::Plugin::CUP;

use strict;

our $VERSION = '0.3.2';

=head1 NAME

MediaWiki::Bot::Plugin::CUP - a plugin for MediaWiki::Bot which contains data retrieval tools for the 2009 WikiCup hosted on the English Wikipedia

=head1 SYNOPSIS

use MediaWiki::Bot;

my $editor = MediaWiki::Bot->new('Account');
$editor->login('Account', 'password');
$editor->cup_get_all('User:Contestant');

=head1 DESCRIPTION

MediaWiki::Bot is a framework that can be used to write Wikipedia bots. MediaWiki::Bot::Plugin::CUP can be used for data retrieval and reporting bots related to the 2009 WikiCup

=head1 AUTHOR

Dan Collins (ST47) and others

=head1 METHODS

=over 4

=item import()

Calling import from any module will, quite simply, transfer these subroutines into that module's namespace. This is possible from any module which is compatible with MediaWiki/Bot.pm.

=cut

sub import {
	no strict 'refs';
	foreach my $method (qw/cup_get_all cup_get_item/) {
		*{caller() . "::$method"} = \&{$method};
	}
}

=item cup_get_all($contestant[, $text])

Will retrieve the contestant's total score. $text is optional but recommended if you will be calling these functions multiple times for the same user or if you will be using the submisssions pages, for performance reasons. Also, if you need to get several users' stats, please use MediaWiki::Bot's get_pages sub to retrieve all the submissions pages in one go. Also, if you want any control at all over where we get the data, say if there's a capitalization mismatch or the submissions pages are not located where I think they are, then if you pass the text of the submission page to me, I will use your submissions page. Finally, note that for purposes of getting edit counts, we use $contestant as the username, so please don't do anything to mangle that just so that I get the right submissions page. File a bug first.

Data is returned as edits, gas, fas, fls, fss, fpis, fpos, dyks, itns, fts, gts, and total score. All are in number of points claimed, not number of articles submitted.

=cut

sub cup_get_all {
	my $self    = shift;
	my $user    = shift;
	my $text    = shift;
	my %hash;
	my $config=$self->{'cup'};
	if (defined $self->{'cup'}->{'override'}) {
	unless (defined $self->{'cup'}->{'override'}) {
		my $text=$self->get_text($self->{'cup'}->{'overridefrom'});
		$self->{'cup'}->{'override'}=$text;
	}
	while ($self->{'cup'}->{'override'}=~/User\((.+)\) => (.+) => (.+) => (.+)/g) {
		if ($1 eq $user) {
			$config->{$2}->{$3}=$4;
		}
	}
	}
	foreach my $item (keys %{$config}) {
		unless (ref($config->{$item}) eq 'HASH') {next}
		$hash{$item}=$self->cup_get_item($user, $item, $text);
	}
	my %score; my $score;
	foreach my $item (keys %hash) {
		$score+=$config->{$item}->{'score'} * $hash{$item};
		$score{$item}=$config->{$item}->{'score'} * $hash{$item};
	}
	my @return;
	foreach my $item (@{$config->{'return'}}) {
		if ($item->{'type'} eq 'edits') {
			my $score;
			foreach my $type (@{$item->{'types'}}) {
				$score+=$score{$type};
			}
			push @return, $score;
		} elsif ($item->{'type'} eq 'number') {
			push @return, $hash{$item->{'key'}};
		} elsif ($item->{'type'} eq 'score') {
			push @return, $score{$item->{'key'}};		
		}
	}
	push @return, $score;
	return @return;
}

=item cup_get_item($contestant, $item[, $text])

Will retrieve the contestant's subscore for a particular item. $item must match the title in config exactly. $text is optional but recommended.

Data is returned as number, not score. For scores or for general use, use cup_get_all.

=cut

sub cup_get_item {
	my $self    = shift;
	my $user    = shift;
	my $item    = shift;
	my $text    = shift;
	my $return = 0;
	my $config=$self->{'cup'};
	if (defined $self->{'cup'}->{'override'}) {
	unless (defined $self->{'cup'}->{'override'}) {
		my $text=$self->get_text($self->{'cup'}->{'overridefrom'});
		$self->{'cup'}->{'override'}=$text;
	}
	while ($self->{'cup'}->{'override'}=~/User\((.+)\) => (.+) => (.+) => (.+)/g) {
		if ($1 eq $user) {
			$config->{$2}->{$3}=$4;
		}
	}
	}
#print "Checking $item for $user\n";
	unless ($text) {
		if ($config->{$item}->{'method'} eq 'regex' or $config->{$item}->{'method'} eq 'split') {
			my $page=$config->{'submissions'};
			$page=~s/\$USER/$user/i;
			$text=$self->get_text($page);
		}
	}
	if ($config->{$item}->{'method'} eq 'split') {
#		print "$item\n";
		my @text = split ($config->{$item}->{'regex'}, $text);
#		print "$text\n";
		my $data = $text[$config->{$item}->{'index'}];
#		print "$data\n";
		my $regex = $config->{$item}->{'countregex'};
#		print "$regex\n";
		while ($data=~/$regex/g) {$return++}
#		print "$return\n";
	} elsif ($config->{$item}->{'method'} eq 'regex') {
		my $regex=$config->{$item}->{'regex'};
		if ($text and $text ne 2) {
			$text=~/$regex/;
			$return=$1 || 0;
		} else {
			$return=0;
		}
	} elsif ($config->{$item}->{'method'} eq 'ecquery') {
		my $hash={	action	=> 'query',
			list	=> 'usercontribs',
			ucuser	=> "User:$user",
			ucstart => '2009-01-01T00:00:00Z',
			uclimit	=> 500,
			ucdir	=> 'newer',
			%{$config->{$item}->{'params'}}};
		my $res=$self->{api}->list($hash);
#		use Data::Dumper; print Dumper($hash); print Dumper($res);
		foreach my $edit (@{$res}) {
			if ($config->{$item}->{'notregex'}) {
				my $regex=$config->{$item}->{'notregex'};
				if ($edit->{'comment'} !~ /$regex/) {
					$return++;
				}
			} elsif ($config->{$item}->{'regex'}) {
				my $regex=$config->{$item}->{'regex'};
				if ($edit->{'comment'} =~ /$regex/) {
					$return++;
				}
			} else {
				$return++;
			}
		}
	}
#print "Returning $return\n";
	return $return;
}

1;
