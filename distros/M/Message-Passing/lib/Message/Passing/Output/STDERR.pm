package Message::Passing::Output::STDERR;
use Moo;
use namespace::clean -except => 'meta';

with 'Message::Passing::Role::Output';

sub consume {
    my $self = shift;
    local $|=1;
    print STDERR shift() . "\n";
}


1;

=head1 NAME

Message::Passing::Output::STDOUT - STDOUT output

=head1 SYNOPSIS

    message-pass --input STDIN --output STDERR
    {"foo": "bar"}
    {"foo":"bar"}

=head1 DESCRIPTION

Output messages to STDERR

=head1 METHODS

=head2 consume

Consumes a message by printing it, followed by \n

=head1 SEE ALSO

L<Message::Passing>

=head1 SPONSORSHIP

This module exists due to the wonderful people at Suretec Systems Ltd.
<http://www.suretecsystems.com/> who sponsored its development for its
VoIP division called SureVoIP <http://www.surevoip.co.uk/> for use with
the SureVoIP API - 
<http://www.surevoip.co.uk/support/wiki/api_documentation>

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing>.

=cut