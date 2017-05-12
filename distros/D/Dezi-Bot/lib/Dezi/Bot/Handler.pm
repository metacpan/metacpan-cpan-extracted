package Dezi::Bot::Handler;
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use base qw( SWISH::Prog::Class );

our $VERSION = '0.003';

=head1 NAME

Dezi::Bot::Handler - web crawler handler

=head1 SYNOPSIS

 use Dezi::Bot::Handler;
 my $handler = Dezi::Bot::Handler->new();
 $handler->handle( $swish_prog_doc );

=head1 DESCRIPTION

The Dezi::Bot::Handler manages each doc the crawler
successfully encounters.

=head1 METHODS

=head2 new( I<config> )

Returns a new Dezi::Bot::Handler object. Each
subclass may define its own definition for I<config>.

=cut

=head2 handle( I<bot>, I<doc> )

Subclasses are expected to override this method.
The default behavior is to print the I<doc>->uri
to stderr.

=cut

sub handle {
    my $self = shift;
    my $bot  = shift;
    my $doc  = shift;
    warn
        sprintf( "[%s] %s crawled %s\n", $$, $bot->spider->agent, $doc->url );
}

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


