use strict;
use warnings FATAL => 'all';

use Test::Requires { 'Dist::Zilla::Plugin::MakeMaker::Awesome' => '0.13' };
use Test::More;
BEGIN {
    plan skip_all => 'new [MakeMaker] and old [MakeMaker::Awesome] are not compatible'
        if not eval { Dist::Zilla::Plugin::MakeMaker::Awesome->VERSION(0.23); 1 }
            and eval { Dist::Zilla::Plugin::MakeMaker->VERSION(5.022); 1 };
}

use Path::Tiny;
my $code = path('t', '01-basic.t')->slurp_utf8;

$code =~ s/'MakeMaker'/'MakeMaker::Awesome'/g;

eval $code;
die $@ if $@;
