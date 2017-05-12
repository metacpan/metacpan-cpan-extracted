package Luka::Mailer;

# $Id: Mailer.pm,v 1.3 2006/02/27 21:43:59 toni Exp $

use strict;
use Mail::SendEasy;
use Data::Dumper;

=head1 NAME

Luka::Mailer - wrapper around Mail::SendEasy

=head1 SYNOPSIS

  my $mess = Luka::Mailer->new
             ( to         => "some@some.org",
	       cc         => "bla@bla.org",
	       subject    => "some message", 
	       from       => "me@bla.org",
	       body       => "lots of text. ta.\n"
	     );    
	    
  if ($mess->send("Email sent")) {

      do_something();

  } else {

      warn "Couldn't sent email";

  }

=cut

sub new {
    my $self = shift;
    my $class = ref($self) || $self;
    my %args = @_;

    my $obj = { };
    bless $obj, $class;

    my $mail = Mail::SendEasy->new(
				   smtp => 'localhost' ,
				   );
    my $f;
    foreach my $field (keys %args) {
	$f = $field eq "body" ? "message" : $field;
	push @{$obj->{opts}}, $f, $args{$field};
    };

    $obj->{mail} = $mail;
    return $obj;
}

sub error {
   my ($self)  = @_;
   return $self->{mail}->error;
}

sub send {
    my ($self, $msg)  = @_;

    my @opts = $self->{opts};
    my $status = $self->{mail}->send(@{$self->{opts}});

    if (!$status) { print $self->error . "\n" ; return  }
    else          { return 1                            }
}

1;

=head1 SEE ALSO

L<Mail::SendEasy>, L<Luka>

=head1 AUTHOR

Toni Prug <toni@irational.org>

=head1 COPYRIGHT

Copyright (c) 2006. Toni Prug. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
USA

See L<http://www.gnu.org/licenses/gpl.html>

=cut
