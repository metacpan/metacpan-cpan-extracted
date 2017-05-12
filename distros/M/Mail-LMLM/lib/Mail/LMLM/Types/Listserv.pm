package Mail::LMLM::Types::Listserv;

use strict;
use warnings;

use Mail::LMLM::Types::Base;

use vars qw(@ISA);

@ISA=qw(Mail::LMLM::Types::Base);

sub _get_post_address
{
    my $self = shift;

    return ($self->get_group_base(), $self->get_hostname());
}

sub _get_owner_address
{
    my $self = shift;

    return (('owner-' . $self->get_group_base()) , $self->get_hostname());
}

sub render_mail_management
{
    my $self = shift;

    my $htmler = shift;
    my $begin_msg = shift;
    my $line_prefix = shift;

    $htmler->para($begin_msg . " write a message with the following line as body:");
    $htmler->indent_inc();
    $htmler->para(($line_prefix. " " . $self->get_group_base()), { 'bold' => 1});
    $htmler->indent_dec();
    $htmler->para("to the following address:");
    $htmler->indent_inc();
    $htmler->start_para();
    $htmler->email_address(
        "listserv", $self->get_hostname()
        );
    $htmler->end_para();
    $htmler->indent_dec();

    return 0;
}

sub render_subscribe
{
    my $self = shift;

    my $htmler = shift;

    return $self->render_mail_management(
        $htmler,
        "To subscribe",
        "subscribe"
        );
}

sub render_unsubscribe
{
    my $self = shift;

    my $htmler = shift;

    return $self->render_mail_management(
        $htmler,
        "To unsubscribe",
        "signoff"
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

Mail::LMLM::Types::Listserv - mailing list type for listserv.

=head1 METHODS

=head2 render_mail_management

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

