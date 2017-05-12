package Kelp::Module::Redis;
use Kelp::Base 'Kelp::Module';
use Redis;

our $VERSION = 0.01;

sub build {
    my ( $self, %args ) = @_;
    my $redis = Redis->new(%args);
    $self->register( redis => $redis );
}

1;

__END__

=pod

=head1 NAME

Kelp::Module::Redis - Use Redis within Kelp

=head1 SYNOPSIS

First ...

    # conf/config.pl
    {
        modules      => ['Redis'],
        modules_init => {
            Redis => {
                server => 'redis.example.com:8080',  # example
                name   => 'my_connection_name'       # example
            }
        }
    }

Then ...

    package MyApp;
    use Kelp::Base 'Kelp';

    sub some_route {
        my $self = shift;
        $self->redis->set( key => 'value' );
    }

=head1 REGISTERED METHODS

This module registers only one method into the application: C<redis>.
It is an instance of a L<Redis> class.

=head2 AUTHOR

Stefan Geneshky minimal@cpan.org

=head2 LICENCE

Perl

=cut
