package Message::Passing::Role::Input;
use Moo::Role;
use Scalar::Util qw/ blessed /;
use Module::Runtime qw/ require_module /;
use namespace::clean -except => 'meta';

has output_to => (
    is => 'ro',
    required => 1,
    isa => sub { blessed($_[0]) && $_[0]->can('consume') },
    coerce => sub {
        my $val = shift;
        if (ref($val) eq 'HASH') {
            my %stuff = %$val;
            my $class = delete($stuff{class});
            require_module($class);
            $val = $class->new(%stuff);
        }
        $val;
    },
);

1;

=head1 NAME

Message::Passing::Role::Input

=head1 DESCRIPTION

Produces messages.

=head1 ATTRIBUTES

=head2 output_to

Required, must perform the L<Message::Passing::Role::Output> role.

=head1 SEE ALSO

=over

=item L<Message::Passing>

=item L<Message::Passing::Manual::Concepts>

=back

=head1 SPONSORSHIP

This module exists due to the wonderful people at Suretec Systems Ltd.
<http://www.suretecsystems.com/> who sponsored its development for its
VoIP division called SureVoIP <http://www.surevoip.co.uk/> for use with
the SureVoIP API - 
<http://www.surevoip.co.uk/support/wiki/api_documentation>

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing>.

=cut