package Logic::Probabilistic::Serializer;

use v5.38;
use experimental 'signatures';
use feature 'try';
no warnings 'experimental::try';
use Carp         qw(croak);
use Scalar::Util qw(blessed openhandle);

use Logic::Relational::Serializer ();
use Logic::Probabilistic::PFact   ();
use Logic::Probabilistic::PChoice ();

our $VERSION = '0.01';

sub encode_pfact ( $pfact, $now = time ) {
    my @encoded_args =
      map { Logic::Relational::Serializer::encode_term($_) } @{ $pfact->args };

    my %data = (
        id          => $pfact->id,
        predicate   => $pfact->predicate,
        probability => $pfact->probability,
        args        => \@encoded_args,
    );

    if ( defined $pfact->expires_at ) {
        $data{expires_at} = $pfact->expires_at;
        my $rem = $pfact->expires_at - $now;
        $data{remaining_ttl} = $rem > 0 ? $rem : 0;
    }

    return \%data;
}

sub encode_pchoice ($pchoice) {
    my @encoded_base_args =
      map { Logic::Relational::Serializer::encode_term($_) }
      @{ $pchoice->args };

    my @encoded_outcomes;
    for my $out ( $pchoice->outcomes ) {
        push @encoded_outcomes,
          {
            probability => $out->{probability},
            value       =>
              Logic::Relational::Serializer::encode_term( $out->{value} ),
          };
    }

    my %data = (
        id        => $pchoice->id,
        predicate => $pchoice->predicate,
        args      => \@encoded_base_args,
        outcomes  => \@encoded_outcomes,
    );

    return \%data;
}

sub encode_deterministic_facts ( $prog, $now = time ) {
    my $rel_prog = $prog->relational_program;
    my $pred_map = $rel_prog->{predicates} // {};
    my @encoded_facts;

    for my $key ( sort keys %$pred_map ) {
        my $list = $pred_map->{$key} // [];
        for my $clause (@$list) {
            my $body_ref = ref( $clause->body );
            if ( !$body_ref || $body_ref eq 'Logic::Relational::Goal::True' ) {
                push @encoded_facts,
                  Logic::Relational::Serializer::encode_clause( $clause, $now );
            }
        }
    }

    return \@encoded_facts;
}

sub _write_target ( $json_str, $target ) {
    if ( ref($target) eq 'SCALAR' ) {
        $$target = $json_str;
    }
    elsif ( ref($target) || openhandle($target) ) {
        print {$target} $json_str;
    }
    else {
        open my $fh, '>:encoding(UTF-8)', $target
          or croak "Cannot write snapshot to file '$target': $!";
        print {$fh} $json_str;
        close $fh;
    }
    return;
}

sub _read_source ($source) {
    my $json_str;
    if ( ref($source) eq 'SCALAR' ) {
        $json_str = $$source;
    }
    elsif ( ref($source) || openhandle($source) ) {
        local $/ = undef;
        $json_str = <$source>;
    }
    else {
        open my $fh, '<:encoding(UTF-8)', $source
          or croak "Cannot read snapshot from file '$source': $!";
        local $/ = undef;
        $json_str = <$fh>;
        close $fh;
    }
    return $json_str;
}

sub _clear_existing_facts ($prog) {
    $prog->{pfacts}   = [];
    $prog->{pchoices} = [];

    my $rel_prog = $prog->relational_program;
    my %new_active;
    for my $key ( keys %{ $rel_prog->{active_predicates} // {} } ) {
        my $list = $rel_prog->{active_predicates}{$key} // [];
        my @rules_only;
        for my $clause (@$list) {
            my $body_ref = ref( $clause->body );
            if ( $body_ref && $body_ref ne 'Logic::Relational::Goal::True' ) {
                push @rules_only, $clause;
            }
        }
        $new_active{$key} = \@rules_only;
    }
    $rel_prog->{active_predicates} = \%new_active;
    $rel_prog->{predicates}        = \%new_active;
    return;
}

sub _resolve_ttl ( $item, $ttl_mode, $filter_expired, $now ) {
    if ( $ttl_mode eq 'relative' ) {
        if ( exists $item->{remaining_ttl} && defined $item->{remaining_ttl} ) {
            my $rem = $item->{remaining_ttl};
            return ( 0, undef )       if $filter_expired && $rem <= 0;
            return ( 1, $now + $rem ) if $rem > 0;
            return ( 1, undef );
        }
        if (   $filter_expired
            && exists $item->{expires_at}
            && defined $item->{expires_at}
            && $now >= $item->{expires_at} )
        {
            return ( 0, undef );
        }
    }
    elsif ( $filter_expired
        && exists $item->{expires_at}
        && defined $item->{expires_at}
        && $now >= $item->{expires_at} )
    {
        return ( 0, undef );
    }

    return ( 1, $item->{expires_at} );
}

sub _load_deterministic_facts ( $prog, $facts_data, $ttl_mode, $filter_expired,
    $now )
{
    my $count = 0;
    for my $fact_data (@$facts_data) {
        my $clause = Logic::Relational::Serializer::decode_clause($fact_data);
        my $meta   = $clause->metadata;

        my ( $keep, $expires_at ) =
          _resolve_ttl( $meta, $ttl_mode, $filter_expired, $now );
        next unless $keep;

        if ( defined $expires_at ) {
            $meta->{expires_at} = $expires_at;
        }
        else {
            delete $meta->{expires_at};
        }

        $prog->relational_program->fact($clause);
        $count++;
    }
    return $count;
}

sub _load_pfacts ( $prog, $pfacts_data, $ttl_mode, $filter_expired, $now ) {
    my $count = 0;
    for my $item (@$pfacts_data) {
        my ( $keep, $expires_at ) =
          _resolve_ttl( $item, $ttl_mode, $filter_expired, $now );
        next unless $keep;

        my @decoded_args =
          map { Logic::Relational::Serializer::decode_term($_) }
          @{ $item->{args} // [] };

        my %opts;
        $opts{id}         = $item->{id} if exists $item->{id};
        $opts{expires_at} = $expires_at if defined $expires_at;

        $prog->assert_pfact(
            probability => $item->{probability},
            predicate   => $item->{predicate},
            args        => \@decoded_args,
            %opts,
        );
        $count++;
    }
    return $count;
}

sub _load_pchoices ( $prog, $pchoices_data ) {
    my $count = 0;
    for my $item (@$pchoices_data) {
        my @base_args =
          map { Logic::Relational::Serializer::decode_term($_) }
          @{ $item->{args} // [] };

        my @outcomes;
        for my $out ( @{ $item->{outcomes} // [] } ) {
            push @outcomes,
              [
                $out->{probability},
                Logic::Relational::Serializer::decode_term( $out->{value} )
              ];
        }

        $prog->pchoice( $item->{predicate}, \@outcomes, @base_args );
        $count++;
    }
    return $count;
}

sub save_snapshot ( $prog, $target, %options ) {
    $prog->cleanup_expired_pfacts;
    $prog->cleanup_expired_facts;

    my $now       = time;
    my @pfacts    = map { encode_pfact( $_, $now ) } $prog->all_pfacts;
    my @pchoices  = map { encode_pchoice($_) } $prog->all_pchoices;
    my $det_facts = encode_deterministic_facts( $prog, $now );

    my $snapshot_data = {
        metadata => {
            format_version => 1,
            engine         => 'Logic::Probabilistic',
            exported_at    => $now,
            version        => $prog->version,
        },
        pfacts              => \@pfacts,
        pchoices            => \@pchoices,
        deterministic_facts => $det_facts,
    };

    my $json_str =
      Logic::Relational::Serializer::to_json( $snapshot_data, %options );

    _write_target( $json_str, $target );
    return $json_str;
}

sub load_snapshot ( $prog, $source, %options ) {
    my $json_str      = _read_source($source);
    my $snapshot_data = Logic::Relational::Serializer::from_json($json_str);

    croak "Invalid snapshot data format"
      unless ref($snapshot_data) eq 'HASH'
      && exists $snapshot_data->{metadata};

    my $mode           = $options{mode}           // 'replace';
    my $filter_expired = $options{filter_expired} // 1;
    my $ttl_mode       = $options{ttl_mode}
      // ( $options{pause_ttl} ? 'relative' : 'absolute' );
    my $now = time;

    if ( $mode eq 'replace' ) {
        _clear_existing_facts($prog);
    }

    my $loaded_count = 0;

    my $det_facts_data = $snapshot_data->{deterministic_facts}
      // $snapshot_data->{facts} // [];
    $loaded_count +=
      _load_deterministic_facts( $prog, $det_facts_data, $ttl_mode,
        $filter_expired, $now );

    $loaded_count += _load_pfacts( $prog, $snapshot_data->{pfacts} // [],
        $ttl_mode, $filter_expired, $now );

    $loaded_count +=
      _load_pchoices( $prog, $snapshot_data->{pchoices} // [] );

    $prog->_rebuild_known_pred_keys;
    $prog->increment_version;

    return $loaded_count;
}

1;

__END__

=head1 NAME

Logic::Probabilistic::Serializer - Snapshot serialization and deserialization for probabilistic models.

=head1 SYNOPSIS

    use Logic::Probabilistic::Serializer;

    # Save snapshot
    Logic::Probabilistic::Serializer::save_snapshot($prog, "world.json");

    # Load snapshot
    Logic::Probabilistic::Serializer::load_snapshot($prog, "world.json", mode => 'replace');

=head1 DESCRIPTION

Serializes complete probabilistic states including probabilistic facts (C<PFact>),
categorical choices (C<PChoice>), ground relational facts, and ephemeral TTL metadata
into portable JSON snapshots.

=cut
