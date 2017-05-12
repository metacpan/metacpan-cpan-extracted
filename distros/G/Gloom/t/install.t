use strict;
use Test::More;

my ($t, $module_file);
BEGIN {
    $t = -e 't' ? 't' : 'test';
    @INC = grep { not /[\\\/]inc$/ } @INC;
    eval 'require Module::Install; 1' or do {
        plan skip_all => 'This test requires Module::Install';
        return;
    };

    $module_file = "$t/lib/Foo/Gloom.pm";
    unlink($module_file) if -e $module_file;
    die if -e $module_file;
    system("(cd $t; $^X Makefile.PL)");
    plan tests => 1;
}

use File::Path;
END {
    unlink $module_file;
    rmtree "$t/inc";
}

use File::Basename;
use lib dirname(__FILE__) . '/lib', 'inc';

use Foo;

my $f = Foo->new(
    this => 'ok',
);

is $f->this, 'ok', 'Everything is OK';
