package File::Temp::VarOptions;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-15'; # DATE
our $DIST = 'File-Temp-VarOptions'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001; # for //
use strict 'subs', 'vars';
use warnings;
use File::Temp ();

use Exporter qw(import);
our @EXPORT_OK   = @File::Temp::EXPORT_OK;
our %EXPORT_TAGS = %File::Temp::EXPORT_TAGS;

my @our_funcs = qw(tempfile tempdir);
for my $func (@EXPORT_OK) {
    next if grep {$_ eq $func} @our_funcs;
    *{$func} = \&{"File::Temp::$func"};
}

# defaults from File/Temp.pm
our $TEMPLATE = undef;
our $DIR      = undef;
our $SUFFIX   = '';
our $UNLINK   = 0;
our $OPEN     = 1;
our $TMPDIR   = 0;
our $EXLOCK   = 0;
sub tempfile {
    my $template;
    if (@_ % 2) { $template = shift }

    File::Temp::tempfile(
        TEMPLATE => $template // $TEMPLATE,
        DIR      => $DIR,
        SUFFIX   => $SUFFIX,
        UNLINK   => $UNLINK,
        OPEN     => $OPEN,
        TMPDIR   => $TMPDIR,
        EXLOCK   => $EXLOCK,
        @_,
    );
}

# defaults from File/Temp.pm
our $CLEANUP = 0;
sub tempdir {
    my $template;
    if (@_ % 2) { $template = shift }

    File::Temp::tempdir(
        CLEANUP  => $CLEANUP,
        DIR      => $DIR,
        TMPDIR   => $TMPDIR,
        @_,
    );
}

1;
# ABSTRACT: Like File::Temp, but allowing to set options with variables

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Temp::VarOptions - Like File::Temp, but allowing to set options with variables

=head1 VERSION

This document describes version 0.001 of File::Temp::VarOptions (from Perl distribution File-Temp-VarOptions), released on 2021-04-15.

=head1 SYNOPSIS

 use File::Temp::VarOptions qw(tempfile tempdir);

 {
     local $File::Temp::VarOptions::SUFFIX = '.html';
     ($fh, $filename) = tempfile(); # use .html suffix
     ...
     ($fh, $filename) = tempfile('XXXXXXXX', SUFFIX=>''); # use empty suffix
 }
 ...
 ($fh, $filename) = tempfile(); # use empty suffi

=for Pod::Coverage ^(.+)$

=head1 EXPORTS

Same as L<File::Temp>'s.

=head1 VARIABLES

=head2 $TEMPLATE

=head2 $DIR

=head2 $SUFFIX

=head2 $UNLINK

=head2 $OPEN

=head2 $TMPDIR

=head2 $EXLOCK

=head2 $CLEANUP

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/File-Temp-VarOptions>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-File-Temp-VarOptions>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-File-Temp-VarOptions/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

A patch version of this functionality: L<File::Temp::Patch::VarOptions>

L<File::Temp>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
