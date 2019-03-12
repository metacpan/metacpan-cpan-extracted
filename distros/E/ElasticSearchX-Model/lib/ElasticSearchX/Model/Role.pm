#
# This file is part of ElasticSearchX-Model
#
# This software is Copyright (c) 2019 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package ElasticSearchX::Model::Role;
$ElasticSearchX::Model::Role::VERSION = '2.0.1';
use Moose::Role;
use Search::Elasticsearch;
use ElasticSearchX::Model::Index;
use version;
use ElasticSearchX::Model::Document::Types qw(ES);

has es => ( is => 'rw', lazy_build => 1, coerce => 1, isa => ES );

sub _build_es {
    Search::Elasticsearch->new(
        nodes => $ENV{ES} || '127.0.0.1:9200',
        cxn => 'HTTPTiny',
    );
}

sub deploy {
    my ( $self, %params ) = @_;
    my $t = $self->es->transport;

    foreach my $name ( $self->meta->get_index_list ) {
        my $index = $self->index($name);
        next if ( $index->alias_for && $name eq $index->alias_for );
        $name = $index->alias_for if ( $index->alias_for );
        local $@;
        eval { $self->es->indices->delete( index => $name ) }
            if ( $params{delete} );
        my $dep     = $index->deployment_statement;
        my $mapping = delete $dep->{mappings};
        eval {
            $t->perform_request(
                {
                    method => 'PUT',
                    path   => "/$name",
                    body   => $dep,
                }
            );
        };
        sleep(1);

        while ( my ( $k, $v ) = each %$mapping ) {
            $t->perform_request(
                {
                    method => 'PUT',
                    path   => "/$name/$k/_mapping",
                    body   => { $k => $v },
                }
            );
        }
        if ( my $alias = $index->alias_for ) {
            my @aliases = keys %{
                $self->es->indices->get_alias(
                    index  => $index->name,
                    ignore => [404]
                    )
                    || {}
            };
            my $actions = [
                (
                    map {
                        { remove => { index => $_, alias => $index->name } }
                    } @aliases
                ),
                { add => { index => $alias, alias => $index->name } }
            ];
            $self->es->indices->update_aliases(
                body => { actions => $actions } );
        }
    }
    return 1;
}

sub bulk {
    my $self = shift;
    return ElasticSearchX::Model::Bulk->new( es => $self->es, @_ );
}

sub es_version {
    my $self   = shift;
    my $string = $self->es->info->{version}->{number};
    $string =~ s/RC//g;
    return version->parse($string)->numify;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ElasticSearchX::Model::Role

=head1 VERSION

version 2.0.1

=head1 AUTHOR

Moritz Onken

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
