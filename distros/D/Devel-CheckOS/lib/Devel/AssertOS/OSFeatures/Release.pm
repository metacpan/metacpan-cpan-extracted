package Devel::AssertOS::OSFeatures::Release;

use strict;
use warnings;
use File::Spec;
use parent 'Exporter';

our $VERSION   = '1.0';
our @EXPORT_OK = qw(distributor_id);

=pod

=head1 NAME

Devel::AssertOS::OSFeatures::Release - functions to manipulate os-release file

=head1 SYNOPSIS

    use Devel::AssertOS::OSFeatures::Release 'distributor_id';
    my $id = distributor_id;

=head1 DESCRIPTION

This module exports functions to handle text files related to Debian-like
distributions.

=head1 EXPORTED

The following subs are exported.

=head2 distributor_id

Retrieves and returns the distributor ID from the F</etc/os-release> file.

It is expected that the file exists, it is readable and have the following
(minimum) content format:

    NAME="Ubuntu"
    VERSION_ID="22.04"
    VERSION="22.04.4 LTS (Jammy Jellyfish)"
    VERSION_CODENAME=jammy
    ID=ubuntu
    ID_LIKE=debian
    HOME_URL="https://www.ubuntu.com/"

This excerpt is from Ubuntu 22.04, but other distributions might have fewer,
more or different fields and values.

It returns the value of C<ID> or C<undef>, if the conditions are not those
specified above.

=cut

sub distributor_id {
    my $filename  = 'os-release';
    my $file_path = File::Spec->catfile( ( '', 'etc' ), $filename );
    my $regex     = qr/^ID\=(\w+)/;
    my $dist_id   = undef;

    if ( -r $file_path ) {
        open my $in, '<', $file_path or die "Cannot read $file_path: $!";
        while (<$in>) {
            chomp;
            if ( $_ =~ $regex ) {
                $dist_id = ucfirst(lc $1) if (defined($1));
                last;
            }
        }
        close($in) or die "Cannot close $file_path: $!";
    }

    return $dist_id;
}

=head1 COPYRIGHT and LICENCE

Copyright 2024 David Cantrell

This software is free-as-in-speech software, and may be used, distributed, and modified under the terms of either the GNU General Public Licence version 2 or the Artistic Licence. It's up to you which one you use. The full text of the licences can be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=cut

1;
