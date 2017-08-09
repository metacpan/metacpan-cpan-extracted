package File::RsyBak;

our $DATE = '2017-07-31'; # DATE
our $VERSION = '0.35'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use File::chdir;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(backup);

our %SPEC;

sub _parse_path {
    require Cwd;

    my ($path) = @_;
    $path =~ s!/+$!!;
    if ($path =~ m!^(\S+)::([^/]+)/?(.*)$!) {
        return {
            raw=>$path, remote=>1, host=>$1,
            proto=>"rsync", module=>$2, path=>$3,
        };
    } elsif ($path =~ m!([^@]+)?\@?(^\S+):(.*)$!) {
        return {
            raw=>$path, remote=>1, host=>$2,
            user=>$1, proto=>"ssh", path=>$3,
        };
    } else {
        return {
            raw=>$path, remote=>0, path=>$path,
            abs_path=>Cwd::abs_path($path)
        };
    }
}

# rsync requires all source to be local, or remote (same host). check sources
# before we run rsync, so we can report the error and die earlier.
sub _check_sources {
    my ($sources) = @_;

    my $all_local = 1;
    for (@$sources) {
        if ($_->{remote}) { $all_local = 0; last }
    }

    my $all_remote = 1;
    for (@$sources) {
        if (!$_->{remote}) { $all_remote = 0; last }
    }

    return [400, "Sources must be all local or all remote"]
        unless $all_remote || $all_local;

    if ($all_remote) {
        my $host;
        for (@$sources) {
            $host //= $_->{host};
            return [400, "Remote sources must all be from the same machine"]
                if $host ne $_->{host};
        }
    }
    [200, "OK"];
}

$SPEC{backup} = {
    v             => 1.1,
    summary       =>
        'Backup files/directories with histories, using rsync',
    args          => {
        source           => {
            summary      => 'Director(y|ies) to backup',
            #schema       => ['any*'   => {
            #    of => ['str*', ['array*' => {of=>'str*'}]]
            #}],
            schema       => 'str*', # temp, because in pericmd when specifying as arg#0, there is a warning of JSON decoding failure
            req          => 1,
            pos          => 0,
        },
        target           => {
            summary      => 'Backup destination',
            schema       => ['str*'   => {}],
            req          => 1,
            pos          => 1,
        },
        histories        => {
            summary      => 'Histories/history levels',
            schema       => ['array' => {
                default      => [-7, 4, 3],
                of           => 'int*',
            }],
            description  => <<'_',

Specifies number of backup histories to keep for level 1, 2, and so on. If
number is negative, specifies number of days to keep instead (regardless of
number of histories).

_
        },
        extra_dir        => {
            summary      =>
                'Whether to force creation of source directory in target',
            schema       => ['bool'   => {}],
            description  => <<'_',

If set to 1, then backup(source => '/a', target => '/backup/a') will create
another 'a' directory in target, i.e. /backup/a/current/a. Otherwise, contents
of a/ will be directly copied under /backup/a/current/.

Will always be set to 1 if source is more than one, but default to 0 if source
is a single directory. You can set this to 1 to so that behaviour when there is
a single source is the same as behaviour when there are several sources.

_
        },
        backup           => {
            summary      => 'Whether to do backup or not',
            schema       => [bool     => {
                default      => 1,
            }],
            description  => <<'_',

If backup=1 and rotate=0 then will only create new backup without rotating
histories.

_
        },
        rotate           => {
            summary      => 'Whether to do rotate after backup or not',
            schema       => [bool     => {
                default      => 1,
            }],
            description  => <<'_',

If backup=0 and rotate=1 then will only do history rotating.

_
        },
        extra_rsync_opts => {
            summary      => 'Pass extra options to rsync command',
            schema       => [array    => {
                of           => 'str*',
            }],
            description  => <<'_',

Extra options to pass to rsync command when doing backup. Note that the options
will be shell quoted, , so you should pass it unquoted, e.g. ['--exclude',
'/Program Files'].

_
        },
    },

    examples => [
        {
            argv         => ['/home/jajang/mydata','/backup/jajang/mydata'],
            test         => 0,
            'x.doc.show_result' => 0,
            description  => <<'_',

Backup /home/jajang/mydata to /backup/jajang/mydata using the default number of
histories ([-7, 4, 3]).

_
        },
    ],

    deps => {
        all => [
            {prog => 'nice'},
            {prog => 'rsync'}, # XXX not needed if backup=0
            {prog => 'rm'},    # XXX not needed if rotate=0
        ],
    },
};
sub backup {
    require File::Flock::Retry;
    require File::Path;
    require File::Which;

    my %args = @_;

    # XXX schema
    my $source    = $args{source} or return [400, "Please specify source"];
    my @sources   = ref($source) eq 'ARRAY' ? @$source : ($source);
    for (@sources) { $_ = _parse_path($_) }
    my $res = _check_sources(\@sources);
    return $res unless $res->[0] == 200;
    my $target    = $args{target} or return [400, "Please specify target"];
    $target       = _parse_path($target);
    $target->{remote} and
        return [400, "Sorry, target can't be remote at the moment"];
    my $histories = $args{histories} // [-7, 4, 3];
    ref($histories) eq 'ARRAY' or return [400, "histories must be array"];
    my $backup    = $args{backup} // 1;
    my $rotate    = $args{rotate} // 1;
    my $extra_dir = $args{extra_dir} || (@sources > 1);

    # sanity
    my $rsync_path = File::Which::which("rsync")
        or return [500, "Can't find rsync in PATH"];

    unless (-d $target->{abs_path}) {
        log_debug("Creating target directory %s ...", $target->{abs_path});
        File::Path::make_path($target->{abs_path})
            or return [500, "Error: Can't create target directory ".
                "$target->{abs_path}: $!"];
    }

    my $lock = File::Flock::Retry->lock("$target->{abs_path}/.lock");

    if ($backup) {
        _backup(
            \@sources, $target,
            {
                extra_dir        => $extra_dir,
                extra_rsync_opts => $args{extra_rsync_opts},
            });
    }

    if ($rotate) {
        _rotate($target->{abs_path}, $histories);
    }

    [200, "OK"];
}

sub _backup {
    require POSIX;
    require String::ShellQuote; String::ShellQuote->import;

    my ($sources, $target, $opts) = @_;
    log_info("Starting backup %s ==> %s ...",
                [map {$_->{raw}} @$sources], $target);
    my $cmd;
    $cmd = join(
        "",
        "nice -n19 rsync ",
        ($opts->{extra_rsync_opts} ? map { shell_quote($_), " " }
             @{$opts->{extra_rsync_opts}} : ()),
        "-a --del --force --ignore-errors --ignore-existing ",
        (log_is_debug() ? "-v " : ""),
        ((-e "$target->{abs_path}/current") ?
             "--link-dest ".shell_quote("$target->{abs_path}/current")." "
                 : ""),
        map({ shell_quote($_->{raw}), ($opts->{extra_dir} ? "" : "/"), " " }
                @$sources),
        shell_quote("$target->{abs_path}/.tmp/"),
    );
    log_debug("Running rsync ...");
    log_trace("system(): $cmd");
    system $cmd;
    log_warn("rsync didn't succeed ($?)".
                   ", please recheck") if $?;

    # but continue anyway, half backups are better than nothing

    if (-e "$target->{abs_path}/current") {
        my $tspath = "$target->{abs_path}/.current.timestamp";
        my @st     = stat($tspath);
        my $tstamp = POSIX::strftime(
            "%Y-%m-%d\@%H:%M:%S+00",
            gmtime( $st[9] || time() )); # timestamp might not exist yet
        log_debug("rename $target->{abs_path}/current ==> ".
                        "hist.$tstamp ...");
        unless (rename "$target->{abs_path}/current",
                "$target->{abs_path}/hist.$tstamp") {
            log_warn("Failed renaming $target->{abs_path}/current ==> ".
                         "hist.$tstamp: $!");
        }
        log_debug("touch $tspath ...");
        system "touch ".shell_quote($tspath);
    }

    log_debug("rename $target->{abs_path}/.tmp ==> current ...");
    unless (rename "$target->{abs_path}/.tmp",
            "$target->{abs_path}/current") {
        log_warn("Failed renaming $target->{abs_path}/.tmp ==> current: $!");
    }

    log_info("Finished backup %s ==> %s", $sources, $target);
}

sub _rotate {
    require String::ShellQuote; String::ShellQuote->import;
    require Time::Local;

    my ($target, $histories) = @_;
    log_info("Rotating backup histories in %s (%s) ...",
                $target, $histories);

    local $CWD = $target; # throws exception when failed

    my $now = time();
    for my $level (1 .. @$histories) {
        my $is_highest_level  = $level == @$histories;
        my $prefix            = "hist" . ($level == 1 ? '' : $level);
        my $prefix_next_level = "hist" . ($level + 1);
        my $n                 = $histories->[$level - 1];
        my $moved             = 0;

        if ($n > 0) {
            log_debug("Only keeping $n level-$level histories ...");
            my @f = reverse sort grep { !/\.tmp$/ } glob "$prefix.*";
            #untaint for @f;
            my $any_tagged = (grep {/t$/} @f) ? 1 : 0;
            for my $f (@f[ $n .. @f - 1 ]) {
                my ($st, $tagged) = $f =~ /[^.]+\.(.+?)(t)?$/;
                my $f2 = "$prefix_next_level.$st";
                if (!$is_highest_level &&
                        !$moved && ($tagged || !$any_tagged)) {
                    log_debug("Moving history level: $f -> $f2");
                    rename $f, $f2;
                    $moved++;
                    if ($f ne $f[0]) {
                        rename $f[0], "$f[0]t";
                    }
                } else {
                    log_debug("Removing history: $f ...");
                    system "nice -n19 rm -rf " . shell_quote($f);
                }
            }
        } else {
            $n = -$n;
            log_debug("Only keeping $n day(s) of level-$level histories ...");
            my @f = reverse sort grep { !/\.tmp$/ } glob "$prefix.*";
            my $any_tagged = ( grep {/t$/} @f ) ? 1 : 0;
            for my $f (@f) {
                my ($st, $tagged) = $f =~ /[^.]+\.(.+?)(t)?$/;
                my $f2 = "$prefix_next_level.$st";
                my $t;
                $st =~ /(\d\d\d\d)-(\d\d)-(\d\d)\@(\d\d):(\d\d):(\d\d)\+00/;
                $t = Time::Local::timegm($6, $5, $4, $3, $2 - 1, $1) if $1;
                unless ($st && $t) {
                    log_warn("Wrong format of history, ignored: $f");
                    next;
                }
                if ($t > $now) {
                    log_warn("History in the future, ignored: $f");
                    next;
                }
                my $delta = ($now - $t) / 86400;
                if ($delta > $n) {
                    if (!$is_highest_level &&
                            !$moved && ( $tagged || !$any_tagged)) {
                        log_debug("Moving history level: $f -> $f2");
                        rename $f, $f2;
                        $moved++;
                        if ($f ne $f[0]) {
                            rename $f[0], "$f[0]t";
                        }
                    } else {
                        log_debug("Removing history: $f ...");
                        system "nice -n19 rm -rf " . shell_quote($f);
                    }
                }
            }
        }
    }
}

1;
# ABSTRACT: Backup files/directories with histories, using rsync

__END__

=pod

=encoding UTF-8

=head1 NAME

File::RsyBak - Backup files/directories with histories, using rsync

=head1 VERSION

This document describes version 0.35 of File::RsyBak (from Perl distribution File-RsyBak), released on 2017-07-31.

=head1 SYNOPSIS

From your Perl program:

 use File::RsyBak qw(backup);
 backup(
     source    => '/path/to/mydata',
     target    => '/backup/mydata',
     histories => [-7, 4, 3],         # 7 days, 4 weeks, 3 months
     extra_rsync_opts => [qw/--exclude Cache --exclude cache --exclude tmp --exclude temp/],
 );

Or, just use the provided script from the command-line:

 % rsybak --source /path/to/mydata --target /backup/mydata --extra-rsync-opts-json '["--exclude","Cache","--exclude","cache","--exclude","tmp","--exclude","temp"]'

Or, if you have this configuration in C</etc/rsybak.conf> or C<~/rsybak.conf>:

 [system]
 source = /path/to/mydata
 target = /backup/mydata
 ; also specify as JSON
 extra_rsync_opts = ["--exclude","Cache","--exclude","cache","--exclude","tmp","--exclude","temp"]

you can just run:

 % rsybak --config-profile system

Example resulting backup (after several runs so that backup history has
accumulated):

 % ls /path/to/mydata/
 myfile
 anotherfile
 mydir/

 % ls /backup/mydata/
 current/
 hist.2013-10-31@12:04:17+00/
 hist.2013-11-01@12:09:31+00/
 hist.2013-11-02@12:09:41+00t/
 hist.2013-11-03@12:15:02+00/
 hist.2013-11-04@12:13:19+00/
 hist.2013-11-05@12:11:31+00/
 hist2.2013-10-08@12:07:50+00/
 hist2.2013-10-15@12:06:03+00/
 hist2.2013-10-21@12:02:42+00/
 hist2.2013-10-27@12:06:25+00t/
 hist3.2013-06-25@12:15:39+00/
 hist3.2013-08-31@12:05:31+00/
 hist3.2013-10-02@12:05:57+00/

Each directory under C</backup/mydata> is a "snapshot" backup of
C</path/to/mydata>:

 % ls /backup/mydata/current/
 myfile
 anotherfile
 mydir/

 % ls /backup/mydata/hist.2013-10-31@12:04:17+00/
 myfile
 anotherfile
 mydir/

 % ls /backup/mydata/hist3.2013-10-02@12:05:57+00/
 myfile
 anotherfile
 mydir/
 someoldfile

=head1 DESCRIPTION

This module is basically just a wrapper around B<rsync> to create a filesystem
backup system. Some characteristics of this backup system:

=over 4

=item * Supports backup histories and history levels

For example, you can create 7 level-1 backup histories (equals 7 daily histories
if you run backup once daily), 4 level-2 backup histories (equals 4 weekly
histories) and 3 level-3 backup histories (roughly equals 3 monthly histories).
The number of levels and history per levels are customizable.

=item * Backups (and histories) are not compressed/archived ("tar"-ed)

They are just verbatim copies (produced by L<rsync -a>) of source directory. The
upside of this is ease of cherry-picking (taking/restoring individual files from
backup). The downside is lack of compression and the backup not being a single
archive file.

This is because rsync needs two real directory trees when comparing. Perhaps if
rsync supports tar virtual filesystem in the future...

=item * Hardlinks are used between backup histories to save disk space

This way, we can maintain several backup histories without wasting too much
space duplicating data when there are not a lot of differences among them.

=item * High performance

Rsync is implemented in C and has been optimized for a long time. B<rm> is also
used instead of Perl implementation File::Path::remove_path.

=item * Unix-specific

There are ports of rsync and rm on Windows, but this module hasn't been tested
on those platforms.

=back

=head1 HOW IT WORKS

=head2 First-time backup

First, we lock target directory to prevent other backup process from
interfering:

 mkdir -p TARGET
 flock    TARGET/.lock

Then we copy source to temporary directory:

 rsync    SRC            TARGET/.tmp

If copy finishes successfully, we rename temporary directory to final directory
'current':

 rename   TARGET/.tmp    TARGET/current
 touch    TARGET/.current.timestamp

If copy fails in the middle, TARGET/.tmp will still be lying around and the next
backup run will just continue the rsync process:

 rsync    SRC            TARGET/.tmp

Finally, we remove lock:

 unlock   TARGET/.lock

=head2 Subsequent backups (after TARGET/current exists)

First, we lock target directory to prevent other backup process to interfere:

 flock    TARGET/.lock

Then we rsync source to target directory (using --link-dest=TARGET/current):

 rsync    SRC            TARGET/.tmp

If rsync finishes successfully, we rename target directories:

 rename   TARGET/current TARGET/hist.<timestamp>
 rename   TARGET/.tmp    TARGET/current
 touch    TARGET/.current.timestamp

If rsync fails in the middle, TARGET/.tmp will be lying around and the next
backup run will just continue the rsync process.

Finally, we remove lock:

 unlock   TARGET/.lock

=head2 Maintenance of histories/history levels

TARGET/hist.* are level-1 backup histories. Each backup run will produce a new
history:

 TARGET/hist.<timestamp1>
 TARGET/hist.<timestamp2> # produced by the next backup
 TARGET/hist.<timestamp3> # and the next ...
 TARGET/hist.<timestamp4> # and so on ...
 TARGET/hist.<timestamp5>
 ...

You can specify the number of histories (or number of days) to maintain. If the
number of histories exceeds the limit, older histories will be deleted, or one
will be promoted to the next level, if a higher level is specified.

For example, with B<histories> being set to [7, 4, 3], after
TARGET/hist.<timestamp8> is created, TARGET/hist.<timestamp1> will be promoted
to level 2:

 rename TARGET/hist.<timestamp1> TARGET/hist2.<timestamp1>

TARGET/hist2.* directories are level-2 backup histories. After a while, they
will also accumulate:

 TARGET/hist2.<timestamp1>
 TARGET/hist2.<timestamp8>
 TARGET/hist2.<timestamp15>
 TARGET/hist2.<timestamp22>

When TARGET/hist2.<timestamp29> arrives, TARGET/hist2.<timestamp1> will be
promoted to level 3: TARGET/hist3.<timestamp1>. After a while, level-3 backup
histories too will accumulate:

 TARGET/hist3.<timestamp1>
 TARGET/hist3.<timestamp29>
 TARGET/hist3.<timestamp57>

Finally, TARGET/hist3.<timestamp1> will be deleted after
TARGET/hist3.<timestamp85> comes along.

=head1 FUNCTIONS


=head2 backup

Usage:

 backup(%args) -> [status, msg, result, meta]

Backup files/directories with histories, using rsync.

Examples:

=over

=item * Example #1:

 backup( source => "/home/jajang/mydata", target => "/backup/jajang/mydata");

Backup /home/jajang/mydata to /backup/jajang/mydata using the default number of
histories ([-7, 4, 3]).

=back

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<backup> => I<bool> (default: 1)

Whether to do backup or not.

If backup=1 and rotate=0 then will only create new backup without rotating
histories.

=item * B<extra_dir> => I<bool>

Whether to force creation of source directory in target.

If set to 1, then backup(source => '/a', target => '/backup/a') will create
another 'a' directory in target, i.e. /backup/a/current/a. Otherwise, contents
of a/ will be directly copied under /backup/a/current/.

Will always be set to 1 if source is more than one, but default to 0 if source
is a single directory. You can set this to 1 to so that behaviour when there is
a single source is the same as behaviour when there are several sources.

=item * B<extra_rsync_opts> => I<array[str]>

Pass extra options to rsync command.

Extra options to pass to rsync command when doing backup. Note that the options
will be shell quoted, , so you should pass it unquoted, e.g. ['--exclude',
'/Program Files'].

=item * B<histories> => I<array[int]> (default: [-7,4,3])

Histories/history levels.

Specifies number of backup histories to keep for level 1, 2, and so on. If
number is negative, specifies number of days to keep instead (regardless of
number of histories).

=item * B<rotate> => I<bool> (default: 1)

Whether to do rotate after backup or not.

If backup=0 and rotate=1 then will only do history rotating.

=item * B<source>* => I<str>

Director(y|ies) to backup.

=item * B<target>* => I<str>

Backup destination.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 FAQ

=head2 How do I exclude some directories?

Just use rsync's --exclude et al. Pass them to extra_rsync_opts.

=head2 What is a good backup practice (using RsyBak)?

Just follow the general practice. While this is not a place to discuss backups
in general, some of the principles are:

=over 4

=item * backup regularly (e.g. once daily or more often)

=item * automate the process (else you'll forget)

=item * backup to another disk partition and computer

=item * verify your backups often (what good are they if they can't be restored)

=item * make sure your backup is secure (encrypted, correct permission, etc)

=back

=head2 How do I restore backups?

Backups are just verbatim copies of files/directories, so just use whatever
filesystem tools you like.

=head2 How to do remote backup?

From your backup host:

 [BAK-HOST]% rsybak --source USER@SRC-HOST:/path --dest /backup/dir

Or alternatively, you can backup on SRC-HOST locally first, then send the
resulting backup to BAK-HOST.

=head1 HISTORY

The idea for this module came out in 2006 as part of the Spanel hosting control
panel project. We need a daily backup system for shared hosting accounts that
supports histories and cherry-picking. Previously we had been using a
Python-based script B<rdiff-backup>. It was not very robust, the script chose to
exit on many kinds of non-fatal errors instead of ignoring the errors and
continuning backup. It was also very slow: on a server with hundreds of accounts
with millions of files, backup process often took 12 hours or more. After
evaluating several other solutions, we realized that nothing beats the raw
performance of rsync. Thus we designed a simple backup system based on it.

First public release of this module is in Feb 2011. I have since used this
script in various production servers as well as personal PCs/laptops.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/File-RsyBak>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-File-RsyBak>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=File-RsyBak>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<File::Backup>

L<File::Rotate::Backup>

L<Snapback2>, which is a backup system using the same basic principle (rsync
snapshots), created in as early as 2004 (or earlier) by Mike Heins. Do check it
out. I wish I had found it first before reinventing it in 2006 :-)

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015, 2014, 2013, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
