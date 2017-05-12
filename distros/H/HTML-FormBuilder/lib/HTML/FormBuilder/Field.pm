package HTML::FormBuilder::Field;

use strict;
use warnings;
use 5.008_005;

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

sub BUILDARGS {
    my (undef, @args) = @_;
    my %args = (@args % 2) ? %{$args[0]} : @args;

    my $data = $args{data};

    # normalize: if 'input' is not an array, then make it as an array, so that
    # we can process the array directly
    if ($data->{input} && ref($data->{input}) ne 'ARRAY') {
        $data->{input} = [$data->{input}];
    }

    return \%args;
}

sub build {
    my $self = shift;
    my $env  = shift;

    my $data = $self->{data};

    my $stacked = $env->{stacked};
    my $classes = $self->classes;

    my $div_span     = "div";
    my $label_column = $classes->{label_column};
    my $input_column = $classes->{input_column};
    $input_column = $data->{override_input_class} if ($data->{override_input_class});

    if ($stacked == 0) {
        $div_span     = "span";
        $label_column = "";
        $input_column = "";
    }
    my $input_fields_html = '';

    my $stacked_attr = {};

    if ($stacked == 1) {
        my $class = $data->{'class'} ? " $data->{class}" : '';

        if ($data->{'type'} and $data->{'type'} eq 'hidden') {
            $stacked_attr->{class} = $class;
        } else {
            $stacked_attr->{class} = "$classes->{row_padding} $classes->{row} clear$class";
        }
    }

    #create the field label
    if (defined $data->{'label'}) {
        my $label_text = $data->{'label'}->{'text'} || '';
        undef $data->{'label'}->{'text'};
        my $required_mark = delete $data->{label}{required_mark} || 0;
        my $label_html = $self->_build_element_and_attributes('label', $data->{'label'}, $label_text, {required_mark => $required_mark},);

        # add a tooltip explanation if given
        if ($data->{'label'}{'tooltip'}) {

            # img_url is the url of question mark picture
            my $tooltip = _tooltip($data->{'label'}{'tooltip'}{'desc'}, $data->{'label'}{tooltip}{img_url});

            $input_fields_html .= qq{<div class="$classes->{extra_tooltip_container}">$label_html$tooltip</div>};
        } else {
            my $hide_mobile = $label_text ? "" : $classes->{hide_mobile};

            $input_fields_html .= qq{<$div_span class="$label_column $hide_mobile form_label">$label_html</$div_span>};
        }
    }

    # create the input field
    if (defined $data->{'input'}) {

        #if there are more than 1 input field in a single row then we generate 1 by 1
        my $inputs = $data->{input};
        $input_fields_html .= qq{<$div_span class="$input_column">};
        foreach my $input (@{$inputs}) {
            $input_fields_html .= $self->_build_input($input, $env);
        }
    }

    if (defined $data->{'comment'}) {
        $data->{'comment'}->{'class'} ||= '';

        unless ($data->{comment}->{no_new_line}) {
            $input_fields_html .= '<br>';
        }
        $input_fields_html .= $self->_build_element_and_attributes('p', $data->{'comment'}, $data->{'comment'}->{'text'});
    }

    if (defined $data->{'error'}) {

        my @errors =
            ref($data->{'error'}) eq 'ARRAY'
            ? @{$data->{error}}
            : $data->{error};

        foreach my $error_box (@errors) {
            $input_fields_html .= $self->_build_element_and_attributes('p', $error_box, $error_box->{text});
        }

    }

    #close the input tag
    if (defined $data->{'input'}) {
        $input_fields_html .= '</' . $div_span . '>';
    }

    if ($stacked == 1) {
        $input_fields_html = $self->_build_element_and_attributes('div', $stacked_attr, $input_fields_html);
    }

    return $input_fields_html;
}

#####################################################################
# Usage      : build the input field its own attributes
# Purpose    : perform checking build the input field according to its own
#              characteristics
# Returns    : input field with its attributes in string
# Parameters : $input_field in HASH ref for example
#              $attributes = {'id' => 'test', 'name' => 'test', 'class' => 'myclass'}
# Comments   : check pod below to understand how to create different input fields
# See Also   :
#####################################################################
sub _build_input {
    my $self        = shift;
    my $input_field = shift;

    my $html = '';

    # delete this so that it doesn't carry on to the next field
    # I don't know why should delete it(undef it)
    my $heading  = delete $input_field->{'heading'};
    my $trailing = delete $input_field->{'trailing'};

    # wrap <input>, heading & trailing <span> in <div>
    my ($wrap_input, $wrap_heading, $wrap_trailing);
    if ($input_field->{wrap_in_div_class}) {
        ($wrap_input, $wrap_heading, $wrap_trailing) = @{$input_field->{wrap_in_div_class}}{'input', 'heading', 'trailing'};
    }

    #create the filed input
    if (eval { $input_field->can('widget_html') }) {
        $html = $input_field->widget_html;
    } elsif ($input_field->{'type'} and $input_field->{'type'} eq 'textarea') {
        undef $input_field->{'type'};
        my $textarea_value = $input_field->{'value'} || '';
        undef $input_field->{'value'};
        $html = $self->_build_element_and_attributes('textarea', $input_field, $textarea_value);
    } elsif ($input_field->{'type'}) {
        my $type = $input_field->{'type'};
        if ($type =~ /^(?:text|password)$/i) {
            $input_field->{'class'} .= ' text';
        } elsif ($type =~ /button|submit/) {
            $input_field->{'class'} .= ' button';
        }

        my $tag = ($type =~ /button|submit/ ? 'button' : 'input');

        $html = $self->_build_element_and_attributes($tag, $input_field);

        if ($type =~ /button|submit/) {
            $html = qq{<span class="$input_field->{class}">$html</span>};
        }
    }
    if ($wrap_input) {
        $html = qq{<div class="$wrap_input">$html</div>};
    }

    if ($heading) {
        my $heading_html = qq{<span id="inputheading">$heading</span>};
        if ($wrap_heading) {
            $heading_html = qq{<div class="$wrap_heading">$heading_html</div>};
        }

        if ($input_field->{'type'}
            && ($input_field->{'type'} =~ /radio|checkbox/i))
        {
            $html .= qq{$heading_html<br />};
        } else {
            $html = $heading_html . $html;
        }
    }

    if ($trailing) {
        my $trailing_html = qq{<span class="$self->{classes}{inputtrailing}">$trailing</span>};
        if ($wrap_trailing) {
            $trailing_html = qq{<div class="$wrap_trailing">$trailing_html</div>};
        }
        $html .= $trailing_html;
    }

    return $html;
}

#####################################################################
# Usage      : _tooltip($content, $url)
# Purpose    : create tooltip html code
# Returns    : HTML
# Comments   :
# See Also   :
#####################################################################
sub _tooltip {
    my $content = shift;
    my $url     = shift;
    $content =~ s/\'/&apos;/g;    # Escape for quoting below

    return qq{ <a href='#' title='$content' rel='tooltip'><img src="$url" /></a>};
}

1;

=head1 NAME

HTML::FormBuilder::Field - Field container used by HTML::FormBuilder

=head1 SYNOPSIS

    my $form = HTML::FormBuilder->new(data => {id => 'testform});

    my $fieldset = $form->add_fieldset({id => 'fieldset1'});

    $fieldset->add_field({input => {type => 'text', value => 'Join'}});

    # Text only, without input fields
    $fieldset->add_field({
        comment => {
            text        => 'Please check on checkbox below:',
            class       => 'grd-grid-12',
            # no extra <br/> before <span> for comment
            no_new_line => 1,
        },
    });

    # checkbox & explanation text
    $fieldset->add_field({
        input => {
            id                  => 'tnc',
            name                => 'tnc',
            type                => 'checkbox',
            trailing            => 'I have read & agree to all terms & condition.',
            # wrap <input> & trailing <span> respectively in <div>, with class:
            wrap_in_div_class   => {
                input    => 'grd-grid-1',
                trailing => 'grd-grid-11'
            },
        },
        error => {
            id    => 'error_tnc',
            class => 'errorfield',
         },
        validation => [{
            type    => 'checkbox_checked',
            err_msg => localize('Please agree in order to proceed.'),
        }],
        # override div container class for input
        override_input_class => 'grd-grid-12',
    });

    $form->add_field($fieldset_index, {input => {type => 'text', value => 'Join'}});

=head1 METHODS

=head2 BUILDARGS

=head2 build

=head2 data

=head1 AUTHOR

Chylli L<mailto:chylli@binary.com>

=head1 CONTRIBUTOR

Fayland Lam L<mailto:fayland@binary.com>

Tee Shuwn Yuan L<mailto:shuwnyuan@binary.com>

=head1 COPYRIGHT AND LICENSE

=cut

