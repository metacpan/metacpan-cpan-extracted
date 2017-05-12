package MARC::Field;

use strict;
use warnings;
use integer;
use Carp;

use constant SUBFIELD_INDICATOR => "\x1F";
use constant END_OF_FIELD       => "\x1E";

use vars qw( $ERROR );

=head1 NAME

MARC::Field - Perl extension for handling MARC fields

=head1 SYNOPSIS

  use MARC::Field;

  # If your system uses wacky control field tags, add them
  MARC::Field->allow_controlfield_tags('FMT', 'LLE');

  my $field = MARC::Field->new( 245, '1', '0',
       'a' => 'Raccoons and ripe corn / ',
       'c' => 'Jim Arnosky.'
  );
  $field->add_subfields( "a", "1st ed." );

=head1 DESCRIPTION

Defines MARC fields for use in the MARC::Record module.  I suppose
you could use them on their own, but that wouldn't be very interesting.

=head1 EXPORT

None by default.  Any errors are stored in C<$MARC::Field::ERROR>, which
C<$MARC::Record> usually bubbles up to C<$MARC::Record::ERROR>.

=head1 CLASS VARIABLES

B<extra_controlfield_tags>: Some systems (notably Ex Libris's Aleph) throw
extra control fields in their MARC (e.g., Aleph's MARC-XML tends to have a 
C<FMT> control field). We keep a class-level hash to track to track them; it can
be manipulated with C<allow_controlfield_tags> and c<disallow_controlfield_tags>.

=cut

my %extra_controlfield_tags = ();


=head1 METHODS

=head2 new()

The constructor, which will return a MARC::Field object. Typically you will
pass in the tag number, indicator 1, indicator 2, and then a list of any
subfield/data pairs. For example:

  my $field = MARC::Field->new(
       245, '1', '0',
       'a' => 'Raccoons and ripe corn / ',
       'c' => 'Jim Arnosky.'
  );

Or if you want to add a control field (< 010) that does not have indicators.

  my $field = MARC::Field->new( '001', ' 14919759' );

=cut

sub new {
    my $class = shift;
    $class = $class;

    ## MARC spec indicates that tags can have alphabetical
    ## characters in them! If they do appear we assume that
    ## they have indicators like tags > 010 unless they've
    ## been previously defined as control tags using
    ## add_controlfield
    
    my $tagno = shift;
    $class->is_valid_tag($tagno)
        or croak( "Tag \"$tagno\" is not a valid tag." );
    my $is_control = $class->is_controlfield_tag($tagno);

    my $self = bless {
        _tag => $tagno,
        _warnings => [],
        _is_control_field => $is_control,
    }, $class;

    if ( $is_control ) {
        $self->{_data} = shift;
        $self->_warn("Too much data for control field '$tagno'") if (@_);
    } else {
        for my $indcode ( qw( _ind1 _ind2 ) ) {
            my $indicator = shift;
            defined($indicator) or croak("Field $tagno must have indicators (use ' ' for empty indicators)");
            unless ($self->is_valid_indicator($indicator)) {
                $self->_warn( "Invalid indicator \"$indicator\" forced to blank" ) unless ($indicator eq "");
                $indicator = " ";
            }
            $self->{$indcode} = $indicator;
        } # for

        (@_ >= 2)
            or croak( "Field $tagno must have at least one subfield" );

        # Normally, we go thru add_subfields(), but internally we can cheat
        $self->{_subfields} = [@_];
    }

    return $self;
} # new()


=head2 tag()

Returns the three digit tag for the field.

=cut

sub tag {
    my $self = shift;
    return $self->{_tag};
}

=head2 set_tag(tag)

Changes the tag number of this field. Updates the control status accordingly.
Will C<croak> if an invalid value is passed in.

=cut

sub set_tag {
    my ( $self, $tagno ) = @_;

    $self->is_valid_tag($tagno)
      or croak("Tag \"$tagno\" is not a valid tag.");
    $self->{_tag}              = $tagno;
    $self->{_is_control_field} = $self->is_controlfield_tag($tagno);
}

=head2 indicator(indno)

Returns the specified indicator.  Returns C<undef> and logs
a warning if field is a control field and thus doesn't have
indicators.  If the field is not a control field, croaks
if the I<indno> is not 1 or 2.

=cut

sub indicator {
    my $self = shift;
    my $indno = shift;

    if ($self->is_control_field) {
        $self->_warn( "Control fields (generally, those with tags below 010) do not have indicators" );
        return;
    }

    if ( $indno == 1 ) {
        return $self->{_ind1};
    } elsif ( $indno == 2 ) {
        return $self->{_ind2};
    } else {
        croak( "Indicator number must be 1 or 2" );
    }
}

=head2 set_indicator($indno, $indval)

Set the indicator position I<$indno> to the value
specified by I<$indval>.  Croaks if the indicator position,
is invalid, the field is a control field and thus
doesn't have indicators, or if the new indicator value
is invalid.

=cut

sub set_indicator {
    my $self = shift;
    my $indno = shift;
    my $indval = shift;

    croak('Indicator number must be 1 or 2')
      unless defined $indno && $indno =~ /^[12]$/;
    croak('Cannot set indicator for control field')
      if $self->is_control_field;
    croak('Indicator value is invalid') unless $self->is_valid_indicator($indval);

    $self->{"_ind$indno"} = $indval;
}

=head2 allow_controlfield_tags($tag, $tag2, ...)

Add $tags to class-level list of strings to consider valid control fields tags (in addition to 001 through 009).
Tags must have three characters. 

=cut

sub allow_controlfield_tags {
  my $self = shift;
  foreach my $tag (@_) {
    $extra_controlfield_tags{$tag} = 1;
  }
}

=head2 disallow_controlfield_tags($tag, $tag2, ...)
=head2 disallow_controlfield_tags('*')

Revoke the validity of a control field tag previously added with allow_controlfield_tags. As a special case, 
if you pass the string '*' it will clear out all previously-added tags.

NOTE that this will only deal with stuff added with allow_controlfield_tags; you can't disallow '001'.

=cut

sub disallow_controlfield_tags {
  my $self = shift;
  if ($_[0] eq '*') {
    %extra_controlfield_tags = ();
    return;
  }
  foreach my $tag (@_) {
    delete $extra_controlfield_tags{$tag};
  }
}

=head2 is_valid_tag($tag) -- is the given tag valid?

Generally called as a class method (e.g., MARC::Field->is_valid_tag('001'))

=cut

sub is_valid_tag {
    my $self = shift;
    my $tag = shift;
    return 1 if defined $tag && $tag =~ /^[0-9A-Za-z]{3}$/;
    return 0;
}

=head2 is_valid_indicator($indval) -- is the given indicator value valid?

Generally called as a class method (e.g., MARC::Field->is_valid_indicator('4'))

=cut

sub is_valid_indicator {
    my $self = shift;
    my $indval = shift;
    return 1 if defined $indval && $indval =~ /^[0-9A-Za-z ]$/;
    return 0;
}

=head2 is_controlfield_tag($tag) -- does the given tag denote a control field?

Generally called as a class method (e.g., MARC::Field->is_controlfield_tag('001'))

=cut

sub is_controlfield_tag
{
  my $self = shift;
  my $tag = shift;
  return 1 if ($extra_controlfield_tags{$tag});
  return 1 if (($tag =~ /^\d+$/) && ($tag < 10));
  return 0; # otherwise, it's not a control field
}


=head2 is_control_field()

Tells whether this field is one of the control tags from 001-009.

=cut

sub is_control_field {
    my $self = shift;
    return $self->{_is_control_field};
}

=head2 subfield(code)

When called in a scalar context returns the text from the first subfield
matching the subfield code.

    my $subfield = $field->subfield( 'a' );

Or if you think there might be more than one you can get all of them by
calling in a list context:

    my @subfields = $field->subfield( 'a' );

If no matching subfields are found, C<undef> is returned in a scalar context
and an empty list in a list context.

If the tag is a control field, C<undef> is returned and
C<$MARC::Field::ERROR> is set.

=cut

sub subfield {
    my $self = shift;
    my $code_wanted = shift;

    croak( "Control fields (generally, just tags below 010) do not have subfields, use data()" )
        if $self->is_control_field;

    my @data = @{$self->{_subfields}};
    my @found;
    while ( defined( my $code = shift @data ) ) {
        if ( $code eq $code_wanted ) {
            push( @found, shift @data );
        } else {
            shift @data;
        }
    }
    if ( wantarray() ) { return @found; }
    return( $found[0] );
}

=head2 subfields()

Returns all the subfields in the field.  What's returned is a list of
list refs, where the inner list is a subfield code and the subfield data.

For example, this might be the subfields from a 245 field:

        (
          [ 'a', 'Perl in a nutshell :' ],
          [ 'b', 'A desktop quick reference.' ],
        )

=cut

sub subfields {
    my $self = shift;

    if ($self->is_control_field) {
        $self->_warn( "Control fields (generally, just tags below 010)  do not have subfields" );
        return;
    }

    my @list;
    my @data = @{$self->{_subfields}};
    while ( defined( my $code = shift @data ) ) {
        push( @list, [$code, shift @data] );
    }
    return @list;
}

=head2 data()

Returns the data part of the field, if the tag number is less than 10.

=cut

sub data {
    my $self = shift;

    croak( "data() is only for control fields (generally, just tags below 010) , use subfield()" )
        unless $self->is_control_field;

    $self->{_data} = $_[0] if @_;

    return $self->{_data};
}

=head2 add_subfields(code,text[,code,text ...])

Adds subfields to the end of the subfield list.

    $field->add_subfields( 'c' => '1985' );

Returns the number of subfields added, or C<undef> if there was an error.

=cut

sub add_subfields {
    my $self = shift;

    croak( "Subfields are only for data fields (generally, just tags >= 010)" )
        if $self->is_control_field;

    push( @{$self->{_subfields}}, @_ );
    return @_/2;
}

=head2 delete_subfield()

delete_subfield() allows you to remove subfields from a field: 

    # delete any subfield a in the field
    $field->delete_subfield(code => 'a');

    # delete any subfield a or u in the field
    $field->delete_subfield(code => ['a', 'u']);

    # delete any subfield code matching a compiled regular expression
    $field->delete_subfield(code => qr/[^a-z0-9]/);

If you want to only delete subfields at a particular position you can 
use the pos parameter:

    # delete subfield u at the first position
    $field->delete_subfield(code => 'u', pos => 0);

    # delete subfield u at first or second position
    $field->delete_subfield(code => 'u', pos => [0,1]);

    # delete the second subfield, no matter what it is
    $field->delete_subfield(pos => 1);

You can specify a regex to for only deleting subfields that match:

   # delete any subfield u that matches zombo.com
   $field->delete_subfield(code => 'u', match => qr/zombo.com/);

   # delete any subfield that matches quux
   $field->delete_subfield(match => qr/quux/);

You can also pass a single subfield label:

  # delete all subfield u
  $field->delete_subfield('u');

=cut

sub delete_subfield {
    my ($self, @options) = @_;

    my %options;
    if (scalar(@options) == 1) {
        $options{code} = $options[0];
    } elsif (0 == scalar(@options) % 2) {
        %options = @options;
    } else {
        croak 'delete_subfield must be called with single scalar or a hash';
    }

    my $codes = _normalize_arrayref($options{code});
    my $positions = _normalize_arrayref($options{'pos'});
    my $match = $options{match};
   
    croak 'match must be a compiled regex' 
      if $match and ref($match) ne 'Regexp';

   croak 'must supply subfield code(s) and/or subfield position(s) and/or match patterns to delete_subfield'
      unless $match or (@$codes > 0) or (@$positions > 0);

    my @current_subfields = @{$self->{_subfields}};
    my @new_subfields = ();
    my $removed = 0;
    my $subfield_num = $[ - 1; # users $[ preferences control indexing 

    while (@current_subfields > 0) {
        $subfield_num += 1;
        my $subfield_code = shift @current_subfields;
        my $subfield_value = shift @current_subfields;
        if ((@$codes==0 or 
            grep {
                (ref($_) eq 'Regexp' && $subfield_code =~ $_) ||
                (ref($_) ne 'Regexp' && $_ eq $subfield_code)
            } @$codes)
            and (!$match or $subfield_value =~ $match) 
            and (@$positions==0 or grep {$_ == $subfield_num} @$positions)) {
            $removed += 1;
            next;
        }
        push( @new_subfields, $subfield_code, $subfield_value);
    }
    $self->{_subfields} = \@new_subfields;
    return $removed;
}

=head2 delete_subfields()

Delete all subfields with a given subfield code. This is here for backwards
compatibility, you should use the more flexible delete_subfield().

=cut

sub delete_subfields {
    my ($self, $code) = @_;
    return $self->delete_subfield(code => $code);
}

=head2 update()

Allows you to change the values of the field. You can update indicators
and subfields like this:

  $field->update( ind2 => '4', a => 'The ballad of Abe Lincoln');

If you attempt to update a subfield which does not currently exist in the field,
then a new subfield will be appended to the field. If you don't like this
auto-vivification you must check for the existence of the subfield prior to
update.

  if ( $field->subfield( 'a' ) ) {
    $field->update( 'a' => 'Cryptonomicon' );
  }

If you want to update a field that has no indicators or subfields (000-009)
just call update() with one argument, the string that you would like to
set the field to.

  $field = $record->field( '003' );
  $field->update('IMchF');

Note: when doing subfield updates be aware that C<update()> will only
update the first occurrence. If you need to do anything more complicated
you will probably need to create a new field and use C<replace_with()>.

Returns the number of items modified.

=cut

sub update {
    my $self = shift;

    ## tags 000 - 009 don't have indicators or subfields
    if ( $self->is_control_field ) {
        $self->{_data} = shift;
        return(1);
    }

    ## otherwise we need to update subfields and indicators
    my @data = @{$self->{_subfields}};
    my $changes = 0;

    while ( @_ ) {

        my $arg = shift;
        my $val = shift;

        ## indicator update
        if ($arg =~ /^ind[12]$/) {
            $self->{"_$arg"} = $val;
            $changes++;
        }

        ## subfield update
        else {
            my $found = 0;
            ## update existing subfield
            for ( my $i=0; $i<@data; $i+=2 ) {
                if ($data[$i] eq $arg) {
                    $data[$i+1] = $val;
                    $found = 1;
                    $changes++;
                    last;
                }
            } # for

            ## append new subfield
            if ( !$found ) {
                push( @data, $arg, $val );
                $changes++;
            }
        }

    } # while

    ## synchronize our subfields
    $self->{_subfields} = \@data;
    return($changes);

}

=head2 replace_with()

Allows you to replace an existing field with a new one. You need to pass
C<replace()> a MARC::Field object to replace the existing field with. For
example:

  $field = $record->field('245');
  my $new_field = new MARC::Field('245','0','4','The ballad of Abe Lincoln.');
  $field->replace_with($new_field);

Doesn't return a meaningful or reliable value.

=cut

sub replace_with {

  my ($self,$new) = @_;
  ref($new) =~ /^MARC::Field$/
    or croak("Must pass a MARC::Field object");

  %$self = %$new;

}


=head2 as_string( [$subfields] [, $delimiter] )

Returns a string of all subfields run together. A space is added to
the result between each subfield, unless the delimiter parameter is
passed.  The tag number and subfield character are not included.

Subfields appear in the output string in the order in which they
occur in the field.

If C<$subfields> is specified, then only those subfields will be included.

  my $field = MARC::Field->new(
                245, '1', '0',
                        'a' => 'Abraham Lincoln',
                        'h' => '[videorecording] :',
                        'b' => 'preserving the union /',
                        'c' => 'A&E Home Video.'
                );
  print $field->as_string( 'abh' ); # Only those three subfields
  # prints 'Abraham Lincoln [videorecording] : preserving the union /'.
  print $field->as_string( 'ab', '--' ); # Only those two subfields, with a delimiter
  # prints 'Abraham Lincoln--preserving the union /'.

Note that subfield h comes before subfield b in the output.

=cut

sub as_string {
    my $self = shift;
    my $subfields = shift;
    my $delimiter = shift;
    $delimiter = " " unless defined $delimiter;

    if ( $self->is_control_field ) {
        return $self->{_data};
    }

    my @subs;

    my $subs = $self->{_subfields};
    my $nfields = @$subs / 2;
    for my $i ( 1..$nfields ) {
        my $offset = ($i-1)*2;
        my $code = $subs->[$offset];
        my $text = $subs->[$offset+1];
        push( @subs, $text ) if !defined($subfields) || $code =~ /^[$subfields]$/;
    } # for

    return join( $delimiter, @subs );
}


=head2 as_formatted()

Returns a pretty string for printing in a MARC dump.

=cut

sub as_formatted {
    my $self = shift;

    my @lines;

    if ( $self->is_control_field ) {
        push( @lines, sprintf( "%03s     %s", $self->{_tag}, $self->{_data} ) );
    } else {
        my $hanger = sprintf( "%03s %1.1s%1.1s", $self->{_tag}, $self->{_ind1}, $self->{_ind2} );

        my $subs = $self->{_subfields};
        my $nfields = @$subs / 2;
        my $offset = 0;
        for my $i ( 1..$nfields ) {
            push( @lines, sprintf( "%-6.6s _%1.1s%s", $hanger, $subs->[$offset++], $subs->[$offset++] ) );
            $hanger = "";
        } # for
    }

    return join( "\n", @lines );
}


=head2 as_usmarc()

Returns a string for putting into a USMARC file.  It's really only
useful for C<MARC::Record::as_usmarc()>.

=cut

sub as_usmarc {
    my $self = shift;

    # Control fields are pretty easy
    if ( $self->is_control_field ) {
        return $self->data . END_OF_FIELD;
    } else {
        my @subs;
        my @subdata = @{$self->{_subfields}};
        while ( @subdata ) {
            push( @subs, join( "", SUBFIELD_INDICATOR, shift @subdata, shift @subdata ) );
        } # while

        return
            join( "",
                $self->indicator(1),
                $self->indicator(2),
                @subs,
                END_OF_FIELD, );
    }
}

=head2 clone()

Makes a copy of the field.  Note that this is not just the same as saying

    my $newfield = $field;

since that just makes a copy of the reference.  To get a new object, you must

    my $newfield = $field->clone;

Returns a MARC::Field record.

=cut

sub clone {
    my $self = shift;

    my $tagno = $self->{_tag};
    my $is_control = $self->is_controlfield_tag($tagno);

    my $clone =
        bless {
            _tag => $tagno,
            _warnings => [],
            _is_control_field => $is_control,
        }, ref($self);

    if ( $is_control ) {
        $clone->{_data} = $self->{_data};
    } else {
        $clone->{_ind1} = $self->{_ind1};
        $clone->{_ind2} = $self->{_ind2};
        $clone->{_subfields} = [@{$self->{_subfields}}];
    }

    return $clone;
}

=head2 warnings()

Returns the warnings that were created when the record was read.
These are things like "Invalid indicators converted to blanks".

The warnings are items that you might be interested in, or might
not.  It depends on how stringently you're checking data.  If
you're doing some grunt data analysis, you probably don't care.

=cut

sub warnings {
    my $self = shift;

    return @{$self->{_warnings}};
}

# NOTE: _warn is an object method
sub _warn {
    my $self = shift;

    push( @{$self->{_warnings}}, join( "", @_ ) );
}

sub _gripe {
    $ERROR = join( "", @_ );

    warn $ERROR;

    return;
}

sub _normalize_arrayref {
    my $ref = shift;
    if (ref($ref) eq 'ARRAY') { return $ref }
    elsif (defined $ref) { return [$ref] }
    return [];
}


1;

__END__

=head1 SEE ALSO

See the "SEE ALSO" section for L<MARC::Record>.

=head1 TODO

See the "TODO" section for L<MARC::Record>.

=cut

=head1 LICENSE

This code may be distributed under the same terms as Perl itself.

Please note that these modules are not products of or supported by the
employers of the various contributors to the code.

=head1 AUTHOR

Andy Lester, C<< <andy@petdance.com> >>

=cut
