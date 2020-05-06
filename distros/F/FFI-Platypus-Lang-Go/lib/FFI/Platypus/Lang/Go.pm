package FFI::Platypus::Lang::Go;

use strict;
use warnings;
use 5.008001;
use File::ShareDir::Dist 0.07 qw( dist_config );

# ABSTRACT: Documentation and tools for using Platypus with Go
our $VERSION = '0.01'; # VERSION



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

version 0.01

=head1 SYNOPSIS

Go code:

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

Perl code:

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

=head1 DESCRIPTION

This distribution is the Go language plugin for Platypus.
It provides the definition for native Go types, like
C<goint> and C<gostring>.  It also provides a L<FFI::Build>
interface for building Perl extensions written in Go.

For a full working example based on the synopsis above,
including support files like C<Makefile.PL> and tests,
see the C<examples/Awesome-FFI> directory that came with
this distribution.

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

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
