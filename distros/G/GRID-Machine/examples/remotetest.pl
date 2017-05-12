#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $dist = shift or die "Usage:\n$0 distribution.tar.gz machine1 machine2 ... \n";

die "No distribution $dist found\n" unless -r $dist;

  die "Distribution does not follow standard name convention\n" 
unless $dist =~ m{([\w.-]+)\.tar\.gz$};
my $dir = $1;

die "Usage:\n$0 distribution.tar.gz machine1 machine2 ... \n" unless @ARGV;
for my $host (@ARGV) {

  my $m = eval { 
    GRID::Machine->new(host => $host, uses  => [ qw{File::Spec} ]) 
  };

  warn "Cant' create GRID::Machine connection with $host\n", next unless UNIVERSAL::isa($m, 'GRID::Machine');

  my $r = $m->eval(q{ 
      chdir(File::Spec->tmpdir) or die "Can't change to dir ".File::Spec->tmpdir."\n"; 
    }
  );

  warn($r),next unless $r->ok;

  $m->put([$dist]) or die "Can't copy distribution in $host\n";

  $r = $m->eval(q{
      my $dist = shift;

      eval('use Archive::Tar');
      if (Archive::Tar->can('new')) {
        # Archive::Tar is installed, use it
        my $tar = Archive::Tar->new;
        $tar->read($dist,1) or die "Archive::Tar error: Can't read distribution $dist\n";
        $tar->extract() or die "Archive::Tar error: Can't extract distribution $dist\n";
      }
      else {
        system('gunzip', $dist) or die "Can't gunzip $dist\n";
        my $tar = $dist =~ s/\.gz$//;
        system('tar', '-xf', $tar) or die "Can't untar $tar\n";
      }
    },
    $dist # arg for eval
  );

  warn($r), next unless $r->ok;

  $m->chdir($dir)->ok or do {
    warn "$host: Can't change to directory $dir\n";
    next;
  };

  print "************$host************\n";
  next unless $m->run('perl Makefile.PL');
  next unless $m->run('make');
  next unless $m->run('make test');
}

=head1 NAME

remotetest.pl - make tests on a remote machine


=head1 SYNOPSYS

  remotetest.pl MyInteresting-Dist-1.107.tar.gz machine1.domain machine2.domain

=head1 DESCRIPTION

The script C<remotetest.pl> copies a Perl distribution (see L<ExtUtils::MakeMaker>)
to each of the listed machines via C<scp>
and proceeeds to run C<make test> on a temporary directory. Assumes that 
automatic authentification via ssh has been set up with each of the remote machines.

=head1 AUTHOR

Casiano Rodriguez-Leon 

=head1 COPYRIGHT

(c) Copyright 2008 Casiano Rodriguez-Leon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

