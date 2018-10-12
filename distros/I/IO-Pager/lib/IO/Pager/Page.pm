package IO::Pager::Page;

our $VERSION = 0.32;


# The meat
BEGIN {
  # Do nothing in Perl compile mode
  return if $^C;
  # Find a pager
  use IO::Pager;
  # Pipe stdout to it
  new IO::Pager *STDOUT, 'IO::Pager::Unbuffered';
}

# Gravy
sub import {
  my ($self, %opt) = @_;
  $SIG{PIPE} = 'IGNORE' if $opt{hush};
}

"Badee badee badee that's all folks!";

__END__

=pod

=head1 NAME

IO::Pager::Page - Emulate IO::Page, pipe STDOUT to a pager if STDOUT is a TTY

=head1 SYNOPSIS

Pipes STDOUT to a pager if STDOUT is a TTY

=head1 DESCRIPTION

IO::Pager was designed to programmatically decide whether or not to point
the STDOUT file handle into a pipe to program specified in the I<PAGER>
environment variable or one of a standard list of pagers.

=head1 USAGE

  BEGIN {
    use IO::Pager::Page;
    # use I::P::P first, just in case another module sends output to STDOUT
  }
  print<<HEREDOC;
  ...
  A bunch of text later
  HEREDOC

If you wish to forgo the potential for a I<Broken Pipe> foible resulting
from the user exiting the pager prematurely, load IO::Pager::Page like so:

  use IO::Pager::Page hush=>1;

=head1 SEE ALSO

L<IO::Page>, L<IO::Pager>, L<IO::Pager::Unbuffered>, L<IO::Pager::Buffered>

=head1 AUTHOR

Jerrad Pierce <jpierce@cpan.org>

Florent Angly <florent.angly@gmail.com>

This module inspired by Monte Mitzelfelt's IO::Page 0.02

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003-2015 Jerrad Pierce

=over

=item * Thou shalt not claim ownership of unmodified materials.

=item * Thou shalt not claim whole ownership of modified materials.

=item * Thou shalt grant the indemnity of the provider of materials.

=item * Thou shalt use and dispense freely without other restrictions.

=back

Or, if you prefer:

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
