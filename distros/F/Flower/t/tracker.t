use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::MockTime ();
use Test::MonkeyMock;
use Flower::Chronos::Tracker;

subtest 'not run on_end when same info' => sub {
    my $ended = 0;

    my $x11 = _mock_x11([{id => 'foo'}, {id => 'foo'}]);
    my $tracker = _build_tracker(
        x11    => $x11,
        on_end => sub { $ended++ }
    );

    $tracker->track;
    $tracker->track;

    is $ended, 0;
};


subtest 'finish previous activity when idle' => sub {
    my $ended = 0;

    my $x11 = _mock_x11([{id => 'foo'}]);
    my $tracker = _build_tracker(
        idle_timeout => 10,
        x11          => $x11,
        on_end       => sub { $ended++ }
    );

    $tracker->track;

    $x11->mock(idle_time => sub { 100 });
    $tracker->track;

    is $ended, 1;
};

subtest 'run on_end when flush_timeout' => sub {
    my $ended = 0;

    my $i       = 0;
    my $x11     = _mock_x11([{id => 'foo'}, {id => 'foo'}]);
    my $tracker = _build_tracker(
        flush_timeout => 10,
        x11           => $x11,
        on_end        => sub { $ended++ }
    );

    Test::MockTime::set_absolute_time('1970-01-01T00:00:00Z');

    $tracker->track;

    Test::MockTime::set_absolute_time('1970-01-01T00:00:20Z');

    $tracker->track;

    Test::MockTime::restore_time();

    is $ended, 1;
};

subtest 'when flush_timeout set end time not to the absolute time' => sub {
    my $time;
    my $x11 = _mock_x11([{id => 'foo'}, {id => 'foo'}]);
    my $tracker = _build_tracker(
        flush_timeout => 10,
        x11           => $x11,
        on_end        => sub { $time = $_[0]->{_end} }
    );

    Test::MockTime::set_absolute_time('1970-01-01T00:00:00Z');

    $tracker->track;

    Test::MockTime::set_absolute_time('1970-01-01T00:00:20Z');

    $tracker->track;

    Test::MockTime::restore_time();

    is $time, 10;
};

subtest 'not run on_end when nothing to flush' => sub {
    my $ended = 0;

    my $x11 = _mock_x11([{id => 'foo'}, {id => 'foo'}]);
    my $tracker = _build_tracker(
        flush_timeout => 10,
        x11           => $x11,
        on_end        => sub { $ended++ }
    );

    Test::MockTime::set_absolute_time('1970-01-01T00:00:00Z');

    $tracker->track;

    Test::MockTime::set_absolute_time('1970-01-01T00:00:20Z');

    Test::MockTime::restore_time();

    is $ended, 0;
};

subtest 'run on_end on end' => sub {
    my @args;
    my $ended = 0;

    my $x11 = _mock_x11([{id => 'foo'}, {id => 'new'}]);
    my $tracker = _build_tracker(
        x11    => $x11,
        time   => '123',
        on_end => sub { @args = @_; $ended++ }
    );

    $tracker->track;
    $tracker->track;

    is $ended, 1;
    is_deeply \@args,
      [
        {
            _start      => 123,
            _end        => 123,
            id          => 'foo',
            application => 'other',
            category    => 'other',
            name        => '',
            class       => '',
            role        => ''
        }
      ];
};

subtest 'run applications' => sub {
    my @args;
    my $x11 = _mock_x11([{id => 'foo'}, {id => 'new'}]);
    my $tracker = _build_tracker(
        x11          => $x11,
        on_end       => sub { @args = @_ },
        applications => [TestApplication->new]
    );

    $tracker->track;
    $tracker->track;

    is $args[0]->{application}, 1;
};

subtest 'catch application exceptions' => sub {
    my $x11 = _mock_x11([{id => 'foo'}, {id => 'new'}]);
    my $tracker = _build_tracker(
        x11          => $x11,
        applications => [TestApplicationError->new]
    );

    ok !exception { $tracker->track };
};

subtest 'stop when application returns true' => sub {
    my @args;
    my $x11 = _mock_x11([{id => 'foo'}, {id => 'new'}]);
    my $tracker = _build_tracker(
        x11    => $x11,
        on_end => sub { @args = @_ },
        applications => [TestApplication->new, TestApplication->new]
    );

    $tracker->track;
    $tracker->track;

    is $args[0]->{application}, 1;
};

subtest 'not stop when application returns false' => sub {
    my @args;
    my $x11 = _mock_x11([{id => 'foo'}, {id => 'new'}]);
    my $tracker = _build_tracker(
        x11    => $x11,
        on_end => sub { @args = @_ },
        applications => [TestApplicationFalse->new, TestApplicationFalse->new]
    );

    $tracker->track;
    $tracker->track;

    is $args[0]->{application}, 2;
};

sub _mock_x11 {
    my ($variants) = @_;

    my $x11 = Test::MonkeyMock->new;
    $x11->mock(get_active_window => sub { shift @$variants });
    $x11->mock(idle_time         => sub { 0 });
    return $x11;
}

sub _build_tracker {
    my (%params) = @_;

    my $x11  = delete $params{x11};
    my $time = delete $params{time};

    my $tracker = Flower::Chronos::Tracker->new(%params);
    $tracker = Test::MonkeyMock->new($tracker);
    $tracker->mock(_time => sub { $time }) if $time;
    $tracker->mock(_build_x11 => sub { $x11 });
    return $tracker;
}

done_testing;

package TestApplication;
use base 'Flower::Chronos::Application::Base';

sub run {
    my $self = shift;
    my ($info) = @_;

    $info->{application}++;

    return 1;
}

package TestApplicationFalse;
use base 'Flower::Chronos::Application::Base';

sub run {
    my $self = shift;
    my ($info) = @_;

    $info->{application}++;

    return;
}

package TestApplicationError;
use base 'Flower::Chronos::Application::Base';

sub run {
    my $self = shift;
    my ($info) = @_;

    die 'here';

    return 1;
}
