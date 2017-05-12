package Logfile::EPrints::Mapping::EPrints;

use strict;
use warnings;

sub new {
	my ($class,%self) = @_;

	Carp::croak(__PACKAGE__." requires identifier argument") unless exists $self{identifier};

	bless \%self, $class;
}

sub hit {
	my ($self,$hit) = @_;
	if( 'GET' eq $hit->method && 200 == $hit->code ) {
		my $path = URI->new($hit->page,'http')->path;
		# Full text
		if( $path =~ /^(?:\/archive)?\/(\d+)\/\d/ ) {
			$hit->{identifier} = $self->_identifier($1);
			$self->{handler}->fulltext($hit);
		} elsif( $path =~ /^(?:\/archive)?\/(\d+)\/?$/ ) {
			$hit->{identifier} = $self->_identifier($1);
			$self->{handler}->abstract($hit);
		} elsif( $path =~ /^\/view\/(\w+)\// ) {
			$hit->{section} = $1;
			$self->{handler}->browse($hit);
		} elsif( $path =~ /^\/perl\/search/ ) {
			$self->{handler}->search($hit);
		} else {
			#warn "Unknown path = ", $uri->path, "\n";
		}
	}
}

sub _identifier {
	my ($self,$no) = @_;
	return $self->{'identifier'}.($no+0);
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Logfile::EPrints::Mapping::EPrints - Parse Apache logs from GNU EPrints

=head1 SYNOPSIS

  use Logfile::EPrints;

  my $parser = Logfile::EPrints::Parser->new(
	handler=>Logfile::EPrints::Mapping::EPrints->new(
	  identifier=>'oai:myir:', # Prepended to the eprint id
  	  handler=>Logfile::EPrints::Repeated->new(
	    handler=>Logfile::EPrints::Institution->new(
	  	  handler=>$MyHandler,
	  )),
	),
  );
  open my $fh, "<access_log" or die $!;
  $parser->parse_fh($fh);
  close $fh;

  package MyHandler;

  sub new { ... }
  sub AUTOLOAD { ... }
  sub fulltext {
  	my ($self,$hit) = @_;
	printf("%s from %s requested %s (%s)\n",
	  $hit->hostname||$hit->address,
	  $hit->institution||'Unknown',
	  $hit->page,
	  $hit->identifier,
	);
  }

=head1 SEE ALSO

L<Logfile::EPrints>

=head1 AUTHOR

Timothy D Brody, E<lt>tdb01r@ecs.soton.ac.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Timothy D Brody

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
