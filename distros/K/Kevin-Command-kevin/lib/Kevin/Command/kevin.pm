package Kevin::Command::kevin;
$Kevin::Command::kevin::VERSION = '0.1.1';
# ABSTRACT: Alternative Minion command
use Mojo::Base 'Mojolicious::Commands';

has description => 'Minion job queue alternative commands';
has hint        => <<EOF;

See 'APPLICATION kevin help COMMAND' for more information on a specific
command.
EOF
has message    => sub { shift->extract_usage . "\nCommands:\n" };
has namespaces => sub { ['Kevin::Command::kevin'] };

sub help { shift->run(@_) }

1;

#pod =encoding utf8
#pod
#pod =head1 SYNOPSIS
#pod
#pod   Usage: APPLICATION kevin COMMAND [OPTIONS]
#pod
#pod =head1 DESCRIPTION
#pod
#pod L<Kevin::Command::kevin> lists available alternative L<Minion> commands.
#pod
#pod =head1 ATTRIBUTES
#pod
#pod L<Kevin::Command::kevin> inherits all attributes from
#pod L<Mojolicious::Commands> and implements the following new ones.
#pod
#pod =head2 description
#pod
#pod   my $description = $cmd->description;
#pod   $cmd            = $cmd->description('Foo');
#pod
#pod Short description of this command, used for the command list.
#pod
#pod =head2 hint
#pod
#pod   my $hint = $cmd->hint;
#pod   $cmd     = $cmd->hint('Foo');
#pod
#pod Short hint shown after listing available L<Minion> commands.
#pod
#pod =head2 message
#pod
#pod   my $msg = $cmd->message;
#pod   $cmd    = $cmd->message('Bar');
#pod
#pod Short usage message shown before listing available L<Minion> commands.
#pod
#pod =head2 namespaces
#pod
#pod   my $namespaces = $cmd->namespaces;
#pod   $cmd           = $cmd->namespaces(['MyApp::Command::kevin']);
#pod
#pod Namespaces to search for available alternative L<Minion> commands, defaults to
#pod L<Kevin::Command::kevin>.
#pod
#pod =head1 METHODS
#pod
#pod L<Kevin::Command::kevin> inherits all methods from L<Mojolicious::Commands>
#pod and implements the following new ones.
#pod
#pod =head2 help
#pod
#pod   $minion->help('app');
#pod
#pod Print usage information for alternative L<Minion> command.
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

Kevin::Command::kevin - Alternative Minion command

=head1 VERSION

version 0.1.1

=head1 SYNOPSIS

  Usage: APPLICATION kevin COMMAND [OPTIONS]

=head1 DESCRIPTION

L<Kevin::Command::kevin> lists available alternative L<Minion> commands.

=head1 ATTRIBUTES

L<Kevin::Command::kevin> inherits all attributes from
L<Mojolicious::Commands> and implements the following new ones.

=head2 description

  my $description = $cmd->description;
  $cmd            = $cmd->description('Foo');

Short description of this command, used for the command list.

=head2 hint

  my $hint = $cmd->hint;
  $cmd     = $cmd->hint('Foo');

Short hint shown after listing available L<Minion> commands.

=head2 message

  my $msg = $cmd->message;
  $cmd    = $cmd->message('Bar');

Short usage message shown before listing available L<Minion> commands.

=head2 namespaces

  my $namespaces = $cmd->namespaces;
  $cmd           = $cmd->namespaces(['MyApp::Command::kevin']);

Namespaces to search for available alternative L<Minion> commands, defaults to
L<Kevin::Command::kevin>.

=head1 METHODS

L<Kevin::Command::kevin> inherits all methods from L<Mojolicious::Commands>
and implements the following new ones.

=head2 help

  $minion->help('app');

Print usage information for alternative L<Minion> command.

=head1 SEE ALSO

L<Minion>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=head1 AUTHOR

Adriano Ferreira <ferreira@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Adriano Ferreira

Adriano Ferreira <a.r.ferreira@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adriano Ferreira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
