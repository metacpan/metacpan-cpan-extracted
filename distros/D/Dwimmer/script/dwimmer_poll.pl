#!/usr/bin/perl
use strict;
use warnings;

# step:
# 1) replace IP and SID with counter values and save as single json (this file can already be shared).
# 2) filter duplicate SIDs or duplicate IPs (the user can choose), create new file.
# 3) Collect stats (all the other items) and save them as a json file.
# 4) Generate pie graphs from the choice based questions.
# 5) Allow the listing of all the "other" and free-text fields.
# *) at some place we should let the owner remove some textual responses or fix them (assuming typos and grammar errors)


use Data::Dumper qw(Dumper);
use File::Slurp  qw(read_file write_file);
use JSON         qw(from_json to_json);
use Params::Util qw(_SCALAR _ARRAY _STRING _NUMBER);
use Pod::Usage   qw(pod2usage);
use Getopt::Long qw(GetOptions);

=head1 NAME

Sanitize a poll file

=head1 SYNOPSIS


PARAMETERS:
   --clean        (replace IP and SID with counter values on same IP same
                  counter mapping to allow identificating duplicates
                  without the privacy issues.)
   --filter [SID|IP|all]

   --report       generate report from the already cleaned and filtered data

   --pollid       id of the poll

=cut

my %opt;
GetOptions(\%opt,
	'pollid=s',
	'clean',
	'filter=s',
);

pod2usage if not $opt{pollid};
my $poll_file = "polls/$opt{pollid}.json";
my $in_file   = "polls/$opt{pollid}.txt";
my $out_file  = "polls/$opt{pollid}.out";
die "Could not find poll file '$poll_file'" if not -e $poll_file;
die "Could not find in file '$in_file'" if not -e $in_file;
die "There is already an out file '$out_file'" if -e $out_file;

my $poll = from_json scalar read_file $poll_file;

if ($opt{filter}) {
	die "Invalid --filter" if $opt{filter} !~ /^(SID|IP|all)$/;
} else {
	$opt{filter} = '';
}
#die Dumper \%opt;

#pod2usage if not $result;
clean() if $opt{clean};
#print Dumper \%DUPLICATE;
exit;


sub clean {
	my $raw_data = read_file($in_file);
	my @p = split  /^$/m, $raw_data;
	#print scalar @p;
	#print $p[0];

	my %MAP;
	my %count = (SID => 0, IP => 0);
	my %DUPLICATE;
	my @all;
	my %RESULT;

	foreach my $json (@p) {
		next if $json =~ /^\s*$/;
	#	print $json;
	#	print "-----------------------\n";
		my $d = from_json($json);
		foreach my $f (qw(SID IP)) {
			if (not $MAP{$f}{ $d->{$f} }) {
				$count{$f}++;
				$MAP{$f}{ $d->{$f} } = $count{$f};
			} else {
				$DUPLICATE{$f}++;
				next if $f eq 'SID' and ($opt{filter} eq 'SID' or $opt{filter} eq 'all');
				next if $f eq 'IP'  and ($opt{filter} eq 'IP'  or $opt{filter} eq 'all');
			}
			$d->{$f} = $MAP{$f}{ $d->{$f} };
			push @all, $d;
		}

	}
	write_file($out_file, to_json \@all, { pretty => 1, utf8 => 1 });
}

sub report {
	foreach my $key (keys %$d) {
		next if $key =~ /^(SID|TS|IP|id)$/;
		next if not defined $d->{$key}; # TODO report error
		next if $d->{$key} eq '';

		if ($key =~ /^other__/) {
			push @{ $RESULT{$key} }, $d->{$key};
		} elsif (_ARRAY($d->{$key})) {
			$RESULT{ $key }{$_}++ for @{ $d->{$key} };
		} elsif (defined _STRING($d->{$key})) {
			# source_of_perl_news
			$RESULT{ $key }{$_}++ for $d->{$key};
		} else {
			#die ref $d->{$key};
			die "Unhandled key: '$key' " . Dumper $d;
		}
	}
	write_file($report_file, to_json \%RESULT, { pretty => 1, utf8 => 1 });
}




