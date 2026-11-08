use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use Ekorn::Pipeline;
use Ekorn::Pipeline::Errors;
use Ekorn::Pipeline::Gather ();
use Ekorn::Pipeline::Pipes;
use Ekorn::Pipeline::Stages::Batch ();
use Ekorn::Pipeline::Stages::Flow  ();
use Ekorn::Pipeline::Stages::Taps  ();
use Ekorn::Pipeline::Stop          ();

# Imported functions are cleaned out of each package, so they can't be
# called as methods.
my %imported = (
    'Ekorn::Pipeline'                => [qw(croak  croakf is_coderef is_ref)],
    'Ekorn::Pipeline::Gather'        => [qw(croakf is_coderef)],
    'Ekorn::Pipeline::Stages::Batch' => [qw(croakf gather is_coderef)],
    'Ekorn::Pipeline::Stages::Flow'  => [qw(croakf gather is_coderef)],
    'Ekorn::Pipeline::Stages::Taps'  =>
        [qw(croakf gather is_coderef is_plain_scalarref openhandle)],
    'Ekorn::Pipeline::Stop' => [qw(croak)],
);

for my $pkg (sort keys %imported) {
    subtest $pkg => sub {
        ok !$pkg->can($_), "no $_" for @{ $imported{$pkg} };
    };
}

subtest 'what the packages need is kept' => sub {
    ok +Ekorn::Pipeline::Errors->can('import'), 'Errors can export';
    ok +Ekorn::Pipeline::Errors->can('croakf'), 'and keeps croakf';
    ok +Ekorn::Pipeline::Gather->can('import'), 'Gather can export';
    ok +Ekorn::Pipeline::Gather->can('gather'), 'and keeps gather';
    my @stages = map { "Ekorn::Pipeline::Stages::$_" } qw(Batch Flow Taps);
    ok $_->can('import'),                     "$_ can export" for @stages;
    ok +Ekorn::Pipeline::Stop->can('import'), 'Stop can export';
    ok +Ekorn::Pipeline::Pipes->can($_),      "Pipes can $_" for qw(pipe tap);

    my $p = Ekorn::Pipeline->new(sub { $_ * 2 });
    is [$p->(1, 2)], [2, 4], 'a pipeline can be called';
    is '' . dies { Ekorn::Pipeline::Stop->throw },
        "Stop used outside a pipeline\n",
        'a stop explains itself as a string';
};

subtest 'the version is dotted' => sub {
    like $Ekorn::Pipeline::VERSION, qr( \A v \d+ \. \d+ \. \d+ \z )x;
};

done_testing;
