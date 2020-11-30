#!/usr/bin/perl

use strict;
use Data::Dumper;
use Cwd qw(cwd);
use Minio;

my $MObj = new Minio({
  'json' => 1,
  'debug' => 1,
  'minio_client' => cwd().'/minio-mc',
  'minio_config_dir' => cwd().'/minio',
});

#my $MB = $MObj->MakeBucket({bucket=>'myminio/pub'});
#print Data::Dumper::Dumper($MB);

#my $MB = $MObj->DeleteBucket({bucket=>'myminio/pub', force=>1});
#print Data::Dumper::Dumper($MB);

#my $L2M = $MObj->Local2Minio({local_path=>'/tmp/1.txt',minio_path=>'myminio/pub/00/11/22/33/44/1.txt'});
#print Data::Dumper::Dumper($L2M);

#my $M2L = $MObj->Minio2Local({minio_path=>'myminio/pub/00/11/22/33/44/1.txt',local_path=>'/tmp/2.txt'});
#print Data::Dumper::Dumper($M2L);

#my $Cat = $MObj->Cat({minio_path=>'myminio/pub/00/11/22/33/44/1.txt'});
#print $Cat;

#my $Del = $MObj->Delete({minio_path=>'myminio/pub/00/11/22/33/44/1.txt'});
#print Data::Dumper::Dumper($Del);

#my $LS = $MObj->LS({minio_path=>'myminio/pub'});
#print Data::Dumper::Dumper($LS);

#my $LS = $MObj->LS({minio_path=>'myminio/pub/00'});
#print Data::Dumper::Dumper($LS);

#my $Tree = $MObj->Tree({minio_path=>'myminio/pub',json=>0});
#print Data::Dumper::Dumper($Tree);

