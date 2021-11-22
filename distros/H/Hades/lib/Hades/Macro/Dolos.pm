package Hades::Macro::Dolos;
use strict;
use warnings;
use base qw/Hades::Macro/;
our $VERSION = 0.21;

sub new {
	my ( $cls, %args ) = ( shift(), scalar @_ == 1 ? %{ $_[0] } : @_ );
	my $self      = $cls->SUPER::new(%args);
	my %accessors = (
		macro => {
			default => [
				qw/
				    autoload_cb
				    caller
				    clear_unless_keys
				    call_sub
				    call_sub_my
				    delete
				    die_unless_keys
				    else
				    elsif
				    export
				    for
				    foreach
				    for_keys
				    for_key_exists_and_return
				    grep
				    grep_map
				    if
				    map
				    map_grep
				    maybe
				    merge_hash_refs
				    require
				    unless
				    while
				    /
			],
		},
	);
	for my $accessor ( keys %accessors ) {
		my $param
		    = defined $args{$accessor}
		    ? $args{$accessor}
		    : $accessors{$accessor}->{default};
		my $value
		    = $self->$accessor( $accessors{$accessor}->{builder}
			? $accessors{$accessor}->{builder}->( $self, $param )
			: $param );
		unless ( !$accessors{$accessor}->{required} || defined $value ) {
			die "$accessor accessor is required";
		}
	}
	return $self;
}

sub macro {
	my ( $self, $value ) = @_;
	if ( defined $value ) {
		if ( ( ref($value) || "" ) ne "ARRAY" ) {
			die qq{ArrayRef: invalid value $value for accessor macro};
		}
		$self->{macro} = $value;
	}
	return $self->{macro};
}

sub autoload_cb {
	my ( $self, $mg, $cb ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method autoload_cb};
	}
	if ( !defined($cb) || ref $cb ) {
		$cb = defined $cb ? $cb : 'undef';
		die
		    qq{Str: invalid value $cb for variable \$cb in method autoload_cb};
	}

	return qq|
			my (\$cls, \$vn) = (ref \$_[0], q{[^:'[:cntrl:]]{0,1024}});
			our \$AUTOLOAD =~ /^\${cls}::(\$vn)\$/;
                	return ${cb}(\$1) if \$1; 
		|;

}

sub caller {
	my ( $self, $mg, $variable ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die qq{Object: invalid value $mg for variable \$mg in method caller};
	}
	$variable = defined $variable ? $variable : q|$caller|;
	if ( !defined($variable) || ref $variable ) {
		$variable = defined $variable ? $variable : 'undef';
		die
		    qq{Str: invalid value $variable for variable \$variable in method caller};
	}

	return qq|my $variable = caller();|;

}

sub clear_unless_keys {
	my ( $self, $mg, $variable, $hash ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method clear_unless_keys};
	}
	if ( !defined($variable) || ref $variable ) {
		$variable = defined $variable ? $variable : 'undef';
		die
		    qq{Str: invalid value $variable for variable \$variable in method clear_unless_keys};
	}
	if ( !defined($hash) || ref $hash ) {
		$hash = defined $hash ? $hash : 'undef';
		die
		    qq{Str: invalid value $hash for variable \$hash in method clear_unless_keys};
	}

	return
	    qq|$variable = undef if (! ref $hash \|\| ! scalar keys \%{$hash});|;

}

sub call_sub {
	my ( $self, $mg, $sub, @params ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method call_sub};
	}

	my $p = join ", ", @params;
	return qq|${sub}($p);|;

}

sub call_sub_my {
	my ( $self, $mg, $my, $sub, @params ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method call_sub_my};
	}
	if ( !defined($my) || ref $my ) {
		$my = defined $my ? $my : 'undef';
		die
		    qq{Str: invalid value $my for variable \$my in method call_sub_my};
	}

	my $p = join ", ", @params;
	return qq|my (${my}) = ${sub}($p);|;

}

sub delete {
	my ( $self, $mg, $hash, $key, $variable, $or, $list ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die qq{Object: invalid value $mg for variable \$mg in method delete};
	}
	if ( !defined($hash) || ref $hash ) {
		$hash = defined $hash ? $hash : 'undef';
		die qq{Str: invalid value $hash for variable \$hash in method delete};
	}
	if ( !defined($key) || ref $key ) {
		$key = defined $key ? $key : 'undef';
		die qq{Str: invalid value $key for variable \$key in method delete};
	}
	if ( defined $variable ) {
		if ( ref $variable ) {
			die
			    qq{Optional[Str]: invalid value $variable for variable \$variable in method delete};
		}
	}
	if ( defined $or ) {
		if ( ref $or ) {
			die
			    qq{Optional[Str]: invalid value $or for variable \$or in method delete};
		}
	}
	if ( defined $list ) {
		my $ref = ref $list;
		if (   ( $ref || 'SCALAR' ) ne 'SCALAR'
			|| ( $ref ? $$list : $list ) !~ m/^(1|0)$/ )
		{
			die
			    qq{Optional[Bool]: invalid value $list for variable \$list in method delete};
		}
		$list = !!( $ref ? $$list : $list ) ? 1 : 0;
	}

	my $code = q||;
	$code .= qq|$variable = | if $variable;
	$code .= qq|delete $hash\->{$key}|;
	$code .= qq| \|\| $or| if $or;
	$code .= $list ? q|,| : qq|;|;
	return $code;

}

sub die_unless_keys {
	my ( $self, $mg, $hash, $error ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method die_unless_keys};
	}
	if ( !defined($hash) || ref $hash ) {
		$hash = defined $hash ? $hash : 'undef';
		die
		    qq{Str: invalid value $hash for variable \$hash in method die_unless_keys};
	}
	$error = defined $error ? $error : "hash is empty";
	if ( !defined($error) || ref $error ) {
		$error = defined $error ? $error : 'undef';
		die
		    qq{Str: invalid value $error for variable \$error in method die_unless_keys};
	}

	return qq|die "$error" if (! ref $hash \|\| ! scalar keys \%{$hash});|;

}

sub else {
	my ( $self, $mg, @code ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die qq{Object: invalid value $mg for variable \$mg in method else};
	}

	my $c = join "\n", @code;
	return qq|else { $c }|;

}

sub elsif {
	my ( $self, $mg, $condition, @code ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die qq{Object: invalid value $mg for variable \$mg in method elsif};
	}
	if ( !defined($condition) || ref $condition ) {
		$condition = defined $condition ? $condition : 'undef';
		die
		    qq{Str: invalid value $condition for variable \$condition in method elsif};
	}

	my $c = join "\n", @code;
	return qq|elsif ($condition) { $c }|;

}

sub export {
	my ( $self, $mg, $method, $code, $no_warnings, $caller ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die qq{Object: invalid value $mg for variable \$mg in method export};
	}
	if ( !defined($method) || ref $method ) {
		$method = defined $method ? $method : 'undef';
		die
		    qq{Str: invalid value $method for variable \$method in method export};
	}
	if ( !defined($code) || ref $code ) {
		$code = defined $code ? $code : 'undef';
		die qq{Str: invalid value $code for variable \$code in method export};
	}
	$no_warnings = defined $no_warnings ? $no_warnings : 1;
	if (  !defined($no_warnings)
		|| ref $no_warnings
		|| $no_warnings !~ m/^[-+\d]\d*$/ )
	{
		$no_warnings = defined $no_warnings ? $no_warnings : 'undef';
		die
		    qq{Int: invalid value $no_warnings for variable \$no_warnings in method export};
	}
	$caller = defined $caller ? $caller : '$caller';
	if ( !defined($caller) || ref $caller ) {
		$caller = defined $caller ? $caller : 'undef';
		die
		    qq{Str: invalid value $caller for variable \$caller in method export};
	}

	my $c
	    = $no_warnings
	    ? qq|no strict "refs"; no warnings "redefine";|
	    : q||;
	$caller =~ s/\$([^: ]+)/\${$1}/g;
	$method =~ s/\$([^: ]+)/\${$1}/g;
	return $c . qq|*{ "${caller}::${method}" } = sub { $code };|;

}

sub for {
	my ( $self, $mg, $condition, @code ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die qq{Object: invalid value $mg for variable \$mg in method for};
	}
	if ( !defined($condition) || ref $condition ) {
		$condition = defined $condition ? $condition : 'undef';
		die
		    qq{Str: invalid value $condition for variable \$condition in method for};
	}

	my $c = join "\n", @code;
	return qq|for ($condition) { $c }|;

}

sub foreach {
	my ( $self, $mg, $condition, @code ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die qq{Object: invalid value $mg for variable \$mg in method foreach};
	}
	if ( !defined($condition) || ref $condition ) {
		$condition = defined $condition ? $condition : 'undef';
		die
		    qq{Str: invalid value $condition for variable \$condition in method foreach};
	}

	my $c = join "\n", @code;
	return qq|foreach ($condition) { $c }|;

}

sub for_keys {
	my ( $self, $mg, $hash, $key, @code ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method for_keys};
	}
	if ( !defined($hash) || ref $hash ) {
		$hash = defined $hash ? $hash : 'undef';
		die
		    qq{Str: invalid value $hash for variable \$hash in method for_keys};
	}
	$key = defined $key ? $key : $key;
	if ( !defined($key) || ref $key ) {
		$key = defined $key ? $key : 'undef';
		die qq{Str: invalid value $key for variable \$key in method for_keys};
	}

	$hash =~ s/^\$([^\(\{\-\:\ ]+)$/\%{\$$1}/;
	my $c = join "\n", @code;
	return qq|for my $key (keys $hash) { $c }|;

}

sub for_key_exists_and_return {
	my ( $self, $mg, $hash, $for ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method for_key_exists_and_return};
	}
	if ( !defined($hash) || ref $hash ) {
		$hash = defined $hash ? $hash : 'undef';
		die
		    qq{Str: invalid value $hash for variable \$hash in method for_key_exists_and_return};
	}
	if ( !defined($for) || ref $for ) {
		$for = defined $for ? $for : 'undef';
		die
		    qq{Str: invalid value $for for variable \$for in method for_key_exists_and_return};
	}

	return qq|\$_ && exists ${hash}->{\$_} and return ${hash}->{\$_}
			for ($for);|;

}

sub grep {
	my ( $self, $mg, $condition, @code ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die qq{Object: invalid value $mg for variable \$mg in method grep};
	}
	if ( !defined($condition) || ref $condition ) {
		$condition = defined $condition ? $condition : 'undef';
		die
		    qq{Str: invalid value $condition for variable \$condition in method grep};
	}

	my $c = join "\n", @code;
	return qq|grep { $c } $condition|;

}

sub grep_map {
	my ( $self, $mg, $condition, $grep_code, @map_code ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method grep_map};
	}
	if ( !defined($condition) || ref $condition ) {
		$condition = defined $condition ? $condition : 'undef';
		die
		    qq{Str: invalid value $condition for variable \$condition in method grep_map};
	}
	if ( !defined($grep_code) || ref $grep_code ) {
		$grep_code = defined $grep_code ? $grep_code : 'undef';
		die
		    qq{Str: invalid value $grep_code for variable \$grep_code in method grep_map};
	}

	my $mc = join "\n", @map_code;
	return qq|map { $mc } grep { $grep_code } $condition|;

}

sub if {
	my ( $self, $mg, $condition, @code ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die qq{Object: invalid value $mg for variable \$mg in method if};
	}
	if ( !defined($condition) || ref $condition ) {
		$condition = defined $condition ? $condition : 'undef';
		die
		    qq{Str: invalid value $condition for variable \$condition in method if};
	}

	my $c = join "\n", @code;
	return qq|if ($condition) { $c }|;

}

sub map {
	my ( $self, $mg, $condition, @code ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die qq{Object: invalid value $mg for variable \$mg in method map};
	}
	if ( !defined($condition) || ref $condition ) {
		$condition = defined $condition ? $condition : 'undef';
		die
		    qq{Str: invalid value $condition for variable \$condition in method map};
	}

	my $c = join "\n", @code;
	return qq|map { $c } $condition|;

}

sub map_grep {
	my ( $self, $mg, $condition, $grep_code, @map_code ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method map_grep};
	}
	if ( !defined($condition) || ref $condition ) {
		$condition = defined $condition ? $condition : 'undef';
		die
		    qq{Str: invalid value $condition for variable \$condition in method map_grep};
	}
	if ( !defined($grep_code) || ref $grep_code ) {
		$grep_code = defined $grep_code ? $grep_code : 'undef';
		die
		    qq{Str: invalid value $grep_code for variable \$grep_code in method map_grep};
	}

	my $mc = join "\n", @map_code;
	return qq|grep { $grep_code } map { $mc } $condition|;

}

sub maybe {
	my ( $self, $mg, $key, $variable ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die qq{Object: invalid value $mg for variable \$mg in method maybe};
	}
	if ( !defined($key) || ref $key ) {
		$key = defined $key ? $key : 'undef';
		die qq{Str: invalid value $key for variable \$key in method maybe};
	}
	if ( !defined($variable) || ref $variable ) {
		$variable = defined $variable ? $variable : 'undef';
		die
		    qq{Str: invalid value $variable for variable \$variable in method maybe};
	}

	return qq|(defined $variable ? ( $key => $variable ) : ())|;

}

sub merge_hash_refs {
	my ( $self, $mg, @hashes ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method merge_hash_refs};
	}

	my $base  = $hashes[0];
	my $merge = join ', ', map { '%{' . $_ . '}' } @hashes;
	return qq|$base = { $merge };|;

}

sub require {
	my ( $self, $mg, $variable ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die qq{Object: invalid value $mg for variable \$mg in method require};
	}
	if ( !defined($variable) || ref $variable ) {
		$variable = defined $variable ? $variable : 'undef';
		die
		    qq{Str: invalid value $variable for variable \$variable in method require};
	}

	return qq|eval "require ${variable}";|;

}

sub unless {
	my ( $self, $mg, $condition, @code ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die qq{Object: invalid value $mg for variable \$mg in method unless};
	}
	if ( !defined($condition) || ref $condition ) {
		$condition = defined $condition ? $condition : 'undef';
		die
		    qq{Str: invalid value $condition for variable \$condition in method unless};
	}

	my $c = join "\n", @code;
	return qq|unless ($condition) { $c }|;

}

sub while {
	my ( $self, $mg, $condition, @code ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die qq{Object: invalid value $mg for variable \$mg in method while};
	}
	if ( !defined($condition) || ref $condition ) {
		$condition = defined $condition ? $condition : 'undef';
		die
		    qq{Str: invalid value $condition for variable \$condition in method while};
	}

	my $c = join "\n", @code;
	return qq|while ($condition) { $c }|;

}

1;

__END__

=head1 NAME

Hades::Macro::Dolos - Hades macro helpers for Dolos

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Quick summary of what the module does:

	Hades->run({
		eval => q|
			macro {
				Dolos
			}
			Kosmos { 
				psyche $dolos :t(Int) $eros :t(HashRef) $psyche :t(HashRef) {
					€if($dolos,€if($dolos > 10, return $eros;);, €elsif($dolos > 5, €merge_hash_refs($eros, $psyche););,
						€else(return $psyche;););
					return undef;
				}
			}
		|;
	});

=head1 SUBROUTINES/METHODS

=head2 new

Instantiate a new Hades::Macro::Dolos object.

	Hades::Macro::Dolos->new

=head2 autoload_cb

call autoload_cb method. Expects param $mg to be a Object, param $cb to be a Str.

	$obj->autoload_cb($mg, $cb)

=head2 caller

call caller method. Expects param $mg to be a Object, param $variable to be a Str.

	$obj->caller($mg, $variable)

=head2 clear_unless_keys

call clear_unless_keys method. Expects param $mg to be a Object, param $variable to be a Str, param $hash to be a Str.

	$obj->clear_unless_keys($mg, $variable, $hash)

=head2 call_sub

call call_sub method. Expects param $mg to be a Object, param $sub to be any value including undef, param @params to be any value including undef.

	$obj->call_sub($mg, $sub, @params)

=head2 call_sub_my

call call_sub_my method. Expects param $mg to be a Object, param $my to be a Str, param $sub to be any value including undef, param @params to be any value including undef.

	$obj->call_sub_my($mg, $my, $sub, @params)

=head2 delete

call delete method. Expects param $mg to be a Object, param $hash to be a Str, param $key to be a Str, param $variable to be a Optional[Str], param $or to be a Optional[Str], param $list to be a Optional[Bool].

	$obj->delete($mg, $hash, $key, $variable, $or, $list)

=head2 die_unless_keys

call die_unless_keys method. Expects param $mg to be a Object, param $hash to be a Str, param $error to be a Str.

	$obj->die_unless_keys($mg, $hash, $error)

=head2 else

call else method. Expects param $mg to be a Object, param @code to be any value including undef.

	$obj->else($mg, @code)

=head2 elsif

call elsif method. Expects param $mg to be a Object, param $condition to be a Str, param @code to be any value including undef.

	$obj->elsif($mg, $condition, @code)

=head2 export

call export method. Expects param $mg to be a Object, param $method to be a Str, param $code to be a Str, param $no_warnings to be a Int, param $caller to be a Str.

	$obj->export($mg, $method, $code, $no_warnings, $caller)

=head2 for

call for method. Expects param $mg to be a Object, param $condition to be a Str, param @code to be any value including undef.

	$obj->for($mg, $condition, @code)

=head2 foreach

call foreach method. Expects param $mg to be a Object, param $condition to be a Str, param @code to be any value including undef.

	$obj->foreach($mg, $condition, @code)

=head2 for_keys

call for_keys method. Expects param $mg to be a Object, param $hash to be a Str, param $key to be a Str, param @code to be any value including undef.

	$obj->for_keys($mg, $hash, $key, @code)

=head2 for_key_exists_and_return

call for_key_exists_and_return method. Expects param $mg to be a Object, param $hash to be a Str, param $for to be a Str.

	$obj->for_key_exists_and_return($mg, $hash, $for)

=head2 grep

call grep method. Expects param $mg to be a Object, param $condition to be a Str, param @code to be any value including undef.

	$obj->grep($mg, $condition, @code)

=head2 grep_map

call grep_map method. Expects param $mg to be a Object, param $condition to be a Str, param $grep_code to be a Str, param @map_code to be any value including undef.

	$obj->grep_map($mg, $condition, $grep_code, @map_code)

=head2 if

call if method. Expects param $mg to be a Object, param $condition to be a Str, param @code to be any value including undef.

	$obj->if($mg, $condition, @code)

=head2 map

call map method. Expects param $mg to be a Object, param $condition to be a Str, param @code to be any value including undef.

	$obj->map($mg, $condition, @code)

=head2 map_grep

call map_grep method. Expects param $mg to be a Object, param $condition to be a Str, param $grep_code to be a Str, param @map_code to be any value including undef.

	$obj->map_grep($mg, $condition, $grep_code, @map_code)

=head2 maybe

call maybe method. Expects param $mg to be a Object, param $key to be a Str, param $variable to be a Str.

	$obj->maybe($mg, $key, $variable)

=head2 merge_hash_refs

call merge_hash_refs method. Expects param $mg to be a Object, param @hashes to be any value including undef.

	$obj->merge_hash_refs($mg, @hashes)

=head2 require

call require method. Expects param $mg to be a Object, param $variable to be a Str.

	$obj->require($mg, $variable)

=head2 unless

call unless method. Expects param $mg to be a Object, param $condition to be a Str, param @code to be any value including undef.

	$obj->unless($mg, $condition, @code)

=head2 while

call while method. Expects param $mg to be a Object, param $condition to be a Str, param @code to be any value including undef.

	$obj->while($mg, $condition, @code)

=head1 ACCESSORS

=head2 macro

get or set macro.

	$obj->macro;

	$obj->macro($value);

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-hades::macro::dolos at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hades-Macro-Dolos>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hades::Macro::Dolos

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Hades-Macro-Dolos>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hades-Macro-Dolos>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Hades-Macro-Dolos>

=item * Search CPAN

L<https://metacpan.org/release/Hades-Macro-Dolos>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

 
