package FFI::ExtractSymbols::Windows;

use strict;
use warnings;
use File::ShareDir::Dist ();
use File::Which qw( which );

my $config = File::ShareDir::Dist::dist_config('FFI-ExtractSymbols');

# ABSTRACT: Windows (and Cygwin) implementation for FFI::ExtractSymbols
our $VERSION = '0.04'; # VERSION


return 1 if FFI::ExtractSymbols->can('extract_symbols') || $^O !~ /^(MSWin32|cygwin)$/;

my $dumpbin = which('dumpbin');
$dumpbin ||= $config->{'exe'}->{dumpbin};

if($dumpbin)
{
  # convert path to dumpbin to a spaceless version if it has
  # spaces
  $dumpbin = Win32::GetShortPathName($dumpbin) if $dumpbin =~ /\s/;

  # use forward slashes
  $dumpbin =~ s{\\}{/}g;

  # maybe we can tell the difference?
  # N:\home\ollisg\dev\FFI-ExtractSymbols\.build\PxJz6vIGTh\libtest>dumpbin /symbols cygtest-1.dll|grep my_
  # 017 00000080 SECT1  notype ()    External     | my_function
  # 1F8 000001B0 SECT7  notype       External     | my_variable
  $FFI::ExtractSymbols::mode = 'mixed';

  *FFI::ExtractSymbols::extract_symbols = sub
  {
    my($libpath, %callbacks) = @_;
    $callbacks{$_} ||= sub {} for qw( export code data );

    # dumpbin requires a Windows path, not a POSIX one if you
    # are running under cygwin
    $libpath = Cygwin::posix_to_win_path($libpath) if $^O eq 'cygwin';

    # convert path to library to a spaceless version if it has spaces
    $libpath = Win32::GetShortPathName($libpath) if $libpath =~ /\s/;

    # use forward slashes
    $libpath =~ s{\\}{/}g;

    foreach my $line (`$dumpbin /exports $libpath`)
    {
      # we do not differentiate between code and data
      # with dumpbin extracts
      if($line =~ /[0-9]+\s+[0-9]+\s+[0-9a-fA-F]+\s+([^\s]*)\s*$/)
      {
        my $symbol = $1;
        $callbacks{export}->($symbol, $symbol);
        $callbacks{code}  ->($symbol, $symbol);
      }
    }

    ();
  };
}
else
{
  die "no implementation for FFI::ExtractSymbols";
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::ExtractSymbols::Windows - Windows (and Cygwin) implementation for FFI::ExtractSymbols

=head1 VERSION

version 0.04

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
