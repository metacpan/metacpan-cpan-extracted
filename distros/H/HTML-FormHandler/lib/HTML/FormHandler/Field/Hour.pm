package HTML::FormHandler::Field::Hour;
# ABSTRACT: accept integer from 0 to 23
$HTML::FormHandler::Field::Hour::VERSION = '0.40068';
use Moose;
extends 'HTML::FormHandler::Field::IntRange';

has '+range_start' => ( default => 0 );
has '+range_end'   => ( default => 23 );


__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Field::Hour - accept integer from 0 to 23

=head1 VERSION

version 0.40068

=head1 DESCRIPTION

Enter an integer from 0 to 23 hours.

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
