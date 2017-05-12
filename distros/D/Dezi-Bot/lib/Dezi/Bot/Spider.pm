package Dezi::Bot::Spider;
use strict;
use warnings;
use base qw( SWISH::Prog::Aggregator::Spider );
use Carp;

our $VERSION = '0.003';

=head1 NAME

Dezi::Bot::Spider - web spider

=head1 SYNOPSIS

 use Dezi::Bot::Spider;

 my $spider = Dezi::Bot::Spider->new(); 
 $spider->crawl( 'http://dezi.org/' ); 

=head1 DESCRIPTION

The Dezi::Bot::Spider is a subclass of L<SWISH::Prog::Aggregator::Spider>.

=head1 METHODS

Only new or overridden methods are documented here.
See L<SWISH::Prog::Aggregator::Spider>.

=cut

=head2 init( I<args> )

Internal method for initializing object. I<args> are passed
through to L<SWISH::Prog::Aggregator::Spider> constructor.

=cut

sub init {
    my $self = shift;
    my %args = @_;

    # our defaults
    $args{agent} ||= sprintf( "dezibot/%s-%s", $VERSION, $$ );
    $args{email} ||= 'bot@dezi.org';

    $self->SUPER::init(%args);

    return $self;
}

=head2 add_to_queue( I<uri> )

Add I<uri> to the queue.

=cut

sub add_to_queue {
    my $self = shift;
    my $uri = shift or croak "uri required";
    return $self->queue->put( "$uri", client_name => $self->agent, );
}

# These aren't needed yet. here for reference.

#=head2 next_from_queue
#
#Return next I<uri> from queue.
#
#=cut
#
#sub next_from_queue {
#    my $self = shift;
#    return $self->queue->get();
#}
#
#=head2 left_in_queue
#
#Returns queue()->size().
#
#=cut
#
#sub left_in_queue {
#    return shift->queue->size();
#}
#
#=head2 remove_from_queue( I<uri> )
#
#Calls queue()->remove(I<uri>).
#
#=cut
#
#sub remove_from_queue {
#    my $self = shift;
#    my $uri = shift or croak "uri required";
#    return $self->queue->remove($uri);
#}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dezi-bot at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dezi-Bot>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dezi::Bot


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-Bot>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dezi-Bot>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dezi-Bot>

=item * Search CPAN

L<http://search.cpan.org/dist/Dezi-Bot/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2013 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut


