package Kwiki::PageTemperature;
use Kwiki::Plugin '-Base';
use mixin 'Kwiki::Installer';

const class_id             => 'page_temperature';
const time_period_minutes  => 60 * 24 * 60;
const color_divisor        => (60 * 24 * 60) / 255;

our $VERSION = '0.01';

sub register {
    my $registry = shift;
    $registry->add(status => 'page_temperature',
                   template => 'page_temperature.html',
                   show_for => 'display',
               );
}

sub page_age {
    my $page = $self->hub->pages->current;
    $page->age_in_minutes < $self->time_period_minutes
      ? $page->age_in_minutes
      : $self->time_period_minutes;
}

sub red {
    int(($self->time_period_minutes - $self->page_age)/$self->color_divisor);
}

sub blue {
    int($self->page_age/$self->color_divisor);
}

__DATA__

=head1 NAME

Kwiki::PageTemperature - Provide a visual cue to the age of a page

=head1 DESCRIPTION

Add a status that provides a colored cue to the age of a page. The
color is a combination of red and blue. The more recently changed
the page, the more red.

As distributed a page that is 60 or more days "cold" will show an
all blue status. In the future this time span will be chosen from
a preference.

=head1 AUTHORS

Chris Dent, <cdent@burningchrome.com>

=head1 SEE ALSO

L<Kwiki>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005, Chris Dent

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
__template/tt2/page_temperature.html__
<!-- BEGIN page_temperature -->
<div id="page_temperature" style="height: .25em;background-color: rgb([%- hub.page_temperature.red %], 0, [%- hub.page_temperature.blue %]);">&nbsp;</div>
<!-- END page_temperature -->
