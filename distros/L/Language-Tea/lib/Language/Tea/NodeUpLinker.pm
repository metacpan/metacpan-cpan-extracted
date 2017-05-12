package Language::Tea::NodeUpLinker;

use strict;
use warnings;
use Scalar::Util qw(blessed);
use Language::Tea::Traverse;

sub create_links {
    my $root = shift;
    Language::Tea::Traverse::visit_prefix(
        $root,
        sub {
            my ( $node, $parent ) = @_;
            if ( blessed $node) {
                $node->{__node_parent__} = $parent;
            }
            return;
        },
        undef
    );
}

1;
