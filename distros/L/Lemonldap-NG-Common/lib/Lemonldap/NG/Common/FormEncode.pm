package Lemonldap::NG::Common::FormEncode;

use strict;
use Exporter;

our @ISA     = qw(Exporter);
our $VERSION = '2.0.0';

our @EXPORT_OK = qw(build_urlencoded);
our @EXPORT    = qw(build_urlencoded);

BEGIN {
    require Plack::Request;
    if ( $Plack::Request::VERSION < '1.0040' ) {
        require URI::Escape;
        eval <<'EOT';
sub build_urlencoded {
    my(%h)=@_;
    return join('&',map {my $v=URI::Escape::uri_escape($h{$_});"$_=$v"} keys %h);
}
EOT
    }
    else {
        require WWW::Form::UrlEncoded;
        *build_urlencoded = \&WWW::Form::UrlEncoded::build_urlencoded;
    }
}

1;
