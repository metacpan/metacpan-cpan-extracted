## Forecast.io Wrapper

This is a wrapper for the forecast.io API.  You need an API key to use it (http://developer.forecast.io).  
Please consult the API docs at https://developer.forecast.io/docs/v2.


## Example Use


```perl
use 5.016;
use Forecast::IO;
use Data::Dumper;

my $lat  = 43.6667;
my $long = -79.4167;
my $key = "c9ce1c59d139c3dc62961cbd63097d13"; # example Forecast.io API key

my $forecast = Forecast::IO->new(
    key       => $key,
    longitude => $long,
    latitude  => $lat,
);

say "current temperature: " . $forecast->{currently}->{temperature};

my @daily_data_points = @{ $forecast->{daily}->{data} };

# Use your imagination about how to use this data.
# in the meantime, inspect it by dumping it.
for (@daily_data_points) {
    print Dumper($_);
}
```

## Links

Patches/suggestions welcome

Github: https://github.com/mlbright/Forecast-IO

CPAN: coming soon