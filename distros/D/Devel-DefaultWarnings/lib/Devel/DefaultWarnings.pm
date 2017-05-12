package Devel::DefaultWarnings;
use strict;
use warnings FATAL => 'all';

our $VERSION = '0.001002';

use base 'Exporter';
our @EXPORT = qw(warnings_default);

my $check = do {
  if ($] >= 5.016) { q{
    !defined ${^WARNING_BITS};
  } }
  elsif ($] >= 5.008008) { q{
    my $w = ${^WARNING_BITS};
    local $^W = !$^W;
    $w ne ${^WARNING_BITS};
  } }
  elsif ($] >= 5.006001) { q{
    my $depth = 0;
    while (my ($sub, $bits) = (caller(++$depth))[3,9]) {
      if ($sub =~ /::BEGIN$/) {
        local $^W = !$^W;
        my $new_bits = (caller($depth))[9];
        return $bits ne $new_bits;
      }
    }
    ${^WARNING_BITS} eq $warnings::NONE;
  } }
  else { q{
    ${^WARNING_BITS} eq $warnings::NONE;
  } }
};

eval "sub warnings_default () { $check }; 1" or die $@;

1;

__END__
=head1 NAME

Devel::DefaultWarnings - Detect if warnings have been left at defaults

=head1 SYNOPSIS

  use Devel::DefaultWarnings;
  {
    BEGIN { my $def = warnings_default(); } #true;
  }
  {
    use warnings;
    BEGIN { my $def = warnings_default(); } #false;
  }
  {
    no warnings;
    BEGIN { my $def = warnings_default(); } #false;
  }

=head1 DESCRIPTION

Check if lexical warnings have been changed from the default.  Checks the
current compiling context.

=head1 FUNCTIONS

=over 4

=item warnings_default

Returns a true value if lexical warnings have been left as the default.

=back

=head1 AUTHOR

haarg - Graham Knop (cpan:HAARG) <haarg@haarg.org>

=head1 CONTRIBUTORS

None yet.

=head1 COPYRIGHT

Copyright (c) 2014 the Devel::DefaultWarnings L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
