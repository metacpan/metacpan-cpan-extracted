
package Log::Parallel::Task;

use strict;
use warnings;
use List::Util qw(shuffle sum);
use List::MoreUtils qw(uniq);
use List::EvenMoreUtils qw(do_sublist repeatable_list_shuffler);
use File::Path;
use File::Basename;
use File::Slurp::Remote::BrokenDNS qw($myfqdn %fqdnify);
use Tie::Function::Examples qw(%q_shell %q_perl);
use Log::Parallel::Paths qw(path_to_filename);
use Log::Parallel::Writers;
use Log::Parallel::Parsers;
use Sort::MergeSort;
use Clone::PP qw(clone);
use RPC::ToWorker::Callback;
use Proc::Parallel::RemoteKiller;
use String::CRC qw(crc);
use Time::HiRes qw(time sleep);
use YAML::Syck qw(Dump);
require Exporter;
use File::Slurp::Remote;
use Module::Load;
require POSIX;

my $debug_bucket = 0;

our %compile_fields = (
	transform	=> 'config',
	filter		=> 'filter_config',
	bucketizer	=> 'bucket_config',
	open_inputs	=> 'open_inputs_config',
	grouper		=> 'grouper_config',
);

our %initialize_fields = (
	transform	=> 'initialize',
	filter		=> 'filter_init',
	bucketizer	=> 'bucket_init',
	open_inputs	=> 'open_inputs_init',
	grouper		=> 'grouper_init',
);

our %user_code_defaults = (
	transform	=> sub { return grep { defined } $_[0] },
	filter		=> sub { 1 },
	bucketizer	=> sub { 0 },
	open_inputs	=> sub { 1 },
	grouper		=> sub { return(@_) },
);

our %decompress = (
	gz	=> 'zcat',
	bz2	=> 'bzcat',
);

my $max_command_arg = 10_000;
my $min_open_delay_per_host = 1.0;

our @ISA = qw(Exporter);
our @EXPORT = qw(do_task_remote compile_user_code do_bucket_cleanup grouper_wrap);
our @EXPORT_OK = (@EXPORT, qw(%compile_fields %initialize_fields %user_code_defaults));

if (0) {
	my $freq = 5;
	$main::SIG{ALRM} = sub {
		my ($pkg, $file, $line) = caller(0);
		print "TT$$ $file:$line\n";
		alarm($freq);
	};
	alarm($freq);
}


#
# The job isn't considered complete until the metadata is written on the
# control node.
#
# $hostsinfo is the hostsinfo key from the config file.
# @inputs is a list of the input filenames as anonymous hashes.
#	host
#	filename
#	format
#	header
#	sorted_by
#	bucket
#
sub do_task_remote
{
	my @r;
	my $remote_killer = Proc::Parallel::RemoteKiller->new();
	eval {
		@r = do_task_remote_real($remote_killer, @_);
	};
	my $e = $@;
	if ($e) {
		print STDERR $@;
		print $RPC::ToWorker::Callback::master Dump($@)."RETURN_ERROR\n"
			if $RPC::ToWorker::Callback::master;
		undef $remote_killer;
		POSIX::_exit(1);
	}
	undef $remote_killer;
	return @r;
}

sub do_bucket_cleanup
{
	my @r;
	eval {
		@r = do_bucket_cleanup_real(@_);
	};
	if ($@) {
		print STDERR $@;
		print $RPC::ToWorker::Callback::master Dump($@)."RETURN_ERROR\n"
			if $RPC::ToWorker::Callback::master;
		# exit 1;  hangs
		POSIX::_exit(1);
	}
	return @r;
}


sub do_task_remote_real
{
	my ($remote_killer, $opts, $job, $timeinfo, $hostsinfo, $input_bucket, @inputs) = @_;

	local($main::SIG{USR1}) = sub {
		my ($pkg, $file, $line) = caller(0);
		print "LOCATION $file:$line for $0\n";
	};

	$0 =~ s/: RUNNING.*/: RUNNING /;
	my $av0 = $0;

	$0 = "$av0 setting up remote killer";

	$SIG{'TERM'} = sub {
		$remote_killer->kill_them_all;
		# exit 1; hangs
		POSIX::_exit(1);
	};

	$0 = "$av0 opening inputs";

	my @parsers;
	my @dependencies;

	my $u = '0000';
	my $stream;
	my $expected_input_records = 0;

	my %last_open;

	my $mods = $job->{use} || [];
	for my $mod (@$mods) {
		load $mod;
	}

	do_sublist(
		sub { 
			if (($_->{host} eq '' || $fqdnify{$_->{host}} eq $myfqdn) && $_->{filename} !~ /\.gz$/) {
				return $u++;
			} else {
				$_->{filename} =~ /\.(gz)$/;
				my $jd = $job->{just_depend}{$_->{name}} ? "|JD" : '';
				my $gz = $1 || '';
				return $_->{host} . "|" . $_->{selector} . '|' . $gz . $jd;
			}
		},
		sub {
			my (@i) = sort { $a->{time} <=> $b->{time} } @_;
			my $input = $i[0];
			my @files = map { $_->{filename} } @i;

			# print STDERR "WILL OPEN $input->{host}: @files\n";

			$expected_input_records += sum map { $_->{items} } @i;

			my $fh;
			$0 = "$av0 opening\t$input->{host}:$input->{filename}";
			print "Opening $input->{host}:$input->{filename}\n" if $opts->{verbose} >= 2;
			my $pid;
			my $lohost = $input->{host} || $myfqdn;
			my $tdiff = time - ($last_open{$lohost} || 0);
			if ($tdiff < $min_open_delay_per_host) {
				local($0) = "$av0 sleeping to avoid opening too fast on $lohost";
				sleep($min_open_delay_per_host - $tdiff);
			}
			$last_open{$lohost} = time;

			if ($input->{host} eq '' || $fqdnify{$input->{host}} eq $myfqdn) {
				if ($input->{filename} =~ /\.(gz|bz2)$/) {
					$pid = open $fh, "-|", $decompress{$1}, @files
						or die "open $decompress{$1} $input->{host}: @files: $! ($myfqdn)";
				} else {
					die if @files > 1;
					open $fh, "<", $input->{filename}
						or die "open $input->{filename}: $!";
				}
			} else {
				my @q = map { $q_shell{$_} } @files;

				if ($input->{filename} =~ /\.(gz|bz2)$/) {
					$pid = open $fh, "ssh $input->{host} -n -o StrictHostKeyChecking=no cat @q | $decompress{$1} |"
						or die "ssh $input->{host} cat $input->{filename} | $decompress{$1}: $!";
				} else {
					$pid = open $fh, "-|", 'ssh', '-o', 'StrictHostKeyChecking=no', $input->{host}, '-n', 'cat', @q
						or die "ssh $input->{host} cat $input->{filename}: $!";
				}
			}
			$remote_killer->note(undef, $pid) if $pid;

			my $input_config = $job->{input_config};
			$input_config = $input_config->{$input->{name}}
				if $input_config->{$input->{name}};
			$input_config = $input_config->{$input->{format}}
				if $input_config->{$input->{format}};

			my $format = $input->{format};
			$format = $input_config->{format}
				if $input_config->{format};

			my %extra = map { $_ => $input->{$_} } grep { exists $input->{$_} } qw(filesize header time filename host);
			$extra{filenames} = \@files;
			$extra{span} = $i[-1]->{time} - $i[0]{time} + $i[-1]{span}
				if $i[-1]{span};
			delete $extra{filesize} if @i > 1;

			$0 = "$av0 starting $format parser for $input->{host}:$input->{filename}";
			my $parser = get_parser($format, $fh, 
				sorted_by => $input->{sorted_by}, 
				%{$input->{parsers_config}}, 
				%$input_config,
				%extra);
			$0 = "$av0 started $format parser for $input->{host}:$input->{filename}";
			if ($job->{just_depend}{$input->{name}}) {
				push(@dependencies, $parser);
			} else {
				push(@parsers, $parser);
			}
		},
		@inputs
	) unless $job->{open_inputs};

	if ($job->{open_inputs}) {
		$0 = "$av0 compiling input open code";
		my $open_inputs = compile_user_code(
			$job, 
			$timeinfo, 
			$user_code_defaults{open_inputs},
			{ inputs => \@inputs }, 
			'my @inputs = @{$extra_data->{inputs}};',
			$hostsinfo,
		);

		$0 = "$av0 compiling input open code";

		@parsers = &$open_inputs(@inputs);
	}

	$0 = "$av0 parsers started";

	my @sorted_by;
	@sorted_by = @{$inputs[0]->{sorted_by}} if @inputs;
	@sorted_by = () if (@sorted_by == 1 && $sorted_by[0] eq 'unsorted') || @sorted_by == 0;
	@sorted_by = () if $job->{input_config} && $job->{input_config}{ignore_sorting};

	# print STDERR "SORTBY IS @sorted_by\n";

	$0 = "$av0 starting iterators";

	@parsers = ( sub { undef } ) unless @parsers;

	my @iterators = map { Sort::MergeSort::Iterator->new($_) } @parsers;

	if (@sorted_by && @iterators > 1) {
		$0 = "$av0 making comparision function";

		print STDERR "Sorting by @sorted_by\n";

		my $compare = make_compare_func($inputs[0]->{sort_types} || {}, @sorted_by);

		$0 = "$av0 starting mergesort of inputs";

		$stream = mergesort($compare, @iterators);
	} else {
		$stream = pop(@iterators);
	}

	my $new_field_cb = sub {
		my (%param) = @_;
		master_call(
			'',
			'Log::Parallel::unify_fields',
			'job',
			%param,
		);
	};

	$0 = "$av0 opening outputs";

	my @writers;
	eval {
		(@writers) = open_output_files($job, $timeinfo, $hostsinfo, $remote_killer, $new_field_cb, $input_bucket);
	};
	print STDERR "FAILED: $@" if $@;
	die $@ if $@;


	$0 = "$av0 opening outputs (register pointer)";

	for my $i (0..$#writers) {
		$writers[$i]->register_pointer(\$writers[$i]) if $writers[$i]->can('register_pointer');
	}

# print "COMPILING FOR $job->{name}\n";
	
	my $filter = compile_user_code(
		$job,
		$timeinfo,
		'filter',
		{ dependencies => \@dependencies }, 
		'my @dependencies = @{$extra_data->{dependencies}};',
		$hostsinfo,
	);
	my $grouper = compile_user_code($job,
		$timeinfo,
		'grouper',
		undef,
		undef,
		$hostsinfo,
	);
	$grouper = grouper_wrap($grouper) if $job->{grouper};
	my $bucketizer = compile_user_code($job,
		$timeinfo,
		'bucketizer',
		undef,
		undef,
		$hostsinfo,
	);
	my $transform = compile_user_code(
		$job,
		$timeinfo,
		'transform',	
		{ dependencies => \@dependencies }, 
		'my @dependencies = @{$extra_data->{dependencies}};',
		$hostsinfo,
	);

# print "DONE COMPILING FOR $job->{name}\n";

	my $logcount = 0;
	my $filtered = 0;
	my $outputs = 0;
	my $groupcount = 0;
	eval {
		for(;;) {
			$0 = "$av0 $logcount done - getting input";
			my $log = <$stream>;
			$0 = "$av0 $logcount done - handling record";
			if ($log) {
				$logcount++;
				$0 = "$av0 $logcount done - calling filter";
				next if $filter && ! $filter->($log) && ++$filtered;
				$0 = "$av0 $logcount done - calling grouper";
			} else {
				if (! @sorted_by) {
					$stream = pop(@iterators);
					next if $stream;
				} 
				$0 = "$av0 $logcount done - calling transform on last input record";
			}
			my @output;
			for my $group ($grouper->($log)) {
				$0 = "$av0 $logcount done - calling transform";
				$groupcount++;
				push(@output, $transform->($group)); 
			}
			$outputs += scalar(@output);
			for my $new_log (@output) {
				$0 = "$av0 $logcount done - writing output";
				my $string = $bucketizer->($new_log);
				my $crc = crc($string || '', 32);
				my $bucket = $crc % $job->{buckets};
				my $writer = $writers[ $bucket ];
				die "bucketizer returned '$string'" unless $writer;
				$writer->write($new_log);
			}
			last unless $log;
		}
	};
	if ($@) {
		print STDERR $@;
		print $RPC::ToWorker::Callback::master Dump($@)."RETURN_ERROR\n"
			if $RPC::ToWorker::Callback::master;
		# exit 1; hangs
		POSIX::_exit(1);
	}

	$0 = "$av0 closing writers";

	$_->done() for @writers;

	$remote_killer->forget_all;

	my @metadata = map { $_->metadata } grep { $_->items } @writers;

	printf "Counts: files w/data: %d files w/o data: %d hosts w/data: %d input records: %d expected input records: %d filtered: %d groups %d output records: %d, input count match: %s\n",
		scalar(grep { $_ } map { $_->{items} } @metadata),
		scalar(grep { ! $_ } map { $_->{items} } @metadata),
		scalar(uniq(map { $_->{host} } grep { $_->{items} } @metadata)),
		$logcount,
		$expected_input_records,
		$filtered,
		$groupcount,
		sum( map { $_->{items} } @metadata),
		($logcount == $expected_input_records ? "yes" : "NO MATCH") ;

	return ($logcount, @metadata);
}

my $fake_package_counter = 'a0000';

sub compile_user_code
{
	my ($job, $timeinfo, $field, $extra_data, $extra_eval, $hostsinfo, %extra) = @_;

	local($0) = $0;
	$0 =~ s/(: RUNNING).*/$1 compiling user code: $field - setup/;

	my $mode = $extra{mode} || 'real';

	return $extra{default} || $user_code_defaults{$field} unless defined $job->{$field};

	my $config_key = $compile_fields{$field} || 'no config key';
	my $config = $job->{$config_key} 
		? clone($job->{$config_key})
		: {}; 

	my $init_key = $initialize_fields{$field} || 'no init key';
	my $init_code = $job->{$init_key} || '';

	my $coderef;

	my $uses = '';
	for my $u (@{$job->{use}}) {
		my $uu = $u;
		$uu =~ s{/}{::}g;
		$uu =~ s{\.pm$}{};
		$uses .= "use $uu;\n";
	}

	$extra_eval = '' unless $extra_eval;
	my $varname = '$log';
	$varname = '$session' if $field eq 'transform' && $job->{grouper};
	$varname = $extra{varname} if $extra{varname};

	my $code = $job->{$field} || '';

	my $sub;
	$fake_package_counter++;
	my $eval = <<END_EVAL;
		package Log::Parallel::Task::UserCode::$fake_package_counter;
#line 1 "job '$job->{name}', $field PREQUEL"
		$extra_eval
		$uses
#line 1 "job '$job->{name}', $field initialization"
		$init_code;
		\$sub = sub { 
			my $varname = shift; 
#line 1 "job '$job->{name}', $field code"
			$code
		};
END_EVAL

	$0 =~ s/(: RUNNING).*/$1 compiling user code: $field - eval/;

	# print STDERR "Compiling $job->{name} $field:\n$eval\n";

	eval $eval;

	if ($@ && $mode ne 'test') {
		$0 =~ s/(: RUNNING).*/$1 failed compiling user code: $field: $@/;
		my $e = "can't compile user code for $job->{name}, $field: $@\n$eval";
		print STDERR $e;
		print $RPC::ToWorker::Callback::master Dump($e)."RETURN_ERROR\n"
			if $RPC::ToWorker::Callback::master;
		# exit 1; hangs
		POSIX::_exit(1);
	}

	$0 =~ s/(: RUNNING).*/$1 done compiling user code: $field/;

	if ($coderef) {
		&$sub(undef);
		$sub = $coderef; 
	}
	return ($sub, $eval) if wantarray;
	return $sub;
}
	
sub grouper_wrap
{
	my ($gfunc, $limit) = @_;
	$limit ||= 100_000;
	my $value;
	my $buf;
	return sub {
		my $log = shift;
		my $old = $value;
		$value = $gfunc->($log);
		if ($log) {
			if ($buf) {
				if ($old eq $value) {
					push(@$buf, $log);
					if (@$buf > $limit) {
						my $b = $buf;
						undef $buf;
						return ($b);
					}
					return ();
				} else {
					my $b = $buf;
					$buf = [ $log ];
					return ($b);
				}
			} else {
				$buf = [ $log ];
				return ();
			}
		} else {
			return ($buf, undef) if $buf;
			return (undef);
		}
	};
}


sub open_output_files
{
	my ($job, $timeinfo, $hostsinfo, $remote_killer, $new_field_cb, $input_bucket) = @_;
	my %output_files;
	my @writers;

	my $nbuckets = $job->{buckets};
	my @buckets = (0 .. ($nbuckets-1));

	my @where;

	my $shuffle = repeatable_list_shuffler($timeinfo->{JD}.$job->{name});

	my @hosts = $shuffle->(@{$job->{hosts}});

	# x x x x x need to support 'from source-name'
	for my $b (@buckets) {
		@hosts = $shuffle->(@{$job->{hosts}}) unless @hosts;
		$where[$b] = pop(@hosts);
		# print "($timeinfo->{JD}.$job->{name}) bucket $b goes to $where[$b]\n";
	}

	my $jobname = $job->{name};
	$jobname =~ s/\s+/-/g;
	my $destname = $job->{destination};
	$destname =~ s/\s+/-/g;

	my $done = 1;

	for my $bucket (@buckets) {
		my $host = $where[$bucket];

		die "No input bucket but 'SOURCE_BKT' is part of path" 
			if $job->{path} =~ /SOURCE_BKT/ && ! defined $input_bucket;
		
		my $filename = path_to_filename($job->{path},
			DATADIR		=> $hostsinfo->{$host}{datadir},
			BUCKET		=> $bucket,
			SOURCE_BKT	=> $input_bucket,
			JOBNAME		=> $jobname,
			DESTNAME	=> $destname,
			%$timeinfo,
		);

		my $ofn = $filename;
		$ofn .= ".tmp" if $job->{sort_by} || ($filename =~ /\.gz/ && ! $job->{compress_early});
		$ofn = ">$ofn";

		my $dirname = dirname($filename);

		if ($fqdnify{$host} ne $myfqdn) {
			$ofn = "mkdir -p $q_shell{$dirname} ; cat $ofn";
			$ofn = "| ssh $host -o StrictHostKeyChecking=no $q_shell{$ofn}";
		} else {
			mkpath($dirname);
		}
		if ($filename =~ /\.gz$/ && ! $job->{sort_by} && $job->{compress_early}) {
			$ofn = "| gzip $ofn";
		}

		$0 =~ s/(: RUNNING).*/$1 setting up output to $ofn ($done of $nbuckets)/;
		$done++;

		my $writer = get_writer($job->{output_format},
			%{$job->{output_config}},
			lazy_open_filename	=> $ofn,
			sort_by			=> $job->{sort_by},
			host			=> $host,
			filename		=> $filename,
			bucket			=> $bucket,
			new_field_cb		=> $new_field_cb,
		);
		push(@writers, $writer);
	}

	$0 =~ s/(: RUNNING).*/$1 opening outputs/;

	return @writers;
}

#
# This is called after do_task_remote with the metadata for the files
# that are local to the host it is called on.
#
sub do_bucket_cleanup_real
{
	my ($hostinfo, $counts, $compress_early, @metadata) = @_;

	$0 =~ s/(: RUNNING).*/$1 preparing to sort/;

	# only combine things that are are being sorted -- otherwise
	# natural order may be lost.
	my $unique = "a00000";
	for my $m (@metadata) {
		if ($m->{header}{sort_by}) {
			$m->{key} = "$m->{header}{name} = $m->{bucket} = $m->{sort_args} = $m->{post_sort_transform}";
			if ($m->{header}{format} eq 'TSV') {
				# I know, gross to hard code it!
				$m->{key} = "$m->{bucket} = $m->{sort_args} = $m->{post_sort_transform} = " 
					. join(",", sort @{$m->{header}{columns}});
			}
		} else {
			$m->{key} = $unique++;
		}
	}
		
	my @m2;

	my $total = @metadata;
	my $done = 0;
	my $setcount = 0;

	# printf "doing bucket cleanup on %d files\n", scalar(@metadata);

	do_sublist(
		sub { $_->{key} },
		sub {
			my $this_set = @_;
			$setcount++;
			$done += $this_set;
			$0 =~ s/(: RUNNING).*/$1 sorting $this_set ($done of $total)/;
			printf "bucket cleanup for %d files with key %s\n", $this_set, $_[0]->{key} if $debug_bucket;

			my $first = shift;
			my $header = $first->{header};
			my $filename = $first->{filename};

			if ($header->{sort_by} && @{$header->{sort_by}}) {
				my $sortargs = $first->{sort_args};
				my $tdir = $hostinfo->{temporary_storage} || $hostinfo->{datadir} || "/tmp";

				mkpath($tdir);

				my $command = "sort -o $q_shell{$filename}.tmp2 --temporary-directory=$q_shell{$tdir} $sortargs";

				my $mem = $hostinfo->{max_memory} || 64*1024*1024;
				my $threads = $hostinfo->{max_threads} || 1;
				my $size = int($mem/$threads/1024/1024);
				$size = 16 unless $size > 16;

				$command .= " --buffer-size=${size}M";

				$0 =~ s/(: RUNNING).*/$1 post sort $this_set ($done of $total)/;

				my @same = grep { $_->{header}{name} eq $header->{name} } @_;
				my @different = grep { $_->{header}{name} ne $header->{name} } @_;

				if ($header->{format} eq 'TSV' && @different) {
					$command .= " $q_shell{$_->{filename}}.tmp" for $first, @same;
					$command = "| $command -";
					my @standard = @{$first->{header}{columns}};
					my $pid = open my $sort, $command 
						or die "open $command: $!";
					for my $file (@different) {
						open my $f, "<", "$file->{filename}.tmp" 
							or die "cannot open $file->{filename}.tmp: $!";
						my @this = @{$file->{header}{columns}};
						my $c = 0;
						my %order = map { $_ => $c++ } @this;
						my @reorder = @order{@standard};
						while (<$f>) {
							chomp;
							my (@line) = split(/\t/, $_, -1);
							no warnings;
							print $sort join("\t", @line[@reorder]) . "\n" 
								or die "print to sort: $!";
						}
					}
					close($sort) 
						or die "close $command: $!";
					die "bad exit from $command: $!" if $? >> 8;
				} else {
					$command .= " $q_shell{$_->{filename}}.tmp" for $first, @_;

					# print "+ $command\n";
					system($command);
					die "sort failed ($command)" if $? >> 8;
				}

				my $pst = $first->{post_sort_transform};
				do_post_sort_transform($filename, $pst);
			} elsif ($filename =~ /\.gz$/ && ! $compress_early) {
				system("gzip < $q_shell{$filename}.tmp > $q_shell{$filename}");
				die "bad exit from gzip < $q_shell{$filename}.tmp > $q_shell{$filename}" if $? >> 8;
			}

			$0 =~ s/(: RUNNING).*/$1 rm tmp files $this_set ($done of $total)/;
			unlink("$_->{filename}.tmp2") for $first, @_;
			unlink("$_->{filename}.tmp") for $first, @_;

			$first->{items} += sum( 0, map { $_->{items} } @_ );
			print "ITEMS in $filename: $first->{items}\n" if $debug_bucket;

			# These aren't needed in the on-disk metadata file
			delete $first->{post_sort_transform};
			delete $first->{sort_args};
			delete $first->{key};

			$0 =~ s/(: RUNNING).*/$1 write header $this_set ($done of $total)/;
			my $counter = 1;
			write_file("$filename.header", 
				map { sprintf("%d\t%s\n", $counter++, $_) } @{$header->{columns}});

			die "zero size" if $first->{items} && ! -s $filename;

			push(@m2, $first);
		},
		sort { $counts->{$b->{header}{name}} <=> $counts->{$a->{header}{name}} || $a->{filename} cmp $b->{filename} } @metadata
	);
	printf "cleanup done done: %d in %d sets, starting from %d\n", $done, $setcount, scalar(@metadata);
	$0 =~ s/(: RUNNING).*/$1 done/;
	return (@m2);
}

sub do_post_sort_transform
{
	my ($filename, $pst) = @_;
	if ($pst) {
		die $@ if $@;
		open my $sorted, "<", "$filename.tmp2"
			or die "open $filename.tmp2: $!";
		my $fixed;
		if ($filename =~ /\.gz$/) {
			open $fixed, "| gzip > $q_shell{$filename}"
				or die "open gzip >$filename: $!";
		} else {
			open $fixed, ">", $filename
				or die "open $filename: $!";
		}
		my $pstfunc = eval $pst;
		die $@ if $@;
		while (<$sorted>) {
			&$pstfunc;
		}
		$_ = undef;
		&$pstfunc;
		close($fixed) or die;
	} elsif ($filename =~ /\.gz$/) {
		system("gzip < $q_shell{$filename}.tmp2 > $q_shell{$filename}");
		die "bad exit from gzip < $q_shell{$filename}.tmp2 > $q_shell{$filename}" if $? >> 8;
	} else {
		rename("$filename.tmp2", $filename)
			or die "mv $filename.tmp2 $filename: $!";
	}
}

sub make_compare_func
{
	my ($types, @col) = @_;

	my $r;
	$r = sub { 
		my ($types, $col, @remainder) = @_;
		my $cola = '$a->{' . $q_perl{$col} . '}';
		my $colb = '$b->{' . $q_perl{$col} . '}';
		my $cmp = 'cmp';
		my $type = $types->{$col};
		if (! $type) {
			# default
		} elsif ($type eq 'n' || $type eq 'g') {
			$cmp = '<=>';
		} elsif ($type =~ /^(?:rn|nr|rg|ng)$/) {
			$cmp = '<=>';
			($cola, $colb) = ($colb, $cola);
		} elsif ($type eq 'r') {
			($cola, $colb) = ($colb, $cola);
		} else {
			die "unknown sort type '$type'";
		}
		my $s = "$cola $cmp $colb";
		return $s unless @remainder;
		$s .= " || ";
		$s .= $r->($types, @remainder);
	};

	my $e = 'sub { no warnings; my ($a, $b) = @_; ' . $r->($types, @col) . "}";
	# print STDERR "SORT FUNC: $e\n";
	my $func = eval $e;
	die "compile '$e': $@" if $@;
	return $func;
}

1;
__END__

=head1 NAME

Log::Parallel::Task - execute a log processing job on a remote system

=head1 DESCRIPTION

This is the code that runs on the remote system to do a L<Log::Parallel> job.

=head1 LICENSE

This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

