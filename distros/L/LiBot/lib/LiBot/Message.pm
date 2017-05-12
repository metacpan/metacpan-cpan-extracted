package LiBot::Message;
use strict;
use warnings;
use utf8;

use Mouse;

has text => (is => 'ro', isa => 'Str', required => 1);
has nickname => (is => 'ro', isa => 'Str', required => 1);

no Mouse;

1;
__END__

=head1 NAME

LiBot::Message - The message object

=head1 DESCRIPTION

This is a message object for LiBot.

=head1 ACCESSORS

=over 4

=item text

Message text

=item nickname

Message owner's name.

=back

