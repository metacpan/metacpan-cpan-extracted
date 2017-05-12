package Log::Shiras::Unhide;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare("v0.48.0");
use strict;
use utf8;
use 5.010;
use warnings;
# [rt.cpan.org #84818]
use if $^O eq "MSWin32", "Win32";

use File::Temp;# qw(tempfile);
#~ $File::Temp::DEBUG = 1;
use File::Spec;
use Module::Runtime qw( require_module );
use Data::Dumper;
use lib
		'../../../lib',
	;

use constant IMPORT_DEBUG => 0; # Unhide Dev testing only
use constant INTERNAL_DEBUG => 0; # Unhide Dev testing only
use constant VIEW_TRANSFORM => 0; # Unhide Dev testing only
my	$my_unhide_skip_check = qr/(
		^Archive.Zip|		^attributes|		^AutoLoader|		^B\.pm|
		^B.(Op_|Deparse)|	^B.(Hooks)|			^Carp|				^Class|
		^Clone|				^common|			^Compress.Raw|		^Cwd|
		^Data.OptList|		^DateTime(?!X)|		^Devel|				^Encode|
		^Eval|				^Exporter|			^feature|			^File|
		^Filter|			^if\.pm|			^integer|			^IO.File|
		^JSON|				^List|				^Log.Shiras.Unhide|	^metaclass|
		^Module|			^Moose(?!X)|		^MooseX.Has|		^MooseX.Non|
		^MooseX.Singleton|	^MooseX.Strict|		^MooseX.Type|		^MRO|
		^namespace|			^Package|			^Params|			^parent|
		^PerlIO|			^POSIX|				^re\.pm|			^SelfLoader|
		^SetDual|			^Smart|				^Sub|				^Test2|
		^Tie|				^Text|				^Time.Local|		^Try|
		^Type|				^unicore|			^UNIVERSAL|			^utf8|
		^Variable|			^Win32|				^XML|				
		^YAML				
	)/x;
my	$run_once_hash;
our	$strip_match;
my	$temp_dir;


#########1 import   2#########3#########4#########5#########6#########7#########8#########9

sub import {
    my( $class, @args ) = @_;
	# Handle re-call
	if( $strip_match ){
		warn "------------>Trying to reload Unhide with string: $strip_match !!!!!!!!!\n" if IMPORT_DEBUG;
		_resurrector_init();
		return 1;
	}

	warn "Received args:" . join( '~|~', @args ) if @args and IMPORT_DEBUG;

	# Build a temporary directory
	$temp_dir = File::Temp->newdir( CLEANUP => 1 );

	# Handle versions
	if( $args[0] and $args[0] =~ /^v?\d+\.?\d*/ ){# Version check since import highjacks the built in
		warn "Running version check on version: $args[0]" if IMPORT_DEBUG;
		my $result = $VERSION <=> version->parse( $args[0]);
		warn "Tested against version -$VERSION- gives result: $result" if IMPORT_DEBUG;
		if( $result < 0 ){
			die "Version -$args[0]- requested for Log::Shiras::Switchboard " .
					"- the installed version is: $VERSION";
		}
		shift @args;
	}

	# Build/Load the string strippers
	my @strip_list;
	for my $flag ( @args ){
		warn "Arrived at import with flag: $flag" if IMPORT_DEBUG;
		if( $flag =~ /^:([A-Za-z]+)$/ ){# Handle text based flags
			my $strip = $1;
			push @strip_list, $strip eq 'debug' ? 'LogSD' : $strip;
		}else{
			die "Flag -$flag- passed to import Log::Shiras::Switchboard did not pass the format test.";
		}
	}

	# Implement string stripping
	if( @strip_list ){
		$strip_match = '(' . join( '|', @strip_list	) . ')';
		warn "Using Log::Shiras::Unhide-$VERSION strip_match string: $strip_match" if !$ENV{hide_warn};
		_resurrector_init();
		$ENV{loaded_filter_util_call} = 1;
		# Check for Filter::Util::Call availability
		warn "Attempting to strip leading qr/###$Log::Shiras::Unhide::strip_match/" if IMPORT_DEBUG;
		my $FILTER_MODULE = "Filter::Util::Call";
		my $require_result;
		eval{ $require_result = require_module( 'Filter::Util::Call' ) };# require_module( $FILTER_MODULE ) };#
		if( $require_result and ($require_result == 1  or $require_result eq $FILTER_MODULE) ) {
			$ENV{loaded_filter_util_call} = 1;
			# Strip the top level script
			Filter::Util::Call::filter_add(
				sub {
					my $status;
					if($status = Filter::Util::Call::filter_read() > 0 ){
						s/^(\s*)###$Log::Shiras::Unhide::strip_match\s/$1/mg;
					}
					warn "----->script scrubbed line  : $_" if VIEW_TRANSFORM;
					$status;
				}
			);
		}else{
			warn "$FILTER_MODULE required to strip the script.  The flags |" . join( ' ', @args ) .
				"| will only be implemented for 'use'd modules - ('cpan Filter::Util::Call' to install)";
		}
	}
}

#########1 Functional Startup Private Methods     5#########6#########7#########8#########9

sub _resurrector_init {
    unshift @INC, \&_resurrector_loader;
}

sub _resurrector_loader {

    my ($code, $module) = @_;

    warn "$module sent to source filter scrub\n" if INTERNAL_DEBUG;

	# Skip Stuff that isn't likely to have source filter flags
    if($module =~ $my_unhide_skip_check) {
		warn "Don't scrub |$module| (it's on the skip list) return undef" if INTERNAL_DEBUG;
        return undef;
    }else{
		warn "Scrubbing Module: $module\n" if INTERNAL_DEBUG;;
	}

    my $path = $module;
	warn "Finding the location of module: $module" if INTERNAL_DEBUG;

	# Skip unknown files
    if(!-f $module) {
          # We might have a 'use lib' statement that modified the
          # INC path, search again.
        $path = _pm_search($module);
        if(! defined $path) {
            warn "File $module not found" if INTERNAL_DEBUG;
            return undef;
        }
        warn "File $module found in $path" if INTERNAL_DEBUG;
    }

    warn "Unhiding debug in module $path" if INTERNAL_DEBUG;
	my	$fh;
	if( exists $run_once_hash->{$path} ){
		warn "No action since this is already done" if INTERNAL_DEBUG;
	}else{
		$fh = _resurrector_fh($path);
		$run_once_hash->{$path} = 1;
	}

    my $abs_path = File::Spec->rel2abs( $path );
    warn "Setting %INC entry of $module to $abs_path" if INTERNAL_DEBUG;
    $INC{$module} = $abs_path;
	eval 'use $module_copy';
    return $fh;
}

sub _pm_search {

    my($pmfile) = @_;

	warn "Reviewing: $pmfile" if INTERNAL_DEBUG;
    for(@INC) {
          # Skip subrefs
		warn "Next file: $_" if INTERNAL_DEBUG;
        next if ref($_);
		warn "Passed the ref test..." if INTERNAL_DEBUG;
        my $path = File::Spec->catfile($_, $pmfile);
        return $path if -f $path;
    }

    return undef;
}

sub _resurrector_fh {

    my( $file, ) = @_;
	warn "Resurrecting lines from file: $file" if INTERNAL_DEBUG;
	warn "with string: $strip_match" if INTERNAL_DEBUG;
    open my $start_file_handle, "<$file" or die "Cannot open $file";
	my $text;
	{
		# read the file
		local($/) = undef;
		$text = <$start_file_handle>;
		warn "Read ", length($text), " bytes from $file" if INTERNAL_DEBUG;
	}
	close $start_file_handle;

	# Transform the file
	$text =~ s/^(\s*)###$strip_match\s/$1/mg;
	warn "----->script scrubbed file:\n$text" if VIEW_TRANSFORM;
	warn "-------------------------------------------->Module Scrub complete" if INTERNAL_DEBUG;

	# Turn it back over to management by the INC loader via fh
	my( $tmp_fh ) = File::Temp->new( UNLINK => 1, DIR => $temp_dir );# ( UNLINK => 1 );
    print $tmp_fh $text;
    seek $tmp_fh, 0, 0;

	return $tmp_fh;
}

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Log::Shiras::Unhide - Unhides Log::Shiras hidden comments in @ISA

=head1 SYNOPSIS

	#!perl
	# Note this example uses the demonstration package Level1.pm Level2.pm, and Level3.pm
	use	lib	'../lib',;

	BEGIN{
		$ENV{hide_warn} = 1;
	}
	use Log::Shiras::Unhide qw( :debug :Meditation  :Health :Family );
	my	$basic = 'Nothing';
	###LogSD	$basic = 'Something';
	warn 'Found ' . $basic;
	my	$health = 'Sick';
	###Health	$health = 'Healthy';
	warn 'I am ' . $health;
	my	$wealth = 'Broke';
	###Wealth	$wealth = 'Rich';
	warn 'I am ' . $wealth;
	use Level1; # Which uses Level2 which uses Level3
	warn Level1->check_return;

	#######################################################################################
	# Synopsis Screen Output for the following conditions
	# $ENV{hide_warn} = 1;# In a BEGIN block
	# 'use Log::Shiras::Unhide qw( :debug :Meditation  :Health :Family :InternalSwitchboarD );'
	# 01: Using Log::Shiras::Unhide-v0.29_1 strip_match string: (LogSD|Meditation|Health|Family) at ../lib/Log/Shiras/Unhide.pm line 88.
	# 02: Found Something at log_shiras_unhide.pl line 8.
	# 03: I am Healthy at log_shiras_unhide.pl line 11.
	# 04: I am Broke at log_shiras_unhide.pl line 14.
	# 05: Level3 Peace uncovered - Level2 Healing uncovered - Level1 Joy uncovered at log_shiras_unhide.pl line 16.
	#######################################################################################

	#######################################################################################
	# Synopsis Screen Output for the following conditions
	# $ENV{hide_warn} = 0;
	# 'use Log::Shiras::Unhide( :debug );
	# 01: Found Something at log_shiras_unhide.pl line 8.
	# 02: I am Sick at log_shiras_unhide.pl line 11.
	# 03: I am Broke at log_shiras_unhide.pl line 14.
	# 04: Level3 LogSD uncovered - No Level2 uncovering occured - No Level1 uncovering occured at log_shiras_unhide.pl line 16.
	#######################################################################################

=head1 DESCRIPTION

This package will strip '###SomeKey' tags from your script after the 'use Log::Shiras::Unhide;'
statement.  It will also recursivly parse down through any included lower level modules as well.
If Log::Shiras::Unhide is called in some lower place it's import settings there will be
overridden by the top level call.

Since this module implements a source filter and source filters are not universally loved the
module will generally emit a warning statement when it implements the source filter.  To turn
that off you need to set $ENV{hide_warn} = 1 in a BEGIN block prior to 'use'ing
Log::Shiras::Unhide.  The SYNOPSIS includes examples of various tags that are stripped at
compile time with some examples of tags in the code that are not stripped since they are
not passed to L<import|http://perldoc.perl.org/functions/import.html>.  It is important to note
that both the synopsis and supporting modules are all stored in the 'examples' folder of this
distribution.  You can inspect the specific implemenation for Level1.pm which uses Level2.pm
which uses Level3.pm.  This demonstrates that the source filter is implemented accross the full
depth of used packages.

When Moose uses a role with the word 'with' the Unhide process is not called.  You can get
around this by calling 'use My::Role' prior to 'with My::Role'.  The role will then be consumed
(implemented) by 'with' in it's stripped state.

This class takes unashamedly from L<Log::Log4perl::Resurrector>.  Any mistakes are my
own and the genius is from there.  Log::Log4perl::Resurrector also credits the
L<Acme::Incorporated> CPAN module, written by L<chromatic|/https://metacpan.org/author/CHROMATIC>.
Of course none of it would be possible without L<Filter::Util::Call>.  Long live CPAN!

The point of using this module is to add lines that are only exposed some time.  However,
this makes it difficult to troubleshoot syntax errors in those lines using your favorite
editor or debuger when implementing the lines to begin with.  One way to resolve this is to
place two lines at the top of your code that will unhide those lines temporarily when you
are testing it and then either delelete or comment out the first line when releasing.  The
purpose of the first line is to unhide your lines for testing and the second will issue a
warning so you don't forget you are in dev mode.  An example is;

    #~ use Log::Shiras::Unhide qw( :MyCoolUnhideStrinG );
    ###MyCoolUnhideStrinG	warn "You uncovered internal logging statements for My::Cool::Package-$VERSION";

If you choose to leave line two in then you also have an indication if the module was
implemented in a stripped fashion whenever you call it.

TL;DR

This package definitly falls in the dark magic catagory and will only slow your code down.
Don't use it if you arn't willing to pay the price.  The value is all the interesting
information you receive from the exposed code.  While this does use Filter::Util::Call
to handle scrubbing the top level script. The included modules are scrubbed with a L<hook
into @INC|http://perldoc.perl.org/functions/require.html> I<search for hook on that page>
The scrubbed modules are built and loaded via temporary files built with L<File::Temp>.
In general this is a good think since File::Temp does a good job of garbage collection
the garbage collection fails when the code 'dies' or 'confesses..  If your code regularly
dies or fails while ~::Unhide is active it will leave a lot of orphaned files in the temp
directory.

This module also adds a startup hit to any processing where filtering is turned on and as
such should be used with caution, however, an attempt has been made to mitigate that by
excluding Module names matching the following regex;

	qr/(
		^Archive.Zip|		^attributes|		^AutoLoader|		^B\.pm|
		^B.(Op_|Deparse)|	^B.(Hooks)|			^Carp|				^Class|
		^Clone|				^common|			^Compress.Raw|		^Cwd|
		^Data.OptList|		^DateTime(?!X)|		^Devel|				^Encode|
		^Eval|				^Exporter|			^feature|			^File|
		^Filter|			^if\.pm|			^integer|			^IO.File|
		^JSON|				^List|				^Log.Shiras.Unhide|	^metaclass|
		^Module|			^Moose(?!X)|		^MooseX.Has|		^MooseX.Non|
		^MooseX.Singleton|	^MooseX.Strict|		^MooseX.Type|		^MRO|
		^namespace|			^Package|			^Params|			^parent|
		^PerlIO|			^POSIX|				^re\.pm|			^SelfLoader|
		^SetDual|			^Smart|				^Sub|				^Test2|
		^Tie|				^Text|				^Time.Local|		^Try|
		^Type|				^UNIVERSAL|			^utf8|				^Variable|
		^Win32|				^XML|				^YAML
	)/x;

=head2 Methods

This module does not provide any methods for the user other than what is called during 'use'.
(import) Private methods will not be documented.

=head3 import

=over

B<Definition:> perl auto calls import anytime the module is 'use'd.  In this case the import
statement will accept (first only and optional) a minimum version requirement in either v-string or
decimal input.  It will also accept any number of text strings matched to the regex [A-Za-z]+
prepended with ':'.  These strings will be treated as case sensitive targets for this module
to find and expose the line behind them using a source filter.  It will look in 'use'd modules
and strip those lines as well.  The flags are transposed to include three '#'s without the colon.
There can be more than one passed flag and all will be implemented.  An example of the stripping
implementation of imported flags are;

	qw(:FooBar :Baz) -> $line =~ s/^(\s*)###(FooBar|Baz)\s/$1/mg;

There is one special flag that is transposed

	:debug -> strips '###LogSD' (for Log Shiras Debug)

The overall package eats its own dogfood and uses module specific flags starting with 'InternaL'.
See the source for each module to understand which flag is used.

B<Accepts:> $VERSION and colon prepended strip flags

B<Returns:> nothing, but it transforms files prior to use

=back

=head1 Tags Available in CPAN

This is a list (not comprehensive) of tags embedded in packages I have released to CPAN.  Since
they require a source filter to uncover there should be minimal impact to using these packages
unless this class is used.

=over

B<:InternalSwitchboarD> - L<Log::Shiras::Switchboard>

B<:InternalTelephonE> - L<Log::Shiras::Telephone>

B<:InternalTypeSShirasFormat> - L<Log::Shiras::Types>

B<:InternalTypeSFileHash> - L<Log::Shiras::Types>

B<:InternalTypeSReportObject> - L<Log::Shiras::Types>

B<:InternalLoGShiraSTesT> - L<Log::Shiras::Test2>

B<:InternalTaPPrinT> - L<Log::Shiras::TapPrint>

B<:InternalTaPWarN> - L<Log::Shiras::TapWarn>

B<:InternalReporTCSV> - L<Log::Shiras::Report::CSVFile>

B<:InternalBuilDInstancE> - L<MooseX::ShortCut::BuildInstance>

B<:InternalExtracteD> - L<Data::Walk::Extracted>

B<:InternalExtracteDGrafT> - L<Data::Walk::Graft>

B<:InternalExtracteDClonE> - L<Data::Walk::Clone>

B<:InternalExtracteDPrinT> - L<Data::Walk::Print>

B<::InternalExtracteDPrunE> - L<Data::Walk::Prune>

B<::InternalExtracteDDispatcH> - L<Data::Walk::Extracted::Dispatch>

=back

=head1 SUPPORT

=over

L<Log-Shiras/issues|https://github.com/jandrew/Log-Shiras/issues>

=back

=head1 GLOBAL VARIABLES

=over

=item B<$ENV{hide_warn}>

The module will warn when tags are passed to it so you have visibility to Unhide
actions.  In the case where the you don't want these notifications set this
environmental variable to true.

=back

=head1 TODO

=over

B<1.> Nothing L<currently|/SUPPORT>

=back

=head1 AUTHOR

=over

=item Jed Lund

=item jandrew@cpan.org

=back

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

This software is copyrighted (c) 2014 - 2016 by Jed Lund

=head1 DEPENDENCIES

=over

L<perl 5.010|perl/5.10.0>

L<version>

L<File::Temp>

L<File::Spec>

L<Data::Dumper>

L<Filter::Util::Call>

=back

=head1 SEE ALSO

=over

L<Log::Log4perl::Resurrector>

L<Filter::Util::Call>

=back

=cut

#########1#########2 main pod documentation end  5#########6#########7#########8#########9
