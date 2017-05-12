package Maypole::Virtual::Application;

use warnings;
use strict;

# for now, get this from beerdb.riverside-cms.co.uk
use Maypole::Application 2.10 ();

our $VERSION = 0.01;

=head1 NAME

Maypole::Virtual::Application - create multiple Maypole apps on the fly

=cut

=head1 SYNOPSIS

    package BeerDB;
    use strict;
    use warnings;
    
    use Class::DBI::Loader::Relationship;
    
    use Maypole::Virtual::Application; 
    
    Maypole::Virtual::Application->install_packages( qw( -Debug AutoUntaint ) );
    
    # beer for everyone!
    sub virtual_packages { map { __PACKAGE__ . "::Site$_" } 1 .. 100 }
    
    sub initialize_package
    {
        my ( $self, $package ) = @_;
        
        $package =~ /(Site\d+)$/;
        
        my $site = $1;
        
        my $username = My::Config::System->get_beerdb_username_for( $site );
        my $password = My::Config::System->get_beerdb_password_for( $site );
        
        $package->setup( "dbi:mysql:BeerDB$site", 
                         $username,
                         $password,
                         );
        
        $package->config->{template_root}  = '/home/beerdb/www/www/htdocs';
        $package->config->{uri_base}       = '/';
        $package->config->{rows_per_page}  = 10;
        $package->config->{display_tables}   = [ $package->config->loader->tables ]; 
        $package->config->{application_name} = 'The Beer Database';
        
        $package->auto_untaint;
        
        $package->config->loader->relationship( $_ ) for (
            'a brewery produces beers',
            'a style defines beers',
            'a pub has beers on handpumps',
            );
                
        # this would get called anyway during the first request, but 
        # putting it here is useful under mod_perl to get all initialisation 
        # done before forking off child servers
        $package->init;
    }
    
    sub my_custom_request_method
    {
        # all virtual apps inherit from this package (BeerDB in this case), 
        # so methods defined here are inherited by all Maypole request objects 
        # in the virtual apps.
    }
    
    1;
    
=head1 DESCRIPTION

Use this class to setup multiple applications 'on the fly'. This might be useful in a mod_perl 
virtual hosting environment, where you want to give each site its own version of a Maypole 
application. 

=head1 METHODS

=over 4

=item install_packages( @plugins )

Pass the list of plugins and flags to be installed in each application, just as with L<Maypole::Application|Maypole::Application>. 
This method then 
uses the C<virtual_packages> callback to get a list of package names to install, installs 
each package using L<Maypole::Application|Maypole::Application>, and runs the 
C<initialize_package> callback to configure each package. 

=back

=cut

sub install_packages
{
    my ( $class, @plugins ) = @_;
    
    my $caller = caller(0);
    
    foreach my $package ( $caller->virtual_packages )
    {
        eval "{ package $package; Maypole::Application->import( qw( @plugins ) ) }";
        
        die "Error creating virtual Maypole app $package: $@" if $@;
        
        {
            no strict 'refs';
            unshift @{"$package\::ISA"}, $caller;
        }
    
        $caller->initialize_package( $package );
    }
}

=head1 Maypole::Application

There's a bug in L<Maypole::Application|Maypole::Application> that needs to be fixed before using 
this module. You can download a fixed version of C<Maypole::Application> from C<beerdb.riverside-cms.co.uk>,
until the patch is incorporated in L<Maypole::Application|Maypole::Application> proper. 
That version of C<Maypole::Application> also works with L<MasonX::Maypole|MasonX::Maypole> (as well as the other L<Maypole|Maypole> frontends). The build script should check for version 2.10, as does the main package, 
so you should install the patched C<Maypole::Application> before attempting to install this.
  
=head1 AUTHOR

David Baird, C<< <cpan@riverside-cms.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-maypole-virtual-application@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Maypole-Virtual-Application>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 David Baird, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Maypole::Virtual::Application
