# NAME

Dispatcher::Small - Small dispatcher with Regular-Expression

# SYNOPSIS

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

# DESCRIPTION

"Dispatcher::Small" is a dispatcher class that is written in perl, and is maybe smallest one of them in the world... maybe.

# REQUIREMENT

Dispatcher::Small requires perl-5.10 or later.

# METHODS

## new

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

## match

    my $res = $object->match($env);

Returns matching result as hashref. $env is environment-values of PSGI.

# LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ytnobody <ytnobody@gmail.com>
