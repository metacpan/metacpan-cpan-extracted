use strict;
use warnings;
package MetaCPAN::Client::Types;
# ABSTRACT: type checking helper class
$MetaCPAN::Client::Types::VERSION = '2.028000';
use Type::Tiny      ();
use Types::Standard ();
use Ref::Util qw< is_ref >;

use parent 'Exporter';
our @EXPORT_OK = qw< Str Int Time ArrayRef HashRef Bool >;

sub Str      { Types::Standard::Str      }
sub Int      { Types::Standard::Int      }
sub ArrayRef { Types::Standard::ArrayRef }
sub HashRef  { Types::Standard::HashRef  }
sub Bool     { Types::Standard::Bool     }

sub Time {
    return Type::Tiny->new(
        name       => "Time",
        constraint => sub { !is_ref($_) and /^[1-9][0-9]*(?:s|m|h)$/ },
        message    => sub { "$_ is not in time format (e.g. '5m')" },
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MetaCPAN::Client::Types - type checking helper class

=head1 VERSION

version 2.028000

=head1 METHODS

=head2 ArrayRef

=head2 Bool

=head2 HashRef

=head2 Int

=head2 Str

=head2 Time

=head1 AUTHORS

=over 4

=item *

Sawyer X <xsawyerx@cpan.org>

=item *

Mickey Nasriachi <mickey@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
