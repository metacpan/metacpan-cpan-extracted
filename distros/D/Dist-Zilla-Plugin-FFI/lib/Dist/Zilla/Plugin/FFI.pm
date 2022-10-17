package Dist::Zilla::Plugin::FFI 1.07 {

  use strict;
  use warnings;
  use 5.020;

  # ABSTRACT: FFI related Dist::Zilla plugins


}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::FFI - FFI related Dist::Zilla plugins

=head1 VERSION

version 1.07

=head1 SYNOPSIS

 [FFI::Build]
 [FFI::CheckLib]

=head1 DESCRIPTION

This distribution contains some useful plugins for working with L<FFI::Platypus> and friends.

=head1 SEE ALSO

=over 4

=item L<Dist::Zilla::Plugin::FFI::Build>

Install the L<FFI::Build::MM> layer into your C<Makefile.PL>.

=item L<Dist::Zilla::Plugin::FFI::CheckLib>

Add L<FFI::CheckLib> checks into your C<Makefile.PL>.

=back

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Zaki Mughal (zmughal)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
