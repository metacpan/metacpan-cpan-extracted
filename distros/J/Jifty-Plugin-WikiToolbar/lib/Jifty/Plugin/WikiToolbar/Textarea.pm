use strict;
use warnings;

package Jifty::Plugin::WikiToolbar::Textarea;
use base qw(Jifty::Web::Form::Field::Textarea);

=head1 NAME

Jifty::Plugin::WikiToolbar::Textarea - Textarea widget with a wiki toolbar

=head2 accessors

allow to override rows and cols size
 
=cut

__PACKAGE__->mk_accessors(qw(rows cols));

sub accessors { shift->SUPER::accessors(), 'rows', 'cols' }

=head2 render_widget

html widget

=cut

sub render_widget {
    my $self  = shift;
    my $field;
    my $element_id = "@{[ $self->element_id ]}";
        $element_id=~s/://g;

    $field .= qq!<textarea!;
    $field .= qq! name="@{[ $self->input_name ]}"!;
    $field .= qq! id="$element_id"!;
    $field .= qq! rows="@{[$self->rows || 5 ]}"!;
    $field .= qq! cols="@{[$self->cols || 60]}"!;
    $field .= $self->_widget_class;
    $field .= qq! >!;
    $field .= Jifty->web->escape($self->current_value) if $self->current_value;
    $field .= qq!</textarea>\n!;
    $field .= <<"EOF";
<script language="javascript">
    jQuery(document).ready(function() {
      jQuery('#$element_id').each(function() { addWikiFormattingToolbar(this) });
    });
</script>
EOF

    Jifty->web->out($field);
    '';
}


1;
