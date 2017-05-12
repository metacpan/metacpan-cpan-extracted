use strict;
use warnings;

use Test::More 0.88;
use Test::DZil;

use Git::Wrapper;
use File::pushd qw(pushd);

my ($zilla, $pushd);

my $FIRST_RELEASE_CHANGELOG;

sub init_zilla {
    my ($version) = @_;

    undef($pushd);

    $zilla = Builder->from_config(
        {dist_root => 'dzil-tester/DZT'},
        {
            add_files => {
                'source/dist.ini' => dist_ini(
                    {
                        name             => 'DZT-Sample',
                        abstract         => 'Sample DZ Dist',
                        author           => 'Name Lastname <example@example.org>',
                        license          => 'GPL_3',
                        copyright_holder => 'Name Lastname',
                    },
                    'GatherDir',
                    'Git::Init',
                    'Git::Check',
                    [
                        'Git::NextVersion' => {
                            first_version     => 0.1,
                            version_by_branch => 0,
                            version_regexp    => '^(.+)$'
                        }
                    ],

                    ['ChangelogFromGit::Debian::Sequential' => {tag_regexp => '^(\d+\.\d+)$'}],
                    'FakeRelease',
                    ['Git::Commit' => {add_files_in => ['debian/changelog']}],
                    ['Git::Tag'    => {tag_format   => '%v'}],
                ),
                'source/.gitignore' => "DZT-Sample-*\nDZP-git*\n",
            }
        }
    );

    $pushd = pushd($zilla->tempdir->subdir('source'));

    print "# ";
    system "git init";

    my $git = Git::Wrapper->new('.');
    $git->config('user.name'  => 'dzp-git test');
    $git->config('user.email' => 'dzp-git@test');

    $git->add(-f => '.gitignore', 'dist.ini', 'lib/DZT.pm', 'debian/control');
    $git->commit({message => 'Initial commit'});

    system "echo .project >>.gitignore";
    $git->add(-f => '.gitignore');
    $git->commit(
        {
            message =>
"Added file .project to .gitignore and it is very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very long string\nIts new line on commit message"
        }
    );

    if ($version == 2) {
        $git->tag('0.1');
        $git->checkout(-b => 'fix_gitignore');
        system "echo .proverc >>.gitignore";
        open(my $fh, '>', 'debian/changelog') || die "Cannot create file 'debian/changelog': $!";
        print $fh $FIRST_RELEASE_CHANGELOG;
        close($fh);
        $git->add(-f => '.gitignore', 'debian/changelog');
        $git->commit({message => 'Fixed .gitignore'});
        $git->checkout('master');
        $git->merge('--no-ff', 'fix_gitignore');
    }
}

init_zilla(1);

$zilla->release;

my $content = $FIRST_RELEASE_CHANGELOG = $zilla->slurp_file('source/debian/changelog');

like(
    $content, qr/^libdzt-perl \(0\.1\) \w+; urgency=low

  \* Added file .project to .gitignore and it is very very very very very
    very very very very very very very very very very very very very very
    very very very very very very very very very very very very very very
    long string Its new line on commit message

  \* Initial commit

 -- .+? <.+?>  \w{3}, \d{2} \w{3} \d{4} \d{2}:\d{2}:\d{2} [+-]\d{4}
$/s, 'Checking first release changelog'
);

########################################################################################################################
init_zilla(2);

$zilla->release;

$content = $zilla->slurp_file('source/debian/changelog');

like(
    $content, qr/^libdzt-perl \(0\.2\) \w+; urgency=low

  \* Fixed .gitignore

 -- .+? <.+?>  \w{3}, \d{2} \w{3} \d{4} \d{2}:\d{2}:\d{2} [+-]\d{4}

libdzt-perl \(0\.1\) \w+; urgency=low

  \* Added file .project to .gitignore and it is very very very very very
    very very very very very very very very very very very very very very
    very very very very very very very very very very very very very very
    long string Its new line on commit message

  \* Initial commit

 -- .+? <.+?>  \w{3}, \d{2} \w{3} \d{4} \d{2}:\d{2}:\d{2} [+-]\d{4}
$/s, 'Checking second release changelog'
);

undef($pushd);

done_testing;
