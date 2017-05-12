package KinoSearch1::Index::FieldInfos;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::Class Exporter );

use constant INDEXED    => "\x01";
use constant VECTORIZED => "\x02";
use constant OMIT_NORMS => "\x10";

our @EXPORT_OK;

BEGIN {
    __PACKAGE__->init_instance_vars(
        # members
        by_name   => undef,
        by_num    => undef,
        from_file => 0,
    );
    __PACKAGE__->ready_get_set(qw( from_file ));

    @EXPORT_OK = qw(
        INDEXED
        VECTORIZED
        OMIT_NORMS
    );
}

use KinoSearch1::Document::Field;

sub init_instance {
    my $self = shift;
    $self->{by_name} = {};
    $self->{by_num}  = [];
}

sub clone {
    my $self      = shift;
    my $evil_twin = __PACKAGE__->new;
    $evil_twin->{from_file} = $self->{from_file};
    my @by_num;
    my %by_name;
    for my $finfo ( @{ $self->{by_num} } ) {
        my $dupe = $finfo->clone;
        push @by_num, $dupe;
        $by_name{ $finfo->get_name } = $dupe;
    }
    $evil_twin->{by_num}  = \@by_num;
    $evil_twin->{by_name} = \%by_name;
    return $evil_twin;
}

# Add a user-supplied Field object to the collection.
sub add_field {
    my ( $self, $field ) = @_;
    croak("Not a KinoSearch1::Document::Field")
        unless a_isa_b( $field, 'KinoSearch1::Document::Field' );

    # don't mod Field objects for segments that are read back in
    croak("Can't update FieldInfos that were read in from file")
        if $self->{from_file};

    # add the field
    my $fieldname = $field->get_name;
    $self->{by_name}{$fieldname} = $field;
    $self->_assign_field_nums;
}

# Return the number of fields in the segment.
sub size { scalar @{ $_[0]->{by_num} } }

# Return a list of the Field objects.
sub get_infos { @{ $_[0]->{by_num} } }

# Given a fieldname, return its number.
sub get_field_num {
    my ( $self, $name ) = @_;
    return undef
        unless exists $self->{by_name}{$name};
    my $num = $self->{by_name}{$name}->get_field_num;
    return $num;
}

# Given a fieldname, return its FieldInfo.
sub info_by_name { $_[0]->{by_name}{ $_[1] } }

# Given a field number, return its fieldInfo.
sub info_by_num { $_[0]->{by_num}[ $_[1] ] }

# Given the field number (new, not original), return the name of the field.
sub field_name {
    my ( $self, $num ) = @_;
    my $name = $self->{by_num}[$num]->get_name;
    croak("Don't know about field number $num")
        unless defined $name;
    return $name;
}

# Sort all the fields lexically by name and assign ascending numbers.
sub _assign_field_nums {
    my $self = shift;
    confess("Can't _assign_field_nums when from_file") if $self->{from_file};

    # assign field nums according to lexical order of field names
    @{ $self->{by_num} }
        = sort { $a->get_name cmp $b->get_name } values %{ $self->{by_name} };
    my $inc = 0;
    $_->set_field_num( $inc++ ) for @{ $self->{by_num} };
}

# Decode an existing .fnm file.
sub read_infos {
    my ( $self,    $instream ) = @_;
    my ( $by_name, $by_num )   = @{$self}{qw( by_name by_num )};

    # set flag indicating that this FieldInfos object has been read in
    $self->{from_file} = 1;

    # read in infos from stream
    my $num_fields     = $instream->lu_read('V');
    my @names_and_bits = $instream->lu_read( 'Ta' x $num_fields );
    my $field_num      = 0;
    while ( $field_num < $num_fields ) {
        my ( $name, $bits ) = splice( @names_and_bits, 0, 2 );
        my $info = KinoSearch1::Document::Field->new(
            field_num  => $field_num,
            name       => $name,
            indexed    => ( "$bits" & INDEXED ) eq INDEXED ? 1 : 0,
            vectorized => ( "$bits" & VECTORIZED ) eq VECTORIZED ? 1 : 0,
            fnm_bits   => $bits,
        );
        $by_name->{$name} = $info;
        # order of storage implies lexical order by name and field number
        push @$by_num, $info;
        $field_num++;
    }
}

# Write .fnm file.
sub write_infos {
    my ( $self, $outstream ) = @_;

    $outstream->lu_write( 'V', scalar @{ $self->{by_num} } );
    for my $finfo ( @{ $self->{by_num} } ) {
        $outstream->lu_write( 'Ta', $finfo->get_name, $finfo->get_fnm_bits, );
    }
}

# Merge two FieldInfos objects, redefining fields as necessary and generating
# new field numbers.
sub consolidate {
    my ( $self, @others ) = @_;
    my $infos = $self->{by_name};

    # Make *this* finfos the master FieldInfos object
    for my $other (@others) {
        while ( my ( $name, $other_finfo ) = each %{ $other->{by_name} } ) {
            if ( exists $infos->{$name} ) {
                $infos->{$name} = $other_finfo->breed_with( $infos->{$name} );
            }
            else {
                $infos->{$name} = $other_finfo->clone;
            }
        }
    }

    $self->_assign_field_nums;
}

# Generate a mapping of field numbers between two FieldInfos objects.  Should
# be called by the superset.
sub generate_field_num_map {
    my ( $self, $other ) = @_;
    my $map = '';
    for my $other_finfo ( @{ $other->{by_num} } ) {
        my $orig_finfo = $self->{by_name}{ $other_finfo->get_name };
        $map .= pack( 'I', $orig_finfo->get_field_num );
    }
    return KinoSearch1::Util::IntMap->new( \$map );
}

sub encode_fnm_bits {
    my ( undef, $field ) = @_;
    my $bits = "\0";
    for ($bits) {
        $_ |= INDEXED    if $field->get_indexed;
        $_ |= VECTORIZED if $field->get_vectorized;
        $_ |= OMIT_NORMS if $field->get_omit_norms;
    }
    return $bits;
}

sub decode_fnm_bits {
    my ( undef, $field, $bits ) = @_;
    $field->set_indexed(    ( $bits & INDEXED )    eq INDEXED );
    $field->set_vectorized( ( $bits & VECTORIZED ) eq VECTORIZED );
    $field->set_omit_norms( ( $bits & OMIT_NORMS ) eq OMIT_NORMS );
}

sub close { }

1;

__END__

==begin devdocs

==head1 NAME

KinoSearch1::Index::FieldInfos - track field characteristics

==head1 SYNOPSIS

    my $finfos = KinoSearch1::Index::FieldInfos->new;
    $finfos->read_infos($instream);

==head1 DESCRIPTION

A FieldInfos object tracks the characteristics of all fields in a given
segment.

KinoSearch1 counts on having field nums assigned to fields by lexically sorted
order of field names, but indexes generated by Java Lucene are not likely to
have this property. 

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut

