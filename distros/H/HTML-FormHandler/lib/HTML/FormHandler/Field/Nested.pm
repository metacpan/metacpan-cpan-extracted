package HTML::FormHandler::Field::Nested;
# ABSTRACT: for nested elements of compound fields
$HTML::FormHandler::Field::Nested::VERSION = '0.40068';
use Moose;
extends 'HTML::FormHandler::Field::Text';




__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Field::Nested - for nested elements of compound fields

=head1 VERSION

version 0.40068

=head1 SYNOPSIS

This field class is intended for nested elements of compound fields. It
does no particular validation, since the compound field should handle
that.

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
