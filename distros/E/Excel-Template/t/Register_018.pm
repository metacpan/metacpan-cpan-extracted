package Register_018;

use strict;

sub render
{
    my ($self, $context) = @_;

    my $old_format = $context->active_format;
    my $format = $context->format_object->copy(
        $context, $old_format,

        align => 'center', bold => 1,
    );

    $context->active_format($format);

    my $child_success = $self->SUPER::render($context);

    $context->active_format($old_format);

    return $child_success;

}

1;
__END__
