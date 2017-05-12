package Labyrinth::IPAddr;

use warnings;
use strict;

use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT @EXPORT_OK);
$VERSION = '5.32';

=head1 NAME

Labyrinth::IPAddr - IP Address Functions for Labyrinth

=head1 SYNOPSIS

  use Labyrinth::IPAddr;

  CheckIP();
  BlockIP($who,$ipaddr);
  AllowIP($who,$ipaddr);

=head1 DESCRIPTION

The IPAddr package contains generic functions used for verifying known IP
addresses. Used to allow known safe address to use the site without hindrance
and to refuse access to spammers.

Eventually this may be rewritten as a memcached stand-alone application, to be
used across multiple sites.

=head1 EXPORT

  CheckIP
  BlockIP
  AllowIP

=cut

# -------------------------------------
# Constants

use constant BLOCK => 1;
use constant ALLOW => 2;

# -------------------------------------
# Export Details

require Exporter;
@ISA = qw(Exporter);
@EXPORT    = ( qw( CheckIP BlockIP AllowIP BLOCK ALLOW) );

# -------------------------------------
# Library Modules

use Labyrinth::Globals;
use Labyrinth::DBUtils;
use Labyrinth::Variables;

use JSON::XS;
use URI::Escape;
use WWW::Mechanize;

# -------------------------------------
# The Subs

=head1 FUNCTIONS

=over 4

=item CheckIP

Checks whether the current request sender IP address is know, and if so returns
the classification. Return codes are:

  0 - Unknown
  1 - Blocked
  2 - Allowed

=cut

sub CheckIP {
    if($settings{blockurl}) {
        my $res = _request($settings{blockurl},'check',$settings{ipaddr});
        return $res && $res->{success} ? $res->{result} : 0;
    }

    my @rows = $dbi->GetQuery('hash','FindIPAddress',$settings{ipaddr});
    return @rows ? $rows[0]->{type} : 0;
}


=item BlockIP

Block current request sender IP address.

=cut

sub BlockIP {
    my $who     = shift || 'UNKNOWN';
    my $ipaddr  = shift || return;

    if($settings{blockurl}) {
        my $res = _request($settings{blockurl},'block',$ipaddr,$who);
        return $res && $res->{success} ? $res->{result} : 0;
    }

    if(my @rows = $dbi->GetQuery('array','FindIPAddress',$ipaddr)) {
        $dbi->DoQuery('SaveIPAddress',$who,1,$ipaddr);
    } else {
        $dbi->DoQuery('AddIPAddress',$who,1,$ipaddr);
    }

    return 1;
}

=item AllowIP

Allow current request sender IP address.

=cut

sub AllowIP {
    my $who     = shift || 'UNKNOWN';
    my $ipaddr  = shift || return;

    if($settings{blockurl}) {
        my $res = _request($settings{blockurl},'allow',$ipaddr,$who);
        return $res && $res->{success} ? $res->{result} : 0;
    }

    if(my @rows = $dbi->GetQuery('array','FindIPAddress',$ipaddr)) {
        $dbi->DoQuery('SaveIPAddress',$who,2,$ipaddr);
    } else {
        $dbi->DoQuery('AddIPAddress',$who,2,$ipaddr);
    }

    return 1;
}

sub _request {
    my $url = shift;
    $url .= '/' . join('/', map { uri_escape_utf8($_) } @_);

    my $mech = WWW::Mechanize->new();
    $mech->get($url);
    if($mech->success()) {
        my $json = $mech->content();
        my $data = decode_json($json);
        return $data;
    }

    return;
}

1;

__END__

=back

=head1 SEE ALSO

  Labyrinth

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
