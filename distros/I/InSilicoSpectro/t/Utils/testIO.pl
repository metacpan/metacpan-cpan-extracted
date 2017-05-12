#!/usr/bin/env perl

use strict;
use Carp;

BEGIN{
  use File::Basename;
  push @INC, (dirname $0).'/../../lib';
}

END{
}

use InSilicoSpectro::Utils::io;

my $iTest=shift @ARGV;

use File::Temp qw(tempfile tempdir);
eval{
  if($iTest==0){
    my (undef, $fname)=tempfile(SUFFIX=>'.zip', UNLINK=>1);
    zipFiles($fname, [@ARGV]);
    print STDERR "going to $fname\n";
    zipFiles(\*STDIN, [@ARGV]);
    exit(0);
  }

  if($iTest==1){
    foreach(InSilicoSpectro::Utils::io::headGz($ARGV[0], 4, '/^>/')){
      print "[[$_]]\n";
    }
    exit(0);
  }

  if($iTest==2){
    use Archive::Zip qw( :ERROR_CODES :CONSTANTS);
    my $zipfile=shift @ARGV || die "must provide a file.zip with itest=2";
    my $tmpdir=tempdir(CLEANUP=>1, UNLINK=>1);

    my $zip=Archive::Zip->new();
    unless($zip->read($zipfile)==AZ_OK){
      ok(0, "zip/unzip: cannot read archive $zipfile");
    }else{
      my @members=$zip->members();
      foreach (@members){
	print "extracting: ".$_->fileName()."\n";
	my (undef, $tmp)=tempfile("$tmpdir/".(basename $_->fileName()."-XXXXX"), UNLINK=>1);
	print "extracting [".$_->fileName()."] -> [$tmp]\n";
	$zip->extractMemberWithoutPaths($_, $tmp) && croak "cannot extract ".$_->fileName().": $!\n";
      }
      print STDERR "unzipped [".(scalar @members)."] files from archive\n";
    }
    exit(0);
  }
};

if ($@){
  print STDERR "error trapped in main\n";
  carp $@;
}
