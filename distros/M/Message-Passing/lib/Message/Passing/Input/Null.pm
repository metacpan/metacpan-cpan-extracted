package Message::Passing::Input::Null;
use Moo;
use AnyEvent;
use Try::Tiny;
use namespace::clean -except => 'meta';

with 'Message::Passing::Role::Input';


1;

=head1 NAME

Message::Passing::Input::Null - Null input

=head1 SYNOPSIS

    message-pass --input Null --output STDOUT
    # Nothing ever happens..

=head1 DESCRIPTION

Does nothing (for testing).

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