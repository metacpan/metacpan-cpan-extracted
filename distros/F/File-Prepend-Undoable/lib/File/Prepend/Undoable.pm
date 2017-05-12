package File::Prepend::Undoable;

our $DATE = '2015-09-03'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

use File::Trash::Undoable;

our %SPEC;

$SPEC{prepend} = {
    v           => 1.1,
    summary     => 'Prepend string to a file, with undo support',
    description => <<'_',

On do, will trash file, copy it to original location (with the same permission
and ownership as the original) and prepend the string to the beginning of file.
On undo will trash the new file and untrash the original.

Some notes:

* Chown will not be done if we are not running as root.

* Symlink is currently not permitted.

* Since transaction requires the function to be idempotent, in the `check_state`
  phase the function will check if the string has been prepended. It will refuse
  to prepend the same string twice.

* Take care not to use string that are too large, as the string, being a
  function parameter, is entered into the transaction table.

Fixed state: file exists and string has been prepended to beginning of file.

Fixable state: file exists and string has not been prepended to beginning of
file.

Unfixable state: file does not exist or path is not a regular file (directory
and symlink included).

_
    args        => {
        path => {
            summary => 'The file to prepend',
            schema  => 'str*',
            req     => 1,
            pos     => 0,
        },
        string => {
            summary => 'The string to prepend to file',
            req     => 1,
            pos     => 1,
        },
    },
    features => {
        tx => {v=>2},
        idempotent => 1,
    },
};
sub prepend {
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
            read $fh, $buf, length($string);
            if (defined($buf) && $buf eq $string) {
                return [304, "File $path already prepended with string, ".
                            "won't prepend twice"];
            }
        }
        $log->info("(DRY) Prepending string to file $path ...") if $dry_run;
        return [200, "File $path needs to be prepended with a string", undef,
                {undo_actions=>[
                    ['File::Trash::Undoable::untrash', # restore original
                     {path=>$path, suffix=>substr($taid,0,8)}],
                    ['File::Trash::Undoable::trash', # trash new file
                     {path=>$path, suffix=>substr($taid,0,8)."n"}],
                ]}];
    } elsif ($tx_action eq 'fix_state') {
        $log->info("Prepending string to file $path ...");
        my $res = File::Trash::Undoable::trash(
            -tx_action=>'fix_state', path=>$path, suffix=>substr($taid,0,8));
        return $res unless $res->[0] == 200 || $res->[0] == 304;
        open my($oh), "<", $res->[2]
            or return [500, "Can't open $res->[2] for reading: $!"];
        open my($nh), ">", $path
            or return [500, "Can't open $path for writing: $!"];
        print $nh $string;
        while (my $l = <$oh>) { print $nh $l }
        close $nh or return [500, "Can't close: $!"];
        chmod $st[2] & 07777, $path; # XXX ignore error?
        unless ($>) { chown $st[4], $st[5], $path } # XXX ignore error?
        return [200, "OK"];
    }
    [400, "Invalid -tx_action"];
}

1;
# ABSTRACT: Prepend string to a file, with undo support

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Prepend::Undoable - Prepend string to a file, with undo support

=head1 VERSION

This document describes version 0.04 of File::Prepend::Undoable (from Perl distribution File-Prepend-Undoable), released on 2015-09-03.

=head1 SEE ALSO

L<Rinci::Transaction>

=head1 FUNCTIONS


=head2 prepend(%args) -> [status, msg, result, meta]

Prepend string to a file, with undo support.

On do, will trash file, copy it to original location (with the same permission
and ownership as the original) and prepend the string to the beginning of file.
On undo will trash the new file and untrash the original.

Some notes:

=over

=item * Chown will not be done if we are not running as root.

=item * Symlink is currently not permitted.

=item * Since transaction requires the function to be idempotent, in the C<check_state>
phase the function will check if the string has been prepended. It will refuse
to prepend the same string twice.

=item * Take care not to use string that are too large, as the string, being a
function parameter, is entered into the transaction table.

=back

Fixed state: file exists and string has been prepended to beginning of file.

Fixable state: file exists and string has not been prepended to beginning of
file.

Unfixable state: file does not exist or path is not a regular file (directory
and symlink included).

This function is idempotent (repeated invocations with same arguments has the same effect as single invocation). This function supports transactions.


Arguments ('*' denotes required arguments):

=over 4

=item * B<path>* => I<str>

The file to prepend.

=item * B<string>* => I<any>

The string to prepend to file.

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

Please visit the project's homepage at L<https://metacpan.org/release/File-Prepend-Undoable>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-File-Prepend-Undoable>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=File-Prepend-Undoable>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
