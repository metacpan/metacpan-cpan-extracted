package Mail::LMLM::Types::Listar;

use strict;
use warnings;

use vars qw(@ISA);

@ISA=qw(Mail::LMLM::Types::Base);

sub parse_args
{
    my $self = shift;

    my $args = shift;

    $args = $self->SUPER::parse_args($args);

    return $args;
}

sub group_form
{
    my $self = shift;

    my $add = shift;

    return (
        ( $self->get_group_base() .
        ($add ? ("-" . $add) : "") )
        ,
        $self->get_hostname()
        );
}

sub get_request_address
{
    my $self = shift;

    return $self->group_form("request");
}

sub _get_post_address
{
    my $self = shift;

    return $self->group_form();
}

sub _get_owner_address
{
    my $self = shift;

    return $self->group_form("owner");
}

sub render_sub_or_unsub
{
    my $self = shift;

    my $htmler = shift;

    my $command = shift;

    $htmler->para("Send a message containing the following line:");
    $htmler->indent_inc();
    $htmler->para("$command", {'bold' => 1});
    $htmler->indent_dec();
    $htmler->para("To the following address:");
    $htmler->indent_inc();
    $htmler->email_address(
        $self->get_request_address()
        );
    $htmler->indent_dec();

    return 0;
}

sub render_subscribe
{
    my $self = shift;

    my $htmler = shift;

    return $self->render_sub_or_unsub($htmler, "subscribe");
}

sub render_unsubscribe
{
    my $self = shift;

    my $htmler = shift;

    return $self->render_sub_or_unsub($htmler, "unsubscribe");
}

sub render_post
{
    my $self = shift;

    my $htmler = shift;

    return $self->render_something_with_email_addr(
        $htmler,
        "Send your messages to the following address: ",
        \&_get_post_address
        );
}

sub render_owner
{
    my $self = shift;

    my $htmler = shift;

    return $self->render_something_with_email_addr(
        $htmler,
        "Send messages to the mailing-list owner to the following address: ",
        \&_get_owner_address
        );
}

1;

__END__

=head1 NAME

Mail::LMLM::Types::Listar - mailing list type for Listar-based mailing
lists.

=head1 METHODS

=head2 parse_args

Internal method, over-rides the L<Mail::LMLM::Types::Base>.

=head2 get_request_address

Calculates the request address

=head2 group_form

Calculates the group form.

=head2 render_sub_or_unsub

Internal method.

=head2 render_subscribe

Over-rides the equivalent from L<Mail::LMLM::Types::Base>.

=head2 render_unsubscribe

Over-rides the equivalent from L<Mail::LMLM::Types::Base>.

=head2 render_post

Over-rides the equivalent from L<Mail::LMLM::Types::Base>.

=head2 render_owner

Over-rides the equivalent from L<Mail::LMLM::Types::Base>.

=head2 render_maint_url

Render a maintenance URL. Internal method.


=head1 SEE ALSO

L<Mail::LMLM::Types::Base>

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>.

