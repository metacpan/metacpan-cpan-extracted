package Dyn::Callback 0.02 {
    use strict;
    use warnings;
    use 5.030;
    use XSLoader;
    XSLoader::load( __PACKAGE__, $Dyn::Callback::VERSION );
    use parent 'Exporter';
    our %EXPORT_TAGS = (
        dcb => [
            qw[ dcbNewCallback dcbInitCallback dcbFreeCallback dcbGetUserData
            ]
        ]
    );
    @{ $EXPORT_TAGS{all} } = our @EXPORT_OK = map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS;
};
1;
__END__

=encoding utf-8

=head1 NAME

Dyn::Callback - Perl Code as FFI Callbacks

=head1 SYNOPSIS

    use Dyn::Callback qw[:all];    # Exports nothing by default
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
            my ($in) = @_;
            ...;                   # do something
            return 1;
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

=head2 C<dcbNewCallback( ... )>

Creates a new callback object, where C<signature> is a signature string
describing the function.

    my $pcb = dcbNewCallback(
        'i)i',
        sub {
            my ($in) = @_;
            ...;
            return 1;
        },
        5
    );

Expected parameters include:

=over

=item C<signature> - string describing any parameters and return value

=item C<code> - a code reference

=item C<userdata> - optional, arbitrary data

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

    my $data = dcbFreeCallback( $pcb );

Expected parameters include:

=over

=item C<pcb> - Dyn::Callback object to reinitialize

=back

=head2 C<call( ... )>

Calls a Dyn::Callback object with the given parameters.

    my $ret = call( $pcb, 5 );

Expected parameters include:

=over

=item C<pcb> - Dyn::Callback object to reinitialize

=item C<...> - optional arguments

=back

Returns the value matching the provided signature.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

reinitialize userdata

=end stopwords

=cut
