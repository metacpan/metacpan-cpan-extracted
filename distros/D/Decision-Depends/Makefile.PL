use strict;
use warnings;
use inc::Module::Install;

name 'Decision-Depends';
license 'gpl3';
auto_license( holder => 'Smithsonian Astrophysical Observatory' );
all_from 'lib/Decision/Depends.pm';

resources(
    license => 'http://www.gnu.org/licenses/gpl-3.0.html',

    # bitbucket is the fiducial repo.  it's mirrored to github
    # 'cause that seems to be what people prefer

    #   repository => 'https://bitbucket.org/djerius/decision-depends',

    # stuck at CPAN::Meta::Spec version 1.4. due to Module::Install
    repository => 'https://github.com/djerius/decision-depends',
);

author_tests( 'xt' );

cpanfile;

WriteAll;
