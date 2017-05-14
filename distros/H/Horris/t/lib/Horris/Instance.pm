package Horris::Instance;
use strict;
use warnings;
use Horris::Connection;

# ABSTRACT: module for horris test

=head1 METHODS

=head2 new

make a new instance for plugin test

=cut

sub new {
    my ($class, $plugins) = @_;
    my $self->{conn} = Horris::Connection->new(
        nickname => '', 
        port     => '', 
        password => '', 
        server   => '', 
        username => '', 
        plugins	 => $plugins
    );

    bless $self, $class;
}

1;
