package Maypole::Plugin::Session;

use 5.005;
use warnings;
use strict;

use Maypole();
use Maypole::Config();
use Maypole::Constants();

use Apache::Session::Wrapper 0.24;

Maypole::Config->mk_accessors('session');
Maypole->mk_accessors( 'apache_session_wrapper' );

=head1 NAME

Maypole::Plugin::Session - simple sessions for Maypole

=cut

our $VERSION = 0.2;

=head1 SYNOPSIS

    use Maypole::Application qw( Session );
    
    # Elsewhere in your app:
    my $session = $r->session;
    
=head1 API CHANGES

This version is a re-write using L<Apache::Session::Wrapper>. As such, the configuration parameters
have changed - use L<Apache::Session::Wrapper> settings rather than L<Apache::Session> settings. 
See B<Configuration>.
    
=head1 DESCRIPTION

Provides C<session> and C<delete_session> methods for your Maypole request class. The session is 
implemented using L<Apache::Session::Wrapper>, and as such, a range of session store mechanisms 
are available. 

=head1 CONFIGURATION

The B<Configuration> section of the L<Apache::Session::Wrapper> docs lists all the 
available parameters. These should be placed in the C<Maypole::Config::session> slot as a hashref. 

=over 4

=item setup

If there are no settings in C<< Maypole::Config->session >>, then default settings for L<Apache::Session::File> 
are placed there. Also, cookies are turned on by default:

    $config->{session} = { class          => 'File',
                           directory      => "/tmp/sessions",
                           lock_directory => "/tmp/sessionlock",
                     
                           use_cookie => 1,
                           cookie_name => 'maypole-plugin-session-cookie',
                           };
                         
You need to create these directories with appropriate permissions if you
want to use these defaults.

You can place custom settings there either before (preferably) or after (probably OK) 
calling C<< Maypole->setup >>, e.g.

    $r->config->session( { class     => "Flex",
                           store     => 'DB_File',
                           lock      => 'Null',
                           generate  => 'MD5',
                           serialize => 'Storable'
                           } );

=cut

sub setup
{
    my $r = shift; # class name
    
    warn "Running " . __PACKAGE__ . " setup for $r" if $r->debug;
    
    # Apache::Session::Wrapper will use add() to set the cookie under CGI
    *Maypole::Headers::add = \&Maypole::Headers::push;
    
    my %defaults = ( class          => 'File',
                     directory      => "/tmp/sessions",
                     lock_directory => "/tmp/sessionlock",
            
                     use_cookie  => 1,
                     cookie_name => 'maypole-plugin-session-cookie',
                     );
                      
    my $cfg = $r->config->session || {};
    
    if ( keys %$cfg )
    {
        exists $cfg->{use_cookie}  or $cfg->{use_cookie}  = $defaults{use_cookie};
        exists $cfg->{cookie_name} or $cfg->{cookie_name} = $defaults{cookie_name};
    }
    else
    {
        %$cfg = %defaults;
    }
                              
    $r->NEXT::DISTINCT::setup( @_ );
}

=back

=head1 METHODS

=over 4

=item session

Returns the session hashref.

=item delete_session

Deletes the session and cookie.

=cut

sub session        { shift->apache_session_wrapper->session( @_ ) }
sub delete_session { shift->apache_session_wrapper->delete_session( @_ ) }

=back

=head1 PRIVATE METHODS

These are only necessary if you are writing custom C<authenticate> method(s). 
Otherwise, they are called for you.

=over 4

=item authenticate

This is called early in the Maypole request workflow, and is used as the hook to 
call C<get_session>. If you are writing your own C<authenticate> method(s), either in 
model classes or in the request classes, make sure your C<authenticate> method calls 
C<get_session>.
    
=cut

sub authenticate
{
    my ( $r ) = @_;
    
    $r->get_session;
    
    return Maypole::Constants::OK;  
}

=item get_session

Retrieves the cookie from the browser and matches it up with a session in the store. 

You should call this method inside any custom C<authenticate> methods.

=cut

sub get_session
{
    my ( $r ) = @_;
    
    # returning 1 silences an anonymous warning
    $r->can( 'ar' ) && $r->ar && $r->ar->register_cleanup( sub { $r->apache_session_wrapper->cleanup_session; 1 } );
    
    $r->{apache_session_wrapper} =
        Apache::Session::Wrapper->new( header_object => $r, 
                                       param_object  => $r, 
                                       %{ $r->config->session },
                                       );    
}

=back

=head1 SEE ALSO

L<Apache::Session::Wrapper>. 

=head1 AUTHOR

David Baird, C<< <cpan@riverside-cms.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-maypole-plugin-session@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Maypole-Plugin-Session>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 David Baird, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Maypole::Plugin::Session
