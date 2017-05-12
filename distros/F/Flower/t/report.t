use strict;
use warnings;

use Test::More;
use Test::MockTime ();
use Test::MonkeyMock;
use JSON       ();
use File::Temp ();
use Flower::Chronos::Report;

subtest 'parse empty log' => sub {
    my $report = _build_report(printed => \my $printed);

    $report->run;

    is $printed, '';
};

subtest 'ignore empty lines' => sub {
    my $report = _build_report(content => \"\n\n\n", printed => \my $printed);

    $report->run;

    is $printed, '';
};

subtest 'ignore invalid lines' => sub {
    my $report = _build_report(
        content => \"foobar",
        printed => \my $printed
    );

    $report->run;

    is $printed, '';
};

subtest 'ignore lines with invalid json' => sub {
    my $report = _build_report(
        content => \"asdad start=123 end=124",
        printed => \my $printed
    );

    $report->run;

    is $printed, '';
};

subtest 'ignore lines with invalid dates' => sub {
    my $report = _build_report(
        from    => 0,
        to      => 123,
        content => \'{"activity":"foo"} start=123 end=1',
        printed => \my $printed
    );

    $report->run;

    is $printed, '';
};

subtest 'accumulate total run by default' => sub {
    my $report = _build_report(
        content => [
            {_start => 1, _end => 2,  activity => 'foo', foo => 'bar'},
            {_start => 2, _end => 10, activity => 'foo', foo => 'bar'}
        ],
        printed => \my $printed
    );

    Test::MockTime::set_absolute_time('1970-01-01T00:00:10Z');
    $report->run;
    Test::MockTime::restore_time();

    my @lines = split /\n/, $printed;
    is scalar @lines, 1;
    like $lines[0], qr/00d 00:00:09/;
};

subtest 'group by' => sub {
    my $report = _build_report(
        group_by => 'activity',
        content  => [
            {_start => 1, _end => 2,  activity => 'foo', foo => 'bar'},
            {_start => 2, _end => 10, activity => 'bar', foo => 'bar'}
        ],
        printed => \my $printed
    );

    Test::MockTime::set_absolute_time('1970-01-01T00:00:10Z');
    $report->run;
    Test::MockTime::restore_time();

    my @lines = split /\n/, $printed;
    is scalar @lines, 2;
    like $lines[0], qr/00d 00:00:08/;
    like $lines[1], qr/00d 00:00:01/;
};

subtest 'where' => sub {
    my $report = _build_report(
        where   => '$activity eq "foo"',
        content => [
            {_start => 1, _end => 2,  activity => 'foo', foo => 'bar'},
            {_start => 2, _end => 10, activity => 'bar', foo => 'bar'}
        ],
        printed => \my $printed
    );

    Test::MockTime::set_absolute_time('1970-01-01T00:00:10Z');
    $report->run;
    Test::MockTime::restore_time();

    my @lines = split /\n/, $printed;
    is scalar @lines, 1;
    like $lines[0], qr/00d 00:00:01/;
};

subtest 'fields' => sub {
    my $report = _build_report(
        group_by => 'activity',
        fields   => 'activity,foo',
        content  => [
            {_start => 1, _end => 2,  activity => 'foo', foo => 'bar'},
            {_start => 2, _end => 10, activity => 'bar', foo => 'bar'}
        ],
        printed => \my $printed
    );

    Test::MockTime::set_absolute_time('1970-01-01T00:00:10Z');
    $report->run;
    Test::MockTime::restore_time();

    my @lines = split /\n/, $printed;
    is scalar @lines, 2;
    like $lines[0], qr/00d 00:00:08 activity=bar foo=bar/;
    like $lines[1], qr/00d 00:00:01 activity=foo foo=bar/;
};

subtest 'show current day by default' => sub {
    my $report = _build_report(
        group_by => 'activity',
        fields   => 'activity',
        content  => [
            {_start => 1,         _end => 2,             activity => 'foo'},
            {_start => 24 * 3600, _end => 24 * 3600 + 1, activity => 'bar'}
        ],
        printed => \my $printed
    );

    Test::MockTime::set_absolute_time('1970-01-02T23:59:59Z');
    $report->run;
    Test::MockTime::restore_time();

    my @lines = split /\n/, $printed;
    is scalar @lines, 1;
    like $lines[0], qr/00d 00:00:01 activity=bar/;
};

subtest 'correctly show overlapping start date' => sub {
    my $report = _build_report(
        group_by => 'activity',
        fields   => 'activity',
        content  => [
            {_start => 1, _end => 2, activity => 'foo'},
            {
                _start   => 24 * 3600 - 15,
                _end     => 24 * 3600 + 1,
                activity => 'bar'
            }
        ],
        printed => \my $printed
    );

    Test::MockTime::set_absolute_time('1970-01-02T23:59:59Z');
    $report->run;
    Test::MockTime::restore_time();

    my @lines = split /\n/, $printed;
    is scalar @lines, 1;
    like $lines[0], qr/00d 00:00:01 activity=bar/;
};

subtest 'correctly show overlapping end date' => sub {
    my $report = _build_report(
        group_by => 'activity',
        fields   => 'activity',
        from     => '1970-01-02 00:00:00',
        to       => '1970-01-02 00:00:10',
        content  => [
            {_start => 1,         _end => 2,               activity => 'foo'},
            {_start => 24 * 3600, _end => 24 * 3600 + 100, activity => 'bar'}
        ],
        printed => \my $printed
    );

    $report->run;

    my @lines = split /\n/, $printed;
    is scalar @lines, 1;
    like $lines[0], qr/00d 00:00:10 activity=bar/;
};

my $log_file;

sub _build_report {
    my (%params) = @_;

    my $content = delete $params{content};
    $log_file = File::Temp->new;
    if (ref $content eq 'SCALAR') {
        print $log_file $$content;
    }
    else {
        foreach my $entry (@$content) {
            print $log_file JSON::encode_json($entry), "\n";
        }
    }
    seek $log_file, 0, 0;

    my $printed = delete $params{printed};
    $$printed = '';

    my $report =
      Flower::Chronos::Report->new(log_file => $log_file->filename, %params);
    $report = Test::MonkeyMock->new($report);
    $report->mock(_print => sub { shift; $$printed .= join('', @_) });
    return $report;
}

done_testing;
