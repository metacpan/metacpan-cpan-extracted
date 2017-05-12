
package Log::Parallel::ConfigCheck;

use strict;
use warnings;
use Config::Checker;
use Log::Parallel::Parsers;
use Log::Parallel::Writers;
use Log::Parallel::Task;
use Time::ParseDate;
use Clone::PP qw(clone);
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(validate_config);

my $prototype_config = <<'END_PROTOTYPE';
---
master_node:            The control node where the header information and metadata is kept[HOSTNAME]
metadata:               path to the metadata informatin (on master_node)[PATH]
errors:                 path to where to write error logs[PATH]
debug_data:             path to where to write debug data[PATH]
#state_variables:        '*path to where to keep internal state information in YAML files[PATH]'
parameters:             %additional global configuration parameters
sources:
  -
    name:               =name of this source -- will be used later[TEXT]
    hosts:              '*<,>name of hosts where the data can be found[HOSTNAME]'
    path:               filesystem path name where the data can be found[PATH]
    valid_from:         '?date from which this source is valid[DATE]{=parsedate($_[0]) || die "invalid date: <$_[0]> fOr $context"}'
    valid_to:           '?date until which this source is valid[DATE]{=parsedate($_[0]) || die "invalid date: <$_[0]> for $context"}'
    format:             'record format for this source{valid_parser($_[0]) or $error = "invalid parser: <$_[0]> at $context"}'
    remove_after:       '?data expiration policy{parse_expiration_policy($_[0])}'
    sorted_by:          '*<,>how is this input file ordered, by field name returned by the parser'
    parser_config:      '%extra parameters for parsers reading this file'
    use:                '*<\s+>dependent perl modules[MODULE_NAME]'
jobs:
  -
    name:               =name of this step[WORD]
    DISABLED:           '?<No>Disable this job?[BOOLEAN]'
    source:             '+<,>name of input the data[TEXT]'
    dependency:         '*<,>name of input that are not streamed[TEXT]'
    destination:        name of the output data[TEXT]
    hosts:              '*<,>where to do the work and store the output[HOSTNAME]'
    path:               where to write the output data[PATH]
    valid_from:         '?the first day to do this job this way[DATE]{=parsedate($_[0]) || die "invalid date: <$_[0]> For $context"}'
    valid_to:           '?the last day to do this job this way[DATE]{=parsedate($_[0]) || die "invalid date: <$_[0]> FOR $context"}'
    filter:             '?perl expression: to apply to choose input[CODE]'
    transform:          '?perl expression: transform input[CODE]'
    sort_by:            '*<,>list of job fields to sort by[WORD]'
    combine_inputs:     '?<No>De-bucketize the inputs?[BOOLEAN]'
    bucketizer:         '?perl expression: returns data to choose bucket[CODE]'
    buckets:            '?the total number of output buckets[INTEGER]'
    grouper:            '?perl expression: group inputs[CODE]'
    compress_early:     '?<No>Compress output files as they are created[BOOLEAN]'
    remove_after:       '?data expiration policy{parse_expiration_policy($_[0])}'
    output_format:      'name of perl module to handle $object -> ascii{valid_writer($_[0]) or $error = "invalid writer: <$_[0]> at $context"}'
    config:             '%additional configuration parameters for transformers'
    bucket_config:      '%extra parameters for the bucketizer'
    filter_config:      '%extra parameters for the filter'
    parser_config:      '%extra parameters for downstream parsers reading the output file'
    input_config:       '%extra parameters for the input parsers, optionally on a per-source basis'
    output_config:      '%extra parameters for the output writers'
    grouper_config:     '%extra parameters for the grouper function'
    initialize:         '?perl initialization code for the trasform step[CODE]'
    filter_init:        '?perl initialization code for the filter step[CODE]'
    bucket_init:        '?perl initialization code for the bucktization step[CODE]'
    grouper_init:       '?perl initialization code for the grouping step[CODE]'
    open_inputs_init:   '?perl initialization code for the open inputs step[CODE]'
    frequency:          '?how often to generate the data, eg "monthly"[FREQUENCY]'
    timespan:           '?how much data from previous steps to include[TIMESPAN]'
    use:                '*<\s+>dependent perl modules[MODULE_NAME]'
    host_restriction:   '?restrict this job to a single host[HOSTNAME]'
    debug:              '?<No>Extra debugging output for this job?[BOOLEAN]'
    open_inputs:        '?perl expression: code to open the inputs[CODE]'
    open_inputs_config: '%extra parameters for the open_inputs code'
    comment:            '?ignored'
    priority:           '?<100>job priority -- higher runs first[INTEGER]'
    tests:              '*<,>list of test input files[PATH]'
hostsinfo:
  hostname[HOSTNAME]:
    max_threads:        '?<4>maximum number of processes to run at once[INTEGER]'
    max_memory:         '?<5G>maximum amount of memory to use at once[SIZE]'
    temporary_storage:  '?</tmp>Where to keep tmp files[PATH]'
    datadir:            '?Where relative paths start on this system[PATH]'
END_PROTOTYPE

sub parse_expiration_policy
{
	# x x x x x 
	return 1;
}

sub valid_parser
{
	my ($pname) = @_;
	my $p = eval { get_parser($pname); };
	return $p && ! $@;
}

sub valid_writer
{
	my ($pname) = @_;
	open my $fh, ">", "/dev/null"
		or die "open /dev/null: $!";
	my $p = eval { get_writer($pname, fh => $fh, filename => '/dev/null'); };
	return $p && ! $@;
}

sub validate_config
{
	my ($config) = @_;

	my $checker = eval config_checker_source;
	die $@ if $@;

	eval {
		@{$config->{jobs}} = grep { keys %$_ } @{$config->{jobs}}
			if @{$config->{jobs}};
	};

	$checker->($config, $prototype_config, '- log configuration');


	local($Stream::Aggregate::suppress_line_numbers) = 1;

	for my $job (@{$config->{jobs}}) {
		next if $job->{DISABLED};
		my $timeinfo = {
			YYYY	=> 2000,
			MM	=> '01',
			DD	=> '01',
		};
		my $mode = 'test';
		undef $@;
		for my $field (keys %Log::Parallel::Task::compile_fields) {
			local $SIG{ALRM} = sub {
				die "timeout trying to compile '$field' for $job->{name}";
			};
			alarm(30);
			my ($s, $eval) = compile_user_code($job, $timeinfo, $field, {}, '', {}, mode => 'test', default => 'DEFAULT');
			alarm(0);
			next if $s && $s eq 'DEFAULT';
			if ($@) {
				die "Could not compile $job->{name}/$field: $@\nEVAL:\n$eval\n";
			}
		}
	}
}

1;

__END__

=head1 NAME

Log::Parallel::ConfigCheck - Log processing configuration file validation

=head1 SYNOPSIS

 use Config::YAMLMacros qw(get_config);
 use Log::Parallel::ConfigCheck;

 my $config = get_config($config_file);
 validate_config($config);

=head1 DESCRIPTION

ConfigCheck uses L<Config::Checker> to validate a log processing 
configuration that is used by L<process_logs>.  Essentially all ConfigCheck 
consists of is a description of the log processing configuration options.
 
The configuration file has three several sections.  The main section
is the one that defines the jobs that process logs does.

=head2 Jobs Section

The jobs section describes the processing steps that will be applied to the 
logs.  This is the meat of the process.

The jobs are an YAML array in with a key of C<jobs> in the main section.

The keys are:

=over 15

=item name

B<Required>.
The name of the job is used only for diagnostics.  It is not required to be
unique execpt for its specified time range.

=item source

B<Required>.
A list of sources of information.  These can come from the C<destination> fields of
other prior jobs or from the C<name> fields of sources (see below).   Multiple items
may be listed (comma separated or as a YAML array) but the sources must all be 
in the same sort order.  The input to the C<filter> and C<transform> steps will be
in sorted order.  An example source would be something like C<raw apache logs>.

=item destination

B<Required>.
This is the name of what this job produces.   This needs to be unique within the
time range that this job is valid for.  An example destination might be
C<queries extracted from sessions>.

=item output_format

B<Required>.
The name of the output format for the output of this job.  This needs to be one
of the Writers that registers itself with L<Log::Parallel::Writers>.  
Exmaples are: C<TSV_as_sessions>, C<Sessions>, C<TSV>.

=item hosts

B<Not implemented yet>. 
B<Optional>, defaults to the hosts of the privious job or source.
Which hosts should the output from this job be written to.

=item path

B<Required>.
What is the path name where output from this job should be written.
The path name will undergo macro substitutions from 
L<Config::YAMLMacros>, from L<Log::Parallel::Durations>, and from L<Log::Parallel::Task>.  These substitutions 
include:

=over 10

=item DATADIR

Defined perl-host in the Hosts section.

=item BUCKET

The bucket number.  Five digits.

=item YYYY
=item MM
=item DD
=item FROM_YYYY
=item FROM_MM
=item FROM_DD
=item DURATION

Eg C<3 weeks> or C<daily>.

=item FROM_JD

=back

=item valid_from

B<Optional>, defaults to the earliest time based on its sources.
The earliest date for which this job should be run.

=item valid_to

B<Optional>, defaults to the latest time based on its sources.
The last date for which this job should be run.

=item filter

B<Optional>.
Perl code to choose if the input C<$log> object should be processed 
or ignored.   A I<true> return value indicates that the object should
be processed.

To provide a closure instead of code, have a C<BEGIN> block set
C<$coderef> to the closure.  If set, code outside the C<BEGIN> block
will be invoked only once.  This is how C<filter_config> can be used.

=item filter_config

B<Optional>.
A HASH of extra information to provide at compile time for the C<filter> to use.  

=item grouper

B<Optional>
Perl code to group log objects together.  The default is not to group.  
If C<grouper> is set, then the C<$log> objects will be formed into groups
based on the output of the C<grouper> function.  The input is assumed to be
in order so that groups form in sequence and only one group need be 
remembered at a time.  Once grouped, the transform step will receive
a reference to an array of log objects instead of the single log object
it would receive if there was no C<grouper>.

To provide a closure instead of code, have a C<BEGIN> block set
C<$coderef> to the closure.  If set, code outside the C<BEGIN> block
will be invoked only once.  This is how C<grouper_config> can be used.

=item grouper_config

B<Optional>.
A HASH of extra information to provide at compile time for the C<grouper> to use.  

=item transform

B<Optional>.
Perl code to transform input C<$log> objects into zero or more output
C<$log> objects.  This can do re-grouping to turn multiple events into a 
session or vice versa.  It can do 
aggregation (see L<Stream::Aggregate>) and collapse many log 
enties to statistics.

To provide a closure instead of code, have a C<BEGIN> block set
C<$coderef> to the closure.  If set, code outside the C<BEGIN> block
will be invoked only once.  This is how C<config> can be used.

=item config

B<Optional>.
A HASH of extra information to provide at compile time for the C<trasform> to use.  

=item sort_by

B<Optional>.
A list of fields (in the C<$log>) object that to use to sort the output.  The list
can be comma-separated or it can be a YAML list.  Each field name may be followed
by unix sort flags in parenthesis.  For example:

 sort_by:
   - id()
   - count(n)
   - name

The sort flags are optional, but if there are none present, then the data will be
examined (which isn't free) and a guess made as to what kind of data is present.  It's
better to use flags.  If any flag is used, then no data will be examined and any field
without a flag will be treated as a text field.   An empty parenthesis C<()> signifies
text.

The currently supported flags are C<n>, C<g>, and C<r>.  More could be added by modifying
C<make_compare_func()> in L<Log::Parallel::Task>.

=item buckets

B<Optional>.
A number: how many I<buckets> to split the output from this job into.  This would be
used to allow parallel processing.  Defaults to one per host.

=item bucketizer

B<Not implemented yet>.
B<Optional>.
When splitting the output into buckets, it will be split on the modulo of the 
md5-sum of the return value from this bit of perl code.  If you want to make sure
that all URLs from the same domain end up in the same bucket, return the domain
name.

To provide a closure instead of code, have a C<BEGIN> block set
C<$coderef> to the closure.  If set, code outside the C<BEGIN> block
will be invoked only once.  This is how C<bucket_config> can be used.

=item bucket_config

B<Optional>.
A HASH of extra information to provide at compile time for the C<bucketizer> to use.  

=item frequency

B<Optional>, defaults to the frequency of it's C<source>.
How often should this job be run?  This is parsed by L<Log::Parallel::Durations>.
Examples are: C<daily>, C<monthly>, C<on the 3rd Sunday each month>. 

=item timespan

B<Optional>, defaults to the length of the C<frequency>.
How much data should be processed by the job?  
This is parsed by L<Log::Parallel::Durations>.
Examples are: C<daily>, C<3 weeks>.

=item remove_after

B<Not Implemented Yet>.
B<Optional>.
How long should the output of this job be kept?

=item parser_config

B<Optional>.
Extra parameters (a hash) for the parsers of the output of this job.

=item input_config

B<Optional>.
Extra parameters for the parsers used to read the input for this job.

=item output_config

B<Optional>.
Extra parameters for the Writer used to save the output from this job.

=item DISABLED

B<Optional>.
C<0> or C<1>.  If a true value, this job is skipped.

=back

=head2 Sources Section

The sources section specifies were the raw inputs for the log processing system
can be found.  

The sources are an YAML array in with a key of C<sources> in the main section.

=over 15

=item name

B<Required>.
The name of the source.  This must be unique with
other sources and jobs for the time period that this source is valid within.

=item hosts

B<Required>.
A list of hosts (YAML array or comma-separated) where the input files can be found.

=item path

B<Required>.
The path to the input files.  The path name can have can have predefined and
regular-expression wildcard matches.    The pre-defined matches are:

=over 10

=item %YYYY%

Match a year.

=item %MM%

Match a month number.

=item %DD%

Match a day number.

=back

Regular expression matches are defined as I<%NAME=regex%>.  For example, if
the months are 1-12 instead of 01-12, use C<%MM=\d\d?%> instead of C<%MM%>
to match month numbers.

=item valid_from

B<Required>.
The earliest date for which this source is valid.

=item valid_to

B<Optional>, defaults to C<now>.
The last date for which this source is valid.

=item format

The data format of this source.  This must be one of the Parsers that
registers itself with L<Log::Parallel::Parsers>.  

=item remove_after

B<Not Implemented Yet>.
B<Optional>.
How long until the source files should be removed to recover disk space and
protect our users' privacy.

=item sorted_by

B<Optional>.
How is this data ordered?   
A list of fields (YAML array or comma-separated) from the C<$log> objects returned
by the Parser.  Usually these are ordered by time.

=item parser_config

B<Optional>.
A has of extra parameters for the parsers that will read this data.

=back

=head2 Hosts Section

The hosts section provides parameters for the hosts that will be used to rune
the jobs and store the output from the jobs.  

The hosts section is is a YAML HASH in the main section as C<hostsinfo>.
The keys are hostnames.  The values are hashes with the following keys:

=over 15

=item datadir

B<Required>.
The path to where permanent data should be be stored on this host.  This 
path is available as C<%DATADIR%> substitution into C<jobs> and 
C<sources> path names.

=item temporary_storage

B<Optional>, defaults to C</tmp>.
Where temporary files should be stored.

=item max_threads

B<Not Implemented Yet>.
B<Optional>, default = 4.
The number of simultaneous processes to run on this host.

=item max_memory

B<Not Implemented Yet>.
B<Optional>, default = 5G.
Amount of memory available for log processing jobs on this host.

=back

=head2 Directives Section

The directives section is where over-all parameters are set.

These are all level 1 YAML keys.

=over 15

=item master_node

The hostname of the control node where the header information and metadata is kept.  This needs
to match one of the hostnames in the C<hostsinfo> section.

=item headers

The path to where header information is kept (on C<master_node>).

=item metdata_data

The path to where meta data information is kept (on C<master_node>).

=back

=head1 LICENSE

This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

