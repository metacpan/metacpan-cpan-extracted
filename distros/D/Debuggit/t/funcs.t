use strict;
use warnings;

use Test::More      0.88                            ;
use Test::Output    0.16    qw<:tests :functions>   ;

use Debuggit(DEBUG => 2);


our $CONFIG =
{
    db          =>  DEBUG ? 'dev' : 'prod',
};
ok Debuggit::add_func(CONFIG => 1, sub
{
    my ($sub, $key) = @_;
    return $CONFIG->{$key};
}), "successful add_func";
note explain "PROCS is", \%Debuggit::PROCS;
stderr_is { debuggit(2 => 'db:', CONFIG => 'db'); } "db: dev\n", "add func (2 args) works";
ok Debuggit::add_func(CONFIG => 1, sub
{
    my ($sub, $key) = @_;
    return "$key:", $CONFIG->{$key};
}), "successful add_func";
stderr_is { debuggit(2 => CONFIG => 'db'); } "db: dev\n", "replace func works";

my @test = ('db');
foreach (@test)
{
    stderr_is { debuggit(2 => CONFIG => $_); } "db: dev\n", 'func with $_ arg works';
}

my $sepline = '=' x 40;
my $output = 'expected output';
ok Debuggit::add_func(SEPARATOR => 0, sub
{
    $Debuggit::output->("$sepline\n");
    return ();
}), "successful add_func";
stderr_is { debuggit(2 => SEPARATOR => $output); } "$sepline\n$output\n", "add func (0 args) works";

my $self =
{
    _data       =>  {
                        foo =>  'bar',
                    },
};
bless $self, 'Foo::Bar';
ok Debuggit::add_func(OBJDATA => 2, sub
{
    my ($sub, $obj, $field) = @_;
    return (ref($obj) . "->$field =", $obj->{'_data'}->{$field});
}), "successful add_func";
stderr_is { debuggit(2 => OBJDATA => $self, 'foo'); } "Foo::Bar->foo = bar\n", "add func (2 args) works";

ok Debuggit::remove_func('CONFIG'), "remove func successful";
stderr_is { debuggit(2 => $output, CONFIG => 'db'); } "$output CONFIG db\n", "removed added func";


done_testing;
