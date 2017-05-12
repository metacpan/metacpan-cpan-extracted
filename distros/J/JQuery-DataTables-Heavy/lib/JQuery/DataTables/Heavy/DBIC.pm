package JQuery::DataTables::Heavy::DBIC;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
with 'JQuery::DataTables::Heavy::Base';
use Carp;
use Scalar::Util qw(blessed);
use Hash::Merge;
use namespace::clean;

has '+dbh' => ( is => 'rw', isa => InstanceOf ['DBIx::Class::Schema'] );
has has_many => ( is => 'rw', isa => Any, default => sub { []; } );
has rs => ( is => 'lazy', isa => InstanceOf ['DBIx::Class::ResultSet'] );
has _hashed_has_many     => ( is => 'lazy', isa => HashRef );
has _related_has_many    => ( is => 'lazy', isa => HashRef );
has _hash_merge_prefetch => ( is => 'lazy', isa => InstanceOf ['Hash::Merge'] );

sub _build_rs {
    my ($self) = @_;
    if ( blessed $self->table and $self->table->isa('DBIx::Class::ResultSet') ) {
        return $self->table;
    }
    else {
        return $self->dbh->resultset( $self->table );
    }
}

sub _build__hashed_has_many {
    my ($self) = @_;
    return $self->_generate_hashed_has_many( $self->has_many );
}

sub _build__related_has_many {
    my ($self) = @_;
    return $self->_generate_related_has_many( $self->_hashed_has_many );
}

sub _build__hash_merge_prefetch {
    my $merge = Hash::Merge->new;
    $merge->set_behavior('RETAINMENT_PRECEDENT');
    return $merge;
}

sub _get_table_content {
    my ($self) = @_;
    my $limit = $self->limit;

    if ( $limit == -1 ) { $limit = undef; }

    my $attr = {
        order_by => $self->order_clause,
        rows     => $limit,
        offset   => $self->offset,
        alias    => $self->rs->result_source->name,
    };

    if ( my $prefetch = $self->_generate_prefetch_clause_for_where_clause ) {
        $attr->{prefetch} = $prefetch;
    }

    my $rs        = $self->rs->search_rs( $self->where_clause, $attr );
    my $rs_hashed = $self->rs->search_rs( $self->where_clause, $attr );
    my %rel_rs;

    my $aoData = [];
    if ( $self->return_hashref ) {
        $rs_hashed->result_class('DBIx::Class::ResultClass::HashRefInflator');
        while ( my $row = $rs->next ) {
            my $h = $rs_hashed->next;
            while ( my ( $rel_name, $v ) = each %{ $self->_related_has_many } ) {
                next if exists $h->{$rel_name};
                my $attr = {};
                if ( ref $v or $rel_name ne $v ) {
                    $attr->{prefetch} = $v;
                }
                my $rel_rs = $row->related_resultset($rel_name)->search_rs( {}, $attr );
                $rel_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
                $h->{$rel_name} = [ $rel_rs->all ];
            }
            push @$aoData, $self->_merge_data_default($h);
        }
    }
    else {
        $aoData = $rs;
    }
    return $aoData;
}

sub _generate_related_has_many {
    my ( $self, $data ) = @_;
    my $h;
    foreach my $v ( values %$data ) {
        if ( not defined $h ) {
            $h = $v;
        }
        else {
            $h = $self->_hash_merge_prefetch->merge( $h, $v );
        }
    }
    foreach my $key ( keys %$h ) {
        $h->{$key} = $self->_extract_hash( $h->{$key} );
    }
    return $h;
}

sub _generate_hashed_has_many {
    my ( $self, $ref ) = @_;
    my %h = ();
    if ( ref $ref eq 'HASH' ) {
        while ( my ( $k, $v ) = each %{$ref} ) {    # hash shoud have 1 key-value.
            my $hash_tmp = $self->_generate_hashed_has_many($v);
            foreach my $k2 ( keys %$hash_tmp ) {
                $h{"$k.$k2"} = { $k => $hash_tmp->{$k2} };
            }
        }
    }
    elsif ( ref $ref eq 'ARRAY' ) {
        foreach my $item (@$ref) {
            my $hash_tmp = $self->_generate_hashed_has_many($item);
            @h{ keys %$hash_tmp } = values %$hash_tmp;
        }
    }
    else {
        $h{$ref} = $ref;
    }
    return \%h;
}

sub _generate_prefetch_clause_for_where_clause {
    my ($self) = @_;
    $self->where_clause;    # setup where_fields
    my $prefetch;
    foreach my $field ( @{ $self->where_fields } ) {
        ( my $key = $field ) =~ s/\.[^\.]+\z//msx;
        if ( my $v = $self->_hashed_has_many->{$key} ) {
            if ( not defined $prefetch ) {
                $prefetch = $v;
            }
            else {
                $prefetch = $self->_hash_merge_prefetch->merge( $prefetch, $v );
            }
        }
    }
    return $self->_extract_hash($prefetch);
}

sub _extract_hash {
    my ( $self, $data ) = @_;
    my $ref = ref $data;
    if ( $ref eq 'ARRAY' ) {
        foreach my $item (@$data) {
            $item = $self->_extract_hash($item);
        }
    }
    elsif ( $ref eq 'HASH' ) {
        while ( my ( $k, $v ) = each %$data ) {
            $data->{$k} = $self->_extract_hash($v);
        }
        if ( keys %$data > 1 ) {
            return [
                map { ( not ref $data->{$_} and $_ eq $data->{$_} ) ? $_ : +{ $_ => $data->{$_} } }
                sort keys %$data
            ];
        }
        else {
            my ( $k, $v ) = each %$data;
            if ( not ref $v and $k eq $v ) {
                return $k;
            }
        }
    }
    return $data;
}

# _get_total_record_count()
#
# Get the number of records in the table, regardless of restrictions of the
# where clause or the limit clause. Used to display the total number of records
# without applied filters.

sub _get_total_record_count {
    my ($self) = @_;
    return $self->rs->count();
}

# _get_filtered_total()
#
# Get the total number of filtered records (in resprect of filters by the where
# clause, without limit). This accounts for the "search" field of data tables.

sub _get_filtered_total {
    my ($self) = @_;
    my $attr = {};
    if ( my $prefetch = $self->_generate_prefetch_clause_for_where_clause ) {
        $attr->{prefetch} = $prefetch;
    }
    return $self->rs->count( $self->where_clause, $attr );
}

1;

__END__

=pod

=head1 NAME

JQuery::DataTables::Heavy::DBIC - jquery datatable server side processing by DBIC

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 Method

=head1 PREREQUISITES

C<Moo>

=head1 Author

 Yusuke Watase <ywatase@gmail.com>
  
=cut
