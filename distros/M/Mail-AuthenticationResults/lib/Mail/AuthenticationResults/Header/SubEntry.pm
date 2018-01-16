package Mail::AuthenticationResults::Header::SubEntry;
# ABSTRACT: Class modelling Sub Entry parts of the Authentication Results Header

require 5.010;
use strict;
use warnings;
our $VERSION = '1.20180113'; # VERSION
use Carp;

use base 'Mail::AuthenticationResults::Header::Base';

sub _HAS_KEY{ return 1; }
sub _HAS_VALUE{ return 1; }
sub _HAS_CHILDREN{ return 1; }

sub _ALLOWED_CHILDREN {
    my ( $self, $child ) = @_;
    return 1 if ref $child eq 'Mail::AuthenticationResults::Header::Comment';
    return 1 if ref $child eq 'Mail::AuthenticationResults::Header::Version';
    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::AuthenticationResults::Header::SubEntry - Class modelling Sub Entry parts of the Authentication Results Header

=head1 VERSION

version 1.20180113

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
