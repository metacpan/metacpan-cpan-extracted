package File::Trash::EmptyFiles::Undoable;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-03'; # DATE
our $DIST = 'File-Trash-EmptyFiles-Undoable'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Trash all empty files in the current directory tree, with undo/redo capability',
    description => <<'_',

This is the undoable version of <pm:App::FileRemoveUtils>
`delete_all_empty_files`. The CLI is <prog:trash-all-empty-files-u>.

_
};

$SPEC{trash_all_empty_files} = {
    v => 1.1,
    summary => 'Trash all empty (zero-sized) files in the current '.
        'directory tree, with undo support',
    args => {
    },
    features => {
        tx => {v=>2},
        idempotent => 1,
    },
};
sub trash_all_empty_files {
    require App::FileRemoveUtils;
    require File::Trash::Undoable;

    my %args = @_;

    my $files = App::FileRemoveUtils::list_all_empty_files();

    File::Trash::Undoable::trash_files(
        %args,
        files => $files,
    );
}

1;
# ABSTRACT: Trash all empty files in the current directory tree, with undo/redo capability

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Trash::EmptyFiles::Undoable - Trash all empty files in the current directory tree, with undo/redo capability

=head1 VERSION

This document describes version 0.001 of File::Trash::EmptyFiles::Undoable (from Perl distribution File-Trash-EmptyFiles-Undoable), released on 2020-06-03.

=head1 SYNOPSIS

 # use the trash-all-empty-files-u script

=head1 DESCRIPTION

This module provides routines to trash all empty files in the current directory
tree, with undo/redo support. Actual trashing/untrashing is provided by
L<File::Trash::Undoable>.


This is the undoable version of L<App::FileRemoveUtils>
C<delete_all_empty_files>. The CLI is L<trash-all-empty-files-u>.

=head1 FUNCTIONS


=head2 trash_all_empty_files

Usage:

 trash_all_empty_files() -> [status, msg, payload, meta]

Trash all empty (zero-sized) files in the current directory tree, with undo support.

This function is not exported.

This function is idempotent (repeated invocations with same arguments has the same effect as single invocation). This function supports transactions.


No arguments.

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

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/File-Trash-EmptyFiles-Undoable>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-File-Trash-EmptyFiles-Undoable>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=File-Trash-EmptyFiles-Undoable>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<File::Trash::Undoable> and L<trash-u>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
