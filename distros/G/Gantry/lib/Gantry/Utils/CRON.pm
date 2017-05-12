package Gantry::Utils::CRON;

use strict;
use warnings;

use HTML::TreeBuilder;
use HTML::FormatText;

use Gantry::Server;
use Gantry::Engine::CGI;

sub new {
    my ( $class, $opts ) = ( shift, shift );

    my $self = {};
    bless( $self, $class );

    $self->set_controller( $opts->{controller} || undef );
    $self->set_conf_instance( $opts->{conf_instance} || undef );
    $self->set_conf_file( $opts->{conf_file} || undef );
    $self->set_template_engine( $opts->{template_engine} || undef );
    $self->set_namespace( $opts->{namespace} || undef );

    # populate self with data from site
    return( $self );

} # end new

sub run {
    my( $self, $opts ) = ( shift, shift );
    
    die "missing controller"    if ! $self->controller();
    die "missing conf_instance" if ! $self->conf_instance();
    die "missing conf_file"     if ! $self->conf_file();

    die "missing the controller method to call" if ! defined $opts->{method};
    
    if ( $opts->{method} !~ /^do_/ ) {
        die "method must be a do_* method";
    }

    my @imports;
    push( @imports, 
        "-Engine=CGI",
        ( "-TemplateEngine=" . $self->template_engine() ),
    );
    
    push( @imports, 
        ( "-PluginNamespace=" . $self->namespace() ),
    ) if $self->namespace();

    my $app_module = $self->controller() 
        . " qw{ " . join( ' ', @imports ) . " }";

    eval "use $app_module";
    if ( $@ ) { die $@; }

    my $cgi = Gantry::Engine::CGI->new( {
        config => {
            GantryConfInstance  => $self->conf_instance,
            GantryConfFile      => $self->conf_file,
        },
        locations => {
            '/' => $self->controller(),
        },
    } );

    my $server = Gantry::Server->new();
    $server->set_engine_object( $cgi );

    my $action = $opts->{method};
    $action    =~ s/^do_//;

    my @uri_parts   = ();
    my @param_pairs = ();
    
    push( @uri_parts, $action );
    push( @uri_parts, @{ $opts->{args} } );

    for my $p ( keys %{ $opts->{params} } ) {
        next if ! defined $opts->{params}{$p};
        
        push( @param_pairs, 
            join( '=', $p, $opts->{params}{$p} ) 
        );
    }
    
    my $uri = '/' . join( '/', @uri_parts );
    if ( scalar( @param_pairs ) > 0 ) {
        $uri .= '?' . join( '&', @param_pairs );         
    }

    # set the proper gantry request call
    my $gantry_method_call = 'handle_request_test_post';

    if ( $opts->{type} eq 'get' ) {
        $gantry_method_call = 'handle_request_test';
    }
   
    my( $status, $content ) = $server->$gantry_method_call( $uri );
   
    my $tree         = HTML::TreeBuilder->new_from_content( $content );
    my $formatter    = HTML::FormatText->new(
            leftmargin => 0, rightmargin => 55
    );

    my $text_content = $formatter->format( $tree );
    $tree->delete; # required to properly free memory    

    $self->set_status( $status );
    $self->set_content( $text_content );

    return( $status, $text_content );
}

# content accessors
sub set_content {
    my( $self, $p ) = @_;    
    $self->{_content} = $p;
}
sub content {
    my( $self ) = @_;    
    return $self->{_content};
}

# status accessors
sub set_status {
    my( $self, $p ) = @_;    
    $self->{_status} = $p;
}
sub status {
    my( $self ) = @_;    
    return $self->{_status};
}

# controller accessors
sub set_controller {
    my( $self, $p ) = @_;    
    $self->{_controller} = $p;
}
sub controller {
    my( $self ) = @_;    
    return $self->{_controller};
}

# conf instance accessors
sub set_conf_instance {
    my( $self, $p ) = @_;    
    $self->{_conf_instance} = $p;
}
sub conf_instance {
    my( $self ) = @_;    
    return $self->{_conf_instance};
}

# conf file accessors
sub set_conf_file {
    my( $self, $p ) = @_;    
    $self->{_conf_file} = $p;
}
sub conf_file {
    my( $self ) = @_;    
    return $self->{_conf_file} || '/etc/gantry.conf';
}

# template engine accessors
sub set_template_engine {
    my( $self, $p ) = @_;    
    $self->{_template_engine} = $p;
}
sub template_engine {
    my( $self ) = @_;    
    return $self->{_template_engine} || 'TT';
}

# plugin namespace accessors
sub set_namespace {
    my( $self, $p ) = @_;    
    $self->{_namespace} = $p;
}
sub namespace {
    my( $self ) = @_;    
    return $self->{_namespace};
}

# EOF
1;

__END__

=head1 NAME 

Gantry::Utils::CRON - a way to call a controller's method from a CRON script

=head1 SYNOPSIS

  use strict; use warnings;

  use Gantry::Utils::CRON;

  my $cron = Gantry::Utils::CRON->new( {
    controller      => 'Apps::RR::InvoiceMunger::Batch',
    conf_instance   => 'apps_rr_invoicemunger_dev_prod',
    conf_file       => '/etc/gantry.conf',         # optional
    template_engine => 'TT',                       # optional
    namespace       => 'Apps::RR::InvoiceMunger',  # optional
  } );

  # alternative setters
  $cron->set_controller( 'Apps::RR::InvoiceMunger::Batch' );
  $cron->set_conf_instance( 'invoice_munger_prod' );
  $cron->set_conf_file( '/etc/gantry.conf' );
  $cron->set_template_engine( 'TT' );    
  $cron->set_namespace( 'mynamespace' );

  $cron->run( {
    method => 'do_process_files',          # do_* required
    args   => [ '1', '2' ],                # optional
    params => { confirm => 1, test => 3 }  # optional
    type   => 'post'                       # or 'get' -- optional 
  } );

  print STDERR $cron->status();  
  print STDERR $cron->content();

=head1 DESCRIPTION

This module is a utility to run a Gantry do_ method from a CRON script

=head1 METHODS 

=over 4

=item new( {} ); 

Standard constructor, call it first. 

Required

    controller      - Gantry controller that contains the do_ method
    conf_instance   - Gantry conf instance name

Optional

    conf_file       - defaults to '/etc/gantry.conf'
    template_engine - defaults to 'TT'
    namespace       

=item run( {} )

This method executes the defined controller's do_ method.

Accepts
  
  method - the do_ method
  args   - array of args to be passed to the method
  params - hashref of params to be passed to method
  type   - 'get' or 'post' defaults to 'post' 

Returns
  
  status  - page status code
  content - plain-text version of method's returned content
        
=item set_content

setter for the returned content 

=item content

getter for the returned content
        
=item set_status

setter for the returned status 

=item status

getter for the returned status

=item set_controller

setter for controller 

=item controller

getter for controller

=item set_conf_instance

setter for the Gantry conf_instance 

=item conf_instance

getter for the Gantry conf_instance 

=item set_conf_file

setter for the Gantry conf_file. 

=item conf_file

getter for the Gantry conf_file. Defaults to /etc/gantry.conf 

=back

=head1 SEE ALSO

Gantry(3)

=head1 LIMITATIONS 

This module depends on Gantry(3), HTML::TreeBuilder, HTML::FormatText

=head1 AUTHOR

Tim Keefer <tim@timkeefer.com>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2007, Tim Keefer.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
