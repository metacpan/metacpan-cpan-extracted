package Dist::Zooky::App::Command::metafile;
$Dist::Zooky::App::Command::metafile::VERSION = '0.24';
# ABSTRACT: The other command that Dist::Zooky uses

use strict;
use warnings;
use Dist::Zooky::App -command;

sub abstract { 'Dist::Zooky!' }

sub execute {
  my ($self, $opt, $args) = @_;
  require Dist::Zooky;
  my $zooky = Dist::Zooky->new( metafile => 1 );
  $zooky->examine;
  return;
}

qq[Lighten up and play];

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zooky::App::Command::metafile - The other command that Dist::Zooky uses

=head1 VERSION

version 0.24

=head1 DESCRIPTION

Dist::Zooky anther command, this is it. And it is not the default so
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
