package LJ::Schedule;

use warnings;
use strict;

=head1 NAME

LJ::Schedule - A quick and dirty schedule-posting tool for LiveJournal.

=head1 VERSION

Version 0.6

=cut

our $VERSION = '0.6';

=head1 SYNOPSIS

This module is designed to scratch a very specific itch - taking a schedule
from a given format (for me, vCal) and constructing an LJ schedule post from 
it. It is designed to be extensible to other input file formats and other
posting methods, although currently only vCal as input and LJ::Simple posting
are supported.

    use LJ::Schedule;

    # Choose the type of schedule to import
    my $cal = LJ::Schedule::Vcal->new({filename => $ARGV[0]});
    $cal->prep_cal_for_lj();

    my $lj = LJ::Schedule::Post->new();
    my $post_ok = $lj->post_cal($cal);

    ...

=head1 FUNCTIONS

=head2 get_config

Reads in the config from the specified config file (.ini style) - defaulting to 
.lj_cfg.ini if the filename isn't given.

Sample config file:

 # Comment line

 [private]
 user=kitty
 pass=XXXXX

 [entry]
 subject='Schedule Post'
 protect=friends

 [alias]
 b=bobt

The above config file will post to journal name 'kitty', authenticating with the
password XXXXX, with a title of 'Schedule Post', protected to friends-only.

The aliases allow a vCal entry such as "Date with B" to be automatically transformed
to an LJ user (in this case, of bobt).

=cut

=head1 AUTHOR

Ben Evans, C<< <ben at bpfh.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-lj-schedule at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LJ-Schedule>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LJ::Schedule

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/LJ-Schedule>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/LJ-Schedule>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=LJ-Schedule>

=item * Search CPAN

L<http://search.cpan.org/dist/LJ-Schedule>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Ben Evans, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

use LJ::Schedule::Vcal;
use LJ::Schedule::Post;

use Config::Simple;

# This package stores our global variables which are largely used by the other
# modules. These are deliberately public to alow the user to alter them as s/he
# sees fit

our $CONFIG;
our $ALIAS;

our $DATE_FMT     = '%o %b: ';

# FIXME config file

our $TAGS         = [];

sub get_config {
    my $fname = shift;
    $fname ||= '.lj_cfg.ini';

    my %cfg;

    # Open the config
    Config::Simple->import_from($fname, \%cfg) or die Config::Simple->error();
    $CONFIG = \%cfg;

    my @keys = keys(%$CONFIG);
    foreach my $k (@keys) {
        next unless $k =~ /^alias\.(.*)/;
        my $name = $1;

        $ALIAS->{$name} = $CONFIG->{'alias.'.$name}
    }

    $DATE_FMT = $CONFIG->{'global.date_format'} if $CONFIG->{'global.date_format'};
}

1;



1; # End of LJ::Schedule
