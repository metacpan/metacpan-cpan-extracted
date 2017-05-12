package Git::Status::Tackle;
# ABSTRACT: a pluggable "git status"-replacement toolbox
use strict;
use warnings;
use Module::Pluggable (
    sub_name    => '_installed_plugins',
    search_path => ['Git::Status::Tackle'],
    except      => 'Git::Status::Tackle::Plugin',
);

our $VERSION = '0.01';

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub all_plugins {
    my $self = shift;

    return sort $self->_installed_plugins;
}

sub plugins {
    my $self = shift;

    chomp(my $plugins = `git config status-tackle.plugins`);
    return split ' ', $plugins if $plugins;
    return $self->all_plugins;
}

sub _instantiate_plugin {
    my $self = shift;
    my $name = shift;

    (my $file = "$name.pm") =~ s{::}{/}g;
    require $file;

    return $name->new;
}

sub load_plugin {
    my $self = shift;
    my $plugin_class = shift;

    my $plugin = eval { $self->_instantiate_plugin($plugin_class) };
    return $plugin if $plugin;

    my $error = $@;

    $plugin ||= eval { $self->_instantiate_plugin("Git::Status::Tackle::$plugin_class") };
    return $plugin if $plugin;

    # errors more specific than 404 should dominate
    $error = $@ if $@ !~ /^Can't locate/;

    die "Unable to load plugin $plugin_class: $error";
}

sub status {
    my $self = shift;

    my @output;

    my $block = 0;

    for my $plugin_class ($self->plugins) {
        my $plugin = $self->load_plugin($plugin_class);

        my $results = eval { $plugin->list };

        if (my $e = $@) {
            warn $plugin->name . ': ' . $e;
            next;
        }

        next unless $results && @$results;

        push @output, "\n" if $block++ > 0;

        push @output, $plugin->header;
        push @output, @$results;
    }

    return @output;
}

1;

