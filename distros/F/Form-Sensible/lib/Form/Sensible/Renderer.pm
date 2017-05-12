package Form::Sensible::Renderer;

use Moose; 
use namespace::autoclean;

## this module provides the basics for rendering of forms / fields
##
## should this be an abstract role that defines the interface for rendering?

sub render_hints_for {
    my ($self, $renderer_name, $thing) = @_;
    
    my $hints = $thing->render_hints();
    
    if (exists($hints->{$renderer_name})) {
        return $hints->{$renderer_name};
    } else {
        return $hints;
    }
}

sub render {
    my ($self, $form) = @_;
    
    die "Unable to render " . $form->name . " because you are trying to use an abstract base class to render.";
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Form::Sensible::Renderer - Base class for Renderers. 

=head1 DESCRIPTION

This module provides a base class for renderers.  It's not
very interesting.

=head1 METHODS

=over 8

=item C<render($form)>

Returns a rendered representation of
the form.

=item C<render_hints_for($renderer_name, $thing)>

Returns the render hints for the given type. This looks for an element called
C<renderer_name> in C<< $thing->render_hints >>. If found, it is returned,
otherwise returns C<< $thing->render_hints >>. This is used to allow for
specification of different renderhints within the same form for use by
different renderers.

=back

=head1 AUTHOR

Jay Kuri - E<lt>jayk@cpan.orgE<gt>

=head1 SPONSORED BY

Ionzero LLC. L<http://ionzero.com/>

=head1 SEE ALSO

L<Form::Sensible>

=head1 LICENSE

Copyright 2009 by Jay Kuri E<lt>jayk@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut