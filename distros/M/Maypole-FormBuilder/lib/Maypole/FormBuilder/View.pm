package Maypole::FormBuilder::View;
use strict;
use warnings;

use Maypole::FormBuilder;

our $VERSION = $Maypole::FormBuilder::VERSION;

# Maypole::Plugin::FormBuilder::init() does some funky messing about, which results in 
# this view class inheriting from Maypole::View::Base

=over

=item vars

Overrides the standard Maypole::View::Base vars method, removing the C<classmetadata> entries.

=cut

sub vars 
{
    my ( $self, $r ) = @_;
    
    my $base  = $r->config->uri_base;
    $base =~ s/\/+$//;
    
    my %args = (
        request => $r,
        objects => $r->objects,
        base    => $base,
        config  => $r->config
    );
    
    # needs to exist in the hash to get exported
    $args{form_failed_validation} = undef;
    
    # Overrides
    %args = ( %args, %{ $r->template_args || {} } );
    %args;
}

1;