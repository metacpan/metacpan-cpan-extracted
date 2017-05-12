use strict;
use warnings;
use Test::More;
use Test::Git;
use File::Temp qw( tempdir );
use File::Path;
use File::Spec;
use File::Basename;
use Git::CPAN::Hook;

has_git('1.5.1');

# a simple file installer
sub install_file {
    my ( $dir, $path, $content ) = @_;
    $path = File::Spec->catfile( $dir, split /\//, $path );
    mkpath dirname $path;
    open my $fh, '>', $path or die "Can't open $path for writing: $!";
    print $fh $content;
    close $fh;
}

plan tests => my $tests;

# setup a repository
my $dir = tempdir( CLEANUP => 1 );
init($dir);

my $r = Git::Repository->new( work_tree => $dir );
my @base = $r->run(qw( log --pretty=format:%H ));

# "install" a bunch of files
BEGIN { $tests += 2 }
install_file $dir, 'lib/Git/CPAN/Hook/Fake.pm', << 'EOF';
1;
EOF
install_file $dir, 'lib/Git/CPAN/Hook/Fake.pod', << 'EOF';
=head1 NAME

Git::CPAN::Hook::Fake

=cut
EOF

{
    local @INC = (    # pick all possible cases in @INC
        tempdir( CLEANUP => 1 ),    # a simple dir
        test_repository->work_tree, # a git repository, not hooked
        do {                        # a git repository, hooked
            my $t = test_repository;
            $t->run(qw( config --bool cpan-hook.active true ));
            $t->work_tree;
        },
        $dir,                       # a git repository, hooked, with changes
    );

    # call commit
    Git::CPAN::Hook->commit('B/BO/BOOK/Git-CPAN-Hook-Fake-0.01.tar.gz');
}

# check that a commit was created
my @logs = $r->run(qw( log --pretty=format:%H ));
is( scalar @logs, @base + 1, '1 new commit' );

# check the commit added our two files
chomp( my $diff_tree = << 'EOF' );
:000000 100644 0000000000000000000000000000000000000000 0afc6045cfe8a72a20a12683e24b4a0458ccefa7 A	lib/Git/CPAN/Hook/Fake.pm
:000000 100644 0000000000000000000000000000000000000000 b71f691cc7326f5a99e6104c7b5e0dba0f1d95d0 A	lib/Git/CPAN/Hook/Fake.pod
EOF
is( $r->run(qw( diff-tree -r HEAD^ HEAD )), $diff_tree, 'installed files' );

