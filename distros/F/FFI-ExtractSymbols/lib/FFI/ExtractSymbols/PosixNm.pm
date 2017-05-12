package FFI::ExtractSymbols::PosixNm;

use strict;
use warnings;
use File::Which qw( which );
use FFI::ExtractSymbols::ConfigData;
use constant _function_code =>
  FFI::ExtractSymbols::ConfigData->config('function_code');
use constant _data_code =>
  FFI::ExtractSymbols::ConfigData->config('data_code');

# ABSTRACT: Posix nm implementation for FFI::ExtractSymbols
our $VERSION = '0.03'; # VERSION


return 1 if FFI::ExtractSymbols->can('extract_symbols');

my $nm = which('nm');
$nm = FFI::ExtractSymbols::ConfigData->config('exe')->{nm}
  unless defined $nm;

if(my $prefix = FFI::ExtractSymbols::ConfigData->config('function_prefix'))
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

if(my $prefix = FFI::ExtractSymbols::ConfigData->config('data_prefix'))
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
  
  foreach my $line (`$nm -g -P $libpath`)
  {
    next if $line =~ /^\s/;
    my($symbol, $type) = split /\s+/, $line;
    if($type eq _function_code || $type eq 'W')
    {
      $callbacks{export}->(_remove_code_prefix($symbol), $symbol);
      $callbacks{code}->  (_remove_code_prefix($symbol), $symbol);
    }
    elsif($type eq _data_code)
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

version 0.03

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
