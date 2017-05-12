package MasonX::Maypole;
use warnings;
use strict;
use Carp;

use base 'Apache::MVC';

Maypole::Config->mk_accessors( 'masonx' );

__PACKAGE__->mk_classdata( 'mason_ah' );

=head1 NAME

MasonX::Maypole - use Mason as the frontend and view for Maypole version 2

=cut

our $VERSION = 0.32;

=head1 SYNOPSIS

    package BeerDB;
    use warnings;
    use strict;

    use Class::DBI::Loader::Relationship;

    use MasonX::Maypole::Application qw( -Debug2 MasonX AutoUntaint );

    BeerDB->setup( 'dbi:mysql:beerdb', 'username', 'password' );

    BeerDB->config->{template_root}  = '/home/beerdb/www/www/htdocs';
    BeerDB->config->{uri_base}       = '/';
    BeerDB->config->{rows_per_page}  = 10;
    BeerDB->config->{display_tables} = [ qw( beer brewery pub style ) ];
    BeerDB->config->{application_name} = 'The Beer Database';

    BeerDB->config->masonx->{comp_root}  = [ [ factory => '/var/www/maypole/factory' ] ];
    BeerDB->config->masonx->{data_dir}   = '/home/beerdb/www/www/mdata';
    BeerDB->config->masonx->{in_package} = 'BeerDB::TestApp';

    BeerDB->auto_untaint;

    BeerDB->config->{loader}->relationship($_) for (
        'a brewery produces beers',
        'a style defines beers',
        'a pub has beers on handpumps',
        );

    1;

=head1 DESCRIPTION

A frontend and view for Maypole, using Mason.

=head1 EXAMPLES

Example C<BeerDB.pm> and a C<httpd.conf> VirtualHost setup are included in 
the C</doc> directory of the distribution.

A working example of the BeerDB application is at C<http://beerdb.riverside-cms.co.uk>, 
including the C<BeerDB.pm> and C<httpd.conf> used for that site.

=head1 CONFIGURING MASON

Set any parameters for the Mason ApacheHandler in C<<BeerDB->config->{masonx}>>.
This is where to tell Maypole/Mason where the factory templates are stored.

Note that the user the server runs as must have permission to read the files in the
factory templates directory, which also means all directories in the path to the
templates must be readable and executable (i.e. openable). If Mason can't read
these templates, you may get a cryptic 'file doesn't exist' error, but you
will not get a 'not permitted' error.

=head1 Maypole::Application

L<Maypole::Application|Maypole::Application> needs to be patched before it will work 
with MasonX::Maypole. The patch is available at C<http://beerdb.riverside-cms.co.uk>, 
or you can use L<MasonX::Maypole::Application|MasonX::Maypole::Application> (included with 
this distribution), which is just L<Maypole::Application|Maypole::Application> with the 
patch applied.

=head1 TEMPLATES

This distribution includes Masonized versions of the standard Maypole templates,
plus a dhandler and autohandler. The autohandler simply takes care of adding
a header and footer to every page, while the dhandler loads the template
specified in the Maypole request object.

So if you set the factory comp_root to point at the Maypole factory templates,
the thing should Just Work right out of the box. Except for maypole.css, which 
you will need to copy to the right place on your server. 

=head1 METHODS

=over

=item init

This method is called by Maypole while processing the first request the server
receives. Probably better under mod_perl to call this explicitly at the end of
your setup code (C<BeerDB-E<gt>init>) to share memory among Apache children.
Sets up the Mason ApacheHandler, including the search path behaviour.

=cut

# This only gets called once. Mason's path searching mechanism replaces
# get_template_root and Maypole::View::Base::paths.
sub init {
    my ( $class ) = @_;

    $class->set_mason_comp_roots;

    my $mason_cfg = $class->config->masonx;

    $mason_cfg->{decline_dirs} ||= 0;
    $mason_cfg->{in_package}   ||= 'HTML::Mason::Commands';

    # this provides dynamic table-name component roots
    $mason_cfg->{request_class}  = 'MasonX::Request::ExtendedCompRoot';
    $mason_cfg->{resolver_class} = 'MasonX::Resolver::ExtendedCompRoot';

    $class->mason_ah( MasonX::Maypole::ApacheHandler->new( %{ $mason_cfg } ) );
    
    $class->config->view || $class->config->view( 'MasonX::Maypole::View' );

    $class->SUPER::init;
}

=item set_mason_comp_roots

The default search path for a component is:

    /template_root/<table_moniker>/<component>  # if querying a table
    /template_root/custom/<component>
    /template_root/<component>
    /factory/template/root/<component>

where C</factory/template/root> defaults to C</template_root/factory>, but can
be altered by providing a factory C<comp_root> to the masonx config as shown
in the synopsis.

You can provide extra component roots in the masonx config setup. For other
modifications to the search path, make a subclass that overrides this method.

=cut

# note that the table-name search path is added to the front of this list at
# the start of every request, in send_output
sub set_mason_comp_roots {
    my ( $class ) = @_;

    my $template_root = $class->get_template_root;

    my $comp_roots = $class->config->masonx->{comp_root} || [];

    my $factory = [];

CROOT:  foreach my $index ( 0 .. $#$comp_roots )
    {
        if ( $comp_roots->[ $index ][0] eq 'factory' )
        {
            $factory = delete $comp_roots->[ $index ];
            last CROOT;
        }
    }

    push @$comp_roots, [ custom  => File::Spec->catdir( $template_root, 'custom' ) ];
    push @$comp_roots, [ maypole => $template_root ];
    push @$comp_roots, [ factory => $factory->[1] || File::Spec->catdir( $template_root, 'factory' ) ];

    $class->config->masonx->{comp_root} = $comp_roots;
    
    #warn "Base comp roots: " . YAML::Dump( $comp_roots ) if $class->debug > 2;
}

=item parse_args

Uses Mason to extract the request arguments from the request.

=cut

# override the method in Apache::MVC
sub parse_args {
    my ( $self ) = @_;

    # set and return request args in Mason request object
    my $args = $self->mason_ah->request_args( $self->ar );

    $self->{params} = $args;
    $self->{query}  = $args;
}

=item send_output

Template variables have already been exported to Mason components namespace
in C<MasonX::Maypole::View::template>. This method now runs the Mason C<exec>
phase to generate and send output.

=cut

sub send_output {
    my ( $self ) = @_;

    # if there was an error, there may already be a report in the output slot,
    # so send it via Apache::MVC
    return $self->SUPER::send_output if $self->output;

    my $m = eval { $self->mason_ah->prepare_request( $self->ar ) };

    if ( my $error = $@ )
    {
        # In here, $m is actually a status code, but Maypole::handler isn't
        # interested so no point in returning it.
        $self->output( $error );
        return $self->SUPER::send_output;
    }

    unless ( ref $m )
    {
        $self->output( "prepare_request returned this: [$m]\n instead of a Mason request object" );
        return $self->SUPER::send_output;
    }

    $self->ar->content_type(
          $self->content_type =~ m/^text/
        ? $self->content_type . "; charset=" . $self->document_encoding
        : $self->content_type
    );
    
    foreach ( $self->headers_out->field_names ) 
    {
        next if /^Content-(Type|Length)/;
        $self->{ar}->headers_out->set( $_ => $self->headers_out->get( $_ ) );
    }
    
    # I think Mason will do this:
    #$self->{ar}->send_http_header;

    # add dynamic comp root for table queries
    # Changed to using model_class instead of table in 0.219 ( see Maypole::View::Base::paths() 
    # - ideally, this stuff would go in a paths() method).
    if ( $self->model_class )
    {
        my $model_comp_root = File::Spec->catdir( $self->get_template_root, $self->model_class->moniker );
        # Even with this ugliness, there might be potential for non-unique prefixes, if a site was 
        # running multiple Maypole sub-apps all using the same Mason datadir...
        $m->prefix_comp_root( 'MAYPOLE_MODEL_' . $self->model_class->moniker . "=>$model_comp_root" ) if -d $model_comp_root;
    }
    
    #if ( $self->table )
    #{
    #    my $table_comp_root = File::Spec->catdir( $self->get_template_root, $self->table );
    #    $m->prefix_comp_root( "table=>$table_comp_root" ) if -d $table_comp_root;
    #}
    
    warn "Comp roots:\n" . join( "\n", map { "@$_" } @{ $m->interp->comp_root } ) if $self->debug;

    # now generate output
    $m->exec;
}

=item get_template_root

Returns C<template_root> from the config.

This varies from L<Apache::MVC|Apache::MVC>, which concatenates
document_root and location from the Apache request server config.

=cut

sub get_template_root { $_[0]->config->template_root }

{
    # copied from MasonX::WebApp
    package MasonX::Maypole::ApacheHandler;
    use base 'HTML::Mason::ApacheHandler';

    sub request_args
    {
        my ( $self, $apr ) = @_;

        return $apr->pnotes('__request_args__') if $apr->pnotes('__request_args__');

        my $args = ($self->SUPER::request_args($apr))[0] || {};

        $apr->pnotes( __request_args__ => $args );

        return $args;
    }
}

=back

=head1 AUTHOR

David Baird, C<< <cpan@riverside-cms.co.uk> >>

=head1 TODO

Currently hard-coded to use Apache/mod_perl. Shouldn't be too hard to use CGI
instead.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-masonx-maypole2@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 TESTS

There are none. The module loads Mason::ApacheHandler, which causes compile
time errors unless loaded within mod_perl.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2004 David Baird, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of MasonX::Maypole2
