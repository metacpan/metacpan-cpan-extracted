package Kwiki::Widgets::RecentChanges;
use Kwiki::Plugin -Base;
use mixin 'Kwiki::Installer';
our $VERSION = '0.01';

const class_id => 'widgets_recent_changes';
const class_title => 'Widgets Recent Changes';

sub register {
    my $registry = shift;
    $registry->add(widget => 'recent_changes',
		   template => 'widgets_recent_changes.html');
    $registry->add(preference => $self->recent_changes_numbers);
}

sub recent_changes_numbers {
    my $p = $self->new_preference('widget_recent_changes_numbers');
    $p->query('How many recent changed pages to display in the widget ?');
    $p->type('pulldown');
    my $choices = [ qw(5 5 10 10 15 15 20 20) ];
    $p->choices($choices);
    $p->default(5);
    return $p;
}

sub get_pages {
    my $number = $self->preferences->widget_recent_changes_numbers->value;
    my @pages = sort { 
        $b->modified_time <=> $a->modified_time 
    } $self->pages->recent_by_count($number);
    return \@pages;
}

__DATA__

=head1 NAME

  Kwiki::Widgets::RecentChanges - Widget version of RecentChaneges

=head1 SYNOPSIS

  # kwiki -install Kwiki::Widgets::RecentChanges

=head1 DESCRIPTION

This widget gives you a small recent changed page list (configurable
from user preference) on the theme's widget pane. Hence it depends
on L<Kwiki::Widgets> and your theme must display widgets too,
otherwise this plugin will not change anything on your screen.

=head1 COPYRIGHT

Copyright 2005 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut

__template/tt2/widgets_recent_changes.html__
<div id="widgets_recent_changes">
<h4>Recent Changes</h4>
<ul>
[% FOREACH page = hub.widgets_recent_changes.get_pages %]
<li>[% page.kwiki_link %]</li>
[% END %]
</ul>
</div>
