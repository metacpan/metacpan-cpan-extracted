package File::Util::Tempdir;

our $DATE = '2018-09-20'; # DATE
our $VERSION = '0.033'; # VERSION

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(get_tempdir get_user_tempdir);

sub get_tempdir {
    if ($^O eq 'MSWin32') {
        for (qw/TMP TEMP TMPDIR TEMPDIR/) {
            return $ENV{$_} if defined $ENV{$_};
        }
        for ("C:\\TMP", "C:\\TEMP") {
            return $_ if -d;
        }
    } else {
        for (qw/TMPDIR TEMPDIR TMP TEMP/) {
            return $ENV{$_} if defined $ENV{$_};
        }
        for ("/tmp", "/var/tmp") {
            return $_ if -d;
        }
    }
    die "Can't find any temporary directory";
}

sub get_user_tempdir {
    if ($^O eq 'MSWin32') {
        return get_tempdir();
    } else {
        my $dir = $ENV{XDG_RUNTIME_DIR} ?
            $ENV{XDG_RUNTIME_DIR} : get_tempdir();
        my @st = stat($dir);
        die "Can't stat tempdir '$dir': $!" unless @st;
        return $dir if $st[4] == $> && !($st[2] & 022);
        my $i = 0;
        while (1) {
            my $subdir = "$dir/$>" . ($i ? ".$i" : "");
            my @stsub = stat($subdir);
            my $is_dir = -d _;
            if (!@stsub) {
                mkdir $subdir, 0700 or die "Can't mkdir '$subdir': $!";
                return $subdir;
            } elsif ($is_dir && $stsub[4] == $> && !($stsub[2] & 022)) {
                return $subdir;
            } else {
                $i++;
            }
        }
    }
}

1;
# ABSTRACT: Cross-platform way to get system-wide & user private temporary directory

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Util::Tempdir - Cross-platform way to get system-wide & user private temporary directory

=head1 VERSION

This document describes version 0.033 of File::Util::Tempdir (from Perl distribution File-Util-Tempdir), released on 2018-09-20.

=head1 SYNOPSIS

 use File::Util::Tempdir qw(get_tempdir get_user_tempdir);

 my $tmpdir = get_tempdir(); # => e.g. "/tmp"

 my $mytmpdir = get_tempdir(); # => e.g. "/run/user/1000", or "/tmp/1000"

=head1 DESCRIPTION

=head1 FUNCTIONS

None are exported by default, but they are exportable.

=head2 get_tempdir

Usage:

 my $dir = get_tempdir();

A cross-platform way to get system-wide temporary directory.

On Windows: it first looks for one of these environment variables in this order
and return the first value that is set: C<TMP>, C<TEMP>, C<TMPDIR>, C<TEMPDIR>.
If none are set, will look at these directories in this order and return the
first value that is set: C<C:\TMP>, C<C:\TEMP>. If none are set, will die.

On Unix: it first looks for one of these environment variables in this order and
return the first value that is set: C<TMPDIR>, C<TEMPDIR>, C<TMP>, C<TEMP>. If
none are set, will look at these directories in this order and return the first
value that is set: C</tmp>, C</var/tmp>. If none are set, will die.

=head2 get_user_tempdir

Usage:

 my $dir = get_user_tempdir();

Get user's private temporary directory.

When you use world-writable temporary directory like F</tmp>, you usually need
to create randomly named temporary files, such as those created by
L<File::Temp>. If you try to create a temporary file with guessable name, other
users can intercept this and you can either: 1) fail to create/write your
temporary file; 2) be tricked to read malicious data; 3) be tricked to write to
other location (e.g. via symlink).

This routine is like L</"get_tempdir"> except: on Unix, it will look for
C<XDG_RUNTIME_DIR> first (which on a Linux system with systemd will have value
like C</run/user/1000> which points to a RAM-based tmpfs). Also,
C<get_user_tempdir> will first check that the temporary directory is: 1) owned
by the running user; 2) not group- and world-writable. If not, it will create a
subdirectory named C<$EUID> (C<< $> >>) with permission mode 0700 and return
that. If that subdirectory already exists and is not owned by the user or is
group-/world-writable, will try C<$EUID.1> and so on.

It will die on failure.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/File-Util-Tempdir>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-File-Util-Tempdir>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=File-Util-Tempdir>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<File::Spec> has C<tmpdir> function. It also tries to look at environment
variables, e.g. on Unix it will look at C<TMPDIR> (but not C<TEMPDIR>) and
then falls back to C</tmp> (but not C</var/tmp>).

L<File::HomeDir>, a cross-platform way to get user's home directory and a few
other related directories.

L<File::Temp> to create a temporary directory.

L<https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html>
for the specification of C<XDG_RUNTIME_DIR>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
