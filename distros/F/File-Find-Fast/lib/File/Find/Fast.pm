#!/usr/bin/env perl
package File::Find::Fast;
use strict;
use warnings;
#use Class::Interface qw/implements/;
use Exporter qw(import);
use File::Basename qw/fileparse basename dirname/;
use File::Temp qw/tempdir tempfile/;
use File::Spec;
use Data::Dumper;
use Carp qw/croak confess/;

our $VERSION = '0.2.1';

our @EXPORT_OK = qw(find);

local $0=basename $0;

# If this is used in a scalar context, $self->toString() is called
use overload '""' => 'toString';

=pod

=head1 NAME

File::Find::Fast

=head1 SYNOPSIS

A module to find files much more quickly than File::Find

=head1 DESCRIPTION

=head1 METHODS

=over

=item find()

=back

=cut

sub find{
  my($dir) = @_;

  my @file = ($dir);

  if(!-d $dir){
    croak "ERROR: $dir is not a directory";
  }
  _find_recursive($dir, \@file);

  return \@file;
}

sub _find_recursive{
  my($parentDir, $files) = @_;

  opendir(my $dh, $parentDir) || confess "Can't opendir $parentDir: $!";
  while(my $file = readdir($dh)){
    next if($file =~ /^\.{1,2}$/);
    my $path = "$parentDir/$file";
    #my $path = File::Spec->catfile($parentDir, $file);
    push(@$files, $path);
    if(-d $path){
      _find_recursive($path, $files);
    }
  }
  closedir($dh);
  return 1;
}

1;

