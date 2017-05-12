package Mail::Summary;

$Mail::Summary::VERSION = "0.02";

=head1 NAME

Mail::Summary - scan read your mail!

=head1 SYNOPSIS

  my $ms = Mail::Summary->new({ maildir => '/home/mwk/Maildir' });

  my @mail_summaries = $ms->summaries;

=head1 DESCRIPTION

Too busy to read your mail? Subscribe to too many mailing lists? 
Take two folders into the shower? Well, for the busy on the go geek
of today, here is the answer! Get all your messages summarised, to 
save you having to read them, or to read them by which summary looks
better!

=cut

use strict;
use Mail::Box::Manager;
use Lingua::EN::Summarize;

=head2 new

  my $ms = Mail::Summary->new({ maildir => '/home/mwk/Maildir' });

This will make a new Mail::Summary object.

=cut

sub new {
  my $self = {};
  bless $self, shift;
  return $self->_init(@_);
}

sub _init {
  my ($self, $ref) = @_;
  die "No args passed to new"     unless $ref;
  die "Args to new not a hashref" unless ref $ref eq 'HASH';
  die "No mail folder given"      unless $ref->{maildir};
  $self->{maildir} = $ref->{maildir};
  $self->{mbm} = Mail::Box::Manager->new->open(folder => $ref->{maildir});
  return $self;
}

sub _mbm { shift->{mbm} }

=head2 maildir

  my $maildir = $ms->maildir;

This is the mail directory as defined by the user.

=cut

sub maildir { shift->{maildir} }

=head2 summaries

  my @mail_summaries = $ms->summaries;

This will return a list, with every entry in the list being a summary of an 
individual message.

=cut

sub _messages { shift->_mbm->messages }

sub summaries { map summarize($_->body), shift->_messages }

=head1 BUGS

I have only tried this with my Maildir style mailbox. If you use something 
else, and this works, I would love to hear from you. If it doesn't, I want 
to hear as well!

=head1 TODO

Oh....lots of things.

  o Make it look more than the script it originally was!!
  o SMS the results of the summary?
  o Get the five keywords and feed them into google?
  o ignore already read messages
  o show which folder the messages summarised are in

=head1 SHOWING YOUR APPRECIATION

There was a thread on london.pm mailing list about working in a vacumn
- that it was a bit depressing to keep writing modules but never get
any feedback. So, if you use and like this module then please send me
an email and make my day.

All it takes is a few little bytes.

(Leon wrote that, not me!)

=head1 AUTHOR

Stray Toaster E<lt>F<coder@stray-toaster.co.uk>E<gt>

=head2 With Thanks

  o Dennis Taylor for his Lingua::EN::Summarize which inspired this!

=head1 COPYRIGHT

Copyright (C) 2002, mwk

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut

return qw/This is the secret message/;
