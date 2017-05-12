package File::TypeCategories;

# Created on: 2014-11-07 16:39:51
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use strict;
use warnings;
use autodie;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use Type::Tiny;
use Types::Standard -types;
use File::ShareDir qw/dist_dir/;
use YAML qw/LoadFile/;

our $VERSION = 0.06;
our %warned_once;

has ignore => (
    is      => 'rw',
    isa     => ArrayRef[Str],
    default => sub{[qw{ ignore }]},
);
has include => (
    is  => 'rw',
    isa => ArrayRef[Str],
);
has exclude => (
    is  => 'rw',
    isa => ArrayRef[Str],
);
has include_type => (
    is      => 'rw',
    isa     => ArrayRef[Str],
    default => sub{[]},
);
has exclude_type => (
    is      => 'rw',
    isa     => ArrayRef[Str],
    default => sub{[]},
);
has symlinks => (
    is  => 'rw',
    isa => Bool,
);
has type_suffixes => (
    is      => 'rw',
    isa     => HashRef,
    default => sub {{}},
);

sub BUILD {
    my ($self) = @_;

    if (!$ENV{HOME}) {
        $ENV{HOME} = $ENV{USERPROFILE};
    }
    my $dir = eval { dist_dir('File-TypeCategories'); };
    my $config_name = '.type_categories.yml';

    # import each config file the each subsiquent config overwrites the
    # previous more general config.
    for my $config_dir ($dir, $ENV{HOME}, '.') {
        next if ! $config_dir || !-d $config_dir;
        my $config_file = "$config_dir/$config_name";
        next if !-f $config_file;

        my ($conf) = LoadFile($config_file);

        # import each type
        for my $file_type ( keys %{ $conf } ) {
            $self->type_suffixes->{$file_type} ||= {
                definite    => [],
                possible    => [],
                other_types => [],
                none        => 0,
                bang        => '',
            };

            # add each of the settings found
            for my $setting ( keys %{ $conf->{$file_type} } ) {

                # if a plus (+) is prepended to possible, definite or other_types
                # we add it here other wise it's replaced
                if ( $setting =~ s/^[+]//xms ) {
                    push @{ $self->type_suffixes->{$file_type}{$setting} }
                         , ref $conf->{$file_type}{"+$setting"} eq 'ARRAY'
                         ? @{ $conf->{$file_type}{"+$setting"} }
                         : $conf->{$file_type}{"+$setting"};
                }
                else {
                    $self->type_suffixes->{$file_type}{$setting}
                         = ref $conf->{$file_type}{$setting} eq 'ARRAY'
                         ? $conf->{$file_type}{$setting}
                         : [ $conf->{$file_type}{$setting} ];
                }
            }
        }
    }

    return;
}

sub file_ok {
    my ($self, $file) = @_;

    for my $ignore (@{ $self->ignore }) {
        return 0 if $self->types_match($file, $ignore);
    }

    return 1 if -d $file;

    my $possible = 0;
    my $matched  = 0;
    my $includes = 0;

    if ( @{ $self->include_type }) {
        for my $type (@{ $self->include_type }) {
            my $match = $self->types_match($file, $type);
            $possible-- if $match == 2;
            $matched += $match;
        }
        $includes++;
    }

    if (!$matched) {
        for my $type (@{ $self->exclude_type }) {
            my $match = $self->types_match($file, $type);
            return 0 if $match && $match != 2;
            $possible++ if $match == 2;
        }
        return 0 if $possible > 0;
    }

    if ($self->include) {
        my $matches = 0;
        for my $include (@{ $self->include }) {
            $matches = $file =~ /$include/;
            last if $matches;
        }
        return 0 if !$matches;
        $includes++;
    }

    if ($self->exclude) {
        for my $exclude (@{ $self->exclude }) {
            return 0 if $file =~ /$exclude/;
        }
    }

    return !$includes || $matched || $possible;
}

sub types_match {
    my ($self, $file, $type) = @_;

    my $types = $self->type_suffixes;

    if ( !exists $types->{$type} ) {
        warn "No type '$type'\n" if !$warned_once{$type}++;
        return 0;
    }

    for my $suffix ( @{ $types->{$type}{definite} } ) {
        return 3 if $file =~ /$suffix/;
    }

    for my $suffix ( @{ $types->{$type}{possible} } ) {
        return 2 if $file =~ /$suffix/;
    }

    if ( $types->{$type}{bang} && -r $file && -f $file && -s $file ) {
        open my $fh, '<', $file;
        my $line = <$fh>;
        close $fh;
        for my $bang ( @{ $types->{$type}{bang} } ) {
            return 3 if $line =~ /$bang/;
        }
    }

    return 1 if $types->{$type}{none} && $file !~ m{ [^/] [.] [^/]+ $}xms;

    for my $other ( @{ $types->{$type}{other_types} } ) {
        my $match = $self->types_match($file, $other);
        return $match if $match;
    }

    return 0;
}

1;

__END__

=head1 NAME

File::TypeCategories - Determine if files match a specific type

=head1 VERSION

This documentation refers to File::TypeCategories version 0.06

=head1 SYNOPSIS

   use File::TypeCategories;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

A C<File::TypeCategories> object can be used to test if files match the defined
categories.

=head1 SUBROUTINES/METHODS

=over 4

=item C<new (%hash)>

=over 4

=item ignore ArrayRef[Str] [ignore]

The types to ignore the default C<ignore> includes:

=over 4

=item *

build

=item *

backups

=item *

vcs

=item *

images

=item *

logs

=item *

editors

=item *

min

=back

=item include ArrayRef[Str]

Match only files that match regexes in C<include>

=item exclude ArrayRef[Str],

Don't match any files that match regexes in C<exclude>

=item include_type ArrayRef[Str]

Match only files of types specified in C<include_type>

=item exclude_type ArrayRef[Str]

Don't match files of types specified in C<exclude_type>

=item symlinks Bool

Allow symlinks to match

=item type_suffixes HASH

The configuration of types. This defaulted from the dist share dir,
C<~/.type_categories.yml> and C<./.type_categories.yml>

=back

=item C<BUILD ()>

Loads the config file when new is called

=item C<file_ok ($file)>

Determines if a file matches the current config

=item C<types_match ($file, $type)>

Checks if a file matches C<$type>

=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
