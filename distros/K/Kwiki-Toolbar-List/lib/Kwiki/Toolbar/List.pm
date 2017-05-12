package Kwiki::Toolbar::List;
use strict;
use warnings;
use Kwiki::Toolbar '-Base';

our $VERSION = 0.01;

#const class_id => 'toolbar';
const class_title => 'Kwiki Toolbar List';
const toolbar_template => 'toolbar_pane.html';
#const css_file => 'toolbar.css';
#const config_file => 'toolbar.yaml';

sub html {
    my $lookup = $self->hub->registry->lookup;
    my $tools = $lookup->{toolbar}
      or return '';
    my %toolmap;
    for (keys %$tools) {
        my $array = $tools->{$_};
        push @{$toolmap{$array->[0]}}, {@{$array}[1..$#{$array}]};
    }
    my %classmap = reverse %{$lookup->{classes}};
    my $x = 1;
    my %class_ids = map {
        ($classmap{$_}, $x++)
    } @{$self->hub->config->plugin_classes};
    my @class_ids = grep {
        delete $class_ids{$_}
    } @{$self->config->toolbar_order};
    push @class_ids, sort {
        $class_ids{$a} <=> $class_ids{$b}
    } keys %class_ids;
    my @toolbar_content = ();
    @toolbar_content = grep {
        defined $_ and do {
            my $button = $_;
            $button =~ s/<!--.*?-->//gs;
            $button =~ /\S/;
        }
    } map {
        $self->show($_) ? defined($_->{template}) ? $self->template->process($_->{template}) : undef : undef
    } map {
        defined $toolmap{$_} ? @{$toolmap{$_}} : ()
    } @class_ids;

    $self->template->process($self->toolbar_template,
        toolbar_content => \@toolbar_content,
	action		=> $self->hub->action,
    );
}

1;

__DATA__

=head1 NAME

Kwiki::Toolbar::List - Creates an unordered list for the toolbar items in a Kwiki site.

=head1 SYNOPSIS

     $ cpan Kwiki::Toolbar::List
     $ cd /path/to/kwiki
     $ echo "Kwiki::Toolbar::List" >> plugins
     $ kwiki -update

=head1 DESCRIPTION

Kwiki::Toolbar::List displays the toolbar items as a pipe delimited string which looks great but
is difficult to apply a style sheet to.  This module displays the toolbar as an
unordered list that can be styled easily.  It also provides more control from a template,
so if you don't like an unordered list, you can simply change the HTML in the template
instead of modifying a Perl module.

This module should be used in place of Kwiki::Toolbar.

Another module, Kwiki::Theme::TabNav provides an example of the styling that can be
applied to the toolbar.

=head1 AUTHOR

Dave Mabe <dmabe@runningland.com>

=head1 COPYRIGHT

Copyright (c) 2004. Dave Mabe. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
__template/tt2/toolbar_pane.html__
<!-- BEGIN toolbar_pane.html -->
<div class="toolbar">
<ul id="nav">
[% FOREACH item = toolbar_content -%]
<li>[% item %]</li>
[% END -%]
</ul>
</div>
<!-- END toolbar_pane.html -->
__config/toolbar.yaml__
toolbar_order:
- search
- display
- recent_changes
- user_preferences
- new_page
- edit
- revisions
