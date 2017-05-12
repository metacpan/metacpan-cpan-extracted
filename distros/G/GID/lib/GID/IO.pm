package GID::IO;
BEGIN {
  $GID::IO::AUTHORITY = 'cpan:GETTY';
}
{
  $GID::IO::VERSION = '0.004';
}
# ABSTRACT: IO functions of GID, like dir() and file()


use strictures 1;
use Exporter 'import';

use GID::File;
use GID::Dir;
use File::Temp ();

our @EXPORT = qw(
	dir
	file
	foreign_file
	foreign_dir
	tempdir
	tempfile
	rmrf
	mkdir
);

sub dir { GID::Dir->new(@_)->absolute }
sub file { GID::File->new(@_)->absolute }
sub foreign_dir { GID::Dir->new_foreign(@_) }
sub foreign_file { GID::File->new_foreign(@_) }
sub tempdir { GID::Dir->new(File::Temp::tempdir(@_))->absolute }

sub tempfile {
	my ($fh, $filename) = File::Temp::tempfile(@_);
	GID::File->new($filename)->absolute;
}

sub rmrf { dir(@_)->rmrf }

sub mkdir { GID::Dir->mkdir(@_)->absolute }

1;

__END__

=pod

=head1 NAME

GID::IO - IO functions of GID, like dir() and file()

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  use GID::IO;

  my $dir = dir('/home/foo');
  my $file = $dir->file('bar.txt');
  my $other_file = file('some','path','foobar.txt');

  my $tempdir = tempdir;
  my $tempfile = tempfile;
  my $other_tempfile = $tempdir->tempfile;
  $other_tempfile->spew('I will disappear');

  $file->touch;

  my $subdir = $dir->mkdir('foobar');
  $subdir->rmrf;

  $dir->files(sub {
    print "Filename in $dir: $_\n";
  });

  print "$dir not empty" unless $dir->rm;

  $file->rm;

=head1 DESCRIPTION

See L<GID::File> and L<GID::Dir>

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
