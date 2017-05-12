package FormValidator::LazyWay::Fix::DateTime;

use strict;
use warnings;
use DateTime::Format::Strptime;

sub format {
    my $text = shift;
    my $args = shift || { pattern => '%Y-%m-%d %H:%M:%S' };

    return unless $text;

    my $strp = DateTime::Format::Strptime->new( %{$args}  );
    my $dt = $strp->parse_datetime($text);
    return $dt;
}

1;
