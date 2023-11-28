package File::Util::DirList;

use strict;
use warnings;
use Log::ger;

use Exporter qw(import);
use Perinci::Object;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-15'; # DATE
our $DIST = 'File-Util-DirList'; # DIST
our $VERSION = '0.001'; # VERSION

our @EXPORT_OK = qw(
                       mv_files_to_dirs
               );
# cp_files_to_dirs
# ln_files_to_dirs

our %SPEC;

our %argspecs_common = (
    files_then_dirs => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'file_or_dir',
        summary => 'One or more existing file (or directory) names then the same number of existing directories',
        schema => ['array*', of=>'pathname::exists*', min_len=>2],
        req => 1,
        pos => 0,
        slurpy => 1,
    },
);

sub _cp_or_mv_or_ln_files_to_dirs {
    my $action = shift;
    my %args = @_;

    my ($files_then_dirs, $half_size);
  CHECK_ARGUMENTS: {
        $files_then_dirs = $args{files_then_dirs} or return [400, "Please specify files_then_dirs"];
        (ref $files_then_dirs eq 'ARRAY') && (@$files_then_dirs >= 2) && (@$files_then_dirs % 2 == 0)
            or return [400, "files_then_dirs must be array of even number of elements, minimum 2"];
        $half_size = @$files_then_dirs / 2;
        for my $i ($half_size .. $#{$files_then_dirs}) {
            -d $files_then_dirs->[$i] or return [400, "files_then_dirs[$i] not a directory"];
        }
    }

    my $envres = envresmulti();

    require File::Copy::Recursive;

  FILE:
    for my $i (0 .. $half_size-1) {
        my $file = $files_then_dirs->[$i];
        my $dir  = $files_then_dirs->[$i+$half_size];

        if ($action eq 'mv') {
            if ($args{-dry_run}) {
                log_info "[DRY_RUN] [#%d/%d] Moving %s to dir %s ...", $i+1, scalar(@$files_then_dirs), $file, $dir;
                $envres->add_result(200, "OK (dry-run)", {item_id=>$file});
            } else {
                log_info "[#%d/%d] Moving %s to dir %s ...", $i+1, scalar(@$files_then_dirs), $file, $dir;
                my $ok = File::Copy::Recursive::rmove($file, $dir);
                if ($ok) {
                    $envres->add_result(200, "OK", {item_id=>$file});
                } else {
                    log_error "Can't move %s to dir %s: %s", $file, $dir, $!;
                    $envres->add_result(500, "Error: $!", {item_id=>$file});
                }
            }
        } else {
            return [501, "Action unknown or not yet implemented"];
        }
    }

    $envres->as_struct;
}

$SPEC{mv_files_to_dirs} = {
    v => 1.1,
    summary => 'Move files to directories, one file to each directory',
    args => {
        %argspecs_common,
    },
    features => {
        dry_run => 1,
    },
    examples => [
        {
            summary => 'Move f1 to d1, f2 to d2, f3 to d3',
            argv => [qw/f1 f2 f3 d1 d2 d3/],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub mv_files_to_dirs {
    _cp_or_mv_or_ln_files_to_dirs('mv', @_);
}

1;
# ABSTRACT: File utilities involving a list of directories

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Util::DirList - File utilities involving a list of directories

=head1 VERSION

This document describes version 0.001 of File::Util::DirList (from Perl distribution File-Util-DirList), released on 2023-11-15.

=head1 FUNCTIONS


=head2 mv_files_to_dirs

Usage:

 mv_files_to_dirs(%args) -> [$status_code, $reason, $payload, \%result_meta]

Move files to directories, one file to each directory.

Examples:

=over

=item * Move f1 to d1, f2 to d2, f3 to d3:

 mv_files_to_dirs(files_then_dirs => ["f1", "f2", "f3", "d1", "d2", "d3"]);

=back

This function is not exported by default, but exportable.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<files_then_dirs>* => I<array[pathname::exists]>

One or more existing file (or directory) names then the same number of existing directories.


=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=E<gt>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/File-Util-DirList>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-File-Util-DirList>.

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=File-Util-DirList>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
