package Mail::LMLM::Types::Ezmlm;

use strict;
use warnings;

use Mail::LMLM::Types::Base;

use vars qw(@ISA);

@ISA=qw(Mail::LMLM::Types::Base);

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

sub _get_subscribe_address
{
    my $self = shift;

    return $self->group_form("subscribe");
}

sub _get_unsubscribe_address
{
    my $self = shift;

    return $self->group_form("unsubscribe");
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


sub render_something_with_email_addr
{
    my $self = shift;

    my $htmler = shift;
    my $begin_msg = shift;
    my $address_method = shift;


    $htmler->para($begin_msg);
    $htmler->indent_inc();
    $htmler->start_para();
    $htmler->email_address(
        $self->$address_method()
        );
    $htmler->end_para();
    $htmler->indent_dec();

    return 0;
}

sub render_subscribe
{
    my $self = shift;

    my $htmler = shift;

    return $self->render_something_with_email_addr(
        $htmler,
        "Send an empty mail message to the following address: ",
        \&_get_subscribe_address
        );
}

sub render_unsubscribe
{
    my $self = shift;

    my $htmler = shift;

    return $self->render_something_with_email_addr(
        $htmler,
        "Send an empty mail message to the following address: ",
        \&_get_unsubscribe_address
        );
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

Mail::LMLM::Types::Ezmlm - mailing list type for ezmlm-based mailing lists.

=head1 METHODS

=head2 group_form

Creates a group-based form (like C<mygroup-subscribe@myhost.tld> or
C<mygroup-owner@myhost.tld>) for the mailing list.

=head2 render_something_with_email_addr

Internal method.

=head2 render_subscribe

Over-rides the equivalent from L<Mail::LMLM::Types::Base>.

=head2 render_unsubscribe

Over-rides the equivalent from L<Mail::LMLM::Types::Base>.

=head2 render_post

Over-rides the equivalent from L<Mail::LMLM::Types::Base>.

=head2 render_owner

Over-rides the equivalent from L<Mail::LMLM::Types::Base>.

=head1 SEE ALSO

L<Mail::LMLM::Types::Base>

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>.

