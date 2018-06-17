#!perl

use strict;
use warnings;

use Cwd            ('abs_path');
use File::Basename ('dirname');
use File::Spec     ();
use Test::More;

#####################################################################
# Class Tests

{
    my @TEST_INC = @INC;
    local @INC = (File::Spec->catdir(abs_path(dirname($0)), "lib"), @TEST_INC);
    use_ok("ShareDir::TestClass");
}
my $class_file = File::ShareDir->can("class_file")->('ShareDir::TestClass', 'test_file.txt');
ok(-f $class_file, 'class_file ok');
my $module_file = File::ShareDir->can("module_file")->('File::ShareDir', 'test_file.txt');
is($class_file, $module_file, 'class_file matches module_file for subclass');

done_testing;
