package Linux::DesktopFiles;

# This module is designed to be pretty fast.
# The best uses of this module is to generate real
# time menus, based on the content of desktop files.

use 5.014;

#use strict;
#use warnings;

our $VERSION = '0.13';

sub new {
    my ($class, %opts) = @_;

    my $self = bless {}, $class;

    my @default_arguments = qw(
      abs_icon_paths
      icon_db_filename
      keep_unknown_categories
      unknown_category_key
      case_insensitive_cats
      skip_filename_re
      skip_svg_icons
      icon_dirs_first
      icon_dirs_second
      icon_dirs_last
      strict_icon_dirs
      terminalize
      use_current_theme_icons
      terminal
      gtk_rc_filename
      home_dir
      terminalization_format
      skip_entry
      substitutions
      );

    @{$self}{@default_arguments} = delete @opts{@default_arguments};

    $self->{desktop_files_paths} =
      ref($opts{desktop_files_paths}) eq 'ARRAY'
      ? delete($opts{desktop_files_paths})
      : [qw(/usr/share/applications)];

    $self->{keys_to_keep} =
      ref($opts{keys_to_keep}) eq 'ARRAY'
      ? delete($opts{keys_to_keep})
      : [qw(Exec Name Icon)];

    $self->{file_keys_re} = do {
        my @keys = map quotemeta, do {
            my %seen;
            grep !$seen{$_}++, @{$self->{keys_to_keep}}, qw(Hidden NoDisplay Categories),
              $self->{terminalize} ? qw(Terminal) : ();
        };
        local $" = q{|};
        qr/^(@keys)=(.*\S)/m;
    };

    $self->{categories} = {
        map { ($self->{case_insensitive_cats} ? (lc $_) =~ tr/_a-z0-9/_/cr : $_) => undef }
          ref($opts{categories}) eq 'ARRAY'
        ? @{delete($opts{categories})}
        : qw(
          Utility
          Development
          Education
          Game
          Graphics
          AudioVideo
          Network
          Office
          Settings
          System
          )
    };

    $self->{true_values} =
      ref($opts{true_value}) eq 'ARRAY'
      ? {map { $_ => 1 } @{delete($opts{true_value})}}
      : {
         'true' => 1,
         'True' => 1,
         '1'    => 1
        };

    $self->{home_dir}               //= $ENV{HOME};
    $self->{gtk_rc_filename}        //= "$self->{home_dir}/.gtkrc-2.0";
    $self->{terminal}               //= $ENV{TERM};
    $self->{terminalization_format} //= q{%s -e '%s'};

    if (defined $self->{icon_db_filename} and $self->{abs_icon_paths}) {
        $self->_init_icon_database() || warn "Can't open/create database '$self->{icon_db_filename}': $!";
    }

    foreach my $key (keys %opts) {
        warn "Invalid option or value: $key";
    }

    $self;
}

sub _init_icon_database {
    my ($self) = @_;
    require GDBM_File;
    tie %{$self->{icons_db}}, 'GDBM_File', $self->{icon_db_filename}, &GDBM_File::GDBM_WRCREAT, 0640;
}

sub get_icon_theme_name {
    my ($self) = @_;

    if (-r $self->{gtk_rc_filename}) {
        if (sysopen my $fh, $self->{gtk_rc_filename}, 0) {
            sysread $fh, (my $content), -s _;
            $content =~ /^\s*gtk-icon-theme-name\s*=\s*["']?([^'"\r\n]+)/im
              && return $1;
        }
    }

    return;
}

sub get_icon_path {
    my ($self, $icon_name) = @_;

    if (defined($icon_name) and $icon_name ne q{}) {

        if (chr ord $icon_name eq '/') {
            return -f $icon_name ? $icon_name : q{};
        }

        $icon_name =~ s/\.\w{3}$//;
        $self->{abs_icon_paths} || return $icon_name;
    }
    else {
        return q{};
    }

    my $icon = $self->{icons_db}{$icon_name};

    if (not defined($icon) and not exists($self->{_stored_icons})) {

        $self->{_stored_icons} = 1;

        my $icon_theme =
          (!$self->{strict_icon_dirs} || $self->{use_current_theme_icons})
          ? $self->get_icon_theme_name()
          : undef;

        my @icon_dirs;
        if (defined $self->{icon_dirs_first}
            and ref $self->{icon_dirs_first} eq 'ARRAY') {
            push @icon_dirs, grep -d, @{$self->{icon_dirs_first}};
        }

        if (defined($icon_theme) and (!$self->{strict_icon_dirs} || $self->{use_current_theme_icons})) {
            my @icon_theme_dirs = (
                                   "/usr/share/icons/$icon_theme",
                                   "$self->{home_dir}/.icons/$icon_theme",
                                   "$self->{home_dir}/.local/share/icons/$icon_theme"
                                  );

            my %seen_dir;
            while (@icon_theme_dirs) {
                my $icon_dir = shift @icon_theme_dirs;

                if (-d $icon_dir) {
                    push @icon_dirs, $icon_dir;
                    if (-e (my $index_theme = "$icon_dir/index.theme")) {

                        sysopen my $fh, $index_theme, 0 or next;

                        while (defined(my $line = <$fh>)) {
                            if ($line =~ /^\[Icon Theme\]/) {

                                local $/ = "";
                                while (defined(my $para = <$fh>)) {
                                    if ($para =~ /^Inherits=(\S+)/m) {
                                        my $base = substr($icon_dir, 0, rindex($icon_dir, '/'));
                                        push @icon_theme_dirs, grep { !$seen_dir{$_}++ } map { "$base/$_" } split(/,/, $1);
                                        last;
                                    }
                                    last if $para =~ /^\[.*?\]/m;
                                }

                                last;
                            }
                        }

                        close $fh;
                    }
                }
            }
        }

        if (defined $self->{icon_dirs_second}
            and ref $self->{icon_dirs_second} eq 'ARRAY') {
            push @icon_dirs, grep -d, @{$self->{icon_dirs_second}};
        }

        if (not $self->{strict_icon_dirs}) {
            push @icon_dirs, grep -d,
              '/usr/share/pixmaps',                   '/usr/share/icons/hicolor',
              "$self->{home_dir}/.local/share/icons", "$self->{home_dir}/.icons";
        }

        if (defined $self->{icon_dirs_last}
            and ref $self->{icon_dirs_last} eq 'ARRAY') {
            push @icon_dirs, grep -d, @{$self->{icon_dirs_last}};
        }

        if (
            (
             my @uniq_dirs = (
                              do { my %seen; grep !$seen{$_}++ => @icon_dirs }
                             )
            )
          ) {
            require File::Find;
            File::Find::find(
                {
                 wanted => sub {
                     (substr($File::Find::name, -4, 1) ne q{.}) && return;
                     (substr($_, -4, 4, q{}) eq '.svg' and $self->{skip_svg_icons}) && return;
                     (exists $self->{icons_db}{$_}) && return;
                     $self->{icons_db}{$_} = $File::Find::name;
                 },
                } => @uniq_dirs
            );
        }

    }

    unless (defined $icon) {
        $icon = $self->{icons_db}{$icon_name};
        unless (defined $icon) {
            $self->{icons_db}{$icon_name} = '';
            $icon = '';
        }
    }

    $icon;    # return the icon
}

sub get_desktop_files {
    my ($self) = @_;

    my @desktop_files;
    foreach my $dir (@{$self->{desktop_files_paths}}) {
        opendir(my $dir_h, $dir) or next;
        foreach my $file (readdir $dir_h) {
            push(@desktop_files, "$dir/$file") if substr($file, -8) eq '.desktop';
        }
        closedir $dir_h;
    }
    wantarray ? @desktop_files : \@desktop_files;
}

sub parse {
    my ($self, $file_data, @desktop_files) = @_;

    foreach my $desktop_file (@desktop_files) {

        if (defined $self->{skip_filename_re}) {
            substr($desktop_file, rindex($desktop_file, '/') + 1) =~ /$self->{skip_filename_re}/ && next;
        }

        sysopen my $desktop_fh, $desktop_file, 0 or next;
        sysread $desktop_fh, (my $file), -s $desktop_file;

        if ((my $index = index($file, "]\n", index($file, "[Desktop Entry]") + 15)) != -1) {
            $file = substr($file, 0, $index);
        }

        my %info = $file =~ /$self->{file_keys_re}/g;

        if (exists $info{NoDisplay}) {
            next if exists $self->{true_values}{$info{NoDisplay}};
        }

        if (exists $info{Hidden}) {
            next if exists $self->{true_values}{$info{Hidden}};
        }

        # If no 'Name' enrty is defined, create one with the name of the file
        $info{Name} //= substr($desktop_file, rindex($desktop_file, '/') + 1, -8);

        (
         my @categories =
           grep { exists $self->{categories}{$_} }
           $self->{case_insensitive_cats}
         ? (map { lc($_) =~ tr/_a-z0-9/_/cr } split(/;/, $info{Categories} // ''))
         : (split(/;/, $info{Categories} // ''))
        )
          || (!$self->{keep_unknown_categories} && next);

        if (defined $self->{skip_entry} and ref $self->{skip_entry} eq 'ARRAY') {
            my $skip;

            foreach my $pair_ref (@{$self->{skip_entry}}) {
                if (exists $info{$pair_ref->{key}} and $info{$pair_ref->{key}} =~ /$pair_ref->{re}/) {
                    $skip = 1;
                    last;
                }
            }

            $skip && next;
        }

        if (defined $self->{substitutions} and ref $self->{substitutions} eq 'ARRAY') {

            foreach my $pair_ref (@{$self->{substitutions}}) {
                if (exists $info{$pair_ref->{key}}) {
                    if ($pair_ref->{global}) {
                        $info{$pair_ref->{key}} =~ s/$pair_ref->{re}/$pair_ref->{value}/g;
                    }
                    else {
                        $info{$pair_ref->{key}} =~ s/$pair_ref->{re}/$pair_ref->{value}/;
                    }
                }
            }

        }

        index($info{Exec}, ' %') != -1 && $info{Exec} =~ s/ +%.*//s;

        if (    $self->{terminalize}
            and defined $info{Terminal}
            and exists $self->{true_values}{$info{Terminal}}) {
            $info{Exec} = sprintf($self->{terminalization_format}, $self->{terminal}, $info{Exec});
        }

        if (exists $info{Icon}) {
            $info{Icon} = $self->get_icon_path($info{Icon});
        }

        if (scalar(@categories)) {
            foreach my $category (@categories) {
                push @{$file_data->{$category}}, {map { $_ => $info{$_} } @{$self->{keys_to_keep}}};
            }
        }
        elsif ($self->{keep_unknown_categories}) {
            push @{$file_data->{$self->{unknown_category_key}}}, {map { $_ => $info{$_} } @{$self->{keys_to_keep}}};
        }
    }
}

sub parse_desktop_file {
    my ($self, $file) = @_;
    my %file_data;
    $self->parse(\%file_data, $file);
    %file_data ? (values %file_data)[0][0] : ();
}

sub parse_desktop_files {
    my ($self) = @_;
    my %categories;
    $self->parse(\%categories, $self->get_desktop_files);
    \%categories;
}

1;

__END__

=encoding utf8

=head1 NAME

Linux::DesktopFiles - Get and parse the Linux desktop files.

=head1 SYNOPSIS

  use Linux::DesktopFiles;
  my $obj = Linux::DesktopFiles->new( terminalize => 1 );
  print join "\n", $obj->get_desktop_files;
  my $hash_ref = $obj->parse_desktop_files;

=head1 DESCRIPTION

The C<Linux::DesktopFiles>, a very fast and simple way to parse the Linux desktop files.

=head1 CONSTRUCTOR METHODS

The following constructor methods are available:

=over 4

=item $obj = Linux::DesktopFiles->new( %options )

This method constructs a new C<Linux::DesktopFiles> object and returns it.
Key/value pair arguments may be provided to set up the initial state.

By default,

    Linux::DesktopFiles->new()

is equivalent with:

    Linux::DesktopFiles->new(
        abs_icon_paths   => 0,
        skip_svg_icons   => 0,
        icon_db_filename => undef,

        icon_dirs_first  => [],
        icon_dirs_second => [],
        icon_dirs_last   => [],

        case_insensitive_cats   => 0,
        strict_icon_dirs        => 0,
        use_current_theme_icons => 0,

        terminal    => $ENV{TERM},
        terminalize => 0,

        home_dir        => $ENV{HOME},
        gtk_rc_filename => "$ENV{HOME}/.gtkrc-2.0",

        skip_entry       => [],
        skip_filename_re => [],
        substitutions    => [],

        desktop_files_paths => ['/usr/share/applications'],
        keys_to_keep        => ["Name", "Exec", "Icon"],
        true_values         => ['true', 'True', '1'],
        categories          => [
                                qw( Utility
                                  Development
                                  Education
                                  Game
                                  Graphics
                                  AudioVideo
                                  Network
                                  Office
                                  Settings
                                  System )
                               ],
      );

=back

=head2 Main options

=over 4

=item desktop_files_paths => ['dir1', 'dir2', ...]

Set directories where to find the desktop files (default: /usr/share/applications)

=item keys_to_keep => [qw(Name Exec Icon Comment ...)]

Any of the valid keys from desktop files. This keys will be stored in the returned
hash reference when calling C<$obj-E<gt>parse_desktop_files>.

=item categories => [qw(Graphics Network AudioVideo ...)]

Any of the valid categories from the desktop files. Any category not listed
will be ignored.

=back

=head2 Other options

=over 4

=item keep_unknown_categories => 1

When an item is not part of any specified category, put it into an
unknown category, specified by I<unknown_category_key>.

=item unknown_category_key => 'key_name'

Category name where to store the applications which doesn't belong to
any specified category.

=item case_insensitive_cats => 1

This option makes the categories case insensitive, by lowercasing and replacing
any non-alpha numeric characters with an underscore. For example, "X-XFCE" will
be equivalent with "x_xfce".

=item terminalize => 1

When B<Terminal> is true, modify the B<Exec> value to something like:
I<terminal -e 'command'>

=item terminal => "xterm"

This terminal will be used when I<terminalize> is set to a true value.

=item terminalization_format => q{%s -e '%s'}

Format used by C<sprintf> to terminalize a command which requires to run
in a new terminal.

=item home_dir => "/home/dir"

Set the home directory. This value is used to locate icons in the ~/.local/share/icons.

=item gtk_rc_filename => "/path/to/.gtkrc-x.x"

This file is used to get the icon theme name from it. (default: ~/.gtkrc-2.0)
I<NOTE:> It works with Gtk3 as well.

=item true_values => [qw(1 true True)]

This values are used to test for truthiness some values from the desktop files.

=back

=head2 Icon options

=over 4

=item abs_icon_paths => 1

Resolve the absolute file paths for B<Icon> values.

=item icon_db_filename => "filename.db"

A database file which will be used to store icon names as keys and icon paths as
values for a faster lookup (used with GDBM_File).
I<NOTE:> Works in combination with B<abs_icon_paths>.

=item skip_svg_icons => 1

Ignore SVG icons when looking for absolute icon paths.

=item icon_dirs_first => [dir1, dir2, ...]

When looking for absolute icon paths, look in this directories first,
before looking in the directories of the current icon theme.

=item icon_dirs_second => [dir1, dir2, ...]

When looking for full icon paths, look in this directories as a second
icon theme. (Before I</usr/share/pixmaps>)

=item icon_dirs_last => [dir1, dir2, ...]

Look in this directories at the very last, after looked in I</usr/share/pixmaps>,
I</usr/share/icons/hicolor> and some other directories.

=item strict_icon_dirs => 1

Be very strict and use only the directories specified in either
one of I<icon_dirs_first>, I<icon_dirs_second> and/or I<icon_dirs_last>.

=item use_current_theme_icons => 1

Use the current icon theme (from ~/.gtkrc-2.0) even when I<strict_icon_dirs>
is set to a true value. This option is useful when you want to get only the icons
from the current theme. It is usually used in combination with I<strict_icon_dirs>.
When I<strict_icon_dirs> is set a false value, this option is true by default.
When I<strict_icon_dirs> is set a true value, this option is false by default.

=back

=head2 Regex options

=over 4

=item skip_filename_re => qr/regex/

Skip any desktop file if its file name matches the regex.
I<NOTE:> File names are from the last slash to the end.

=item skip_entry  => [{key => 'KeyName', re => qr/REGEX/i}, {...}]

Skip any desktop file if the value from a given key matches the specified regular expression.
The I<key> can be any valid key from the desktop files.

Example:

        skip_entry => [
            {key => 'Name', re => qr/(?:about|terminal)/i},
            {key => 'Exec', re => qr/xterm/},
        ],

=item substitutions => [{key => 'KeyName', re => qr/REGEX/i, value => 'Value'}, {...}]

Substitute, by using a regex, in the values of the desktop files.
The I<key> can be any valid key from the desktop files.
The I<re> can be any valid regular expression. Anything matched by the regex, will be
replaced the string stored in I<value>.
For global matching/substitution, you need to set the I<global> key to a true value.

Example:

        substitutions => [
            {key => 'Exec', re => qr/xterm/,    value => 'sakura'},
            {key => 'Exec', re => qr/\$HOME\b/, value => '/my/home', global => 1},
        ],

=back

=head1 SUBROUTINES/METHODS

=over 4

=item $obj->get_desktop_files()

Get all desktop files. In list context returns a list, but in scalar context,
it returns an array reference containing the full names of the desktop files.

=item $obj->get_icon_theme_name()

Returns the name of the current icon theme, if any, otherwise returns undef;

=item $obj->get_icon_path("icon_name")

If I<abs_icon_paths> is set to a true value, returns the absolute path of an
icon name located in the system. If it can't find the icon name, it returns
an empty string.
If I<abs_icon_paths> is set to a false value, it strips the extension name of
the icon (if any), and returns the icon name. If the icon name is undefined, it
returns an empty string.

=item $obj->parse(\%hash, @desktop_files)

Parse a list of desktop files into a HASH ref.

=item $obj->parse_desktop_file("filename")

It returns a HASH reference which contains the I<keys_to_keep> and the corresponding
values from the given file.

=item $obj->parse_desktop_files()

It returns a HASH reference which categories names as keys, and ARRAY references
as values which contains HASH references with the keys specified in the I<keys_to_keep>
option, and values from the desktop files.

The returned HASH reference might look something like this:

        {
          utility => [ {Exec => "...", Name => "..."}, {Exec => "...", Name => "..."} ],
          network => [ {Exec => "...", Name => "..."}, {Exec => "...", Name => "..."} ],
        }

This function is equivalent with:

    $obj->parse(\%hash, $obj->get_desktop_files);

=back

=head1 REPOSITORY

L<https://github.com/trizen/Linux-DesktopFiles>

=head1 AUTHOR

Daniel "Trizen" Șuteu, E<lt>trizenx@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2017

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<File::DesktopEntry> and L<X11::FreeDesktop::DesktopEntry>

=cut
