use strict;
use warnings;
use 5.022;

package Alien::Build::Wizard::Detect 0.01 {

  use Moose;
  use Moose::Util::TypeConstraints;
  use MooseX::StrictConstructor;
  use Path::Tiny ();
  use experimental qw( signatures postderef );
  use namespace::autoclean;
  use constant myURI => "@{[ __PACKAGE__ ]}::URI";

  # ABSTRACT: Tarball detection class

  subtype myURI, as 'URI';

  coerce myURI, from 'Str', via {
    require URI;
    state $base ||= do {
      require URI::file;
      my $base = URI->new(URI::file->cwd);
      $base->host("localhost");
      $base;
    };
    URI->new_abs($_, $base);
  };

  has uri => (
    is       => 'ro',
    isa      => myURI,
    required => 1,
    coerce   => 1,
  );

  has ua => (
    is      => 'ro',
    isa     => 'LWP::UserAgent',
    lazy    => 1,
    default => sub {
      require LWP::UserAgent;
      my $ua = LWP::UserAgent->new;
      $ua->env_proxy;
      $ua;
    },
  );

  has tarball => (
    is       => 'ro',
    lazy     => 1,
    isa      => 'ScalarRef[Str]',
    init_arg => undef,
    default  => sub ($self) {
      my $ua = $self->ua;
      my $res = $ua->get($self->uri);
      die $res->status_line
        unless $res->is_success;
      \$res->decoded_content;
    },
  );

  has file_list => (
    is       => 'ro',
    isa      => 'ArrayRef[Path::Tiny]',
    lazy     => 1,
    init_arg => undef,
    default  => sub ($self) {
      require Archive::Libarchive::Peek;
      [map { Path::Tiny->new($_) } Archive::Libarchive::Peek->new( memory => $self->tarball )->files];
    }
  );

  has build_type => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    lazy     => 1,
    init_arg => undef,
    default  => sub ($self) {

      my %types;

      foreach my $file ($self->file_list->@*)
      {
        $types{autoconf} = 1 if $file->basename eq 'configure';
        $types{cmake} = 1    if $file->basename eq 'CMakeLists.txt';
        $types{make} = 1     if $file->basename eq 'Makefile';
      }

      [sort keys %types];
    },
  );

  has name => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 1,
    init_arg => undef,
    default  => sub ($self) {
      Path::Tiny->new($self->uri->path)->basename =~ s/[-\.].*$//r;
    },
  );

  has pkg_config => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    lazy     => 1,
    init_arg => undef,
    default  => sub ($self) {

      my %pc;

      foreach my $file ($self->file_list->@*)
      {
        $pc{$1} = 1 if $file->basename =~ /^(.*)\.pc(\.in)?$/;
      }

      [sort keys %pc];
    },
  );

  __PACKAGE__->meta->make_immutable;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Build::Wizard::Detect - Tarball detection class

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 % perldoc Dist::Zilla::MintingProfile::AlienBuild

=head1 DESCRIPTION

This class is private.

=head1 SEE ALSO

=over 4

=item L<Dist::Zilla::MintingProfile::AlienBuild>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
