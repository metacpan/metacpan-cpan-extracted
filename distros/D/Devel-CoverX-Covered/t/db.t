
use strict;
use warnings;
use Test::More tests => 39;
use Test::Exception;
use Test::Differences;

use Data::Dumper;
use Path::Class;
use File::Path;



use lib "lib", "t/lib";
use Test::Covered;
my $test_dir = dir(qw/ t data cover_db /);

use Devel::CoverX::Covered::Db;
use Devel::CoverX::Covered;



diag("Create db file");
lives_ok(
    sub { Devel::CoverX::Covered::Db->new() },
    "Create DB ok with no params ok",
);

my $count;

ok(my $covered_db = Devel::CoverX::Covered::Db->new(dir => $test_dir), "Create DB ok");
ok($covered_db->db, "  and got db object");
is(
    scalar @{[ glob( file($test_dir->parent, "covered") . "/*.db") ]},
    1,
    "  and SQLite db file",
);



like(
    "hey/prove.bat",
    $covered_db->rex_skip_calling_file,
    "  default skip rex matches prove.bat",
);
unlike(
    "hey/baberiba",
    $covered_db->rex_skip_calling_file,
    "  default skip rex doesn't match nonsense",
);



$covered_db->db->query("select count(*) from covered_calling_metric")->into( $count );
is($count, 0, "  and got empty table");

$covered_db->db->query("select count(*) from file")->into( $count );
is($count, 0, "  and got empty table");




diag("Connect to existing db file");
ok($covered_db = Devel::CoverX::Covered::Db->new(dir => $test_dir), "Create DB ok");
ok(my $db = $covered_db->db, "  and got db object");

$db->query("select count(*) from covered_calling_metric")->into( $count );
is($count, 0, "  and got empty table");





diag("reset_calling_file");

sub count_rows {
    my ($db, $table) = @_;
    $table ||= "covered_calling_metric";
    $db->query("select count(*) from $table")->into( my $count );
    return $count;
}

sub insert_dummy_calling_file {
    my ($covered_db, %p) = @_;

    for my $name (qw/ calling_file covered_file /) {
        $p{$name} &&= file( $covered_db->dir, $p{$name} ) . "";
    }

    my %args = (
        metric_type      => "subroutine",
        calling_file     => "",
        covered_file     => "",
        covered_row      => "",
        covered_sub_name => "",
        metric           => 0,
        %p,
    );

    $covered_db->report_metric_coverage(%args);
};

is(count_rows($db), 0, "No rows");
insert_dummy_calling_file(
    $covered_db,
    calling_file => "a.t",
    covered_file => "x.pm",
);
insert_dummy_calling_file(
    $covered_db,
    calling_file     => "b.t",
    covered_file     => "x.pm",
    covered_row      => 10,
    covered_sub_name => "b",
);
insert_dummy_calling_file(
    $covered_db,
    calling_file     => "c.t",
    covered_file     => "x.pm",
    covered_row      => 20,
    covered_sub_name => "c",
);
is(count_rows($db), 3, "Fixture rows");
is_deeply(
    [ $covered_db->covered_files() ],
    [ file(qw/ t data cover_db x.pm /) . "" ],
    "source_files found one file",
);
is_deeply(
    [ $covered_db->test_files() ],
    [ sort ( map { file(qw/ t data cover_db /, "$_.t") . "" } qw/ a b c / )  ],
    "test_files found three files",
);


ok($covered_db->reset_calling_file(file(qw/ t data cover_db a.t /)), "reset_calling_file a.t");
is(count_rows($db), 2, "One less row");





diag("test_files_covering, source_files_covered_by");
is_deeply(
    [ $covered_db->test_files_covering(file(qw/ t data cover_db x.pm /) . "") ],
    [],
    "test_files_covering with subroutine metric 0 finds nothing",
);
is_deeply(
    [ $covered_db->test_files_covering(file(qw/ t data cover_db x.pm /) . "", "missing_sub") ],
    [],
    "test_files_covering + sub with subroutine metric 0 finds nothing",
);



is(count_rows($db), 2, "  Fixture rows");
is(count_rows($db, "file"), 4, "  Fixture file rows");
insert_dummy_calling_file(
    $covered_db,
    calling_file     => "c.t",
    covered_file     => "x.pm",
    covered_row      => 20,
    covered_sub_name => "c",
    metric           => 1,
);
is(count_rows($db), 3, "  Fixture rows");
is(count_rows($db, "file"), 4, "  Fixture file rows");
insert_dummy_calling_file(
    $covered_db,
    calling_file     => "c.t",
    covered_file     => "x.pm",
    covered_row      => 30,
    covered_sub_name => "a",
    metric           => 1,
);
is(count_rows($db), 4, "  Fixture rows");
is(count_rows($db, "file"), 4, "  Fixture file rows");
my @covered;
is_deeply(
    [ @covered = $covered_db->test_files_covering(file($covered_db->dir, "x.pm") . "") ],
    [ file(qw/ t data cover_db c.t /) . "" ],
    "test_files_covering with two subroutine metric 1 finds the correct test file",
) or die(Dumper([ @covered ]));

is_deeply(
    [ @covered = $covered_db->test_files_covering(file($covered_db->dir, "x.pm") . "", "a") ],
    [ file(qw/ t data cover_db c.t /) . "" ],
    "test_files_covering + existing sub with two subroutine metric 1 finds the correct test file",
) or die(Dumper([ @covered ]));
is_deeply(
    [
        @covered = $covered_db->test_files_covering(
            file($covered_db->dir, "x.pm") . "",
            "missing_sub",
        ),
    ],
    [ ],
    "test_files_covering + missing sub finds nothing",
) or die(Dumper([ @covered ]));


is_deeply(
    [ $covered_db->source_files_covered_by(file(qw/ t data cover_db c.t /) . "") ],
    [ file(qw/ t data cover_db x.pm /) . "" ],
    "source_files_covered_by finds the correct source file",
);



insert_dummy_calling_file(
    $covered_db,
    calling_file     => "a.t",
    covered_file     => "x.pm",
    covered_row      => 30,
    covered_sub_name => "f",
    metric           => 1,
);
is_deeply(
    [ sort $covered_db->test_files_covering(file(qw/ t data cover_db x.pm /) . "") ],
    [ file(qw/ t data cover_db a.t /) . "", file(qw/ t data cover_db c.t /) . "" ],
    "test_files_covering with two subroutine metric 1 finds the correct test files",
);
is_deeply(
    [ sort $covered_db->test_files_covering(file(qw/ t data cover_db x.pm /) . "", "f") ],
    [ file(qw/ t data cover_db a.t /) . "" ],
    "test_files_covering + sub with two subroutine metric 1 finds the correct test files",
);

is_deeply(
    [ $covered_db->source_files_covered_by(file(qw/ t data cover_db c.t /) . "") ],
    [ file(qw/ t data cover_db x.pm /) . "" ],
    "source_files_covered_by finds the correct source file",
);




diag("covered_subs");

insert_dummy_calling_file(
    $covered_db,
    calling_file     => "a.t",
    covered_file     => "x.pm",
    covered_row      => 10,
    covered_sub_name => "b",
    metric           => 3,
);

insert_dummy_calling_file(
    $covered_db,
    calling_file     => "a.t",
    covered_file     => "x.pm",
    covered_row      => 1000,
    covered_sub_name => "a",
    metric           => 7,
);

eq_or_diff(
    [ $covered_db->covered_subs(file(qw/ t data cover_db x.pm /) . "") ],
    [
        [ "b", 3 ],  #One undef metric, one 3
        [ "c", 1 ],
        [ "a", 1 ],  #On one row
        [ "f", 1 ],
        [ "a", 7 ],  #On another row
    ],
    "covered_subs finds the correc sub names and coverage count",
);



__END__
