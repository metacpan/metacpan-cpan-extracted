package Mail::LMLM::Types::GoogleGroups;

use strict;
use warnings;

use Mail::LMLM::Types::Mailman;

use vars qw(@ISA);

@ISA=qw(Mail::LMLM::Types::Mailman);

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

    $self->{'google_homepage'} =
        "http://groups.google.com/group/" . $self->get_group_base(). "/";

    $self->{'homepage'} = $self->{'google_homepage'};

    return \@left;
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
        return $self->{'google_homepage'};
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

sub get_default_hostname
{
    return "googlegroups.com";
}

sub get_online_archive
{
    my $self = shift;

    return $self->SUPER::get_online_archive()
        || $self->get_maintenance_url();
}
1;

__END__

=head1 NAME

Mail::LMLM::Types::GoogleGroups - mailing list type for Google groups mailing
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


=head2 get_default_hostname

The default hostname. Internal method.

=head2 get_online_archive

The online archive. Internal method.

=head1 SEE ALSO

L<Mail::LMLM::Types::Base>

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>.

