# $Id: /mirror/perl/HTTP-RobotsTag/trunk/lib/HTTP/RobotsTag.pm 31676 2007-12-10T00:06:35.669605Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endewoks.jp>
# All rights reserved.

package HTTP::RobotsTag;
use strict;
use warnings;
use Carp qw(croak);
use DateTime::Format::Strptime;
use HTTP::Headers;
use HTTP::RobotsTag::Rules;
our $VERSION = '0.00001';

sub new
{
    my $class = shift;
    my $self  = bless {}, $class;
    return $self;
}

my $re = qr{
    (
        (?:no)?
        (?:
            index   |
            archive |
            snippet |
            follow  |
            unavailable_after:.+
        )
    )
    (?:
        \s*,\s*
        |
        $
    )
}x;

sub parse_headers
{
    my ($self, $headers) = @_;

    if (! eval { $headers->can('header') }) {
        croak "argument does not implement a header() function";
    }

    my $fmt = DateTime::Format::Strptime->new(
        pattern => '%d %b %Y %H:%M:%S %Z'
    );

    my %directives;
    my @tags = $headers->header( 'x-robots-tag' );
    foreach my $tag (@tags) {
        while ($tag =~ /$re/g) {
            my($key, $val) = split(/:/, $tag, 2);
            $key = lc $key;
            if ($key eq 'unavailable_after') {
                $val =~ s/^\s+//;
                $val =~ s/\s+$//;
                $directives{ $key } = $fmt->parse_datetime($val) or die;
            } else {
                $directives{ $key } = $val || 1;
            }
        }
    }

    return HTTP::RobotsTag::Rules->new(%directives);
}

1;

__END__

=head1 NAME

HTTP::RobotsTag - Parse Robots Tag In HTTP Headers

=head1 SYNOPSIS

  use HTTP::RobotsTag;

  my $response = $lwp->get( $url );
  my $p        = HTTP::RobotsTag->new();
  my $rule     = $p->parse_headers( $response );

  if ($rule->can_index()) {
    ...
  }

  if ($rule->is_available( $dt )) {
    ...
  }

=head1 DESCRIPTION

HTTP::RobotsTag parses HTTP headers for X-Robots-Tag headers and stores the
information in a Rules object.

=head1 METHODS

=head2 new

=head2 parse_headers($headers)

Accepts a HTTP::Headers (or an object that implements the header()) method,
and looks for X-Robots-Tag headers.

=head1 AUTHOR

Copyright (c) 2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=head1 SEE ALSO

L<HTML::RobotsTag::Rules|HTML::RobotsTag::Rules> 

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut