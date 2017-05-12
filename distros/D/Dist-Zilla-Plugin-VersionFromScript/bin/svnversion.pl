#!/usr/bin/perl
#===============================================================================
#
#     ABSTRACT:  munge svnversion output to be suitable for a real version number
#      PODNAME:  svnversion.pl
#
#       AUTHOR:  Reid Augustin (REID), <reid@lucidport.com>
#      COMPANY:  LucidPort Technology, Inc.
#      CREATED:  12/02/2010 10:35:48 AM PST
#===============================================================================

use strict;
use warnings;

use File::Basename;

our $VERSION = '0.017'; # VERSION

my $major = 0;
my $offset = 0;

my ($myname, undef, $suffix) = fileparse($0);
$myname .= $suffix;
my $help = "$myname [ --major number ] [ --offset number ]\n";

while (my $arg = shift) {
    if ($arg =~ s/^--?//) {
        if ($arg eq 'major') {
            $major = shift;
        } elsif ($arg eq 'offset') {
            $offset = shift;
        }
    } else {
        die $help;
    }
}
if (not defined ($major) or
    ($major =~ m/\D/)) {
    $major = '<undefined>' unless (defined($major));
    die "$help\n*** illegal major: $major (must be a non-negative integer)\n";
}
if (not defined ($offset) or
    ($offset !~ m/^-?\d+$/)) {
    $offset = '<undefined>' unless (defined($offset));
    die "$help\n*** illegal offset: $offset (must be an integer)\n";
}

my $ver = `svnversion .`;
# if good, $ver might be one of: qw( 4168 4123:4167 4166M 4165S 4212:4164MS )
# if svnversion doesn't exist, $ver will be undef.  If there is no .svn info,
# $ver will be something like "export\n".  See 'svnversion --help' for more info.
$ver ||= 0;         # if no returned result

if ($ver =~ m/(\d+)\D*(\d*)/) {     # split?
    my ($v1, $v2) = ($1, $2);
    $v2 = $v1 if ($v2 eq '');
    $v1 = $v2 if ($v2 > $v1);       # swapped?
    $v1 += $offset;
    print STDERR "Version too big: $v1\n" if ($v1 > 999);
    print STDERR "Minor version is negative: $v1\n" if ($v1 < 0);
    printf ("%d.%03d\n", $major, $v1);
} else {
    print STDERR "not a Subversioned project? $ver\n";
    print '0.001';
}



__END__
=pod

=head1 NAME

svnversion.pl - munge svnversion output to be suitable for a real version number

=head1 VERSION

version 0.017

=head1 AUTHOR

Reid Augustin <reid@hellosix.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Reid Augustin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

