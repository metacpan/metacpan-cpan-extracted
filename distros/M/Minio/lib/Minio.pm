package Minio;

use 5.006001;
use strict;
use utf8;
use JSON::XS;

=head1 NAME

Minio - interface to minio client

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.07';

=head1 SYNOPSIS

  use Minio;
  use Data::Dumper;

  my $MObj = new Minio({
   'json' => 1,
   'debug' => 1,
   'minio_client' => '/usr/bin/minio-mc',
   'minio_config_dir' => '/etc/minio',
  });

  my $MB = $MObj->MakeBucket({bucket=>'myminio/pub'});
  print Data::Dumper::Dumper($MB);

  my $MD = $MObj->DeleteBucket({bucket=>'myminio/pub', force=>1});
  print Data::Dumper::Dumper($MD);

  my $L2M = $MObj->Local2Minio({local_path=>'/tmp/file.txt',minio_path=>'myminio/pub/00/11/22/33/44/file.txt'});
  print Data::Dumper::Dumper($L2M);

  my $M2L = $MObj->Minio2Local({minio_path=>'myminio/pub/00/11/22/33/44/file.txt',local_path=>'/tmp/file2.txt'});
  print Data::Dumper::Dumper($M2L);

  my $Delete = $MObj->Delete({minio_path=>'myminio/pub/00/11/22/33/44/file.txt'});
  print Data::Dumper::Dumper($Delete);

  my $LS = $MObj->LS({minio_path=>'myminio/pub/00/11/22/33/44/'});
  print Data::Dumper::Dumper($LS);

  my $Cat = $MObj->Cat({minio_path=>'myminio/pub/00/11/22/33/44/file.txt'});
  print $Cat;

  my $Tree = $MObj->Tree({minio_path=>'myminio/pub',json=>0});
  print $Tree;

  my $Look = $MObj->Lookup({minio_path=>'myminio/pub/00/11/22/33/44/file.txt'});
  print $Look;

=cut

sub new {
  my $class = shift;
  my $X = {};
  my $Args = shift;

  my $MinioEXE = $Args->{'minio_client'} || FindFile('minio-mc', [split /:/,$ENV{'PATH'}]);

  die "\ncan't find Minio client".($Args->{'minio_path'}?" [".$Args->{'minio_path'}."]":"")
    ."\n\ninstall Minio-client and use 'minio_path_dir' parameter\nhttps://docs.min.io/docs/minio-client-quickstart-guide.html\n\n"
      if !$MinioEXE || !-f $MinioEXE;
  
  my $Check = CheckMinioConfig($Args->{'minio_config_dir'});
  unless ($Check == 1) {
    die "Can't find Minio-config path or config corrupted. Use 'minio_config_dir' parameter.: ".$Check;
  }

  $X->{'json'} = $Args->{'json'} || 1;
  $X->{'debug'} = $Args->{'debug'} || 0;
  $X->{'minio_exe'} = $MinioEXE;
  $X->{'minio_config'} = $Args->{'minio_config_dir'};

  bless $X, $class;
  return $X;
}

sub _ex {
  my $X = shift;
  my $Str = shift;
  my $Args = shift;

  die 'invalid options format. cmd(bucket,{option=>1,option=>2})' if defined $Args && ref $Args ne 'HASH';

  my $ToJson = $X->{'json'} && !(exists $Args->{'json'} && $Args->{'json'}==0);
  my $Force = $Args->{'force'};

  my $Cmd = $X->{'minio_exe'}.' -C '.$X->{'minio_config'}.' '.($ToJson?'--json ':'').$Str;
  print "Command: ".$Cmd."\n" if $X->{'debug'};
  my $Ex = `$Cmd 2>&1`;
  #print "EX ".$Ex."\n";

  if ($ToJson) {
    my $JSON;
    eval {
      $Ex =~ s/}[\n\r]{/},{/g;
      $Ex = '['.$Ex.']';
      $JSON = decode_json($Ex);
      if (!$Args->{'as_array'} && scalar @$JSON == 1 || ($JSON->[0] && $JSON->[0]->{'status'} eq 'error') ) {
        $JSON = $JSON->[0];
        $Ex =~ s/^\[//;
        $Ex =~ s/\]$//;
      } 
    };
    if ($@) {
      return "[ERROR] ".$Ex;      
    }
    my $R = {
      json=>$Ex,
      data=>$JSON,
    };
    $R->{'error'} = $JSON->{error}->{cause}->{message} || $JSON->{error}->{message}
      if ref $JSON eq 'HASH' && $JSON->{status} eq 'error';
    $R->{'status'} = $R->{'error'} ? 'error' : 'success';
    return $R;
  }
  return $Ex;
}

sub Lookup {
  my $X = shift;
  my $Args = shift;
  my $Path = $Args->{'minio_path'} || return {status=>'error',error_message=>"'minio_path' not defined"};
  my $Look = LS($X,{'minio_path'=>$Path});
  return $Look if $Look->{'status'} eq 'error';
  return $Look->{'data'}->[0] && $Look->{'data'}->[0]->{'key'} ? ($Args->{'info'}?$Look->{'data'}->[0]:1) : 0;
}

sub Cat {
  my $X = shift;
  my $JS = $X->{'json'};
  $X->{'json'} = 0;
  my $Args = shift;
  my $Path = $Args->{'minio_path'} || return {status=>'error',error_message=>"'minio_path' not defined"};
  my $Cmd = 'cat '.$Path;
  $Args->{'as_array'}=1;
  my $Ret = $X->_ex($Cmd, $Args);
  $X->{'json'} = $JS;
  return $Ret;
}

sub Delete {
  my $X = shift;
  my $Args = shift;
  my $Path = $Args->{'minio_path'} || return {status=>'error',error_message=>"'minio_path' not defined"};
  my $Cmd = 'rm '.$Path;
  $Args->{'as_array'}=1;
  return $X->_ex($Cmd, $Args);
}

sub LS {
  my $X = shift;
  my $Args = shift;
  my $Path = $Args->{'minio_path'} || return {status=>'error',error_message=>"'minio_path' not defined"};
  my $Cmd = 'ls '.$Path;
  $Args->{'as_array'}=1;
  return $X->_ex($Cmd, $Args);
}

sub Tree {
  my $X = shift;
  my $Args = shift;
  my $Path = $Args->{'minio_path'} || return {status=>'error',error_message=>"'minio_path' not defined"};
  my $Cmd = 'tree '.$Path;
  $Args->{'as_array'}=1;
  return $X->_ex($Cmd, $Args);
}

sub Local2Minio {
  my $X = shift;
  my $Args = shift;
  my $Source = $Args->{'local_path'} || return {status=>'error',error_message=>"Source 'local_path' not defined"};
  my $Destination = $Args->{'minio_path'} || return {status=>'error',error_message=>"Destination 'minio_path' not defined"};
  return {status=>'error',error_message=>"Source file '".$Source." not exists"}
    if !-f $Source && !-d $Source;
  my $Cmd = 'cp '.$Source.' '.$Destination;
  return $X->_ex($Cmd, $Args);
}

sub Minio2Local {
  my $X = shift;
  my $Args = shift;
  my $Source = $Args->{'minio_path'} || return {status=>'error',error_message=>"Source 'minio_path' not defined"};
  my $Destination = $Args->{'local_path'} || return {status=>'error',error_message=>"Destination 'local_path' not defined"};
  return {status=>'error',error_message=>"Source minio path '".$Source." not exists"}
    unless Lookup($X,{'minio_path'=>$Source});
  my $Cmd = 'cp '.$Source.' '.$Destination;
  return $X->_ex($Cmd, $Args);
}

sub MakeBucket {
  my $X = shift;
  my $Args = shift;
  my $BucketName = $Args->{'bucket'} || return {status=>'error',error_message=>"Bucket name not defined"};
  my $Cmd = 'mb '.$BucketName;
  return $X->_ex($Cmd, $Args);
}

sub DeleteBucket {
  my $X = shift;
  my $Args = shift;
  my $BucketName = $Args->{'bucket'} || return {status=>'error',error_message=>"Bucket name not defined"};
  my $Cmd = 'rb '.($Args->{force}?'--force ':'').$BucketName;
  return $X->_ex($Cmd, $Args);
}

sub CheckMinioConfig {
  my $Path = shift || return 'param not defined';
  return 'config dir "'.$Path.'" not exists' unless -d $Path;
  return 'config dir "'.$Path.'" wrong' unless -f $Path.'/config.json';
  return 1;
}

sub FindFile {
  my $FileName = shift;
  my $Dirs = shift;
  foreach (@$Dirs) {
    my $Path = $_.'/'.$FileName;
    return $Path if -f $Path;
  }
  return undef;
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 Litres.ru

The GNU Lesser General Public License version 3.0

Minio is free software: you can redistribute it and/or modify it
under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3.0 of the License.

Minio is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
License for more details.

Full text of License L<http://www.gnu.org/licenses/lgpl-3.0.en.html>.

=cut

1; # End of Minio
