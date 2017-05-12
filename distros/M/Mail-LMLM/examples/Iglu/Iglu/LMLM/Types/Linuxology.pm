package Iglu::LMLM::Types::Linuxology;

use strict;
use warnings;

use Mail::LMLM::Types::Base;

use vars qw(@ISA);

@ISA=qw(Mail::LMLM::Types::Base);

sub get_address
{
    my $self = shift;

    return ($self->get_group_base(), $self->get_hostname());
}

sub render_something_with_subject
{
    my $self = shift;

    my $htmler = shift;
    my $subject = shift;

    $htmler->para("Send a message to the following E-mail address:");
    $htmler->indent_inc();
    $htmler->start_para();
    $htmler->email_address(
        $self->get_address()
        );
    $htmler->end_para();
    $htmler->indent_dec();
    $htmler->para("With the following subject:");
    $htmler->indent_inc();
    $htmler->para($subject, { 'bold' => 1 });
    $htmler->indent_dec();

    return 0;
}

sub render_subscribe
{
    my $self = shift;

    my $htmler = shift;

    return $self->render_something_with_subject($htmler, "subscribe");
}

sub render_unsubscribe
{
    my $self = shift;

    my $htmler = shift;

    return $self->render_something_with_subject($htmler, "unsubscribe");
}

sub render_post
{
    my $self = shift;

    my $htmler = shift;

    return $self->render_something_with_subject($htmler, "stuff");
}

sub render_owner
{
    my $self = shift;

    my $htmler = shift;

    return $self->render_something_with_subject($htmler, "comments");
}
