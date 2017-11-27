package MVC::Neaf::View::JS;

use strict;
use warnings;

our $VERSION = 0.19;

=head1 NAME

MVC::Neaf::View::JS - JSON-base view for Not Even A Framework.

=head1 SYNOPSIS

    return {
        # your data ...
        -view => 'JS',
        -jsonp => 'my.jsonp.callback', # this is optional
    }

Will result in your application returning raw data in JSON/JSONP format
instead or rendering a template.

=head1 METHODS

=cut

use JSON;

use parent qw(MVC::Neaf::View);

my $codec = JSON->new->allow_blessed->convert_blessed
    ->allow_unknown->allow_nonref;
my $js_id_re = qr/[A-Z_a-z][A-Z_a-z\d]*/;
my $jsonp_re = qr/^$js_id_re(?:\.$js_id_re)*$/;

=head2 new( %options )

%options may include:

=over

=item * preserve_dash - don't strip dashed options. Useful for debugging.

=back

B<NOTE> No input checks are made whatsoever,
but this MAY change in the future.

=cut

=head2 render( \%data )

Returns a scalar with JSON-encoded data.

=cut

sub render {
    my ($self, $data) = @_;

    my $callback = $data->{-jsonp};
    my $type = $data->{-type};

    if( exists $data->{-serial} ) {
        $data = $data->{-serial}
    } else {
        $self->{preserve_dash} or $data = do {
            my %shallow_copy;
            /^-/ or $shallow_copy{$_} = $data->{$_}
                for keys %$data;
            \%shallow_copy;
        };
    }

    my $content = $codec->encode( $data );
    return $callback && $callback =~ $jsonp_re
        ? ("$callback($content);", "application/javascript; charset=utf-8")
        : ($content, "application/json; charset=utf-8");
};

1;
