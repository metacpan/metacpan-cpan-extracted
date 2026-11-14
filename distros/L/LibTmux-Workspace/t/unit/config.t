use v5.44;
use Test2::V1;
use Scalar::Util qw(blessed);
my $loaded = eval { require LibTmux::Workspace; 1 };
T2->ok($loaded, 'separate workspace consumer loads');
unless ($loaded) { T2->diag($@); T2->done_testing; exit }
my $data = {
    schema   => 'libtmux.workspace/v1',
    sessions => [
        {
            name    => 'main',
            windows => [{name => 'api', panes => [{command => ['/bin/cat']}]}]
        }
    ]
};
my $workspace = LibTmux::Workspace->new(config => $data);
$data->{sessions}[0]{name} = 'changed';
T2->is($workspace->plan->{sessions}[0]{name},
    'main', 'configuration and dry-run own their inputs');
my $copy = $workspace->plan;
$copy->{sessions}[0]{name} = 'edited';
T2->is($workspace->plan->{sessions}[0]{name},
    'main', 'plan export cannot change loader meaning');

for my $case (
    {schema => 'future', sessions => []},
    {
        schema   => 'libtmux.workspace/v1',
        sessions => [{name => 'x', windows => []}]
    },
    {
        schema   => 'libtmux.workspace/v1',
        sessions => [
            {
                name    => 'x',
                windows =>
                    [{panes => [{command => ['cat'], shell_command => 'cat'}]}]
            }
        ]
    },
    {schema => 'libtmux.workspace/v1', sessions => [], mcp => true}
    )
{
    my $error;
    try { LibTmux::Workspace->new(config => $case) } catch ($caught) {
        $error = $caught
    }
    T2->ok(blessed($error) && $error->isa('LibTmux::Workspace::X::Config'),
        'invalid configuration fails before I/O');
}
T2->done_testing;
