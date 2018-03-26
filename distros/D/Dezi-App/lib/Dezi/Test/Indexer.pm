package Dezi::Test::Indexer;
use Moose;
extends 'Dezi::Indexer';
use Dezi::Test::Doc;
use SWISH::3 qw( :constants );
use Search::Tools::UTF8;
use Data::Dump qw( dump );

our $VERSION = '0.015';

sub invindex_class       {'Dezi::Test::InvIndex'}
sub use_swish3_tokenizer {1}

my $doc_prop_map = SWISH_DOC_PROP_MAP();

sub swish3_handler {
    my ( $self, $payload ) = @_;
    my $s3config = $payload->config;
    my $s3props  = $s3config->get_properties;
    my $s3metas  = $s3config->get_metanames;

    # will hold all the parsed text, keyed by field name
    my %doc;

    # Swish built-in fields first
    for my $propname ( keys %$doc_prop_map ) {
        my $attr = $doc_prop_map->{$propname};
        $doc{$propname} = [ $payload->doc->$attr ];
    }

    # fields parsed from document
    my $props = $payload->properties;
    my $metas = $payload->metanames;

    #dump $props;
    #dump $metas;

    # flesh out %doc
    for my $field ( keys %$props ) {
        push @{ $doc{$field} }, @{ $props->{$field} };
    }
    for my $field ( keys %$metas ) {
        next if exists $doc{$field};    # prefer property over metaname
        push @{ $doc{$field} }, @{ $metas->{$field} };
    }
    for my $k ( keys %doc ) {
        $doc{$k} = to_utf8( join( SWISH_TOKENPOS_BUMPER(), @{ $doc{$k} } ) );
    }

    $self->invindex->put_doc( Dezi::Test::Doc->new(%doc) );

    # add tokens to our invindex
    my $term_cache = $self->invindex->term_cache;
    my $tokens     = $payload->tokens;
    my $uri        = $doc{swishdocpath};
    while ( my $token = $tokens->next ) {
        my $str = $token->value;
        if ( !$term_cache->has($str) ) {
            $term_cache->add( $str => { $uri => 1 } );
        }
        else {
            $term_cache->get($str)->{$uri}++;
        }
    }

}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Dezi::Test::Indexer - test indexer class

=head1 SYNOPSIS

 use Dezi::Test::Indexer;

 my $spider = Dezi::Aggregator::Spider->new(
    indexer => Dezi::Test::Indexer->new()
 );
 $spider->crawl('http://localhost/foo');

=head1 DESCRIPTION

Dezi::Test::Indexer uses Dezi::Test::InvIndex for
running tests on the API, particularly Aggregator classes.

=head1 CONSTANTS

All the L<SWISH::3> constants are imported into this namespace,
including:

=over 4

=item * SWISH_DOC_PROP_MAP

=back

=head1 METHODS

=head2 process( I<doc> )

Tokenizes content in I<doc> and adds each term
to the InvIndex.

=head2 swish3_handler

Called by L<SWISH::3> handler() function.

=head2 use_swish3_tokenizer

Returns true.

=head2 invindex_class

Returns L<Dezi::Test::InvIndex>.

=head1 AUTHOR

Peter Karman, E<lt>perl@peknet.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-swish-prog at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dezi-App>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dezi


You can also look for information at:

=over 4

=item * Mailing list

L<http://lists.swish-e.org/listinfo/users>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-App>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dezi-App>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dezi-App>

=item * Search CPAN

L<http://search.cpan.org/dist/Dezi-App/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2015 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://swish-e.org/>
