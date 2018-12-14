use strict;

package HTML::FormFu::Constants;
# ABSTRACT: FormFU constants EMPTY_STR and SPACE
$HTML::FormFu::Constants::VERSION = '2.07';
use warnings;

use Readonly;
use Exporter qw( import );

Readonly our $EMPTY_STR => q{};
Readonly our $SPACE     => q{ };

our @EXPORT_OK = qw(
    $EMPTY_STR
    $SPACE
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormFu::Constants - FormFU constants EMPTY_STR and SPACE

=head1 VERSION

version 2.07

=head1 AUTHOR

Carl Franks <cpan@fireartist.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Carl Franks.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
