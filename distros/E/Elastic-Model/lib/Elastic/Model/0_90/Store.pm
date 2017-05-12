package Elastic::Model::0_90::Store;
$Elastic::Model::0_90::Store::VERSION = '0.52';
use Moose;

with 'Elastic::Model::Role::Store';
use namespace::autoclean;

my @Top_Level = qw(
    index       type        lenient
    preference  routing     scroll
    search_type timeout     version
);

#===================================
sub search {
#===================================
    my $self = shift;
    my $args = _tidy_search( $self, @_ );
    $self->es->search($args);
}

#===================================
sub scrolled_search {
#===================================
    my $self = shift;
    my $args = _tidy_search( $self, @_ );
    $self->es->scroll_helper($args);
}

#===================================
sub _tidy_search {
#===================================
    my $self = shift;
    my %body = ref $_[0] eq 'HASH' ? %{ shift() } : @_;
    my %args;
    for (@Top_Level) {
        my $val = delete $body{$_};
        if ( defined $val ) {
            $args{$_} = $val;
        }
    }
    if ( $self->es->isa('Search::Elasticsearch::Client::0_90::Direct') ) {
        if ( delete $body{_source} ) {
            push @{ $body{fields} }, '_source'
                unless grep { $_ eq '_source' } @{ $body{fields} };
        }
    }
    $args{body} = \%body;
    return \%args;
}
#===================================
sub delete_by_query {
#===================================
    my $self = shift;
    my $args = _tidy_search( $self, @_ );
    $args->{body} = $args->{body}{query};
    my $result = eval { $self->es->delete_by_query($args) };
    return $result if $result;
    die $@ unless $@ =~ /request does not support/;
    $args->{body} = { query => $args->{body} };
    $self->es->delete_by_query($args);
}

#===================================
sub get_doc {
#===================================
    my ( $self, $uid, %args ) = @_;
    return $self->es->get(
        fields => [qw(_routing _parent _source)],
        %{ $uid->read_params },
        %args,
    );
}


#===================================
sub get_mapping {
#===================================
    my $self   = shift;
    my %args   = _cleanup(@_);
    my $result = $self->es->indices->get_mapping(%args);
    for ( keys %$result ) {
        next unless $result->{$_};
        return $result if $result->{$_}{mappings};
        $result->{$_} = { mappings => $result->{$_} };
    }
    return $result;
}

#===================================
sub put_mapping {
#===================================
    my ( $self, %args ) = @_;
    $args{body} = { $args{type} => delete $args{mapping} };
    return $self->es->indices->put_mapping(%args);
}

1;

=pod

=encoding UTF-8

=head1 NAME

Elastic::Model::0_90::Store - A 0.90.x compatibility class for Elastic::Model::Store

=head1 VERSION

version 0.52

=head1 DESCRIPTION

L<Elastic::Model::0_90::Store> handles differences between Elasticsearch 0.90.x
and 1.x, specifically to do with partial fields, get and put mapping responses,
and delete-by-query.

See L<Elastic::Manual::Delta> for more information about enabling
the 0.90.x compatibility mode.

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: A 0.90.x compatibility class for Elastic::Model::Store

