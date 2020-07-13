package FFI::Build::File::Pascal;

use strict;
use warnings;
use 5.008004;
use base qw( FFI::Build::File::Base );
use File::Which ();
use Carp ();
use Path::Tiny ();
use File::chdir;
use FFI::CheckLib qw( find_lib_or_die );
use File::Copy qw( copy );

our $VERSION = '0.09';

=head1 NAME

FFI::Build::FIle::Pascal - Build Pascal library using the FFI::Build system

=head1 SYNOPSIS

In your .fbx file:

 use strict;
 use warnings;
 our $DIR;
 {
   source  => ["$DIR/test.pas"],
   verbose => 2,
 }

=head1 DESCRIPTION

This class provides the necessary machinery for building Pascal files as
part of the L<FFI::Build> system using the Free Pascal compiler.  The
source file should be a Free Pascal library.  Only the library C<.pas>
file should be specified.  You can use other Units, but because the
Free Pascal Compiler automatically handles dependencies you do not
need to specify them.

=head1 BASE CLASS

L<FFI::Build::File::Base>

=head1 CONSTRUCTOR

=head2 new

 my $file = FFI::Build::File::Pascal->new($content, %opt);

In addition to the normal options, this class accepts:

=over 4

=item C<fpc_flags>

The Free Pascal compiler flags to use when building the library.

=back

=cut

sub new
{
  my($class, $content, %config) = @_;

  my @fpc_flags;
  if(defined $config{fpc_flags})
  {
    if(ref $config{fpc_flags} eq 'ARRAY')
    {
      push @fpc_flags, @{ delete $config{fpc_flags} };
    }
    elsif(ref $config{fpc_flags} eq '')
    {
      push @fpc_flags, delete $config{fpc_flags};
    }
    else
    {
      Carp::croak("Unsupported fpc_flags");
    }
  }

  my $self = $class->SUPER::new($content, %config);

  $self->{fpc_flags} = \@fpc_flags;

  $self;
}

sub build_all
{
  shift->build_item;
}

sub build_item
{
  my($self) = @_;

  my $pas = Path::Tiny->new($self->path);

  local $CWD = Path::Tiny->new($self->path)->parent;
  print "+cd $CWD\n";

  my @cmd = ($self->fpc, $self->fpc_flags, $pas->basename);
  print "+@cmd\n";
  system @cmd;
  exit 2 if $?;

  my($dl) = find_lib_or_die(
    lib => '*',
    libpath => [$CWD],
    systempath => [],
  );

  Carp::croak("unable to find lib for $pas") unless $dl;

  if($self->build)
  {
    my $lib = $self->build->file;

    my $dir = Path::Tiny->new($lib)->parent;
    unless(-d $dir)
    {
      print "+mkdir $dir\n";
      $dir->mkpath;
    }

    $dl = Path::Tiny->new($dl)->relative($CWD);
    print "+cp $dl $lib\n";
    copy($dl, $lib) or die "Copy failed $!";

    print "+cd -\n";

    return $lib;
  }
  else
  {
    require FFI::Build::File::Library;
    print "+cd -\n";
    return FFI::Build::File::Library->new([$dl]);
  }
}

sub fpc
{
  my $fpc = File::Which::which('fpc');
  die "Free Pascal compiler not found" unless defined $fpc;
  $fpc;
}

sub fpc_flags
{
  my($self) = @_;
  @{ $self->{fpc_flags} };
}

sub default_suffix
{
  return '.pas';
}

sub default_encoding
{
  return ':utf8';
}

sub accept_suffix
{
  (qr/\.(pas|pp)$/)
}

1;

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

The Core Platypus documentation.

=item L<FFI::Platypus::Lang::Pascal>

Pascal language plugin for L<FFI::Platypus>.

=back

=head1 AUTHOR

Graham Ollis E<lt>plicease@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

