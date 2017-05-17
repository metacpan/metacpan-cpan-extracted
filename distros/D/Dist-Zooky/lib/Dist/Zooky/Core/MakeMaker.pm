package Dist::Zooky::Core::MakeMaker;
$Dist::Zooky::Core::MakeMaker::VERSION = '0.24';
# ABSTRACT: gather meta data for EUMM or M::I dists

use strict;
use warnings;
use Moose;
use IPC::Cmd qw[run can_run];

with 'Dist::Zooky::Role::Core';
with 'Dist::Zooky::Role::Meta';

has 'make' => (
  is => 'ro',
  isa => 'Str',
  default => sub { can_run('make') },
);

sub _build_metadata {
  my $self = shift;

  my $struct;

  {
    local $ENV{X_MYMETA} = 1; # Make Module::Install produce MYMETA.yml
    local $ENV{PERL_MM_USE_DEFAULT} = 1;
    local $ENV{PERL_EXTUTILS_AUTOINSTALL} = '--defaultdeps';

    my $cmd = [ $^X, 'Makefile.PL' ];
    run ( command => $cmd, verbose => 0 );
  }

  if ( -e 'MYMETA.json' ) {

    $struct = $self->meta_from_file( 'MYMETA.json' );

  }
  elsif ( -e 'MYMETA.yml' ) {

    $struct = $self->meta_from_file( 'MYMETA.yml' );

  }
  else {

    $struct = $self->_parse_makefile;

  }

  {
    my $cmd = [ $self->make, 'distclean' ];
    run( command => $cmd, verbose => 0 );
  }

  return { %$struct };
}

sub _parse_makefile {
  my $self = shift;

  die "No 'Makefile' found\n" unless -e 'Makefile';

  my $struct = { };

  my %p;
  my %c;
  my %b;

  {
    open my $MAKEFILE, '<', 'Makefile' or die "Could not open 'Makefile': $!\n";

    while( local $_ = <$MAKEFILE> ) {
      chomp;
      if ( m|^[\#]\s+AUTHOR\s+=>\s+q\[(.*?)\]$| ) {
        $struct->{author} = [ $1 ];
        next;
      }
      if ( m|^[\#]\s+LICENSE\s+=>\s+q\[(.*?)\]$| ) {
        $struct->{license} = [ $1 ];
        next;
      }
      if ( m|^DISTNAME\s+=\s+(.*?)$| ) {
        $struct->{name} = $1;
        next;
      }
      if ( m|^VERSION\s+=\s+(.*?)$| ) {
        $struct->{version} = $1;
        next;
      }

      if ( my ($prereqs) = m|^[\#]\s+PREREQ_PM\s+=>\s+(.+)| ) {
        while( $prereqs =~ m/(?:\s)([\w\:]+)=>(?:q\[(.*?)\],?|undef)/g ) {
            if( defined $p{$1} ) {
                my $ver = $self->_version_to_number(version => $2);
                $p{$1} = $ver
                  if $self->_vcmp( $ver, $p{$1} ) > 0;
            }
            else {
                $p{$1} = $self->_version_to_number(version => $2);
            }
        }
        next;
      }

      if ( my ($buildreqs) = m|^[\#]\s+BUILD_REQUIRES\s+=>\s+(.+)| ) {
        while( $buildreqs =~ m/(?:\s)([\w\:]+)=>(?:q\[(.*?)\],?|undef)/g ) {
            if( defined $b{$1} ) {
                my $ver = $self->_version_to_number(version => $2);
                $b{$1} = $ver
                  if $self->_vcmp( $ver, $b{$1} ) > 0;
            }
            else {
                $b{$1} = $self->_version_to_number(version => $2);
            }
        }
        next;
      }

      if ( my ($confreqs) = m|^[\#]\s+CONFIGURE_REQUIRES\s+=>\s+(.+)| ) {
        while( $confreqs =~ m/(?:\s)([\w\:]+)=>(?:q\[(.*?)\],?|undef)/g ) {
            if( defined $c{$1} ) {
                my $ver = $self->_version_to_number(version => $2);
                $c{$1} = $ver
                  if $self->_vcmp( $ver, $c{$1} ) > 0;
            }
            else {
                $c{$1} = $self->_version_to_number(version => $2);
            }
        }
        next;
      }

    }

    close $MAKEFILE;
  }

  my $prereqs = { };
  $prereqs->{runtime}   = { requires => \%p } if scalar keys %p;
  $prereqs->{configure} = { requires => \%c } if scalar keys %c;
  $prereqs->{build}     = { requires => \%c } if scalar keys %c;
  $struct->{prereqs}    = $prereqs if scalar keys %{ $prereqs };

  return $struct;
}

__PACKAGE__->meta->make_immutable;
no Moose;

qq[MakeMaker];

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zooky::Core::MakeMaker - gather meta data for EUMM or M::I dists

=head1 VERSION

version 0.24

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
