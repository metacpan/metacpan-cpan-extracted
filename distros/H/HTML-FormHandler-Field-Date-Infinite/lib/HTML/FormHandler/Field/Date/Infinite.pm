package HTML::FormHandler::Field::Date::Infinite;

use Moose;
extends 'HTML::FormHandler::Field::Date';

use version; our $VERSION = qv('0.1.3');

has 'deflate_method' => ( is => "ro",
                          default => sub { \&_my_date_deflate } );

sub _my_date_deflate {

    my ( $self, $value ) = @_;

    if ($value->is_infinite) {
        ## plain stringification
        if ( $value->isa("DateTime::Infinite::Future")) {
            return "infinity";
        }
        else {
            return "-infinity";
        }
    }
    else {
        return HTML::FormHandler::Field::Date::date_deflate($self,$value);
    }

};

override 'validate' => sub {

    my $self = shift;

    if ( $self->value and $self->value =~ /^(-?inf)(?:init[ey])?$/i) {
        return $self->_set_value( lc $1 eq "-inf" ? DateTime::Infinite::Past->new : DateTime::Infinite::Future->new );
    }
    else {
        return super();
    }

};

__PACKAGE__->meta->make_immutable;
use namespace::autoclean;

1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

HTML::FormHandler::Field::Date::Infinite - Subclass of
HTML::FormHandler::Field::Date that supports DateTime::Infinite.

Valid input strings are:

-inf
inf
-infinit[ey]
infinit[ey]

=head1 VERSION

This document describes HTML::FormHandler::Field::Date::Infinite version 0.1.3

=head1 SYNOPSIS

## In your form:

has_field my_date => (
    type => 'Date::Infinite',
);

## when rendered it will now display -inf / inf and accepts variations
## of "infinite" as input and will update the model as
## apropriate. Otherwise works as a normal HF::Field::Date

=head1 DESCRIPTION

A slight alteration of the original FH::Field::Date to make it also
accept infinite input for dates (DateTime supports this).

=head1 DIAGNOSTICS

This module does not introduce new errors, if any, they originate from
in HTML::FormHandler::Field::Date or above.

=head1 CONFIGURATION AND ENVIRONMENT

HTML::FormHandler::Field::Date::Infinite requires no configuration files or environment variables.

=head1 DEPENDENCIES

DateTime

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-html-formhandler-field-date-infinite@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Torbjørn Lindahl  C<< <torbjorn.lindahl@gmail.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Torbjørn Lindahl C<< <torbjorn.lindahl@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
