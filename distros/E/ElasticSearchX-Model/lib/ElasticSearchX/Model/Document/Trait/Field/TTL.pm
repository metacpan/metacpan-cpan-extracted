#
# This file is part of ElasticSearchX-Model
#
# This software is Copyright (c) 2018 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package ElasticSearchX::Model::Document::Trait::Field::TTL;
$ElasticSearchX::Model::Document::Trait::Field::TTL::VERSION = '2.0.0';
use Moose::Role;
use ElasticSearchX::Model::Document::Types qw(:all);

has ttl => (
    is        => 'rw',
    isa       => TTLField,
    coerce    => 1,
    predicate => 'has_ttl',
);

around mapping => sub { () };

around type_mapping => sub {
    my ( $orig, $self ) = @_;
    my $default = $self->default($self);
    return ( _ttl => $self->ttl );
};

around field_name => sub {'_ttl'};

around property => sub {0};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ElasticSearchX::Model::Document::Trait::Field::TTL

=head1 VERSION

version 2.0.0

=head1 AUTHOR

Moritz Onken

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
