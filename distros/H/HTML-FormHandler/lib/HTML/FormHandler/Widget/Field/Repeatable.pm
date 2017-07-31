package HTML::FormHandler::Widget::Field::Repeatable;
# ABSTRACT: repeatable field widget
$HTML::FormHandler::Widget::Field::Repeatable::VERSION = '0.40068';
use Moose::Role;
with 'HTML::FormHandler::Widget::Field::Compound';


has 'wrap_repeatable_element_method' => (
     traits => ['Code'],
     is     => 'ro',
     isa    => 'CodeRef',
     handles => { 'wrap_repeatable_element' => 'execute_method' },
);

sub render_subfield {
    my ( $self, $result, $subfield ) = @_;

    my $subresult = $result->field( $subfield->name );

    return "" unless $subresult
        or ( $self->has_flag( "is_repeatable")
            and $subfield->name < $self->num_when_empty
        );

    my $output = $subfield->render($subresult);
    if ( $self->wrap_repeatable_element_method ) {
        $output = $self->wrap_repeatable_element($output, $subfield->name);
    }
    return $output;
}

use namespace::autoclean;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Widget::Field::Repeatable - repeatable field widget

=head1 VERSION

version 0.40068

=head1 SYNOPSIS

Renders a repeatable field

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
