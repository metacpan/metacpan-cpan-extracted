package HTML::FormHandler::Field::Month;
# ABSTRACT: select list 1 to 12
$HTML::FormHandler::Field::Month::VERSION = '0.40068';
use Moose;
extends 'HTML::FormHandler::Field::IntRange';

has '+range_start' => ( default => 1 );
has '+range_end'   => ( default => 12 );


__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Field::Month - select list 1 to 12

=head1 VERSION

version 0.40068

=head1 DESCRIPTION

Select list for range of 1 to 12. Widget type is 'select'

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
