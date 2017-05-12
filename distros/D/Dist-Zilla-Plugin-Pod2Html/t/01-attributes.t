#!/usr/bin/env perl
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}
use strict;
use warnings;
use Test::More 0.88;
use Test::DZil;
use Moose::Autobox;
use File::Spec;

my $author = 'me';
my $dist_ini_root = {
    name => 'DZT',
    version => 1,
    abstract => 'DZT abstract',
    license => 'Perl_5',
    author => $author,
    copyright_holder => $author,
};
my @dist_ini_plugins = (
    ['@Filter', { '-bundle' => '@Basic', '-remove' => 'Readme' }],
#    ['FileFinder::ByName', 'BinNotShell', { dir => 'bin', skip => '.*\.sh$' }],
#    ['PkgVersion'],
#    ['PodWeaver', { finder => [':InstallModules', 'BinNotShell'] }],
    );

# examples:
# build_it ( {} );
# build_it ( {dir => 'docs_other', ignore => 'lib/abc' });
sub build_it {
    my ($args) = @_;

    my $name = 'Pod2Html';
    my $zilla = Builder->from_config (
        { dist_root => 'corpus/DZT' },
        {
            add_files => {
                'source/dist.ini' => dist_ini ($dist_ini_root,
                                               @dist_ini_plugins,
                                               [$name => $args])
            }
        }
        );
    $zilla->build;
    return $zilla;
}

my $zilla = build_it ({});
my $created_files = $zilla->files->grep ( sub { $_->name =~ m{^docs[/\\]} } );
is (scalar @$created_files, 3, '# of created files');

$zilla = build_it ({ dir => 'other-dir' });
$created_files = $zilla->files->grep ( sub { $_->name =~ m{^other-dir[/\\]} } );
is (scalar @$created_files, 3, '# of created files: other-dir');

$zilla = build_it ({ ignore => File::Spec->catfile ('bin', 'myscript') });
$created_files = $zilla->files->grep ( sub { $_->name =~ m{^docs[/\\]} } );
is (scalar @$created_files, 2, '# of created files: ignore 1');

$zilla = build_it ({ ignore => [File::Spec->catfile ('bin', 'myscript'),
                                File::Spec->catfile ('lib', 'DZT.pm') ] });
$created_files = $zilla->files->grep ( sub { $_->name =~ m{^docs[/\\]} } );
is (scalar @$created_files, 1, '# of created files: ignore 2');

$zilla = build_it ({ ignore => [File::Spec->catfile ('bin', 'myscript'),
                                File::Spec->catfile ('lib', 'DZT.pm') ],
                     dir    => 'another-dir' });
$created_files = $zilla->files->grep ( sub { $_->name =~ m{^another-dir[/\\]} } );
is (scalar @$created_files, 1, '# of created files: dir and ignore');

#use Data::Dumper;
#diag (Dumper ($zilla));
#diag ($zilla->files->grep ( sub { $_->name =~ m{^docs[/\\]} } )->map ( sub { $_->name } )->join ("\n"));

done_testing (5);

__END__
