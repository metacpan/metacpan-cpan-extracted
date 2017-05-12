
use strict;
use warnings;
use Test::More tests => 2;
use Test::Exception;

use Path::Class;
use File::Path;



use lib "lib";

use Devel::CoverX::Covered::Db;


my $test_dir = dir(qw/ t data cover_db /);


diag("Create db file");

my $count;

ok(my $covered_db = Devel::CoverX::Covered::Db->new(dir => $test_dir), "Create DB ok");
ok(
    $covered_db->schema_version >= 0.01 && $covered_db->schema_version < 2,
    "  and got reasonable schema_version",
);



   
__END__
