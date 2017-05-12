package FreePAN::Command;
use Spoon::Command -Base;
use FreePAN;

field 'dist';
field author_name => 'Johnny XXX';
field author_email => '';

sub all {
    map { ($_, $self->$_) } qw(
        author_name
        author_email
    );
}

sub process {
    return $self->first_time unless -d $self->hub->config->base;
    $self->setup;
    super;
}

sub handle_reconfigure {
    my $base = io->dir($self->hub->config->base);
    if ($base->exists) {
        unless (io->prompt('Do you really want to purge the existing configuration? ') =~ /^Y(ES)?$/) {
            warn "Aborting reconfigure.\n";
            return;
        }
        io->dir($self->hub->config->base)->rmtree;
    }
    $self->first_time;
}

sub first_time {
    $self->msg("\nFreePAN First Time User Setup:\n\n");
    mkdir $self->hub->config->base or die "Can't create '$self->hub->config->base':\n $!";
    my $base = io($self->hub->config->base)->chdir;
    $self->install('config');
    io('plugin')->mkdir;
    my $config = $self->hub->config->config_class->new(
        'config.yaml', -plugins => 'plugins',
    );
    $self->hub->config($config);
    $self->create_registry;
    $self->install_plugins;
    $self->prompt_info;
    $self->hub->template->path($self->hub->config->base);
    $self->create_file('config.yaml');
    $self->msg("\nFreePAN First Time User Setup is Complete.\n\n");
}

sub prompt_info {
    my $author_name = io->prompt('Enter your full name: ');
    $self->author_name($author_name) if $author_name;
    my $author_email = io->prompt('Enter your email address: ');
    $self->author_email($author_email) if $author_email;
}

sub create_file {
    my $path = shift;
    my $template_name = shift || io->file($path)->filename;
    my $content = $self->hub->template->process($template_name,
        $self->all,
    );
    my $output = io($path);
    # XXX assert is broken without a directory path.
    $output->assert if $path =~ /\//;
    $output->print($content);
}

sub setup {
    $self->update_registry
      if $self->registry_outdated;
    $self->hub->registry->load;
}

sub install {
    my $class_id = shift;
    my $object = $self->hub->$class_id
      or return;
    return unless $object->can('extract_files');
    my $class_title = $self->hub->$class_id->class_title;
    $self->msg("Extracting files for $class_title:\n");
    $self->hub->$class_id->quiet($self->quiet);
    $self->hub->$class_id->extract_files;
    $self->msg("\n");
}

sub install_plugins {
    map {
        $self->install($_->{id});
    } @{$self->hub->registry->lookup->{plugins}};
}

sub create_registry {
    my $registry = $self->hub->registry;
    my $registry_path = $registry->registry_path;
    $self->msg("Generating FreePAN Registry '$registry_path'\n");
    $registry->update;
    if ($registry->validate) {
        $registry->write;
    }
    $registry->load;
}

sub registry_outdated {
    my $base = io($self->hub->config->base)->chdir;
    -M 'plugins' < -M 'registry.dd';
}

sub update_registry {
    $self->create_registry(@_);
}

sub handle_all {
    warn "-all not yet implemented\n";
}

sub handle_update {
    my $base = io($self->hub->config->base)->chdir;
    $self->create_registry;
    $self->install_plugins;
}

sub usage {
    warn <<END . $self->command_usage("  freepan -%-14s# %s\n");
usage:
  freepan -update        # Upate FreePAN configuration
END
}

__DATA__

=head1 NAME 

FreePAN::Command - FreePAN Command Line Tool Module

=head1 SYNOPSIS

    > cd ~/src/cpan/My-Module
    > module -release

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
