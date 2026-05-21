package Dist::Zilla::Plugin::Docker::API::Result;
# ABSTRACT: Result object from Docker image build/push operations
our $VERSION = '0.103';
use Moo;
use Types::Standard qw(Str ArrayRef);

has image_id => (
    is  => 'ro',
    isa => Str,
);

has tags => (
    is      => 'ro',
    isa     => ArrayRef [Str],
    default => sub { [] },
);

has pushed => (
    is      => 'ro',
    isa     => ArrayRef [Str],
    default => sub { [] },
);

has digest => (
    is  => 'ro',
    isa => Str,
);

has warnings => (
    is      => 'ro',
    isa     => ArrayRef [Str],
    default => sub { [] },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Docker::API::Result - Result object from Docker image build/push operations

=head1 VERSION

version 0.103

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-dist-zilla-plugin-docker-api/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
