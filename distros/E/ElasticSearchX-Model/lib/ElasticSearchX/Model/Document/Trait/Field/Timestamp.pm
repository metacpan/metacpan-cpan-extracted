#
# This file is part of ElasticSearchX-Model
#
# This software is Copyright (c) 2016 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package ElasticSearchX::Model::Document::Trait::Field::Timestamp;
$ElasticSearchX::Model::Document::Trait::Field::Timestamp::VERSION = '1.0.2';
use Moose::Role;
use ElasticSearchX::Model::Document::Types qw(:all);

has timestamp => (
    is        => 'rw',
    isa       => TimestampField,
    coerce    => 1,
    predicate => 'has_timestamp',
);

around mapping => sub { () };

around type_mapping => sub {
    my ( $orig, $self ) = @_;
    return ( _timestamp => $self->timestamp );
};

around field_name => sub {'_timestamp'};

around query_property => sub {1};

around property => sub {0};

package ElasticSearchX::Model::Document::Trait::Class::Timestamp;
$ElasticSearchX::Model::Document::Trait::Class::Timestamp::VERSION = '1.0.2';
use Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ElasticSearchX::Model::Document::Trait::Field::Timestamp

=head1 VERSION

version 1.0.2

=head1 AUTHOR

Moritz Onken

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
