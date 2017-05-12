package Dispatcher::Small;
use 5.010;
use strict;
use warnings;

our $VERSION = "0.02";

sub new {
    my $class = shift;
    return bless +{ @_ }, $class;
}

sub match {
    my ($self, $env) = @_;
    my $i = 0;
    my ($regex, $class, @capture);
    my $path   = $env->{PATH_INFO} || '/';
    my $method = $env->{REQUEST_METHOD};
    while ($regex = $self->{$method}[$i * 2]) {
        if (@capture = $path =~ $regex) {
            return +{ 
                %{ $self->{$method}[$i * 2 + 1] },
                %+ ? %+ : ( capture => [@capture] ),
            };
        }
        $i++;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Dispatcher::Small - Small dispatcher with Regular-Expression

=head1 SYNOPSIS

    use Dispatcher::Small;
    my $ds = Dispatcher::Small->new(
        GET  => [
            qr'^/user/(?<id>.+)' => { action => \&user },
            qr'^/'               => { action => \&root },
        ],
        POST => [
            qr'^/user/(?<id>.+)' => { action => \&user_update },
        ],
    );
    my $res = $ds->match({
       PATH_INFO      => '/user/oreore', 
       REQUEST_METHOD => 'GET',
    }); ### $res = { action => sub {...}, id => 'oreore' }

=head1 DESCRIPTION

"Dispatcher::Small" is a dispatcher class that is written in perl, and is maybe smallest one of them in the world... maybe.

=head1 REQUIREMENT

Dispatcher::Small requires perl-5.10 or later.

=head1 METHODS

=head2 new

    my %dispatch_rule = (
        GET => [
            qr'^/user/(?<id>.+)' => \&user,
            qr'^/'               => \&root,
        ],
        POST => [
            qr'^/user/(?<id>.+)' => \&user_update,
        ],
    );
    my $object = Dispatcher::Small->new( %dispatch_rule );

Constructor method.

=head2 match

    my $res = $object->match($env);

Returns matching result as hashref. $env is environment-values of PSGI.

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

