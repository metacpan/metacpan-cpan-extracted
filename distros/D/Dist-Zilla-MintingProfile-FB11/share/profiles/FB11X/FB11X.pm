package {{ $name }};

use Moose::Role;
use CatalystX::InjectComponent;
use namespace::autoclean;

with 'OpusVL::FB11::RolesFor::Plugin';

# ABSTRACT: A brand new FB11 plugin!
our $VERSION = '0';
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
