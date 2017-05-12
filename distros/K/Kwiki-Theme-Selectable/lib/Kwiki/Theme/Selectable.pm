package Kwiki::Theme::Selectable;
use Kwiki::Theme -Base;
our $VERSION = '0.10';

# XXX:
# - Install all themes on -update
# - default to basic if theme not available
const theme_id => 'selectable';
const class_title => 'Selectable Theme';
const config_file => 'theme_selectable.yaml';
const default_selection => 'Kwiki::Theme::Basic';

sub register {
    super;
    my $registry = shift;
    $registry->add(preference => $self->theme_selection);
    $self->hook_install;
}

sub init {
    super;
    $self->reset_theme_class($self->selected_class);
}

sub selected_class {
    my @all_themes = $self->all_themes;
    my %classes = map {($_, $_)} @all_themes;
    my $class = $self->preferences->theme_selection->value;
    return $classes{$class} || $all_themes[0] || die;
}

sub reset_theme_class {
    my $class = shift;
    field theme_class => 
          -package => ref($self->config);
    $self->hub->config->theme_class($class);
    $self->hub->theme(undef);
    $self->hub->theme;
}

sub theme_selection {
    my $p = $self->new_preference('theme_selection');
    $p->query('Select A Theme.');
    $p->type('pulldown');
    my $choices = [
        map {($_, $_)} $self->all_themes
    ];
    $p->default($choices->[0]);
    $p->choices($choices);
    $p->edit('set_new_theme');
    return $p;
}

sub Kwiki::Theme::set_new_theme {
    my $self = shift;
    $self = __PACKAGE__->new;
    my $preference = shift;
    $self->reset_theme_class($preference->new_value);
}

sub all_themes {
    $self->hub->config->can('theme_list')
    ? @{$self->hub->config->theme_list}
    : $self->default_selection;
}

sub hook_install {
    no strict 'refs';
    no warnings;
    my $command_class = ref($self->hub->command);
    my $command_install = \ &{$command_class . "::install"};
    *{$command_class . "::install"} = sub {
        my $self = shift;
        $self->$command_install(@_);
        my $class_id = shift;
        return unless $class_id eq 'theme';
        my $theme = $self->hub->theme;
        return unless $theme->isa(__PACKAGE__);
        for my $class ($theme->all_themes) {
            $theme->reset_theme_class($class);
            $self->install('theme');
        }
    }
}

__DATA__

=head1 NAME

Kwiki::Theme::Selectable - Kwiki Preference to Select a Theme

=head1 SYNOPSIS

=head1 DESCRIPTION

This theme is really a proxy for other theme plugins. It exposes a user
preference, that lets a user choose from a list of themes. The list
should be specified by the Kwiki administrator in the config.yaml file.

=head1 AUTHOR

Brian Ingerson <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
__config/theme_selectable.yaml__
theme_list:
- Kwiki::Theme::Basic
