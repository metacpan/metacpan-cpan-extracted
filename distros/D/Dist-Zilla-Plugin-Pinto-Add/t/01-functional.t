#!perl

use strict;
use warnings;

use Test::More;
use Test::DZil;
use Test::Exception;

use IPC::Run;
use File::Path;
use File::Which;
use File::Temp;
use Dist::Zilla::Tester;

#------------------------------------------------------------------------------
# Much of this test was deduced from:
#
#  https://metacpan.org/source/RJBS/Dist-Zilla-4.300016/t/plugins/uploadtocpan.t
#
# But it isn't clear how much of the D::Z testing API is actually stable and
# public.  So I wouldn't be surpised if these tests start failing with newer
# D::Z.
#------------------------------------------------------------------------------


my $pinto_exe = File::Which::which('pinto');
plan skip_all => 'pinto (executable) required' if not $pinto_exe;

my $archive = 'DZT-Sample-0.001.tar.gz';

my $plugin = 'Pinto::Add';

#------------------------------------------------------------------------------

diag 'These tests are slow.  Be patient.';

#------------------------------------------------------------------------------

sub build_tzil {

    my $dist_ini = simple_ini('GatherDir', 'ModuleBuild', @_);

    return Builder->from_config(
        { dist_root => 'corpus/dist/DZT' },
        { add_files => {'source/dist.ini' => $dist_ini} }
    );
}

#------------------------------------------------------------------------------

sub build_repo {
    my ($class, @args) = @_;

    my $dir = File::Temp::tempdir(CLEANUP => 1);
    run_cmd($pinto_exe, -root => $dir, 'init');
    return $dir;
}

#-----------------------------------------------------------------------------

sub run_cmd {
    my @cmd = @_;

    s/^-/--/ for @cmd;

    my $input = my $output = '';
    my $timeout = IPC::Run::timeout(20);

    note "Running command: @cmd";
    my $ok = IPC::Run::run(\@cmd, $output, $output, $input, $timeout);
    diag "Command failed (@cmd): $output" if not $ok;

    return ($ok, $output);
}


#-----------------------------------------------------------------------------

local $ENV{PINTO_AUTHOR_ID}       = 'AUTHOR';
local $ENV{PINTO_USERNAME}        = undef;
local $ENV{PINTO_REPOSITORY_ROOT} = undef;

#-----------------------------------------------------------------------------

subtest "Basic release" => sub {

    my $root = build_repo;
    my $tzil = build_tzil( [$plugin => {root => $root}] );

    lives_ok { $tzil->release };

    my $log = join "\n", @{ $tzil->log_messages };
    like $log, qr/\Qadded $archive to $root\E/;
};

#-------------------------------------------------------------------------

subtest "Release to a stack" => sub {

    my $root = build_repo;
    my $stack = 'mystack';

    run_cmd($pinto_exe, -root => $root, new => $stack);
    my $tzil = build_tzil( [$plugin => {root  => $root, stack => $stack}] );

    lives_ok{ $tzil->release };

    my $log = join "\n", @{ $tzil->log_messages };
    like $log, qr/\Qadded $archive to $root\E/;
};

#-------------------------------------------------------------------------

subtest "No live repos" => sub {

    my $root = '/dev/null';
    my $tzil = build_tzil( [$plugin => {root  => $root}] );
    $tzil->chrome->set_response_for('Abort release? ', 'N');

    throws_ok{ $tzil->release }
        my $error = qr/none of your repositories are available/;

    my $log = join "\n", @{ $tzil->log_messages };
    like $log, qr/\Qchecking if repository at $root is available\E/;
    like $log, $error;
};

#-------------------------------------------------------------------------

subtest "Params from ENV" => sub {

    local $ENV{PINTO_REPOSITORY_ROOT} = 'myrepo';
    local $ENV{PINTO_USERNAME}        = 'user';

    my $tzil = build_tzil( [$plugin => {}] );
    my $p = $tzil->plugin_named($plugin);

    is $p->roots->[0], $ENV{PINTO_REPOSITORY_ROOT};
    is $p->username,  $ENV{PINTO_USERNAME};
};

#-------------------------------------------------------------------------

subtest "Params from dist.ini" => sub {

    my $tzil = build_tzil( [$plugin => { root     => 'myrepo',
                                         author   => 'ME',
                                         username => 'user',
                                         password => 'secret',
                                         recurse  => 0 }] );
    my $p = $tzil->plugin_named($plugin);

    is $p->roots->[0], 'myrepo';
    is $p->author,    'ME';
    is $p->username,  'user';
    is $p->password,  'secret';
    is $p->recurse,   0;

};

#-----------------------------------------------------------------------------

subtest "Prompt for password" => sub {

    my $user = 'someone';
    my $pass = 'secret';
    my $root = build_repo;
    my $tzil = build_tzil( [$plugin => { root         => $root,
                                         username     => $user,
                                         authenticate => 1}] );

    $tzil->chrome->set_response_for("Pinto password for $user: ", $pass);
    lives_ok{ $tzil->release };

    my $p = $tzil->plugin_named($plugin);
    is $p->password, $pass;
};

#-----------------------------------------------------------------------------

subtest "Multiple repositories" => sub {

    my ($root1, $root2) = map { build_repo() } (1,2);
    my $roots           = [ $root1, $root2 ];

    my $tzil = build_tzil( [$plugin => { root => $roots }] );

    lives_ok{ $tzil->release };

    my $log = join "\n", @{ $tzil->log_messages };
    like $log, qr/\Qadded $archive to $root1\E/;
    like $log, qr/\Qadded $archive to $root2\E/;
};

#-----------------------------------------------------------------------------

subtest "Repo not repsonding -- so abort" => sub {

    # So we don't have to wait forever...
    local $ENV{PINTO_LOCKFILE_TIMEOUT} = 5;

    my ($root1, $root2) = (build_repo, '/dev/null');
    my $roots           = [ $root1, $root2 ];

    my $tzil = build_tzil( [$plugin => { root => $roots }] );

    throws_ok { $tzil->release } my $error = qr/Aborting/;

    my $log = join "\n", @{ $tzil->log_messages };
    like   $log, qr/\Q$root2 is not available\E/;
    unlike $log, qr/\Qadded $archive to $root1\E/;
    unlike $log, qr/\Qadded $archive to $root2\E/;
    like   $log, $error;
};

#-----------------------------------------------------------------------------

subtest "Repo not responding -- partial release" => sub {

    # So we don't have to wait forever...
    local $ENV{PINTO_LOCKFILE_TIMEOUT} = 5;

    my ($root1, $root2) = (build_repo, '/dev/null');
    my $roots           = [ $root1, $root2 ];

    my $tzil = build_tzil( [$plugin => { root => $roots }] );
    $tzil->chrome->set_response_for('Abort release? ', 'N');

    lives_ok { $tzil->release };

    my $log = join "\n", @{ $tzil->log_messages };
    like   $log, qr/\Q$root2 is not available\E/;
    like   $log, qr/\Qadded $archive to $root1\E/;
    unlike $log, qr/\Qadded $archive to $root2\E/;
};

#-----------------------------------------------------------------------------

subtest "Handling of the recurse option" => sub {

    my @pinto_args;
    no warnings qw(once redefine);
    local *Dist::Zilla::Plugin::Pinto::Add::_run_pinto = sub {
        @pinto_args = @_;
        return (1, '');
    };

    subtest "Recurse param of 0 handled correctly" => sub {

        my $root = build_repo;
        my $tzil = build_tzil( [$plugin => {root => $root,
                                            recurse => 0,}] );

        lives_ok { $tzil->release };

        is(grep(/^-no-recurse$/, @pinto_args), 1,
           'recurse => 0 handled correctly');
    };
    subtest "Recurse param of 1 handled correctly" => sub {

        my $root = build_repo;
        my $tzil = build_tzil( [$plugin => {root => $root,
                                            recurse => 1,}] );

        lives_ok { $tzil->release };

        is(grep(/^-recurse$/, @pinto_args), 1,
           'recurse => 1 handled correctly');
    };
    subtest "Recurse param unspecified handled correctly" => sub {

        my $root = build_repo;
        my $tzil = build_tzil( [$plugin => {root => $root}] );

        lives_ok { $tzil->release };

        is(grep(/recurse/, @pinto_args), 0,
           'no recurse param handled correctly');
    };
};

#-----------------------------------------------------------------------------

done_testing;

#-----------------------------------------------------------------------------

# Clean up after Test::DZil
END { eval { File::Path::rmtree('tmp') } if -e 'tmp' }



