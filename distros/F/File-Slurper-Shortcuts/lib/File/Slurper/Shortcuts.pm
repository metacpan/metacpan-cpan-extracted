package File::Slurper::Shortcuts;

our $DATE = '2019-10-06'; # DATE
our $VERSION = '0.003'; # VERSION

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

This document describes version 0.003 of File::Slurper::Shortcuts (from Perl distribution File-Slurper-Shortcuts), released on 2019-10-06.

=head1 SYNOPSIS

 use File::Slurper::Shortcuts qw(modify_text modify_binary);
 modify_text("dist.ini", sub { s/One/Two/ });

=head1 DESCRIPTION

=for Pod::Coverage ^(replace_text|replace_binary)$

=head1 FUNCTIONS

=head2 modify_text

Usage:

 $orig_content = modify_text($filename, $code, $encoding, $crlf);

This is like L<File::Slurper>'s C<write_text> except that instead of C<$content>
in the second argument, this routine accepts C<$code>. Code should modify C<$_>
(which contains the content of the file) B<and return true>. This routine will
die if: file can't be read with C<read_text()>, code does not return true, file
can't be written to with C<write_text()>.

If content (C<$_>) does not change, file will not be written.

Return the original content of file.

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

L<File::Slurper>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
