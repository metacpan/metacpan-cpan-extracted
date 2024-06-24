use strict;
use warnings;
use Keyword::Pluggable;

BEGIN {
	my %macros;
	Keyword::Pluggable::define keyword => 'inline', code => sub {
		my $r = shift;
		$$r =~ /\G\s*(\w+)/gcs or die "macro name expected";
		my $name = $1;
		die "macro '$name' is defined already" if $macros{$1}++;
		$$r =~ /\G\s*\(\s*([^\)]*)\s*\)/gcs or die "macro parameters expected";
		my @parmlist = split /\s*,\s*/, $1;
		$$r =~ /\G\s+\{\s*([^\}]*)\s*\}/gcs or die "macro body expected";
		my $body = $1;
		substr( $$r, 0, pos($$r), '');

		Keyword::Pluggable::define keyword => $name, expression => 1, code => sub {
			my $r = shift;
			$$r =~ /\G\s*\(\s*([^\)]*)\s*\)/gcs or die "macro $name parameters expected";
			my @args = split /\s*,\s*/, $1;
			die "macro $name expects ", scalar(@parmlist), " arguments, but ", scalar(@args), " were given"
				unless @args == @parmlist;
			my $xbody = $body;
			for ( my $i = 0; $i < @args; $i++) {
				my ($from, $to) = ( $parmlist[$i], $args[$i] );
				$xbody =~ s/\Q$from\E/$to/g;
			}
			substr( $$r, 0, pos($$r), $xbody);
		};
	}
}

inline sqr($x) { $x * $x }
print sqr(5), "\n";
