use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/IPC/PrettyPipe.pm',
    'lib/IPC/PrettyPipe/Arg.pm',
    'lib/IPC/PrettyPipe/Arg/Format.pm',
    'lib/IPC/PrettyPipe/Cmd.pm',
    'lib/IPC/PrettyPipe/DSL.pm',
    'lib/IPC/PrettyPipe/Execute/IPC/Run.pm',
    'lib/IPC/PrettyPipe/Executor.pm',
    'lib/IPC/PrettyPipe/Format.pm',
    'lib/IPC/PrettyPipe/Queue.pm',
    'lib/IPC/PrettyPipe/Queue/Element.pm',
    'lib/IPC/PrettyPipe/Render/Template/Tiny.pm',
    'lib/IPC/PrettyPipe/Renderer.pm',
    'lib/IPC/PrettyPipe/Stream.pm',
    'lib/IPC/PrettyPipe/Stream/Utils.pm',
    'lib/IPC/PrettyPipe/Types.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/arg/iface.t',
    't/arg/render.t',
    't/arg/val.t',
    't/cmd/iface.t',
    't/cmd/val.t',
    't/dsl/arg.t',
    't/dsl/cmd.t',
    't/dsl/iface.t',
    't/dsl/ppipe.t',
    't/lib/IPC/PrettyPipe/Render/Test.pm',
    't/lib/My/Run.pm',
    't/lib/My/Tests.pm',
    't/ppipe/iface.t',
    't/ppipe/plugins.t',
    't/ppipe/val.t',
    't/render/multiple.t',
    't/render/render.t',
    't/render/user.t',
    't/run/t1.t',
    't/run/test.3',
    't/run/testprog.pl',
    't/run/user.t',
    't/stream/iface.t',
    't/stream/parse_spec.t'
);

notabs_ok($_) foreach @files;
done_testing;
