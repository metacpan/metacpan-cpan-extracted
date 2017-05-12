# $Id: Site.pm,v 1.4 2007-05-29 17:16:31 mike Exp $

package Keystone::Resolver::DB::Site;

use strict;
use warnings;
use Keystone::Resolver::DB::Object;

use vars qw(@ISA);
@ISA = qw(Keystone::Resolver::DB::Object);


sub table { "site" }
sub fields { (id => undef,
	      tag => undef,
	      name => undef,
	      bg_colour => undef,
	      email_address => undef,
	      ) }


# ----------------------------------------------------------------------------
# Application logic below this fold

sub create_session {
    my $this = shift();

    return Keystone::Resolver::DB::Session->create($this->db(),
						   site_id => $this->id());
}


sub session1 {
    my $this = shift();
    return $this->db()->session1(@_, site_id => $this->id());
}


sub user1 {
    my $this = shift();
    return $this->db()->user1(@_, site_id => $this->id());
}


sub add_user {
    my $this = shift();
    my(%data) = @_;

    return create Keystone::Resolver::DB::User($this->db(), %data,
					       site_id => $this->id());
}


sub search {
    my $this = shift();
    my $findclass = shift();

    return new Keystone::Resolver::ResultSet($this, $findclass, @_);
}


sub send_email {
    use Net::SMTP;

    my $this = shift();
    my($to, $subject, $text) = @_;

    my $from = $this->email_address();
    my $data = "From: $from\nTo: $to\nSubject: $subject\n\n$text";
    my $smtp = new Net::SMTP("localhost", Hello => "resolver.indexdata.com")
	or die "can't make SMTP object";
    $smtp->mail($from) or die "can't send email from $from";
    $smtp->to($to) or die "can't use SMTP recipient '$to'";
    $smtp->data($data) or die "can't email data to '$to'";
    $smtp->quit() or die "can't send email to '$to'";
}


1;
