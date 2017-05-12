package Gantry::Plugins::Cache;

use strict; 
use warnings;

use File::Spec;

use base 'Exporter';
our @EXPORT = qw( 
    get_callbacks
);

my %registered_callbacks;

#-----------------------------------------------------------
# $class->get_callbacks( $namespace )
#-----------------------------------------------------------
sub get_callbacks {
    my ( $class, $namespace ) = @_;

    return if ( $registered_callbacks{ $namespace }++ );

    warn "Your app needs a 'namespace' method which doesn't return 'Gantry'"
            if ( $namespace eq 'Gantry' );

    return (
        { phase => 'post_engine_init', callback => \&initialize }
    );
}

#-----------------------------------------------------------
# initialize
#-----------------------------------------------------------
sub initialize {
    my ($gobj) = @_;

    $gobj->cache_init();

}

1;

__END__

=head1 NAME

Gantry::Plugins::Cache - A Plugin for initializing cache processing

=head1 SYNOPSIS

In Apache Perl startup or app.cgi or app.server:

    <Perl>
        # ...
        use MyApp qw{ -Engine=CGI -TemplateEngine=TT Cache::FastMap };
        
        # or
        use MyApp qw{ -Engine=CGI -TemplateEngine=TT Cache::Memcached };
        
    </Perl>


=head1 DESCRIPTION

The purpose of the plugin is to initalize cache processing for the application.
Caching process should only be started once and this module is an attempt
to do so at the beginning of session processing. This module should be  
placed after the -TemplateEngine selection and before any other plugins.

Note that you must include Cache in the list of imported items when you use 
your base app module (the one whose location is app_rootp). Failure to do so 
will cause errors.

=head1 CONFIGURATION

The following items can be set by configuration:

=over 4

There is no configuration for this module. Which caching system used,
depends on which module from Gantry::Cache is included in the base module for
the application. If no caching modules are include an error will result.

=back

=head1 METHODS

=over 4

=item get_callbacks

For use by Gantry.pm. Registers the callbacks needed for cache  management
during the PerlHandler Apache phase or its moral equivalent.

=back

=head1 PRIVATE SUBROUTINES

=over 4

=item initialize

Callback to initialize plugin configuration.

=back

=head1 SEE ALSO

    Gantry

=head1 AUTHOR

Kevin L. Esteb <kesteb@wsipc.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
