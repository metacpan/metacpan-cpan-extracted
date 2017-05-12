package Kwiki::Status;
use Kwiki::Pane -Base;

const class_id => 'status';
const pane_template => 'status_pane.html';

__DATA__

=head1 NAME

Kwiki::Status - Kwiki Status Base Class

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
__template/tt2/status_pane.html__
<div class="status">
[% units.join("<br />") %]
</div>
