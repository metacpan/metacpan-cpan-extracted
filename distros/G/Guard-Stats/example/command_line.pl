#!/usr/bin/perl -w

# Example of Guard::Stats
# usage: $0
# Type commands [cfdsqh] to perform actions on guards and display statistics

use strict;
use Data::Dumper;

use Guard::Stats;

my $usage = <<"EOF";
Commands (only 1st letter counts):
[c]reate <id>
[f]inish <id> [<result>]
[d]estroy <id>
[s]how stat
[q]uit
[h]elp
EOF

my $st = Guard::Stats->new( want_time => 1 );

my %g; # guards
my %action = (
	c => sub { $g{$_[0]} = $st->guard },
	d => sub { delete $g{$_[0]} },
	f => sub { $g{$_[0]}->end( $_[1] ) },
	q => sub { exit },
	s => sub { my_print( Dumper ($st->get_stat)) },
	l => sub { my_print(
		map { ($g{$_}->is_done ?'+' :' '). "$_\n" } sort keys %g
	) },
	h => sub { my_print( $usage ) },
);


while (<>) {
	/^\s*(\S)\S*(?:\s+(\S*)\s+(.*))?$/ or next;
	my $code = $action{$1};
	unless ($code) {
		my_print ("Wrong command $1");
		next;
	};
	$code->($2, $3);
};

sub my_print {
	my $str = join "", @_;
	$str =~ s/^/# /mg;
	$str =~ s/\n*$/\n/s;
	print $str;
};

