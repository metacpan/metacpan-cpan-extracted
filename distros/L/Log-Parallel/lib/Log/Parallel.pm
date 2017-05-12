
package Log::Parallel;

use strict;
use warnings;
use File::Glob ':glob';
use File::Slurp;
use List::Util qw(min max sum);
use List::MoreUtils qw(uniq);
use Time::ParseDate;
use File::Flock;
use Time::JulianDay;
use Config::YAMLMacros::YAML;
use File::Path;
use File::Basename;
use Log::Parallel::Misc qw(jd_data);
use List::EvenMoreUtils qw(do_sublist);
use Log::Parallel::Paths;
use Log::Parallel::Metadata;
use Log::Parallel::Durations;
use File::Slurp::Remote::BrokenDNS qw($myfqdn %fqdnify);
use Tie::Function::Examples qw(%q_shell);
use Eval::LineNumbers qw(eval_line_numbers);
use List::EvenMoreUtils qw(initial_sublist_match longer_list);
use Log::Parallel::Task;
use File::Slurp::Remote;
use Data::Compare qw(Compare);
use Object::Dependency;
use Proc::JobQueue::DependencyJob;
use Proc::JobQueue::DependencyTask;
use RPC::ToWorker qw(do_remote_job);
use Digest::MD5 qw(md5_hex);
use Callback;
require YAML;

our $VERSION = 0.303;

our @ISA = qw(Exporter);
our @EXPORT = qw(make_task_list do_task_local get_files_by_srec add_recnums make_dependency_graph setup_slave_hosts);
our @EXPORT_OK = (@EXPORT, qw(make_srecs make_object_selector precalculate_prerequisites jd_minmax unify_fields));

our $prequel;

my $default_priority = 10000;
our $timer_interval = 7;

my @suppress_from_meta = qw(srec output_colums hosts valid_from valid_to path);

tie my %time2jd, 'Tie::Function::Examples',
	sub {
		my ($time) = @_;
		return undef unless $time;
		return local_julian_day($time);
	};

my %checksum_cache;


use Getopt::Long;
use Config::YAMLMacros qw(get_config listify);
use Log::Parallel::ConfigCheck;
use File::Slurp::Remote::BrokenDNS qw($myfqdn %fqdnify);
use YAML::Syck qw(Dump Load);
use Log::Parallel::Paths;
use Log::Parallel::Task;
use Proc::JobQueue::DependencyQueue;
use Log::Parallel::Misc qw(monitor_free_space);
use IO::Event qw(emulate_Event);

sub options
{

	my %opts;
	exit unless GetOptions(
		'config_file|config-file|c=s'		=> \$opts{config_file},
#			'recheck|verify|r'			=> \$opts{recheck},
		'reprocess_all|reprocess-all|all|a'	=> \$opts{reprocess},
		'reprocess_from|reprorces-from|from=s'	=> \$opts{from},
		'verbose|v+'				=> \$opts{verbose},
		'min_start_date=s'			=> \$opts{min_start_date},
		'max_end_date=s'			=> \$opts{max_end_date},
		'priority_bias|priority-bias|bias=s'	=> \$opts{priority_bias},
		'target_date=s'				=> \$opts{target_date},
		'ignore_code_dependencies|no_code'	=> \$opts{ignore_code_dependencies},
	);
	$opts{from} = local_julian_day(parsedate($opts{from}, WHOLE => 1, PREFER_PAST => 1))
		if $opts{from};
	die "configuration file required" unless $opts{config_file};
	my $bias = $opts{priority_bias} ||= ($opts{target_date} ? 'date' : 'random');
	if ($bias eq 'random') {
		# good;
	} elsif ($bias eq 'date') {
		# good;
	} elsif ($bias eq 'depth') {
		# good;
	} else {
		die "bias values can be 'random', 'date', or 'depth'";
	}
	run(\%opts);
}

sub run
{
	my ($opts) = @_;
	my $config = get_config($opts->{config_file});

	$opts->{verbose} ||= 0;

	validate_config($config);

	die "$0 must be run on $config->{master_node} ($myfqdn ne $fqdnify{$config->{master_node}})"
		unless $myfqdn eq $fqdnify{$config->{master_node}};

	add_recnums($config);

	my %files_by_recnum;
	for my $source (@{$config->{sources}}) {
		$files_by_recnum{$source->{recnum}} = get_files_by_srec($source, $config->{hostsinfo});
	}

	my @tasks = make_task_list($opts, $config, %files_by_recnum);

	my $dependency_graph = make_dependency_graph(@tasks);

	my $job_queue = new Proc::JobQueue::DependencyQueue(dependency_graph => $dependency_graph, hosts => [], hold_all => 1);

	extra_slave_setup($config, $job_queue);
	setup_slave_hosts($config, $job_queue);

	$job_queue->hold(0);

	local $SIG{PIPE} = 'IGNORE';

	$job_queue->startmore();

	if ($job_queue->alldone && $dependency_graph->alldone) {
		print STDERR "Nothing needs to be done.\n";
		return;
	}

	my $timer = IO::Event->timer(
		interval	=> $timer_interval,
		cb		=> sub {
			my $free = monitor_free_space(2100100);
			print "Free space is $free\n";
		},
	);

	IO::Event::loop;
}



sub extra_slave_setup {};

#
# Tell the Proc::JobQueue about the hosts described in the configuration
#

sub setup_slave_hosts
{
	my ($config, $job_queue) = @_;

	my $hi = $config->{hostsinfo};

	for my $host (keys %$hi) {
		$job_queue->addhost($host, jobs_per_host => $hi->{$host}{max_threads});
	}
}

sub combine_arrays
{
	return (@_) unless @_ > 1;
	return [ map { @$_ } @_ ];
}

#
# The inputs for each job are the sources.  Since inputs can either be
# original data files or the outputs of other jobs, they are unified into
# source record (srec).  This function creates a hash that maps source
# names to lists of srec's (each source can end up with multiple records)
#

sub make_srecs
{
	my ($config) = @_;

	#
	# Names are not unique.  A name and a time together must be unique.
	#
	my %source2sreclist;
	my $register_srec = sub {
		my ($srec) = @_;
		$source2sreclist{$srec->{name}} = []
			unless $source2sreclist{$srec->{name}};
		push(@{$source2sreclist{$srec->{name}}}, $srec);
		$srec->{use} = [] unless $srec->{use};  # why was this needed?
		die "use isn't an array" unless ref($srec->{use}) eq 'ARRAY';
		return $srec;
	};

	for my $source (@{$config->{sources}}) {
		$register_srec->({
			name		=> $source->{name},
			hosts		=> $source->{hosts},
			path		=> $source->{path},
			format		=> $source->{format},
			valid_from	=> $source->{valid_from},
			valid_to	=> $source->{valid_to},
			parser_config   => $source->{parser_config} || {},
			recnum		=> $source->{recnum},
			use		=> $source->{use},
			frequency	=> $source->{frequency} || 'daily',
		});
	}
	for my $job (@{$config->{jobs}}) {
		next if $job->{DISABLED};
		print "$job->{name} is enabled\n" if $job->{debug};
		$job->{input_config} ||= {};
		$job->{output_config} ||= {};
		$job->{just_depend} = { map { $_ => 1 } @{$job->{dependency}} };
		$job->{srec} = $register_srec->({
			name		=> $job->{destination},
			hosts		=> $job->{hosts},
			path		=> $job->{path},
			format		=> $job->{output_format},
			valid_from	=> $job->{valid_from},
			valid_to	=> $job->{valid_to},
			jobname		=> $job->{name},
			prereq		=> combine_arrays($job->{source}, $job->{dependency}),
			parser_config   => $job->{parser_config} || {},
			recnum		=> $job->{recnum},
			use		=> [],
			frequency	=> $job->{frequency},
			timespan	=> $job->{timespan},
		});
	}

	return \%source2sreclist;
}

sub precalculate_prerequisites
{
	my ($config, $source2sreclist) = @_;

	my $get_prerequisites;
	$get_prerequisites = sub {
		my ($srec, $inter_compare, $intra_compare) = @_;
		return $srec unless $srec->{prereq};
		my @inter;
		for my $srecname (@{$srec->{prereq}}) {
			my (@intra) = 
				map { $get_prerequisites->($_, $inter_compare, $intra_compare) } 
				map { @$_ }
				map { $source2sreclist->{$_} }
				$srecname;
			push(@inter, $intra_compare->(@intra));
		}
		return $inter_compare->(@inter, $srec);
	};
	return $get_prerequisites;
}

sub make_object_selector
{
	my ($field, $func) = @_;
	return sub {
		my (@objs) = @_;
		my %val2obj = map { $_->{$field} => $_ } grep { defined $_->{$field} } @objs;
		my $val = $func->(keys %val2obj);
		return $val2obj{$val};
	};
}

sub jd_minmax 
{
	my ($get_prerequisites, $srec, $field, $default, $inter, $intra) = @_;

	my $p_inter = make_object_selector($field, $inter);
	my $p_intra = make_object_selector($field, $intra);

	my $t_srec = $get_prerequisites->($srec, $p_inter, $p_intra);

	my $t = $default;
	$t = $t_srec->{$field}
		if $t_srec->{$field} && $t_srec;

	$t = $inter->($t, $srec->{$field}) 
		if $srec->{$field};

	my $jd = local_julian_day($t);
	return $jd;
};

sub make_task_list
{
	my ($opts, $config, %files_by_recnum) = @_;

	my @tasklist;

	my $hostsinfo = $config->{hostsinfo};

	my $source2sreclist = make_srecs($config);

	my $get_prerequisites = precalculate_prerequisites($config, $source2sreclist);

	my %files_by_jd_by_srec;

	my $jd_from_override;
	my $jd_to_override;
	if ($opts->{min_start_date}) {
		my $t = parsedate($opts->{min_start_date});
		$jd_from_override = gm_julian_day($t);
	}
	if ($opts->{max_end_date}) {
		my $t = parsedate($opts->{max_end_date});
		$jd_to_override = gm_julian_day($t);
	}

	my $made_progress = 1;
	while ($made_progress) {
		$made_progress = 0;
		for my $job (@{$config->{jobs}}) {
			next if $job->{DISABLED};
			for my $field (qw(timespan frequency)) {
				next if defined $job->{$field};
				# print "JOB $job->{name} does hnave a $field...\n";
				my @sreclists = map { $source2sreclist->{$_} || die "no srecs for '$_'" } @{$job->{source}};
				my %found;
				for my $srec (map { @$_ } @sreclists) {
					next unless $srec->{$field};
					$found{$srec->{$field}}++;
				}
				if (keys %found == 1) {
					($job->{$field}) = keys %found;
					$job->{srec}{$field} = $job->{$field};
					# print "\tNOW IT IS $job->{$field}\n";
					$made_progress++;
				}
			}
		}
	}

	for my $job (@{$config->{jobs}}) {
		next if $job->{DISABLED};
		next if $job->{DISABLED};
		$job->{priority} ||= $default_priority;
		$job->{use} = [] unless $job->{use};
		$job->{output_columns} = [] unless $job->{output_columns};
		my @sreclists = map { $source2sreclist->{$_} || die "no srecs for '$_'" } @{$job->{source}};

		#
		# First we figure out the date range this job is valid for.
		#

		my $jd_from = $time2jd{$job->{valid_from} || 0} 
			|| jd_minmax($get_prerequisites, $job->{srec}, 'valid_from', scalar(parsedate('2008-03-01')), \&max, \&min);
		my $jd_to = $time2jd{$job->{valid_to} || 0}
			|| jd_minmax($get_prerequisites, $job->{srec}, 'valid_to', $job->{valid_to} || time, \&min, \&max);

		$jd_from = $jd_from_override
			if $jd_from_override && $jd_from_override > $jd_from;
		$jd_to = $jd_to_override
			if $jd_to_override && $jd_to_override < $jd_to;

		printf "possible range for %s: %d-%d-%d to %d-%d-%d\n", $job->{name}, inverse_julian_day($jd_from), inverse_julian_day($jd_to) if ($opts->{verbose} >= 4 || $job->{debug});

		if ($jd_from > $jd_to) {
			print "range for $job->{name} does not include any days\n";
			next;
		}

		for my $srec (map { @$_ } @sreclists) {
			#
			# We assume all original sources are daily 
			#
			next if $srec->{jobname};
			my $files_by_jd = $files_by_recnum{$srec->{recnum}};

			for my $jd (keys %$files_by_jd) {
				$files_by_jd_by_srec{$jd}{$srec->{name}} = $files_by_jd->{$jd};
				my %jddata = jd_data($jd);
				$srec->{valid_days}{$jd} = {
					%jddata,
					DURATION	=> 'daily',
					(map { "FROM_" . $_ => $jddata{$_} } keys %jddata),
				};
			}
		}

		if (! $job->{hosts}) {
			my @hostlists;
			for my $srec (map { @$_ } @sreclists) {
				next unless $srec->{jobname};
				next unless $srec->{hosts};
				push(@hostlists, join(',', sort @{$srec->{hosts}}));
			}
			@hostlists = uniq(@hostlists);
			die "Cannot determine host lists for $job->{name}: choices: @hostlists"
				unless @hostlists == 1;
			$job->{hosts} = [ split(',', $hostlists[0]) ];
			$job->{srec}->{hosts} = $job->{hosts};
		}

		if (! $job->{buckets}) {
			$job->{buckets} = scalar(@{$job->{hosts}}) || 1;
		}


		for my $h (@{$job->{hosts}}) {
			next if $hostsinfo->{$h};
			die "Host $h for job $job->{name} isn't defined";
		}

		printf "No days in the possible range for %s: %d-%d-%d to %d-%d-%d\n", $job->{name}, inverse_julian_day($jd_from), inverse_julian_day($jd_to)
			if ($opts->{verbose} >= 2 || $job->{debug}) && $jd_from > $jd_to;

		#
		# Now, for each day in the date range, we run the jobs.
		#
		my @parsers;
		for my $jd ($jd_from .. $jd_to) {
			my ($timeinfo, @range) = frequency_and_span($job, $jd, $jd_from, $jd_to);
#print "=========================================================================================<===\n";
#use Data::Dumper;
#print Dumper($timeinfo, \@range, $job, $jd, $jd_from, $jd_to);
#print "=========================================================================================>===\n";
			if (@range) {
				print "adding task for $job->{name} for $timeinfo->{YYYY}/$timeinfo->{MM}/$timeinfo->{DD}\n" if $job->{debug} || $opts->{verbose} > 4;
				$job->{srec}{valid_days}{$jd} = $timeinfo;
				$job->{srec}{valid_to} = jd_secondslocal($range[-1]);
				push(@tasklist, [ $opts, $config, $job, $timeinfo, \@range, \@sreclists, 
					{ map { $_ => $files_by_jd_by_srec{$_} } @range } ]);
			} else {
				print "No valid days for $job->{name}\n" if $opts->{verbose} >= 3 || $job->{debug};
				$job->{srec}{valid_to} = 1; # time_t
			}
		}
		$job->{inc} = {};


		for my $sreclist (@sreclists) {
			die "sreclist isn't a list" unless ref($sreclist) eq 'ARRAY';
			for my $srec (@$sreclist) {
				die "srec isn't a hash" unless ref($srec) eq 'HASH';
				die "srec is missing a use list" unless $srec->{use};
				die "use list ins't a list" unless ref($srec->{use}) eq 'ARRAY';
			}
		}
		die "no job use" unless $job->{use};
		die "job use ins't an array" unless ref($job->{use}) eq 'ARRAY';

		for my $inc (@{$job->{use}}, map { @{$_->{use}} } map { @$_ } @sreclists ) {
			my $use = $inc;
			$inc =~ s{::}{/}g;
			$inc .= ".pm" unless $inc =~ /\.pm$/;
			$job->{inc}{$use} = $checksum_cache{$inc} ||
				($checksum_cache{$inc} = md5_hex(scalar(read_file($INC{$inc}))));
		}
	}
	return @tasklist;
}

sub make_dependency_graph
{
	my (@tasklist) = @_;

	my $dg = new Object::Dependency;

	my %jobs_by_jd_and_destination;

	my %dtask;

	my %depth_score;

	my $task;
	for $task (@tasklist) {
		my ($opts, $config, $job, $timeinfo, $range, $sreclists, $files_by_jd_by_srec) = @$task;
		my $jdesc = "$job->{name} for $timeinfo->{YYYY}-$timeinfo->{MM}-$timeinfo->{DD} for $timeinfo->{DURATION}";
		die "duplicate job for $job->{destination} at $timeinfo->{YYYY}-$timeinfo->{MM}-$timeinfo->{DD}"
			if $jobs_by_jd_and_destination{$timeinfo->{JD}}{$job->{destination}};
		my $efile = path_to_filename($config->{errors},
			%$timeinfo,
			JOBNAME => $job->{name},
		);
		mkpath(dirname($efile));
		my $efh;
		my $elines = 0;
		my $errors = sub {
			unless ($elines++) {
				open $efh, ">>", $efile or die "open >>$efile: $!";
				$efh->autoflush(1);
				seek($efh, 0, 0) or die "seek in $efile: $!";
				truncate($efh, 0) or die "truncate $efile: $!";
				print $efh "---\n";
			}
			print STDERR "$job->{name} @_";
			print $efh scalar(localtime(time)), ": ", @_;
		};
		$jobs_by_jd_and_destination{$timeinfo->{JD}}{$job->{destination}} 
			= $dtask{$task} 
			= Proc::JobQueue::DependencyTask->new(
				desc			=> $jdesc,
				func			=> \&do_task_local,
				args			=> $task,
				errors			=> $errors,
				_elines			=> \$elines,
				_depth_score_ref	=> \$depth_score{$task},
			);
		$dg->add($dtask{$task});
		$errors->("Task $jdesc now in dependency graph\n") if $job->{debug};
		$depth_score{$dtask{$task}} = 1+rand(.1);
	}
	for $task (@tasklist) {
		my ($opts, $config, $job, $timeinfo, $range, $sreclists, $files_by_jd_by_srec) = @$task;
		for my $srec (map { @$_ } @$sreclists) {
			for my $jd (@$range) {
				next unless $srec->{jobname};
				next unless $srec->{valid_days}{$jd};
				my $depends_on = $jobs_by_jd_and_destination{$jd}{$srec->{name}};
				next unless $depends_on;
				$dg->add($dtask{$task}, $depends_on);
				$dtask{$task}->{errors}->("$job->{name} for $timeinfo->{YYYY}-$timeinfo->{MM}-$timeinfo->{DD} for $timeinfo->{DURATION} now depends on $depends_on->{desc}\n") if $job->{debug};
				$depth_score{$task} = max($depth_score{$dtask{$task}} + rand(.1), $depth_score{$depends_on} + 1);
			}
		}
		$dtask{$task}->{errors}->($dg->desc($dtask{$task})) if $job->{debug};
	}
	return $dg unless wantarray;
	return ($dg, \%depth_score);
}

sub do_task_local
{
	my ($opts, $config, $job, $timeinfo, $range, $sreclists, $files_by_jd_by_srec, $dependency_task, $dependency_graph) = @_;

	my $hostsinfo = $config->{hostsinfo};

	my $jobsrec = $job->{srec};
	my $metafname = path_to_filename($config->{metadata}, 
		%$timeinfo,
		JOBNAME => $job->{name},
	);

	mkpath(dirname($metafname));
	lock($metafname);

	my $errors = $dependency_task->{errors};

	my $eq = 0;
	my $oldmeta;
	if (-s $metafname 
		&& ! $opts->{reprocess}
		&& ! ($opts->{from} && $timeinfo->{FROM_JD} < $opts->{from}))
	{
		delete $job->{srec};
		$oldmeta = LoadFile($metafname);
		my @suppressed = delete @$job{@suppress_from_meta};
		if ($opts->{ignore_code_dependencies}) {
			delete $oldmeta->{job}{inc};
			my $oi = delete $job->{inc};
			$eq = Compare($job, $oldmeta->{job});
			$job->{inc} = $oi;
		} else {
			$eq = Compare($job, $oldmeta->{job});
		}
		@$job{@suppress_from_meta} = @suppressed;
		$job->{srec} = $jobsrec;
	}

	my $most_recent_input = 0;
	
	#
	# Create an input file list
	#
	#	host
	#	filename
	#	format
	#	header
	#	sorted_by
	#	bucket
	#

	my %inputs;
	my $unique = 0;
	for my $srec (map { @$_ } @$sreclists) {
		for my $jd (@$range) {
			next unless $srec->{valid_days}{$jd};
			if ($srec->{jobname}) {
				my $mfname = path_to_filename( $config->{metadata},
					%$timeinfo,
					JOBNAME	=> $srec->{jobname},
					%{$srec->{valid_days}{$jd}},
				);
				unless (-s $mfname) {
					$errors->("Missing metadata file: $mfname -- skipping this input\n");
					next;
				}
				my $old_metadata = Load(scalar(read_file($mfname)));
				for my $filedata (@{$old_metadata->{FILES}}) {
					next unless $filedata->{items};
					push(@{$inputs{$filedata->{bucket}}}, {
						host		=> $filedata->{host},
						filename	=> $filedata->{filename},
						format		=> $filedata->{header}{format}, 
						header		=> $filedata->{header},
						sorted_by	=> $filedata->{header}{sort_by} || [ 'unsorted' ],
						sort_types	=> $filedata->{header}{sort_types} || {},
						bucket		=> $filedata->{bucket},
						parser_config	=> $srec->{parser_config},
						name		=> $srec->{name},
						selector	=> "u $unique",
						items		=> $filedata->{items},
					});
					$unique++;
					$most_recent_input = max((stat($mfname))[9], $most_recent_input);
				}
			} else {
				# raw sources don't have metadata
				my $files = $files_by_jd_by_srec->{$jd}{$srec->{name}} or die;
				for my $host (sort keys %$files) {
					for my $filename (sort keys %{$files->{$host}}) {
						my $r = $files->{$host}{$filename};
						my $span = 84600;
						my $time;
						if ($r->{YYYY}) {
							my $filejd = julian_day($r->{YYYY}, $r->{MM}||1, $r->{DD}||1);
							$time = jd_secondslocal($filejd);
							if (defined $r->{hour}) {
								$time += $r->{hour} * 3600;
								$span = 3600;
							}
						}
						$most_recent_input = max($r->{mtime}, $most_recent_input);
						push(@{$inputs{0}}, {
							host		=> $host,
							filename	=> $filename,
							format		=> $srec->{format},
							sorted_by	=> $srec->{sorted_by} || [ 'unsorted' ],
							sort_types	=> {},
							bucket		=> $unique,
							time		=> $time || $r->{mtime},
							span		=> $span,
							parser_config	=> $srec->{parser_config},
							name		=> $srec->{name},
							selector	=> $r->{SELECTOR} || "u $unique",
							items		=> 0,
						});
						$unique++;
					}
				}
			}
		}
	}

	my $jdesc = "$job->{name} for $timeinfo->{YYYY}-$timeinfo->{MM}-$timeinfo->{DD} for $timeinfo->{DURATION}";

	unless (keys %inputs) {
		$errors->("ERROR: NO INPUTS FOR $jdesc -- SKIPPING\n");
		write_file($metafname, "");
		unlock($metafname);
		$dependency_graph->remove_all_dependencies($dependency_task);
		return 'done';
	}

	if ($job->{input_config} && $job->{input_config}{ignore_sorting}) {
		# ignore the sort order of the inputs
	} else {
		my %found;
		for my $input (grep { ! $job->{just_depend}{$_->{name}} } map { @$_ } values %inputs) {
			my $sig = join("\t", @{$input->{sorted_by}}) . ";;;" . join("\t", %{$input->{sort_types}});
			next if $found{$sig};
			$found{$sig} = $input;
		}
		if (keys %found > 1) {
			my $e = "ERROR: INCONSISTENT SORT ORDER for inputs to $jdesc\n";
			for my $sig (keys %found) {
				$e .= "\t$found{$sig}{host}:$found{$sig}{filename} signature is\t'$sig'\n";
			}
			$errors->($e);
			die "problem with job '$job->{name}': sort order and type for all inputs must be identical for $jdesc";
		}
	}

	if ($eq) {
		if ($most_recent_input < (stat($metafname))[9]) {
			print "$metafname exists and $jdesc is already complete.\n" if $opts->{verbose} >= 1;
			unlock($metafname);
			return('done');
		} else {
			print "$jdesc hasn't changed but some of it's inputs have.\n" if $opts->{verbose};
		}
	} else {
		if ($oldmeta) {
			print "$jdesc has changed, must rerun\n" if $opts->{verbose};
		} else {
			print "$jdesc needs to be run\n" if $opts->{verbose};
		}
	}

	if ($job->{combine_inputs}) {
		%inputs = ( 0 => [ map { @$_ } values %inputs ] );
	}

	my $ninputs = scalar(keys %inputs);
	if ($ninputs > 1 && $job->{path} !~ /SOURCE_BKT/) {
		die "Must use SOURCE_BKT as part of 'path' for $job->{name} since there are multiple input buckets";
	}
	if ($job->{buckets} > 1 && $job->{path} !~ /BUCKET/) {
		die "Must use BUCKET as part of 'path' for $job->{name} since there are multiple output buckets";
	}


	my $input_record_count = 0;
	my @metadata2;
	my %post_work;

	my $write_metadata = Proc::JobQueue::DependencyTask->new(
		desc	=> "Write Metadata for $jdesc",
		func	=> sub {
			my ($self, $dependency_graph) = @_;
			$self->{errors}->("Write metadata for $jdesc\n");

			@metadata2 = compress_metadata(@metadata2);
			my $items = sum(map { $_->{items} } @metadata2);

			my $meta = {
				%$timeinfo,
				FILES		=> \@metadata2,
				JOBNAME		=> $job->{name},
				sorted_by	=> $job->{sort_by},
				job		=> $job,
				items		=> $items,
				input_records	=> $input_record_count,
			};

			# don't save these fields in the metadata.
			my @suppressed = delete @$job{@suppress_from_meta};

			write_file($metafname, Dump($meta));
			unlock($metafname);

			@$job{@suppress_from_meta} = @suppressed;

			$job->{srec} = $jobsrec;

			return 'done';
		},
		args	=> [],
		errors	=> $errors,
	);

	$dependency_graph->add($dependency_task, $write_metadata);

	my @metadata;
	my $bias = $opts->{priority_bias} || 'random';
	my $priority_adjust;
	my $pjd = $timeinfo->{JD};
	if ($opts->{target_date}) {
		$pjd = $timeinfo->{JD} - abs(gm_julian_day(parsedate($opts->{target_date})) - $timeinfo->{JD});
	}
	if ($bias eq 'random') {
		$priority_adjust = rand(100);
	} elsif ($bias eq 'date') {
		$priority_adjust = $pjd + rand(1);
	} elsif ($bias eq 'depth') {
		$priority_adjust = $dependency_task->{_depth_score_ref} + $pjd / 2;
	}

	my $sort_and_merge_buckets = Proc::JobQueue::DependencyTask->new(
		desc	=> "Sort, post-sort, merge for $jdesc",
		func	=> sub {
			my ($self, $dependency_graph) = @_;
			$self->{errors}->("Do bucket sorting for $jdesc\n");

			my %namecount;
			for my $meta (@metadata) {
				$namecount{$meta->{header}{name}}++;
			}

			do_sublist(
				sub { $_->{host} }, 
				sub {
					my @m = @_;
					my $host = $m[0]->{host};
$errors->(sprintf("[%s] files: to process: %d\n", $host, scalar(@m)));
					my $dd = $hostsinfo->{$host}{datadir};
					die "no datadir for $host" unless $dd;
					my $jqj;
					$jqj = Proc::JobQueue::DependencyJob->new(
						$dependency_graph,
						sub {
							my ($job_queue_job) = @_;
							die unless $job_queue_job->{host} eq $host;

							$self->{errors}->("Starting $jdesc bucket sorting on $host\n");
							do_remote_job(
								desc		=> "$job_queue_job->{jobnum} $jdesc bucket sorting",
								prefix		=> "$host/$job_queue_job->{jobnum}: ",
								host		=> $host,
								eval		=> 'do_bucket_cleanup(@$data)',
								data		=> [ $hostsinfo->{$host}, \%namecount, $job->{compress_early}, @m ],
								chdir		=> "$dd/code",
								prequel		=> $prequel,
								preload		=> [qw(Log::Parallel::Task)],
								when_done	=> sub {
$errors->(sprintf("[%s] files: processed: %d\n", $host, scalar(@_)));
									push(@metadata2, @_);
									$job_queue_job->finished(0);
								},
								failure		=> sub {
									$jqj->failure(@_);
								},
								error_handler	=> sub {
									$errors->("[$host] ERROR: ", @_);
								},
								output_handler	=> sub {
									$errors->("[$host] ", @_);
								},
							);
							return 'all-keep';
						},
						force_host	=> $host,
						priority	=> $job->{priority} + $priority_adjust,
						desc		=> "$jdesc bucket cleanup",
					);
					$dependency_graph->add($write_metadata, $jqj);
				},
				compress_metadata(@metadata)
			);
			return 'done';
		},
		args	=> [],
		errors	=> $errors,
	);

	$dependency_graph->add($write_metadata, $sort_and_merge_buckets);

	my %host_restriction;
	if ($job->{host_restriction}) {
		%host_restriction = ( force_host => $job->{host_restriction} );
	}
	for my $bucket (keys %inputs) {
		my $desc = $jdesc;
		$desc .= " input bucket $bucket" if $ninputs > 1;
		my $jqj;
		$jqj = Proc::JobQueue::DependencyJob->new(
			$dependency_graph,
			sub {
				my ($job_queue_job) = @_;
				my $host = $job_queue_job->{host};

				my $dd = $hostsinfo->{$host}{datadir};
				die "no datadir for $host" unless $dd;
				my $chdir = "$dd/code";

				# print "PREQUEL $prequel, CHDIR $chdir\n";

				$errors->("Starting $desc on $host\n");
				do_remote_job(
					desc		=> "$job_queue_job->{jobnum} $desc",
					prefix		=> "$host/$job_queue_job->{jobnum}: ",
					host		=> $host,
					eval		=> 'do_task_remote(@$data)',
					data		=> [ $opts, $job, $timeinfo, $hostsinfo, $bucket, @{$inputs{$bucket}} ],
					chdir		=> $chdir,
					prequel		=> $prequel,
					preload		=> [qw(Log::Parallel::Task)],
					when_done	=> sub {
$errors->(sprintf("[%s, bucket=%d] input records: %s, files: %d\n", $host, $bucket, $_[0], scalar(@_)-1));
						$input_record_count += shift;
						push(@metadata, @_);
						$job_queue_job->finished(0);
					},
					local_data	=> {
						dependency_node		=> $write_metadata,
						dependency_graph	=> $dependency_graph,
						job_queue		=> $job_queue_job->{queue},
						config			=> $config,
						hostsinfo		=> $hostsinfo,
						priority		=> $job_queue_job->{priority},
						job			=> $job,
					},
					failure		=> sub {
						$jqj->failure(@_);
					},
					error_handler	=> sub {
						$errors->("[$host, bucket=$bucket] ERROR: ", @_);
					},
					output_handler	=> sub {
						$errors->("[$host, bucket=$bucket] ", @_);
					},
				);
				return 'all-keep';
			},
			priority	=> $job->{priority} + $priority_adjust,
			desc		=> $desc,
			%host_restriction,
		);
		$dependency_graph->add($sort_and_merge_buckets, $jqj);
	}

	$dependency_task->set_cb(sub { return 'done' });
	return 'requeue';
}

#
# For a "source record", return hash of available files
#
# 	$files{$julian_day}{$host}{$filename} = {
#		YYYY	=> $year,
#		MM	=> $month,
#		DD	=> $day,
#		mtime	=> modify-time as time_t,
#	};
#
sub get_files_by_srec
{
	my ($srec, $hostsinfo) = @_;
	die unless $srec->{path};
	delete $srec->{hosts}
		if $srec->{hosts} && @{$srec->{hosts}} == 1 && $fqdnify{$srec->{hosts}[0]} eq $myfqdn;
	my %files;
	my $found_one = sub {
		my ($host, $file, %data) = @_;
		return {} if defined($data{filesize}) && ! $data{filesize};
		#print "FOUND $file $data{YYYY}/$data{MM}/$data{DD}\n";
		my $jd = julian_day($data{YYYY}, $data{MM} || 1, $data{DD} || 1);
		$files{$jd}{$host}{$file} = \%data;
	};
	if ($srec->{hosts}) {
		for my $host (@{$srec->{hosts}}) {
			my $path = $srec->{path};
			$path =~ s/%DATADIR%/$hostsinfo->{$host}{datadir}/g;
			my ($path_re, $afunc) = path_to_regex($path, 5);
			my $sglob = path_to_shell_glob($path);
			my $recho = "csh -c 'echo $sglob' | tr ' ' '\\n' | xargs ls -lLd --full-time";
			#print "SGLOB: $sglob\n";
			#print "PATHRE: $path_re\n";
			open my $ls, "-|", 'ssh', $host, '-n', '-o', 'StrictHostKeyChecking=no', "csh -c $q_shell{$recho}"
				or die "open ls on $host: $!";
			while (<$ls>) {
				my (%vals) = 
				next unless m{^-(?:[-r][-w][-x]){3}\s\d+\s+\S+\s+\S+\s+(\d+)\s+(\d\d\d\d-\d+-\d+ \d\d:\d\d:\d\d)\.000000000( [-+]\d\d\d\d)\s+($path_re)$};
				my ($size, $timestr, $timezone, $file) = ($1, $2, $3, $4);
				my $time = parsedate($timestr.$timezone, WHOLE => 1, VALIDATE => 1, SUBSECOND => 1);
				$found_one->($fqdnify{$host}, $file, mtime => $time, filesize => $size, &$afunc);
			}
			close($ls);
		}
	} else {
		my $path = $srec->{path};
		$path =~ s/%DATADIR%/$hostsinfo->{$myfqdn}{datadir}/g;
		my ($path_re, $afunc) = path_to_regex($path, 1);
		for my $file (bsd_glob path_to_shell_glob($path)) {
			next unless $file =~ /^$path_re$/;
			my ($mtime, $size) = (stat($file))[9,7];
			$found_one->($myfqdn, $file, mtime => $mtime, filesize => $size, &$afunc);
		}
	}

	return \%files;
}

sub add_recnums
{
	my ($config) = @_;

	my %namecounters;
	my $snum = 0;

	my %files_by_srec;
	for my $source (@{$config->{sources}}) {
		$snum++;
		$source->{recnum} = "$source->{name}-$snum-s";
	}
	$snum += 100;
	for my $job (@{$config->{jobs}}) {
		next if $job->{DISABLED};
		$snum++;
		$job->{recnum} = "$job->{name}-$snum-j";
	}
}

sub unify_fields
{
	my (%param) = @_;
	die unless $param{job};
	my $output_columns = $param{job}{output_columns};
	my $new = $param{new} || die;
	my $sort_by = $param{sort_by} || die;
	my $current = $param{current} || die;

	die unless initial_sublist_match(@$sort_by, @$current);
	my $cur;
	if (initial_sublist_match(@$current, @$output_columns) && initial_sublist_match(@$sort_by, @$output_columns)) {
		# this is the normal case
		$cur = longer_list(@$current, @$output_columns);
	} else {
		$cur = $current;
	}

	if ($#$cur < $#$sort_by) {
		@$cur = @$sort_by;
	}
	my $c = 1;
	my %already = map { $_ => $c++ } @$cur;
	my @new = grep { ! defined $already{$_} } @$new;
	if (@new) {
		push(@$cur, @new);
		print STDERR "Column list for $param{job}{name} now @$cur\n";
	}
	return $cur;
}

1;

__END__

=head1 NAME

Log::Parallel - cluster computing framework

=head1 SYNOPSIS

 % bin/process_logs -c config_file

 use Log::Parallel;
 use Log::Parallel::ConfigCheck qw(validate_config);
 use Proc::JobQueue::DependencyQueue;

 opitons();

 run($opts);

 validate_config($config);

 add_recnums($config);

 $files_by_recnum{$_->{recnum}} = get_files_by_srec($_, $config->{hostsinfo}) 
 	for @{$config->{sources}};

 my $dependency_graph = make_dependency_graph(make_task_list($opts, $config, %files_by_recnum))

 my $job_queue = new Proc::JobQueue::DependencyQueue(dependency_graph => $dependency_graph, hosts => [], hold_all => 1);

 setup_slave_hosts($config, $job_queue);

=head1 DESCRIPTION

This is the main driver module at the heart of a cluster computing framework
used for batch log processing.  It
sets things up, figures out what jobs can run and in what order, and queues them up
to run.

Everything it does is driven from the configuration data, probably parsed by
L<Config::YAMLMacros> and validated by L<Log::Parallel::ConfigCheck>.

Only one program, L<process_logs>, is expected to use this module.  As such, 
documentation for the API for this module in particular is not particularly
relevant, but this is as good a place as any to document the overall system.

L<process_logs> is the driver script for processing data logs through a series of
jobs specified in a configuration file.  

Each job consists of a set of steps to process input files and create an 
output file (possibly bucketized).  This very much like a map-reduce framework.
The steps are:

=over 10

=item 1. Parse

The first step is to parse the input files.  The input files can come
from multiple places/steps and be in multiple formats.  They must all
be sorted on the same fields so that they can be joined together in an
ordered stream.  

=item 2. Filter

As items are read in, the filter code is executed.  Items are dropped
unless the filter code returns a true value.

=item 4. Group

The items that make it past the filter can optionally be grouped together
so that they're passed to the next starge as an array of items.

=item 4. Transform

The transform step consumes items and generate items.  It consumes items
one-by-one (or one group at a time), but it can produce zero or many items 
for each one it consumes.
It can take events and squish them together into a session; or it can 
take a session and break it apart into events; or it can take sessions
and produce a single aggregated result when it had consumed all the input.

=item 5. Bucketize

As new resultant items are generated, they can be bucketized into 
many buckets and split across a cluster.

=item 6. Write 

The resultant items are writen in the format specified.  Since the next
step may run things though unix sort, the output format may need to be
squished onto one line.

=item 7. Sort

The output files get sorted according to fields defined in the resultant
items.

=item 8. Post-Sort Transform

If the writer had to encode the output for unix sort, it gets a chance to
un-encode it after sorting so that it's in its desired format.

=back

=head1 CONFIGURATION FILE

The configuration file is in YAML format and is preprocessed
with L<Config::YAMLMacros> which provides some macro directives
(include and define).

It is post-processed with L<Config::Checker> which
allows for some flexibility (sloppyness) on the part of 
configuration writers.  Single items will be automatically turned
into lists when needed.

The configuration file has three several sections.  The main section
is the one that defines the jobs that process logs does.

The exact details of each section are described in L<Log::Parallel::ConfigCheck>.

=head1 CAPABILITIES, LIMITATIONS, POTENTIAL IMPROVEMENTS

The current version of Log::Parallel can efficiently utilize more than 100 CPU cores 
for doing parallel work.  A single process handles starting new jobs and receives
all STDOUT & STDERR from all jobs.  The author expect that this setup will 
bottleneck at around 400 CPU cores.  Larger jobs with less output will change
will allow larger scale processing. 

All jobs in Log::Parallel currently date-based.  All the rules and the input
data are understood to cover certain date ranges.  Log::Parallel figures that
the output time range of a job is the same as the intput time range for that
job.  You can have daily jobs with daily output.  You can combine daily inputs
together to run a weekly job.  In the current system, there is no way to break
up that weekly job's output back into daily time ranges.  This presents two 
problems: first, there is no good solution to sessions that cross a time 
boundry; second, there is no easy way to to go backwards in time (for example,
to filter out spammers).  

On potential improvement would be to allow jobs that have the same input
to run together so that the parsing/combining step is only done once. 

Another improvement would be to use unix C<sort -m> instead of 
L<Sort::MergeSort>.

Currently all files are read and written using C<ssh>.   Reading using a
remote file system (NFS automounts) would improve performance.

=head1 FILE NAMING

The input files for Log::Parallel need to be named with a date stamp.  The
exact naming convention is flexible because the input files can be on multiple
hosts and matched with globs.  Normal syslog filenames will not work so 
some other processes must name things by the date.

=head1 SEE ALSO

This is used by L<process_logs>.   It reads configurations from
L<Log::Parallel::ConfigCheck>.   
It uses a L<Proc::JobQueue::DependencyQueue> to queue the jobs
that need to run.   The jobs it runs are farmed out to remote systems
using L<RPC::ToWorker>.  On the remote system, that code
that runs the jobs is L<Log::Parallel::Task>.  The inputs to the jobs
are parsed using a parser found by L<Log::Parallel::Parsers> and the
outputs are written using a writer invoked by L<Log::Parallel::Writers>.
The main writer is L<Log::Parallel::TSV>.  The time time formats that
describe when jobs should run are parsed by L<Log::Parallel::Durations>.
This module has support modules: L<Log::Parallel::Paths>, 
L<Log::Parallel::Metadata>, L<Log::Parallel::Misc>.

Some modules that are handy for writing jobs are: L<Log::Parallel::Sql>, 
L<Stream::Aggregate>, L<Log::Parallel::Geo::IP>.

=head1 LICENSE

This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

