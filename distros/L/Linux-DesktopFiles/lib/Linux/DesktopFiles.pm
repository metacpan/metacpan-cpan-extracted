package Linux::DesktopFiles;

# This module is designed to be pretty fast.
# The best uses of this module is to generate real
# time menus, based on the content of desktop files.

use 5.014;

#use strict;
#use warnings;

our $VERSION = '0.21';

our %TRUE_VALUES = (
                    'true' => 1,
                    'True' => 1,
                    '1'    => 1
                   );

sub new {
    my ($class, %opt) = @_;

    my %data = (
        keep_unknown_categories => 0,
        unknown_category_key    => 'other',

        case_insensitive_cats => 0,

        skip_filename_re => undef,
        skip_entry       => undef,
        substitutions    => undef,

        terminal => (defined($opt{terminal}) ? undef : $ENV{TERM}),

        terminalize            => 0,
        terminalization_format => q{%s -e '%s'},

        desktop_files_paths => [
            qw(
              /usr/local/share/applications
              /usr/share/applications
              )
        ],

        keys_to_keep => [qw(Exec Name Icon)],

        categories => [
            qw(
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
        ],

        %opt,
               );

    $data{_file_keys_re} = do {
        my %seen;
        my @keys = map { quotemeta($_) } grep { !$seen{$_}++ }
          (@{$data{keys_to_keep}}, qw(Hidden NoDisplay Categories), ($data{terminalize} ? qw(Terminal) : ()));

        local $" = q{|};
        qr/^(@keys)=(.*\S)/m;
    };

    if ($data{case_insensitive_cats}) {
        @{$data{_categories}}{map { (lc $_) =~ tr/_a-z0-9/_/cr } @{$data{categories}}} = ();
    }
    else {
        @{$data{_categories}}{@{$data{categories}}} = ();
    }

    bless \%data, $class;
}

sub get_desktop_files {
    my ($self) = @_;

    my %table;
    foreach my $dir (@{$self->{desktop_files_paths}}) {
        opendir(my $dir_h, $dir) or next;

#<<<
        my $is_local = (
               index($dir,  '/local/') != -1
            or index($dir, '/.local/') != -1
        );
#>>>

        foreach my $file (readdir $dir_h) {
            if (substr($file, -8) eq '.desktop') {
                if ($is_local or not exists($table{$file})) {
                    $table{$file} = "$dir/$file";
                }
            }
        }
    }

    wantarray ? values(%table) : [values(%table)];
}

sub parse {
    my ($self, $file_data, @desktop_files) = @_;

    foreach my $desktop_file (@desktop_files) {

        # Check the filename and skip it if it matches `skip_filename_re`
        if (defined $self->{skip_filename_re}) {
            substr($desktop_file, rindex($desktop_file, '/') + 1) =~ /$self->{skip_filename_re}/ && next;
        }

        # Open and read the desktop file
        sysopen my $desktop_fh, $desktop_file, 0 or next;
        sysread $desktop_fh, (my $file), -s $desktop_file;

        # Locate the "[Desktop Entry]" section
        if ((my $index = index($file, "]\n", index($file, "[Desktop Entry]") + 15)) != -1) {
            $file = substr($file, 0, $index);
        }

        # Parse the entry data
        my %info = $file =~ /$self->{_file_keys_re}/g;

        # Ignore the file when `NoDisplay` is true
        if (exists $info{NoDisplay}) {
            next if exists $TRUE_VALUES{$info{NoDisplay}};
        }

        # Ignore the file when `Hidden` is true
        if (exists $info{Hidden}) {
            next if exists $TRUE_VALUES{$info{Hidden}};
        }

        # If no 'Name' entry is defined, create one with the name of the file
        $info{Name} //= substr($desktop_file, rindex($desktop_file, '/') + 1, -8);

        # Handle `skip_entry`
        if (defined($self->{skip_entry}) and ref($self->{skip_entry}) eq 'ARRAY') {
            my $skip;
            foreach my $pair_ref (@{$self->{skip_entry}}) {
                if (exists($info{$pair_ref->{key}}) and $info{$pair_ref->{key}} =~ /$pair_ref->{re}/) {
                    $skip = 1;
                    last;
                }
            }
            $skip and next;
        }

        # Make user-defined substitutions
        if (defined($self->{substitutions}) and ref($self->{substitutions}) eq 'ARRAY') {
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

        # Parse categories
        (
         my @categories =
           grep { exists $self->{_categories}{$_} }
           $self->{case_insensitive_cats}
         ? (map { lc($_) =~ tr/_a-z0-9/_/cr } split(/;/, $info{Categories} // ''))
         : (split(/;/, $info{Categories} // ''))
        )
          || (!$self->{keep_unknown_categories} and next);

        # Remove `% ...` from the value of `Exec`
        index($info{Exec}, ' %') != -1 and $info{Exec} =~ s/ +%.*//s;

        # Terminalize
        if (    $self->{terminalize}
            and defined($info{Terminal})
            and exists($TRUE_VALUES{$info{Terminal}})) {
            $info{Exec} = sprintf($self->{terminalization_format}, $self->{terminal}, $info{Exec});
        }

        # Check and clean the icon name
        if (exists $info{Icon}) {
            my $icon = $info{Icon};

            my $abs;
            if (substr($icon, 0, 1) eq '/') {
                if (-f $icon) {    # icon is specified as an absolute path
                    $abs = 1;
                }
                else {             # ... otherwise, take its basename
                    $icon = substr($icon, 1 + rindex($icon, '/'));
                }
            }

            # Remove any icon extension
            if (!$abs) {
                $icon =~ s/\.(?:png|jpe?g|svg|xpm)\z//i;
            }

            # Store the icon back into `%info`
            $info{Icon} = $icon;
        }

        # Push the entry into its belonging categories
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

Linux::DesktopFiles - Fast parsing of the Linux desktop files.

=head1 SYNOPSIS

  use Linux::DesktopFiles;
  my $obj = Linux::DesktopFiles->new( terminalize => 1 );
  print join("\n", $obj->get_desktop_files);
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

    Linux::DesktopFiles->new();

is equivalent with:

    Linux::DesktopFiles->new(

        terminal               => $ENV{TERM},
        terminalize            => 0,
        terminalization_format => "%s -e '%s'",

        skip_entry       => [],
        skip_filename_re => [],
        substitutions    => [],

        desktop_files_paths => ['/usr/local/share/applications',
                                '/usr/share/applications'],

        keys_to_keep        => ["Name", "Exec", "Icon"],
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

        case_insensitive_cats   => 0,

        keep_unknown_categories => 0,
        unknown_category_key    => 'other',
      );

=back

=head2 Main options

=over 4

=item desktop_files_paths => ['dir1', 'dir2', ...]

Sets the directories where to find the desktop files.

=item keys_to_keep => [qw(Name Exec Icon Comment ...)]

Any valid keys from the desktop files. This keys will be stored in the returned
hash reference when calling C<$obj-E<gt>parse_desktop_files>.

=item categories => [qw(Graphics Network AudioVideo ...)]

Any valid categories from the desktop files. Any category not listed will be ignored
or stored in the B<unknown_category_key> when C<keep_unknown_categories> is set to a true value.

=back

=head2 Other options

=over 4

=item keep_unknown_categories => $bool

When an item is not part of any specified category, will be stored inside the
unknown category, specified by B<unknown_category_key>.

=item unknown_category_key => $name

Category name where to store the applications which do not belong to
any specified category.

=item case_insensitive_cats => $bool

This option makes the category names case insensitive, by lowercasing and replacing
any non-alpha numeric characters with an underscore. For example, "X-XFCE" becomes "x_xfce".

=item terminal => $command

This terminal command will be used when B<terminalize> is set to a true value.

=item terminalize => $bool

When the value of B<Terminal> is true, modify the B<Exec> value to something like:

    terminal -e 'command'

=item terminalization_format => q{%s -e '%s'}

Format used by C<sprintf()> to terminalize a command which requires to be executed
inside a terminal.

Used internally as:

    sprintf($self->{terminalization_format}, $self->{terminal}, $command);

=back

=head2 Regex options

=over 4

=item skip_filename_re => qr/regex/

Skip any desktop file if its file name matches the regex.
B<NOTE:> File names are from the last slash to the end.

=item skip_entry  => [{key => 'KeyName', re => qr/REGEX/i}, {...}]

Skip any desktop file if the value from a given key matches the specified regular expression.
The B<key> can be any valid key from the desktop files.

Example:

        skip_entry => [
            {key => 'Name', re => qr/(?:about|terminal)/i},
            {key => 'Exec', re => qr/xterm/},
        ],

=item substitutions => [{key => 'KeyName', re => qr/REGEX/i, value => 'Value'}, {...}]

Substitute, by using a regex, in the values of the desktop files.
The B<key> can be any valid key from the desktop files.
The B<re> can be any valid regular expression. Anything matched by the regex, will be
replaced the string stored in B<value>.
For global matching/substitution, you need to set the B<global> key to a true value.

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

=item $obj->parse(\%hash, @desktop_files)

Parse a list of desktop files into a HASH ref.

=item $obj->parse_desktop_files()

It returns a HASH reference which categories names as keys, and ARRAY references
as values which contains HASH references with the keys specified in the B<keys_to_keep>
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
