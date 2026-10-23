package Langertha::Engine::Mock;
# ABSTRACT: Langertha::Engine::Virtual under the engine name Mock
our $VERSION = '0.504';
use Moose;

extends 'Langertha::Engine::Virtual';


__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::Mock - Langertha::Engine::Virtual under the engine name Mock

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    use Langertha;
    use Langertha::Virtual::Rules qw( answer );

    my $engine = Langertha->new_engine( Mock =>
      rules    => [ 'Hello' => answer('Hi there!') ],
      fallback => answer('done'),
    );

    my $echo = Langertha::Engine::Mock->preset('echo');

=head1 DESCRIPTION

The engine name C<Mock> for L<Langertha::Engine::Virtual>: the same class
with nothing added or changed, so code that picks its engine by name (for
example C<< Langertha->new_engine('Mock', ...) >>) can ask for a mock.
Everything - the rules, the script mode, the presets, C<rules_file> and the
recording - is documented in L<Langertha::Engine::Virtual>. Its
L<preset|Langertha::Engine::Virtual/preset> builds a
C<Langertha::Engine::Mock>.

=head1 SEE ALSO

=over

=item * L<Langertha::Engine::Virtual> - The engine and its rule language

=item * L<Langertha::Virtual::Rules> - C<answer>, C<tool>, C<tools> and C<after>

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

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
