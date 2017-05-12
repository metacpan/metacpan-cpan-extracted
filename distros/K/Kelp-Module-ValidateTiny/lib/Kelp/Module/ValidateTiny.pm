{
package Kelp::Module::ValidateTiny;

use Kelp::Base 'Kelp::Module';

use Validate::Tiny;

use Class::Load;
use Sub::Install;

our $VERSION = '0.04';

# These are Validate::Tiny functions that we 
# forward into the application namespace
 
my @forward_ok = qw{
    filter
    is_required
    is_required_if
    is_equal
    is_long_between
    is_long_at_least
    is_long_at_most
    is_a
    is_like
    is_in
};

sub build {
    
    my ($self, %args) = @_;
    
    my @import;
    # Imported from Validate::Tiny?
    if (%args && 
        exists $args{subs}) {

            @import = @{$args{subs}};
        }
        
    @import = @forward_ok if (@import && $import[0] eq ':all');

    # Namespaces to import into (default is our App)
    # If our App name is Kelp, we are probably running 
    # from a standalone script and our classname is main
    
    my $class = ref $self->app;
    $class = 'main' if ($class eq 'Kelp');
    my @into = ($class);

    if (%args &&
        exists $args{into}) {
            
            push @into, @{$args{into}};
        }
    
    # Import!
    foreach (@into) {
        
        my $class = $_;

        Class::Load::load_class($class) 
          unless Class::Load::is_class_loaded($class);
          
        foreach (@import) {
            
            Sub::Install::install_sub({
                code => Validate::Tiny->can($_),
                from => 'Validate::Tiny',
                into => $class,
            });
        }
    }

    # Register a single method - self->validate
    $self->register(
        validate => \&_validate
    );
}

sub _validate {

    my $self = shift;
    my $rules = shift;
    my %args = @_;
    
    # Combine all params
    # TODO: check if mixed can be avoided 
    # on the Hash::Multivalue "parameters"

    my $input = {
        %{$self->req->parameters->mixed}, 
        %{$self->req->named}
    };
    
    my $result = Validate::Tiny->new($input, $rules);
    
    return $result if (
       $result->success || (!(%args && exists $args{on_error}))
    );
    
    # There are errors and a template is passed
   
    my $data = $result->data;
    $data->{error} = $result->error;

    if (exists $args{data}) {
        $data = {
            %$data,
            %{$args{data}},
        };
    }
    
    return Validate::Tiny::PlackResponse->new(
        $result, 
        $self->res->template($args{on_error}, $data)
    );
}

}


{
	package Validate::Tiny::PlackResponse;

	use parent Validate::Tiny;
	use Scalar::Util qw{blessed refaddr};
	
	my %_response;
	
	sub new {
		
		my ($class, $obj, $response) = @_;
		
        die "Incorrect Parent Class. Not an instance of Validate::Tiny" 
          unless blessed($obj) eq 'Validate::Tiny';
    
        $_response{refaddr $obj} = $response;

        bless $obj, $class;
        
        return $obj;
	}
	
	sub response {
		
		my $self = shift;
        die "Incorrect Parent Class. Not an instance of Validate::Tiny::PlackResponse" 
          unless blessed($self) eq 'Validate::Tiny::PlackResponse';
        
        return $_response{refaddr $self};   
	}
	
	sub DESTROY {
		
		my $self = shift;

		my $key = refaddr $self;
		delete $_response{$key} if exists $_response{$key};
        
        $self->SUPER::DESTROY if $self->SUPER::can(DESTROY);		
	}
}

1;
__END__

=encoding utf-8

=head1 NAME

Kelp::Module::ValidateTiny - Validate parameters in a Kelp Route Handler

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Kelp::Module::ValidateTiny;
    # inside your Kelp config file 
    {
        modules => [ qw{SomeModule Validate::Tiny} ],
        modules_init => {
            ...
            ,
            # :all will import everything
            # no need to list MyApp here
            'Validate::Tiny' => {
                subs => [ qw{is_required is_required_id} ],
                into => [ qw{MyApp::OtherRouteClass} ], 
            }
        }
    }
    ...
    #inside a Kelp route

    my $vt_rules = {
        fields => [...],
        filters => [...],
        checks => [...],
    };
    
    my $result = $self->validate($vt_rules)
    # $result is a Validate::Tiny object

    # process $result
    ...
    
    # render the template form.tt if validation fails
    # $errors and valid values are automatically passed, 
    # to the template, but you can optionally pass some 
    # more data to that template

    my $result = $self->validate($rules, 
        on_error => 'form.tt',
        data => {
            message => 'You could try something else'
        },
    );
    # If validation fails, $result is an instance of 
    # Validate::Tiny::PlackResponse and has a response 
    # method that can be sent
    return $result->response unless $result->success
    
    # All data is valid here.
    # use $result->data
      

=head1 DESCRIPTION

Kelp::Module::ValidateTiny adds Validate::Tiny's validator to your Kelp application.

=head1 METHODS

=head2 validate

This is the only method decorating $self. You can call it in three ways:

First you can pass it just a valid Validate::Tiny $rules hash reference. It 
will return a Validate::Tiny object and you can call all the usual V::T
methods on it.

    my $result = $self->validate($rules);
    # $result is now a Validate::Tiny object
    
Second you can pass it a name ('on_error') and value (a template filename) pair. 
If your data passed the validation, the return value is the usual V::T object. 
However, if validation fails, the validate method returns an object that has 
a "response" method in addition to all the Validate::Tiny methods.

    my $result = $self->validate(
        $rules,
        on_error => 'form'
    );
    return $result->response unless $result->success # form.tt rendered
    ...
    # Your data was valid here
    ...
    # Return some other response    

Note that calling $result->response if your validations succeeded is a fatal 
error. The template (form.tt in the code above) is rendered with a hashref
that contains the key-value pairs of valid parameters plus a key "error" that
points to another hashref with names of invalid parameters as keys and the 
corresponding error messages as values. So if your parameters were 

    {id => 41, lang => 'Perl', version => '5.10'}

and id was found to be invalid with your rules/checks, then the template 
'form.tt' renderer is passed the following hashref:

    {
    	lang => 'Perl',
    	version => '5.10',
    	error {
    		id => 'The answer is 42, not 41',
    	}
    }

This can be useful with a construct like C<[% error.name || name %]> 
in your template.

Third, you can pass some additional values that will be passed "as is"" to the 
on_fail template  
    
    $self->validate($rules, 
        on_error => 'form.tt',
        data => {
            message => 'You could try something else next time!'
        },
    );

Here the caller passes an additional key data so that your C<on_error> template 
renderer gets the following hash ref

    {
        lang => 'Perl',
        version => '5.10',
        error {
            id => 'The answer is 42, not 41',
        },
        message => 'You could try something else next time!'
    }


=head1 AUTHOR

Gurunandan R. Bhat E<lt>gbhat@pobox.comE<gt>

=head1 COPYRIGHT

Copyright 2013- Gurunandan R. Bhat

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Kelp>, L<Kelp::Module>, L<Validate::Tiny>

=cut
