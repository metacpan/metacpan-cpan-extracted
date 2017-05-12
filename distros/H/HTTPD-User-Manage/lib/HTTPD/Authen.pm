package HTTPD::Authen;
use HTTPD::UserAdmin ();
use strict;
use vars qw($VERSION @ISA $Debug);
$Debug = 0;
$VERSION = (qw$Revision: 1.1.1.1 $)[1];

sub new {
    my($class) = shift;
    my(%attr);
    if(ref $_[0]) {
 	my($k,$v);
 	while (($k,$v) = each %{$_[0]}) {
 	    next if substr($k,0,1) eq "_";
 	    $attr{$k} = $v;
 	}
  	shift;
 	while ($k = shift @_) {
 	    $v = shift @_;
 	    $attr{$k} = $v;
 	}
    }
    else {
	%attr = @_;
    }
    $attr{ENCRYPT} ||= 'crypt';
    bless {
	USER => HTTPD::UserAdmin->new(%attr, LOCKING => 0, FLAGS => 'r'), 
	%attr,
    } => $class;
}

sub parse {
    my($self,$string) = @_;
    $self->type($string)->parse($string);
}

sub type {
    my($self,$hdr) = @_;
    $hdr =~ /^(\w+) /;
    my($type) = lc $1;
    print STDERR "type -> $type\n" if $Debug;
    $self->$type();
}

sub check {
    my($self,$username,$guess) = @_;
    my($method) = $self->{ENCRYPT};
    my($passwd) = $self->{USER}->password($username);
    if($method eq 'crypt') {
	return (crypt($guess, $passwd) eq $passwd);
    }
    elsif ($method eq 'none') {
	return $passwd eq $guess;
    }
    else {
      Carp::croak("Unknown encryption method '$self->{ENCRYPT}'");
    }
}

sub digest { HTTPD::Authen::Digest->new($_[0]) }
sub basic  { HTTPD::Authen::Basic->new($_[0])  }

package HTTPD::Authen::Basic;
use strict;
use vars qw(@ISA $Debug);
@ISA = qw(HTTPD::Authen);
*Debug = \$HTTPD::Authen::Debug;

sub new {
    require MIME::Base64;
    my($class,$ref) = @_;
    $ref ||= {};
    bless $ref => $class;
}

sub parse {
    my($self,$string) = @_;
    $string =~ s/^Basic\s+//;
    return split(":", MIME::Base64::decode_base64($string), 2);
}

package HTTPD::Authen::Digest;
use strict;
use vars qw(@ISA $Debug);
@ISA = qw(HTTPD::Authen);
*Debug = \$HTTPD::Authen::Debug;

sub new {
    my($class,$ref) = @_;
    $ref ||= {};
    require MD5;
    $ref->{MD5} = new MD5;
    bless $ref => $class;
}

sub parse {
   my($self,$string) = @_;
   $string =~ s/^Digest\s+//; 
   $string =~ s/"//g; #"
   my(@pairs) = split(/,?\s+/, $string);
   my(%pairs) = map { split(/=/) } @pairs;
   print STDERR "Digest::parse -> @pairs{qw(username realm response)}\n" if $Debug;
   return \%pairs; 
}

sub check {
    my($self,$mda,$request,$max_nonce_time,$client_ip) = @_;
    #$max_nonce_time ||= (15*60);
    $request ||= {};
    my($method,$uri);

    if(ref $request eq 'HASH') {
	$request->{method} ||= 'GET';
	$request->{uri}    ||= $mda->{uri};
	($method,$uri) = @{$request}{qw(method uri)};
    }
    else {
	#must be an HTTP::Request object
	($method,$uri) = ($request->method(), $request->uri());
    }
    if(defined $max_nonce_time) {
	return (0, "nonce is stale!")
	    unless($self->check_nonce($mda,$max_nonce_time));
    }
    if(defined $client_ip) {
	return (0, "invalid opaque string!")
	    unless($self->check_opaque($mda,$client_ip));
    }
    my $md = \$self->{MD5};

    my $username = $mda->{username};
    my($realm,$passwd) = split(":", $self->{USER}->password($username));
    print STDERR "lookup '$username': $passwd,$realm\n" if $Debug;
    #return 0 unless $realm eq $mda->{realm};

    print STDERR "request: $method $uri\n" if $Debug;
    $$md->add(join(":", $method,$uri));
    my $digest = $$md->hexdigest();

    print STDERR "All: $passwd, $mda->{nonce}, $digest\n" if $Debug;
    $$md->reset;
    $$md->add(join(":", $passwd, $mda->{nonce}, $digest));
    $digest = $$md->hexdigest();
    $$md->reset;

    print STDERR "MD5 check: $digest eq $mda->{response}\n" if $Debug;
    $digest eq $mda->{response};
}

sub check_nonce {
    my($self,$mda,$max) = @_;
    $max ||= (15*60);
    my($time) = time();
    ! (($mda->{nonce} > $time) || ($mda->{nonce} < ($time - $max)));
}

sub check_opaque {
    my($self, $mda, $ip) = @_;
    return unless defined $ip;
    my $md = \$self->{MD5};
    $$md->add( join(":", @{$mda}{qw(realm nonce)}, $ip) );
    my $digest = $$md->hexdigest();
    print STDERR "check_opaque: @{$mda}{qw(realm nonce)} $ip\n",
                 "check_opaque:  $digest eq $mda->{opaque}\n" if $Debug;
    $$md->reset;
    $digest eq $mda->{opaque};
}

#sub md5check {}
    
1;


__END__

=head1 NAME 

HTTPD::Authen - HTTP server authentication class

=head1 SYNOPSIS

    use HTTPD::Authen ();


=head1 DESCRIPTION

This module provides methods for authenticating a user.
It uses HTTPD::UserAdmin to lookup passwords in a database.
Subclasses provide methods specific to the authentication mechanism.

Currently, under HTTP/1.0 the only supported authentication mechanism is 
Basic Authentication.  NCSA Mosaic and NCSA HTTPd understand the proposed 
Message Digest Authentication, which should make it into the HTTP spec someday.
This module supports both.

=head1 METHODS

=head2 new ()

Since HTTPD::Authen uses HTTPD::UserAdmin for database lookups it needs many
of the same attributes.
Or, if the first argument passed to the new() object constructor is a 
reference to an HTTPD::UserAdmin, the attributes are inherited.

The following attributes are recognized from HTTPD::UserAdmin:

B<DBType>, B<DB>, B<Server>, B<Path>, B<DBMF>, B<Encrypt> 

And if you wish to query an SQL server:
B<Host>, B<User>, B<Auth>, B<Driver>, B<UserTable>, B<NameField>, B<PasswordField>

The same defaults are assumed for these attributes, as in HTTPD::UserAdmin.
See I<HTTPD::UserAdmin> for details.

    $authen = new HTTPD::Authen (DB => "www-users");
    
=head2 basic()

Short-cut to return an HTTPD::Authen::Basic object.

    $basic = $authen->basic;

=head2 digest()

Short-cut to return an HTTPD::Authen::Digest object.

    $digest = $authen->digest;

=head2 type($authorization_header_value)

This method will guess the authorization scheme based on the 'Authorization' 
header value, and return an object bless into that scheme's class.

By using this method, it is simple to authenticate a user without even knowing what scheme is
being used:

     $authtype = HTTPD::Authen->type($authinfo);
     @info = $authtype->parse($authinfo)
     if( $authtype->check(@info) ) {
         #response 200 OK, etc.
     }


=head1 SUBCLASSES


=item HTTPD::Authen::Basic methods


=head2 new([$hashref])

$hashref should be an HTTPD::Authen object, it must be present when looking up 
users.  Optionally, you can pass the attribute B<USER> with the value of an 
HTTPD::UserAdmin object.

Normally, this method is not called directly, but rather by HTTPD::Authen->basic method.

=head2 parse ($authorization_header_value)

This method expects the value of the HTTP 'Authorization' header of type
Basic.  This should look something like: 

 'Basic ZG91Z206anN0NG1l'  

This string will be parsed and decoded, returning the username and password.  Note that
the I<MIME::Base64> module is required for decoding.

    ($username,$password) = HTTPD::Authen::Basic->parse($authinfo)
    
    #or, assuming $authen is an HTTPD::Authen object
    ($username,$password) = $authen->basic->parse($authinfo)

    #or check the info at the same time
    $OK = $authen->check($authen->basic->parse($authinfo))


=head2 check($username,$password)

This method expects a username and *clear text* password as arguments.
Returns true if the username was found, and passwords match, otherwise
returns false.

    if($authen->check("JoeUser", "his_clear_text_password")) {
	print "Well, the passwords match at least\n";
    }
    else {
	print "Password mismatch! Intruder alert! Intruder alert!\n";
    }


=item HTTPD::Authen::Digest methods


B<NOTE>: The B<MD5> module is required to use these methods.

=head2 new([$hashref])

$hashref should be an HTTPD::Authen object.
Normally, this method is not called directly, but rather by HTTPD::Authen->digest method.

=head2 parse ($authorization_header_value)

This method expects the value of the HTTP 'Authorization' header of type
Basic.  This should look something like: 

  Digest username="JoeUser", realm="SomePlace", nonce="826407380", uri="/test/blah.html", response="0306f29f88690fb9203451556c376ae9", opaque="5e09061a062a271c8fcc686c5be90c2a"

This method returns a hash ref containing all Name = Value pairs from the header.

     $mda = HTTPD::Authen::Digest->parse($authinfo);

     #or, assuming $authen is an HTTPD::Authen object
     $mda = $authen->digest->parse($authinfo)

     #or check the info at the same time
     $OK = $authen->check($authen->digest->parse($authinfo))

=head2 check ($hashref[, $request [, $seconds [, $client_ip ]]]) 

This method expects a hashref of Name Value pairs normally found in the 'Authorization'
header.  With this argument alone, the method will return true without checking nonce or
the opaque string if the client 'response' checksum matches ours.

If $request is present, it must be a hashref or an B<HTTP::Request> method.  From here, we fetch
the request uri and request method.  
Otherwise, we default to the value of 'uri' present in $hashref, and 'GET' for the method.

If $seconds is present, the value of 'nonce' will be checked, returning false if it is stale.

If $client_ip is present, the value of the 'opaque' string will be checked, returning false if
the string is not valid.

This implementation is based on the Digest Access Authentication internet-draft
http://hopf.math.nwu.edu/digestauth/draft.rfc
and NCSA's implementation
http://hoohoo.ncsa.uiuc.edu/docs/howto/md5_auth.html

=head1 SEE ALSO

HTTPD::UserAdmin, MD5, HTTP::Request, MIME::Base64

=head1 AUTHOR

Doug MacEachern <dougm@osf.org>

Copyright (c) 1996, Doug MacEachern, OSF Research Institute

This library is free software; 
you can redistribute it and/or modify it under the same terms as Perl itself. 

=cut
