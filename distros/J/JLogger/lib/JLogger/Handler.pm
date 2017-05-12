package JLogger::Handler;

use strict;
use warnings;

sub new {
    my $class = shift @_;
    bless {@_}, $class;
}

1;
__END__

=head1 NAME

JLogger::Handler - handle data from jabber server.

=head1 DESCRIPTION

This is a base class for data handlers.

=cut
