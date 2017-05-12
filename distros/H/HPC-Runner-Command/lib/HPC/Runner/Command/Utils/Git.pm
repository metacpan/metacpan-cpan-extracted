package HPC::Runner::Command::Utils::Git;

use MooseX::App::Role;

use namespace::autoclean;

use Git::Wrapper;
use Git::Wrapper::Plus::Ref::Tag;
use Git::Wrapper::Plus::Tags;
use Git::Wrapper::Plus::Branches;

use Try::Tiny;

use Sort::Versions;
use Version::Next qw/next_version/;

use Cwd;
use List::Uniq ':all';
use File::Path qw(make_path);
use File::Slurp;
use File::Spec;
use Archive::Tar;
use Data::Dumper;

with 'HPC::Runner::Command::Utils::Log';

=head1 HPC::Runner::Command::Utils::Git

For projects under version control (and they should all be under version control), tag each submission with a version. Keep track of branches, tag, remote, etc.

=head2 Attributes

=cut

=head3 version

Version of our submission. Has a corresponding git tag.

=cut

option 'version' => (
    is        => 'rw',
    required  => 0,
    predicate => 'has_version',
    documentation =>
        'Submission version. Each version has a corresponding git tag. See the difference between tags with `git diff tag1 tag2`. Tags are always version numbers, starting with 0.01.',
);

option 'autocommit' => (
    traits        => ['Bool'],
    is            => 'rw',
    isa           => 'Bool',
    default       => 1,
    documentation => 'Run a git add -A on dirty build',
    handles       => { no_autocommit => 'unset', },
);

has 'git_dir' => (
    is        => 'rw',
    isa       => 'Str',
    default   => sub { return cwd() },
    predicate => 'has_git_dir',
);

has 'git' => (
    is        => 'rw',
    predicate => 'has_git',
    required  => 0,
);

has 'current_branch' => (
    is        => 'rw',
    isa       => 'Str',
    required  => 0,
    predicate => 'has_current_branch',
);

has 'remote' => (
    is        => 'rw',
    isa       => 'Str',
    required  => 0,
    predicate => 'has_remote',
);

#TODO Create option for adding archive

=head2 Subroutines

=cut

=head3 init_git

Create a new Git::Wrapper object

=cut

sub init_git {
    my $self = shift;

    my $git = Git::Wrapper->new( cwd() )
        or die print "Could not initialize Git::Wrapper $!\n";

    try {
        my @output = $git->rev_parse(qw(--show-toplevel));
        $self->git_dir( $output[0] );
        $git = Git::Wrapper->new( $self->git_dir );
        $self->git($git);
    }

}

sub git_info {
    my $self = shift;

    return unless $self->has_git;

    $self->branch_things;
    $self->get_version;
}

=head3 dirty_run

Check for uncommited files
#TODO add in option for autocommiting

=cut

sub dirty_run {
    my $self = shift;

    return unless $self->has_git;

    my $dirty_flag = $self->git->status->is_dirty;

    if ( $dirty_flag && !$self->autocommit ) {
        $self->app_log->warn(
            "There are uncommited files in your repo!\n\tPlease commit these files."
        );
    }
    elsif ( $dirty_flag && $self->autocommit ) {
        $self->app_log->warn(
            "There are uncommited files in your repo!\n\tWe will try to commit these files before running."
        );
        try {
            $self->git->add(qw/ -A /);
            $self->git->commit( qw/ --message "stuff" /, { all => 1 } );
            $self->app_log->info("Files were commited to git");
        }
        catch {
            $self->app_log->warn("Were not able to commit files to git");
            $self->app_log->warn("STDERR: ".$_->error);
            $self->app_log->warn("STDOUT: ".$_->output);
            $self->app_log->warn("STATUS: ".$_->status);
        }
    }
}

sub branch_things {
    my ($self) = @_;

    return unless $self->has_git;
    my $current;

    try {
        my $branches = Git::Wrapper::Plus::Branches->new( git => $self->git );

        for my $branch ( $branches->current_branch ) {
            $self->current_branch( $branch->name );
        }
    }
    catch {
        $self->current_branch('master');
    }
}

sub git_config {
    my ($self) = @_;

    return unless $self->has_git;

    #First time we run this we want the name, username, and email
    my @output = $self->git->config(qw(--list));

    my %config = ();
    foreach my $c (@output) {
        my @words = split /=/, $c;
        $config{ $words[0] } = $words[1];
    }
    return \%config;
}

sub git_logs {
    my ($self) = shift;

    return unless $self->has_git;
    my @logs = $self->git->log;
    return \@logs;
}

sub get_version {
    my ($self) = shift;

    return unless $self->has_git;
    return if $self->has_version;

    my $tags_finder = Git::Wrapper::Plus::Tags->new( git => $self->git );

    my @versions = ();
    for my $tag ( $tags_finder->tags ) {
        my $name = $tag->name;
        if ( $name =~ m/^(\d+)\.(\d+)$/ ) {
            push( @versions, $name );
        }
    }

    if ( @versions && $#versions >= 0 ) {
        my @l = sort { versioncmp( $a, $b ) } @versions;
        my $v = pop(@l);

        my $pv = next_version($v);
        $pv = "$pv";
        $self->version($pv);
    }
    else {
        $self->version("0.01");
    }

    $self->git_push_tags;
}

#TODO Make this an option
sub git_push_tags {
    my ($self) = shift;

    return unless $self->has_git;
    return unless $self->has_version;

    return if  $self->git->status->is_dirty;

    my @remote = $self->git->remote;

    $self->git->tag( $self->version );

    foreach my $remote (@remote) {
        $self->git->push( { tags => 1 }, $remote );
    }
}

sub create_release {
    my ($self) = @_;

    return unless $self->has_git;
    my @filelist = $self->git->ls_files();

    return unless @filelist;

    #make git_dir/archive if it doesn't exist
    make_path( $self->git_dir . '/hpc-runner/archive' );
    Archive::Tar->create_archive(
        $self->git_dir
            . "/hpc-runner/archive/archive" . "-"
            . $self->version . ".tgz",
        COMPRESS_GZIP, @filelist
    );
}

1;
