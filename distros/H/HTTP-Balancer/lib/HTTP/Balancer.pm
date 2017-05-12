package HTTP::Balancer;

our $VERSION = '0.0.2';

use Modern::Perl;

use Moose;
use MooseX::Singleton;

use HTTP::Balancer::Command;

sub run {
    my ($self, ) = @_;

    HTTP::Balancer::Command
    ->dispatch(@ARGV)
    ->new_with_options
    ->prepare()
    ->run();
}

1;
__END__

=head1 NAME

HTTP::Balancer - manage your http load balancer in seconds

=head1 SYNOPSIS

  use HTTP::Balancer;

  HTTP::Balancer->new->run;

=head1 DESCRIPTION

HTTP::Balancer is

=head1 AUTHOR

shelling E<lt>navyblueshellingford@gmail.comE<gt>

=head1 SEE ALSO

L<Namespace::Dispatch>
L<MooseX::Getopt>

=head1 LICENSE

Copyright (C) shelling

The MIT License

=cut
