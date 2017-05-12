# ABSTRACT: Adds a TO_JSON method to DateTime

package DateTimeX::TO_JSON;
$DateTimeX::TO_JSON::VERSION = '0.0.2';
use strict;
use warnings;
use Class::Load;
use Carp;

sub import {
    my ($class, @args) = @_;

    ## Only deal with formatter just now but might deal with more later
    ## such as importing DateTime itself
    my %args;
    while ($_ = shift @args) {
        if ( $_ eq 'formatter' ) {
            $args{$_} = shift @args;
        }
    }

    if ( $args{formatter} && ref($args{formatter}) ) {
        *DateTime::TO_JSON = sub {
            $args{formatter}->format_datetime($_[0]);
        }
    }
    elsif ( $args{formatter} ) {
        Class::Load::load_class $args{formatter};
        *DateTime::TO_JSON = sub {
            $args{formatter}->new->format_datetime($_[0]);
        }
    }
    else {
        *DateTime::TO_JSON = sub {
            $_[0]->datetime;
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DateTimeX::TO_JSON - Adds a TO_JSON method to DateTime

=head1 VERSION

version 0.0.2

=head1 SYNOPSIS

  use DateTime;
  use JSON;
  use DateTimeX::TO_JSON formatter => 'DateTime::Format::RFC3339';

  my $dt = DateTime->now;
  my $out = JSON->new->convert_blessed(1)->encode([$dt]);

=head1 DESCRIPTION

Adds a TO_JSON method to L<DateTime> so that L<JSON> and other
JSON serializers can serialize it when it encounters it a data
structure.

Can be given an optional DateTime formatter on import such as
L<DateTime::Format::RFC3339>. Any formatter that supports new and
format_datetime will work.
Defaults to turning DateTime into a string by calling L<DateTime/datetime>

If you want to format the date in your own way, then just define the following
function in your code instead of using this module:

    sub DateTime::TO_JSON {
        my $dt = shift;
        # do something with $dt, such as:
        return $dt->ymd;
    }

=head1 AUTHOR

Steven Humphrey <shumphrey@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Steven Humphrey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
