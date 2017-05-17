package Dist::Zooky::App::Command::dist;
$Dist::Zooky::App::Command::dist::VERSION = '0.24';
# ABSTRACT: The one command that Dist::Zooky uses

use strict;
use warnings;
use Dist::Zooky::App -command;

sub abstract { 'Dist::Zooky!' }

sub opt_spec {
  return (
      [ 'make=s', 'Specify make utility to use', ],
      [ 'bundle=s', 'Specify a plugin bundle to write to the dist.ini file', ],
  );
}

sub execute {
  my ($self, $opt, $args) = @_;
  require Dist::Zooky;
  my $zooky = Dist::Zooky->new(
    ( defined $opt->{make} ? ( make => $opt->{make} ) : () ),
    ( defined $opt->{bundle} ? ( bundle => $opt->{bundle} ) : () )
  );
  $zooky->examine;
  return;
}

qq[Lighten up and play];

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zooky::App::Command::dist - The one command that Dist::Zooky uses

=head1 VERSION

version 0.24

=head1 DESCRIPTION

Dist::Zooky has but one command, this is it. And it is the default so
you should never need to specify it.

=head1 METHOD

=over

=item C<execute>

This runs L<Dist::Zooky> for you.

=back

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
