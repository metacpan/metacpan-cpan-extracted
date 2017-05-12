package IPC::Transit::Router;
{
  $IPC::Transit::Router::VERSION = '1.132260';
}

use strict;use warnings;
use 5.006;
use Message::Router qw(mroute mroute_config);
use IPC::Transit;
require Exporter;
use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(troute troute_config);

sub troute {
    my $message = shift;
    return mroute($message);
}
sub troute_config {
    my $new_config = shift;
    foreach my $route (@{$new_config->{routes}}) {
        foreach my $forward (@{$route->{forwards}}) {
            $forward->{handler} = 'IPC::Transit::Router::handler';
        }
    }
    return mroute_config($new_config);
}

sub handler {
    my %args = @_;
    if($args{forward}->{destination}) {
        return IPC::Transit::send(
            message => $args{message},
            qname => $args{forward}->{qname},
            destination => $args{forward}->{destination},
        );
    } else {
        return IPC::Transit::send(message => $args{message}, qname => $args{forward}->{qname});
    }
}
1;

__END__
=head1 NAME

IPC::Transit::Router - Allows fast, simple routing of Transit messages

=head1 SYNOPSIS

    use IPC::Transit;
    use IPC::Transit::Router qw(troute troute_config);
    troute_config({
        routes => [
            {   match => {
                    a => 'b',
                },
                forwards => [
                    {   qname => 'some_q' }
                ],
                transform => {
                    x => 'y',
                },
            }
        ],
    });
    troute({a => 'b'});
    my $ret = IPC::Transit::receive(qname => 'some_q');
    #$ret contains { a => 'b', x => 'y' }

=head1 DESCRIPTION

This library allows fast, simple routing of Transit messages

=head1 FUNCTION

=head2 troute_config($config);

The config used by all mroute calls

=head2 troute($message);

Pass $message through the config; this will emit zero or more IPC::Transit
messages.

=head1 TODO

A config validator.

=head1 BUGS

None known.

=head1 AUTHOR

Dana M. Diederich <diederich@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2012,2013 Dana M. Diederich.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

