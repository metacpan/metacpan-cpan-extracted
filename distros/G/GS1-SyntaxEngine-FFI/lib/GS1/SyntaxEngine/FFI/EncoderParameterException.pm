# SPDX-License-Identifier: GPL-1.0-or-later OR Artistic-1.0-Perl

# ABSTRACT: Error in case that libgs1encoders couldn't be initialized

package GS1::SyntaxEngine::FFI::EncoderParameterException;
$GS1::SyntaxEngine::FFI::EncoderParameterException::VERSION = '0.3';
use utf8;

use Moose;
with 'Throwable';

has message => ( is => 'ro' );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

GS1::SyntaxEngine::FFI::EncoderParameterException - Error in case that libgs1encoders couldn't be initialized

=head1 VERSION

version 0.3

=head1 AUTHOR

hangy

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by hangy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
