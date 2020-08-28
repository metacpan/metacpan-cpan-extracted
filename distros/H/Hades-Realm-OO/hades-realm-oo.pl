use Hades;
Hades->run({
	eval => q`
		Hades::Realm::OO base Hades {
			current_class :t(Str)
			meta :t(Map[Str, Dict[types => HashRef, attributes => HashRef]])
			is_role :t(Bool) :c
			module_generate $mg :t(Object) {
				$mg->keyword('has',
					CODE => sub { $self->build_has(@_) },
					KEYWORDS => $self->build_has_keywords,
					POD_TITLE => 'ATTRIBUTES',
					POD_POD => 'Get or set $keyword',
					POD_EXAMPLE => "\$obj->\$keyword;\n\n\t\$obj->\$keyword(\$value)"
				);
				$mg->keyword('extends',
					CODE => sub { $self->build_extends(@_) },
					KEYWORDS => $self->build_extends_keywords,
					POD_TITLE => 'EXTENDS',
					POD_POD => 'This class extends the following classes',
					POD_EXAMPLE => "\$keyword"
				);
				$mg->keyword('with',
					CODE => sub { $self->build_with(@_) },
					KEYWORDS => $self->build_with_keywords,
					POD_TITLE => 'WITH',
					POD_POD => 'This class includes the following roles',
					POD_EXAMPLE => "\$keyword"
				);
				$mg->keyword('requires',
					CODE => sub { $self->build_requires(@_) },
					KEYWORDS => $self->build_requires_keywords,
					POD_TITLE => 'REQUIRES',
					POD_POD => 'This class requires:',
					POD_EXAMPLE => "\$keyword"
				);
				$mg->keyword('before',
					CODE => sub { $self->build_before(@_) },
					KEYWORDS => $self->build_before_keywords,
					POD_TITLE => 'BEFORE',
					POD_POD => 'Call $keyword method',
					POD_EXAMPLE => "\$obj->\$keyword"
				);
				$mg->keyword('around',
					CODE => sub { $self->build_around(@_) },
					KEYWORDS => $self->build_around_keywords,
					POD_TITLE => 'AROUND',
					POD_POD => 'Call $keyword method',
					POD_EXAMPLE => "\$obj->\$keyword"
				);
				$mg->keyword('after',
					CODE => sub { $self->build_after(@_) },
					KEYWORDS => $self->build_after_keywords,
					POD_TITLE => 'AFTER',
					POD_POD => 'Call $keyword method',
					POD_EXAMPLE => "\$obj->\$keyword"
				);
			}
			build_class_inheritance :b {
				if ($params[-1] =~ m/^(role)$/i) {
					$self->is_role(1);
					return $params[-2];
				} elsif ($params[-1] =~ m/^(with|extends)$/) {
					return $params[-1];
				} elsif ($params[-2] =~ m/^(is|with|extends)$/) {
					my ($mg, $last, $ident) = splice @params, -3;
					$mg->$last($ident); 
					return $last;
				}
			}
			build_new $mg :t(Object) $meta :t(HashRef) $types :t(HashRef) :d({}) {
        			my %class = %Module::Generate::CLASS;
      				my %accessors = ();
      				map {
					my $key = $_;
					exists $meta->{$key}->{$_} && do { $accessors{$key}->{$_} = $meta->{$key}->{$_} }
        					for (@{$self->build_has_keywords});
				} grep { 
					$self->unique_types($meta->{$_}->{type}, $types) if $meta->{$_}->{type};
					$meta->{$_}->{meta} eq 'ACCESSOR'; 
				} keys %{$meta};
				my $class_meta = $self->meta;
				$class_meta->{$class{CURRENT}{NAME}} = {
					types => $types,
					attributes => \%accessors
				};
				$self->meta($class_meta);
				$self->current_class($class{CURRENT}{NAME});
        			$class{CURRENT}{SUBS}{new}{NO_CODE} = 1;
        			$class{CURRENT}{SUBS}{new}{TEST} = [$self->build_tests('new', $meta, 'new', \%class)];
			}
			build_clearer :a {
				$res[0]->no_code(1);
			}
			build_predicate :a {
				$res[0]->no_code(1);
		  	}
			build_accessor $mg :t(Object) $name :t(Str) $meta :t(HashRef) {
				$mg->has($name);
				$meta->{$name}->{$_} and $mg->$_(
					$self->can("build_accessor_${_}") 
						? $self->can("build_accessor_${_}")->($meta->{$name}->{$_}) 
						: $meta->{$name}->{$_}
				) for (@{$self->build_has_keywords});
				$mg->isa(
					$self->can("build_accessor_isa") 
						? $self->can("build_accessor_isa")->($meta->{$name}->{type}->[0]) 
						: $meta->{$name}->{type}->[0]
				) if ! $meta->{$name}->{isa};
				$mg->clear_tests->test(
					$self->build_tests($name, $meta->{$name})
				);
			}
			build_modify $mg :t(Object) $name :t(Str) $meta :t(HashRef) {
				$meta->{$name}->{$_} 
					&& $mg->$_($name)->code(delete $meta->{$name}->{$_})->test($self->build_tests($name, $meta->{$name})) 
				for qw/before around after/;
			}
			after_class $mg :t(Object) $meta :t(HashRef) {
				$self->clear_is_role == 1 ? $self->build_as_role($mg, $meta) : $self->build_as_class($mg, $meta);
			}
			unique_types $type :t(Str) :co(if (ref $type eq 'ARRAY') { $self->unique_types($_, $unique) for @{$type}; return }) $unique :t(HashRef) {
				if ($type =~ s/^([^\[ ]+)\[(.*)\]$/$2/) {
					my ($t, $v) = ($1, $2);
					$unique->{$t}++ if ($t =~ m/^\w+$/);
					$v =~ s/,\s*\d+,\s*\d+$//g;
					$self->unique_types($v, $unique);
				} elsif ($type =~ m/^\s*\w+\s*\=\>\s*/ || $type =~ m/^([^,]+),\s*(.*)$/) {
					my @matches = split ',', $type;
					while (@matches) {
						my ($match) = (shift @matches);
						if (@matches && $match =~ m/(Map|Tuple|ArrayRef|Dict)\[/) {
							my $cb = sub {
								my $copy = shift;
								1 while ($copy =~ s/\[[^\[\]]+\]//g);
								return ($copy =~ m/\[|\]/) ? 1 : 0;
							};
							1 while ($cb->($match .=  ', ' . shift @matches));
						}
						my ($k, $v) = map { my $h = $_; $h =~ s/^\s*|\s*$//g; $h; } $match =~ m/\s+\w*\s*\=\>/ ? split('=>', $match, 2) : $match;
						$self->unique_types($v || $k, $unique);
					}
				} else {
					$unique->{$type}++;
				}
			}
			build_as_class $mg :t(Object) $meta :t(HashRef) { return ($mg, $meta) }
			build_as_role $mg :t(Object) $meta :t(HashRef) { return ($mg, $meta) }
			build_has_keywords $keywords :t(ArrayRef) :d([qw/is isa required default clearer coerce predicate trigger private/]) { return $keywords; }
			build_has $meta :t(HashRef) { 
				my $name = $meta->{has};
				my $private = $self->SUPER::build_private($name, $meta->{private});
				my $type = $self->SUPER::build_coerce($name, '$value', $meta->{coerce}) . $self->build_type($name, $meta->{type}[0]);
				my $trigger = $self->SUPER::build_trigger($name, '$value', $meta->{trigger});
				return qq|{
					my ( \$self, \$value ) = \@_; $private
					if ( defined \$value ) { $type
						\$self->{$name} = \$value; $trigger
					}
					return \$self->{$name};
				}|;
			}
			build_extends_keywords $keywords :t(ArrayRef) :d([]) { return $keywords; }
			build_extends $meta :t(HashRef) {
				$meta->{extends} = '"' . $meta->{extends} . '"' if $meta->{extends} !~ m/^["'q]/;
				return qq(extends $meta->{extends};);
			}
			build_with_keywords $keywords :t(ArrayRef) :d([]) { return $keywords; }
			build_with $meta :t(HashRef) {
				$meta->{with} = '"' . $meta->{with} . '"' if $meta->{with} !~ m/^["'q]/;
				return qq(with $meta->{with};);
			}
			build_requires_keywords $keywords :t(ArrayRef) :d([]) { return $keywords; }
			build_requires $meta :t(HashRef) {
				$meta->{requires} = '"' . $meta->{requires} . '"' if $meta->{requires} !~ m/^["'q]/;
				return qq(requires $meta->{requires};);
			}
			build_before_keywords $keywords :t(ArrayRef) :d([]) { return $keywords; }
			build_before $meta :t(HashRef) { 
				return qq(before $meta->{before} => sub { my (\$orig, \$self, \@params) = \@_; $meta->{CODE} };); 
			}
			build_around_keywords $keywords :t(ArrayRef) :d([]) { return $keywords; }
			build_around $meta :t(HashRef) { 
				return qq(around $meta->{around} => sub { my (\$orig, \$self, \@params) = \@_; $meta->{CODE} };); 
			}
			build_after_keywords $keywords :t(ArrayRef) :d([]) { return $keywords; }
			build_after $meta :t(HashRef) { 
				return qq(after $meta->{after} => sub { my (\$orig, \@params) = \@_; $meta->{CODE} };); 
			}
		}
	`,
	lib => 'lib',
	tlib => 't'
});
