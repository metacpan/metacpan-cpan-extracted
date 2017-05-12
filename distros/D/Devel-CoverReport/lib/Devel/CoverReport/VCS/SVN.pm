# Copyright 2009-2011, Bartłomiej Syguła (perl@bs502.pl)
#
# This is free software. It is licensed, and can be distributed under the same terms as Perl itself.
#
# For more, see my website: http://bs502.pl/

package Devel::CoverReport::VCS::SVN;

use strict; use warnings;

our $VERSION = "0.05";

use Carp::Assert::More qw( assert_defined );
use File::Slurp qw( read_file );
use Time::Local qw( timelocal );

=encoding UTF-8

=head1 NAME

Devel::CoverReport::VCS::SVN - Subversion plugin for Devel::CoverReport.

=head1 SYNOPSIS

 require Devel::CoverReport::VCS::SVN;

 my $vcs_metadata = Devel::CoverReport::VCS::SVN::inspect($file_path);

=over

=item inspect

Returns: VCS metadata, as required by Devel::CoverReport.

Parameter: path to file, that should be inspected.

=cut

sub inspect { # {{{
    my ( $file_path ) = @_;

    assert_defined($file_path, "File path given");

#    use Data::Dumper; warn Dumper \@commits;

    # Yes, it is NOT obvious ;)
    if (not -f $file_path) {
        return;
    }

    my $ph;
    if (not open $ph, q{-|}, "svn blame $file_path 2>/dev/null") {
        return;
    }
    my @lines = read_file($ph);
    close $ph;

#    use Data::Dumper; warn Dumper \@lines;

    my %metadata = (
        lines   => [],
    );

    foreach my $line (@lines) {
        if ($line =~ m{^\s*(\d+)\s+(.+?)\s}s) {
            # Fixme: timezone is ignored.
            my ( $revision, $author ) = ( $1, $2 );

            push @{ $metadata{'lines'} }, {
                _id    => 'svn:'. $revision,
                vcs    => 'svn',
                author => $author,
                cid    => $revision,
                date   => _rev_date($file_path, $revision),
            };
        }
    }

    return \%metadata;
} # }}}

my %_rev_date_cache;

sub _rev_date { # {{{
    my ( $file, $revision ) = @_;

    if ($_rev_date_cache{$revision}) {
        return $_rev_date_cache{$revision};
    }

    my $ph;
    if (not open $ph, q{-|}, "svn info --xml -r $revision $file 2>/dev/null") {
        return;
    }
    my @lines = read_file($ph);
    close $ph;

#    use Data::Dumper; warn Dumper \@lines;

    foreach my $line (@lines) {
        if ($line =~ m{date\>(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d).+?\<\/date}s) {
            my ( $year, $mon, $mday, $hour, $min, $sec ) = ( int $1, int $2, int $3, int $4, int $5, int $6 );

#            warn "timelocal($sec,$min,$hour, $mday,$mon,$year)\n";

            return $_rev_date_cache{$revision} = timelocal($sec,$min,$hour,$mday,$mon - 1,$year - 1900);
        }
    }

    return;
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
