package Filename::Executable;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-16'; # DATE
our $DIST = 'Filename-Executable'; # DIST
our $VERSION = '0.002'; # VERSION

our @EXPORT_OK = qw(check_executable_filename);

our %TYPES = (
    'perl script'   => [qw/.pl/],
    'php script'    => [qw/.php/],
    'python script' => [qw/.py/],
    'ruby script'   => [qw/.rb/],
    'shell script'  => [qw/.sh .bash/],
    'shell archive' => [qw/.shar/],
    'dos program'   => [qw/.exe .com .bat/],
    'appimage'      => [qw/.appimage/],
);
our %EXTS = map { my $type = $_; map {($_=> $type)} @{ $TYPES{$type} } } keys %TYPES;
our $RE_STR  = join("|", sort {length($b) <=> length($a) || $a cmp $b} keys %EXTS);
our $RE_NOCI = qr/\A(.+)($RE_STR)\z/;
our $RE_CI   = qr/\A(.+)($RE_STR)\z/i;

our %SPEC;

$SPEC{check_executable_filename} = {
    v => 1.1,
    summary => 'Check whether filename indicates being an executable program/script',
    description => <<'_',


_
    args => {
        filename => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        # XXX recurse?
        ignore_case => {
            summary => 'Whether to match case-insensitively',
            schema  => 'bool*',
            default => 1,
            cmdline_aliases => {i=>{}},
        },
    },
    result_naked => 1,
    result => {
        schema => ['any*', of=>['bool*', 'hash*']],
        description => <<'_',

Return false if no archive suffixes detected. Otherwise return a hash of
information, which contains these keys: `exec_type`, `exec_ext`,
`exec_name`.

_
    },
    examples => [
        {
            args => {filename => 'foo.pm'},
            naked_result => 0,
        },
        {
            args => {filename => 'foo.appimage'},
            naked_result => {exec_name=>'foo', exec_type=>'appimage', exec_ext=>'.appimage'},
        },
        {
            summary => 'Case-insensitive by default',
            args => {filename => 'foo.Appimage'},
            naked_result => {exec_name=>'foo', exec_type=>'appimage', exec_ext=>'.Appimage'},
        },
        {
            summary => 'Case-sensitive',
            args => {filename => 'foo.Appimage', ignore_case=>0},
            naked_result => 0,
        },
    ],
};
sub check_executable_filename {
    my %args = @_;

    my $filename = $args{filename};
    my $ci = $args{ignore_case} // 1;

    #use DD; dd \%EXTS;
    my ($name, $ext) = $filename =~ ($ci ? $RE_CI : $RE_NOCI)
        or return 0;
    return {
        exec_name => $name,
        exec_ext  => $ext,
        exec_type => $EXTS{lc $ext},
    };
}

1;
# ABSTRACT: Check whether filename indicates being an executable program/script

__END__

=pod

=encoding UTF-8

=head1 NAME

Filename::Executable - Check whether filename indicates being an executable program/script

=head1 VERSION

This document describes version 0.002 of Filename::Executable (from Perl distribution Filename-Executable), released on 2023-12-16.

=head1 SYNOPSIS

 use Filename::Executable qw(check_executable_filename);
 my $res = check_executable_filename(filename => "foo.sh");
 if ($res) {
     printf "File is an executable (type: %s, ext: %s)\n",
         $res->{exec_type},
         $res->{exec_ext};
 } else {
     print "File is not an executable\n";
 }

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 check_executable_filename

Usage:

 check_executable_filename(%args) -> bool|hash

Check whether filename indicates being an executable programE<sol>script.

Examples:

=over

=item * Example #1:

 check_executable_filename(filename => "foo.pm"); # -> 0

=item * Example #2:

 check_executable_filename(filename => "foo.appimage");

Result:

 { exec_ext => ".appimage", exec_name => "foo", exec_type => "appimage" }

=item * Case-insensitive by default:

 check_executable_filename(filename => "foo.Appimage");

Result:

 { exec_ext => ".Appimage", exec_name => "foo", exec_type => "appimage" }

=item * Case-sensitive:

 check_executable_filename(filename => "foo.Appimage", ignore_case => 0); # -> 0

=back

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filename>* => I<str>

(No description)

=item * B<ignore_case> => I<bool> (default: 1)

Whether to match case-insensitively.


=back

Return value:  (bool|hash)


Return false if no archive suffixes detected. Otherwise return a hash of
information, which contains these keys: C<exec_type>, C<exec_ext>,
C<exec_name>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Filename-Executable>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Filename-Executable>.

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Filename-Executable>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
