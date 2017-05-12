package File::Symlink::Atomic;
use strict;
use warnings;
# ABSTRACT: an atomic drop-in replacement for CORE::symlink
our $VERSION = '0.002'; # VERSION

use File::Temp;
use File::Spec;
use Exporter qw(import);
our @EXPORT = qw(symlink); ## no critic(Modules::ProhibitAutomaticExportation)

    
sub symlink($$) { ## no critic(Subroutines::ProhibitSubroutinePrototypes Subroutines::ProhibitBuiltinHomonyms)
    my $symlink_target = shift;
    my $symlink_name   = shift;

    my ($volume, $dirs, $file) = File::Spec->splitpath($symlink_name);
    my $template = File::Spec->catpath($volume, $dirs, ".$file.$$.XXXXXX");
    my $tmp_symlink_name;
    ATTEMPT:
    for (1..10) { # try 10 times
        $tmp_symlink_name = mktemp($template);
        symlink $symlink_target, $tmp_symlink_name and last ATTEMPT;
    }
    return 0 unless -l $tmp_symlink_name; # wtf?
    
    rename $tmp_symlink_name, $symlink_name or return 0; # should be atomic
    return 1;
}

1;


__END__
=pod

=encoding utf-8

=head1 NAME

File::Symlink::Atomic - an atomic drop-in replacement for CORE::symlink

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use File::Symlink::Atomic;   # imports replacement symlink
    symlink "target", "name1";   # easy peasy
    symlink "bullseye", "name1"; # now atomic

=head1 DESCRIPTION

Actually creating a symlink is not problematic, but making an existing one point
at a new target may not be atomic on your system. For example, on Linux, the
system does C<unlink> and then C<symlink>. In between, no symlink exists. If
something goes wrong, you're left with nothing.

In your shell, you probably want to do something like:

    mkdir old-target new target # Create your targets
    ln -s old-target link       # Create your initial symlink
    # ln -sf new-target link    # NOT atomic!
    ln -s new-target link-tmp && mv -Tf link-tmp link

Moving the symlink to the new name makes it atomic, because under the hood, the
C<mv> command does C<rename>, which is guaranteed to be atomic by
L<POSIX|http://pubs.opengroup.org/onlinepubs/9699919799/functions/rename.html>.

B<File::Symlink::Atomic> attempts to do the same thing in Perl what the command
shown above does for your shell.

=head1 FUNCTIONS

=head2 symlink OLDFILE,NEWFILE

Creates a new filename symbolically linked to the old filename.
Returns C<1> for success, C<0> otherwise. This drop-in replacement
for C<CORE::symlink> creates a symlink with a temporary name, then
renames it to the name you requested - this ensures that if a
symlink by the requested name already existed, then its target is
updated atomically.

=head1 CAVEATS

This module is B<not> guaranteed to be portable. I have no idea what this will
do on any platform other than Linux. Feel free to run the test suite to find out!

=head1 AVAILABILITY

The project homepage is L<http://metacpan.org/release/File-Symlink-Atomic/>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/File::Symlink::Atomic/>.

=head1 SOURCE

The development version is on github at L<http://github.com/doherty/File-Symlink-Atomic>
and may be cloned from L<git://github.com/doherty/File-Symlink-Atomic.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/doherty/File-Symlink-Atomic/issues>.

=head1 AUTHOR

Mike Doherty <doherty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Mike Doherty.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

