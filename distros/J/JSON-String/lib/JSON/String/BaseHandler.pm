use strict;
use warnings;

package JSON::String::BaseHandler;

use Carp qw(croak);
our @CARP_NOT = qw(JSON::String::ARRAY JSON::String::HASH);

our $VERSION = '0.2.0'; # VERSION

use Sub::Exporter -setup => {
    exports => [
        '_reencode',
        '_recurse_wrap_value',
        'constructor' => \&build_constructor,
    ]
};

require JSON::String;

sub build_constructor {
    my($class, $name, $args) = @_;

    my $type = $args->{type};
    my $validator = sub {
        my $params = shift;

        unless ($params->{data} and ref($params->{data}) eq $type) {
            croak(qq(Expected $type ref for param 'data', but got ).ref($params->{data}));
        }
        unless ($params->{encoder}) {
            croak('encoder is a required param');
        }
    };

    return sub {
        my($class, %params) = @_;

        $validator->(\%params);
        return bless \%params, $class;
    };
}

sub encoder { shift->{encoder} }

sub _reencode { encoder(shift)->() }

sub _recurse_wrap_value {
    my($self, $val) = @_;
    return JSON::String::_construct_object($val, undef, encoder($self));
}

1;

=pod

=head1 NAME

JSON::String::BaseHandler - Common code for hashes and arrays in JSON::String

=head1 DESCRIPTION

This module is not intended to be used directly.  It contains code common to
L<JSON::String::HASH> and L<JSON::String::ARRAY>.

=head1 SEE ALSO

L<JSON::String>, L<JSON::String::ARRAY>, L<JSON::String::HASH>

=head1 AUTHOR

Anthony Brummett <brummett@cpan.org>

=head1 COPYRIGHT

Copyright 2015, Anthony Brummett.  This module is free software. It may
be used, redistributed and/or modified under the same terms as Perl itself.

=cut
