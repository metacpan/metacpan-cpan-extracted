package FFI::Platypus::Lang::Go;

use strict;
use warnings;
use 5.008001;
use File::ShareDir::Dist 0.07 qw( dist_config );

# ABSTRACT: Documentation and tools for using Platypus with Go
our $VERSION = '0.03'; # VERSION


my $config;

sub _config
{
  unless($config)
  {
    $config = dist_config 'FFI-Platypus-Lang-Go';
    # running out of an unbuilt git, probe for types on the fly
    if(!%$config && -f 'inc/mymm-build.pl')
    {
      my $clean = 0;
      if(!-f 'blib')
      {
        require Capture::Tiny;
        my($out, $exit) = Capture::Tiny::capture_merged(sub {
          my @cmd = ($^X, 'inc/mymm-build.pl');
          print "+@cmd\n";
          system @cmd;
        });
        if($exit)
        {
          require File::Path;
          File::Path::rmtree('blib',0,0);
          print STDERR $out;
          die "probe of go types failed";
        }
        else
        {
          $clean = 1;
        }
      }
      $config = do './blib/lib/auto/share/dist/FFI-Platypus-Lang-Go/config.pl';
      if($clean)
      {
        require File::Path;
        File::Path::rmtree('blib',0,0);
      }
    }
  }

  $config;
}

sub native_type_map
{
  _config->{go_types};
}

sub load_custom_types
{
  my(undef, $ffi) = @_;
  $ffi->load_custom_type('::GoString' => 'gostring');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::Platypus::Lang::Go - Documentation and tools for using Platypus with Go

=head1 VERSION

version 0.03

=head1 SYNOPSIS

Go code:

 package main
 
 import "C"
 
 //export add
 func add(x, y int) int {
     return x + y
 }
 
 func main() {}

Perl code:

 use FFI::Platypus 2.00;
 use FFI::CheckLib qw( find_lib_or_die );
 use File::Basename qw( dirname );
 
 my $ffi = FFI::Platypus->new(
   api  => 2,
   lib  => './add.so',
   lang => 'Go',
 );
 $ffi->attach( add => ['goint', 'goint'] => 'goint' );
 
 print add(1,2), "\n";  # prints 3

=head1 DESCRIPTION

This distribution is the Go language plugin for Platypus.
It provides the definition for native Go types, like
C<goint> and C<gostring>.  It also provides a L<FFI::Build>
interface for building Perl extensions written in Go (see
L<FFI::Build::File::GoMod> for details).

=head1 EXAMPLES

The examples in this discussion are bundled with this
distribution and can be found in the C<examples> directory.

=head2 Passing and Returning Integers

=head3 Go

 package main
 
 import "C"
 
 //export add
 func add(x, y int) int {
     return x + y
 }
 
 func main() {}

=head3 Perl

 use FFI::Platypus 2.00;
 use FFI::CheckLib qw( find_lib_or_die );
 use File::Basename qw( dirname );
 
 my $ffi = FFI::Platypus->new(
   api  => 2,
   lib  => './add.so',
   lang => 'Go',
 );
 $ffi->attach( add => ['goint', 'goint'] => 'goint' );
 
 print add(1,2), "\n";  # prints 3

=head3 Execute

 $ go build -o add.so -buildmode=c-shared add.go
 $ perl add.pl
 3

=head3 Discussion

The Go code has to:

=over 4

=item 1 Import the pseudo package C<"C">

=item 2 Mark any exported function with the command C<//export>

=item 3 Include a C<main> function, even if you do not use it.

=back

From the Perl side, the Go types have a C<go> prefix, so C<int>
in Go is C<goint> in Perl.

Aside from that passing basic types like integers and floats
is trivial with FFI.

=head2 Module

=head3 Go

 /*
  * borrowed from
  * https://medium.com/learning-the-go-programming-language/calling-go-functions-from-other-languages-4c7d8bcc69bf
  */
 
 package main
 
 import "C"
 
 import (
 	"fmt"
 	"math"
 	"sort"
 	"sync"
 )
 
 var count int
 var mtx sync.Mutex
 
 //export Add
 func Add(a, b int) int { return a + b }
 
 //export Cosine
 func Cosine(x float64) float64 { return math.Cos(x) }
 
 //export Sort
 func Sort(vals []int) { sort.Ints(vals) }
 
 //export Log
 func Log(msg string) int {
 	mtx.Lock()
 	defer mtx.Unlock()
 	fmt.Println(msg)
 	count++
 	return count
 }
 
 func main() {}

=head3 Perl

Module:

 package Awesome::FFI;
 
 use strict;
 use warnings;
 use FFI::Platypus;
 use FFI::Go::String;
 use base qw( Exporter );
 
 our @EXPORT_OK = qw( Add Cosine Log );
 
 my $ffi = FFI::Platypus->new( api => 1, lang => 'Go' );
 # See FFI::Platypus::Bundle for the how and why
 # bundle works.
 $ffi->bundle;
 
 $ffi->attach( Add    => ['goint','goint'] => 'goint'     );
 $ffi->attach( Cosine => ['gofloat64'    ] => 'gofloat64' );
 $ffi->attach( Log    => ['gostring'     ] => 'goint'     );
 
 1;

Test:

 use Test2::V0 -no_srand => 1;
 use Awesome::FFI qw( Add Cosine Log );
 use Capture::Tiny qw( capture );
 use FFI::Go::String;
 
 is( Add(1,2), 3 );
 is( Cosine(0), 1.0 );
 
 is(
   [capture { Log("Hello Perl!") }],
   ["Hello Perl!\n", '', 1]
 );
 
 done_testing;

=head3 Execute

 $ prove -lvm t/awesome_ffi.t
 t/awesome_ffi.t ..
 ok 1
 ok 2
 ok 3
 1..3
 ok
 All tests successful.
 Files=1, Tests=3,  1 wallclock secs ( 0.01 usr  0.00 sys +  1.28 cusr  0.48 csys =  1.77 CPU)
 Result: PASS

=head3 Discussion

This is a full working example of a Perl distribution / module
included in the C<examples/Awesome-FFI> directory.

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

More about FFI and Platypus itself.

=item L<FFI::Platypus::Type::GoString>

Type plugin for the go string type.

=item L<FFI::Go::String>

Low level interface to the go string type.

=item L<FFI::Build::File::GoMod>

L<FFI::Build> class for handling Go modules.

=item L<Calling Go Functions from Other Languages using C Shared Libraries|https://github.com/vladimirvivien/go-cshared-examples>

=back

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Graham TerMarsch (GTERMARS)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
