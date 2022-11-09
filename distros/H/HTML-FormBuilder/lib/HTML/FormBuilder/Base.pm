package HTML::FormBuilder::Base;

use strict;
use warnings;
use 5.008_005;

use Carp;
use Moo;
use namespace::clean;

our $VERSION = '0.13';    ## VERSION

our $CLASSES = {
    fieldset_group          => 'fieldset_group',
    no_stack_field_parent   => 'no_stack_field_parent',
    row_padding             => 'row_padding',
    fieldset_footer         => 'fieldset_footer',
    comment                 => 'comment',
    row                     => 'row',
    extra_tooltip_container => 'extra_tooltip_container',
    backbutton              => 'backbutton',
    required_asterisk       => 'required_asterisk',
    inputtrailing           => 'inputtrailing',
    label_column            => 'label_column',
    input_column            => 'input_column',
    hide_mobile             => 'hide_mobile'
};

has classes => (
    is  => 'ro',
    isa => sub {
        my $classes = shift;
        croak('classes should be a hashref') unless ref($classes) eq 'HASH';
    });

has localize => (
    is  => 'ro',
    isa => sub {
        my $localize = shift;
        croak('localize should be a sub') unless ref($localize) eq 'CODE';
    },
    default => sub {
        return sub { return shift; }
    },
);

#####################################################################
# Usage      : build the html element and its own attributes
# Purpose    : perform checking and drop unnecessary attributes
# Returns    : element with its attributes in string
# Parameters : $element_tag such as p, input, label and etc
#              $attributes in HASH ref for example
#              $attributes = {'id' => 'test', 'name' => 'test', 'class' => 'myclass'}
# Comments   :
# See Also   :
#####################################################################
sub _build_element_and_attributes {
    my $self        = shift;
    my $element_tag = shift;
    my $attributes  = shift;
    my $content     = shift || '';
    my $options     = shift || {};

    #check if the elemen tag is empty
    return if ($element_tag eq '');

    my $html;
    $html = '<' . $element_tag;
    foreach my $key (sort keys %{$attributes}) {
        next
            if (ref($attributes->{$key}) eq 'HASH'
            or ref($attributes->{$key}) eq 'ARRAY');

        # skip attributes that are not intended for HTML
        next if ($key =~ /^(?:option|text|hide_required_text|localize|wrap_in_div_class)/i);
        next if not defined $attributes->{$key};
        next if $attributes->{$key} eq '';

        $html .= qq[ $key="$attributes->{$key}"];
    }
    if ($element_tag eq 'button') {
        $html .= '>' . $attributes->{'value'} . '</' . $element_tag . '>';
    } else {
        $html .= '>';
    }

    if ($options->{required_mark} && !$self->{option}{hide_required_text}) {
        $html .= qq[<em class="$self->{classes}{required_asterisk}">**</em>];
    }

    #close the tag
    my $end_tag = "</$element_tag>";

    # input needn't close tag
    if ($element_tag =~ /^(input)$/) {
        $end_tag = '';
    }
    return $html . $content . $end_tag;
}

#####################################################################
# Usage      : call $self->{option}{localize} to localize a string
# Purpose    : localize string
# Returns    : a localized string
# Parameters : string
# Comments   :
# See Also   : new
#####################################################################
sub _localize {
    my $self = shift;
    my $str  = shift;
    return $self->localize->($str);
}

1;

=head1 NAME

HTML::FormBuilder::Base - HTML::FormBuilder and HTML::FormBuilder::Fieldset, HTML::FormBuilder::Field base class

=head1 Attributes

=head2 classes

please refer to L<HTML::FormBuilder>.

=head2 localize

please refer to L<HTML::FormBuilder>.

=head1 AUTHOR

Chylli L<mailto:chylli@binary.com>

=head1 CONTRIBUTOR

Fayland Lam L<mailto:fayland@binary.com>

Tee Shuwn Yuan L<mailto:shuwnyuan@binary.com>

=head1 COPYRIGHT AND LICENSE

=cut
