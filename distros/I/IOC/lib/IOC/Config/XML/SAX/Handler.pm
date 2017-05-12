
package IOC::Config::XML::SAX::Handler;

use strict;
use warnings;

our $VERSION = '0.02';

use IOC::Exceptions;

use IOC::Registry;
use IOC::Container;
use IOC::Service;
use IOC::Service::Literal;
use IOC::Service::ConstructorInjection;
use IOC::Service::SetterInjection;
use IOC::Service::Prototype;
use IOC::Service::Prototype::ConstructorInjection;
use IOC::Service::Prototype::SetterInjection;
use IOC::Service::Parameterized;

use base qw(XML::SAX::Base);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{registry}        = undef;
    $self->{current}         = undef;
    $self->{current_service} = undef;
    return $self;
}

## XML::SAX Handlers

sub start_element {
    my ($self, $el) = @_;
    my $type = lc($el->{Name});       
    if ($type eq 'registry') {
        $self->_createRegistry($el);
    }
    elsif (defined($self->{registry})) {
        if ($type eq 'container') {
            $self->_createContainer($el);
        }
        elsif ($type eq 'service') {              
            $self->_createService($el);                
        }
        elsif ($type eq 'class') {
            $self->_createClass($el);
        }
        elsif ($type eq 'parameter') {
            $self->_createConstructorParameter($el);
        }            
        elsif ($type eq 'setter') {
            $self->_createSetterParameter($el);
        }
    }
    else {
        throw IOC::ConfigurationError "$type is not allowed unless a Registry is created first";
    }
}  

sub end_element {
    my ($self, $el) = @_;	
    my $name = lc($el->{Name});
    if ($name eq 'container') {
        $self->_finishContainer();
    }
    elsif ($name eq 'service') {
        $self->_finishService();    
    }

}

sub characters {
    my ($self, $el) = @_;
    my $data = $el->{Data};
    return if $data =~ /^\s+$/;
    $self->_handleServiceCharacterData($data) if $self->{current_service};
}

## basic utility routines

sub _getName { 
    my ($self, $el) = @_; 
    return $el->{Attributes}->{'{}name'}->{Value};
}

sub _getValue {
    my ($self, $el, $key) = @_;
    return undef unless exists $el->{Attributes}->{'{}' . $key};
    return $el->{Attributes}->{'{}' . $key}->{Value};        
}

sub _compilePerl {
    my ($self, $perl) = @_;
    my $value = eval $perl;
    throw IOC::OperationFailed "Could not compile '$perl'", $@ if $@;
    return $value;     
}

## IOC::Registry handler

sub _createRegistry {
    my ($self, $el) = @_;
    (!defined($self->{registry})) ||
        throw IOC::ConfigurationError "We already have a registry";
    $self->{registry} = IOC::Registry->new();    
    $self->{current}  = $self->{registry};
}

## IOC::Container handler(s)

sub _createContainer {
    my ($self, $el) = @_;
    ($self->_getValue($el, 'name'))
        || throw IOC::ConfigurationError "Container must have name";
    my $c = IOC::Container->new($self->_getName($el));    
    if ($self->{current}->isa('IOC::Registry')) {
        $self->{current}->registerContainer($c);
    }
    elsif ($self->{current}->isa('IOC::Container')) {
        $self->{current}->addSubContainer($c);
    }    
    $self->{current} = $c;
}

sub _finishContainer {
    my ($self) = @_;
    ($self->{current}) 
        || throw IOC::ConfigurationError "This should never happen";
    $self->{current} = $self->{current}->getParentContainer() 
        if $self->{current}->isa('IOC::Container') &&
           !$self->{current}->isRootContainer();    
}

## IOC::Service::* handler(s)

sub _createService {
    my ($self, $el) = @_;
    (!$self->{current}->isa('IOC::Registry')) ||
        throw IOC::ConfigurationError "Services must be within containers";  
    ($self->_getValue($el, 'name'))
        || throw IOC::ConfigurationError "Service must have name";                
    $self->{current_service} = {
        name      => $self->_getName($el),
        type      => $self->_getValue($el, 'type'),
        prototype => $self->_getValue($el, 'prototype'),                
    };    
}

sub _createClass {
    my ($self, $el) = @_;    
    ($self->{current_service}) ||
        throw IOC::ConfigurationError "Class must be within Services";  
    $self->{current_service}->{class} = {
        name        => $self->_getName($el),
        constructor => $self->_getValue($el, 'constructor')
    };    
}

sub _createConstructorParameter {
    my ($self, $el) = @_;
    ($self->{current_service} && 
        ($self->{current_service}->{type} eq 'ConstructorInjection' && 
            exists $self->{current_service}->{class})) ||
                throw IOC::ConfigurationError "Paramter must be after Class and must be within Services";
    unless (exists $self->{current_service}->{parameters}) {
        $self->{current_service}->{parameters} = [];
    }
    push @{$self->{current_service}->{parameters}} => {
        type => $self->_getValue($el, 'type')
    };    
}

sub _createSetterParameter {
    my ($self, $el) = @_;
    ($self->{current_service} && 
        ($self->{current_service}->{type} eq 'SetterInjection' && 
            exists $self->{current_service}->{class})) ||
                throw IOC::ConfigurationError "Paramter must be after Class and must be within Services";              
    unless (exists $self->{current_service}->{setters}) {
        $self->{current_service}->{setters} = [];
    }
    push @{$self->{current_service}->{setters}} => {
        name => $self->_getName($el)
    };                             
}

sub _handleServiceCharacterData {
    my ($self, $data) = @_;
    if ($self->{current_service}->{parameters}) {
        $self->{current_service}->{parameters}->[-1]->{data} = $data;
    }
    if ($self->{current_service}->{setters}) {
        $self->{current_service}->{setters}->[-1]->{data} = $data;                
    }
    else {
        $self->{current_service}->{data} = $data;
    }    
}

sub _finishService {
    my ($self) = @_;
    my $service_desc = $self->{current_service};    
    $service_desc->{service_class}  = 'IOC::Service';    
    $service_desc->{service_class} .= '::Prototype' 
        if $service_desc->{prototype} && lc($service_desc->{prototype}) ne 'false';  
    # NOTE:
    # this allows for us to add on more Service 
    # types without too much trouble ...
    my $constructor = $self->can('__makeService' . ($service_desc->{type} || ''));
    if ($constructor) {
        $self->$constructor($service_desc);            
    }   
    else {
        throw IOC::ConfigurationError "Unrecognized type : " . $service_desc->{type};
    }      
    $self->{current_service} = undef;     
}

## ultra-private Service constructors

sub __makeService {
    my ($self, $service_desc) = @_;
    # we have a plain Service
    ($service_desc->{data})
        || throw IOC::ConfigurationError "No sub in Service";        
    $self->{current}->register(
        $service_desc->{service_class}->new(
            $service_desc->{name} => $self->_compilePerl('sub { ' . $service_desc->{data} . ' }')
        )
    );    
}

sub __makeServiceParameterized {
    my ($self, $service_desc) = @_;
    # we have a plain Service
    ($service_desc->{data})
        || throw IOC::ConfigurationError "No sub in Service";        
    $self->{current}->register(
        IOC::Service::Parameterized->new(
            $service_desc->{name} => $self->_compilePerl('sub { ' . $service_desc->{data} . ' }')
        )
    );    
}

sub __makeServiceLiteral {
    my ($self, $service_desc) = @_;    
    (exists $service_desc->{data}) 
        || throw IOC::ConfigurationError "Cant make a Literal without a value";
    $self->{current}->register(
        IOC::Service::Literal->new($service_desc->{name} => $service_desc->{data})
    );      
}

sub __makeServiceConstructorInjection {
    my ($self, $service_desc) = @_;    
    (exists $service_desc->{class} && 
        ($service_desc->{class}->{name} && $service_desc->{class}->{constructor})) 
            || throw IOC::ConfigurationError "Cant make a ConstructorInjection without a class";
    my @parameters;
    @parameters = map {
        if ($_->{type}) {           
            if ($_->{type} eq 'component') {
                IOC::Service::ConstructorInjection->ComponentParameter($_->{data})
            }
            elsif ($_->{type} eq 'perl') {
                $self->_compilePerl($_->{data})                 
            }                    
            else {
                throw IOC::ConfigurationError "Unknown Type: " . $_->{type}
            }
        }
        else {
            (defined $_->{data})
                || throw IOC::ConfigurationError "No data";             
            $_->{data}
        }
    } @{$service_desc->{parameters}}
        if exists $service_desc->{parameters};
    $service_desc->{service_class} .= '::ConstructorInjection';    
    $self->{current}->register(
        $service_desc->{service_class}->new($service_desc->{name} => (
            $service_desc->{class}->{name},
            $service_desc->{class}->{constructor},
            \@parameters
        ))
    );      
}

sub __makeServiceSetterInjection {
    my ($self, $service_desc) = @_;    
    (exists $service_desc->{class} &&
        ($service_desc->{class}->{name} && $service_desc->{class}->{constructor}))         
            || throw IOC::ConfigurationError "Cant make a ConstructorInjection without a class";                       
    my @setters;
    @setters = map {
        { $_->{name} => $_->{data} }
    } @{$service_desc->{setters}} 
        if exists $service_desc->{setters};            
    $service_desc->{service_class} .= '::SetterInjection';    
    $self->{current}->register(
        $service_desc->{service_class}->new($service_desc->{name} => (
            $service_desc->{class}->{name},
            $service_desc->{class}->{constructor},
            \@setters
        ))
    );      
} 	

1;

__END__

=head1 NAME

IOC::Config::XML::SAX::Handler - An XML::SAX handler to read IOC Config files

=head1 SYNOPSIS

    use IOC::Config::XML::SAX::Handler; # used by IOC::Config::XML    

=head1 DESCRIPTION

This class is used by L<IOC::Config::XML> to construct the L<IOC::Registry> object hierarchy from the given XML document. There are no user serviceable parts in this module really. But if you want to add handling for any type of custom L<IOC::Container> or L<IOC::Service> subclasses, this would be the place to do it. 

=head1 METHODS

These are methods used by XML::SAX. Consult that modules documentation for more information about them.

=over 4

=item B<new>

=item B<start_element>

=item B<end_element>

=item B<characters>

=back

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it. 

=head1 CODE COVERAGE

I use B<Devel::Cover> to test the code coverage of my tests, see the CODE COVERAGE section of L<IOC> for more information.

=head1 SEE ALSO

=over 4

=item L<XML::SAX>

=item L<XML::SAX::Base>

=back

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2007 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
