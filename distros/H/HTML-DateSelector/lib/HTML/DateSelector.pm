package HTML::DateSelector;
use strict;
use warnings;
use Carp;
use 5.008001;
our $VERSION = '0.05';

sub _this_year {
    my ($class, ) = @_;

    my @localtime = localtime;
    return $localtime[5] + 1900;
}

sub year {
    my ($class, $prefix, $options) = @_;

    my $start = $options->{start_year} || $class->_this_year - 5;
    my $end   = $options->{end_year}   || $class->_this_year + 5;

    return $class->_select_html($prefix, 'year', $start, $end, $options);
}

sub month {
    my ($class, $prefix, $options) = @_;

    return $class->_select_html($prefix, 'month', 1, 12, $options);
}

sub day {
    my ($class, $prefix, $options) = @_;

    return $class->_select_html($prefix, 'day', 1, 31, $options);
}

sub hour {
    my ($class, $prefix, $options) = @_;

    return $class->_select_html($prefix, 'hour', 0, 23, $options);
}

sub minute {
    my ($class, $prefix, $options) = @_;

    return $class->_select_html($prefix, 'minute', 0, 59, $options);
}

sub _select_html {
    my ($class, $prefix, $type, $start, $end, $options) = @_;

    my $result = '';
    $result .= qq{<select name="${prefix}_$type" id="${prefix}_$type">\n};
    $result .= qq{<option value=""></option>\n} if $options->{include_blank};
    for my $i ($start..$end) {
        $result .= qq{<option value="$i">$i</option>\n};
    }
    $result .= qq{</select>};
    return $result;
}

sub ymd {
    my ( $class, $prefix, $options ) = @_;

    return join( "\n\n",
                 $class->ym($prefix, $options),
                 $class->day( $prefix, $options ) );
}

sub ym {
    my ( $class, $prefix, $options ) = @_;

    return join( "\n\n",
                 $class->year( $prefix, $options ),
                 $class->month( $prefix, $options ),
             );
}

1;
__END__

=head1 NAME

HTML::DateSelector - Generate HTML for date selector.

=head1 SYNOPSIS

    use HTML::DateSelector;
    HTML::DateSelector->ymd('start_on');

=head1 DESCRIPTION

generate HTML for date selector.

=head1 CLASS METHODS

=head2 ymd

=head2 ym

    my $html = HTML::DateSelector->ymd('start_on');
    my $html = HTML::DateSelector->ym('start_on');

date selector.

ymd => year, month, day.
ym => year, month.

=head2 year

    my $html = HTML::DateSelector->year('start_on');
    my $html = HTML::DateSelector->year('start_on', {start_on => 2000, end_on => 2005});

Year selector.You can set the span of year.

=head2 month

=head2 day

=head2 hour

=head2 minute

  my $html = HTML::DateSelector->hour('start_on');
  my $html = HTML::DateSelector->minute('start_on');
  # and...

primitive selector.month, day, hour, minute.

=head1 OPTIONS

=head2 include_blank

you can select the blank.

=head1 AUTHOR

Tokuhiro Matsuno  C<< <tokuhirom @__at__ gmail.com> >>

=head1 SEE ALSO

L<http://dev.rubyonrails.org/browser/trunk/actionpack/lib/action_view/helpers/date_helper.rb>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006, Tokuhiro Matsuno C<< <tokuhiro __at__ mobilefactory.jp> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Ruby on Rails itself.
