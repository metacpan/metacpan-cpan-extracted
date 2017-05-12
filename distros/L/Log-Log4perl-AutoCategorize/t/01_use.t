#! perl

BEGIN {
    # it seems unholy to do this, but perl Core does..
    chdir 't' if -d 't';
    use lib '../lib';
    $ENV{PERL5LIB} = '../lib';    # so children will see it too
    unlink <out.01*>;
}

use Test::More (tests => 1);

use Log::Log4perl::AutoCategorize;
ok (1, "use Log::Log4perl::AutoCategorize didnt bomb");

