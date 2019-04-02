package Devel::Cover::Report::SonarGeneric;

use strict;
use warnings;
use Path::Tiny qw(path);

our $VERSION = '0.3';

sub report {
    my ($pkg, $db, $options) = @_;

    my $cover = $db->cover;

    my $otxt = qq(<coverage version="1">\n);
    for my $file ( @{ $options->{file} } ) {
        my $f  = $cover->file($file);
        my $st = $f->statement;
        my $br = $f->branch;

        $otxt .= qq(  <file path="$file">\n);

        for my $lnr ( sort { $a <=> $b } $st->items ) {
            my $sinfo = $st->location($lnr);
            if ( $sinfo ) {
                my $covered = 0;
                for my $o ( @$sinfo ) {
                    my $ocov = $o->covered // 0;
                    my $ounc = $o->uncoverable // 0;
                    $covered |= $ocov || $ounc;
                }
                my $covtxt = $covered > 0 ? 'true' : 'false';
                if ( $br and my $binfo = $br->location($lnr) ) {
                    my $btot = $binfo->[0]->total;
                    my $bcov = $binfo->[0]->covered;
                    $otxt .= qq(    <lineToCover lineNumber="$lnr" covered="$covtxt" branchesToCover="$btot" coveredBranches="$bcov"/>\n);
                } else {
                    $otxt .= qq(    <lineToCover lineNumber="$lnr" covered="$covtxt"/>\n);
                }
            }
        }

        $otxt .= qq(  </file>\n);
    }

    $otxt .= qq(</coverage>\n);

    path('cover_db/sonar_generic.xml')->spew($otxt);
}

1;

__END__

=pod

=head1 NAME

Devel::Cover::Report::SonarGeneric - SonarQube generic backend for Devel::Cover

=head1 SYNOPSIS

    > cover -report SonarGeneric

=head1 DESCRIPTION

This module generates an XML file suitable for import into SonarQube from an existing
Devel::Cover database.

It is designed to be called from the C<cover> program distributed with L<Devel::Cover>.

The output file will be C<cover_db/sonar_generic.xml>.

To upload the file to SonarQube you have to put a line of

    sonar.coverageReportPaths=cover_db/sonar_generic.xml

into your C<sonar-project.properties> file.

=head1 AUTHOR

Thomas Kratz E<lt>tomk@cpan.orgE<gt>

=cut
