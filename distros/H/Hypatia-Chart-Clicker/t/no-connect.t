#!perl -T
use strict;
use warnings;
use Test::More tests => 15;
use Scalar::Util qw(blessed);
use Hypatia;

my $hypatia=Hypatia->new({
    back_end=>"Chart::Clicker",
    graph_type=>"Line",
    dbi=>{
        dsn=>"fakedsn",
        username=>"jdoe",
        password=>'p@$$w0rD1234',
        table=>"schema.table",
        connect=>0
    },
    columns=>{"x"=>"col1","y"=>"col2"}
});



isa_ok($hypatia,"Hypatia");
ok(!$hypatia->dbi->dbh);
isa_ok($hypatia->engine,"Hypatia::Chart::Clicker::Line");
ok($hypatia->dbi->dsn eq 'fakedsn');
ok($hypatia->dbi->username eq 'jdoe');
ok($hypatia->dbi->password eq 'p@$$w0rD1234');
ok($hypatia->dbi->table eq 'schema.table');
ok($hypatia->dbi->connect == 0);
ok(blessed($hypatia->cols) eq "Hypatia::Columns");
ok($hypatia->columns->{x} eq "col1");
ok($hypatia->columns->{y} eq "col2");
ok(scalar(keys %{$hypatia->columns}) == 2);

my $input={"a1"=>[1..10],"a2"=>[2,6,5,-7,1.4,9,9,0,8,2.71828]};

undef $hypatia;

$hypatia=Hypatia->new({
    back_end=>"Hypatia::Chart::Clicker",
    graph_type=>"Line",
    input_data=>$input,
    columns=>{"x"=>"a1","y"=>"a2"},
});

isa_ok($hypatia,"Hypatia");
ok(!$hypatia->use_dbi);
ok($hypatia->has_input_data);



