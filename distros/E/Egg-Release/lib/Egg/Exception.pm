package Egg::Exception;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Exception.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;

our $VERSION= '3.00';

package Egg::Error;
use strict;
use warnings;
use Devel::StackTrace;
use overload  '""' => 'stacktrace';
use base qw/ Class::Accessor::Fast /;

our $IGNORE_PACKAGE= [qw/ main Carp /];
our $IGNORE_CLASS  = [qw/ Egg::Error /];

__PACKAGE__->mk_accessors(qw/ errstr frames as_string /);

sub new {
	my $class = shift;
	my $errstr= join '', @_;
	my $stacktrace;
	{
		local $@;
		eval{
		  $stacktrace= Devel::StackTrace->new(
		    ignore_package   => $IGNORE_PACKAGE,
		    ignore_class     => $IGNORE_CLASS,
		    no_refs          => 1,
		    respect_overload => 1,
		    );
		  };
	  };
	die $errstr unless $stacktrace;
	bless {
	  errstr   => $errstr,
	  as_string=> $stacktrace->as_string,
	  frames   => [$stacktrace->frames],
	  }, $class;
}
sub throw {
	my $error= shift->new(@_);
	die $error;
}
sub stacktrace {
	my($self)= @_;
	my @trace;
	foreach my $f (@{$self->frames}) {
		push @trace, $f->filename. ': '. $f->line;
	}
	"$self->{errstr} \n\n stacktrace: \n [". join("] \n [", @trace). "] \n";
}

1;

__END__

=head1 NAME

Egg::Exception - The exception with stack trace is generated.

=head1 SYNOPSIS

  use Egg::Exception;
  
  Egg::Error->throw('The error occurs.');
  
  or
  
  local $SIG{__DIE__}= sub { Egg::Error->throw(@_) };
  die 'The error occurs.';

=head1 DESCRIPTION

It is a module to vomit the message with stack trace when the exception is generated.

=head1 METHODS

=head2 new

Constructor. This is internally called. 

=head2 throw ([MESSAGE_STRING])

After the constructor is let pass, the exception is generated.

  Egg::Error->throw( 'internal error.' );

=head2 stacktrace

Only trace information on the object is returned.

  local $SIG{__DIE__}= sub { Egg::Error->throw(@_) };
  eval{ ... code. };
  if ($@) { die $@->stacktrace }

=head2 frames

Trace information on the object is returned by the ARRAY reference.

  local $SIG{__DIE__}= sub { Egg::Error->throw(@_) };
  eval{ ... code. };
  if ($@) { die join "\n", @{$@->frames} }

=head2 as_string

as_string of L<Devel::StackTrace > is returned.

  local $SIG{__DIE__}= sub { Egg::Error->throw(@_) };
  eval{ ... code. };
  if ($@) { die $@->as_string }

=head2 errstr

Only the exception message of the object is returned.

  local $SIG{__DIE__}= sub { Egg::Error->throw(@_) };
  eval{ ... code. };
  if ($@) { die $@->errstr }

=head1 SEE ALSO

L<Egg::Release>,
L<Devel::StackTrace>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

