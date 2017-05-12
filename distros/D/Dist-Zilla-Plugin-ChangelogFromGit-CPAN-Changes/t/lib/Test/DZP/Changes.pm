package Test::DZP::Changes;

use Test::Roo::Role;
use Test::DZil;
use Test::CPAN::Changes;
use Archive::Tar;
use File::chdir;
use Dist::Zilla::File::InMemory;
use Path::Tiny;

# requires 'test_repo_name';

has test_repo_name => (is => 'ro',   required => 1);
has test_repo      => (is => 'lazy');
has tzil           => (is => 'lazy', clearer  => 1);
has tzil_ini       => (is => 'rw');

sub _build_tzil {
    my $self = shift;
    my $tzil = Builder->from_config(
        {dist_root => $self->test_repo},
        {add_files => $self->tzil_ini},
    );
    $tzil->build;
    return $tzil;
}

sub _set_tzil_ini_opts {
    my $self = shift;

    my @opts = (['GatherDir' => {exclude_filename => 'Changes'}]);

    if (scalar @_ == 0) {
        push @opts, 'ChangelogFromGit::CPAN::Changes';
    } else {
        @opts = (@opts, @_);
    }

    $self->tzil_ini({'source/dist.ini' => simple_ini(@opts)});
}

sub _build_test_repo {
    my $self = shift;
    local $CWD = 't';
    diag 'Extracting test repo';
    Archive::Tar->extract_archive($self->test_repo_name . '.tar.gz');
    return path('t/' . $self->test_repo_name);
}

after teardown => sub { shift->test_repo->remove_tree({safe => 0}) };
after each_test => sub { shift->clear_tzil };

sub test_changes {
    my ($self, $expected_name) = @_;

    my $changes_file = $self->tzil->tempdir->child('build/Changes');
    changes_file_ok $changes_file;

    my $expected_file    = path "t/changes/$expected_name";
    my @expected_changes = $expected_file->lines_utf8;
    my @got_changes      = $changes_file->lines_utf8;

    # everything should match except the date
    foreach (my $i = 0 ; $i < scalar @expected_changes ; $i++) {
        if ($expected_changes[$i] =~ /^\d+\.\d{3}/) {
            like $got_changes[$i],
              qr/^\d+\.\d{3}(_\d+)? \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z?$/,
              'Matched line';
        } else {
            is $got_changes[$i], $expected_changes[$i], 'Matched line';
        }
    }
}

1;
