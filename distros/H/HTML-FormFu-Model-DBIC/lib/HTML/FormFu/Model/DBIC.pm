package HTML::FormFu::Model::DBIC;

use strict;
use warnings;
use base 'HTML::FormFu::Model';

our $VERSION = '2.03'; # VERSION

use HTML::FormFu::Util qw( _merge_hashes );
use List::MoreUtils qw( none notall );
use List::Util qw( first );
use Scalar::Util qw( blessed reftype );
use Storable qw( dclone );
use Carp qw( croak );

sub options_from_model {
    my ( $self, $base, $attrs ) = @_;

    my $form      = $base->form;
    my $resultset = _get_resultset( $base, $form, $attrs );
    my $source    = $resultset->result_source;

    my $id_col     = $attrs->{id_column};
    my $label_col  = $attrs->{label_column};
    my $condition  = $attrs->{condition};
    my $attributes = $attrs->{attributes} || {};

    my $enum_col =
        first {
            lc( $base->name ) eq lc($_);
        }
        grep {
            my $data_type = $source->column_info($_)->{data_type};
            defined $data_type && $data_type =~ /enum/i
        } $source->columns;

    if ( defined $enum_col ) {
        return map {
            [ $_, $_ ]
        } @{ $source->column_info($enum_col)->{extra}{list} };
    }

    if ( !defined $id_col ) {
        ($id_col) = $source->primary_columns;
    }

    if ( !defined $label_col ) {

        # use first text column
        ($label_col) = grep {
            my $data_type = $source->column_info($_)->{data_type};
            defined $data_type && $data_type =~ /text|varchar/i
        } $source->columns;
    }
    $label_col = $id_col if !defined $label_col;

    if ( defined( my $from_stash = $attrs->{condition_from_stash} ) ) {
        $condition
            = $condition
            ? { %{$condition} }
            : {};    # avoid overwriting attrs->{condition}
        for my $name ( keys %$from_stash ) {
            croak "config value must not be a reference" if ref $from_stash->{$name};
            if ( $attrs->{expand_stash_dots} ) {
                $condition->{$name} = $self->_get_stash_value( $form->stash, $from_stash->{$name} );
            }
            else {
                $condition->{$name} = $form->stash->{ $from_stash->{$name} };
            }
        }
    }

    # save the expanded condition for later use
    $attrs->{'-condition'} = $condition if ($condition);

    $attributes->{'-columns'} = [ $id_col, $label_col ];

    my $result = $resultset->search( $condition, $attributes );

    my @defaults   = $result->all;
    my $has_column = $source->has_column($label_col);

    if ( $attrs->{localize_label} ) {
        @defaults = map {
            {   value     => $_->get_column($id_col),
                label_loc => $has_column ? $_->get_column($label_col) : $_->$label_col,
            }
        } @defaults;
    }
    else {
        @defaults = map { [
                $_->get_column($id_col),
                $has_column ? $_->get_column($label_col) : $_->$label_col,
            ]
        } @defaults;
    }

    return @defaults;
}

sub _get_stash_value {
    my ( $self, $stash, $key ) = @_;
    my $base = $stash;

    if ( $key =~ /\./ ) {
        for my $part ( grep {length} split qr/\./, $key ) {
            if ( blessed($base) && $base->can($part) ) {
                $base = $base->$part;
            }
            elsif ( 'HASH' eq reftype($base) ) {
                $base = $base->{$part};
            }
            elsif ( 'ARRAY' eq reftype($base) && $key =~ /^[0-9]+\z/ ) {
                $base = $base->[$key];
            }
            else {
                croak "don't know what to do with part '$part' in key '$key'";
            }
        }
    }

    return $base;
}

sub _get_resultset {
    my ( $base, $form, $attrs ) = @_;

    my $schema  = $form->stash->{schema};
    my $context = $form->stash->{context};

    if ( defined $schema ) {
        my $rs_name = $attrs->{resultset} || ucfirst $base->name;

        return $schema->resultset($rs_name);
    }
    elsif ( defined $context && defined $attrs->{model} ) {

        my $model = $context->model( $attrs->{model} );

        if ( defined( my $rs = $attrs->{resultset} ) ) {
            $model = $model->resultset($rs);
        }

        return $model;
    }
    elsif ( defined $context ) {
        my $model = $context->model;

        return $model if defined $model;
    }

    croak "need a schema or context";
}

sub default_values {
    my ( $self, $dbic, $attrs ) = @_;

    my $form = $self->form;
    my $base = defined $attrs->{base} ? delete $attrs->{base} : $form;

    $base = $form->get_all_element( { nested_name => $attrs->{nested_base} } )
        if defined $attrs->{nested_base}
            && ( !defined $base->nested_name
                || $base->nested_name ne $attrs->{nested_base} );

    _fill_in_fields( $base, $dbic );
    _fill_nested( $self, $base, $dbic );

    return $form;
}

# returns 0 if there is a node with nested_name set on the path from $field to $base
sub is_direct_child {
    my ( $base, $field ) = @_;

    while ( defined $field->parent ) {
        $field = $field->parent;

        return 1 if $base == $field;
        return 0 if defined $field->nested_name;
    }
}

# fills in values for all direct children fields of $base
sub _fill_in_fields {
    my ( $base, $dbic ) = @_;
    for my $field ( @{ $base->get_fields } ) {
        my $name   = $field->name;
        my $config = $field->model_config;

        next if not defined $name || $config->{accessor};
        next if not is_direct_child( $base, $field );

        $name = $field->original_name if $field->original_name;

        my $accessor = $config->{accessor};

        if ( defined $accessor ) {
            $field->default( $dbic->$accessor );
        }
        elsif ( $dbic->can($name) ) {
            my $has_col = $dbic->result_source->has_column($name);
            my $has_rel = $dbic->result_source->has_relationship($name);

            if ( $has_col && $has_rel ) {

                # can't use direct accessor, if there's a rel of the same name
                $field->default( $dbic->get_column($name) );
            }
            elsif ($has_col) {
                $field->default( $dbic->$name );
            }
            elsif (
                $field->multi_value
                && ($config->{default_column}
                    || ( ref( $dbic->$name )
                        && $dbic->$name->can('result_source') ) ) )
            {

                my ($col) = $config->{default_column}
                    || $dbic->$name->result_source->primary_columns;

                my $info = $dbic->result_source->relationship_info($name);

                if ( !defined $info or $info->{attrs}{accessor} eq 'multi' ) {
                    my @defaults = $dbic->$name->get_column($col)->all;
                    $field->default( \@defaults );
                }
                else {

                    # has_one/might_have
                    my ($pk) = $dbic->result_source->primary_columns;
                    $field->default( $dbic->$name->$pk );
                }
            }
            else {

                # This field is a method expected to return the value
                $field->default( $dbic->$name );
            }
        }

        # handle {label}

        if ( defined( my $label = $config->{label} ) ) {
            my $has_rel = $dbic->result_source->has_relationship($label);

            if ($has_rel) {

                # can't use direct accessor, if there's a rel of the same name
                $field->label( $dbic->get_column($label) );
            }
            else {
                $field->label( $dbic->$label );
            }
        }
    }
}

# loop over all child blocks with nested_name that is a method on the DBIC row
# and recurse
sub _fill_nested {
    my ( $self, $base, $dbic ) = @_;

    for my $block ( @{ $base->get_all_elements } ) {
        next if $block->is_field && !$block->is_block;
        next if !$block->can('nested_name');

        my $config = $block->model_config;

        # first handle {label}

        if ( defined( my $label = $config->{label} ) && $block->can('label') ) {
            my $has_rel = $dbic->result_source->has_relationship($label);

            if ($has_rel) {

                # can't use direct accessor, if there's a rel of the same name
                $block->label( $dbic->get_column($label) );
            }
            else {
                $block->label( $dbic->$label );
            }
        }

        my $rel = $block->nested_name;
        next if !defined $rel;

        my $has_rel = $dbic->result_source->relationship_info($rel)
            || ( $dbic->can($rel) && $dbic->can( 'add_to_' . $rel ) )
            ;    # many_to_many

        # recursing only when $rel is a relation or non-column accessor on $dbic
        next
            unless $has_rel
                || ( $dbic->can($rel)
                    && !$dbic->result_source->has_column($rel) );

        if ( $block->is_repeatable && $block->increment_field_names ) {

            # check there's a field name matching the PK
            my ($pk) = $dbic->$rel->result_source->primary_columns;

            next
                unless grep {
                $pk eq
                    ( defined $_->original_name ? $_->original_name : $_->name )
                } @{ $block->get_fields( { type => 'Hidden' } ) };

            my @rows = $dbic->$rel->all;

            my $count
                = $config->{empty_rows}
                ? scalar @rows + $config->{empty_rows}
                : scalar @rows;

            my $blocks = $block->repeat($count);

            $block->process;

            for my $rep ( 0 .. $#rows ) {
                default_values( $self, $rows[$rep],
                    { base => $blocks->[$rep] } );
            }

            # set the counter field to the number of rows

            if ( defined( my $param_name = $block->counter_name ) ) {
                my ($field) = grep {
                    $param_name eq (
                        defined $_->original_name
                        ? $_->original_name
                        : $_->name )
                } @{ $base->get_fields };

                $field->default($count)
                    if defined $field;
            }

            # remove 'delete' checkbox from the last repetition ?

            if ( $config->{empty_rows} ) {

                my $new_row_count
                    = $config->{empty_rows}
                    ? $config->{empty_rows}
                    : 1;

                my @reps = reverse @{ $block->get_elements };

                for my $i ( 0 .. ( $new_row_count - 1 ) ) {

                    my $rep = $reps[$i];

                    my ($del_field)
                        = grep { $_->model_config->{delete_if_true} }
                        @{ $rep->get_fields };

                    if ( defined $del_field ) {
                        $del_field->parent->remove_element($del_field);
                    }
                }
            }
        }
        else {
            if ( defined( my $row = $dbic->$rel ) ) {
                default_values( $self, $row, { base => $block } );
            }
        }
    }
    return;
}

sub create {
    my ( $self, $attrs ) = @_;

    croak "invalid arguments" if @_ > 2;

    my $form = $self->form;
    my $base = defined $attrs->{base} ? delete $attrs->{base} : $form;

    my $schema = $form->stash->{schema}
        or croak 'schema required on form stash, if no row object provided';

    my $resultset
        = $attrs->{resultset}
        || $base->model_config->{resultset}
        || $form->model_config->{resultset}
        or croak 'could not find resultset name';

    $resultset = $schema->resultset($resultset);

    my $dbic = $resultset->new_result( {} );

    return $self->update( $dbic, { %$attrs, base => $base } );
}

sub update {
    my ( $self, $dbic, $attrs ) = @_;

    croak "row object missing" if !defined $dbic;

    my $form = $self->form;
    my $base = defined $attrs->{base} ? delete $attrs->{base} : $form;

    $base = $form->get_all_element( { nested_name => $attrs->{nested_base} } )
        if defined $attrs->{nested_base}
            && ( !defined $base->nested_name
                || $base->nested_name ne $attrs->{nested_base} );

    my $rs   = $dbic->result_source;
    my @rels = $rs->relationships;
    my @cols = $rs->columns;

    # check for belongs_to relationships with a required foreign key
    my (@belongs_to_rels, @other_rels);

    foreach my $rel (@rels) {
        # 'fk_columns' is set for belong_to rels in DBIx::Class::Relationship::BelongsTo
        my @fk_columns = keys %{ $dbic->relationship_info($rel)->{attrs}{fk_columns} };

        if (@fk_columns) {
            push @belongs_to_rels, $rel;
        } else {
            push @other_rels, $rel;
        }
    }

    # add belongs_to rels before insert
    if (@belongs_to_rels) {
        # tell _save_relationships not to update $dbic yet, just add the rels
        my %attrs = ( %$attrs, no_update => 1 );
        _save_relationships( $self, $base, $dbic, $form, $rs, \%attrs, \@belongs_to_rels );
    }


    _save_columns( $base, $dbic, $form ) or return;

    $dbic->update_or_insert;

    _save_relationships( $self, $base, $dbic, $form, $rs, $attrs, \@other_rels );

    _save_multi_value_fields_many_to_many( $base, $dbic, $form, $attrs, \@rels,
        \@cols );

    _save_repeatable_many_to_many( $self, $base, $dbic, $form, $attrs, \@rels,
        \@cols );

    # handle non-rel, non-column, nested_base accessors.
    # - this highlights a failing of the approach of iterating over
    # db cols + rels - we should maybe refactor to iterate over
    # form blocks and fields instead ?

    for my $block ( @{ $base->get_all_elements } ) {
        next if $block->is_field;
        next if !$block->can('nested_name');

        my $rel = $block->nested_name;
        next if !defined $rel;

        next unless $dbic->can($rel);

        next if grep { $rel eq $_ } @cols;
        next if grep { $rel eq $_ } @rels;

        next if $dbic->can( "add_to_" . $rel );    # many-to-many

        if ( defined( my $row = $dbic->$rel ) ) {
            update( $self, $row, { base => $block } );
        }
    }

    return $dbic;
}

sub _save_relationships {
    my ( $self, $base, $dbic, $form, $rs, $attrs, $rels ) = @_;

    return if $attrs->{no_follow};

    for my $rel (@$rels) {

        # don't follow rels to where we came from
        next
            if defined $attrs->{from}
                && $attrs->{from} eq $rs->related_source($rel)->result_class;

        my @elements = @{ $base->get_all_elements( { nested_name => $rel } ) };

        my ($block) = grep { !$_->is_field } @elements;
        my ($multi_value) = grep { $_->is_field && $_->multi_value } @elements;
        my ($combo) = grep { $_->isa('HTML::FormFu::Element::ComboBox') } @elements;

        next if !defined $block && !defined $multi_value;
        next if !$form->valid($rel);

        my $params = $form->param($rel);

        if ( defined $block && $block->is_repeatable ) {

            # Handle has_many

            _save_has_many( $self, $dbic, $form, $rs, $block, $rel, $attrs );

        }
        elsif ( defined $combo ) {

            _save_combobox( $self, $base, $dbic, $form, $rs, $combo, $rel, $attrs );
        }
        elsif ( defined $block && ref $params eq 'HASH' ) {
            # It seems that $dbic->$rel must be called otherwise the following
            # find_related() can fail.
            # However, this can die - so we're just wrapping it in an eval
            eval {
                $dbic->$rel;
            } or $dbic->discard_changes;

            my $target = $dbic->find_related( $rel, {} );

            if ( !defined $target && grep { length $_ } values %$params ) {
                $target = $dbic->new_related( $rel, {} );
            }

            next if !defined $target;

            update(
                $self, $target,
                {   %$attrs,
                    base        => $block,
                    nested_base => $rel,
                    from        => $dbic->result_class,
                } );
            unless ( $dbic->$rel ) {
                $dbic->$rel($target);
                $dbic->update unless $attrs->{no_update};
            }
        }
        elsif ( defined $multi_value ) {

            # belongs_to, has_one or might_have relationship

            my $info = $dbic->result_source->relationship_info($rel);

            my @fpkey = $dbic->related_resultset($rel)
                ->result_source->primary_columns;

            my @cond = ( %{ $info->{cond} } );

            # make sure $rel is a has_one or might_have rel
            # stolen from SQL/Translator/Parser/DBIx/Class

            my $fk_constraint;

            # Get the key information, mapping off the foreign/self markers
            my @refkeys = map {/^\w+\.(\w+)$/} @cond;
            my @keys = map { $info->{cond}{$_} =~ /^\w+\.(\w+)$/ }
                grep { exists $info->{cond}{$_} } @cond;

            #first it can be specified explicitly
            if ( exists $info->{attrs}{is_foreign_key_constraint} ) {
                $fk_constraint = $info->{attrs}{is_foreign_key_constraint};
            }

            # it can not be multi
            elsif ($info->{attrs}{accessor}
                && $info->{attrs}{accessor} eq 'multi' )
            {
                $fk_constraint = 0;
            }

            # if indeed single, check if all self.columns are our primary keys.
            # this is supposed to indicate a has_one/might_have...
            # where's the introspection!!?? :)
            else {
                $fk_constraint
                    = not _compare_relationship_keys( \@keys, \@fpkey );
            }

            next if ($fk_constraint);

            my $fpkey = shift @fpkey;
            my ( $fkey, $skey ) = @cond;
            $fkey =~ s/^foreign\.//;
            $skey =~ s/^self\.//;

            my $fclass = $info->{class};

            croak
                'The primary key and the foreign key may not be the same column in class '
                . $fclass
                if $fpkey eq $fkey;

            croak
                'multiple primary keys are not supported for has_one/might_have relationships'
                if ( @fpkey > 1 );

            my $schema = $dbic->result_source->schema;

            # use transactions if supported by storage
            $schema->txn_do(
                sub {

                    # reset any previous items which were related to $dbic
                    $rs->schema->resultset($fclass)
                        ->search( { $fkey => $dbic->$skey } )
                        ->update( { $fkey => undef } );

                    # set new related item
                    my $updated
                        = $rs->schema->resultset($fclass)
                        ->search( { $fpkey => $params } )
                        ->update( { $fkey => $dbic->$skey } );

                    $schema->txn_rollback
                        if $updated != 1;

                } );
        }
    }
}

sub _save_combobox {
    my ( $self, $base, $dbic, $form, $rs, $combo, $rel, $attrs ) = @_;

    my $select = $combo->get_field({ type => 'Select' });
    my $text   = $combo->get_field({ type => 'Text' });

    my $select_value = $form->param( $select->nested_name );
    my $text_value   = $form->param( $text->nested_name );

    my $target_rs = $dbic->result_source->related_source( $rel )->resultset;
    my $target;

    if ( defined $select_value && length $select_value ) {
        my $pk_name = $combo->model_config->{select_column};

        $target = $target_rs->find(
            {
                $pk_name => $select_value,
            },
        );
    }
    else {
        my $column_name = $combo->model_config->{text_column};

        $target = $target_rs->create(
            {
                $column_name => $text_value,
            },
        );
    }

    $dbic->set_from_related( $rel, $target );
    $dbic->update;
}

# Copied from DBIx::Class::ResultSource
sub _compare_relationship_keys {
    my ( $keys1, $keys2 ) = @_;

    # Make sure every keys1 is in keys2
    my $found;
    foreach my $key (@$keys1) {
        $found = 0;
        foreach my $prim (@$keys2) {
            if ( $prim eq $key ) {
                $found = 1;
                last;
            }
        }
        last unless $found;
    }

    # Make sure every key2 is in key1
    if ($found) {
        foreach my $prim (@$keys2) {
            $found = 0;
            foreach my $key (@$keys1) {
                if ( $prim eq $key ) {
                    $found = 1;
                    last;
                }
            }
            last unless $found;
        }
    }

    return $found;
}

sub _save_has_many {
    my ( $self, $dbic, $form, $rs, $block, $rel, $attrs ) = @_;

    return unless $block->increment_field_names;

    # check there's a field name matching the PK

    my ($pk) = $rs->related_source($rel)->primary_columns;

    return
        unless grep { $_->original_name eq $pk }
            @{ $block->get_fields( { type => 'Hidden' } ) };

    my @blocks = @{ $block->get_elements };
    my $max    = $#blocks;
    my $config = $block->model_config;

    my $new_rows_max = $config->{new_rows_max} || $config->{empty_rows} || 0;
    my $new_rows_counter = 0;

    # iterate over blocks, not rows
    # new rows might have been created in the meantime

    for my $i ( 0 .. $max ) {
        my $rep = $blocks[$i];

        # find PK field

        my ($pk_field)
            = grep { $_->original_name eq $pk }
            @{ $rep->get_fields( { type => 'Hidden' } ) };

        next if !defined $pk_field;

        my $value = $form->param_value( $pk_field->nested_name );
        my $row;

        if (( !defined $value || $value eq '' )
            && ( $new_rows_max
                && ( ++$new_rows_counter <= $new_rows_max ) ) )
        {

            # insert a new row
            $row = _insert_has_many( $dbic, $form, $config, $rep, $rel,
                $pk_field );

            next if !defined $row;
        }
        elsif ( !defined $value || $value eq '' ) {
            next;
        }
        else {
            $row = $dbic->find_related( $rel, $value );
        }
        next if !defined $row;

        # should we delete the row?

        next if _delete_has_many( $form, $row, $rep );

        update(
            $self, $row,
            {   %$attrs,
                base        => $rep,
                repeat_base => $rel,
                from        => $dbic->result_class,
            } );
    }
}

sub _insert_has_many {
    my ( $dbic, $form, $config, $repetition, $rel, $pk_field ) = @_;

    return
        if !_can_insert_new_row( $dbic, $form, $config, $repetition, $rel,
                $pk_field );

    my $row = $dbic->new_related( $rel, {} );

    return $row;
}

sub _can_insert_new_row {
    my ( $dbic, $form, $config, $repetition, $rel, $pk_field ) = @_;

    my @rep_fields = @{ $repetition->get_fields };

    my $pk_name = $pk_field->nested_name;

    my @constraints = grep { $_->when->{field} eq $pk_name }
        grep { defined $_->when }
        map { @{ $_->get_constraints( { type => 'Required' } ) } } @rep_fields;

    my @required_fields;

    if (@constraints) {

        # if there are any Required constraints whose 'when' clause points to
        # the PK field - check that all these fields are filled in - as
        # the PK value is missing on new reps, so the constraint won't have run

        return
            if notall { defined && length }
            map { $form->param_value( $_->nested_name ) }
            map { $_->parent } @constraints;
    }
    else {

        # otherwise, just check at least 1 field that matches either a column
        # name or an accessor, is filled in

        my $result_source = $dbic->$rel->result_source;

        #  only create a new record if (read from bottom)...

        return
            if none { defined && length }
            map { $form->param_value( $_->nested_name ) }
                grep {
                           $result_source->has_column( $_->original_name )
                        || $result_source->can( $_->original_name )
                }
                grep { defined $_->original_name } @rep_fields;
    }

    return 1;
}

sub _delete_has_many {
    my ( $form, $row, $rep ) = @_;

    my ($del_field)
        = grep { $_->model_config->{delete_if_true} } @{ $rep->get_fields };

    return if !defined $del_field;

    my $nested_name = $del_field->nested_name;

    return
        unless $form->valid($nested_name)
            && $form->param_value($nested_name);

    $row->delete if ( $row->in_storage );

    return 1;
}

sub _fix_value {
    my ( $dbic, $col, $value, $field, ) = @_;

    my $col_info    = $dbic->column_info($col);
    my $is_nullable = $col_info->{is_nullable} || 0;
    my $data_type   = $col_info->{data_type} || '';

    if ( defined $value ) {
        if ( ( (     $is_nullable
                  && $data_type =~ m/^timestamp|date|int|float|numeric/i
            ) or $field->model_config->{null_if_empty} )

            # comparing to '' does not work for inflated objects
            && !ref $value
            && $value eq ''
            )
        {
            $value = undef;
        }
    }

    if (  !defined $value
        && defined $field
        && $field->isa('HTML::FormFu::Element::Checkbox')
        && !$is_nullable )
    {
        $value = 0;
    }

    return $value;
}

sub _save_columns {
    my ( $base, $dbic, $form ) = @_;

    for my $field ( @{ $base->get_fields }, ) {
        next if not is_direct_child( $base, $field );

        my $config = $field->model_config;
        next if $config->{delete_if_true};
        next if $config->{read_only};

        my $name = $field->name;
        $name = $field->original_name if $field->original_name;

        my $accessor = $config->{accessor} || $name;
        next if not defined $accessor;

        my $value = ( $dbic->result_source->has_column($accessor)
				  and exists $dbic->result_source->column_info($accessor)->{is_array} )
			? $form->param_array( $field->nested_name )
        	: $form->param_value( $field->nested_name ) ;

        next
            if $config->{ignore_if_empty}
                && ( !defined $value || $value eq "" );

        my ($pk) = $dbic->result_source->primary_columns;

        # don't set primary key to null or '' - for Pg SERIALs
        next if ( $name eq $pk ) && !( defined $value && length $value );

        if ( $config->{delete_if_empty}
            && ( !defined $value || !length $value ) )
        {
            $dbic->discard_changes if $dbic->is_changed;
            $dbic->delete          if $dbic->in_storage;
            return;
        }
        if ( $dbic->result_source->has_column($accessor) ) {
            $value = _fix_value( $dbic, $accessor, $value, $field );
        }
        elsif ( $field->isa('HTML::FormFu::Element::Checkbox') ) {

            # We are a checkbox.
            unless ( defined $value ) {
                $value = 0;
            }
        }

        if (   !$config->{accessor}
            and $dbic->result_source->has_relationship($accessor)
            and $dbic->result_source->has_column($accessor) )
        {
            $dbic->set_column( $accessor, $value );
        }
        elsif (
            $dbic->can($accessor)

# and $accessor is not a has_one or might_have rel where the foreign key is on the foreign table
            and !$dbic->result_source->relationship_info($accessor)
            and !$dbic->can( 'add_to_' . $accessor ) )
        {
            $dbic->$accessor($value);
        }
        else {

            # We should just ignore
            #croak "cannot call $accessor on $dbic";
        }
    }

# for values inserted by add_valid - and not correlated to any field in the form
    my $parent = $base;
    do {
        return 1 if defined $parent->nested_name;
        $parent = $parent->parent;
    } until ( !defined $parent );

    for my $valid ( $form->valid ) {
        next if @{ $base->get_fields( name => $valid ) };
        next if not $dbic->can($valid);

        my $value = $form->param_value($valid);
        $dbic->$valid($value);
    }

    return 1;
}

sub _save_multi_value_fields_many_to_many {
    my ( $base, $dbic, $form, $attrs, $rels, $cols ) = @_;

    my @fields = grep {
        ( defined $attrs->{nested_base} && defined $_->parent->nested_name )
            ? $_->parent->nested_name eq $attrs->{nested_base}
            : !$_->nested
        }
        grep { $_->multi_value }
        grep { defined $_->name } @{ $base->get_fields };

    for my $field (@fields) {
        my $name = $field->name;

        next if grep { $name eq $_ } @$rels, @$cols;

        if ( $dbic->can($name) ) {
            my $related = $dbic->$name;

            next if !blessed($related) || !$related->can('result_source');

            my $nested_name = $field->nested_name;

            next if $form->has_errors($nested_name);

            my @values = $form->param_list($nested_name);
            my @rows;

            my $config = $field->model_config;

            next if $config->{read_only};

            my ($pk) = $config->{default_column}
                || $related->result_source->primary_columns;

            if (@values) {

                $pk = "me.$pk" unless $pk =~ /\./;

                @rows = $related->result_source->resultset->search( {
                        %{ $config->{condition} || {} },
                        $pk => { -in => \@values } } )->all;
            }

            if ( $config->{additive} ) {
                $pk =~ s/^.*\.//;

                my $set_method    = "add_to_$name";
                my $remove_method = "remove_from_$name";

                foreach my $row (@rows) {
                    $dbic->$remove_method($row);
                    $dbic->$set_method( $row, $config->{link_values} );
                }
            }
            else {

                # check if there is a restricting condition on here
                # if so life is more complex
                my $condition = $config->{'-condition'};
                if ($condition) {
                    my $set_method    = "add_to_$name";
                    my $remove_method = "remove_from_$name";
                    foreach ( $dbic->$name->search($condition)->all ) {
                        $dbic->$remove_method($_);
                    }
                    foreach my $row (@rows) {
                        $dbic->$set_method( $row, $config->{link_values} );
                    }
                }
                else {
                    my $set_method = "set_$name";
                    $dbic->$set_method( \@rows, $config->{link_values} );
                }
            }
        }
    }
}

sub _save_repeatable_many_to_many {
    my ( $self, $base, $dbic, $form, $attrs, $rels, $cols ) = @_;

    my @blocks
        = grep { !$_->is_field && $_->is_repeatable && $_->increment_field_names }
        @{ $base->get_all_elements };

    for my $block (@blocks) {
        my $rel = $block->nested_name;

        next if !defined $rel;
        next if grep { $rel eq $_ } @$rels, @$cols;

        if ( $dbic->can($rel) ) {

            # check there's a field name matching the PK

            my ($pk) = $dbic->$rel->result_source->primary_columns;

            my @blocks = @{ $block->get_elements };
            my $max    = $#blocks;

            # iterate over blocks, not rows
            # new rows might have been created in the meantime

            for my $i ( 0 .. $max ) {
                my $rep = $blocks[$i];

                # find PK field

                my ($pk_field)
                    = grep { $_->original_name eq $pk }
                    @{ $rep->get_fields( { type => 'Hidden' } ) };

                next if !defined $pk_field;

                my $value = $form->param_value( $pk_field->nested_name );
                my $row;
                my $is_new;

                my $config = $block->model_config;
                my $new_rows_max
                    = $config->{new_rows_max}
                    || $config->{empty_rows}
                    || 0;
                my $new_rows_counter = 0;

                if (( !defined $value || $value eq '' )
                    && ( $new_rows_max
                        && ( ++$new_rows_counter <= $new_rows_max ) ) )
                {

                    # insert a new row
                    $row = _insert_many_to_many( $dbic, $form, $config, $rep,
                        $rel, $pk_field );

                    next if !defined $row;

                    $is_new = 1;
                }
                elsif ( !defined $value || $value eq '' ) {
                    next;
                }
                else {
                    $row = $dbic->$rel->find($value);
                }
                next if !defined $row;

                # should we delete the row?

                next if _delete_many_to_many( $form, $dbic, $row, $rel, $rep );

                update(
                    $self, $row,
                    {   %$attrs,
                        base        => $rep,
                        repeat_base => $rel,
                        from        => $dbic->result_class,
                    } );

                if ($is_new) {

                    # new rows need to be related
                    my $add_method = "add_to_$rel";

                    $dbic->$add_method($row);
                }
            }
        }
    }
    return;
}

sub _insert_many_to_many {
    my ( $dbic, $form, $config, $repetition, $rel, $pk_field ) = @_;

    return
        if !_can_insert_new_row( $dbic, $form, $config, $repetition, $rel,
                $pk_field );

    my $row = $dbic->$rel->new( {} );

    # add_to_* will be called later, after update is called on this row

    return $row;
}

sub _delete_many_to_many {
    my ( $form, $dbic, $row, $rel, $rep ) = @_;

    my ($del_field)
        = grep { $_->model_config->{delete_if_true} } @{ $rep->get_fields };

    return if !defined $del_field;

    my $nested_name = $del_field->nested_name;

    return
        unless $form->valid($nested_name)
            && $form->param_value($nested_name);

    my $remove = "remove_from_$rel";

    $dbic->$remove($row);

    return 1;
}

1;

__END__

=head1 NAME

HTML::FormFu::Model::DBIC - Integrate HTML::FormFu with DBIx::Class

=head1 VERSION

version 2.03

=head1 SYNOPSIS

Example of typical use in a Catalyst controller:

    sub edit : Chained {
        my ( $self, $c ) = @_;

        my $form = $c->stash->{form};
        my $book = $c->stash->{book};

        if ( $form->submitted_and_valid ) {

            # update dbic row with submitted values from form

            $form->model->update( $book );

            $c->response->redirect( $c->uri_for('view', $book->id) );
            return;
        }
        elsif ( !$form->submitted ) {

            # use dbic row to set form's default values

            $form->model->default_values( $book );
        }

        return;
    }

=head1 SETUP

For the form object to be able to access your L<DBIx::Class> schema, it needs
to be placed on the form stash, with the name C<schema>.

This is easy if you're using L<Catalyst-Controller-HTML-FormFu>, as you can
set this up to happen in your Catalyst app's config file.

For example, if your model is named C<MyApp::Model::Corp>, you would set this
(in L<Config::General> format):

    <Controller::HTML::FormFu>
        <model_stash>
            schema Corp
        </model_stash>
    </Controller::HTML::FormFu>

Or if your app's config file is in L<YAML> format:

    'Controller::HTML::FormFu':
        model_stash:
            schema: Corp

=head1 METHODS

=head2 default_values

Arguments: $dbic_row, [\%config]

Return Value: $form

    $form->model->default_values( $dbic_row );

Set a form's default values from the database, to allow a user to edit them.

=head2 update

Arguments: [$dbic_row], [\%config]

Return Value: $dbic_row

    $form->model->update( $dbic_row );

Update the database with the submitted form values.

=head2 create

Arguments: [\%config]

Return Value: $dbic_row

    my $dbic_row = $form->model->create( {resultset => 'Book'} );

Like L</update>, but doesn't require a C<$dbic_row> argument.

You need to ensure the DBIC schema is available on the form stash - see
L</SYNOPSIS> for an example config.

The C<resultset> must be set either in the method arguments, or the form or
block's C<model_config>.

An example of setting the ResultSet name on a Form:

    ---
    model_config:
      resultset: FooTable

    elements:
      # [snip]

=head2 options_from_model

Populates a multi-valued field with values from the database.

This method should not be called directly, but is called for you during
C<< $form->process >> by fields that inherit from
L<HTML::FormFu::Element::_Group>. This includes:

=over

=item L<HTML::FormFu::Element::Select>

=item L<HTML::FormFu::Element::Checkboxgroup>

=item L<HTML::FormFu::Element::Radiogroup>

=item L<HTML::FormFu::Element::ComboBox>

=back

To use you must set the appropriate C<resultset> on the element C<model_config>:

    element:
      - type: Select
        name: foo
        model_config:
          resultset: TableClass

=head1 BUILDING FORMS

=head2 single table

To edit the values in a row with no related rows, the field names simply have
to correspond to the database column names.

For the following DBIx::Class schema:

    package MySchema::Book;
    use base 'DBIx::Class';

    __PACKAGE__->load_components(qw/ Core /);

    __PACKAGE__->table("book");

    __PACKAGE__->add_columns(
        id     => { data_type => "INTEGER" },
        title  => { data_type => "TEXT" },
        author => { data_type => "TEXT" },
        blurb  => { data_type => "TEXT" },
    );

    __PACKAGE__->set_primary_key("id");

    1;

A suitable form for this might be:

    elements:
      - type: Text
        name: title

      - type: Text
        name: author

      - type: Textarea
        name: blurb

=head2 might_have and has_one relationships

Set field values from a related row with a C<might_have> or C<has_one>
relationship by placing the fields within a
L<Block|HTML::FormFu::Element::Block> (or any element that inherits from
Block, such as L<Fieldset|HTML::FormFu::Element::Fieldset>) with its
L<HTML::FormFu/nested_name> set to the relationship name.

For the following DBIx::Class schemas:

    package MySchema::Book;
    use base 'DBIx::Class';

    __PACKAGE__->load_components(qw/ Core /);

    __PACKAGE__->table("book");

    __PACKAGE__->add_columns(
        id    => { data_type => "INTEGER" },
        title => { data_type => "TEXT" },
    );

    __PACKAGE__->set_primary_key("id");

    __PACKAGE__->might_have( review => 'MySchema::Review', 'book' );

    1;


    package MySchema::Review;
    use base 'DBIx::Class';

    __PACKAGE__->load_components(qw/ Core /);

    __PACKAGE__->table("review");

    __PACKAGE__->add_columns(
        id          => { data_type => "INTEGER" },
        book        => { data_type => "INTEGER", is_nullable => 1 },
        review_text => { data_type => "TEXT" },
    );

    __PACKAGE__->set_primary_key("book");

    __PACKAGE__->belongs_to( book => 'MySchema::Book' );

    1;

A suitable form for this would be:

    elements:
      - type: Text
        name: title

      - type: Block
        nested_name: review
        elements:
          - type: Textarea
            name: review_text

For C<might_have> and C<has_one> relationships, you generally shouldn't need
to have a field for the related table's primary key, as DBIx::Class will
handle retrieving the correct row automatically.

You can also set a C<has_one> or C<might_have> relationship using a multi value
field like L<Select|HTML::FormFu::Element::Select>.

    elements:
      - type: Text
        name: title

      - type: Select
        nested: review
        model_config:
          resultset: Review

This will load all reviews into the select field. If you select a review from
that list, a current relationship to a review is removed and the new one is
added. This requires that the primary key of the C<Review> table and the
foreign key do not match.

=head2 has_many and many_to_many relationships

The general principle is the same as for C<might_have> and C<has_one> above,
except you should use a L<Repeatable|HTML::FormFu::Element::Repeatable>
element instead of a Block, and it needs to contain a
L<Hidden|HTML::FormFu::Element::Hidden> field corresponding to the primary key
of the related table.

The Repeatable block's
L<nested_name|HTML::FormFu::Element::Repeatable/nested_name> must be set to the
name of the relationship.

The Repeable block's
L<increment_field_names|HTML::FormFu::Element::Repeatable/increment_field_names>
must be true (which is the default value).

The Repeable block's
L<counter_name|HTML::FormFu::Element::Repeatable/counter_name> must be set to
the name of a L<Hidden|HTML::FormFu::Element::Hidden> field, which is placed
outside of the Repeatable block.
This field is used to store a count of the number of repetitions of the
Repeatable block were created.
When the form is submitted, this value is used during C<< $form->process >>
to ensure the form is rebuilt with the correct number of repetitions.

To allow the user to add new related rows, either C<empty_rows> or
C<new_rows_max> must be set - see L</"Config options for Repeatable blocks">
below.

For the following DBIx::Class schemas:

    package MySchema::Book;
    use base 'DBIx::Class';

    __PACKAGE__->load_components(qw/ Core /);

    __PACKAGE__->table("book");

    __PACKAGE__->add_columns(
        id    => { data_type => "INTEGER" },
        title => { data_type => "TEXT" },
    );

    __PACKAGE__->set_primary_key("id");

    __PACKAGE__->has_many( review => 'MySchema::Review', 'book' );

    1;


    package MySchema::Review;
    use base 'DBIx::Class';

    __PACKAGE__->load_components(qw/ Core /);

    __PACKAGE__->table("review");

    __PACKAGE__->add_columns(
        book        => { data_type => "INTEGER" },
        review_text => { data_type => "TEXT" },
    );

    __PACKAGE__->set_primary_key("book");

    __PACKAGE__->belongs_to( book => 'MySchema::Book' );

    1;

A suitable form for this might be:

    elements:
      - type: Text
        name: title

      - type: Hidden
        name: review_count

      - type: Repeatable
        nested_name: review
        counter_name: review_count
        model_config:
          empty_rows: 1
        elements:
          - type: Hidden
            name: book

          - type: Textarea
            name: review_text

=head2 belongs_to relationships

Belongs-to relationships can be edited / created with a ComboBox element.
If the user selects a value with the Select field, the belongs-to will be set
to an already-existing row in the related table.
If the user enters a value into the Text field, the belongs-to will be set
using a newly-created row in the related table.

    elements:
      - type: ComboBox
        name: author
        model_config:
          resultset: Author
          select_column: id
          text_column: name

The element name should match the relationship name.
C<< $field->model_config->{select_column} >> should match the related primary
column.
C<< $field->model_config->{text_column} >> should match the related text
column.

=head2 many_to_many selection

To select / deselect rows from a C<many_to_many> relationship, you must use
a multi-valued element, such as a
L<Checkboxgroup|HTML::FormFu::Element::Checkboxgroup> or a
L<Select|HTML::FormFu::Element::Select> with
L<multiple|HTML::FormFu::Element::Select/multiple> set.

The field's L<name|HTML::FormFu::Element::_Field/name> must be set to the
name of the C<many_to_many> relationship.

=head3 default_column

If you want to search / associate the related table by a column other it's
primary key, set C<< $field->model_config->{default_column} >>.

    ---
    element:
        - type: Checkboxgroup
          name: authors
          model_config:
            default_column: foo

=head3 link_values

If you want to set columns on the link table you can do so if you add a
C<link_values> attribute to C<model_config>:

    ---
    element:
        - type: Checkboxgroup
          name: authors
          model_config:
            link_values:
              foo: bar

=head3 additive

The default implementation will first remove all related objects and set the
new ones (see L<http://search.cpan.org/perldoc?DBIx::Class::Relationship::Base#set_$rel>).
If you want to add the selected objects to the current set of objects
set C<additive> in the C<model_config>.

    ---
    element:
        - type: Checkboxgroup
          name: authors
          model_config:
            additive: 1
            options_from_model: 0

L</options_from_model> is set to C<0> because it will try to fetch
all objects from the result class C<Authors> if C<model_config> is specified
without a C<resultset> attribute.)

=head1 COMMON ARGUMENTS

The following items are supported in the optional C<config> hash-ref argument
to the methods L<default_values>, L<update> and L<create>.

=over

=item base

If you want the method to process a particular Block element, rather than the
whole form, you can pass the element as a C<base> argument.

    $form->default_values(
        $row,
        {
            base => $formfu_element,
        },
    );

=item nested_base

If you want the method to process a particular Block element by
L<name|HTML::FormFu::Element/name>, you can pass the name as an argument.

    $form->default_values(
        $row,
        {
            nested_base => 'foo',
        }'
    );

=back

=head1 CONFIGURATION

=head2 Config options for fields

The following items are supported as C<model_config> options on form fields.

=over

=item accessor

If set, C<accessor> will be used as a method-name accessor on the
C<DBIx::Class> row object, instead of using the field name.

=item ignore_if_empty

If the submitted value is blank, no attempt will be made to save it to the database.

=item null_if_empty

If the submitted value is blank, save it as NULL to the database. Normally an empty string is saved as NULL when its corresponding field is numeric, and as an empty string when its corresponding field is a text field. This option is useful for changing the default behavior for text fields.

=item delete_if_empty

Useful for editing a "might_have" related row containing only one field.

If the submitted value is blank, the related row is deleted.

For the following DBIx::Class schemas:

    package MySchema::Book;
    use base 'DBIx::Class';

    __PACKAGE__->load_components(qw/ Core /);

    __PACKAGE__->table("book");

    __PACKAGE__->add_columns(
        id    => { data_type => "INTEGER" },
        title => { data_type => "TEXT" },
    );

    __PACKAGE__->set_primary_key("id");

    __PACKAGE__->might_have( review => 'MySchema::Review', 'book' );

    1;


    package MySchema::Review;
    use base 'DBIx::Class';

    __PACKAGE__->load_components(qw/ Core /);

    __PACKAGE__->table("review");

    __PACKAGE__->add_columns(
        book        => { data_type => "INTEGER" },
        review_text => { data_type => "TEXT" },
    );

    __PACKAGE__->set_primary_key("book");

    __PACKAGE__->belongs_to( book => 'MySchema::Book' );

    1;

A suitable form for this would be:

    elements:
      - type: Text
        name: title

      - type: Block
        nested_name: review
        elements:
          - type: Text
            name: review_text
            model_config:
              delete_if_empty: 1

=item label

To use a column value for a form field's
L<label|HTML::FormFu::Element::_Field/label>.

=back

=head2 Config options for fields within a Repeatable block

=over

=item delete_if_true

Intended for use on a L<Checkbox|HTML::FormFu::Element::Checkbox> field.

If the checkbox is checked, the following occurs: for a has-many relationship,
the related row is deleted; for a many-to-many relationship, the relationship
link is removed.

An example of use might be:

    elements:
      - type: Text
        name: title

      - type: Hidden
        name: review_count

      - type: Repeatable
        nested_name: review
        counter_name: review_count
        elements:
          - type: Hidden
            name: book

          - type: Textarea
            name: review_text

          - type: Checkbox
            name: delete_review
            label: 'Delete Review?'
            model_config:
              delete_if_true: 1

Note: make sure the name of this field does not clash with one of your
L<DBIx::Class::Row> method names (e.g. "delete") - see L</CAVEATS>.

=back

=head2 Config options for Repeatable blocks

=over

=item empty_rows

For a Repeatable block corresponding to a has-many or many-to-many
relationship, to allow the user to insert new rows, set C<empty_rows> to
the number of extra repetitions you wish added to the end of the Repeatable
block.

=item new_rows_max

Set to the maximum number of new rows that a Repeatable block is allowed to
add.

If not set, it will fallback to the value of C<empty_rows>.

=back

=head2 Config options for options_from_model

The column used for the element values is set with the C<model_config>
value C<id_column> - or if not set, the table's primary column is used.

    element:
      - type: Select
        name: foo
        model_config:
          resultset: TableClass
          id_column: pk_col

The column used for the element labels is set with the C<model_config>
value C<label_column> - or if not set, the first text/varchar column found
in the table is used - or if one is not found, the C<id_column> is used
instead.

    element:
      - type: Select
        name: foo
        model_config:
          resultset: TableClass
          label_column: label_col

To pass the database label values via the form's localization object, set
C<localize_label>

    element:
      - type: Select
        name: foo
        model_config:
          localize_label: 1

You can set a C<condition>, which will be passed as the 1st argument to
L<DBIx::Class::ResultSet/search>.

    element:
      - type: Select
        name: foo
        model_config:
          resultset: TableClass
          condition:
            type: is_foo

You can set a C<condition_from_stash>, which will be passed as the 1st argument to
L<DBIx::Class::ResultSet/search>.

C<key> is the column-name to be passed to
L<search|DBIx::Class::ResultSet/search>,
and C<stash_key> is the name of a key on the form L<stash|HTML::FormFu/stash>
from which the value to be passed to L<search|DBIx::Class::ResultSet/search>
is found.

    element:
      - type: Select
        name: foo
        model_config:
          resultset: TableClass
          condition_from_stash:
            key: stash_key

Is comparable to:

    $form->element({
        type => 'Select',
        name => 'foo',
        model_config => {
            resultset => 'TableClass',
            condition => {
                key => $form->stash->{stash_key}
            }
        }
    })

If the value in the stash is nested in a data-structure, you can access it by
setting C<expand_stash_dots>. As you can see in the example below, it
automatically handles calling methods on objects, accessing hash-keys on
hash-references, and accessing array-slots on array references.

    element:
      - type: Select
        name: foo
        model_config:
          resultset: TableClass
          condition_from_stash:
            key: foo.bar.0
          expand_stash_dots: 1

Is comparable to:

    $form->element({
        type => 'Select',
        name => 'foo',
        model_config => {
            resultset => 'TableClass',
            condition => {
                key => $form->stash->{foo}->bar->[0];
            }
        }
    })
    # Where stash returns a hashref.
    # The 'foo' hash-key returns an object.
    # The object-method 'bar' returns an arrayref.
    # The first array slot returns the value used in the query.

You can set C<attributes>, which will be passed as the 2nd argument to
L<DBIx::Class::ResultSet/search>.

=head3 ENUM Column Type

If the field name matches (case-insensitive) a column name with type 'ENUM'
and the Schema contains enum values in
C<< $resultset->column_info($name)->{extra}{list} >>, the field's options
will be populated with the enum values.

=head1 FAQ

=head2 Add extra values not in the form

To update values to the database which weren't submitted to the form,
you can first add them to the form with L<add_valid|HTML::FormFu/add_valid>.

    my $passwd = generate_passwd();

    $form->add_valid( passwd => $passwd );

    $form->model->update( $row );

C<add_valid> works for fieldnames that don't exist in the form.

=head2 Set a field read only

You can make a field read only. The value of such fields cannot be changed by
the user even if they submit a value for it.

  $field->model_config->{read_only} = 1;

  - Name: field
    model_config:
      read_only: 1

See L<HTML::FormFu::Element::Label>.

=head1 CAVEATS

To ensure your column's inflators and deflators are called, we have to
get / set values using their named methods, and not with C<get_column> /
C<set_column>.

Because of this, beware of having column names which clash with DBIx::Class
built-in method-names, such as C<delete>. - It will have obviously
undesirable results!

=head1 REMOVED METHODS

=head2 new_empty_row

See C<empty_rows> in L</"Config options for Repeatable blocks"> instead.

=head2 new_empty_row_multi

See C<new_rows_max> in L</"Config options for Repeatable blocks"> instead.

=head2 Range constraint

See C<empty_rows> in L</"Config options for Repeatable blocks"> instead.

=head1 SUPPORT

Project Page:

L<http://code.google.com/p/html-formfu/>

Mailing list:

L<http://lists.scsys.co.uk/cgi-bin/mailman/listinfo/html-formfu>

Mailing list archives:

L<http://lists.scsys.co.uk/pipermail/html-formfu/>

=head1 BUGS

Please submit bugs / feature requests to
L<http://code.google.com/p/html-formfu/issues/list> (preferred) or
L<http://rt.perl.org>.

=head1 GITHUB REPOSITORY

This module's sourcecode is maintained in a git repository at
L<git://github.com/fireartist/HTML-FormFu-Model-DBIC.git>

The project page is L<https://github.com/fireartist/HTML-FormFu-Model-DBIC>

=head1 SEE ALSO

L<HTML::FormFu>, L<DBIx::Class>, L<Catalyst::Controller::HTML::FormFu>

=head1 AUTHOR

Carl Franks

=head1 CONTRIBUTORS

Based on the code of C<DBIx::Class::HTML::FormFu>, which was contributed to
by:

Adam Herzog

Daisuke Maki

Mario Minati

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Carl Franks

Based on the original source code of L<DBIx::Class::HTMLWidget>, copyright
Thomas Klausner.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
