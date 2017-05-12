package Eidolon::Driver::Log;
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   Eidolon/Driver/Log.pm - generic log driver
#   
# ==============================================================================

use base qw/Eidolon::Driver/;
use Eidolon::Driver::Log::Exceptions;
use warnings;
use strict;

our $VERSION = "0.02"; # 2009-05-14 05:21:50

# ------------------------------------------------------------------------------
# \% new()
# constructor
# ------------------------------------------------------------------------------
sub new
{
    my ($class, $self);

    $class = shift;
    $self  = {};

    bless $self, $class;

    return $self;
}

# ------------------------------------------------------------------------------
# open()
# open log
# ------------------------------------------------------------------------------
sub open
{
    throw CoreError::AbstractMethod;
}

# ------------------------------------------------------------------------------
# close()
# close log
# ------------------------------------------------------------------------------
sub close
{
    throw CoreError::AbstractMethod;
}

# ------------------------------------------------------------------------------
# notice($msg)
# log notice
# ------------------------------------------------------------------------------
sub notice
{
    throw CoreError::AbstractMethod;
}

# ------------------------------------------------------------------------------
# warning($msg)
# log warning
# ------------------------------------------------------------------------------
sub warning
{
    throw CoreError::AbstractMethod;
}

# ------------------------------------------------------------------------------
# error($msg)
# log error
# ------------------------------------------------------------------------------
sub error
{
    throw CoreError::AbstractMethod;
}

1;

__END__

=head1 NAME

Eidolon::Driver::Log - Eidolon generic log driver.

=head1 SYNOPSIS

Example log driver:

    package MyApp::Driver::Log;
    use base qw/Eidolon::Driver::Log/;

    sub notice
    {
        my ($self, $msg) = @_;
        throw DriverError::Log::Open("This is just an example!");
    }

    sub warning
    {
        my ($self, $msg) = @_;
        throw DriverError::Log::Open("This is just an example!");
    }

    sub error
    {
        my ($self, $msg) = @_;
        throw DriverError::Log::Open("This is just an example!");
    }

=head1 DESCRIPTION

The I<Eidolon::Driver::Log> is a generic log driver for 
I<Eidolon>. It declares some functions that are common for all driver 
types and some abstract methods, that I<must> be overloaded in ancestor classes.
All log drivers should subclass this package.

=head1 METHODS

=head2 new()

Class constructor. 

=head2 open()

Opens log handle. Abstract method, should be overloaded by the ancestor class.

=head2 close()

Closes log handle. Abstract method, should be overloaded by the ancestor class.

=head2 notice($msg)

Log a notice message C<$msg>. Abstract method, should be overloaded by the 
ancestor class.

=head2 warning($msg)

Log a warning message C<$msg>. Abstract method, should be overloaded by the
ancestor class.

=head2 error($msg)

Log an error message C<$msg>. Abstract method, should be overloaded by the
ancestor class.

=head1 SEE ALSO

L<Eidolon>, L<Eidolon::Driver::Log::Exceptions>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Anton Belousov, E<lt>abel@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2009, Atma 7, L<http://www.atma7.com>

=cut
