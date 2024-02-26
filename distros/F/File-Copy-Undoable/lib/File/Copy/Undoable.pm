package File::Copy::Undoable;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use File::Trash::Undoable;
use File::Util::Test qw(file_exists);
use IPC::System::Options 'system', -log=>1;
#use PerlX::Maybe;
use Proc::ChildError qw(explain_child_error);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-21'; # DATE
our $DIST = 'File-Copy-Undoable'; # DIST
our $VERSION = '0.130'; # VERSION

our %SPEC;

$SPEC{cp} = {
    v           => 1.1,
    summary     => 'Copy file/directory using rsync, with undo support',
    description => <<'_',

On do, will copy `source` to `target` (which must not exist beforehand). On
undo, will trash `target`.

Fixed state: `source` exists and `target` exists. Content or sizes are not
checked; only existence.

Fixable state: `source` exists and `target` doesn't exist.

Unfixable state: `source` does not exist.

_
    args        => {
        source => {
            schema => 'str*',
            req    => 1,
            pos    => 0,
        },
        target => {
            schema => 'str*',
            summary => 'Target location',
            description => <<'_',

Note that to avoid ambiguity, you must specify full location instead of just
directory name. For example: cp(source=>'/dir', target=>'/a') will copy /dir to
/a and cp(source=>'/dir', target=>'/a/dir') will copy /dir to /a/dir.

_
            req    => 1,
            pos    => 1,
        },
        target_owner => {
            schema => 'str*',
            summary => 'Set ownership of target',
            description => <<'_',

If set, will do a `chmod -Rh` on the target after rsync to set ownership. This
usually requires super-user privileges. An example of this is copying files on
behalf of user from a source that is inaccessible by the user (e.g. a system
backup location). Or, setting up user's home directory when creating a user.

Will do nothing if not running as super-user.

_
        },
        target_group => {
            schema => 'str*',
            summary => 'Set group of target',
            description => <<'_',

See `target_owner`.

_
        },
        rsync_opts => {
            schema => [array => {of=>'str*', default=>['-a']}],
            summary => 'Rsync options',
            description => <<'_',

By default, `-a` is used. You can add, for example, `--delete` or other rsync
options.

_
        },
    },
    features => {
        tx => {v=>2},
        idempotent => 1,
    },
    deps => {
        prog => 'rsync',
    },
};
sub cp {
    my %args = @_;

    # TMP, schema
    my $tx_action  = $args{-tx_action} // '';
    my $dry_run    = $args{-dry_run};
    my $source     = $args{source};
    defined($source) or return [400, "Please specify source"];
    my $target     = $args{target};
    defined($target) or return [400, "Please specify target"];
    my $rsync_opts = $args{rsync_opts} // ['-a'];
    $rsync_opts = [$rsync_opts] unless ref($rsync_opts) eq 'ARRAY';

    if ($tx_action eq 'check_state') {
        return [412, "Source $source does not exist"]
            unless file_exists($source);
        my $te = file_exists($target);
        unless ($args{-tx_recovery} || $args{-tx_rollback}) {
            # in rollback/recovery, we might need to continue interrupted
            # transfer, so we allow target to exist
            return [304, "Target $target already exists"] if $te;
        }
        log_info("(DRY) ".
                       ($te ? "Syncing" : "Copying")." $source -> $target ...")
            if $dry_run;
        return [200, "$source needs to be ".($te ? "synced":"copied").
                    " to $target", undef, {undo_actions=>[
                        ["File::Trash::Undoable::trash" => {path=>$target}],
                    ]}];

    } elsif ($tx_action eq 'fix_state') {
        my @cmd = ("rsync", @$rsync_opts, "$source/", "$target/");
        log_info("Rsync-ing $source -> $target ...");
        system @cmd;
        return [500, "Can't rsync: ".explain_child_error($?)] if $?;
        if (defined($args{target_owner}) || defined($args{target_group})) {
            if ($> == 0) {
                log_info("Chown-ing $target ...");
                @cmd = (
                    "chown", "-Rh",
                    join("", $args{target_owner}//"", ":",
                         $args{target_group}//""),
                    $target);
                system @cmd;
                return [500, "Can't chown: ".explain_child_error($?)] if $?;
            } else {
                log_debug("Not running as root, not doing chown");
            }
        }
        return [200, "OK"];
    }
    [400, "Invalid -tx_action"];
}

1;
# ABSTRACT: Copy file/directory using rsync, with undo support

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Copy::Undoable - Copy file/directory using rsync, with undo support

=head1 VERSION

This document describes version 0.130 of File::Copy::Undoable (from Perl distribution File-Copy-Undoable), released on 2023-11-21.

=head1 FUNCTIONS


=head2 cp

Usage:

 cp(%args) -> [$status_code, $reason, $payload, \%result_meta]

Copy fileE<sol>directory using rsync, with undo support.

On do, will copy C<source> to C<target> (which must not exist beforehand). On
undo, will trash C<target>.

Fixed state: C<source> exists and C<target> exists. Content or sizes are not
checked; only existence.

Fixable state: C<source> exists and C<target> doesn't exist.

Unfixable state: C<source> does not exist.

This function is not exported.

This function is idempotent (repeated invocations with same arguments has the same effect as single invocation). This function supports transactions.


Arguments ('*' denotes required arguments):

=over 4

=item * B<rsync_opts> => I<array[str]> (default: ["-a"])

Rsync options.

By default, C<-a> is used. You can add, for example, C<--delete> or other rsync
options.

=item * B<source>* => I<str>

(No description)

=item * B<target>* => I<str>

Target location.

Note that to avoid ambiguity, you must specify full location instead of just
directory name. For example: cp(source=>'/dir', target=>'/a') will copy /dir to
/a and cp(source=>'/dir', target=>'/a/dir') will copy /dir to /a/dir.

=item * B<target_group> => I<str>

Set group of target.

See C<target_owner>.

=item * B<target_owner> => I<str>

Set ownership of target.

If set, will do a C<chmod -Rh> on the target after rsync to set ownership. This
usually requires super-user privileges. An example of this is copying files on
behalf of user from a source that is inaccessible by the user (e.g. a system
backup location). Or, setting up user's home directory when creating a user.

Will do nothing if not running as super-user.


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

=head1 FAQ

=head2 Why do you use rsync? Why not, say, File::Copy::Recursive?

With C<rsync>, we can continue interrupted transfer. We need this ability for
recovery. Also, C<rsync> can handle hardlinks and preservation of ownership,
something which L<File::Copy::Recursive> currently does not do. And, being
implemented in C, it might be faster when processing large files/trees.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/File-Copy-Undoable>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-File-Copy-Undoable>.

=head1 SEE ALSO

L<Setup>

L<Rinci::Transaction>

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

This software is copyright (c) 2023, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=File-Copy-Undoable>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
