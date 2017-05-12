#===============================================================================
#
#         FILE:  Dg2TkPs
#
#     ABSTRACT:  convert Games::Go::Sgf2Dg::Diagrams to Postscript from a Tk window
#
#       AUTHOR:  Reid Augustin (REID), <reid@hellosix.com>
#===============================================================================
#
#   Copyright (C) 2005 Reid Augustin reid@hellosix.com
#                      1000 San Mateo Dr.
#                      Menlo Park, CA 94025 USA
#

=head1 SYNOPSIS

use Games::Go::Sgf2Dg::Dg2TkPs

 my $dg2ps = B<Games::Go::Sgf2Dg::Dg2TkPs-E<gt>new> (options);
 my $canvas = $dg2ps->convertDiagram($diagram);

=head1 DESCRIPTION

This is a real hack to get PostScript output from the Dg2Tk
converter.  All it does is use the built-in PostScript that a
Tk::Canvas widget provides to convert the Dg2Tk canvas pages to
PostScript.  The resulting PostScript is fairly crude because the
Canvas that it is drawn from is crude to begin with.  See
L<Games::Go::Sgf2Dg::Dg2Ps> for a better PostScript converter.

A Games::Go::Sgf2Dg::Dg2TkPs inherits from L<Games::Go::Sgf2Dg::Dg2Tk>, and uses all
its methods and options.  The main difference is that after
conversion to Tk is complete, each diagram L<Tk::Canvas> is
converted to PostScript via the L<Tk::Canvas>->postscript method.
Some minor massaging of the PostScript source is done to string the
canvas pages together.

=cut

use strict;
require 5.001;

our $VERSION = '4.252'; # VERSION

package Games::Go::Sgf2Dg::Dg2TkPs;
use Games::Go::Sgf2Dg::Dg2Tk;
use Carp;

our @ISA = qw(Exporter Games::Go::Sgf2Dg::Dg2Tk);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration       use PackageName ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

######################################################
#
#       Class Variables
#
#####################################################

######################################################
#
#       Public methods
#
#####################################################

=head1 METHODS

See Dg2Tk for the usual Dg2* conversion methods.

=over 4

=item $dg2ps-E<gt>B<comment> ($comment ? , ... ?)

Inserts comments into the PostScript source code.  Note that since
the PostScript is generated B<after> the diagrams are all
constructed by Dg2Tk, comments are likely to be out of order - they
will all be at the head of the PostScript file.

=cut

sub comment {
    my ($my, @comments) = @_;

    $my->{comment} = '' unless(exists($my->{comment}));
    $my->{comment} .= join("\n", @comments);
}

=item $dg2ps-E<gt>B<configure> (option =E<gt> value, ?...?)

Grabs 'file' configuration option, passes all other requests to
Dg2Tk.

=cut

sub configure {
    my ($my, %args) = @_;

    if (exists($args{file})) {
        $my->{file} = delete($args{file});
        if (ref($my->{file}) eq 'SCALAR') {
            $my->{filename} = $my->{file};
        } elsif (ref($my->{file}) eq 'ARRAY') {
            $my->{filename} = 'ARRAY';
        } elsif (ref($my->{file}) eq 'GLOB') {
            $my->{filename} = 'GLOB';
        } elsif (ref($my->{file}) =~ m/^IO::/) {
            $my->{filename} = 'IO';
        } else {
            $my->{filename} = $my->{file};
        }
    }
    $my->SUPER::configure(%args);
}

=item $dg2ps-E<gt>B<close>

Converts each diagram L<Tk::Canvas> in the Dg2Tk NoteBook to
PostScript via the L<Tk::Canvas>->postscript method.

=cut

my $pageSetup =
#   "%%PageBoundingBox: 28 28 584 764\n" .
    "\%\%BeginPageSetup\n" .
    "/pagelevel save def\n" .
#   "28 28 584 764 cliptobox\n" .
#   "debugdict begin\n" .
#   "userdict begin" .
    "\%\%EndPageSetup\n";
my $pageTrailer = 
    "\%\%PageTrailer\n" .
#   "end\n" .
#   "end\n" .
    "pagelevel restore\n" .
    "showpage\n";

sub close {
    my ($my) = @_;

    my $nb = $my->notebook;     # get the Dg2Tk notebook object
    # $my->diagrams->[0]->after(1000); # delay
    require IO::File;
    my $fname = $my->{filename} || 'dg2ps.ps';
    my $fd = IO::File->new($fname) or
        die("Error opening $fname: $!\n");
    my $trailer;
    $my->{comment} =~ s/^/%%/;
    $my->{comment} =~ s/\n/\n%%/gs;
    $my->{comment} =~ s/\n%%$/\n/s;
    my $page = 0;
    foreach my $dg (@{$my->diagrams}) {
        $nb->update;                # bring Tk display up to date
        my $ps = $dg->postscript();
        $page++;
        $ps =~ s/^(\%!PS-Adobe-3.0) EPSF-.*?\n/$1\n/;
        $ps =~ s/(\%\%Trailer\b.*)//s;  # remove trailer
        unless (defined($trailer)) {    # first page
            $trailer = $1;
            $ps =~ s/\%\%Pages: 1/\%\%Pages: (atend)/s; # report pages at end
            $ps =~ s/(\%\%EndComments)/$my->{comment}\n$1/s;
        } else {                        # all following pages
            $ps =~ s/.*\%\%EndSetup\b//s;  # remove prologue
        }
        $ps =~ s/\n%%Page: .*?\n/\%\%Page: $page $page\n$pageSetup/so;

        $ps =~ s/\s*\bshowpage\n\n$/\n$pageTrailer/so;
        $fd->print($ps);
        $nb->raise($nb->info('focusnext'));
    }
    $trailer =~ s/\%\%Trailer/\%\%Trailer\n\%\%Pages: $page/gs;
    $fd->print($trailer);       # put trailer back
    close $fd;
}

######################################################
#
#       Private methods
#
#####################################################


1;

__END__

=back

=head1 SEE ALSO

=over

=item L<sgf2dg>(1)

Script to convert SGF format files to Go diagrams

=back

=head1 BUGS

The output is pretty ugly.  Oh well, what can one expect from such a
simple hack?

