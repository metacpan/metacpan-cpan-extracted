package IO::Framed::ReadWrite;

use strict;
use warnings;

use parent qw(
    IO::Framed::Read
    IO::Framed::Write
);

sub new {
    my ( $class, $in_fh, $out_fh, $initial_buffer ) = @_;

    my $self = $class->SUPER::new( $in_fh, $initial_buffer );

    $self->{'_out_fh'} = $out_fh || $in_fh,

    return (bless $self, $class)->disable_write_queue();
}

1;
