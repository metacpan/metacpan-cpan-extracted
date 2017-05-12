# -*- perl -*-
#
#   HTML::EP	- A Perl based HTML extension.
#
#
#   Copyright (C) 1998    Jochen Wiedmann
#                         Am Eisteich 9
#                         72555 Metzingen
#                         Germany
#
#                         Phone: +49 7123 14887
#                         Email: joe@ispsoft.de
#
#   All rights reserved.
#
#   You may distribute this module under the terms of either
#   the GNU General Public License or the Artistic License, as
#   specified in the Perl README file.
#
############################################################################

require 5.004;
use strict;


use CGI::Cookie ();


package HTML::EP::Session::Cookie;


sub encode {
    my($self, $in, $attr) = @_;
    my $out = Storable::nfreeze($in);
    if ($attr->{'zlib'}) {
	require Compress::Zlib;
	$out = Compress::Zlib::compress($out);
    }
    if ($attr->{'base64'}) {
	require MIME::Base64;
	$out = MIME::Base64::encode_base64($out);
    } else {
	$out = unpack("H*", $out);
    }
    $out;
}

sub decode {
    my($self, $in, $attr) = @_;
    my $out;
    if ($attr->{'base64'}) {
	require MIME::Base64;
	$out = MIME::Base64::decode_base64($in);
    } else {
	$out = pack("H*", $in);
    }
    if ($attr->{'zlib'}) {
	require Compress::Zlib;
	$out = Compress::Zlib::uncompress($out);
    }
    Storable::thaw($out);
}

sub new {
    my($proto, $ep, $id, $attr) = @_;
    my $class = (ref($proto) || $proto);
    my $session = {};
    bless($session, $class);
    my $freezed_session = $proto->encode($session, $attr);
    my %opts;
    $opts{'-name'} = $id;
    $opts{'-expires'} = $attr->{'expires'} || '+1h';
    $opts{'-domain'} = $attr->{'domain'} if exists($attr->{'domain'});
    $opts{'-path'} = $attr->{'path'} if exists($attr->{'path'});
    my $cookie = CGI::Cookie->new(%opts,
				  '-value' => $freezed_session);
    $ep->{'_ep_cookies'}->{$id} = $cookie;
    $opts{'zlib'} = $attr->{'zlib'};
    $opts{'base64'} = $attr->{'base64'};
    $session->{'_ep_data'} = \%opts;
    $session;
}

sub Open {
    my($proto, $ep, $id, $attr) = @_;
    my $cgi = $ep->{'cgi'};
    my $cookie = $cgi->cookie('-name' => $id);

    return $proto->new($ep, $id, $attr) unless $cookie;

    my $class = (ref($proto) || $proto);
    my %opts;
    $opts{'-name'} = $id;
    $opts{'-expires'} = $attr->{'expires'} || '+1h';
    $opts{'-domain'} = $attr->{'domain'} if exists($attr->{'domain'});
    $opts{'-path'} = $attr->{'path'} if exists($attr->{'path'});
    if (!$cookie) {
	die "Missing cookie $id." .
	    " (Perhaps Cookies not enabled in the browser?)";
    }
    my $session = $proto->decode($cookie, $attr);
    bless($session, $class);
    $opts{'zlib'} = $attr->{'zlib'};
    $opts{'base64'} = $attr->{'base64'};
    $session->{'_ep_data'} = \%opts;
    $session;
}

sub Store {
    my($self, $ep, $id, $locked) = @_;
    my $data = delete $self->{'_ep_data'};
    my $freezed_session = $self->encode($self, $data);
    my $zlib = delete $data->{'zlib'};
    my $base64 = delete $data->{'base64'};
    my $cookie = CGI::Cookie->new(%$data,
				  '-value' => $freezed_session);
    $ep->{'_ep_cookies'}->{$id} = $cookie;
    if ($locked) {
	$data->{'zlib'} = $zlib if defined $zlib;
	$data->{'base64'} = $base64 if defined $base64;
	$self->{'_ep_data'} = $data;
    }
}


sub Delete {
    my($self, $ep, $id) = @_;
    my $data = delete $self->{'_ep_data'};
    my $cookie = CGI::Cookie->new('-name' => $id,
				  '-expires' => '-1m',
				  '-value' => '');
    $self->{'_ep_cookies'}->{$id} = $cookie;
}


1;
