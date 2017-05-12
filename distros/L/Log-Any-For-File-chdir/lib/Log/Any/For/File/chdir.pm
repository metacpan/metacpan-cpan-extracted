package Log::Any::For::File::chdir;

our $DATE = '2016-06-14'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any '$log';

use File::chdir ();
use Monkey::Patch::Action qw(patch_package);

our $h = patch_package(
    'File::chdir::SCALAR',
    '_chdir',
    'wrap',
    sub {
        my $ctx = shift;
        $log->tracef("[File::chdir] chdir(%s)", $_[0]);
        $ctx->{orig}->(@_);
    },
);

1;
# ABSTRACT: Add logging to File::chdir

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::For::File::chdir - Add logging to File::chdir

=head1 VERSION

This document describes version 0.001 of Log::Any::For::File::chdir (from Perl distribution Log-Any-For-File-chdir), released on 2016-06-14.

=head1 SYNOPSIS

 use Log::Any::For::File::chdir;
 use File::chdir;

 $CWD = "foo";
 ...
 $CWD = "bar";
 ...

Now everytime C<$CWD> is set, the directory name will be logged. To see the log
messages at the screen, use this for example:

 % TRACE=1 perl -MLog::Any::Adapter=Screen -MLog::Any::For::File::chdir -MFile::chdir -e'$CWD = "foo"; ...'
 [File::chdir] chdir(foo)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Log-Any-For-File-chdir>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Log-Any-For-File-chdir>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Log-Any-For-File-chdir>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<File::chdir>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
