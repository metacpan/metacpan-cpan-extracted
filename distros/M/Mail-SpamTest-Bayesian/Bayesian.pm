package Mail::SpamTest::Bayesian;

=head1 NAME

Mail::SpamTest::Bayesian - Perl extension for Bayesian spam-testing

=head1 SYNOPSIS

  use Mail::SpamTest::Bayesian;

  my $j=Mail::SpamTest::Bayesian->new(dir => '.');
  $j->init_db;
  $j->merge_mbox_spam($scalar_spam_box);
  $j->merge_mbox_nonspam($scalar_nonspam_box);
  $message=$j->markup_message($message);

=head1 DESCRIPTION

This module implements the Bayesian spam-testing algorithm described by
Paul Graham at:

http://www.paulgraham.com/spam.html

In short: the system is trained by exposure to mailboxes of known spam
and non-spam messages. These are (1) MIME-decoded, and non-text parts
deleted; (2) tokenised. The database files spam.db and nonspam.db
contain lists of tokens and the number of messages in which they have
occurred; general.db holds a message count.

This module is in early development; it is functional but basic. It is
expected that more mailbox parsing routines will be added, probably
using Mail::Box; and that ancillary programs will be supplied for use of
the module as a personal mail filter.

=head1 METHODS

=cut

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our $VERSION = '0.02';

use strict;
use BerkeleyDB;   # libberkeleydb-perl
use MIME::Parser; # libmime-perl

=head2 new()

Standard constructor. Pass a hash or hashref with parameters.

Useful parameters:
  dir -> database directory (.)
  significant -> number of significant tokens to consider (15)
  threshold -> spam threshold (0.9)
  fudgefactor -> Non-spam priority (2)

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self={};
  bless ($self, $class);
  $self->{dir}='.';
  $self->{significant}=15;
  $self->{threshold}=0.9;
  $self->{fudgefactor}=2;
  my @param;
  while (my $p=shift) {
    if (ref($p) eq 'HASH') {
      map {$self->{lc($_)}=$p->{$_}} keys %{$p};
    } else {
      my $v=shift;
      $self->{$p}=$v;
    }
  }
  foreach my $db (qw(spam nonspam general)) {
    $self->{$db}=new BerkeleyDB::Hash(
                        -Filename => "$self->{dir}/$db.db",
                        -Flags => DB_CREATE
                      );
  }
  $self->{parser}=new MIME::Parser;
  $self->{parser}->output_to_core(1);
  $self->{parser}->tmp_to_core(1);
  $self->{parser}->tmp_recycling(1);
  return $self;
}

=head2 init_db()

Deletes and re-initialises databases. Call this only once, when you
first set up the database.

=cut

sub init_db {
  my $self=shift;
  foreach my $db (qw(spam nonspam general)) {
    undef $self->{$db};
    unlink "$self->{dir}/$db.db";
    $self->{$db}=new BerkeleyDB::Hash(
                        -Filename => "$self->{dir}/$db.db",
                        -Flags => DB_CREATE
                      );
  }
  $self->{general}->db_put('spam',0);
  $self->{general}->db_put('nonspam',0);
}

=head2 merge_mbox_spam()

Train the system by giving it a mailbox full of spam.

Pass a scalar or array or arrayref containing raw messages.

=cut

sub merge_mbox_spam {
  my $self=shift;
  $self->merge_mbox(1,@_);
}

=head2 merge_mbox_nonspam()

Train the system by giving it a mailbox full of legitimate email.

Pass a scalar or array or arrayref containing raw messages.

=cut

sub merge_mbox_nonspam {
  my $self=shift;
  $self->merge_mbox(0,@_);
}

sub merge_mbox {
  my $self=shift;
  my $spamstate=shift;
  my @message=@_;
  if (scalar @message == 1) {
    my $m=$message[0];
    if (ref($m) eq 'ARRAY') {
      @message=@{$m};
      $m='';
    } elsif (ref($m) eq 'SCALAR') {
      $m=$$m;
    }
    if ($m ne '') {
      @message=map {"From $_"} grep !/^$/, (split /^From /m,$m);
    }
  }
  foreach my $m (@message) {
    $self->merge_message($spamstate,$m);
  }
}

=head1 merge_stream_spam()

Pass a stream (pointing to an mbox file) from which to read messages.
For example, an IO::File object.

=cut

sub merge_stream_spam {
    my $self=shift;
    $self->merge_stream(1,@_);
}

=head1 merge_stream_nonspam()

Pass a stream (pointing to an mbox file) from which to read messages.

=cut

sub merge_stream_nonspam {
    my $self=shift;
    $self->merge_stream(0,@_);
}

sub merge_stream {
    my $self=shift;
    my $spamstate=shift;
    my $handle=shift;
    my $message = '';
    while (my $line = <$handle>) {
      if ($line =~ /^From / && length($message) > 0) {
          $self->merge_message($spamstate,$message);
          $message='';
      }
      $message .= $line;
    }
    if (length($message) > 0) {
      $self->merge_message($spamstate,$message);
    }
}


=head2 merge_message_spam()

As merge_mbox_spam, but for a single message; pass in a scalar.

=cut

sub merge_message_spam {
  my $self=shift;
  $self->merge_message(1,@_);
}

=head2 merge_message_nonspam()

As merge_mbox_nonspam, but for a single message; pass in a scalar.

=cut

sub merge_message_nonspam {
  my $self=shift;
  $self->merge_message(0,@_);
}

sub merge_message {
  my $self=shift;
  my $spamstate=shift;
  my $message=shift;
  my @tokens=$self->_tokenise_message($message);
  @tokens=keys %{{ map {$_ => 1} @tokens }};
  my $sk=($spamstate==1)?'spam':'nonspam';
  foreach my $t (@tokens) {
    my $old;
    if ($self->{$sk}->db_get($t,$old) == 0) {
      $old++;
    } else {
      $old=1;
    }
    $self->{$sk}->db_put($t,$old);
    delete $self->{tokencache}->{$t};
  }
  my $old;
  $self->{general}->db_get($sk,$old);
  $old++;
  $self->{general}->db_put($sk,$old);
}

=head2 markup_message()

Test a message for possible spammishness. Pass a scalar containing a
single message. Will return the original message with inserted headers:

  X-Bayesian-Spam: (YES|NO) (probability%)
  X-Bayesian-Test: the significant tests and their weights

=cut

sub markup_message {
  my $self=shift;
  my $message=shift;
  my ($spam,$prob,$list)=$self->test_message($message);
  my $text=($spam)?'YES':'NO';
  $prob=sprintf("%.1f",100*$prob);
  $message =~ s/^$/X-Bayesian-Spam: $text ($prob%)\n/m;
  $text=join(', ',@{$list});
  $message =~ s/^$/X-Bayesian-Test: $text\n/m;
  return $message;
}

=head2 test_message()

Pass a scalar containing a single message. Returns a list:

  0: spam status (1 for spam, 0 for non spam)
  1: probability of spam
  2: listref of significant tests

=cut

sub test_message {
  my $self=shift;
  my $message=shift;
  my @tokens=$self->_tokenise_message($message);
  my %total;
  foreach my $mode (qw(spam nonspam)) {
    if ($self->{general}->db_get($mode,$total{$mode})) {
      $total{$mode}=1;
    }
    unless ($total{$mode}) {
      $total{$mode}=1;
    }
  }
  foreach my $token (@tokens) {
    unless (exists $self->{tokencache}->{$token}) {
      $self->{tokencache}->{$token}=0.2;
      my %this;
      foreach my $mode (qw(spam nonspam)) {
        if ($self->{$mode}->db_get($token,$this{$mode})) {
          $this{$mode}=0;
        }
      }
      $this{nonspam}*=$self->{fudgefactor};
      if ($this{spam}+$this{nonspam}>5) {
        $self->{tokencache}->{$token}=
          &_max(0.01,&_min(0.99,
            &_min($this{spam}/$total{spam},1)/
             (&_min($this{nonspam}/$total{nonspam},1)+
              &_min($this{spam}/$total{spam},1))
          ));
      }
    }
  }
  my @toklist=sort {abs($self->{tokencache}->{$b}-0.5) <=> abs($self->{tokencache}->{$a}-0.5)} @tokens;
  @toklist=@toklist[0..($self->{significant}-1)];
  my $p=0.5;
  foreach (map {$self->{tokencache}->{$_}} @toklist) {
    $p *= $_ / ( ($p*$_) + ((1-$p) * (1-$_)));
  }
  my $s=0;
  if ($p >= $self->{threshold}) {
    $s=1;
  }
  @toklist=map {"$_ (".sprintf('%.3f',$self->{tokencache}->{$_}).")"}
           sort {$self->{tokencache}->{$a} <=> $self->{tokencache}->{$b}
                 ||
                 $a cmp $b}
           @toklist;
  return ($s,$p,\@toklist);
}

sub _tokenise_message {
  my $self=shift;
  my ($message)=@_;
  my $data=$self->{parser}->parse_data($message);
  my @keep=grep { $_->mime_type =~ /^text\/(plain|html)$/ } $data->parts;
  $data->parts(\@keep);
  my @message=($data->head->as_string);
  for (my $i = 0; $i < $data->parts; $i++) {
      my $ent = $data->parts($i);
      if (my $io = $ent->open("r")) {
         while (defined(my $line = $io->getline)) {
             push(@message, $line);
         }
         $io->close;
      }
  }
  my @token;
  foreach my $line (@message) {
    foreach my $token (split /[^-\$A-Za-z0-9\']+/o,$line) {
      if ($token =~ /\D/o) {
        push @token,$token;
      }
    }
  }
  return @token;
}

sub _min {
  my @t=@_;
  my $a=$t[0];
  foreach my $b (@t[1..$#t]) {
    if ($b<$a) {
      $a=$b;
    }
  }
  return $a;
}

sub _max {
  my @t=@_;
  my $a=$t[0];
  foreach my $b (@t[1..$#t]) {
    if ($b>$a) {
      $a=$b;
    }
  }
  return $a;
}

1;
__END__

=head1 AUTHOR

Roger Burton West, E<lt>roger@firedrake.orgE<gt>

=head1 ACKNOWLEDGEMENTS

Erwin Harte provided useful feedback and the de-MIMEing code.

=head1 SEE ALSO

L<perl>, L<BerkeleyDB>.

=cut
