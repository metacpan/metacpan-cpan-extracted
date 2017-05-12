package Graphics::Primitive::Driver::CairoPango::TextLayout;
use Moose;

use Graphics::Primitive::TextBox;

with 'Graphics::Primitive::Driver::TextLayout';

use Pango;

has '_layout' => (
    is => 'rw',
    isa => 'Pango::Layout',
);

sub slice {
    my ($self, $offset, $size) = @_;

    my $lay = $self->_layout;
    my $comp = $self->component;

    if(!defined($size) || ($size > $self->height && !$offset)) {
        # If there was no size or there was a size bigger than this textbox
        # with no offset, give them the whole shebang
        my $clone = $comp->clone;
        $clone->layout($self);
        $clone->minimum_width($self->width + $comp->outside_width);
        $clone->minimum_height($self->height + $comp->outside_height);
        $clone->width($self->width + $comp->outside_width);
        $clone->height($self->height + $comp->outside_height);
        return $clone;
    }

    my $lc = $lay->get_line_count;

    my $found = 0;
    my $using = $comp->outside_height;
    # This component is too big to fit!
    if($using >= $size) {
        return undef;
    }
    my @lines;

    my $start = undef;
    my $count = 0;
    for(my $i = 0; $i < $lc; $i++) {
        my $line = $lay->get_line_readonly($i);
        my ($ink, $log) = $line->get_pixel_extents;
        my $lh = $log->{height};

        last if (($lh + $using) > $size);
        if(($found + $using) >= $offset) {
            unless(defined($start)) {
                $start = $i;
            }
            $count++;
            $using += $lh;
        }
        $found += $lh;
    }

    # We didn't find any lines that fit, so just return nothing
    if($count == 0) {
        return undef;
    }

    return $comp->clone(
        height => $using,
        layout => $self,
        lines => { start => $start , count => $count },
        minimum_width => $self->width + $comp->outside_width,
        minimum_height => $using,
        prepared => 0,
        width => $self->width + $comp->outside_width,
    );
}

no Moose;
1;
__END__
=head1 NAME

Graphics::Primitive::Driver::CairoPango::TextLayout - Text layout engine

=head1 SYNOPSIS

    my $tl = $driver->get_textbox_layout($comp);
    ...

=head1 DESCRIPTION

Implements L<Graphics::Primitive::Driver::TextLayout>.  Please refer to it's
documentation for usage.

=head1 IMPLEMENTATION

This text layout engine uses Pango to layout text.

=head1 AUTHOR

Cory Watson, C<< <gphat@cpan.org> >>

Infinity Interactive, L<http://www.iinteractive.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-geometry-primitive at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geometry-Primitive>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.