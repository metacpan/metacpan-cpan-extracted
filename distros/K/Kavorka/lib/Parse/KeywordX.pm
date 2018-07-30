use 5.014;
use strict;
use warnings;

use Exporter::Tiny ();

package Parse::KeywordX;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.039';

use Text::Balanced qw( extract_bracketed );
use PadWalker qw( closed_over set_closed_over peek_my );
use Parse::Keyword {};

our @ISA    = qw( Exporter::Tiny );
our @EXPORT = qw( parse_name parse_variable parse_trait parse_block_or_match );

#### From p5-mop-redux
sub read_tokenish ()
{
	my $token = '';
	if ((my $next = lex_peek) =~ /[\$\@\%]/)
	{
		$token .= $next;
		lex_read;
	}
	while ((my $next = lex_peek) =~ /\S/)
	{
		$token .= $next;
		lex_read;
		last if ($next . lex_peek) =~ /^\S\b/;
	}
	return $token;
}

#### From p5-mop-redux
sub parse_name
{
	my ($what, $allow_package, $stop_at_single_colon) = @_;
	my $name = '';
	
	# XXX this isn't quite right, i think, but probably close enough for now?
	my $start_rx = qr/^[\p{ID_Start}_]$/;
	my $cont_rx  = qr/^\p{ID_Continue}$/;
	my $char_rx = $start_rx;
	
	while (1)
	{
		my $char = lex_peek;
	
		last unless length $char;
		if ($char =~ $char_rx)
		{
			$name .= $char;
			lex_read;
			$char_rx = $cont_rx;
		}
		elsif ($allow_package && $char eq ':')
		{
			if (lex_peek(3) !~ /^::(?:[^:]|$)/)
			{
				return $name if $stop_at_single_colon;
				die("Not a valid $what name: $name" . read_tokenish);
			}
			$name .= '::';
			lex_read(2);
		}
		else
		{
			last;
		}
	}
	
	die("Not a valid $what name: " . read_tokenish) unless length $name;
	
	($name =~ /\A::/) ? "main$name" : $name;
}

sub parse_variable
{
	my $allow_bare_sigil = $_[0];
	
	my $sigil = lex_peek(1);
	($sigil eq '$' or $sigil eq '@' or $sigil eq '%')
		? lex_read(1)
		: die("Not a valid variable name: " . read_tokenish);
	
	my $name = $sigil;
	
	my $escape_char = 0;
	if (lex_peek(2) eq '{^')
	{
		lex_read(2);
		$name .= '{^';
		$name .= parse_name('escape-char variable', 0);
		lex_peek(1) eq '}'
			? ( lex_read(1), ($name .= '}') )
			: die("Expected closing brace after escape-char variable");
		return $name;
	}
	
	if (lex_peek =~ /[\w:]/)
	{
		$name .= parse_name('variable', 1, 1);
		return $name;
	}
	
	if ($allow_bare_sigil)
	{
		return $name;
	}
	
	die "Expected variable name";
}

sub parse_trait
{
	my $name = parse_name('trait', 0);
	#lex_read_space;
	
	my $extracted;
	if (lex_peek eq '(')
	{
		my $peek = lex_peek(1000);
		$extracted = extract_bracketed($peek, '()');
		lex_read(length $extracted);
		lex_read_space;
		$extracted =~ s/(?: \A\( | \)\z )//xgsm;
	}
	
	my $evaled = 1;
	if (defined $extracted)
	{
		my $ccstash = compiling_package;
		$evaled = eval("package $ccstash; no warnings; no strict; local \$SIG{__WARN__}=sub{die}; [$extracted]");
	}
	
	($name, $extracted, $evaled);
}

sub parse_block_or_match
{
	lex_read_space;
	return parse_block(@_) if lex_peek eq '{';
	
	require match::simple;
	
	my $___term = parse_arithexpr(@_);
	
	eval <<"CODE" or die("could not eval implied match::simple comparison: $@");
		sub {
			local \$_ = \@_ ? \$_[0] : \$_;
			match::simple::match(\$_, \$___term->());
		};
CODE
}

1;
