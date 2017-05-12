package Eidolon::Core::Exception;
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   Eidolon/Core/Exception.pm - base exception class
#
# ==============================================================================

use base qw/Class::Accessor::Fast/;
use warnings;
use strict;

__PACKAGE__->mk_accessors(qw/message line file/);

our $VERSION = "0.02"; # 2009-05-14 04:42:38

use constant TITLE => "Base exception";

# overload some operations
use overload
    "bool" => sub { 1 },
    "eq"   => "overloaded_equ",
    '""'   => "overloaded_str";

# ------------------------------------------------------------------------------
# \% new($message)
# constructor
# ------------------------------------------------------------------------------
sub new
{
    my ($class, $message, $self);

    ($class, $message) = @_;

    # class attributes
    $self = 
    {
        "message" => $message,
        "line"    => undef,
        "file"    => undef
    };

    bless $self, $class;
    $self->_init;

    return $self;
}

# ------------------------------------------------------------------------------
# _init()
# class initialization
# ------------------------------------------------------------------------------
sub _init
{
    my ($self, $file, $line);

    $self = shift;

    # get caller info
    (undef, $file, $line) = caller(2);

    $self->file( $file );
    $self->line( $line );
}

# ------------------------------------------------------------------------------
# throw()
# throw exception
# ------------------------------------------------------------------------------
sub throw
{
    my $class = shift;

    $class->rethrow(@_) if (ref $class);
    die $class->new(@_);
}

# ------------------------------------------------------------------------------
# rethrow()
# rethrow exception
# ------------------------------------------------------------------------------
sub rethrow
{
    die $_[0] if (ref $_[0]);
}

# ------------------------------------------------------------------------------
# $ overloaded_equ($class)
# check the type of exception
# ------------------------------------------------------------------------------
sub overloaded_equ
{
    return $_[0]->isa($_[1]);
}

# ------------------------------------------------------------------------------
# $ overloaded_str()
# stringify exception
# ------------------------------------------------------------------------------
sub overloaded_str
{
    my ($self, $str);

    $self = shift;
    $str  = $self->TITLE;
    $str .= $self->message ? ": ".$self->message : "";

    return $str;
}

1;

__END__

=head1 NAME

Eidolon::Core::Exception - base exception class for Eidolon.

=head1 SYNOPSIS

General exception usage example:

    eval
    {
        # ...
        
        throw CoreError::Compile("Oops!");

        # ...
    };

    if ($@)
    {
        my $e = $@;

        if ($e eq "CoreError::Compile")
        {
            print $e; # prints "Oops!"
        }
        else
        {
            $e->rethrow;
        }
    }

=head1 DESCRIPTION

The I<Eidolon::Core::Exception> class is a base class for all core, driver and 
application exceptions. It contains various methods that can be useful for 
exception handling. This package is a rework of CPAN L<Exception> package.

=head1 METHODS

=head2 new($message)

Class constructor. Creates an exception object and calls class initialization
function. Don't raise exceptions using this method, use C<throw()> instead.

=head2 throw()

Throws exception. Actually, creates an I<Eidolon::Core::Exception> object and 
dies.

=head2 rethrow()

Rethrows the exception (if it was thrown before).

=head2 overloaded_equ($class)

Overloaded equality comparsion operator (==). Checks if exception is the
instance of C<$class> specified.

=head2 overloaded_str()

Overloaded stringify operation. Returns exception message.

=head1 SEE ALSO

L<Eidolon>, 
L<Eidolon::Core::Exception::Builder>,
L<Eidolon::Core::Exceptions>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Anton Belousov, E<lt>abel@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2009, Atma 7, L<http://www.atma7.com>

=cut
