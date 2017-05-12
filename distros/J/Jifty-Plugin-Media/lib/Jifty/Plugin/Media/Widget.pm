use strict;
use warnings;

package Jifty::Plugin::Media::Widget;
use base qw/Jifty::Web::Form::Field/;

=head1 NAME

Jifty::Plugin::Media::Widget - widget for managing files in Jifty 

=head2 render_widget

html widget

=cut

sub render_widget {
    my $self  = shift;
    my $field;

    my $element_id = "@{[ $self->element_id ]}";
    $element_id=~s/://g;

    my $current_value = $self->current_value || '';

    $field .= qq!<div>!;
    $field .= qq!<input id="$element_id"!;
    $field .= qq! name="@{[ $self->input_name ]}"!;
    $field .= qq! type="text" value="$current_value" /></div>!;
    my $folder = 'f'.$element_id;
    $field .= qq! <div id="$folder"></div>!;

    $field .= <<"EOF";
<script language="javascript">
jQuery(document).ready( function() {
    jQuery('#$folder').fileTree ({ 
        root: '/',
        script: '/media_browse',
        expandSpeed: 300,
        collapseSpeed: 300,
        multiFolder: false
        }, function(file) {
            jQuery('#$element_id').val(file);
        });
});
</script>
EOF

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

