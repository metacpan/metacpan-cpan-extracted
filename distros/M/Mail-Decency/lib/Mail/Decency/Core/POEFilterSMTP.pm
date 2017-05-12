package Mail::Decency::Core::POEFilterSMTP;

use strict;
use warnings;

use version 0.74; our $VERSION = qv( "v0.1.4" );

use Data::Dumper;

use base qw/ POE::Filter::Line /;

=head1 NAME

Mail::Decency::Core::POEFilterSMTP

=head1 DESCRIPTION

Filters incoming data, based on POE::Filter::Line

Each incoming line will be splitted into a trippled, where the first value contains the first word in uppercase, the second value the rest of the line (original case) and the last value the whole original line

The first and second values are made for handling the SMTP protocol, whereas the last value has to assure the correct (upper/lower)case of the send DATA.

This is based on: L<POE::Component::Server::SimpleSMTP> .. yes, it is reinventing the wheel, but somehow i have to understand this!

=cut

use constant CRLF => qq/\x0D\x0A/; # RFC 2821, 2.3.7

=head1 METHODS

=head2 new

Create new filter, derived from POE::Filter::Line

=cut

sub new {
    my ($class) = @_;
    return $class->SUPER::new( Literal => CRLF );
}


=head2 get_one

Handle incoming lines

=cut

sub get_one {
    my ($self) = shift;
    my $lines = $self->SUPER::get_one( @_ );
    
    foreach my $line ( @$lines ) {
        my ($command, $data) = split( /\s+/, $line, 2 );
        $data =~ s/\s+$// if $data;
        #print "IN> $line\n";
        $line = [ uc( $command ), $data, $line. CRLF ];
    }
    
    return $lines;
}


=head2 put

Handle output content

=cut

sub put {
    my ($self, $lines) = @_;
    
    my $code = shift @{$lines};
    
    # return
    #   250 OK
    if ( $#$lines == 0 ) {
        return $self->SUPER::put( [ "$code @{$lines}" ] );
    }
    
    # return
    #   250-something
    #   250 OK
    my @output;
    push @output, "$code-$lines->[$_]" for 0 .. $#$lines - 1;
    push @output, "$code $lines->[-1]";
    
    return $self->SUPER::put( \@output );
}


=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut

1;
