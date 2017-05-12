# Copyright 2009-2011, Bartłomiej Syguła (perl@bs502.pl)
#
# This is free software. It is licensed, and can be distributed under the same terms as Perl itself.
#
# For more, see my website: http://bs502.pl/

package Devel::CoverReport::VCS::Git;

use strict; use warnings;

our $VERSION = "0.05";

use Carp::Assert::More qw( assert_defined );
use File::Slurp qw( read_file );
use Time::Local qw( timelocal );

=encoding UTF-8

=head1 NAME

Devel::CoverReport::VCS::Git - Git VCS plugin for Devel::CoverReport.

=head1 SYNOPSIS

 require Devel::CoverReport::VCS::Git;

 my $vcs_metadata = Devel::CoverReport::VCS::Git::inspect($file_path);

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
    if (not open $ph, q{-|}, "git blame $file_path") {
        return;
    }

    my %metadata = (
        lines   => [],
    );

    my @lines = read_file($ph);

#    use Data::Dumper; die Dumper \@lines;

    foreach my $line (@lines) {
        if ($line =~ m{^([^ ]+) \((.+?) (\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)}s) {
            # Fixme: timezone is ignored.
            my ( $commit_id, $author, $year, $mon, $mday, $hour, $min, $sec ) = ( $1, $2, $3,$4,$5, $6,$7,$8 );

            push @{ $metadata{'lines'} }, {
                _id    => 'git:'. $commit_id,
                vcs    => 'git',
                author => $author,
                cid    => $commit_id,
                date   => eval { return timelocal($sec, $min, $hour, $mday, $mon - 1, $year - 1900); },
            };
        }
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

