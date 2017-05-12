use 5.008;
use strict;
use warnings;

{
	package JSON::Tiny::Subclassable;

	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.005';
	our @ISA       = qw(JSON::Tiny);
	
	use B;
	use Encode ();
	use Scalar::Util ();
	
	BEGIN {
		eval { require Sub::Name; Sub::Name->import('subname'); 1 }
			or eval q{ sub subname { $_[1] } };
	};
	
	sub new {
		my $class = shift;
		bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, $class;
	}
	
	sub error {
		$_[0]->{error} = $_[1] if @_ > 1;
		return $_[0]->{error};
	}
	
	sub pretty {
		$_[0]->{pretty} = $_[1] if @_ > 1;
		return $_[0]->{pretty};
	}
	
	sub import {
		my $class  = shift;
		my $caller = caller;
		my $opts   = {};
		while (@_) {
			my $arg = shift;
			$opts->{$arg} = ref $_[0] ? shift @_ : undef;
		}
		if (exists $opts->{'j'}) {
			my $func = ((ref $opts->{j} eq 'HASH') && $opts->{j}{-as}) || 'j';
			no strict 'refs';
			*{"$caller\::$func"} = subname "$class\::j" => sub {
				my $d = shift;
				return $class->new->encode($d) if ref $d eq 'ARRAY' || ref $d eq 'HASH';
				return $class->new->decode($d);
			};
			delete $opts->{'j'};
		}
	}
	
	__PACKAGE__->import('j');
	
	# Literal names
	my $FALSE = bless \(my $false = 0), 'JSON::Tiny::_Bool';
	my $TRUE  = bless \(my $true  = 1), 'JSON::Tiny::_Bool';
	
	# Escaped special character map (with u2028 and u2029)
	my %ESCAPE = (
		'"'     => '"',
		'\\'    => '\\',
		'/'     => '/',
		'b'     => "\x07",
		'f'     => "\x0C",
		'n'     => "\x0A",
		'r'     => "\x0D",
		't'     => "\x09",
		'u2028' => "\x{2028}",
		'u2029' => "\x{2029}"
	);
	my %REVERSE = map { $ESCAPE{$_} => "\\$_" } keys %ESCAPE;
	for (0x00 .. 0x1F, 0x7F) {
		my $k = pack 'C', $_;
		$REVERSE{$k} = sprintf '\u%.4X', $_ unless defined $REVERSE{$k};
	}
	
	# Unicode encoding detection
	my $UTF_PATTERNS = {
		'UTF-32BE' => qr/^\0\0\0[^\0]/,
		'UTF-16BE' => qr/^\0[^\0]\0[^\0]/,
		'UTF-32LE' => qr/^[^\0]\0\0\0/,
		'UTF-16LE' => qr/^[^\0]\0[^\0]\0/
	};
	
	my $WHITESPACE_RE = qr/[\x20\x09\x0a\x0d]*/;
	
	sub DOES {
		my ($proto, $role) = @_;
		return 1 if $role eq 'Mojo::JSON';
		return $proto->SUPER::DOES($role);
	}
	
	sub decode {
		my ($self, $bytes) = @_;
		
		# Cleanup
		$self->error(undef);
		
		# Missing input
		$self->error('Missing or empty input') and return undef unless $bytes; ## no critic (undef)
		
		# Remove BOM
		$bytes =~ s/^(?:\357\273\277|\377\376\0\0|\0\0\376\377|\376\377|\377\376)//g;
		
		# Wide characters
		$self->error('Wide character in input') and return undef ## no critic (undef)
			unless utf8::downgrade($bytes, 1);
		
		# Detect and decode Unicode
		my $encoding = 'UTF-8';
		$bytes =~ $UTF_PATTERNS->{$_} and $encoding = $_ for keys %$UTF_PATTERNS;
		
		my $d_res = eval { $bytes = Encode::decode($encoding, $bytes, 1); 1 };
		$bytes = undef unless $d_res;
		
		# Object or array
		my $res = eval {
			local $_ = $bytes;
			
			# Leading whitespace
			m/\G$WHITESPACE_RE/gc;
			
			# Array
			my $ref;
			if (m/\G\[/gc) { $ref = $self->_decode_array() }
			
			# Object
			elsif (m/\G\{/gc) { $ref = $self->_decode_object() }
			
			# Unexpected
			else { $self->_exception('Expected array or object') }
			
			# Leftover data
			unless (m/\G$WHITESPACE_RE\z/gc) {
				my $got = ref $ref eq 'ARRAY' ? 'array' : 'object';
				$self->_exception("Unexpected data after $got");
			}
			
			$ref;
		};
		
		# Exception
		if (!$res && (my $e = $@)) {
			chomp $e;
			$self->error($e);
		}
		
		return $res;
	}
	
	sub encode {
		my ($self, $ref) = @_;
		
		my $eof = '';
		if ($self->pretty) {
			$self->{_indent} = '';
			$eof .= "\n";
		}
		
		return Encode::encode 'UTF-8', $self->_encode_values($ref).$eof;
	}
	
	sub false {$FALSE}
	sub true  {$TRUE}
	
	sub _new_hash  { +{} }
	sub _new_array { +[] }
	
	sub _decode_array {
		my $self  = shift;
		my $array = $self->_new_array;
		until (m/\G$WHITESPACE_RE\]/gc) {
			
			# Value
			push @$array, $self->_decode_value();
			
			# Separator
			redo if m/\G$WHITESPACE_RE,/gc;
			
			# End
			last if m/\G$WHITESPACE_RE\]/gc;
			
			# Invalid character
			$self->_exception('Expected comma or right square bracket while parsing array');
		}
		
		return $array;
	}
	
	sub _decode_object {
		my $self = shift;
		my $hash = $self->_new_hash;
		until (m/\G$WHITESPACE_RE\}/gc) {
			
			# Quote
			m/\G$WHITESPACE_RE"/gc
				or $self->_exception('Expected string while parsing object');
			
			# Key
			my $key = $self->_decode_string();
			
			# Colon
			m/\G$WHITESPACE_RE:/gc
				or $self->_exception('Expected colon while parsing object');
			
			# Value
			$hash->{$key} = $self->_decode_value();
			
			# Separator
			redo if m/\G$WHITESPACE_RE,/gc;
			
			# End
			last if m/\G$WHITESPACE_RE\}/gc;
			
			# Invalid character
			$self->_exception('Expected comma or right curly bracket while parsing object');
		}
		
		return $hash;
	}
	
	sub _decode_string {
		my $self = shift;
		my $pos = pos;
		
		# Extract string with escaped characters
		m#\G(((?:[^\x00-\x1F\\"]|\\(?:["\\/bfnrt]|u[[:xdigit:]]{4})){0,32766})*)#gc;
		my $str = $1;
		
		# Missing quote
		unless (m/\G"/gc) {
			$self->_exception('Unexpected character or invalid escape while parsing string')
				if m/\G[\x00-\x1F\\]/;
			$self->_exception('Unterminated string');
		}
		
		# Unescape popular characters
		if (index($str, '\\u') < 0) {
			$str =~ s!\\(["\\/bfnrt])!$ESCAPE{$1}!gs;
			return $str;
		}
		
		# Unescape everything else
		my $buffer = '';
		while ($str =~ m/\G([^\\]*)\\(?:([^u])|u(.{4}))/gc) {
			$buffer .= $1;
			
			# Popular character
			if ($2) { $buffer .= $ESCAPE{$2} }
			
			# Escaped
			else {
				my $ord = hex $3;
				
				# Surrogate pair
				if (($ord & 0xF800) == 0xD800) {
					
					# High surrogate
					($ord & 0xFC00) == 0xD800
						or pos($_) = $pos + pos($str), $self->_exception('Missing high-surrogate');
					
					# Low surrogate
					$str =~ m/\G\\u([Dd][C-Fc-f]..)/gc
						or pos($_) = $pos + pos($str), $self->_exception('Missing low-surrogate');
					
					# Pair
					$ord = 0x10000 + ($ord - 0xD800) * 0x400 + (hex($1) - 0xDC00);
				}
				
				# Character
				$buffer .= pack 'U', $ord;
			}
		}
		
		# The rest
		return $buffer . substr $str, pos($str), length($str);
	}
	
	sub _decode_value {
		my $self = shift;
		
		# Leading whitespace
		m/\G$WHITESPACE_RE/gc;
		
		# String
		return $self->_decode_string() if m/\G"/gc;
		
		# Array
		return $self->_decode_array() if m/\G\[/gc;
		
		# Object
		return $self->_decode_object() if m/\G\{/gc;
		
		# Number
		return 0 + $1
			if m/\G([-]?(?:0|[1-9][0-9]*)(?:\.[0-9]*)?(?:[eE][+-]?[0-9]+)?)/gc;
		
		# True
		return $self->true if m/\Gtrue/gc;
		
		# False
		return $self->false if m/\Gfalse/gc;
		
		# Null
		return undef if m/\Gnull/gc;  ## no critic (return)
		
		# Invalid data
		$self->_exception('Expected string, array, object, number, boolean or null');
	}
	
	sub _encode_array {
		my $self = shift;
		
		return "[]" unless @{$_[0]};
		
		return '[' . join(',', map { $self->_encode_values($_) } @{shift()}) . ']'
			unless exists $self->{_indent};
		
		my $indent = $self->{_indent};
		return "\[\n$indent\t"
			. join(",\n$indent\t", map {
				local $self->{_indent} = "$indent\t"; $self->_encode_values($_)
			} @{shift()})
			. "\n$indent\]";
	}
	
	sub _encode_object {
		my $self = shift;
		my $object = shift;
		
		my $indent;
		if (exists $self->{_indent}) {
			$indent = $self->{_indent};
			$self->{_indent} .= "\t";
		}
		
		# Encode pairs
		my @pairs;
		my $space = defined $indent ? q( ) : q();
		while (my ($k, $v) = each %$object) {
			push @pairs, sprintf(
				'%s:%s%s',
				$self->_encode_string($k),
				$space,
				$self->_encode_values($v),
			);
		}
		
		if (defined $indent)
		{
			$self->{_indent} =~ s/^.//;
			return "{}" unless @pairs;
			return "\{\n$indent\t" . join(",\n$indent\t", @pairs) . "\n$indent\}";
		}
		else
		{
			return '{' . join(',', @pairs) . '}';
		}
	}
	
	sub _encode_string {
		my $self = shift;
		my $string = shift;
		
		# Escape string
		$string =~ s!([\x00-\x1F\x7F\x{2028}\x{2029}\\"/\b\f\n\r\t])!$REVERSE{$1}!gs;
		
		# Stringify
		return "\"$string\"";
	}
	
	sub _encode_values {
		my $self = shift;
		my $value = shift;
		
		# Reference
		if (my $ref = ref $value) {
			
			# Array
			return $self->_encode_array($value) if $ref eq 'ARRAY';
			
			# Object
			return $self->_encode_object($value) if $ref eq 'HASH';
			
			# True or false
			return $$value ? 'true' : 'false' if $ref eq 'SCALAR';
			return $value  ? 'true' : 'false' if $ref eq 'JSON::Tiny::_Bool';
			
			# Blessed reference with TO_JSON method
			if (Scalar::Util::blessed $value && (my $sub = $value->can('TO_JSON'))) {
				return $self->_encode_values($value->$sub);
			}
		}
		
		# Null
		return 'null' unless defined $value;
		
		# Number
		return 0 + $value
			if B::svref_2object(\$value)->FLAGS & (B::SVp_IOK | B::SVp_NOK);
		
		# String
		return $self->_encode_string($value);
	}
	
	sub _exception {
		my $self = shift;
		
		# Leading whitespace
		m/\G$WHITESPACE_RE/gc;
		
		# Context
		my $context = 'Malformed JSON: ' . shift;
		if (m/\G\z/gc) { $context .= ' before end of data' }
		else {
			my @lines = split /\n/, substr($_, 0, pos);
			$context .= ' at line ' . @lines . ', offset ' . length(pop @lines || '');
		}
		
		# Throw
		die "$context\n";
	}
}

{
	package JSON::Tiny::_Bool;
	no warnings;
	use overload
		'0+' => sub { ${$_[0]} },
		'""' => sub { ${$_[0]} },
		fallback => 1,
	;
	sub DOES {
		my ($proto, $role) = @_;
		return 1 if $role eq 'Mojo::JSON::_Bool';
		return 1 if $role =~ /^JSON::(?:PP::|XS::)?Boolean$/;
		return $proto->SUPER::DOES($role);
	}
}

1;

__END__

=head1 NAME

JSON::Tiny::Subclassable

=head1 DESCRIPTION

Although technically this is a subclass of L<JSON::Tiny>, in practice
it's a fork because it overrides every method, and never calls the
supermethods. In fact, even though this is a subclass of L<JSON::Tiny>,
you don't need to have the latter installed to use this module.

The main difference between this module and its parent is that all the
internal calls to private functions have been replaces with calls to
private methods. This makes it easy to override particular parts of the
JSON parsing/generation algorithm.

The other tiny added feature is to support pretty indented output.

This module was written was to make developing L<JSON::MultiValueOrdered>
simpler, but it may be of some use for other purposes as well.

JSON::Tiny::Subclassable is a subclass of L<JSON::Tiny>, which is itself a
fork of L<Mojo::JSON>. Except where noted, the methods listed below behave
identically to the methods of the same names in the superclass.

=head2 Constructor

=over

=item C<< new(%attributes) >>

=back

=head2 Attributes

=over

=item C<< pretty >>

If set to true, indents generated JSON in a pretty fashion.

=item C<< error >>

=back

=head2 Methods

=over

=item C<< decode($bytes) >>

=item C<< encode($ref) >>

=item C<< false >>

=item C<< true >>

=item C<< DOES($role) >>

As per L<UNIVERSAL>::C<DOES>. Returns true for L<Mojo::DOM>.

=back

=head2 Functions

=over

=item C<< j(\@array) >> / C<< j(\%hash) >> / C<< j($bytes) >>

Encode or decode JSON as applicable.

This function may be exported, but is not exported by default. You may
request to import it with a different name:

   use JSON::Tiny::Subclassable j => { -as => 'quick_json' };

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=JSON-MultiValueOrdered>.

=head1 SEE ALSO

L<JSON::Tiny>,
L<Mojo::JSON>.

=head1 AUTHORS

David J. Oswald.

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013 by Toby Inkster.

Portions copyright 2012-2013 David J. Oswald.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

