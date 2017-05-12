package Mail::Chimp2;

use 5.012;
use Mouse;

# ABSTRACT: Mailchimp V2 API

our $VERSION = '0.5'; # VERSION

with 'Web::API';
use Data::Dump;


has 'dc' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { 'us1' },
);

has 'commands' => (
    is      => 'rw',
    default => sub {
        {
            # campaign handling
            campaigns_list => { path => 'campaigns/list' },

            # list handling
            lists_list    => { path => 'lists/list' },
            lists_members => {
                path      => 'lists/members',
                mandatory => ['id']
            },
            lists_batch_subscribe => {
                path      => 'lists/batch-subscribe',
                mandatory => [ 'id', 'batch' ]
            },
            lists_subscribe => {
                path      => 'lists/subscribe',
                mandatory => [ 'id', 'email' ]
            },
            lists_unsubscribe => {
                path      => 'lists/unsubscribe',
                mandatory => [ 'id', 'email' ]
            },

        };
    });


sub commands {
    my ($self) = @_;
    return $self->commands;
}


sub BUILD {
    my ($self) = @_;

    my ($_key, $_dc) = split(/-/, $self->api_key);
    $self->dc($_dc) if $_dc;
    $self->user_agent(__PACKAGE__ . ' ' . $Mail::Chimp2::VERSION);
    $self->strict_ssl(1);
    $self->content_type('application/json');
    $self->default_method('POST');
    $self->extension('json');
    $self->base_url('https://' . $self->dc . '.api.mailchimp.com/2.0');
    $self->auth_type('hash_key');
    $self->api_key_field('apikey');

    return $self;
}


__PACKAGE__->meta->make_immutable();    # End of Mail::Chimp2

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::Chimp2 - Mailchimp V2 API

=head1 VERSION

version 0.5

=head1 SYNOPSIS

This is a very rudimentary start of a Mailchimp API version 2
integration. It will be a complete implementation eventually but for now
all I needed was bulk add addresses to lists, so that is what i covered
so far.

    use Mail::Chimp2;

    my $chimp = Mail::Chimp2->new(
        debug   => 1,
        api_key => 'yourapikey-us1'
    );
    dump $chimp->lists_batch_subscribe(
        id              => 'list_id',
        double_optin    => 'false',
        update_existing => 'true',
        batch           => [ {
                email      => { email => 'me@example.com' },
                merge_vars => { FNAME => 'Me', LNAME => 'Example' } 
        } ]
    );

=head1 ATTRIBUTES

=head2 dc

The datacenter attribute is set to the extension of the API key. You can force
it if you need by setting this attribute.

=head1 INTERNALS

=head2 BUILD

basic configuration for the client API happens usually in the BUILD method when using Web::API

=head1 BUGS

Please report any bugs or feature requests on GitHub's issue tracker L<https://github.com/norbu09/Mail::Chimp2/issues>.
Pull requests welcome.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mail::Chimp2

You can also look for information at:

=over 4

=item * GitHub repository

L<https://github.com/norbu09/Mail::Chimp2>

=item * MetaCPAN

L<https://metacpan.org/module/Mail::Chimp2>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mail::Chimp2>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mail::Chimp2>

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=back

=head1 AUTHOR

Lenz Gschwendtner <lenz@springtimesoft.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by ideegeo Group Limited.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
