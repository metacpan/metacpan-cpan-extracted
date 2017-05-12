package Getopt::Long::Subcommand::Util;

our $DATE = '2016-10-27'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
                       detect_getopt_long_script
               );

our %SPEC;

$SPEC{detect_getopt_long_subcommand_script} = {
    v => 1.1,
    summary => 'Detect whether a file is a Getopt::Long::Subcommand-based CLI script',
    description => <<'_',

The criteria are:

* the file must exist and readable;

* (optional, if `include_noexec` is false) file must have its executable mode
  bit set;

* content must start with a shebang C<#!>;

* either: must be perl script (shebang line contains 'perl') and must contain
  something like `use Getopt::Long::Subcommand`;

_
    args => {
        filename => {
            summary => 'Path to file to be checked',
            schema => 'str*',
            cmdline_aliases => {f=>{}},
            pos => 0,
        },
        string => {
            summary => 'Path to file to be checked',
            schema => 'buf*',
            description => <<'_',

Either `file` or `string` must be specified.

_
        },
        include_noexec => {
            summary => 'Include scripts that do not have +x mode bit set',
            schema  => 'bool*',
            default => 1,
        },
    },
    args_rels => {
        req_one => ['filename', 'string'],
    },
};
sub detect_getopt_long_subcommand_script {
    my %args = @_;

    (defined($args{filename}) xor defined($args{string}))
        or return [400, "Please specify either filename or string"];
    my $include_noexec  = $args{include_noexec}  // 1;

    my $yesno = 0;
    my $reason = "";
    my %extrameta;

    my $str = $args{string};
  DETECT:
    {
        if (defined $args{filename}) {
            my $fn = $args{filename};
            unless (-f $fn) {
                $reason = "'$fn' is not a file";
                last;
            };
            if (!$include_noexec && !(-x _)) {
                $reason = "'$fn' is not an executable";
                last;
            }
            my $fh;
            unless (open $fh, "<", $fn) {
                $reason = "Can't be read";
                last;
            }
            # for efficiency, we read a bit only here
            read $fh, $str, 2;
            unless ($str eq '#!') {
                $reason = "Does not start with a shebang (#!) sequence";
                last;
            }
            my $shebang = <$fh>;
            unless ($shebang =~ /perl/) {
                $reason = "Does not have 'perl' in the shebang line";
                last;
            }
            seek $fh, 0, 0;
            {
                local $/;
                $str = <$fh>;
            }
        }
        unless ($str =~ /\A#!/) {
            $reason = "Does not start with a shebang (#!) sequence";
            last;
        }
        unless ($str =~ /\A#!.*perl/) {
            $reason = "Does not have 'perl' in the shebang line";
            last;
        }
        if ($str =~ /^\s*(use|require)\s+(Getopt::Long::Subcommand)(\s|;)/m) {
            $yesno = 1;
            $extrameta{'func.module'} = $2;
            last DETECT;
        }
        $reason = "Can't find any statement requiring Getopt::Long::Subcommand module";
    } # DETECT

    [200, "OK", $yesno, {"func.reason"=>$reason, %extrameta}];
}

# ABSTRACT: Utilities for Getopt::Long::Subcommand

__END__

=pod

=encoding UTF-8

=head1 NAME

Getopt::Long::Subcommand::Util - Utilities for Getopt::Long::Subcommand

=head1 VERSION

This document describes version 0.002 of Getopt::Long::Subcommand::Util (from Perl distribution Getopt-Long-Subcommand-Util), released on 2016-10-27.

=head1 FUNCTIONS


=head2 detect_getopt_long_subcommand_script(%args) -> [status, msg, result, meta]

Detect whether a file is a Getopt::Long::Subcommand-based CLI script.

The criteria are:

=over

=item * the file must exist and readable;

=item * (optional, if C<include_noexec> is false) file must have its executable mode
bit set;

=item * content must start with a shebang C<#!>;

=item * either: must be perl script (shebang line contains 'perl') and must contain
something like C<use Getopt::Long::Subcommand>;

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filename> => I<str>

Path to file to be checked.

=item * B<include_noexec> => I<bool> (default: 1)

Include scripts that do not have +x mode bit set.

=item * B<string> => I<buf>

Path to file to be checked.

Either C<file> or C<string> must be specified.

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

Please visit the project's homepage at L<https://metacpan.org/release/Getopt-Long-Subcommand-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Getopt-Long-Subcommand-Util>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Getopt-Long-Subcommand-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Getopt::Long::Subcommand>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
