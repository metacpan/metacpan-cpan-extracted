use strict;
use warnings;
use 5.020;
use experimental qw( postderef );

package Dist::Zilla::MintingProfile::FFI 0.03 {

  use Moose;
  with 'Dist::Zilla::Role::MintingProfile::ShareDir';
  use namespace::autoclean;

  # ABSTRACT: A minimal Dist::Zilla minting profile for FFI

  __PACKAGE__->meta->make_immutable;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::MintingProfile::FFI - A minimal Dist::Zilla minting profile for FFI

=head1 VERSION

version 0.03

=head1 SYNOPSIS

 dzil new -P FFI Foo::FFI

=head1 DESCRIPTION

This is a L<Dist::Zilla> minting profile for creating L<FFI::Platypus> bindings.
It uses a reasonable template and the L<[@Starter]|Dist::Zilla::PluginBundle::Starter>
or L<[@Starter::Git]|Dist::Zilla::PluginBundle::Starter::Git> bundle plus some
FFI specific plugins.

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

=item L<[@Starter]|Dist::Zilla::PluginBundle::Starter>

=item L<[@Starter::Git]|Dist::Zilla::PluginBundle::Starter::Git>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
