package Games::Lacuna::Task::Types;

use 5.010;
use strict;
use warnings;
our $VERSION = $Games::Lacuna::Task::VERSION;


use Games::Lacuna::Client::Types qw(ore_types food_types);

use Path::Class::File;
use Moose::Util::TypeConstraints;
use MooseX::Types::Path::Class;
use Games::Lacuna::Task::Constants;

subtype 'Lacuna::Task::Type::Ore'
    => as enum([ ore_types() ])
    => message { "Not a valid ore '$_'" };

subtype 'Lacuna::Task::Type::Food'
    => as enum([ food_types() ])
    => message { "No valid food '$_'" };

subtype 'Lacuna::Task::Type::Coordinate'
    => as 'ArrayRef[Int]'
    => where { scalar(@$_) == 2 }
    => message { "Not a valid coordinate".Data::Dumper::Dumper($_); };

subtype 'Lacuna::Task::Type::Coordinates'
    => as 'ArrayRef[Lacuna::Task::Type::Coordinate]';

coerce 'Lacuna::Task::Type::Coordinate'
    => from 'Str'
    => via {
        return [ split(/[;,x]/) ];
    };

subtype 'Lacuna::Task::Type::Resource' 
    => as 'Str'
    => where {
        my $element = $_;
        my $resources_re = join('|',
            @Games::Lacuna::Task::Constants::RESOURCES_ALL,
            ore_types(),
            food_types()
        );
        return ($element =~ m/^($resources_re)[:=](\d+)$/ ? 1:0);
    }
    => message { "Not a valid push resource '$_' (must be 'type:quantiy' eg. 'ore:10000')" };

subtype 'Lacuna::Task::Type::Resources'
    => as 'ArrayRef[Lacuna::Task::Type::Resource]';

MooseX::Getopt::OptionTypeMap->add_option_type_to_map(
    'Lacuna::Task::Type::Coordinate' => '=s',
    'Lacuna::Task::Type::Resource'   => '=s',
    'Lacuna::Task::Type::Coordinates'=> '=s@',
    'Lacuna::Task::Type::Resources'  => '=s@',
    
);

1;
