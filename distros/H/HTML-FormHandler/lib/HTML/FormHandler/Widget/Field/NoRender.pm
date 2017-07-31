package HTML::FormHandler::Widget::Field::NoRender;
# ABSTRACT: no rendering widget
$HTML::FormHandler::Widget::Field::NoRender::VERSION = '0.40068';
use Moose::Role;


sub render { '' }

use namespace::autoclean;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Widget::Field::NoRender - no rendering widget

=head1 VERSION

version 0.40068

=head1 SYNOPSIS

Renders a field as the empty string.

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
