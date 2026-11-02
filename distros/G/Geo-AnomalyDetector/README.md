## Name

Geo::AnomalyDetector - Detect anomalies in geospatial coordinate datasets

## Synopsis

This module analyzes latitude and longitude data points to identify anomalies based on their distance from the mean location.

```perl
use Geo::AnomalyDetector;

my $detector = Geo::AnomalyDetector->new(threshold => 3);
my $coords = [ [37.7749, -122.4194], [40.7128, -74.0060], [35.6895, 139.6917] ];
my $anomalies = $detector->detect_anomalies($coords);
print 'Anomalies: ', join ', ', map { ($_->[0], $_->[1]) } @{$anomalies};
```

Each co-ordinate can be either a two element array of \[latitude, longitude\] or an object that has
`latitude` and `longitude` methods.

## Version

0.03

## Subroutines/Methods

### New

Creates a Geo::AnomalyDetector object.

It takes two optional parameters:

- `threshold`

    A number to hint at what consitutues an anomaly.
    The larger the number,
    the larger the distance to be called an anomaly,
    there will be fewer matches.
    The default is 3.

- `units`

    The unit to be used internally for measurement.
    Can be `M` or `K`.
    The default is `K`.
    This should have no effect on the determination of outliers.

### Detect\_Anomalies

Identify outlier geographic coordinates based on their distance from the average location of a dataset.

Takes an array reference of coordinate pairs.
Each coordinate can be an array reference \[lat, lon\] or an object with latitude() and longitude() methods.

It returns a reference to an array of coordinates considered anomalous based on their distance from the mean.

#### Api Specification

##### Input

```perl
{
  'coordinates' => { type => 'arrayref' }     # Each element can be either a coordinate pair or an object
}
```

##### Output

```perl
{
  'type' => 'arrayref',  # A list of coordinates
  'schema' => {
    'type' => 'arrayref',
    'min' => 2,  # Each coordinate is two numbers
    'max' => 2,
    'schema' => {
      # FIXME: specify that the latitude (the first number) is between -90 and 90
      'type' => 'number', 'min' => -180.0, 'max' => 180.0 }
  }
}
```

- Argument error: croak
- No matches found: \[\]

## Author

Nigel Horne, `<njh at nigelhorne.com>`

## Bugs

## See Also

- Test coverage report: [https://nigelhorne.github.io/Geo-AnomalyDetector/coverage/](https://nigelhorne.github.io/Geo-AnomalyDetector/coverage/)
- [Geo::Location::Point](https://metacpan.org/pod/Geo%3A%3ALocation%3A%3APoint)
- [Math::Trig](https://metacpan.org/pod/Math%3A%3ATrig)

## Support

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-geo-anomalydetector at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-AnomalyDetector](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-AnomalyDetector).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

```
perldoc Geo::AnomalyDetector
```

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/dist/Geo-AnomalyDetector](https://metacpan.org/dist/Geo-AnomalyDetector)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-AnomalyDetector](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-AnomalyDetector)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Geo-AnomalyDetector](http://matrix.cpantesters.org/?dist=Geo-AnomalyDetector)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Geo::AnomalyDetector](http://deps.cpantesters.org/?module=Geo::AnomalyDetector)

## License and Copyright

Copyright 2025 Nigel Horne.

This program is released under the following licence: GPL2
