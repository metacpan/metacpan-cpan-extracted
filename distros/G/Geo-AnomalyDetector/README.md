# NAME

Geo::AnomalyDetector - Detect anomalies in geospatial coordinate datasets

# SYNOPSIS

This module analyzes latitude and longitude data points to identify anomalies based on their distance from the mean location.

    use Geo::AnomalyDetector;
    
    my $detector = Geo::AnomalyDetector->new(threshold => 3);
    my $coords = [ [37.7749, -122.4194], [40.7128, -74.0060], [35.6895, 139.6917] ];
    my $anomalies = $detector->detect_anomalies($coords);
    print "Anomalies: " . join ", ", map { "($_->[0], $_->[1])" } @$anomalies;

# VERSION

0.01

# AUTHOR

Your Name

# LICENSE

This module is released under the same terms as Perl itself.
