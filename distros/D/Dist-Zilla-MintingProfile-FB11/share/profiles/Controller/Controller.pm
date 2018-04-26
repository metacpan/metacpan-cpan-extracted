package {{ $name }};
{{ @bits = split(/::/, $name); $basename = $bits[-1] ; ''
}}
use v5.20;
use strict;
use warnings;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; };
with 'OpusVL::FB11::RolesFor::Controller::GUI';

__PACKAGE__->config
(
# The title of the top-level menu. Controllers with the same name go under the same menu.
fb11_name                 => '{{ @dnbits = split(/-/, $dist->name) ; $dnbits[-1] }}',
# Choose a Font Awesome icon and drop the fa_ for the main menu icon
fb11_icon                 => 'asterisk',
# Used by File::ShareDir to find your templates
fb11_myclass              => '{{$dist->name =~ s/-/::/gr}}',
# TODO: What is this for?
fb11_shared_module        => '{{ $basename }}',
#
fb11_method_group         => '{{ $basename }}',
);

#has_forms (
#    {{ lc $basename}}_form => '{{$basename}}',
#    bar_form => '+A::FB11X::B::Form::Bar',
#);

#sub index
#    :Local
#    :FB11Feature('Read {{ $basename }}')
#    :NavigationName('{{ $basename }} List')
#{
#    my ($self, $c) = @_;
#    $c->stash({{lc $basename}}s => [$c->model('{{$bits[0]}}DB::{{ $basename }}')->all]);
#}

1;


=head1 NAME

{{ $name }} - 

=head1 METHODS

# =head2 index
