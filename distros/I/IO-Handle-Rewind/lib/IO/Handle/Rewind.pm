package IO::Handle::Rewind;

use strict;
use Carp qw(croak);
use base qw(Class::Accessor);

=head1 NAME

IO::Handle::Rewind - pretend to rewind filehandles

=head1 VERSION

0.06

=cut

our $VERSION = '0.06';

=head1 DESCRIPTION

IO::Handle::Rewind wraps any IO::Handle object in a soft,
fluffy coat.

=head1 METHODS

Delegates most methods to the wrapped object.

=head3 C<< IO::Handle::Rewind->new($obj) >>

Return an IO::Handle::Rewind object wrapping the passed-in
IO::Handle.

=head3 C<< $re->rewind(@lines, $lines) >>

Further calls to C<< readline >>, C<< getline >>, or C<<
getlines >> will read from the passed-in array/arrayrefs
before actually reading further from the filehandle.

Despite the name, this does not seek the filehandle.

=head3 C<< $re->getline >>

=head3 C<< $re->getlines >>

=head3 C<< $re->readline >>

See documentation for C<< rewind >>.

=head1 SEE ALSO

L<IO::Handle>

=head1 AUTHOR

Hans Dieter Pearcey <hdp@icgroup.com>

=head1 LICENSE

Copyright (C) 2005, Hans Dieter Pearcey.

Available under the same terms as Perl itself.

=cut

__PACKAGE__->mk_accessors(qw(rewound obj));

sub _delegate {
  my ($class, @meths) = @_;
  for my $meth (@meths) {
    no strict 'refs';
    *{$class . "::" . $meth} = sub {
      my $self = shift;
      return $self->obj->$meth(@_);
    }
  }
}

# XXX I'm not sure all of these make sense to delegate

my @meths = qw(fdopen close opened fileno getc eof print
               printf truncate read sysread write syswrite
               stat autoflush input_line_number
               format_page_number format_lines_per_page
               format_lines_left format_name format_top_name
               formline format_write fcntl ioctl constant
               printflush);

__PACKAGE__->_delegate(@meths);

sub new {
  my ($class, $obj, $opt) = @_;
  
  $obj->isa('IO::Handle') or croak "Can't wrap non-IO::Handle object: $obj";

  my $self = bless {} => $class;

  $self->obj($obj);
 
  return $self;
}

sub rewind {
  my ($self, @lines) = @_;
  $self->rewound([@lines]);
}

sub getline {
  my $self = shift;
  return scalar $self->readline(@_);
}

sub getlines {
  my $self = shift;
  croak "Don't call getlines in scalar context" unless wantarray;
  my @lines;
  while (defined(my $line = $self->readline)) {
    push @lines, $line
  }
  return @lines;
}

sub readline {
  my $self = shift;
  my $re = $self->rewound;
  
  while (1) {
    # simple case -- no rewound entries
    if (not $re or not @$re) {
      #warn "real readline\n";
      return $self->obj->getline
    }

    # >>> past here, @$re is non-empty
    my $next = $re->[0];

    # simple case -- next rewound entry is plain scalar
    if (not ref($next)) {
      #warn "plain scalar: $next\n";
      return shift @$re;
    }

    # simple case -- next rewound entry is something we don't know
    if (ref($next) ne "ARRAY") {
      die "can't handle rewind entry $next";
    }
    
    # >>> complex case -- next rewound entry is arrayref
    
    # simple subcase -- it's empty
    if (not @$next) {
      #warn "ditching empty inner array\n";
      shift @$re;
      next;
    }

    # simple subcase -- its entry is plain scalar
    if (not ref($next->[0])) {
      #warn "inner scalar: $next->[0]\n";
      return shift @$next;
    }

    # simple subcase -- its next entry is something we don't know
    if (ref($next->[0])) {
      die "can't handle nested rewind entry $next";
    }
  }
}

"false";
