
use strict;
use warnings;

use Test::More;

# ABSTRACT: Make sure from-code files get written out to disk.
use Dist::Zilla::File::FromCode;
use Dist::Zilla::Tester;
my @files;
my $called_setup   = 0;
my $called_capture = 0;
{

  package Dist::Zilla::Plugin::TestTempDir;
  use Moose;
  use Path::Tiny qw(path);
  with 'Dist::Zilla::Role::Plugin';
  with 'Dist::Zilla::Role::Tempdir';
  with 'Dist::Zilla::Role::FileInjector';
  with 'Dist::Zilla::Role::InstallTool';

  sub setup_installer {
    my ( $self, $arg ) = @_;
    my $file = Dist::Zilla::File::FromCode->new(
      {
        name => 'Foo',
        code => sub {
          'Content',;
        }
      }
    );
    $called_setup = 1;
    my (@generated) = $self->capture_tempdir(
      sub {
        $called_capture = 1;
        for my $child ( path('./')->children ) {
          push @files,
            {
            path   => $child,
            exists => -e $child,
            lines  => -e $child ? [ $child->lines_raw ] : [],
            };
        }
      }
    );

  }

  __PACKAGE__->meta->make_immutable;
  $INC{'Dist/Zilla/Plugin/TestTempDir.pm'} = 1;
}

sub _build_config {
  my $out = <<'EOF';
name = Test-DZRTd
copyright_holder = Kent Fredric
main_module = t/fake/dist.pm
abstract = A Fake Dist
license = Perl_5
version = 0.01

[GatherDir]

[TestTempDir]
EOF
  return $out;
}

my $dz =
  Dist::Zilla::Tester->from_config( { dist_root => 't/fake/' }, { add_files => { 'source/dist.ini' => _build_config() } } );

$dz->build;

ok( $called_setup,   'setup calls' );
ok( $called_capture, 'capture calls' );

is( scalar @files, 2, 'has files' );

subtest 'distini' => sub {
  my ( $file, ) = grep { $_->{path}->basename eq 'dist.ini' } @files;
  ok( $file,                      'has dist.ini' );
  ok( $file->{exists},            'dist.ini exists on disk' );
  ok( scalar @{ $file->{lines} }, 'dist.ini has lines' )

};
subtest 'distpm' => sub {
  my ( $file, ) = grep { $_->{path}->basename eq 'dist.pm' } @files;
  ok( $file,           'has dist.pm' );
  ok( $file->{exists}, 'dist.ini exists on disk' );

  ok( scalar @{ $file->{lines} }, 'dist.pm has lines' );
};

done_testing;

