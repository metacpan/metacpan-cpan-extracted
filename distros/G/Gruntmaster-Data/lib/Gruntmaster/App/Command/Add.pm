package Gruntmaster::App::Command::Add;

use 5.014000;
use warnings;

our $VERSION = '6000.001';

use Gruntmaster::App '-command';
use Gruntmaster::Data;

use Date::Parse qw/str2time/;
use File::Slurp qw/read_file write_file/;
use IO::Prompter [ -style => 'bold', '-stdio', '-verbatim' ];
use JSON::MaybeXS qw/encode_json/;
use PerlX::Maybe;
use Term::ANSIColor qw/RED RESET/;

use constant LEVEL_VALUES => {
	beginner => 100,
	easy => 250,
	medium => 500,
	hard => 1000,
};

sub usage_desc { '%c [-cp] add id' }

my %TABLE = (
	contests => \&add_contest,
	problems => \&add_problem,
);

sub validate_args {
	my ($self, $opt, $args) = @_;
	my @args = @$args;
	$self->usage_error('No table selected') unless $self->app->table;
	$self->usage_error('Don\'t know how to add to this table') unless $TABLE{$self->app->table};
	$self->usage_error('Wrong number of arguments') if @args != 1;
}

sub execute {
	my ($self, $opt, $args) = @_;
	my ($id) = @$args;
	$TABLE{$self->app->table}->($self, $id);
}

sub add_contest {
	my ($self, $id) = @_;

	my $name = prompt 'Contest name';
	my $owner = prompt 'Owner';
	my $start = str2time prompt 'Start time' or die "Cannot parse time\n";
	my $stop = str2time prompt 'Stop time' or die "Cannot parse time\n";

	db->insert(contests => {id => $id, name => $name, owner => $owner, start => $start, stop => $stop});
	purge '/ct/';
}

sub add_problem {
	my ($self, $id) = @_;
	my $db = $self->app->db;

	my $name = prompt 'Problem name';
	my $private = prompt('Private?', '-yn') eq 'y';
	my $contest = prompt 'Contest';
	my $author = prompt 'Problem author (full name)';
	my $writer = prompt 'Problem statement writer (full name)';
	my $owner = prompt 'Problem owner (username)';
	my $level = prompt 'Problem level', -menu => "beginner\neasy\nmedium\nhard";
	my $value = LEVEL_VALUES->{$level};
	my $statement = read_file prompt 'File with problem statement', -complete => 'filenames';
	my $generator = prompt 'Generator', -menu => "File\nRun\nUndef";
	my $runner = prompt 'Runner', -menu => "File\nVerifier\nInteractive";
	my $judge = prompt 'Judge', -menu => "Absolute\nPoints";
	my $testcnt = prompt 'Test count', '-i';

	my $timeout = prompt 'Time limit (seconds)', '-n';
	my $olimit = prompt 'Output limit (bytes)', '-i';
	say 'Memory limits are broken, so I won\'t ask you for one';

	my (@tests, $gensource, $genformat, $versource, $verformat);

	if ($generator eq 'Run') {
		$gensource = read_file prompt '[Generator::Run] Generator file name', -complete => 'filenames';
		$genformat = prompt '[Generator::Run] Generator format', -menu => [qw/C CPP MONO JAVA PASCAL PERL PYTHON/];
	}

	if ($runner eq 'File') {
		my $default = $judge eq 'Points' ? 10 : 'Ok';
		$tests[$_ - 1] = prompt "[Runner::File] Score for test ${_} [$default]", -default => $default for 1 .. $testcnt;
	}

	if ($runner eq 'Verifier' || $runner eq 'Interactive') {
		say RED, 'WARNING: Runner::Interactive is experimental', RESET if $runner eq 'Interactive';
		$versource = read_file prompt "[Runner::$runner] Verifier file name", -complete => 'filenames';
		$verformat = prompt "[Runner::$runner] Verifier format", -menu => [qw/C CPP MONO JAVA PASCAL PERL PYTHON/];
	}

	my %options = (
		id => $id,
		name => $name,
		level => $level,
		value => $value,
		statement => $statement,
		author => $author,
		writer => $writer,
		owner => $owner,
		generator => $generator,
		runner => $runner,
		judge => $judge,
		testcnt => $testcnt,
		maybe private => $private,
		maybe timeout => $timeout,
		maybe olimit => $olimit,
		maybe gensource => $gensource,
		maybe genformat => $genformat,
		maybe versource => $versource,
		maybe verformat => $verformat,
	);
	$options{tests} = encode_json \@tests if @tests;
	db->insert(problems => \%options);
	db->insert(contest_problems => {problem => $id, contest => $contest}) if $contest;
	purge '/pb/';
}

1;
__END__

=encoding utf-8

=head1 NAME

Gruntmaster::App::Command::Add - add a problem or contest by answering a series of prompts

=head1 SYNOPSIS

  gm -p add aplusb
  gm -c add test_contest

=head1 DESCRIPTION

The add command creates a new problem or contest by prompting the user
for the properties of the new object. It takes a single argument, the
ID of the new object.

=head1 SEE ALSO

L<gm>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2016 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
