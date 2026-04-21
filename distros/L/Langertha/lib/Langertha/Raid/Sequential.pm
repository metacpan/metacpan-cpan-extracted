package Langertha::Raid::Sequential;
# ABSTRACT: Sequential Raid orchestrator
our $VERSION = '0.402';
use Moose;
use Future::AsyncAwait;

extends 'Langertha::Raid';


async sub run_f {
  my ( $self, $ctx ) = @_;
  $ctx = $self->_coerce_context($ctx);

  $ctx->add_trace({
    node  => ref($self),
    event => 'sequential_start',
    steps => scalar @{$self->steps},
  });

  return await $self->_run_steps_sequentially_f($ctx);
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raid::Sequential - Sequential Raid orchestrator

=head1 VERSION

version 0.402

=head1 SYNOPSIS

    my $raid = Langertha::Raid::Sequential->new(
      steps => [ $step1, $step2, $step3 ],
    );

    my $result = await $raid->run_f($ctx);

=head1 DESCRIPTION

Runs child steps in strict order and forwards one shared context through all
steps. Final outputs update context input for downstream steps. Non-final
results (question/pause/abort) are propagated immediately.

=head2 run_f

    my $result = await $raid->run_f($ctx);

Executes all steps sequentially with shared context propagation.

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
