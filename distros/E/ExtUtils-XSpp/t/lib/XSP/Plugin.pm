package t::lib::XSP::Plugin;

use strict;
use warnings;

sub new { return bless {}, $_[0] }

my $called = 0;

sub register_plugin {
    my( $class, $parser ) = @_;

    die "register_plugin called twice!" if $called;

    $parser->add_post_process_plugin( plugin => $class->new );
    $called = 1;
}

# add _perl to all function/method names
sub post_process {
    my( $self, $nodes ) = @_;

    foreach my $node ( @$nodes ) {
        next unless $node->isa( 'ExtUtils::XSpp::Node::Function' );
        $node->set_perl_name( $node->cpp_name . '_perl' );
    }
}

1;
