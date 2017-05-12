package JavaScript::Ectype::Handler::Apache2;
use strict;
use warnings;
use JavaScript::Ectype::Loader;
use Apache2::Const -compile => qw(OK);
use Apache2::Request;
use Apache2::RequestIO   ();
use Apache2::RequestRec  ();
use Apache2::RequestUtil ();
use Apache2::Response ();
use HTTP::Date;
our $VERSION = q(0.0.1);
use constant EXPIRE_TIME => 60*60*24*14;


sub _uri_to_path_and_file {
    my ( $request ) = @_;
    my $lib_path = $request->dir_config->get('EctypeLibPath');
    my $prefix   = $request->dir_config->get('EctypePrefix');
    my $minify   = $request->dir_config->get('EctypeMinify');
    if( $request->uri =~ m/$prefix([a-zA-Z0-9_.]+)/ ){
        my $uri = $1;
        return ( $lib_path , $uri, $minify);
    }
}

sub _not_found {
    my ($class,$r ) = @_;
    $r->status(404);
    return Apache2::Const::OK;
}

sub _not_modified {
    my ($class,$r ) = @_;
    $r->status(304);
    $r->err_headers_out->set('Expires', HTTP::Date::time2str( time() + &EXPIRE_TIME ) );
    return Apache2::Const::OK;
}

sub handler : method {
    my ($class, $r) = @_;
    my ($lib_path,$fqn,$minify) = _uri_to_path_and_file( $r );
 
    my $jel = JavaScript::Ectype::Loader->new(
        path   => $lib_path,
        target => $fqn,
        minify => int($minify)
    );
    my $ims = HTTP::Date::str2time($r->headers_in->{'If-Modified-Since'}) || 0;

    return $class->_not_found($r)    unless ( $lib_path or $fqn );
    return $class->_not_found($r)    unless -e $jel->file_path;
    return $class->_not_modified($r) unless $jel->is_modified_from($ims);

    $jel->load_content;

    my $content = $jel->get_content;
    my $last_modified = $jel->newest_mtime;
    $r->status(200);
    $r->content_type('text/javascript');
    $r->headers_out->set('Content-length', length $content );
    $r->headers_out->set('Last-Modified',  HTTP::Date::time2str($last_modified) );
    $r->headers_out->set('Expires',        HTTP::Date::time2str( time() + &EXPIRE_TIME ) );
    $r->print( $content );
    return Apache2::Const::OK;
}


1;

__END__
=head1 NAME

JavaScript::Ectype::Handler::Apache2 - An Apache2 Handler JavaScript Preprocessor designed for large scale javascript development

=head1 SYNOPSYS

    # in httpd.conf
    <LocationMatch "/ectype/[a-zA-Z0-9.]+">
        SetHandler perl-script 
        PerlResponseHandler  JavaScript::Ectype::Handler::Apache2
        PerlSetVar EctypeLibPath "$DOCUMENT_ROOT/static/js"
        PerlSetVar EctypePrefix  "/ectype/"
        PerlSetVar EctypeMinify 0
    </LocationMatch>

For example , you access http://example.com/ectype/org.cpan.ajax,
get response $DOCUMENT_ROOT/static/js/org/cpan/ajax.js converted by JavaScript::Ectype.

=head1 VARIABLES

In httpd.conf, you can set some variables to control JavaScript::Ectype.

=head2 EctypeLibPath

EctypeLibPath is where javascript files are.

=head2 EctypePrefix

EctypePrefix is url prefix.

=head2 EctypeMinify

EctypeMinify is whether minify javascript code or not.

=head1 AUTHOR

Daichi Hiroki, C<< <hirokidaichi<AT>gmail.com> >>

=head1 SEE ALSO

L<JavaScript::Ectype>

=head1 LICENSE AND COPYRIGHT

Copyright 2009 Daichi Hiroki.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut



