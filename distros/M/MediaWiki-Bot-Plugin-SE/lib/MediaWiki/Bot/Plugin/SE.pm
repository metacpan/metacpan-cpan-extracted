package MediaWiki::Bot::Plugin::SE;
use locale;
use POSIX qw(locale_h);
setlocale(LC_ALL, "en_US.UTF-8");
use strict;

our $VERSION = '0.2.1';

=head1 NAME

MediaWiki::Bot::Plugin::SE - a plugin for MediaWiki::Bot which contains data retrieval tools for the 2009 Steward elections

=head1 SYNOPSIS

use MediaWiki::Bot;

my $editor = MediaWiki::Bot->new('Account');
$editor->login('Account', 'password');
$editor->se_get_stats('User:Candidate');

=head1 DESCRIPTION

MediaWiki::Bot is a framework that can be used to write Wikipedia bots. MediaWiki::Bot::Plugin::SE can be used for data retrieval and reporting bots related to the 2009 Steward Elections

=head1 AUTHOR

Dan Collins (ST47) and others

=head1 METHODS

=over 4

=item import()

Calling import from any module will, quite simply, transfer these subroutines into that module's namespace. This is possible from any module which is compatible with MediaWiki/Bot.pm.

=cut

sub import {
	no strict 'refs';
	foreach my $method (qw/se_get_stats se_check_valid/) {
		*{caller() . "::$method"} = \&{$method};
	}
}

=item se_get_stats($candidate[, $text])


=cut

sub se_get_stats {
	my $self    = shift;
	my $user    = shift;
	my $text    = shift || $self->get_text("Stewards/elections 2009/statements/$user");
	$text=~/
		==.+?yes.+?==(.+)
		==.+?no.+?==(.+)
		==.+?neutral.+?==(.+)/sx;
	my $su=$1;
	my $op=$2;
	my $ne=$3;
	my ($s, $o, $n);
	while ($su=~/\n\#[^\#\*\:\n]/g) {$s++}
	while ($op=~/\n\#[^\#\*\:\n]/g) {$o++}
	while ($ne=~/\n\#[^\#\*\:\n]/g) {$n++}
	return ($s, $o, $n);
}

=item se_check_valid($voter)

1=valid
2=valid, no SUL
0=not valid
-1=IP

=cut

sub se_check_valid {
	my $self    = shift;
	my $voter    = shift;
	if ($voter=~/\d+\.\d+\.\d+\.\d+/) {
		return (-1);
	}
	print "Checking $voter global\n" if $self->{debug};
	my $url="http://toolserver.org/~vvv/".
	"sulutil.php?user=$voter";
	print "$url\n" if $self->{debug};
	my $res=$self->{mech}->get($url);
	print "Got URL\n" if $self->{debug};
	my $content=$res->content;
	if ($content=~/metawiki.+(merged|created|home)/) {
		while ($content=~/<td>(\d+)<\/td>.+
				(merged|created|home)/xg) {
			if ($1>600) {
				print "PASS\n" if $self->{debug};
				return (1);
			} else {
				#print $1;
			}
		}
	}
	print "Done checking global, no pass.\n" if $self->{debug};

	my %wikis;
#	$wikis{'enwiki'}++;
	$wikis{'metawiki'}=$voter;
	my $userpage=$self->get_text("User:$voter")."\n";
	print $userpage."\n" if $self->{debug};
	while ($userpage=~/{[^}|]+\|:?([a-z]{2,3}):/ig) {
		$wikis{$1 ."wiki"}=$voter;
	}
	while ($userpage=~/\[\[:?w?:?([a-z]{2,3}):[^\]]+?:([^\]]+?)[\|\]]/ig) {
		$wikis{$1 ."wiki"}=$2;
	}
	while ($userpage=~/\[?http:\/\/([a-z]{2,3})\.wikipedia\.org
			\/w(?:iki)?\/.+?:(.+?)[\s\|\]\n\b\&]/igx) {
		$wikis{$1 ."wiki"}=$2;
	}

	foreach my $wiki (keys %wikis) {
		my $check=$wikis{$wiki};
		print "Checking $wiki\n" if $self->{debug};
		my $url="http://toolserver.org/~pathoschild/".
		"accounteligibility/?user=$check".
		'&wiki='. $wiki .'_p&event=2';
		print "$url\n" if $self->{debug};
		my $res=$self->{mech}->get($url);
		print $res->decoded_content if $self->{debug}>2;
		if ($res->decoded_content=~/This account is\s\s?eligible to vote/) {
			print "PASS\n" if $self->{debug};
			return (2, $wiki, $check);
		}
	}
	return (0);
}

1;
