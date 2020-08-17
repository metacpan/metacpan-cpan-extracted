package Hades;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.04';
use Module::Generate;
use Switch::Again qw/switch/;

sub new {
	my ($class, $args) = @_;
	bless $args, $class;
}

sub run {
	my ($class, $args) = @_;
	$args->{eval} = _read_file($args->{file}) if $args->{file};
	my $mg = Module::Generate->start;
	$args->{$_} && $mg->$_($args->{$_}) for (qw/dist lib author email version/);
	my $self = $class->new($args);
	my ($index, $ident, @lines, @line, @innerline, $nested) = (0, '');
	while ($index < length $self->{eval}) {
		my $first_char = $self->index($index++);
		$ident =~ m/^:.*\(/
			? do {
				my $copy = $ident;
				while ($copy =~ s/\([^()]+\)//g) {}
				if ($copy =~ m/\(|\)/) {
					$ident .= $first_char;
				} else {
					push @innerline, $ident;
					$ident = '';
				}
			}
			: $first_char =~ m/\s/ && $ident !~ m/^$/
				? $nested && $nested == 1
					? $ident =~ m/^(:|\$|\%|\@|\&)/ ? do {
						push @innerline, $ident;
						$ident = '';
					} : do {
						push @line, [@innerline] if scalar @innerline;
						@innerline = ($ident);
						$ident = '';
					} : $nested
						? do {
							push @innerline, $ident;
							$ident = '';
						} : do {
							push @line, $ident;
							$ident = '';
						}
				: $first_char =~ m/\{/
					? ! $nested
						? $nested++
						: do {
							push @innerline, '{';
							$nested++;
						}
					: $first_char =~ m/\}/ && do { $nested--; 1; }
						? ! $nested
							? do {
								push @line, [@innerline] if @innerline;
								push @lines, [@line] if @line;
								(@innerline, @line) = ((), ());
							}
							: do {
								push @innerline, '}';
								if ($nested == 1) {
									push @line, [@innerline];
									@innerline = ();
								}
							}
						: do {
							$ident .= $first_char unless $first_char =~ m/\s/;
						};
	}
	if (scalar @lines) {
		my $last_token;
		for my $class (@lines) {
			if ($class->[0] eq 'macro') {
				shift @{$class};
				$mg->macro(shift @{$_}, join(' ', @{$_}) . ';') for @{$class};
				next;
			}
			while ($class->[0] =~ m/^(dist|lib|author|email|version)$/) {
				$mg->$1($class->[1]);
				shift @{$class}, shift @{$class};
			}
			my %meta;
			$mg->class(shift @{$class})->new;
			for my $token (@{$class}) {
				! ref $token
					? $token =~ m/^(parent|base|require|use)$/
						? do {
							$last_token = $token;
						} : do {
							$mg->$last_token($token);
						}
					: scalar @{$token} == 1
						? do {
							$meta{$token->[0]}->{meta} = 'ACCESSOR';
							$mg->accessor($token->[0]);
						}
						: $token->[1] eq '{'
							? do {
								my $name = shift @{$token};
								$name =~ m/^(begin|unitcheck|check|init|end|new)$/
									? $mg->$name(join ' ', @{$token})
									: $mg->sub($name)->code(sprintf qq|{
										my (\$self) = \@_;
										%s
									}|, join ' ', splice( @{$token}, 1, scalar @{$token} - 2))
									->pod(qq|call $name method. Expects no params.|)->example(qq|\$obj->$name()|);
							} : do {
								my $name = shift @{$token};
								$name =~ m/^(our)$/
									? $mg->$name( '(' . join( ', ', @{$token}) . ')')
									: $name =~ m/^(synopsis|abstract)$/
										? $mg->$name(join ' ', @{$token})
										: do {
											$meta{$name}->{meta} = 'ACCESSOR';
											my $switch = switch(
												qr/^(\:around|\:ar)/ => sub {
													$meta{$name}->{meta} = 'MODIFY';
													while ($token->[0] ne '{') { shift @{$token} }
													@{$token} = splice @{$token}, 1, scalar @{$token} - 2;
													$meta{$name}->{around} = join " ", map { shift @{$token} } 0 .. scalar @{$token} - 1;
												},
												qr/^(\:after|\:a)/ => sub {
													$meta{$name}->{meta} = 'MODIFY';
													while ($token->[0] ne '{') { shift @{$token} }
													@{$token} = splice @{$token}, 1, scalar @{$token} - 2;
													$meta{$name}->{after} = join " ", map { shift @{$token} } 0 .. scalar @{$token} - 1;
												},
												qr/^(\:before|\:b)/ => sub {
													$meta{$name}->{meta} = 'MODIFY';
													while ($token->[0] ne '{') { shift @{$token} }
													@{$token} = splice @{$token}, 1, scalar @{$token} - 2;
													$meta{$name}->{before} = join " ", map { shift @{$token} } 0 .. scalar @{$token} - 1;
												},
												qr/^(\:clearer|\:c)$/ => sub {
													$meta{$name}->{clearer} = 1;
												},
												qr/^(\:coerce|\:co)/ => sub {
													my $value = shift;
													$value =~ s/(\:co|\:coerce)\((.*)\)$/$2/g;
													$meta{$name}->{coerce} = $value;
													if ($meta{$name}->{params_map}) {
														$meta{$name}->{params_map}->{
															$meta{$name}->{param}->[-1]
														}->{coerce} = $value;
													}
												},
												qr/^(\:default|\:d)/ => sub {
													my $value = shift;
													$value =~ s/.*\((.*)\)/$1/;
													$value = '"' . $value . '"'
														if $value !~ m/^(\{|\[|\"|\'|q)|(\d+)/;
													$meta{$name}->{default} =  $value;
												},
												qr/^(\:private|\:p)$/ => sub {
													$meta{$name}->{private} = 1;
												},
												qr/^(\:predicate|\:pr)$/ => sub {
													$meta{$name}->{predicate} = 1;
												},
												qr/^(\:required|\:r)$/ => sub {
													$meta{$name}->{required} = 1;
												},
												qr/^(\:trigger|\:tr)/ => sub {
													my $value = shift;
													$value =~ s/(\:tr|\:trigger)\((.*)\)$/$2/g;
													$meta{$name}->{trigger} = $value;
												},
												qr/^(\:type|\:t)/ => sub {
													my $value = shift;
													$value =~ s/.*\((.*)\)/$1/;
													push @{$meta{$name}->{type}}, $value;
													if ($meta{$name}->{params_map}) {
														$meta{$name}->{params_map}->{
															$meta{$name}->{param}->[-1]
														}->{type} = $value;
													}
												},
												qr/^(\{)/ => sub {
													$meta{$name}->{meta} = 'METHOD';
													pop @{$token};
													$meta{$name}->{code} = join " ", map { shift @{$token} } 0 .. scalar @{$token} - 1;
												},
												qr/^(\%|\$|\@|\&)/ => sub {
													push @{$meta{$name}->{param}}, $_[0];
													$meta{$name}->{params_map}->{$_[0]} = {};
												}
											);
											$switch->(shift @{$token}) while scalar @{$token};
											if ($meta{$name}->{meta} eq 'ACCESSOR') {
												my $private = $self->build_private($name, $meta{$name}->{private});
												my $type = $self->build_coerce($name, '$value', $meta{$name}->{coerce})

												. $self->build_type($name, $meta{$name}->{type}[0]);
												my $trigger = $self->build_trigger($name, '$value', $meta{$name}->{trigger});
												my $code = qq|{
													my ( \$self, \$value ) = \@_; $private
													if ( defined \$value ) { $type
														\$self->{$name} = \$value; $trigger
													}
													return \$self->{$name};
												}|;
												$mg->accessor($name)->code($code);
											} elsif ($meta{$name}->{meta} eq 'MODIFY') {
												my $before_code = $meta{$name}->{before} || "";
												my $around_code = $meta{$name}->{around} || qq|my \@res = \$self->\$orig(\@params);|;
												my $after_code = $meta{$name}->{after} || "";
												my $code = qq|{
													my (\$orig, \$self, \@params) = ('SUPER::$name', \@_);
													$before_code$around_code$after_code
													return \@res;
												}|;
												$mg->sub($name)->code($code)->pod(qq|call $name method.|);
											} else {
												my $code = $meta{$name}->{code};
												my ($params, $subtype, $params_explanation) = ( '', '', '' );
												$subtype .= $self->build_private($name)
													if $meta{$name}->{private};
												if ($meta{$name}->{param}) {
													for my $param (@{ $meta{$name}->{param} }) {
														$params_explanation .= ', ' if $params_explanation;
														$params .= ', ' .  $param;
														my $pm = $meta{$name}->{params_map}->{$param};
														$subtype .= $self->build_coerce($name, $param, $pm->{coerce});
														if ($pm->{type}) {
															my $error_message = qq|die qq{$pm->{type}: invalid value $param for variable \\$param in method $name};|;
															$subtype .= $self->build_type($name, $pm->{type}, $param, $error_message);
															$params_explanation .= qq|param $param to be a $pm->{type}|;
														} else {
															$params_explanation .= qq|param $param to be any value including undef|;
														}
													}
												}
												$code = qq|{
													my (\$self $params) = \@_; $subtype
													$code;
												}|;
												$params =~ s/^,\s*//;
												my $example = qq|\$obj->$name($params)|;
												$mg->sub($name)->code($code)
													->pod(qq|call $name method. Expects $params_explanation.|)
													->example($example);
											}
											if ($meta{$name}->{clearer}) {
												$mg->sub(qq|clear_$name|)
												->code(qq|{
													my (\$self) = \@_;
													delete \$self->{$name};
													return \$self;
												}|)
												->pod(qq|clear $name accessor|)
												->example(qq|\$obj->clear_$name|);
											}
											if ($meta{$name}->{predicate}) {
												$mg->sub(qq|has_$name|)
												->code(qq|{
													my (\$self) = \@_;
													return !! \$self->{$name};
												}|)
												->pod(qq|has_$name will return true if $name accessor has a value.|)
												->example(qq|\$obj->has_$name|);
											}
										}
							};
			}
			my %class = %Module::Generate::CLASS;
			my $accessors = q|(|;
			map {
				$accessors .= qq|$_ => {|;
				$accessors .= qq|required=>1,| if $meta{$_}{required};
				$accessors .= qq|default=>$meta{$_}{default},| if $meta{$_}{default};
				$accessors .= qq|},|;
			} grep { $meta{$_}{meta} eq 'ACCESSOR' } keys %meta;
			$accessors .= q|)|;
			my $new = $class{CURRENT}{PARENT} || $class{CURRENT}{BASE} ? 'my $self = $cls->SUPER::new(%args)' : 'my $self = bless {}, $cls';
			my $code = qq|{
				my (\$cls, \%args) = (shift(), scalar \@_ == 1 ? \%{\$_[0]} : \@_);
				$new;
				my \%accessors = $accessors;
				for my \$accessor ( keys \%accessors ) {
					my \$value = \$self->\$accessor(defined \$args{\$accessor} ? \$args{\$accessor} : \$accessors{\$accessor}->{default});
					unless (!\$accessors{\$accessor}->{required} \|\| defined \$value) {
						die "\$accessor accessor is required";
					}
				}
				return \$self;
			}|;
			$class{CURRENT}{SUBS}{new}{CODE} = $code;
		}
	}
	$mg->generate;
}

sub _read_file {
	my ($file) = @_;
	open my $fh, '<', $file;
	my $content = do { local $/; <$fh>; };
	close $fh;
	return $content;
}

sub build_coerce {
	my ($self, $name, $param, $code) = @_;
	return defined $code ? $code =~ m/^\w+$/
		? qq|$param = \$self->$code($param);|
		: $code
	: q||;
}

sub build_trigger {
	my ($self, $name, $param, $code) = @_;
	return defined $code ? $code =~ m/^\w+$/
		? qq|\$self->$code($param);|
		: $code
	: q||;
}

sub build_private {
	my ($self, $name, $private) = @_;
        return $private ? qq|
		my \$private_caller = caller();
		if (\$private_caller ne __PACKAGE__) {
			die \"cannot call private method $name from \$private_caller\";
		}| : q||;
}

sub build_type {
	my ($self, $name, $type, $value, $error_string, $code) = @_;
	$value ||= '$value';
	$code ||= '';
	if ($type) {
		$error_string ||=  qq|die qq{$type: invalid value $value for accessor $name};|;
		my $switch = switch
			qr/^(Any)$/ => sub {
				return '';
			},
			qr/^(Item)$/ => sub {
				return '';
			},
			qr/^(Bool)$/ => sub {
				return qq|
					my \$ref = ref $value;
					if ((\$ref \|\| 'SCALAR') ne 'SCALAR' \|\| (\$ref ? \$$value : $value) !~ m/^(1\|0)\$/) {
						$error_string
					}
					$value = !!(\$ref ? \$$value : $value) ? 1 : 0;|;
			},
			qr/^(Str)$/ => sub {
				return qq|
					if (ref $value \|\| $value !~ m/.+/) {
						$error_string
					}|;
			},
			qr/^(Num)$/ => sub {
				return qq|
					if (ref $value \|\| $value !~ m/^[-+\\d]\\d*\\.?\\d\*\$/) {
						$error_string
					}|;
			},
			qr/^(Int)$/ => sub {
				return qq|
					if (ref $value \|\| $value !~ m/^[-+\\d]\\d\*\$/) {
						$error_string
					}|;
			},
			qr/^(Ref)$/ => sub {
				return qq|
					if (! ref $value) {
						$error_string
					}|;
			},
			qr/^(Ref\[(.*)\])$/ => sub {
				my ($val, @matches) = @_;
				$matches[1] = '"' . $matches[1] . '"' if $matches[1] =~ m/^[a-zA-Z]/;
				return qq|
					if ((ref($value) \|\| "") ne $matches[1]) {
						$error_string
					}|;
			},
			qr/^(ScalarRef)$/ => sub {
				return qq|
					if ((ref($value) \|\| "") ne "SCALAR") {
						$error_string
					}|;
			},
			qr/^(ScalarRef\[(.*)\])$/ => sub {
				my ($val, @matches) = @_;
				$matches[1] = '"' . $matches[1] . '"' if $matches[1] =~ m/^[a-zA-Z]/;
				return qq|
					if ((ref($value) \|\| "") ne $matches[1]) {
						$error_string
					}|;
			},
			qr/^(ArrayRef)$/ => sub {
				return qq|
					if ((ref($value) \|\| "") ne "ARRAY") {
						$error_string
					}|;
			},
			qr/^(ArrayRef\[(.*)\])$/ => sub {
				my ($val, @matches) = @_;
				@matches = map { my $h = $_; $h =~ s/^\s*|\s*//g; $h; } split ',', $matches[1];
				my $code = qq|
					if ((ref($value) \|\| "") ne "ARRAY") {
						$error_string
					}|;
				my $new_error_string = $self->extend_error_string($error_string, $value, '$item', qq| expected $matches[0]|);
				my $sub_code = $self->build_type($name, $matches[0], '$item', $new_error_string);
				$code .= qq|
					for my \$item (\@{ $value }) {$sub_code
					}| if $sub_code;
				$code .= qq|
					my \$length = scalar \@{$value};|
				if $matches[1] || $matches[2];
				$code .= qq|
					if (\$length < $matches[1]) {
						die qq{ArrayRef for $name must contain atleast $matches[1] items}
					}|
				if defined $matches[1];
				$code .= qq|
					if (\$length > $matches[2]) {
						die qq{ArrayRef for $name must not be greater than $matches[2] items}
					}|
				if defined $matches[2];
				return $code;
			},
			qr/^(HashRef)$/ => sub {
				return qq|
					if ((ref($value) \|\| "") ne "HASH") {
						$error_string
					}|;
			},
			qr/^(HashRef\[(.*)\])$/ => sub {
				my ($val, @matches) = @_;
				my $code = qq|
					if ((ref($value) \|\| "") ne "HASH") {
						$error_string
					}|;
				$error_string =~ s/};$/ expected $matches[1]};/;
				$error_string =~ s/\$value/\$item/;
				my $sub_code = $self->build_type($name, $matches[1], '$item', $error_string);
				$code .= qq|
					for my \$item (values \%{ $value }) {$sub_code
					}| if $sub_code;
 				return $code;
			},
			qr/^(CodeRef)$/ => sub {
				return qq|
					if ((ref($value) \|\| "") ne "CODE") {
						$error_string
					}|;
			},
			qr/^(RegexpRef)$/ => sub {
				return qq|
					if ((ref($value) \|\| "") ne "Regexp") {
						$error_string
					}|;
			},
			qr/^(GlobRef)$/ => sub {
				return qq|
					if ((ref($value) \|\| "") ne "GLOB") {
						$error_string
					}|;
			},
			qr/^(Object)$/ => sub {
				return qq|
					if ((ref($value) \|\| "") =~ m/^(\|HASH\|ARRAY\|SCALAR\|CODE\|GLOB)\$/) {
						$error_string
					}|;
			},
			qr/^(Map\[(.*)\])$/ => sub {
				my ($val, @matches) = @_;
				@matches = map { my $h = $_; $h =~ s/^\s*|\s*//g; $h; } split ',', $matches[1];
				my $code = qq|
					if ((ref($value) \|\| "") ne "HASH") {
						$error_string
					}|;
				my $key_error_string = $self->extend_error_string($error_string, $value, '$key', qq| expected $matches[0]|);
				my $key_sub_code = $self->build_type($name, $matches[0], '$key', $key_error_string);
				my $value_error_string = $self->extend_error_string($error_string, $value, '$val', qq| expected $matches[1]|);
				my $value_sub_code = $self->build_type($name, $matches[1], '$val', $value_error_string);
				$code .= qq|
					for my \$key (keys \%{ $value }) {
						my \$val = ${value}->{\$key};$key_sub_code$value_sub_code
					}| if $key_sub_code || $value_sub_code;
 				return $code;
			},
			qr/^(Tuple\[(.*)\])$/ => sub {
				my ($val, @matches) = @_;
				@matches = map { my $h = $_; $h =~ s/^\s*|\s*//g; $h; } split ',', $matches[1];
				my $code = qq|
					if ((ref($value) \|\| "") ne "ARRAY") {
						$error_string
					}|;
				my $i = 0;
				for my $match (@matches) {
					(my $new_value = $value) .= qq|->[$i]|;
					my $item_error_string = $self->extend_error_string($error_string, $value, $new_value, qq| expected $match for index $i|);
					my $key_sub_code = $self->build_type($name, $match, $new_value, $item_error_string);
					$code .= $key_sub_code;
					$i++;
				}
				return $code;
			},
			qr/^(Dict\[(.*)\])$/ => sub {
				my ($val, @matches) = @_;
				@matches = split ',', $matches[1];
				my $sub_code;
				while (@matches) {
					my ($match) = (shift @matches);
					if ($match =~ m/(Map|Tuple|ArrayRef|Dict)\[/) {
						my $lame = sub {
							my $copy = shift;
							while ($copy =~ s/\[[^\[\]]+\]//g) {}
							return ($copy =~ m/\[|\[/) ? 1 : 0;
						};
						while ($lame->($match .=  ', ' . shift @matches)) {}
					}
					my ($k, $v) = map { my $h = $_; $h =~ s/^\s*|\s*$//g; $h; } split('=>', $match, 2);
					(my $new_value = $value) .= qq|->{$k}|;
					my $new_error_string = $self->extend_error_string($error_string, $value, $new_value, qq| expected $v for $k|);
					$sub_code .= $self->build_type($k, $v, $new_value, $new_error_string);
				}
				my $code = qq|
					if ((ref($value) \|\| "") ne "HASH") {
						$error_string
					} $sub_code|;
				return $code;
			},
			qr/^(Optional\[(.*)\])$/ => sub {
				my ($val, @matches) = @_;
				my $sub_code = $self->build_type($name, $matches[1], $value, $error_string);
				my $code = qq|
					if (defined $value) { $sub_code
					}|;
				return $code;
			};
		$code .= $switch->($type);
	}
	return $code;
}

sub extend_error_string {
	my ($self, $error_string, $value, $new_value, $message) = @_;
	(my $new_error_string = $error_string) =~ s/\Q$value\E/$new_value/;
	$new_error_string =~ s/};$/$message};/;
	return $new_error_string;
}

sub index {
	my ($self, $index) = @_;
	return substr $self->{eval}, $index, 1;
}

1;

__END__

=head1 NAME

Hades - The great new Hades!

=head1 VERSION

Version 0.04

=cut

=head1 SYNOPSIS

	use Hades;

	Hades->run({
		eval => 'Kosmos { penthos :d(2) :p :pr :c :t(Int) curae :r geras $nosoi :t(Int) { if ($self->penthos == $nosoi) { return $self->curae; } } }'
	});

	... generates ...

	package Kosmos;
	use strict;
	use warnings;
	our $VERSION = 0.01;

	sub new {
		my ( $cls, %args ) = ( shift(), scalar @_ == 1 ? %{ $_[0] } : @_ );
		my $self = bless {}, $cls;
		my %accessors = ( curae => { required => 1, }, penthos => { default => 2, }, );
		for my $accessor ( keys %accessors ) {
			my $value = $self->$accessor(
				defined $args{$accessor}
					? $args{$accessor}
					: $accessors{$accessor}->{default}
			);
			unless ( !$accessors{$accessor}->{required} || defined $value ) {
				die "$accessor accessor is required";
			}
		}
		return $self;
	}

	sub penthos {
		my ( $self, $value ) = @_;
		my $private_caller = caller();
		if ( $private_caller ne __PACKAGE__ ) {
			die "cannot call private method penthos from $private_caller";
		}
		if ( defined $value ) {
			if ( ref $value || $value !~ m/^[-+\d]\d*$/ ) {
				die qq{Int: invalid value $value for accessor penthos};
			}
			$self->{penthos} = $value;
		}
		return $self->{penthos};
	}

	sub clear_penthos {
		my ($self) = @_;
		delete $self->{penthos};
		return $self;
	}

	sub has_penthos {
		my ($self) = @_;
		return !!$self->{penthos};
	}

	sub curae {
		my ( $self, $value ) = @_;
		if ( defined $value ) {
			$self->{curae} = $value;
		}
		return $self->{curae};
	}

	sub geras {
		my ( $self, $nosoi ) = @_;
		if ( ref $nosoi || $nosoi !~ m/^[-+\d]\d*$/ ) {
			die
			    qq{Int: invalid value $nosoi for variable \$nosoi in method geras};
		}
		if ( $self->penthos == $nosoi ) { return $self->curae; }
	}

	1;

	__END__

=head1 SUBROUTINES/METHODS

=head2 run

=over

=item file

Provide a file to read in.

=item eval

Provide a string to eval.

=item dist

Provide a name for the distribution.

=item lib

Provide a path where the generated files will be compiled.

=item author

The author of the distribution/module.

=item email

The authors email of the distribution/module.

=item version

The version number of the distribution/module.

=back

=cut

=head1 Hades

=cut

=head2 Class

Declare a new class.

	Kosmos {

	}

=cut

=head3 Inheritance

=cut

=head4 base

Establish an ISA relationship with base classes at compile time.

Unless you are using the fields pragma, consider this discouraged in favor of the lighter-weight parent.

	Kosmos base Kato {

	}

=cut

=head4 parent

Establish an ISA relationship with base classes at compile time.

	Kosmos parent Kato {

	}

=cut

=head4 require

Require library files to be included if they have not already been included.

	Kosmos require Kato {

	}

=cut

=head4 use

Declare modules that should be included in the class.

	Kosmos use Kato Vathys {

	}

=cut

=head2 Compile phase

=cut

=head3 begin

Define a code block is executed as soon as possible.

	Kosmos {
		begin {
			... perl code ...
		}
	}

=cut

=head3 unitcheck

Define a code block that is executed just after the unit which defined them has been compiled.

	Kosmos {
		unitcheck {
			... perl code ...
		}
	}

=cut

=head3 check

Define a code block that is executed just after the initial Perl compile phase ends and before the run time begins.

	Kosmos {
		check {
			... perl code ...
		}
	}

=cut

=head3 init

Define a code block that is executed just before the Perl runtime begins execution.

	Kosmos {
		init {
			... perl code ...
		}
	}

=cut

=head3 end

Define a code block is executed as late as possible.

	Kosmos {
		end {
			... perl code ...
		}
	}

=cut

=head2 Variables

=cut

=head3 our

Declare variable of the same name in the current package for use within the lexical scope.

	Kosmos {
		our $one %two
	}

=cut

=head2 Accessors

Declare an accessor for the class

	Kosmos {
		dokimi
	}

=cut

=head3 :required | :r

Making an accessor required means a value for the accessor must be supplied to the constructor.

	dokimi :r
	dokimes :required

=cut

=head3 :default | :d

The default is used when no value for the accessor was supplied to the constructor.

	dokimi :d(Eimai o monos)
	dokimes :default([{ ola => "peripou", o => [qw/kosmos/] }])

=cut

=head3 :clearer | :c

Setting clearer creates a method to clear the accessor.

	dokimi :c
	dokimes :clearer

	$class->clear_dokimi;

=cut

=head3 :coerce | :co

Takes a coderef which is meant to coerce the attributes value.

	dokimi :co(array_to_string)
	dokimes :coerce($value = $value->[0] if ref($value) || "" eq "ARRAY";)

=cut

=head3 :private | :p

Setting private makes the accessor only available to the class.

	dokimi :p
	dokimes :private

=cut

=head3 :predicate | :pr

Takes a method name which will return true if an attribute has a value. The predicate is automatically named has_${accessor}.

	dokimi :pr
	dokimes :predicate

=cut

=head3 :trigger | :tr

Takes a coderef which will get called any time the attribute is set.

	dokimi :tr(trigger_to_method)
	dokimes :trigger(warn Dumper $value)

=cut

=head3 :type | :t

Add type checking to the accessor.

	dokimi :t(Dict[onoma => Str, id => Optional[Int], epiloges => Dict[onama => Str]])
	dokimes :type(Str)

=cut

=head2 Methods

Declare a sub routine/method.

	Kosmos {
		dokimi {
			... perl code ...
		}
	}

=head3 Params

Methods will always have $self defined but you can define additional params by declaring them before the code block.

	dokimi $one %two {
		... perl code ...
	}

generates

	sub dokimi {
		my ($self, $one, %two) = @_;
		... perl code ...
	}

=cut

=head4 :type :t

Add type checking to the param.

	dokimi $one :t(Str) {
		... perl code ...
	}

	dokimes $one :t(Str) $two :t(HashRef) {
		... perl code ...
	}
=cut

=head4 :coerce | :co

Takes a coderef which is meant to coerce the method param.

	dokimi $str :co(array_to_string)
	dokimes $str :t(Str) :co(array_to_string)

=cut

=head3 :private :p

Setting private makes the method only available to the class.

	dokimi :p {
		... perl code ...
	}
	dokimes :private $one %two {
		... perl code ...
	}

=cut

=head3 :before | :b

Before is called before the parent method is called. You can modify the params using the @params variable.

	dokimi :b {
		... before ...
	}:

generates

	sub dokimi {
		my ( $orig, $self, @params ) = ( 'SUPER::geras', @_ );
		... before ...
		my @res = $self->$orig(@params);
        	return @res;
	}

=cut

=head3 :around | :ar

Around is called instead of the method it is modifying. The method you're overriding is passed in as the first argument (called $orig by convention). You can modify the params using the @params variable.

	dokimi :ar {
		... before around ...
		my @res = $self->$orig(@params);
		... after around ...
	}

generates

	sub dokimi {
		my ( $orig, $self, @params ) = ( 'SUPER::geras', @_ );
		... before around ...
		my @res = $self->$orig(@params);
		... after around ...
        	return @res;
	}


=cut

=head3 :after | :a

After is called after the parent method is called. You can modify the response using the @res variable.

	dokimi :a {
		... after ...
	}

generates

	sub dokimi {
		my ( $orig, $self, @params ) = ( 'SUPER::geras', @_ );
		my @res = $self->$orig(@params);
		... after ...
		return @res;
	}

=cut

=head2 Types

=cut

=head3 Any

Absolutely any value passes this type constraint (even undef).

	dokimi :t(Any)

=cut

=head3 Item

Essentially the same as Any. All other type constraints in this library inherit directly or indirectly from Item.

	dokimi :t(Item)

=cut

=head3 Bool

Values that are reasonable booleans. Accepts 1, 0, the empty string and undef.

	dokimi :t(Bool)

=cut

=head3 Str

Any string.

	dokimi :t(Str)

=cut

=head3 Num

Any number.

	dokimi :t(Num)

=cut

=head3 Int

An integer; that is a string of digits 0 to 9, optionally prefixed with a hyphen-minus character.

	dokimi :t(Int)

=cut

=head3 Ref

Any defined reference value, including blessed objects.

	dokimi :t(Ref)
	dokimes :t(Ref[HASH])

=cut

=head3 ScalarRef

A value where ref($value) eq "SCALAR" or ref($value) eq "REF".

	dokimi :t(ScalarRef)
	dokimes :t(ScalarRef[SCALAR])

=cut

=head3 ArrayRef

A value where ref($value) eq "ARRAY".

	dokimi :t(ArrayRef)
	dokimes :t(ArrayRef[Str, 1, 100])

=cut

=head3 HashRef

A value where ref($value) eq "HASH".

	dokimi :t(HashRef)
	dokimes :t(HashRef[Int])

=cut

=head3 CodeRef

A value where ref($value) eq "CODE"

	dokimi :t(CodeRef)

=cut

=head3 RegexpRef

A value where ref($value) eq "Regexp"

	dokimi :t(RegexpRef)

=cut

=head3 GlobRef

A value where ref($value) eq "GLOB"

	dokimi :t(GlobRef)

=cut

=head3 Object

A blessed object.

	dokimi :t(Object)

=cut

=head3 Map

Similar to HashRef but parameterized with type constraints for both the key and value. The constraint for keys would typically be a subtype of Str.

	dokimi :t(Map[Str, Int])

=cut

=head3 Tuple

Accepting a list of type constraints for each slot in the array.

	dokimi :t(Tuple[Str, Int, HashRef])

=cut

=head3 Dict

Accepting a list of type constraints for each slot in the hash.

	dokimi :t(Dict[onoma => Str, id => Optional[Int], epiloges => Dict[onama => Str]])

=cut

=head3 Optional

Used in conjunction with Dict and Tuple to specify slots that are optional and may be omitted.

	dokimi :t(Optional[Str])

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-hades at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hades>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hades

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Hades>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hades>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Hades>

=item * Search CPAN

L<https://metacpan.org/release/Hades>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Hades
