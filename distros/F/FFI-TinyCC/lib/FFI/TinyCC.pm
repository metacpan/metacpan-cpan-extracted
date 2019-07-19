package FFI::TinyCC;

use strict;
use warnings;
use 5.008001;
use Config;
use FFI::Platypus;
use FFI::Platypus::Memory qw( malloc free );
use Carp qw( croak carp );
use File::Spec;
use File::ShareDir::Dist qw( dist_share );

# ABSTRACT: Tiny C Compiler for FFI
our $VERSION = '0.29'; # VERSION


sub _dlext ()
{
  $^O eq 'MSWin32' ? 'dll' : $Config{dlext};
}

our $ffi = FFI::Platypus->new;
$ffi->lib(
  File::Spec->catfile(dist_share( 'FFI-TinyCC' ), 'libtcc.' . _dlext)
);

$ffi->custom_type( tcc_t => {
  perl_to_native => sub {
    $_[0]->{handle},
  },
  
  native_to_perl => sub {
    {
      handle   => $_[0],
      relocate => 0,
      error    => [],
    };
  },

});

do {
  my %output_type = qw(
    memory 0
    exe    1
    dll    2
    obj    3
  );

  $ffi->custom_type( output_t => {
    native_type => 'int',
    perl_to_native => sub { $output_type{$_[0]} },
  });
};

$ffi->type('int' => 'error_t');
$ffi->type('(opaque,string)->void' => 'error_handler_t');

$ffi->attach([tcc_new             => '_new']             => []                                     => 'tcc_t');
$ffi->attach([tcc_delete          => '_delete']          => ['tcc_t']                              => 'void');
$ffi->attach([tcc_set_error_func  => '_set_error_func']  => ['tcc_t', 'opaque', 'error_handler_t'] => 'void');
$ffi->attach([tcc_add_symbol      => '_add_symbol']      => ['tcc_t', 'string', 'opaque']          => 'int');
$ffi->attach([tcc_get_symbol      => '_get_symbol']      => ['tcc_t', 'string']                    => 'opaque');
$ffi->attach([tcc_relocate        => '_relocate']        => ['tcc_t', 'opaque']                    => 'int');
$ffi->attach([tcc_run             => '_run']             => ['tcc_t', 'int', 'opaque']             => 'int');

sub _method ($;@)
{
  my($name, @args) = @_;
  $ffi->attach(["tcc_$name" => "_$name"] => ['tcc_t', @args] => 'error_t');
  eval  '# line '. __LINE__ . ' "' . __FILE__ . qq("\n) .qq{
    sub $name
    {
      my \$r = _$name (\@_);
      die FFI::TinyCC::Exception->new(\$_[0]) if \$r == -1;
      \$_[0];
    }
  };
  die $@ if $@;
}


sub new
{
  my($class, %opt) = @_;

  my $self = bless _new(), $class;
  
  $self->{error_cb} = $ffi->closure(sub {
    push @{ $self->{error} }, $_[1];
  });
  _set_error_func($self, undef, $self->{error_cb});
  
  if($^O eq 'MSWin32')
  {
    require File::Basename;
    require File::Spec;
    my $path = File::Spec->catdir(File::Basename::dirname($ffi->lib), 'lib');
    $self->add_library_path($path);
  }
  
  $self->{no_free_store} = 1 if $opt{_no_free_store};
  
  $self;
}

sub _error
{
  my($self, $msg) = @_;
  push @{ $self->{error} }, $msg;
  $self;
}

if(defined ${^GLOBAL_PHASE})
{
  *DESTROY = sub
  {
    my($self) = @_;
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
    _delete($self);
    # TODO: should we do this?
    free($self->{store});
  }
}
else
{
  require Devel::GlobalDestruction;
  *DESTROY = sub
  {
    my($self) = @_;
    return if Devel::GlobalDestruction::in_global_destruction();
    _delete($self);
    # TODO: should we do this?
    free($self->{store});
  }
}


_method set_options => qw( string );


_method add_file => qw( string );


_method compile_string => qw( string );


sub add_symbol
{
  my($self, $name, $ptr) = @_;
  my $r;
  $r = _add_symbol($self, $name, $ptr);
  die FFI::TinyCC::Exception->new($self) if $r == -1;
  $self;
}


sub detect_sysinclude_path
{
  my($self) = @_;
  
  my @path_list;
  
  if($^O eq 'MSWin32')
  {
    require File::Spec;
    push @path_list, File::Spec->catdir(dist_share('Alien-TinyCC'), 'include');
  }
  elsif($Config{incpth})
  {
    require Alien::TinyCC;
    require File::Spec;
    push @path_list, File::Spec->catdir(Alien::TinyCC->libtcc_library_path, qw( tcc include ));
    push @path_list, split /\s+/, $Config{incpth};
  }
  elsif($Config{ccname} eq 'gcc')
  {
    require File::Temp;
    my($fh, $filename) = File::Temp::tempfile( "tryXXXX", SUFFIX => '.c', UNLINK => 1 );
    close $fh;
    
    my @lines = `$Config{cpp} -v $filename 2>&1`;
    
    shift @lines while defined $lines[0] && $lines[0] !~ /^#include </;
    shift @lines;
    pop @lines while defined $lines[-1] && $lines[-1] !~ /^End of search /;
    pop @lines;
    
    croak "Cannot detect sysinclude path" unless @lines;
    
    require Alien::TinyCC;
    require File::Spec;
    
    push @path_list, File::Spec->catdir(Alien::TinyCC->libtcc_library_path, qw( tcc include ));
    push @path_list, map { chomp; s/^ //; $_ } @lines;
  }    
  else
  {
    croak "Cannot detect sysinclude path";
  }
  
  croak "Cannot detect sysinclude path" unless grep { -d $_ } @path_list;
  
  $self->add_sysinclude_path($_) for @path_list;
  
  @path_list;
}



_method add_include_path => qw( string );


_method add_sysinclude_path => qw( string );


_method set_lib_path => qw( string );


$ffi->attach([tcc_define_symbol=>'define_symbol'] => ['tcc_t', 'string', 'string'] => 'void');


$ffi->attach([tcc_undefine_symbol=>'undefine_symbol'] => ['tcc_t', 'string', 'string'] => 'void');


_method set_output_type => qw( output_t );


_method add_library => qw( string );


_method add_library_path => qw( string );


sub run
{
  my($self, @args) = @_;
  
  croak "unable to use run method after get_symbol" if $self->{relocate};
  
  my $argc = scalar @args;
  my @c_strings = map { "$_\0" } @args;
  my $ptrs = pack 'P' x $argc, @c_strings;
  my $argv = unpack('L!', pack('P', $ptrs));

  my $r = _run($self, $argc, $argv);
  die FFI::TinyCC::Exception->new($self) if $r == -1;
  $r;  
}


sub get_symbol
{
  my($self, $symbol_name) = @_;
  
  unless($self->{relocate})
  {
    my $size = _relocate($self, undef);
    $self->{store} = malloc($size);
    my $r = _relocate($self, $self->{store});
    die FFI::TinyCC::Exception->new($self) if $r == -1;
    $self->{relocate} = 1;
  }
  _get_symbol($self, $symbol_name);
}


_method output_file => qw( string );

package
  FFI::TinyCC::Exception;

use overload '""' => sub {
  my $self = shift;
  if(@{ $self->{fault} } == 2)
  {
    join(' ', $self->as_string, 
      at => $self->{fault}->[0], 
      line => $self->{fault}->[1],
    );
  }
  else
  {
    $self->as_string . "\n";
  }
};
use overload fallback => 1;

sub new
{
  my($class, $tcc) = @_;
  
  my @errors = @{ $tcc->{error} };
  $tcc->{errors} = [];
  my @stack;
  my @fault;
  
  my $i=2;
  while(my @frame = caller($i++))
  {
    push @stack, \@frame;
    if(@fault == 0 && $frame[0] !~ /^FFI::TinyCC/)
    {
      @fault = ($frame[1], $frame[2]);
    }
  }
  
  my $self = bless {
    errors => \@errors,
    stack  => \@stack,
    fault  => \@fault,
  }, $class;
  
  $self;
}

sub errors { shift->{errors} }

sub as_string
{
  my($self) = @_;
  join "\n", @{ $self->{errors} };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::TinyCC - Tiny C Compiler for FFI

=head1 VERSION

version 0.29

=head1 SYNOPSIS

 use FFI::TinyCC;
 use FFI::Platypus;
 
 my $tcc = FFI::TinyCC->new;
 
 $tcc->compile_string(q{
   int
   find_square(int value)
   {
     return value*value;
   }
 });
 
 my $address = $tcc->get_symbol('find_square');
 my $ffi = FFI::Platypus->new;
 $ffi->attach([$address => 'find_square'] => ['int'] => 'int');
 
 print find_square(4), "\n"; # prints 16

For code that requires system headers:

 use FFI::TinyCC;
 use FFI::Platypus;
 
 my $tcc = FFI::TinyCC->new;
 
 # this will throw an exception if the system
 # include paths cannot be detected.
 $tcc->detect_sysinclude_path;
 
 $tcc->compile_string(q{
   #include <stdio.h>
   
   void print_hello()
   {
     puts("hello world");
   }
 });
 
 my $address = $tcc->get_symbol('print_hello');
 my $ffi = FFI::Platypus->new;
 $ffi->attach([$address => 'print_hello'] => [] => 'void');
 print_hello();

=head1 DESCRIPTION

This module provides an interface to a very small C compiler known as 
TinyCC.  It does almost no optimizations, so C<gcc> or C<clang> will 
probably generate faster code, but it is very small and is very fast and 
thus may be useful for some Just In Time (JIT) or Foreign Function 
Interface (FFI) situations.

For a simpler, but less powerful interface see L<FFI::TinyCC::Inline>.

=head1 CONSTRUCTOR

=head2 new

 my $tcc = FFI::TinyCC->new;

Create a new TinyCC instance.

=head1 METHODS

Methods will generally throw an exception on failure.

=head2 Compile

=head3 set_options

 $tcc->set_options($options);

Set compiler and linker options, as you would on the command line, for 
example:

 $tcc->set_options('-I/foo/include -L/foo/lib -DFOO=22');

=head3 add_file

 $tcc->add_file('foo.c');
 $tcc->add_file('foo.o');
 $tcc->add_file('foo.so'); # or dll on windows

Add a file, DLL, shared object or object file.

On windows adding a DLL is not supported via this interface.

=head3 compile_string

 $tcc->compile_string($c_code);

Compile a string containing C source code.

=head3 add_symbol

 $tcc->add_symbol($name, $callback);
 $tcc->add_symbol($name, $pointer);

Add the given given symbol name / callback or pointer combination. See 
example below for how to use this to call Perl from Tiny C code.

If you are using L<FFI::Platypus> you can use L<FFI::Platypus#cast>
to get a pointer to a closure:

 use FFI::Platypus;
 my $ffi = FFI::Platypus;
 my $closure = $ffi->closure(sub { return $_[0]+1 });
 my $pointer = $ffi->cast('(int)->int' => 'opaque', $closure);
 
 $tcc->add_symbol('foo' => $pointer);

=head2 Preprocessor options

=head3 detect_sysinclude_path

[version 0.18]

 $tcc->detect_sysinclude_path;

Attempt to find and configure the appropriate system include directories. If 
the platform that you are on does not (yet?) support this functionality 
then this method will throw an exception.

[version 0.19]

Returns the list of directories added to the system include directories.

=head3 add_include_path

 $tcc->add_include_path($path);

Add the given path to the list of paths used to search for include files.

=head3 add_sysinclude_path

 $tcc->add_sysinclude_path($path);

Add the given path to the list of paths used to search for system 
include files.

=head3 set_lib_path

 $tcc->set_lib_path($path);

Set the lib path

=head3 define_symbol

 $tcc->define_symbol($name => $value);
 $tcc->define_symbol($name);

Define the given symbol, optionally with the specified value.

=head3 undefine_symbol

 $tcc->undefine_symbol($name);

Undefine the given symbol.

=head2 Link / run

=head3 set_output_type

 $tcc->set_output_type('memory');
 $tcc->set_output_type('exe');
 $tcc->set_output_type('dll');
 $tcc->set_output_type('obj');

Set the output type.  This must be called before any compilation.

Output formats may not be supported on your platform.  C<exe> is
NOT supported on *BSD or OS X.  It may NOT be supported on Linux.

As a basic baseline at least C<memory> should be supported.

=head3 add_library

 $tcc->add_library($libname);

Add the given library when linking.  Example:

 $tcc->add_library('m'); # equivalent to -lm (math library)

=head3 add_library_path

 $tcc->add_library_path($pathname);

Add the given directory to the search path used to find libraries.

=head3 run

 my $exit_value = $tcc->run(@arguments);

=head3 get_symbol

 my $pointer = $tcc->get_symbol($symbol_name);

Return symbol address or undef if not found.  This can be passed into 
the L<FFI::Platypus#function> method, L<FFI::Platypus#attach> method, 
or similar interface that takes a pointer to a C function.

=head3 output_file

 $tcc->output_file($filename);

Output the generated code (either executable, object or DLL) to the 
given filename. The type of output is specified by the 
L<set_output_type|/set_output_type> method.

=head1 EXAMPLES

=head2 Calling Tiny C code from Perl

 use FFI::TinyCC;
 
 my $tcc = FFI::TinyCC->new;
 
 $tcc->compile_string(<<EOF);
 int
 main(int argc, char *argv[])
 {
   puts("hello world");
 }
 EOF
 
 my $r = $tcc->run;
 
 exit $r;

=head2 Calling Perl from Tiny C code

 use FFI::TinyCC;
 use FFI::Platypus;
 
 my $ffi = FFI::Platypus->new;
 my $say = $ffi->closure(sub { print $_[0], "\n" });
 my $ptr = $ffi->cast('(string)->void' => 'opaque' => $say);
 
 my $tcc = FFI::TinyCC->new;
 $tcc->add_symbol(say => $ptr);
 
 $tcc->compile_string(<<EOF);
 extern void say(const char *);
 
 int
 main(int argc, char *argv[])
 {
   int i;
   for(i=0; i<argc; i++)
   {
     say(argv[i]);
   }
 }
 EOF
 
 my $r = $tcc->run($0, @ARGV);
 
 exit $r;

=head2 Attaching as a FFI::Platypus function from a Tiny C function

 use FFI::TinyCC;
 use FFI::Platypus;
 
 my $tcc = FFI::TinyCC->new;
 
 $tcc->compile_string(q{
   int
   calculate_square(int value)
   {
     return value*value;
   }
 });
 
 my $value = shift @ARGV;
 $value = 4 unless defined $value;
 
 my $address = $tcc->get_symbol('calculate_square');
 
 my $ffi = FFI::Platypus->new;
 $ffi->attach([$address => 'square'] => ['int'] => 'int');
 
 print square($value), "\n";

=head1 CAVEATS

Tiny C is only supported on platforms with ARM or Intel processors.  All 
features may not be fully supported on all operating systems.

Tiny C is no longer supported by its original author, though various 
forks seem to have varying levels of support. We use the fork that comes 
with L<Alien::TinyCC>.

=head1 SEE ALSO

=over 4

=item L<FFI::TinyCC::Inline>

=item L<Tiny C|http://bellard.org/tcc/>

=item L<Tiny C Compiler Reference Documentation|http://bellard.org/tcc/tcc-doc.html>

=item L<FFI::Platypus>

=item L<C::Blocks>

=item L<Alien::TinyCC>

=item L<C::TinyCompiler>

=back

=head1 BUNDLED SOFTWARE

This package also comes with a parser that was shamelessly stolen from 
L<XS::TCC>, which I strongly suspect was itself shamelessly "borrowed" 
from L<Inline::C::Parser::RegExp>

The license details for the parser are:

 Copyright 2002 Brian Ingerson
 Copyright 2008, 2010-2012 Sisyphus
 Copyright 2013 Steffen Muellero

This program is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

aero

Dylan Cali (calid)

pipcet

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
