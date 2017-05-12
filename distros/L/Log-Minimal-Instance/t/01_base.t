use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Output;
use File::Temp ();

use Log::Minimal::Instance;

my @levels = qw/crit warn info croak/;

sub _tempfile {
    my (undef, $fname) = File::Temp::tempfile;
    $fname;
}

sub _tempdir {
    my $dir = File::Temp::tempdir(CLEANUP => 1);
}

subtest 'instance' => sub {
    my $log = Log::Minimal::Instance->new;
    isa_ok $log, 'Log::Minimal::Instance';

    for my $level (@levels) {
        for my $suffix (qw/f ff d/) {
            my $method = $level.$suffix;
            can_ok $log, $method;
        }
    }
};

subtest 'log to file' => sub {
    my $fname = _tempfile();
    my $log   = Log::Minimal::Instance->new(pattern => $fname);
    my $body  = 'file';

    for my $level (@levels) {
        my $method = $level.'f';
        if ($level eq 'croak') {
            dies_ok { $log->$method($body) } "died at level:$level";
        } else {
            $log->$method($body);
        }
    }

    open my $fh, '<', $fname or die $!;
    for my $level (@levels) {
        next if ($level eq 'croak');
        like(scalar <$fh>, qr/\[$level.*\] .*$body at/i, "level:$level");
    }
    close $fh;
};

subtest 'log to stderr' => sub {
    my $log  = Log::Minimal::Instance->new;
    my $body = 'stderr';
    for my $level (@levels) {
        my $method = $level.'f';
        if ($level eq 'croak') {
            dies_ok { $log->$method($body) } "died at level:$level";
        } else {
            stderr_like { $log->$method($body) }
                qr/\[$level.*\] .*$body.* at/i, "level: $level";
        }
    }
};

subtest 'log_to' => sub {
    my $fname1 = _tempfile();
    my $fname2 = _tempfile();

    my $log = Log::Minimal::Instance->new(pattern => $fname1);
    $log->infof('default file 1st');
    $log->log_to($fname2, 'specified file 1st'); my $log_to_line1 = __LINE__;
    $log->infof('default file 2nd');
    $log->log_to($fname2, 'specified file 2nd'); my $log_to_line2 = __LINE__;

    open my $fh1, '<', $fname1 or die $!;
    like(scalar <$fh1>, qr/\[INFO] .*default file 1st/i, "default 1st");
    like(scalar <$fh1>, qr/\[INFO] .*default file 2nd/i, "default 2nd");
    close $fh1;

    open my $fh2, '<', $fname2 or die $!;
    like(scalar <$fh2>, qr/.*specified file 1st at .*$log_to_line1/i, "specified 1st");
    like(scalar <$fh2>, qr/.*specified file 2nd at .*$log_to_line2/i, "specified 2nd");
    close $fh2;
};

subtest 'File::Stamped options' => sub {
    my $fname = _tempfile();
    my $log   = Log::Minimal::Instance->new(
        pattern           => $fname,
        iomode            => '>>:encoding(euc-jp)',
        autoflush         => 0,
        close_after_write => 0,
        rotationtime      => 86400 * 30,
    );
    my $fh = $log->{_fh};

    is *$fh->{iomode}, '>>:encoding(euc-jp)';
    is *$fh->{autoflush}, 0;
    is *$fh->{close_after_write}, 0;
    is *$fh->{rotationtime}, 86400 * 30;
};

subtest 'log_to with File::Stamped options' => sub {
    my $fname = _tempfile();
    my $log   = Log::Minimal::Instance->new(
        pattern           => $fname,
        iomode            => '>>:encoding(euc-jp)',
        autoflush         => 0,
        close_after_write => 0,
        rotationtime      => 86400 * 30,
    );

    no warnings 'redefine';
    local *Log::Minimal::Instance::critf = sub {
        my ($self, @args) = @_;
        my $fh = $self->{_fh};
        is *$fh->{iomode}, '>>:encoding(euc-jp)';
        is *$fh->{autoflush}, 0;
        is *$fh->{close_after_write}, 0;
        is *$fh->{rotationtime}, 86400 * 30;
    };

    $log->log_to($fname, 'foobar');
};

subtest 'with symlink' => sub {
    my $fname   = _tempfile();
    my $symlink = "$fname.symlink";

    my $log = Log::Minimal::Instance->new(
        pattern => $fname,
        symlink => $symlink,
    );

    $log->infof('foo');
    open my $fh, '<', $fname;
    like scalar <$fh>, qr/\[INFO] .*foo/;

    open my $sfh, '<', $symlink;
    like scalar <$sfh>, qr/\[INFO] .*foo/;
};

subtest 'with symlink and base_dir' => sub {
    my $base_dir = _tempdir();
    my $fname    = "pattern";
    my $symlink  = "symlink";

    my $log = Log::Minimal::Instance->new(
        pattern  => $fname,
        symlink  => $symlink,
        base_dir => $base_dir,
    );

    $log->infof('foo');
    open my $fh, '<', "$base_dir/$fname";
    like scalar <$fh>, qr/\[INFO] .*foo/;

    open my $sfh, '<', "$base_dir/$symlink";
    like scalar <$sfh>, qr/\[INFO] .*foo/;
};

subtest 'log to with symlink (array)' => sub {
    my $fname   = _tempfile();
    my $symlink = "$fname.symlink";

    my $log = Log::Minimal::Instance->new;
    $log->log_to([ $fname, $symlink ], 'bar');

    open my $fh, '<', $fname;
    like scalar <$fh>, qr/ bar/;

    open my $sfh, '<', $symlink;
    like scalar <$sfh>, qr/ bar/;
};

subtest 'log to with symlink (array)' => sub {
    my $fname   = _tempfile();
    my $symlink = "$fname.symlink";

    my $log = Log::Minimal::Instance->new;
    $log->log_to([ $fname, $symlink ], 'bar');

    open my $fh, '<', $fname;
    like scalar <$fh>, qr/ bar/;

    open my $sfh, '<', $symlink;
    like scalar <$sfh>, qr/ bar/;
};

subtest 'log to with symlink (array) and base_dir' => sub {
    my $base_dir = _tempdir();
    my $fname    = "pattern";
    my $symlink  = "symlink";

    my $log = Log::Minimal::Instance->new(base_dir => $base_dir);
    $log->log_to([ $fname, $symlink ], 'bar');

    open my $fh, '<', "$base_dir/$fname";
    like scalar <$fh>, qr/ bar/;

    open my $sfh, '<', "$base_dir/$symlink";
    like scalar <$sfh>, qr/ bar/;
};

subtest 'log to with symlink (hash)' => sub {
    my $fname   = _tempfile();
    my $symlink = "$fname.symlink";

    my $log = Log::Minimal::Instance->new;
    $log->log_to({ pattern => $fname, symlink => $symlink }, 'baz');

    open my $fh, '<', $fname;
    like scalar <$fh>, qr/ baz/;

    open my $sfh, '<', $symlink;
    like scalar <$sfh>, qr/ baz/;
};

subtest 'log to with symlink (hash) and overwrite base_dir' => sub {
    my $base_dir     = _tempdir();
    my $new_base_dir = _tempdir();
    my $fname        = "pattern";
    my $symlink      = "symlink";

    my $log = Log::Minimal::Instance->new(base_dir => $base_dir);
    $log->log_to({
        pattern  => $fname,
        symlink  => $symlink,
        base_dir => $new_base_dir,
    }, 'baz');

    open my $fh, '<', "$new_base_dir/$fname";
    like scalar <$fh>, qr/ baz/;

    open my $sfh, '<', "$new_base_dir/$symlink";
    like scalar <$sfh>, qr/ baz/;
};

done_testing;
