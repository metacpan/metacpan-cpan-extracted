package Hiredis::Raw::Constants;
BEGIN {
    $Hiredis::Raw::Constants::VERSION = '0.07';
}
use strict;
use warnings;

my %CONSTANTS;

BEGIN {
    %CONSTANTS = (
        REDIS_ERR           => -1,
        REDIS_OK            => 0,
        REDIS_ERR_IO        => 1,
        REDIS_ERR_EOF       => 3,
        REDIS_ERR_PROTOCOL  => 4,
        REDIS_ERR_OTHER     => 2,
        REDIS_BLOCK         => 0x1,
        REDIS_CONNECTED     => 0x2,
        REDIS_DISCONNECTING => 0x4,
        REDIS_FREEING       => 0x8,
        REDIS_IN_CALLBACK   => 0x10,
        REDIS_SUBSCRIBED    => 0x20,
        REDIS_REPLY_STRING  => 1,
        REDIS_REPLY_ARRAY   => 2,
        REDIS_REPLY_INTEGER => 3,
        REDIS_REPLY_NIL     => 4,
        REDIS_REPLY_STATUS  => 5,
        REDIS_REPLY_ERROR   => 6,
    );

    no strict 'refs';
    for my $k (keys %CONSTANTS){
        *{$k} = sub () { $CONSTANTS{$k} };
    }
};

use Sub::Exporter -setup => {
    exports => [ keys %CONSTANTS ],
};

1;

__END__

=pod

=head1 NAME

Hiredis::Raw::Constants

=head1 CONSTANTS

=head2 REDIS_ERR

=head2 REDIS_OK

=head2 REDIS_ERR_IO

=head2 REDIS_ERR_EOF

=head2 REDIS_ERR_PROTOCOL

=head2 REDIS_ERR_OTHER

=head2 REDIS_BLOCK

=head2 REDIS_CONNECTED

=head2 REDIS_DISCONNECTING

=head2 REDIS_FREEING

=head2 REDIS_IN_CALLBACK

=head2 REDIS_SUBSCRIBED

=head2 REDIS_REPLY_STRING

=head2 REDIS_REPLY_ARRAY

=head2 REDIS_REPLY_INTEGER

=head2 REDIS_REPLY_NIL

=head2 REDIS_REPLY_STATUS

=head2 REDIS_REPLY_ERROR

=head1 SEE ALSO

L<Hiredis::Raw>
