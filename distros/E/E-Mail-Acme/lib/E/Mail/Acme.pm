use strict;
## no critic warnings # let's be 5.00x compatible

package E'Mail::Acme;

$E'Mail::Acme::VERSION = 1555;

my $CRLF = "\x0d\x0a";

use overload '""' => sub {
  my ($self) = @_;

  if (@{$self->[ @$self ]}) {
    unless (($self->{'content-type'}->[0]||'') =~ qr{^multipart/}) {
      warn "content-type set, but not multipart on multipart message"
        if $self->{'content-type'};
      delete $self->{'content-type'};
      $self->{'content-type'} = qq{multipart/mixed};
    }

    unless ($self->{'content-type'}->[0] =~ qr{boundary="(?:[^"]+)"}) {
      $self->{'content-type'}->[0] .= qq{; boundary="$self->[@$self+1]"};
    }
  }

  join(
    $CRLF,
    $self->{''},
    join($CRLF, @{ $_[0] }, '')
    . (
      @{ $_[0]->[ @{ $_[0] } ] }
      ? "$CRLF--$_[0]->[ @{ $_[0] } + 1 ]$CRLF"
        . join("--$_[0]->[ @{ $_[0] } + 1 ]$CRLF", @{ $_[0]->[ @{ $_[0] } ] })
        . "--$_[0]->[ @{ $_[0] } + 1 ]--$CRLF"
      : ''
    )
  );
};

use overload '&{}' => sub {
  my ($self) = @_;
  sub {
    my ($program) =  @_;
    $program = 'sendmail' unless defined $program and length $program;

    if ($program !~ m{[/\\]}) {
      path: for my $dir (split /:/, $ENV{PATH}) {
        if ( -x "$dir/program" ) {
          $program = "$dir/program";
          last path;
        }
      }
    }

    open  $self, "| $program -t -oi -f $self->{from}->[0]" or die;
    print $self $self or die;
    close $self  or die;
  }
};

use overload '@{}' => sub {
  tie @{*{$_[0]}}, q<E'Mail::Acme::Body> unless @{*{$_[0]}};#'
  return \@{*{$_[0]}};
};

use Scalar::Util qw(refaddr); # XXX

use overload '%{}' => sub {
  tie %{*{$_[0]}}, q<E'Mail::Acme::Header> unless %{*{$_[0]}};#'
  return \%{*{$_[0]}};
};

use overload fallback => 1;

{
  package E'Mail::Acme::HeaderFieldValues;
  our @ISA = qw(E'Mail::Acme::Base);

  sub TIEARRAY {
    my ($class, $name, $gutter) = @_;
    bless [ $name, $gutter ] => $class;
  }

  sub FETCHSIZE {
    my ($self) = @_;
  
    my $gut = $self->[1]->();

    my $hits = 0;
    i: for (my $i = 0; $i < $#$gut; $i += 2) {
      lc $gut->[ $i ] eq lc $self->_idx(0) and $hits++;
    }

    return $hits;
  }

  sub EXISTS {
    my ($self, $idx) = @_;
    return $idx <= $self->FETCHSIZE;
  }

  sub FETCH {
    my ($self, $idx) = @_;

    my $gut = $self->_idx(1)->();

    i: for (my $i = 0; $i < $#$gut; $i += 2) {
      lc $gut->[ $i ] eq lc $self->_idx(0) or next i;
      return $gut->[ $i + 1 ] if $idx == 0;
      $idx--;
    }

    return;
  }

  sub DELETE {
    my ($self, $idx) = @_;
    $self->SPLICE($idx, 1);
  }

  sub CLEAR {
    my ($self) = @_;
    $self->SPLICE(0, $self->FETCHSIZE);
  }

  sub EXTEND { }

  sub SPLICE {
    my ($self, $idx, $length, @new) = @_;

    if ($idx >= $self->FETCHSIZE) {
      return $self->PUSH(@new);
    }

    my $gut = $self->_idx(1)->();

    i: for (my $i = 0; $i < $#$gut; $i += 2) {
      lc $gut->[ $i ] eq lc $self->_idx(0) or next;
      if ($idx == 0) {
        if ($length == 0) {
          splice @$gut, $i, 0, map { $self->_idx(0), $_ } @new;
          return;
        }

        if (@new) {
          $gut->[ $i ] = $self->_idx(0);
          $gut->[ $i + 1 ] = shift @new;
        } else {
          splice @$gut, $i, 2;
          $i -= 2;
        }
        $length--;
      } else {
        $idx--;
      }
    }

    $self->PUSH(@new);
  }

  sub PUSH {
    my ($self, @new) = @_;

    my $gut = $self->_idx(1)->();
    push @$gut, $self->_idx(0), $_ for @new;
  }

  sub STORE {
    my ($self, $idx, $value) = @_;

    my $gut = $self->_idx(1)->();

    if ($idx >= $self->FETCHSIZE) {
      push @$gut, $self->_idx(0), $value;
      return $value;
    }

    i: for (my $i = 0; $i < $#$gut; $i += 2) {
      lc $gut->[ $i ] eq lc $self->_idx(0) or next;
      if ($idx == 0) {
        $gut->[ $i ] = $self->_idx(0);
        $gut->[ $i + 1 ] = $value;
        return $value;
      }
      $idx--;
    }
  }
}

{
  package E'Mail::Acme::Body;
  our @ISA = qw(E'Mail::Acme::Base);

  my $i = 0;
  sub TIEARRAY {
    my ($class) = @_;

    my $self = {
      lines => [],
      parts => [],
      bound => time . '-' . $$ . '-' . $i++ . $^T,
    };
    bless $self => $class;
  }

  sub CLEAR {
    my ($self) = @_;
    $self->{lines} = [];
    $self->{parts} = [];
  }

  sub EXTEND { }

  sub FETCHSIZE {
    my ($self) = @_;
    warn "calling FETCHSIZE\n" if $::foo;
    my $size = scalar @{ $self->{lines} };
    return $size;
  }

  sub FETCH {
    my ($self, $idx) = @_;

    warn "calling FETCH $idx\n" if $::foo;
    my $size = $self->FETCHSIZE;
    if ($idx == $size) {
      return $self->{parts};
    } elsif ($idx == $size + 1) {
      return $self->{bound};
    }

    $self->{lines}[$idx];
  }

  sub _values {
    my ($self, $value) = @_;
    return $value if ref $value;
    my @values = split /\x0d\x0a|\x0a\x0d|\x0a|\x0d/, $value;
  }

  sub STORE {
    my ($self, $idx, @values) = @_;
    $self->SPLICE($idx, 1, 
      map { my @v = $self->_values($_); @v ? @v : '' } @values
    );
  }

  sub SPLICE {
    my ($self, $idx, $length, @values) = @_;

    my @to_splice;
    my @parts;

    for my $v (map { my @v = $self->_values($_); @v ? @v : '' } @values) {
      # The E:: is a concession to v5.6.x
      if (eval { $v->isa("E'Mail::Acme") or $v->isa("E::Mail::Acme") }) {
        push @parts, $v;
      } elsif (ref $v eq 'ARRAY' or eval { overload::Method($v, '@{}') }) {
        push @to_splice, map { my @v = $self->_values($_); @v ? @v : '' } @$v;
      } else {
        push @to_splice, $v;
      }
    }

    push @{ $self->{parts} }, @parts;
    splice @{ $self->{lines} }, $idx, $length, @to_splice;
  }

  sub PUSH {
    my ($self, @values) = @_;

    $self->SPLICE(
      $self->FETCHSIZE,
      0,
      map { my @v = $self->_values($_); @v ? @v : '' } @values
    );
  }
}

{
  package E'Mail::Acme::HeaderField;
  our @ISA = qw(E'Mail::Acme::Base);

  sub TIESCALAR {
    my ($class, $name, $gutter) = @_;
    bless [ $name, $gutter ] => $class;
  }

  sub _str_first {
    my ($self) = @_;

    my $gut = $self->_idx(1)->();
 
    i: for (my $i = 0; $i < $#$gut; $i += 2) {
      lc $gut->[ $i ] eq lc $self->_idx(0) and return $gut->[ $i + 1 ];
    }
  }

  sub _str_all {
    my ($self) = @_;

    my $string = '';

    my $gut = $self->_idx(1)->();
    i: for (my $i = 0; $i < $#$gut; $i += 2) {
      lc $gut->[ $i ] eq lc $self->_idx(0) and
        $string .= $gut->[$i] . ': ' . $gut->[$i + 1] . $CRLF;
    }
    return $string;
  }

  sub _values_obj {
    my ($self) = @_;

    tie my @values, "E'Mail::Acme::HeaderFieldValues",
      $self->_idx(0),
      $self->_idx(1),
    ;

    \@values;
  }

  use overload
    '""'     => '_str_all',
    '@{}'    => '_values_obj',
    fallback => 1;
}

{ # package E'Mail::Acme::Header
  package E'Mail::Acme::Header;
  @E'Mail::Acme::Header::ISA = qw(E'Mail::Acme::Base);

  sub TIEHASH {
    my ($class, $e_mail) = @_;
    bless {
      obj => $e_mail,
      hdr => []
    } => $class;
  }

  sub FETCH {
    my ($self, $key) = @_;

    return $self->_str_all if $key eq '';

    return tie my $field, "E'Mail::Acme::HeaderField",
      $key,
      sub { $self->{hdr} }
    ;
  }

  sub EXISTS {
    my ($self, $key) = @_;

    i: for (my $i = 0; $i < $#{$self->{hdr}}; $i += 2) {
      return 1 if lc $self->{hdr}[$i] eq lc $key;
    }
    return;
  }

  sub STORE {
    my ($self, $key, $value) = @_;

    return $self->DELETE($key) if ! defined $value;

    if (
      ref $value eq 'ARRAY'
      or
      eval { overload::Method($value, '@{}') }
    ) {
      $self->DELETE($key), return $self->FETCH($key) unless @$value;
      $self->STORE($key, $_) for @$value;
      return $self->FETCH($key);
    }

    push @{ $self->_attr('hdr') }, $key, $value;

    return $self->FETCH($key);
  }

  sub DELETE {
    my ($self, $key) = @_;

    return unless $#{ $self->{hdr} } >= 1;

    i: for (my $i = $#{$self->{hdr}} - 1; $i >= 0; $i -= 2) {
      lc $self->{hdr}[$i] eq lc $key or next i;
      splice @{ $self->{hdr} }, $i, 2;
    }
  }

  sub FIRSTKEY {
    my ($self) = @_;

    delete $self->{iter};
    $self->{iter} = { };

    i: for (my $i = 0; $i < $#{$self->{hdr}}; $i += 2) {
      my $v = $self->{iter}{ lc $self->{hdr}[$i] } ||= [];
      push @$v, $self->{hdr}[ $i + 1 ];
    }

    return each %{ $self->{iter} };
  }

  sub NEXTKEY {
    my ($self, $prev) = @_;

    die "error during e'mail header transnaviation" unless $self->{iter};
    return each %{ $self->{iter} };
  }

  sub _str_all {
    my ($self) = @_;

    my $string = '';
    i: for (my $i = 0; $i < $#{$self->{hdr}}; $i += 2) {
      $string .= $self->{hdr}[$i] . ': ' . $self->{hdr}[$i + 1] . $CRLF;
    }
    return $string;
  }

  use overload
    fallback => 1,
    '""'     => '_str_all',
  ;
}

{ # Utility constructor class
  package E'Mail;
  sub Acme {
    my $guts = {};

    use Symbol;
    my $self = Symbol::gensym;
    bless $self => "E'Mail::Acme";
  };
}

{
  package E'Mail::Acme::Base;
  sub _idx {
    my ($self, $idx) = @_;
    my $orig_class = ref $self;
    bless $self => "E'Mail::Acme::HoldingPattern";
    my $value = $self->[$idx];
    bless $self => $orig_class;
    return $value;
  }

  sub _attr {
    my ($self, $key) = @_;
    my $orig_class = ref $self;
    bless $self => "E'Mail::Acme::HoldingPattern";
    my $value = $self->{$key};
    bless $self => $orig_class;
    return $value;
  }
}

E'Mail::Acme;#'

__END__

=head1 NAME

E'Mail::Acme - the epitome of simple e-mail handling

=head1 VERSION

version 1555

=head1 SYNOPSIS

  my $e_mail = E'Mail::Acme;

  $e_mail->{From} = q<Ricardo SIGNES <rjbs@acme.example.biz>>;
  $e_mail->{To  } = q<Alvin Theodore <monk@chip.shoulder.dw>>;

  $e_mail->{Subject} = 'Finally, a simple e-mail module!';

  push @$e_mail,
    'Alvin,',
    '',
    'I agree!  What the world needs is a module that makes e-mail more',
    'accessible to the common man -- or at least the common Perl programmer.',
    '',
    'I have attached a modest example.',
  ;

  $e_mail->('sendmail');

=head1 DESCRIPTION

Good grief, everywhere you turn there's yet another e-mail module!  This one
says that the message is an object.  That one says that every I<field> is an
object.  Then there's the one that says the darn B<body> is an object!

How many methods do I need to learn, anyway?  Look, an e-mail is simple.  It's
a set of name/value pairs forming a header and a list of lines.  That's it!
Anybody who tells you otherwise is just being a nervous Nelly.

E'Mail::Acme is the epitome of simple e-mail handling.  It does use an object,
but only to help produce a synergistic, cohesive unity of purpose.  It uses
I<just> the familiar, existing Perl data system so that you only need use the
Perl you already know -- none of this overwrought API that we've all gotten so
sick of.

=head1 METHODS

None.

=head1 CONSTRUCTION

Making a new e-mail is easy:

  my $e_mail = E'Mail::Acme;

=head1 HEADERS

Setting headers is easy:

  $e_mail->{header} = "First Value";
  $e_mail->{HeadEr} = "Second Value";

  print $e_mail->{header};
  # header: First Value
  # HeadeR: Second Value

You can also assign multiple values at once:

  $e_mail->{XForce} = [ qw(Lethal Aggressive) ];

  print $e_mail->{XForce};
  # X-Force: Lethal
  # X-Force: Aggressive

To clear all of those headers, you can just:

  delete $e_mail->{xforce};

Or, to delete just the first, either of these will work:

  delete $e_mail->{XForce}[0];

  splice @{ $e_mail->{XForce} }, 0, 1;

Alternately, more values could be added in a similar fashion:

  push @{ $e_mail->{XForce} }, 'except on Sundays';
  
  splice @{ $e_mail->{XForce} }, 1, 0, 'and';

Of course, individual header values can be passed around and used to affect the
original message:

  my $recipients = $e_mail->{to};

  munge_values($recipients); # the $e_mail is altered

This frees you from passing around a large clunky message "object" when you
only need to deal with part of it.

=head1 THE BODY

The body is just a sequence of lines, and you can treat it as such:

  @$e_mail = "Friends, Romans, Countrymen:"
          , ''
          , 'Lend me your ears!';

You can always easily add your sig to a message:

  my $sig = "-- \nrjbs\n";

  push @$e_mail, $sig;

E'Mail::Acme will take care of all the conversion of newlines, breaking up text
on all likely newlines and normalizing to CRLF.

=head1 MULTIPART

Multipart messages are easy:  just push more e-mails onto the body.

  my $e_mail = E'Mail::Acme; # top part;
  my $part_1 = E'Mail::Acme; # attachment
  my $part_2 = E'Mail::Acme; # attachment

  push @$e_mail, $part_1, $part_2;

Any lines in a multi-part e-mail message form the preamble, and an arrayref of
subparts is always available at the end of the e-mail -- that is, like this:

  my $subparts = $e_mail->[ scalar @$e_mail ];

Nested multipart messages are handled just fine.  A multipart content-type will
be added, if none has been supplied.  If a multipart content-type is set, but
the boundary is not, it will be added.  Do not set your own boundary unless you
know what you are doing!  You will probably produce a corrupt message!

=head1 SENDING MAIL

A mail exists to be sent, not hoarded!  Once you've composed your e-mail
message, you can send it just how you'd expect:

  $e_mail->();

If your F<sendmail> program is not installed in your path, you can specify
which program to use by passing it as an argument:

  $e_mail->(q(c:/program files/sendmail/sendmail.exe));

=cut

=head1 THANKS

Thanks to Simon, Simon, Casey, Richard, Dave, Dieter, Meng, Mark, Graham, Tim,
Yves, David, Eryq and everyone else who has helped form my understanding of how
e-mail should be handled.

=head1 AUTHOR

Ricardo SIGNES wrote this module on Friday, July 13, 2007.

=head1 COPYRIGHT AND LICENSE

This code is copyright (c) 2007, Ricardo SIGNES.  It is free software,
available under the same terms as Perl itself.

=cut
