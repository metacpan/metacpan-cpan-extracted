package Exporter::Extensible;
use v5;
use strict; no strict 'refs';
use warnings; no warnings 'redefine';
require Exporter::Extensible::Compat if "$]" < "5.012";
require mro;

# ABSTRACT: Create easy-to-extend modules which export symbols
our $VERSION = '0.11'; # VERSION

our %EXPORT_FAST_SUB_CACHE;
our %EXPORT_PKG_CACHE;
our %EXPORT_TAGS_PKG_CACHE;

our %EXPORT= (
	-exporter_setup => [ 'exporter_setup', 1 ],
);

our %sigil_to_reftype= (
	'$' => 'SCALAR',
	'@' => 'ARRAY',
	'%' => 'HASH',
	'*' => 'GLOB',
	'&' => 'CODE',
	''  => 'CODE',
	'-' => 'CODE',
);
our %reftype_to_sigil= (
	'SCALAR' => '$',
	'ARRAY'  => '@',
	'HASH'   => '%',
	'GLOB'   => '*',
	'CODE'   => '',
);
our %sigil_to_generator_prefix= (
	'$' => [ '_generateSCALAR_', '_generateScalar_' ],
	'@' => [ '_generateARRAY_', '_generateArray_' ],
	'%' => [ '_generateHASH_', '_generateHash_' ],
	'*' => [ '_generateGLOB_', '_generateGlob_' ],
	'&' => [ '_generate_', '_generateCODE_', '_generateCode' ],
);
$sigil_to_generator_prefix{''}= $sigil_to_generator_prefix{'&'};
our %ord_is_sigil= ( ord '$', 1, ord '@', 1, ord '%', 1, ord '*', 1, ord '&', 1, ord '-', 1, ord ':', 1 );
our %ord_is_directive= ( ord '-', 1, ord ':', 1 );

my ($carp, $croak, $weaken, $colon, $hyphen);
$carp=   sub { require Carp; $carp= \&Carp::carp; goto $carp; };
$croak=  sub { require Carp; $croak= \&Carp::croak; goto $croak; };
$weaken= sub { require Scalar::Util; $weaken= \&Scalar::Util::weaken; goto $weaken; };
$colon= ord ':';
$hyphen= ord '-';

sub import {
	my $self= shift;
	# Can be called as class method or instance method
	$self= bless { into => scalar caller }, $self
		unless ref $self;
	# Optional config hash might be given as first argument
	$self->exporter_apply_global_config(shift)
		if ref $_[0] eq 'HASH';
	my $class= ref $self;
	my @todo= @_? @_ : @{ $self->exporter_get_tag('default') || [] };
	return 1 unless @todo;
	# If only installing subs without generators or unusual options, use a more direct code path.
	# This only takes effect the second time a symbol is requested, since the cache is not pre-populated.
	# (abuse a while loop as a if/goto construct)
	fast: while (!$self->{_complex} && !grep ref, @todo) {
		my $fastsub= $EXPORT_FAST_SUB_CACHE{$class} || last; # can't optimize if no cache is built
		my $prefix= $self->{into}.'::'; # {into} can be a hashref, but not when {_complex} is false
		my $replace= $self->{replace} || 'carp';
		if ($replace eq 'carp') {
			# Use perl's own warning system to detect attempts to overwrite the GLOB.  Only warn if the
			# new reference isn't the same as existing.
			use warnings 'redefine';
			local $SIG{__WARN__}= sub { *{$prefix.$_}{CODE} == $fastsub->{$_} or $carp->($_[0]) };
			ord == $colon || (*{$prefix.$_}= ($fastsub->{$_} || last fast))
				for @todo;
		}
		elsif ($replace eq 1) {
			ord == $colon || (*{$prefix.$_}= ($fastsub->{$_} || last fast))
				for @todo;
		}
		else { last } # replace==croak and replace==skip require more logic
		# Now apply any tags that were requested.  Each will get its own determination of whether it
		# can use the 'fast' method.
		ord == $colon && $self->import(@{$self->exporter_get_tag(substr $_, 1)})
			for @todo;
		return 1;
	}
	my $install= $self->_exporter_build_install_set(\@todo);

	# Install might actually be uninstall.  It also might be overridden by the user.
	# The exporter_combine_config sets this up so we don't need to think about details.
	my $method= $self->{installer} || ($self->{no}? 'exporter_uninstall' : 'exporter_install');
	# Convert
	#    { foo => { SCALAR => \$foo, HASH => \%foo } }
	# into
	#    [ foo => \$foo, foo => \%foo ]
	my @flat_install= %$install;
	for my $i (reverse 1..$#flat_install) {
		if (ref $flat_install[$i] eq 'HASH') {
			splice @flat_install, $i-1, 2, map +($flat_install[$i-1] => $_), values %{$flat_install[$i]};
		}
	}
	# Then pass that list to the installer (or uninstaller)
	$self->$method(\@flat_install);
	# If scope requested, create the scope-guard object
	if (my $scope= $self->{scope}) {
		$$scope= bless [ $self, \@flat_install ], 'Exporter::Extensible::UnimportScopeGuard';
		$weaken->($self->{scope});
	}
	# It's entirely likely that a generator might curry $self inside the sub it generated.
	# So, we end up with a circular reference if we're holding onto the set of all things we
	# exported.  Clear the set.
	%$install= ();
	1;
}

sub _exporter_build_install_set {
	my ($self, $todo)= @_;
	$self->{todo}= $todo;
	my $install= $self->{install_set} ||= {};
	my $inventory= $EXPORT_PKG_CACHE{ref $self} ||= {};
	while (@$todo) {
		my $symbol= shift @$todo;

		# If it is a tag, then recursively call import on that list
		if (ord $symbol == $colon) {
			my $name= substr $symbol, 1;
			my $tag_cache= $self->exporter_get_tag($name)
				or $croak->("Tag ':$name' is not exported by ".ref($self));
			# If first element of tag is a hashref, they count as nested global options.
			# If tag was followed by hashref, those are user-supplied options.
			if (ref $tag_cache->[0] eq 'HASH' || ref $todo->[0] eq 'HASH') {
				$tag_cache= [ @$tag_cache ]; # don't destroy cache
				my $self2= $self;
				$self2= $self2->exporter_apply_global_config(shift @$tag_cache)
					if ref $tag_cache->[0] eq 'HASH';
				$self2= $self2->exporter_apply_inline_config(shift @$todo)
					if ref $todo->[0] eq 'HASH';
				if ($self != $self2) {
					$self2->_exporter_build_install_set($tag_cache);
					next;
				}
			}
			unshift @$todo, @$tag_cache;
			next;
		}
		# Else, it is an option or plain symbol to be exported
		# Check current package cache first, else do the full lookup.
		my $ref= (exists $inventory->{$symbol}? $inventory->{$symbol} : $self->exporter_get_inherited($symbol))
			or $croak->("'$symbol' is not exported by ".ref($self));

		# If it starts with '-', it is an option, and might consume additional args
		if (ord $symbol == $hyphen) {
			# back-compat for when opt was arrayref
			if (ref $ref eq 'ARRAY') {
				my ($method, $count)= @$ref;
				$ref= $self->_exporter_wrap_option_handler($method, $count);
			}
			$self->$ref;
		}
		else {
			my ($sigil, $name)= $ord_is_sigil{ord $symbol}? ( substr($symbol,0,1), substr($symbol,1) ) : ( '', $symbol );
			my $self2= $self;
			# If followed by a hashref, add those options to the current ones.
			$self2= $self->exporter_apply_inline_config(shift @$todo)
				if ref $todo->[0] eq 'HASH';
			if ($self2->{_name_mangle}) {
				next if defined $self2->{not} and $self2->_exporter_is_excluded($symbol);
				$name= delete $self2->{as} || ($self2->{prefix}||'') . $name . ($self2->{suffix}||'');
				# If 'as' was the only reason for _name_mangle, then disable it to return to fast-path
				delete $self2->{_name_mangle} unless defined $self2->{prefix} || defined $self2->{suffix} || defined $self2->{not};
			}
			# If $ref is a generator (method name or coderef or coderefref in the case of exported subs) then run it,
			# unless it was already run for the current symbol exporting to the current dest.
			if (!ref $ref || ref $ref eq ($sigil? 'CODE':'REF')) {
				$ref= ($self2->{_generator_cache}{$symbol.";".$name} ||= do {
					# Run the generator.
					my $method= ref $ref eq 'REF'? $$ref : $ref;
					$method= $$method if ref $method eq 'SCALAR'; # back-compat for \\$method_name
					$self2->$method($symbol, $self2->{generator_arg});
				});
				# Verify generator output matches sigil
				ref $ref eq $sigil_to_reftype{$sigil} or (ref $ref eq 'REF' && $sigil eq '$')
					or $croak->("Trying to export '$symbol', but generator returned "
						.ref($ref).' (need '.$sigil_to_reftype{$sigil}.')');
			}
			# Check for collisions.  Unlikely scenario in typical usage, but could occur if two
			# tags include the same symbol, or if user adds a prefix or suffix that collides
			# with another exported name.
			if ($install->{$name}) {
				if ($install->{$name} != $ref) { # most common case of duplicate export, ignore it.
					if (ref $ref eq 'GLOB' || ref $install->{$name} eq 'GLOB') {
						# globrefs will never be equal - compare the glob itself.
						ref $ref eq 'GLOB' && ref $install->{dest} eq 'GLOB' && *{$install->{$name}} eq *$ref
							# can't install an entire glob at the same time as a piece of a glob.
							or $croak->("Can't install ".ref($ref)." and ".$install->{dest}." into the same symbol '".$name."'");
					}
					# Upgrade this item to a hashref of reftype if it wasn't already  (hashrefs are always stored this way)
					$install->{$name}= { ref($install->{$name}) => $install->{$name} }
						unless ref $install->{$name} eq 'HASH';
					# Assign this new ref into a slot of that hash, unless something different was already there
					($install->{$name}{ref $ref} ||= $ref) == $ref
						or $croak->("Trying to import conflicting ".ref($ref)." values for '".$name."'");
				}
			}
			# Only make install->{$name} a hashref if we really have to, for performance.
			elsif (ref $ref eq 'HASH') {
				$install->{$name}{HASH}= $ref;
			}
			else {
				$install->{$name}= $ref;
			}
		}
	}
	return $install;
}

sub Exporter::Extensible::UnimportScopeGuard::clean {
	my $self= shift;
	$self->[0]->exporter_uninstall($self->[1]) if $self->[1];
	$self->[1]= undef; # Ignore subsequent calls
}

sub Exporter::Extensible::UnimportScopeGuard::DESTROY {
	shift->clean;
}

sub exporter_install {
	my $self= shift;
	my $into= $self->{into} or $croak->("'into' must be defined before exporter_install");
	return $self->_exporter_install_to_ref(@_) if ref $into;
	my $replace= $self->{replace} || 'warn';
	my $stash= \%{$into.'::'};
	my $list= @_ == 1 && ref $_[0] eq 'ARRAY'? $_[0] : \@_;
	for (my $i= 0; $i < @$list; $i+= 2) {
		my ($name, $ref)= @{$list}[$i..1+$i];
		my $pkg_dest= $into.'::'.$name;
		# Each value is either a hashref with keys matching the parts of a typeglob,
		# or it is a single ref that can be assigned directly to the typeglob.
		if (defined $stash->{$name} and $replace ne 1) {
			# there is actually no way I know of to test existence of *foo{SCALAR}.
			# It auto-vivifies when accessed.
			my $conflict= (ref $ref eq 'GLOB')? $stash->{$name} ne *$ref
				: (ref $ref eq 'SCALAR')? 0 # TODO: How to test existence of *foo{SCALAR} ?  It auto-vivifies
				: (*$pkg_dest{ref $ref} && *$pkg_dest{ref $ref} != $ref);
			if ($conflict) {
				next if $replace eq 'skip';
				$name= $reftype_to_sigil{ref $ref} . $name; # include sigil for user's benefit
				$replace eq 'warn'? $carp->("Overwriting '$name' with $ref from ".ref($self))
					: $croak->("Refusing to overwrite '$name' with $ref from ".ref($self));
			}
		}
		*$pkg_dest= $ref;
	}
}

sub exporter_uninstall {
	my $self= shift;
	my $into= $self->{into} or $croak->("'into' must be defined before exporter_uninstall");
	return $self->_exporter_install_to_ref(@_) if ref $into;
	my $stash= \%{$into.'::'};
	my $list= @_ == 1 && ref $_[0] eq 'ARRAY'? $_[0] : \@_;
	for (my $i= 0; $i < @$list; $i+= 2) {
		my ($name, $ref)= @{$list}[$i..1+$i];
		# Each value is either a hashref with keys matching the parts of a typeglob,
		# or it is a single ref that can be assigned directly to the typeglob.
		if (ref $ref eq 'GLOB') {
			# If the value we installed is no longer there, do nothing
			next unless *$ref eq ($stash->{$name}||'');
			delete $stash->{$name};
		}
		else {
			my $pkg_dest= $into.'::'.$name;
			# If the value we installed is no longer there, do nothing
			next unless $ref == (*{$pkg_dest}{ref $ref}||0);
			# Remove old typeglob, then copy all slots except reftype back to that typeglob name
			my $old= delete $stash->{$name};
			($_ ne ref $ref) && *{$old}{$_} && (*$pkg_dest= *{$old}{$_})
				for qw( SCALAR HASH ARRAY CODE IO );
		}
	}
}

sub _exporter_install_to_ref {
	my $self= shift;
	my $into= $self->{into};
	ref $into eq 'HASH' or $croak->("'into' must be a hashref");
	my $replace= $self->{replace} || 'warn';
	my $list= @_ == 1 && ref $_[0] eq 'ARRAY'? $_[0] : \@_;
	for (my $i= 0; $i < @$list; $i+= 2) {
		my ($name, $ref)= @{$list}[$i..1+$i];
		$name= $reftype_to_sigil{ref $ref} . $name; # include sigil when installing to hashref
		if ($self->{no}) {
			delete $into->{$name};
		}
		else {
			if (defined $into->{$name} && $into->{name} != $ref) {
				$replace eq 'skip' and next;
				$replace eq 'warn' and $carp->("Overwriting '$name' with $ref from ".ref($self));
				$replace eq 'die' and $croak->("Refusing to overwrite '$name' with $ref from ".ref($self));
			}
			$into->{$name}= $ref;
		}
	}
}

sub exporter_config_prefix    { $_[0]->_exporter_set_attr(prefix => $_[1]) if @_ > 1; $_[0]{prefix} }
sub exporter_config_suffix    { $_[0]->_exporter_set_attr(suffix => $_[1]) if @_ > 1; $_[0]{suffix} }
sub exporter_config_as        { $_[0]->_exporter_set_attr(as     => $_[1]) if @_ > 1; $_[0]{as} }
sub exporter_config_no        { $_[0]->_exporter_set_attr(no     => $_[1]) if @_ > 1; $_[0]{no} }
sub exporter_config_into      { $_[0]->_exporter_set_attr(into   => $_[1]) if @_ > 1; $_[0]{into} }
sub exporter_config_scope     { $_[0]->_exporter_set_attr(scope  => $_[1]) if @_ > 1; $_[0]{scope};     }
sub exporter_config_not       { $_[0]->_exporter_set_attr(not    => $_[1]) if @_ > 1; $_[0]{not};       }
sub exporter_config_installer { $_[0]->_exporter_set_attr(installer => $_[1]) if @_ > 1; $_[0]{installer}; }

sub _exporter_set_attr {
	my ($self, $name, $val)= @_;
	$self->{$name}= $val;
	# After changing config, update the optimization flags.
	# _name_mangle is set if there is any deviation from normal installation of the symbol name
	$self->{_name_mangle}= defined $self->{not}
		|| defined $self->{as}
		|| (defined $self->{prefix} && length $self->{prefix})
		|| (defined $self->{suffix} && length $self->{suffix});
	# _complex is set if the required algorithm is anything more than a simple *{$into.'::'.$name}= $ref
	# but 'replace' does not trigger _complex currently because I handled that in the fast installer.
	$self->{_complex}= $self->{no} || $self->{_name_mangle}
		|| defined $self->{scope}
		|| $self->{installer} || ref $self->{into};
}

our %replace_aliases= (
	1     => 1,
	carp  => 'carp',
	warn  => 'carp',
	croak => 'croak',
	fatal => 'croak',
	die   => 'croak',
	skip  => 'skip',
);
sub exporter_config_replace {
	$_[0]{replace}= $replace_aliases{$_[1]} or $croak->("Invalid 'replace' value: '$_[1]'")
		if @_ > 1;
	$_[0]{replace};
}

sub exporter_apply_global_config {
	my ($self, $conf)= @_;
	for my $k (keys %$conf) {
		my $setter= $self->can('exporter_config_'.$k)
			or (substr($k,0,1) eq '-' && $self->can('exporter_config_'.substr($k,1)))
			or $croak->("No such exporter configuration '$k'");
		$self->$setter($conf->{$k});
	}
	$self;
}

sub exporter_apply_inline_config {
	my ($self, $conf)= @_;
	my @for_global_config= grep ord == $hyphen, keys %$conf;
	# In the event that only "-as" was given, we don't actually need to create a new object
	if (@for_global_config == 1 && $for_global_config[0] eq '-as' && keys %$conf == 1) {
		$self->exporter_config_as($conf->{-as});
		return $self;
	}
	# Else clone and apply temporary settings
	my $self2= bless { %$self, parent => $self }, ref $self;
	for my $k (@for_global_config) {
		my $setter= $self2->can('exporter_config_'.substr($k,1))
			or $croak->("No such exporter configuration '$k'");
		$self2->$setter($conf->{$k});
	}
	# If any options didn't start with '-', then the config becomes a parameter to the generator.
	# The generator cache isn't valid for $self2 since the arg changed.
	if (@for_global_config < scalar keys %$conf) {
		$self2->{generator_arg}= $conf;
		delete $self2->{_generator_cache};
	}
	$self2;
}

sub unimport {
	# If first option is a hashref (global options), merge that with { no => 1 }
	my %opts= ( (ref $_[1] eq 'HASH'? %{splice(@_,1,1)} : () ), no => 1 );
	# Use this as the global options
	splice @_, 1, 0, \%opts;
	goto $_[0]->can('import'); # to preserve caller
}

sub import_into {
	shift->import({ into => shift, (ref $_[0] eq 'HASH'? %{+shift} : ()) }, @_);
}

sub exporter_register_symbol {
	my ($class, $export_name, $ref)= @_;
	$class= ref($class)||$class;
	$ref ||= $class->_exporter_get_ref_to_package_var($export_name)
		or $croak->("Symbol $export_name not found in package $class");
	${$class.'::EXPORT'}{$export_name}= $ref;
}

sub exporter_autoload_symbol {
	my ($class, $export_name)= @_;
	return;
}

sub exporter_get_inherited {
	my ($self, $sym)= @_;
	my $class= ref($self)||$self;
	# Make the common case fast.
	return $EXPORT_PKG_CACHE{$class}{$sym} ||=
		do {
			my $x;
			# quick check of own package first
			unless ($x= ${$class.'::EXPORT'}{$sym}) {
				# search package hierarchy
				($x= ${$_.'::EXPORT'}{$sym}) && last for @{ mro::get_linear_isa($class) }
			}
			# If it is a plain sub, it is elligible for "fast export"
			$EXPORT_FAST_SUB_CACHE{$class}{$sym}= $x if ref $x eq 'CODE' and !$ord_is_sigil{ord $sym};
			#print "# ref=".ref($x)." sym=$sym\n";
			$x;
		}
		# Isn't exported, but maybe autoload.
		|| $self->exporter_autoload_symbol($sym);
}

sub exporter_register_option {
	my ($class, $option_name, $method_name, $arg_count)= @_;
	$class= ref($class)||$class;
	${$class.'::EXPORT'}{'-'.$option_name}= $class->_exporter_wrap_option_handler($method_name, $arg_count);
}

sub _exporter_wrap_option_handler {
	my ($class, $method, $count)= @_;
	return $method unless $count;
	if ($count eq '*') {
		return sub {
			my $consumed= $_[0]->$method(@{$_[0]{todo}});
			$consumed =~ /^[0-9]+$/ or $croak->("Method $method in ".ref($_[0])." must return a number of arguments consumed");
			splice(@{$_[0]{todo}}, 0, $consumed);
		}
	}
	elsif ($count eq '?') {
		return sub {
			if (ref $_[0]{todo}[0]) {
				my $arg= shift @{$_[0]{todo}};
				(ref $arg eq 'HASH'? $_[0]->exporter_apply_inline_config($arg) : $_[0])
					->$method($arg);
			} else {
				$_[0]->$method();
			}
		}
	}
	else {
		return sub {
			$_[0]->$method(splice(@{$_[0]{todo}}, 0, $count));
		}
	}
}

sub exporter_register_generator {
	my ($class, $export_name, $method)= @_;
	$class= ref($class)||$class;
	!ref $method or ref $method eq 'CODE'
		or $croak->("Generator method must be method name (scalar) or coderef");
	# Register tag generators in %EXPORT_TAGS
	if (ord $export_name == $colon) {
		(${$class.'::EXPORT_TAGS'}{substr($export_name,1)} ||= $method) eq $method
			or $croak->("Cannot set generator for $export_name when that tag is already populated within this class ($class)");
	}
	# Register variable generators (export having a sigil) in %EXPORT
	# Sub generators (for coderef methods) get an extra layer of ref added
	else {
		${$class.'::EXPORT'}{$export_name}= (ref $method && !$ord_is_sigil{ord $export_name})? \$method : $method;
	}
}

sub exporter_register_tag_members {
	my ($class, $tag_name)= (shift, shift);
	$class= ref($class)||$class;
	push @{ ${$class.'::EXPORT_TAGS'}{$tag_name} }, @_;
}

sub _exporter_build_tag_cache {
	my ($self, $tagname)= @_;
	my $class= ref($self)||$self;
	# Collect all members of this tag from any parent class, but stop at the first undef
	my ($dynamic, @keep, %seen, $known);
	for (@{ mro::get_linear_isa($class) }) {
		my $add= ${$_.'::EXPORT_TAGS'}{$tagname}
			# Special case, ':all' is built from all known keys of the %EXPORT var at each inherited package
			# Also exclude anything exported as part of the Exporter API, but right now that is only
			# the '-exporter_setup' option.
			|| ($tagname eq 'all' && defined *{$_.'::EXPORT'}{HASH}
				&& [ grep !$ord_is_directive{+ord}, keys %{$_.'::EXPORT'} ]
			)
			or next;
		++$known;
		if (ref $add ne 'ARRAY') {
			# Found a generator (coderef or method name ref).  Call it to get the list of tags.
			$add= ref $add eq 'CODE'? $add
				: ref $add eq 'SCALAR'? $$add
				: $croak->("Tag must expand to an array, code, or a method name ref (not $add)");
			$add= $self->$add($self->{generator_arg});
			ref $add eq 'ARRAY' or $croak->("Tag generator must return an arrayref");
			++$dynamic;
		}
		# If first element of the list is undef it means this class wanted to reset the tag.
		# Since we're iterating *up* the hierarchy, it just means end here.
		my $start= (@$add && !defined $add->[0])? 1 : 0;
		# symbol might be followed by options, so need to skip over refs, but also need to allow
		# duplicate symbols if they were followed by a ref.
		(ref $add->[$_] || !$seen{$add->[$_]}++ || ref $add->[$_+1]) && push @keep, $add->[$_]
			for $start .. $#$add;
		last if $start;
	}
	my $ret= $known? \@keep : $self->exporter_autoload_tag($tagname);
	$EXPORT_TAGS_PKG_CACHE{$class}{$tagname}= $ret unless $dynamic;
	return $ret;
}

sub exporter_get_tag {
	my ($self, $tagname)= @_;
	my $class= ref($self)||$self;
	# Make the common case fast
	my $list= $EXPORT_TAGS_PKG_CACHE{$class}{$tagname};
	$list= $self->_exporter_build_tag_cache($tagname)
		unless $list or exists $EXPORT_TAGS_PKG_CACHE{$class}{$tagname};
	return $list;
}

sub _exporter_is_excluded {
	my ($self, $symbol)= @_;
	return unless ref $self && (my $not= $self->{not});
	# N^2 exclusion iteration isn't cool, but doing something smarter requires a
	# lot more setup that probably won't pay off for the usual tiny lists of 'not'.
	for my $filter (ref $not eq 'ARRAY'? @$not : ($not)) {
		if (!ref $filter) {
			return 1 if $symbol eq $filter;
		}
		elsif (ref $filter eq 'Regexp') {
			return 1 if $symbol =~ $filter;
		}
		elsif (ref $filter eq 'CODE') {
			&$filter && return 1 for $symbol;
		}
		else { $croak->("Unhandled 'not' filter: $filter") }
	}
	return;
}

sub exporter_autoload_tag {
	my ($self, $tagname)= @_;
	return;
}

sub exporter_also_import {
	my $self= shift;
	ref $self && $self->{todo} or $croak->('exporter_also_import can only be called on $self during an import()');
	push @{$self->{todo}}, @_;
}

my %method_attrs;
sub FETCH_CODE_ATTRIBUTES {
	my ($class, $coderef)= (shift, shift);
	my $super= $class->next::can;
	return @{$method_attrs{$class}{$coderef} || []},
		($super? $super->($class, $coderef, @_) : ());
}
sub MODIFY_CODE_ATTRIBUTES {
	my ($class, $coderef)= (shift, shift);
	my @unknown= grep !$class->_exporter_process_attribute($coderef, $_), @_;
	my $super= $class->next::can;
	return $super? $super->($class, $coderef, @unknown) : @unknown;
}

sub _exporter_get_coderef_name {
	# Sub::Identify has an XS version that we take advantage of if available
	my $impl= (eval 'require Sub::Identify;1')? sub {
			&Sub::Identify::sub_name
				or $croak->("Can't determine export name of $_[0]");
		}
		: do {
			require B;
			sub {
				my $cv= &B::svref_2object;
				$cv->isa('B::CV') && !$cv->GV->isa('B::SPECIAL') && $cv->GV->NAME
					or $croak->("Can't determine export name of $_[0]");
			};
		};
	*_exporter_get_coderef_name= $impl;
	$impl->(shift);
}

sub _exporter_get_ref_to_package_var {
	my ($class, $sigil, $name)= @_;
	unless (defined $name) {
		($sigil, $name)= ($_[1] =~ /^([\$\@\%\*\&]?)(\w+)$/)
			or $croak->("'$_[1]' is not an allowed variable name");
	}
	my $reftype= $sigil_to_reftype{$sigil};
	return undef unless ${$class.'::'}{$name};
	return $reftype eq 'GLOB'? \*{$class.'::'.$name} : *{$class.'::'.$name}{$reftype};
}

sub _exporter_process_attribute {
	my ($class, $coderef, $attr)= @_;
	if ($attr =~ /^Export(?:\(\s*(.*?)\s*\))?$/) {
		my (%tags, $subname, @export_names);
		# If given a list in parenthesees, split on space and proces each.  Else use the name of the sub itself.
		for my $token ($1? split(/\s+/, $1) : ()) {
			if ($token =~ /^:(.*)$/) {
				$tags{$1}++; # save tags until we have the export_names
			}
			elsif ($token =~ /^\w+$/) {
				push @export_names, $token;
				${$class.'::EXPORT'}{$token}= $coderef;
			}
			elsif ($token =~ /^-(\w*)(?:\(([0-9]+|\*|\?)\))?$/) {
				$subname ||= _exporter_get_coderef_name($coderef);
				push @export_names, length $1? $token : "-$subname";
				$class->exporter_register_option(substr($export_names[-1],1), $subname, $2);
			}
			elsif (my($sym, $name)= ($token =~ /^=([\&\$\@\%\*:]?(\w*))$/)) {
				$subname ||= _exporter_get_coderef_name($coderef);
				my $export_name= length $name? $sym : do {
					(my $x= $subname) =~ s/^_generate[A-Za-z]*_//;
					$sym . $x
				};
				$export_name =~ s/^[&]//;
				$class->exporter_register_generator($export_name, $subname);
				push @export_names, $export_name;
			}
			else {
				$croak->("Invalid export notation '$token'");
			}
		}
		if (!@export_names) { # if list was empty or only tags...
			push @export_names, _exporter_get_coderef_name($coderef);
			${$class.'::EXPORT'}{$export_names[-1]}= $coderef;
		}
		$class->exporter_register_tag_members($_, @export_names) for keys %tags;
		return 1;
	}
	return;
}

sub exporter_setup {
	my ($self, $version)= @_;
	push @{$self->{into}.'::ISA'}, ref($self);
	strict->import;
	warnings->import;
	if ($version == 1) {
		# Declare 'our %EXPORT'
		*{$self->{into}.'::EXPORT'}= \%{$self->{into}.'::EXPORT'};
		# Make @EXPORT and $EXPORT_TAGS{default} be the same arrayref.
		# Allow either one to have been declared already.
		my $tags= \%{$self->{into}.'::EXPORT_TAGS'};
		*{$self->{into}.'::EXPORT'}= $tags->{default}
			if ref $tags->{default} eq 'ARRAY';
		$tags->{default} ||= \@{$self->{into}.'::EXPORT'};
		# Export the 'export' function.
		*{$self->{into}.'::export'}= \&_exporter_export_from_caller;
	}
	elsif ($version) {
		$croak->("Unknown export API version $version");
	}
}

sub _exporter_export_from_caller {
	unshift @_, scalar caller;
	goto $_[0]->can('exporter_export');
}
sub exporter_export {
	my $class= shift;
	my ($export, $is_gen, $sigil, $name, $args, $ref);
	arg_loop: for (my $i= 0; $i < @_;) {
		$export= $_[$i++];
		ref $export and $croak->("Expected non-ref export name at argument $i");
		# If they provided the ref, capture it from arg list.
		$ref= ref $_[$i]? $_[$i++] : undef;
		# Common case first - ordinary functions
		if ($export =~ /^\w+$/) {
			if ($ref) {
				ref $ref eq 'CODE' or $croak->("Expected CODEref following '$export'");
			} else {
				$ref= $class->can($export) or $croak->("Export '$export' not found in $class");
			}
			${$class.'::EXPORT'}{$export}= $ref;
		}
		# Next, check for generators
		elsif (($is_gen, $sigil, $name)= ($export =~ /^(=?)([\$\@\%\*]?)(\w+)$/)) {
			if ($is_gen) {
				if ($ref) {
					# special case, remove ref on method name (since it isn't possible to pass
					# a plain scalar as the second asrgument)
					$ref= $$ref if ref $ref eq 'SCALAR';
					$class->exporter_register_generator($sigil.$name, $ref);
				} else {
					for (@{ $sigil_to_generator_prefix{$sigil} }) {
						my $method= $_ . $name;
						if ($class->can($method)) {
							$class->exporter_register_generator($sigil.$name, $method);
							next arg_loop;
						}
					}
					$croak->("Export '$export' not found in package $class, nor a generator $sigil_to_generator_prefix{$sigil}[0]");
				}
			}
			else {
				$ref ||= $class->_exporter_get_ref_to_package_var($sigil, $name);
				ref $ref eq $sigil_to_reftype{$sigil} or (ref $ref eq 'REF' && $sigil eq '$')
					or $croak->("'$export' should be $sigil_to_reftype{$sigil} but you supplied ".ref($ref));
				${$class.'::EXPORT'}{$sigil.$name}= $ref;
			}
		}
		# Tags ":foo"
		elsif (($is_gen, $name)= ($export =~ /^(=?):(\w+)$/)) {
			if ($is_gen && !$ref) {
				my $gen= $sigil_to_generator_prefix{':'}.$name;
				$class->can($gen)
					or $croak->("Can't find generator for tag $name : '$gen'");
				$ref= $gen;
			}
			ref $ref eq 'ARRAY'? $class->exporter_register_tag_members($name, @$ref)
				: $class->exporter_register_generator($export, $ref);
		}
		# Options "-foo" or "-foo(3)"
		elsif (($name, $args)= ($export =~ /^-(\w+)(?:\(([0-9]+|\*|\?)\))?$/)) {
			if ($ref) {
				ref $ref eq 'CODE' or (ref $ref eq 'SCALAR' and $class->can($ref= $$ref))
					or $croak->("Option '$export' must be followed by coderef or method name as scalar ref");
			} else {
				$class->can($name)
					or $croak->("Option '$export' defaults to a method '$name' which does not exist on $class");
				$ref= $name;
			}
			$class->exporter_register_option($name, $ref, $args);
		}
		else {
			$croak->("'$export' is not a valid export syntax");
		}
	}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Exporter::Extensible - Create easy-to-extend modules which export symbols

=head1 SYNOPSIS

Define a module with exports

  package My::Utils;
  use Exporter::Extensible -exporter_setup => 1;

  export(qw( foo $x @STUFF -strict_and_warnings ), ':baz' => ['foo'] );

  sub foo { ... }

  sub strict_and_warnings {
    strict->import;
    warnings->import;
  }

Create a new module which exports all that, and more

  package My::MoreUtils;
  use My::Utils -exporter_setup => 1;
  sub util_fn3 : Export(:baz) { ... }

Use the module

  use My::MoreUtils qw( -strict_and_warnings :baz @STUFF );
  # Use the exported things
  push @STUFF, foo(), util_fn3();

=head1 DESCRIPTION

As a module author, you have dozens of exporters to choose from, so I'll try to get straight to
the pros/cons of this module:

=head2 Pros

=over

=item Extend Your Module

This exporter focuses on the ability and ease of letting you "subclass" a module-with-exports to
create a derived module-with-exports.  It supports multiple inheritance, for things like tying
together all your utility modules into a mega-utility module.

=item Extend Behavior of C<import>

This exporter supports lots of ways to add custom processing during 'import' without needing to
dig into the implementation.

=item More than just subs

This module supports exporting C<foo>, C<$foo>, C<@foo>, C<%foo>, or even C<*foo>.  It also
supports tags (C<:foo>) and options (C<-foo>).

=item Be Lazy

This exporter supports on-demand generators for symbols, as well as tags!  So if you have a
complicated or expensive list of exports you can wait until the first time each is requested
before finding out whether it is available or loading the dependent module.

=item Full-featured

This exporter attempts to copy useful features from other popular exporters, like renaming
imports with C<-prefix>/C<-suffix>/C<-as>, excluding symbols with C<-not>, scoped-unimport,
passing options to generators, importing to things other than C<caller>, etc.

=item More-Than-One-Way-To-Declare-Exports

Pick your favorite.  You can use the L<export> do-what-I-mean function, method attributes, the
C<< __PACKAGE__->exporter_ ... >> API, or declare package variables similar to L<Exporter>.

=item No Non-core Dependencies (for Perl E<8805> 5.12)

Because nobody likes big dependency trees.

=item Speed

The features are written so you only pay for what you use, with emphasis on "make the common
case fast".  Benchmarking is difficult since there are so many patterns to compare, but in
general, this module is significantly faster than Sub::Exporter, faster than Exporter::Tiny for
medium or large export workload, and even beats Exporter itself for large sets of exported subs.

=back

=head2 Cons

=over

=item Imposes meaning on hashrefs in import list

If the first argument to C<import> is a hashref, it is used as configuration of C<import>.
Hashref arguments following a symbol name are treated as arguments to the generator (if any)
or config overides for a tag.  (but you can control hashref processing on your own for C<-NAME>
in the API you are authoring).

=item Imposes meaning for notation C<-NAME>

This module follows the L<Exporter> convention for symbol names but with the additional
convention that names beginning with dash C<-> are treated as requests for runtime behavior.
Additionally, it may consume the arguments that follow it, at the discresion of the module
author.  This feature is designed to feel like command-line option processing.

=item Inheritance and Namespace pollution

This module uses the package hierarchy for combining exportable sets of things.
It also defines lots of methods starting with the prefix C<exporter_>.
It also calls C<< __PACKAGE__->new >> every time a user imports something.
If you want to make an object-oriented class but also export a few symbols, you need to use
a second namespace like C<My::Class::Exports> instead of C<My::Class> and then delegate to
its L</import_into> method.

    package My::Class;
    package My::Class::Exports {
      use Exporter::Extensible -exporter_setup => 1;
      ...
    }
    sub import { My::Class::Exports->import_into(scalar caller, @_) }

=back

=head1 IMPORT API (for consumer)

=head2 import

This is the method that gets called when you C<use DerivedModule @list>.

The user-facing API is mostly the same as L<Sub::Exporter> or L<Exporter::Tiny>, except that C<-tag>
is not an alias for C<:tag>.

The elements of C<@list> are handled according to the following patterns:

=head3 Plain Name With Sigil

  use DerivedModule 'name', '$name', '@name', '%name', '*name', ':name';

Same as L<Exporter>, except it might be generated on the fly, and can be followed by an
options hashref for further control over how it gets imported.  (see L</In-line Options>)

=head3 Option

  use DerivedModule -name, ...;

Run custom processing defined by module author, possibly consuming arguments that follow it.

=head3 Global Options

  use DerivedModule { ... }, ...;

If the first argument to C<import> is a hashref, these fields are recognized:

=over

=item into

Package name or hashref to which all symbols will be exported.  Defaults to C<caller>.

=item scope

Empty scalar-ref whose scope determines when to unimport the things just imported.
After a successful import, this will be assigned a scope-guard object whose destructor
un-imports those same symbols.  This saves you the hassle of calling C<< no MyModule @args >>.
You can also call C<< $scope->clean >> to trigger the unimport in a more direct manner.
If you need the methods cleaned out at the end of compilation (i.e. before execution)
you can wrap C<clean> in a C<BEGIN> block.

  {
    use MyModule { scope => \my $scope }, ':sugar_methods';
	# use sugar methods
	...
	# you could "BEGIN { $scope->clean }" if you want them removed sooner
  }
  # All those symbols are now neatly removed from your package

This also works well when combined with C<< use B::Hooks::EndOfScope 'on_scope_end' >>.
(I would have added a stronger integration with B::Hooks::EndOfScope but I didn't want to
depend on an XS module)

=item not

Only applies to tags.  Can be a scalar, regex, coderef, or list of any of those that filters
out un-wanted imports.

  use MyModule ':foo' => { -not => 'log' };
  use MyModule ':foo' => { -not => qr/^log/ };
  use MyModule ':foo' => { -not => sub { $forbidden{$_} } };
  use MyModule ':foo' => { -not => [ 'log', qr/^log/, sub { ... } ] };

=item no

If true, then the list of symbols will be uninstalled from the C<into> package.
For example, C<< no MyModule @args >> is the same as
C<< MyModule->import({ no => 1 }, @args) >>

=item replace

Determines what to do if the symbol already exists in the target package:

=over

=item C<1>

Replace the symbol with no warning.

=item C<'warn'> (or C<'carp'>)

Replace the symbol but warn about it using C<carp>.

=item C<'die'> (or C<'fatal'> or C<'croak'>)

Don't import the symbol, and die by calling C<croak>.

=item C<'skip'>

Don't import the symbol and don't warn about it.

=back

=item installer

A coderef which will be called instead of L</exporter_install> or L</export_uninstall>.
Uses the same arguments:

  installer => sub {
	my ($exporter, $list)= @_;
	for (my $i= 0; $i < @$list; $i+= 2) {
		my ($name, $ref)= @{$list}[$i..1+$i];
		...
  }

=item prefix (or -prefix)

Prefix all imported names with this string.

=item suffix (or -suffix)

Append this string to all imported names.

=back

=head3 In-line Options

  use DerivedModule ':name' => { ... };

The arguments to C<import> are generally plain strings.  If one is followed by a hashref,
the hashref becomes the argument to the generator (if any), but may also contain:

=over

=item -as => $name

Install the thing as this exact name. (no sigil, but relative to C<into>)

=item -prefix

Same as global option C<prefix>, limited to this one symbol/tag.

=item -suffix

Same as global option C<suffix>, limited to this one symbol/tag.

=item -not

Same as global option C<not>, limited to this one tag.

=item -replace

Same as global option C<replace>, limited to this one tag.

=back

=head2 import_into

  DerivedModule->import_into('DestinationPackage', @list);

This is a shorthand for

  DerivedModule->import({ into => 'DestinationPackage }, @list);

There is also a more generic way to handle this underlying need though - see L<Import::Into>

=head1 EXPORT API (for author)

The underlying requirements for using this exporter are to inherit from it, and declare your
exports in the variables C<%EXPORT> and C<%EXPORT_TAGS>.  The quickest way to do that is:

  package My::Module;
  use Exporter::Extensible -exporter_setup => 1;
  export(...);

Those lines are shorthand for:

  package My::Module;
  use strict;
  use warnings;
  use parent 'Exporter::Extensible';
  our (@EXPORT, %EXPORT, %EXPORT_TAGS);
  $EXPORT_TAGS{default} ||= \@EXPORT;
  $EXPORT{...}= ...; # for each argument to export()

Everything else below is just convenience and shorthand to make this easier.

=head2 Export by API

This module provides an api for specifying the exports.  You can call these methods on
C<__PACKAGE__>, or if you ask for version-1 as C<< -export_setup => 1 >> you can use the
convenience function L</export>.

=head3 export

C<< export(@list) >> is a convenient alias for C<< __PACKAGE__->exporter_export(@list); >>
which you receive from C<-exporter_setup>.

=head3 exporter_export

  __PACKAGE__->exporter_export(@things);
  __PACKAGE__->exporter_export(qw( $foo bar ), ':baz' => \@tag_members, ... );

This class method takes a list of keys (which must be scalars), with optional values which must be
refs.  If the value is omitted, C<export> attempts to do-what-you-mean to find it.

=over

=item C<< foo => \&CODE >>

This declares a normal exported function.  If the ref is omitted, C<export> looks for it in
the the current package.  Note that this lookup happens immediately, so derived packages that
want to override C<foo> must re-declare it.

=item C<< '$foo' => \$SCALAR >>, C<< '@foo' => \@ARRAY >>, C<< '%foo' => \%HASH >>, C<< '*foo' => \*GLOB >>

This exports a normal variable or typeglob.  If the ref is omitted, C<export> looks for it
in the current package. Note: this exports a B<global variable which can be modified>.
In general, that's bad practice, but might be desired for efficiency.  If your goal is
efficient access to a singleton object, consider a generator instead like C<=$foo>.

=item C<< -foo => $CODEREF >> or C<< -foo => \"methodname" >>

This differs from a normal exported function in that it will execute the coderef at import time,
and sub-packages B<can> override it, since it gets called as a method.  The default is to derive
the method name by removing the C<->.

=item C<< ':foo' => \@LIST >>

Declaring a tag is nothing special; just give it an arrayref of what should be imported when
the tag is encountered.

=item C<< '=$foo' => $CODEREF >> or C<< '=$foo' => \"methodname" >>

Prefixing an export name with an equal sign means you want to generate the export on the fly.
The ref is understood to be the coderef or method name to call (as a method) which will return
the ref of the correct type to be exported.  The default is to look for C<_generate_foo>,
C<_generateSCALAR_foo>, C<_generateARRAY_foo>, C<_generateHASH_foo>, etc.

=back

=head3 exporter_register_symbol

  __PACKAGE__->exporter_register_symbol($name_with_sigil, $ref);

=head3 exporter_register_option

  __PACKAGE__->exporter_register_option($name, $method, $arg_count);

This declares an "option" like C<-foo>.  The name should B<not> include the leading C<->.
The C<$method> argument can either be a package method name, or a coderef.  The C<$arg_count>
is the number of options to consume from the C<import(...)> list following the option.

To declare an option that consumes a variable number of arguments, specify C<*> for the count
and then write your method so that it returns the number of arguments it consumed.

=head3 exporter_register_generator

  __PACKAGE__->exporter_register_generator($name_with_sigil, $method);

This declares that you want to generate C<$name_with_sigil> on demand, using C<$method>.
C<$name_with_sigil> may be a tag like C<':foo'>.
C<$method> can be either a coderef or method name.  The function will be called as a method
on an instance of your package.  The instance is the blessed hash of options passed by the
current consumer of your module.

=head3 exporter_register_tag_members

  __PACKAGE__->exporter_register_tag_members($tag_name, @members);

This pushes a list of C<@members> onto the end of the named tag.  C<$tag_name> should not
include the leading ':'.  These C<@members> are cumulative with tags inherited from parent
packages.  To avoid inheriting tag members, register a generator for the tag, instead.

=head2 Export by Attribute

Attributes are fun.  If you enjoy artistic code, you might like to declare your exports like so:

  sub foo : Export( :foo ) {}
  sub bar : Export(-) {}
  sub _generate_baz : Export(= :foo) {}

instead of

  export( 'foo', '-bar', '=baz', ':foo' => [ 'foo','baz' ] );

The notations supported in the C<Export> attribute are different but similar to those in the
L</export> function.  You may include one or more of the following in the parenthesees:

=over

=item C<< foo >>

This indicates the export-name of a sub.  A sub may be exported as more than one name.
Note that the first name in the list becomes the official name (ignoring the actual name of
the sub) which will be added to any tags you listed.

=item C<< :foo >>

This requests that the export-name get added to the named tag.  You may specify any number of
tags.

=item C<< - >>, C<< -(N) >>, C<< -foo >>, C<< -foo(N) >>

This sets up the sub as an option, capturing N arguments.  In the cases without a name, the
name of the sub is used.  N may be C<'*'> or C<'?'>; see L</IMPLEMENTING OPTIONS>.

=item C<< = >>, C<< =$ >>, C<< =@ >>, C<< =% >>, C<< =* >>, C<< =foo >>, C<< =$foo >>, ...

This sets up the sub as a generator for the export-name.  If the word portion of the name is
omitted, it is taken to be the sub name minus the prefix C<_generate_> or C<_generate$REFTYPE_>.
See L</IMPLEMENTING GENERATORS>.

=back

=head2 Export by Variables

As shown above, the configuration for your exports is the variable C<%EXPORT>.
If you want the fastest possible module load time, you might decide to
populate C<%EXPORT> manually.

The keys of this hash are the strings that the user would specify as the C<import> arguments,
like C<'-foo'>, C<'$foo'>, etc.  The value should be some kind of reference matching the sigil.
Functions should be a coderef, scalars should be a scalarref, etc.  But, there are two special
cases:

=over

=item Options

An option is any key starting with C<->, like this module's own C<-exporter_setup>.  The values
for these must be a pair of C<< [ $method_name, $arg_count_or_star ] >>.  (the default
structure is subject to change, but this notation will always be supported)

  { '-exporter_setup' => [ "exporter_setup", 1 ] }

This means "call C<< $self->exporter_setup($arg1) >> when you see
C<< import('-exporter_setup', $arg1, ... ) >>.
Because it is a method call, subclasses of your module can override it.

=item Generators

Sometimes you want to generate the thing to be exported.  To indicate this, use a ref-ref of
the method name, or a ref of the coderef to execute.  For example:

  {
    foo => "_generate_foo",
    bar => \\&generate_bar,
    baz => \sub { ... },
  }

Again, this is subject to change, but these notations will always be supported for
backward-compatibility.

=back

Meanwhile the C<%EXPORT_TAGS> variable is almost identical to the one used by L<Exporter>, but
with a few enhancements:

=over

=item C<:all>

You don't need to declare the tag C<all>, because this module calculates it for you, from the
list of all keys of C<%EXPORT> excluding tags or options.  You can override this default though.

=item C<:default>

C<@EXPORT> is added to C<%EXPORT_TAGS> as C<'default'>.  So, you can push items into C<@EXPORT>
or into C<@{$EXPORT_TAGS{default}}> and it is the same arrayref.

=item Resetting the Tag Members

If the first element of the arrayref is C<undef>, it means "don't inherit the tag
members from the parent class".

  # Don't want to inherit members of ':foo' from parent:
  foo => [ undef, 'x', 'y', 'z' ]

=item Data in a Tag

The elements of a tag can include parameters to generators, or arguments to an option, etc;
anything that could be passed to C<import> will work as expected.

  foo => [ 'x', 'y', -init => [1,2,3] ],

=item Generators

If the value in C<%EXPORT_TAGS> is not an arrayref, then it should be a REF-ref of either the
scalar name of a generator, or a coderef of the generator.

  foo => \\"_generate_foo",

=back

=head1 IMPLEMENTING OPTIONS

Exporter::Extensible lets you run whatever code you like when it encounters "-name" in the
import list.  To accommodate all the different ways I wanted to use this, I decided to let the
option decide how many arguments to consume.  So, the API is as follows:

  # By default, no arguments are captured.  A ref may not follow this option.
  sub name : Export( -name ) {
    my $exporter= shift;
    ...
  }

  # Ask for three arguments (regardless of whether they are refs)
  sub name : Export( -name(3) ) {
    my ($exporter, $arg1, $arg2, $arg3)= @_;
    ...
  }

  # Ask for one argument but only if it is a ref of some kind.
  # If it is a hashref, this also processes import options like -prefix, -replace, etc.
  sub name : Export( -name(?) ) {
    my ($exporter, $maybe_arg)= @_;
    ...
  }

  # Might need any number of arguments.  Return the number we consumed.
  sub name : Export( -name(*) ) {
    my $exporter = shift;
    while (@_) {
      last if ...;
      ...
      ++$consumed;
    }
    return $consumed;
  }

The first argument C<$exporter> is a instance of the exporting package, and you can inspect it
or even reconfigure it.  For instance, if you want your option to automatically select some
symbols as if they had been passed to L</import>, you could call L</exporter_also_import>.

=head2 exporter_also_import

This method can be used *during* a call to C<import> for an option or generator to request that
aditional things be imported into the caller as if the caller had requested them on the import
line.  For example:

  sub foo : Export(-) {
    shift->exporter_also_import(':all');
  }

This causes the option C<-foo> to be equivalent to the tag C<':all'>;

=head1 IMPLEMENTING GENERATORS

A generator is just a function that returns the thing to be imported.  A generator is called as:

  $exporter->$generator($symbol, $args);

where C<$exporter> is an instance of your package, C<$symbol> is the name of the thing
as specified to C<import> (with sigil) and C<$args> is the optional hashref the user might have
given following C<$symbol>.

If you wanted to implement something like L<Sub::Exporter>'s "Collectors", you can just write
some options that take an argument and store it in the C<$exporter> instance.  Then, your
generator can retrieve the values from there.

  package MyExports;
  use Exporter::Extensible -exporter_setup => 1;
  export(
    # be sure to use hash keys that won't conflict with Exporter::Extensible's internals
    '-foo(1)' => sub { $_[0]{foo}= $_[1] },
    '-bar(1)' => sub { $_[0]{bar}= $_[1] },
    '=foobar' => sub { my $foobar= $_[0]{foo} . $_[0]{bar}; sub { $foobar } },
  );

  package User;
  use MyModule qw/ -foo abc -bar def foobar -foo xyz foobar /, { -as => "x" };
  # This exports a sub as "foobar" which returns "abcdef", and a sub as "x" which
  # returns "xyzdef".  Note that if the second one didn't specify {-as => "x"},
  # it would get ignored because 'foobar' was already queued to be installed.

=head1 AUTOLOADING SYMBOLS AND TAGS

In the same spirit that Perl lets you AUTOLOAD methods on demand, this exporter lets you define
symbols and tags on demand.  Simply override one of these methods:

=head2 exporter_autoload_symbol

  my $ref= $self->exporter_autoload_symbol($sym);

This takes a symbol (including sigil), and returns a ref which should be installed.  The ref
is cached, but B<not> added to the package C<%EXPORT> to be inherited by subclasses.  If you
want that to happen, you need to do it yourself.  This method is called once at the end of
checking the package hierarchy, rather than per-class of the hierarchy, so you should call
C<next::method> if you don't recognize the symbol.

=head2 exporter_autoload_tag

  my $arrayref= $self->exporter_autoload_tag($name);

This takes a tag name (no sigil) and returns an arrayref of items which should be added to the
tag.  The combined tag members are cached, but not added to the package C<%EXPORT_TAGS> to be
inherited by subclasses.  This method is called only if no package in the hierarchy defined the
tag, which could cause confusion if a derived class wants to add a few symbols to a tag which
is otherwise autoloaded by a parent.  This method is called once at the end of iterating the
package hierarchy, so you should call C<next::method> to collect any inherited autoloaded
members of this tag.

=head1 SEE ALSO

=over

=item L<Exporter::Almighty>

=item L<Exporter::Tiny>

=item L<Sub::Exporter>

=item L<Export::Declare>

=item L<Badger::Exporter>

=back

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 CONTRIBUTOR

=for stopwords Tabulo

Tabulo <dev-git.perl@tabulo.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
