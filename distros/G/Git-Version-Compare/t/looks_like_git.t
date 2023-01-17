use strict;
use warnings;
use Test::More;
use Test::NoWarnings;
use Git::Version::Compare qw( looks_like_git eq_git );

my @ok = (

    # actual output from `git --version`
    "git version 1.0.0a\n",
    "git version 2.7.0\n",
    "git version 2.6.4 (Apple Git-63)\n",

    # just the version number
    '0.99.7', '0.99.9l', '1.2.3', '1.2.3', '1.8.0.rc3', '1.8.0', '1.8.0.3',
    '1.8.5.4.19.g5032098', '2.3.0.rc0.36.g63a0e83',

    # Win32 msysgit
    '1.9.4.msysgit.0', '1.9.5.msysgit.1',

    # plausible version numbers
    '1.0.rc4', '1.0rc4', '1.6',

    # tags from git.git
    'v1.0rc4', 'v1.7.12-rc2', 'v1.8.4.5', 'v1.8.5.4-19-g5032098', 'v2.0.0-rc0',
    'v0.99.8-255-g0f8fdc3',  'v1.7.12-301-g382a967',  'v1.5.4.3-197-gdc31cd8',
    'v2.0.0-rc3-5-g50b54fd', 'v1.5.3.7-971-g61fd255', 'v1.5.3.7-1198-g467f42c',

    # the pre-computed aliases from Git::Version::Compare
    '0.99.7a', '0.99.7b', '0.99.7c', '0.99.7d', '0.99.8a', '0.99.8b',
    '0.99.8c', '0.99.8d', '0.99.8e', '0.99.8f', '0.99.8g', '0.99.9a',
    '0.99.9b', '0.99.9c', '0.99.9d', '0.99.9e', '0.99.9f', '0.99.9g',
    '0.99.9h', '1.0.rc1', '0.99.9i', '1.0.rc2', '0.99.9j', '1.0.rc3',
    '0.99.9k', '0.99.9l', '1.0.rc4', '0.99.9m', '1.0.rc5', '0.99.9n',
    '1.0.rc6', '1.0.0a',  '1.0.0b',

    # vendor specific versions
    # GitLab embedded git
    '2.37.1.gl1',
);

# non-git version
my @fail = ( 'this is a test', '1.0203', '1.02_03', );

plan tests => @ok + @fail + 2 + 1;

ok( looks_like_git($_), $_ ) for @ok;
ok( !looks_like_git($_), "'$_' is not a Git version" ) for @fail;

ok( !eval { eq_git( 'not-a-git-version', '1.0.0' ); 1 }, 'not a git version' );
like(
    $@,
    qr/^not-a-git-version does not look like a Git version /,
    '... expected error message'
);
