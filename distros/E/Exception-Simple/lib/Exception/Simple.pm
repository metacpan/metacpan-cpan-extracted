package Exception::Simple;
use strict;
use warnings;

our $VERSION = '1.000001';
$VERSION = eval $VERSION;

use overload(
    'fallback' => 1,
    '""'       => sub { shift->as_string },
);
use Carp;

# __public__ #
sub throw{
    my $self = shift;
    my %params;

    if ( @_ == 1 ){
        %params = ( 'error' => $_[0] );
    } else {
         %params = ( @_ );
    }

    ( $params{'_package'}, $params{'_filename'}, $params{'_line'} ) = caller;

    die $self->_new( %params );
}

sub rethrow{
    die shift;
}

# __internal__ #

sub import {
    my ( $pkg, $alias ) = ( @_ );

    if ( $alias ) {
        my $target = caller;
        croak "sub $alias already exists in $target" if $target->can($alias);

        {
            no strict 'refs';
            *{"${target}::${alias}"} = sub() { return $pkg };
        }
    }
}

sub as_string{
    my $self = shift;
    return $self->error;
}

sub _new{
    my $invocant = shift;
    my %params = ( @_ );

    my $class = ref( $invocant ) || $invocant;
    my $self = bless( \%params, $class );

#serious business
    foreach my $key ( keys( %params ) ){
        if ( !$self->can( $key ) ){
            $self->_mk_accessor( $key );
        }
    }

    return $self;
}

#creates an accessor for $name
sub _mk_accessor{
    my ( $self, $name ) = @_;

    my $class = ref( $self ) || $self;
    {
        no strict 'refs';
        *{$class . '::' . $name} = sub {
            return shift->{ $name } || undef;
        };
    }
}

1;

=head1 NAME

Exception::Simple - simple exception class

=head1 SYNOPSIS

    use Exception::Simple;
    use Try::Tiny; #or just use eval {}, it's all good

    ### throw ###
    try{
        Exception::Simple->throw( 'oh noes!' );
    } catch {
        warn $_; #"oh noes!"
        warn $_->error; #"oh noes!"
    };

    my $data = {
        'foo' => 'bar',
        'fibble' => [qw/wibble bibble/],
    };
    try{
        Exception::Simple->throw(
            'error' => 'oh noes!',
            'data' => $data,
        );
    } catch {
        warn $_; #"oh noes!"
        warn $_->error; #"oh noes!"

        warn $_->data->{'foo'}; #"bar"
    };


=head1 DESCRIPTION

pretty simple exception class. auto creates argument accessors.
simple, lightweight and extensible are this modules goals.

=head1 ALIAS

When using this module, you can specify a shortcut method, so you don't have to
type the full module name each time.

This works by importing a sub with the name specified into the current namespace,
that returns the package name so you need to make sure this sub does not already exist,
or you'll get an error

e.g.

    use Exception::Simple qw/E/;
    use Try::Tiny; #or just use eval {}, it's all good

    ### throw ###
    try{
        E->throw( 'oh noes!' );
    } catch {
        warn ref $_; # Exception::Simple
        warn $_; #"oh noes!"
        warn $_->error; #"oh noes!"
    };

=head1 METHODS

=head2 throw

with just one argument $@->error is set
    Exception::Simple->throw( 'error message' );
    # $@ stringifies to $@->error

or set multiple arguments (creates accessors)
    Exception::Simple->throw(
        error => 'error message',
        data => 'custom attribute',
    );
    # warn $@->data or something

=head2 rethrow

say you catch an error, but then you want to uncatch it

    use Try::Tiny;

    try{
        Exception:Simple->throw( 'foobar' );
    } catch {
        if ( $_ eq 'foobar' ){
        #not our error, rethrow
            $_->rethrow;
        }
    };

=head2 error

accessor for error message (set if only 1 arg is passed to throw)

=head2 _package

package that threw the exception

=head2 _filename

filename of the code that threw the exception

=head2 _line

line number that threw the exception

=head1 CAVEATS

If you pass in package, filename or line, they will be overwritten with the caller information

If you don't pass in error, then you'll get an undef warning on stringify

=head1 SUPPORT

Please submit bugs through L<https://github.com/markwellis/exception-simple/issues>

For other issues, contact the maintainer

=head1 AUTHOR

Mark Ellis E<lt>markellis@cpan.orgE<gt>

=head1 CONTRIBUTORS

Stephen Thirlwall

=head1 SEE ALSO

L<Try::Tiny> L<aliased>

=head1 LICENSE

Copyright 2014 Mark Ellis E<lt>markellis@cpan.orgE<gt>

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
