package ExtUtils::CFeatureTest;
our $VERSION= '0.002'; # VERSION
use strict;
use warnings;
use IO::Handle;
use ExtUtils::CBuilder;

=head1 NAME

ExtUtils::CFeatureTest - Test a host for available C language features and libraries

=head1 SYNOPSIS

  use "./inc";
  use ExtUtils::CFeatureTest;
  my $ftest= ExtUtils::CFeatureTest->new;
  
  # Test if a header exists.  If found, set macro HAVE_STDBOOL_H, and all
  # compilation attempts below this will automatically include the header.
  $ftest->header('stdbool.h');
  
  # Compile and run the snippet of code, and set HAVE_BOOL if it succeeds.
  $ftest->feature(HAVE_BOOL => 'bool x= true; return x? 0 : 1;');
  
  # Compile and run the snippet of code, and try various permutations of
  # headers and libs until it works.  This one is required, so warn and
  # exit if it isn't available.
  $ftest->require_feature(HAVE_LIBSSL =>
    'unsigned char buf[1]; return RAND_bytes(buf, 1) == 1? 0 : 1;',
    { h => 'openssl/rand.h', pkg_config => ['libressl'] },
    { h => 'openssl/rand.h', pkg_config => ['openssl'] },
    { h => 'openssl/rand.h', -l => [ 'ssl', 'crypto' ] });
  
  # Export all the things we learned into a header to be included by all
  # source units in the project.
  $ftest->write_config_header('MyModule_config.h');
  
  # Export the compiler flags into ExtUtils::Depends to be used and/or
  # installed for other modules to use.
  my $dep= ExtUtils::Depends->new('MyModule');
  $ftest->export_deps($dep);

=head1 DESCRIPTION

This is a module for testing aspects the C compiler and available libraries prior to building an
XS distribution.  It borrows many ideas from L<ExtUtils::CChecker> and L<Devel::CheckLib>.
The main difference is that instead of simply building a list of compiler flags, it
builds an entire header file for you that helps remove boilerplate from your other C files.

For example, a traditional approach is to test for a C header like C<stdint.h>, and if found
define a preprocessor macro like C<HAVE_STDINT_H>, and then in your source code you write

  #ifdef HAVE_STDINT_H
  #include <stdint.h>
  #endif

This results in a bulky list of C<< -DHAVE_SOME_FEATURE >> options to your compiler, and also
a lot of boilerplate within each C file.

This module eliminates the middleman by generating a header of its own with everything it
learned from feature detection I<and> the workarounds your Makefile.PL have added based on that
knowledge.  For the above example, if it finds C<stdint.h> it adds the include statement
directly to the generated header, saving you the C<#ifdef> boilerplate and avoiding any
commandline arguments for the compiler.

=head1 INTEGRATION

I strongly recommend copying C<CFeatureTest> into your distribution as
C<< inc/ExtUtils/CFeatureTest.pm >> rather than installing a system-wide copy.  This ensures
that future changes to CFeatureTest don't break existing distributions.  While I don't change
APIs frivolously, I'm not committing to full back-compat until it reaches version 1.0.

To this end, C<CFeatureTest> is a single file with no non-core dependencies (since C<perl 5.9.3>
which added L<ExtUtils::CBuilder>) so literally all you need to do is copy one file into your
distribution as C<< inc/ExtUtils/CFeatureTest.pm >> and add C<< use lib "./inc" >> to the top
of your C<Makefile.PL>.

See the C<Makefile.PL> of L<Crypt::SecretBuffer> for a complete example.

=head1 CONSTRUCTOR

=head2 new

  $test= ExtUtils::CFeatureTest->new(%attributes);

=cut

sub new {
   my $self= bless {}, shift;
   $self->{verbose}= $ENV{EXTUTILS_CFEATURETEST_VERBOSE} || 0;
   $self->{emit_tty}= -t \*STDOUT;
   $self->{emit_unicode}= $self->{emit_tty}
      && grep(defined($_) && /UTF-?8/i, @ENV{qw( LANG LC_ALL LC_CTYPE )})
      && ($^O ne 'MSWin32' || $ENV{WT_SESSION} || $ENV{TERM});
   $self->{config_includes}= '';
   $self->{config_include_set}= {};
   $self->{config_pkg_set}= {};
   $self->{config_macros}= {};
   $self->{config_local}= '';
   $self->{last_err}= '';
   $self->{last_compile_output}= '';
   $self->{last_exec_output}= '';
   $self->{include_dirs}= [];
   $self->{extra_compiler_flags}= [];
   $self->{extra_linker_flags}= [];
   @_ & 1 and die "Expected even-length list of attribute => value";
   for (my $i= 0; $i < @_; $i+= 2) {
      my ($attr, $val)= @_[$i,$i+1];
      my $setter= "_set_$attr";
      $self->$setter($val);
   }
   $self;
}

=head1 ATTRIBUTES

=head2 verbose

If true, emit diagnostics, including output from the compiler.  The default comes from
C<$ENV{EXTUTILS_CFEATURETEST_VERBOSE}>.  A future version might make this into an integer of
"log levels".

=head2 emit_tty

If true, enable fancy colorized output.  The default is based on whether STDOUT is a terminal.
This also triggers for MSWin32 consoles, but the latest versions of the Windows console do
support TTY color codes.

=head2 emit_unicode

If true, enable fancy unicode indicators in the output.  The default is true if any locale
environment variables contain 'utf-8'.

=cut

sub verbose { @_ > 1? shift->_set_verbose(@_) : $_[0]{verbose} }
sub _set_verbose { $_[0]{verbose}= !!$_[1]; $_[0] }

sub emit_tty { @_ > 1? shift->_set_emit_tty(@_) : $_[0]{emit_tty} }
sub _set_emit_tty { $_[0]{emit_tty}= !!$_[1]; $_[0] }

sub emit_unicode { @_ > 1? shift->_set_emit_unicode(@_) : $_[0]{emit_unicode} }
sub _set_emit_unicode { $_[0]{emit_unicode}= !!$_[1]; $_[0] }

my ($green, $red, $reset, $uchar_check, $uchar_x)
   = ("\e[32m","\e[31m","\e[0m","\x{2713}","\x{2715}");

sub _emit {
   my ($self, $handle, $msg)= @_;
   # This method is not efficient, but not a hot code path so not worth optimizing.
   $msg =~ s/\e\[.*?m//g
      unless $self->{emit_tty};
   if ($self->{emit_unicode} && utf8::is_utf8($msg)) {
      require PerlIO;
      utf8::encode($msg)
         unless grep /utf-?8/i, PerlIO::get_layers($handle);
   }
   $handle->print($msg."\n");
}

=head2 config_header_text

The C source code generated so far by the detection methods, including the L</config_macros>
and L</config_local>.  The config source code is structured as

  /* attribute config_includes */
  #include <header1>
  #include <header2>
  ...
  /* attribute config_macros */
  #define HAS_HEADER1
  #define HAS_HEADER2
  ...
  /* attribute config_local */
  ...

This structure ensures that system headers are included before the pollution from your local
macros and other symbols.

=head2 config_includes

The C code of C<#include> statements generated so far by the detection methods.
Also any code you added with L</append_config_includes>.

=head2 config_include_set

A hashref where each key is a header name which has been added to C<config_includes>.
(The hashref is used as a cache, not a declaration that drives code generation)

=head2 config_pkg_set

A hashref of the C<pkg-config> library names which have been added.  Read-only.
(The hashref is used as a cache, not a declaration that drives code generation)

=head2 config_macros

A hashref where each key is a C macro name and the value is the definition of the macro.
You may modify this hashref to define or remove macros.
These will always come after the text of C<config_includes> so as not to pollute global
namespace before system headers get included.  If you wish to define a macro I<before> the
inclusion of system headers (such as C<_GNU_SOURCE> or C<WIN32_LEAN_AND_MEAN>) use
L</append_config_includes>.

=head2 config_local

A string of custom C code to append following C<config_includes> and C<config_macros>.
This is intended for code you want defined for your entire project but don't want defined until
after all system headers are included.  See L</append_config_local>.

=cut

sub config_header_text {
   my $self= shift;
   return $self->config_includes
        . $self->_config_macros_text
        . $self->config_local;
}

sub config_includes { @_ > 1? shift->_set_config_includes(@_) : $_[0]{config_includes} }
sub _set_config_includes {
   ref $_[1] and die "config_includes must be a string of C code";
   $_[0]{config_includes}= $_[1];
   $_[0]
}

sub config_include_set { $_[0]{config_include_set} }
sub config_pkg_set { $_[0]{config_pkg_set} }

sub config_macros { @_ > 1? shift->_set_config_macros(@_) : $_[0]{config_macros} }
sub _set_config_macros {
   ref $_[1] eq 'HASH' or die "config_macros must be a hashref";
   $_[0]{config_macros}= $_[1];
   $_[0]
}
sub _config_macros_text {
   my $self= shift;
   my $code= '';
   my $macros= $self->config_macros;
   for (sort keys %$macros) {
      if (defined(my $val= $macros->{$_})) {
         $val =~ s/\n\z//;    # automatically add the backslashes on multiline macros
         $val =~ s/\n/\\\n/g;
         $code .= "#define $_ $val\n";
      } else {
         $code .= "#define $_\n";
      }
   }
   return $code;
}

sub config_local { @_ > 1? shift->_set_config_local(@_) : $_[0]{config_local} }
sub _set_config_local {
   ref $_[1] and die "config_local must be a string of C code";
   $_[0]{config_local}= $_[1];
   $_[0]
}

=head2 cbuilder

An instance of L<ExtUtils::CBuilder> (a core module in modern perls), lazy-built.

=head2 last_err

The exception generated by the last call to L</compile_and_run>, if any.

=head2 last_compile_output

The stdout/stderr generated by the last invocation of compiler and/or linker.

=head2 last_exec_output

The stdout/stderr generated by the last execution of a built executable.

=cut

sub cbuilder {
   @_ > 1? shift->_set_cbuilder(@_)
   : ($_[0]{cbuilder} ||= ExtUtils::CBuilder->new)
}
sub _set_cbuilder { $_[0]{cbuilder}= $_[1]; $_[0] }

sub last_err { @_ > 1? shift->_set_last_err(@_) : $_[0]{last_err} }
sub _set_last_err { $_[0]{last_err}= $_[1]; $_[0] }

sub last_compile_output { @_ > 1? shift->_set_last_compile_output(@_) : $_[0]{last_compile_output} }
sub _set_last_compile_output { $_[0]{last_compile_output}= $_[1]; $_[0] }

sub last_exec_output { @_ > 1? shift->_set_last_exec_output(@_) : $_[0]{last_exec_output} }
sub _set_last_exec_output { $_[0]{last_exec_output}= $_[1]; $_[0] }

=head2 include_dirs

An arrayref of directories to be passed to the compiler as C<< -Ipath >>.

=head2 extra_compiler_flags

An arrayref of command line arguments to pass to the C compiler.

=head2 extra_linker_flags

An arrayref of command line arguments to pass to the C linker.

=cut

sub include_dirs { @_ > 1? shift->_set_include_dirs(@_) : $_[0]{include_dirs} }
sub _set_include_dirs { my $self= shift; $self->{include_dirs}= [ ref $_[0] eq 'ARRAY'? @{$_[0]} : @_ ]; $self }

sub extra_compiler_flags { @_ > 1? shift->_set_extra_compiler_flags(@_) : $_[0]{extra_compiler_flags} }
sub _set_extra_compiler_flags { my $self= shift; $self->{extra_compiler_flags}= [ ref $_[0] eq 'ARRAY'? @{$_[0]} : @_ ]; $self }

sub extra_linker_flags { @_ > 1? shift->_set_extra_linker_flags(@_) : $_[0]{extra_linker_flags} }
sub _set_extra_linker_flags { my $self= shift; $self->{extra_linker_flags}= [ ref $_[0] eq 'ARRAY'? @{$_[0]} : @_ ]; $self }

sub _spew {
   my $fname= shift;
   open my $fh, '>', $fname or die "open($fname): $!";
   $fh->print(@_) or die "write($fname): $!";
   $fh->close or die "close($fname): $!";
}

sub _maybe_list {
   ref $_[0] eq 'ARRAY'? (grep length, @{ $_[0] })
   : defined $_[0] && length $_[0]? ( $_[0] )
   : ()
}

sub _capture_output {
   my ($self, $code)= @_;
   my $outfile= "ftest-$$-" . ++$self->{seq} . "-out.txt";
   open my $out_fh, '+>', $outfile or die "open($outfile): $!";
   open my $stdout_save, ">&STDOUT" or die "dup(STDOUT): $!";
   open my $stderr_save, ">&STDERR" or die "dup(STDERR): $!";
   open STDOUT, ">&" . fileno $out_fh or die "Can't redirect STDOUT: $!";
   open STDERR, ">&" . fileno $out_fh or die "Can't redirect STDERR: $!";
   my ($ex, $out_txt);
   eval { $code->(); 1 }
      or $ex= $@;
   # restore handles
   open STDERR, ">&" . fileno $stderr_save or die "Can't restore STDERR: $!";
   open STDOUT, ">&" . fileno $stdout_save or die "Can't restore STDOUT: $!";
   # Slurp contents of compiler output
   seek($out_fh, 0, 0);
   { local $/; $out_txt= <$out_fh> }
   close $out_fh;
   unlink $outfile;
   $out_txt .= "\n".$ex if defined $ex;
   return $out_txt;
}

sub _capture_cmd {
   my ($self, @cmd)= @_;
   my $wstat;
   my $out= $self->_capture_output(sub { system { $cmd[0] } @cmd; $wstat= $?; });
   return ($wstat, $out);
}

=head1 METHODS

=head2 compile_and_run

  $bool= $ftest->compile_and_run($code, %options);
  # %options:
  #   include_dirs => [ ... ],
  #   extra_compiler_flags => [ ... ],
  #   extra_linker_flags => [ ... ],

Attempt to compile and execute the specified C program text.  The compiler will be given all
include paths, compiler flags, and linker flags that have been detected so far, in addition to
the ones that you pass to this method.  C<$code> must be the complete program; the accumulated
configuration code in L</config_header_text> is not automatically applied.

Returns boolean of whether it succeeded (meaning compile, link, and executable all exited with
code 0).
The compiler output is stored in attribute L</last_compile_output>, perl exceptions are stored
in attribute L</last_err>, and output of the text executable is stored in L</last_exec_output>.
Nothing is printed to stdout/stderr.

=cut

sub compile_and_run {
   my ($self, $code, %opts)= @_;
   $self->{last_err}= '';
   $self->{last_exec_output}= '';
   $self->{last_compile_output}= '';
   for (qw( include_dirs extra_compiler_flags extra_linker_flags )) {
      $opts{$_}= [ @{ $self->$_ }, @{ $opts{$_} || [] } ];
   }

   my $srcfile= "ftest-$$-" . ++$self->{seq} . ".c";
   _spew($srcfile, $code);
   my ($objfile, $exefile, $err, $success);

   # Compiler is rather noisy.  Redirect output to temp file.
   $self->{last_compile_output}= $self->_capture_output(sub {
      $success= eval {
         $err= "compile failed";
         $objfile= $self->cbuilder->compile(%opts, source => $srcfile);
         $err= "link failed";
         $exefile= $self->cbuilder->link_executable(%opts, objects => $objfile);
      };
      chomp($self->{last_err}= $@? "$err: $@" : $err) unless $success;
   });
   if ($success) {
      $self->{last_exec_output}= $self->_capture_output(sub {
         $success= eval {
            $err= "execute";
            system("./$exefile");
            if ($?) { $err= "execute failed: ".($? & 0xFF? "signal $?" : "exit code ".($? >> 8)) }
            $? == 0
         };
         chomp($self->{last_err}= $@? "$err: $@" : $err) unless $success;
      });
   }
   unlink grep defined, $srcfile, $objfile, $exefile;
   return $success;
}

=head2 header

  $ftest->header('some_header.h', @test_inc_paths);

Attempt to compile a simple C program that includes the named header.  The first compilation
attempt will use the existing include path, and if not found, it will try compilation again
for each element of C<@test_inc_paths> added to the include path until one succeeds.

If any attempt succeeds, append the C<#include> directive to the L</config_includes> attribute
and define macro C<HAVE_SOME_HEADER_H> in attribute L</config_macros>.

This means all future tests will automatically have this header loaded, if it exists.

Returns a boolean of whether it added the header.

=head2 require_header

Like L</header>, but warn+exit if it fails.  i.e. the header is mandatory for the build.

=cut

sub header {
   my ($self, $header, @paths)= @_;
   return 1 if $self->{config_include_set}{$header};
   (my $macro= 'HAVE_'.uc($header)) =~ s/\W/_/g;
   my $code= <<END_C;
@{[ $self->config_includes ]}
#include <$header>
@{[ $self->_config_macros_text ]}
@{[ $self->config_local ]}
int main(int argc, char **argv) { return 0; }
END_C
   for my $path (undef, @paths) {
      if ($self->compile_and_run($code, (defined $path? (include_dirs => [$path]) : ()))) {
         # It worked.  Add the header to our list, and add a macro for having detected it.
         $self->{config_includes} .= "#include <$header>\n";
         $self->{config_include_set}{$header}= 1;
         push @{$self->{include_dirs}}, $path if defined $path;
         $self->{config_macros}{$macro}= 1;
         $self->_emit(\*STDOUT, "Found $header".(defined $path? " at $path" : " in existing include dirs"));
         $self->_emit(\*STDOUT, ($self->emit_unicode? "$uchar_check " : '+') . "$green$macro$reset");
         return 1;
      }
   }
   $self->_emit(\*STDOUT, ($self->emit_unicode? "$uchar_x " : '-') . "$red$macro$reset");
   return 0;
}

sub require_header {
   my ($self, $header, @args)= @_;
   my $success= $self->header($header, @args);
   if (!$success) {
      STDOUT->flush;
      warn $self->last_err;
      warn $self->last_compile_output;
      $self->_emit(\*STDERR, "${red}Can't proceed without $header$reset");
      exit 1;
   }
   1;
}

=head2 feature

  $bool= $ftest->feature(MACRO_NAME => $c_code_snippet,
    { # one possible set of options known to work
      h                    => \@header_names,
      include_dirs         => \@paths,
      extra_compiler_flags => \@commandline_options,
      extra_linker_flags   => \@commandline_options,
      pkg_config           => \@module_names,
    },
    { # another possible set of options known to work
      # using convenient aliases for the attributes above
      h => $header, -I => $path, -D => $macro, -L => $path, -l => $lib
    },
    ... # as many attempts as you want
  );

This attempts to compile and execute C<$c_code_snippet>.  It attempts compilation once without
any configuration changes, and then attempts again using each of a supplied list of
configurations until one succeeds.  You can specify the configurations using full attribute
names, or with shorthand aliases that resemble the gcc command line flags.

Again, note that any compiler/linker flags are I<appended> to any others that were previously
detected (the attributes L</include_dirs>, L</extra_compiler_flags>, and L</extra_linker_flags>)
and the generated source code automatically includes the L</config_header_text> that
CFeatureTest is in the process of building.

Also note that the C<pkg_config> option attempts to load I<all> of the C<@module_names> and
proceeds to attempt compilation if I<any> of them were found.

=head2 require_feature

Like L</feature>, but warn+exit if it fails.  i.e. the feature is mandatory for the build.

=cut

sub feature {
   my ($self, $macro, $code, @permutations)= @_;
   # Single function name? just take the address of it
   if ($code =~ /^\w+\z/) {
      # Compilers might optimize a simple "fn != NULL" to a constant expression and then not
      # even link it.  Compare to another pointer like argv hoping they can't optimize that.
      $code= "void *fn= (void *) $code; return fn != argv? 0 : 1;";
   }
   # Bare snippet without 'main' function wrapping it?
   unless ($code =~ /int main\(/) {
      # Is it a snippet belonging inside main?
      if ($code =~ /return [^{}]+;/) {
         $code= "int main(int argc, char **argv) { $code }\n";
      } else {
         $code= "$code\nint main(int argc, char **argv) { return 0; }\n";
      }
   }
   $self->_emit(\*STDOUT, "Test for feature $macro");
   for my $p (undef, @permutations) {
      my $prefix= $self->config_includes;
      my (@headers, @pkg_found);
      if ($p) {
         # clone $p before making changes
         $p= { %$p };
         $p->{$_}= [ _maybe_list($p->{$_}) ]
            for qw( include_dirs extra_compiler_flags extra_linker_flags );
         # optional header attempts
         @headers= grep !$self->{config_include_set}{$_}, _maybe_list(delete $p->{h});
         $prefix .= "#include <$_>\n" for @headers;
         # expand convenient aliases
         push @{ $p->{include_dirs} }, _maybe_list(delete $p->{-I})
            if defined $p->{-I};
         push @{ $p->{extra_compiler_flags} }, map "-D$_", _maybe_list(delete $p->{-D})
            if defined $p->{-D};
         push @{ $p->{extra_linker_flags} }, map "-L$_", _maybe_list(delete $p->{-L})
            if defined $p->{-L};
         push @{ $p->{extra_linker_flags} }, map "-l$_", _maybe_list(delete $p->{-l})
            if defined $p->{-l};
         # If any pkg_config modules were requested, add those to the options.
         # If none are available, skip the compilation attempt.
         if (my @mod= _maybe_list(delete $p->{pkg_config})) {
            my $msg= "  pkg-config";
            for (@mod) {
               if ($self->get_pkg_config($_, $p)) {
                  push @pkg_found, $_;
                  $msg .= " $green$_$reset (found)";
               } else {
                  $msg .= " $red$_$reset (not found)";
               }
            }
            $self->_emit(\*STDOUT, $msg);
            next unless @pkg_found;
         }
      }
      $prefix .= $self->_config_macros_text . $self->config_local;
      if ($p) {
         my @show_options;
         for (sort keys %$p) {
            my $val= $p->{$_};
            next unless defined $val;
            if (ref $val eq 'ARRAY') {
               next unless @$val;
               $val= join ' ', @$val;
            }
            next unless length $val;
            push @show_options, "$_=$val";
         }
         if (@show_options) {
            print "  test with $_\n" for shift @show_options;
            print "            $_\n" for @show_options;
         }
      }
      if ($self->compile_and_run($prefix.$code, $p? (%$p) : ())) {
         if ($p) {
            for (qw( include_dirs extra_compiler_flags extra_linker_flags )) {
               push @{$self->{$_}}, @{$p->{$_}} if $p->{$_};
            }
            for (@headers) {
               $self->{config_includes} .= "#include <$_>\n";
               $self->{config_include_set}{$_}= 1;
            }
         }
         if (defined $macro && length $macro) {
            $self->{config_macros}{$macro}= 1;
            $self->_emit(\*STDOUT, ($self->emit_unicode? "$uchar_check " : '+') . "$green$macro$reset");
         }
         return 1;
      } elsif ($self->verbose) {
         my $msg= $self->last_err."\n".$self->last_compile_output."\n";
         $msg =~ s/^/    /mg;
         print $msg;
      }
   }
   $self->_emit(\*STDOUT, ($self->emit_unicode? "$uchar_x " : '-') . "$red$macro$reset")
      if defined $macro && length $macro;
   return 0;
}

sub require_feature {
   my ($self, $macro, @args)= @_;
   my $success= $self->feature($macro, @args);
   if (!$success) {
      STDOUT->flush;
      warn $self->last_err;
      warn $self->last_compile_output;
      warn "Can't proceed without $macro";
      exit 1;
   }
   1;
}

=head2 get_pkg_config

  $bool= $ftest->get_pkg_config($package_name, \%options_out);
  $bool= $ftest->get_pkg_config(\@package_names, \%options_out);

For a named package, retrieve the C<--cflags> and C<--libs> and store the values into
C<%options_out>.
If the package is not installed or C<pkg-config> executable is missing, this returns false.
You can customize the C<pkg-config> executable with C<$ENV{PKG_CONFIG}>.

If you specify an array of names to check, B<all> will be attempted, and success will be
determined by whether B<any> of them existed.  This is intended for cases where you have one
specific package in mind, but it may be available as an alternate name or divided into
sub-modules depending on the OS distribution.

=cut

my $have_pkg_config;
sub get_pkg_config {
   my ($self, $modules, $options_out)= @_;
   my $pc = 'pkg-config';
   if (defined $ENV{PKG_CONFIG}) {
      # Disallow shell metacharacters in executable name, just in case.
      ($pc= $ENV{PKG_CONFIG}) !~ /[\0-\x1F"'\$\%{}\x7F]/
         or die "Unsafe value of PKG_CONFIG environment variable";
   }
   #print " called get_pkg_config($modules)\n";
   unless (defined $have_pkg_config) {
      # only warn about it once
      my ($wstat, $out)= $self->_capture_cmd($pc, '--version');
      chomp($have_pkg_config= $wstat == 0? $out : '');
      print "$pc not found (override with PKG_CONFIG=path)\n"
         unless $have_pkg_config;
   }
   my $success;
   if ($have_pkg_config) {
      for my $m (_maybe_list($modules)) {
         if (!exists $self->{config_pkg_set}{$m}) {
            # Existence check first
            if ((system { $pc } $pc, '--exists', $m) == 0) {
               my ($cf_wstat, $cflags) = $self->_capture_cmd($pc, '--cflags', $m);
               my ($l_wstat, $libs)    = $self->_capture_cmd($pc, '--libs', $m);
               chomp($cflags, $libs);
               if ($self->verbose || $cf_wstat || $l_wstat) {
                  print "  pkg-config module $m cflags: ".($cf_wstat? 'FAILED: ':'')."$cflags\n";
                  print "  pkg-config module $m libs  : ".($l_wstat? 'FAILED: ':'')."$libs\n";
               }
               $self->{config_pkg_set}{$m}{cflags}= $cf_wstat? '' : $cflags;
               $self->{config_pkg_set}{$m}{libs}= $l_wstat? '' : $libs;
            }
            else {
               # warn once if module not on this host
               print "  pkg-config module $m not found\n" if $self->verbose;
               $self->{config_pkg_set}{$m}= undef;
            }
         }
         if (my $cfg= $self->{config_pkg_set}{$m}) {
            for (_shellwords($cfg->{cflags})) {
               if (/^-I(.+)$/) { push @{$options_out->{include_dirs}}, $1; }
               else { push @{$options_out->{extra_compiler_flags}}, $_; }
            }
            push @{$options_out->{extra_linker_flags}}, _shellwords($cfg->{libs})
               if length $cfg->{libs};
            $success= 1;
         }
      }
   }
   return $success;
}

# Extract a list of program arguments from a commandline string.
# This doesn't fully respect shell rules, just enough for what pkg-config is likely
# to emit for the --cflags or --libs.  Win32 would throw a wrench into proper shell
# word parsing, anyway.
sub _shellwords {
   my ($s)= @_;
   my @out;
   while (defined $s && length $s) {
      $s =~ s/^\s+//;
      last unless length $s;
      if ($s =~ s/^"((?:\\.|[^"])*)"//) {
         (my $w=$1)=~s/\\"/"/g; $w=~s/\\\\/\\/g;
         push @out, $w;
      }
      elsif ($s =~ s/^'((?:\\.|[^'])*)'//) {
         (my $w=$1)=~s/\\'/'/g; $w=~s/\\\\/\\/g;
         push @out, $w;
      }
      else {
         $s =~ s/^([^\s]+)// or last;
         push @out, $1;
      }
   }
   return @out;
}

=head2 append_config_includes

  $ftest->append_config_includes(@c_code);

Append custom lines of C code to the L</config_includes> attribute.
Each element of C<@c_code> will be given a trailing newline if it lacks one.

=head2 append_config_local

  $ftest->append_config_local(@c_code);

Append custom lines of C code to the L</config_local> attribute.
Each element of C<@c_code> will be given a trailing newline if it lacks one.

=cut

sub append_config_includes {
   my ($self, @c_code)= @_;
   s/\n?\z/\n/ for @c_code;
   $self->{config_includes} .= join '', @c_code;
   $self;
}

sub append_config_local {
   my ($self, @c_code)= @_;
   s/\n?\z/\n/ for @c_code;
   $self->{config_local} .= join '', @c_code;
   $self;
}

=head2 write_config_header

  $ftest->write_config_header($filename);

Write the contents of L</config_header_text> to a file, also with a standard include-guard of

  #ifndef FILENAME_H
  #define FILENAME_H
  ...
  #endif

You should choose a filename distinct to your project.

=cut

sub write_config_header {
   my ($self, $fname)= @_;
   (my $guard_macro= uc($fname)) =~ s/\W/_/g;
   _spew($fname,
      "#ifndef $guard_macro\n"
      ."#define $guard_macro\n\n"
      .$self->config_header_text
      ."\n#endif\n");
   print "Wrote config to $fname\n";
   return $self;
}

=head2 export_deps

  $ftest->export_deps($extutils_depends_obj);

Export the include paths, compiler flags, and linker flags required for using this into the
L<ExtUtils::Depends> object.

=cut

sub export_deps {
   my ($self, $extutils_depends)= @_;
   my @inc= (
      map("-I$_", grep length, @{ $self->{include_dirs} }),
      @{ $self->{extra_compiler_flags} },
   );
   $extutils_depends->set_inc(join ' ', @inc) if @inc;
   $extutils_depends->set_libs(join ' ', @{$self->{extra_linker_flags}})
      if @{$self->{extra_linker_flags}};
   return $self;
}

1;

__END__

=head1 SEE ALSO

=over

=item L<ExtUtils::CChecker>

=item L<Devel::CheckLib>

=back

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025-2026 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under the same terms as the
Perl 5 programming language system itself.

