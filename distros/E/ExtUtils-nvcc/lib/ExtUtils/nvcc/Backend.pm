=head1 NAME

ExtUtils::nvcc::Backend - Backend to CUDA compiler and linker wrapper for Perl's toolchain

=cut

use strict;
use warnings;

package ExtUtils::nvcc::Backend;

# For errors, of course:
use Carp qw(croak);

# To check if this is a windows perl built with gcc:
use Config;

=head1 SYNOPSIS

This is meant to be used from the command-line, invoking either the C<compiler>
or C<linker> functions like so:

 prompt> perl -MExtUtils::nvcc::Backend \
              -eExtUtils::nvcc::Backend::compiler -- \
              source.c -o test_prog

For verbosity, supply the -v flag (after the double-dash) or call the C<verbose>
function:

 prompt> perl -MExtUtils::nvcc::Backend \
              -eExtUtils::nvcc::Backend::compiler -- \
              source.c -v -o test_prog
 
 prompt> perl -MExtUtils::nvcc::Backend \
              -e"ExtUtils::nvcc::Backend::verbose;ExtUtils::nvcc::Backend::compiler"
              -- source.c -o test_prog


=head1 DESCRIPTION

This module provides functions to convert arbitrary command-line arguments to
acceptable nvcc arguments and invoke nvcc to compile or link your code.
Generally speaking, you won't need to worry about this module and should stick
with functions from L<ExtUtils::nvcc> that provide configuration options for the
common Perl toolchains.

However, if you are working on your own toolchain and need to invoke nvcc with
Perl's original build arguments, you'll probably want to use this module. The
command-line examples in the SYNOPSIS hopefully give you enough to get started
playing around.

At this point, you may be curious why I didn't just put the command-line
processing in the front-end library, L<ExtUtils::nvcc>. The reason is simple:
nvcc's behavior depends on the filename's ending (can't set it with a flag, as
far as I can tell), so filenames with CUDA code I<must> have a .cu ending.
I could subclass each of Perl's toolchains (L<Inline::C>, L<ExtUtils::MakeMaker>,
and L<Module::Build>) to accomodate CUDA, but I decided it would be better to
create this drop-in replacement for gcc. Since I have to have a layer between
the toolchains and nvcc to rename .c files to .cu files, and since I need to
process arguments, I decided to roll the whole thing into one.

=head2 compiler

The compiler function processes all arguments in C<@ARGS>, wraps them in such a
way that nvcc knows how to process them, and ensures that nvcc compiles the
source files as cuda files (even if they have a .c extension).

=cut

################################################################################
# Usage			: compiler()
# Purpose		: Process the command-line arguments and send digestable
#				: arguments to nvcc in compiler mode.
# Returns		: nothing
# Parameters	: none
# Throws		: if there are no arguments or no source files.
# Comments		: Most of the hard work is done by process_args
# See also		: linker

sub compiler {
	# First make sure that we have arguments (since I'll need a file to
	# compile, in the very least):
	die "Nothing to do! You didn't give me any arguments, not even a file!\n"
		unless @ARGV;
	
	# Check for verbosity flag. Note that $verbose may already be true if the
	# verbose() function was called.
	our $verbose = 1 if grep {$_ eq '-v'} @ARGV;
	
	# Get the nvcc args, the compiler args, and the source files:
	my ($nvcc_args, $other_args, $source_files) = process_args(@ARGV);
	
	# Unpack array refs into normal arrays
	my @nvcc_args = @$nvcc_args;
	my @other_args = @$other_args;
	my @source_files = @$source_files;
	
	# Add --x=cu if it's not already there (why would it already be there?)
	push @nvcc_args, '--x=cu' unless grep {/^-+x=?cu/} @nvcc_args;
	
	# Make sure they provided at least one source file:
	die "You must provide at least one source file\n"
		unless @source_files;
	
	# Set up the flags for the compiler arguments:
	unshift @nvcc_args, ("-Xcompiler=" . join ',', @other_args)
		if @other_args;
	
	# Run nvcc (errors will propogate with death)
	run_nvcc(@nvcc_args, @source_files);
}

=head2 linker

The linker function processes all arguments in C<@ARGS>, and invokes nvcc
as a linker with properly modified arguments.

=cut

################################################################################
# Usage			: linker()
# Purpose		: Process the command-line arguments and send digestable
#				: arguments to nvcc in linker mode.
# Returns		: nothing
# Parameters	: none
# Throws		: if there are no arguments or no source files.
# Comments		: Most of the hard work is done by process_args
# See also		: compiler

sub linker {
	# First make sure that we have arguments (since I'll need a file to
	# link, in the very least):
	die "Nothing to do! You didn't give me any arguments, not even a file!\n"
		unless @ARGV;
	
	# Check for verbosity flag. Note that $verbose may already be true if the
	# verbose() function was called.
	our $verbose = 1 if grep {$_ eq '-v'} @ARGV;
	
	# Get the nvcc args, the compiler args, and the source files:
	my ($nvcc_args, $other_args, $source_files) = process_args(@ARGV);
	
	# Unpack array refs into normal arrays
	my @nvcc_args = @$nvcc_args;
	my @other_args = @$other_args;
	my @source_files = @$source_files;
	
	# Make sure they provided at least one source file:
	die "You must provide at least one source file\n"
		unless @source_files;
	
	# Set up the flags for the compiler arguments:
	unshift @nvcc_args, ("-Xlinker=" . join ',', @other_args)
		if @other_args;
	
	# Run nvcc.
	run_nvcc(@nvcc_args, @source_files);
}

=head2 run_nvcc

Runs nvcc with the supplied list of nvcc-compatible command-line arguments,
using the L<system> Perl function.

If the system call fails, run_nvcc checks that it can find nvcc in the first
place, and croaks with one of two messages:

=over

=item nvcc encountered a problem

This message means that nvcc is in your path but the system call failed, which
means that the compile didn't like what you sent it.

=item Unable to run nvcc. Is it in your path?

This message means that nvcc cannot be found. Make sure you've installed nVidia's
toolkit and double-check your path settings.

=back

To use, try something like this:

 run_nvcc qw(my_source.cu -o my_program);

=cut

################################################################################
# Usage			: run_nvcc(@args)
# Purpose		: Run nvcc with the supplied arguments and die if errors.
# Returns		: nothing
# Parameters	: command-line arguments for nvcc
# Throws		: if nvcc fails; gives different exception if nvcc is
#				: or is not available
# Comments		: 
# See also		: compiler, linker

sub run_nvcc {
	# XXX nvcc does not play nicely with gcc on Windows. It requires cl (from
	# Visual Studio). There might be a heroic way to get around this, but the
	# obvious/historic answer (using --foreign) does not work:
	if ($Config{cc} eq 'gcc' and $Config{osname} =~ /MSWin/) {
#		push @_, '--foreign=gcc' unless grep {/^--foreign/} @_;
		warn join("\n", '', '*'x61
			, '* This will very likely not compile. You compiled your perl *'
			, '* using gcc (either with mingw, Cygwin, or Strawberry) but  *'
			, '* nvcc on Windows requires Visual Studio, i.e. cl.exe. If   *'
			, '* you have Visual Studio, this may compile, but it is       *'
			, '* unlikely to link correctly.  I will attempt, with fingers *'
			, '* crossed...                                                *'
			, '*'x61, '');
			
	}
	# See these forum discussions:
	# http://forums.nvidia.com/index.php?showtopic=78531
	# http://forums.nvidia.com/index.php?showtopic=182655
	
	# The heroic ways to get around this would be to write a wrapper around gcc
	# that accepts cl arguments, or to create a blank cl.bat and manually
	# seperate the kernel code from the host code and send only the kernel code
	# through nvcc.

	our $verbose;
	print "Running nvcc with args [[", join(']], [[', @_), "]]\n" if $verbose;

	# Run the nvcc command and return the results:
	my $results = system('nvcc', @_);

	# Make sure things didn't go bad:
	if ($results != 0) {
		# Can't find it in the path! Of course it'll fail!
		die "Unable to run nvcc. Is it in your path?\n" unless `nvcc -V`;
		
		# If nvcc is available, it must be compiler error:
		die "nvcc encountered a problem\n";
	}
}

=head2 process_args

Processes the list of supplied (gcc-style) arguments, seperating out 
nvcc-compatible arguments, and nvcc-incompatible arguments, and source file
names. The resulting lists are returned by reference in that order.

Here's a usage example:

 # Get the nvcc args, the compiler args, and the source files:
 my ($nvcc_args, $other_args, $source_files) = process_args(@ARGV);
 
 # Unpack array refs into normal arrays
 my @nvcc_args = @$nvcc_args;
 my @other_args = @$other_args;
 my @source_files = @$source_files;


=cut

################################################################################
# Usage			: ($nvcc_args, $other_args, $files) = process_args(@array)
# Purpose		: Process the command-line arguments, seperating out the nvcc-
#				: compatible options from the source file names and the other
#				: compiler options.
# Returns		: Three array references containing
#				:	- nvcc args
#				:	- other args
#				:	- file names
# Parameters	: The array of command-line options to be processed.
# Throws		: if the last argument was expecting a value, such as -o file.o
#				: but without the file.o bit.
# Comments		: The means by which this function performs its work is hackish,
#				: but I doubt it needs to be improved except possibly for
#				: legibility. Perhaps all of these options can be seperated into
#				: some text file, or put in the __DATA__ section, in more readable
#				: form and then parsed once upon loading?
# See also		: compiler, linker


sub process_args {
	my (@nvcc_args, @other_args, @source_files);
	my $include_next_arg = 0;

	foreach (@_) {
		# First check if the next arg was flagged as something to include (as
		# an argument to the previous option). 
		if ($include_next_arg) {
			push @nvcc_args, $_;
			$include_next_arg = 0;
		}
		#*#*# Ridiculous edge case for Fedora 14:
		elsif ($_ eq '-Wp,-D_FORTIFY_SOURCE=2') {
			push @nvcc_args, '-D_FORTIFY_SOURCE=2';
			# XXX - still not working for Fedora becuase the linker doesn't like
			# the atom tuning invoked in the stock perl build.
		}
		elsif (
			# check if it's an nvcc-safe flag or option, and pass it along if so:
			
			# Make sure the argument is a valid argument. These are the valid flags
			# (i.e. options that do not take values)
			m{^-(?:
				[EMcgv]|cuda|cubin|fatbin|ptx|gpu|lib|pg|extdeb|shared
				|noprof|foreign|dryrun|keep|clean|deviceemu|use_fast_math
			)$}x
			or
			m{^--(?:
				cuda|cubin|fatbin|ptx|gpu|preprocess|generate-dependencies|lib
				|profile|debug|extern-debug-info|shared|dont-use-profile|foreign
				|dryrun|verbose|keep|clean-targets|no-align-double
				|device-emulation|use_fast_math
			)$}x
			# These are valid command-line options with associated values, but which
			# don't have an = seperating the option from the value
			or
			m/^-[lLDUIoO]./
			or
			# Handle the machine regex more precisely since gcc has the -march
			# option, which can throw this off:
			m{^-m(?:32|64)$}
			or
			# Handle G flag more precisely since cl.exe likes to use -G followed
			# by letters:
			m/^-G\d/
			or
			# These are valid command-line options that have an = seperating the
			# option from the value.
			m{^-(?:
				include|isystem|odir|ccbin
				|X(?:compiler|linker|opencc|cudafe|ptxas|fatbin)
				|idp|ddp|dp|arch|code|gencode|dir|ext|int
				|maxrregcount|ftz|prec-div|prec-sqrt
			)=.+}x
			or 
			m{^--(?:
				output-file|pre-include|library|define-macro|undefine-macro
				|include-path|system-include|library-path|output-directory
				|compiler-bindir|device-debug|optimize|machine|compiler-options
				|linker-options|opencc-options|cudafe-options|ptxas-options
				|fatbin-options|input-drive-prefix|dependency-drive-prefix
				|gpu-name|gpu-code|generate-code|export-dir|extern-mode
				|intern-mode|maxrregcount|ftz|prec-div|prec-sqrt|host-compilation
				|options-file
			)=.+}x
		) {
			# Matches one of the many known flags; include in nvcc args
			push @nvcc_args, $_;
		}
		# Check if this is a bare flag that sets an option and allows a space
		# between it and the option. That indicates that the next option should
		# be passed along untouched
		# XXX - these must be verified!!!
		elsif (
			m{^-(?:
				[oDUlLImG]|include|isystem|odir|ccbin
				|X(?:compiler|linker|opencc|cudafe|ptxas|fatbin)
				|idp|ddp|dp|arch|code|gencode|dir|ext|int
				|maxrregcount|ftz|prec-div|prec-sqrt
			)$}x
			or
			m{^--(?:
				output-file|pre-include|library|define-macro|undefine-macro
				|include-path|system-include|library-path|output-directory
				|compiler-bindir|device-debug|optimize|machine|compiler-options
				|linker-options|opencc-options|cudafe-options|ptxas-options
				|fatbin-options|input-drive-prefix|dependency-drive-prefix
				|gpu-name|gpu-code|generate-code|export-dir|extern-mode
				|intern-mode|maxrregcount|ftz|prec-div|prec-sqrt|host-compilation
				|options-file
			)$}x
		) {
			# If those are found without equal signs after them, include them
			# as an nvcc_arg and indicate that the next arg should also be included
			push @nvcc_args, $_;
			$include_next_arg = 1;
		}
		# Otherwise pull it out and add it to the collection of external flags and
		# options.
		elsif (/^-/) {
			push @other_args, $_;
		}
		# If there is no dash, it's just a source filename.
		else {
			push @source_files, $_;
		}
	}
	
	# The last option should not leave the loop expecting an entry, so check for that
	# and croak if that's the case:
	croak ("Last argument [[" . $_[-1] . "]] left me expecting a value, but I didn't find one")
		if $include_next_arg;
	
	# I'm finding weird instances of mutliple -O settings. As such, I'm going
	# to insert an explicit check for it. I'm sure this could be more efficient
	my $O_found = 0;
	OPTION: for(my $i = 0; $i < $#nvcc_args; $i++) {
		next OPTION unless $nvcc_args[$i] =~ /^-O/;
		# If we already found the -O option, then splice this one out
		if ($O_found) {
			splice @nvcc_args, $i, 1;
			redo OPTION;
		}
		$O_found++;
	}

	if (our $verbose) {
		print "ExtUtils::nvcc found nvcc args [[", join(']], [[', @nvcc_args), "]]\n";
		print "ExtUtils::nvcc found other args [[", join(']], [[', @other_args), "]]\n";
		print "ExtUtils::nvcc found source files [[", join(']], [[', @source_files), "]]\n";
	}

	return (\@nvcc_args, \@other_args, \@source_files);
}

=head2 verbose

This function simply sets the package global variable C<$verbose> to a true
value, enabling verbose printouts from the compiler, linker, and other
functions. See the L</SYNOPSIS> for an example of use.

=cut

################################################################################
# Usage			: verbose()
# Purpose		: Turn on verbose output by making the global $verbose true
# Returns		: nothing
# Parameters	: none
# Throws		: nothing
# Comments		: To see how this is used, see ExtUtils::nvcc::build_args
# See also		: n/a

sub verbose {
	print "Making verbose\n";
	our $verbose = 1;
}

1;

=head1 DIAGNOSTICS

Please see L<ExtUtils::nvcc/DIAGNOSTICS> for help on error messages.

=head1 AUTHOR

I have obfuscated my email address. Simply remove the portion that would not
be sensible for a Perl developer.

David Mertens <dcmertens.perl.csharp@gmail.com>

=head1 SEE ALSO

L<ExtUtils::nvcc> and references therein

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010-2011 David Mertens. All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

This software is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut
