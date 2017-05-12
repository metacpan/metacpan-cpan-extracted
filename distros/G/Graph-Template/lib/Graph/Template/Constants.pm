package Graph::Template::Constants;

use strict;

BEGIN {
    use vars qw(@ISA @EXPORT_OK $VERSION);

    $VERSION = 0.01;

    use Exporter;
    @ISA = qw( Exporter );
    @EXPORT_OK = qw(
        %GraphTypes
    );
 
    use vars qw(
        %GraphTypes
    );
}

%GraphTypes = (
    vert_bars   => 'bars',
    horiz_bars  => 'hbars',
    line_graph  => 'lines',
    point_graph => 'points',
    line_point  => 'linespoints',
    pie         => 'pie',

    # This will be commented out, for now
#   mixed => 'mixed',
);

1;
__END__
