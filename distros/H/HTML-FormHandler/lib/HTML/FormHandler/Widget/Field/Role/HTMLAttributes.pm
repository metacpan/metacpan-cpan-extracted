package HTML::FormHandler::Widget::Field::Role::HTMLAttributes;
# ABSTRACT: apply HTML attributes
$HTML::FormHandler::Widget::Field::Role::HTMLAttributes::VERSION = '0.40068';

use Moose::Role;
use HTML::FormHandler::Render::Util ('process_attrs');

sub _add_html_attributes {
    my $self = shift;
    my $output = process_attrs( $self->attributes );
    return $output;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Widget::Field::Role::HTMLAttributes - apply HTML attributes

=head1 VERSION

version 0.40068

=head1 SYNOPSIS

Deprecated. Only here for interim compatibility, to provide
'_add_html_attributes' method. Will be removed in the future.

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
