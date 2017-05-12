# Copyright 2009-2011, Bartłomiej Syguła (perl@bs502.pl)
#
# This is free software. It is licensed, and can be distributed under the same terms as Perl itself.
#
# For more, see my website: http://bs502.pl/

package Devel::CoverReport::VCS::Fake;

use strict; use warnings;

our $VERSION = "0.05";

use Carp::Assert::More qw( assert_defined );
use File::Slurp qw( read_file );

=encoding UTF-8

=head1 NAME

Devel::CoverReport::VCS::Fake - Fake VCS plugin for testing purposes.

=head1 SYNOPSIS

 require Devel::CoverReport::VCS::Fake;

 my $vcs_metadata = Devel::CoverReport::VCS::Fake::inspect($file_path);

=over

=item inspect

Returns: VCS metadata, as required by Devel::CoverReport.

Parameter: path to file, that should be inspected.

=cut

my $c_count;    # How many fake commits will be... faked (defined in BEGIN).
my $n = 0;
my @commits;

BEGIN {
    my @authors = qw(
        Alicia
        Mark
        Nataly
        Quinn
        Wictor
        Zuzanna
    );

    $c_count = 15;

    foreach my $seed (1..$c_count) {
        my $cid = 1 + int ( $seed * 1.234 );

        push @commits, {
            _id    => 'fake:' . $cid,
            vcs    => 'fake',
            author => $authors[ int ( $seed / 3 ) ],
            cid    => $cid,
            date   => 1278492553 + 3600 * $seed
        };
    }
}

sub inspect { # {{{
    my ( $file_path ) = @_;

    assert_defined($file_path, "File path given");

#    use Data::Dumper; warn Dumper \@commits;

    # Yes, it is NOT obvious ;)
    if (not -f $file_path) {
        return;
    }

    my %metadata = (
        lines   => [],
    );
    
    my @lines = read_file($file_path);
    foreach my $line (@lines) {
        push @{ $metadata{'lines'} }, $commits[ ( $n++ / 3 ) % $c_count ];
    }

    return \%metadata;
} # }}}

1;

__END__

=back

=head1 LICENCE

Copyright 2009-2011, Bartłomiej Syguła (perl@bs502.pl)

This is free software. It is licensed, and can be distributed under the same terms as Perl itself.

For more, see my website: http://bs502.pl/

=cut

# vim: fdm=marker
