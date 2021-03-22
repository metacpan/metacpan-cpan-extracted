package File::Symlink::Relative;

use 5.008001;

use strict;
use warnings;

# OK, the following is probably paranoia. But if Perl 7 decides to
# change this particular default I'm ready. Unless they eliminate $].
no if $] ge '5.020', feature => qw{ signatures };

use Carp;
use Exporter qw{ import };
use File::Spec;

our $VERSION = '0.004';

our @EXPORT_OK = qw{
    symlink_r
    SYMLINK_SUPPORTED
};
our @EXPORT = qw{ symlink_r };	## no critic (ProhibitAutomaticExportation)
our %EXPORT_TAGS = (
    all	=> \@EXPORT_OK,
);

{
    local $@ = undef;

    # This is true if and only if symbolic links are supported by the
    # underlying operating system. The check is from
    #     perldoc -f symlink
    # in Perl 5.30.2.

    use constant SYMLINK_SUPPORTED => eval { symlink '', ''; 1 } || 0;
}

sub symlink_r ($$) {	## no critic (ProhibitSubroutinePrototypes)
    my ( $source, $target ) = @_;
    my ( $tgt_device, $tgt_dir ) = File::Spec->splitpath( $target );
    defined $tgt_device
	and '' ne $tgt_device
	and $tgt_dir = File::Spec->catdir( $tgt_device, $tgt_dir );
    my $relative = File::Spec->abs2rel( $source, $tgt_dir );
    return symlink $relative, $target;
}

1;

__END__

=head1 NAME

File::Symlink::Relative - Create relative symbolic links

=head1 SYNOPSIS

 use File::Symlink::Relative;

 symlink_r $source, $target;

=head1 DESCRIPTION

This Perl package creates relative symbolic links. All it really does is
wrap the L<symlink> built-in in suitable code.

=head1 SUBROUTINES

This class supports the following public subroutine:

=head2 symlink_r

This subroutine creates a relative symbolic link. All it really does is
to wrap the Perl L<symlink> built-in with code to convert the source
file specification (F<OLDFILE> in the parlance of C<perldoc -f symlink>)
to a path relative to the target file (F<NEWFILE>, a.k.a. the link to be
created), and then delegate to the L<symlink> built-in.

It returns whatever the built-in returns. An exception will be thrown if
the operating system does not support symbolic links. See
L<PORTABILITY|/PORTABILITY> below.

This subroutine is exported by default.

=head1 PORTABILITY

The functionality in this module requires the Perl C<symlink()> built-in
to work under the host operating system. Without this support, the
module should still install and load, but will throw an exception when
called.

=head2 SYMLINK_SUPPORTED

This manifest constant is true if symbolic links are supported, and
false if not.

It is not exported by default, but can be imported to your module by
name or using the C<:all> tag.

=head1 SEE ALSO

L<perlport|perlport>

The documentation for the L<symlink> built-in.

=head1 ACKNOWLEDGMENT

This module was inspired by F</r/perl> post
L<https://www.reddit.com/r/perl/comments/fluxay/can_i_make_relative_symbolic_links_in_perl/>.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=File-Symlink-Relative>,
L<https://github.com/trwyant/perl-File-Symlink-Relative/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020-2021 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
