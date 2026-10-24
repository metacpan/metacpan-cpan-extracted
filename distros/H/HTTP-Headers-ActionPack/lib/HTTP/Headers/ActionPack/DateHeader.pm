package HTTP::Headers::ActionPack::DateHeader;
# ABSTRACT: A Date Header

use strict;
use warnings;

our $VERSION = '0.10';

use HTTP::Headers::ActionPack::Util qw[
    header_to_date
    date_to_header
];

use parent 'HTTP::Headers::ActionPack::Core::Base';

sub BUILDARGS {
    my (undef, $date) = @_;
    +{ date => $date }
}

sub new_from_string {
    my ($class, $header_string) = @_;
    $class->new( header_to_date( $header_string ) );
}

sub as_string { date_to_header( (shift)->{'date'} ) }

# implement a simple API
sub second       { (shift)->{'date'}->second       }
sub minute       { (shift)->{'date'}->minute       }
sub hour         { (shift)->{'date'}->hour         }
sub day_of_month { (shift)->{'date'}->day_of_month }
sub month_number { (shift)->{'date'}->mon          }
sub fullmonth    { (shift)->{'date'}->fullmonth    }
sub month        { (shift)->{'date'}->month        }
sub year         { (shift)->{'date'}->year         }
sub day_of_week  { (shift)->{'date'}->day_of_week  }
sub day          { (shift)->{'date'}->day          }
sub fullday      { (shift)->{'date'}->fullday      }
sub epoch        { (shift)->{'date'}->epoch        }

sub date { (shift)->{'date'} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Headers::ActionPack::DateHeader - A Date Header

=head1 VERSION

version 0.10

=head1 SYNOPSIS

  use HTTP::Headers::ActionPack::DateHeader;

  # create from string
  my $date = HTTP::Headers::ActionPack::DateHeader->new_from_string(
      'Mon, 23 Apr 2012 14:14:19 GMT'
  );

  # create using Time::Peice object
  my $date = HTTP::Headers::ActionPack::DateHeader->new(
      $timepeice_object
  );

=head1 DESCRIPTION

This is an object which represents an HTTP header with a date.
It will inflate the header value into a L<Time::Piece> object
and proxy most of the relevant methods.

=head1 DateTime compatibility

I opted to not use L<DateTime> (by default) for this class since
it is not a core module and can be a memory hog at times. That said,
it should be noted that L<DateTime> objects are compatible with
this class. You will need to pass in a L<DateTime> instance to
C<new> and after that everything should behave properly. If you
want C<new_from_string> to inflate strings to L<DateTime> objects
you will need to override that method yourself.

=head1 METHODS

=over 4

=item C<date>

Returns the underlying L<Time::Piece> object.

=item C<new_from_string ( $date_header_string )>

This will take an HTTP header Date string
and parse it into and object.

=item C<as_string>

=item C<second>

=item C<minute>

=item C<hour>

=item C<day_of_month>

=item C<month_number>

=item C<fullmonth>

=item C<month>

=item C<year>

=item C<day_of_week>

=item C<day>

=item C<fullday>

=item C<epoch>

These delegate to the underlying L<Time::Piece> object.

=back

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/sartak/http-headers-actionpack/issues>.

=head1 SOURCE

The source code repository for HTTP-Headers-ActionPack can be found at L<https://github.com/sartak/http-headers-actionpack>.

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan@cpan.org>

=item *

Dave Rolsky <autarch@urth.org>

=item *

Robert Rothenberg <perl@rhizomnic.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 - 2026 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
