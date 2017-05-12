package Kwiki::Icons;
use Kwiki::Plugin -Base;
use mixin 'Kwiki::Installer';

const class_id => 'icons';
const css_file => 'icons.css';
const config_file => 'icons.yaml';

sub class_title {
    $self->usage;
}

sub register {
    my $registry = shift;
    $registry->add(preload => 'icons');
    $registry->add(preference => $self->use_icons);
}

sub init {
    super;
    if ($self->preferences->can('use_icons') and
        $self->preferences->use_icons->value) {
        $self->template->add_path($self->icons_path);
    }
}

sub use_icons {
    my $p = $self->new_preference('use_icons');
    $p->query('Use icons in toolbar?');
    $p->type('boolean');
    $p->edit('correct_template_path');
    $p->default(1);
    return $p;
}

sub correct_template_path {
    my $pref = shift;
    if ($pref->new_value) {
        $self->template->add_path($self->icons_path);
    }
    else {
        $self->template->remove_path($self->icons_path);
    }
}

sub icons_path {
    $self->usage;
}

sub usage {
    die "Don't use Kwiki::Icons directly. Use a subclass of it.";
}

__DATA__

=head1 NAME 

Kwiki::Icons - Kwiki Icons Plugin Base Class

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

__config/icons.yaml__
icons_on_by_default: 1
