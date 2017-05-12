# ABSTRACT: Another helper for 'hid publish -A'


package HiD::Server::Loader;
our $AUTHORITY = 'cpan:GENEHACK';
$HiD::Server::Loader::VERSION = '1.98';
use 5.014;  # strict, unicode_strings
use warnings;

use parent 'Plack::Loader::Restarter';

# FIXME this is kinda not the greatest idea but this is less re-implementation
# than overriding the 'run' method and there really are zero hooks provided
# for this...
sub _fork_and_start {
  my($self, $server) = @_;

  delete $self->{pid};          # re-init in case it's a restart

  my $pid = fork;
  die "Can't fork: $!" unless defined $pid;

  if ($pid == 0) {              # child
    $server->republish();

    return $server->run($self->{builder}->());
  }
  else {
    $self->{pid} = $pid;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HiD::Server::Loader - Another helper for 'hid publish -A'

=head1

Another helper for C<hid publish -A>

=head1 VERSION

version 1.98

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
