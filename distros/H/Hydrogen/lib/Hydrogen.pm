use 5.008001;
use strict;
use warnings;

use List::Util ();
use Scalar::Util ();

package Hydrogen;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.017';

use Exporter::Shiny qw( croak fc );

sub croak {
    my ( $message, @args ) = @_;
    if ( @args ) {
        require Data::Dumper;
        local $Data::Dumper::Terse  = 1;
        local $Data::Dumper::Indent = 0;
        $message = sprintf $message, map {
            ref($_) ? Data::Dumper::Dumper($_) : defined($_) ? $_ : '(undef)'
        } @args;
    }
    require Carp;
    @_ = $message;
    goto \&Carp::croak;
}

if ( $] ge '5.016' ) {
    *fc = \&CORE::GLOBAL::fc;
}
else {
   eval 'sub fc { lc( @_ ? $_[0] : $_ ) }';
}

# Compatibility shim for Perl < 5.10
eval 'require re';
unless ( exists &re::is_regexp ) {
    require B;
    *re::is_regexp = sub {
        eval { B::svref_2object( $_[0] )->MAGIC->TYPE eq 'r' };
    };
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Hydrogen - utilities for the simplest elements of Perl

=head1 SYNOPSIS

Normal version of the function:

    use feature 'say';
    use Hydrogen::HashRef { prefix => 'hhr_' }, qw( get set );
    
    my %hash;
    hhr_set( \%hash, Alice => 123 );
    hhr_set( \%hash, Bob   => 456 );
    
    say $hash{Alice};                ## ==> 123
    say hhr_get( \%hash, 'Bob' );    ## ==> 456

Version of the function which uses prototypes:

    use feature 'say';
    use Hydrogen::Hash { prefix => 'hh_' }, qw( get set );
    
    my %hash;
    hh_set( %hash, Alice => 123 );
    hh_set( %hash, Bob   => 456 );
    
    say $hash{Alice};                ## ==> 123
    say hh_get( %hash, 'Bob' );      ## ==> 456

Currying:

    use feature 'say';
    use Hydrogen::Curry::HashRef qw( curry_get curry_set );
    
    my %hash;
    my $setter = curry_set( \%hash );
    my $getter = curry_get( \%hash );
    
    $setter->( Alice => 123 );
    $setter->( Bob   => 456 );
    
    say $hash{Alice};                ## ==> 123
    say $getter->( 'Bob' );          ## ==> 456

Using the C<< $_ >> topic variable:

    use feature 'say';
    use Hydrogen::Topic::HashRef qw( get set );
    
    local $_ = {};
    
    set( Alice => 123 );
    set( Bob   => 456 );
    
    say $_->{Alice};                 ## ==> 123
    say get( 'Bob' );                ## ==> 456

=head1 DESCRIPTION

L<Hydrogen> provides a standard library for doing really simple things in
Perl. And I mean I<really> simple things.

Things which are often Perl builtin functions, operators, and even just
part of Perl syntax like accessing keys within hashes.

=head1 RATIONALE

Whydrogen?

You can make a coderef pointing to C<< \&Hydrogen::Number::add >> but you
can't make a coderef pointing to Perl's C<< += >> operator!

If you are implementing a scripting language or DSL which needs to provide
a standard library of builtin functions, then Hydrogen may be a good place
to start.

=head1 THE HYDROGEN LIBRARY

=over

=item *

L<Hydrogen::ArrayRef>

=item *

L<Hydrogen::Bool>

=item *

L<Hydrogen::CodeRef>

=item *

L<Hydrogen::Counter>

=item *

L<Hydrogen::HashRef>

=item *

L<Hydrogen::Number>

=item *

L<Hydrogen::Scalar>

=item *

L<Hydrogen::String>

=back

=head2 Prototyped Functions

=over

=item *

L<Hydrogen::Array>

=item *

L<Hydrogen::Code>

=item *

L<Hydrogen::Hash>

=back

=head2 Curry Functions

=over

=item *

L<Hydrogen::Curry::ArrayRef>

=item *

L<Hydrogen::Curry::Bool>

=item *

L<Hydrogen::Curry::CodeRef>

=item *

L<Hydrogen::Curry::Counter>

=item *

L<Hydrogen::Curry::HashRef>

=item *

L<Hydrogen::Curry::Number>

=item *

L<Hydrogen::Curry::Scalar>

=item *

L<Hydrogen::Curry::String>

=back

=head2 Topicalized Functions

=over

=item *

L<Hydrogen::Topic::ArrayRef>

=item *

L<Hydrogen::Topic::Bool>

=item *

L<Hydrogen::Topic::CodeRef>

=item *

L<Hydrogen::Topic::Counter>

=item *

L<Hydrogen::Topic::HashRef>

=item *

L<Hydrogen::Topic::Number>

=item *

L<Hydrogen::Topic::Scalar>

=item *

L<Hydrogen::Topic::String>

=back

=head1 BONUS FUNCTIONS

Hydrogen uses the following functions internally, but they may also be
useful to you.

=head2 C<< Hydrogen::croak( $message, @args? ) >>

Acts like C<croak> from L<Carp>, but if C<< @args >> is provided, will
C<sprintf> first. If C<< @args >> contains references, those will be
dumped using L<Data::Dumper>.

=head2 C<< Hydrogen::fc( $string? ) >>

Acts like C<CORE::fc> if that function is available, and C<CORE::lc>
otherwise.

If no C<< $string >> is provided, operates on C<< $_ >>.

=head1 DEPENDENCIES

Hydrogen requires Perl 5.8.1 or above.

Hydrogen requires the modules L<Carp>, L<Data::Dumper>, L<List::Util>, and
L<Scalar::Util>, all of which normally come with Perl. Hydrogen needs at least
version 1.54 of List::Util; Perl versions older than 5.32.0 will be distributed
with older versions of List::Util, but upgrades to the module can be found on
the CPAN.

Hydrogen also requires the module L<Exporter::Shiny> which can be found on
the CPAN.

Hydrogen's test suite requires the module L<Test2::V0> which can be found on
the CPAN.

=head1 BUGS

Please report any bugs to
L<http://github.com/tobyink/p5-hydrogen/issues>.

=head1 SEE ALSO

This standard library is autogenerated from L<Sub::HandlesVia> which provides
the same functionality as methods which objects can delegate to attributes.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

