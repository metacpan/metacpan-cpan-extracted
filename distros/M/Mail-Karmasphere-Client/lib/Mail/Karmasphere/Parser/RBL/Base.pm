package Mail::Karmasphere::Parser::RBL::Base;

use strict;
use warnings;
use base 'Mail::Karmasphere::Parser::Base';
use Mail::Karmasphere::Parser::Record;

sub new {
	my $class = shift;
	my $self = ($#_ == 0) ? { %{ (shift) } } : { @_ };
	$self->{Streams} ||= [ $class->_streams() ];
	$self = $class->SUPER::new($self);
	$self->{default}->{a}   = "127.0.0.2";
	$self->{default}->{txt} = undef;
	return $self;
}

sub _streams { die "subclass of RBL::Base must define _streams()" }

sub my_format { die "subclass of RBL::Base must define my_format()" }

sub _parse {
	my $self = shift;

      GETLINE:
	while ( not eof($self->fh)) {
		local $_ = $self->fh->getline;

		my $additional;
		my $value; #[ -1000 .. 1000 ]

		# XXX This should be an argument to a_to_value, or
		# it should be handled in this routine. It should NOT
		# be an instance variable.
		$self->{is_exclusion} = 0;
	
		/^\#/   and 			      next GETLINE;
		/^\@/   and $self->handle_fancy($_),  next GETLINE;
		/^\$/   and $self->handle_dollar($_), next GETLINE;
		/^\:/   and $self->handle_colon($_),  next GETLINE;
		s/^!//  and $self->{is_exclusion} = 1;
		/\S/     or next GETLINE;

		chomp;
		my @F = split /\s*:\s*/;

		$value    = $self->a_to_value($F[1]);
		$additional = $self->txt_to_additional($F[2]);
		
		my ($type, $stream, $identity) = $self->tweaks(@F) or next GETLINE;

		warn ("returning Record: identity=$identity; value=$value; additional=$additional; stream=$stream\n") if $self->debug;

		return new Mail::Karmasphere::Parser::Record
		    (
		     s	=> $stream,
		     i	=> $identity,
		     v	=> $value,
		     (defined $additional ? (d  => $additional) : ()), # this is what elsewhere thinks of as "data".
		     (defined $type ? (t  => $type) : ()),
		     );
	}

	return;
}


# ----------------------------------------------------------
# 			 functions
# ----------------------------------------------------------

sub txt_to_additional {
  my $self = shift;
  my $txt = shift;
  return $txt || $self->{default}->{txt};
}

sub a_to_value {
  my $self = shift;
  my $a = shift || $self->{default}->{a};

  # if  127.0.0.2 means "black"
  # and 127.0.0.4 means "white",
  # this is where we would put the logic to return the appropriate value.

  my $value = defined $self->{Value} ? $self->{Value} : 1000;

  # exclusions are operated as whitelists
  return - $value if $self->{is_exclusion};

  return $value;
}

sub handle_fancy  { my $self = shift; }
sub handle_dollar { my $self = shift; }

sub handle_colon  {
  my $self = shift;
  my $line = shift;
  chomp $line;
  my ($null, $default_a, $default_txt) = split /:/, $line, 3;
  $self->{default}->{a}   = $default_a   if $default_a;
  $self->{default}->{txt} = $default_txt if $default_txt;
}

1;
