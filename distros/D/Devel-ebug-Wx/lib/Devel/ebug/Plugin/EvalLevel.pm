package Devel::ebug::Plugin::EvalLevel;

use strict;
use base qw(Exporter);

our @EXPORT = qw(eval_level);

# eval expression and return the result as a tree of depth "level"
sub eval_level {
    my( $self, $expr, $level ) = @_;
    my $response = $self->talk( { command => "eval_level",
                                  eval    => $expr,
                                  level   => $level,
                                  } );
    return wantarray ? ( $response->{eval}, $response->{exception} ) :
                       $response->{eval};
}

1;

