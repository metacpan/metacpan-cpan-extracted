package Fancy::Middleware;
BEGIN {
  $Fancy::Middleware::VERSION = '1.101680';
}
use MooseX::Declare;

#ABSTRACT: Provides alternate implementation of Plack::Middleware in a Moose Role




role Fancy::Middleware
{
    use POEx::Types::PSGIServer(':all');
    use MooseX::Types::Moose(':all');


    has app => (is => 'ro', isa => CodeRef, required => 1);


    has response => (is => 'ro', isa => PSGIResponse, writer => 'set_response');

    
    has env => (is => 'ro', isa => HashRef, writer => 'set_env');


    method wrap(ClassName $class: CodeRef $app, @args)
    {
        my $self = $class->new(app => $app, @args);
        return $self->to_app;
    }


    method call(HashRef $env)
    {
        $self->set_env($env);
        $self->preinvoke();
        $self->invoke();
        $self->postinvoke();
        return $self->response;
    }


    method preinvoke()
    {
        return;
    }


    method invoke()
    {
        $self->set_response(($self->app)->($self->env));
    }


    method postinvoke()
    {
        return;
    }


    method to_app()
    {   
        return sub { $self->call(@_) };
    }
}

1;


=pod

=head1 NAME

Fancy::Middleware - Provides alternate implementation of Plack::Middleware in a Moose Role

=head1 VERSION

version 1.101680

=head1 SYNOPSIS

    use MooseX::Declare;
    
    class My::Custom::Middleware::Logger
    {
        with 'Fancy::Middleware';

        has logger =>
        (
            is => 'ro',
            isa => 'SomeLoggerClass',
            required => 1,
        );

        around preinvoke()
        {
            $self->env->{'my.custom.middleware.logger'} = $self->logger;
        }
    }

    ...

    my $app = My::Web::Simple::Subclass->as_psgi_app();
    $app = My::Custom::Middleware::Logger->wrap($app, logger => $some_logger_instance);

=head1 DESCRIPTION

Fancy::Middleware is an alternate implementation of the Plack::Middleware base
class but as a Moose Role instead. This gives us a bit more flexibility in how 
how the Middleware functionality is gained in a class without having to
explicitly subclass. That said, this Role should fit in just fine with other
Plack::Middleware implemented solutions as the API is similar.

There are some differences that should be noted.

Three distinct "phases" were realized: L</preinvoke>, L</invoke>,
L</postinvoke>. This allows more fine grained control on where in the process
middleware customizations should take place.

Also, more validation is in place than provided by Plack::Middleware. The
response is checked against L<POEx::Types::PSGIServer/PSGIResponse>, the
L</env> hash is constrained to HashRef, and L</app> is constrained to a
CodeRef.

=head1 CLASS_METHODS

=head2 wrap

    (ClassName $class: CodeRef $app, @args)

wrap is defined by Plack::Middleware as a method that takes a PSGI application
coderef and wraps is with the middleware, returning the now wrapped coderef.

Internally, this means the class itself is instantiated with the provided
arguments with $app being passed to the constructor as well. Then to_app is
called and the result returned.

=head1 PUBLIC_ATTRIBUTES

=head2 app

    is: ro, isa: CodeRef, required: 1

app is the actual PSGI application. 

=head2 response

    is: ro, isa: PSGIResponse, writer: set_response

response holds the result from the invocation of the PSGI application. This is
useful if the response needs to be filtered after invocation. 

=head2 env

    is: ro, isa: HashRef, writer: set_env

env has the environment hash passed from the server during L</call>.

=head1 PUBLIC_METHODS

=head2 call

    (HashRef $env)

call is also defined by Plack::Middleware as the method to implement to perform
work upon the provided application with the supplied $env hash. Instead of 
overriding this method, move your implementation pieces into one of the methods
below.

=head2 preinvoke

preinvoke is called prior to L</invoke>. By default it simply returns. Exclude
or advise this method to provide any work that should take place prior to
actually invoking the application. Note, that there isn't a valid PSGIResponse
at this point. 

=head2 invoke

invoke executes L</app> with L</env> provided as the argument. The result is
stored in L</response>. If application execution should be short circuited for
any reason, this would be the place to do it.

=head2 postinvoke

postinvoke is called after invoke returns. If the L</response> needs filtering
applied to it, this is the place to do it.

=head2 to_app

to_app returns a coderef that closes around $self. When executed, it calls
L</call> with all of the arguments presented to it. 

=head1 AUTHOR

  Nicholas R. Perez <nperez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Nicholas R. Perez <nperez@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

