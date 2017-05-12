
use strict;
use warnings;

use Test::More tests => 5;    # last test to print

use Dist::Zilla;
use Dist::Zilla::Tester;
use Dist::Zilla::Role::Tempdir;

sub _build_config {
  my $out = <<'EOF';
  name = Test-DZRTd
  copyright_holder = Kent Fredric
  main_module = t/fake/dist.pm
  abstract = A Fake Dist
  license = Perl_5
EOF
  $out;
}

{

  package Dist::Zilla::Plugin::TestTempDir;
  use Moose;
  with 'Dist::Zilla::Role::Plugin';
  with 'Dist::Zilla::Role::Tempdir';
  with 'Dist::Zilla::Role::FileInjector';
  with 'Dist::Zilla::Role::InstallTool';


  sub setup_installer {
    my ( $self, $arg ) = @_;

  }

  __PACKAGE__->meta->make_immutable;
}

my $dz =
  Dist::Zilla::Tester->from_config( { dist_root => 't/fake/' }, { add_files => { 'source/dist.ini' => _build_config() } } );

for (qw( GatherDir )) {
  my $full = 'Dist::Zilla::Plugin::' . $_;
  eval "use $full; 1" or die("Cant load plugin >$full<");
  my $plug = $full->new( zilla => $dz, plugin_name => $_ );

  push @{ $dz->plugins }, $plug;
}

$_->gather_files for @{ $dz->plugins_with( -FileGatherer ) };

my $plug = Dist::Zilla::Plugin::TestTempDir->new(
  zilla       => $dz,
  plugin_name => 'TestTempDir',
);

my (@files) = $plug->capture_tempdir(
  sub {
    use Path::Tiny qw(path);
    path('example2.pm')->spew_raw("# ABSTRACT: A Sample Generated File");
    system('echo ANOTHER GENERATED FILE > example.pm');
  }
);

my ( $distpm, ) = grep { $_->name eq 'dist.pm' } @files;
is( $distpm->{status}, 'O', 'Dist.pm reports unmodified' );

my ( $e2pm, ) = grep { $_->name eq 'example2.pm' } @files;
is( $e2pm->{status}, 'N', 'New file example2.pm appeared' );

my ( $epm, ) = grep { $_->name eq 'example.pm' } @files;
is( $epm->{status}, 'N', 'New file example.pm appeared' );

@files = $plug->capture_tempdir(
  sub {
    #    system("cmd");
    system( $^X, '-we', 'unlink q{dist.pm}' ) and die;

    #    print "done!\n";
    #    system("cmd");
  }
);

( $distpm, ) = grep { $_->name eq 'dist.pm' } @files;

is( $distpm->{status}, 'D', 'dist.pm reports deleted' );

@files = $plug->capture_tempdir(
  sub {
    system('echo garbage appended >> dist.pm');
  }
);

#use Data::Dump qw( dump );
#dump \@files;
( $distpm, ) = grep { $_->name eq 'dist.pm' } @files;

is( $distpm->{status}, 'M', 'dist.pm reports modified' );

