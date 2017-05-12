package Mac::Safari::JavaScript::Exception;

# This isn't a problem, all Macs have at least 5.8
use 5.008;

use strict;
use warnings;

our $VERSION = "0.04";

# overload stringification, but also overload boolean evalulation so
# if the string form of this exception is the empty string, this still
# has a true value
use overload '""' => "to_string", bool => sub { 1 }, fallback => 1;

# this is super lightweight.  I'd feel more comfortable writing this in moose,
# as that would give us nice error checking, but that's too much dependancy
# for such a simple class

sub new {
  my $class = shift;
  return bless { @_ }, $class;
}

sub name     { return $_[0]->{name}     }
sub line     { return $_[0]->{line}     }
sub sourceId { return $_[0]->{sourceId} }  ## no critic (ProhibitMixedCaseSubs)
sub message  { return $_[0]->{message}  }
sub error    { return $_[0]->{error}    }
sub expressionBeginOffset                  ## no critic (ProhibitMixedCaseSubs)
             { return $_[0]->{expressionBeginOffset} }
sub expressionEndOffset                    ## no critic (ProhibitMixedCaseSubs)
             { return $_[0]->{expressionEndOffset} }

sub to_string { return exists $_[0]->{message} ? $_[0]->{message} : $_[0]->{error}; }

1;

__END__

=head1 NAME

Mac::Safari::JavaScript::Exception - exception class to represent JS errors

=head1 SYNOPSIS

  use Mac::Safari::JavaScript qw(safari_js);
  
  eval {
    safari_js "compile time error!";
  };
  
  if ($@) {
     say "'$@' at line ".$@->line;
  }

=head1 DESCRIPTION

Error class for errors originating from Mac::Safari::JavaScript.

=head2 Constructors

=over

=item new(%params)

Creates a new instance of the object.  Expects the read only attributes (described below)
as parameters.  You shouldn't have to ever call this - these objects should be constructed
by Mac::Safari::JavaScript

=back

=head2 Accessors

The following read only accessors are avalible

=over

=item error

The original error object.

=item name

The type of the error.  This can be one of the following:

=over 8

=item CustomError

=item EvalError

=item RangeError

=item ReferenceError

=item SyntaxError

=item TypeError

=item URIError

=back

The name C<CustomError> will be used for any error thrown with the C<throw> keyword
by you in your code.  Other error codes are assigned by Safari based on the type of
exception that occurs.

=item message

The string describing the error as set by the browser.  This value
will B<not> be set if you simply throw a string (the string will
be contained in the C<error> accessor)

=item line

The line number the error occured on.

This is only set for browser raised errors
or if you throw an exception object.  Throwing a string will not 

=item expressionBeginOffset

This value is not avalble on modern Safari (since Version 5.1.3
(7534.53.10)).  This will only be set if you manually throw an
exception object (and only an object, not a string.) 

The index of the first character of your source code that threw
the exception object.

=item expressionEndOffset

This value is not avalble on modern Safari (since Version 5.1.3
(7534.53.10)).  This will only be set if you manually throw an
exception object (and only an object, not a string.) 

The index of the last character of your source code that threw
the exception object.

=item sourceId

The unique identifier for the originating source of the error.

(The odd case for this accessor matches the odd case that Safari itself uses)

=back

=head2 Methods

=over

=item to_string

The stringiftication of this error.

This method is automatically called if you use this object in a string context.

=back

=head1 AUTHOR

Written by Mark Fowler <mark@twoshortplanks.com>

Copryright Mark Fowler 2011. All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 BUGS

Bugs should be reported to me via the CPAN RT system. http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mac::Safari::JavaScript

=head1 SEE ALSO

L<Mac::Safari::JavaScript>

=cut
