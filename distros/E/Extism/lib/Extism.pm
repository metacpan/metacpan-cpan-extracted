package Extism v0.3.1;

use 5.016;
use strict;
use warnings;
use Extism::XS qw(version log_file);
use Extism::CompiledPlugin;
use Extism::Plugin;
use Extism::Function ':all';
use Exporter 'import';

sub log_custom {
  my ($level) = @_;
  return Extism::XS::log_custom($level);
}

sub log_drain {
  my ($func) = @_;
  local *Extism::active_log_drain_func = $func;
  return Extism::XS::log_drain();
}

our @EXPORT_OK = qw(
  Extism_I32
  Extism_I64
  Extism_F32
  Extism_F64
  Extism_V128
  Extism_FuncRef
  Extism_ExternRef
  Extism_String
);

our %EXPORT_TAGS;
$EXPORT_TAGS{all} = [@EXPORT_OK];

1;

__END__

=head1 NAME

Extism - Extism Perl SDK

=head1 DESCRIPTION

Extism L<https://extism.org/> is a cross-language framework for building
with WebAssembly. This distribution integrates Extism into Perl so Perl
programmers can easily use WebAssembly. Possibily to add a Plugin system
into their application or to integrate native deps without the headache
of native builds.

=head1 SYNOPSIS

    use Extism ':all';
    my $wasm = do { local(@ARGV, $/) = 'count_vowels.wasm'; <> };
    my $plugin = Extism::Plugin->new($wasm, {wasi => 1});
    my $output = $plugin->call('count_vowels', "this is a test");

=head1 EXAMPLES

See script/demo-perl-extism and t/02-extism.t

=head1 SUPPORT AND DOCUMENTATION

You can find documentation for this module with the perldoc command.

    perldoc Extism

Additional documentation, support, and bug reports can be found at the
Extism perl-sdk repository L<https://github.com/extism/perl-sdk>

Additional Extism support may be found in the discord server:
L<https://extism.org/discord>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2024 by Dylibso.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut