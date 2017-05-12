package JSPL::Stash;
1;

__END__

=head1 NAME

JSPL::Stash - Perl namespaces reflector for JavaScript.

=head1 DESCRIPTION

Every perl namespace when exposed to JavaScript either automatically or by the
methods of the  L<JSPL::Controller> perl class is represented by an instance of a
C<Stash>.

In perl a particular namespace can be used for different things. From simply to
collect a bunch of variables and subroutines, to implement a complete class, or
can act as a class "broker" when its static methods are constructors for other
classes.
The ways in which you can use C<Stash> instances in javascript are different too.

In fact a perl namespace can be exposed to javascript without binding the
associated C<Stash> instance into any property in your global object,
making it invisible and its use transparent. That whats happens when
a perl object enters javascript land and you call its instance methods.

=head1 Javascript interface

TBD

=head1 Perl interface

The value returned by L<JSPL::Controller/add> and C<Stash> instances
entering perl land are wrapped as C<JSPL::Stash> objects.

    my $ctl = $ctx->get_controller;
    my $stash = $ctl->add('DBI'); # Expose to js the package 'DBI'.

=head2 Instance methods

=over 4

=item allow_from_js ( [ BOOLEAN ] )

    my $old = $stash->allow_from_js($bool);

Call this with a TRUE value to allow javascript code to make changes to the
associated perl namespace. All namespaces are, by default, not modifiable from
javascript. Returns the previous state of the flag.

For example:

    # Expose the namespace 'ForJSUse'
    my $stash = $ctl->add('ForJSuse');
    # Make 'ForJSUse' modifiable by js code
    $stash->allow_from_js(1);

=item class_bind ( I<BIND_POINT> )

    $stash->class_bind($prop_name);

Make the package visible in javascript I<as a class> under the given property 
I<BIND_POINT>.

For example:

    require 'DBI';
    $ctl->add('DBI')->class_bind('DBI');

Exposes the perl package 'DBI' and binds it to the property of the same name as
a class, allowing to call its methods as static ones.

=item package_bind ( I<BIND_POINT> )

    $stash->package_bind($prop_name);

Make the package visible in javascript I<as a simple> collection of values (normally
soubroutines) under the property I<BIND_POINT>.

For example:

    require 'POSIX';
    $ctl->add('POSIX')->package_bind('POSIX');

So you can call any subroutine in package 'POSIX' from javascript:

    // In javascript land
    var fd = POSIX.open('foo', POSIX.O_RDONLY());
    // Yes, fd is a real file descriptor
    POSIX.lseek(fd, 0, POSIX.SEEK_SET())
    ...
    POSIX.close(fd);

=item set_constructor ( )

=item set_constructor ( CODE )

=item set_constructor ( SUB_NAME )

TBD

=item add_properties

TBD

=back

