use strict;
use warnings;

package Jifty::Plugin::SimpleColor::Widget;
use base qw/Jifty::Web::Form::Field/;

=head1 NAME

Jifty::Plugin::SimpleColor::Widget - widget for a simple color picker

=cut

__PACKAGE__->mk_accessors(qw(addColors));

=head2 render_widget

html widget

=cut

sub render_widget {
    my $self  = shift;
    my $field;

    my $element_id = "@{[ $self->element_id ]}";
    my $js_element_id = $element_id;
       $js_element_id =~s/:/\\\\:/g;

    my ($plugin) = Jifty->find_plugin('Jifty::Plugin::SimpleColor');

    my $defaultColors = $plugin->defaultColors() || undef;
    my $addColors = $self->addColors() || undef;
    my $current_value = $self->current_value || '';

    $field .= qq!<div>!;
    $field .= qq!<input id="$element_id"!;
    $field .= qq! name="@{[ $self->input_name ]}"!;
    $field .= qq! type="text" value="$current_value" /></div>!;
    $field .= <<"EOF";
<script language="javascript">

jQuery(document).ready(function() {
EOF

$field .= qq!    jQuery.fn.colorPicker.defaultColors = $defaultColors ;! if ($defaultColors) ;
$field .= qq!    jQuery.fn.colorPicker.addColors( $addColors ) ;! if ($addColors) ;

$field .= <<"EOF2";
    jQuery('#$js_element_id').colorPicker();
  });
</script>
EOF2

    Jifty->web->out($field);
    '';
};

=head2 render_value

Renders value as a div block

=cut

sub render_value {
    my $self  = shift;
    my $field;

    my $current_value = $self->current_value || '';
    $field .= <<"E2F";
<div style="
  height: 16px;
  width: 16px;
  padding: 0 !important;
  border: 1px solid #ccc;
E2F
 $field .= qq!  background-color: $current_value;! if $current_value;
 $field .= qq!  line-height: 16px;">\&nbsp;</div>!;


    Jifty->web->out($field);
    '';
};

=head1 AUTHOR

Yves Agostini, <yvesago@cpan.org>

=head1 LICENSE

Copyright 2010, Yves Agostini.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut


1;

