use strict;
use warnings;
use Test::More;
use App::Prove::Plugin::ShareDirDist;
use File::Spec;

@INC = map { File::Spec->rel2abs($_) } @INC;
delete $ENV{PERL_FILE_SHAREDIR_DIST};

chdir 'corpus/plugin/Foo-Bar-Baz';

App::Prove::Plugin::ShareDirDist->load;

ok $ENV{PERL_FILE_SHAREDIR_DIST}, 'PERL_FILE_SHAREDIR_DIST is set';
note "PERL_FILE_SHAREDIR_DIST = $ENV{PERL_FILE_SHAREDIR_DIST}";

is $ENV{PERL_FILE_SHAREDIR_DIST},'Foo-Bar-Baz=share';

done_testing;
