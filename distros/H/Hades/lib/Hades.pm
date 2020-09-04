package Hades;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.18';
use Module::Generate;
use Switch::Again qw/switch/;
use Hades::Myths { as_keywords => 1 };

our ($PARENTHESES, $PARSE_PARAM_STRING);
BEGIN {
	$PARENTHESES = qr{ \( ( (?: (?> [^()]+ ) | (??{ $PARENTHESES }) )* ) \) }x;
	$PARSE_PARAM_STRING = qr{ (^ (?: (?> [^(),]+ ) | (??{ $PARENTHESES }) )* ) \, }x;
}

sub new {
	my ($class, %args) = (shift, scalar @_ == 1 ? %{$_[0]} : @_);
	$args{macros} = {} if !$args{macros};
	eval qq|require "Data::Dumper"| if $args{debug};
	bless \%args, $class;
}

sub verbose {
	my ($self, $verbose) = @_;
	if (defined $verbose) {
		$self->{verbose} = !!$verbose;
	}
	return $self->{verbose};
}

sub debug {
	my ($self, $debug) = @_;
	if (defined $debug) {
		$self->{debug} = !!$debug;
	}
	return $self->{debug};
}

sub debug_step {
	my ($self, $message, @debug) = @_;
	if ($self->debug || $self->verbose) {
		$self->{debug_step}++;
		my @caller = caller();
		print "hades step $self->{debug_step} line $caller[2]: $message\n";
		if ($self->debug) {
			print Data::Dumper::Dumper $_ for (@debug);
			print press_enter_to_continue . "\n";
			my $ahh = <STDIN>;
		}
	}
}

sub run {
	my ($class, $args) = @_;
	$args->{eval} = _read_file($args->{file}) if $args->{file};
	my $mg = Module::Generate->start;
	$args->{$_} && $mg->$_($args->{$_}) for (qw/dist lib tlib author email version/);
	if ($args->{realm}) {
		$class = sprintf "Hades::Realm::%s", $args->{realm};
		eval "require $class";
	}
	my $self = $class->new($args);
	$self->debug_step(sprintf(debug_step_1, $class), $args);
	$self->can('module_generate') && $self->module_generate($mg, $class);
	$self->debug_step(sprintf(debug_step_2, $class), $args->{eval});
	my ($index, $ident, @lines, @line, @innerline, $nested) = (0, '');
	while ($index <= length $self->{eval}) {
		my $first_char = $self->index($index++);
		$ident =~ m/^((:.*\()|(\{)|(\[))/
			? do {
				my $copy = $ident;
				$copy =~ s/\\\{|\\\}|\\\(|\\\)|\\\[|\\\]//g; # remove escaped
				1 while ($copy =~ s/\([^()]*\)|\{[^{}]*\}|\[[^\[\]]*\]//g);
				($copy =~ m/\(|\{|\[|\)|\}|\]/) ? do {
					$ident .= $first_char;
				} : do {
					if ($nested) {
						push @innerline, $ident;
					} else {
						push @line, $ident;
					}
					$ident = '';
				}
			}
			: ($first_char =~ m/\s/ && $ident !~ m/^$/)
				? (($nested)
					? ($ident =~ m/^(:|\$|\%|\@|\&)/) ? do {
							push @innerline, $ident;
						} : do {
							push @line, [@innerline] if scalar @innerline;
							@innerline = ($ident);
						}
					: do {
						push @line, $ident;
					}) && do { $ident = '' }
				: ($first_char =~ m/\{/)
					? ! $nested ? $nested++ : do {
						push @innerline, $ident if $ident;
						$ident = '{';
					}
					: ($first_char =~ m/\}/ && do { $nested--; 1; })
						? do{
							push @line, [@innerline] if @innerline;
							push @lines, [@line] if @line;
							(@innerline, @line) = ((), ());
						}
						: do {
							$ident .= $first_char unless $first_char =~ m/\s/;
						};
	}
	if (scalar @lines) {
		$self->debug_step(sprintf(debug_step_3, scalar @lines), \@lines);
		my $last_token;
		for my $class (@lines) {
			$self->can('before_class') && $self->before_class($mg, $class);
			my $meta = {};
			for my $token (@{$self->build_class($mg, $class)}) {
				$self->debug_step(debug_step_13, $token);
				! ref $token
					? do { $last_token = $self->build_class_inheritance($mg, $last_token, $token); }
					: scalar @{$token} == 1
						? $self->build_accessor_no_arguments($mg, $token, $meta)
						: $token->[0] =~ m/^(synopsis|abstract|test)$/
							? do { my $m = "build_$1"; $self->$m($mg, $token, $meta); }
							: $token->[1] =~ s/^{|}$//g
								? $self->build_sub_no_arguments($mg, $token, $meta)
								: $token->[0] =~ m/^(our)$/
									? $self->build_our($mg, $token, $meta)
									: $self->build_sub_or_accessor($mg, $token, $meta);
			}
			if (scalar keys %{$meta}) {
				$self->build_new($mg, $meta);
				$self->can('after_class') && $self->after_class($mg, $meta);
				$self->debug_step(debug_step_35, $meta);	
			}
		}
		$self->debug_step(debug_step_36);
	}
	$self->can('before_generate') && $self->before_generate($mg);
	$self->debug_step(debug_step_37);
	$mg->generate;
	$self->can('after_generate') && $self->after_generate($mg);
}

sub build_class {
	my ($self, $mg, $class) = @_;
	while ($class->[0] =~ m/^(dist|lib|tlib|realm|author|email|version)$/) {
		$mg->$1($class->[1]);
		$self->debug_step(sprintf(debug_step_4, $1, $class->[1]));
		shift @{$class}, shift @{$class};
	}
	if ($class->[0] eq 'macro') {
		shift @{$class};
		$self->debug_step(debug_step_5, $class);
		$self->build_macro($mg, $class);
		return [];
	}
	$self->debug_step(sprintf (debug_step_12, $class->[0]), $class);
	$mg->class(shift @{$class})->new;
	return $class;
}

sub build_new {
	my ($self, $mg, $meta) = @_;
	my %class = %Module::Generate::CLASS;
	$self->debug_step(sprintf (debug_step_33, $class{CURRENT}{NAME}), $meta);
	my $accessors = q|(|;
	map {
		$accessors .= qq|$_ => {|;
		$accessors .= qq|required => 1,| if $meta->{$_}->{required};
		$accessors .= qq|default => $meta->{$_}->{default},| if $meta->{$_}->{default};
		$accessors .= qq|builder => sub { my (\$self, \$value) = \@_;| . $self->build_builder($_, '$value', $meta->{$_}->{builder}) . qq|return \$value;}|
			if $meta->{$_}->{builder};
		$accessors .= qq|},|;
	} grep { $meta->{$_}->{meta} eq 'ACCESSOR' } keys %{$meta};
	$accessors .= q|)|;
	my $new = $class{CURRENT}->{PARENT} || $class{CURRENT}->{BASE} ? 'my $self = $cls->SUPER::new(%args)' : 'my $self = bless {}, $cls';
	my $code = qq|{
		my (\$cls, \%args) = (shift(), scalar \@_ == 1 ? \%{\$_[0]} : \@_);
		$new;
		my \%accessors = $accessors;
		for my \$accessor ( keys \%accessors ) {
			my \$param = defined \$args{\$accessor} ? \$args{\$accessor} : \$accessors{\$accessor}->{default};
			my \$value = \$self->\$accessor(
				\$accessors{\$accessor}->{builder} ? \$accessors{\$accessor}->{builder}->(
					\$self,
					\$param
				) : \$param
			);
			unless (!\$accessors{\$accessor}->{required} \|\| defined \$value) {
				die "\$accessor accessor is required";
			}
		}
		return \$self;
	}|;
	$class{CURRENT}{SUBS}{new}{CODE} = $code;
	$class{CURRENT}{SUBS}{new}{TEST} = [$self->build_tests('new', $meta, 'new', \%class)];
	$self->debug_step(sprintf (debug_step_34, $class{CURRENT}{NAME}), $code);
}

sub build_class_inheritance {
	my ($self, $mg, $last_token, $token) = @_;
	($token =~ m/^(parent|base|require|use)$/) ? do {
		$self->debug_step(sprintf(debug_step_14, $token), sprintf(debug_step_14_b, $token));
		$last_token = $token;
	} : do {
		$self->debug_step(sprintf(debug_step_15, $last_token, $token));
		$mg->$last_token($token);
	};
	return $last_token;
}

sub build_accessor_no_arguments {
	my ($self, $mg, $token, $meta) = @_;
	$meta->{$token->[0]}->{meta} = 'ACCESSOR';
	$self->debug_step(sprintf(debug_step_16, $token->[0]), $meta->{$token->[0]});
	$mg->accessor($token->[0]);
	return $meta;
}

sub build_sub_no_arguments {
	my ($self, $mg, $token, $meta) = @_;
	my $name = shift @{$token};
	$self->debug_step(sprintf(debug_step_18, $name), $meta->{$name});
	$name =~ m/^(begin|unitcheck|check|init|end|new)$/
		? $mg->$name('{' . join( ' ', @{$token}) . '}')
		: $mg->sub($name)->code($self->build_code($mg, $name, $self->build_sub_code($name, '', '', join ' ', @{$token})))
		->pod(qq|call $name method. Expects no params.|)->example(qq|\$obj->$name()|);
	return $meta;
}

sub build_our {
	my ($self, $mg, $token, $meta) = @_;
	my $name = shift @{$token};
	$self->debug_step(debug_step_19, $token);	
	$mg->$name( '(' . join( ', ', @{$token}) . ')');
	return $meta;
}

sub build_synopsis { goto &build_synopsis_or_abstract; }

sub build_abstract { goto &build_synopsis_or_abstract; }

sub build_test {
	my ($self, $mg, $token, $meta) = @_;
	my ($name, $content) = @{$token};
	$self->debug_step(sprintf(debug_step_17, $name), $content);
	$content =~ s/^\{\s*|\s*\}$//g;
	$mg->class_tests(eval $content);
	return $meta;
}

sub build_synopsis_or_abstract {
	my ($self, $mg, $token, $meta) = @_;
	my ($name, $content) = @{$token};
	$self->debug_step(sprintf(debug_step_17, $name), $content);
	$content =~ s/^\{\s*|\s*\}$//g;
	$mg->$name($content);
	return $meta;
}

sub build_sub_or_accessor_attributes {
	my ($self, $name, $token, $meta) = @_;
	my @ATTR = (
		'default' => sub {
			my $value = shift;
			push @{$meta->{$name}->{caught}}, $value;
		},
		qr/^(\:around|\:ar)$/ => sub {
			$meta->{$name}->{meta} = 'MODIFY';
			$token->[-1] =~ s/^\{(.*)\}$/$1/sg;
			$meta->{$name}->{around} = pop @{$token};
		},
		qr/^(\:after|\:a)$/ => sub {
			$meta->{$name}->{meta} = 'MODIFY';
			$token->[-1] =~ s/^\{(.*)\}$/$1/sg;
			$meta->{$name}->{after} = pop @{$token};
		},
		qr/^(\:before|\:b)$/ => sub {
			$meta->{$name}->{meta} = 'MODIFY';
			$token->[-1] =~ s/^\{(.*)\}$/$1/sg;
			$meta->{$name}->{before} = pop @{$token};
		},
		qr/^(:builder|:bdr)/ => sub {
			my $value = shift;
			$value =~ s/(\:bd|\:build)\((.*)\)$/$2/sg;
			$meta->{$name}->{builder} = $2 ? $value : 1;
		},
		qr/^(\:clearer|\:c)$/ => sub {
			$meta->{$name}->{clearer} = 1;
		},
		qr/^(\:coerce|\:co)/ => sub {
			my $value = shift;
			$value =~ s/(\:co|\:coerce)\((.*)\)$/$2/sg;
			$meta->{$name}->{coerce} = $value;
			if ($meta->{$name}->{params_map}) {
				$meta->{$name}->{params_map}->{
					$meta->{$name}->{param}->[-1]
				}->{coerce} = $value;
			}
		},
		qr/^(\:default|\:d)/ => sub {
			my $value = shift;
			$value =~ s/.*\((.*)\)/$1/sg;
			$value = '"' . $value . '"'
				if $value !~ m/^(\{|\[|\"|\'|\$|\£|q)|(\d+)/;
			$meta->{$name}->{default} =  $value;
			if ($meta->{$name}->{params_map}) {
				$meta->{$name}->{params_map}->{
					$meta->{$name}->{param}->[-1]
				}->{default} = $value;
			}
		},
		qr/^(\:example)/ => sub {
			my $value = shift;
			$value =~ s/^\:example\(\s*(.*)\s*\)$/$1/sg;
			$meta->{$name}->{example} =  $value;
		},
		qr/^(\:no_success_test)/ => sub {
			$meta->{$name}->{no_success_test} = 1;
		},
		qr/^(\:pod)/ => sub {
			my $value = shift;
			$value =~ s/^:pod\(\s*(.*)\s*\)$/$1/sg;
			$meta->{$name}->{pod} =  $value;
		},
		qr/^(\:private|\:p)$/ => sub {
			$meta->{$name}->{private} = 1;
		},
		qr/^(\:predicate|\:pr)$/ => sub {
			$meta->{$name}->{predicate} = 1;
		},
		qr/^(\:required|\:r)$/ => sub {
			$meta->{$name}->{required} = 1;
		},
		qr/^(\:trigger|\:tr)/ => sub {
			my $value = shift;
			$value =~ s/(\:tr|\:trigger)\((.*)\)$/$2/sg;
			$meta->{$name}->{trigger} = $value;
		},
		qr/^(\:test|\z)/ => sub {
			my $value = shift;
			$value =~ s/^(\:test|\:z)\(\s*(.*)\s*\)$/$2/sg;
			push @{$meta->{$name}->{test}}, eval '(' . $value . ')';
		},
		qr/^(\:type|\:t)/ => sub {
			my $value = shift;
			$value =~ s/.*\((.*)\)/$1/sg;
			push @{$meta->{$name}->{type}}, $value;
			if ($meta->{$name}->{params_map}) {
				$meta->{$name}->{params_map}->{
					$meta->{$name}->{param}->[-1]
				}->{type} = $value;
			}
		},
		qr/^(\{)/ => sub {
			my $value = shift;
			$value =~ s/^\{|\}$//g;
			$meta->{$name}->{meta} = 'METHOD' unless $meta->{$name}->{meta} eq 'MODIFY';
			$meta->{$name}->{code} = $value;
		},
		qr/^(\%|\$|\@|\&)/ => sub {
			push @{$meta->{$name}->{param}}, $_[0];
			$meta->{$name}->{params_map}->{$_[0]} = {};
		}
	);
	return @ATTR;
}

sub build_sub_or_accessor {
	my ($self, $mg, $token, $meta) = @_;
	my $name = shift @{$token};
	if ($name =~ s/^\[(.*)\]$/$1/) {
		$self->debug_step(debug_step_20, $1);
		$self->build_sub_or_accessor($mg, [$_, @{$token}], $meta) for split / /, $1;
		return;
	}
	$self->debug_step(sprintf(debug_step_21, $name), $token);
	$meta->{$name}->{meta} = 'ACCESSOR';
	my $switch = switch(
		$self->build_sub_or_accessor_attributes($name, $token, $meta)
	);
	$switch->(shift @{$token}) while scalar @{$token};
	$self->debug_step(sprintf(debug_step_22, $name), $meta->{$name});
	$meta->{$name}->{meta} eq 'ACCESSOR'
		? $self->build_accessor($mg, $name, $meta)
		: $meta->{$name}->{meta} eq 'MODIFY'
			? $self->build_modify($mg, $name, $meta)
			: $self->build_sub($mg, $name, $meta);
	$self->build_predicate($mg, $name, $meta) if $meta->{$name}->{predicate};
	$self->build_clearer($mg, $name, $meta) if $meta->{$name}->{clearer};
	return $meta;
}

sub build_accessor {
	my ($self, $mg, $name, $meta) = @_;
	$self->debug_step(sprintf(debug_step_23, $name), $meta->{$name});
	my $private = $self->build_private($name, $meta->{$name}->{private});
	my $type = $self->build_coerce($name, '$value', $meta->{$name}->{coerce})
	. $self->build_type($name, $meta->{$name}->{type}[0]);
	my $trigger = $self->build_trigger($name, '$value', $meta->{$name}->{trigger});
	my $code = $self->build_code($mg, $name, $self->build_accessor_code($name, $private, $type, $trigger));
	$mg->accessor($name)->code($code)->clear_tests->test($self->build_tests($name, $meta->{$name}));
	$meta->{$name}->{$_} && $mg->$_($self->replace_pe_string($meta->{$name}->{$_}, $name)) for qw/pod example/;
	$self->debug_step(sprintf(debug_step_28, $name), $meta->{$name});
}

sub build_accessor_code {
	my ($self, $name, $private, $type, $trigger) = @_;
	return qq|{
		my ( \$self, \$value ) = \@_; $private
		if ( defined \$value ) { $type
			\$self->{$name} = \$value; $trigger
		}
		return \$self->{$name};
	}|;
}

sub replace_pe_string {
	my ($self, $str, $name) = @_;
	$str =~ s/\$name/$name/g;
	return $str;
}

sub build_modify {
	my ($self, $mg, $name, $meta) = @_;
	$self->debug_step(sprintf(debug_step_29, $name), $meta->{$name});
	my $before_code = $meta->{$name}->{before} || "";
	my $around_code = $meta->{$name}->{around} || qq|my \@res = \$self->\$orig(\@params);|;
	my $after_code = $meta->{$name}->{after} || "";
	my $code = $self->build_code($mg, $name, $self->build_modify_code($name, $before_code, $around_code, $after_code));
	$mg->sub($name)->code($code)->pod(qq|call $name method.|)->test($self->build_tests($name, $meta->{$name}));
	$meta->{$name}->{$_} && $mg->$_($self->replace_pe_string($meta->{$name}->{$_}, $name)) for qw/pod example/;
	$self->debug_step(sprintf(debug_step_30, $name), $meta->{$name});
}

sub build_modify_code {
	my ($self, $name, $before_code, $around_code, $after_code) =@_;
	return qq|{
		my (\$orig, \$self, \@params) = ('SUPER::$name', \@_);
		$before_code$around_code$after_code
		return wantarray ? \@res : \$res[0];
	}|;
}

sub build_sub {
	my ($self, $mg, $name, $meta) = @_;
	my $code = $meta->{$name}->{code};
	$self->debug_step(sprintf(debug_step_31, $name), $meta->{$name});
	my ($params, $subtype, $params_explanation) = ( '', '', '' );
	$subtype .= $self->build_private($name)
		if $meta->{$name}->{private};
	if ($meta->{$name}->{param}) {
		for my $param (@{ $meta->{$name}->{param} }) {
			$params_explanation .= ', ' if $params_explanation;
			$params .= ', ' .  $param;
			my $pm = $meta->{$name}->{params_map}->{$param};
			$subtype .= qq|$param = defined $param ? $param : $pm->{default};|
				if ($pm->{default});
			$subtype .= $self->build_coerce($name, $param, $pm->{coerce});
			if ($pm->{type}) {
				my $error_message = ($pm->{type} !~ m/^(Optional|Any|Item)/
					? qq|$param = defined $param ? $param : 'undef';| : q||)
					. qq|die qq{$pm->{type}: invalid value $param for variable \\$param in method $name};|;
				$subtype .= $self->build_type(
					$name,
					$pm->{type},
					$param,
					$error_message,
					($pm->{type} !~ m/^(Optional|Any|Item)/
						? qq|! defined($param) \|\|| : q||)
				);
				$params_explanation .= qq|param $param to be a $pm->{type}|;
			} else {
				$params_explanation .= qq|param $param to be any value including undef|;
			}
		}
	}
	$meta->{$name}->{params_explanation} = $params_explanation;
	$code = $self->build_code($mg, $name, $self->build_sub_code($name, $params, $subtype, $code));
	$params =~ s/^,\s*//;
	my $example = qq|\$obj->$name($params)|;
	$mg->sub($name)->code($code)
		->pod(qq|call $name method. Expects $params_explanation.|)
		->example($example)
		->test($self->build_tests($name, $meta->{$name}));
	$meta->{$name}->{$_} && $mg->$_($self->replace_pe_string($meta->{$name}->{$_}, $name)) for qw/pod example/;
	$self->debug_step(sprintf(debug_step_32, $name), $meta->{$name});
}

sub build_code {
	my ($self, $mg, $name, $code) = @_;
	$self->debug_step(sprintf(debug_step_38, $name), $code);
	return unless defined $code;
	1 while $code =~ s/€(\w+(|$PARENTHESES));/$self->build_macro_code($mg, $1)/ge;
	$code =~ s/£(\w*(\s|\$|\-|\;|\,|\{|\}|\[|\]|\)|\(|\:))/$self->build_self($1)/eg;	
	$self->debug_step(sprintf(debug_step_44, $name), $code);
	return $code;
}

sub build_self {
	my ($self, $name) = @_;
	return qq|\$self->$name|;
}

sub parse_params {
	my ($self, $param_string) = @_;
	my @params;
	while ($param_string =~ s/$PARSE_PARAM_STRING//g) {
		push @params, $self->minimise_param_string($1);
	}
	push @params, $self->minimise_param_string($param_string);
	return @params;
}

sub minimise_param_string {
	my ($self, $string) = @_;
	return $string unless length $string;
	$string =~ s/^\s*\(\s*(.*)\s*\)\s*$/$1/sg;
	$string =~ s/\s+/ /g;
	$string =~ s/^\s*|\s*$//g;
	$string =~ s/^q*(("|'|\||\/))((\\{2})*|(.*?[^\\](\\{2})*))\1$/$3/sg; # back compat
	$string =~ s/q+(\{|\})((\\[\{\}])*|(.*?[^\\]([\{\}])*))\}/$2/sg; # back compat
	return undef if $string =~ m/^undef$/;
	return $string;
}

sub build_macro_code {
	my ($self, $mg, $match) = @_;
	$self->debug_step(sprintf(debug_step_39, $match));
	if ($match =~ m/^(.*)$PARENTHESES$/m) {
		$self->debug_step(sprintf(debug_step_40, $1), $2);
		return '' unless $self->{macros}->{$1}->{code};
		$self->debug_step(sprintf(debug_step_41, $1), $self->{macros}->{$1}->{code});
		my $v =  $self->{macros}->{$1}->{code}->($self, $mg, $self->parse_params($2));
		$self->debug_step(sprintf(debug_step_42, $1), $v); 
		return $v;
	}
	return '' unless $self->{macros}->{$match}->{code};
	$self->debug_step(sprintf(debug_step_43, $match), $self->{macros}->{$match}->{code}); 
	my $v = $self->{macros}->{$match}->{code}->($self, $mg);
	$self->debug_step(sprintf(debug_step_42, $match), $v); 
	return $v;
}

sub build_sub_code {
	my ($self, $name, $params, $subtype, $code) = @_;
	return qq|{
		my (\$self $params) = \@_; $subtype
		$code;
	}|;
}

sub build_clearer {
	my ($self, $mg, $name, $meta) = @_;
	$self->debug_step(sprintf(debug_step_47, $name));
	$mg->sub(qq|clear_$name|)
		->code($self->build_code($mg, $name, $self->build_clearer_code($name)))
		->pod(qq|clear $name accessor|)
		->example(qq|\$obj->clear_$name|)
		->test(
			$self->build_tests($name, $meta->{$name}, "success"),
			['ok', qq|\$obj->clear_$name|],
			['is', qq|\$obj->$name|, 'undef']
		);
	$self->debug_step(sprintf(debug_step_48, $name));
	return ($mg, $name, $meta);
}

sub build_clearer_code {
	my ($self, $name) = @_;
	return qq|{
		my (\$self) = \@_;
		delete \$self->{$name};
		return \$self;
	}|;
}

sub build_predicate {
	my ($self, $mg, $name, $meta) = @_;
	$self->debug_step(sprintf(debug_step_45, $name));
	$mg->sub(qq|has_$name|)
		->code($self->build_code($mg, $name, $self->build_predicate_code($name)))
		->pod(qq|has_$name will return true if $name accessor has a value.|)
		->example(qq|\$obj->has_$name|)
		->test(
			['ok', qq|do{ delete \$obj->{$name}; 1;}|],
			['is', qq|\$obj->has_$name|, q|''|],
			$self->build_tests($name, $meta->{$name}, 'success'),
			['is', qq|\$obj->has_$name|, 1],
		);
	$self->debug_step(sprintf(debug_step_46, $name));
	return ($mg, $name, $meta);
}

sub build_predicate_code {
	my ($self, $name) = @_;
	return qq|{
		my (\$self) = \@_;
		return exists \$self->{$name};
	}|;
}

sub build_builder {
	my ($self, $name, $param, $code) = @_;
	if (defined $code) {
		$code = "_build_$name" if $code =~ m/^1$/;
		return $code =~ m/^\w+$/
			? qq|$param = \$self->$code($param);|
			: $code
	}
	return q||;
}

sub build_coerce {
	my ($self, $name, $param, $code) = @_;
	if (defined $code) {
		$code = $code =~ m/^\w+$/
			? qq|$param = \$self->$code($param);|
			: $code;
		$self->debug_step(sprintf(debug_step_25, $name), $code);
		return $code;
	}
	return q||;
}

sub build_trigger {
	my ($self, $name, $param, $code) = @_;

	if (defined $code) {
		$code = $code =~ m/^1$/
			? qq|\$self->_trigger_$name|
			: $code =~ m/^\w+$/
				? qq|\$self->$code($param);|
				: $code;
		$self->debug_step(sprintf(debug_step_27, $name), $code);
		return $code;
	}
	return q||;
}

sub build_private {
	my ($self, $name, $private) = @_;
	if ($private) {
        	$private = qq|
		my \$private_caller = caller();
		if (\$private_caller ne __PACKAGE__) {
			die \"cannot call private method $name from \$private_caller\";
		}|;
		$self->debug_step(sprintf(debug_step_24, $name), $private);
		return $private;
	} 
	return q||;
}

sub build_type {
	my ($self, $name, $type, $value, $error_string, $subcode, $code) = @_;
	$value ||= '$value';
	$code ||= '';
	$subcode ||= '';
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
					if ($subcode (\$ref \|\| 'SCALAR') ne 'SCALAR' \|\| (\$ref ? \$$value : $value) !~ m/^(1\|0)\$/) {
						$error_string
					}
					$value = !!(\$ref ? \$$value : $value) ? 1 : 0;|;
			},
			qr/^(Str)$/ => sub {
				return qq|
					if ($subcode ref $value) {
						$error_string
					}|;
			},
			qr/^(Num)$/ => sub {
				return qq|
					if ($subcode ref $value \|\| $value !~ m/^[-+\\d]\\d*\\.?\\d\*\$/) {
						$error_string
					}|;
			},
			qr/^(Int)$/ => sub {
				return qq|
					if ($subcode ref $value \|\| $value !~ m/^[-+\\d]\\d\*\$/) {
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
					if ($subcode (ref($value) \|\| "") ne "ARRAY") {
						$error_string
					}|;
			},
			qr/^(ArrayRef\[(.*)\])$/ => sub {
				my ($val, @matches) = @_;
				my $max = $matches[1] =~ s/\,\s*(\d+)\s*$// && $1;
				my $min = $matches[1] =~ s/\,\s*(\d+)\s*$// && $1;
				my $type = $matches[1];
				@matches = ($type, $min, $max);
				my $code = qq|
					if ((ref($value) \|\| "") ne "ARRAY") {
						$error_string
					}|;
				my $new_error_string = $self->extend_error_string($error_string, $value, '$item', qq| expected $matches[0]|, $matches[0]);
				my $sub_code = $self->build_type($name, $matches[0], '$item', $new_error_string, ($matches[0] !~ m/^(Optional|Any|Item)/ ? qq|! defined(\$item) \|\|| : q||));
				$code .= qq|
					for my \$item (\@{ $value }) {$sub_code
					}| if $sub_code;
				$code .= qq|
					my \$length = scalar \@{$value};|
				if $matches[1] || $matches[2];
				$code .= qq|
					if (\$length < $matches[1]) {
						die qq{$val for $name must contain atleast $matches[1] items}
					}|
				if $matches[1] !~ m/^$/;
				$code .= qq|
					if (\$length > $matches[2]) {
						die qq{$val for $name must not be greater than $matches[2] items}
					}|
				if $matches[2] !~ m/^$/;
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

				my $new_error_string = $self->extend_error_string($error_string, $value, '$item', qq| expected $matches[1]|, $matches[1]);
				my $sub_code = $self->build_type($name, $matches[1], '$item', $new_error_string, ($matches[1] !~ m/^(Optional|Any|Item)/ ? qq|! defined(\$item) \|\|| : q||));
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
				@matches = map { my $h = $_; $h =~ s/^\s*|\s*//g; $h; } split ',', $matches[1], 2;
				my $code = qq|
					if ((ref($value) \|\| "") ne "HASH") {
						$error_string
					}|;
				my $key_error_string = $self->extend_error_string($error_string, $value, '$key', qq| expected $matches[0]|);
				my $key_sub_code = $self->build_type($name, $matches[0], '$key', $key_error_string);
				$key_sub_code =~ s/ref \$key \|\| //;;
				my $value_error_string = $self->extend_error_string($error_string, $value, '$val', qq| expected $matches[1]|, $matches[0]);
				my $value_sub_code = $self->build_type($name, $matches[1], '$val', $value_error_string, ($matches[1] !~ m/^(Optional|Any|Item)/ ? qq|! defined(\$val) \|\|| : q||));
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
				while (@matches) {
					my ($match) = (shift @matches);
					if ($match =~ m/(Map|Tuple|HashRef|ArrayRef|Dict)\[/) {
						my $lame = sub {
							my $copy = shift;
							while ($copy =~ s/\[[^\[\]]+\]//g) {}
							return ($copy =~ m/\[|\[/) ? 1 : 0;
						};
						while ($lame->($match .=  ', ' . shift @matches)) {}
					}
					(my $new_value = $value) .= qq|->[$i]|;
					my $item_error_string = $self->extend_error_string($error_string, $value, $new_value, qq| expected $match for index $i|, $match);
					my $key_sub_code = $self->build_type($name, $match, $new_value, $item_error_string, ($match !~ m/^(Optional|Any|Item)/ ? qq|! defined($new_value) \|\|| : q||));
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
					if (@matches && $match =~ m/(Map|Tuple|HashRef|ArrayRef|Dict)\[/) {
						my $lame = sub {
							my $copy = shift;
							while ($copy =~ s/\[[^\[\]]+\]//g) {}
							return ($copy =~ m/\[|\[/) ? 1 : 0;
						};
						while ($lame->($match .=  ', ' . shift @matches)) {}
					}
					my ($k, $v) = map { my $h = $_; $h =~ s/^\s*|\s*$//g; $h; } split('=>', $match, 2);
					(my $new_value = $value) .= qq|->{$k}|;
					my $new_error_string = $self->extend_error_string($error_string, $value, $new_value, qq| expected $v for $k|, $v);
					$sub_code .= $self->build_type($k, $v, $new_value, $new_error_string, ($v !~ m/^(Optional|Any|Item)/ ? qq|! defined($new_value) \|\|| : q||));
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
		$self->debug_step(sprintf(debug_step_26, $name), $code);
	}
	return $code;
}

sub extend_error_string {
	my ($self, $new_error_string, $value, $new_value, $message, $type) = @_;
	my $old_type = quotemeta(qq|$value = defined $value ? $value : 'undef';|);
	$new_error_string =~ s/^$old_type//;
 	$new_error_string =~ s/\Q$value\E/$new_value/;
	$new_error_string =~ s/};$/$message};/;
	if ($type && $type !~ m/^(Optional|Any|Item)/) {
		$new_error_string = qq|$new_value = defined $new_value ? $new_value : 'undef';| . $new_error_string;
	}
	return $new_error_string;
}

sub build_macro_attributes {
	my ($self, $name, $token, $meta) = @_;
	return (
		'default' => sub {
			my $value = shift;
			push @{$meta->{$name}->{caught}}, $value;
		},
		qr/^(\:a|\:alias)/ => sub {
			my $value = shift;
			$value =~ s/^\:(a|alias)\(\s*(.*)\s*\)$/$2/sg;
			push @{$meta->{$name}->{alias}}, split(' ', $value);
		},
		qr/^(\{)/ => sub {
			my $value = shift;
			$value =~ s/^\{|\}$//g;
			$meta->{$name}->{code} = eval qq|sub { my (\$self, \$mg, \@params) = \@_; $value }|;
		},
	);
}

sub build_macro {
	my ($self, $mg, $class) = @_;
	my $meta = $self->{macros};
	for my $macro (@{$class}) {
		$self->debug_step(debug_step_6, $macro);
		if ($macro->[-1] !~  m/^{/) {
			my $include = sprintf "Hades::Macro::%s", shift @{$macro};
			$self->debug_step(sprintf(debug_step_7, $include), $macro);
			eval qq|require $include|;
			die $@ if $@;
			my $include_meta = $include->new($macro->[0] ? do {
				$macro->[0] =~ s/^\[|\]$//g;
				( eval qq|$macro->[0]| );
			} : ())->meta;
			$self->debug_step(sprintf(debug_step_8, $include), $include_meta);
			$meta = {%{$meta}, %{$include_meta}};
		} else {
			my $name = shift @{$macro};
			$self->debug_step(sprintf(debug_step_9, $name), $macro);
			$meta->{$name}->{meta} = 'MACRO';
			my $switch = switch(
				$self->build_macro_attributes($name, $macro, $meta)
			);
			$switch->(shift @{$macro}) while scalar @{$macro};
			$self->debug_step(sprintf(debug_step_10, $name), $meta->{$name});
			if ($meta->{$name}->{alias}) {
				for (@{$meta->{$name}->{alias}}) {
					$meta->{$_} = $meta->{$name};
				}
			}
		}
	}
	$self->debug_step(debug_step_11, $meta);
	$self->{macros} = $meta;
}

sub index {
	my ($self, $index) = @_;
	return substr $self->{eval}, $index, 1;
}

sub build_test_data {
	my ($self, $type, $name, $required) = @_;
	my $switch = switch
		qr/^(Any)$/ => sub {
			return $self->_generate_test_string;
		},
		qr/^(Item)$/ => sub {
			return $self->_generate_test_string;
		},
		qr/^(Bool)$/ => sub {
			return (q|1|, q|[]|, q|{}|);
		},
		qr/^(Str)$/ => sub {
			return ($self->_generate_test_string, q|[]|, q|\1|);
		},
		qr/^(Num)$/ => sub {
			return (q|100.555|, q|[]|, $self->_generate_test_string);
		},
		qr/^(Int)$/ => sub {
			return (q|10|, q|[]|, $self->_generate_test_string);
		},
		qr/^(Ref)$/ => sub {
			return (q|{ test => 'test' }|, $self->_generate_test_string, q|1|);
		},
		qr/^(Ref\[(.*)\])$/ => sub {
			my ($val, @matches) = @_;
			$matches[1] = '"' . $matches[1] . '"' if $matches[1] =~ m/^[a-zA-Z]/;
			return (
				qq|bless({ test => 'test' }, $matches[1])|,
				qq|bless({ test => 'test' }, $matches[1] . 'Error')|,
				$self->_generate_test_string
			);
		},
		qr/^(ScalarRef)$/ => sub {
			return ( q|\1|, 1, q|[]|);
		},
		qr/^(ScalarRef\[(.*)\])$/ => sub {
			my ($val, @matches) = @_;
			$matches[1] = '"' . $matches[1] . '"' if $matches[1] =~ m/^[a-zA-Z]/;
			return (
				qq|do { my \$okay = ''; bless( \\\$okay, $matches[1]) }|,
				qq|do { my \$okay = ''; bless( \\\$okay, $matches[1] . 'Error') }|,
				$self->_generate_test_string,
				q|{}|
			);
		},
		qr/^(ArrayRef)$/ => sub {
			return (
				qq|['test']|,
				qq|{}|,
				$self->_generate_test_string
			);
		},
		qr/^(ArrayRef\[(.*)\])$/ => sub {
			my ($val, @matches) = @_;
			my $max = $matches[1] =~ s/\,\s*(\d+)\s*$// && $1;
			my $min = $matches[1] =~ s/\,\s*(\d+)\s*$// && $1;
			my $type = $matches[1];
			@matches = ($type, $min, $max);
			my @values = $self->build_test_data($matches[0], $name, $required);
			push @values, 'undef' unless $matches[0] =~ m/^Optional/;
			return (
				(map {
					my $v = $_;
					sprintf q|[ %s ]|, join ", ", map { $v } 0 .. ($matches[1] || 1) - 1;
				} @values),
				(($matches[1] || 0) > 0 ? (
					qq|[]|
				) : ( )),
				($matches[2] ? (
					sprintf q|[ %s ]|, join ", ", map { $values[0] } 0 .. $matches[2] + 1
				) : ( )),
				q|{}|,
				$self->_generate_test_string
			);
		},
		qr/^(HashRef)$/ => sub {
			return (
				q|{ 'test' => 'test' }|,
				q|[]|,
				$self->_generate_test_string
			);
		},
		qr/^(HashRef\[(.*)\])$/ => sub {
			my ($val, @matches) = @_;
			my @values = $self->build_test_data($matches[1], $name, $required);
			push @values, 'undef' unless $matches[1] =~ qr/^Optional/;
			return (
				(map {
					sprintf q|{ test => %s }|, $_;
				} @values),
				q|[]|,
				$self->_generate_test_string
			);
		},
		qr/^(CodeRef)$/ => sub {
			return (
				q|$sub|,
				q|[]|,
				$self->_generate_test_string
			);
		},
		qr/^(RegexpRef)$/ => sub {
			return (
				q|qr/abc/|,
				q|[]|,
				$self->_generate_test_string
			);
		},
		qr/^(GlobRef)$/ => sub {
			return (
				q|$globref|,
				q|[]|,
				$self->_generate_test_string
			);
		},
		qr/^(Object)$/ => sub {
			return (
				q|bless({}, 'Test')|,
				q|[]|,
				$self->_generate_test_string
			);
		},
		qr/^(Map\[(.*)\])$/ => sub {
			my ($val, @matches) = @_;
			@matches = map { my $h = $_; $h =~ s/^\s*|\s*//g; $h; } split ',', $matches[1], 2;
			my @keys = $self->build_test_data($matches[0], $name, $required);
			my @values = $self->build_test_data($matches[1], $name, $required);
			push @values, 'undef' unless $matches[1] =~ m/^Optional/;
			return (
				(map {
					sprintf q|{ %s => %s }|, $keys[0], $_;
				} @values),
				q|[]|,
				$self->_generate_test_string
			);
		},
		qr/^(Tuple\[(.*)\])$/ => sub {
			my ($val, @matches) = @_;
			@matches = map { my $h = $_; $h =~ s/^\s*|\s*//g; $h; } split ',', $matches[1];
			my @tuple;
			while (@matches) {
				my ($match) = (shift @matches);
				if ($match =~ m/(Map|Tuple|HashRef|ArrayRef|Dict)\[/) {
					my $lame = sub {
						my $copy = shift;
						while ($copy =~ s/\[[^\[\]]+\]//g) {}
						return ($copy =~ m/\[|\[/) ? 1 : 0;
					};
					while ($lame->($match .=  ', ' . shift @matches)) {}
				}
				push @tuple, [
					$self->build_test_data($match, $name, $required), ($_ =~ m/^Optional/ ? () : 'undef')
				];
			}
			my $d = 0;
			return (
				 (map {
					my ($tup, $m) = ($_, 0, $d++);
					map {
						my $ah = $_;
						$m++ == 0 && $d > 1 ? () :
						sprintf q|[ %s ]|, join ', ', map {$d - 1 == $_ ? $ah : $tuple[$_]->[0] } 0 .. $#tuple;
					} @{$tup};
				} @tuple),
				q|[]|,
				q|{}|,
				$self->_generate_test_string
			);
		},
		qr/^(Dict\[(.*)\])$/ => sub {
			my ($val, @matches) = @_;
			@matches = split ',', $matches[1];
			my %map;
			while (@matches) {
				my ($match) = (shift @matches);
				if (@matches && $match =~ m/(Map|Tuple|ArrayRef|Dict)\[/) {
					my $lame = sub {
						my $copy = shift;
						while ($copy =~ s/\[[^\[\]]+\]//g) {}
						return ($copy =~ m/\[|\[/) ? 1 : 0;
					};
					while ($lame->($match .=  ', ' . shift @matches)) {}
				}
				my ($k, $v) = map { my $h = $_; $h =~ s/^\s*|\s*$//g; $h; } split('=>', $match, 2);
				$v =~ s/,\s*$//;
				my @values = $self->build_test_data($v, $name, $required);
				push @values, 'undef' unless $v =~ m/^Optional/;
				$map{$k} = \@values;
				push @{ $map{_dict_columns} }, $k;
			}
			my $d = 0;
			return (
				 (map {
					my ($dict, $m) = ($_, 0, $d++);
					map {
						my $ah = $_;
						$m++ == 0 && $d > 1 ? () :
						sprintf q|{ %s }|, join ', ', map {$dict eq $_ ? qq|$_ => $ah| : sprintf( q|%s => %s|, $_, $map{$_}->[0]) } @{$map{_dict_columns}};
					} @{$map{$dict}};
				} @{$map{_dict_columns}}), q|{}|, q|[]|, $self->_generate_test_string
			);
		},
		qr/^(Optional\[(.*)\])$/ => sub {
			my ($val, @matches) = @_;
			my @values = $self->build_test_data($matches[1], $name, $required);
			$values[0] = 'undef' unless $required;
			return @values;
		};
	return $switch->($type);
}

sub build_tests {
	my ($self, $name, $meta, $mod, $class) = @_;
	my @tests = ();
	$mod ? $mod ne 'new' ? do {
		my ($valid) = $self->build_test_data($meta->{type}->[0] || 'Any', $name);
		push @tests, ['deep', qq|\$obj->$name($valid)|, $valid];
	} : do {
		my %test_data;
		map {
			unless ($meta->{$_}->{no_success_test}) {
				push @{$test_data{test_data_columns}}, $_;
				$test_data{$_} = [ $self->build_test_data($meta->{$_}->{type}->[0] ? $meta->{$_}->{type}->[0] : 'Any', '', 1) ]
			}
		} grep { $meta->{$_}->{meta} eq 'ACCESSOR' } keys %{$meta};
		my $valid =  join(', ', map { sprintf '%s => %s', $_, $test_data{$_}->[0] } grep { $meta->{$_}->{required} } @{$test_data{test_data_columns}});
		push @tests, [
			'ok',
			sprintf(
				'my $obj = %s->new({%s})',
				$class->{CURRENT}->{NAME},
				$valid
			)
		], [
			'ok',
			sprintf(
				'$obj = %s->new(%s)',
				$class->{CURRENT}->{NAME},
				$valid
			)
		], ['isa_ok', '$obj', qq|'$class->{CURRENT}->{NAME}'|];
		my $d = 0;
		for my $key (@{$test_data{test_data_columns}}) {
			if ($meta->{$key}->{default}) {
				$valid = join(', ', map { $key ne $_ ? ( sprintf '%s => %s', $_, $test_data{$_}->[0] ) : () } @{$test_data{test_data_columns}});
				push @tests, [
					'ok',
					sprintf(
						'$obj = %s->new({%s})',
						$class->{CURRENT}->{NAME},
						$valid
					),
				], [
					'ok',
					sprintf(
						'$obj = %s->new(%s)',
						$class->{CURRENT}->{NAME},
						$valid
					),
				], [ 'deep', qq|\$obj->$key|, $meta->{$key}->{default} ];
			} elsif ($meta->{$key}->{required}) {
				push @tests, [
					'eval',
					sprintf(
						'$obj = %s->new({%s})',
						$class->{CURRENT}->{NAME},
						join(', ', map { $key ne $_ ? ( sprintf '%s => %s', $_, $test_data{$_}->[0] ) : () } @{$test_data{test_data_columns}})
					),
					'required'
				];
			}
			my $m = 0;
			for my $ah (@{$test_data{$key}}) {
				if ($m++ == 0) {
					next if $d > 0;
					push @tests, [
						'ok',
						sprintf q|$obj = %s->new({ %s })|,
						$class->{CURRENT}->{NAME},
						join ', ', map {$key eq $_ ? qq|$_ => $ah| : sprintf( q|%s => %s|, $_, $test_data{$_}->[0]) } @{$test_data{test_data_columns}}
					];
				} else {
					push @tests, [
						'eval',
						sprintf(
							q|$obj = %s->new({ %s })|,
							$class->{CURRENT}->{NAME},
							join ', ', map {$key eq $_ ? qq|$_ => $ah| : sprintf( q|%s => %s|, $_, $test_data{$_}->[0]) } @{$test_data{test_data_columns}}
						),
						'invalid|type|constraint|greater|atleast'
					];
				}
			}
			$d++;
		}
	} : $meta->{meta} eq 'ACCESSOR' ? do {
		push @tests, ['can_ok', qq|\$obj|, qq|'$name'|];
		$meta->{private} ? do {
			push @tests, ['eval', qq|\$obj->$name|, 'private method|private attribute'];
		} : do {
			push @tests, ['is', qq|\$obj->$name|, 'undef'] if !$meta->{no_success_test} && !$meta->{builder} && !$meta->{required} && !$meta->{default};
			my (@test_cases) = $self->build_test_data($meta->{type}->[0] || 'Any', $name, $meta->{required} || $meta->{builder});
			if (scalar @test_cases > 1) {
				my $valid = shift @test_cases;
				push @tests, ['deep', qq|\$obj->$name($valid)|, $valid] unless $meta->{no_success_test};
				unless ($meta->{coerce}) {
					for (@test_cases) {
						push @tests, ['eval', qq|\$obj->$name($_)|, 'invalid|value|type|constraint|greater|atleast' ];
					}
				}
				push @tests, ['deep', qq|\$obj->$name|, $valid] unless $meta->{no_success_test};
			}
		};
	} : do {
		$meta->{private} ? do {
			push @tests, ['eval', qq|\$obj->$name|, 'private method'];
		} : $meta->{param} && do {
			my %test_data = map {
				$_ => [
					$self->build_test_data($meta->{params_map}->{$_}->{type} || 'Any', $name), ($meta->{params_map}->{$_}->{type} || 'Any') !~ m/^(|Optional|Any|Item)/ ? q|undef| : ()
				]
			} @{ $meta->{param} };
			for my $key (@{$meta->{param}}) {
				for my $ah (splice @{$test_data{$key}}, 1) {
					push @tests, [
						'eval',
						sprintf(
							q|$obj->%s(%s)|,
							$name,
							join ', ', map {$key eq $_ ? $ah : $test_data{$_}->[0]} @{$meta->{param}}
						),
						'invalid|value|type|constraint|greater|atleast'
					];
				}
			}
		}
	};
	push @tests, @{$meta->{test}} if $meta->{test};
	return @tests;
}

sub _read_file {
	my ($file) = @_;
	open my $fh, '<', $file;
	my $content = do { local $/; <$fh>; };
	close $fh;
	return $content;
}

sub _generate_test_string {
	my @data = qw/penthos curae nosoi geras phobos limos aporia thanatos algea hypnos gaudia/;
	return sprintf q|'%s'|, $data[int(rand(scalar @data))];
}

1;

__END__

=head1 NAME

Hades - Less is more, more is less!

=head1 VERSION

Version 0.18

=cut

=head1 SYNOPSIS

	use Hades;

	Hades->run({
		eval => 'Kosmos { [penthos curae] :t(Int) :d(2) :p :pr :c :r geras $nosoi :t(Int) :d(2) { if (£penthos == $nosoi) { return £curae; } } }'
	});

	... generates ...

	package Kosmos;
	use strict;
	use warnings;
	our $VERSION = 0.01;

	sub new {
		my ( $cls, %args ) = ( shift(), scalar @_ == 1 ? %{ $_[0] } : @_ );
		my $self = bless {}, $cls;
		my %accessors = (
			penthos => { required => 1, default => 2, },
			curae   => { required => 1, default => 2, },
		);
		for my $accessor ( keys %accessors ) {
			my $value
			    = $self->$accessor(
				defined $args{$accessor}
				? $args{$accessor}
				: $accessors{$accessor}->{default} );
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
		return exists $self->{penthos};
	}

	sub curae {
		my ( $self, $value ) = @_;
		my $private_caller = caller();
		if ( $private_caller ne __PACKAGE__ ) {
			die "cannot call private method curae from $private_caller";
		}
		if ( defined $value ) {
			if ( ref $value || $value !~ m/^[-+\d]\d*$/ ) {
				die qq{Int: invalid value $value for accessor curae};
			}
			$self->{curae} = $value;
		}
		return $self->{curae};
	}

	sub clear_curae {
		my ($self) = @_;
		delete $self->{curae};
		return $self;
	}

	sub has_curae {
		my ($self) = @_;
		return exists $self->{curae};
	}

	sub geras {
		my ( $self, $nosoi ) = @_;
		$nosoi = defined $nosoi ? $nosoi : 5;
		if ( !defined($nosoi) || ref $nosoi || $nosoi !~ m/^[-+\d]\d*$/ ) {
			$nosoi = defined $nosoi ? $nosoi : 'undef';
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

=item verbose

Set verbose to true, to print build steps to STDOUT.

=item debug

Set debug to true, to step through the build.

=item dist

Provide a name for the distribution.

=item lib

Provide a path where the generated files will be compiled.

=item tlib

Provide a path where the generates test files will be compiled.

=item author

The author of the distribution/module.

=item email

The authors email of the distribution/module.

=item version

The version number of the distribution/module.

=item realm

The Hades realm that is used to generate the code.

=cut

=back

=head1 Hades

=cut

=head2 Class

Declare a new class.

	Kosmos {

	}

=cut

=head3 Abstract

Declare the classes Abstract.

	Kosmos {
		abstract { Afti einai i perilipsi }
	}

=cut

=head3 Synopsis

Declare the classes Synopsis.

	Kosmos {
		synopsis {
			Schetika me ton Kosmos

				Kosmos->new;
		}
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

=head3 Test

Declare the classes additional tests.

	Kosmos {
		test {
			[
				['ok', 'my $obj = Kosmos->new'],
				['is', '$obj->dokimi', undef]
			]
		}
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
		dokimes
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

=head3 :builder | :bdr

Takes a coderef which is meant to build the attributes value.

	dokimi :bdr
	dokimes :builder($value = $value->[0] if ref($value) || "" eq "ARRAY";)

=cut

=head3 :test | :z

Add tests associated to the accessor.

	dokimi :z(['ok', '$obj->dokimi'])
	dokimes :z(['deep', '$obj->dokimes({})', q|{}|)

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

=head3 :default | :d

The default is used when no value for the sub was passed as a param.

	dokimi $str :d(Eimai o monos) { }
	dokimes $arrayRef :default([{ ola => "peripou", o => [qw/kosmos/] }]) { }

=cut

=head3 :test | :z

Add tests associated to the sub.

	dokimi :z(['ok', '$obj->dokimi']) { }
	dokimes :test(['deep', '$obj->dokimes({})', q|{}|) { }

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

=head2 Macros

Hades has a concept of macros that allow you to write re-usable code. see L<https://metacpan.org/source/LNATION/Hades-0.18/macro-fh.hades> for an example of how to extend via macros.

	macro {
		FH [ macro => [qw/read_file write_file/], alias => { read_file => [qw/rf/], write_file => [qw/wf/] } ]
		str2ArrayRef :a(s2ar) {
			return qq|$params[0] = [ $params[0] ];|;
		}
		ArrayRef2Str :a(ar2s) {
			return qq|$params[0] = $params[0]\->[0];|;
		}
	}
	MacroKosmos {
		eros $eros :t(Str) :d(t/test.txt) {
			€s2ar('$eros');
			€ar2s('$eros');
			€wf('$eros', q|'this is a test'|);
			return $eros;
		}
		psyche $psyche :t(Str) :d(t/test.txt) {
			€rf('$psyche');
			return $content;
		}
	}

	... generates ...

	package MacroKosmos;
	use strict;
	use warnings;
	our $VERSION = 0.01;

	sub new {
		my ( $cls, %args ) = ( shift(), scalar @_ == 1 ? %{ $_[0] } : @_ );
		my $self = bless {}, $cls;
		my %accessors = ();
		for my $accessor ( keys %accessors ) {
			my $value
			    = $self->$accessor(
				defined $args{$accessor}
				? $args{$accessor}
				: $accessors{$accessor}->{default} );
			unless ( !$accessors{$accessor}->{required} || defined $value ) {
				die "$accessor accessor is required";
			}
		}
		return $self;
	}

	sub eros {
		my ( $self, $eros ) = @_;
		$eros = defined $eros ? $eros : "t/test.txt";
		if ( !defined($eros) || ref $eros ) {
			$eros = defined $eros ? $eros : 'undef';
			die qq{Str: invalid value $eros for variable \$eros in method eros};
		}

		$eros = [$eros];
		$eros = $eros->[0];
		open my $wh, ">", $eros or die "cannot open file for writing: $!";
		print $wh 'this is a test';
		close $wh;
		return $eros;

	}

	sub psyche {
		my ( $self, $psyche ) = @_;
		$psyche = defined $psyche ? $psyche : "t/test.txt";
		if ( !defined($psyche) || ref $psyche ) {
			$psyche = defined $psyche ? $psyche : 'undef';
			die
			    qq{Str: invalid value $psyche for variable \$psyche in method psyche};
		}

		open my $fh, "<", $psyche or die "cannot open file for reading: $!";
		my $content = do { local $/; <$fh> };
		close $fh;
		return $content;
	}

	1;

	__END__

=head2 Testing

Hades can auto-generate test files. If you take the following example:

	use Hades;
	Hades->run({
		eval => q|Dokimes {
			curae :r :default(5)
			penthos :t(Str) :r
			nosoi :default(3) :t(Int) :clearer
			limos
				$test :t(Str)
				:test(
					['ok', '$obj->penthos(2) && $obj->nosoi(2) && $obj->curae(5)'],
					['is', '$obj->limos("yay")', 5 ],
					['ok', '$obj->penthos(5)' ],
					['is', '$obj->limos("yay")', q{''}]
				)
				{ if ($_[0]->penthos == $_[0]->nosoi) { return $_[0]->curae; } }
		}|,
		lib => 'lib',
		tlib => 't/lib',
	});


It will generate a test file located at t/lib/Dokimes.t which looks like:

	use Test::More;
	use strict;
	use warnings;
	BEGIN { use_ok('Dokimes'); }
	subtest 'new' => sub {
		plan tests => 16;
		ok( my $obj = Dokimes->new( { curae => 'hypnos', penthos => 'aporia' } ),
			q{my $obj = Dokimes->new({curae => 'hypnos', penthos => 'aporia'})}
		);
		ok( $obj = Dokimes->new( curae => 'hypnos', penthos => 'aporia' ),
			q{$obj = Dokimes->new(curae => 'hypnos', penthos => 'aporia')}
		);
		isa_ok( $obj, 'Dokimes' );
		ok( $obj = Dokimes->new( { penthos => 'aporia', nosoi => 10 } ),
			q{$obj = Dokimes->new({penthos => 'aporia', nosoi => 10})}
		);
		ok( $obj = Dokimes->new( penthos => 'aporia', nosoi => 10 ),
			q{$obj = Dokimes->new(penthos => 'aporia', nosoi => 10)}
		);
		is( $obj->curae, 5, q{$obj->curae} );
		ok( $obj = Dokimes->new(
				{ curae => 'hypnos', penthos => 'aporia', nosoi => 10 }
			),
			q{$obj = Dokimes->new({ curae => 'hypnos', penthos => 'aporia', nosoi => 10 })}
		);
		eval { $obj = Dokimes->new( { curae => 'hypnos', nosoi => 10 } ) };
		like( $@, qr/required/,
			q{$obj = Dokimes->new({curae => 'hypnos', nosoi => 10})} );
		eval {
			$obj = Dokimes->new(
				{ curae => 'hypnos', penthos => [], nosoi => 10 } );
		};
		like(
			$@,
			qr/invalid value|greater|atleast/,
			q{$obj = Dokimes->new({ curae => 'hypnos', penthos => [], nosoi => 10 })}
		);
		eval {
			$obj = Dokimes->new(
				{ curae => 'hypnos', penthos => \1, nosoi => 10 } );
		};
		like(
			$@,
			qr/invalid value|greater|atleast/,
			q{$obj = Dokimes->new({ curae => 'hypnos', penthos => \1, nosoi => 10 })}
		);
		eval {
			$obj = Dokimes->new(
				{ curae => 'hypnos', penthos => '', nosoi => 10 } );
		};
		like(
			$@,
			qr/invalid value|greater|atleast/,
			q{$obj = Dokimes->new({ curae => 'hypnos', penthos => '', nosoi => 10 })}
		);
		ok( $obj = Dokimes->new( { curae => 'hypnos', penthos => 'aporia' } ),
			q{$obj = Dokimes->new({curae => 'hypnos', penthos => 'aporia'})}
		);
		ok( $obj = Dokimes->new( curae => 'hypnos', penthos => 'aporia' ),
			q{$obj = Dokimes->new(curae => 'hypnos', penthos => 'aporia')}
		);
		is( $obj->nosoi, 3, q{$obj->nosoi} );
		eval {
			$obj = Dokimes->new(
				{ curae => 'hypnos', penthos => 'aporia', nosoi => [] } );
		};
		like(
			$@,
			qr/invalid value|greater|atleast/,
			q{$obj = Dokimes->new({ curae => 'hypnos', penthos => 'aporia', nosoi => [] })}
		);
		eval {
			$obj = Dokimes->new(
				{ curae => 'hypnos', penthos => 'aporia', nosoi => 'limos' } );
		};
		like(
			$@,
			qr/invalid value|greater|atleast/,
			q{$obj = Dokimes->new({ curae => 'hypnos', penthos => 'aporia', nosoi => 'limos' })}
		);
	};
	subtest 'curae' => sub {
		plan tests => 2;
		ok( my $obj = Dokimes->new( { curae => 'hypnos', penthos => 'aporia' } ),
			q{my $obj = Dokimes->new({curae => 'hypnos', penthos => 'aporia'})}
		);
		can_ok( $obj, 'curae' );
	};
	subtest 'penthos' => sub {
		plan tests => 7;
		ok( my $obj = Dokimes->new( { curae => 'hypnos', penthos => 'aporia' } ),
			q{my $obj = Dokimes->new({curae => 'hypnos', penthos => 'aporia'})}
		);
		can_ok( $obj, 'penthos' );
		is_deeply( $obj->penthos('curae'), 'curae', q{$obj->penthos('curae')} );
		eval { $obj->penthos( [] ) };
		like( $@, qr/invalid value|greater|atleast/, q{$obj->penthos([])} );
		eval { $obj->penthos( \1 ) };
		like( $@, qr/invalid value|greater|atleast/, q{$obj->penthos(\1)} );
		eval { $obj->penthos('') };
		like( $@, qr/invalid value|greater|atleast/, q{$obj->penthos('')} );
		is_deeply( $obj->penthos, 'curae', q{$obj->penthos} );
	};
	subtest 'nosoi' => sub {
		plan tests => 6;
		ok( my $obj = Dokimes->new( { curae => 'hypnos', penthos => 'aporia' } ),
			q{my $obj = Dokimes->new({curae => 'hypnos', penthos => 'aporia'})}
		);
		can_ok( $obj, 'nosoi' );
		is_deeply( $obj->nosoi(10), 10, q{$obj->nosoi(10)} );
		eval { $obj->nosoi( [] ) };
		like( $@, qr/invalid value|greater|atleast/, q{$obj->nosoi([])} );
		eval { $obj->nosoi('phobos') };
		like( $@, qr/invalid value|greater|atleast/, q{$obj->nosoi('phobos')} );
		is_deeply( $obj->nosoi, 10, q{$obj->nosoi} );
	};
	subtest 'limos' => sub {
		plan tests => 10;
		ok( my $obj = Dokimes->new( { curae => 'hypnos', penthos => 'aporia' } ),
			q{my $obj = Dokimes->new({curae => 'hypnos', penthos => 'aporia'})}
		);
		can_ok( $obj, 'limos' );
		eval { $obj->limos( [] ) };
		like( $@, qr/invalid value|greater|atleast/, q{$obj->limos([])} );
		eval { $obj->limos( \1 ) };
		like( $@, qr/invalid value|greater|atleast/, q{$obj->limos(\1)} );
		eval { $obj->limos('') };
		like( $@, qr/invalid value|greater|atleast/, q{$obj->limos('')} );
		eval { $obj->limos(undef) };
		like( $@, qr/invalid value|greater|atleast/, q{$obj->limos(undef)} );
		ok( $obj->penthos(2) && $obj->nosoi(2) && $obj->curae(5),
			q{$obj->penthos(2) && $obj->nosoi(2) && $obj->curae(5)}
		);
		is( $obj->limos("yay"), 5, q{$obj->limos("yay")} );
		ok( $obj->penthos(5), q{$obj->penthos(5)} );
		is( $obj->limos("yay"), '', q{$obj->limos("yay")} );
	};
	subtest 'clear_nosoi' => sub {
		plan tests => 5;
		ok( my $obj = Dokimes->new( { curae => 'hypnos', penthos => 'aporia' } ),
			q{my $obj = Dokimes->new({curae => 'hypnos', penthos => 'aporia'})}
		);
		can_ok( $obj, 'clear_nosoi' );
		is_deeply( $obj->nosoi(10), 10, q{$obj->nosoi(10)} );
		ok( $obj->clear_nosoi, q{$obj->clear_nosoi} );
		is( $obj->nosoi, undef, q{$obj->nosoi} );
	};
	done_testing();


and has 100% test coverage.

	cover --test

	------------------- ------ ------ ------ ------ ------ ------
	File                  stmt   bran   cond    sub   time  total
	------------------- ------ ------ ------ ------ ------ ------
	blib/lib/Dokimes.pm  100.0  100.0  100.0  100.0  100.0  100.0
	Total                100.0  100.0  100.0  100.0  100.0  100.0
	------------------- ------ ------ ------ ------ ------ ------

=cut

=head3 tests

Unfortunately not all code can have auto generated tests, so you should use the :test attribute to define additional
to test custom logic.

=cut

=head4 ok

This simply evaluates any expression ($got eq $expected is just a simple example) and uses that to determine if the test succeeded or failed. A true expression passes, a false one fails.

	['ok', '$obj->$method']

=cut

=head4 can_ok

Checks to make sure the $module or $object can do these @methods (works with functions, too).

	['can_ok', '$obj', $method]

=cut

=head4 isa_ok

Checks to see if the given $object->isa($class). Also checks to make sure the object was defined in the first place. Handy for this sort of thing:

	['isa_ok', '$obj', $class]

=cut

=head4 is

Similar to ok(), is() and isnt() compare their two arguments with eq and ne respectively and use the result of that to determine if the test succeeded or failed. So these:

	['is', '$obj->$method', $expected]

=cut

=head4 isnt

	['isnt', '$obj->$method', $expected]

=cut

=head4 like

Similar to ok(), like() matches $got against the regex qr/expected/.

	['like', '$obj->$method', $expected_regex]

=cut

=head4 unlike

Works exactly as like(), only it checks if $got does not match the given pattern.

	['unlike', '$obj->$method', $expected_regex]

=cut

=head4 deep

Similar to is(), except that if $got and $expected are references, it does a deep comparison walking each data structure to see if they are equivalent. If the two structures are different, it will display the place where they start differing.

	['deep', '$obj->$method', $expected]

=cut

=head4 eval

Evaluate code that you expect to die and check the warning using like.

	['eval', '$obj->$method", $error_expected]

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
