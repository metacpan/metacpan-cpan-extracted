package Graphics::Grid::Functions;

# ABSTRACT: Function interface for Graphics::Grid

use Graphics::Grid::Setup;

our $VERSION = '0.0001'; # VERSION

use Module::Load;

use Graphics::Grid;
use Graphics::Grid::GPar;
use Graphics::Grid::Unit;
use Graphics::Grid::Viewport;
use Graphics::Grid::GTree;

my @grob_types = Graphics::Grid->_grob_types();

use Exporter 'import';
our @EXPORT_OK = (
    qw(
      unit gpar viewport
      grid_write grid_draw grid_driver
      push_viewport pop_viewport up_viewport down_viewport seek_viewport
      gtree
      ), ( map { ( "grid_${_}", "${_}_grob" ) } @grob_types )
);

our %EXPORT_TAGS = ( all => \@EXPORT_OK );

my $grid = Graphics::Grid->new;    # global object

sub unit {
    return Graphics::Grid::Unit->new(@_);
}

sub gpar {
    return Graphics::Grid::GPar->new(@_);
}

sub viewport {
    return Graphics::Grid::Viewport->new(@_);
}

sub grid_draw {
    $grid->draw(@_);
}

sub grid_write {
    $grid->write(@_);
}

fun grid_driver( :$driver = 'Cairo', %rest ) {
    if ( $driver->DOES('Graphics::Grid::Driver') ) {
        $grid->driver($driver);
    }
    else {
        my $cls = "Graphics::Grid::Driver::$driver";
        load $cls;
        $grid->driver( $cls->new(%rest) );
    }
    return $grid->driver;
}

sub gtree {
    return Graphics::Grid::GTree->new(@_);
}

for my $grob_type (@grob_types) {
    my $class = 'Graphics::Grid::Grob::' . ucfirst($grob_type);
    load $class;

    my $grob_func = sub {
        my $grob = $class->new(@_);
    };

    no strict 'refs';    ## no critic
    *{ $grob_type . "_grob" } = $grob_func;
    *{ "grid_" . $grob_type } = sub {
        $grid->$grob_type(@_);
    };
}

for my $method (
    qw(
    push_viewport pop_viewport up_viewport down_viewport seek_viewport
    )
  )
{
    no strict 'refs';    ## no critic
    *{$method} = sub { $grid->$method(@_); }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::Grid::Functions - Function interface for Graphics::Grid

=head1 VERSION

version 0.0001

=head1 SYNOPSIS

    use Graphics::Grid::Functions qw(:all);

    grid_driver( width => 900, height => 300, format => 'svg' );
    grid_rect();    # draw white background

    for my $setting (
        { color => 'red',   x => 1 / 6 },
        { color => 'green', x => 0.5 },
        { color => 'blue',  x => 5 / 6 }
      )
    {
        push_viewport(
            viewport( x => $setting->{x}, y => 0.5, width => 0.2, height => 0.6 ) );
        grid_rect( gp => { fill => $setting->{color}, lty => 'blank' } );
        grid_text( label => $setting->{color}, y => -0.1 );

        pop_viewport();
    }

    grid_write("foo.svg");

=head1 DESCRIPTION

This is the function interface for L<Graphics::Grid>. In this package
it has a global Graphics::Grid object, on which the functions are
operated.

=head1 FUNCTIONS

=head2 unit(%params)

It's equivalent to C<Graphics::Grid::Unit-E<gt>new>.

=head2 viewport(%params)

It's equivalent to C<Graphics::Grid::Viewport-E<gt>new>.

=head2 gpar(%params)

It's equivalent to C<Graphics::Grid::GPar-E<gt>new>.

=head2 push_viewport($viewport)

It's equivalent to Graphics::Grid's C<push_viewport> method.

=head2 pop_viewport($n=1)

It's equivalent to Graphics::Grid's C<pop_viewport> method.

=head2 up_viewport($n=1)

It's equivalent to Graphics::Grid's C<up_viewport> method.

=head2 down_viewport($from_tree_node, $name)

It's equivalent to Graphics::Grid's C<down_viewport> method.

=head2 seek_viewport($name)

It's equivalent to Graphics::Grid's C<seek_viewport> method.

=head2 ${grob_type}_grob(%params)

This creates a grob object.

C<$grob_type> can be one of following,

=over 4

=item *

circle

=item *

lines

=item *

points

=item *

polygon

=item *

polyline

=item *

rect

=item *

segments

=item *

text

=item *

null

=item *

zero

=back

=head2 grid_${grob_type}(%params)

This creates a grob, and draws it. This is equivalent to Graphics::Grid's
${grob_type}(...) method.

See above for possible C<$grob_type>.

=head2 gtree(%params)

It's equivalent to C<Graphics::Grid::GTree-E<gt>new>.

=head2 grid_draw($grob)

It's equivalent to Graphics::Grid's C<draw> method.

=head2 grid_driver(:$driver='Cairo', %rest)

Set the device driver. If you don't run this function, the default driver
will be effective.

If C<$driver> consumes Graphics::Grid::Driver, C<$driver> is assigned to
the global Graphics::Grid object, and C<%rest> is ignored.

    grid_driver(driver => Graphics::Grid::Driver::Cairo->new(...));

If C<$driver> is a string, a Graphics::Grid::Driver::$driver object is
created with C<%rest> as construction parameters, and is assigned to the
global Graphics::Grid object.

    grid_driver(driver => 'Cairo', width => 800, height => 600);

You may run it at the the beginning of you code. At present changing driver
settings at the middle is not guarenteed to work.

This function returns current width and height.

    my $driver = grid_device();

=head2 grid_write($filename)

It's equivalent to Graphics::Grid's C<write> method.

=head1 SEE ALSO

L<Graphics::Grid>

Examples in the C<examples> directory of the package release.

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
