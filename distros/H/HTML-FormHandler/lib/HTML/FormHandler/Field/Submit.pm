package HTML::FormHandler::Field::Submit;
# ABSTRACT: submit field
$HTML::FormHandler::Field::Submit::VERSION = '0.40068';
use Moose;
extends 'HTML::FormHandler::Field::NoValue';


has '+value'  => ( default => 'Save' );
has '+widget' => ( default => 'Submit' );
has '+type_attr' => ( default => 'submit' );
has '+html5_type_attr' => ( default => 'submit' );
sub do_label {0}

sub _result_from_input {
    my ( $self, $result, $input, $exists ) = @_;
    $self->_set_result($result);
    $result->_set_input($input);
    $result->_set_field_def($self);
    return $result;
}

__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Field::Submit - submit field

=head1 VERSION

version 0.40068

=head1 SYNOPSIS

Use this field to declare a submit field in your form.

   has_field 'submit' => ( type => 'Submit', value => 'Save' );

It will be used by L<HTML::FormHandler::Render::Simple> to construct
a form with C<< $form->render >>.

Uses the 'submit' widget.

If you have multiple submit buttons, currently the only way to test
which one has been clicked is with C<< $field->input >>. The 'value'
attribute is used for the HTML input field 'value'.

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
