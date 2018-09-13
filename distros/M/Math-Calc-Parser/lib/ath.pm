package ath;
use strict;
use warnings;
use Math::Calc::Parser;
use Encode ();
our $VERSION = '1.002';
use Filter::Simple sub {
	my $expr = quotemeta Encode::decode 'UTF-8', "$_", Encode::FB_CROAK | Encode::LEAVE_SRC;
	$_ = 'use utf8; print Math::Calc::Parser::calc "' . $expr . '", "\n";'
};
1;

=encoding utf8

=head1 NAME

ath - Evaluate mathematical expressions in a compact one-liner

=head1 SYNOPSIS

  $ perl -Math -e'2+2'
  $ perl -Math -e'5!'
  $ perl -Math -e'round e^(i*pi)'
  $ perl -Math -e'log 5rand'
  $ perl -Math -e'2π'

=head1 DESCRIPTION

A source filter that parses and evaluates the source code as a mathematical
expression using L<Math::Calc::Parser>, and prints the result.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Math::Calc::Parser>
