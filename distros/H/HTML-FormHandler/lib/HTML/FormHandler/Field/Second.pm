package HTML::FormHandler::Field::Second;
# ABSTRACT: select list 0 to 59
$HTML::FormHandler::Field::Second::VERSION = '0.40068';
use Moose;
extends 'HTML::FormHandler::Field::IntRange';

has '+range_start' => ( default => 0 );
has '+range_end'   => ( default => 59 );


__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Field::Second - select list 0 to 59

=head1 VERSION

version 0.40068

=head1 DESCRIPTION

A select field for seconds in the range of 0 to 59.

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
