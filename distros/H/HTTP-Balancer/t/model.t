use Modern::Perl;
use Test::More;
use local::lib 'local';

BEGIN {
    use_ok 'HTTP::Balancer::Model';
}

is_deeply (
    [HTTP::Balancer::Model->models],
    [qw(HTTP::Balancer::Model::Backend HTTP::Balancer::Model::Host)],
    "make sure all current models defined",
);

HTTP::Balancer::Config->instance->dbpath("/tmp/http-balancer");

{
    package HTTP::Balancer::Model::Foo;
    use Modern::Perl;
    use Moose;
    use MooseX::Storage;
    extends qw(HTTP::Balancer::Model);
    with Storage(
        format  => 'YAML',
        io      => 'File',
    );

    has id => (
        is  => 'rw',
        isa => 'Num',
    );

    has bar => (
        is  => 'rw',
        isa => 'Str',
    );
}

my $foo = HTTP::Balancer::Model::Foo->new( bar => "blah" );

is (
    $foo->model_name,
    "foo",
    "model_name is the lowercase last package name",
);

is (
    $foo->model_dir,
    "/tmp/http-balancer/foo",
    "model_dir is dbpath followed with model_name",
);

is (
    $foo->path,
    undef,
    "path should be undefined before saving",
);

use Path::Tiny;
path($foo->model_dir)->remove;
path($foo->model_dir)->mkpath;

$foo->save;

is (
    $foo->id,
    1,
    "id would be generated automatically and auto-increment"
);

is (
    $foo->path,
    "/tmp/http-balancer/foo/1",
    "path could be calculated after id has been set",
);

for (1..30) {
    HTTP::Balancer::Model::Foo->new( bar => "blahblah" )->save;
}

is_deeply (
    [map { s{/tmp/http-balancer/foo/}{}; $_ } HTTP::Balancer::Model::Foo->glob],
    [1..31],
    "glob() will return sorted paths",
);

is_deeply (
    [map { $_->id } HTTP::Balancer::Model::Foo->all],
    [1..31],
    "all() are sorted either",
);

is (
    HTTP::Balancer::Model::Foo->find(id => 5)->id,
    5,
    "find() returns one object satisfiying given condition",
);

is_deeply (
    [map { $_->id } HTTP::Balancer::Model::Foo->where(bar => "blahblah")],
    [2..31],
    "where() returns all objects satisfiying given condition",
);

done_testing;
