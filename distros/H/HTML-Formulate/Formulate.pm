package HTML::Formulate;

use 5.005;
use HTML::Tabulate 0.39;
use HTML::Entities qw(encode_entities);
use Carp;
use strict;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(HTML::Tabulate Exporter);
@EXPORT = qw(&render);
@EXPORT_OK = qw(&render);
%EXPORT_TAGS = ();

$VERSION = '0.20';

# Additional valid arguments, fields, and field attributes to those of
#   HTML::Tabulate
my %VALID_ARG = (
    # form: form tag attribute/value hash, or boolean scalar
    form => 'HASH/SCALAR',
    # formtype: form/table
    formtype => 'SCALAR',
    # primkey: primary key field, or list of primary key fields (for composites)
#   primkey => 'SCALAR/ARRAY',
    # submit: list of submit/button/reset elements for form
    submit => 'SCALAR/ARRAY',
    # submit_location: location of submit elements - top/bottom/both, default: bottom
    submit_location => 'SCALAR',
    # hidden: list of fields to render as hiddens, or hashref of field/value 
    #   pairs; default: none
    hidden => 'ARRAY/HASH',
    # required: list of required/mandatory fields, or tokens 'ALL' or 'NONE'
    required => 'ARRAY/SCALAR',
    # use_name_as_id: add 'name' as 'id' field to input-type fields if none set
    use_name_as_id => 'SCALAR',
    # errors: hashref of field => (scalar/array of) validation-error-messages
    errors => 'HASH',
    # errors_where: where to display validation error messages:
    #   top: above form table (default)
    #   column: within form table, in a third table column
    errors_where => 'SCALAR',
    # errors_format: subroutine to format/render 'top' style error messages
    errors_format => 'SCALAR/CODE',
);
my %VALID_FIELDS = (
    # primary key defaults (deprecated?)
#   -primkey => 'HASH',
    # select defaults
    '-select' => 'HASH',
    # submit button defaults
    -submit => 'HASH',
    # required fields defaults
    -required => 'HASH',
    # error field defaults
    -errors => 'HASH',
);
my %FIELD_ATTR = (
    # type: how this field is rendered on the form (roughly an <input /> type)
#   type => [ qw(text textarea password select hidden display static omit)],
    type => [ qw(text textarea password file image button select checkbox radio hidden display static omit)],
    # datatype: the validation datatype for this field (deprecated?)
#   datatype => 'SCALAR/ARRAY',
    # required: boolean
    required => 'SCALAR',
    # values: a list of possible values (scalars) for selects or radio buttons
    'values' => 'ARRAY/CODE',
    # vlabels: a list (or hashref keyed by values entries) of labels for use 
    #   with selects or radio buttons
    vlabels => 'ARRAY/HASH/CODE',
);
# Attributes applicable to the various input-type fields
my %TEXT_ATTR = map { $_ => 1 } qw(accesskey disabled id maxlength name notab onblur onchange onclick onfocus onselect readonly selected size tabindex taborder value vlabel);
my %INPUT_ATTR = map { $_ => 1 } qw(accesskey checked disabled id name notab onblur onchange onclick onfocus onselect readonly selected size tabindex taborder value vlabel);
my %SELECT_ATTR = map { $_ => 1 } qw(disabled id multiple name onblur onchange onfocus size tabindex vlabel);
my %TEXTAREA_ATTR = map { $_ => 1 } qw(accesskey cols disabled id name onblur onchange onfocus onselect readonly rows tabindex vlabel wrap);
my %TABLE_ATTR = map { $_ => 1 } qw(tr th td);
my %EMPTY_TAGS = map { $_ => 1 } qw(input br);

sub get_valid_arg
{
    my $self = shift;
    my %arg = $self->SUPER::get_valid_arg();
    return wantarray ? ( %arg, %VALID_ARG ) : { %arg, %VALID_ARG };
}
sub get_valid_fields
{
    my $self = shift;
    my %arg = $self->SUPER::get_valid_fields();
    return wantarray ? ( %arg, %VALID_FIELDS ) : { %arg, %VALID_FIELDS };
}
sub get_field_attributes
{
    my $self = shift;
    my %attr = $self->SUPER::get_field_attributes();
    @attr{ keys %FIELD_ATTR } = values %FIELD_ATTR;
    return wantarray ? %attr : \%attr;
}


# -------------------------------------------------------------------------
# Merge in form base defaults
#
sub init
{
    my $self = shift;
    my $defn = shift;

    # Munge form => 1 to form => {} for cleaner merging
    $defn->{form} = {} if $defn->{form} && ! ref $defn->{form};

    $defn = $self->merge({
        form => { method => 'post' },
        formtype => 'form',
        table => { cellpadding => '2' },
        style => 'across',
        labels => 1,
        hidden => {},
        xhtml => 1,
        use_name_as_id => 0,
        null => '&nbsp;',
        errors_where => 'top',
        errors_format => sub {
          return qq(<p style="color:red;font-weight:bold">\n<span class="error">) .
            join(qq(</span><br />\n<span class="error">), @_) . 
                 qq(</span>\n</p>\n);
        },
#       errors_format => sub {
#         return qq(<p style="color:red;font-weight:bold">\n<span class="error">) .
#           join(qq(</span><br />\n<span class="error">), @_) . 
#                qq(</span>\n</p>\n);
#       },
        field_attr => {
          -select => { size => undef },
          -submit => { maxlength => undef, size => undef },
          -required => { 
            th => { style => 'color:blue' },
            label_format => '<span class="required">%s</span>'
          },
#         -required => { label_format => '%s [*]' },
          -errors => { 
            th => { style => 'color:red' },
            label_format => '<span class="error_field">%s</span>',
#           td_error => { style => 'color:red;font-weight:bold' },
            td_error => { class => 'error' },
          },
        },
    }, $defn) unless $defn->{formtype} && $defn->{formtype} eq 'table';

    return $self->SUPER::init($defn);
}

#
# Further split tx_attr into tx_attr and input_attr
sub cell_split_out_tx_attr
{
    my $self = shift;
    my ($field) = @_;

    $self->SUPER::cell_split_out_tx_attr(@_);

    for my $attr (qw(label_attr tfoot_attr data_attr)) {
        my $type = $self->{defn_t}->{$attr}->{$field}->{type} || '';
        $self->{defn_t}->{$attr}->{$field}->{input_attr} = {};

        for (keys %{ $self->{defn_t}->{$attr}->{$field}->{tx_attr} }) {
            # Attributes like input_class will be mapped as input.class
            if (m/^input_/) {
                my $val = delete $self->{defn_t}->{$attr}->{$field}->{tx_attr}->{$_};
                s/^input_//;
                $self->{defn_t}->{$attr}->{$field}->{input_attr}->{$_} = $val;
            }
            elsif ($TEXT_ATTR{$_} || $TEXTAREA_ATTR{$_} || $SELECT_ATTR{$_}) {
                my $val = delete $self->{defn_t}->{$attr}->{$field}->{tx_attr}->{$_};

                if ($type eq 'select') {
                    $self->{defn_t}->{$attr}->{$field}->{input_attr}->{$_} = $val
                        if $SELECT_ATTR{$_};
                }
                elsif ($type eq 'textarea') {
                    $self->{defn_t}->{$attr}->{$field}->{input_attr}->{$_} = $val
                        if $TEXTAREA_ATTR{$_};
                }
                elsif (! $type ||
                         $type eq 'text' ||
                         $type eq 'password') {
                    $self->{defn_t}->{$attr}->{$field}->{input_attr}->{$_} = $val
                        if $TEXT_ATTR{$_};
                }
                else {
                    $self->{defn_t}->{$attr}->{$field}->{input_attr}->{$_} = $val
                        if $INPUT_ATTR{$_};
                }
            }
        }
    }
}

# One-off or dataset-specific presentation definition munging
sub prerender_munge
{
    my $self = shift;

    # Call SUPER version first
    $self->SUPER::prerender_munge(@_);

    my $defn_t = $self->{defn_t};
    if ($defn_t->{formtype} eq 'table') {
        delete $defn_t->{form};
        return;
    }

    # Map top-level 'hidden' arrayref/hashref into fields
    if (ref $defn_t->{hidden} eq 'HASH') {
        for my $hidden (keys %{$defn_t->{hidden}}) {
            $defn_t->{field_attr}->{$hidden} ||= {};
            $defn_t->{field_attr}->{$hidden}->{type} = 'hidden';
            push @{$defn_t->{fields}}, $hidden 
                unless grep /^$hidden$/, @{$defn_t->{fields}};
        }
    }
    elsif (ref $defn_t->{hidden} eq 'ARRAY') {
        for my $hidden (@{$defn_t->{hidden}}) {
            $defn_t->{field_attr}->{$hidden} ||= {};
            $defn_t->{field_attr}->{$hidden}->{type} = 'hidden';
            push @{$defn_t->{fields}}, $hidden 
                unless grep /^$hidden$/, @{$defn_t->{fields}};
        }
        # Reset to hashref
        $defn_t->{hidden} = {};
    }
    # Map top-level 'required' array into fields
    my $required = $defn_t->{required};
    if ($required && ! ref $required && $required =~ m/^(ALL|NONE)$/) {
      if ($required eq 'NONE') {
          $defn_t->{required} = $required = [];
      }
      elsif ($defn_t->{fields} && ref $defn_t->{fields} eq 'ARRAY') {
          $defn_t->{required} = $required = [ @{$defn_t->{fields}} ];
      }
    }
    elsif ($required && ! ref $required) {
      $defn_t->{required} = $required = [ $required ];
    }
    if ($required && ref $required eq 'ARRAY') {
        for (@$required) {
            $defn_t->{field_attr}->{$_} ||= {};
            $defn_t->{field_attr}->{$_}->{required} = 1;
        }
    }

    # Add default submit if fields
    $defn_t->{submit} = [ 'submit' ] 
        if exists $defn_t->{fields} && ! exists $defn_t->{submit};

    # Reset errors_where unless we have error_messages
    my $error_messages = 0;
    if ($self->{defn_t}->{errors}) {
        for (keys %{$self->{defn_t}->{errors}}) {
            $error_messages = 1, last 
                if $self->{defn_t}->{errors}->{$_} ne '';
        }
        $self->{defn_t}->{errors_where} = 'column'
            if $error_messages && 
               $self->{defn_t}->{errors_where} !~ m/^(column|top)$/;
    }
    $self->{defn_t}->{errors_where} = '' unless $error_messages;

    # Default primkey to first field if not set
#   $defn->{primkey} = $defn->{fields}->[0]
#        if ! $defn->{primkey} && 
#             $defn->{fields} && ref $defn->{fields} eq 'ARRAY';

    # Default primkey type to 'static' if not set
#   my $primkey = $defn->{primkey};
#   if ($primkey) {
#       $defn->{field_attr}->{$primkey} ||= {};
#       $defn->{field_attr}->{$primkey}->{type} = 'static'
#            if $primkey && ! $defn->{field_attr}->{$primkey}->{type};
#   }
}


# -------------------------------------------------------------------------
# Override start_tag to add explicit 'id' fields if use_name_as_id is set
#
sub start_tag
{
    my ($self, $tag, $attr, $close, $extra) = @_;
    if ($self->{defn_t}->{use_name_as_id} && 
        $tag =~ qr/^(input|select|textarea)$/ && 
        exists $attr->{name}) {
      $attr->{id} ||= $attr->{name};
    }
    if ($attr->{value}) {
        $attr->{value} = $self->_escape_value($attr->{value}, $extra->{escape});
    }
    return $self->SUPER::start_tag($tag, $attr, $close, $extra);
}

# -------------------------------------------------------------------------
# Render cells as appropriate input type etc.
#
sub cell_content
{
    my $self = shift;
    my ($row, $field, $fattr) = @_;
    $fattr ||= $self->{defn_t}->{field}->{$field} || {};
    $fattr->{type} ||= 'text' if $row;
    my $extra = { escape => $fattr->{escape} };

    # No special handling required for labels or 'table' forms or composites
    if (! defined $row or 
           $self->{defn_t}->{formtype} eq 'table' or 
           $fattr->{composite}) {
        my ($fvalue, $value) = $self->SUPER::cell_content(@_);
        # Cache label values for later e.g. error_messages
        $self->{defn_t}->{_labels}->{$field} = $value if ! defined $row;
        return wantarray ? ($fvalue, $value) : $fvalue;
    }

    # Call the parent cell_value to get the data value to use
    my $value = $self->SUPER::cell_value(@_);
    undef $value 
        if defined $self->{defn_t}->{null} && $value eq $self->{defn_t}->{null};
    undef $value if defined $value && $value eq '';

    # Create <input> (etc.) fields
    my $out = '';
    my $selected_value = $self->{defn_t}->{xhtml} ? 'selected' : '';
    delete $fattr->{value} 
        if defined $self->{defn_t}->{null} && defined $fattr->{value} &&
            $fattr->{value} eq $self->{defn_t}->{null};
    if ($fattr->{type} eq 'static' || $fattr->{type} eq 'display') {
        if ($fattr->{vlabel}) {
          if (ref $fattr->{vlabel}) {
            if (ref $fattr->{vlabel} eq 'CODE') {
              $out .= $fattr->{vlabel}->($value, $row, $field);
            }
          }
          else {
            $out .= sprintf $fattr->{vlabel}, $value;
          }
        }
        else {
          $out .= $self->_escape_value($value, $fattr->{escape});
        }
        delete $fattr->{vlabel};
        $out .= $self->start_tag('input', 
            { type => 'hidden', name => $field, value => $value }, 'close', $extra)
            if $fattr->{type} eq 'static';
    }
    # Select fields
    elsif ($fattr->{type} eq 'select') {
        my $values = $fattr->{values};
        # Allow code on values
        if (ref $values eq 'CODE') {
            my @values = $values->($field, $row);
            $values = @values == 1 && ref $values[0] ? $values[0] : \@values;
        }
        if (ref $values eq 'ARRAY' && @$values) {
            $out .= $self->start_tag('select', 
                { %{$fattr->{input_attr}}, name => $field }, 0, $extra);
            my $vlabels = $fattr->{vlabels} || {};
            # Iterate over values, creating options
            for (my $i = 0; $i <= $#$values; $i++) {
                my $v = $values->[$i];
                my $oattr = {};
                $oattr->{value} = $v if defined $v;
                if (defined $value) {
                    # Multi-values make sense in select contexts
                    if (ref $value eq 'ARRAY') {
                        $oattr->{selected} = $selected_value if grep { $v eq $_ } @$value;
                    } else {
                        $oattr->{selected} = $selected_value if $v eq $value;
                    }
                }
                $out .= $self->start_tag('option', $oattr, 0, $extra);
                my $vlabel = '';
                if (ref $vlabels eq 'CODE') {
                    # Two styles are supported for vlabel subroutines - the sub
                    # can either just return a single label based on the given
                    # value, or the first invocation can return an arrayref or
                    # hashref containing the whole set of labels
                    my @vlabels = $vlabels->($v, $field, $row);
                    $vlabel = @vlabels == 1 ? $vlabels[0] : \@vlabels;
                    # Replace vlabels if arrayref or hashref returned
                    if (ref $vlabel) {
                        $vlabels = $vlabel;
                        $vlabel = '';
                    }
                }
                if (ref $vlabels eq 'HASH') {
                    $vlabel = $vlabels->{$v};
                }
                elsif (ref $vlabels eq 'ARRAY') {
                    $vlabel = $vlabels->[$i];
                }
                $vlabel = $v if ! defined $vlabel;

                $out .= $vlabel;
                $out .= $self->end_tag('option');
            }
            $out .= $self->end_tag('select');
        }
    }
    # Radio fields
    elsif ($fattr->{type} eq 'radio') {
        my $values = $fattr->{values};
        # Allow code on values
        if (ref $values eq 'CODE') {
            my @values = $values->($field, $row);
            $values = @values == 1 && ref $values[0] ? $values[0] : \@values;
        }
        if (ref $values eq 'ARRAY' && @$values) {
#           $out .= $self->start_tag('select', 
#               { %{$fattr->{input_attr}}, name => $field });
            my $vlabels = $fattr->{vlabels} || {};
            # Iterate over values
            my @out = ();
            for (my $i = 0; $i <= $#$values; $i++) {
                my $v = $values->[$i];
                my $oattr = {};
                $oattr->{value} = $v if defined $v;
                if (defined $value) {
                    # Multi-values make sense in select contexts
                    if (ref $value eq 'ARRAY') {
                        $oattr->{selected} = $selected_value if grep { $v eq $_ } @$value;
                    } else {
                        $oattr->{selected} = $selected_value if $v eq $value;
                    }
                }
                my $input = $self->start_tag('input', {
                    %{$fattr->{input_attr}}, name => $field, type => 'radio', 
                    ($self->{defn_t}->{use_name_as_id} ? (id => "${field}_$i") : ()),
                    (defined $v ? (value => $v) : ()),
                    (defined $value && ! ref $value && defined $v && $v eq $value
                        ? (checked => 'checked') 
                        : ()),
                }, 'close', $extra);
                my $vlabel = '';
                if (ref $vlabels eq 'CODE') {
                    # Two styles are supported for vlabel subroutines - the sub
                    # can either just return a single label based on the given
                    # value, or the first invocation can return an arrayref or
                    # hashref containing the whole set of labels
                    my @vlabels = $vlabels->($v, $field, $row);
                    $vlabel = @vlabels == 1 ? $vlabels[0] : \@vlabels;
                    # Replace vlabels if arrayref or hashref returned
                    if (ref $vlabel) {
                        $vlabels = $vlabel;
                        $vlabel = '';
                    }
                }
                if (ref $vlabels eq 'HASH') {
                    $vlabel = $vlabels->{$v};
                }
                elsif (ref $vlabels eq 'ARRAY') {
                    $vlabel = $vlabels->[$i];
                }
                $vlabel = $v if ! defined $vlabel or $vlabel eq '';

                # TODO: need a way of controlling the format used here
                push @out, "$vlabel&nbsp;$input";
            }
            # TODO: need a way of designating the join here too
            $out .= join('  ', @out);
        }
    }
    # Hidden fields
    elsif ($fattr->{type} eq 'hidden') {
        $out .= $self->start_tag('input', 
            { type => 'hidden', name => $field, value => $value }, 'close', $extra);
    }
    # Textareas
    elsif ($fattr->{type} eq 'textarea') {
        $out .= $self->start_tag('textarea',
            { %{$fattr->{input_attr}}, name => $field, }, 0, $extra);
        $out .= $self->_escape_value($value, $fattr->{escape});
        $out .= $self->end_tag('textarea');
    }
    # Input fields
    else {
        $out .= $self->start_tag('input',
             { %{$fattr->{input_attr}},  name => $field, 
               type => $fattr->{type}, value => $value }, 'close', $extra);
    }

    # Now format using $out as value
    return $self->SUPER::cell_format($out, $fattr, $row, $field);
}

sub _escape_value
{
    my ($self, $data, $escape) = @_;
    $escape = 1 if ! defined $escape;
    if ($data && $escape) {
      $data = encode_entities($data);
    }
    return $data;
}

# Derived cell_format_escape - noop here
# We escape values in start_tag, and tag body value in cell_content
sub cell_format_escape
{
    my ($self, $data) = @_;
    return $data;
}

# Derived cell_format_link - ignore links except for display fields
sub cell_format_link
{
    my $self = shift;
    my ($data, $fattr, $row, $field, $data_unformatted) = @_;
    return $data if $fattr->{type} && $fattr->{type} ne 'display';
    return $self->SUPER::cell_format_link(@_);
}

# Derived cell_tags, for special handling of hiddens
sub cell_tags
{
    my $self = shift;
    my ($data, $row, $field, $tx_attr) = @_;

    # Default handling for 'table' forms
    return $self->SUPER::cell_tags(@_) 
        if $self->{defn_t}->{formtype} eq 'table';

    # Default handling if not a 'hidden'
    my $type = $self->{defn_t}->{field_attr}->{$field}->{type};
    return $self->SUPER::cell_tags(@_) 
        unless $type && $type eq 'hidden';

    return $data;
}

# Merge in extra default sets: -submit for submit fields, -required for 
#   required fields, -errors for fields with errors
sub cell_merge_extras
{
    my $self = shift;
    my ($row, $field) = @_;
    my %extra = ();
   
    # Hack: -submit => { table => 0 } is used to signal external submits
    if (ref $self->{defn_t}->{field_attr}->{-submit} eq 'HASH' &&
        exists $self->{defn_t}->{field_attr}->{-submit}->{table}) {
        $self->{defn_t}->{submit_table} = $self->{defn_t}->{field_attr}->{-submit}->{table};
        delete $self->{defn_t}->{field_attr}->{-submit}->{table};
    }

    # -select fields
    @extra{keys %{$self->{defn_t}->{field_attr}->{-select}}} =
         values %{$self->{defn_t}->{field_attr}->{-select}}
        if $self->{defn_t}->{field_attr}->{-select} &&
           ref $self->{defn_t}->{field_attr}->{-select} eq 'HASH' &&
               $self->{defn_t}->{field_attr}->{$field}->{type} &&
               $self->{defn_t}->{field_attr}->{$field}->{type} eq 'select';

    # -submit fields
    @extra{keys %{$self->{defn_t}->{field_attr}->{-submit}}} =
         values %{$self->{defn_t}->{field_attr}->{-submit}}
        if $self->{defn_t}->{field_attr}->{-submit} &&
           ref $self->{defn_t}->{field_attr}->{-submit} eq 'HASH' &&
               $self->{defn_t}->{submit_hash}->{$field};

    # -required fields
    @extra{keys %{$self->{defn_t}->{field_attr}->{-required}}} =
         values %{$self->{defn_t}->{field_attr}->{-required}}
        if $self->{defn_t}->{field_attr}->{-required} &&
           $self->{defn_t}->{field_attr}->{$field}->{required};

    # -errors fields
    @extra{keys %{$self->{defn_t}->{field_attr}->{-errors}}} =
         values %{$self->{defn_t}->{field_attr}->{-errors}}
        if $self->{defn_t}->{field_attr}->{-errors} &&
            exists $self->{defn_t}->{errors}->{$field};

    return %extra;
}

# Extract per-field table attribute definitions (tr, th, td, td_error)
sub extract_field_table_attr 
{
    my $self = shift;
    my ($td_attr, $th_attr) = @_;
    $td_attr ||= {};
    $th_attr ||= {};

    my $tr_attr = $self->{defn_t}->{tr} || {};
    if ($td_attr->{tr} && ref $td_attr->{tr} eq 'HASH') {
        $tr_attr = { %$tr_attr, %{$td_attr->{tr}} };
        delete $td_attr->{tr};
    }
    if ($td_attr->{th} && ref $td_attr->{th} eq 'HASH') {
        $th_attr = { %$th_attr, %{$td_attr->{th}} };
        delete $td_attr->{th};
    }
    if ($td_attr->{td} && ref $td_attr->{td} eq 'HASH') {
        $td_attr = { %$td_attr, %{$td_attr->{td}} };
        delete $td_attr->{td};
    }
    # 'td_error' components are only applied to (column) error messages
    my $error_td_attr;
    if ($td_attr->{td_error} && ref $td_attr->{td_error} eq 'HASH') {
        my $td = $td_attr->{td_error};
        delete $td_attr->{td_error};
        $error_td_attr = { %$td_attr, %$td }
            if $self->{defn_t}->{errors_where} eq 'column';
    }

    return $tr_attr, $td_attr, $th_attr, $error_td_attr;
}

# Derived row_across, for special handling of hiddens
sub row_across 
{   
    my $self = shift;
    my ($data, $rownum, $field) = @_;

    # Default handling for 'table' forms
    return $self->SUPER::row_across(@_) 
        if $self->{defn_t}->{formtype} eq 'table';

    # Need to call cell_merge_defaults early, since there may be 
    # settings that affect the whole row (single row table assumed)
    $self->cell_merge_defaults($rownum, $field);
    my $lattr = $self->{defn_t}->{label_attr}->{$field};
    my $th_attr = $lattr->{tx_attr};
    my $fattr = $self->{defn_t}->{data_attr}->{$field};
    my $td_attr = $fattr->{tx_attr};

    # Special handling for 'hidden' and 'omit' fields
    my $type = $fattr->{type} || '';
    if ($type eq 'hidden') {
        # Don't render - just update top-level hidden hashref
        my $value = $self->{defn_t}->{hidden}->{$field};
        $self->{defn_t}->{hidden}->{$field} = $self->SUPER::cell_content(
            $data->[0], $field, $fattr)
                unless defined $value;
        # Reset null-ified values
        $self->{defn_t}->{hidden}->{$field} = '' 
            if $self->{defn_t}->{hidden}->{$field} eq $self->{defn_t}->{null};
        return '';
    }
    elsif ($type eq 'omit') {
        return '';
    }

    my ($tr_attr, $error_td_attr);
    ($tr_attr, $td_attr, $th_attr, $error_td_attr) = 
        $self->extract_field_table_attr($td_attr, $th_attr); 

    my @format = ();
    my @value = ();
    my $th_colspan = 1;
    if ($self->{defn_t}->{labels}) {
      push @format, $self->cell(undef, $field, $lattr, $th_attr);
      push @value,  $self->cell(undef, $field, $lattr, $th_attr, tags => 0);
      $th_colspan = $th_attr->{colspan} || 1;
    }
    # Omit data field if th_colspan >= 2
    if ($th_colspan < 2) {
      push @format, $self->cell($data->[0], $field, $fattr, $td_attr);
      push @value,  $self->cell($data->[0], $field, $fattr, $td_attr, tags => 0);
    }
    # Column errors
    if ($self->{defn_t}->{errors_where} eq 'column') {
        my $error = ref $self->{defn_t}->{errors}->{$field} eq 'ARRAY' ?
            join ("<br />", 
                map { sprintf $_, $self->{defn_t}->{_labels}->{$field} } 
                    @{$self->{defn_t}->{errors}->{$field}}) :
            sprintf($self->{defn_t}->{errors}->{$field} || '&nbsp;',
                $self->{defn_t}->{_labels}->{$field});
        push @format, $self->cell_tags($error, 1, $field, $error_td_attr);
    }

    # Generate output
    $tr_attr = { %$tr_attr, %{ $self->tr_attr($rownum, \@value, $data) } };
    my $row = $self->start_tag('tr', $tr_attr);
    $row .= join '', @format;
    $row .= $self->end_tag('tr', $tr_attr) . "\n";

    return $row;
}

# Override body_across to avoid automatic field derivation
sub body_across
{
    my $self = shift;
    my $fields = $self->{defn_t}->{fields};
    return '' unless $fields && ref $fields eq 'ARRAY' && @$fields;
    $self->SUPER::body_across(@_);
}

# Output hidden fields
sub hidden
{
    my $self = shift;
    my $out = '';
    if (ref $self->{defn_t}->{hidden} eq 'HASH') {
        for my $name (sort keys %{$self->{defn_t}->{hidden}}) {
            $out .= $self->start_tag('input', { 
                type => 'hidden', name => $name, 
                value => $self->{defn_t}->{hidden}->{$name},
            }, 'close');
            $out .= "\n";
        }
    }
    return $out;
}

# Display submit etc. buttons
sub submit
{
    my $self = shift;
    my %arg = @_;

    my $out = '';
    my $defn = $self->{defn_t};
    return '' unless $defn->{submit};

    # Map scalars to array (and submit => 1 == submit => 'submit')
    $defn->{submit} = [ $defn->{submit} == 1 ? 'submit' : $defn->{submit} ]
        if ! ref $defn->{submit};
    $defn->{submit_hash} = { map { $_ => 1 } @{$defn->{submit}} };

    # Build submit buttons input fields
    my ($tr_attr, $td_attr);
    for my $field (@{$defn->{submit}}) {
        $self->cell_merge_defaults(1, $field);
        my $fattr = $self->{defn_t}->{data_attr}->{$field};
        my $td = $fattr->{tx_attr};
        my $tr;
        ($tr, $td) = $self->extract_field_table_attr($td);
        # Save tr/td attributes from first submit
        if (! $defn->{submit_attr}) {
            $defn->{submit_attr} = {
                tr_attr => $tr,
                td_attr => $td,
            };
        }
        $tr_attr = $defn->{submit_attr}->{tr_attr};
        $td_attr = $defn->{submit_attr}->{td_attr};
        my $field_id = lc $field;
        $field_id =~ s/\s+/_/g;
        my $field_value = $fattr->{value} || $fattr->{label} || 
          join(' ', map { ucfirst } split /\s+/, $field);
        $out .= $self->start_tag('input', {
          type => 'submit', name => $field_id, id => $field_id, value => $field_value,
          %{$fattr->{input_attr}}
        }, 'close');
        $out .= "\n";
    }

    # Build submit line
    if ($arg{table}) {
        my $cols = 2;
        $cols++ if $defn->{errors_where} && $defn->{errors_where} eq 'column';
        $cols-- if ! $self->{defn_t}->{labels};
        my %colspan = $cols > 1 ? ( colspan => $cols ) : ();
        $tr_attr = { %$tr_attr, %{$self->tr_attr(1, [ 'Submit', $out ])} };
        return $self->start_tag('tr', $tr_attr) .
               $self->start_tag('td', { %colspan, align => 'center', %$td_attr }) . "\n" .
               $out .
               $self->end_tag('td') . 
               $self->end_tag('tr') . "\n";
    }
    else {
        return $self->start_tag('p', $td_attr) . "\n" .
               $out . 
               $self->end_tag('p') . "\n";
    }
}

# Format error messages using errors_format
sub top_errors
{
    my $self = shift;
    my $defn_t = $self->{defn_t};

    return '' unless $defn_t->{errors_format};

    # Fields and labels should always be defined by this point
    my %errors = %{$defn_t->{errors}};
    my @errors;
    # Report errors in field order
    for my $field (@{$defn_t->{fields}}) {
        if ($errors{$field}) {
            if (ref $errors{$field} eq 'ARRAY') {
                for my $err (@{$errors{$field}}) {
                    push @errors, sprintf($err, $defn_t->{_labels}->{$field});
                }
            }
            else {
                push @errors, sprintf($errors{$field}, $defn_t->{_labels}->{$field});
            }
            delete $errors{$field};
        }
    }
    # Report any remaining (presumably non-field-specific) errors
    for my $extra (sort keys %errors) {
        if (ref $errors{$extra} eq 'ARRAY') {
            push @errors, sprintf($_, $extra) foreach @{$errors{$extra}};
        }
        else {
            push @errors, sprintf($errors{$extra}, $extra);
        }
    }
    return '' unless @errors;

    # If sub, simply invoke, passing all errors
    if (ref $defn_t->{errors_format}) {
        return $defn_t->{errors_format}->(@errors); 
    }
    else {
        my $out = '';
        for my $err (@errors) {
            $out .= sprintf $defn_t->{errors_format}, $err;
            $out .= "\n" unless substr($out,-1) eq "\n";
        }
        return $out;
    }
}

# Derived pre_table to include top-style error messages
sub pre_table
{
    my $self = shift;
    my ($set) = @_;
    my $content = '';
    $content .= $self->title($set) if $self->{defn_t}->{title};
    $content .= $self->top_errors 
        if $self->{defn_t}->{errors_where} && 
           $self->{defn_t}->{errors_where} eq 'top';
    $content .= $self->text($set) if $self->{defn_t}->{text};
    return $content;
}

#
# Derived start_table to include form tags
#
sub start_table
{
    my ($self) = @_;
    my $out = '';
    $out .= $self->start_tag('form',$self->{defn_t}->{form}) . "\n"
        if $self->{defn_t}->{form};
    my $submit_location = $self->{defn_t}->{submit_location} || 'bottom';
    if ($submit_location eq 'bottom') {
      $out .= $self->SUPER::start_table();
    }
    elsif (exists $self->{defn_t}->{submit_table} && 
                  $self->{defn_t}->{submit_table} == 0) {
      $out .= $self->submit();
      $out .= $self->SUPER::start_table();
    } 
    else {
      $out .= $self->SUPER::start_table();
      $out .= $self->submit(table => 1);
    }
    return $out;
}

#
# Derived end_table to include form tags and submits
#
sub end_table
{
    my ($self) = @_;
    my $out = '';
    my $submit_location = $self->{defn_t}->{submit_location} || 'bottom';
    if ($submit_location eq 'top') {
      $out .= $self->SUPER::end_table();
    }
    elsif (exists $self->{defn_t}->{submit_table} && 
                  $self->{defn_t}->{submit_table} == 0) {
      $out .= $self->SUPER::end_table();
      $out .= $self->submit();
    }
    else {
      $out .= $self->submit(table => 1);
      $out .= $self->SUPER::end_table();
    }
    $out .= $self->hidden() if $self->{defn_t}->{hidden};
    $out .= $self->end_tag('form') . "\n" if $self->{defn_t}->{form};
    return $out;
}

# -------------------------------------------------------------------------
# Derived check_fields - unlike Tabulate, don't derive from data if undefined
sub check_fields {
    my $self = shift;
    # Default handling for 'table' forms
    $self->SUPER::check_fields(@_) if $self->{defn_t}->{formtype} eq 'table';
}

# Derived render_table - skip form altogether unless 'fields' or 'submit'
sub render_table
{
    my $self = shift;
    my ($set) = @_;

    # Default handling for 'table' forms
    return $self->SUPER::render_table(@_) 
        if $self->{defn_t}->{formtype} eq 'table';

    # Decide whether we need a form
    my $fields = $self->{defn_t}->{fields};
    my $submit = $self->{defn_t}->{submit};
    my $do_form = ($fields && ref $fields eq 'ARRAY' && @$fields) ||
                  ($submit && ref $submit eq 'ARRAY' && @$submit);

    # Ignore 'style' - we just always use 'across'
    my $body = $self->body_across($set) if $do_form;
    
    # Build table
    my $table = '';
    $table .= $self->pre_table($set);
    if ($do_form) {
        $table .= $self->start_table();
        $table .= $body; 
        $table .= $self->end_table();
    }
    $table .= $self->post_table($set);

    return $table;
}

# -------------------------------------------------------------------------
# Derived render to setup procedural call if necessary
sub render
{
    my $self = shift;
    my ($set, $defn) = @_;

    # If $self is not blessed, this is a procedural call, $self is $set
    if (ref $self eq 'HASH' || ref $self eq 'ARRAY') {
      $defn = $set;
      $set = $self;
      $self = __PACKAGE__->new($defn);
      undef $defn;
    }

    # Call super version
    $self->SUPER::render(@_);
}

1;

__END__

=head1 NAME

HTML::Formulate - module for producing/rendering HTML forms


=head1 SYNOPSIS

   # Simple employee create form
   $f = HTML::Formulate->new({
      fields => [ qw(firstname surname email position) ],
      required => [ qw(firstname surname) ],
   });
   print $f->render;

outputs:

   <form method="post">
   <table cellpadding="2">
   <tr><th style="color:blue"><span class="required">Firstname</span></th>
   <td><input name="firstname" type="text" /></td></tr>
   <tr><th style="color:blue"><span class="required">Surname</span></th>
   <td><input name="surname" type="text" /></td></tr>
   <tr><th>Email</th><td><input name="email" type="text" /></td></tr>
   <tr><th>Position</th><td><input name="position" type="text" /></td></tr>
   <tr><td align="center" colspan="2">
   <input name="submit" id="submit" type="submit" value="Submit" />
   </td></tr>
   </table>
   </form>

   # Simple employee edit form
   $f = HTML::Formulate->new({
      fields => [ qw(emp_id firstname surname email position) ],
      required => [ qw(firstname surname) ],
      field_attr => {
        emp_id => { type => 'hidden' },
      },
   });
   print $f->render(\%data);

outputs the same form but with an additional 'hidden' emp_id input 
field, and data values from the %data hash in the relevant input 
field values.


=head1 DESCRIPTION

HTML::Formulate is a module used to produce HTML forms. It uses a
presentation definition hash to control the output format, which is
great for flexible programmatic control, inheritance, and subclassing
(e.g. defining site- or section-specific HTML::Formulate subclasses
and then producing standardised forms very easily). On the other hand,
it doesn't give you the very fine-grained control over presentation
that you get using a template-based system.

HTML::Formulate handles only form presentation - it doesn't include
any validation or processing functionality (although it does include
functionality for displaying validation errors). If you're after the
processing end of things, check out CGI::FormFactory, which uses 
HTML::Formulate and Data::FormValidator to manage the full HTML form
lifecycle. CGI::FormBuilder is another good alternative.

HTML::Formulate also allows form definitions to be built in multiple
stages, so that you can define a base form with common definitions
(either on the fly or as a dedicated subclass) and then provide only
the details that are particular to your new form.


=head1 FORM DEFINITION ARGUMENTS

HTML::Formulate is a subclass of HTML::Tabulate, and uses HTML tables 
to lay out its forms. It supports all the standard HTML::Tabulate 
presentation definition arguments - see HTML::Tabulate for details. 
Probably the following are the most important:

=over 5

=item fields 

Arrayref of field names

=item field_attr 

Hashref defining per-field attributes (important - see HTML::Tabulate
for the details, and the FIELD ATTRIBUTE ARGUMENTS section below)

=item table, tr, th, td 

Hashrefs defining attributes to be applied to the relevant table element

=item title, text, caption 

Scalars or subroutine references (see HTML::Tabulate) defining simple 
text elements to be displayed before or after the form

=back

In addition, HTML::Formulate supports the following form-specific 
definition arguments:

=over 4

=item form

Hashref defining attributes to be set on the form tag. Can also be used
as a scalar with a false value to omit the form elements from the rendered 
form (presumably because you're handling them explicitly yourself).
Default: form => { method => 'post' }

=item formtype 

Scalar - currently just 'form' or 'table'. A 'table' form suppresses all
the HTML::Formulate extras, producing a vanilla HTML::Tabulate table from
your definition.

=item submit

Arrayref of submit/button/reset elements to display at the bottom of 
your form. By default, these are rendered as (e.g. for submit => [ 'Search' ]):

  type="submit" name="search" id="search" value="Search"

input elements. To change attributes, use a named field_attr section 
(see FIELD ATTRIBUTE ARGUMENTS below) or the special field_attr '-submit'
section (which applies to all submit elements). Default: 

  submit => [ 'submit' ]

To omit submit elements altogether, use:

  submit => []            # or submit => 0

=item required

Arrayref of field names that are required/mandatory fields, or a scalar
field name if only one field is required. The special field names 'ALL'
and 'NONE' are also supported. Default: none.

Required fields are marked as such, usually on the field label. By
default, required field labels are rendered as:

  <th style="color:blue"><span class="required">Label</span></th>

This colours required labels blue, by default, but can be overridden
by defining a CSS 'required' class. This default itself can be 
overridden by defining per-field attributes (typically 'th' and
'label_format') for the '-required' pseudo-field (see '-required' 
below).

=item hidden

Arrayref of field names to render as hidden elements, or a hashref of
field => value pairs. Hiddens can also be defined within a field 
attribute section by setting the field type to 'hidden'.
Default: none.

=item use_name_as_id 

Boolean. If true, HTML::Formulate will add an id attribute set
to the field name on any input/select/textarea fields that do
not have an id.

=item errors

Hashref defining a set of field => error_message pairs to be displayed
as errors on the form (multiple error messages per field are also 
supported by making the value an arrayref of error messages).

Errors are displayed in two ways: the list error messages are 
error messages is displayed either above the form or in a third 
column within the form (see 'errors_where' to control which); and
error field labels are modified to indicate an error.

Error messages are listed in form field order if the error key
is recognised as a field name ('field errors'); any others are not 
recognised as field names ('extra errors') are listed after this.
Error messages are treated as sprintf messages, with a '%s' in the
message replaced by the field label (for field errors) or the error
key (for extra errors). Errors without %s placeholders therefore 
just get rendered as literals.

Field error labels are by default rendered in a similar way to 
'required' fields, like this:

  <th style="color:red"><span class="error_field">Label</span></th>

This colours error labels red, but can be overridden by defining a 
CSS 'error_field' class. This default itself can be overridden by
defining per-field attributes (typically 'th' and 'label_format') for 
the '-errors' pseudo-field (see '-errors' below).

Error messages, if defined, are displayed as a list before the form
(errors_where => 'top') or in a third table column annotating each 
field (errors_where => 'column'). See 'errors_where' following.

=item errors_where

Scalar, either 'top' or 'column'. If 'top', error messages are 
displayed as a list before the form - see errors_format to control
how this list is formatted. If 'column', error messages are 
displayed in a third table column immediately to the right of the
relevant field. Default: top.

=item errors_format

Subroutine reference or scalar defining how to format 'top' style 
error messages. If a subroutine, is passed the array of messages
as arguments, and is expected to return a string containing the
formatted errors. If a scalar, is interpreted as a sprintf 
pattern to be applied per-message, with the results simply joined
with newlines - in particular, the scalar should include any 
HTML line breaks required. e.g.

  errors_format => '<span class="error">%s</span><br />'

Default is a subref that renders messages like this:

  <p style="color:red;font-weight:bold">
  <span class="error">Error 1</span>
  <span class="error">Error 2</span>
  </p>

producing red bold error messages, which can be overridden by 
defining a CSS 'error' class.

=back

=item submit_location

Scalar, either 'bottom' or 'top' or 'both'. Location of submit 
elements. Default: bottom.


=head1 FIELD ATTRIBUTE ARGUMENTS

Per-field attributes can be defined in a 'field_attr' hashref
(see HTML::Tabulate for the details). In addition to the standard
HTML::Tabulate attributes (and the '-defaults' pseudo-field),
HTML::Formulate defines some extra attributes and a set of extra
pseudo-fields, as follows.

=head2 FORMULATE PSEUDO-FIELDS

=over 4

=item -select

A hashref of field attributes to be used for all <select> fields,
The order in which attributes are defined is global -defaults, 
then -select attributes, and then per-field attributes, allowing 
defaults to be overridden as required.

=item -submit

A hashref of field attributes to be used for all submit fields,
as defined in the top-level 'submit' argument. The order in 
which attributes are defined is global -defaults, then -submit
attributes, and then per-field attributes, allowing defaults to 
be overridden as required.

=item -required

A hashref of field attributes to be used for all required fields,
as defined in the top-level 'required' argument. The order in 
which attributes are defined is global -defaults, then -required
attributes, and then per-field attributes, allowing defaults to 
be overridden as required.

For example, to turn off the default 'required' field styling,
you could define -required as follows:

  -required => {
    th => {},
    label_format => '',
  }

=item -errors

A hashref of field attributes to be used for any field defined
as having a validation error in the top-level 'errors' argument. 
The order in which attributes are defined is global -defaults, 
then -required attributes (if applicable), then -errors
attributes, and then per-field attributes.

=back

=head2 FORMULATE FIELD ATTRIBUTES

=over 4

=item type

An enum defining what sort of control to present for this field, usually 
being an HTML input type (or equivalent). Current valid values are:

  text textarea password radio select checkbox hidden file image button
  display static omit

Of these display, static, and omit do not have obvious HTML correlates - 
these mean:

=over 4

=item display

The field is a readonly display field, and any value simply displayed as
text i.e. no input fields are produced e.g.

  emp_name => { type => 'display' }

is rendered as the following line:

  <tr><th>Emp Name</th><td>Fred Flintstone</td></tr>

=item static

The field is a readonly display field, but is passed when the field is
submitted i.e. both a text label and a hidden input field are produced e.g.

  emp_name => { type => 'static' }

is rendered as the following line:

  <tr><th>Emp Name</th>
  <td>Fred Flintstone
  <input name="emp_name" type="hidden" value="Fred Flintstone" />
  </td></tr>

(some formatting newlines added). If you want to use a different label
than the underlying data value, you can set a scalar or coderef 'vlabel', 
similar to selects. A scalar vlabel is interpreted as a sprintf pattern 
passed the current data value i.e. $label = sprintf($vlabel,$value). 
For example:

  emp_id => { type => 'static', value => '123', vlabel => 'E%05d' }

is rendered as:

  <tr><th>Emp ID</th>
  <td>E00123<input name="emp_id" type="hidden" value="123" />
  </td></tr>

(newlines added).

A coderef vlabel is passed the standard arguments: value, row, field e.g.

  emp_id => { type => 'static', value => '123', vlabel => sub {
    my ($value, $row, $field) = @_;
    sprintf 'E%05d', $value;
  }}

renders the same as the previous example.

=item omit

The field is to be omitted altogether i.e. no row or input field is to be 
included for this field. This is useful either to temporarily comment out
a field without deleting its field attribute definition, or if you're 
doing something like building the field manually yourself for some reason,
and still want it validated etc. as part of 'fields'.

=back

=item required

A boolean allowing you to specify whether this field is required, as an
alternative to including it in a 'required' arrayref at the top-level.

=item values

An arrayref or subroutine defining (or returning) a list of possible 
values for a field, typically used in defining the possible values of a 
list field e.g. a select, checkbox set, etc.

If a subroutine, it is called as follows:

  $values_sub->( $field, $row );

where $field is the field name, and $row is the current data row. It 
is expected to return a arrayref of values to use.

=item vlabels

An arrayref or subroutine defining (or returning) a list of labels to
be associated with the corresponding items in the values arrayref 
above. Alternatively, it may be (or return) a hashref defining 
value => label correspondences explicitly.

If a subroutine, it is called as follows:

  $vlabels_sub->( $v, $field, $row )

where $v is the current value, $field is the field name, and $row is the 
current data row. The subroutine may return any of the following: an
arrayref defining the entire list of labels for this field, in the same
order as the values arrayref; a hashref defining the entire set of labels
for this field, mapping values to labels; or a scalar, defining the label
for the given value only.

=item OTHER ATTRIBUTES

All other attributes defined for a field are taken to be attributes to
be applied either to the field input or textarea or select tag (if it
looks like a valid attribute for the tag in question e.g. class, name, 
id, size, maxlength, etc.), or else are applied to the enclosing <th> 
and <td> table tags (as for HTML::Tabulate - see Tabulate 
documentation). 

=back


=head1 EXAMPLES

=over 4

=item User login form

    $f = HTML::Formulate->new({
      fields => [ qw(username password) ],
      required => 'ALL',
      submit => [ qw(login) ],
      field_attr => {
        password => { type => 'password' },
      },
    });

=item User registration form

    $f = HTML::Formulate->new({
      fields => [ qw(firstname surname email password password_confirm) ],
      required => 'ALL',
      submit => [ qw(register) ],
      field_attr => {
        qr/^password/ => { type => 'password' },
      },
    });


=back


=head1 SEE ALSO

HTML::Tabulate, CGI::FormFactory, CGI::FormBuilder


=head1 AUTHOR

Gavin Carr, E<lt>gavin@openfusion.com.auE<gt>


=head1 COPYRIGHT

Copyright 2003-2016, Gavin Carr.

This program is free software. You may copy or redistribute it under the 
same terms as perl itself.

=cut

# vim:sw=4

