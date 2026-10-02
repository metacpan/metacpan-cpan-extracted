package Langertha::Raider::Hall::ACP::SubStream;
our $VERSION = '0.503';
# ABSTRACT: Internal stream shim feeding hall output into an ACP callback


use strict;
use warnings;

sub new {
  my ($class, %args) = @_;
  bless { cb => $args{cb}, opened => 1 }, $class;
}
sub write {
  my ($self, $line) = @_;
  chomp(my $l = $line);
  $self->{cb}->($l);
  return 1;
}
sub handle { $_[0] }
sub opened { $_[0]->{opened} }

# The hall drops a subscriber whose stream is no longer opened.
sub close { $_[0]->{opened} = 0 }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Hall::ACP::SubStream - Internal stream shim feeding hall output into an ACP callback

=head1 VERSION

version 0.503

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

Minimal stand-in for an L<IO::Async::Stream> used by
L<Langertha::Raider::Hall::ACP>: each written JSON line is passed to a
callback.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-raider/issues>.

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
