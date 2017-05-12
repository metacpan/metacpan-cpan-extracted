use strict;
use warnings;

package JavaScript::Writer::jQueryHelper;

our $VERSION = '0.0.2';

use JavaScript::Writer;

use Sub::Exporter -setup => {
    exports => ['jQuery'],
    groups  => {
        default =>  [ -all ],
    }
};

sub jQuery {
    my $js = JavaScript::Writer::_js;
    my $s = shift;

    if (defined $js) {
        return $js->jQuery( $s ) if defined $s;
        return $js->object('jQuery');
    }

    return js->jQuery($s) if defined $s;
    return js->object('jQuery');
}

1;

__END__

=head1 NAME

JavaScript::Writer::jQueryHelper - A "jQuery" helper method for writing jQuery code.

=head1 SYNOPSIS

    use JavaScript::Writer;
    use JavaScript::Writer::jQueryHelper;

    # This is Perl code
    jQuery("#area')->load("/data/foo.html");

=head1 METHOD

=over

=item jQuery(...)

The only method exported by this helper module, acts pretty much like
jQuery in javascript. It constructs a C<JavaScript::Writer> object
like the way C<js> does.

=back

=head1 AUTHOR and LICENSE

See L<JavaScript::Writer>

=cut

