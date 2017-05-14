package MasonX::Maypole::View;
use warnings;
use strict;

use Maypole::Constants;

use Symbol 'qualify_to_ref';

use base 'Maypole::View::Base';

=head1 NAME

MasonX::Maypole::View - Mason view subclass for MasonX::Maypole + Maypole 2

=head1 SYNOPSIS

See L<MasonX::Maypole|MasonX::Maypole>.

=head1 METHODS

=over

=item template

Loads the Maypole template vars into Mason components' namespace.

=cut

sub template {
    my ( $self, $maypole ) = @_;
    
    eval {
        my $pkg = $maypole->config->masonx->{in_package};

        my %vars = $self->vars( $maypole );

        warn "got template vars: " . YAML::Dump( \%vars ) if $maypole->debug > 2;

        foreach my $varname ( keys %vars )
        {
            my $export = qualify_to_ref( $varname, $pkg );
            *$export = \$vars{ $varname };

            # XXX need to check how this plays in mod_perl2. It may be
            # unnecessary anyway.
            $maypole->ar->register_cleanup( sub { undef *$export } );

            # no strict 'refs';
            # *{"$pkg\::$varname"} = \$vars{ $varname };
        }
    };

    if ( my $error = $@ )
    {
        $maypole->error( 'Error populating template vars: ' . $error );
        return ERROR;
    }

    return OK;
}

=item error

Handles errors by sending a plain text error report (i.e. not through any
templates) to the browser.

=cut

sub error {
    my ( $self, $maypole, $error ) = @_;
    
    # Some parts of Maypole will store the error in the Maypole request 'error' slot
    # (e.g. see above). Others pass the error as an argument (e.g. Maypole::handler_guts)
    my %errors;
    foreach my $an_error ( $error, $maypole->error )
    {
        next unless $an_error;
        warn $an_error;
        $errors{ $an_error }++;
    }

    $maypole->content_type( 'text/plain' );

    $maypole->output( join( "\n", keys %errors ) );

    $maypole->send_output;

    return ERROR;
}

1;

