package Dyn::Callback 0.05 {
    use strict;
    use warnings;
    use 5.030;
    use XSLoader;
    XSLoader::load( __PACKAGE__, our $VERSION );
    use parent 'Exporter';
    our %EXPORT_TAGS;
    @{ $EXPORT_TAGS{all} } = our @EXPORT_OK = map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS;
};
1;
__END__

=encoding utf-8

=head1 NAME

Dyn::Callback - Perl Code as FFI Callbacks

=head1 SYNOPSIS

    use Dyn::Callback qw[:all];
    use Dyn::Load;
    use Dyn::Call qw[DC_CALL_C_DEFAULT];
    my $lib = Dyn::Load::dlLoadLibrary('path/to/lib.so');
    my $ptr = Dyn::Load::dlFindSymbol( $lib, 'timer' );
    my $cvm = dcNewCallVM(1024);
    Dyn::Call::dcMode( $cvm, DC_CALL_C_DEFAULT );
    Dyn::Call::dcReset($cvm);
    my $cb = dcbNewCallback(       # Accepts an int and returns an int
        'i)i',
        sub {
            my ($cb, $args, $result, $userdata) = @_;
            ...;                   # do something
            return 'i';
        },
        5
    );
    Dyn::Call::dcArgPointer( $cvm, $cb );    # pass callbacks as pointers
    Dyn::Call::dcCallVoid( $cvm, $ptr );     # your timer() function returns void

=head1 DESCRIPTION

Dyn::Callback is an interface to create callback objects that can be passed to
functions as callback arguments. In other words, a pointer to the callback
object can be "called" directly from the foreign library.

=head1 Functions

These may be imported by name or called directly.

=head2 C<dcbNewCallback( $signature, $coderef, $userdata )>

Creates a new callback object, where C<$signature> is a signature string
describing the function.

    my $pcb = dcbNewCallback(
        'i)i',
        sub {
            my ($cb, $args, $result, $userdata) = @_;
            ...;
            return 'i';
        },
        5
    );

Expected parameters include:

=over

=item C<signature> - string describing any parameters and return value

This is needed for dyncallback dyncallback to correctly prepare the arguments
passed in by the function that calls the callback handler.

=item C<code> - a code reference

Note that the code reference doesn't return the value specified in the
signature, directly, but a signature character, specifying the return value's
type. The return value itself is stored where the callback's 3rd parameter
points to (see below).

=item C<userdata> - optional, arbitrary data

This data, if defined, is passed back to the given coderef as the 4th
parameter.

=back

=head2 C<dcbInitCallback( ... )>

Initialize (or reinitialize) the callback object.

    dcbInitCallback( $pcb, 'i)Z', sub { ...; }, undef );

Expected parameters include:

=over

=item C<pcb> - Dyn::Callback object to reinitialize

=item C<signature> - string describing any parameters and return value

=item C<code> - a code reference

=item C<userdata> - optional, arbitrary data

=back

=head2 C<dcbFreeCallback( ... )>

Destroys and frees the callback.

    dcbFreeCallback( $pcb );

Expected parameters include:

=over

=item C<pcb> - Dyn::Callback object to reinitialize

=back

=head2 C<dcbGetUserData( ... )>

Returns the userdata passed to the callback object on creation or
initialization.

    my $data = dcbGetUserData( $pcb );

Expected parameters include:

=over

=item C<pcb> - Dyn::Callback object to query

=back

=head1 Example

Let's say, we want to create a callback object and call it. For simplicity,
this example will omit passing it as a function pointer to a function in a
separate library and demonstrate calling it directly. First, we need to define
our callback handler:

    sub cbHandler {
        my ( $cb, $args, $result, $userdata ) = @_;

        # $cb is a Dyn::Callback object
        # $args is a Dyn::Callback::Args object
        # $result is a Dyn::Callback::Value object
        # $userdata, if defined, is a normal Perl value
        my $arg1 = dcbArgInt($args);
        my $arg2 = dcbArgFloat($args);
        my $arg3 = dcbArgShort($args);
        my $arg4 = dcbArgDouble($args);
        my $arg5 = dcbArgLongLong($args);

        # do something here
        $result->s(1244);
        return 's';
    }

Note that the return value of the handler is a signature character, not the
actual return value, itself.  Now, let's call it through a Dyn::Callback
object:

    my $userdata = 1337;
    my $cb       = dcbNewCallback( 'ifsdl)s', \&cbHandler, $userdata );
    my $result   = $cb->call( 123, 23, 3, 1.82, 9909 );                   # $result is 1244
    dcbFreeCallback($cb);

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

reinitialize userdata dyncallback coderef

=end stopwords

=cut
