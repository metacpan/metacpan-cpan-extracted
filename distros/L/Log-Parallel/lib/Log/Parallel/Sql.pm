
package Log::Parallel::Sql;

use strict;
use warnings;
use Tie::Function::Examples qw(%q_perl);
use Config::Checker;
use Stream::Aggregate::Random;
use Log::Parallel::Sql::Numbers;
require Exporter;
use DBI;

our @ISA = qw(Exporter);
our @EXPORT = qw(db_insert_func);

my $prototype_config = <<'END_PROTOTYPE';
dsn:                    'perl DBI DSN string[WORD]'
user:                   '?database user name[WORD]'
pass:                   '?database password[WORD]'
debug:                  '?<0>debug level[INTEGER]'
queries:                '+Database insert commands[STRING]'
initialize:             '*Database setup commands[STRING]'
commit_every:           '?<1000>commit changes to the database after this # of records[INTEGER]'
END_PROTOTYPE

sub db_insert_func
{
	my ($config, $job, $timeinfo, $mode) = @_;

	my $checker = eval config_checker_source;
	die $@ if $@;
	$checker->($config, $prototype_config, '- Log::Parallel::Sql config');

	die "must set mode, 'test' or 'real'" unless $mode eq 'test' || $mode eq 'real';

	my $debug = $config->{debug};

	print "connecting to $config->{dsn}...\n" if $debug;

	my $dbh = DBI->connect(
			$config->{dsn}, 
			$config->{user}, 
			$config->{pass},
			{
				PrintError	=> 1,
				RaiseError	=> 1,
				AutoCommit	=> 0,
			}
		) or die "DBI connect $config->{dsn}, user=$config->{user}, pass=$config->{pass} for $job->{name}: $DBI::error";

	print "connected to $config->{dsn}...\n" if $debug;

	$dbh->do("SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE");
	$dbh->do("SET sql_mode='ansi,strict_trans_tables'");
	$dbh->do("SET character_set_server='utf8'");
	$dbh->do("SET names 'latin1'");


	print "isolation level set...\n" if $debug > 1;

	my $log;
	my @seq;
	my @subs;
	my $subnum = -1;
	my %subindex;
	my $pending;
	my $commit_every = $config->{commit_every};
	my $retries = $config->{max_retries} || 50;
	my %last_id;

	my $compile_query = sub {
		my ($q) = @_;
		print "compile $q\n" if $debug > 9;
		my $final = '';
		my $subs = '';
		$q =~ s{(?:\$log->\{(\w+)\}|<<<(.*?)>>>|\$last_id\{(\w+)\}|LASTID\((\w+),(\w+)\))}{
			do {
				if (defined $1) {
					$final .= qq{\$log->{$q_perl{$1}}, };
				} elsif (defined $2) {
					if ($subindex{$2}) {
						$subnum = $subindex{$2};
					} else {
						$subnum++;
						$subs .= qq{\$subs[$subnum] = sub { $2 };\n};
					}
					$final .= "\$subs[$subnum]->(), ";
				} elsif (defined $3) {
					$final .= qq{\$last_id{$q_perl{$3}}};
				} else {
					$final .= "(\$last_id{$q_perl{$4}} = \$dbh->last_insert_id(undef, undef, $q_perl{$4}, $q_perl{$5})), ";
				}
				'?';
			}
			}ges;
		print STDERR "SUBS: $subs\nDATA: $final\nQ: $q\n" if $config->{debug};
		eval $subs;
		die "eval '$subs' for $q: $@" if $@;
		my $datafunc;
		eval "\$datafunc = sub { ($final) };";
		die "eval '$final' for $q: $@" if $@;
		print "preparing $q\n" if $debug > 1;
		my $stmt = $dbh->prepare($q);
		return ($stmt, $datafunc, $q);
	};

	my $display_interpolated = sub {
		my ($q, @data) = @_;
		$q =~ s/[?]/"'" . shift(@data) . "'"/ges;
		return $q;
	};

	my $compile_compound = sub {
		my ($q) = @_;
		print "compile compound $q\n" if $debug > 10;
		if ($q =~ /(.*?)(SKIP|DO)-CONDITION:(.*)/s) {
			my ($action, $ctype, $condition) = ($1, $2, $3);
			print "action: $action\nctype: $ctype\ncondition: $condition\n" if $debug > 18;

			my ($stmt, $data, $query) = $compile_query->($action);
			my ($cs, $cd, $cq) = $compile_query->($condition);

			my $do = sub {
				if ($debug > 4) {
					my @d = $cd->();
					print $display_interpolated->("TEST: $cq\n", @d) if $debug > 6;
					print "TEST @d\n" if $debug == 5;
				}
				$cs->execute($cd->());
				my (@test_data) = $cs->fetchrow_array();
				my $doit = $ctype eq 'DO'
					? !! $test_data[0]
					: ! $test_data[0];
				if ($debug) {
					print "got @test_data\n" if $debug > 5;
					print "doit='$doit'\n" if $debug > 4;
					if ($doit && $debug > 2) {
						my @d = $data->();
						print $display_interpolated->("WILL NOW DO: $query\n", @d) if $debug > 4;
						print "INSERT @d\n" if $debug <= 4;
					}
				}
				$stmt->execute($data->())
					if $doit;
				print "insert complete\n" if $debug > 8;
			};
			return ($stmt, $data, $query, $do);
		} else {
			my ($stmt, $data, $query) = $compile_query->($q);
			my $do = sub {
				if ($debug > 2) {
					my @d = $data->();
					print $display_interpolated->("DO: $query\n", @d) if $debug > 4;
					print "INSERT @d\n" if $debug <= 4;
				}
				$stmt->execute($data->());
				print "insert complete\n" if $debug > 8;
			};
			return ($stmt, $data, $query, $do);
		}
	};

	my $tried = 0;
	my $attempted;

	my @do;
	my @data;
	my @stmts;
	my @queries;

	for(;;) {
		undef @stmts;
		undef @data;
		undef @queries;
		undef @do;
		eval {
			for my $init (@{$config->{initialize}}) {
				my ($stmt, $func, $q) = $compile_query->($init);
				$attempted = "init $init";
				print "running init: $q\n" if $debug;
				$stmt->execute($func->())
					unless $mode eq 'test';
			}

			for my $q (@{$config->{queries}}) {
				$attempted = "compile $q";
				my ($stmt, $func, $q, $do) = $compile_compound->($q);
				push(@stmts, $stmt);
				push(@data, $func);
				push(@queries, $q);
				push(@do, $do);
			};
		};
		if ($@ && $@ =~ /try restarting transaction/ && $tried++ < $retries) {
			eval { $dbh->rollback };
			print STDERR "Retrying $tried $attempted: $@\n";
			undef @stmts;
			undef @data;
			undef @do;
			undef @queries;
			sleep(rand(5));
			redo;
		} elsif ($@) {
			die "Already tried $tried $attempted, giving up: $@";
		} else {
			last;
		}
	}

	my $count = 0;
	$tried = 0;
	my @pending;

	return sub { die } if $mode eq 'test';

	return sub {
		$log = shift;
		my $attempt;
		eval {
			if ($log) {
				push(@pending, $log);
				for my $i (0..$#stmts) {
					$attempt = $i;
					$do[$i]->();
				}
				$count++;
				if ($count % $commit_every == 0) {
					$attempt = -1;
					$dbh->commit();
					undef @pending;
				}
			} else {
				if (@pending) {
					$attempt = -1;
					$dbh->commit();
					undef @pending;
				}
			}
		};
		if ($@) {
			my $q;
			if ($attempt == -1) {
				$q = "commit";
			} else {
				$q = $queries[$attempt];
			}
			if ($@ =~ /try restarting transaction/ && $retries > 1) {
				my $final = $log;
				print STDERR "Retrying $tried $attempt: $@\n";
				my $olog = $log;
				for(;;) {
					eval {
						for $log (@pending) {
							for my $i (0..$#stmts) {
								$do[$i]->();
								$dbh->commit();
							}
						}
					};
					if ($@ && $@ =~ /try restarting transaction/ && $tried++ < $retries) {
						print STDERR "Retrying $tried $attempt: $@\n";
						eval { $dbh->rollback };
						sleep(rand(5));
						redo;
					} elsif ($@) {
						die "After $tried attempt on $attempt, giving up: $@";
					} else {
						$tried = 0;
						last;
					}
				}
				$log = $olog;
			} else {
				my @d;
				@d = $data[$attempt]->()
					if defined($attempt) && $attempt >= 0;
				die $display_interpolated->("GIVING UP!\n$q\nfailed $tried times: ", @d).$@;
			} 
		}
		return () if $log;
		return { db_insert_count => $count };
	};
}

1;

__END__

=head1 NAME

 Log::Parallel::Sql - insert a stream of data into an SQL database

=head1 SYNOPSIS

 use Log::Parallel::Sql;

 my $dbf = db_insert_func($db_config, $job, $timeinfo, $mode);

 while ($log = ???) {
	$dbf->($log);
 }
 my $rows = $dbf->(undef);

=head1 DESCRIPTION

Log::Parallel::Sql is a somewhat general-purpose database insert module.  It knows to retry
certain types of transactions.  It can perform initialization.  It can run more than one SQL
statement per input record.  It can execute SQL conditionally based on the results of other
SQL statements.

It is not tied to the rest of L<Log::Parallel>.

=head2 API

The configuration for Log::Parallel::Sql is compiled into a perl function which is
then called once for each input object.  
When there is no more input data, call the function with C<undef>.  

The generate-the-fucntion routine, C<db_insert_func> takes four parameters.  The
first is the configuration object (defined below) that is expected (but not required) to come
from a YAML file.   The second and third provide extra information.  The forth parameter,
C<$mode> is set to C<testing> when the code is just being compiled to check the configuration
file.   

The configuration object is a set of key/value pairs.   The following keys are general parameters:

=over 

=item dsn

This is the L<DBI> DSN needed to connect to the database.

=item user

This is the username parameter for conncting to the database.

=item pass

This is the password parameter for conncting to the database.

This sets the debug level for Log::Parallel::Sql.   

=item commit_every

This sets the frequency of calling C<commit>.   When a deadlock occurs, the data will be
re-processed, committing for each record until that batch of data is done.

=item debug

=back

Additionally, there are two parameters that are either a single query or a list of queries: 
C<initialize> and C<queries>.   The C<initialize> SQL statements are run once per invocation
of Log::Parallel::Sql.  There is no current method to automatically install/update the
database schemea.

If C<initialize> or C<queries> is an array, then the queries will be run in-order.

The statements defined in C<initialize> and C<queries> will have the following strings
interpolated into them:

=over

=item $log-E<gt>{KEY_NAME}

This is the easy way to grab data from your input records.

=item E<lt>E<lt>E<lt> PERL CODE E<gt>E<gt>E<gt>

When you need something a little more complicated, you can embed
arbitrary perl code.   The perl code will be compiled as a function
so you can C<return> the value you want interpolated.

=item LASTID(TABLE,COLUMN)

When you need to need the last ID assigned on an insert.

=back

The queries can be run conditionally.  If the string C<SKIP-CONDITION:> or 
C<DO-CONDITION:> occurs in the query, then the SQL following the condition
marker will be run first as a query.  If the return value from that query 
is a perl true value, then the SQL before the condition marker will be run
(assuming C<DO-CONDITION>, the resverse is true for C<SKIP-CONDITION>).

=head1 LICENSE

This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

