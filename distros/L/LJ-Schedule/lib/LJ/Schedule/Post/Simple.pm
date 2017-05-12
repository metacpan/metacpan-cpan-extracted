package LJ::Schedule::Post::Simple;

use warnings;
use strict;

use base qw(LJ::Schedule::Post);

use LJ::Simple;

=head1 NAME

LJ::Schedule::Post::Simple - The default LJ::Schedule posting component.

=head1 VERSION

Version 0.6

=cut

our $VERSION = '0.6';

=head1 SYNOPSIS

This module is used internally by LJ::Schedule, and shouldn't need to be
used directly.

=head1 AUTHOR

Ben Evans, C<< <ben at bpfh.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-lj-schedule-post-simple at rt.cpan.org>, or through the web interface at
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

#
# Default constructor
#
sub new {
    my ($pkg, $params) = @_;
    my $self = {};

    $self = $params if (ref($params) eq 'HASH');
    bless $self, $pkg;

    return $self;
}

#
# Actually does the post
#
sub post_cal {
    my $self = shift;
    my $cal  = shift;

    my $post_content = $self->output_cal_for_lj($cal);

#    print STDERR "In post_cal(): \n-------\n", $post_content, "\n\n";

    my $rh_res = {};

    my %lj_params = (
                     user    =>      $LJ::Schedule::CONFIG->{'private.user'},
                     pass    =>      $LJ::Schedule::CONFIG->{'private.pass'},
                     entry   =>      $post_content,
                     subject =>      $LJ::Schedule::CONFIG->{'entry.subject'},
                     html    =>      1,
                     protect =>      $LJ::Schedule::CONFIG->{'entry.protect'},
                     results =>      $rh_res,
                     );

    if (scalar(@{$LJ::Schedule::TAGS}) > 0) {
        %lj_params = (%lj_params, 'tags' => $LJ::Schedule::TAGS);
    }

    my $post_ok = LJ::Simple::QuickPost(%lj_params) || die "$0: Failed to post entry: $LJ::Simple::error\n";

# Currently unimplemented - will do if wanted
#               mood    =>      Current mood
#               music   =>      Current music
#               groups  =>      Friends groups list


    return $post_ok;
}


1; # End of LJ::Schedule::Post::Simple
