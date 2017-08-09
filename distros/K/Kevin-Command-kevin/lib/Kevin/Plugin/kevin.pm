package Kevin::Plugin::kevin;
$Kevin::Plugin::kevin::VERSION = '0.1.1';
# ABSTRACT: Mojolicious plugin for alternative minion commands
use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ($self, $app, $conf) = @_;

  unshift @{$app->commands->namespaces}, 'Kevin::Command';
}

1;

#pod =encoding utf8
#pod
#pod =head1 SYNOPSIS
#pod
#pod   # plugin for Minion
#pod   $self->plugin(Minion => {Pg => 'postgresql://postgres@/test'});
#pod
#pod   # then
#pod   $self->plugin('Kevin::Plugin::kevin');
#pod
#pod   # run
#pod   ./app.pl kevin worker
#pod
#pod =head1 DESCRIPTION
#pod
#pod This setups the L<kevin worker> command with the alternative
#pod L<Kevin::Command::kevin::worker>.
#pod
#pod =head1 METHODS
#pod
#pod L<Kevin::Plugin::kevin> inherits all methods from
#pod L<Mojolicious::Plugin> and implements the following new ones.
#pod
#pod =head2 register
#pod
#pod   $plugin->register(Mojolicious->new);
#pod
#pod Register plugin in L<Mojolicious> application.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Minion>, L<Mojolicious::Guides>, L<http://mojolicious.org>.
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

Kevin::Plugin::kevin - Mojolicious plugin for alternative minion commands

=head1 VERSION

version 0.1.1

=head1 SYNOPSIS

  # plugin for Minion
  $self->plugin(Minion => {Pg => 'postgresql://postgres@/test'});

  # then
  $self->plugin('Kevin::Plugin::kevin');

  # run
  ./app.pl kevin worker

=head1 DESCRIPTION

This setups the L<kevin worker> command with the alternative
L<Kevin::Command::kevin::worker>.

=head1 METHODS

L<Kevin::Plugin::kevin> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Minion>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=head1 AUTHOR

Adriano Ferreira <ferreira@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adriano Ferreira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
