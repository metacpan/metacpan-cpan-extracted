package Foorum::TheSchwartz::Worker::DailyChart;

use strict;
use warnings;
our $VERSION = '1.001000';
use base qw( TheSchwartz::Moosified::Worker );
use Foorum::SUtils qw/schema/;
use Foorum::Logger qw/error_log/;
use Foorum::XUtils qw/tt2/;
use File::Spec;
use Date::Calc qw/Add_Delta_Days/;

sub work {
    my $class = shift;
    my $job   = shift;

    my @args = $job->arg;

    my $schema = schema();

    register_stat( $schema, 'User' );
    register_stat( $schema, 'Comment' );
    register_stat( $schema, 'Forum' );
    register_stat( $schema, 'Topic' );
    register_stat( $schema, 'Message' );
    register_stat( $schema, 'Visit' );

    my $tt2 = tt2();

    my @atime = localtime();
    my $year  = $atime[5] + 1900;
    my $month = $atime[4] + 1;
    my $day   = $atime[3];

    ( $year, $month, $day ) = Add_Delta_Days( $year, $month, $day, -7 );
    my $date = sprintf( '%04d%02d%02d', $year, $month, $day );

    my @stats
        = $schema->resultset('Stat')->search( { date => \"> $date", } )->all;

    my $stats;
    foreach (@stats) {
        $stats->{ $_->stat_key }->{ $_->date } = $_->stat_value;
    }

    my $var = {
        title => "$month/$day/$year Chart",
        stats => $stats,
    };

    my $filename = sprintf( '%04d%02d%02d', $year, $month, $day );
    use File::Spec;
    my ( undef, $path ) = File::Spec->splitpath(__FILE__);
    use Cwd qw/abs_path/;
    $path = abs_path($path);

    $tt2->process(
        'site/stats/chart.html',
        $var,
        File::Spec->catfile(
            $path, '..',   '..',     '..',
            '..',  'root', 'static', 'stats',
            "$filename.html"
        )
    );

    $job->completed();
}

sub register_stat {
    my ( $schema, $table ) = @_;

    my @atime = localtime();
    my $year  = $atime[5] + 1900;
    my $month = $atime[4] + 1;
    my $day   = $atime[3];
    my $now   = sprintf( '%04d%02d%02d', $year, $month, $day );

    my $stat_value = $schema->resultset($table)->count();

    my $stat_key = lc($table) . '_counts';

    my $dbh = $schema->storage->dbh;

    my $sql
        = qq~SELECT COUNT(*) FROM stat WHERE stat_key = ? AND date = $now~;
    my $sth = $dbh->prepare($sql);
    $sth->execute($stat_key);

    my ($count) = $sth->fetchrow_array;

    unless ($count) {
        $sql
            = qq~INSERT INTO stat (stat_key, stat_value, date) VALUES (?, ?, ?)~;
    } else {
        $sql
            = qq~UPDATE stat SET stat_key = ?, date = ? WHERE stat_value = ?~;
    }
    $sth = $dbh->prepare($sql);
    $sth->execute( $stat_key, $stat_value, $now );

}

1;
__END__

=pod

=head1 NAME

Foorum::TheSchwartz::Worker::DailyChart - Build daily chart

=head1 SYNOPSIS

  # check bin/cron/TheSchwartz_client.pl and bin/cron/TheSchwartz_worker.pl for usage

=head1 DESCRIPTION

Daily chart is helpful to take care about the site.

=head1 SEE ALSO

L<TheSchwartz>

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
