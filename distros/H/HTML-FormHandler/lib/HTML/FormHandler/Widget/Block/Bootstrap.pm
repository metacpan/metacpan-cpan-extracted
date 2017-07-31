package HTML::FormHandler::Widget::Block::Bootstrap;
# ABSTRACT: block to format bare form element like bootstrap
$HTML::FormHandler::Widget::Block::Bootstrap::VERSION = '0.40068';
use Moose;
extends 'HTML::FormHandler::Widget::Block';

has 'after_controls' => ( is => 'rw' );

sub BUILD {
    my $self = shift;
    $self->add_class('control-group');
    $self->add_label_class('control-label');
    $self->label_tag('label');
}

sub render_from_list {
    my ( $self, $result ) = @_;
    $result ||= $self->form->result;
    my $output = $self->next::method($result);
    my $after_controls = $self->after_controls || '';
    return qq{<div class="controls">\n$output\n$after_controls\n</div>\n};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Widget::Block::Bootstrap - block to format bare form element like bootstrap

=head1 VERSION

version 0.40068

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
