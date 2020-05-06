package FFI::Build::File::GoMod;

use strict;
use warnings;
use 5.008001;
use base qw( FFI::Build::File::Base );
use constant default_suffix => '.mod';
use constant default_encoding => ':utf8';
use Path::Tiny ();
use FFI::Build::Platform;
use FFI::Build::File::Library;
use File::chdir;

# ABSTRACT: Class to track C source file in FFI::Build
our $VERSION = '0.01'; # VERSION


sub accept_suffix
{
  (qr/\/go\.mod$/)
}

sub build_all
{
  my($self) = @_;
  $self->build_item;
}

sub build_item
{
  my($self) = @_;

  my $gomod = Path::Tiny->new($self->path);

  my $platform;
  my $buildname;
  my $lib;

  if($self->build)
  {
    $platform = $self->build->platform;
    $buildname = $self->build->buildname;
    $lib = $self->build->file;
  }
  else
  {
    $platform = FFI::Build::Platform->new;
    $buildname = "_build";
    $lib = FFI::Build::File::Library->new(
      [
        $gomod->parent->child($buildname).'',
        do {
          my($name) = map { my $m = $_; $m =~ s/\s*$//; lc $m }
                      map { my $m = $_; $m =~ s/^.*\///; $m }
                      grep /^module /,
                      $gomod->lines_utf8;
          $name = "gomod" unless defined $name;
          join '', $platform->library_prefix, $name, scalar $platform->library_suffix
        },
      ],
      platform => $self->platform
    );
  }

  return $lib if -f $lib->path && !$lib->needs_rebuild($self->_deps($gomod));

  {
    my $lib_path = Path::Tiny->new($lib->path)->relative($gomod->parent);
    print "+cd @{[ $gomod->parent ]}\n";
    local $CWD = $gomod->parent;
    $platform->run('go', 'build', -o => "$lib_path", '-buildmode=c-shared');
    die "command failed" if $?;
    die "no c-shared library" unless -f $lib_path;
    chmod 0755, $lib_path unless $^O eq 'MSWin32';
    if($self->_test)
    {
      $platform->run('go', 'test' );
      die "command failed" if $?;
    }
    print "+cd -\n";
  }

  $lib;
}

sub _deps
{
  my($self, $gomod) = @_;
  map { "$_" } grep { $_->basename =~ /^(.*\.go|go\.mod|go\.sum)$/ } $gomod->parent->children;
}

sub _test
{
  my($self) = @_;
  map { "$_" } grep { $_->basename =~ /_test\.go$/ } Path::Tiny->new('.')->children;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::Build::File::GoMod - Class to track C source file in FFI::Build

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 use FFI::Build::File::GoMod;
 
 my $c = FFI::Build::File::GoMod->new('src/go.mod');

=head1 DESCRIPTION

File class for Go Modules.  This works like the other
L<FFI::Build> file types.  For a complete example,
see the C<examples/Awesome-FFI> directory that comes
with the L<FFI::Platypus::Lang::Go> distribution.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
