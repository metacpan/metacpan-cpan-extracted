package Kwiki::Toolbar;
use Kwiki::Pane -Base;

const class_id => 'toolbar';
const pane_template => 'toolbar_pane.html';
const css_file => 'toolbar.css';
const config_file => 'toolbar.yaml';

sub order {
    @{$self->config->toolbar_order};
}

__DATA__

=head1 NAME

Kwiki::Toolbar - Kwiki Toolbar Plugin

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
__template/tt2/toolbar_pane.html__
<div class="toolbar">
[% units.join(' &nbsp; ') %]
</div>
__config/toolbar.yaml__
toolbar_order:
- search_box
- home_button
- recent_changes_button
- user_preferences_button
- new_page_button
- edit_button
- revisions_button
- revisions_controls
__css/toolbar.css__
div.toolbar {
}

