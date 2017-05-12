package Mail::QmailQueue;
# $Id: QmailQueue.pm,v 1.2 2002/04/05 13:07:58 ikechin Exp $
use strict;
use vars qw($VERSION);
use IO::Pipe;
use IO::Handle;
use Carp;

$VERSION = '0.03';

sub new {
    my $class = shift;
    my $bin = shift || "/var/qmail/bin/qmail-queue";
    my $self = {
	bin => $bin
    };
    bless $self,$class;
}
  
sub mail {
    my $self = shift;
    if ($_[0]) {
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
	my $data = $_[0];
	if (ref($data) eq 'ARRAY') {
	    for my $d(@{$data}) {
		$d =~ s/\r\n/\n/g;
		$self->{data} .= $d;
	    }
	}
	else {
	    $data =~ s/\r\n/\n/g;
	    $self->{data} .= $data;
	}
    }
    $self->{data};
}

sub datasend {
    my $self = shift;
    $self->data(shift);
    $self->send;
}

sub send {
    my $self = shift;
    my $data = IO::Pipe->new;
    my $addr = IO::Pipe->new;
    
    foreach my $key (qw(recipient mail data)) {
	if (!$self->{$key}) {
	    carp "please specify $key";
	}
    }
    $self->{data} .= "\n" unless $self->{data} =~ m/\n$/s;
    if (my $pid = fork) {
	$data->writer;
	$addr->writer;
	
	$data->print($self->data);
	$data->close;
	
	$addr->print("F" . $self->mail . "\0");
	foreach my $rcpt (@{$self->recipient}) {
	    $addr->print("T" . $rcpt . "\0");
	}
	$addr->print("\0");
	$addr->close;
	
	delete $self->{mail};
	delete $self->{recipient};
	delete $self->{data};
	
	wait;
    } elsif (defined $pid) {
	my $fd0 = IO::Handle->new->fdopen(0,"w");
	my $fd1 = IO::Handle->new->fdopen(1,"w");
	$data->reader();
	$addr->reader();
	$fd0->fdopen(fileno($data),"r");
	$fd1->fdopen(fileno($addr),"r");
	exec($self->{bin}) || carp $!;
	exit;
    } else {
	carp "Cannot fork!!";
    }
}


sub quit {
    # do nothing
    1;
}

1;
__END__

=head1 NAME

Mail::QmailQueue - Perl extension to operate qmail-queue directly

=head1 SYNOPSIS

  use Mail::QmailQueue;
  use Mime::Lite;

  # generate mail.
  my $mime = MIME::Lite->new(
      #...
  );

  # send mail via qmail-queue.
  my $qmail = Mail::QmailQueue->new;
  $qmail->sender($ENV{USER});
  $qmail->recipient('postmaster@foo.bar');
  $qmail->data($mime->as_string);
  $qmail->send;

=head1 DESCRIPTION

This module operate qmail-queue directly,
so, you can send mail more faster than the case where SMTP is used.

=head1 CONSTRUTOR

=over 4

=item new(QMAIL_QUEUE)

construtor for Mail::QmailQueue object.
QMAIL_QUEUE is location of qmail-queue program 
(default /var/qmail/bin/qmail-queue)

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
DATA can be either a scalar or a ref to an array of scalars.

if you call this method twice or more. DATA will be appended.

=item send

send mail.

=back

=head1 AUTHOR

IKEBE Tomohiro E<lt>ikebe@edge.co.jpE<gt>

=head1 SEE ALSO

qmail. http://cr.yp.to/qmail.html
qmail-queue man page.

=head1 COPYRIGHT

Copyright(C) 2002 IKEBE Tomohiro All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

=cut

