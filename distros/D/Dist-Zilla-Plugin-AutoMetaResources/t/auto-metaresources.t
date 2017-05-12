
use strict;
use warnings;

use Test::More tests => 15;
use Test::NoWarnings;
use Test::DZil;

is_deeply getMetadata({}),
    {}
, "no params generate no metadata";


is_deeply getMetadata({ 'bugtracker.rt' => 1}),
    {
        'bugtracker' => {
            'web' => 'https://rt.cpan.org/Public/Dist/Display.html?Name=DZT-Sample',
            'mailto' => 'bug-DZT-Sample@rt.cpan.org'
        }
    }
, "bugrtracker.rt is known";

is_deeply getMetadata({ 'bugtracker.github' => 'user:ajgb' }),
    {
        'bugtracker' => {
            'web' => 'https://github.com/ajgb/dzt-sample/issues',
        }
    }
, "bugrtracker.github is known";

is_deeply getMetadata({ 'bugtracker.bitbucket' => 'user:xenoterracide' }), {
    'bugtracker' => {
        'web' => 'https://bitbucket.org/xenoterracide/dzt-sample/issues',
    }
}, "bugrtracker.bitbucket is known";

is_deeply getMetadata({ 'bugtracker.other' => 1 }),
    { }
, "bugrtracker.other is not recognised";


is_deeply getMetadata({ 'repository.github' => 'user:ajgb' }),
    {
        'repository' => {
            'web' => 'https://github.com/ajgb/dzt-sample',
            'url' => 'git://github.com/ajgb/dzt-sample.git',
            'type' => 'git',
        }
    }
, "repository.github is known";

is_deeply getMetadata({ 'repository.bitbucket' => 'user:xenoterracide' }),
    {
        'repository' => {
            'web' => 'https://bitbucket.org/xenoterracide/dzt-sample',
            'url' => 'git://bitbucket.org:xenoterracide/dzt-sample.git',
            'type' => 'git',
        }
    }
, "repository.bitbucket is known";

is_deeply getMetadata({ 'repository.GitHub' => 'user:ajgb' }),
    {
        'repository' => {
            'web' => 'https://github.com/ajgb/dzt-sample',
            'url' => 'git://github.com/ajgb/dzt-sample.git',
            'type' => 'git',
        }
    }
, "repository.GitHub is known";

is_deeply getMetadata({ 'repository.gitmo' => 1 }),
    {
        'repository' => {
            'web' => 'http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=gitmo/DZT-Sample.git;a=summary',
            'url' => 'git://git.moose.perl.org/DZT-Sample.git',
            'type' => 'git',
        }
    }
, "repository.gitmo is known";

is_deeply getMetadata({ 'repository.catsvn' => 1 }),
    {
        'repository' => {
            'web' => 'http://dev.catalystframework.org/svnweb/Catalyst/browse/DZT-Sample',
            'url' => 'http://dev.catalyst.perl.org/repos/Catalyst/DZT-Sample/',
            'type' => 'svn',
        }
    }
, "repository.catsvn is known";

for (qw(catagits p5sagit dbsrgits)) {
    is_deeply getMetadata({ "repository.$_" => 1 }),
        {
            'repository' => {
                'web' => "http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=$_/DZT-Sample.git;a=summary",
                'url' => "git://git.shadowcat.co.uk/$_/DZT-Sample.git",
                'type' => 'git',
            }
        }
    , "repository.$_ is known";
};

is_deeply getMetadata({ 'homepage' => 'http://myperlprojects.org/%{lcdist}/' } ),
    {
        'homepage' => 'http://myperlprojects.org/dzt-sample/'
    }
, "custom params passed and processed";



sub getMetadata {
    my $args = shift;

    my $tzil = Builder->from_config(
        { dist_root => 't/does-not-exist' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    [ AutoMetaResources => $args ],
                ),
            },
        },
    );

    return $tzil->distmeta->{resources};
}

