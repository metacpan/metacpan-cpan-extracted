package File::Append::Undoable;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.05'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use File::Trash::Undoable;
use File::Copy;

our %SPEC;

$SPEC{append} = {
    v           => 1.1,
    summary     => 'Append string to a file, with undo support',
    description => <<'_',

On do, will trash file, copy it to original location (with the same permission
and ownership as the original) and append the string to the end of file. On undo
will trash the new file and untrash the original.

Some notes:

* Chown will not be done if we are not running as root.

* Symlink is currently not permitted.

* Since transaction requires the function to be idempotent, in the `check_state`
  phase the function will check if the string has been appended. It will refuse
  to append the same string twice.

* Take care not to use string that are too large, as the string, being a
  function parameter, is entered into the transaction table.

Fixed state: file exists and string has been appended to end of file.

Fixable state: file exists and string has not been appended to end of file.

Unfixable state: file does not exist or path is not a regular file (directory
and symlink included).

_
    args        => {
        path => {
            summary => 'The file to append',
            schema  => 'str*',
            req     => 1,
            pos     => 0,
        },
        string => {
            summary => 'The string to append to file',
            req     => 1,
            pos     => 1,
        },
    },
    features => {
        tx => {v=>2},
        idempotent => 1,
    },
};
sub append {
    my %args = @_;

    # TMP, schema
    my $tx_action  = $args{-tx_action} // '';
    my $taid       = $args{-tx_action_id}
        or return [400, "Please specify -tx_action_id"];
    my $dry_run    = $args{-dry_run};
    my $path       = $args{path};
    defined($path) or return [400, "Please specify path"];
    defined($args{string}) or return [400, "Please specify string"];
    my $string     = "$args{string}";

    my $is_sym  = (-l $path);
    my @st      = stat($path);
    my $exists  = $is_sym || (-e _);
    my $is_file = (-f _);
    my $size    = (-s _);

    if ($tx_action eq 'check_state') {
        return [412, "File $path does not exist"]        unless $exists;
        return [412, "File $path is not a regular file"] if $is_sym||!$is_file;
        return [500, "File $path can't be stat'd"]       unless @st;

        if ($size >= length($string)) {
            my $buf;
            open my($fh),"<",$path or return [500, "Can't open file $path: $!"];
            seek $fh, $size-length($string), 0;
            read $fh, $buf, length($string);
            if (defined($buf) && $buf eq $string) {
                return [304, "File $path already appended with string, ".
                            "won't append twice"];
            }
        }
        log_info("(DRY) Appending string to file $path ...") if $dry_run;
        return [200, "File $path needs to be appended with a string", undef,
                {undo_actions=>[
                    ['File::Trash::Undoable::untrash', # restore original
                     {path=>$path, suffix=>substr($taid,0,8)}],
                    ['File::Trash::Undoable::trash', # trash new file
                     {path=>$path, suffix=>substr($taid,0,8)."n"}],
                ]}];
    } elsif ($tx_action eq 'fix_state') {
        log_info("Appending string to file $path ...");
        my $res = File::Trash::Undoable::trash(
            -tx_action=>'fix_state', path=>$path, suffix=>substr($taid,0,8));
        return $res unless $res->[0] == 200 || $res->[0] == 304;
        copy $res->[2], $path
            or return [500, "Can't copy from $res->[2]: $!"];
        open my($fh), ">>", $path or return [500, "Can't open for append: $!"];
        print $fh $string;
        close $fh or return [500, "Can't close: $!"];
        chmod $st[2] & 07777, $path; # XXX ignore error?
        unless ($>) { chown $st[4], $st[5], $path } # XXX ignore error?
        return [200, "OK"];
    }
    [400, "Invalid -tx_action"];
}

1;
# ABSTRACT: Append string to a file, with undo support

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Append::Undoable - Append string to a file, with undo support

=head1 VERSION

This document describes version 0.05 of File::Append::Undoable (from Perl distribution File-Append-Undoable), released on 2017-07-10.

=head1 FUNCTIONS


=head2 append

Usage:

 append(%args) -> [status, msg, result, meta]

Append string to a file, with undo support.

On do, will trash file, copy it to original location (with the same permission
and ownership as the original) and append the string to the end of file. On undo
will trash the new file and untrash the original.

Some notes:

=over

=item * Chown will not be done if we are not running as root.

=item * Symlink is currently not permitted.

=item * Since transaction requires the function to be idempotent, in the C<check_state>
phase the function will check if the string has been appended. It will refuse
to append the same string twice.

=item * Take care not to use string that are too large, as the string, being a
function parameter, is entered into the transaction table.

=back

Fixed state: file exists and string has been appended to end of file.

Fixable state: file exists and string has not been appended to end of file.

Unfixable state: file does not exist or path is not a regular file (directory
and symlink included).

This function is not exported.

This function is idempotent (repeated invocations with same arguments has the same effect as single invocation). This function supports transactions.


Arguments ('*' denotes required arguments):

=over 4

=item * B<path>* => I<str>

The file to append.

=item * B<string>* => I<any>

The string to append to file.

=back

Special arguments:

=over 4

=item * B<-tx_action> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_action_id> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_recovery> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_rollback> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_v> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/File-Append-Undoable>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-File-Append-Undoable>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=File-Append-Undoable>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Rinci::Transaction>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015, 2014, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
