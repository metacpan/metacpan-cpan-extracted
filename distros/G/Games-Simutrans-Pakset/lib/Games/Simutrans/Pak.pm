package Games::Simutrans::Pak;

#
# Represents an individual Simutrans object (although multiple objects
# may reside in an actual *.pak file).
#

use v5.32;

our $VERSION = '0.02';

use Mojo::Base -base, -signatures;
use Mojo::File;
use Data::DeepAccess qw(deep_exists deep_get deep_set);

has '_intro';
has '_retire';
has 'name';

################
#
# Create an object from, e.g., a dat file section.
# This requires both the text, and the pathname from which it was loaded,
# in order to be able to locate the attached images.
#
################

sub from_string ($self, $params) {

    my $filename;
    my $dat_text;

    if (ref $params) {
        $filename = $params->{file};
        $dat_text = $params->{text};
    } else {
        return undef;
    }

    my %this_object;
    $this_object{_filename} = $filename;

    foreach my $line (split("\n", $dat_text)) {
        # Remove (but save) comments
        if ($line =~ s/\#(?<comment>.*)\Z//) {
            push @{$this_object{_comments}}, $+{comment};
        } elsif ($line =~ /^\s*-{2,}/) {
            last;  # Only load the first object.  Caller is responsible for splitting *.dat files.
        }

        if ($line =~ /^\s*(?<object>\w+)\s*(?:\[(?<subscr>(?:\[|\]|\-|\w|\s)+)\])?\s*=(?<nozoom>>?)\s*(?<value>.*?)\s*\Z/) {
            # /^\s*(?<object>\w+)\s*(?:\[(?<sub1>\w+)\](?:\[(?<sub2>\w+)\])?)?\s*=\s*(?<value>.*?)\s*\Z/) {
            my ($object, $value, $nozoom) = @+{qw(object value)};
            $object = lc($object);
            $this_object{_nozoom}{$object} = 1 if $+{nozoom};  # icon=>foo  means foo.png without change as map is zoomed
            my @subscripts;
            @subscripts = split /[\[\]]+/, $+{subscr} if defined $+{subscr};
            if (scalar @subscripts || $object =~ /^(?:cursor|icon)\z/) {
                # NOTE: Values with subscripts, as "value[0]=50", will clobber a previous "value=50".
                if (ref(\$this_object{$object}) eq 'SCALAR') {
                    undef $this_object{$object};
                }
                my $is_image = 0;
                my $dimensions;
                if ($object =~ /^(front|back)?(image|diagonal|start|ramp|pillar)(up)?2?\z/) {
                    # NOTE: certain keys (FrontImage, BackImage) have multiple assumed axes,
                    # but not all values will give values for each; thus you may find two
                    # entries as:
                    #    FrontImage[1][0]    = value1
                    #    FrontImage[1][0][1] = value2
                    # where value1 is actually for FrontImage[1][0][0][0][0][0], with all the
                    # unstated axes defaulting to zero.
                    $dimensions = (defined $1 && $2 eq 'image') ? 6 : 2;  # frontimage, backimage are 6-dim;
                    # all other images are two-dimensional (one axis plus season).
                    $is_image++;
                } elsif ($object =~ /^((empty|freight)image|cursor|icon)\z/) {
                    $dimensions = 3;
                    $is_image++;
                }
                if (defined $dimensions) {
                    if (scalar @subscripts > $dimensions) {
                        print STDERR "Object " . ($this_object{name} // '??') . " has " .
                        scalar @subscripts . " ($dimensions expected)\n";
                    }
                    # Convert to correction number of dimensions, with '0' defaults:
                    @subscripts = map { $_ // 0 } @subscripts[0..($dimensions-1)]; 
                }
                if ($is_image) {
                    # Can begin as './something' but otherwise file cannot have dots within
                    if ($value =~ /^(?<image>\.?[^.]+)           
                                   (?:\.(?<y>\d+)
                                       (?:\.(?<x>\d+))?
                                       (?:,(?<xoff>\d+)
                                           (?:,(?<yoff>\d+))?
                                       )?
                                   )?/xa) {
                        $value = { ( map { defined $+{$_} ? ($_ => $+{$_}) : () } qw(image xoff yoff) ),   # skip each if undef
                                   ( map { $_ => $+{$_} // 0 } qw( x y ) ) };      # these default to zero
                        # Override above in case of older "imagefile.3" form, which assumes column (x) only
                        if (!defined $+{x} && $object =~ /^(front|back|empty|freight)/) {  # 
                            $value->{x} = $+{y} // 0; $value->{y} = 0;
                        }
                        $value->{imagefile} = Mojo::File->new($filename)->sibling($value->{image}.'.png') unless $value->{image} eq '-';
                        $this_object{_hasimages}{$object}++;
                    }
                }
                # for Data::DeepAccess … Thanks mst and Grinnz on irc.perl.org #perl 2020-06-18
                deep_set(\%this_object, $object, (map { lc } (@subscripts)), $value);
            } else {
                $this_object{lc($object)} = $value;
            }
        }
    }

    ################
    # Finalization
    ################

    if (! $this_object{intro_year} && ! $this_object{retire_year}) {
	$this_object{_is_permanent} = 1;
        $this_object{_sort_key} = '0000';
    } else {
        $this_object{intro_year} ||= 1000;
        $this_object{intro_month} ||= 1;
        $this_object{retire_year} ||= 2999;
        $this_object{retire_month} ||= 12;
        $this_object{_is_internal} = $this_object{intro_year} < 100; # Internal object

        # Permit second-level sorting for objects with equal introductory times
        my $power = $this_object{'engine_type'};
        $power = '~~~' if (!length($power)); # sort last

        $this_object{_sort_key} = sprintf("%4d.%02d %s %4d.%02d",
                                          $this_object{'intro_year'}, $this_object{'intro_month'},
                                          $power,
                                          $this_object{'retire_year'}, $this_object{'retire_month'});
    }

    ###### OBSOLETE
    # # Abbreviate loquacious names
    # $this_object{_short_name} = $this_object{'name'} // '(none)';
    # if (length($this_object{_short_name}) > 30) {
    #     $this_object{_short_name} =~ s/-([^-]{3})[^-]+/-$1/g;
    # }

    # en-passant spelling correction
    $this_object{max_length} //= delete $this_object{max_lenght} if defined $this_object{max_lenght};

    if (exists $this_object{intro_year}) {
	foreach my $event (qw[intro retire]) {
            foreach my $period (qw[month year]) {
                my $setit = $event . '_' . $period;
                $self->$setit (delete $this_object{$setit});
            }
	}
    }

    ################
    # TODO: Suppress trailing zero dimensions in image hashes/arrays.
    ################

    ################
    # Copy values into returned (self) object
    ################

    foreach my $k (keys %this_object) {
        $self->{$k} = $this_object{$k};
    }

    return defined $this_object{obj} ? $self : undef;
}

################

sub intro ($self) { return $self->_intro; }
sub retire ($self) { return $self->_retire; }

sub intro_year ($self, $value = undef) {
    $self->_intro( $value * 12 + (($self->intro() // 0) % 12) ) if defined $value;
    return defined $self->intro() ? int($self->intro() / 12) : undef;
}

sub intro_month ($self, $value = undef) {
    $self->_intro( (($self->intro_year() // 0) * 12) + $value  - 1) if defined $value;
    return defined $self->intro() ? ($self->intro() % 12) + 1 : undef;
}

sub retire_year ($self, $value = undef) {
    $self->_retire( $value * 12 + (($self->retire() // 0) % 12) ) if defined $value;
    return defined $self->retire() ? int($self->retire() / 12) : undef;
}

sub retire_month ($self, $value = undef) {
    $self->_retire( (($self->retire_year() // 0) * 12) + $value - 1) if defined $value;
    return defined $self->retire() ? ($self->retire() % 12) + 1 : undef;
}

################

sub waytype_text ($self) {
    # Return a standardized, shorter version of the waytype
    my $waytype = $self->{'waytype'};
    if (defined $waytype) {
        $waytype =~ s/_track//;
        $waytype =~ s/track/train/;
        $waytype =~ s/water/ship/;
        $waytype =~ s/narrowgauge/narrow/;
    }
    return $waytype // '';
}

sub payload_text ($self) {
    # Return a standardized, shorter version of the capacities (from the payload)
    my $capacity;
    if ( defined $self->{payload} ) {
        if ( ref $self->{payload} eq 'HASH' ) {
            $capacity = join(',', $self->{payload}->@{ sort keys %{$self->{payload}} } );
        } else {
            $capacity = sprintf("%3du", $self->{payload});
        }
    }
    return $capacity // '--';
}

################

sub comments ($self) {
    return $self->{_comments};
}

sub deep_print ($self, $attribute, @keys) {
    my $value = deep_get($self->{$attribute}, @keys);
    if (ref $value eq 'HASH') {
        my $text;
        my $has_values = [];
        my $is_image = exists $value->{image} && exists $value->{x};
        foreach my $k (sort keys %{$value}) {
            if ($is_image && !ref deep_get($self->{$attribute}, @keys, $k)) {
                push @{$has_values}, $k;
            } else {
                $text .= $self->deep_print($attribute, @keys, $k);
            }
        }
        if (scalar @{$has_values}) {
            # TODO: Only if this is an image!
            my $image_spec = $value->{image} .
            '.' . ($value->{y}//0) .
            '.' . ($value->{x}//0);
            $image_spec .= ',' . ($value->{xoff}//0) . ',' . ($value->{yoff}//0)
            if defined $value->{xoff} || $value->{yoff};
            return $attribute . '[' . join('][', @keys) . ']=' . $image_spec . "\n";
        }
        return $text;
    } else {
        return $attribute . '[' . join('][', @keys) . ']=' . $value . "\n";
    }
}

sub to_string ($self) {
    # Preferred order to emit attributes.  Any others will be emitted
    # in random order after these.
    my $emit_order = Mojo::Collection->new(qw( obj type name copyright 
                                               intro_year intro_month retire_year retire_month 
                                               waytype own_waytype engine_type chance DistributionWeight
                                               needs_ground seasons climates
                                               noinfo noconstruction
                                               build_time level offset_left
                                               enables_pax enables_post enables_ware
                                               catg metric weight_per_unit value speed_bonus
                                               freight payload speed topspeed cost maintenance runningcost
                                               power gear height weight length sound smoke
                                               loading_time
                                               max_length max_height pillar_distance pillar_asymmetric system_type
                                               MapColor
                                               dims
                                               icon cursor
                                               FrontImage BackImage BackImage2
                                               FreightImageType FreightImage EmptyImage
                                               openimage front_openimage closedimage front_closedimage
                                         ));
    my %to_emit = map { ($_, $self->{$_}) } grep { $_ !~ /^_/ } keys %{$self};

    # Replace synthetic dates with external representations
    if (defined $self->intro()) {
        @to_emit{qw(intro_year intro_month retire_year retire_month)} =
        ($self->intro_year(), $self->intro_month(), $self->retire_year(), $self->retire_month());
    };

    my $text = '';

    foreach my $c (@{$self->comments // []}) {
        $text .= "#$c\n";
    }
    # Emit common attributes in a desirable order
    $emit_order->each(sub { my $emit_key = lc($_); # %to_emit has keys from object, not as capitalized above
                            if (defined $to_emit{$emit_key}) {
                              if (ref $self->{$emit_key} ne 'HASH') {
                                  $text .= "$_=" . $to_emit{$emit_key} . "\n";  # simple value
                              } else {
                                  $text .= $self->deep_print($emit_key);
                              }
                              delete $to_emit{$emit_key};
                          }
                      });
    $text .= "\n";

    # Emit remaining attributes
    foreach my $k (sort keys %to_emit) {
        if (defined $self->{$k}) {
            if (ref $self->{$k} ne 'HASH') {
                $text .= "$k=" . $self->{$k} . "\n";  # simple value
            } else {
                $text .= $self->deep_print($k);
            }
        }
    }
    return $text . "------\n\n";
}

1;

__END__

=encoding utf-8

=head1 NAME

Games::Simutrans::Pak - Represents a single Simutrans object.

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use Games::Simutrans::Pakt;

  my $p = Games::Simutrans::Pak->new;

=head1 DESCRIPTION

This module works in concert with L<Games::Simutrans::Pakset> as
objects that represent portions of a Pakset for the Simutrans game.
These objects have various attributes like L<Games::Simutrans::Image>
images (using the L<Imager> module) and are also accompanied by
various other meta-information like language translations.

Pak objects created with this module are relatively free-form in what
information may be stored, with the C<to_string> method generally
making a best-effort to emit scalars and arrays in a format that
should be recognized by the C<makeobj> program.  In general, data
which map directly to dat file values have a key (in the internal
hash) that begins with an alphanumeric character; leading underscores
are used for internal values.

Pak definitions for both the Standard and Extended (formerly
"Experimental") versions for Simutrans are supported.

=head1 METHODS

=head2 new

  my $pak = Games::Simutrans::Pak->new;

Create a new Pak object.  This module uses objects contructed with
L<Mojo::Base>.  The following attributes, all optional, may be useful
to pass when creating the object:

=over 4

=item name

=back

=head2 name

An identifying name for the pak. This must be the same as the C<name=>
value in the *.dat file which describes the Simutrans object.

=head2 from_string

  $pak->from_string( { file => $filename, text => $dat_text });

Parses the text in Simutrans's dat format as described at
L<https://simutrans-germany.com/wiki/wiki/en_dat_Files>.
The C<file> parameter was formerly used, and is still stored b

=head2 to_string

  my $text = $pak->to_string;

Returns a textual representation of the Pak object, designed to be
able to be fed to the C<makeobj> program.  For example, each object
will terminate with a line consisting only of several dashes, followed
by a blank line.  (In this way, several of these strings may be
concatenated into a single *.dat file for correct processing by
C<makeobj>). The attribute lines are output in predesignated order,
partially because of C<makeobj>'s requirements and partially to be
sensible to human readers, starting with the following sequence:

=over 4

=item obj=

=item type=

=item name=

=item copyright=

=back

C<to_string> in general will do its best to output ordinary values
(whose keys do not begin with an underscore) whether scalar, hash, or
array, in a format that the C<makeobj> program will understand.
C<to_string> is guaranteed to skip processing for internal keys
(beginning with an underscore) it does not recognize, and to give
special processing to those it does recognize. This may be augmented
later with a plugin system to permit user extensions.

=head2 intro

Returns or sets the object's introduction month, in the format C<year
* 12 + month - 1>, suitable for sorting or chronological comparison.

The methods C<intro_year> and C<intro_month> return or set the
individual year and month components of the combined value.

=head2 retire

As C<intro>, with component methods C<retire_year> and
C<retire_month>.

=head2 waytype_text

Returns a standardized version of the object's C<waytype> parameter,
e.g., C<tram_track> becomes just C<tram>, and C<narrowgauge> becomes
just C<narrow>.

=head2 payload_text

Returns a standardized version of the object's C<payload> parameter.
Missing payloads (as for locomotives) will return '--', classed
payloads (as for passenger carriages) will be a comma-delimited
sequence of numbers, and ordinary freight capacities will be in the
form C<100u> (u for units).

=head1 IMAGE HANDLING

Simutrans generally handles the several images for an object as
multi-level arrays.  This module stores them as Perl hashes, with the
key being the array index (usually a number, but some image types —
e.g., C<Image> and C<EmptyImage> — use directional letters like C<S>
or C<SW>).  The value of a particular multidimensional position is in
turn a hash which may contain these keys:

=head2 image

The name of the image file as given in the dat file, without path or
extension.  The existence of this key may be used to indicate the
value describes and image.

=head2 imagefile

The image file with an absolute path (resolved as a relative path from
the dat file itself) and extension (always C<.png> as required by
Simutrans).

=head2 x, y

The column and row number as given in the dat file.

=head2 xoff, yoff

The x and y offsets as given in the dat file, if defined; missing or
undef are equivalent to zero.

=head1 INTERNAL KEYS

The following internal keys may be found in the hash representing an
object.

=head2 _has_images

Nonzero if the object has attached images.

=head2 _is_permanent

Nonzero if the object is permanently defined in the game (it does not
have an introduction or retire year).

=head2 _is_internal

Nonzero if the object is marked as internal to Simutrans itself; in
the dat file it will have an C<intro_year> less than 100.

=head2 _sort_key

Used for sorting the C<timeline>, this contains text describing the
introduction and retirement dates, along with the power (or other)
text useful for human viewing of a sorted list.

=head1 AUTHOR

William Lindley E<lt>wlindley@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2021 William Lindley

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Games::Simutrans::Pak>

L<Games::Simutrans::Image>

L<Imager>

Simutrans, L<https://simutrans.com/>, is free software, an open-source
transportation simulator.

The Simutrans Wiki,
L<https://simutrans-germany.com/wiki/wiki/en_dat_Files>, explains the
format of *.dat files. They are normally fed, along with graphic *.png
files, to the C<makeobj> program to make the binary *.dat files that
the Simutrans game engines use.

=cut
