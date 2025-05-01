package ExtUtils::Builder::Conf;
$ExtUtils::Builder::Conf::VERSION = '0.031';
use strict;
use warnings;

use Carp;
use File::Basename qw/basename dirname/;
use File::Spec::Functions qw/catfile curdir/;
use File::Temp qw/tempfile tempdir/;

use ExtUtils::Builder::Action::Command;
use ExtUtils::Builder::Planner;

sub fail {
	my ($diag) = @_;
	my $message = defined $diag ? "OS unsupported - $diag\n" : "OS unsupported\n";
	die $message;
}

my @names = qw/include_dirs library_dirs libraries extra_compiler_flags extra_linker_flags/;

sub add_methods {
	my ($self, $planner, %args) = @_;

	for my $name (@names) {
		$planner->add_delegate($name, sub {
			my $self = shift;
			return @{ $self->{$name} // [] };
		});
		$planner->add_delegate("push_$name", sub {
			my ($self, @args) = @_;
			push @{ $self->{$name} }, @args;
		});
	}

	$planner->add_delegate(define => sub {
		my ($self, $symbol, $value) = @_;
		$self->{defines}{$symbol} = $value // '';
	});

	$planner->add_delegate(defines => sub {
		my $self = shift;
		return %{ $self->{defines} // {} };
	});

	$planner->add_delegate(write_defines => sub {
		my ($self, $to, %arguments) = @_;

		my @lines;
		for my $symbol (sort keys %{ $self->{defines} }) {
			if (not defined $self->{defines}{$symbol}) {
				push @lines, "#undef $symbol\n";
			} elsif ($self->{defines}{$symbol} eq '') {
				 push @lines, "#define $symbol\n"
			} else {
				my $value = $self->{defines}{$symbol};
				$value =~ s/\n/\\\n/g;
				push @lines, "#define $symbol $symbol\n"
			}
		}

		open my $fh, '>', $to or croak "Cannot open $to for writing: $!";
		print join "\n", @lines;
		close $fh or croak "Cannot write $to for writing: $!"
	});

	$planner->add_delegate(try_compile_run => sub {
		my ($self, %args) = @_;

		my $dir = File::Temp->newdir;

		my ($source_file, $c_file) = tempfile('try_compilerXXXX', DIR => $dir, SUFFIX => '.c');

		print $source_file $args{source};

		my $inner = $self->new_planner;
		$inner->load_extension('ExtUtils::Builder::AutoDetect::C', 0.015);

		my @include_dirs         = (@{ $args{include_dirs} // [] },         @{ $self->{include_dirs} // [] });
		my @extra_compiler_flags = (@{ $args{extra_compiler_flags} // [] }, @{ $self->{extra_compiler_flags} // [] });
		my %defines              = (%{ $args{defines} // {} },              %{ $self->{defines} // {} });

		my %compile_args = (
			extra_args   => \@extra_compiler_flags,
			include_dirs => \@include_dirs,
			defines      => \%defines,
		);

		my $basename = basename($c_file, '.c');
		my $o_file = $inner->obj_file($basename, $dir);
		$inner->compile($c_file, $o_file, %compile_args);

		my @libraries          = (@{ $args{libraries} // [] },          @{ $self->{libraries} // [] });
		my @library_dirs       = (@{ $args{library_dirs} // [] },       @{ $self->{library_dirs} // [] });
		my @extra_linker_flags = (@{ $args{extra_linker_flags} // [] }, @{ $self->{extra_linker_flags} // [] });

		my %link_args = (
			libraries    => \@libraries,
			library_dirs => \@library_dirs,
			extra_args   => \@extra_linker_flags,
		);

		my $exe_file = $inner->exe_file($basename, $dir);
		$inner->link([ $o_file ], $exe_file, %link_args);

		my $run = $args{run} // 1;

		my $target;
		if ($run) {
			$inner->create_node(
				target       => 'test',
				dependencies => [ $exe_file ],
				actions      => [
					ExtUtils::Builder::Action::Command->new(command => [ $exe_file ]),
				],
				phony        => 1,
			);

			$target = 'test';
		} else {
			$target = $exe_file;
		}

		my $result = eval { $inner->materialize->run($target, quiet => $args{quiet}); 1 };

		return !!0 if not $result;

		$self->define($args{define}) if defined $args{define};

		if ($args{push_args}) {
			for my $name (@names) {
				if (my $arg = $args{$name}) {
					push @{ $self->{$name} }, @{$arg};
				}
			}
			if ($args{defines}) {
				for my $key (keys %{$args{defines}}) {
					$self->{defines}{$key} = $args{defines}{$key};
				}
			}
		}

		return !!1;
	});

	$planner->add_delegate(assert_compile_run => sub {
		my ($self, %args) = @_;

		my $diag = delete $args{diag};
		$self->try_compile_run(%args) or fail($diag);
	});

	$planner->add_delegate(try_find_cflags_for => sub {
		my ($self, %args) = @_;

		ref(my $cflags = $args{cflags}) eq "ARRAY" or croak "Expected 'cflags' as ARRAY ref";

		foreach my $f (@$cflags) {
			ref $f eq "ARRAY" or croak "Expected 'cflags' element as ARRAY ref";

			$self->try_compile_run(%args, extra_compiler_flags => $f, push_args => 1) or next;
			return !!1;
		}

		return !!0;
	});

	$planner->add_delegate(try_find_include_dirs_for => sub {
		my ($self, %args) = @_;

		ref(my $dirs = $args{dirs}) eq "ARRAY" or croak "Expected 'dirs' as ARRAY ref";

		foreach my $d (@$dirs) {
			ref $d eq "ARRAY" or croak "Expected 'dirs' element as ARRAY ref";

			$self->try_compile_run(%args, include_dirs => $d, push_args => 1) or next;
			return !!1;
		}

		return !!0;
	});

	$planner->add_delegate(try_find_libraries_for => sub {
		my ($self, %args) = @_;

		ref(my $libs = $args{libs}) eq "ARRAY" or croak "Expected 'libs' as ARRAY ref";

		foreach my $libraries (@$libs) {
			$self->try_compile_run(%args, libraries => $libraries, push_args => 1) or next;
			return !!1;
		}

		return !!0;
	});

	$planner->add_delegate(try_find_library_dirs_for => sub {
		my ($self, %args) = @_;

		ref(my $dirs = $args{dirs}) eq "ARRAY" or croak "Expected 'dirs' as ARRAY ref";

		foreach my $d (@$dirs) {
			ref $d eq "ARRAY" or croak "Expected 'dirs' element as ARRAY ref";

			$self->try_compile_run(%args, library_dirs => $d, push_args => 1) or next;
			return !!1;
		}

		return !!0;
	});

	foreach my $name (qw/find_cflags_for find_libraries_for find_include_dirs_for find_library_dirs_for/) {
		my $trymethod = "try_$name";

		$planner->add_delegate($name, sub {
			my ($self, %args) = @_;

			my $diag = delete $args{diag};
			$self->$trymethod(%args) or fail($diag);
		});
	};
}

1;

# ABSTRACT: Configure-time utilities for using C headers, libraries, or OS features

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Builder::Conf - Configure-time utilities for using C headers, libraries, or OS features

=head1 VERSION

version 0.031

=head1 SYNOPSIS

 load_extension("ExtUtils::Builder::Conf");
 assert_compile_run(diag => 'no PF_MOONLASER', source => <<'EOF');
 #include <stdio.h>
 #include <sys/socket.h>
 int main(int argc, char *argv[]) {
   printf("PF_MOONLASER is %d\n", PF_MOONLASER);
   return 0;
 }
 EOF

=head1 DESCRIPTION

Often Perl modules are written to wrap functionality found in existing C headers, libraries, or to use OS-specific features. It is useful to check for the existance of these requirements before attempting to actually build the module.

Objects in this class provide an extension around L<ExtUtils::Builder::Compiler> to simplify the creation of a F<.c> file, compiling, linking and running it, to test if a certain feature is present.

It may also be necessary to search for the correct library to link against, or for the right include directories to find header files in. This class also provides assistance here.

=head1 DELEGATES

=head2 try_compile_run

 $success = try_compile_run(%args);

Try to compile, link, and execute a C program whose source is given. Returns true if the program compiled and linked, and exited successfully. Returns false if any of these steps fail.

Takes the following named arguments:

=over 4

=item source => STRING

The source code of the C program to try compiling, building, and running.

=item defines => HASH

Optional. A set of defines to be passed to the compiler.

=item extra_compiler_flags => ARRAY

Optional. If specified, pass extra flags to the compiler.

=item extra_linker_flags => ARRAY

Optional. If specified, pass extra flags to the linker.

=item include_dirs => ARRAY

Optional. If specified, pass extra include dirs to the compiler.

=item libraries => ARRAY

Optional. If specified, pass extra libaries to the linker.

=item library_dirs => ARRAY

Optional. If specified, pass extra libary directories to the linker.

=item quiet => BOOL

This makes C<try_compile_run> run quietly.

=item define => STRING

Optional. If specified, then the named symbol will be defined if the program ran successfully. This will either on the C compiler commandline (by passing an option C<-DI<SYMBOL>>), in the C<defines> method, or via the C<write_defines> method.

=item push_args => BOOL

If true, any of C<extra_compiler_flags>, C<extra_linker_flags>, C<include_dirs>, C<libraries>, C<library_dirs> or C<defines> will have its value pushed on success (e.g. C<push_include_dirs> for the C<include_dirs> argument).

=back

=head2 assert_compile_run

 assert_compile_run(%args);

Calls C<try_compile_run>. If it fails, die with an C<OS unsupported> message. Useful to call from F<Build.PL> or F<Makefile.PL>.

Takes one extra optional argument:

=over 4

=item diag => STRING

If present, this string will be appended to the failure message if one is generated. It may provide more useful information to the user on why the OS is unsupported.

=back

=head2 try_find_cflags_for

 $success = try_find_cflags_for(%args);

Try to compile, link and execute the given source, using extra compiler flags.

When a usable combination is found, the flags are stored in the object for use in further compile operations, or returned by C<extra_compiler_flags>. The method then returns true.

If no usable combination is found, it returns false.

Takes the following extra arguments:

=over 4

=item source => STRING

Source code to compile

=item cflags => ARRAY of ARRAYs

Gives a list of sets of flags. Each set of flags should be strings in its own array reference.

=item define => STRING

Optional. If specified, then the named symbol will be defined if the program ran successfully. This will either on the C compiler commandline (by passing an option C<-DI<SYMBOL>>), in the C<defines> method, or via the C<write_defines> method.

=back

=head2 try_find_include_dirs_for

 $success = try_find_include_dirs_for(%args);

Try to compile, link and execute the given source, using extra include directories.

When a usable combination is found, the directories required are stored in the object for use in further compile operations, or returned by C<include_dirs>. The method then returns true.

If no a usable combination is found, it returns false.

Takes the following arguments:

=over 4

=item source => STRING

Source code to compile

=item dirs => ARRAY of ARRAYs

Gives a list of sets of dirs. Each set of dirs should be strings in its own array reference.

=item define => STRING

Optional. If specified, then the named symbol will be defined if the program ran successfully. This will either on the C compiler commandline (by passing an option C<-DI<SYMBOL>>), in the C<defines> method, or via the C<write_defines> method.

=back

=head2 try_find_libraries_for

 $success = try_find_libraries_for(%args);

Try to compile, link and execute the given source, when linked against a given set of extra libraries.

When a usable combination is found, the libraries required are stored in the object for use in further link operations, or returned by C<libraries>. The method then returns true.

If no usable combination is found, it returns false.

Takes the following arguments:

=over 4

=item source => STRING

Source code to compile

=item libs => ARRAY of STRINGs

Gives a list of sets of libraries. Each set of libraries should be space-separated.

=item define => STRING

Optional. If specified, then the named symbol will be defined if the program ran successfully. This will either on the C compiler commandline (by passing an option C<-DI<SYMBOL>>), in the C<defines> method, or via the C<write_defines> method.

=back

=head2 try_find_library_dirs_for

 $success = try_find_library_dirs_for(%args);

Try to compile, link and execute the given source, using extra library directories.

When a usable combination is found, the directories required are stored in the object for use in further compile operations, or returned by C<library_dirs>. The method then returns true.

If no a usable combination is found, it returns false.

Takes the following arguments:

=over 4

=item source => STRING

Source code to compile

=item dirs => ARRAY of ARRAYs

Gives a list of sets of dirs. Each set of dirs should be strings in its own array reference.

=item define => STRING

Optional. If specified, then the named symbol will be defined if the program ran successfully. This will either on the C compiler commandline (by passing an option C<-DI<SYMBOL>>), in the C<defines> method, or via the C<write_defines> method.

=back

=head2 find_cflags_for

 find_cflags_for(%args);

=head2 find_include_dirs_for

 find_include_dirs_for(%args);

=head2 find_libraries_for

 find_libraries_for(%args);

Calls C<try_find_cflags_for>, C<try_find_include_dirs_for> or C<try_find_libraries_for> respectively. If it fails, die with an C<OS unsupported> message.

Each method takes one extra optional argument:

=over 4

=item diag => STRING

If present, this string will be appended to the failure message if one is generated. It may provide more useful information to the user on why the OS is unsupported.

=back

=head2 include_dirs

 $dirs = include_dirs;

Returns the currently-configured include directories as an array.

=head2 library_dirs

 $dirs = library_dirs;

Returns the currently-configured library directories as an array.

=head2 libraries

 $libs = libraries;

Returns the currently-configured libraries as an array.

=head2 extra_compiler_flags

 $flags = extra_compiler_flags;

Returns the currently-configured extra compiler flags as an array.

=head2 extra_linker_flags

 $flags = extra_linker_flags;

Returns the currently-configured extra linker flags as an array.

=head2 push_include_dirs

 push_include_dirs(@dirs);

Adds more include directories

=head2 push_library_dirs

 push_library_dirs(@dirs);

Adds more library directories

=head2 push_libraries

 push_libraries(@libs);

Adds more libraries

=head2 push_extra_compiler_flags

 push_extra_compiler_flags(@flags);

Adds more compiler flags

=head2 push_extra_linker_flags

 push_extra_linker_flags(@flags);

Adds more linker flags

=head2 define

 define($symbol);

Adds a new defined symbol directly; either by appending to the compiler flags or writing it into the defines file.

=head1 EXAMPLES

=head2 Socket Libraries

Some operating systems provide the BSD sockets API in their primary F<libc>. Others keep it in a separate library which should be linked against. The following example demonstrates how this would be handled.

 find_libraries_for(
   diag => 'no socket()',
   libs => [ [], ['socket', 'nsl' ]],
   source => q[
 #include <sys/socket.h>
 int main(int argc, char *argv) {
  int fd = socket(PF_INET, SOCK_STREAM, 0);
  if (fd < 0)
    return 1;
  return 0;
 }
 ]);

=head2 Testing For Optional Features

Sometimes a function or ability may be optionally provided by the OS, or you may wish your module to be useable when only partial support is provided, without requiring it all to be present. In these cases it is traditional to detect the presence of this optional feature in the F<Build.PL> script, and define a symbol to declare this fact if it is found. The XS code can then use this symbol to select between differing implementations. For example, the F<Build.PL>:

 try_compile_run(
   define => 'HAVE_MANGO',
   source => <<'EOF');
 #include <mango.h>
 #include <unistd.h>
 int main(void) {
  if (mango() != 0)
    exit(1);
  exit(0);
 }
 EOF

If the C code compiles and runs successfully, and exits with a true status, the symbol C<HAVE_MANGO> will be defined on the compiler commandline. This allows the XS code to detect it, for example

   int
   mango()
     CODE:
   #ifdef HAVE_MANGO
       RETVAL = mango();
   #else
       croak("mango() not implemented");
   #endif
     OUTPUT:
       RETVAL

This module will then still compile even if the operating system lacks this particular function. Trying to invoke the function at runtime will simply throw an exception.

=head2 Linux Kernel Headers

Operating systems built on top of the F<Linux> kernel often share a looser association with their kernel version than most other operating systems. It may be the case that the running kernel is newer, containing more features, than the distribution's F<libc> headers would believe. In such circumstances it can be difficult to make use of new socket options, C<ioctl()>s, etc.. without having the constants that define them and their parameter structures, because the relevant header files are not visible to the compiler. In this case, there may be little choice but to pull in some of the kernel header files, which will provide the required constants and structures.

The Linux kernel headers can be found using the F</lib/modules> directory. A fragment in F<Build.PL> like the following, may be appropriate.

   chomp(my $uname_r = `uname -r);

   my @dirs = (
      [],
      [ "/lib/modules/$uname_r/source/include" ],
   );

   find_include_dirs_for(
      diag => "no PF_MOONLASER",
      dirs => \@dirs,
      source => <<'EOF');
   #include <sys/socket.h>
   #include <moon/laser.h>
   int family = PF_MOONLASER;
   struct laserwl lwl;
   int main(int argc, char *argv[]) {
     return 0;
   }
   EOF

This fragment will first try to compile the program as it stands, hoping that the F<libc> headers will be sufficient. If it fails, it will then try including the kernel headers, which should make the constant and structure visible, allowing the program to compile.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
