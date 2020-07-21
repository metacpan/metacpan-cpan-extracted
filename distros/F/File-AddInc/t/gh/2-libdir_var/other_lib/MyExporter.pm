package MyExporter;
use strict;
use warnings;
use parent qw/File::AddInc/;

sub import {
  my ($pack, @args) = @_;

  my $opts = $pack->Opts->new(caller => [caller]);

  $pack->declare_these_libdirs($opts, @args);
}

1;
