package Dist::Zilla::Plugin::LaunchpadPPA;
{
  $Dist::Zilla::Plugin::LaunchpadPPA::VERSION = '0.1';
}

use Moose;

with 'Dist::Zilla::Role::Releaser';

use Path::Class qw(dir);
use File::pushd qw(pushd);
use Archive::Tar;
use Dpkg::Changelog::Parse;

has ppa => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has debuild_args => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    default  => '-S -sa',
);

has dput_args => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    default  => '',
);

sub release {
    my ($self, $archive) = @_;
    $archive = $archive->absolute;

    my $build_root = $self->zilla->root->subdir('.build');
    $build_root->mkpath unless -d $build_root;

    my $tmpdir = dir(File::Temp::tempdir(DIR => $build_root));

    $self->log("Extracting $archive to $tmpdir");

    my @files = do {
        my $pushd = pushd($tmpdir);
        Archive::Tar->extract_archive("$archive");
    };

    $self->log_fatal(["Failed to extract archive: %s", Archive::Tar->error])
      unless @files;

    my $pushd = pushd("$tmpdir/$files[0]");

    $self->_run_cmd(
        'debuild ' . $self->debuild_args . ' 2>&1',
        'Building source package',
        'Failed to build source package'
    );

    my $changelog = changelog_parse(file => 'debian/changelog');

    my $changes_fn = '../' . join('_', $changelog->{'Source'}, $changelog->{'Version'}, 'source.changes');

    $self->_run_cmd(
        'dput ' . $self->dput_args . ' ppa:' . $self->ppa . " $changes_fn 2>&1",
        'Uploading source package',
        'Failed to upload source package'
    );

    undef($pushd);
    $tmpdir->rmtree;
}

sub _run_cmd {
    my ($self, $cmd, $desc, $error) = @_;

    $self->log("$desc:");
    open(my $fh, "$cmd |") || $self->log_fatal('Cannot run `$cmd`: $!');
    while (<$fh>) {
        chomp;
        $self->log("  $_");
    }
    close($fh);

    $self->log_fatal($error) if $?;
}

1;

__END__

=pod

=head1 NAME

Dist::Zilla::Plugin::LaunchpadPPA - build and upload source package to ppa.launchpad.net

=head1 DESCRIPTION

It does not generate debian/* files, you must create them by yourself in advance.

=head1 ATTRIBUTES

=head2 ppa

PPA name, without 'ppa:' prefix.

=head2 debuild_args

`debuild` command arguments, default: '-S -sa'.

=head2 dput_args

`dput` command arguments, default: ''.

=head1 AUTHOR

Sergei Svistunov <svistunov@cpan.org>

=cut