use strict;
use warnings;
no warnings 'uninitialized';

package Form::Diva;

our $VERSION='1.05';

# use Data::Printer;

# ABSTRACT: Generate HTML5 form label and input fields

use Storable 3.15 qw(dclone);

# The _option_id sub needs access to a variable for hashing the ids
# in use, even though it is initialized at the beginning of generate,
# it needs to exist outside of the generate subroutines scope
# and before before the _option_id sub is declared.
my %id_uq = ();
sub _clear_id_uq { %id_uq = () }

# our $id_base = 'formdiva_';

# True if all fields are used no more than once, if not it dies.
# Form::Diva->{FormHash} stores all the fields a duplicated fieldname
# would replace the previous value.
sub _field_once {
    my $self   = shift;
    my @fields = ( @{ $self->{FormMap} }, @{ $self->{HiddenMap} } );
    my %hash   = ();
    foreach my $field (@fields) {
        if ( $hash{ $field->{name} } ) {
            die "$field->{name} would appear more than once or "
                . "is in both hidden and visible field lists. Not "
                . "only would this cause strange behaviour in your form "
                . "but it could internally corrupt Form::Diva";
        }
        else { $hash{ $field->{name} } = 1; }
    }
    return 1;
}

sub _build_html_tag {
    my $self = shift;
    my $tag_name = shift;
    my %options = @_;
    my @attrs = grep { defined && length } @{ $options{attributes} // [] };

    my $output = join ' ', $tag_name, @attrs;
    $output = "<$output>";

    if (exists $options{content}) {
        $output .= join '', $options{content} // '', "</$tag_name>";
    }

    if (defined $options{prefix}) {
        $output = $options{prefix} . $output;
    }

    if (defined $options{suffix}) {
        $output .= $options{suffix};
    }

    return $output;
}

sub new {
    my $class = shift;
    my $self  = {@_};
    bless $self, $class;
    $self->{class} = $class;
    unless ( $self->{input_class} ) { die 'input_class is required.' }
    unless ( $self->{label_class} ) { die 'label_class is required.' }
    $self->{id_base} = length $self->{id_base} ? $self->{id_base} : 'formdiva_';
    ( $self->{HiddenMap}, my $HHash )
        = $self->_expandshortcuts( $self->{hidden} );
    ( $self->{FormMap}, my $FHash )
        = $self->_expandshortcuts( $self->{form} );
    $self->{FormHash} = { %{$HHash}, %{$FHash} };
    $self->_field_once;
    return $self;
}

sub clone {
    my $self  = shift;
    my $args  = shift;
    my $new   = {};
    my $class = 'Form::Diva';
    $new->{FormHash} = dclone $self->{FormHash};
    $new->{input_class}
        = $args->{input_class} ? $args->{input_class} : $self->{input_class};
    $new->{label_class}
        = $args->{label_class} ? $args->{label_class} : $self->{label_class};
    $new->{form_name}
        = $args->{form_name} ? $args->{form_name} : $self->{form_name};

    if ( $args->{neworder} ) {
        my @reordered = map { $new->{FormHash}->{$_} } @{ $args->{neworder} };
        $new->{FormMap} = \@reordered;
    }
    else { $new->{FormMap} = dclone $self->{FormMap}; }
    if ( $args->{newhidden} ) {
        my @hidden = map { $self->{FormHash}{$_} } @{ $args->{newhidden} };
        $new->{HiddenMap} = \@hidden;
    }
    else { $new->{HiddenMap} = dclone $self->{HiddenMap}; }
    bless $new, $class;
    $self->_field_once;
    return $new;
}

# specification calls for single letter shortcuts on all fields
# these all need to expand to the long form.
sub _expandshortcuts {
    my $self         = shift;
    my $FormMap      = shift;    # data passed to new
    my %DivaShortMap = (
        qw /
            n name t type i id e extra x extra l label p placeholder
            d default v values c class lc label_class /
    );
    my %DivaLongMap = map { $DivaShortMap{$_}, $_ } keys(%DivaShortMap);
    my $FormHash = {};
    foreach my $formfield ( @{$FormMap} ) {
        foreach my $tag ( keys %{$formfield} ) {
            if ( $DivaShortMap{$tag} ) {
                $formfield->{ $DivaShortMap{$tag} }
                    = delete $formfield->{$tag};
            }
        }
        unless ( $formfield->{type} ) { $formfield->{type} = 'text' }
        unless ( $formfield->{name} ) { die "fields must have names" }
        unless ( $formfield->{id} ) {
            $formfield->{id} = $self->{id_base} . $formfield->{name};
        }

        # dclone because otherwise it would be a ref into FormMap
        $FormHash->{ $formfield->{name} } = dclone $formfield;
    }
    return ( $FormMap, $FormHash );
}

sub input_class {
    my $self = shift;
    return $self->{input_class};
}

sub label_class {
    my $self = shift;
    return $self->{label_class};
}

# given a field returns either the default field class="string"
# or the field specific one
sub _class_input {
    my $self   = shift;
    my $field  = shift;
    my $fclass = $field->{class} || '';
    if   ($fclass) { return qq!class="$fclass"! }
    else           { return qq!class="$self->{input_class}"! }
}

sub _field_bits {
    my $self      = shift;
    my $field_ref = shift;
    my $data      = shift;
    my %in        = %{$field_ref};
    my %out       = ();
    my $fname     = $in{name};
    $out{extra} = $in{extra};    # extra is taken literally
    $out{input_class} = $self->_class_input($field_ref);
    $out{name}        = qq!name="$in{name}"!;
    $out{id}          = qq!id="$in{id}"!;

    if ( lc( $in{type} ) eq 'textarea' ) {
        $out{type}     = 'textarea';
        $out{textarea} = 1;
    }
    else {
        $out{type}     = qq!type="$in{type}"!;
        $out{textarea} = 0;
        if ( $in{type} eq 'hidden' ) { $out{hidden} = 1 }
    }
    if ( keys %{$data} ) {
        $out{placeholder} = '';
        $out{rawvalue} = $data->{$fname} || '';
    }
    else {
        if   ( $in{default} ) { $out{rawvalue} = $in{default}; }
        else                  { $out{rawvalue} = '' }
    }
    if ( $in{placeholder} ) {
        $out{placeholder} = qq!placeholder="$in{placeholder}"!;
    }
    else {
        $out{placeholder} = '';
    }

    $out{value} = qq!value="$out{rawvalue}"!;
    return %out;
}

sub _label {

    # an id does not get put in label because the spec does not say either
    # the id attribute or global attributes are supported.
    # http://www.w3.org/TR/html5/forms.html#the-label-element
    my $self  = shift;
    my $field = shift;

    return '' if exists $field->{label} && !defined $field->{label};

    my $label_class
        = $field->{label_class}
        ? $field->{label_class}
        : $self->{label_class};
    my $label_tag
        = exists $field->{label} ? $field->{label} || '' : ucfirst( $field->{name} );

    return $self->_build_html_tag('LABEL',
        attributes => [
            qq|for="$field->{id}"|,
            qq|id="$field->{id}_label"|,
            qq|class="$label_class"|,
        ],
        content => $label_tag
    );
}

sub _input {
    my $self  = shift;
    my $field = shift;
    my $data  = shift;
    my %B     = $self->_field_bits( $field, $data );
    my $input = '';
    if ( $B{textarea} ) {
        $input = $self->_build_html_tag('TEXTAREA',
            attributes => [
                $B{name},
                $B{id},
                $B{input_class},
                $B{placeholder},
                $B{extra},
            ],
            content => $B{rawvalue}
        );
    }
    else {
        $input = $self->_build_html_tag('INPUT',
            attributes => [
                $B{type},
                $B{name},
                $B{id},
                $B{input_class},
                $B{placeholder},
                $B{extra},
                $B{value},
            ],
        );
    }
    return $input;
}

sub _input_hidden {
    my $self  = shift;
    my $field = shift;
    my $data  = shift;
    my %B     = $self->_field_bits( $field, $data );

    #hidden fields don't get a class or a placeholder
    my $input = $self->_build_html_tag('INPUT',
        attributes => [
            qq|type="hidden"|,
            $B{name},
            $B{id},
            $B{extra},
            $B{value},
        ],
    );

    return $input;
}

# generates the id= for option items.
# uses global %id_uq to insure uniqueness in generated ids.
# It might be cleaner to make this a sub ref under _option_input
# and put the hash there too, but potentially the global hash
# protects against a wider (though unlikely) range of collisions,
# also putting the code_ref in _option_id would make it that much longer.
sub _option_id {
    my $self  = shift;
    my $id    = shift;
    my $value = shift;
    my $idv   = $id . '_' . lc($value);
    $idv =~ s/\s+/_/g;
    while ( defined $id_uq{$idv} ) {
        $id_uq{$idv}++;
        $idv = $idv . $id_uq{$idv};
    }
    $id_uq{$idv} = 1;
    return "id=\"$idv\"";
}

sub _option_input {    # field, input_class, data;
    my $self           = shift;
    my $field          = shift;    # field definition from FormMap or FormHash
    my $data           = shift;    # data for this form field
    my $replace_fields = shift;    # valuelist to use instead of default
    my $datavalue   = $data->{ $field->{name} };
    my $output      = '';
    my $input_class = $self->_class_input($field);
    my $extra       = $field->{extra} || "";

    # in case default is 0, it must be checked in a string context
    my $default = length( $field->{default} )
        ? do {
        if   ( keys %{$data} ) {undef}
        else                   { $field->{default} }
        }
        : undef;
    my @values
        = $replace_fields
        ? @{$replace_fields}
        : @{ $field->{values} };
    if ( $field->{type} eq 'select' ) {
        my @options;
        foreach my $val (@values) {
            my ( $value, $v_lab ) = ( split( /\:/, $val ), $val );
            my $idf = $self->_option_id( $field->{id}, $value );
            my $selected = '';
            if    ( $datavalue eq $value ) { $selected = 'selected' }
            elsif ( $default eq $value )   { $selected = 'selected' }

            push @options, $self->_build_html_tag('option',
                attributes => [
                    qq|value="$value"|,
                    $idf,
                    $selected,
                ],
                content => $v_lab,
                prefix => ' ',
                suffix => "\n",
            );
        }

        $output = $self->_build_html_tag('SELECT',
            attributes => [
                qq|name="$field->{name}"|,
                qq|id="$field->{id}"|,
                $extra,
                $input_class
            ],
            # NOTE: add an empty line before first option
            content => (join '', "\n", @options),
        );
    }
    else {
        my @options;
        foreach my $val (@values) {
            my ( $value, $v_lab ) = ( split( /\:/, $val ), $val );
            my $idf = $self->_option_id( $field->{id}, $value );
            my $checked = '';
            if ( $datavalue eq $value ) {
                $checked = q !checked="checked"!;
            }
            elsif ( $default eq $value ) {
                $checked = q !checked="checked"!;
            }
            push @options, $self->_build_html_tag('input',
                attributes => [
                    qq|type="$field->{type}"|,
                    $input_class,
                    $extra,
                    qq|name="$field->{name}"|,
                    $idf,
                    qq|value="$value"|,
                    $checked
                ],
                suffix => "$v_lab<br>\n"
            );
        }

        $output = join '', @options;
    }
    return $output;
}

# check if $data is a hashref or a dbic result row and inflate it.
sub _checkdatadbic {
    my $data = shift;
    if ( ref $data eq 'HASH' ) { return $data }
    elsif ( eval { $data->isa('DBIx::Class::Row') } ) {
        return { $data->get_inflated_columns };
    }
    else { return {} }
}

sub generate {
    my $self      = shift @_;
    my $data      = _checkdatadbic( shift @_ );
    my $overide   = shift @_;
    my @generated = ();
    $self->_clear_id_uq;    # needs to be empty when form generation starts.
    foreach my $field ( @{ $self->{FormMap} } ) {
        my $input = undef;
        if (   $field->{type} eq 'radio'
            || $field->{type} eq 'checkbox'
            || $field->{type} eq 'select' )
        {
            $input
                = $self->_option_input( $field, $data,
                $overide->{ $field->{name} },
                );
        }
        else {
            $input = $self->_input( $field, $data );
        }
        push @generated,
            {
            label   => $self->_label($field),
            input   => $input,
            comment => $field->{comment},
            };
    }
    return \@generated;
}

sub prefill {
    my $self       = shift @_;
    my $data       = _checkdatadbic( shift @_ );
    my $overide    = shift @_;
    my $oriFormMap = dclone $self->{FormMap};
    foreach my $item ( @{ $self->{FormMap} } ) {
        my $iname = $item->{name};
        if ( $data->{$iname} ) {
            $item->{default} = $data->{$iname};
        }
    }
    my $generated = $self->generate( undef, $overide );
    $self->{FormMap} = $oriFormMap;
    return $generated;
}

sub hidden {
    my $self   = shift;
    my $data   = _checkdatadbic( shift @_ );
    my $output = '';
    foreach my $field ( @{ $self->{HiddenMap} } ) {
        $output .= $self->_input_hidden( $field, $data ) . "\n";
    }
    return $output;
}


    # my $data      = _checkdatadbic( shift @_ );
    # my $overide   = shift @_;
    # my @generated = ();

sub datavalues {
    my $self      = shift;
    my $data      = _checkdatadbic( shift @_ );
    my $skipempty = 0;
    my $moredata  = 0;
    for (@_) {
        if ( $_ eq 'skipempty' ) { $skipempty = 1 }
        if ( $_ eq 'moredata' )  { $moredata  = 1 }
    }
    my @datavalues = ();
PLAINLOOP:
    foreach my $field ( @{ $self->{FormMap} } ) {
        if ($skipempty) {
            unless ( $data->{ $field->{name} } ) { next PLAINLOOP }
        }
        my %row = (
            name    => $field->{name},
            type    => $field->{type},
            value   => $data->{ $field->{name} },
            comment => $field->{comment},
        );
        $row{label}
            = exists $field->{label} ? $field->{label} || '' : ucfirst( $field->{name} );
        $row{id} = $field->{id}
            ; # coverage testing deletion ? $field->{id} : 'formdiva_' . $field->{name};
        if ($moredata) {
            $row{extra}       = $field->{extra};
            $row{values}      = $field->{values};
            $row{default}     = $field->{default};
            $row{placeholder} = $field->{placeholder};
            $row{class}
                = $field->{class} ? $field->{class} : $self->{input_class};

        }
        push @datavalues, \%row;
    }
    return \@datavalues;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Diva - Generate HTML5 form label and input fields

=head1 VERSION

version 1.05

=head1 AUTHOR

John Karr <brainbuz@brainbuz.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by John Karr.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
