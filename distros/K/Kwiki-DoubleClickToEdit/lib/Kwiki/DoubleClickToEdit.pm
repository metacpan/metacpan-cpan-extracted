package Kwiki::DoubleClickToEdit;
use Kwiki::Plugin -Base;
use mixin 'Kwiki::Installer';
use 5.006001;
our $VERSION = '0.10';

const class_id => 'double_click_to_edit';

sub javascript_file {
    return $self->preferences->double_click_to_edit->value
    ? 'double_click_to_edit.js'
    : ''
}

sub register {
    my $registry = shift;
    $registry->add(preload => 'double_click_to_edit');
    $registry->add(preference => $self->double_click);
}

sub double_click {
    my $p = $self->new_preference('double_click_to_edit');
    $p->query('Kwiki Double Click To Edit?');
    $p->type('boolean');
    $p->default('1');
    return $p;
}

__DATA__

=head1 NAME 

Kwiki::DoubleClickToEdit - Double Click Starts Edit

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006. Ingy döt Net. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

__javascript/double_click_to_edit.js__
(
function() {
    var ol = window.onload;
    var doubleclick = function() {
        var links = document.getElementsByTagName('a');
        for (var i = 0; i < links.length; i++) {
            var link = links[i];
            var href = link.getAttribute('href');
            if (! href) continue;
            if (! href.match(/action=edit/)) continue;
            window.location = href;
            break;
        }
    };
    window.onload = function() {
        if (ol) ol();
        document.body.ondblclick = doubleclick;
    }
}
)();
