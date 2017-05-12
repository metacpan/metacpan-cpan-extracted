package Fey::Meta::Role::Relationship::ViaFK;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.47';

use Fey::Exceptions qw( param_error );
use Fey::ORM::Types qw( Bool );

use Moose::Role;

has fk => (
    is        => 'ro',
    isa       => 'Fey::FK',
    lazy      => 1,
    builder   => '_build_fk',
    predicate => '_has_fk',
    writer    => '_set_fk',
);

has _is_has_many => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    default => sub { ( ref $_[0] ) =~ /HasMany/ ? 1 : 0 },
);

sub BUILD { }

after BUILD => sub {
    my $self = shift;

    return unless $self->_has_fk();

    $self->_set_fk( $self->_invert_fk_if_necessary( $self->fk() ) );
};

sub _build_fk {
    my $self = shift;

    $self->_find_one_fk_between_tables(
        $self->table(),
        $self->foreign_table(),
    );
}

sub _find_one_fk_between_tables {
    my $self         = shift;
    my $source_table = shift;
    my $target_table = shift;

    my @fk = $source_table->schema()
        ->foreign_keys_between_tables( $source_table, $target_table );

    my $desc = $self->_is_has_many() ? 'has_many' : 'has_one';

    if ( @fk == 0 ) {
        param_error
            'There are no foreign keys between the table for this class, '
            . $source_table->name()
            . " and the table you passed to $desc(), "
            . $target_table->name() . '.';
    }
    elsif ( @fk > 1 ) {
        param_error
            'There is more than one foreign key between the table for this class, '
            . $source_table->name()
            . " and the table you passed to $desc(), "
            . $target_table->name()
            . '. You must specify one explicitly.';
    }

    return $self->_invert_fk_if_necessary( $fk[0] );
}

# We may need to invert the meaning of source & target since source &
# target for an FK object are sort of arbitrary. The source should be
# "our" table, and the target the foreign table.
sub _invert_fk_if_necessary {
    my $self = shift;
    my $fk   = shift;

    # Self-referential keys are a special case, and that case differs
    # for has_one vs has_many.
    if ( $fk->is_self_referential() ) {
        if ( $self->_is_has_many() ) {
            return $fk
                unless $fk->target_table()
                ->has_candidate_key( @{ $fk->target_columns() } );
        }
        else {

            # A self-referential key is a special case. If the target
            # columns are _not_ a key, then we need to invert source &
            # target so we do our select by a key. This doesn't
            # address a pathological case where neither source nor
            # target column sets make up a key. That shouldn't happen,
            # though ;)
            return $fk
                if $fk->target_table()
                ->has_candidate_key( @{ $fk->target_columns() } );
        }
    }
    else {
        return $fk
            if $fk->target_table()->name() eq $self->foreign_table->name();
    }

    return Fey::FK->new(
        source_columns => $fk->target_columns(),
        target_columns => $fk->source_columns(),
    );
}

1;
