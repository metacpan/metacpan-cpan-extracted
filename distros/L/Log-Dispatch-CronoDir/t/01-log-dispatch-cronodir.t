use strict;
use warnings;
use File::Spec;
use File::Temp qw(tempdir);
use Log::Dispatch::CronoDir;
use Scope::Guard;
use Test::Exception;
use Test::Mock::Guard;
use Test::More;

my $class = 'Log::Dispatch::CronoDir';

sub slurp_file {
    my ($file, %opt) = @_;
    local $/ = undef;
    open my $fh, '<', $file
        or die "Failed opening file $file: $!";
    binmode $fh, $opt{binmode} if $opt{binmode};
    <$fh>;
}

subtest 'Test instance' => sub {

    subtest 'Fails with insufficient params' => sub {
        dies_ok {
            $class->new(

                # Log::Dispatch::Output
                name      => 'foobar',
                min_level => 'debug',
                newline   => 1,

                # Log::Dispatch::CronoDir
                filename => 'test.log',
                )
        }
        'Missing dirname_pattern';

        dies_ok {
            $class->new(

                # Log::Dispatch::Output
                name      => 'foobar',
                min_level => 'debug',
                newline   => 1,

                # Log::Dispatch::CronoDir
                dirname_pattern => '/var/log/tmp/%Y/%m/%d',
                )
        }
        'Missing filename';
    };

    subtest 'Succeeds with valid params' => sub {
        my $dir = tempdir(CLEANUP => 1);
        my $log = $class->new(

            # Log::Dispatch::Output
            name      => 'foobar',
            min_level => 'debug',
            newline   => 1,

            # Log::Dispatch::CronoDir
            dirname_pattern => File::Spec->catdir($dir, qw( %Y %m %d )),
            filename        => 'test.log',
        );
        my ($sec, $min, $hour, $mday, $mon, $year) = localtime;
        my $output_dir = File::Spec->catdir(
            $dir,
            $year + 1900,
            sprintf('%02d', $mon + 1),
            sprintf('%02d', $mday)
        );

        isa_ok $log, 'Log::Dispatch::CronoDir';

        subtest 'Output dir is created' => sub {
            ok -d $output_dir;
        };
    };
};

subtest 'Test log_message' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $log = Log::Dispatch::CronoDir->new(

        # Log::Dispatch::Output
        name      => 'foobar',
        min_level => 'debug',
        newline   => 1,

        # Log::Dispatch::CronoDir
        dirname_pattern => File::Spec->catdir($dir, qw( %Y %m %d )),
        filename        => 'test.log',
    );

    subtest 'Write to current directory' => sub {
        lives_ok {
            $log->log_message(level => 'error', message => 'Test1');
        };

        my ($sec, $min, $hour, $mday, $mon, $year) = localtime;
        my $output_file = File::Spec->catfile(
            $dir,
            $year + 1900,
            sprintf('%02d', $mon + 1),
            sprintf('%02d', $mday), 'test.log'
        );

        ok -f $output_file;

        my $content = slurp_file($output_file);

        is $content, "Test1";
    };

    subtest 'Write to 2000-01-01 directory' => sub {
        my $guard = mock_guard($class => { _localtime => sub { (0, 0, 0, 1, 0, 100) }, });

        lives_ok {
            $log->log_message(level => 'error', message => 'Test2');
        };

        my $output_file = File::Spec->catfile($dir, qw(2000 01 01), 'test.log');

        ok -f $output_file;

        my $content = slurp_file($output_file);

        is $content, "Test2";
    };
};

SKIP: {

    skip "Directory permissions are always 0777 on Windows OS, and thus not testable"
        if $^O eq 'MSWin32';

    subtest 'Test permissions option' => sub {
        my $guard = mock_guard($class => { _localtime => sub { (0, 0, 0, 1, 0, 100) }, });

        subtest 'permissions => 0777' => sub {
            my $dir = tempdir(CLEANUP => 1);
            my $log = Log::Dispatch::CronoDir->new(

                # Log::Dispatch::Output
                name      => 'foobar',
                min_level => 'debug',
                newline   => 1,

                # Log::Dispatch::CronoDir
                dirname_pattern => File::Spec->catdir($dir, qw( %Y %m %d )),
                permissions     => 0777,
                filename        => 'test.log',
            );
            my $dirmode = (stat(File::Spec->catdir($dir, qw(2000 01 01))))[2];

            is sprintf("%04o", $dirmode & 0777), '0777';
        };

        subtest 'permissions => none' => sub {
            my $umask = umask;
            my $scope_guard = Scope::Guard->new(
                sub {
                    umask $umask;
                }
            );

            subtest 'When umask is 002' => sub {

                umask 002;

                my $dir = tempdir(CLEANUP => 1);
                my $log = Log::Dispatch::CronoDir->new(

                    # Log::Dispatch::Output
                    name      => 'foobar',
                    min_level => 'debug',
                    newline   => 1,

                    # Log::Dispatch::CronoDir
                    dirname_pattern => File::Spec->catdir($dir, qw( %Y %m %d )),
                    filename        => 'test.log',
                );
                my $dirmode = (stat(File::Spec->catdir($dir, qw(2000 01 01))))[2];

                is sprintf('%04o', $dirmode & 0777), '0775';
            };

            subtest 'When umask is 022' => sub {

                umask 022;

                my $dir = tempdir(CLEANUP => 1);
                my $log = Log::Dispatch::CronoDir->new(

                    # Log::Dispatch::Output
                    name      => 'foobar',
                    min_level => 'debug',
                    newline   => 1,

                    # Log::Dispatch::CronoDir
                    dirname_pattern => File::Spec->catdir($dir, qw( %Y %m %d )),
                    filename        => 'test.log',
                );
                my $dirmode = (stat(File::Spec->catdir($dir, qw(2000 01 01))))[2];

                is sprintf('%04o', $dirmode & 0777), '0755';
            };
        };
    };
}

subtest 'Test binmode option' => sub {
    my $guard = mock_guard($class => { _localtime => sub { (0, 0, 0, 1, 0, 100) }, });

    subtest 'Multi-byte logging with binmode => ":utf8"' => sub {
        use utf8;

        my $dir = tempdir(CLEANUP => 1);
        my $log = Log::Dispatch::CronoDir->new(

            # Log::Dispatch::Output
            name      => 'foobar',
            min_level => 'debug',
            newline   => 1,

            # Log::Dispatch::CronoDir
            dirname_pattern => File::Spec->catdir($dir, qw( %Y %m %d )),
            filename        => 'test.log',
            binmode         => ':utf8',
        );

        lives_ok {
            $log->log_message(level => 'error', message => 'あいうえお');
        };

        my $output_file = File::Spec->catfile($dir, qw(2000 01 01), 'test.log');

        my $content = slurp_file($output_file, binmode => ':utf8');

        is $content, "あいうえお";
    };

    subtest 'Multi-byte logging without binmode => ":utf8"' => sub {
        my $dir = tempdir(CLEANUP => 1);
        my $log = Log::Dispatch::CronoDir->new(

            # Log::Dispatch::Output
            name      => 'foobar',
            min_level => 'debug',
            newline   => 1,

            # Log::Dispatch::CronoDir
            dirname_pattern => File::Spec->catdir($dir, qw( %Y %m %d )),
            filename        => 'test.log',
        );

        lives_ok {
            $log->log_message(level => 'error', message => 'あいうえお');
        };

        my $output_file = File::Spec->catfile($dir, qw(2000 01 01), 'test.log');

        my $content = slurp_file($output_file);

        is $content, "あいうえお";
    };
};

done_testing;
