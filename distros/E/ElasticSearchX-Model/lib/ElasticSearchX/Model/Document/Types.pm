#
# This file is part of ElasticSearchX-Model
#
# This software is Copyright (c) 2019 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package ElasticSearchX::Model::Document::Types;
$ElasticSearchX::Model::Document::Types::VERSION = '2.0.1';
use List::MoreUtils ();
use DateTime::Format::Epoch::Unix;
use DateTime::Format::ISO8601;
use MooseX::Attribute::Deflator;
use MooseX::Attribute::Deflator::Moose;
use DateTime;
use JSON::MaybeXS qw( decode_json encode_json );
use Scalar::Util qw(blessed);
use MooseX::Types::ElasticSearch qw(:all);
use Moose::Util::TypeConstraints qw(duck_type);

use MooseX::Types -declare => [
    qw(
        Type
        Types
        TimestampField
        TTLField
        ESBulk
        ESScroll
        )
];

use Sub::Exporter -setup => {
    exports => [
        qw(
            Location
            QueryType
            ES
            ESBulk
            ESScroll
            Type
            Types
            TimestampField
            TTLField
            )
    ]
};

use MooseX::Types::Moose qw/Int Str Bool ArrayRef HashRef/;
use MooseX::Types::Structured qw(Dict Tuple Optional slurpy);

subtype TimestampField,
    as Dict [
    enabled => Bool,
    path    => Optional [Str],
    index   => Optional [Str],
    slurpy HashRef,
    ];
coerce TimestampField, from Int, via {
    { enabled => 1 };
};
coerce TimestampField, from Str, via {
    { enabled => 1, path => $_ };
};
coerce TimestampField, from HashRef, via {
    { enabled => 1, %$_ };
};

subtype ESScroll,
    as duck_type([qw(
        next
        total
        max_score
    )]);

subtype ESBulk,
    as duck_type([qw(
        _buffer_count
        flush
    )]);

subtype TTLField,
    as Dict [
    enabled => Bool,
    default => Optional [Str],
    store   => Optional [Bool],
    index   => Optional [Str],
    slurpy HashRef,
    ];
coerce TTLField, from Int, via {
    { enabled => 1 };
};
coerce TTLField, from Str, via {
    { enabled => 1, default => $_ };
};
coerce TTLField, from HashRef, via {
    { enabled => 1, %$_ };
};

class_type 'DateTime';
coerce 'DateTime', from Int, via {
    DateTime->from_epoch( epoch => $_ / 1000 );
};
coerce 'DateTime', from Str, via {
    DateTime::Format::ISO8601->parse_datetime($_);
};

subtype Types, as HashRef ['Object'], where {
    !grep { $_->isa('Moose::Meta::Class') } keys %$_;
}, message {
    "Types must be either an ArrayRef of class names or a HashRef of name/class name pairs";
};

coerce Types, from HashRef ['Str'], via {
    my $hash = $_;
    return {
        map { $_ => Class::MOP::Class->initialize( $hash->{$_} ) }
            keys %$hash
    };
};

coerce Types, from ArrayRef ['Str'], via {
    my $array = $_;
    return {
        map {
            my $meta = Class::MOP::Class->initialize($_);
            $meta->short_name => $meta
        } @$array
    };
};

my $REGISTRY = Moose::Util::TypeConstraints->get_type_constraint_registry;

$REGISTRY->add_type_constraint(
    Moose::Meta::TypeConstraint::Parameterizable->new(
        name                 => Type,
        package_defined_in   => __PACKAGE__,
        parent               => find_type_constraint('Object'),
        constraint_generator => sub {
            sub {
                blessed $_
                    && $_->can('_does_elasticsearchx_model_document_role');
                }
        },
    )
);

Moose::Util::TypeConstraints::add_parameterizable_type(
    $REGISTRY->get_type_constraint(Type) );

use MooseX::Attribute::Deflator;
my @stat
    = qw(dev ino mode nlink uid gid rdev size atime mtime ctime blksize blocks);
deflate 'File::stat', via { return { List::MoreUtils::mesh( @stat, @$_ ) } },
    inline_as {
    join( "\n",
        'my @stat = qw(dev ino mode nlink uid gid',
        'rdev size atime mtime ctime blksize blocks);',
        'List::MoreUtils::mesh( @stat, @$value )',
    );
    };
deflate [ 'ArrayRef', 'HashRef' ],
    via { shift->dynamic ? $_ : encode_json($_) }, inline_as {
    return '$value' if ( $_[0]->dynamic );
    return 'JSON::encode_json($value)';
    };
inflate [ 'ArrayRef', 'HashRef' ],
    via { shift->dynamic ? $_ : decode_json($_) }, inline_as {
    return '$value' if ( $_[0]->dynamic );
    return 'JSON::decode_json($value)';
    };

deflate 'ArrayRef', via {$_}, inline_as {'$value'};
inflate 'ArrayRef', via {$_}, inline_as {'$value'};

deflate 'DateTime', via { $_->iso8601 }, inline_as {'$value->iso8601'};
inflate 'DateTime', via {
    $_ =~ /^\d+$/
        ? DateTime->from_epoch( epoch => $_ / 1000 )
        : DateTime::Format::ISO8601->parse_datetime($_);
}, inline_as {
    q(
        $value =~ /^\d+$/
            ? DateTime->from_epoch(epoch => $value/1000)
            : DateTime::Format::ISO8601->parse_datetime($value)
    )
};
deflate Location, via { [ $_->[0] + 0, $_->[1] + 0 ] },
    inline_as {'[ $value->[0] + 0, $value->[1] + 0 ]'};
deflate Type . '[]', via { ref $_ eq 'HASH' ? $_ : $_->meta->get_data($_) },
    inline_as {
    'ref $value eq "HASH" ? $value : $value->meta->get_data($value)';
    };

no MooseX::Attribute::Deflator;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ElasticSearchX::Model::Document::Types

=head1 VERSION

version 2.0.1

=head1 AUTHOR

Moritz Onken

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
