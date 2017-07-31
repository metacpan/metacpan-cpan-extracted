package HTML::FormHandler::Field::Button;
# ABSTRACT: button field
$HTML::FormHandler::Field::Button::VERSION = '0.40068';
use Moose;
extends 'HTML::FormHandler::Field::NoValue';


has '+widget' => ( default => 'Button' );

has '+value' => ( default => 'Button' );

__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Field::Button - button field

=head1 VERSION

version 0.40068

=head1 SYNOPSIS

Use this field to declare a button field in your form.

   has_field 'button' => ( type => 'Button', value => 'Press Me!' );

Uses the 'button' widget.

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
