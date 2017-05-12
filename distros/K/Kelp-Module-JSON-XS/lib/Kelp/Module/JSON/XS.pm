package Kelp::Module::JSON::XS;
use Kelp::Base 'Kelp::Module';
use JSON::XS;
use Carp;

our $VERSION = 0.502;

sub build {
    my ( $self, %args ) = @_;
    my $json = JSON::XS->new;

    # JSON::XS doesn't seem to have a property method
    my $opts = join '->', map { "${_}($args{$_})" } keys %args;
    if ( $opts ) {
        local $@;
        eval "\$json->$opts;";
        croak $@ if $@;
    }

    $self->register( json => $json );
}

1;

__END__

=head1 NAME

Kelp::Module::JSON::XS - JSON:XS module for Kelp applications

=head1 DEPRECATED

*** This module is now deprecated. ***
Beginning with version 2.0 of the JSON module, when both JSON and
JSON::XS are installed, then JSON will fall back on JSON::XS

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

