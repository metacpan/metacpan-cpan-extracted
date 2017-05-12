package Dist::Zooky::Core::ModBuild;
$Dist::Zooky::Core::ModBuild::VERSION = '0.22';
# ABSTRACT: gather meta data for Module::Build dists

use strict;
use warnings;
use Moose;
use IPC::Cmd qw[run can_run];

with 'Dist::Zooky::Role::Core';
with 'Dist::Zooky::Role::Meta';

sub _build_metadata {
  my $self = shift;

  my $struct;

  {
    local $ENV{PERL_MM_USE_DEFAULT} = 1;

    my $cmd = [ $^X, 'Build.PL' ];
    run ( command => $cmd, verbose => 0 );
  }

  if ( -e 'MYMETA.json' ) {

    $struct = $self->meta_from_file( 'MYMETA.json' );

  }
  elsif ( -e 'MYMETA.yml' ) {

    $struct = $self->meta_from_file( 'MYMETA.yml' );

  }
  else {

    die "Couldn\'t find a 'MYMETA.yml or MYMETA.json' file, giving up\n";

  }

  {
    my $cmd = [ $^X, 'Build', 'distclean' ];
    run( command => $cmd, verbose => 0 );
  }

  return { %$struct };
}

__PACKAGE__->meta->make_immutable;
no Moose;

qq[MakeMaker];

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zooky::Core::ModBuild - gather meta data for Module::Build dists

=head1 VERSION

version 0.22

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
