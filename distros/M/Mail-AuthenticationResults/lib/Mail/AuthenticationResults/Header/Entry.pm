package Mail::AuthenticationResults::Header::Entry;
# ABSTRACT: Class modelling Main Entry parts of the Authentication Results Header

require 5.008;
use strict;
use warnings;
our $VERSION = '2.20210915'; # VERSION
use Scalar::Util qw{ refaddr };
use Carp;

use base 'Mail::AuthenticationResults::Header::Base';


sub _HAS_KEY{ return 1; }
sub _HAS_VALUE{ return 1; }
sub _HAS_CHILDREN{ return 1; }

sub _ALLOWED_CHILDREN {
    my ( $self, $child ) = @_;
    return 1 if ref $child eq 'Mail::AuthenticationResults::Header::Comment';
    return 1 if ref $child eq 'Mail::AuthenticationResults::Header::SubEntry';
    return 1 if ref $child eq 'Mail::AuthenticationResults::Header::Version';
    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::AuthenticationResults::Header::Entry - Class modelling Main Entry parts of the Authentication Results Header

=head1 VERSION

version 2.20210915

=head1 DESCRIPTION

Entries are the main result of an Authentication Resutls check, an example of this
would be "dkim=pass" or "dmarc=fail", there may be additional comments of sub entries
associated with this entry, these are represented as children of this class.

Please see L<Mail::AuthenticationResults::Header::Base>

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
