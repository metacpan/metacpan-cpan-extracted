package Mail::QmailRemote;

use strict;
use vars qw($VERSION);

use Net::DNS;
use IPC::Open3;

$VERSION = '0.02';

sub new {
    my $class = shift;
    my $bin = shift || '/var/qmail/bin/qmail-remote';
    my $self = bless {
		      bin => $bin,
		      rcpt_map => undef,
		     },$class;
    $self;
}

sub mail {
    my $self = shift;
    if (@_) {
	$self->{mail} = shift;
    }
    $self->{mail};
}

*sender = \&mail;

sub recipient {
    my $self = shift;
    if (@_) {
	if ($self->{recipient}) {
	    push(@{$self->{recipient}},@_);
	} else {
	    $self->{recipient} = [ @_ ];
	}
    }
    $self->{recipient};
}

*to = \&recipient;

sub data {
    my $self = shift;
    if ($_[0]) {
	$self->{data} = shift;
    }
    $self->{data} =~ s/\r\n/\n/g;
    $self->{data} .= "\n";
    $self->{data};
}

sub send {
    my $self = shift;
    $self->_rcpt_map;
    $self->_do_send;
    delete $self->{data};
    delete $self->{mail};
    delete $self->{rcpt_map};
}

sub errstr {
    my $self = shift;
    $self->{error};
}

sub _do_send {
    my $self = shift;
    foreach my $host(keys %{$self->{rcpt_map}}) {
	my $mailhosts = $self->_find_MX($host);
	unless ($mailhosts) {
	    $mailhosts = $self->_find_A($host);
	}
	foreach my $mailhost(@$mailhosts) {
	    my $res = $self->_qmail_remote($mailhost,$self->{mail},@{$self->{rcpt_map}->{$host}});
	    last if $res;
	}
    }
}

sub _qmail_remote {
    my $self = shift;
    my ($host,$from,@to) = @_;
    
    my $w = IO::Handle->new;
    my $r = IO::Handle->new;
    my $e = IO::Handle->new;

    open3($w,$r,$e,
	  $self->{bin},$host,$from,@to);
    $w->print($self->{data});
    $w->close;
    
    my $res = $r->getline;
    $r->close;
    $e->close;
    if ($res =~ /^r/) {
	$self->{error} = undef;
    }
    else {
	warn "$res\n";
	$self->{error} = $res;
    }
    return ($self->{error} ? 1 : undef);
}


sub _rcpt_map{
    my $self = shift;
    foreach my $rcpt(@{$self->{recipient}}) {
	my($name,$host) = split(/\@/,$rcpt);
	push(@{$self->{rcpt_map}->{$host}},$rcpt);
    }
    return $self->{rcpt_map};
}

sub _find_MX {
    my $self = shift;
    my $host = shift;
    my $res = Net::DNS::Resolver->new;
    my @mx = mx($res,$host);
    unless (@mx) {
	warn "not found MX of $host.\n";
	return undef;
    }
    # order by preference.
    return [map{$_->[0]}
      sort {$a->[1] <=> $b->[1]}
	map {[$_->exchange,$_->preference]} @mx];
}

sub _find_A {
    my $self = shift;
    my $host = shift;
    my $res = Net::DNS::Resolver->new;
    my $query = $res->query($host,"A");
    unless ($query) {
	return undef;
    }
    my @a_records;
    foreach my $ans($query->answer) {
	push(@a_records,$ans->name);
    }
    return \@a_records;
}

1;
__END__

=head1 NAME

Mail::QmailRemote - Perl extension to send email using qmail-remote directly.

=head1 SYNOPSIS

  use Mail::QmailRemote;
  use Mime::Lite;

  # generate mail.
  my $mime = MIME::Lite->new(
			     ...
			    );

  # send mail using qmail-remote
  my $remote = Mail::QmailRemote->new;
  $remote->sender($ENV{USER});
  $remote->recipient('postmaster@foo.bar');
  $remote->data($mime->as_string);
  $remote->send;

=head1 DESCRIPTION

this module send email, using qmail-remote program directly.
MX or A Record is searched by Net::DNS module.

=head1 CONSTRUCTOR

=item new(QMAIL_REMOTE)

construtor for Mail::QmailRemote object.
QMAIL_REMOTE is location of qmail-remote program 
(default /var/qmail/bin/qmail-remote)

=back

=head1 METHODS

=over 4

=item sender(ADDRESS)

set sender's mail address.

=item mail(ADDRESS)

Synonym for sender.

=item recipient(ADDRESS [,ADDRESS, [...]])

set recipient's mail address.

=item to(ADDRESS [,ADDRESS, [...]])

Synonym for recipient.

=item data(DATA)

set mail message. (including header.)

=item send

send mail.

=item errstr

if some problem has occured, return error message from qmail-remote.

=back

=head1 AUTHOR

IKEBE Tomohiro <ikebe@cpan.org>

=head1 SEE ALSO

L<Net::DNS> L<IPC::Open3> L<Mail::QmailQueue>

L<qmail-remote(8)>

=head1 COPYRIGHT

Copyright(C) 2001 IKEBE Tomohiro All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

=cut


