package Langertha::Role::Runnable;
# ABSTRACT: Common async execution contract for Raider and Raid nodes
our $VERSION = '0.305';
use Moose::Role;


requires 'run_f';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::Runnable - Common async execution contract for Raider and Raid nodes

=head1 VERSION

version 0.305

=head1 SYNOPSIS

    package My::Runnable;
    use Moose;
    use Future::AsyncAwait;
    with 'Langertha::Role::Runnable';

    async sub run_f {
      my ( $self, $ctx ) = @_;
      ...
    }

=head1 DESCRIPTION

Minimal execution contract shared by L<Langertha::Raider> and orchestration
nodes under L<Langertha::Raid>. Consumers must implement C<run_f($ctx)>.

=head2 run_f

    my $result = await $node->run_f($ctx);

Required method. Executes the runnable node with a context and returns a
Future that resolves to a result object.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
