package File::chown;

our $DATE = '2015-09-10'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
                    chown
            );

sub chown {
    my $opts = ref($_[0]) eq 'HASH' ? shift : {};

    my ($user, $group);
    if ($opts->{ref}) {
        my @st = stat($opts->{ref})
            or die "Can't stat chown ref '$opts->{ref}': $!";
        ($user, $group) = @st[4, 5];
    } else {
        @_ or die "Please specify user";
        $user = shift // -1;
        unless ($user =~ /\A-?\d+\z/) {
            my @pwent = getpwnam($user)
                or die "Unknown user name '$user'";
            $user = $pwent[2];
        }
        @_ or die "Please specify group";
        $group = shift // -1;
        unless ($group =~ /\A-?\d+\z/) {
            my @grent = getgrnam($group)
                or die "Unknown group name '$group'";
            $group = $grent[2];
        }
    }

    if (!($opts->{deref} // 1)) {
        require File::lchown;
        return File::lchown::lchown($user, $group, @_);
    } else {
        return CORE::chown($user, $group, @_);
    }
}

1;
# ABSTRACT: chown which groks user-/group names and some other extra features

__END__

=pod

=encoding UTF-8

=head1 NAME

File::chown - chown which groks user-/group names and some other extra features

=head1 VERSION

This document describes version 0.02 of File::chown (from Perl distribution File-chown), released on 2015-09-10.

=head1 SYNOPSIS

 use File::chown; # exports chown() by default

 # chown by user-/group names
 chown "ujang", "ujang", @files;

 # numeric ID's still work
 chown -1, 500, "myfile.txt";

 # option: use a reference file's owner/group instead of specifying directly,
 # like the Unix chown command's --reference=FILE.
 chown({ref => "/etc/passwd"}, "mypasswd");

 # option: use lchown instead of chown, like Unix chown command's --no-derefence
 # (-h).
 chown({deref=>0}, "nobody", "nobody", "/home/user/www");

=head1 DESCRIPTION

L<File::chown> provides C<chown()> which overloads the core version with one
that groks user-/group names, as well as some other extra features.

=head1 FUNCTIONS

=head2 chown([ \%opts, ] LIST) => bool

Changes the owner (and group) of a list of files. Like the core version of
C<chown()>, The first two elements of the list must be C<$user> and C<$group>
which can be numeric ID's (or -1 to mean unchanged) or string which will be
looked up using C<getpwnam> and C<getgrnam>. Function will die if lookup fails.

It accepts an optional first hashref argument containing options. Known options:

=over

=item * ref => str

Like C<--reference> option in the C<chown> Unix command, meaning to get C<$user>
and C<$group> from a specified filename instead of from the first two elements
of the argument list.

=item * deref => bool (default: 1)

If set to 0 then, like the C<--no-dereference> (C<-h>) option of the C<chown>
Unix command, will use L<File::lchown> instead of the core C<chown()>. This is
to set ownership of a symlink itself instead of the symlink target.

=back

=head1 SEE ALSO

C<chown> in perlfunc

The C<chown> Unix command

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/File-chown>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-File-chown>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=File-chown>

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
