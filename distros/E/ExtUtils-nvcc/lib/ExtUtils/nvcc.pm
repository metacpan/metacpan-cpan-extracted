=head1 NAME

ExtUtils::nvcc - CUDA compiler and linker wrapper for Perl's toolchain

=cut

use strict;
use warnings;

# These are necessary for Module::Build to work simply:
package ExtUtils::nvcc;
use vars qw($VERSION);

=head1 VERSION

This documentation explains the use of ExtUtils::nvcc version 0.03.

=cut

$VERSION = '0.03';

# For errors, of course:
use Carp qw(croak);

=head1 SYNOPSES

I have included a fully working example for L<Inline::C>, as well as other
partial examples for L<ExtUtils::MakeMaker> and L<Module::Build>.

=head2 Inline::C

 #!/usr/bin/perl
 use strict;
 use warnings;
 
 use ExtUtils::nvcc;
 # Here's the magic sauce
 use Inline C => DATA => ExtUtils::nvcc::Inline;
 
 # The rest of this is just a working example
 
 # Generate a series of 100 sequential values and pack them
 # as an array of floats:
 my $data = pack('f*', 1..100); 
 
 # Call the Perl-callable wrapper to the CUDA kernel:
 cuda_test($data);
 
 # Print the results
 print "Got ", join (', ', unpack('f*', $data)), "\n";
 
 END {
     # I am having trouble with memory leaks. This messgae
     # indicates that the segmentation fault occurrs after
     # the end of the script's execution.
     print "Really done!\n";
 }
 
 __END__
 
 __C__
 
 // This is a very simple CUDA kernel that triples the value of the
 // global data associated with the location at threadIdx.x. NOTE: this
 // is a particularly good example of BAD programming - it should be
 // more defensive. It is just a proof of concept, to show that you can
 // indeed write CUDA kernels using Inline::C.
 
 __global__ void triple(float * data_g) {
     data_g[threadIdx.x] *= 3;
 }
 
 // NOTE: Do not make such a kernel a regular habit. Generally, copying
 // data to and from the device is very, very slow (compared with all
 // other CUDA operations). This is just a proof of concept.
 
 void cuda_test(char * input) {
     // Inline::C knows how to massage a Perl scalar into a char
     // array (pointer), which I can easily cast as a float pointer:
     float * data = (float * ) input;
     
     // Allocate the memory of the device:
     float * data_d;
     unsigned int data_bytes = sizeof(float) * 100;
     cudaMalloc(&data_d, data_bytes);
  
     // Copy the host memory to the device:
     cudaMemcpy(data_d, data, data_bytes, cudaMemcpyHostToDevice);
     
     // Print a status indicator and execuate the kernel
     printf("Trippling values via CUDA\n");
 
     // Execute the kernel:
     triple <<<1, 100>>>(data_d);
     
     // Copy the contents back to the Perl scalar:
     cudaMemcpy(data, data_d, data_bytes, cudaMemcpyDeviceToHost);
     
     // Free the device memory
     cudaFree(data_d);
 }

=head2 ExtUtils::MakeMaker

 # In your Makefile.PL:
 use ExtUtils::MakeMaker;
 use ExtUtils::nvcc;
 
 WriteMakefile(
     # ... other options ...
     ExtUtils::nvcc::EUMM,
 );

=head2 Module::Build

 # In your Build.PL file:
 use Module::Build;
 use ExtUtils::nvcc;
 
 my $build = Module::Build->new(
     # ... other options ...
     config => {ExtUtils::nvcc::MB},
 );


=head1 DESCRIPTION

This module serves as the configuration front-end to a Perl module that knows
how to translate arbitrary command-line arguments into nvcc-digestable
command-line arguments. This means you can use nvcc to compile CUDA code for
Perl. I discuss that functionality in L<ExtUtils::nvcc::Backend>.

This module functions for your day-to-day use of ExtUtils::nvcc (if there is
such a thing as day-to-day use of a toolchain). It provides a few functions that
generate the configuration keys necessary to get L<Inline::C>,
L<ExtUtils::MakeMaker>, and L<Module::Build> to use L<ExtUtils::nvcc::Backend>
to compile your CUDA code. The functions you would use are, respectively,
C<ExtUtils::nvcc::Inline>, C<ExtUtils::nvcc::EUMM>, and C<ExtUtils::nvcc::MB>.

=head2 Inline

If you want to use CUDA in your C<Inline::C> scripts, you simply need to add
the proper configuration options. Those options are generated for you (in an
alternating key => value list) by the function C<ExtUtils::nvcc::Inline>:

 use ExtUtils::nvcc;
 use Inline C => DATA => ExtUtils::nvcc::Inline;

This is equivalent to the following:

 use Inline C => DATA =>
   CC => "$^X -MExtUtils::nvcc::Backend -eExtUtils::nvcc::Backend::compiler --",
   LD => "$^X -MExtUtils::nvcc::Backend -eExtUtils::nvcc::Backend::linker --";

And now you understand why you would use the function that generates these
options for you. If you find that you are having trouble, you can get more
verbose output by calling C<Inline> with the C<verbose> key, as discussed under
L</Optional Arguments>:

 use Inline C => DATA => ExtUtils::nvcc::Inline('verbose');

=cut

################################################################################
# Usage			: Inline([args])
# Purpose		: Returns the key => value pairs appropriate for Inline to use
#				: ExtUtils::nvcc::Backend as a compiler and linker wrapper.
# Returns		: Compiler and linker key => value pairs
# Parameters	: arguments (simple options) that control how
#				: ExtUtils::nvcc::Backend runs
# Throws		: nothing
# Comments		: none
# See also		: EUMM, MB, build_args

sub Inline {
	return	CC => build_args('compiler', @_),
			LD => build_args('linker', @_);
}

=head2 EUMM

If you want to use CUDA in your XS files and you use L<ExtUtils::MakeMaker> to handle your
distribution, ExtUtils::nvcc provides a function to specify your compiler and linker so
that they use ExtUtils::nvcc to properly handle the compiler and linker arguments for you.
The function is called C<ExtUtils::nvcc::EUMM>. You would place it directly into your
options for C<WriteMakefile> like so:

 use ExtUtils::nvcc;
 WriteMakefile(
     # ... other options ...
     ExtUtils::nvcc::EUMM,
 );

This is equivalent to the following:

 WriteMakefile(
     # ... other options ...
     CC => "$^X -MExtUtils::nvcc -eExtUtils::nvcc::compiler --",
     LD => "$^X -MExtUtils::nvcc -eExtUtils::nvcc::linker --",
 );

If you want more verbose output, you can call C<ExtUtils::nvcc::EUMM> with the
C<verbose> argument, as discussed under L</Optional Arguments>:

 use ExtUtils::nvcc;
 WriteMakefile(
     # ... other options ...
     ExtUtils::nvcc::EUMM('verbose'),
 );

=cut

################################################################################
# Usage			: EUMM([args])
# Purpose		: Returns the key => value pairs appropriate for
#				: ExtUtils::MakeMaker to use ExtUtils::nvcc::Backend as a
#				: compiler and linker wrapper.
# Returns		: Compiler and linker key => value pairs
# Parameters	: arguments (simple options) that control how
#				: ExtUtils::nvcc::Backend runs
# Throws		: nothing
# Comments		: none
# See also		: Inline, MB, build_args

sub EUMM {
	return	CC => build_args('compiler', @_),
			LD => build_args('linker', @_);
}

=head2 MB

If you want to use CUDA in your XS files and you use C<Module::Build> to manage your
distribution, ExtUtils::nvcc provides a simple function that will help set up your
build configuration. As with the others, it returns a useful key => value collection,
this time applicable to the config anonymous hash that goes into Module::Build's
constructor. Here's how you should use it:

 use ExtUtils::nvcc;
 my $build = Module::Build->new(
     # ... other options ...
     config => {ExtUtils::nvcc::MB},
 );

If you run into compile trouble and you suspect it has to do with how ExtUtils::nvcc
is processing your compiler's command-line arguments, you can request a verbose
output by calling C<MB> with the argument C<verbose>, as discussed under
L</Optional Arguments>:

 use ExtUtils::nvcc;
 my $build = Module::Build->new(
     # ... other options ...
     config => {ExtUtils::nvcc::MB('verbose')},
 );

=cut

################################################################################
# Usage			: MB([args])
# Purpose		: Returns the key => value pairs appropriate for Module::Build
#				: to use ExtUtils::nvcc::Backend as a compiler and linker
#				: wrapper.
# Returns		: Compiler and linker key => value pairs
# Parameters	: arguments (simple options) that control how
#				: ExtUtils::nvcc::Backend runs
# Throws		: nothing
# Comments		: none
# See also		: Inline, EUMM, build_args

sub MB {
	return	cc => build_args('compiler', @_),
			ld => build_args('linker', @_);

}

=head2 Optional Arguments

I would hope that if there's a problem during compilation, it's due to a mistake
in your code and not this module. However, this toolchain is still quite new and
rather untested, so errors may sometimes arise due to L<ExtUtils::nvcc::Backend>
mis-handling an argument. Verbosity, and possibly other arguments in the future,
can be sent to L<ExtUtils::nvcc::Backend> to help you sort it all out. All you
need to do is supply the word 'verbose' as an argument to L</Inline>, L</EUMM>,
or L</MB>.

=begin more-arguments

Here is the full list of arguments and their affects:
 
 Option     Description
 ----------------------------------------------
 verbose    make ExtUtils::nvcc::Backend chatty

=end more-arguments

=cut

our %arg_for = qw(
	verbose			ExtUtils::nvcc::Backend::verbose
);

=head2 build_args

This is not really a user-level function, but I feel obligated to document it.
It is used by the user-level toolchain configuration functions C<Inline>,
C<EUMM>, and C<MB> to convert the mode (compiler or linker) along with the
options into the command-line needed to
invoke ExtUtils::nvcc::Backend as a compiler or linker. If you're not working on
ExtUtils::nvcc itself, don't worry about this function.

=cut

################################################################################
# Usage			: build_args($mode, [@args])
# Purpose		: Constructs the command-line invocation of
#				: ExtUtils::nvcc::Backend given the mode and
#				: user-level arguments
# Returns		: A string with the command-line invocants
# Parameters	: $mode, either 'compiler' or 'linker'
#				: @args, user-level arguments to MB, EUMM, and Inline
# Throws		: if a bade mode or an invalid option is provided
# Comments		: For example, an output of this function with no args could be
#				:    perl -MExtUtils::nvcc::Backend -e"ExtUtils::nvcc::Backend::linker" --
#				: This also checks for current use of blib and adds it if found
# See also		: verbosity, Inline, EUMM, MB, %args_for

sub build_args {
	my $mode = shift;
	croak("Bad mode; must be either 'compiler' or 'linker'")
		unless $mode eq 'compiler' or $mode eq 'linker';
	
	# Inject -Mblib if this script was invoked with blib:
	my $args = $^X;
	if (grep /blib/, @INC) {
		use Cwd;
		$args .= ' -Mblib="' . getcwd . '"';
	}
	

	# Go through and build the argument list, checking the arguments along the
	# way. If there are bad arguments, collect a full list and croak them all.

	$args .= qq{ -MExtUtils::nvcc::Backend -e"};
	my @bad_args;
	foreach (@_) {
		if (exists $arg_for{$_}) {
			$args .= $arg_for{$_} . ';';
		}
		else {
			push @bad_args, $_;
		}
	}
	croak('Bad arguments: ' . join(', ', @bad_args)) if @bad_args;
	return $args . qq{ExtUtils::nvcc::Backend::$mode" --};
}

1;

=head1 WINDOWS ISSUES

Windows usage presents a couple of difficulties, as described in this section.

=head2 Visual Studio Only

Unfortunately, nVidia's compiler wrapper (nvcc) only supports the use of cl.exe
on Windows. This means that Cygwin and Strawberry Perl users are out of luck for
using ExtUtils::nvcc. I attempted to install Visual Studio alongside Strawberry
Perl, but the Perl toolchain passes along the gcc flags, which cl.exe does not
like. There may be a way to fiddle with the configuration a bit, but I wouldn't
hold my breath.

An alternative may be to create a drop-in cl.exe replacement which parses the
arguments for cl.exe and invokes gcc. If that's not reverse-engineering
reverse-engineered, I don't know what is.

=head2 Visual Studio Command Prompt

When you install Visual Studio (as of Visual Studio 2010), you will get a Start
Menu entry for Visual Studio Command Prompt. You should run your build processes
(i.e. cpan) from one of these command prompts. Among other things, this command
prompt sets all of the necessary environment variables to ensure that the
compiler can be found, and that the compiler can find all the necessary
libraries. This may or may not be necessary for using nvcc directly, but it is
certainly is necessary for the rest of the Perl toolchain to find cl.exe and
friends.


=head1 DIAGNOSTICS

ExtUtils::nvcc could croak for a number of reasons. To keep things concise, I
list both the front-end and the back-end diagnostic messages here. I begin with
the front-end errors, errors that ExtUtils::nvcc will throw at you:

=over

=item Bad mode; must be either 'compiler' or 'linker'

This is an internal error that gets thrown when C<build_args> is called with
an invalid mode. If you see this, either you are C<build_args> yourself, and
not supplying the string 'compiler' or 'linker', or there is an internal error.
In the latter case, please report the error to the bug-tracker listed below.

=item Bad arguments: <bad-arg-1>, <bad-arg-2>, ...

This message means that you supplied an invalid argument to one of the
user-level functions C<Inline>, C<EUMM>, or C<MB>. Check your spelling and
capitalization against L</Optional Arguments> discussed above.

=back

These are the back-end errors, errors that L<ExtUtils::nvcc::Backend> will have:

=over

=item Last argument [[<arg>]] left me expecting a value, but I didn't find one

Apparently you (or the build system) supplied a list of arguments to
L<ExtUtils::nvcc::Backend> ending with an option that expects an argument.
For example, the C<-o> option is a very common option that indicates the output
filename from the compilation or linking process. If you supply a C<-o> option
to L<ExtUtils::nvcc::Backend>, it expects the following argument to be the
output filename. If this is your last argument and you don't supply a filename,
this error will be thrown.

If the last argument is complete, to the best of your knowledge, it could be
that L<ExtUtils::nvcc::Backend> mis-parsed your command-line arguments in other
ways. You should enable verbose output and study that for more details.

=item Nothing to do! You didn't give me any arguments, not even a file!

This means that you somehow invoked L<ExtUtils::nvcc::Backend> without a single
argument. Double-check your command-line invocation and try again.

=item You must provide at least one source file

Somehow you invoked L<ExtUtils::nvcc::Backend> without a source file listed.
Double-check your command-line invocation and try again.

=item Unable to run nvcc. Is it in your path?

This error means that nvcc cannot be found (or more precisely, that nvcc -V
does not give a meaningful result). As the error suggests, be sure to check
that nVidia's nvcc is in your path. You will also get this error if you do not
have nvcc installed. In that case, install nVidia's CUDA toolkit and you should
be ready to go.

=item nvcc encountered a problem

In this case, nvcc attempted to compile or link your code and failed. Look over
the compiler/linker output for clues as to where your code went wrong. My guess
is that there is a compiler error in your code.

However, it is possible that the Backend is out-of-touch with your version of
nvcc, and it (for example) passed an nvcc argument through to your compiler.
Your compiler won't like that and it will likely complain. In that case, file
a bug report, as discussed in L</BUGS AND LIMITATIONS>.

=back

=head1 DEPENDENCIES

This toolchain requires that you have the following pieces:

=over

=item nVidia's CUDA toolkit

You must have nVidia's CUDA toolkit in order to compile CUDA code. This module
ultimately calls nvcc to perform the compilation; it cannot compile your CUDA
code itself. Furthermore, nvcc requires a C++ compiler, so you'll need to be
sure you have one of those. The CUDA toolkit is only available for a handful of
systems, and this module does not support building CUDA-capable modules for
other systems. For example, the latest version of Ubuntu or Fedora may not be
supported, and as of this time of writing Gentoo and Arch Linux (and many
others) have no support at all.

=item A Perl development environment

You will need to have access to the Perl development toolchain, either
L<ExtUtils::MakeMaker> or L<Module::Build>. (Note L<Inline> uses EU::MM on the
backend.) If you are in an environment in which you do not have these tools,
you will be able to use L<ExtUtils::nvcc::Backend>, but you'll have a hard time
tying anything into Perl.

=item gcc (Linux) or Visual Studio (Windows)

The nvcc compiler only supports gcc on Linux, and cl.exe on Windows. You cannot
specify an alternative compiler.

=back

=head1 BUGS, LIMITATIONS

The code for ExtUtils::nvcc is hosted at github, but please file bugs at
L<https://rt.cpan.org/Public/Bug/Report.html?Queue=ExtUtils-nvcc>.

A major maintainability problem is that the Backend has a very ad-hoc parsing
scheme that is not systematically tested at the moment. It would be better, I
think, to query nvcc at runtime for arguments that it accepts so that there
could never be a version skew for the arguments that the Backend parses and the
arguments that nvcc accepts. However, nvcc does not have an easily parsed
representation of its arguments, so this is probably equally troublesome.

For Windows users, a major issue is that nvcc only works with Microsoft's
compiler, cl.exe, on Windows machines. As such, C<ExtUtils::nvcc> will not
operate correctly under Cygwin or Strawberry Perl. I would like to remedy
this situation. Please let me know if you find a work-around for Strawberry
Perl or Cygwin.

Furthermore, C<ExtUtils::nvcc> doesn't even work with Windows at the moment.
This module was developed on Ubuntu and I have only dabbled with the Windows
build system. It is giving trouble, and any help would be much appreciated.

=head1 TESTING

In the few months that ExtUtils::nvcc has been quietly sitting on CPAN, it
has received zero test reports. That's because there isn't a single automated
tester that has nvcc installed. If you try to install this module, please
report your success or failure at cpantesters. The process is a bit involved,
but your test reports will help to turn this piddly little thing into a
useful tool! You can read more here: L<http://wiki.cpantesters.org/wiki/QuickStart>.

=head1 TODO

The only major missing piece at this time is a true test of the build
process using ExtUtils::MakeMake and/or Module::Build. I would like to
add tests of these to the test suite, but it'll take some thought to
figure out how to invoke the build system from inside the test suite.

=head1 AUTHOR

I have obfuscated my email address. Simply remove the portion that would not
be sensible for a Perl developer.

David Mertens <dcmertens.perl.csharp@gmail.com>

=head1 SEE ALSO

The source code for this project is on github at L<github.com/run4flat/perl_nvcc>.

This is intended to be part of the toolchain to enable L<CUDA>. A minimalistic
Perl module for CUDA is in the works and can be found at
L<github.com/run4flat/perl-CUDA-Minimal>.

You can read more about CUDA at nVidia's website:
L<http://www.nvidia.com/object/cuda_home_new.html>

An alternative to embedding CUDA in C or XS is L<KappaCUDA>.

Other important and related toolchain modules include L<Inline::C>,
L<Module::Build>, L<ExtUtils::MakeMaker>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010-2011 David Mertens. All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

This software is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut
