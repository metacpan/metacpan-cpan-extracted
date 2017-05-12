package t::Util;

use strict;
use warnings;

use base qw(Exporter);
our @EXPORT = qw(
                    p reorder_points
                    %InfluxDB_Server %Admin_User %DB_User
            );

use Data::Dumper;

sub p($) {
    local $Data::Dumper::Indent    = 1;
    local $Data::Dumper::Deepcopy  = 1;
    local $Data::Dumper::Sortkeys  = 1;
    local $Data::Dumper::Terse     = 1;
    local $Data::Dumper::Useqq     = 1;
    local $Data::Dumper::Quotekeys = 0;
    my $d =  Dumper($_[0]);
    $d    =~ s/\\x{([0-9a-z]+)}/chr(hex($1))/ge;
    print STDERR $d;
}

our %InfluxDB_Server = (
    host => '127.0.0.1',
    port => '8086',
);

our %Admin_User = (
    username => 'root',
    password => 'root',
);

our %DB_User = (
    username => 'scott',
    password => 'tiger',
);

sub reorder_points {
    my($result, %args) = @_;
    my $points;

    my %col;
    for (my $i=0; $i<scalar(@{ $args{order} }); $i++) {
        $col{ $args{order}[$i] } = $i;
    }

    for my $rs (@{ $result }) {
        push @$points, @{ $rs->{points} };
    }

    # InfluxDB returns order by desc
    $points = [ reverse @{ $points } ];

    for my $p (@{ $points }) {
        my %tmp;
        @tmp{ @{$result->[0]{columns}} } = @{$p};
        delete @tmp{qw(time sequence_number)};
        $p = [];
        for my $c (@{ $args{order} }) {
            push @$p, delete $tmp{$c};
        }
        push @$p, values %tmp; # if remains
    }

    return $points;
}

1;

__END__
