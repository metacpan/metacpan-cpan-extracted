package Foorum::Controller::StaticInfo;

use strict;
use warnings;
our $VERSION = '1.001000';
use parent 'Catalyst::Controller';

sub help : Global {
    my ( $self, $c, $help_id ) = @_;

    __serve_static_info( $c, 'help', $help_id );
}

sub info : Global {
    my ( $self, $c, $info_id ) = @_;

    __serve_static_info( $c, 'info', $info_id );
}

sub __serve_static_info {
    my ( $c, $type, $type_id ) = @_;

    $c->cache_page('1800');    # cache 30 minutes

    $c->stash->{template}                  = "$type/index.html";
    $c->stash->{additional_template_paths} = [
        $c->path_to( 'templates', 'lang', $c->stash->{lang} ),
        $c->path_to( 'templates', 'lang', 'en' )
    ];

    if ( $c->req->param('format') eq 'raw' ) {
        $c->stash->{simple_wrapper} = 1;
    }

    # help/info templates in under its own templates/$lang/help
    # since too many text needs translation.
    if ($type_id) {
        $type_id =~ s/\W+//isg;
        if (-e $c->path_to(
                'templates', 'lang', $c->stash->{lang}, $type,
                "$type_id.html"
            )
            or ($c->stash->{lang} ne 'en'
                and -e $c->path_to(
                    'templates', 'lang', 'en', $type, "$type_id.html"
                )
            )
            ) {
            $c->stash->{template} = "$type/$type_id.html";
        }
    }
}

1;
__END__

=pod

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
