package MVC::Neaf::Exception;

use strict;
use warnings;
our $VERSION = 0.1901;

=head1 NAME

MVC::Neaf::Exception - Exception class for Not Even A Framework.

=head1 DESCRIPTION

Currently internal signalling or L<MVC::Neaf> is based on the exception
mechanism. To avoid collisions with user's exceptions or Perl errors,
these internal exceptions are blessed into this class.

Please see the neaf_err() function in L<MVC::Neaf>.

=cut

use Scalar::Util qw(blessed);
use Carp;
use overload '""' => "as_string";

=head1 METHODS

=head2 new( 500 )

=head2 new( %options )

Returns a new exception object.

=cut

sub new {
    my $class = shift;
    if (@_ % 2) {
        my $err = shift;
        push @_, -status => $err;
    };
    my %opt = @_;

    if ($opt{-status}) {
        $opt{-status} =~ /^(\d\d\d)(?:\s|$)/s
            or croak "$class->new: status must be 3-digit";
        $opt{-status} = $1;
    } else {
        $opt{-status} = 500;
        $opt{-sudden} = 1;
    };

    return bless \%opt, $class;
};

=head2 status()

Return error code.

=cut

sub status {
    my $self = shift;
    return $self->{-status};
};

=head2 is_sudden()

Tells whether error was unexpected.

B<EXPERIMENTAL>. Name and meaning subject to change.

=cut

sub is_sudden {
    my $self = shift;
    return $self->{-sudden} ? 1 : 0;
};

=head2 message()

Error -message, if that was given.

B<EXPERIMENTAL>. Name and meaning subject to change.

=cut

sub message {
    my $self = shift;
    return $self->{message};
};

=head2 as_string()

Stringify. Result is guaranteed to start with MVC::Neaf.

=cut

sub as_string {
    my $self = shift;

    return "MVC::Neaf redirect: see $self->{-location}"
        if $self->{-status} eq 302 and $self->{-location};
    return "MVC::Neaf error $self->{-status}"
        .( $self->{message} ? ": $self->{message}" : "");
};

=head2 TO_JSON()

Converts exception to JSON, so that it doesn't frighten View::JS.

=cut

sub TO_JSON {
    my $self = shift;
    return { %$self };
};

1;
