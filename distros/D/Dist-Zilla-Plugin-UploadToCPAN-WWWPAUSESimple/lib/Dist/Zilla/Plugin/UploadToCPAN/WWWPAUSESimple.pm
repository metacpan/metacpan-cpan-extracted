package Dist::Zilla::Plugin::UploadToCPAN::WWWPAUSESimple;

our $DATE = '2017-01-12'; # DATE
our $VERSION = '0.04'; # VERSION

use Moose;
with qw(Dist::Zilla::Role::BeforeRelease Dist::Zilla::Role::Releaser);

use File::Spec;
use Moose::Util::TypeConstraints;
use Scalar::Util qw(weaken);
use Try::Tiny;

use namespace::autoclean;

has credentials_stash => (
  is  => 'ro',
  isa => 'Str',
  default => '%PAUSE'
);

has _credentials_stash_obj => (
  is   => 'ro',
  isa  => maybe_type( class_type('Dist::Zilla::Stash::PAUSE') ),
  lazy => 1,
  init_arg => undef,
  default  => sub { $_[0]->zilla->stash_named( $_[0]->credentials_stash ) },
);

sub _credential {
  my ($self, $name) = @_;

  return unless my $stash = $self->_credentials_stash_obj;
  return $stash->$name;
}

sub mvp_aliases {
  return { user => 'username' };
}

has username => (
  is   => 'ro',
  isa  => 'Str',
  lazy => 1,
  required => 1,
  default  => sub {
    my ($self) = @_;
    return $self->_credential('username')
        || $self->pause_cfg->{user}
        || $self->zilla->chrome->prompt_str("PAUSE username: ");
  },
);

has password => (
  is   => 'ro',
  isa  => 'Str',
  lazy => 1,
  required => 1,
  default  => sub {
    my ($self) = @_;
    return $self->_credential('password')
        || $self->pause_cfg->{password}
        || $self->zilla->chrome->prompt_str('PAUSE password: ', { noecho => 1 });
  },
);

has pause_cfg_file => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub { '.pause' },
);

has pause_cfg_dir => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub { require File::HomeDir; File::HomeDir::->my_home },
);

has pause_cfg => (
  is      => 'ro',
  isa     => 'HashRef[Str]',
  lazy    => 1,
  default => sub {},
);

has subdir => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_subdir',
);

has upload_uri => (
  is => 'ro',
  isa => 'Str',
  predicate => 'has_upload_uri',
);

has uploader => (
  is   => 'ro',
  isa  => 'CPAN::Uploader',
  lazy => 1,
  default => sub {},
);

has retries => (
    is  => 'ro',
    isa => 'Int',
    default => sub {2},
);

has retry_delay => (
    is  => 'ro',
    isa => 'Int',
    default => sub {3},
);

sub before_release {
  my $self = shift;

  my $problem;
  try {
    for my $attr (qw(username password)) {
      $problem = $attr;
      die unless length $self->$attr;
    }
    undef $problem;
  };

  $self->log_fatal(['You need to supply a %s', $problem]) if $problem;
}

sub release {
  my ($self, $archive) = @_;

  require WWW::PAUSE::Simple;
  #print "D: username: ", $self->username, "\n";
  #print "D: password: ", $self->password, "\n";

  $self->log(["Uploading %s to CPAN ...", "$archive"]);
  my $res = WWW::PAUSE::Simple::upload_files(
      username    => $self->username,
      password    => $self->password,
      subdir      => $self->subdir,
      files       => ["$archive"],
      retries     => $self->retries,
      retry_delay => $self->retry_delay,
  );
  if ($res->[0] == 200) {
      $self->log(["Upload succeeded: %s", $res]);
  } else {
      $self->log_fatal(["Upload failed: %s", $res]);
  }

}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Upload the dist to CPAN (using WWW::PAUSE::Simple)

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::UploadToCPAN::WWWPAUSESimple - Upload the dist to CPAN (using WWW::PAUSE::Simple)

=head1 VERSION

This document describes version 0.04 of Dist::Zilla::Plugin::UploadToCPAN::WWWPAUSESimple (from Perl distribution Dist-Zilla-Plugin-UploadToCPAN-WWWPAUSESimple), released on 2017-01-12.

=head1 SYNOPSIS

In your F<dist.ini>:

 [UploadToCPAN::WWWPAUSESimple]

=head1 DESCRIPTION

This is a replacement for L<Dist::Zilla::Plugin::UploadToCPAN>. It uses
L<WWW::PAUSE::Simple> for the actual upload. It offers some more options, e.g.
retries.

=for Pod::Coverage .+

=head1 CONFIGURATION

=head2 retries => int (default: 2)

Number of retries to do when received a 5xx HTTP error response from PAUSE (0 =
don't retry).

=head2 retry_delay => int (default: 3)

Number of seconds to wait before retrying.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-UploadToCPAN-WWWPAUSESimple>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-UploadToCPAN-WWWPAUSESimple>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-UploadToCPAN-WWWPAUSESimple>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
