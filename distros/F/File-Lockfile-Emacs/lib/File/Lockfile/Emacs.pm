package File::Lockfile::Emacs;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-03-13'; # DATE
our $DIST = 'File-Lockfile-Emacs'; # DIST
our $VERSION = '0.002'; # VERSION

our @EXPORT_OK = qw(
                       emacs_lockfile_get
                       emacs_lockfile_lock
                       emacs_lockfile_locked
                       emacs_lockfile_unlock
);

our %SPEC;

our %argspec0_target_file = (
    target_file => {
        summary => 'Target file',
        schema => 'filename*',
        req => 1,
        pos => 0,
    },
);

our %argspecopt_force = (
    force => {
        schema => 'bool*',
        cmdline_aliases => {f=>{}},
    },
);

sub _lockfile_path {
    my ($target_path) = @_;
    my $lockfile_path = $target_path;
    if ($lockfile_path =~ m!/!) {
        $lockfile_path =~ s!(.*/)(.*)!"$1#$2"!
    } else {
        $lockfile_path = ".#$target_path";
    }
    log_trace "Lockfile path: %s", $lockfile_path;
    $lockfile_path;
}

sub _read_lockfile {
    my ($target_path) = @_;

    my $lockfile_path = _lockfile_path($target_path);
    my $is_symlink = -l $lockfile_path;
    my $res = {exists=>0, path=>$lockfile_path};
    my $content;
    if ($is_symlink) {
        $res->{exists} = 1;
        $content = readlink($lockfile_path);
        if (!defined($content)) {
            $res->{error} = "Can't read link: $!";
            return $res;
        }
    } else {
        open my($fh), "<", $lockfile_path
            or do { $res->{error} = "Can't read file: $!"; return $res };
        { local $/ = undef; $content = <$fh>; close $fh }
    }
    log_trace "Lockfile content: %s", $content;
    $content =~ /\A(.+)\@(.+)\.(\d+)(?::(\d+))?\R?\z/s
        or do { $res->{error} = "Bad syntax in lock file content, does not match user\@host.pid:boot"; return $res };

    $res->{user} = $1;
    $res->{host} = $2;
    $res->{pid}  = $3;
    $res->{boot} = $4 if $4;

    $res;
}

$SPEC{emacs_lockfile_get} = {
    v => 1.1,
    summary => "Get information on an Emacs lockfile of a target file",
    args => {
        %argspec0_target_file,
    },
    description => <<'MARKDOWN',

MARKDOWN
};
sub emacs_lockfile_get {
    my %args = @_;
    defined(my $target_file = $args{target_file}) or return [400, "Please specify target_file"];

    my $lockinfo = _read_lockfile($target_file);

    return [500, $lockinfo->{error}] if $lockinfo->{error};
    [200, "OK", $lockinfo];
}

$SPEC{emacs_lockfile_lock} = {
    v => 1.1,
    summary => "Lock a file using Emacs-style lockfile",
    args => {
        %argspec0_target_file,
        %argspecopt_force,
    },
    description => <<'MARKDOWN',

Will return 412 if target file does not exist (unless `force` option is set to
true, in which case we proceed to locking anyway).

Will return 304 if target file is already locked using Emacs-style lockfile by
the same process as us.

Will return 409 if target file is already locked using Emacs-style lockfile by
another process (unless when `force` option is set to true, in which case will
take over the lock). Note that there are race conditions when using the `force`
option (between checking that the lockfile, unlinking it, and creating our own).
It is not recommended to use the `force` option.

Will return 500 if there's an error in reading the lockfile.

Will return 412 if we are not the same process that locks the file (unless
`force` option is set to true, in which case we proceed to unlocking anyway).

Will return 500 if there's an error in removing the lockfile.

Will return 200 if everything goes ok.

MARKDOWN
};
sub emacs_lockfile_lock {
    my %args = @_;
    defined(my $target_file = $args{target_file}) or return [400, "Please specify target_file"];
    my $force = $args{force};

    return [412, "Target file does not exist"] if !$force && !(-f $target_file);

    my $new_lockinfo = {
        user => $ENV{USERNAME} // $ENV{USER} // $ENV{LOGNAME},
        host => do { require Sys::Hostname; Sys::Hostname::hostname() },
        pid  => $$,
        boot => do { require Unix::Uptime; time() - Unix::Uptime->uptime },
    };
    my $lockfile_path = _lockfile_path($target_file);

  L1:

    # try creating a lock
    if (symlink "$new_lockinfo->{user}\@$new_lockinfo->{host}.$new_lockinfo->{pid}:$new_lockinfo->{boot}", $lockfile_path) {
        return [200, "Locked"];
    }

    # file is probably already locked
    my $old_lockinfo = _read_lockfile($target_file);

    return [500, "Couldn't create lockfile but lockfile doesn't exist, probably permission problem"]
        unless $old_lockinfo->{exists};

    return [500, "Can't get lockfile information: $old_lockinfo->{error}"]
        if $old_lockinfo->{error};

    if ($new_lockinfo->{pid} != $old_lockinfo->{pid}) {
        if ($force) {
            # note that there are race conditions between checking existing lock
            # above, unlinking it, and creating the new lock. Thus it's not
            # really recommended to use the `force` option.

            # unlock this old lockfile
            unlink $lockfile_path or return [500, "Can't remove old lockfile '$lockfile_path': $!"];
            goto L1;
        }

        return [412, "Target file was not locked by us (pid $$) but by pid $old_lockinfo->{pid}"];
    }

    return [304, "File was already locked"];
}

$SPEC{emacs_lockfile_locked} = {
    v => 1.1,
    summary => "Check whether a target file is locked using Emacs-style lockfile",
    args => {
        %argspec0_target_file,
        by_us => {
            summary => 'If set to true, only return true when lockfile is created by us; if false, then will only return true when lockfile is created by others',
            schema => 'bool',
        },
    },
};
sub emacs_lockfile_locked {
    my %args = @_;
    defined(my $target_file = $args{target_file}) or return [400, "Please specify target_file"];

    my $lockinfo = _read_lockfile($target_file);

    return [500, $lockinfo->{error}] if $lockinfo->{error};
    return [200, "OK", 0] unless $lockinfo->{exists};
    return [200, "OK", 1] unless defined $args{by_us};
    return [200, "OK", $args{by_us} ? ($$ == $lockinfo->{pid}) : ($$ != $lockinfo->{pid})];
}

$SPEC{emacs_lockfile_unlock} = {
    v => 1.1,
    summary => "Unlock a file locked with Emacs-style lockfile",
    args => {
        %argspec0_target_file,
        %argspecopt_force,
    },
    description => <<'MARKDOWN',

Note that there is a race condition between reading the lockfile and unlinking
it.

Will return 412 if target file does not exist (unless `force` option is set to
true, in which case we proceed to unlocking anyway).

Will return 304 if target file is not currently locked using Emacs-style
lockfile.

Will return 500 if there's an error in reading the lockfile.

Will return 412 if we are not the same process that locks the file (unless
`force` option is set to true, in which case we proceed to unlocking anyway).

Will return 500 if there's an error in removing the lockfile.

Will return 200 if everything goes ok.

MARKDOWN
};
sub emacs_lockfile_unlock {
    my %args = @_;
    defined(my $target_file = $args{target_file}) or return [400, "Please specify target_file"];
    my $force = $args{force};

    return [412, "Target file does not exist"] if !$force && !(-f $target_file);
    my $lockinfo = _read_lockfile($target_file);

    return [304, "Target file was not unlocked"] unless $lockinfo->{exists};

    return [500, $lockinfo->{error}] if $lockinfo->{error};

    return [412, "Target file was not locked by us (pid $$) but by pid $lockinfo->{pid}"]
        if !$force && ($$ != $lockinfo->{pid});

    unlink $lockinfo->{path}
        or return [500, "Can't unlink lockfile '$lockinfo->{path}': $!"];

    [200, "Unlocked"];
}

1;
# ABSTRACT: Create/check/delete Emacs-style lockfiles

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Lockfile::Emacs - Create/check/delete Emacs-style lockfiles

=head1 VERSION

This document describes version 0.002 of File::Lockfile::Emacs (from Perl distribution File-Lockfile-Emacs), released on 2025-03-13.

=head1 SYNOPSIS

 use File::Lockfile::Emacs qw(
     emacs_lockfile_lock
     emacs_lockfile_get
     emacs_lockfile_locked
     emacs_lockfile_unlock
 );

 # create an Emacs-style lockfile; return 304 status if the same process already
 # acquires the lock, returns 409 if other process is holding the lock.
 my $res = emacs_lockfile_lock(target_file => "target.txt");
 if    ($res->[0] == 200) { say "Locked" }
 elsif ($res->[0] == 304) { say "Already locked" }
 else                     { die "Can't lock target.txt: $res->[0] - $res->[1]" }

 # get information on the emacs lockfile of a file
 my $res = emacs_lockfile_get(target_file => "../target.txt");
 if    ($res->[0] != 200) { die "Can't check lockfile: $res->[0] - $res->[1]" }
 elsif ($res->[0] != 404) { die "Lockfile does not exist" }
 elsif ($res->[0] != 200) { die "Can't get: $res->[0] - $res->[1]" }
 say "user = $res->[2]{user}\nhost = $res->[2]{host}\npid = $res->[2]{pid}";
 say "boot = $res->[2]{boot}" if $res->[2]{boot};

 # check if there is an emacs lockfile to a file. return 200 status and boolean
 # value.
 my $res = check_emacs_locked(target_file => "../target.txt");
 if ($res->[0] != 200) { die "Can't check lockfile: $res->[0] - $res->[1]" }
 say "File is ".($res->[2] ? "locked" : "NOT locked").
     " by ".($res->[2]{"func.pid"} == $$ ? "us" : "pid $res->[3]{'func.pid'}");

 # unlock a file. normally will only unlock if we (the same process) holds the
 # lock.
 my $res = emacs_lockfile_unlock(target_file => "../target.txt");
 if    ($res->[0] == 304) { say "File was not locked" }
 elsif ($res->[0] == 409) { say "Won't lock, file is not locked by us" }
 elsif ($res->[0] != 200) { die "Can't unlock: $res->[0] - $res->[1]" }
 else { say "Unlocked" }

=head1 DESCRIPTION

From Emacs documentation:

  When two users edit the same file at the same time, they are likely to
  interfere with each other. Emacs tries to prevent this situation from arising
  by recording a file lock when a file is being modified. Emacs can then detect
  the first attempt to modify a buffer visiting a file that is locked by another
  Emacs job, and ask the user what to do. The file lock is really a file, a
  symbolic link with a special name, stored in the same directory as the file
  you are editing. The name is constructed by prepending .# to the file name of
  the buffer. The target of the symbolic link will be of the form
  `user@host.pid:boot`, where `user` is replaced with the current username (from
  `user-login-name`), `host` with the name of the host where Emacs is running
  (from `system-name`), `pid` with Emacs’s process id, and `boot` with the time
  since the last reboot. `:boot` is omitted if the boot time is unavailable. (On
  file systems that do not support symbolic links, a regular file is used
  instead, with contents of the form `user@host.pid:boot`.)

=head1 FUNCTIONS


=head2 emacs_lockfile_get

Usage:

 emacs_lockfile_get(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get information on an Emacs lockfile of a target file.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<target_file>* => I<filename>

Target file.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 emacs_lockfile_lock

Usage:

 emacs_lockfile_lock(%args) -> [$status_code, $reason, $payload, \%result_meta]

Lock a file using Emacs-style lockfile.

Will return 412 if target file does not exist (unless C<force> option is set to
true, in which case we proceed to locking anyway).

Will return 304 if target file is already locked using Emacs-style lockfile by
the same process as us.

Will return 409 if target file is already locked using Emacs-style lockfile by
another process (unless when C<force> option is set to true, in which case will
take over the lock). Note that there are race conditions when using the C<force>
option (between checking that the lockfile, unlinking it, and creating our own).
It is not recommended to use the C<force> option.

Will return 500 if there's an error in reading the lockfile.

Will return 412 if we are not the same process that locks the file (unless
C<force> option is set to true, in which case we proceed to unlocking anyway).

Will return 500 if there's an error in removing the lockfile.

Will return 200 if everything goes ok.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<force> => I<bool>

(No description)

=item * B<target_file>* => I<filename>

Target file.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 emacs_lockfile_locked

Usage:

 emacs_lockfile_locked(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check whether a target file is locked using Emacs-style lockfile.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<by_us> => I<bool>

If set to true, only return true when lockfile is created by us; if false, then will only return true when lockfile is created by others.

=item * B<target_file>* => I<filename>

Target file.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 emacs_lockfile_unlock

Usage:

 emacs_lockfile_unlock(%args) -> [$status_code, $reason, $payload, \%result_meta]

Unlock a file locked with Emacs-style lockfile.

Note that there is a race condition between reading the lockfile and unlinking
it.

Will return 412 if target file does not exist (unless C<force> option is set to
true, in which case we proceed to unlocking anyway).

Will return 304 if target file is not currently locked using Emacs-style
lockfile.

Will return 500 if there's an error in reading the lockfile.

Will return 412 if we are not the same process that locks the file (unless
C<force> option is set to true, in which case we proceed to unlocking anyway).

Will return 500 if there's an error in removing the lockfile.

Will return 200 if everything goes ok.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<force> => I<bool>

(No description)

=item * B<target_file>* => I<filename>

Target file.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=for Pod::Coverage ^(x)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/File-Lockfile-Emacs>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-File-Lockfile-Emacs>.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=File-Lockfile-Emacs>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
