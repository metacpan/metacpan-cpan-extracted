package Hash::Param;

use warnings;
use strict;

=head1 NAME

Hash::Param - CGI/Catalyst::Request-like parameter-hash accessor/mutator

=head1 VERSION

Version 0.04

=head1 SYNPOSIS

    my $params = Hash::Param->new(parameters => {
        qw/a 1 b 2 c 3/,
        d => [qw/4 5 6 7/],
    })

    $result = $params->param( a )           # Returns 1
    $result = $params->param( d )           # Returns 4
    @result = $params->param( d )           # Returns 4, 5, 6, 7
    @result = $params->params               # Returns a, b, c, d
    $result = $params->params               # Returns { a => , b => 2,
                                                        c => 3, d => [ 4, 5, 6, 7 ] }
    @result = $params->params( a, b, d )    # Returns 1, 2, [ 4, 5, 6, 7 ]
    %result = $params->slice( a, b )        # Returns a => 1, b => 2

              $params->param( a => 8 )      # Sets a to 8
              $params->param( a => 8, 9 )   # Sets a to [ 8, 9 ]


=head1 DESCRIPTION

Hash::Param provides a CGI-param-like accessor/mutator for a hash

=cut

our $VERSION = '0.04';

use Moose;
use Carp::Clan;

use Hash::Slice;

has parameters => qw/accessor _parameters isa HashRef lazy_build 1/;
sub _build_parameters {
    return {};
}

has _is_rw => qw/is rw default 1/;

sub BUILD {
    my $self = shift;
    my $given = shift;

    if (my $is = $given->{is}) {
        if ($is =~ m/^(?:rw|readwrite|writable)$/i) {
            $self->_is_rw(1);
        }
        elsif ($is =~ m/^(?:ro|readonly)$/i) {
            $self->_is_rw(0);
        }
        else {
            croak "Don't understand this read/write designation: \"$is\"";
        }
    }

    for (qw/params hash data from/) {
        last if $self->{_parameters};
        $self->_parameters($given->{$_}) if $given->{$_};
    }
}

=head1 METHODS

=head2 Hash::Param->new( [ params => <params>, is => <is> ] )

Returns a new Hash::Param object with the given parameters

<params> should be a HASH reference (the object will be initialized with an empty hash if none is given)

<is> should be either C<ro> or C<rw> to indicate where the object is read-only or read-write, respectively

The object will be read-write by default

=head2 $params->param( <param> )

Returns the value of <param>

If the <param> value is an ARRAY reference:

=over

=item In list context, returns every value of the ARRAY

=item In scalar context, returns just the first value of the ARRAY

=back

=head2 $params->param( <param> => <value> )

Sets the value of <param> to <value>

Throws an error if $params is read-only

=head2 $params->param( <param> => <value>, <value>, ... )

Sets the value of <param> to an ARRAY reference consisting of [ <value>, <value>, ... ]

Throws an error if $params is read-only

=head2 $params->param

Returns a list of every param name

=head2 $params->parameter

An alias for ->param

=cut

sub parameter {
    my $self = shift;
    return $self->param(@_);
}

sub param {
    my $self = shift;

    if (@_ == 0) {
        return keys %{ $self->_parameters };
    }

    if (@_ == 1) {
        
        my $param = shift;

        if (ref $param eq "ARRAY") {
            return $self->params(@$param);
        }

        unless (exists $self->_parameters->{$param}) {
            return wantarray ? () : undef;
        }

        if (ref $self->_parameters->{$param} eq 'ARRAY') {
            return (wantarray)
              ? @{ $self->_parameters->{$param} }
              : $self->_parameters->{$param}->[0];
        }
        else {
            return (wantarray)
              ? ($self->_parameters->{$param})
              : $self->_parameters->{$param};
        }
    }
    elsif (@_ > 1) {
        my $field = shift;
        croak "Unable to modify readonly parameter \"@{[ $field || '' ]}\"" unless $self->_is_rw;
        $self->_parameters->{$field} = @_ > 1 ? [ @_ ] : $_[0];
    }
}

=head2 $params->params( <param>, <param>, ... )

Returns a list containing with value of each <param>

Returns an ARRAY reference in scalar context

If $params is read-only, then each ARRAY reference value will be copied first (if any)

=head2 $params->params

Returns a hash of the parameters stored in $param

In scalar context, will return a HASH reference (which will be copied first if $params is read-only)

=head2 $params->params( <hash> )

Sets the parameters of $params via <hash> (which should be a HASH reference)

Throws an error if $params is read-only

=head2 $params->parameters

An alias for ->params

=cut

sub parameters {
    my $self = shift;
    return $self->params(@_);
}

sub params {
    my $self = shift;
    if (@_) {
        if (1 == @_ && ref $_[0] eq "HASH") {
            croak "Unable to modify readonly parameters" unless $self->_is_rw;
            $self->_parameters($_[0]);
        }
        else {
            my @params = map { $self->_parameters->{$_} } @_;
            @params = map { ref $_ eq "ARRAY" ? [ @$_ ] : $_ } @params unless $self->_is_rw;
            return wantarray ? @params : \@params;
        }
    }
    else {
        return wantarray ? keys %{ $self->_parameters } : $self->_is_rw ? $self->_parameters : { %{ $self->_parameters } };
    }
}

=head2 $params->data( <hash> )

Sets the parameters of $params via <hash> (which should be a HASH reference)

Throws an error if $params is read-only

=cut

sub data {
    my $self = shift;
    $self->params(shift);
}

=head2 $params->get( <param> )

Returns the value of <param>

Does the same as $param->param( <param> )

=head2 $params->get( <param>, <param>, ... )

Returns a list containing with value of each <param>

Does the same as $param->params( <param>, <param>, ... )

=head2 $params->get

Returns a hash of the parameters stored in $param

Does the same as $param->params

=cut

sub get {
    my $self = shift;
    return $self->params unless @_;
    return $self->params(@_) if @_ > 1;
    return $self->param(@_);
}

=head2 $params->slice( <param>, <param>, ... )

Returns a hash slice of <param>, <param>, ...

Returns a HASH reference in scalar context

If $params is read-only, then the slice will be cloned

=cut

sub slice {
    my $self = shift;
    my $parameters = $self->_parameters;
    return $self->_is_rw ? Hash::Slice::slice $parameters, @_ : Hash::Slice::clone_slice $parameters, @_;
}

use MooseX::MakeImmutable;
MooseX::MakeImmutable->lock_down;

=head1 SYNOPSIS

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 SOURCE

You can contribute or fork this project via GitHub:

L<http://github.com/robertkrimen/hash-param/tree/master>

    git clone git://github.com/robertkrimen/hash-param.git Hash-Param

=head1 BUGS

Please report any bugs or feature requests to C<bug-hash-param at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hash-Param>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hash::Param


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Hash-Param>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hash-Param>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Hash-Param>

=item * Search CPAN

L<http://search.cpan.org/dist/Hash-Param>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Hash::Param
