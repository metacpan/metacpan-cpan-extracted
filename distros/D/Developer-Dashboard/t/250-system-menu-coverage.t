#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More;
use JSON::XS ();
use File::Spec;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::GoRoutine qw(spawn wait_process);
use Developer::Dashboard::System::Menu;

my $menu = Developer::Dashboard::System::Menu::menu();
is( Developer::Dashboard::System::Menu::menu(), $menu,
    'menu returns the process-local singleton' );

for my $case (
    [ sub { Developer::Dashboard::System::Menu::_id( {} ) }, qr/invalid System::Menu object/ ],
    [ sub { Developer::Dashboard::System::Menu::_id('not-an-object') }, qr/invalid System::Menu object/ ],
    [ sub { Developer::Dashboard::System::Menu::_id( bless { id => '' }, 'Developer::Dashboard::System::Menu' ) }, qr/invalid System::Menu object/ ],
    [ sub { $menu->run( {} ) }, qr/requires an arrayref/ ],
    [ sub { Developer::Dashboard::System::Menu::_text( undef, 'value' ) }, qr/plain scalar/ ],
    [ sub { Developer::Dashboard::System::Menu::_text( [] , 'value' ) }, qr/plain scalar/ ],
    [ sub { Developer::Dashboard::System::Menu::_click_stay( 'yes', 'setting' ) }, qr/0 or 1/ ],
    [ sub { Developer::Dashboard::System::Menu::_click_stay( undef, 'setting' ) }, qr/0 or 1/ ],
    [ sub { Developer::Dashboard::System::Menu::_click_stay( [], 'setting' ) }, qr/0 or 1/ ],
    [ sub { Developer::Dashboard::System::Menu::_menu_spec( {}, 'menu' ) }, qr/requires items/ ],
    [ sub { Developer::Dashboard::System::Menu::_menu_spec( { items => [], wrong => 1 }, 'menu' ) }, qr/unknown option/ ],
    [ sub { Developer::Dashboard::System::Menu::_menu_spec( { items => {} }, 'menu' ) }, qr/requires items/ ],
    [ sub { Developer::Dashboard::System::Menu::_menu_spec( 'items', 'menu' ) }, qr/arrayref or hashref/ ],
) {
    my $ok = eval { $case->[0]->(); 1 };
    ok( !$ok, 'invalid input throws' );
    like( $@, $case->[1], 'invalid input identifies the contract' );
}
is( Developer::Dashboard::System::Menu::_id( bless { id => 'named-menu' }, 'Developer::Dashboard::System::Menu' ),
    'named-menu', 'menu identity accepts a non-empty identifier' );
is( Developer::Dashboard::System::Menu::_text( 'plain ASCII', 'value' ), 'plain ASCII',
    'plain scalar text without UTF-8 bytes is preserved' );
my $unicode_text = 'café';
is( Developer::Dashboard::System::Menu::_text( $unicode_text, 'value' ), $unicode_text,
    'UTF-8-flagged text is preserved without byte decoding' );
is( Developer::Dashboard::System::Menu::_click_stay(0, 'setting'), 0,
    'click_stay preserves the valid false setting' );
my ( $default_click_stay, $empty_menu_items ) =
    Developer::Dashboard::System::Menu::_menu_spec( { items => [] }, 'menu' );
is( $default_click_stay, 0, 'menu hash defaults click_stay to false when omitted' );
is_deeply( $empty_menu_items, [], 'menu hash returns its items array' );

my $builder = bless { id => 'coverage-menu' }, 'Developer::Dashboard::System::Menu';
for my $case (
    [ [], qr/each menu setting must be a hashref/ ],
    [ {}, qr/requires name/ ],
    [ { name => 'a' }, qr/requires icon/ ],
    [ { name => '', icon => 'x' }, qr/non-empty name/ ],
    [ { name => 'a', icon => 'x', unknown => 1 }, qr/unknown menu setting/ ],
    [ { name => 'a', icon => 'x', menu => [], click => 'x' }, qr/both menu and click/ ],
    [ { name => 'a', icon => 'x', menu => 'x' }, qr/menu must be/ ],
    [ { name => 'a', icon => 'x', click_stay => 2 }, qr/0 or 1/ ],
    [ { name => 'a', icon => 'x', click => [] }, qr/click must be/ ],
) {
    my ( %seen, %items );
    my $ok = eval { $builder->_build_item( $case->[0], undef, \%seen, \%items, 0 ); 1 };
    ok( !$ok, 'malformed menu item throws' );
    like( $@, $case->[1], 'menu error describes malformed item' );
}

my ( %seen, %items );
my ($root, $wire) = $builder->_build_item(
    { name => 'root', icon => 'R', menu => { click_stay => 1, items => [
        { name => 'child', icon => 'C', click => 'next' },
    ] } }, undef, \%seen, \%items, 0,
);
is( $root->{children}[0]{click_stay}, 1, 'nested menu click_stay default reaches child item' );
is( $wire->{menu}[0]{click}, 'text', 'plain click value is represented in native wire format' );
my $duplicate = eval {
    $builder->_build_item( { name => 'child', icon => 'x' }, undef, \%seen, \%items, 0 ); 1;
};
ok( !$duplicate, 'duplicate item name is rejected across the menu tree' );
like( $@, qr/duplicate menu name/, 'duplicate-name diagnostic is explicit' );
is( $root->name, 'root', 'menu item exposes its name' );
is( $root->menu, $builder, 'menu item exposes its root menu' );
is( $root->icon, 'R', 'menu item exposes its current icon' );
my $bad_icon = eval { $root->icon( 'new', 'extra' ); 1 };
ok( !$bad_icon, 'menu item rejects extra icon arguments' );
like( $@, qr/exactly one value/, 'icon arity error is explicit' );
my $removed_icon = bless { root => $builder, name => 'gone', removed => 1 },
    'Developer::Dashboard::System::Menu::Item';
my $removed_update = eval { $removed_icon->icon('x'); 1 };
ok( !$removed_update, 'removed menu item cannot be updated' );
like( $@, qr/cannot update removed menu item/, 'removed-item error is explicit' );

my $state = { running => 0, events => [] };
{
    no warnings 'redefine';
    local *Developer::Dashboard::System::Menu::_start = sub { $state->{started}++ };
    local *Developer::Dashboard::System::Menu::_running = sub { $state->{running} };
    local *Developer::Dashboard::System::Menu::_command_json = sub { push @{ $state->{commands} }, $_[0] };
    local *Developer::Dashboard::System::Menu::_read_events = sub {
        return shift @{ $state->{events} } if @{ $state->{events} };
        $state->{running} = 0;
        return '';
    };
    local *Developer::Dashboard::System::Menu::_stop = sub { $state->{stopped}++; $state->{running} = 0 };

    my $callback_count = 0;
    my $run_menu = bless { id => 'event-menu' }, 'Developer::Dashboard::System::Menu';
    $state->{running} = 1;
    $state->{events} = [
        "{bad-json}\n",
        JSON::XS->new->canonical->encode({ event => 'other', name => 'cb' }) . "\n",
        JSON::XS->new->canonical->encode({ event => 'click', name => 'missing' }) . "\n",
        JSON::XS->new->canonical->encode({ event => 'click', name => 'cb' }) . "\n",
        JSON::XS->new->canonical->encode({ event => 'click', name => 'text' }) . "\n",
    ];
    my $run_ok = eval {
        $run_menu->run([
            { name => 'cb', icon => 'a', click => sub { $callback_count++ } },
            { name => 'text', icon => 'b', click => 'updated' },
        ]);
        1;
    };
    ok( $run_ok, 'event loop accepts and processes helper event stream' ) or diag $@;
    is( $callback_count, 1, 'callback click dispatches exactly once' );
    is( $state->{running}, 0, 'event loop exits when the native helper stops' );

    my $active_menu = bless { id => 'active-menu' }, 'Developer::Dashboard::System::Menu';
    $state->{running} = 1;
    my ( $built_item, $active_rt );
    {
        local *Developer::Dashboard::System::Menu::_read_events = sub {
            return '' if $state->{active_actions_done}++;
            $active_rt = $active_menu->_runtime;
            $built_item = $active_rt->{items}{'remove-me'};
            my $reentrant_ok = eval { $active_menu->run([]); 1 };
            ok( !$reentrant_ok, 'active menu refuses a second simultaneous run' );
            like( $@, qr/already active/, 'reentrant run error identifies the active lifecycle' );
            $active_menu->remove('remove-me');
            ok( !exists $active_rt->{items}{nested}, 'removing a parent recursively forgets descendants' );
            ok( $built_item->{removed}, 'removed item is marked unavailable' );
            $built_item->remove;
            $active_menu->remove('not-present');
            ok( Developer::Dashboard::System::Menu::_shutdown_active_helpers(),
                'shutdown helper handles an active runtime explicitly' );
            my @shutdown_warnings;
            {
                local *Developer::Dashboard::System::Menu::_stop = sub {
                    die "simulated shutdown failure\n";
                };
                local $SIG{__WARN__} = sub { push @shutdown_warnings, @_ };
                $state->{running} = 1;
                ok( Developer::Dashboard::System::Menu::_shutdown_active_helpers(),
                    'shutdown cleanup remains best-effort after a stop error' );
            }
            like( join( '', @shutdown_warnings ), qr/shutdown cleanup failed: simulated shutdown failure/,
                'shutdown cleanup failure is reported visibly' );
            $state->{running} = 0;
            ok( Developer::Dashboard::System::Menu::_shutdown_active_helpers(),
                'shutdown cleanup handles an active menu whose helper already stopped' );
            my $empty_remove = eval { $active_menu->remove(''); 1 };
            ok( !$empty_remove, 'remove refuses an empty name' );
            like( $@, qr/non-empty name/, 'empty remove error is explicit' );
            is( $active_menu->stop, $active_menu, 'stop returns the menu object' );
            is( $active_rt->{active}, 0, 'stop marks active menu runtime inactive' );
            my $restart_ok = eval { $active_menu->run([]); 1 };
            ok( $restart_ok, 'menu can start a new run after stop during the prior event callback' )
                or diag $@;
            return '';
        };
        $active_menu->run([
            { name => 'remove-me', icon => 'x', menu => [ { name => 'nested', icon => 'y' } ] },
        ]);
    }
    ok( $state->{stopped} > 0, 'stop asks the running native helper to stop' );

    my $event_stop_menu = bless { id => 'event-stop-menu' }, 'Developer::Dashboard::System::Menu';
    $state->{running} = 1;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::System::Menu::_start = sub {};
        local *Developer::Dashboard::System::Menu::_running = sub { $state->{running} };
        local *Developer::Dashboard::System::Menu::_command_json = sub {};
        local *Developer::Dashboard::System::Menu::_read_events = sub {
            $event_stop_menu->stop;
            return '';
        };
        local *Developer::Dashboard::System::Menu::_stop = sub {
            $state->{event_stop_count}++;
            $state->{running} = 0;
        };
        is( $event_stop_menu->run([]), $event_stop_menu,
            'stop from the active event loop returns its menu object' );
        is( $state->{event_stop_count}, 1,
            'stop signals the native helper while it is running' );
    }

    my $error_menu = bless { id => 'error-menu' }, 'Developer::Dashboard::System::Menu';
    $state->{running} = 1;
    $state->{events} = [];
    local *Developer::Dashboard::System::Menu::_command_json = sub { die "transport failed\n" };
    my $error_ok = eval { $error_menu->run([]); 1 };
    ok( !$error_ok, 'native command transport failure propagates from run' );
    like( $@, qr/transport failed/, 'run preserves native transport failure text' );

    my $start_error_menu = bless { id => 'start-error-menu' }, 'Developer::Dashboard::System::Menu';
    local *Developer::Dashboard::System::Menu::_start = sub { die "start failed\n" };
    local *Developer::Dashboard::System::Menu::_running = sub { 0 };
    my $start_error_ok = eval { $start_error_menu->run([]); 1 };
    ok( !$start_error_ok, 'native startup failure propagates from run' );
    like( $@, qr/start failed/, 'run retains the native startup error' );
}

{
    no warnings 'redefine';
    my $idle_menu = bless { id => 'idle-menu' }, 'Developer::Dashboard::System::Menu';
    my @commands;
    my $stop_count = 0;
    local *Developer::Dashboard::System::Menu::_running = sub { 0 };
    local *Developer::Dashboard::System::Menu::_command_json = sub { push @commands, $_[0] };
    local *Developer::Dashboard::System::Menu::_stop = sub { ++$stop_count };
    ok( !Developer::Dashboard::System::Menu::_shutdown_active_helpers(),
        'shutdown helper is a no-op when no menu runtime is active' );
    is( $idle_menu->remove('not-running'), $idle_menu,
        'remove without an active helper returns the menu object' );
    is( scalar @commands, 0, 'remove does not send a command when the helper is stopped' );
    is( $idle_menu->stop, $idle_menu, 'stop without an active helper returns the menu object' );
    is( $stop_count, 0, 'stop does not signal a stopped helper' );

    my $idle_run = bless { id => 'idle-run' }, 'Developer::Dashboard::System::Menu';
    local *Developer::Dashboard::System::Menu::_start = sub {};
    local *Developer::Dashboard::System::Menu::_command_json = sub { push @commands, $_[0] };
    is( $idle_run->run([]), $idle_run,
        'run returns normally when the native helper exits before entering its event loop' );
}

{
    no warnings 'redefine';
    my $post_loop_menu = bless { id => 'post-loop-dispatch' }, 'Developer::Dashboard::System::Menu';
    my @running = (1, 0, 1);
    my @events = (
        '',
        JSON::XS->new->canonical->encode({ event => 'click', name => 'late-click' }) . "\n",
    );
    my $late_click_count = 0;
    local *Developer::Dashboard::System::Menu::_start = sub {};
    local *Developer::Dashboard::System::Menu::_running = sub { shift @running // 0 };
    local *Developer::Dashboard::System::Menu::_command_json = sub {};
    local *Developer::Dashboard::System::Menu::_read_events = sub { shift @events };
    is( $post_loop_menu->run([
        { name => 'late-click', icon => 'x', click => sub { ++$late_click_count } },
    ]), $post_loop_menu, 'run performs a final event drain after the native loop exits' );
    is( $late_click_count, 1, 'the final event drain dispatches its pending callback once' );
}

{
    my $forgotten = bless { name => 'leaf-without-children', children => undef },
        'Developer::Dashboard::System::Menu::Item';
    my $runtime = { items => { $forgotten->{name} => $forgotten }, roots => [$forgotten] };
    Developer::Dashboard::System::Menu::_forget_item( $runtime, $forgotten );
    ok( $forgotten->{removed}, 'forgetting a leaf without a child list marks it removed' );
    is_deeply( $runtime->{roots}, [], 'forgetting a root leaf removes it from the roots list' );
}

{
    my $scratch = tempdir( 'dd-system-menu-end-XXXXXX', CLEANUP => 1, TMPDIR => 1 );
    my $marker = File::Spec->catfile( $scratch, 'end-cleanup-ran' );
    my $child_source = q{
        use strict;
        use warnings;
        use JSON::XS ();
        use Developer::Dashboard::System::Menu;
        {
            no warnings 'redefine';
            local *Developer::Dashboard::System::Menu::_start = sub {};
            *Developer::Dashboard::System::Menu::_running = sub { 1 };
            local *Developer::Dashboard::System::Menu::_command_json = sub {};
            local *Developer::Dashboard::System::Menu::_read_events = sub {
                return JSON::XS->new->canonical->encode({ event => 'click', name => 'exit' }) . "\n";
            };
            *Developer::Dashboard::System::Menu::_stop = sub {
                open my $fh, '>', $ARGV[0] or die "Unable to write shutdown marker: $!";
                print {$fh} "stopped\n";
                close $fh or die "Unable to close shutdown marker: $!";
            };
            Developer::Dashboard::System::Menu::menu()->run([
                { name => 'exit', icon => 'x', click => sub { exit 0 } },
            ]);
        }
    };
    my $pid = spawn( [ $^X, '-e', $child_source, '--', $marker ], {} );
    is( wait_process($pid), 0, 'helper process exits normally after its menu callback exits' );
    open my $fh, '<', $marker or die "Unable to read shutdown marker '$marker': $!";
    my $marker_text = <$fh>;
    close $fh or die "Unable to close shutdown marker '$marker': $!";
    is( $marker_text, "stopped\n", 'END stops the native helper when Perl exits with an active menu' );

    my $already_stopped_marker = File::Spec->catfile( $scratch, 'end-cleanup-already-stopped' );
    my $already_stopped_source = q{
        use strict;
        use warnings;
        use JSON::XS ();
        use Developer::Dashboard::System::Menu;
        {
            no warnings 'redefine';
            my $running_checks = 0;
            local *Developer::Dashboard::System::Menu::_start = sub {};
            *Developer::Dashboard::System::Menu::_running = sub { ++$running_checks == 1 };
            local *Developer::Dashboard::System::Menu::_command_json = sub {};
            local *Developer::Dashboard::System::Menu::_read_events = sub {
                return JSON::XS->new->canonical->encode({ event => 'click', name => 'exit' }) . "\n";
            };
            *Developer::Dashboard::System::Menu::_stop = sub {
                open my $fh, '>', $ARGV[0] or die "Unable to write shutdown marker: $!";
                print {$fh} "stopped\n";
                close $fh or die "Unable to close shutdown marker: $!";
            };
            Developer::Dashboard::System::Menu::menu()->run([
                { name => 'exit', icon => 'x', click => sub { exit 0 } },
            ]);
        }
    };
    my $already_stopped_pid = spawn(
        [ $^X, '-e', $already_stopped_source, '--', $already_stopped_marker ], {}
    );
    is( wait_process($already_stopped_pid), 0,
        'helper process exits normally when its native helper has already stopped' );
    ok( !-e $already_stopped_marker,
        'END does not stop the native helper a second time after it has stopped' );
}

my $non_singleton = Developer::Dashboard::System::Menu::menu();
is( $non_singleton, $menu, 'repeated menu calls keep the same singleton' );

my $bad_text = eval { $builder->_build_item( { name => "\xFF", icon => 'x' }, undef, {}, {}, 0 ); 1 };
ok( $bad_text, 'invalid UTF-8 bytes are retained as plain text' );
my $valid_utf8_bytes = pack 'C*', 0xC3, 0xA9;
is( Developer::Dashboard::System::Menu::_text( $valid_utf8_bytes, 'value' ), "\x{e9}",
    'valid UTF-8 bytes decode to their character value' );

{
    no warnings 'redefine';
    my @chunks = ( undef, '', "\n{bad-json}\n[]\n{}\r\n{\"event\":\"click\",\"name\":\"fragmented\"", "}\n" );
    my $chunk_menu = bless { id => 'chunk-menu' }, 'Developer::Dashboard::System::Menu';
    my $chunk_rt = {
        active => 1,
        items => {
            fragmented => bless({ root => $chunk_menu, name => 'fragmented', icon => 'x', click => 'y', removed => 0 },
                'Developer::Dashboard::System::Menu::Item'),
        },
        event_buffer => '',
    };
    local *Developer::Dashboard::System::Menu::_read_events = sub { shift @chunks };
    local *Developer::Dashboard::System::Menu::_command_json = sub { $state->{fragmented_command} = $_[0] };
    my @warnings;
    {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        ok( !Developer::Dashboard::System::Menu::_dispatch_events( $chunk_menu, $chunk_rt ),
            'undefined helper read returns without dispatch' );
        ok( !Developer::Dashboard::System::Menu::_dispatch_events( $chunk_menu, $chunk_rt ),
            'empty helper read returns without dispatch' );
        ok( Developer::Dashboard::System::Menu::_dispatch_events( $chunk_menu, $chunk_rt ),
            'event dispatcher accepts a non-empty chunk with malformed and empty lines' );
        is( $chunk_rt->{event_buffer}, '{"event":"click","name":"fragmented"',
            'incomplete helper event remains buffered until its newline arrives' );
        ok( Developer::Dashboard::System::Menu::_dispatch_events( $chunk_menu, $chunk_rt ),
            'event dispatcher completes a helper event split across reads' );
    }
    like( join( '', @warnings ), qr/invalid helper event/,
        'invalid JSON and non-hash helper events are reported explicitly' );
    is( JSON::XS->new->utf8->decode( $state->{fragmented_command} )->{op}, 'icon',
        'fragmented click event is dispatched after the final chunk arrives' );
}

{
    no warnings 'redefine';
    my $stopped_by_click = bless { id => 'stop-click-menu' }, 'Developer::Dashboard::System::Menu';
    my $stopped_rt = { active => 1, items => {}, event_buffer => '' };
    my $stop_click_count = 0;
    $stopped_rt->{items}{stop} = bless {
        root => $stopped_by_click, name => 'stop', icon => 'x', removed => 0,
        click => sub { ++$stop_click_count; $stopped_rt->{active} = 0 },
    }, 'Developer::Dashboard::System::Menu::Item';
    local *Developer::Dashboard::System::Menu::_read_events = sub {
        return JSON::XS->new->canonical->encode({ event => 'click', name => 'stop' }) . "\n"
            . JSON::XS->new->canonical->encode({ event => 'click', name => 'stop' }) . "\n";
    };
    ok( Developer::Dashboard::System::Menu::_dispatch_events( $stopped_by_click, $stopped_rt ),
        'callback may stop the active event dispatch loop' );
    is( $stop_click_count, 1, 'dispatch stops immediately after the callback disables the runtime' );
    like( $stopped_rt->{event_buffer}, qr/\{"event":"click","name":"stop"\}/,
        'later queued events remain buffered after the callback stops dispatch' );
}

my $dispatch_menu = bless { id => 'dispatch-menu' }, 'Developer::Dashboard::System::Menu';
my $dispatch_item = bless {
    root => $dispatch_menu, name => 'callback-fails', icon => 'x',
    click => sub { die "callback exploded\n" }, removed => 0,
}, 'Developer::Dashboard::System::Menu::Item';
my $dispatch_text = bless {
    root => $dispatch_menu, name => 'text-click', icon => 'a',
    click => 'b', removed => 0,
}, 'Developer::Dashboard::System::Menu::Item';
my $dispatch_removed = bless {
    root => $dispatch_menu, name => 'removed', icon => 'r',
    click => sub {}, removed => 1,
}, 'Developer::Dashboard::System::Menu::Item';
my $dispatch_rt = {
    active => 1,
    items => {
        'callback-fails' => $dispatch_item,
        'text-click' => $dispatch_text,
        removed => $dispatch_removed,
        'no-click' => bless({ root => $dispatch_menu, name => 'no-click', removed => 0 },
            'Developer::Dashboard::System::Menu::Item'),
    },
    event_buffer => '',
};
{
    no warnings 'redefine';
    local *Developer::Dashboard::System::Menu::_read_events = sub {
        return join '', map { JSON::XS->new->canonical->encode($_) . "\n" } (
            { event => 'click' },
            { event => 'click', name => 'absent' },
            { event => 'click', name => 'removed' },
            { event => 'click', name => 'no-click' },
            { event => 'click', name => 'callback-fails' },
            { event => 'click', name => 'text-click' },
        );
    };
    local *Developer::Dashboard::System::Menu::_command_json = sub { $state->{last_command} = $_[0] };
    local *Developer::Dashboard::System::Menu::_set_icon = sub { die "icon update failed\n" };
    my @warnings;
    ok( !Developer::Dashboard::System::Menu::_dispatch_events( $dispatch_menu, { active => 0 } ),
        'inactive runtime ignores helper events' );
    ok( !Developer::Dashboard::System::Menu::_dispatch_events( $dispatch_menu, undef ),
        'missing runtime ignores helper events' );
    my $dispatched;
    {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        $dispatched = Developer::Dashboard::System::Menu::_dispatch_events(
            $dispatch_menu, $dispatch_rt
        );
    }
    ok( $dispatched, 'active runtime dispatches valid helper events' );
    like( join( '', @warnings ), qr/Developer::Dashboard::System::Menu: click 'callback-fails' failed: callback exploded/s,
        'callback exceptions are reported visibly' );
    like( join( '', @warnings ), qr/click 'text-click' update failed: icon update failed/s,
        'plain-text click update errors are reported visibly' );
}

done_testing;

END {
    no warnings 'redefine';
    my $running_checks = 0;
    *Developer::Dashboard::System::Menu::_start = sub {};
    *Developer::Dashboard::System::Menu::_running = sub { ++$running_checks == 1 };
    *Developer::Dashboard::System::Menu::_command_json = sub {};
    *Developer::Dashboard::System::Menu::_read_events = sub {
        return JSON::XS->new->canonical->encode({ event => 'click', name => 'exit-at-end' }) . "\n";
    };
    *Developer::Dashboard::System::Menu::_stop = sub {};
    Developer::Dashboard::System::Menu::menu()->run([
        { name => 'exit-at-end', icon => 'x', click => sub { exit 0 } },
    ]);
}

__END__

=head1 NAME

t/250-system-menu-coverage.t - exercise System::Menu validation and event paths

=head1 PURPOSE

Exercises the Perl validation, serialization, helper-event dispatch, and error
paths in C<Developer::Dashboard::System::Menu> without launching a desktop
native menu process.

=head1 WHY IT EXISTS

The native UI is unavailable in headless test containers, but the Perl adapter
contains meaningful branching that must remain covered. Replacing only the
native boundary with local stubs keeps these tests deterministic while still
testing the production adapter code.

=head1 WHEN TO USE

Run this file in the dev Docker service after changing System::Menu validation,
nested items, callback handling, or native event transport.

=head1 HOW TO USE

    d2 docker compose exec dev prove -lv t/250-system-menu-coverage.t

The test covers malformed API input, plain and UTF-8-flagged text, nested menu
defaults, duplicate names, native event parsing, callback dispatch, and
transport failure propagation.

=head1 WHAT USES IT

The distribution test suite runs it with the shared Dashboard XS bundle. It
does not claim native visual verification; that remains a hosted platform test.

=head1 EXAMPLES

The fixture replaces the native helper XSUBs while calling the real Perl
adapter. A serialized click event is dispatched to a callback, while malformed
JSON and unknown events are handled by the production event reader.
Other assertions cover invalid object identities, scalar text validation for
flagged Unicode and encoded bytes, menu defaults, and a final event drain after
the native run loop exits. Child-process fixtures cover both active-helper END
cleanup and the no-op path when the helper has already stopped. The final END
fixture drives the instrumented module's cleanup branch for an active helper.
An active event-loop fixture also verifies that C<stop()> signals the helper
and exits the loop cleanly.

=cut
