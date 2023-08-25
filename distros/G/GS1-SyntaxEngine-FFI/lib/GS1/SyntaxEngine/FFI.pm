# SPDX-License-Identifier: GPL-1.0-or-later OR Artistic-1.0-Perl

package GS1::SyntaxEngine::FFI;
$GS1::SyntaxEngine::FFI::VERSION = '0.2';
# ABSTRACT: Provides a FFI wrapper for libgs1encoders

use utf8;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

GS1::SyntaxEngine::FFI - Provides a FFI wrapper for libgs1encoders

=head1 VERSION

version 0.2

=head1 SYNOPSIS

  use GS1::SyntaxEngine::FFI::GS1Encoder;
  my $encoder = GS1::SyntaxEngine::FFI::GS1Encoder->new();

  # Set tha data string to a GS1 DataMatrix barcode
  # The original FNC1 char needs to be replaced by ^
  $encoder->data_str('^01070356200521631523080710230710');

  print $encoder->ai_data_str();
  # will print (01)07035620052163(15)230807(10)230711

=head1 AUTHOR

hangy

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by hangy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
