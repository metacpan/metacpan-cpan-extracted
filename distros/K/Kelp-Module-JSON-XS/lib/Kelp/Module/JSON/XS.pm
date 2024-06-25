package Kelp::Module::JSON::XS;
use Kelp::Base 'Kelp::Module::Encoder';
use JSON::XS;

our $VERSION = '0.503';

sub encoder_name { 'json' }

sub build_encoder {
    my ($self, $args) = @_;
    my $json = JSON::XS->new;

    for my $key (keys %{$args}) {
        $json->$key($args->{$key});
    }

    return $json;
}

sub build {
    my ( $self, %args ) = @_;
    $self->SUPER::build(%args);

    $self->register(json => $self->get_encoder);
}

1;

__END__

=head1 NAME

Kelp::Module::JSON::XS - DEPRECATED JSON:XS module for Kelp applications

=head1 DEPRECATED

B<*** This module is now deprecated. ***>

Kelp is now using L<JSON::MaybeXS>, which will automatically choose the most
fitting backend for JSON.

Kelp used L<JSON> module before that. Beginning with version 2.0 of the JSON
module, when both JSON and JSON::XS are installed, then JSON will fall back on
JSON::XS

=head1 SYNOPSIS

    package MyApp;
    use Kelp::Base 'Kelp';

    sub some_route {
        my $self = shift;
        return $self->json->encode( { success => \1 } );
    }

=head1 REGISTERED METHODS

This module registers only one method into the application: C<json>.

=head2 CONFIGURATION

In C<conf/config.pl>:

    {
        modules      => ['JSON:XS'],    # And whatever else you need
        modules_init => {
            'JSON::XS' => {
                pretty        => 1,
                allow_blessed => 1
                # And whetever else you want
            }
        }
    }

=head2 AUTHOR

Stefan Geneshky minimal@cpan.org

=head2 LICENCE

Perl

=cut

