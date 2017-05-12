package HTTP::Easy::Headers::PP;

use strict;
use warnings;

sub new { my $pk = shift; bless shift,$pk }

# Adopted from MLEHMANN's AnyEvent::HTTP and ELMEX's AnyEvent::HTTPD
sub decode {
	my $pk = shift;
	local $_ = shift;
	my %args = @_;
	my %h;
	y/\015//d;
	
	$h{lc $1} .= ",$2"
		while /\G
			([^:\000-\037]+)[\011\040]*:           # Key:
			[\011\040]*                            # LWS*
			( (?: [^\012]+ | \012 [\011\040] )* )  # ( 1-line value | \n\t )
			(?: \012 | \Z )
		/sgcxo;
	
	warn "Garbled headers, left buffer: <$1>\n" if /\G(.+)$/;
	
	for (values %h) {
		substr $_, 0, 1, '';
		# remove folding:
		s/\012([\011\040]+)/ /sgo;
		s{[\011\040]+$}{}so;
	}
	if (exists $h{location} and $h{location} !~ /^(?: $ | [^:\/?\#]+ : )/xo and $args{base}) {
		$h{location} = ''.URI->new_abs($h{location},$args{base});
	}
	bless \%h, $pk;
}

sub HTTP {
	my $self = shift;
	if (@_) {
		$self->{Status} = shift;
		$self->{Reason} = shift if @_;
		$self->{HTTPVersion} = shift if @_;
		$self;
	} else {
		return "$self->{Status} $self->{Reason} HTTP/$self->{HTTPVersion}";
	}
}

sub encode {
	my $pk = shift;
	my $h = @_ || !ref $pk ? shift : $pk;
	join ( "", map defined $h->{$_} ? "\u\L$_\E: $h->{$_}\015\012" : '', keys %$h )
}

1;
