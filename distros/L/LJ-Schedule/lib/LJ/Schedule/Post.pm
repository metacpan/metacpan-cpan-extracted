package LJ::Schedule::Post;

use warnings;
use strict;

=head1 NAME

LJ::Schedule::Post - The 'abstract base' for LJ::Schedule posting components

=head1 VERSION

Version 0.6

=cut

our $VERSION = '0.6';

=head1 SYNOPSIS

This module is used internally by LJ::Schedule, and shouldn't need to be
used directly.

It is an 'abstract' module, ie it is expected to be subclassed to provide
different posting functionalities. Currently the only one supported is 
LJ::Simple

=head1 AUTHOR

Ben Evans, C<< <ben at bpfh.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-lj-schedule-post at rt.cpan.org>, or through the web interface at
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

    use LJ::Schedule::Post::Simple;

use Config::Tiny;
use Date::Format;

# TMP
use Data::Dumper;

our $SECS_IN_DAY  = 60 * 60 * 24;
our $SECS_IN_WEEK = 60 * 60 * 24 * 7;
our @DAY_NAMES    = qw(Sun Mon Tue Wed Thu Fri Sat);

# Names of packages to dispatch to.
# Essentially plumbing for if we need to add additional
# posting modules
my $rh_dispatch = {
    simple => 'LJ::Schedule::Post::Simple',
};

#
# Standard constructor
#
sub new {
    my ($pkg, $params) = @_;
    my $rh_p = {};

    $rh_p = $params if (ref($params) eq 'HASH');
    my $class = $rh_dispatch->{simple};

    if ($rh_p->{post}) {
        $class ||= $rh_dispatch->{$rh_p->{post}};
    }

    my $self = $class->new($rh_p);

    # Setup the config file if it hasn't been done already
    LJ::Schedule::get_config() unless defined $LJ::Schedule::CONFIG;

    return $self;
}

#
# Alias an event (eg add lj-user tags) for a post being built up.
#
sub do_summary_aliasing {
    my $self = shift;
    my $raw  = shift;

    my $out = $raw;

    my @keys = keys(%$LJ::Schedule::ALIAS);
    foreach (@keys) {
        $out =~ s/^$_(\W+)/<lj user="$LJ::Schedule::ALIAS->{$_}">$1 /gi;
        $out =~ s/\s+$_(\W+)/ <lj user="$LJ::Schedule::ALIAS->{$_}">$1/gi;
        $out =~ s/\s+$_$/ <lj user="$LJ::Schedule::ALIAS->{$_}">/gi;
    }

    return $out;
}

#
# Format an event for adding to a post being built up
#
sub lj_add_event {
    my $self = shift;
    my $evt = shift;

    my @j = localtime($evt->{tval});
    my $wday = $j[6];

    my $summary = $self->do_summary_aliasing($evt->{summary});

    return $DAY_NAMES[$wday]. ' '. $evt->{date}.' '. $summary. " <br>\n";
}

#
# Helper method
#
sub lj_add_week_break {
    my $self = shift;
    my $evt = shift;

    return "\n<br>\n";
}

#
# Main post building method
#
sub output_cal_for_lj {
    my $self = shift;
    my $cal  = shift;

    my $ra_evts = $cal->evts();

    my $out = "<lj-cut text='Schedule'>\n";

    # This gets the day of week. 0 is Sunday, 1 is monday, etc.
    my @junk = localtime(time());
    my $today_wday = $junk[6];

    # Set up the first event's output
    my $last_evt = shift(@$ra_evts);
    $out .= $self->lj_add_event($last_evt);

    foreach my $evt (@$ra_evts) {
        if ($evt->{tval} - $last_evt->{tval} >= $SECS_IN_WEEK) {
            $out .= lj_add_week_break();
        } else {
            my @j = localtime($last_evt->{tval});
            my $lwday = $j[6];

            @j = localtime($evt->{tval});
            my $wday = $j[6];

            if ( ($wday < $lwday) && ($wday >= 0) ) {
                $out .= $self->lj_add_week_break();
            }
        }

        $out .= $self->lj_add_event($evt);
        $last_evt = $evt;
    }

    $out .= "</lj-cut>\n";

    return $out;
}




1; # End of LJ::Schedule::Post
