package JQuery::DataTables::Heavy::Base;
use Moo::Role;
use MooX::Types::MooseLike::Base qw(:all);
use Hash::Merge;
use Clone;
use Carp;

has dbh                => ( is => 'rw', isa => Any,           required   => 1 );
has table              => ( is => 'rw', isa => Any,           required   => 1 );
has param              => ( is => 'rw', isa => HashRef,       required   => 1 );
has fields             => ( is => 'lazy', isa => ArrayRef[Str] );
has table_cols         => ( is => 'lazy', isa => ArrayRef[Str]);
has where_fields       => ( is => 'rw', isa => ArrayRef[Str], default    => sub { [] } );
has return_hashref     => ( is => 'rw', isa => Bool,          default    => sub { 1 } );
has table_data_default => ( is => 'lazy', isa => HashRef);
has hash_merge         => ( is => 'lazy', isa => InstanceOf['Hash::Merge'] );
has order_clause       => ( is => 'lazy', isa => ArrayRef);
has where_clause       => ( is => 'lazy', isa => HashRef);
has limit              => ( is => 'lazy', isa => Int);
has offset             => ( is => 'lazy', isa => Int);

requires qw(_get_filtered_total _get_table_content _get_total_record_count);

sub _build_fields {
    my ($self) = @_;
    my @field_names;
    for ( my $i = 0; $i < ( $self->param->{iColumns} || 0 ); $i++ ) {
        push @field_names, $self->param->{"mDataProp_$i"};
    }
    return \@field_names;
}

sub _build_table_cols {
    my ($self) = @_;
    my @cols = map {(my $s = $_) =~ s/\A.*\.(?=[^\.]+\.[^\.]+\z)//smx; $s} @{ $self->fields };
    return \@cols;
}

# suppress json warning on { table_name => undef }
sub _build_table_data_default {
    my ($self) = @_;
    my $base = {};
    foreach my $k ( @{ $self->fields } ) {
        next if $k eq '';
        my $hash = undef;
        foreach $k ( reverse split /\./, $k ) {
            $hash = { $k => $hash };
        }
        $base = Hash::Merge::merge( $hash, $base );
    }
    return $base;
}

sub _build_hash_merge {
    my $merge = Hash::Merge->new;
    $merge->specify_behavior(
        {   SCALAR => {
                SCALAR => sub { $_[0] },
                ARRAY  => sub { Carp::croak 'SCALAR and ARRAY cannot merge.' },
                HASH   => sub { defined $_[0] ? $_[0] : $_[1] },
            },
            ARRAY => {
                SCALAR => sub { $_[0] },
                ARRAY  => sub { $_[0] },
                HASH   => sub { $_[1]->{_ARRAY} = $_[0]; return $_[1] },    # for has_many Relation
            },
            HASH => {
                SCALAR => sub { Carp::croak 'HASH and SCALAR cannot merge.' },
                ARRAY  => sub { Carp::croak 'HASH and ARRAY cannot merge.' },
                HASH   => sub { Hash::Merge::_merge_hashes( $_[0], $_[1] ) },
            },
        },
        'MY_DATA_MERGE'
    );
    return $merge;
}

sub _build_where_clause {
    my ($self) = @_;
    return $self->_generate_where_clause;
}

sub _build_order_clause {
    my ($self) = @_;
    return $self->_generate_order_clause;
}

sub _build_limit {
    my ($self) = @_;
    return $self->param->{'iDisplayLength'} || 10;
}

sub _build_offset {
    my ($self) = @_;
    my $offset = 0;
    if ( $self->param->{'iDisplayStart'} ) {
        $offset = $self->param->{'iDisplayStart'};
    }
    return $offset;
}

sub table_data {
    my ($self) = @_;

    if (not defined $self->table) {
        return $self->_create_output( [] , 0, 0);
    }

    # -- get table contents
    my $aaData = $self->_get_table_content;

    # -- get meta information about the resultset
    my $iFilteredTotal = $self->_get_filtered_total;
    my $iTotal         = $self->_get_total_record_count;

    # -- build final data structure
    return $self->_create_output( $aaData, $iTotal, $iFilteredTotal);
}

sub _create_output {
    my ($self, $aaData, $iTotal, $iFilteredTotal) = @_;
    return {
        sEcho => int( $self->param->{'sEcho'} || 0 ),
        iTotalRecords        => int($iTotal),
        iTotalDisplayRecords => int($iFilteredTotal),
        aaData               => $aaData,
    };
}

# _get_table_content
# empty array. If there exist results, return value will be a two-dimensonal
# array.
# Basically, this method builds the SQL and fetches the results.

# _generate_order_clause
#
# Evaluate query for odering information. If present, generate order clause, if
# not, returns empty order clause.

sub _generate_order_clause {
    my ($self) = @_;
    my @order = ();

    if ( defined $self->param->{'iSortCol_0'} ) {
        for ( my $i = 0; $i < $self->param->{'iSortingCols'}; $i++ ) {

            # build direction, must be '-asc' or '-desc' (cf. SQL::Abstract)
            # we only get 'asc' or 'desc', so they have to be prefixed with '-'
            my $direction = '-' . $self->param->{ 'sSortDir_' . $i };

            # We only get the column index (starting from 0), so we have to
            # translate the index into a column name.
            my $column_name = $self->table_cols->[ $self->param->{ 'iSortCol_' . $i } ];
            push @order, { $direction => $column_name };
        }
    }

    return \@order;
}

# _generate_where_clause
#
# Evaluate global search information, that is, information by which each field
# has to be restricted. If present, generate matching conditions for each
# searchable column (searchability indicated by query parameters) and combine
# as disjunction (OR).
#
# NOTE this does not match the built-in DataTables filtering which does it
# word by word on any field. It's possible to do here, but concerned about
# efficiency on very large tables, and MySQL's regex functionality is very
# limited.

sub _generate_where_clause {
    my ($self)        = @_;
    my %where         = ();
    my $search_string = $self->param->{'sSearch'};

    for ( my $i = 0; $i < ( $self->param->{'iColumns'} || 0 ); $i++ ) {

        # Iterate over each column and check if it is searchable.
        # If so, add a constraint to the where clause restricting the given
        # column. In the query, the column is identified by it's index, we
        # need to translates the index to the column name.
        my $searchable_ident = 'bSearchable_' . $i;
        if ( $self->param->{$searchable_ident} and $self->param->{$searchable_ident} eq 'true' ) {
            my $column = $self->table_cols->[$i];
            my $field  = $self->fields->[$i];

            # global search
            if ( defined $search_string and $search_string ne "" ) {
                if ( $self->param->{'bRegex'} eq 'true' ) {
                    push @{ $where{'-or'} }, { $column => { -regexp => $search_string } };
                }
                else {
                    push @{ $where{'-or'} }, { $column => { -like => '%' . $search_string . '%' } };
                }
                push @{$self->where_fields}, $field;
            }

            # each column search
            my $column_search_string = $self->param->{ 'sSearch_' . $i };
            if ( defined $column_search_string and $column_search_string ne "" ) {
                if ( $self->param->{ 'bRegex_' . $i } eq 'true' ) {
                    push @{ $where{'-and'} }, { $column => { -regexp => $column_search_string } };
                }
                else {
                    push @{ $where{'-and'} },
                        { $column => { -like => '%' . $column_search_string . '%' } };
                }
                push @{$self->where_fields}, $field;
            }
        }
    }
    return \%where;
}

sub _get_table_data_default {
    my ( $self, $data ) = @_;
    return Clone::clone( $self->table_data_default );
}

sub _merge_data_default {
    my ( $self, $data ) = @_;
    return $self->hash_merge->merge( $data, $self->_get_table_data_default );
}

1;

__END__

=pod

=head1 NAME

JQuery::DataTables::Heavy::Base - Base Role

=head1 SYNOPSIS

  package JQuery::DataTables::Heavy::DBIC;
  use Moo;
  with 'JQuery::DataTables::Heavy::Base';

=head1 DESCRIPTION

=head1 Method

=head1 PREREQUISITES

L<Moo>, L<MooX::Types::MooseLike::Base>, L<Hash::Merge>, L<Clone>


=head1 Author

 Yusuke Wtase <ywatase@gmail.com>

=cut
