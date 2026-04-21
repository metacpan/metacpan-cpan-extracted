package Langertha::Role::Temperature;
# ABSTRACT: Role for an engine that can have a temperature setting
our $VERSION = '0.402';
use Moose::Role;

has temperature => (
  isa => 'Num',
  is => 'ro',
  predicate => 'has_temperature',
);



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::Temperature - Role for an engine that can have a temperature setting

=head1 VERSION

version 0.402

=head2 temperature

Sampling temperature as a number. Higher values (e.g. C<0.9>) make output more
random; lower values (e.g. C<0.1>) make it more focused and deterministic. When
not set, the engine's API default is used.

=head1 SEE ALSO

=over

=item * L<Langertha::Role::Seed> - Seed for reproducible outputs

=item * L<Langertha::Role::ResponseSize> - Limit response token count

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
