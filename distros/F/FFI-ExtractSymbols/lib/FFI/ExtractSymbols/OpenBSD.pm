package FFI::ExtractSymbols::OpenBSD;

use strict;
use warnings;
use File::Which qw( which );
use File::ShareDir::Dist::Install;
use constant _function_code => 'T';
use constant _data_code     => 'B';

my $config = File::ShareDir::Dist::dist_config('FFI-ExtractSymbols');

# ABSTRACT: OpenBSD nm implementation for FFI::ExtractSymbols
our $VERSION = '0.07'; # VERSION


return 1 if FFI::ExtractSymbols->can('extract_symbols') || $^O ne 'openbsd';

my $nm = which('nm');
$nm = $config->{'exe'}->{nm}
  unless defined $nm;

*FFI::ExtractSymbols::extract_symbols = sub
{
  my($libpath, %callbacks) = @_;

  $callbacks{$_} ||= sub {} for qw( export code data );

  foreach my $line (`$nm -g $libpath`)
  {
    next if $line =~ /^\s/;
    my(undef, $type, $symbol) = split /\s+/, $line;
    if($type eq _function_code || $type eq 'W')
    {
      $callbacks{export}->($symbol, $symbol);
      $callbacks{code}->  ($symbol, $symbol);
    }
    elsif($type eq _data_code)
    {
      $callbacks{export}->($symbol, $symbol);
      $callbacks{data}->  ($symbol, $symbol);
    }
  }
  ();
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::ExtractSymbols::OpenBSD - OpenBSD nm implementation for FFI::ExtractSymbols

=head1 VERSION

version 0.07

=head1 DESCRIPTION

Do not use this module directly.  Use L<FFI::ExtractSymbols>
instead.

=head1 SEE ALSO

=over 4

=item L<FFI::ExtractSymbols>

=item L<FFI::Platypus>

=back

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Sanko Robinson (SANKO)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
