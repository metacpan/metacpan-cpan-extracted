package Module::Build::FFI::Fortran;

use strict;
use warnings;
use Config;
use File::Glob qw( bsd_glob );
use File::Which qw( which );
use Text::ParseWords qw( shellwords );
use File::Spec;
use base qw( Module::Build::FFI );

our $VERSION = '0.09';

=head1 NAME

Module::Build::FFI::Fortran - Build Perl extensions in Fortran with FFI

=head1 DESCRIPTION

L<Module::Build::FFI> variant for writing Perl extensions in Fortran with
FFI (sans XS).

=head1 BASE CLASS

All methods, properties and actions are inherited from:

L<Module::Build::FFI>

=head1 METHODS

=head2 ffi_have_compiler

 my $has_compiler = $mb->ffi_have_compiler;

Returns true if Fortran is available.

=cut

sub _filter
{
  grep { $_ ne '-no-cpp-precomp' && $_ !~ /^-[DI]/ } @_;
}

sub ffi_have_compiler
{
  my($self) = @_;
  
  my %ext;
  
  foreach my $dir (@{ $self->ffi_source_dir }, @{ $self->ffi_libtest_dir })
  {
    next unless -d $dir;
    $ext{$_} = 1 for map { s/^.*\.//; $_ } bsd_glob("$dir/*.{f,for,f90,f95}");
  }

  return unless %ext;

  if($ext{f} || $ext{for})
  {
    #warn "testing Fortran 77";
    return unless $self->_f77_testcompiler;
  }
  
  if($ext{f90})
  {
    #warn "testing Fortran 90";
    # TODO: do an actual test on the compiler, not just
    # check for it in the PATH
    return unless which($self->_f77_config->{f90});
  }

  if($ext{f95})
  {
    #warn "testing Fortran 95";
    # TODO: do an actual test on the compiler, not just
    # check for it in the PATH
    return unless which($self->_f77_config->{f95});
  }
  
  1;
}

=head2 ffi_build_dynamic_lib

 my $dll_path = $mb->ffi_build_dynamic_lib($src_dir, $name, $target_dir);
 my $dll_path = $mb->ffi_build_dynamic_lib($src_dir, $name);

Works just like the version in the base class, except builds Fortran
sources.

=cut

sub ffi_build_dynamic_lib
{
  my($self, $dirs, $name, $dest_dir) = @_;
  
  $dest_dir ||= $dirs->[0];
  
  my $f77_config = $self->_f77_config;
  my @cflags = _filter (
    shellwords($f77_config->{cflags}),
    # hopefully the Fortran compiler understands the same flags as the C compiler
    shellwords($Config{ccflags}),
    shellwords($Config{cccdlflags}),
    shellwords($Config{optimize})
  );
  
  if($self->extra_linker_flags)
  {
    if(ref($self->extra_linker_flags))
    {
      push @cflags, @{ $self->extra_linker_flags };
    }
    else
    {
      push @cflags, shellwords($self->extra_linker_flags);
    }
  }
  
  my @obj;
  my $count = 0;
  
  foreach my $dir (@$dirs)
  {
    push @obj, map {
    
      my $filename = $_;
      my $obj_name = $filename;
      $obj_name =~ s{\.(f|for|f90|f95)$}{$Config{obj_ext}};
      my $ext = $1;
      
      my $source_time = (stat $filename)[9];
      my $obj_time    = (stat $obj_name)[9];
      
      unless($obj_time >= $source_time)
      {
        $self->add_to_cleanup($obj_name);
      
        my $compiler = $f77_config->{f77};
        $compiler = $f77_config->{f90} if $ext eq 'f90';
        $compiler = $f77_config->{f95} if $ext eq 'f95';
      
        my @cmd = (
          $compiler,
          '-c',
          '-o' => $obj_name,
          @cflags,
          $filename,
        );
      
        print "@cmd\n";
        system @cmd;
        exit 2 if $?;
        $count++;
      }
      
      $obj_name;
    
    } bsd_glob("$dir/*.{f,for,f90,f95}");
  }
  
  my $b = $self->cbuilder;
  
  my $libfile = $b->lib_file(File::Spec->catfile($dest_dir, $b->object_file("$name.c")));
  return $libfile unless $count;
  
  if($^O ne 'MSWin32')
  {
    return $b->link(
      lib_file           => $libfile,
      objects            => \@obj,
      extra_linker_flags => $self->extra_linker_flags,
    );
  }
  else
  {
    die "TODO";  # See Module::Build::FFI
  }
}

sub _f77
{
  return if $INC{'Module/Build/FFI/Fortran/ExtUtilsF77.pm'};
  eval qq{ use Module::Build::FFI::Fortran::ExtUtilsF77; };
  die $@ if $@;
}

sub _f77_config
{
  _f77();
  my $config = {
    runtime             => Module::Build::FFI::Fortran::ExtUtilsF77::runtime(),
    trailing_underscore => Module::Build::FFI::Fortran::ExtUtilsF77::trail_(),
    cflags              => Module::Build::FFI::Fortran::ExtUtilsF77::cflags(),
    f77                 => Module::Build::FFI::Fortran::ExtUtilsF77::compiler(),
  };

  # Just guessing...
  foreach my $compiler (qw( 90 95 ))
  {
    $config->{"f$compiler"} = $config->{f77};
    $config->{"f$compiler"} =~ s/77/$compiler/;
  }
    
  $config;
}

sub _f77_testcompiler
{
  _f77();
  Module::Build::FFI::Fortran::ExtUtilsF77::testcompiler();
}

1;

__END__

=head1 EXAMPLES

TODO

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

The Core Platypus documentation.

=item L<Module::Build::FFI>

General MB class for FFI / Platypus.

=back

=head1 AUTHOR

Graham Ollis E<lt>plicease@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

