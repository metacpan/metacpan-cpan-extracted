# NAME

Kelp::Module::JSON::XS - DEPRECATED JSON:XS module for Kelp applications

# DEPRECATED

**\*\*\* This module is now deprecated. \*\*\***

Kelp is now using [JSON::MaybeXS](https://metacpan.org/pod/JSON%3A%3AMaybeXS), which will automatically choose the most
fitting backend for JSON.

Kelp used [JSON](https://metacpan.org/pod/JSON) module before that. Beginning with version 2.0 of the JSON
module, when both JSON and JSON::XS are installed, then JSON will fall back on
JSON::XS

# SYNOPSIS

    package MyApp;
    use Kelp::Base 'Kelp';

    sub some_route {
        my $self = shift;
        return $self->json->encode( { success => \1 } );
    }

# REGISTERED METHODS

This module registers only one method into the application: `json`.

## CONFIGURATION

In `conf/config.pl`:

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

## AUTHOR

Stefan Geneshky minimal@cpan.org

## LICENCE

Perl
