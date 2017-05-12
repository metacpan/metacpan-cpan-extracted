use lib qw (../lib lib);
use warnings;
use strict;
use Test::More 'no_plan';

eval "use MKDoc::Core::Request";
ok (not $@);

eval "use MKDoc::Core::Response";
ok (not $@);

eval "use MKDoc::Core";
ok (not $@);

eval "use MKDoc::Core::Init::Petal";
ok (not $@);

eval "use MKDoc::Core::Plugin";
ok (not $@);

eval "use MKDoc::Core::Error";
ok (not $@);

eval "use MKDoc::Core::Language";
ok (not $@);

eval "use MKDoc::Core::Init";
ok (not $@);

eval "use MKDoc::Core::Plugin::Not_Found";
ok (not $@);

eval "use MKDoc::Core::Plugin::It_Worked";
ok (not $@);

eval "use MKDoc::Setup";
ok (not $@);

eval "use MKDoc::Setup::Core";
ok (not $@);

eval "use MKDoc::Setup::Site";
ok (not $@);


1;


__END__
