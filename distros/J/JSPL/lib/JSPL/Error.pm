package JSPL::Error;

use strict;
use warnings;
our @ISA = "JSPL::Object";
$Carp::Internal{ __PACKAGE__ }++;

use overload q{""} => '_as_string',
    fallback => 1;

sub __new {
    my $self = shift;
    $self = $self->SUPER::__new(@_);
    # Must use basic JSPL::Object methods, isn't tie-able yet
    my($rfn, $oln) = $self->FETCH('fileName') =~ /^(.+) line (\d+)$/;
    if($rfn) {
	$self->STORE('fileName', $rfn);
	$self->STORE('lineNumber', $self->FETCH('lineNumber') + $oln - 1);
    }
    $self;
}

sub _as_string {
    my $self = shift;
    return "$self->{message} at $self->{fileName} line $self->{lineNumber}";
}

sub message {
    $_[0]->{message};
}

sub file {
    $_[0]->{fileName};
}

sub line {
    $_[0]->{lineNumber};
}

sub stacktrace {
    my $stack = $_[0]->{stack};
    return () unless $stack;
    return map {
        /^(.*?)\@(.*?):(\d+)$/ && { function => $1, file => $2, lineno => $3 }
    } split /\n/, $stack;
}

sub new {
    my($proto, $mess, $file, $line) = @_;
    $mess ||= 'something fail';
    my $parms = "'$mess'";
    $parms .= ",'$file'" if $file || $line;
    $parms .= ",$line" if defined $line;
    JSPL::Context::current()->eval(qq{ new Error($parms); });
}

1;
__END__

=head1 NAME

JSPL::Error - Encapsulates errors thrown from JavaScript

=head1 DESCRIPTION

JavaScript runtime errors result in new C<Error> objects being created and thrown.
When not handled in JavaScript, those objects will arrive to perl space when are
wrapped as an instance of JSPL::Error and stored in C<$@>.

What happens next depends on the value of the option L<JSPL::Context/RaiseExceptions>.

=over 4

=item * 

If TRUE perl generates a fatal but trappable exception.

=item *

If FALSE the operation returns C<undef>

=back

The following shows an example:

    eval {
	$ctx->eval(q{
	    throw new Error("Whoops!"); // Synthesize a runtime error
	});
    }
    if($@) {
	print $@->toString(); # 'Error: Whoops!'
    }
	    
=head1 PERL INTERFACE

JSPL::Error inherits from L<JSPL::Object> so you use them as any other
JavaScript Object.

=head2 Constructor

In Perl you can create new JSPL::Error instances, useful when you need to
throw an exception from a perl function called from JavaScript:

    die(JSPL::Error->new('something fails'));

In fact, when you C<die> in perl land inside code that is being called from
JavaScript and if the error (in C<$@>) is a simple perl string, it will be
converted to an <Error> instance with the equivalent to
C<< JSPL::Error->new($@) >>.

So the code above is seen by JavaScript as if C<throw new Error('something fails');>
was executed.

=over 4

=item new($message)

=item new($message, $fileName)

=item new($message, $fileName, $lineNumber)

I<If inside perl code that is called from JavaScript>, C<new(...)> will constructs
a new JavaScript C<Error> instance, wrap it in a JSPL::Error object and return it.

If called outside, it dies with the error "Not in a javascript context".

=back

=head2 Instance properties

C<Error> instances in JavaScript have the following properties.

=over 4

=item message

Error message

=item name

Error Name

=item fileName

Path to file that raised this error.

=item lineNumber

Line number in file that raised this error.

=item stack

Stack trace.

=back

=head2 Instance methods

The following methods are simple perl wrappers over the properties above, use
when you like more methods than properties.

=over 4

=item message ( )

The cause of the exception.

=item file ( )

The name of the file that the caused the exception.

=item line ( )

The line number in the file that caused the exception.

=item as_string ( )

A stringification of the exception in the format C<$message at $file line $line>

=item stacktrace ( )

Returns the stacktrace for the exception as a list of hashrefs containing
C<function>, C<file> and C<lineno>.

=back

=head1 OVERLOADED OPERATIONS

This class overloads stringification an will return the result from the method
C<as_string>.

=cut
