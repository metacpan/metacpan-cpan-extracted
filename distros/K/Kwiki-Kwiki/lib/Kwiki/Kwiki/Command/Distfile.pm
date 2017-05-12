package Kwiki::Kwiki::Command::Distfile;
use strict;
use base 'Kwiki::Kwiki::Command';
use Archive::Tar;
use Cwd qw(cwd);
use File::Basename;

sub process {
    my $self = shift;

    # Generate a manifest
    my @files;
    File::Find::find({
        wanted => sub {
            my ($dev,$ino,$mode,$nlink,$uid,$gid);
            (($dev,$ino,$mode,$nlink,$uid,$gid) = lstat($_))
                && -f _
                && $File::Find::name !~ m#^\./$self->{ROOT}/#
                && $File::Find::name !~ m/~$/
                && push @files, $File::Find::name;
        }}, '.');

    # Tar it, dereference symlinks so files under lib/ are
    # surely distributed.
    my $tar = Archive::Tar->new;
    $tar->add_files(@files);
    $tar->write($self->distfile_name, 1, "Kwiki-Kwiki");
    print $self->distfile_name . " created.\n";
}

sub distfile_name {
    basename(&cwd) . ".tar.gz";
}

1;

__END__

=head1 NAME

Kwiki::Kwiki::Command::Distfile - Methods that creates distfiles.

=head1 DESCRIPTION

See L<Kwiki::Kwiki> for all documentation.

=head1 COPYRIGHT

Copyright 2006 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>
