package Mail::Karmasphere::Parser::Simple::List;

use strict;
use warnings;
use base 'Mail::Karmasphere::Parser::Base';

sub new {
	my $class = shift;
#	print STDERR "new: \$class = $class\n";
#	print STDERR "new: \$class->_streams() = @{[$class->_streams()]}\n";;
	my $self = ($#_ == 0) ? { %{ (shift) } } : { @_ };
	unless (exists $self->{Streams}) {
		$self->{Type} = $class->_type() unless $self->{Type};
		$self->{Streams} = [ $class->_streams() ];
	}
	$self = $class->SUPER::new($self);
	$self->{Value} = 1000 unless exists $self->{Value};
	return $self;
}

sub _parse {
	my $self = shift;
	for (;;) {
		my $line = $self->fh->getline;
		return undef unless $line;
		next if $line =~ /^#/;
		next unless $line =~ /\S/;
		chomp($line); $line =~ s/\r$//g; # strip trailing CRLF
		$line =~ s/[\s;].+$//;
		return new Mail::Karmasphere::Parser::Record(
			s	=> 0,
			i	=> $line,
			v	=> $self->{Value},
				);
	}
}

sub _type { "Parser::Simple::* subclass must define _type()" }

1;
