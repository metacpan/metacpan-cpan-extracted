package Dist::Zilla::Plugin::NextRelease 6.032;
# ABSTRACT: update the next release number in your changelog

use Moose;
with (
  'Dist::Zilla::Role::FileMunger',
  'Dist::Zilla::Role::TextTemplate',
  'Dist::Zilla::Role::AfterRelease',
);

use Dist::Zilla::Pragmas;

use namespace::autoclean;

use Dist::Zilla::Path;
use Moose::Util::TypeConstraints;
use List::Util 'first';
use String::Formatter 0.100680 stringf => {
  -as => '_format_version',

  input_processor => 'require_single_input',
  string_replacer => 'method_replace',
  codes => {
    v => sub { $_[0]->zilla->version },
    d => sub {
      require DateTime;
      DateTime->VERSION('0.44'); # CLDR fixes

      DateTime->from_epoch(epoch => $^T, time_zone => $_[0]->time_zone)
              ->format_cldr($_[1]),
    },
    t => sub { "\t" },
    n => sub { "\n" },
    E => sub { $_[0]->_user_info('email') },
    U => sub { $_[0]->_user_info('name')  },
    T => sub { $_[0]->zilla->is_trial
                   ? ($_[1] // '-TRIAL') : '' },
    V => sub { $_[0]->zilla->version
                . ($_[0]->zilla->is_trial
                   ? ($_[1] // '-TRIAL') : '') },
    P => sub {
      my $releaser = first { $_->can('cpanid') } @{ $_[0]->zilla->plugins_with('-Releaser') };
      $_[0]->log_fatal('releaser doesn\'t provide cpanid, but %P used') unless $releaser;
      $releaser->cpanid;
    },
  },
};

our $DEFAULT_TIME_ZONE = 'local';
has time_zone => (
  is => 'ro',
  isa => 'Str', # should be more validated later -- apocal
  default => $DEFAULT_TIME_ZONE,
);

has format => (
  is  => 'ro',
  isa => 'Str', # should be more validated Later -- rjbs, 2008-06-05
  default => '%-9v %{yyyy-MM-dd HH:mm:ssZZZZZ VVVV}d%{ (TRIAL RELEASE)}T',
);

has filename => (
  is  => 'ro',
  isa => 'Str',
  default => 'Changes',
);

has update_filename => (
  is  => 'ro',
  isa => 'Str',
  lazy    => 1,
  default => sub { $_[0]->filename },
);

has user_stash => (
  is      => 'ro',
  isa     => 'Str',
  default => '%User'
);

has _user_stash_obj => (
  is       => 'ro',
  isa      => maybe_type( class_type('Dist::Zilla::Stash::User') ),
  lazy     => 1,
  init_arg => undef,
  default  => sub { $_[0]->zilla->stash_named( $_[0]->user_stash ) },
);

sub _user_info {
  my ($self, $field) = @_;

  my $stash = $self->_user_stash_obj;

  $self->log_fatal([
    "You must enter your %s in the [%s] section in ~/.dzil/config.ini",
    $field, $self->user_stash
  ]) unless $stash and defined(my $value = $stash->$field);

  return $value;
}

sub section_header {
  my ($self) = @_;

  return _format_version($self->format, $self);
}

has _original_changes_content => (
  is  => 'rw',
  isa => 'Str',
  init_arg => undef,
);

sub munge_files {
  my ($self) = @_;

  my ($file) = grep { $_->name eq $self->filename } @{ $self->zilla->files };
  $self->log_fatal([ 'failed to find %s in the distribution', $self->filename ]) if not $file;

  # save original unmunged content, for replacing back in the repo later
  my $content = $self->_original_changes_content($file->content);

  $content = $self->fill_in_string(
    $content,
    {
      dist    => \($self->zilla),
      version => \($self->zilla->version),
      NEXT    => \($self->section_header),
    },
  );

  $self->log_debug([ 'updating contents of %s in memory', $file->name ]);
  $file->content($content);
}

# new release is part of distribution history, let's record that.
sub after_release {
  my ($self) = @_;
  my $filename = $self->filename;
  my ($gathered_file) = grep { $_->name eq $filename } @{ $self->zilla->files };
  $self->log_fatal("failed to find $filename in the distribution") if not $gathered_file;
  my $iolayer = sprintf(":raw:encoding(%s)", $gathered_file->encoding);

  # read original changelog
  my $content = $self->_original_changes_content;

  # add the version and date to file content
  my $delim  = $self->delim;
  my $header = $self->section_header;
  $content =~ s{ (\Q$delim->[0]\E \s*) \$NEXT (\s* \Q$delim->[1]\E) }
               {$1\$NEXT$2\n\n$header}xs;

  my $update_fn = $self->update_filename;
  $self->log_debug([ 'updating contents of %s on disk', $update_fn ]);

  # and finally rewrite the changelog on disk
  path($update_fn)->spew({binmode => $iolayer}, $content);
}

__PACKAGE__->meta->make_immutable;
1;

#pod =head1 SYNOPSIS
#pod
#pod In your F<dist.ini>:
#pod
#pod   [NextRelease]
#pod
#pod In your F<Changes> file:
#pod
#pod   {{$NEXT}}
#pod
#pod
#pod =head1 DESCRIPTION
#pod
#pod Tired of having to update your F<Changes> file by hand with the new
#pod version and release date / time each time you release your distribution?
#pod Well, this plugin is for you.
#pod
#pod Add this plugin to your F<dist.ini>, and the following to your
#pod F<Changes> file:
#pod
#pod   {{$NEXT}}
#pod
#pod The C<NextRelease> plugin will then do 2 things:
#pod
#pod =over 4
#pod
#pod =item * At build time, this special marker will be replaced with the
#pod version and the build date, to form a standard changelog header. This
#pod will be done to the in-memory file - the original F<Changes> file won't
#pod be updated.
#pod
#pod =item * After release (when running C<dzil release>), since the version
#pod and build date are now part of your dist's history, the real F<Changes>
#pod file (not the in-memory one) will be updated with this piece of
#pod information.
#pod
#pod =back
#pod
#pod The module accepts the following options in its F<dist.ini> section:
#pod
#pod =begin :list
#pod
#pod = filename
#pod the name of your changelog file;  defaults to F<Changes>
#pod
#pod = update_filename
#pod the file to which to write an updated changelog to; defaults to the C<filename>
#pod
#pod = format
#pod sprintf-like string used to compute the next value of C<{{$NEXT}}>;
#pod defaults to C<%-9v %{yyyy-MM-dd HH:mm:ssZZZZZ VVVV}d%{ (TRIAL RELEASE)}T>
#pod
#pod = time_zone
#pod the timezone to use when generating the date;  defaults to I<local>
#pod
#pod = user_stash
#pod the name of the stash where the user's name and email address can be found;
#pod defaults to C<%User>
#pod
#pod =end :list
#pod
#pod The module allows the following sprintf-like format codes in the C<format>:
#pod
#pod =begin :list
#pod
#pod = C<%v>
#pod The distribution version
#pod
#pod = C<%{-TRIAL}T>
#pod Expands to -TRIAL (or any other supplied string) if this
#pod is a trial release, or the empty string if not.  A bare C<%T> means
#pod C<%{-TRIAL}T>.
#pod
#pod = C<%{-TRIAL}V>
#pod Equivalent to C<%v%{-TRIAL}T>, to allow for the application of modifiers such
#pod as space padding to the entire version string produced.
#pod
#pod = C<%{CLDR format}d>
#pod The date of the release.  You can use any CLDR format supported by
#pod L<DateTime>.  You must specify the format; there is no default.
#pod
#pod = C<%U>
#pod The name of the user making this release (from C<user_stash>).
#pod
#pod = C<%E>
#pod The email address of the user making this release (from C<user_stash>).
#pod
#pod = C<%P>
#pod The CPAN (PAUSE) id of the user making this release (from -Releaser plugins;
#pod see L<[UploadToCPAN]|Dist::Zilla::Plugin::UploadToCPAN/username>).
#pod
#pod = C<%n>
#pod A newline
#pod
#pod = C<%t>
#pod A tab
#pod
#pod =end :list
#pod
#pod =head1 SEE ALSO
#pod
#pod Core Dist::Zilla plugins:
#pod L<AutoVersion|Dist::Zilla::Plugin::AutoVersion>,
#pod L<PkgVersion|Dist::Zilla::Plugin::PkgVersion>,
#pod L<PodVersion|Dist::Zilla::Plugin::PodVersion>.
#pod
#pod Dist::Zilla roles:
#pod L<AfterRelease|Dist::Zilla::Plugin::AfterRelease>,
#pod L<FileMunger|Dist::Zilla::Role::FileMunger>,
#pod L<TextTemplate|Dist::Zilla::Role::TextTemplate>.

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::NextRelease - update the next release number in your changelog

=head1 VERSION

version 6.032

=head1 SYNOPSIS

In your F<dist.ini>:

  [NextRelease]

In your F<Changes> file:

  {{$NEXT}}

=head1 DESCRIPTION

Tired of having to update your F<Changes> file by hand with the new
version and release date / time each time you release your distribution?
Well, this plugin is for you.

Add this plugin to your F<dist.ini>, and the following to your
F<Changes> file:

  {{$NEXT}}

The C<NextRelease> plugin will then do 2 things:

=over 4

=item * At build time, this special marker will be replaced with the
version and the build date, to form a standard changelog header. This
will be done to the in-memory file - the original F<Changes> file won't
be updated.

=item * After release (when running C<dzil release>), since the version
and build date are now part of your dist's history, the real F<Changes>
file (not the in-memory one) will be updated with this piece of
information.

=back

The module accepts the following options in its F<dist.ini> section:

=over 4

=item filename

the name of your changelog file;  defaults to F<Changes>

=item update_filename

the file to which to write an updated changelog to; defaults to the C<filename>

=item format

sprintf-like string used to compute the next value of C<{{$NEXT}}>;
defaults to C<%-9v %{yyyy-MM-dd HH:mm:ssZZZZZ VVVV}d%{ (TRIAL RELEASE)}T>

=item time_zone

the timezone to use when generating the date;  defaults to I<local>

=item user_stash

the name of the stash where the user's name and email address can be found;
defaults to C<%User>

=back

The module allows the following sprintf-like format codes in the C<format>:

=over 4

=item C<%v>

The distribution version

=item C<%{-TRIAL}T>

Expands to -TRIAL (or any other supplied string) if this
is a trial release, or the empty string if not.  A bare C<%T> means
C<%{-TRIAL}T>.

=item C<%{-TRIAL}V>

Equivalent to C<%v%{-TRIAL}T>, to allow for the application of modifiers such
as space padding to the entire version string produced.

=item C<%{CLDR format}d>

The date of the release.  You can use any CLDR format supported by
L<DateTime>.  You must specify the format; there is no default.

=item C<%U>

The name of the user making this release (from C<user_stash>).

=item C<%E>

The email address of the user making this release (from C<user_stash>).

=item C<%P>

The CPAN (PAUSE) id of the user making this release (from -Releaser plugins;
see L<[UploadToCPAN]|Dist::Zilla::Plugin::UploadToCPAN/username>).

=item C<%n>

A newline

=item C<%t>

A tab

=back

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

=head1 SEE ALSO

Core Dist::Zilla plugins:
L<AutoVersion|Dist::Zilla::Plugin::AutoVersion>,
L<PkgVersion|Dist::Zilla::Plugin::PkgVersion>,
L<PodVersion|Dist::Zilla::Plugin::PodVersion>.

Dist::Zilla roles:
L<AfterRelease|Dist::Zilla::Plugin::AfterRelease>,
L<FileMunger|Dist::Zilla::Role::FileMunger>,
L<TextTemplate|Dist::Zilla::Role::TextTemplate>.

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
