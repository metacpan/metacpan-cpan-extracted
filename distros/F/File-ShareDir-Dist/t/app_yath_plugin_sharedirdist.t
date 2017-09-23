use strict;
use warnings;
use Test::More;
use App::Yath::Plugin::ShareDirDist;
use File::Spec;

@INC = map { File::Spec->rel2abs($_) } @INC;
delete $ENV{PERL_FILE_SHAREDIR_DIST};

chdir 'corpus/plugin/Foo-Bar-Baz';

App::Yath::Plugin::ShareDirDist->pre_init;

ok $ENV{PERL_FILE_SHAREDIR_DIST}, 'PERL_FILE_SHAREDIR_DIST is set';
note "PERL_FILE_SHAREDIR_DIST = $ENV{PERL_FILE_SHAREDIR_DIST}";

is $ENV{PERL_FILE_SHAREDIR_DIST},'Foo-Bar-Baz=share';

done_testing;
