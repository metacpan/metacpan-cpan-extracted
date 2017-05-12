
use strict;
use warnings;
use Test::More tests => 7;
use Test::Exception;

use Path::Class;
use File::Path;



use lib "lib";

use Devel::CoverX::Covered::Db;


my $test_dir = dir(qw/ t data cover_db /);


diag("Test is_source_file_name_valid");
ok(
    my $covered_db = Devel::CoverX::Covered::Db->new(
        dir                  => $test_dir,
        rex_skip_source_file => [ qr/abc/, qr/de f/xi ],
    ),
    "Create DB ok",
);

ok(   $covered_db->is_source_file_name_valid("fdlsdjf"), "regular file is valid");
ok(   $covered_db->is_source_file_name_valid("fdABClsdjf"), "other case is valid");
ok( ! $covered_db->is_source_file_name_valid("abc"), "first match is not valid");
ok( ! $covered_db->is_source_file_name_valid("def"), "second match is not valid");
ok( ! $covered_db->is_source_file_name_valid("DEF.lkd"), "other case invalid");
ok( ! $covered_db->is_source_file_name_valid("defabc"), "both invalid");


   
__END__
