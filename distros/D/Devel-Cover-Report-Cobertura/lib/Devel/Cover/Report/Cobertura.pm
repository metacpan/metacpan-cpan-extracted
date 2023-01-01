package Devel::Cover::Report::Cobertura;

use strict;
use warnings;

our $VERSION = "1.0";

use Devel::Cover::Report::Cobertura::Builder;
use Getopt::Long;

# Entry point which C<cover> uses
sub report {
    my ( $pkg, $db, $options ) = @_;

    my $report = builder( $db, $options );
    my $outfile = output_file($options);

    printf( "Writing clover output file to '%s'...\n", $outfile ) unless $options->{silent};
    $report->generate($outfile);

}

#extend the options for the C<cover> command line
sub get_options {
    my ( $self, $opt ) = @_;
    $opt->{option}{outputfile}  = "cobertura.xml";
    $opt->{option}{projectname} = "Devel::Cover::Report::Cobertura";
    die "Invalid command line options"
        unless GetOptions(
        $opt->{option},
        qw(
            outputfile=s
            projectname=s
            )
        );
}

sub output_file {
    my ($options) = @_;

    my $out_dir  = $options->{outputdir};
    my $out_file = $options->{option}{outputfile};
    my $out_path = sprintf( '%s/%s', $out_dir, $out_file );
    return $out_path;
}

sub builder {
    my ( $db, $options ) = @_;
    my $project_name = $options->{option}{projectname};
    my $report       = Devel::Cover::Report::Cobertura::Builder->new(
        {   db                         => $db,
            name                       => $project_name,
            include_condition_criteria => 1
        }
    );
}

1;

__END__

=head1 NAME

Devel::Cover::Report::Cobertura - Backend for Cobertura reporting of coverage statistics

=head1 SYNOPSIS

 cover -report cobertura

=head1 DESCRIPTION

This module generates a cobertura compatible coverage xml file which can be used
in Gitlab

It is designed to be called from the C<cover> program distributed with
L<Devel::Cover> L<Devel::Cover::Report::Clover>.

It is implemented as sub class of Devel::Cover::Report::Clover with
a different template

=head1 OPTIONS

Options are specified by adding the appropriate flags to the C<cover> program.
This report format supports the following:

=over 4

=item outputfile

This will be the file name that you would like to write this report out to.
It defaults to F<cobertura.xml>.

=item projectname

This is simply a cosmetic item.  When the xml is generated, it has a project
name which will show up in your continuous integration system once it is
parsed.  This can be any string you want and it defaults to
'Devel::Cover::Report::Cobertura'.

=back

=head1 SEE ALSO

L<Devel::Cover>

L<Devel::Cover::Report::Clover>

=head1 CREDITS

David Bartle - author of Devel::Cover::Report::Clover

=head1 AUTHOR

Jeff Zhang <jhzhang@synopsys.com>

=head1 LICENSE

Copyright

This software is free.  It is licensed under the same terms as Perl itself.

=cut
