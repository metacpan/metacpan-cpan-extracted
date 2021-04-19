package FFI::ExtractSymbols::PosixNm;

use strict;
use warnings;
use File::Which qw( which );
use File::ShareDir::Dist ();
use constant ();

my $config = File::ShareDir::Dist::dist_config('FFI-ExtractSymbols');

# ABSTRACT: Posix nm implementation for FFI::ExtractSymbols
our $VERSION = '0.05'; # VERSION


return 1 if FFI::ExtractSymbols->can('extract_symbols');

my $nm = which('nm');
$nm = $config->{'exe'}->{nm}
  unless defined $nm;

if(my $prefix = $config->{'function_prefix'})
{
  my $re = qr{^$prefix};
  *_remove_code_prefix = sub {
    my $symbol = shift;
    $symbol =~ s{$re}{};
    $symbol;
  }
}
else
{ *_remove_code_prefix = sub { $_[0] } }

if(my $prefix = $config->{'data_prefix'})
{
  my $re = qr{^$prefix};
  *_remove_data_prefix = sub {
    my $symbol = shift;
    $symbol =~ s{$re}{};
    $symbol;
  }
}
else
{ *_remove_data_prefix = sub { $_[0] } }

*FFI::ExtractSymbols::extract_symbols = sub
{
  my($libpath, %callbacks) = @_;

  $callbacks{$_} ||= sub {} for qw( export code data );

  foreach my $line (`$nm -g -P -D $libpath`)
  {
    next if $line =~ /^\s/;
    my($symbol, $type) = split /\s+/, $line;
    if($type eq $config->{function_code} || $type eq 'W')
    {
      $callbacks{export}->(_remove_code_prefix($symbol), $symbol);
      $callbacks{code}->  (_remove_code_prefix($symbol), $symbol);
    }
    elsif($type eq $config->{data_code})
    {
      $callbacks{export}->(_remove_data_prefix($symbol), $symbol);
      $callbacks{data}->  (_remove_data_prefix($symbol), $symbol);
    }
  }
  ();
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::ExtractSymbols::PosixNm - Posix nm implementation for FFI::ExtractSymbols

=head1 VERSION

version 0.05

=head1 DESCRIPTION

Do not use this module directly.  Use L<FFI::ExtractSymbols>
instead.

=head1 SEE ALSO

=over 4

=item L<FFI::ExtractSymbols>

=item L<FFI::Platypus>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
