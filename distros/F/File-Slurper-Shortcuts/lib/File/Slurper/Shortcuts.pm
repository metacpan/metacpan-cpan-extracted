package File::Slurper::Shortcuts;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-02'; # DATE
our $DIST = 'File-Slurper-Shortcuts'; # DIST
our $VERSION = '0.005'; # VERSION

use strict 'subs', 'vars';
use warnings;
no warnings 'once';
use Carp;

use File::Slurper ();

use Exporter qw(import);
our @EXPORT_OK = qw(
                       modify_text
                       modify_binary
                       replace_text
                       replace_binary
               );

sub modify_text {
    my ($filename, $code, $encoding, $crlf) = @_;

    local $_ = File::Slurper::read_text($filename, $encoding, $crlf);
    my $orig = $_;

    my $res = $code->($_);
    croak "replace_text(): Code does not return true" unless $res;

    return if $orig eq $_;

    File::Slurper::write_text($filename, $_, $encoding, $crlf);
    $orig;
}

sub modify_binary {
    return modify_text(@_[0,1], 'latin-1');
}

# old names, deprecated and will be removed in the future
*replace_text = \&modify_text;
*replace_binary = \&modify_binary;

1;
# ABSTRACT: Some convenience additions for File::Slurper

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Slurper::Shortcuts - Some convenience additions for File::Slurper

=head1 VERSION

This document describes version 0.005 of File::Slurper::Shortcuts (from Perl distribution File-Slurper-Shortcuts), released on 2021-08-02.

=head1 SYNOPSIS

 use File::Slurper::Shortcuts qw(modify_text modify_binary);
 modify_text("dist.ini", sub { s/One/Two/ });

=head1 DESCRIPTION

=for Pod::Coverage ^(replace_text|replace_binary)$

=head1 FUNCTIONS

=head2 modify_text

Usage:

 $orig_content = modify_text($filename, $code, $encoding, $crlf);

This is L<File::Slurper>'s C<read_text> and C<write_text> combined. First,
C<read_text> is performed then the content of file is put into C<$_>. Then
C<$code> will be called and should modify C<$_> to modify the content of file.
Finally, C<write_text> is called to write the new content. If content (C<$_>)
does not change, file will not be written.

If file can't be read with C<read_text()> an exception will be thrown by
File::Slurper.

This function will also die if code does not return true.

If file can't be written with C<write_text()> an exception will be thrown by
File::Slurper.

Return the original content of file.

Note that no locking is performed and file is opened twice, so there might be
race condition etc.

=head2 modify_binary

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/File-Slurper-Shortcuts>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-File-Slurper-Shortcuts>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=File-Slurper-Shortcuts>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<File::Slurper::Temp> also provides C<modify_text> and C<modify_binary>.

L<File::Slurper>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
