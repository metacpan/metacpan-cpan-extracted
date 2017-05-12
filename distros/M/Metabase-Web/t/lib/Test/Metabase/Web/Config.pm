use strict;
use warnings;
package Test::Metabase::Web::Config;

use File::Temp ();
use Path::Class;
use JSON;

# XXX: Part of a monstrous hack perpetrated here and in Model::Metabase.
my $CURRENT_GATEWAY;
sub gateway { $CURRENT_GATEWAY }

sub import {
  my %tmp;
  my $root = dir(File::Temp::tempdir(CLEANUP => 1));

  for my $which (qw(public secret)) {
    my $root = $root->subdir($which);
    (my $archive_dir = $root->subdir('store'))->mkpath;
    my $index_file   = $root->file('index.txt');
    close $index_file->openw; # create the file, lest the exists-check die!

    $tmp{$which}{archive} = "$archive_dir";
    $tmp{$which}{index}   = "$index_file";
  }

  my $config = {
    'Model::Metabase' => {
      gateway => {
        librarian => {
          archive => { root_dir   => "$tmp{public}{archive}" },
          index   => { index_file => "$tmp{public}{index}"   },
        },
        secret_librarian => {
          archive => { root_dir   => "$tmp{secret}{archive}" },
          index   => { index_file => "$tmp{secret}{index}"   },
        },
      },
      fact_classes => [ 'Test::Metabase::StringFact' ],
    }
  };

  my $config_file = dir($root)->file('test.json');

  open my $fh, '>', $config_file or die "can't write to $config_file: $!";
  print { $fh } JSON->new->encode($config);
  $ENV{METABASE_WEB_CONFIG} = $config_file;

  $Metabase::Web::Model::Metabase::COMPONENT_CALLBACK = sub {
    $CURRENT_GATEWAY = shift;
  };

  return;
}

1;
