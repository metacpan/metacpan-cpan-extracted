package EBook::Ishmael::ShellQuote;
use 5.016;
our $VERSION = '1.09';
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(shell_quote);

sub shell_quote {

    my ($str) = @_;

    $str =~ s/([\$`"\\\n])/\\$1/g;

    return qq{"$str"};

}

1;

=head1 NAME

EBook::Ishmael::ShellQuote - Quote strings to be used in shell commands

=head1 SYNOPSIS

  use EBook::Ishmael::ShellQuote qw(shell_quote);

  my $quote = shell_quote("$ <-- literally a dollar sign");
  system "echo $quote";

=head1 DESCRIPTION

B<EBook::Ishmael::ShellQuote> is a module that provides the C<shell_quote()>
subroutine for quoting strings to be passed as arguments to a shell command.
This is a private module, consult the L<ishmael> manual for user
documentation.

=head1 SUBROUTINES

=over 4

=item $quoted = shell_quote($string)

Returns the double-quote-quotted version of the given string. Characters like
C<$>, C<`>, and C<"> will be escaped via a backslash, and the string will be
wrapped in double quotes.

=back

=head1 AUTHOR

Written by Samuel Young, E<lt>samyoung12788@gmail.comE<gt>.

This project's source can be found on its
L<Codeberg Page|https://codeberg.org/1-1sam/ishmael>. Comments and pull
requests are welcome!

=head1 COPYRIGHT

Copyright (C) 2025 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=head1 SEE ALSO

L<ishmael>

=cut
