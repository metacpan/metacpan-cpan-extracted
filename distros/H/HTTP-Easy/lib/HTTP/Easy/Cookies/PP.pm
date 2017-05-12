package HTTP::Easy::Cookies::PP;

use strict;
#use warnings;
use Time::Local ();
use Scalar::Util 'weaken';

our @MoY = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
our %MoY;@MoY{@MoY} = (1..12);
our @Leg = qw(comment commenturl discard domain expires httponly max-age path port secure version );
our %Leg; @Leg{@Leg} = (1)x@Leg;

sub CHECK_PARAM () { 1 }
our $DECODE_EXPIRES = 1;

our %HOST;

sub new { my $pk = shift; bless shift||{},$pk }

# Adopted from MLEHMANN's AnyEvent::HTTP
sub decode {
	my $pk = shift;
	my $jar = ref $pk ? $pk : bless {},$pk;
	local $_ = shift;
	my %args = ( host => '', @_ );
	#warn "parse $_ for $args{host}";
	my @kv;my @nv;
	{
		# parse NAME=VALUE
		@kv = @nv;@nv = ();
		while (
			/
			\G
			#\s* ([^=;,[:space:]]+) \s* # strict RFC key
			\s* ([^=;,]+?) \s* # Relaxed token, allowing whitespace
			(?:
				=\s*
				(?:
					"((?:[^\\"]+|\\.)*)" # " quoted entry
					|
					(
						#[SMTWF][a-z][a-z],\s\d\d[\s-][JFMAJSOND][a-z][a-z][\s-]\d\d\d\d\s\d\d:\d\d:\d\d\sGMT # HTTP Date
						[A-Z][a-z][a-z],\s\d\d[\s-][A-Z][a-z][a-z][\s-]\d\d(?:\d\d|)\s\d\d:\d\d:\d\d\sGMT # Loose HTTP Date
						#[A-Z]..,\s..[\s-][A-Z]..[\s-]....\s..:..:..\sGMT # Loosest HTTP Date
						|
						#[^=;,[:space:]]* # strict bareword enrty
						[^;,]* # relaxed entry
					)
				)
			)?
			\s* (?: [,;] | \Z ) # Include terminator for greediness of key
			/gcxso)
		{
			my $flag = 0;
			my $name = $1;#$name =~ s{[[:space:]]+$}{}so;
			my $value = $3;
			#warn "$1 => $2$3";
			unless ( defined $value ){
				if (defined $2) {
					$value = $2;
					$value =~ s/\\(.)/$1/gs; # unescape quoted
				} else {
					#warn "no value for $name";
					$flag = 1;
					$value = 1;
				}
			}
			$value =~ s{\s+$}{}; # trim
			$value =~ s/%([0-9a-fA-F]{2})/ chr(hex($1)) /gse;
			if (CHECK_PARAM) {
				if (!$Leg{lc $name} and !$flag and @kv) {
					#warn "Left $name => $value";
					push @nv, $name => $value;
					last;
				}
			}
			$name = lc $name if @kv;
			push @kv, $name => $value;
			#last unless /\G\s*;/gc; # removed because of terminator
		}
		#warn "Got KV=[@kv]\n";
		last unless @kv;
		my $name = shift @kv;
		my %kv = (value => shift @kv, @kv);

		my $cpath = (delete $kv{path}) || "/";
		my $cdom;
		
		if (exists $kv{domain}) {
			$cdom = delete $kv{domain};
			$cdom =~ s/^\.?/./; # make sure it starts with a "."
			next if $cdom =~ /\.$/;
			# this is not rfc-like and not netscape-like. go figure.
			my $ndots = $cdom =~ y/.//;
			next if $ndots < ($cdom =~ /\.[^.][^.]\.[^.][^.]$/ ? 3 : 2);
		} else {
			$cdom = $args{host} || '';
		}
		if (exists $kv{expires} and $DECODE_EXPIRES and $kv{expires} =~ /^[A-Z]..,\s(..)[\s-]([A-Z]..)[\s-](....)\s(..):(..):(..)\sGMT$/so) {
			eval {
				my $t = Time::Local::timegm($6, $5, $4, $1, $MoY{$2}-1, $3);
				$kv{expires} = $t if $t >=0;
			};
		}
		# store it
		$jar->{version} = 1;
		unless( $cdom and $args{host} and $cdom ne substr '.' . $args{host}, -length $cdom ) {
			# take only our cookies
			if (length $kv{value}) {
				$jar->{$cdom}{$cpath}{$name} = \%kv;
			} else {
				delete $jar->{$cdom}{$cpath}{$name};
				delete $jar->{$cdom}{$cpath} unless %{$jar->{$cdom}{$cpath}};
				delete $jar->{$cdom}         unless %{$jar->{$cdom}};
			}
		}
		redo if /\G\s*,/gco or @nv;
	}
	$HOST{ int $jar } = $args{host};
	return $jar;
}

sub encode {
	my $pk = shift;
	my $jar = @_ || !ref $pk ? shift : $pk;
	my %args = ( secure => 0, @_ );
	my $uhost = $args{host} || $HOST{ int $jar } || '';
	my $upath = $args{path} || '/';
	my @cookie;
	while (my ($chost, $v) = each %$jar) {
		if ($chost =~ /^\./) {
			next unless $chost eq substr '.' . $uhost, -length $chost;
		} elsif ($chost =~ /\./) {
			next unless $chost eq $uhost;
		} elsif ($chost eq 'version') {
			next;
		}
		while (my ($cpath, $v2) = each %$v) {
			next unless $cpath eq substr $upath, 0, length $cpath;
			while (my ($k, $v3) = each %$v2) {
				next if !$args{secure} && exists $v3->{secure};
				my $value = $v3->{value};
				$value =~ s/([\\"])/\\$1/g;
				push @cookie, qq{$k="$value"};
			}
		}
	}
	return @cookie ? join "; ", @cookie : undef;
}

1;
