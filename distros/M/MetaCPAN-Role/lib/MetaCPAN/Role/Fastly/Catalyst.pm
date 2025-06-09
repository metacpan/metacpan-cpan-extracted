package MetaCPAN::Role::Fastly::Catalyst;
$MetaCPAN::Role::Fastly::Catalyst::VERSION = '1.00';
use Moose::Role;

# For dzil [AutoPreq]
use CatalystX::Fastly::Role::Response 0.07;

with 'MetaCPAN::Role::Fastly';
with 'CatalystX::Fastly::Role::Response';

requires '_format_auth_key';
requires '_format_dist_key';

=head1 NAME

MetaCPAN::Role::Fastly::Catalyst - Methods for catalyst fastly API intergration

=head1 SYNOPSIS

  use Catalyst qw/
    +MetaCPAN::Role::Fastly::Catalyst
    /;

=head1 DESCRIPTION

This role includes L<CatalystX::Fastly::Role::Response> and
L<MetaCPAN::Role::Fastly> and therefor L<MooseX::Fastly::Role>.

Before C<finalize> this will add the content type as surrogate keys and perform
a purge of anything added to the purge list. The headers are actually added
by L<CatalystX::Fastly::Role::Response>

=cut

=head2 $c->add_author_key('Ether');

See L<MetaCPAN::Role::Fastly/purge_author_key>

=cut

sub add_author_key {
    my ( $c, $author ) = @_;

    $c->add_surrogate_key( $c->_format_auth_key($author) );
}

=head2 $c->add_dist_key('Moose');

See L<MetaCPAN::Role::Fastly/purge_dist_key>

=cut

sub add_dist_key {
    my ( $c, $dist ) = @_;

    $c->add_surrogate_key( $c->_format_dist_key($dist) );
}


before 'finalize' => sub {
    my $c = shift;

    $c->perform_purges(); # will do any purges that has been setup

    if ( $c->cdn_max_age ) {

        # We've decided to cache on Fastly, so throw fail overs
        # if there is an error at origin
        $c->cdn_stale_if_error('30d');

        # And lets serve stale content whilst we revalidate as our content
        # really doesn't update that often
        $c->cdn_stale_while_revalidate('1d');
    }

    my $content_type = lc( $c->res->content_type || 'none' );

    $c->add_surrogate_key( 'content_type=' . $content_type );

    $content_type =~ s/\/.+$//;    # text/html -> 'text'
    $c->add_surrogate_key( 'content_type=' . $content_type );
};



1;