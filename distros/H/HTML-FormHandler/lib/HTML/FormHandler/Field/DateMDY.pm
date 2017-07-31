package HTML::FormHandler::Field::DateMDY;
# ABSTRACT: m/d/y date field
$HTML::FormHandler::Field::DateMDY::VERSION = '0.40068';
use HTML::FormHandler::Moose;
extends 'HTML::FormHandler::Field::Date';

has '+format' => ( default => '%m/%d/%Y' );


__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Field::DateMDY - m/d/y date field

=head1 VERSION

version 0.40068

=head1 SYNOPSIS

For date fields in the format nn/nn/nnnn. This simply inherits
from L<HTML::FormHandler::Field::Date> and sets the format
to "%m/%d/%Y".

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
