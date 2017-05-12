package Mail::LMLM::Types::Mailman;

use strict;
use warnings;

use Mail::LMLM::Types::Base;

use vars qw(@ISA);

@ISA=qw(Mail::LMLM::Types::Base);

sub parse_args
{
    my $self = shift;

    my $args = shift;

    $args = $self->SUPER::parse_args($args);

    my (@left, $key, $value);

    while (scalar(@$args))
    {
        $key = shift(@$args);
        $value = shift(@$args);

        if ($key =~ /^-?(maintenance[-_]url)$/)
        {
            $self->{'maintenance_url'} = $value;
        }
        elsif ($key =~ /^-?(owner)$/)
        {
            $self->{'owner'} = $value;
        }
        else
        {
            push @left, $key, $value;
        }
    }

    return \@left;


    return $args;
}

sub get_maintenance_url
{
    my $self = shift;

    if (exists($self->{'maintenance_url'}))
    {
        return $self->{'maintenance_url'};
    }
    else
    {
        return $self->{'homepage'} . "mailman/listinfo/" . $self->get_group_base(). "/";
    }

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

sub _get_post_address
{
    my $self = shift;

    return $self->group_form();
}

sub _get_owner_address
{
    my $self = shift;

    if ($self->{owner})
    {
        return @{$self->{owner}};
    }
    else
    {
        return $self->group_form("owner");
    }
}

sub render_maint_url
{
    my $self = shift;
    my $htmler = shift;

    $htmler->start_para();
    $htmler->text("Go to ");
    $htmler->url($self->get_maintenance_url(), "to the maintenance URL");
    $htmler->text(" and follow the instructions there.");
    $htmler->end_para();

    return 0;
}

sub render_subscribe
{
    my $self = shift;

    my $htmler = shift;

    return $self->render_maint_url($htmler);
}

sub render_unsubscribe
{
    my $self = shift;

    my $htmler = shift;

    return $self->render_maint_url($htmler);
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

Mail::LMLM::Types::Mailman - mailing list type for Mailman-based mailing
lists.

=head1 METHODS

=head2 parse_args

Internal method, over-rides the L<Mail::LMLM::Types::Base>.

=head2 get_maintenance_url

Calculates the URL for the Mailman admin web-interface.

=head2 group_form

Calculates the group form.

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

