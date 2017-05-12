package Dezi::Stats::File;

use warnings;
use strict;
use base 'Dezi::Stats';
use Carp;
use Log::Dispatchouli;
use JSON;

our $VERSION = '0.001006';

=head1 NAME

Dezi::Stats::File - store Dezi statistics via Log::Dispatchouli

=head1 SYNOPSIS

 # see Dezi::Stats

=head1 DESCRIPTION

Dezi::Stats::File logs statistics using Log::Dispatchouli.

=head1 METHODS

=head2 init_store()

Required method. Initializes the internal Log::Dispatchouli object.
You can pass any params supported by Log::Dispatchouli->new()
directly to Dezi::Stats->new().

=cut

sub init_store {
    my $self = shift;
    my $path = delete $self->{path} or croak "path required";
    my %args = %$self;
    $args{ident} ||= 'dezi-stats';

    # TODO filter out any that LD doesn't support
    $self->{dispatcher} = Log::Dispatchouli->new( \%args, );
    return $self;
}

=head2 dispatcher

Returns the internal Log::Dispatchouli object.

=cut

sub dispatcher {
    my $self = shift;
    return $self->{dispatcher};
}

=head2 insert( I<hashref> )

Writes I<hashref> encoded as JSON to the dispatcher()->log method.

=cut

sub insert {
    my $self = shift;
    my $row = shift or croak "hashref required";
    $self->{dispatcher}->log( encode_json($row) );
    return $row;
}

1;

__END__

=head1 SEE ALSO

L<Log::Dispatchouli>

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dezi-stats at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dezi-Stats>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dezi::Stats


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-Stats>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dezi-Stats>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dezi-Stats>

=item * Search CPAN

L<http://search.cpan.org/dist/Dezi-Stats/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2012 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

