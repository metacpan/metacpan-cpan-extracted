package {{ $name }};

use Moose::Role;
use CatalystX::InjectComponent;
use namespace::autoclean;

with 'OpusVL::AppKit::RolesFor::Plugin';

our $VERSION = '0.01';
{{ 
    ($controller) = ($name =~ /::([^:]+)$/); ''
}}
after 'setup_components' => sub {
    my $class = shift;
   
    $class->add_paths(__PACKAGE__);
    
    # .. inject your components here ..
    CatalystX::InjectComponent->inject(
        into      => $class,
        component => '{{ $name }}::Controller::{{ $controller }}',
        as        => 'Controller::{{ $controller }}'
    );
};

1;

=head1 NAME

{{ $name }} - A brand new AppKitX component

=head1 DESCRIPTION

Frobnicates the whirligigs in a modular and reusable pattern

=head1 COPYRIGHT and LICENSE

Copyright (C) 2015 OpusVL

This software is licensed according to the "IP Assignment Schedule" provided with the development project.
