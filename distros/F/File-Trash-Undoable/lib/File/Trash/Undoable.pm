package File::Trash::Undoable;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use File::Util::Test qw(l_abs_path);
use File::Trash::FreeDesktop;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-21'; # DATE
our $DIST = 'File-Trash-Undoable'; # DIST
our $VERSION = '0.231'; # VERSION

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Trash files, with undo/redo capability',
};

my $trash = File::Trash::FreeDesktop->new;

$SPEC{trash} = {
    v           => 1.1,
    name        => 'trash',
    summary     => 'Trash a file',
    args        => {
        path => {
            schema => 'str*',
            req => 1,
        },
        suffix => {
            schema => 'str',
        },
    },
    description => <<'_',

Fixed state: path does not exist.

Fixable state: path exists.

_
    features => {
        tx => {v=>2},
        idempotent => 1,
    },
};
sub trash {
    my %args = @_;

    # TMP, SCHEMA
    my $tx_action = $args{-tx_action} // "";
    my $dry_run   = $args{-dry_run};
    my $path      = $args{path};
    defined($path) or return [400, "Please specify path"];
    my $suffix    = $args{suffix};

    my @st     = lstat($path);
    my $exists = (-l _) || (-e _);

    my (@do, @undo);

    if (defined $suffix) {
        if ($tx_action eq 'check_state') {
            if ($exists) {
                unshift @undo, [__PACKAGE__."::untrash" => {path=>$path, suffix=>$suffix}];
            }
            if (@undo) {
                log_info("(DRY) Trashing $path ...") if $dry_run;
                return [200, "File/dir $path should be trashed",
                        undef, {undo_actions=>\@undo}];
            } else {
                return [304, "File/dir $path already does not exist"];
            }
        } elsif ($tx_action eq 'fix_state') {
            log_info("Trashing $path ...");
            my $tfile;
            eval { $tfile = $trash->trash({suffix=>$suffix}, $path) };
            return $@ ? [500, "trash() failed: $@"] : [200, "OK", $tfile];
        }
        return [400, "Invalid -tx_action"];
    } else {
        my $taid = $args{-tx_action_id}
            or return [412, "Please specify -tx_action_id"];
        $suffix = substr($taid, 0, 8);
        if ($exists) {
            push    @do  , [__PACKAGE__."::trash"   => {path=>$path, suffix=>$suffix}];
            unshift @undo, [__PACKAGE__."::untrash" => {path=>$path, suffix=>$suffix}];
        }
        if (@undo) {
            log_info("(DRY) Trashing $path (suffix $suffix) ...") if $dry_run;
            return [200, "", undef, {do_actions=>\@do, undo_actions=>\@undo}];
        } else {
            return [304, "File/dir $path already does not exist"];
        }
    }
}

$SPEC{untrash} = {
    v           => 1.1,
    summary     => 'Untrash a file',
    description => <<'_',

Fixed state: path exists.

Fixable state: Path does not exist (and exists in trash, and if suffix is
specified, has the same suffix).

_
    args        => {
        path => {
            schema => 'str*',
            req => 1,
        },
        suffix => {
            schema => 'str',
        },
    },
    features => {
        tx => {v=>2},
        idempotent => 1,
    },
};
sub untrash {
    my %args = @_;

    # TMP, SCHEMA
    my $tx_action = $args{-tx_action} // "";
    my $dry_run   = $args{-dry_run};
    my $path0     = $args{path};
    defined($path0) or return [400, "Please specify path"];
    my $suffix    = $args{suffix};

    my $apath     = l_abs_path($path0);
    my @st        = lstat($apath);
    my $exists    = (-l _) || (-e _);

    if ($tx_action eq 'check_state') {

        my @undo;
        return [304, "Path $path0 already exists"] if $exists;

        my @res = $trash->list_contents({
            search_path=>$apath, suffix=>$suffix});
        return [412, "File/dir $path0 does not exist in trash"] unless @res;
        unshift @undo, [__PACKAGE__."::trash" => {path => $apath, suffix=>$suffix}];
        log_info("(DRY) Untrashing $path0 ...") if $dry_run;
        return [200, "File/dir $path0 should be untrashed",
                undef, {undo_actions=>\@undo}];

    } elsif ($tx_action eq 'fix_state') {
        log_info("Untrashing $path0 ...");
        eval { $trash->recover({suffix=>$suffix}, $apath) };
        return $@ ? [500, "untrash() failed: $@"] : [200, "OK"];
    }
    [400, "Invalid -tx_action"];
}

$SPEC{trash_files} = {
    v          => 1.1,
    summary    => 'Trash files (with undo support)',
    args       => {
        files => {
            summary => 'Files/dirs to delete',
            description => <<'_',

Files must exist.

_
            schema => ['array*' => {of=>'str*'}],
            req => 1,
            pos => 0,
            greedy => 1,
        },
    },
    features => {
        tx => {v=>2},
        idempotent => 1,
    },
};
sub trash_files {
    my %args = @_;

    # TMP, SCHEMA
    my $dry_run = $args{-dry_run};
    my $ff      = $args{files};
    $ff or return [400, "Please specify files"];
    ref($ff) eq 'ARRAY' or return [400, "Files must be array"];
    @$ff > 0 or return [400, "Please specify at least 1 file"];

    my (@do, @undo);
    for (@$ff) {
        my @st = lstat($_) or return [400, "Can't stat $_: $!"];
        (-l _) || (-e _) or return [400, "File does not exist: $_"];
        my $orig = $_;
        $_ = l_abs_path($_);
        $_ or return [400, "Can't convert to absolute path: $orig"];
        log_info("(DRY) Trashing %s ...", $orig) if $dry_run;
        push    @do  , [__PACKAGE__."::trash"   => {path=>$_}];
        unshift @undo, [__PACKAGE__."::untrash" => {path=>$_, mtime=>$st[9]}];
    }

    return [200, "", undef, {do_actions=>\@do, undo_actions=>\@undo}];
}

$SPEC{list_trash_contents} = {
    v => 1.1,
    summary => 'List contents of trash directory',
};
sub list_trash_contents {
    my %args = @_;
    [200, "OK", [$trash->list_contents]];
}

$SPEC{empty_trash} = {
    v => 1.1,
    summary => 'Empty trash',
};
sub empty_trash {
    my %args = @_;
    my $cmd  = $args{-cmdline};

    $trash->empty;
    if ($cmd) {
        $cmd->run_clear_history;
    } else {
        [200, "OK"];
    }
}

1;
# ABSTRACT: Trash files, with undo/redo capability

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Trash::Undoable - Trash files, with undo/redo capability

=head1 VERSION

This document describes version 0.231 of File::Trash::Undoable (from Perl distribution File-Trash-Undoable), released on 2023-11-21.

=head1 SYNOPSIS

 # use the trash-u script

=head1 DESCRIPTION

This module provides routines to trash files, with undo/redo support. Actual
trashing/untrashing is provided by L<File::Trash::FreeDesktop>.

Screenshots:

=head1 FUNCTIONS


=head2 empty_trash

Usage:

 empty_trash() -> [$status_code, $reason, $payload, \%result_meta]

Empty trash.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 list_trash_contents

Usage:

 list_trash_contents() -> [$status_code, $reason, $payload, \%result_meta]

List contents of trash directory.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 trash

Usage:

 trash(%args) -> [$status_code, $reason, $payload, \%result_meta]

Trash a file.

Fixed state: path does not exist.

Fixable state: path exists.

This function is not exported.

This function is idempotent (repeated invocations with same arguments has the same effect as single invocation). This function supports transactions.


Arguments ('*' denotes required arguments):

=over 4

=item * B<path>* => I<str>

(No description)

=item * B<suffix> => I<str>

(No description)


=back

Special arguments:

=over 4

=item * B<-tx_action> => I<str>

For more information on transaction, see LE<lt>Rinci::TransactionE<gt>.

=item * B<-tx_action_id> => I<str>

For more information on transaction, see LE<lt>Rinci::TransactionE<gt>.

=item * B<-tx_recovery> => I<str>

For more information on transaction, see LE<lt>Rinci::TransactionE<gt>.

=item * B<-tx_rollback> => I<str>

For more information on transaction, see LE<lt>Rinci::TransactionE<gt>.

=item * B<-tx_v> => I<str>

For more information on transaction, see LE<lt>Rinci::TransactionE<gt>.

=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 trash_files

Usage:

 trash_files(%args) -> [$status_code, $reason, $payload, \%result_meta]

Trash files (with undo support).

This function is not exported.

This function is idempotent (repeated invocations with same arguments has the same effect as single invocation). This function supports transactions.


Arguments ('*' denotes required arguments):

=over 4

=item * B<files>* => I<array[str]>

FilesE<sol>dirs to delete.

Files must exist.


=back

Special arguments:

=over 4

=item * B<-tx_action> => I<str>

For more information on transaction, see LE<lt>Rinci::TransactionE<gt>.

=item * B<-tx_action_id> => I<str>

For more information on transaction, see LE<lt>Rinci::TransactionE<gt>.

=item * B<-tx_recovery> => I<str>

For more information on transaction, see LE<lt>Rinci::TransactionE<gt>.

=item * B<-tx_rollback> => I<str>

For more information on transaction, see LE<lt>Rinci::TransactionE<gt>.

=item * B<-tx_v> => I<str>

For more information on transaction, see LE<lt>Rinci::TransactionE<gt>.

=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 untrash

Usage:

 untrash(%args) -> [$status_code, $reason, $payload, \%result_meta]

Untrash a file.

Fixed state: path exists.

Fixable state: Path does not exist (and exists in trash, and if suffix is
specified, has the same suffix).

This function is not exported.

This function is idempotent (repeated invocations with same arguments has the same effect as single invocation). This function supports transactions.


Arguments ('*' denotes required arguments):

=over 4

=item * B<path>* => I<str>

(No description)

=item * B<suffix> => I<str>

(No description)


=back

Special arguments:

=over 4

=item * B<-tx_action> => I<str>

For more information on transaction, see LE<lt>Rinci::TransactionE<gt>.

=item * B<-tx_action_id> => I<str>

For more information on transaction, see LE<lt>Rinci::TransactionE<gt>.

=item * B<-tx_recovery> => I<str>

For more information on transaction, see LE<lt>Rinci::TransactionE<gt>.

=item * B<-tx_rollback> => I<str>

For more information on transaction, see LE<lt>Rinci::TransactionE<gt>.

=item * B<-tx_v> => I<str>

For more information on transaction, see LE<lt>Rinci::TransactionE<gt>.

=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=for HTML <p><img src="http://blogs.perl.org/users/perlancar/screenshot-trashu.jpg" /><br />

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/File-Trash-Undoable>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-File-Trash-Undoable>.

=head1 SEE ALSO

=over 4

=item * B<gvfs-trash>

A command-line utility, part of the GNOME project.

=item * B<trash-cli>, https://github.com/andreafrancia/trash-cli

A Python-based command-line application. Also follows freedesktop.org trash
specification.

=item * B<rmv>, http://code.google.com/p/rmv/

A bash script. Features undo ("rollback"). At the time of this writing, does not
support per-filesystem trash (everything goes into home trash).

=back

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <stevenharyanto@gmail.com>

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

This software is copyright (c) 2023, 2020, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=File-Trash-Undoable>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
