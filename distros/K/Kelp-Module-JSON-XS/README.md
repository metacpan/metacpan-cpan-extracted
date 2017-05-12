# NAME

Kelp::Module::JSON::XS - JSON:XS module for Kelp applications

# SYNOPSIS

```perl
package MyApp;
use Kelp::Base 'Kelp';

sub some_route {
    my $self = shift;
    return $self->json->encode( { success => \1 } );
}
```

# REGISTERED METHODS

This module registers only one method into the application: `json`.

## CONFIGURATION

In `conf/config.pl`:

```perl
{
    modules      => ['JSON:XS'],    # And whatever else you need
    modules_init => {
        'JSON::XS' => {
            pretty        => 1,
            allow_blessed => 1
            # And whetever else you want
        }
    }
}
```

## AUTHOR

Stefan Geneshky minimal@cpan.org

## LICENCE

Perl
