
# Libcola exporter – full scaffold

sub export_to_cola_from_ir {
	my ($ir, $config) = @_;

	my ($ok, $err) = _validate_cola_config($config);
	return (undef, $err) if !$ok;

	my ($cola, $cerr) = _build_cola_structure($ir, $config);
	return (undef, $cerr) if !$cola;

	my ($result, $rerr) = _run_cola($cola, $config);
	return (undef, $rerr) if !$result;

	return _finalize_output($ir, $result, $config);
}

sub export_to_cola_from_dot {
	my ($dot_text, $config) = @_;

	my ($ok, $err) = _validate_cola_config($config);
	return (undef, $err) if !$ok;

	my ($ir, $eerr) = _extract_ir_from_dot($dot_text);
	return (undef, $eerr) if !$ir;

	return export_to_cola_from_ir($ir, $config);
}

sub _validate_cola_config {
	my ($config) = @_;

	for my $k (qw(geometry edge_weights groups constraints output)) {
		return (0, "missing config key: $k") if !exists $config->{$k};
	}

	return (1, undef);
}

sub _build_cola_structure {
	my ($ir, $config) = @_;

	my $cola = {
		nodes       => [],
		edges       => [],
		groups      => [],
		constraints => [],
		id_to_index => {},
		metadata    => {},
	};

	# Nodes
	my $n = 0;
	for my $node (@{ $ir->{nodes} || [] }) {
		my $entry = { id => $node->{id}, index => $n };
		$cola->{id_to_index}{ $node->{id} } = $n;

		if ($config->{geometry} eq 'size' || $config->{geometry} eq 'full') {
			$entry->{width}  = _coerce_num($node->{width});
			$entry->{height} = _coerce_num($node->{height});
		}

		if ($config->{geometry} eq 'full') {
			$entry->{x} = _coerce_num($node->{x});
			$entry->{y} = _coerce_num($node->{y});
		}

		push @{ $cola->{nodes} }, $entry;
		$n++;
	}

	# Edges
	for my $edge (@{ $ir->{edges} || [] }) {
		my $entry = {
			from => $edge->{from},
			to   => $edge->{to},
		};

		if ($config->{edge_weights} eq 'uniform') {
			$entry->{weight} = 1;
		}
		elsif ($config->{edge_weights} eq 'attribute') {
			$entry->{weight} = _coerce_num($edge->{weight});
		}

		$entry->{length} = _resolve_edge_length($edge);

		push @{ $cola->{edges} }, $entry;
	}

	# Groups
	if ($config->{groups} ne 'none') {
		for my $g (@{ $ir->{subgraphs} || [] }) {
			if ($config->{groups} eq 'clusters' && $g->{id} !~ /^cluster_/) {
				next;
			}

			my $entry = {
				id      => $g->{id},
				members => [ @{ $g->{nodes} || [] } ],
			};

			$entry->{padding} = _coerce_num($g->{padding}) if exists $g->{padding};

			push @{ $cola->{groups} }, $entry;
		}
	}

	# Constraints
	if ($config->{constraints} ne 'none') {
		my $c = _build_constraints($ir, $config, $cola);
		push @{ $cola->{constraints} }, @$c;
	}

	return ($cola, undef);
}

sub _resolve_edge_length {
	my ($edge) = @_;

	for my $k (qw(len length)) {
		return _coerce_num($edge->{$k}) if exists $edge->{$k} && _looks_numeric($edge->{$k});
	}

	return 50;
}

sub _build_constraints {
	my ($ir, $config, $cola) = @_;
	my @out;

	if ($config->{constraints} eq 'align' || $config->{constraints} eq 'all') {
		push @out, @{ _extract_alignment_constraints($ir, $cola) };
	}

	if ($config->{constraints} eq 'separation' || $config->{constraints} eq 'all') {
		push @out, @{ _extract_separation_constraints($ir, $config, $cola) };
	}

	return \@out;
}

sub _extract_alignment_constraints {
	my ($ir, $cola) = @_;
	my @out;

	for my $c (@{ $ir->{constraints}{align} || [] }) {
		my @nodes = @{ $c->{nodes} || [] };
		@nodes = grep { exists $cola->{id_to_index}{$_} } @nodes;
		next if @nodes < 2;

		push @out, {
			type  => 'align',
			nodes => [ @nodes ],
		};
	}

	return \@out;
}

sub _extract_separation_constraints {
	my ($ir, $config, $cola) = @_;
	my @out;

	my $explicit_sep = _coerce_num($config->{separation});

	if (@{ $ir->{constraints}{separation} || [] }) {
		for my $c (@{ $ir->{constraints}{separation} }) {
			my $a = $c->{a};
			my $b = $c->{b};
			next if !defined $a || !defined $b;
			next if !exists $cola->{id_to_index}{$a} || !exists $cola->{id_to_index}{$b};

			my $gap = defined $explicit_sep ? $explicit_sep : _coerce_num($c->{gap});
			$gap = 50 if !defined $gap;

			push @out, {
				type => 'separation',
				a    => $a,
				b    => $b,
				gap  => $gap,
			};
		}
		return \@out;
	}

	my $nodes = $cola->{nodes} || [];
	my $n = @$nodes;

	for (my $i = 0; $i < $n; $i++) {
		for (my $j = $i + 1; $j < $n; $j++) {
			my $a = $nodes->[$i];
			my $b = $nodes->[$j];

			my $gap;
			if (defined $explicit_sep) {
				$gap = $explicit_sep;
			} elsif (defined $a->{width} && defined $b->{width}) {
				my $w = ($a->{width} + $b->{width}) / 2;
				my $h = (defined $a->{height} && defined $b->{height})
					? ($a->{height} + $b->{height}) / 2
					: $w;
				$gap = ($w + $h) / 2;
			} else {
				$gap = 50;
			}

			push @out, {
				type => 'separation',
				a    => $a->{id},
				b    => $b->{id},
				gap  => $gap,
			};
		}
	}

	return \@out;
}

sub _coerce_num {
	my ($v) = @_;
	return undef if !defined $v;
	return $v + 0 if _looks_numeric($v);
	return undef;
}

sub _looks_numeric {
	my ($v) = @_;
	return ($v =~ /^-?\d+(?:\.\d+)?$/) ? 1 : 0;
}

sub _run_cola {
	my ($cola, $config) = @_;

	# Placeholder for actual libcola invocation.
	# Expected to return a structure with node positions keyed by node id or index.

	my %geometry;
	for my $node (@{ $cola->{nodes} || [] }) {
		$geometry{ $node->{id} } = {
			x => $node->{x},
			y => $node->{y},
		};
	}

	return ({ geometry => \\%geometry }, undef);
}

sub _finalize_output {
	my ($ir, $result, $config) = @_;

	if ($config->{output} eq 'geometry') {
		return ($result->{geometry}, undef);
	}
	elsif ($config->{output} eq 'ir') {
		return (_inject_geometry_into_ir($ir, $result), undef);
	}
	elsif ($config->{output} eq 'both') {
		return ({
			ir       => _inject_geometry_into_ir($ir, $result),
			geometry => $result->{geometry},
		}, undef);
	}

	return (undef, "invalid output mode");
}

sub _inject_geometry_into_ir {
	my ($ir, $result) = @_;

	my %geom = %{ $result->{geometry} || {} };

	for my $node (@{ $ir->{nodes} || [] }) {
		my $g = $geom{ $node->{id} } or next;
		$node->{x} = $g->{x} if defined $g->{x};
		$node->{y} = $g->{y} if defined $g->{y};
	}

	return $ir;
}

sub _extract_ir_from_dot {
	my ($dot_text) = @_;

	# Placeholder: integrate your real DOT → IR extractor here.
	# On failure: return (undef, "error message").

	my $ir = {
		nodes       => [],
		edges       => [],
		subgraphs   => [],
		constraints => {
			align      => [],
			separation => [],
		},
	};

	return ($ir, undef);
}
