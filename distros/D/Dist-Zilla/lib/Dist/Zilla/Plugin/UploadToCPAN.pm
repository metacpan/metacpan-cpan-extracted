package Dist::Zilla::Plugin::UploadToCPAN 6.032;
# ABSTRACT: upload the dist to CPAN

use Moose;
with 'Dist::Zilla::Role::BeforeRelease',
     'Dist::Zilla::Role::Releaser';

use Dist::Zilla::Pragmas;

use File::Spec;
use Moose::Util::TypeConstraints;
use Scalar::Util qw(weaken);
use Dist::Zilla::Util;
use Try::Tiny;

use namespace::autoclean;

#pod =head1 SYNOPSIS
#pod
#pod If loaded, this plugin will allow the F<release> command to upload to the CPAN.
#pod
#pod =head1 DESCRIPTION
#pod
#pod This plugin looks for configuration in your C<dist.ini> or (more
#pod likely) C<~/.dzil/config.ini>:
#pod
#pod   [%PAUSE]
#pod   username = YOUR-PAUSE-ID
#pod   password = YOUR-PAUSE-PASSWORD
#pod
#pod If this configuration does not exist, it can read the configuration from
#pod C<~/.pause>, in the same format that L<cpan-upload> requires:
#pod
#pod   user YOUR-PAUSE-ID
#pod   password YOUR-PAUSE-PASSWORD
#pod
#pod If neither configuration exists, it will prompt you to enter your
#pod username and password during the BeforeRelease phase.  Entering a
#pod blank username or password will abort the release.
#pod
#pod You can't put your password in your F<dist.ini>.  C'mon now!
#pod
#pod =cut

{
  package
    Dist::Zilla::Plugin::UploadToCPAN::_Uploader;
  # CPAN::Uploader will be loaded later if used
  our @ISA = 'CPAN::Uploader';
  # Report CPAN::Uploader's version, not ours:
  sub _ua_string { CPAN::Uploader->_ua_string }

  sub log {
    my $self = shift;
    $self->{'Dist::Zilla'}{plugin}->log(@_);
  }
}

#pod =attr credentials_stash
#pod
#pod This attribute holds the name of a L<PAUSE stash|Dist::Zilla::Stash::Login>
#pod that will contain the credentials to be used for the upload.  By default,
#pod UploadToCPAN will look for a C<%PAUSE> stash.
#pod
#pod =cut

has credentials_stash => (
  is  => 'ro',
  isa => 'Str',
  default => '%PAUSE'
);

has _credentials_stash_obj => (
  is   => 'ro',
  isa  => maybe_type( role_type('Dist::Zilla::Role::Stash::Login') ),
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

#pod =attr username
#pod
#pod This option supplies the user's PAUSE username.
#pod It will be looked for in the user's PAUSE configuration; if not
#pod found, the user will be prompted.
#pod
#pod =cut

has username => (
  is   => 'ro',
  isa  => 'Str',
  lazy => 1,
  default  => sub {
    my ($self) = @_;
    return $self->_credential('username')
        || $self->pause_cfg->{user}
        || $self->zilla->chrome->prompt_str("PAUSE username: ");
  },
);

sub cpanid { shift->username }

#pod =attr password
#pod
#pod This option supplies the user's PAUSE password.  It cannot be provided via
#pod F<dist.ini>.  It will be looked for in the user's PAUSE configuration; if not
#pod found, the user will be prompted.
#pod
#pod =cut

has password => (
  is   => 'ro',
  isa  => 'Str',
  init_arg => undef,
  lazy => 1,
  default  => sub {
    my ($self) = @_;
    my $pw = $self->_credential('password') || $self->pause_cfg->{password};

    unless ($pw){
      my $uname = $self->username;
      $pw = $self->zilla->chrome->prompt_str(
        "PAUSE password for $uname: ",
        { noecho => 1 },
      );
    }

    return $pw;
  },
);

#pod =attr pause_cfg_file
#pod
#pod This is the name of the file containing your pause credentials.  It defaults
#pod F<.pause>.  If you give a relative path, it is taken to be relative to
#pod L</pause_cfg_dir>.
#pod
#pod =cut

has pause_cfg_file => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub { '.pause' },
);

#pod =attr pause_cfg_dir
#pod
#pod This is the directory for resolving a relative L</pause_cfg_file>.
#pod it defaults to the glob expansion of F<~>.
#pod
#pod =cut

has pause_cfg_dir => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub { Dist::Zilla::Util->homedir },
);

#pod =attr pause_cfg
#pod
#pod This is a hashref of defaults loaded from F<~/.pause> -- this attribute is
#pod subject to removal in future versions, as the config-loading behavior in
#pod CPAN::Uploader is improved.
#pod
#pod =cut

has pause_cfg => (
  is      => 'ro',
  isa     => 'HashRef[Str]',
  lazy    => 1,
  default => sub {
    my $self = shift;
    require CPAN::Uploader;
    my $file = $self->pause_cfg_file;
    $file = File::Spec->catfile($self->pause_cfg_dir, $file)
      unless File::Spec->file_name_is_absolute($file);
    return {} unless -e $file && -r _;
    my $cfg = try {
      CPAN::Uploader->read_config_file($file)
    } catch {
      $self->log("Couldn't load credentials from '$file': $_");
      {};
    };
    return $cfg;
  },
);

#pod =attr subdir
#pod
#pod If given, this specifies a subdirectory under the user's home directory to
#pod which to upload.  Using this option is not recommended.
#pod
#pod =cut

has subdir => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_subdir',
);

#pod =attr upload_uri
#pod
#pod If given, this specifies an alternate URI for the PAUSE upload form.  By
#pod default, the default supplied by L<CPAN::Uploader> is used.  Using this option
#pod is not recommended in most cases.
#pod
#pod =cut

has upload_uri => (
  is => 'ro',
  isa => 'Str',
  predicate => 'has_upload_uri',
);

#pod =attr retries
#pod
#pod The number of retries to perform on upload failure (5xx response). The default
#pod is set to 3 by this plugin. This option will be passed to L<CPAN::Uploader>.
#pod
#pod =cut

has retries => (
  is => 'ro',
  isa => 'Int',
  default => 3,
);

#pod =attr retry_delay
#pod
#pod The number of seconds to wait between retries. The default is set to 5 seconds
#pod by this plugin. This option will be passed to L<CPAN::Uploader>.
#pod
#pod =cut

has retry_delay => (
  is => 'ro',
  isa => 'Int',
  default => 5,
);

has uploader => (
  is   => 'ro',
  isa  => 'CPAN::Uploader',
  lazy => 1,
  default => sub {
    my ($self) = @_;

    # Load the module lazily
    require CPAN::Uploader;
    CPAN::Uploader->VERSION('0.103004');  # require HTTPS

    my $uploader = Dist::Zilla::Plugin::UploadToCPAN::_Uploader->new({
      user     => $self->username,
      password => $self->password,
      ($self->has_subdir
           ? (subdir => $self->subdir) : ()),
      ($self->has_upload_uri
           ? (upload_uri => $self->upload_uri) : ()),
      ($self->retries
           ? (retries => $self->retries) : ()),
      ($self->retry_delay
           ? (retry_delay => $self->retry_delay) : ()),
    });

    $uploader->{'Dist::Zilla'}{plugin} = $self;
    weaken $uploader->{'Dist::Zilla'}{plugin};

    return $uploader;
  }
);

sub before_release {
  my $self = shift;

  my $sentinel = [];

  for my $attr (qw(username password)) {
    my $value;
    my $ok = eval { $value = $self->$attr; 1 };

    unless ($ok) {
      $self->log_fatal([ "Couldn't figure out %s: %s", $attr, $@ ]);
    }

    unless (length $value) {
      $self->log_fatal([ "No $attr was provided" ]);
    }
  }

  return;
}

sub release {
  my ($self, $archive) = @_;

  $self->uploader->upload_file("$archive");
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::UploadToCPAN - upload the dist to CPAN

=head1 VERSION

version 6.032

=head1 SYNOPSIS

If loaded, this plugin will allow the F<release> command to upload to the CPAN.

=head1 DESCRIPTION

This plugin looks for configuration in your C<dist.ini> or (more
likely) C<~/.dzil/config.ini>:

  [%PAUSE]
  username = YOUR-PAUSE-ID
  password = YOUR-PAUSE-PASSWORD

If this configuration does not exist, it can read the configuration from
C<~/.pause>, in the same format that L<cpan-upload> requires:

  user YOUR-PAUSE-ID
  password YOUR-PAUSE-PASSWORD

If neither configuration exists, it will prompt you to enter your
username and password during the BeforeRelease phase.  Entering a
blank username or password will abort the release.

You can't put your password in your F<dist.ini>.  C'mon now!

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 ATTRIBUTES

=head2 credentials_stash

This attribute holds the name of a L<PAUSE stash|Dist::Zilla::Stash::Login>
that will contain the credentials to be used for the upload.  By default,
UploadToCPAN will look for a C<%PAUSE> stash.

=head2 username

This option supplies the user's PAUSE username.
It will be looked for in the user's PAUSE configuration; if not
found, the user will be prompted.

=head2 password

This option supplies the user's PAUSE password.  It cannot be provided via
F<dist.ini>.  It will be looked for in the user's PAUSE configuration; if not
found, the user will be prompted.

=head2 pause_cfg_file

This is the name of the file containing your pause credentials.  It defaults
F<.pause>.  If you give a relative path, it is taken to be relative to
L</pause_cfg_dir>.

=head2 pause_cfg_dir

This is the directory for resolving a relative L</pause_cfg_file>.
it defaults to the glob expansion of F<~>.

=head2 pause_cfg

This is a hashref of defaults loaded from F<~/.pause> -- this attribute is
subject to removal in future versions, as the config-loading behavior in
CPAN::Uploader is improved.

=head2 subdir

If given, this specifies a subdirectory under the user's home directory to
which to upload.  Using this option is not recommended.

=head2 upload_uri

If given, this specifies an alternate URI for the PAUSE upload form.  By
default, the default supplied by L<CPAN::Uploader> is used.  Using this option
is not recommended in most cases.

=head2 retries

The number of retries to perform on upload failure (5xx response). The default
is set to 3 by this plugin. This option will be passed to L<CPAN::Uploader>.

=head2 retry_delay

The number of seconds to wait between retries. The default is set to 5 seconds
by this plugin. This option will be passed to L<CPAN::Uploader>.

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
