package Filesys::Cap;

use 5.010001;
use strict;
use warnings;
#use Log::Any '$log';

use File::Temp qw(tempdir);
use UUID::Random;

our $DATE = '2015-11-12'; # DATE
our $VERSION = '0.02'; # VERSION

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       fs_has_attr_x
                       fs_is_ci
                       fs_is_cs
                       fs_can_symlink
               );

sub _uniq_name {
    # what about filesystem like DOS with 8+3 characters limit? :-)
    UUID::Random::generate();
}

sub fs_has_attr_x {
    my $dir = shift // tempdir(CLEANUP => 1);

    my $file1 = _uniq_name();
    my $file2 = _uniq_name();

    my $res;
    open my $fh1, ">", "$dir/$file1" or goto EXIT;
    open my $fh2, ">", "$dir/$file2" or goto EXIT;
    chmod 0755, "$dir/$file1" or goto EXIT;
    chmod 0644, "$dir/$file2" or goto EXIT;

    $res = (-x "$dir/$file1") && !(-x "$dir/$file2");

  EXIT:
    unlink "$dir/$file1";
    unlink "$dir/$file2";
    return $res;
}

sub _check_fs_case_sensitivity {
    my $ci  = shift;
    my $dir = shift // tempdir(CLEANUP => 1);

    my $res;
    my $subdir = _uniq_name();
    mkdir "$dir/$subdir" or return undef;

    my $file1 = "a" . _uniq_name();
    my $file2 = uc($file1);

    open my $fh1, ">", "$dir/$subdir/$file1" or goto EXIT;
    open my $fh2, ">", "$dir/$subdir/$file2" or goto EXIT;

    opendir my $dh, "$dir/$subdir" or goto EXIT;
    my @d = grep {$_ ne '.' && $_ ne '..'} readdir($dh);

    $res = @d > 1;
    $res = !$res if $ci;

  EXIT:
    unlink "$dir/$subdir/$file1";
    unlink "$dir/$subdir/$file2";
    rmdir "$dir/$subdir";

    return $res;
}

sub fs_is_ci {
    _check_fs_case_sensitivity(1, @_);
}

sub fs_is_cs {
    _check_fs_case_sensitivity(0, @_);
}

sub fs_can_symlink {
    my $dir = shift // tempdir(CLEANUP => 1);

    return undef unless eval { symlink("", ""); 1 };

    my $name = _uniq_name();
    symlink "$dir/$name.2", "$dir/$name" or return undef;

    unlink "$dir/$name";

    return 1;
}

1;
# ABSTRACT: Test filesystem capabilities/characteristics

__END__

=pod

=encoding UTF-8

=head1 NAME

Filesys::Cap - Test filesystem capabilities/characteristics

=head1 VERSION

This document describes version 0.02 of Filesys::Cap (from Perl distribution Filesys-Cap), released on 2015-11-12.

=head1 SYNOPSIS

 use Filesys::Cap qw(fs_has_attr_x fs_is_ci fs_is_cs fs_can_symlink);

 say "Filesystem has x attribute"     if fs_has_attr_x();
 say "Filesystem is case-insensitive" if fs_is_ci("/tmp");
 say "Filesystem is case-sensitive"   if fs_is_cs("/tmp");
 say "Filesystem can do symlinks"     if fs_can_symlink("/tmp");

=head1 FUNCTIONS

=head2 fs_has_attr_x([ $dir ]) => bool

Return true if filesystem has x attribute, meaning it can have files that pass
C<-x> Perl file test operator as well as files that fail it. This is done by
actually creating two temporary files under C<$dir>, one chmod-ed to 0644 and
one to 0755 and test the two files.

If C<$dir> is not specified, will use a temporary directory created by
C<tempdir()>.

Will return undef on failure (e.g.: permission denied, etc).

=head2 fs_is_ci([ $dir ]) => bool

Return true if filesystem is case-insensitive, meaning it is impossible to
create two files with the same name but differing case (e.g. "foo" and "Foo").
This is done by actually creating two temporary files under C<$dir>.

If C<$dir> is not specified, will use a temporary directory created by
C<tempdir()>.

Will return undef on failure (e.g.: permission denied, etc).

=head2 fs_is_cs([ $dir ]) => bool

The opposite of C<fs_is_ci>, will return true if filesystem is case-sensitive.

=head2 fs_can_symlink([ $dir ]) => bool

Return true if filesystem can do symlinks. This is tested by creating an actual
temporary symlink. Note that this check is performed first:

 return undef unless eval { symlink("",""); 1 };

If C<$dir> is not specified, will use a temporary directory created by
C<tempdir()>.

Will return undef on failure (e.g.: permission denied, etc).

=head1 SEE ALSO

To list filesystems and their properties (so, the more proper/rigorous version),
see L<Sys::Filesystem>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Filesys-Cap>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Filesys-Cap>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Filesys-Cap>

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
