package Games::Simutrans::Pakset;

use v5.32;

our $VERSION = '0.02';

use Mojo::Base -base, -signatures;
use Mojo::Path;
use Mojo::File;
use List::Util;
use Path::ExpandTilde;

has 'name';           # An identifying name for the pak

has 'path';          # This must be a path to a pakset's root.

sub valid ($self) {
    # Basic check as to whether a valid Pakset exists at the given path
    return undef unless defined $self->path;
    return 0 unless -e $self->path;
    
    return 1;
}

################
# LANGUAGE SUPPORT
################

has '_xlat_root';

sub xlat_root ($self, $new_root = undef) {
    # Location of the translation text files.  Lazy assignment in case
    # we access before the path has been set.
    my $xlat;
    if (defined $new_root) {
        $xlat = ref $new_root ? $new_root : Mojo::Path->new($new_root);
    } else {
        if (!defined $self->_xlat_root) {
            return undef unless defined $self->path;
            $xlat = Mojo::Path->new($self->path->to_string);
            push @$xlat, 'text';
            $self->_xlat_root($xlat);
        }
    }
    return $self->_xlat_root->to_string;
};

# Find a list of all the language (translation) files for the pak

has 'languages' => sub ($self) {
    # Return a list of available languages

    my $files_collection = Mojo::File->new($self->xlat_root)->list_tree->grep(sub{$_ =~ /\.tab\z/});
    return $files_collection->map(sub { $_->basename('.tab') } );
};

has 'language' => sub ($self, $lang = undef) {
    # the default language
    
    my $l = $lang // $ENV{LANGUAGE} // $ENV{LANG} // 'en'; $l =~ m/^(..)/;
    return $1;
};

has 'language_tables' => sub { {}; };

sub load_language($self, $language = $self->language) {
    # Load a language file
    my $lang_file = Mojo::Path->new($self->xlat_root);
    push @$lang_file, "${language}.tab";
    my $filename = $lang_file->to_string;

    my $translate_from;
    open (my $xlat, '<', $filename) or die "Can't open translation file $filename\n";
    while (<$xlat>) {
	chomp;
	if (/^\s*#(.*)$/) {
	    my $comment_text = $1;
	    if ($comment_text =~ /\blanguage\s*:\s*(\w+)\s(\w+)/i) {
		my ($lang_code, $lang_name) = ($1, $2);
		$self->language_tables->{$lang_code}{name} = $lang_name;
	    }
	} elsif (/\S{1,}/) { # if anything non-blank
	    if (defined $translate_from) {
		$self->language_tables->{$language}{$translate_from} = $_;
		undef $translate_from;
	    } else {
		$translate_from = $_;
	    }
	}
    }
    close $xlat;
}

sub translate($self, $string, $language = $self->language) {
    # Translate a string, in the given language or the default if none given
    if (!defined $self->language_tables->{$language}) {
	eval { $self->load_language($language); }
    }
    return '??' unless defined $string;
    return $self->language_tables->{$language}{$string} // $string // '??';
}

################
# OBJECT SUPPORT
################

# NOTE: "Object" here refers to Simutrans's idea of an object (vehicle, waytype, etc.)
# as defined in the pakset source.

# objects is a simple hash.  Thus, $pak->objects() returns the entire
# pak object-hash

has objects => sub { {}; };

# $pak->object('objname')         # returns entire parameter-hash for given object
# $pak->object('objname',\{...})  # sets an object's parameter-hash
# $pak->object('objname','objkey') # returns the value of a parameter of an object (objkey must be string)
# $pak->object('objname','objkey','value') # sets parameter value.  value could be a reference.

sub object ($self, $objname = undef, $attr = undef, $value = undef) {
    
    return %{$self->objects} unless defined $objname;
    return $self->objects->{$objname} unless defined $attr;
    return ($self->objects->{$objname} = $attr) if ref($attr);
    return $self->objects->{$objname}{$attr} unless defined $value;
    $self->objects->{$objname}{$attr} = $value;
}

# Returns a hash of objects (in the same format as ->objects() )
# matching the coderef. Uses List::Util::pairgrep to populate
# ($a, $b) each time, $a being the object key, $b being the value hash.
# We then pass these as the two parameters to the callback.
# e.g.,
#   $mypak->grep( sub {$_[1]->{intro_year} > 1960} )
#   $mypak->grep( sub {$_[1]->{obj} eq 'bridge'} )

sub grep ($self, $cb) {
    return {List::Util::pairgrep (sub {&$cb($a, $b)}, %{$self->objects}) };
}

has 'object_types' => sub ($self) { {}; };

sub objects_of_type ($self, $type) {
    return $self->grep( sub {$_[1]->{obj} eq $type} )
}

# Various Simutrans-object filters before saving to our object

# Instead, make this 'save_object' which filters and then saves in one.

use Games::Simutrans::Pak;

################
#
#  TODO: save_object, _object_definition_line() to be moved into Pak.pm
#
################

sub save ($self, $obj) {

    # Remember each Pak object instance
    if (defined $obj) {
        $self->object($obj->{name}, $obj);
        $self->object_types->{$obj->{obj}}++;
    }
}

################
#
# Pakset-wide image collection
#
################

use Games::Simutrans::Image;
has 'imagefiles' => sub { {} };

sub _image_level ($self, $object_name, $level, $image_spec) {
    # Drills down recursively, regardless of starting level, so complete proper structure exists
    if ($level == 0) {
        if (ref $image_spec ne 'HASH') {
            print STDERR "Improperly formed $object_name\n";
            return;
        }
        my $image_file_path = scalar $image_spec->{imagefile};
        if (defined $image_file_path) {
            if (!defined $self->imagefiles->{ $image_file_path }) {
                $self->imagefiles->{ $image_file_path } = Games::Simutrans::Image->new(
                    file => $image_file_path ,  # Full path, as string
                );
            }
            $self->imagefiles->{$image_file_path}->record_grid_coordinate($image_spec->{x}, $image_spec->{y});
        }
    } elsif (ref $image_spec eq 'HASH') {
        foreach my $k (keys %{$image_spec}) {
            $self->_image_level($object_name, $level - 1, $image_spec->{$k}) if defined $image_spec->{$k};
        }
    }
}

sub find_all_images ($self) {
    
    my $has_images = $self->grep( sub {defined $_[1]->{_hasimages}} );
    foreach my $ii (keys %{$has_images}) {
        my $o = $self->object($ii);
        my @imagekeys = keys %{$o->{_hasimages}};
        foreach my $imagetype (@imagekeys) {
            my @images;
            if ($imagetype =~ /^(?:freight|empty|cursor|icon)/) {
                # {rotation}{good_index} where direction as 'E', 'NE' etc
                $self->_image_level($ii, 3, $o->{$imagetype});
            } else {
                # } elsif ($imagetype =~ /^(front|back)/) {   # Assume all others have 6 dimensional axes
                # {rotation}{north-south}{east-west}{height}{animation_frame}{season} where rotation = 0..15
                $self->_image_level($ii, 6, $o->{$imagetype});
            }
        }
    }
}

################
# IMAGE FILES
################

# See comments in Games::Simutrans::Image for details on why and how
# we impute the tilesize for each image.

sub find_image_tile_sizes ($self, $params = {}) {

    my $images = $self->imagefiles;
    return unless defined $images;
    foreach my $file (keys %{$images}) {
        if (defined $self->imagefiles->{$file}) {
            $self->imagefiles->{$file}->read($params);  # Computes tile size, and saves when parameter save=1.
        }
    }
}

################
#
# Liveries
#
################

use Games::Simutrans::Livery;

has 'liveries' => sub { {}; };

sub scan_liveries ($self, $type = undef) {

    my $objects;
    if (defined $type) {
        $objects = $self->objects_of_type($type);
    } else {
        $objects = $self->objects;
    }

    foreach my $obj_name (keys %{$objects}) {

        my $this_object = $objects->{$obj_name};
        my $liveries = $this_object->{liverytype};

        next unless (defined $liveries) && (ref $liveries eq 'HASH');
        foreach my $l (values %{$liveries}) {
            $self->liveries->{$l} //= Games::Simutrans::Livery->new(name => $l);
            my $livery = $self->liveries->{$l};
            $livery->record_use($this_object);
        }
    }
}

################
#
# Timeline
#
################

sub timeline ($self, $type = undef) {
    
    my $objects;
    if (defined $type) {
        $objects = $self->objects_of_type($type);
    } else {
        $objects = $self->objects;
    }

    my $timeline;

    my @periods = (qw(intro retire));
    foreach my $obj_name (keys %{$objects}) {
        next if $objects->{$obj_name}{is_permanent};
        my $this_type = $objects->{$obj_name}{obj};
        foreach my $period (0..1) {
            # Value will be the opposite end of the availability period
            $timeline->{$objects->{$obj_name}{$periods[$period]}}{$periods[$period]}{$this_type}{$objects->{$obj_name}{name}} =
            $objects->{$obj_name}{$periods[1-$period]};
        }
    }

    return $timeline;
}

################
#
# OBJECT DATA (.dat) FILES
#
################

has 'dat_files';

sub read_dat ($self, $filename) {

    # Read a .dat file and pass the entire string to be parsed
    my $dat_text;
    eval { $dat_text = Mojo::File->new($filename)->slurp; 1; } or die "Can't open $filename: $!";

    # A dat file may contain multiple objects, separated by a dashed line.
    foreach my $object_text (split(/\n-{2,}\s*\n/, $dat_text)) {
        my $new_object = Games::Simutrans::Pak->new->from_string({ file => $filename,
                                                                   text => $object_text});
        $self->save($new_object) if defined $new_object;
    }

}

sub load ($self, $path = $self->path) {
    # Loads (or reloads) the pak's data files

    if (!ref $path) {
        $self->path($path = Mojo::File->new(expand_tilde($path)));
    }

    return undef unless defined $path;
    # Load directory recursively; or load a single file.
    $self->dat_files( -d $path ?
                      $path->list_tree->grep(sub{/\.dat\z/i}) :
                      Mojo::Collection->new($path) );

    $self->dat_files->each ( sub {
	$self->read_dat($_);
    });

    eval { $self->load_language(); 1; } or $self->{_xlat_root}->{error} = $@;
    $self->find_all_images();
    $self->find_image_tile_sizes();
    $self->scan_liveries();
    1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Games::Simutrans::Pakset - Represents an entire Pakset for the Simutrans game

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use Games::Simutrans::Pakset;

  my $g= Games::Simutrans::Pakset->new;
  $g->path('~/simutrans/sources/simutrans-pak128.britain');

  use Data::Dumper;
  print Dumper($g->languages);

  $g->load;

  print $g->object('4-wheel-1850s')->to_string;

=head1 DESCRIPTION

Games::Simutrans::Pakset creates objects that represent a Pakset for
the Simutrans game.  These objects are of type
L<Games::Simutrans::Pak>, and are accompanied by various other
meta-information like language translations.

"Each pakset has different objects, buying prices, maintenance costs,
themes and a whole unique gameplay. Every pakset is a new game." --
L<https://simutrans.com/>.

Component objects created represent language translations, graphical
objects, and so on. As yet the representation in the objects created
by the Perl modules are incomplete, but eventually they may be enough
to load a pakset into a game engine written entirely in Perl, or to
permit editing an entire Pakset while enforcing set-wide consistency
(i.e., timelines will not include eras when no rail vehicles are
unbuildable; goods prices or capacity and motive power growth can be
tracked over time, etc.)

Paksets for both the Standard and Extended (formerly "Experimental")
versions for Simutrans are supported.

=head1 METHODS

=head2 new

  my $pakset = Games::Simutrans::Pakset->new;

Create a new Pakset object.  This module uses objects contructed with
L<Mojo::Base>.  The following attributes, all optional, may be useful
to pass when creating the object:

=over 4

=item path

=item name

=item language

=back

=head2 name

An identifying name for the pakset.  Not used in any computation; as
an identifier only.

=head2 path

Returns, or sets if an argument is given, the base path on the local
filesystem for the pakset root.  Tildes are expanded to the user's
home directory.  After tke pakset is loaded, this will be a Mojo::File
object (which, when used in scalar context, reduces to the path
string).

=head2 valid

Returns a nonzero value if the path() appears to contain a valid
Simutrans pakset. At the moment it simply verifies that the path
exists.

=head2 xlat_root

Returns, or sets if an argument is given, the base path, usually a
subtree under that pakset root, where the language translation files
are stored.

=head2 languages

Returns a L<Mojo::Collection> of available language translations,
based on the directories and files that exist in C<xlat_root>.

=head2 language

Returns, or sets if an argument is given, the current language for
translation. Defaults to the environment string C<LANGUAGE>, or
C<LANG>, or C<en> otherwise.

=head2 translate ($string, $language)

Returns the translation of C<$string> in the C<$language> given (or in
the current language if C<$language> is C<undef>).

=head2 language_tables

Returns the actual language translation tables, as used by the
C<translate> method.

=head2 objects

Returns a hash of all the objects defined in the pakset.

=head2 object

  my $obj = $pakset->object($object_name);
  my $attr = $pakset->object($object_name, $attribute);
  $pakset->object($object_name, $attribute, $value);

Returns a hash of the values for the given object, by name.  If
C<$attribute> is set, returns only that attribute (which may be a
scalar, array, or hash) or sets it (if C<$value> is defined).

=head2 imagefiles

Returns a hash of discovered image files for the Simutrans objects in
the pakset. The keys of the hash are the full ocal pathnames of the
files, with each value being the matching L<Games::Simutrans::Image>
object.

=head2 grep

  my @objects = $pakset->grep( sub { ... } );

Calls the callback, using List::Util::pairgrep, once for each item in
the hash of attributes for each object (the two parameters to the
callback being the object name, and its hash of attributes).  Returns
a list of object names for which the callback returned a nonzero
value.

=head2 object_types

  my @obj_types = $pakset->objects_types;

Returns a list of object types defined in the pakset.

=head2 objects_of_type

  my @obj = $pakset->objects_of_type('vehicle');

Returns a list of the objects of a given type as defined in the
pakset.

=head2 timeline

  my $timeline = $pakset->timeline($type);

Returns a timeline, in chronological order, of the introduction and
retirement dates for each object in the pak, or for objects of the
type given.

=head2 save

  $pakset->save($object);

Saves an attribute hash in the pakset.  The attribute C<name> must
contain the object name, which will become its key in the pakset's
object hash.

=head2 read_dat 

  $pakset->read_dat($filename);

Reads a single *.dat file using Mojo::File::slurp, splits it into
individual objects (separated by lines beginning with at least two
dashes, as per the *.dat specification), calls the from_string method
in L<Games::Simutrans::Pak> to create a Pak object from it, and then
the C<save> method in this module to save that Pak in the Pakset
object.

=head2 load 

  $pakset->load($path);

Loads an entire pakset, from the path given or from the path at the
C<path> attribute.

=head2 dat_files

Returns a L<Mojo::Collection> list of all the *.dat files loaded via
the C<load()> method.

=head2 find_all_images

For each of the various graphic subimages defined in the pakset,
determines in which actual *.png file they are contained, and finds
the maximum (x,y) grid locations used in each *.png file.

=head2 find_image_tile_sizes

Actually loads (using the L<Imager> module) each *.png file which is
called for by the pakset, and using the maximum (x,y) grid locations
discovered by C<find_all_images>, determines the tile size for each
*.png file.

=head2 scan_liveries

Loads the "convoi" livery files using L<Games::Simutrans::Livery> and
keeps track of the period of use of each of them.

=head2 liveries

Returns a hash, keyed by the name of each livery, of pertinent data.

=head1 AUTHOR

William Lindley E<lt>wlindley@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2021 William Lindley

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Games::Simutrans::Pak>, L<Games::Simutrans::Image>,
L<Games::Simutrans::Livery>

L<Imager>

Simutrans, L<https://simutrans.com/>, is a free-software, open-source
transportation simulator.

The Simutrans Wiki,
L<https://simutrans-germany.com/wiki/wiki/en_dat_Files>, explains the
format of *.dat files. They are normally fed, along with graphic *.png
files, to the C<makeobj> program to make the binary *.dat files that
the Simutrans game engines use.

=cut
