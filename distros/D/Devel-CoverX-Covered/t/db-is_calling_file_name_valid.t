
use strict;
use warnings;
use Test::More tests => 7;
use Test::Exception;

use Path::Class;
use File::Path;



use lib "lib";

use Devel::CoverX::Covered::Db;


my $test_dir = dir(qw/ t data cover_db /);


diag("Test is_calling_file_name_valid");
ok(my $covered_db = Devel::CoverX::Covered::Db->new(dir => $test_dir), "Create DB ok");

ok(   $covered_db->is_calling_file_name_valid("fdlsdjf"), "  regular file is valid");
ok( ! $covered_db->is_calling_file_name_valid("-e"), "  -1  is not valid");
ok( ! $covered_db->is_calling_file_name_valid("hey/prove"), "  prove  is not valid");
ok(   $covered_db->is_calling_file_name_valid("hey/improve"), "  prove  is valid");
ok( ! $covered_db->is_calling_file_name_valid("hey/prove.bat"), "  prove.bat  is not valid");
ok(   $covered_db->is_calling_file_name_valid("hey/provement"), "  provement  is valid");


   
__END__
