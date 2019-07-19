package File::Slurper::Temp;

our $DATE = '2019-07-16'; # DATE
our $VERSION = '0.005'; # VERSION

use strict;
use warnings;

use Carp 'croak';
use File::Slurper ();
use File::Temp ();

use Exporter qw(import);
our @EXPORT_OK = qw(
                       write_text write_binary
                       write_text_to_tempfile write_binary_to_tempfile
               );

our $FILE_TEMP_TEMPLATE = "XXXXXXXXXX";
our $FILE_TEMP_DIR;

sub _tempfile {
    my $target_filename = shift;

    my @tfargs;
    push @tfargs, $FILE_TEMP_TEMPLATE;
    my $dir = $FILE_TEMP_DIR;
    unless (defined $dir) {
        require File::Spec;
        (undef, $dir, undef) = File::Spec->splitpath($target_filename);
    }
    push @tfargs, DIR => $dir;
    File::Temp::tempfile(@tfargs);
}

sub write_text {
    my $filename = shift;

    my ($tempfh, $tempname) = _tempfile($filename);
    File::Slurper::write_text($tempname, @_);
    rename $tempname, $filename
        or croak "Couldn't rename $tempname to $filename: $!";

    return;
}

sub write_binary {
    return write_text(@_[0,1], 'latin-1');
}

sub write_text_to_tempfile {
    my ($tempfh, $tempname) = File::Temp::tempfile();
    File::Slurper::write_text($tempname, @_);
    return $tempname;
}

sub write_binary_to_tempfile {
    return write_text_to_tempfile($_[0], 'latin-1');
}

1;
# ABSTRACT: File::Slurper + File::Temp

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Slurper::Temp - File::Slurper + File::Temp

=head1 VERSION

This document describes version 0.005 of File::Slurper::Temp (from Perl distribution File-Slurper-Temp), released on 2019-07-16.

=head1 SYNOPSIS

Use like you would use L<File::Slurper>'s C<write_text> or C<write_binary>:

 use File::Slurper::Temp qw(write_text write_binary);
 write_text("/tmp/foo.txt", "some text");
 write_binary("/tmp/bar", $somedata);

Use C<write_text_to_tempfile> and C<write_binary_to_tempfile>:

 use File::Slurper::Temp qw(write_text_to_tempfile write_binary_to_tempfile);
 my $filename1 = write_text_to_tempfile("some text");
 my $filename2 = write_binary_to_tempfile($somedata);

=head1 DESCRIPTION

This module is a simple combination of L<File::Slurper> and L<File::Temp>. It
provides L</write_text> and L</write_binary> (as well as a couple of functions
of its own). The two functions are the same as their original in File::Slurper
but they will first write to a temporary file created by L<File::Temp>'s
C<tempfile>, then C<rename()> the temporary file to the originally specified
name. If the filename is originally a symlink, it will be replaced with a
regular file by C<rename()>. This can avoid symlink attack.

In addition to that, this module also provides L/<write_text_to_tempfile> and
L<write_binary_to_tempfile>. You don't have to specify filename but just content
to write and the functions will return the temporay filename created.

=head1 FUNCTIONS

=head2 write_text

Usage:

 write_text($filename, $content [ , $encoding, $crlf ])

Just like the original L<File::Slurper>'s version, except will write to
temporary file created by L<File::Temp>'s C<tempfile> first, then rename the
temporary file using C<rename()>. The function will croak if C<rename()> fails.

To make sure that C<rename()> doesn't fail when the default temporary directory
(e.g. C</tmp>) is on a different filesystem (because C<rename()> does not work
across filesystem boundary), the temporary file is created with option C<< DIR
=> dirname($filename) >> . If you want to set a specific temporary directory,
set C<$FILE_TEMP_DIR> (see source code).

=head2 write_binary

Usage:

 write_binary($filename, $content)

=head2 write_text_to_tempfile

Usage:

 $tempname = write_text_to_tempfile($content [ , $encoding, $crlf ])

Temporary file is created with default option (C<File::Temp::tempfile()>).

=head2 write_binary_to_tempfile

Usage:

 $tempname = write_binary_to_tempfile($content)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/File-Slurper-Temp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-File-Slurper-Temp>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=File-Slurper-Temp>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<File::Slurper>

L<File::Temp>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
