package Dist::Zooky;
$Dist::Zooky::VERSION = '0.22';
# ABSTRACT: converts a distribution to Dist::Zilla

use strict;
use warnings;
use Class::Load ();
use Moose;
use MooseX::Types::Perl qw(DistName LaxVersionStr);
use Dist::Zooky::License;
use Dist::Zooky::DistIni;
use Module::Pluggable search_path => 'Dist::Zooky::Core';
use ExtUtils::MakeMaker ();

has 'make' => (
  is => 'ro',
  isa => 'Str',
);

has 'metafile' => (
  is => 'ro',
  isa => 'Bool',
);

has 'bundle' => (
  is => 'ro',
  isa => 'Str',
);

sub examine {
  my $self = shift;

  die "Hey, you already have a 'dist.ini' giving up\n" if -e 'dist.ini';

  my $type;
  if ( $self->metafile ) {
    $type = 'FromMETA';
  }
  elsif ( -e 'Build.PL' ) {
    $type = 'ModBuild';
  }
  elsif ( -e 'Makefile.PL' ) {
    {
      open my $MAKEFILEPL, '<', 'Makefile.PL' or die "$!\n";
      local $/;
      my $mfpl = <$MAKEFILEPL>;
      if ( $mfpl =~ /inc::Makefile::Install/s ) {
        #$type = 'ModInstall';
        $type = 'MakeMaker';
      }
      else {
         $type = 'MakeMaker';
      }
      close $MAKEFILEPL;
    }
  }

  my $core;

  foreach my $plugin ( $self->plugins ) {
    if ( $plugin =~ /$type$/ ) {
      Class::Load::load_class( $plugin );
      #$core = $plugin->new( ( $type eq 'MakeMaker' and $self->make ? ( make => $self->make ) : () ) );
      $core = $plugin->new( ( defined $self->make ? ( make => $self->make ) : () ) );
    }
  }

  die "No core plugin found for '$type'\n" unless $core;

  my $meta = $core->metadata();

  if ( defined $meta->{license} ) {
    my @licenses;
    foreach my $license ( @{ $meta->{license} } ) {
      my $aref = Dist::Zooky::License->new( metaname => $license )->license;
      push @licenses, map { ( split /::/, ref $_ )[-1] } @$aref;
    }
    $meta->{license} = \@licenses;
  }

  my $ini = Dist::Zooky::DistIni->new( type => $type, metadata => $meta, bundle => $self->bundle );
  $ini->write;

  warn "Wrote 'dist.ini'\n";

  my @files = grep { -e $_ } qw(MANIFEST Makefile.PL Build.PL);
  my $prompt = "\nThere are a number of files that should be removed now\n\n" .
               "Do you want me to remove [" . join(' ', @files ) . "] ? (yes/no)";
  my $answer = ExtUtils::MakeMaker::prompt($prompt, 'no');
  if ($answer =~ /\A(?:y|ye|yes)\z/i) {
    warn "Removing files\n";
    unlink $_ for @files;
  }
  warn "Done.\n";
}

__PACKAGE__->meta->make_immutable;
no Moose;

qq[And Dist::Zooky too!];

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zooky - converts a distribution to Dist::Zilla

=head1 VERSION

version 0.22

=head1 SYNOPSIS

  use Dist::Zooky;

  my $dzooky = Dist::Zooky->new();

  $dzooky->examine;

=head1 DESCRIPTION

Dist::Zooky is L<Dist::Zilla>'s nephew. He has the ability to summon his uncle.

It will try its best to convert a distribution to use L<Dist::Zilla>. It
supports L<ExtUtils::MakeMaker>, L<Module::Install> and L<Module::Build> based
distributions, with certain limitations.

The main documentation for this is under L<dzooky>.

=head2 METHODS

=over

=item C<examine>

This does all the heavy-lifting of determining if a distribution is L<ExtUtils::MakeMaker>,
L<Module::Install> and L<Module::Build> based, gathers meta data and generates a C<dist.ini>.

=back

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
