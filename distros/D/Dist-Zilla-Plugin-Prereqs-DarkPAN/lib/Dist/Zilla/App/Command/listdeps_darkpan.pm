use 5.006;    # our
use strict;
use warnings;

package Dist::Zilla::App::Command::listdeps_darkpan;

our $VERSION = 'v0.3.0';

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

# FILENAME: listdeps_darkpan.pm
# CREATED: 30/10/11 11:07:09 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: List DarkPAN dependencies

use Dist::Zilla::App '-command';



















sub abstract { return 'list your distributions prerequisites from darkpans' }    ## no critic (ProhibitAmbiguousNames)

sub opt_spec {
  return [ 'missing', 'list only the missing dependencies' ],;
}

sub _extract_dependencies {
  my ( undef, $zilla, $missing ) = @_;
  $_->before_build     for @{ $zilla->plugins_with('-BeforeBuild') };
  $_->gather_files     for @{ $zilla->plugins_with('-FileGatherer') };
  $_->prune_files      for @{ $zilla->plugins_with('-FilePruner') };
  $_->munge_files      for @{ $zilla->plugins_with('-FileMunger') };
  $_->register_prereqs for @{ $zilla->plugins_with('-PrereqSource') };
  my @dark;
  my $callback = sub {
    shift @_ if 'HASH' eq ref $_[0];
    push @dark, @_;
  };

  $_->register_external_prereqs($callback) for @{ $zilla->plugins_with('-PrereqSource::External') };

  if ($missing) {
    @dark = grep { not $_->is_satisfied } @dark;
  }
  @dark = sort { lc $a->uri cmp lc $b->uri } @dark;
  return @dark;
}

sub execute {
  my ( $self, $opt, ) = @_;
  my $logger = $self->app->chrome->logger;
  $logger->mute;
  for ( $self->_extract_dependencies( $self->zilla, $opt->missing, ) ) {
    say $_->uri or do {
      $logger->unmute;
      $logger->log_fatal('Error writing to output');
    };
  }
  return 1;
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::App::Command::listdeps_darkpan - List DarkPAN dependencies

=head1 VERSION

version v0.3.0

=head1 SYNOPSIS

This code is mostly borged from the C<listdeps> command as a temporary measure till upstream
add native support.

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Dist::Zilla::App::Command::listdeps_darkpan",
    "interface":"class",
    "inherits":"Dist::Zilla::App::Command"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
