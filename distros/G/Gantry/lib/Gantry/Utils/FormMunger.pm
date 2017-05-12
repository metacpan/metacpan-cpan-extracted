package Gantry::Utils::FormMunger;
use strict; use warnings;

sub new {
    my $class = shift;
    my $form  = shift || { fields => [] };

    my $self  = { form => $form };
    bless $self, $class;

    $self->{ sync } = $self->_sync();

    return $self;
} # END of new

sub _sync {
    my $self  = shift;

    my %sync;
    my $count = 0;

    foreach my $field ( @{ $self->{ form }{ fields } } ) {
        $sync{ $field->{ name } } = { field => $field, order => $count++ };
    }

    return \%sync;
}

sub clear_props {
    my $self       = shift;
    my $field_name = shift;

    my $field      = $self->{ sync }{ $field_name }{ field };

    DOOMED_PROP:
    foreach my $doomed_prop ( @_ ) {
        if ( $doomed_prop eq 'name' ) {
            warn "cowardly refusing to delete field name\n";
            next DOOMED_PROP;
        }
        delete $field->{ $doomed_prop };
    }
} # END of clear_props

sub clear_all_props {
    my $self       = shift;
    my $field_name = shift;

    my $index      = $self->{ sync }{ $field_name }{ order };
    my $field      = $self->{ form }{ fields }[ $index ];

    PROP:
    foreach my $key ( keys %{ $field } ) {
        next PROP if $key eq 'name';
        delete $field->{ $key };
    }

} # END of clear_all_props

sub set_props {
    my $self      = shift;
    my $name      = shift;
    my $new_props = shift;
    my $replace   = shift;

    my $resync    = 0;

    my $field     = $self->{ sync }{ $name }{ field };
    my $old_name  = $field->{ name };

    if ( $replace ) {
        foreach my $key ( keys %{ $field } ) {
            delete $field->{ $key };
        }
        $resync = 1;
    }

    foreach my $new_prop ( keys %{ $new_props } ) {
        $field->{ $new_prop } = $new_props->{ $new_prop };
        $resync = 1 if $new_prop eq 'name';
    }

    $field->{ name } = $old_name unless $field->{ name };

    $self->_sync if $resync;

} # END of set_props

sub set_props_for_fields {
    my $self        = shift;
    my $field_names = shift;
    my $new_props   = shift;

    foreach my $field_name ( @{ $field_names } ) {
        my $field = $self->{ sync }{ $field_name }{ field };

        foreach my $new_prop ( keys %{ $new_props } ) {
            $field->{ $new_prop } = $new_props->{ $new_prop };
        }
    }
} # END of set_props_for

sub set_props_except_for {
    my $self       = shift;
    my $skip_names = shift;
    my $new_props  = shift;

    my %skip       = map { $_ => 1 } @{ $skip_names };

    FIELD:
    foreach my $field ( @{ $self->{ form }{ fields } } ) {
        next FIELD if $skip{ $field->{ name } };

        foreach my $new_prop ( keys %{ $new_props } ) {
            $field->{ $new_prop } = $new_props->{ $new_prop };
        }
    }
} # END of set_props_except_for

sub set_props_all {
    my $self      = shift;
    my $new_props = shift;

    foreach my $field ( @{ $self->{ form }{ fields } } ) {
        foreach my $new_prop ( keys %{ $new_props } ) {
            $field->{ $new_prop } = $new_props->{ $new_prop };
        }
    }
} # END of set_props_all

sub get_field {
    my $self           = shift;
    my $requested_name = shift;

    return $self->{ sync }{ $requested_name }{ field };
} # END of get_field

sub drop_field {
    my $self        = shift;
    my $doomed_name = shift;
    my $splice_pos  = $self->{ sync }{ $doomed_name }{ order };
    my $doomed;

    if ( defined $splice_pos ) {
        $doomed = splice @{ $self->{ form }{ fields } }, $splice_pos, 1;
        $self->{ sync } = $self->_sync();
    }
    else {
        die "Invalid form field specified.";
    }

    return $doomed;
} # END of drop_field

sub append_field {
    my $self  = shift;
    my $field = shift;

    push @{ $self->{ form }{ fields } }, $field;

    $self->{ sync } = $self->_sync();
} # END of append_field

sub unshift_field {
    my $self  = shift;
    my $field = shift;

    unshift @{ $self->{ form }{ fields } }, $field;

    $self->{ sync } = $self->_sync();
} # END of unshift_field

sub add_field_after {
    my $self        = shift;
    my $target_name = shift;
    my $field       = shift;
    my $splice_pos  = $self->{ sync }{ $target_name }{ order };

    if ( defined $splice_pos ) {
        $splice_pos += 1;
        splice  @{ $self->{ form }{ fields } }, $splice_pos, 0, $field;
        $self->{ sync } = $self->_sync();
    }
    else {
        die "Invalid form field specified.";
    }
} # END of add_field_after

sub add_field_before {
    my $self        = shift;
    my $target_name = shift;
    my $field       = shift;
    my $splice_pos  = $self->{ sync }{ $target_name }{ order };

    if ( defined $splice_pos ) {
        splice  @{ $self->{ form }{ fields } }, $splice_pos, 0, $field;
        $self->{ sync } = $self->_sync();
    }
    else {
        die "Invalid form field specified.";
    }
} # END of add_field_before

1;

=head1 NAME

Gantry::Utils::FormMunger - Munges form hashes like the ones bigtop makes.

=head1 SYNOPSIS

    use Gantry::Utils::FormMunger;

    my $form = ...; # make a form hash

    my $munger = Gantry::Utils::FormMunger->new( $form );

    # change properties of existing fields:
    $munger->clear_props( 'field_name', qw( name keys to delete) );

    $munger->clear_all_props( 'field_name' );
    # removes all keys except name

    $munger->set_props(
        'field_name',
        { prop => 'value', ... },
        $replace_props
    ); # modifies only the keys you pass

    $munger->set_props_for_fields(
        [ 'field1', 'field2', ... ],
        { prop => 'value', ... },
    ); # like set_props but for all listed fields

    $munger->set_props_except_for(
        [ 'skip_this_one', 'and_this_one' ],
        { prop => 'value', ... },
    ); # like set_props_for, but negated listed fields are skipped

    $munger->set_props_all( { prop => 'value', ... } );

    # get the field so you can work it yourself:
    my $field = $munger->get_field( 'name' );

    # modify the field list:
    my $deceased = $munger->drop_field( 'name' ); # removes it from the form

    $munger->append_field(  { name => 'name', ... } ); # add at end
    $munger->unshift_field( { name => 'name', ... } ); # add at beginning

    $munger->add_field_after(  'target', { name => 'name', ... } );
    $munger->add_field_before( 'target', { name => 'name', ... } );

=head1 DESCRIPTION

This module is designed to simplify work with Gantry form.tt form hash
data structures.  If makes modifications to the fields array in that
hash.  Usually, bigtop generates that hash.  If you are in a standard
CRUD situation, the generated form is all you need.  But, if you need
to share the form in different contexts, it may be necessary to modify
it to suit those contexts.  That is what this module does.

If you want, you could even use this module to build your entire form
hash, but that might be painful.  Instead, you usually pass a form hash
to its constructor.  Usually, you get that hash from a GEN module's form
method which was generated by bigtop.

Once you have the object, you can call any of the methods below to
modify its fields array.  Most of the methods return nothing useful.
The exceptions are noted below.

All methods are instance methods unless marked.

=head1 METHODs

=over 4

=item new (class method)

Parameters: a form hash.  If you don't already have one try:

    my $munger = Gantry::Utils::FormMunger->new( { fields => [] } );

It is better to use one that already has fields.

Returns: a munger object upon which you may call the rest of the methods.

=item clear_props

Selectively removes specified properties from one field.  This is
done by using delete on the fields subhash.

Parameters: name of field to work on, list of properties to remove from its
fields hash

=item clear_all_props

Given the name of a field, this method deletes all of its properties except
its name.

Parameters: name of field

=item set_props

Given a field name, and a list of properties, sets those properties on that
field.

Parameters:

=over 4

=item field_name

name of field to work on

=item props

hash reference of properties to assign on the field

=item replace

Flag.  If true, all keys are deleted prior to application of props.
Note that you must supply a name property, or the field will have no
name and everyone Will Be Upset.

=back

=item set_props_for_fields

Like C<set_props>, but works for several named fields at once.  This
is more efficient than separate calls, since the fields array is
only traversed once.

Do not change field names with this method.  Use C<set_props> for that.
Trying to use this method will leave all fields involved with the
same name, confusing everyone including this module.

Parameters:

=over 4

=item fields

Array reference, listing fields to work on.

=item props

Hash reference of properties to assign on each field.

=back

=item set_props_except_for

Like C<set_props_for>, but you list fields to skip, instead of fields to
work on.  Every field not mentioned is affected.  The parameters
are the same as for C<set_props_for>.

Note that it is extremely unwise to consider changing field names with this
method, since that would make the field names of all fields modified
the same.

=item set_props_all

Like C<set_props_for>, but it works on all fields.

Note that it is extremely unwise to consider changing field names with this
method, since that would make all field names the same.

Parameters:

=over 4

=item props

Hash reference of properties to assign on each field.

=back

=item get_field

Returns the subhash for a given field.

Parameters: name of field to return

Returns: subhash for the named field (if there is one)

=item drop_field

Deletes a field from the fields array.

Parameters: name of doomed field

Returns: the hash reference for the dearly departed.

=item append_field

Adds a new field at the end of the fields array (so it will appear last
on the form).

Parameters: a hash reference for a new field

=item unshift_field

Just like C<append_field>, except the new field becomes the first field.

=item add_field_after

Adds a new field to the fields array immediately after a named field.
If the named field is not found, the new field goes at the end.

Parameters:

=over 4

=item target

Name of field immediately before new field.

=item props

Hash reference of props for new field.

=back

=item add_field_before

Just like C<add_field_after>, except that the new field goes immediately
before the named field.  (If the name is not found, the new field still
goes at the end.)

=back

=head1 AUTHOR

Phil Crow, E<lt>crow.phil@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

