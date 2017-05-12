package HTML::FormBuilder::FieldSet;

use strict;
use warnings;
use 5.008_005;

use HTML::FormBuilder::Field;
use Carp;
use Scalar::Util qw(weaken blessed);

use Moo;
use namespace::clean;
extends qw(HTML::FormBuilder::Base);

our $VERSION = '0.12';    ## VERSION

has data => (
    is  => 'ro',
    isa => sub {
        my $data = shift;
        croak('data should be a hashref') unless ref($data) eq 'HASH';
    },
    default => sub {
        {};
    },
);

has fields => (
    is  => 'rw',
    isa => sub {
        my $fields = shift;
        croak('fields should be an arrayref') unless ref($fields) eq 'ARRAY';
    },
    default => sub {
        [];
    },
);

sub add_field {
    my $self  = shift;
    my $_args = shift;

    my $field = HTML::FormBuilder::Field->new(
        data     => $_args,
        classes  => $self->classes,
        localize => $self->localize
    );
    push @{$self->{'fields'}}, $field;

    return $field;
}

sub add_fields {
    my ($self, @field_args) = @_;

    for my $field_arg (@field_args) {
        $self->add_field($field_arg);
    }
    return scalar @field_args;
}

#####################################################################
# Usage      : generate the form content for a fieldset
# Purpose    : check and parse the parameters and generate the form
#              properly
# Returns    : a piece of form HTML for a fieldset
# Parameters : fieldset
# Comments   :
# See Also   :
#####################################################################
sub build {
    my $self = shift;

    my $data = $self->{data};

    #FIXME this attribute should be deleted, or it will emit to the html code
    my $fieldset_group = $data->{'group'};
    my $stacked = defined $data->{'stacked'} ? $data->{'stacked'} : 1;

    if (not $fieldset_group) {
        $fieldset_group = 'no-group';
    }

    my $fieldset_html = $self->_build_fieldset_foreword();

    my $input_fields_html = '';

    foreach my $input_field (@{$self->{'fields'}}) {
        $input_fields_html .= $input_field->build({stacked => $stacked});
    }

    if ($stacked == 0) {
        $input_fields_html = $self->_build_element_and_attributes('div', {class => $self->{classes}{'no_stack_field_parent'}}, $input_fields_html);
    }

    $fieldset_html .= $input_fields_html;

    # message at the bottom of the fieldset
    if (defined $data->{'footer'}) {
        my $footer = delete $data->{'footer'};
        $fieldset_html .= qq{<div class="$self->{classes}{fieldset_footer}">$footer</div>};
    }

    $fieldset_html = $self->_build_element_and_attributes('fieldset', $data, $fieldset_html);

    if (
        (not $data->{'id'} or $data->{'id'} ne 'formlayout')
        and (not $data->{'class'}
            or $data->{'class'} !~ /no-wrap|invisible/))
    {
        $fieldset_html = $self->_wrap_fieldset($fieldset_html);

    }
    return ($fieldset_group, $fieldset_html);
}

#####################################################################
# Usage      : generate the form content for a fieldset foreword thing
# Purpose    : check and parse the parameters and generate the form
#              properly
# Returns    : a piece of form HTML code for a fieldset foreword
# Parameters : input_field, stacked
# Comments   :
# See Also   :
#####################################################################
sub _build_fieldset_foreword {
    my $self = shift;
    my $data = $self->{data};

    # fieldset legend
    my $legend = '';
    if (defined $data->{'legend'}) {
        $legend = qq{<legend>$data->{legend}</legend>};
        undef $data->{'legend'};
    }

    # header at the top of the fieldset
    my $header = '';
    if (defined $data->{'header'}) {
        $header = qq{<h2>$data->{header}</h2>};
        undef $data->{'header'};
    }

    # message at the top of the fieldset
    my $comment = '';
    if (defined $data->{'comment'}) {
        $comment = qq{<div class="$self->{classes}{comment}"><p>$data->{comment}</p></div>};
        undef $data->{'comment'};
    }

    return $legend . $header . $comment;
}

#####################################################################
# Usage      : $self->_wrap_fieldset($fieldset_html)
# Purpose    : wrap fieldset html by template
# Returns    : HTML
# Comments   :
# See Also   :
#####################################################################
sub _wrap_fieldset {
    my ($self, $fieldset_html) = @_;

    my $fieldset_template = <<EOF;
<div class="rbox form">
    <div class="rbox-wrap">
        $fieldset_html
        <span class="tl">&nbsp;</span><span class="tr">&nbsp;</span><span class="bl">&nbsp;</span><span class="br">&nbsp;</span>
    </div>
</div>
EOF

    return $fieldset_template;
}

1;

=head1 NAME

HTML::FormBuilder::FieldSet - FieldSet container used by HTML::FormBuilder

=head1 SYNOPSIS

    my $form = HTML::FormBuilder->new(data => {id => 'testform});

    my $fieldset = $form->add_fieldset({id => 'fieldset1'});

    $fieldset->add_field({input => {type => 'text', value => 'Join'}});

    $form->add_field($fieldset_index, {input => {type => 'text', value => 'Join'}});

=head1 Attributes

=head2 fields

The fields included by this fieldset.

=head1 Methods

=head2 build

    my ($fieldset_group, $fieldset_html) = $fieldset->build();

=head2 add_field

    $fieldset->add_field({input => {type => 'text', value => 'name'}});

append the field into fieldset and return that field

=head2 add_fields

    $fieldset->add_fields({input => {type => 'text', value => 'name'}},{input => {type => 'text', value => 'address'}});

append fields into fieldset and return the number of fields added.

=head2 data

=head1 AUTHOR

Chylli L<mailto:chylli@binary.com>

=head1 CONTRIBUTOR

Fayland Lam L<mailto:fayland@binary.com>

Tee Shuwn Yuan L<mailto:shuwnyuan@binary.com>

=head1 COPYRIGHT AND LICENSE

=cut
