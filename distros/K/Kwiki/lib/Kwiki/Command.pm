package Kwiki::Command;
use Spoon::Command -Base;

sub handle_new {
    $self->assert_directory(shift, 'Kwiki');
    $self->add_new_default_config;
    $self->install('files');
    $self->install('config');
    $self->create_registry;
    # XXX a method should return this list of plugin class_ids
    $self->install('display');
    $self->install('edit');
    $self->install('formatter');
    $self->install('users');
    $self->install('pages');
    $self->install('theme');
    $self->install('toolbar');
    $self->install('status');
    $self->install('widgets');
    io('plugin')->mkdir;
    $self->set_permissions;
    warn "\nKwiki software installed! Point your browser at this location.\n\n";
}

sub handle_new_view {
    $self->assert_directory(shift, 'kwiki view');
    die "Parent directory does not look like a Kwiki installation"
      unless -e '../plugins';
    require Cwd;
    my $home = Cwd::cwd();
    $home =~ s/.*\///;
    for my $file (io->updir->all) {
        my $name = $file->filename;
        next if $name eq '.htaccess';
        next if $name eq 'plugins';
        next if $name eq 'registry.dd';
        next if $name eq $home;
        io->link($name)->symlink($file->name);
    }
    $self->create_new_view_plugins;
    $self->handle_update;
    print <<END;

New view created. Now edit the $home/plugins file and run 
'kwiki -update' in the '$home' subdirectory.
END
}

sub create_new_view_plugins {
    io('plugins')->print(<<END);
# You can either list all the plugins you want manually, or put '+' and '-' in
# front of the plugins you want to add/remove from ../plugins respectively.
#
# Example:
#
# -Kwiki::Edit
# +Kwiki::Favorites
# +Kwiki::Weather
END
}

sub assert_directory {
    chdir io->dir(shift || '.')->assert->open->name;
    my $noun = shift;
    die "Can't make new $noun in a non-empty directory\n"
      unless io('.')->empty;
}

sub add_new_default_config {
    $self->hub->config->add_config(
        {
            display_class => 'Kwiki::Display',
            edit_class => 'Kwiki::Edit',
            files_class => 'Kwiki::Files',
            theme_class => 'Kwiki::Theme::Basic',
            toolbar_class => 'Kwiki::Toolbar',
            status_class => 'Kwiki::Status',
            widgets_class => 'Kwiki::Widgets',
        }
    );
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

sub is_kwiki_dir {
    my $dir = shift || '.';
    -d "$dir/plugin" and -f "$dir/registry.dd";
}

sub handle_update {
    chdir io->dir(shift || '.')->assert->open . '';
    die "Can't update non Kwiki directory!\n"
      unless -d 'plugin';
    $self->create_registry;
    $self->install($_) for $self->all_class_ids;
    $self->set_permissions;
}

sub handle_update_all {
    my @dirs = (io->curdir, io->curdir->All_Dirs);
    while (my $dir = shift @dirs) {
        next unless $self->is_kwiki_dir($dir);
        $self->msg('Updating ', $dir->absolute->pathname, "\n");
        $dir->chdir;
        system("kwiki -quiet -update");
    }
}

sub all_class_ids {
    my @all_modules;
    for my $key (keys %{$self->hub->config}) {
        push @all_modules, $self->hub->config->{$key}
          if $key =~ /_class/;
    }
    push @all_modules, @{$self->hub->config->{plugin_classes} || []};
    map {
        eval "require $_; 1"
        ? $_->can('extract_files')
          ? do {
              my $class_id = $_->class_id;
              $self->hub->config->add_config({"${class_id}_class" => $_});
              ($_->class_id)
          }
          : ()
        : ();
    } @all_modules;
}

sub handle_add {
    $self->update_plugins('+', @_);
}

sub handle_remove {
    $self->update_plugins('-', @_);
}

sub update_plugins {
    die "This operation must be performed inside a Kwiki installation directory"
      unless -f $self->hub->config->plugins_file;
    my $mode = shift;
    return $self->usage unless @_;
    my $plugins_file = $self->hub->config->plugins_file;
    my $plugins = io($plugins_file);
    my @lines = $plugins->chomp->slurp;
    for my $module (@_) {
        eval "require $module;1" or die $@ or
          ($module = "Kwiki::$module" and eval "require $module;1") or
            die "Invalid module '$module'";
        if ($mode eq '+') {
            next if grep /^$module$/, @lines;
            push @lines, $module;
            next;
        }
        @lines = grep {$_ ne $module} @lines;
    }
    $plugins->println($_) for @lines;
    $plugins->close;
    $self->hub->config->add_plugins_file($plugins_file);
    $self->handle_update;
}

sub handle_install {
    die "This operation must be performed inside a Kwiki installation directory"
      unless -f $self->hub->config->plugins_file;
    return $self->usage unless @_;
    require Cwd;
    $self->cpan_setup;
    my @modules = @_;
    for my $module (@_) {
        $self->fake_install($module);
        my $home = Cwd::cwd();
        my $rc = CPAN::Shell->expand('Module', $module);
        if (not defined $rc) {
            die "WARNING - Can't install $module\nStopping...\n";
        }
        $rc->install;
        chdir $home;
    }
    $self->update_plugins('+', @modules);
}

sub cpan_setup {
    no warnings;
    require CPAN;
#     require CPAN::Config;
    my $lib = io->dir('lib')->absolute;
    $ENV{PERL_MM_OPT} = "INSTALLSITELIB=$lib PREFIX=$lib"
      if $lib->exists;
    CPAN::Config->load;
    $CPAN::Config_loaded = 1;
    my $cpan_dir = io->dir('.cpan')->rel2abs;
    $CPAN::Config->{cpan_home} =
    $CPAN::Config->{build_dir} = $cpan_dir;
    $CPAN::Config->{keep_source_where} = 
      io->catdir($cpan_dir, 'sources')->name;
}

sub fake_install {
    return unless -d 'lib';
    my $module = shift;
    $module =~ s/::/\//g;
    $module .= '.pm';
    my $file = io->catfile('lib', $module);
    $file->assert->touch
      unless -f $file->name;
}

sub handle_compress {
    require Spoon::Installer;
    Spoon::Installer->new->compress_lib(@_);
}

sub set_permissions {
    my $umask = umask 0000;
    chmod 0777, qw(database plugin);
    chmod 0666, qw(database/HomePage);
    chmod 0755, qw(index.cgi);
    umask $umask;
}

sub create_registry {
    my $registry = $self->hub->registry;
    my $registry_path = $registry->registry_path;
    $self->msg("Generating Kwiki Registry '$registry_path'\n");
    $registry->update;
    if ($registry->validate) {
        $registry->write;
    }
    $self->hub();
    
    $self->hub->registry->load;
}

sub usage {
    warn <<END . $self->command_usage("  kwiki -%-20s # %s\n");
usage:
  kwiki -new [path]           # Generate a new Kwiki
  kwiki -update [path]        # Update an existing Kwiki
  kwiki -add Kwiki::Foo       # Add a plugin
  kwiki -remove Kwiki::Foo    # Remove a plugin
  kwiki -install Kwiki::Foo   # Download and install a plugin
  kwiki -new_view [subdir]    # Create a new view under an existing Kwiki
  kwiki -update_all           # Update all Kwiki dirs under current dir
END
}

__DATA__

=head1 NAME 

Kwiki::Command - Kwiki Command Line Tool Module

=head1 SYNOPSIS

    > kwiki -new mykwiki
    > cd mykwiki
    > kwiki -install Kwiki::RecentChanges Kwiki::Archive::Rcs Kwiki::Revisions
    > vim config.yaml
    > kwiki -update
    > kwiki -remove RecentChanges
    > kwiki -new_view admin

=head1 DESCRIPTION

Kwiki::Command is the module that does all the work of the C<kwiki>
command line tool. You can use C<kwiki> to install a new Kwiki, to
update a Kwiki configuration, to add and remove Kwiki plugins and to
download Kwiki plugins from CPAN. When you download the CPAN modules
they can either be installed in the system Perl libraries or locally
right in your kwiki dist. This is useful if you don't have root
permissions for your installation.

=head1 USAGES

There are many different commands you can do with the C<kwiki> command line
tool.

=over 4

=item * -new

Create a new kwiki with the command:

    kwiki -new

You must be inside an empty directory. Alternatively you can say:

    kwiki -new path/to/kwiki

The target directory must be empty or must not exist yet.

=back

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
