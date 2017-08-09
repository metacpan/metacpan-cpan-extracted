# ABSTRACT: Defines an error object to be used at various stages of JSON validation and SQL generation.


use strict;
use warnings;
use 5.014;

package JsonSQL::Error;

our $VERSION = '0.41'; # VERSION



sub new {
    my ( $class, $type, $message ) = @_;

    return bless {
        message   => $message,
        type      => $type
    }, $class;
}


sub is_error { 1 }


sub type {
    my $this = shift;
    return $this->{type};
}


sub stringify {
    my $this = shift;
    return "Error($this->{type}): $this->{message}";
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JsonSQL::Error - Defines an error object to be used at various stages of JSON validation and SQL generation.

=head1 VERSION

version 0.41

=head1 SYNOPSIS

To use this:

    return JsonSQL::Error->new(<error_type>, <error_msg>);

To check return values for errors:

    my $retval = myFunc();
    if ( eval { $retval->is_error } ) {
        return "An error occurred: $retval->{message}";
    } else {
        ...
    }

This module was inspired by Brian D Foy's post on The Effective Perler,
L<https://www.effectiveperlprogramming.com/2011/10/return-error-objects-instead-of-throwing-exceptions/>

=head1 METHODS

=head2 Constructor new($type, $message)

Instantiates and returns a new JsonSQL::Error object.

    $type      => Any string to group error messages by.
    $message   => The error message.

=head2 ObjectMethod is_error -> 1

Returns a true value. Used for conveniently catching errors:

    if ( eval { $result->is_error } ) {
      die $result->{message};
    }

=head2 ObjectMethod type() -> $type

Returns the type property. Useful for adding for/when loops to error handlers:

    for ( $result->type ) {
      when ( 'validate' ) {
        $err = "JSON schema validation error: <br />";
        $err .= "$result->{message} <br />";
        $err =~ s/\n/\<br \/\>/;
      }
      default {
        $err = "An unspecified error occurred. <br />";
      }
    }

=head2 ObjectMethod stringify() -> $string

Stringifies the error object and returns it.

=head1 AUTHOR

Chris Hoefler <bhoefler@draper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Hoefler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
