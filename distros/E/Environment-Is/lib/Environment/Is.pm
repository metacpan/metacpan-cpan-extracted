use warnings;
use 5.020;
use experimental qw( postderef signatures );

package Environment::Is 0.01 {

  # ABSTRACT: Detect environments like Docker or WSL


  use FFI::Platypus 2.00;
  use Exporter qw( import );

  my $ffi = FFI::Platypus->new(
    api  => 2,
    lang => 'Rust',
  );
  $ffi->bundle;
  $ffi->mangler(sub ($name) { "iz_$name" });


  $ffi->attach( is_docker => [] => 'bool' );
  $ffi->attach( is_interactive => [] => 'bool' );
  $ffi->attach( is_wsl => [] => 'bool' );

  our @EXPORT_OK = sort grep /^is_/, keys %Environment::Is::;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Environment::Is - Detect environments like Docker or WSL

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 use Environment::Is qw( is_docker is_wsl );
 
 if(is_docker()) {
   ...
 }

 if(is_wsl()) {
   ...
 }

=head1 DESCRIPTION

This module provides some C<is_> prefixed functions for detecting certain environments.
Additional environments may be added in the future.

=head1 FUNCTIONS

=head2 is_docker

Returns true if the current process is running inside a docker container.

=head2 is_interactive

Return true if the current process is interactive.

=head2 is_wsl

Returns true if the current process is running inside Windows Subsystem for Linux (WSL).

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
