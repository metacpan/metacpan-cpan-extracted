package Gruntmaster::Data;
use 5.014;
use warnings;

use parent qw/Exporter/;
our $VERSION = '6000.001';
our @EXPORT = qw/dbinit purge db user_list user_entry problem_list problem_entry contest_list contest_entry contest_has_problem job_list job_entry create_job standings update_status rerun_job rerun_problem take_job finish_job open_problem/;
our @EXPORT_OK = @EXPORT;

use JSON::MaybeXS qw/decode_json/;
use HTTP::Tiny;
use PerlX::Maybe qw/maybe/;

use DBI;
use DBIx::Simple;
use List::Util qw/sum/;
use SQL::Abstract;

use constant PROBLEM_PUBLIC_COLUMNS => [qw/id author writer level name owner private timeout olimit value/];
use constant JOBS_PER_PAGE => 50;

my %statements = (
	user_list_sth => 'SELECT * FROM user_list LIMIT 200',
	user_entry_sth => 'SELECT * FROM user_data WHERE id = ?',

	problem_status_sth => 'SELECT problem,solved FROM problem_status WHERE owner = ?',
	contest_status_sth => 'SELECT contest,score,rank FROM contest_status WHERE owner = ?',

	contest_list_sth => 'SELECT * FROM contest_entry',
	contest_entry_sth => 'SELECT * FROM contest_entry WHERE id = ?',
	contest_has_problem_sth => 'SELECT EXISTS(SELECT 1 FROM contest_problems WHERE contest = ? AND problem = ?)',
	opens_sth => 'SELECT problem,owner,time FROM opens WHERE contest = ?',

	problem_entry_sth => 'SELECT ' . (join ',', @{PROBLEM_PUBLIC_COLUMNS()}, 'statement', 'solution') . ' FROM problems WHERE id = ?',
	limits_sth => 'SELECT format,timeout FROM limits WHERE problem = ?',

	job_entry_sth => 'SELECT * FROM job_entry WHERE id = ?',

	rerun_problem_sth => 'UPDATE jobs SET daemon=NULL,result=-2,result_text=NULL,results=NULL,errors=NULL WHERE problem = ?',
	rerun_job_sth => 'UPDATE jobs SET daemon=NULL,result=-2,result_text=NULL,results=NULL,errors=NULL WHERE id = ?',
	take_job_sth => 'UPDATE jobs SET daemon=? WHERE id = (SELECT id FROM jobs WHERE daemon IS NULL LIMIT 1 FOR UPDATE) RETURNING id',
);

our $db;
sub db () { $db }

sub dbinit {
	$db = DBIx::Simple->new(@_);
	$db->keep_statements = 100;
	$db->dbh->do('SET search_path TO gruntmaster, public');
};

sub purge;

sub _query {
	my ($stat, @extra) = @_;
	$db->query($statements{$stat}, @extra)
}

my (%name_cache, %name_cache_time);
use constant NAME_CACHE_MAX_AGE => 5;

sub _object_name {
	my ($table, $id) = @_;
	$name_cache_time{$table} //= 0;
	if (time - $name_cache_time{$table} > NAME_CACHE_MAX_AGE) {
		$name_cache_time{$table} = time;
		$name_cache{$table} = {};
		$name_cache{$table} = $db->select($table, 'id,name')->map;
	}

	$name_cache{$table}{$id}
}


sub _add_names ($) { ## no critic (ProhibitSubroutinePrototypes)
	my ($el) = @_;
	return unless defined $el;
	if (ref $el eq 'ARRAY') {
		&_add_names ($_) for @$el ## no critic (ProhibitAmpersandSigils)
	} else {
		for my $object (qw/contest owner problem/) {
			my $table = $object eq 'owner' ? 'users' : "${object}s";
			$el->{"${object}_name"} = _object_name $table, $el->{$object} if defined $el->{$object}
		}
	}

	$el
}

sub user_list { scalar _query('user_list_sth')->hashes }

sub user_entry {
	my ($id) = @_;
	my $ret = _query('user_entry_sth', $id)->hash;
	$ret->{problems} = _add_names _query('problem_status_sth', $id)->hashes;
	$ret->{contests} = _add_names _query('contest_status_sth', $id)->hashes;

	$ret;
}

sub problem_list {
	my (%args) = @_;
	my @columns = @{PROBLEM_PUBLIC_COLUMNS()};
	push @columns, 'solution' if $args{solution};
	my %where;
	$where{private} = 0 unless $args{contest} || $args{private};
	$where{'cp.contest'} = $args{contest} if $args{contest};
	$where{owner} = $args{owner} if $args{owner};

	my $table = $args{contest} ? 'problems JOIN contest_problems cp ON cp.problem = id' : 'problems';
	_add_names $db->select(\$table, \@columns, \%where, 'name')->hashes
}

sub problem_entry {
	my ($id, $contest) = @_;
	$contest = contest_entry ($contest) if $contest;
	my $ret = _add_names _query(problem_entry_sth => $id)->hash;
	my $limits = _query(limits_sth => $id)->hashes;
	$ret->{limits} = $limits if @$limits;

	if ($contest) {
		$ret->{contest_start} = $contest->{start};
		$ret->{contest_stop}  = $contest->{stop};
		delete $ret->{solution}
	}

	$ret
}

sub contest_list { _add_names _query('contest_list_sth')->hashes }

sub contest_entry { _add_names _query(contest_entry_sth => $_[0])->hash }

sub contest_has_problem { _query('contest_has_problem_sth', @_[0, 1])->flat }

sub job_list {
	my (%args) = @_;
	$args{page} = int ($args{page} // 1);
	my %where = (
		maybe contest => $args{contest},
		maybe owner => $args{owner},
		maybe problem => $args{problem},
		maybe result => $args{result},
	);
	$where{private} = 0 unless $args{private};

	my $rows = $db->select('job_entry', 'COUNT(*)', \%where)->list;
	my $pages = int (($rows + JOBS_PER_PAGE - 1) / JOBS_PER_PAGE);
	my ($stmt, @bind) = $db->abstract->select('job_entry', '*', \%where, {-desc => 'id'});
	my $jobs = _add_names $db->query("$stmt LIMIT " . JOBS_PER_PAGE . ' OFFSET ' . ($args{page} - 1) * JOBS_PER_PAGE, @bind)->hashes;
	my $pageinfo = {
		current_page => $args{page},
		last_page    => $pages,
		($args{page} - 1) ? (previous_page => $args{page} - 1) : (),
		($args{page} < $pages) ? (next_page => $args{page} + 1) : (),
	};
	wantarray ? ($jobs, $pageinfo) : $jobs;
}

sub job_entry {
	my $ret = _add_names _query(job_entry_sth => $_[0])->hash;
	$ret->{results} = decode_json $ret->{results} if $ret->{results};
	$ret
}

sub create_job {
	my (%args) = @_;
	$db->update('users', {lastjob => time}, {id => $args{owner}});
	purge '/log/';
	scalar $db->insert('jobs', \%args, {returning => 'id'})->list
}

sub _calc_score {
	my ($mxscore, $time, $tries, $totaltime) = @_;
	my $score = $mxscore;
	$time = 300 if $time > $totaltime; # uncoverable branch true does not happen anymore (only possible if opens are broken)
	$score = ($totaltime - $time) / $totaltime * $score;
	$score -= $tries / 10 * $mxscore;
	$score = $mxscore * 3 / 10 if $score < $mxscore * 3 / 10;
	int $score + 0.5
}

sub standings {
	my ($ct) = @_;
	my @problems = sort { $a->{value} <=> $b->{value} } @{problem_list contest => $ct};
	my %values = map { $_->{id} => $_->{value} } @problems;
	$ct = contest_entry $ct;

	my (%scores, %tries, %opens);
	my $opens = _query(opens_sth => $ct->{id});
	while ($opens->into(my ($problem, $owner, $time))) {
		$opens{$problem, $owner} = $time;
	}

	# result IS NULL if job was never run
	# result = -2 if job is being rerun
	my %where = (contest => $ct->{id}, result => {'>=', 0});
	my $jobs = $db->select('job_entry', '*', \%where, 'id');

	while (my $job = $jobs->hash) {
		my $open = $opens{$job->{problem}, $job->{owner}} // $ct->{start};
		my $time = $job->{date} - $open;
		next if $time < 0; # uncoverable branch true job sent before contest is deprecated
		my $value = $values{$job->{problem}};
		my $factor = $job->{result} ? 0 : 1;
		$factor = $1 / 100 if $job->{result_text} =~ /^(\d+ )/s;
		$scores{$job->{owner}}{$job->{problem}} = int ($factor * _calc_score ($value, $time, $tries{$job->{owner}}{$job->{problem}}++, $ct->{stop} - $ct->{start}));
	}

	my @st = sort { $b->{score} <=> $a->{score} or $a->{user} cmp $b->{user} } map { ## no critic (ProhibitReverseSortBlock)
		my $user = $_;
		+{
			user => $user,
			user_name => _object_name(users => $user),
			score => sum (values %{$scores{$user}}),
			scores => [map { $scores{$user}{$_->{id}} // '-'} @problems],
		}
	} keys %scores;

	$st[0]->{rank} = 1 if @st;
	$st[$_]->{rank} = $st[$_ - 1]->{rank} + ($st[$_]->{score} < $st[$_ - 1]->{score}) for 1 .. $#st;

	\@st
}

sub update_status {
	my $jobs = $db->select('jobs', 'id,owner,problem,result', {-not_bool => 'private'}, 'id');

	my %hash;
	while ($jobs->into(my ($id, $owner, $problem, $result))) {
		$hash{$problem, $owner} = [$id, $result ? 0 : 1];
	}

	my @problem_statuses = map { [split ($;), @{$hash{$_}} ] } keys %hash;

	my @contest_statuses = map {
		my $ct = $_;
		map { [$ct, $_->{user}, $_->{score}, $_->{rank}] } @{standings $ct}
	} $db->select('contests', 'id')->flat;

	$db->begin;
	$db->delete('problem_status');
	$db->query('INSERT INTO problem_status (problem,owner,job,solved) VALUES (??)', @$_) for @problem_statuses;
	$db->delete('contest_status');
	$db->query('INSERT INTO contest_status (contest,owner,score,rank) VALUES (??)', @$_) for @contest_statuses;
	$db->commit
}

sub rerun_problem {
	my ($problem) = @_;
	_query rerun_problem_sth => $problem;
	purge '/log/';
}

sub rerun_job {
	my ($id) = @_;
	_query rerun_job_sth => $id;
	purge '/log/';
	purge "/log/$id";
}

sub take_job {
	my ($daemon) = @_;
	my $id = _query(take_job_sth => $daemon)->list;
	return unless $id;
	purge '/log/';
	purge "/log/$id";
	db->select(jobs => '*', {id => $id})->hash
}

sub finish_job {
	my ($job, $private, %args) = @_;
	db->update(jobs => \%args, {id => $job->{id}});
	purge '/log/';
	purge '/log/' . $job->{id};
	purge '/st/' . $job->{contest} if $job->{contest};
	return if $private;
	my $status = {
		problem => $job->{problem},
		owner   => $job->{owner},
		job     => $job->{id},
		solved  => ($args{result} ? 0 : 1),
	};
	eval {
		db->insert(problem_status => $status)
	} or db->update(problem_status => $status, {owner => $job->{owner}, problem => $job->{problem}});
	purge '/us/' . $job->{owner};
}

sub open_problem {
	my ($contest, $problem, $owner, $time) = @_;
	my $ct = contest_entry($contest);
	return unless $ct->{id} && $time >= $ct->{start} && $time < $ct->{stop}; ## no critic (ProhibitNegativeExpressionsInUnlessAndUntilConditions)
	eval { db->insert(opens => { ## no critic (RequireCheckingReturnValueOfEval)
		contest => $contest,
		problem => $problem,
		owner => $owner,
		time => $time}) };
}

my @PURGE_HOSTS = exists $ENV{PURGE_HOSTS} ? split ' ', $ENV{PURGE_HOSTS} : ();
my $ht = HTTP::Tiny->new;

sub purge {
	$ht->request(PURGE => "http://$_$_[0]") for @PURGE_HOSTS;
}

1;

__END__

=encoding utf-8

=head1 NAME

Gruntmaster::Data - Gruntmaster 6000 Online Judge -- database interface and tools

=head1 SYNOPSIS


=head1 DESCRIPTION

Gruntmaster::Data is the interface to the Gruntmaster 6000 database.

All functions are exported by default.

=over

=item B<dbinit>(I<@args>)

This function connects to the database. I<@args> are the arguments
passed to the L<DBIx::Simple> constructor.

=item B<purge>(I<$url_path>)

Purges a relative URL from the Varnish Cache by sending PURGE
$url_path requests to all hosts in the PURGE_HOSTS environment
variable.

=item B<db>

Returns a L<DBIx::Simple> object for interacting with the database
directly. Use this when no other function in this module is suitable.

=item B<user_list>

Returns an arrayref of the top 200 users.

=item B<user_entry>(I<$id>)

Returns a hashref describing the user I<$id>.

=item B<problem_list>([I<%args>])

Returns an arrayref of problems.

Takes the following named arguments:

=over

=item owner

Only show problems owned by this user

=item contest

Only show problems in this contest

=item private

If true, include private problems. Always true if contest is present.

=item solution

If true, include problem solutions

=back

=item B<problem_entry>(i<$id>, [I<$contest>])

Returns a hashref describing the problem I<$id>. If $contest is
present, contest start and stop times are included, and the solution
is deleted.

=item B<contest_list>

Returns an arrayref of contests.

=item B<contest_entry>(I<$id>)

Returns a hashref describing the contest I<$id>.

=item B<contest_has_problem>(I<$contest>, I<$problem>)

Returns true if the contest I<$contest> includes the problem
I<$problem>, false otherwise.

=item B<job_list>([I<%args>])

In scalar context, returns an arrayref of jobs. In list context,
returns an arrayref of jobs and a hashref of information about pages.

Takes the following named arguments:

=over

=item page

Show this page of the job log. Defaults to 1.

=item owner

Only show jobs submitted by this user.

=item contest

Only show jobs submitted in this contest.

=item problem

Only show jobs submitted for this problem.

=item result

Only show jobs with this result (see the constants in
L<Gruntmaster::Daemon::Constants>).

=item private

If true, include private jobs. Defaults to false.

=back

=item B<job_entry>(I<$id>)

Returns a hashref describing the job I<$id>.

=item B<create_job>(I<%args>)

Insert a new job into the database. This function also updates the
lastjob field for the job's owner.

=item B<standings>(I<$ct>)

Returns an arrayref of the standings of contest I<$ct>.

=item B<update_status>

Rebuilds the problem_status and contest_status tables.

=item B<rerun_job>(I<$id>)

Marks the job $id as pending and clears its results, so that it will
be run again by the daemon.

=item B<take_job>(I<$daemon>)

Marks a random job as being run by I<$daemon>. Returns a hashref
describing the job, or undef if no job was available.

=item B<finish_job>(I<$job>, I<$private>, I<%results>)

Updates the job $job with the results in %results. If $private is
false, also updates the problem_status table.

=item B<open_problem>(I<$contest>, I<$problem>, I<$owner>, I<$time>)

Notes that I<$owner> has opened the problem I<$problem> of contest
I<$contest> at time I<$time>. If the C<opens> table already contains
this (I<$contest>, I<$problem>, I<$owner>) triplet, this function does
nothing.

=back

=head1 AUTHOR

Marius Gavrilescu E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2016 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
