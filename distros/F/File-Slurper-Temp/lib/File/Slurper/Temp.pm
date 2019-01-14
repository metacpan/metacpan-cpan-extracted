package File::Slurper::Temp;

our $DATE = '2019-01-14'; # DATE
our $VERSION = '0.004'; # VERSION

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

sub write_text {
    my $filename = shift;

    my ($tempfh, $tempname) = File::Temp::tempfile();
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

This document describes version 0.004 of File::Slurper::Temp (from Perl distribution File-Slurper-Temp), released on 2019-01-14.

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
provides C<write_text> and C<write_binary>. The functions are the same as their
original in File::Slurper but they will first write to a temporary file created
by L<File::Temp>'s C<tempfile>, then rename the temporary file to the originally
specified name. If the filename is originally a symlink, it will be replaced
with a regular file. This can avoid symlink attack.

In addition to that, this module also provides C<write_text_to_tempfile> and
C<write_binary_to_tempfile>. You don't have to specify filename but just content
to write and the functions will return the temporay filename created.

=head1 FUNCTIONS

=head2 write_text

=head2 write_binary

=head2 write_text_to_tempfile

=head2 write_binary_to_tempfile

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
