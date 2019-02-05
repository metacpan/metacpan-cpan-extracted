package HTML::Restrict::Types;
our $VERSION = 'v2.4.1';
use strict;
use warnings;

use Type::Library -base;
use Type::Utils ();

BEGIN {
    Type::Utils::extends( 'Types::Common::Numeric', 'Types::Standard', );
}

__PACKAGE__->add_type(
    {
        name       => 'MaxParserLoops',
        parent     => PositiveInt,
        constraint => '$_ >= 2',
    }
);

1;

=pod

=encoding UTF-8

=head1 NAME

HTML::Restrict::Types - Type library for HTML::Restrict

=head1 VERSION

version v2.4.1

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013-2017 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Type library for HTML::Restrict
