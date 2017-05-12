package HTTP::Method;

=head1 NAME

HTTP::Method - HTTP Request Method and Common Properties according to RFC 7231

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';

use strict;
use warnings;

use Carp;

use overload '""' => \&_to_string,
             fallback => 1;

=head1 SYNOPSIS

    use HTTP::Method;
    
    # prefered instantiation
    my $get_mth = HTTP::Method->GET;
    
    # or from string
    my $str_mth = HTTP::Method->new(uc 'get');
    
    # testing
    if ( $mth->is_GET ) { ... }
    
    # introspection
    $mth->is_method_safe;

or more intuative (and less strict!)

    use HTTP::Method ':case-insesitive';
    
    my $mth = HTTP::Method->new($str);
    printf "%s %s return the payload",
        $mth,
        $mth->is_head ? "does NOT" : "does";
                                    # "GET does return the payload"
                                    # "HEAD does NOT return the payload"

=cut

=head1 DESCRIPTION

There is a lot to say about HTTP Methods in L<RFC 7231 Section 4. Request Methods|https://tools.ietf.org/html/rfc7231#section-4>.
Most of the developers make the wrong assumption that it is just a 'uppercase
string'. This module will help writing better code as it does validation and
ensures right capitalization for the HTTP Method names.

As one could read in L<RFC 7231 Section 4.2 Common Method Properties|https://tools.ietf.org/html/rfc7231#section-4.2>
HTTP Methods do have properties and can be divided in: I<Safe Methods>,
I<Idempotent Methods> and I<Cacheable Methods>. These properties are just
predicate methods on a C<HTTP::Method> object

=cut

# this matrix is taken from RFC7231 and RFC5789
# or https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol#Request_methods
#
my %METHOD = (
    CONNECT     => {                                                    },
    DELETE      => {               is_idempotent => 1,                  },
    GET         => { is_safe => 1, is_idempotent => 1, is_cachable => 1 },
    HEAD        => { is_safe => 1, is_idempotent => 1, is_cachable => 1 },
    OPTIONS     => { is_safe => 1, is_idempotent => 1,                  },
    PATCH       => {                                   is_cachable => 1 },
    POST        => {                                   is_cachable => 1 },
    PUT         => {               is_idempotent => 1,                  },
    TRACE       => { is_safe => 1, is_idempotent => 1,                  },
);

=head1 CLASS METHODS

=cut

our $CASE_INSENSITIVE;

=head2 import

Called when module is being C<use>d. This is used to set case-sensitivity.

    use HTTP::Method ':case-insensitive';

such that:

    my $str = 'get';                # or result from functioncall
    
    my $mth = HTTP::Method->new($str);
                                    # do not need to make uppercase
    
    my $del = HTTP::Method->DEL;    # prefer uppercase
    
    print $mth if $mth->is_get;     # prints "GET"
                                    # predicate method is lowercase

=cut

sub import {
    my $class  = shift;
    my $pragma = shift;
    
    $CASE_INSENSITIVE = defined $pragma && $pragma eq ':case-insensitive';
    
    # make aliases from $mth->is_http-method-name to $mth->is_HTTP-METHOD-NAME
    if ($CASE_INSENSITIVE) {
        
        no strict 'refs';
        
        foreach my $token (keys %METHOD) {
            my $predicate = 'is_' . $token;
            my $alias = lc $predicate;
            *$alias = *$predicate;
            undef *$predicate;
        }
    }
}

=head2 new

Creates a new HTTP::Method object. It takes only 1 argument, a HTTP-METHOD-NAME.
It must be one of the methods defined in L<RFC 7231, SECTION 4.3. Method
Definitions|https://tools.ietf.org/html/rfc7231#section-4.3>. Valid names are:
C<GET>, C<HEAD>, C<POST>, C<PUT>, C<DELETE>, C<CONNECT>, C<OPTIONS> and C<TRACE>
and additionally C<PATCH>.

If used with C<:case-insensitive> one can use lowercase names as well.

=cut

sub new {
    my $class = shift;
    my $http_method_name = shift or carp "missing http-method-name";
    $http_method_name = uc $http_method_name if $CASE_INSENSITIVE;
    croak "unknown http-method-name: '$http_method_name'"
        unless exists $METHOD{ $http_method_name };
    return bless \$http_method_name, $class
}

=head1 METHODS

=head2 is_method_safe

From L<RFC 7231 Section 4.2.1. Safe Methods>

Request methods are considered "safe" if their defined semantics are
essentially read-only; i.e., the client does not request, and does
not expect, any state change on the origin server as a result of
applying a safe method to a target resource.  Likewise, reasonable
use of a safe method is not expected to cause any harm, loss of
property, or unusual burden on the origin server.

=cut

sub is_method_safe {
    my $self = shift;
    return $METHOD{$$self}{is_safe}
}

=head2 is_method_idempotent

From L<RFC 7231 Section 4.2.2. Idempotent Methods>

A request method is considered "idempotent" if the intended effect on
the server of multiple identical requests with that method is the
same as the effect for a single such request.  Of the request methods
defined by this specification, PUT, DELETE, and safe request methods
are idempotent.

=cut

sub is_method_idempotent {
    my $self = shift;
    return $METHOD{$$self}{is_idempotent}
}

=head2 is_method_cachable

From L<RFC 7231 Section 4.2.2. Cachable Methods>

Request methods can be defined as "cacheable" to indicate that
responses to them are allowed to be stored for future reuse; for
specific requirements see [RFC7234].  In general, safe methods that
do not depend on a current or authoritative response are defined as
cacheable; this specification defines GET, HEAD, and POST as
cacheable, although the overwhelming majority of cache
implementations only support GET and HEAD.

=cut

sub is_method_cachable {
    my $self = shift;
    return $METHOD{$$self}{is_cachable}
}

sub _to_string {
    my $self = shift;
    return $$self;
}

=head1 ALTERNATIVE INSTANTIATION

C<HTTP::Method> objects have an alternative way of instantiation. These help
building more robust code. You can use C<HTTP::Method::HTTP-METHODE-NAME()> for
most HTTP methods like

    my $mth = HTTP::Method::HTTP-METHOD-NAME();
                                    # non OOP

use the OOP constructors:

    my $mth = HTTP::Method->HTTP-METHOD-NAME
                                    # prefered way

instead of

    my $mth = HTTP::Method->new(uc 'http-method-name')
                                    # don't do this

The list below shows which are available:

=over

=item HTTP::Method::CONNECT

=item HTTP::Method::DELETE

=item HTTP::Method::GET

=item HTTP::Method::HEAD

=item HTTP::Method::OPTIONS

=item HTTP::Method::PATCH

=item HTTP::Method::POST

=item HTTP::Method::PUT

=item HTTP::Method::TRACE

=back

=cut

# create for all the known HTTP Methods in the matrix two methods:
# - HTTP::Method::HTTP-METHOD-NAME
#   a constructor so that we can call for example HTTP::Method->POST
# - is_HTTP-METHOD-NAME
#   a predicate to test if a method is a certain name
#   :case-insensitive will rename these to lowercase method names
#   is_http-method-name
#
{
    no strict 'refs';
    
    foreach my $http_method_name (keys %METHOD) {
        
        my $construct = $http_method_name;
        *$construct = sub {
            return bless \$http_method_name, __PACKAGE__
        };
        
        my $predicate = 'is_' . $http_method_name;
        $predicate = lc $predicate if $CASE_INSENSITIVE;
        *$predicate = sub {
            my $self = shift;
            return $$self eq $http_method_name
        };
    }
}

=head1 CAVEATS

=head2 Case-Insensitive

According to RFC 7231, SECTION 4.1 method tokens are case sensitive, unlike what
most developers think it is. This might be surprising and will become very
inconvenient if we had to think about it too much.

    use HTTP::Method ':case-insensitive';

Using the module this way will make it behave like we are most familiar with.

C<< HTTP::Method->new($string) >> 
creates a new HTTP::Method object that will always have an uppercase name.

C<< $mth = HTTP::Method->HTTP-METHOD-NAME >>
factory methods will be uppercased.

C<< $mth->is_http-method-name >>
predicate methods are lowercased

C<< "$mth" >> always stringfies to uppercase

If one does NOT use the C<import ':case-insensitive'> The above behaviour will
not be swithced on, resulting in some I<surprises>

    my $str = 'get';
    
    my $mth = HTTP::Method->new($str);
                                    # croak "unknown method"
                                    # only uppercase http-method-names
    
    warn "case-sensitive" if $mth ne HTTP::Method->GET;
                                    # $mth stringifies to original $str
                                    # HTTP::Method->GET eq "GET"
    
    $mth->is_get;                   # undefined method
                                    # predicates are spelled according
                                    # to normilization, uppercase
                                    #
                                    # $mth eq "get"
    
    $mth->is_GET;                   # undef
                                    # the internal token is lowercase
    
    $mth->is_method_cachable        # undef
                                    # 'get' is unknown to the RFC

Most of those could had been solved with passin in the right arument into the
constructor, using C<uc> like in

    my $mth = HTTP::Method->new(uc $str);
    
    print "$mth";                   # GET
    $mth->is_GET;                   # 1
    $mth->is_method_cachable;       # 1

=cut

=head1 ACKNOWLEDGEMENTS

Thank you Adam for inspiring me to write better readable code (don't look inside
the source!)

=head1 AUTHOR

Th. J. van Hoesel

=head1 SEE ALSO

=over

=item RFC-7231

=back

=cut

1;