package Mail::AuthenticationResults;
use strict;
use warnings;
our $VERSION = '1.20171226'; # VERSION

use Mail::AuthenticationResults::Parser;

sub new {
    my ( $class ) = @_;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub parser {
    my ( $self, $auth_headers ) = @_;
    return Mail::AuthenticationResults::Parser->new( $auth_headers );
}

1;

__END__

=head1 NAME

Mail::AuthenticationResults - Object Oriented Authentication-Results header class

=head1 DESCRIPTION

Object Oriented Authentication-Results email headers

=for markdown [![Code on GitHub](https://img.shields.io/badge/github-repo-blue.svg)](https://github.com/marcbradshaw/Mail-AuthenticationResults)

=for markdown [![Build Status](https://travis-ci.org/marcbradshaw/Mail-AuthenticationResults.svg?branch=master)](https://travis-ci.org/marcbradshaw/Mail-AuthenticationResults)

=for markdown [![Open Issues](https://img.shields.io/github/issues/marcbradshaw/Mail-AuthenticationResults.svg)](https://github.com/marcbradshaw/Mail-AuthenticationResults/issues)

=for markdown [![Dist on CPAN](https://img.shields.io/cpan/v/Mail-AuthenticationResults.svg)](https://metacpan.org/release/Mail-AuthenticationResults)

=for markdown [![CPANTS](https://img.shields.io/badge/cpants-kwalitee-blue.svg)](http://cpants.cpanauthors.org/dist/Mail-AuthenticationResults)


=head1 SYNOPSIS

    use Mail::AuthenticationResults;

=head1 CONSTRUCTOR

=over

=item new()

Return a new Mail::AuthenticationResults object

=back

=head1 PUBLIC METHODS

=over

=item parser( $auth_results )

Returns a new Mail::AuthenticationResults::Parser object
for the supplied $auth_results header

=back

=head1 DEPENDENCIES

  Carp
  Scalar::Util

=head1 BUGS

Please report bugs via the github tracker.

https://github.com/marcbradshaw/Mail-AuthenticationResults/issues

=head1 AUTHORS

Marc Bradshaw, E<lt>marc@marcbradshaw.netE<gt>

=head1 COPYRIGHT

Copyright (c) 2017, Marc Bradshaw.

=head1 LICENCE

This library is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=cut

