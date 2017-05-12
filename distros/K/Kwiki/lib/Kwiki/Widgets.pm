package Kwiki::Widgets;
use Kwiki::Pane -Base;

const class_id => 'widgets';
const pane_template => 'widgets_pane.html';
const pane_unit => 'widget';

__DATA__

=head1 NAME

Kwiki::Widgets - Kwiki Widgets Base Class

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
__template/tt2/widgets_pane.html__
<div class="widgets">
[% units.join("<br />") %]
</div>
