package HTML::FormHandler::Field::Hidden;
# ABSTRACT: hidden field
$HTML::FormHandler::Field::Hidden::VERSION = '0.40068';
use Moose;
extends 'HTML::FormHandler::Field::Text';

has '+widget' => ( default => 'Hidden' );
has '+do_label' => ( default => 0 );
has '+html5_type_attr' => ( default => 'hidden' );


__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Field::Hidden - hidden field

=head1 VERSION

version 0.40068

=head1 DESCRIPTION

This is a text field that uses the 'hidden' widget type, for HTML
of type 'hidden'.

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
