package FFI::Build::File::Zig;

use strict;
use warnings;
use 5.008004;
use parent qw( FFI::Build::File::Base );
use FFI::CheckLib 0.11 qw( find_lib_or_die );
use Path::Tiny ();
use File::chdir;
use File::Copy qw( copy );

# ABSTRACT: Documentation and tools for using Platypus with the Zig programming language
our $VERSION = '0.01'; # VERSION

sub accept_suffix
{
  (qr/\/build.zig$/)
}

sub build_all
{
  my($self) = @_;
  $self->build_item;
}

sub build_item
{
  my($self) = @_;

  my $build_zig = Path::Tiny->new($self->path);

  my $lib = $self->build ? $self->build->file : die 'todo';

  return $lib if -f $lib->path && !$lib->needs_rebuild($self->_deps($build_zig->parent));

  {
    my $lib = Path::Tiny->new($lib)->relative($build_zig->parent)->stringify;
    local $CWD = $build_zig->parent->stringify;
    print "+cd $CWD\n";

    my @cmd = ('zig', 'build', 'test');
    print "+@cmd\n";
    system @cmd;
    die "error running zig build test" if $?;

    @cmd = ('zig', 'build');
    print "+@cmd\n";
    system @cmd;
    die "error running zig build" if $?;

    my($dl) = find_lib_or_die
      lib        => '*',
      libpath    => "$CWD/zig-out/lib",
      systempath => [],
    ;

    $dl = Path::Tiny->new($dl)->relative($CWD);
    my $dir = Path::Tiny->new($lib)->parent;
    print "+mkdir $dir\n";
    $dir->mkpath;

    print "+cp $dl $lib\n";
    copy($dl, $lib) or die "Copy failed: $!";

    print "+cd -\n";
  }

  $lib;
}

sub _deps
{
  my($self, $path) = @_;

  my @list;

  foreach my $path ($path->child('src')->children)
  {
    next if -d $path;
    next unless $path->basename =~ /\.zig$/;
    push @list, $path;
  }

  @list;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::Build::File::Zig - Documentation and tools for using Platypus with the Zig programming language

=head1 VERSION

version 0.01

=head1 SYNOPSIS

From your perl project root:

 $ mkdir ffi
 $ cd ffi
 $ zig init-lib
 info: Created build.zig
 info: Created src/main.zig
 info: Next, try `zig build --help` or `zig build test`

Edit build.zig, and edit the line C<b.addStaticLibrary> to look like this:

 const lib = b.addSharedLibrary("ffi", "src/main.zig", b.version(0,0,1));

Add Zig code to C<ffi/src/main.zig> that you want to call from Perl:

 export fn add(a: i32, b: i32) callconv(.C) i32 {
     return a + b;
 }

Your Perl bindings go in a C<.pm> file like C<lib/MyLib.pm>:

 package MyLib;
 
 use FFI::Platypus 2.00;
 
 my $ffi = FFI::Platypus( api => 2, lang => 'Zig' );
 $ffi->bundle;
 
 $ffi->attach( 'add' => ['i32','i32'] => 'i32' );
 
 1;

Your C<Makefile.PL>:

 use ExtUtils::MakeMaker;
 use FFI::Build::MM;
 
 my $fbmm = FFI::Build::MM->new;
 
 WriteMakefile($fbmm->mm_args(
     ABSTRACT       => 'My Lib',
     DISTNAME       => 'MyLib',
     NAME           => 'MyLib',
     VERSION_FROM   => 'lib/MyLib.pm',
     BUILD_REQUIRES => {
         'FFI::Build::MM'          => '1.00',
         'FFI::Build::File::Zig'   => '0',
     },
     PREREQ_PM => {
         'FFI::Platypus'             => '2.00',
         'FFI::Platypus::Lang::Zig'  => '0',
     },
 ));
 
 sub MY::postamble {
     $fbmm->mm_postamble;
 }

Or alternatively, your C<dist.ini> if you are using L<Dist::Zilla>:

 [FFI::Build]
 lang = Zig
 build = Zig

Write a test:

 use Test2::V0;
 use MyLib;
 
 is MyLib::add(1,2), 3;
 
 done_testing;

=head1 DESCRIPTION

This module provides the necessary machinery to bundle Zig code with your Perl extension. It uses FFI::Build and
the Zig build system to do the heavy lifting.

The distribution that follows the pattern above works just like a regular Pure-Perl or XS distribution, except:

=over

=item make

Running the C<make> step builds the Zig library as a dynamic library using zig build system, and runs the Zig tests
tests if any are available. It then moves the resulting dynamic library in to the appropriate location in C<blib>
so that it can be found at test and runtime.

=item prove

If you run the tests using C<prove -l> (that is, without building the distribution), Platypus will find the Zig
package in the C<ffi> directory, build that and use it on the fly. This makes it easier to test your distribution
with less explicit building.

=back

This module is smart enough to check the timestamps on the appropriate files so the library won't need to be
rebuilt if the source files haven't changed.

For more details using Perl + Zig with FFI, see FFI::Platypus::Lang::Zig.

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

The Core Platypus documentation.

=item L<FFI::Platypus::Lang::Zig>

Zig language plugin for Platypus.

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
