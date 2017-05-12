package Kwiki::Test;
use Spiffy -Base;
use Kwiki;
use IO::All;
use Cwd;

const 'base_dir' => Cwd::abs_path(".") . "/kwiki";

our $VERSION = '0.03';

sub init {
    my $plugins = shift;
    $self->make_directory;
    $self->install_new_kwiki;
    if ($plugins) {
        $self->add_plugins($plugins);
    }
    return $self;
}

sub initialize_plugins {
    my @plugins = @{$self->hub->registry->lookup->{plugins}};
    foreach my $plugin (@plugins) {
        my $class = $plugin->{id};
        $self->hub->$class->init;
    }
}

sub reset_hub {
    undef($self->{hub});
    $self->hub;
}

sub hub {
    return $self->{hub} if $self->{hub};
    chdir($self->base_dir) || die "unable to chdir to ", $self->base_dir,
        "$!\n";;
    my @configs = qw(config.yaml -plugins plugins);
    my $hub = Kwiki->new->load_hub(@configs);
    $self->{hub} = $hub;
}

sub make_directory {
    mkdir($self->base_dir) || warn "unable to mkdir ", $self->base_dir, "\n";
}

sub install_new_kwiki {
    # we've already chdir'd
    $self->hub->command->process(qw(-quiet -new .));
    # reset the hub
    undef($self->{hub});
}

sub add_plugins {
    my $plugins = shift;
    $self->hub->command->quiet(1);
    $self->hub->command->handle_add(@$plugins);
    $self->initialize_plugins;
}

sub cleanup {
    io($self->base_dir)->rmtree unless $ENV{KWIKI_TEST_DIRTY};
}

# Utlity stuff
# some of this is obvious, but doing it in here in case
# there are change dirs and the like that we'd like to do

sub exists_as_file {
    -f shift;
}

sub exists_as_dir {
    -d shift;
}

__DATA__

=head1 NAME

Kwiki::Test - A helper module for testing Kwiki Plugins

=head1 SYNOPSIS

    use strict;
    use warnings;

    use IO::All;
    use Kwiki::Test;
    use Test::More tests => 6;

    my $REGISTRY_FILE = 'registry.dd';
    my $CONFIG_FILE = 'config.yaml';
    my $CONFIG_DIR = 'config';
    my $TEMPLATE_DIR = 'template';
    my $CSS_DIR = 'css';
    my $HOME_PAGE = 'database/HomePage';

    my $kwiki = Kwiki::Test->new->init;

    ok($kwiki->exists_as_file($REGISTRY_FILE), "$REGISTRY_FILE exists");
    ok($kwiki->exists_as_file($CONFIG_FILE), "$CONFIG_FILE exists");
    ok($kwiki->exists_as_dir($TEMPLATE_DIR), "$TEMPLATE_DIR exists");
    ok($kwiki->exists_as_dir($CONFIG_DIR), "$CONFIG_DIR exists");
    ok($kwiki->exists_as_dir($CSS_DIR), "$CSS_DIR exists");
    ok($kwiki->exists_as_file($HOME_PAGE), "$HOME_PAGE exists");

    $kwiki->cleanup;

=head1 DESCRIPTION

Because of the way templates and other files are handled in kwiki
it can often be a bit painful to write useful tests for Kwiki plugins.
Kwiki::Test creates a kwiki installation in your modules build directory
against which tests can be run.

The tests included in the distribution are the best examples of how to
use the system.

Of special note: if you pass a reference to a list containing plugin
modules to init() those modules will be added to the kwiki test
configuration.

cleanup() removes the mess you've made. This may be moved into DESTROY
in the future.

=head1 CREDITS

Kwiki::Test is based on some ideas from Dave Rolsky (co-worker at
Socialtext). Thanks, Dave, for being an uptight bastard. And thanks
to Brian for giving something worth being uptight about.

=head1 SEE ALSO

L<Kwiki>

=head1 AUTHOR

Chris Dent <cdent@burningchrome.com>

=head1 COPYRIGHT

Copyright (c) 2005. Chris Dent. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
