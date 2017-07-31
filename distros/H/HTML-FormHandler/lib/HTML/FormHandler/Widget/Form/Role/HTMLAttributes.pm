package HTML::FormHandler::Widget::Form::Role::HTMLAttributes;
# ABSTRACT: set HTML attributes on the form tag
$HTML::FormHandler::Widget::Form::Role::HTMLAttributes::VERSION = '0.40068';
use Moose::Role;

sub html_form_tag {
    my $self = shift;

    my @attr_accessors = (
        [ action  => 'action' ],
        [ id      => 'name' ],
        [ method  => 'http_method' ],
        [ enctype => 'enctype' ],
        [ style   => 'style' ],
    );

    # make the element_attr a safe default
    my $element_attr = {};
    # Assuming that self is a form
    $element_attr = { %{$self->form_element_attr} } if ( $self->can( 'form_element_attr' ) );
    # Assuming that self is a field
    $element_attr = { %{$self->element_attr} } if ( $self->can( 'element_attr' ) );

    foreach my $attr_pair (@attr_accessors) {
        my $attr = $attr_pair->[0];
        my $accessor = $attr_pair->[1];
        if ( !exists $element_attr->{$attr} && defined( my $value = $self->$accessor ) ) {
            $element_attr->{$attr} = $self->$accessor;
        }
    }

    my $output = '<form';
    foreach my $attr ( sort keys %$element_attr ) {
        $output .= qq{ $attr="} . $element_attr->{$attr} . qq{"};
    }

    $output .= " >\n";
    return $output;
}

no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Widget::Form::Role::HTMLAttributes - set HTML attributes on the form tag

=head1 VERSION

version 0.40068

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
