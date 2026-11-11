package Logic::Relational::Serializer;

use v5.38;    ## no critic (ValuesAndExpressions::ProhibitVersionStrings)
use experimental 'signatures';
use Carp        qw(croak);
use JSON::PP    ();
use Time::HiRes qw(time);
use Logic::Relational::Term;
use Logic::Relational::Atom;
use Logic::Relational::Variable;
use Logic::Relational::Clause;

=head1 NAME

Logic::Relational::Serializer - Serializes and deserializes knowledge base snapshots.

=cut

sub encode_term ($term) {
    if ( !ref($term) ) {
        return { type => 'scalar', value => $term };
    }

    my $ref = ref($term);
    if ( $ref eq 'Logic::Relational::Atom' ) {
        return { type => 'atom', name => $term->name };
    }
    if ( $ref eq 'Logic::Relational::Variable' ) {
        return { type => 'variable', name => $term->name };
    }
    if ( $ref eq 'Logic::Relational::Term' ) {
        my @encoded_args = map { encode_term($_) } @{ $term->args };
        return {
            type    => 'term',
            functor => $term->functor,
            args    => \@encoded_args,
        };
    }
    if ( $ref eq 'Logic::Relational::ArrayRest' ) {
        return { type => 'array_rest', term => encode_term( $term->term ) };
    }
    if ( $ref eq 'Logic::Relational::Domain' ) {
        return { type => 'domain', values => [ $term->values ] };
    }
    if ( $ref eq 'ARRAY' ) {
        my @encoded_elements = map { encode_term($_) } @$term;
        return { type => 'array', elements => \@encoded_elements };
    }
    if ( $ref eq 'HASH' ) {
        my %encoded_pairs;
        for my $k ( keys %$term ) {
            $encoded_pairs{$k} = encode_term( $term->{$k} );
        }
        return { type => 'hash', pairs => \%encoded_pairs };
    }

    croak "Cannot serialize unhandled term type: $ref";
}

sub decode_term ($data) {
    croak "Invalid term encoding"
      unless ref($data) eq 'HASH' && exists $data->{type};
    my $type = $data->{type};

    if ( $type eq 'scalar' ) {
        return $data->{value};
    }
    if ( $type eq 'atom' ) {
        return Logic::Relational::Atom->new( $data->{name} );
    }
    if ( $type eq 'variable' ) {
        return Logic::Relational::Variable->new( name => $data->{name} );
    }
    if ( $type eq 'term' ) {
        my @decoded_args = map { decode_term($_) } @{ $data->{args} // [] };
        return Logic::Relational::Term->new(
            functor => $data->{functor},
            args    => \@decoded_args,
        );
    }
    if ( $type eq 'array_rest' ) {
        require Logic::Relational::ArrayRest;
        return Logic::Relational::ArrayRest->new(
            decode_term( $data->{term} ) );
    }
    if ( $type eq 'domain' ) {
        require Logic::Relational::Domain;
        return Logic::Relational::Domain->new(
            { values => $data->{values} // [] } );
    }
    if ( $type eq 'array' ) {
        my @decoded_elements =
          map { decode_term($_) } @{ $data->{elements} // [] };
        return \@decoded_elements;
    }
    if ( $type eq 'hash' ) {
        my %decoded_pairs;
        my $pairs = $data->{pairs} // {};
        for my $k ( keys %$pairs ) {
            $decoded_pairs{$k} = decode_term( $pairs->{$k} );
        }
        return \%decoded_pairs;
    }

    croak "Unknown term encoding type: $type";
}

sub encode_clause ( $clause, $now = time ) {
    my $head_term    = $clause->head;
    my @encoded_args = map { encode_term($_) } @{ $head_term->args };

    my %data = (
        id        => $clause->id,
        predicate => $head_term->functor,
        arity     => $head_term->arity,
        args      => \@encoded_args,
    );

    if ( my $meta = $clause->metadata ) {
        $data{created_at} = $meta->{created_at} if exists $meta->{created_at};
        if ( exists $meta->{expires_at} && defined $meta->{expires_at} ) {
            $data{expires_at} = $meta->{expires_at};
            my $rem = $meta->{expires_at} - $now;
            $data{remaining_ttl} = $rem > 0 ? $rem : 0;
        }
        if ( my $expire_to = $meta->{expire_to} ) {
            $data{expire_to} = encode_term($expire_to);
        }
    }

    return \%data;
}

sub decode_clause ($data) {
    croak "Invalid clause encoding"
      unless ref($data) eq 'HASH' && exists $data->{predicate};

    my @decoded_args = map { decode_term($_) } @{ $data->{args} // [] };
    my $head         = Logic::Relational::Term->new(
        functor => $data->{predicate},
        args    => \@decoded_args,
    );

    my %meta;
    $meta{created_at}    = $data->{created_at} if exists $data->{created_at};
    $meta{expires_at}    = $data->{expires_at} if exists $data->{expires_at};
    $meta{remaining_ttl} = $data->{remaining_ttl}
      if exists $data->{remaining_ttl};
    if ( exists $data->{expire_to} && defined $data->{expire_to} ) {
        $meta{expire_to} = decode_term( $data->{expire_to} );
    }

    return Logic::Relational::Clause->new(
        id       => $data->{id},
        head     => $head,
        metadata => \%meta,
    );
}

sub to_json ( $snapshot_data, %opts ) {
    my $coder = JSON::PP->new->utf8;
    $coder->pretty( $opts{pretty} // 1 );
    $coder->canonical(1);
    return $coder->encode($snapshot_data);
}

sub from_json ($json_str) {
    my $coder = JSON::PP->new->utf8;
    return $coder->decode($json_str);
}

1;
