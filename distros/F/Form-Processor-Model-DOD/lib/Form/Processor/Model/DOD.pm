package Form::Processor::Model::DOD;

use strict;
use warnings;
use base 'Form::Processor';

=head1 NAME

Form::Processor::Model::DOD - Model Class for Form::Processor based on Data::ObjectDriver

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    ## define a form class to use with DOD items
    package MyApplication::Form::User;
    use strict;
    use base 'Form::Processor::Model::DOD';

    # Associate this form with a L<Data::ObjectDriver::BaseObject> class
    sub object_class { 'MyApplication::Model::User' }

    sub profile {
    ...
    }
    1;

=head1 DESCRIPTION

This is a Form::Processor::Model add-on module. This module is for use with
L<Data::ObjectDriver> based objects. By declaring a C<object_class> method
in the Form class, a form is tied to the data in the database (typically
a row in one table).

The form object can be prefilled with the data from the object in database,
and similarily on C<update_from_form()> the object can be inserted or updated
in the database (If validation passes). 

=head1 METHODS

=head2 object_class

(pod from cdbi model)
This method is typically overridden in your form class and relates the form
to a specific Class::DBI table class.  This is the mapping between the form and
the columns in the table the form operates on.

The module uses this information to lookup options in related tables for both
select and multiple select (many-to-many) relationships.

If not defined will attempt to use the class of $form->item, if set.

Typically, this method is overridden as shown above, and is all you need to do to
use this module.  This can also be a parameter when creating a form instance.

=head2 init_item

By default, just lookup the item_id associated with that model in the database.

=cut

sub init_item {
    my $model = shift;
    my $item_id = $model->item_id or return;
    return $model->object_class->lookup( $item_id );
}

# use column_defs here XXX
# sub guess_field_type { }

=head2 update_from_form

(some parts of this pod section come from cdbi)

    my $ok = $form->update_from_form( $parameter_hash );
    my $ok = $form->update_from_form( $c->request->parameters ); # catalyst for instance

Update or create the object from values in the form.

Validation is run unless validation has already been
run.  ($form->clear might need to be called if the $form object stays in memory
between requests.)

Pass in hash reference of parameters.

Returns false if form does not validate.  Very likely dies on database errors.

=cut

sub update_from_form {
   my($model, $params) = @_;

    return unless $model->validate($params);

    # Grab either the item or the object class.
    my $item = $model->item;
    my $class = ref( $item ) || $model->object_class;

    # get a hash of all fields
    my %fields = map { $_->name, $_ } grep { !$_->noupdate } $model->fields;

    my %data;
    foreach my $col (@{ $class->column_names }) {
        next unless exists $fields{$col};
        my $field = delete $fields{$col};

        # If the field is flagged "clear" then set to NULL.
        my $value = $field->clear ? undef : $field->value;

        if ($item) {
            $item->$col( $value );
        } else {
            $data{$col} = $value;
        }
    }

    if ($item) {
        $item->update;
        $model->updated_or_created('updated');
    } else {
        $item = $class->new;
        $item->set_values(\%data);
        $item->insert;
        $model->item($item);
        $model->updated_or_created('created');
    }

    $model->reset_params;  # force reload of parameters from values

    return $item;
}

=head1 SEE ALSO

L<Form::Processor>, L<Form::Processor::Model::CDBI>, L<Data::ObjectDriver>

=head1 AUTHOR

Yann Kerherve, C<< <yann.kerherve at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-form-processor-model-dod at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Form-Processor-Model-DOD>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENT

This module is based on the work of Bill Moseley.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Form::Processor::Model::DOD

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Form-Processor-Model-DOD>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Form-Processor-Model-DOD>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Form-Processor-Model-DOD>

=item * Search CPAN

L<http://search.cpan.org/dist/Form-Processor-Model-DOD>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007 Yann Kerherve, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

"Oh neat, hot swap!";
