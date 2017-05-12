#FEATURE: Add a force cache-condition that will override the other conditions
#         so that the cache is still valid although the other conditions fail.
#         Cache timeout: <& template src="blub" cache="never/1h/1d..." / &>
#FEATURE: Implement SQL conditions

=head1 NAME

Konstrukt::Cache - Caching functionalities

=head1 SYNOPSIS
	
	#read and track a file/some files. only files that have been read with the
	#L<Konstrukt::File/read_and_track> method will be tracked for caching and the
	#cache conditions will only be saved for this files.
	$Konstrukt::File->read_and_track('/some/file'); #will be $docroot/some/file
	$Konstrukt::File->read_and_track('another_file'); #will be $docroot/some/another_file
	
	#check that this file has not been changed
	$Konstrukt::Cache->add_condition_file(<filename of the file that should be cached>, <filename of the file that must not change>);
	
	#check that this date is not reached
	#format:
	#YYYY-MM-DD-HH-MM-SS (absolute date)
	#+1Y, 1M, 1D, 1H, 1M, 1S (relative date)
	$Konstrukt::Cache->add_condition_date(<filename of the file that should be cached>, <date in format as stated above>);
	
	#check that the sql table didn't change
	#will use the sql-connection-settings from your konstrukt.config. see Konstrukt::Plugin::sql
	$Konstrukt::Cache->add_condition_sql(<filename of the file that should be cached>, <table>);
	#will use the specified sql-connection-settings
	$Konstrukt::Cache->add_condition_sql_advanced(<filename of the file that should be cached>, <dbi-source>, <dbi-user>, <dbi-pass>, <table>);
	
	#check that this sub returns true.
	#this is the most flexible but also least comfortable way to validate the cache.
	$Konstrukt::Cache->add_condition_perl(<filename of the file that should be cached>, "<perl-code here>");
	
	#prevent caching of the file. if you don't want this file to be cached for some reason.
	$Konstrukt::Cache->prevent_caching(<filename of the file that must not be cached>);
	
	#write the cache
	$Konstrukt::Cache->write_cache($Konstrukt::File->absolute_path(<filename of the file that must not be cached>), <parse tree>);

	#read the cache
	my $parse_tree = $Konstrukt::Cache->get_cache($Konstrukt::File->absolute_path(<filename of the file that must not be cached>));
	
	#delete the cache. generally only used internally
	$Konstrukt::Cache->delete_cache($Konstrukt::File->absolute_path(<filename of the file that must not be cached>));

=head1 DESCRIPTION

This module provides the caching functionality of this framework.
It's one key element to a higher performance, so the usage is recommended.

After the I<prepare>-run the result will be cached, so that on a second request
for this file the prepare-work won't be done again.

You can add conditions to the cached results that must be fulfilled to accept
the cached result as up-to-date.

For example you may specify an input file that must not change (L</add_condition_file>).
If the file was modified its date will change, the cache will get invalid and
the source file has to be processed from the start.

For more possibilities take a look at L</SYNOPSIS>.

=head1 TRACKED FILES / TO WHICH FILES ARE THE CONDITIONS APPLIED?

Only files that have been read with the L<Konstrukt::File/read_and_track> method
will be tracked for caching and the cache conditions will only be saved for this
files.

Let's say you read those three files:

	$Konstrukt::File->read_and_track('/some/file');   #1) will be $docroot/some/file
	$Konstrukt::File->read_and_track('another_file'); #2) will be $docroot/some/another_file
	$Konstrukt::File->read('even_another_file');      #3) will be $docroot/some/even_another_file

Then you add a date condition:

	$Konstrukt::Cache->add_condition_date("+5m"); #cache valid for max. 5 minutes

This condition will be added to file 1) and 2). Not to file 3) as it is not
tracked (i.e. not push()'ed on Konstrukt::File's file stack).

Then you're done with file 2) and remove it from Konstrukt::File's stack:

	$Konstrukt::File->pop();

Now you add another date condition:

	$Konstrukt::Cache->add_condition_date("+2m"); #cache valid for max. 2 minutes

This condition will only be added to file 1), as file 2) isn't tracked anymore.
Note also that only earlier dates will be added. A later date won't be added as
the file already gets invalid by the earlier date condition.

Note: When a new file is read (with L<Konstrukt::File/read_and_track>) a file date
condition will automatically added to each tracked file as
it is supposed that the file depends on the files which have been read as the
file was tracked. See also L<Konstrukt::File/read_and_track>.

Now you might want to write the cache:

	$Konstrukt::Cache->write_cache($Konstrukt::File->absolute_path('/some/file'),        <parse tree 1>);
	$Konstrukt::Cache->write_cache($Konstrukt::File->absolute_path('another_file'),      <parse tree 2>);
	$Konstrukt::Cache->write_cache($Konstrukt::File->absolute_path('even_another_file'), <parse tree 3>);

A cache for all 3 files will be written.

File 1) will have a date condition (+5m) and a file date condition for every file
that has been read (with read_and_track) while file 1) has been tracked. That will
be "/some/file" itself and "/some/file/another_file" (and also "/konstrukt.settings"
as it is supposed that a settings change will invalidate all cached results).

File 2) will have a date condition (+2m) and file conditions only for itself (and
for "/konstrukt.settings").

File 3) will have no cache conditions as it has not been opened with "read_and_track".

Note that L</get_cache> has a similar effect as <Konstrukt::File/read_and_track>.

=head1 CONFIGURATION

You may define those settings. Defaults:

	cache/use       1          #Use cache:    0=never; 1=if exist
	cache/create    1          #Create cache: 0=never; 1=auto; 2=always
	cache/dir       ../cache/  #Directory to store the cached files in. Should end with a /. Relative to your document root
	cache/file_ext  .cached    #File extension for cached files

=cut

package Konstrukt::Cache;

use strict;
use warnings;

use Konstrukt::Debug;

use Date::Calc qw(Today_and_Now Add_Delta_YMDHMS);
use Time::Local;
use Storable;

=head1 METHODS

=head2 new

Constructor of this class

=cut
sub new {
	my ($class) = @_;
	return bless {}, $class;
}
#= /new

=head2 init

Initialization of this class

=cut
sub init {
	my ($self) = @_;
	
	#kill all data fields
	foreach my $key (keys %{$self}) {
		delete $self->{$key};
	}
	
	#set default settings
	$Konstrukt::Settings->default("cache/use"     , 1);
	$Konstrukt::Settings->default("cache/create"  , 1);
	$Konstrukt::Settings->default("cache/dir"     , '../cache');
	$Konstrukt::Settings->default("cache/file_ext", '.cached');
	
	#validate cache dir
	$self->{cache_dir} = $Konstrukt::File->absolute_path($Konstrukt::Settings->get("cache/dir"));
	$self->{cache_dir} .= "/" unless substr($self->{cache_dir}, -1, 1) eq "/";
	
	return 1;
}
#= /init

=head2 add_condition_file

Add a condition, that checks whether a file has been modified.

B<Parameters>:

=over

=item * $watch_file - The B<absolute> path to the file that should be checked for changes.

=back

=cut
sub add_condition_file {
	my ($self, $watch_file) = @_;
	
	return undef unless $Konstrukt::Settings->get("cache/create");
	
	#the date of the file to watch
	my $date = (stat($watch_file))[9];
	
	#add the condition for each tracked file
	#warn join " == ", $Konstrukt::File->get_files();
	foreach my $file ($Konstrukt::File->get_files()) {
		next if $self->{$file}->{prevent_caching};
		$self->{$file}->{conditions}->{file}->{$watch_file} = $date;
		$Konstrukt::Debug->debug_message("Added condition to file '$file': $watch_file @ $date") if Konstrukt::Debug::NOTICE;
	}

	return 1;
}
#= /add_condition_file

=head2 add_condition_date

Add a condition, that checks whether the given date has been reached yet or not.

B<Parameters>:

=over

=item * $date - The date. Absolute and relative dates allowed. Format:
	C<YYYY-MM-DD-HH-MM-SS (absolute date)>, 
	C<+1Y 1M 1D 1h 1m 1s (relative date)>.
	
	Note that only positive date differences are allowed.
	Algebraic signs will not work. The format is B<case sensitive>!

=back

=cut
sub add_condition_date {
	my ($self, $date) = @_;

	return undef unless $Konstrukt::Settings->get("cache/create");
	
	#parse the input string and generate a date in the unix time format
	my $cachedate;
	if (substr($date, 0, 1) eq "+") {
		my @offsets = split /\s+/, substr($date, 1);
		my @diff = ((0) x 6);
		my %letter_to_index = ('Y' => 0, 'M' => 1, 'D' => 2, 'h' => 3, 'm' => 4, 's' => 5);
		foreach my $offset (@offsets) {
			$offset =~ /^(\d+)(.)$/;
			if ($1 and $2 and exists($letter_to_index{$2})) {
				$diff[$letter_to_index{$2}] += $1;
			}
		}
		my @diffed_date = Add_Delta_YMDHMS(Today_and_Now(), @diff);
		#subtract 1 from the month, as the unix-months are in [0..11].
		$diffed_date[1]--;
		#timelocal accepts the dates in reverse order
		@diffed_date = reverse(@diffed_date);
		#convert date into unix time format
		$cachedate = timelocal(@diffed_date);
	} elsif ($date =~ /(\d\d\d\d)-(\d\d)-(\d\d)-(\d\d)-(\d\d)-(\d\d)/) {
		$cachedate = timelocal($6, $5, $4, $3, $2 - 1, $1);
	}

	#add the condition for each tracked file
	foreach my $file ($Konstrukt::File->get_files()) {
		next if $self->{$file}->{prevent_caching};
		#only set new condition if it doesn't exist yet or if it is stricter (earlier) than the existing one
		if (not exists $self->{$file}->{conditions}->{date} or $self->{$file}->{conditions}->{date} > $cachedate) {
			$self->{$file}->{conditions}->{date} = $cachedate;
			$Konstrukt::Debug->debug_message("Added condition to file '$file': 'date' @ $cachedate") if Konstrukt::Debug::NOTICE;
		}
	}

	return 1;
}
#= /add_condition_date

=head2 add_condition_sql

Add a condition, that checks whether an SQL-table has been modified or not.

The sql connection settings from your konstrukt.config will be used.

Note that the specified table B<must> have a column named "timestamp", which must
be kept up to date on UPDATE and INSERT operations.

This may lead into problems as DELETE operations may not be recognized this way,
because the appropriate row just disappears and the youngest timestamp may stay
unmodified.
You may get around this by inserting a dummy row with no content and just a
timestamp that you manually keep up to date.

Note that the column type TIMESTAMP (e.g. in MySQL) will be updated on each UPDATE
and INSERT operation.

B<Parameters>:

=over

=item * $table - The table for which the youngest timestamp will be checked.

=back

=cut
sub add_condition_sql {
	my ($self, $table) = @_;

	return undef unless $Konstrukt::Settings->get("cache/create");

	return 1;
}
#= /add_condition_sql

=head2 add_condition_sql_advanced

This one does the same as L</add_condition_sql> but lets you define the sql
connection settings yourself.

B<Parameters>:

=over

=item * $source - The DBI-source.

=item * $user - The username for the DB logon.

=item * $pass - The password for the DB logon.

=item * $table - The table for which the youngest timestamp will be checked.

=back

=cut
sub add_condition_sql_advanced {
	my ($self, $source, $user, $pass, $table) = @_;

	return undef unless $Konstrukt::Settings->get("cache/create");

	return 1;
}
#= /add_condition_sql_advanced

=head2 add_condition_perl

Adds a condition, that will execute (eval) the passed perl code and will assume
a valid cache on a "true" result and discard the cache otherwise.

B<Parameters>:

=over

=item * $code - The perl code that should be executed.

=back

=cut
sub add_condition_perl {
	my ($self, $code) = @_;

	return undef unless $Konstrukt::Settings->get("cache/create");

	#add the condition for each tracked file
	foreach my $file ($Konstrukt::File->get_files()) {
		next if $self->{$file}->{prevent_caching};
		if (not exists $self->{$file}->{conditions}->{perl}->{$code}) {
			$self->{$file}->{conditions}->{perl}->{$code} = 1;
			$Konstrukt::Debug->debug_message("Added condition to file '$file': 'perl'") if Konstrukt::Debug::NOTICE;
		}
	}

	return 1;
}
#= /add_condition_perl

=head2 prevent_caching

Prevents the caching of a file.

You may pass a reason, why the cache creation should be prevented.

B<Parameters>:

=over

=item * $file - The B<absolute> filename of the file that should be cached.

=item * $reason - An integer which defines the reason for the cache prevention:

=over

=item * 0: No reason

=item * 1: Errors during the processing of this file

=item * 2: Already using a cached file. Don't cache again.

=back

=back

=cut
sub prevent_caching {
	my ($self, $file, $reason) = @_;

	my @reasons = 
		(                                                                            
		 'Cache creation prevented.',                                                        # 0  = no reason
		 'Cache creation prevented due to errors in one or more files.',                     # 1  = errors
		 'Cache creation prevented due to the use of an already cached file.',               # 2  = already cached
		 'Cache creation prevented because we will not cache results from the execute run.', # 3  = execute run
		);
	
	$reason = 0 if $reason > @reasons - 1;
	
	$Konstrukt::Debug->debug_message("File: $file - Reason: $reasons[$reason]") if Konstrukt::Debug::NOTICE;
	
	$self->{$file}->{prevent_caching} = 1;
	
	return 1;
}
#= /prevent_caching

=head2 validate_cache

Takes a cache-file and validates it with the contained conditions.
Returns true on a valid cache-file.

B<Parameters>:

=over

=item * $tree - The content of the cache file (Reference to the root node).

=back

=cut
sub validate_cache {
	my ($self, $tree) = @_;

	#validate each condition. stop the validation, if a condition is not
	#fulfilled and return undef
	
	#file conditions
	foreach my $file (keys %{$tree->{cache_conditions}->{file}}) {
		my $date = $tree->{cache_conditions}->{file}->{$file};
		#invalid, if the file doesn't exist anymore
		unless (-e $file and -f $file) {
			$Konstrukt::Debug->debug_message("Invalid cache: File '$file' doesn't exist anymore/is not readable.") if Konstrukt::Debug::NOTICE;
			return undef;
		} else {
			my $current_date = (stat($file))[9];
			#invalid, if the current file date is newer than the date of the file used in the cached results
			if ($current_date > $date) {
				$Konstrukt::Debug->debug_message("Invalid cache: File '$file' has changed.") if Konstrukt::Debug::NOTICE;
				return undef;
			}
		}
	}
	
	#date condition
	if (exists $tree->{cache_conditions}->{date}) {
		#invalid if the given time is in the past
		if (time > $tree->{cache_conditions}->{date}) {
			$Konstrukt::Debug->debug_message("Invalid cache: Cache date expired.") if Konstrukt::Debug::NOTICE;
			return undef;
		}
	}
	
	#sql conditions
	#FEATURE: implement sql conditions
	
	#advanced sql conditions
	#FEATURE: implement advanced sql conditions
	
	#perl conditions
	foreach my $code (keys %{$tree->{cache_conditions}->{perl}}) {
		#execute the perl block
		my $result = eval $code;
		#check for errors
		if ($@) {
			#Errors in eval
			chomp($@);
			$Konstrukt::Debug->error_message("Error while executing perl condition! $@") if Konstrukt::Debug::NOTICE;
			$result = undef;
		}
		#invalid if the perl code returns false.
		if (!$result) {
			$Konstrukt::Debug->debug_message("Invalid cache: Perl-code condition returned false.") if Konstrukt::Debug::NOTICE;
			return undef;
		}
	}
	
	return 1;
}
#= /validate_cache

=head2 get_cache

Returns the cached results for a given file, if existent and valid.
Returns undef otherwise.

Will also add the path to the requested file to the stack of current directories,
B<if> there is a valid cached file available.

So you should call C<$Konstrukt::File->pop()> when you're done with the file you
read from the cache.

B<Parameters>:

=over

=item * $filename - The B<absolute> path to the file for which we want to get the cached results.

=back

=cut
sub get_cache {
	my ($self, $abs_file) = @_;

	if ($Konstrukt::Settings->get("cache/use")) { #do we want to use cached results?
		$Konstrukt::Debug->debug_message("Looking for cache for file '$abs_file'") if Konstrukt::Debug::NOTICE;
		#compose file name of the cache-file
		#get relative path
		my $cache_file = $Konstrukt::File->relative_path($abs_file);
		#append the file extension
		$cache_file .= $Konstrukt::Settings->get("cache/file_ext");
		#prefix the cache dir
		$cache_file = $self->{cache_dir} . $cache_file;
		
		if (-e $cache_file) {
			#load cache using the Storable module.
			my $tree = retrieve($cache_file);
			
			#return cached results if valid.
			if ($self->validate_cache($tree)) {
				$Konstrukt::Debug->debug_message("Using cached file '$cache_file' for file '$abs_file'") if Konstrukt::Debug::NOTICE;
				$self->prevent_caching($abs_file, 2);
				
				#the parent files must inherit the cache conditions.
				#add the conditions for this file to each file above this file.
				#file conditions:
				foreach my $file (keys %{$tree->{cache_conditions}->{file}}) {
					$self->add_condition_file($file);
				}
				#date conditions:
				if (exists $tree->{cache_conditions}->{date}) {
					$self->add_condition_date($tree->{cache_conditions}->{date});
				}
				#FEATURE: inherit sql
				#FEATURE: inherit sql-advanced
				#perl conditions:
				foreach my $code (keys %{$tree->{cache_conditions}->{perl}}) {
					$self->add_condition_perl($code);
				}
				
				#track this file
				$Konstrukt::File->push($abs_file);
				
				return $tree;
			} else {
				$Konstrukt::Debug->debug_message("Not using invalid cache for file '$abs_file'.") if Konstrukt::Debug::NOTICE;
				return undef;
			}
		} else {
			$Konstrukt::Debug->debug_message("No cache for file '$abs_file' found.") if Konstrukt::Debug::NOTICE;
			return undef;
		}
	} else {
		return undef;
		$Konstrukt::Debug->debug_message("Cache usage prevented in konstrukt.settings: cache/use") if Konstrukt::Debug::NOTICE;
	}
}
#= /get_cache

=head2 write_cache

Writes cached results for a given file to disk

B<Parameters>:

=over

=item * $file - The B<absolute> path (relative will not work) to the file for which we want to save the cached results.

=item * $tree - The result tree of the prepare-run of the parser.

=back

=cut
sub write_cache {
	my ($self, $file, $tree) = @_;

	return undef if ($self->{$file}->{prevent_caching} or not $Konstrukt::Settings->get("cache/create"));
	
	#get relative path
	my $cache_file = $Konstrukt::File->relative_path($file);
	#append the file extension
	$cache_file = $cache_file . $Konstrukt::Settings->get("cache/file_ext");
	#prefix the cache dir
	$cache_file = $self->{cache_dir} . $cache_file;
	
	#ensure that the required cache directory exists
	$Konstrukt::File->create_dirs($Konstrukt::File->extract_path($cache_file));
	
	#add a file condition for konstrukt.settings as every file depends on the settings
	my $settings_file = $Konstrukt::File->absolute_path('/konstrukt.settings');
	if (-e $settings_file and -f $settings_file) {
		my $date = (stat($settings_file))[9];
		$self->{$file}->{conditions}->{file}->{$settings_file} = $date;
		$Konstrukt::Debug->debug_message("Added condition to file '$file': 'file': $settings_file @ $date") if Konstrukt::Debug::NOTICE;
	}
		
	#link cache conditions into the tree
	$tree->{cache_conditions} = $self->{$file}->{conditions};
	
	#write the files
	if (store($tree, $cache_file)) {
		$Konstrukt::Debug->debug_message("Cache written to '$cache_file'.") if Konstrukt::Debug::NOTICE;
		return 1;
	} else {
		$Konstrukt::Debug->error_message("Couldn't store cached results to file '$cache_file'!") if Konstrukt::Debug::ERROR;
		return undef;
	}
}
#= /write_cache

=head2 delete_cache

Deletes the cache for a given file.

B<Parameters>:

=over

=item * $file - The B<absolute> path to the file for which the results have been cached

=back

=cut
sub delete_cache {
	my ($self, $file) = @_;

	return undef if not $Konstrukt::Settings->get("cache/create");

	#get relative path
	my $cache_file = $Konstrukt::File->relative_path($file);
	#append the file extension
	$cache_file = $cache_file . $Konstrukt::Settings->get("cache/file_ext");
	#prefix the cache dir
	$cache_file = $self->{cache_dir} . $cache_file;
	
	#delete the file
	if (unlink $cache_file) {
		$Konstrukt::Debug->debug_message("Cache ('$cache_file') deleted.") if Konstrukt::Debug::NOTICE;
		return 1;
	} else {
		$Konstrukt::Debug->debug_message("Couldn't delete cache file '$cache_file'!") if Konstrukt::Debug::NOTICE;
		return undef;
	}
}
#= /delete_cache

#create global object
sub BEGIN { $Konstrukt::Cache = __PACKAGE__->new() unless defined $Konstrukt::Cache; }

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::File>, L<Konstrukt::Plugin::template>, L<Konstrukt>

=cut
