package Hades::Macro::YAML;
use strict;
use warnings;
use base qw/Hades::Macro/;
our $VERSION = 0.01;
our ( $YAML_CLASS, $CLASS_LOADED );

BEGIN {
	$YAML_CLASS = eval {
		require YAML::XS;
		'YAML::XS';
	} || eval {
		require YAML::PP;
		'YAML::PP';
	} || eval {
		require YAML;
		'YAML';
	};
	die
	    'No supported YAML module installed - supported modules are YAML::XS, YAML::PP or YAML'
	    unless $YAML_CLASS;
}

sub new {
	my ( $cls, %args ) = ( shift(), scalar @_ == 1 ? %{ $_[0] } : @_ );
	my $self      = $cls->SUPER::new(%args);
	my %accessors = (
		macro => {
			default => [
				qw/
				    yaml_load_string
				    yaml_load_file
				    yaml_write_string
				    yaml_write_file
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

sub yaml_load_string {
	my ( $self, $mg, $str, $param, $list ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method yaml_load_string};
	}
	if ( !defined($str) || ref $str ) {
		$str = defined $str ? $str : 'undef';
		die
		    qq{Str: invalid value $str for variable \$str in method yaml_load_string};
	}
	if ( defined $param ) {
		if ( ref $param ) {
			die
			    qq{Optional[Str]: invalid value $param for variable \$param in method yaml_load_string};
		}
	}
	if ( defined $list ) {
		my $ref = ref $list;
		if (   ( $ref || 'SCALAR' ) ne 'SCALAR'
			|| ( $ref ? $$list : $list ) !~ m/^(1|0)$/ )
		{
			die
			    qq{Optional[Bool]: invalid value $list for variable \$list in method yaml_load_string};
		}
		$list = !!( $ref ? $$list : $list ) ? 1 : 0;
	}

	unless ($CLASS_LOADED) {
		$mg->use($YAML_CLASS);
	}
	( my $uf = $YAML_CLASS ) =~ s/\:\:/_/g;
	my $cb = "_yaml_load_string_$uf";
	return __PACKAGE__->$cb( $mg, $str, $param, $list );

}

sub _yaml_load_string_YAML {
	my ( $self, $mg, $str, $param, $list ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method _yaml_load_string_YAML};
	}
	if ( !defined($str) || ref $str ) {
		$str = defined $str ? $str : 'undef';
		die
		    qq{Str: invalid value $str for variable \$str in method _yaml_load_string_YAML};
	}
	if ( defined $param ) {
		if ( ref $param ) {
			die
			    qq{Optional[Str]: invalid value $param for variable \$param in method _yaml_load_string_YAML};
		}
	}
	if ( defined $list ) {
		my $ref = ref $list;
		if (   ( $ref || 'SCALAR' ) ne 'SCALAR'
			|| ( $ref ? $$list : $list ) !~ m/^(1|0)$/ )
		{
			die
			    qq{Optional[Bool]: invalid value $list for variable \$list in method _yaml_load_string_YAML};
		}
		$list = !!( $ref ? $$list : $list ) ? 1 : 0;
	}

	my $code = q||;
	$code .= qq|$param = | if $param;
	$code .= qq|YAML::Load($str)|;
	$code .= $list ? q|,| : q|;|;
	return $code;

}

sub _yaml_load_string_YAML_XS {
	my ( $self, $mg, $str, $param, $list ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method _yaml_load_string_YAML_XS};
	}
	if ( !defined($str) || ref $str ) {
		$str = defined $str ? $str : 'undef';
		die
		    qq{Str: invalid value $str for variable \$str in method _yaml_load_string_YAML_XS};
	}
	if ( defined $param ) {
		if ( ref $param ) {
			die
			    qq{Optional[Str]: invalid value $param for variable \$param in method _yaml_load_string_YAML_XS};
		}
	}
	if ( defined $list ) {
		my $ref = ref $list;
		if (   ( $ref || 'SCALAR' ) ne 'SCALAR'
			|| ( $ref ? $$list : $list ) !~ m/^(1|0)$/ )
		{
			die
			    qq{Optional[Bool]: invalid value $list for variable \$list in method _yaml_load_string_YAML_XS};
		}
		$list = !!( $ref ? $$list : $list ) ? 1 : 0;
	}

	my $code = q||;
	$code .= qq|$param = | if $param;
	$code .= qq|Load($str)|;
	$code .= $list ? q|,| : q|;|;
	return $code;

}

sub _yaml_load_string_YAML_PP {
	my ( $self, $mg, $str, $param, $list ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method _yaml_load_string_YAML_PP};
	}
	if ( !defined($str) || ref $str ) {
		$str = defined $str ? $str : 'undef';
		die
		    qq{Str: invalid value $str for variable \$str in method _yaml_load_string_YAML_PP};
	}
	if ( defined $param ) {
		if ( ref $param ) {
			die
			    qq{Optional[Str]: invalid value $param for variable \$param in method _yaml_load_string_YAML_PP};
		}
	}
	if ( defined $list ) {
		my $ref = ref $list;
		if (   ( $ref || 'SCALAR' ) ne 'SCALAR'
			|| ( $ref ? $$list : $list ) !~ m/^(1|0)$/ )
		{
			die
			    qq{Optional[Bool]: invalid value $list for variable \$list in method _yaml_load_string_YAML_PP};
		}
		$list = !!( $ref ? $$list : $list ) ? 1 : 0;
	}

	my $code = q|my $lpp = YAML::PP->new;|;
	$code .= qq|$param = | if $param;
	$code .= qq|\$lpp->load_string($str);|;
	$code = $list ? qq|do { $code },| : qq|$code;|;
	return $code;

}

sub yaml_load_file {
	my ( $self, $mg, $file, $param, $list ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method yaml_load_file};
	}
	if ( !defined($file) || ref $file ) {
		$file = defined $file ? $file : 'undef';
		die
		    qq{Str: invalid value $file for variable \$file in method yaml_load_file};
	}
	if ( defined $param ) {
		if ( ref $param ) {
			die
			    qq{Optional[Str]: invalid value $param for variable \$param in method yaml_load_file};
		}
	}
	if ( defined $list ) {
		my $ref = ref $list;
		if (   ( $ref || 'SCALAR' ) ne 'SCALAR'
			|| ( $ref ? $$list : $list ) !~ m/^(1|0)$/ )
		{
			die
			    qq{Optional[Bool]: invalid value $list for variable \$list in method yaml_load_file};
		}
		$list = !!( $ref ? $$list : $list ) ? 1 : 0;
	}

	unless ($CLASS_LOADED) {
		$mg->use($YAML_CLASS);
	}
	( my $uf = $YAML_CLASS ) =~ s/\:\:/_/g;
	my $cb = "_yaml_load_file_$uf";
	return __PACKAGE__->$cb( $mg, $file, $param, $list );

}

sub _yaml_load_file_YAML {
	my ( $self, $mg, $file, $param, $list ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method _yaml_load_file_YAML};
	}
	if ( !defined($file) || ref $file ) {
		$file = defined $file ? $file : 'undef';
		die
		    qq{Str: invalid value $file for variable \$file in method _yaml_load_file_YAML};
	}
	if ( defined $param ) {
		if ( ref $param ) {
			die
			    qq{Optional[Str]: invalid value $param for variable \$param in method _yaml_load_file_YAML};
		}
	}
	if ( defined $list ) {
		my $ref = ref $list;
		if (   ( $ref || 'SCALAR' ) ne 'SCALAR'
			|| ( $ref ? $$list : $list ) !~ m/^(1|0)$/ )
		{
			die
			    qq{Optional[Bool]: invalid value $list for variable \$list in method _yaml_load_file_YAML};
		}
		$list = !!( $ref ? $$list : $list ) ? 1 : 0;
	}

	my $code = q||;
	$code .= qq|$param = | if $param;
	$code .= qq|YAML::LoadFile($file)|;
	$code .= $list ? q|,| : q|;|;
	return $code;

}

sub _yaml_load_file_YAML_XS {
	my ( $self, $mg, $file, $param, $list ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method _yaml_load_file_YAML_XS};
	}
	if ( !defined($file) || ref $file ) {
		$file = defined $file ? $file : 'undef';
		die
		    qq{Str: invalid value $file for variable \$file in method _yaml_load_file_YAML_XS};
	}
	if ( defined $param ) {
		if ( ref $param ) {
			die
			    qq{Optional[Str]: invalid value $param for variable \$param in method _yaml_load_file_YAML_XS};
		}
	}
	if ( defined $list ) {
		my $ref = ref $list;
		if (   ( $ref || 'SCALAR' ) ne 'SCALAR'
			|| ( $ref ? $$list : $list ) !~ m/^(1|0)$/ )
		{
			die
			    qq{Optional[Bool]: invalid value $list for variable \$list in method _yaml_load_file_YAML_XS};
		}
		$list = !!( $ref ? $$list : $list ) ? 1 : 0;
	}

	my $code = q||;
	$code .= qq|$param = | if $param;
	$code .= qq|LoadFile($file)|;
	$code .= $list ? q|,| : q|;|;
	return $code;

}

sub _yaml_load_file_YAML_PP {
	my ( $self, $mg, $file, $param, $list ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method _yaml_load_file_YAML_PP};
	}
	if ( !defined($file) || ref $file ) {
		$file = defined $file ? $file : 'undef';
		die
		    qq{Str: invalid value $file for variable \$file in method _yaml_load_file_YAML_PP};
	}
	if ( defined $param ) {
		if ( ref $param ) {
			die
			    qq{Optional[Str]: invalid value $param for variable \$param in method _yaml_load_file_YAML_PP};
		}
	}
	if ( defined $list ) {
		my $ref = ref $list;
		if (   ( $ref || 'SCALAR' ) ne 'SCALAR'
			|| ( $ref ? $$list : $list ) !~ m/^(1|0)$/ )
		{
			die
			    qq{Optional[Bool]: invalid value $list for variable \$list in method _yaml_load_file_YAML_PP};
		}
		$list = !!( $ref ? $$list : $list ) ? 1 : 0;
	}

	my $code = q|my $lpp = YAML::PP->new;|;
	$code .= qq|$param = | if $param;
	$code .= qq|\$lpp->load_file($file);|;
	$code = $list ? qq|do { $code },| : qq|$code;|;
	return $code;

}

sub yaml_write_string {
	my ( $self, $mg, $content, $param, $list ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method yaml_write_string};
	}
	if ( !defined($content) || ref $content ) {
		$content = defined $content ? $content : 'undef';
		die
		    qq{Str: invalid value $content for variable \$content in method yaml_write_string};
	}
	if ( defined $param ) {
		if ( ref $param ) {
			die
			    qq{Optional[Str]: invalid value $param for variable \$param in method yaml_write_string};
		}
	}
	if ( defined $list ) {
		my $ref = ref $list;
		if (   ( $ref || 'SCALAR' ) ne 'SCALAR'
			|| ( $ref ? $$list : $list ) !~ m/^(1|0)$/ )
		{
			die
			    qq{Optional[Bool]: invalid value $list for variable \$list in method yaml_write_string};
		}
		$list = !!( $ref ? $$list : $list ) ? 1 : 0;
	}

	unless ($CLASS_LOADED) {
		$mg->use($YAML_CLASS);
	}
	( my $uf = $YAML_CLASS ) =~ s/\:\:/_/g;
	my $cb = "_yaml_write_string_$uf";
	return __PACKAGE__->$cb( $mg, $content, $param, $list );

}

sub _yaml_write_string_YAML {
	my ( $self, $mg, $content, $param, $list ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method _yaml_write_string_YAML};
	}
	if ( !defined($content) || ref $content ) {
		$content = defined $content ? $content : 'undef';
		die
		    qq{Str: invalid value $content for variable \$content in method _yaml_write_string_YAML};
	}
	if ( defined $param ) {
		if ( ref $param ) {
			die
			    qq{Optional[Str]: invalid value $param for variable \$param in method _yaml_write_string_YAML};
		}
	}
	if ( defined $list ) {
		my $ref = ref $list;
		if (   ( $ref || 'SCALAR' ) ne 'SCALAR'
			|| ( $ref ? $$list : $list ) !~ m/^(1|0)$/ )
		{
			die
			    qq{Optional[Bool]: invalid value $list for variable \$list in method _yaml_write_string_YAML};
		}
		$list = !!( $ref ? $$list : $list ) ? 1 : 0;
	}

	my $code = q||;
	$code .= qq|$param = | if $param;
	$code .= qq|YAML::Dump($content)|;
	$code .= $list ? q|,| : q|;|;
	return $code;

}

sub _yaml_write_string_YAML_XS {
	my ( $self, $mg, $content, $param, $list ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method _yaml_write_string_YAML_XS};
	}
	if ( !defined($content) || ref $content ) {
		$content = defined $content ? $content : 'undef';
		die
		    qq{Str: invalid value $content for variable \$content in method _yaml_write_string_YAML_XS};
	}
	if ( defined $param ) {
		if ( ref $param ) {
			die
			    qq{Optional[Str]: invalid value $param for variable \$param in method _yaml_write_string_YAML_XS};
		}
	}
	if ( defined $list ) {
		my $ref = ref $list;
		if (   ( $ref || 'SCALAR' ) ne 'SCALAR'
			|| ( $ref ? $$list : $list ) !~ m/^(1|0)$/ )
		{
			die
			    qq{Optional[Bool]: invalid value $list for variable \$list in method _yaml_write_string_YAML_XS};
		}
		$list = !!( $ref ? $$list : $list ) ? 1 : 0;
	}

	my $code = q||;
	$code .= qq|$param = | if $param;
	$code .= qq|Dump($content)|;
	$code .= $list ? q|,| : q|;|;
	return $code;

}

sub _yaml_write_string_YAML_PP {
	my ( $self, $mg, $content, $param, $list ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method _yaml_write_string_YAML_PP};
	}
	if ( !defined($content) || ref $content ) {
		$content = defined $content ? $content : 'undef';
		die
		    qq{Str: invalid value $content for variable \$content in method _yaml_write_string_YAML_PP};
	}
	if ( defined $param ) {
		if ( ref $param ) {
			die
			    qq{Optional[Str]: invalid value $param for variable \$param in method _yaml_write_string_YAML_PP};
		}
	}
	if ( defined $list ) {
		my $ref = ref $list;
		if (   ( $ref || 'SCALAR' ) ne 'SCALAR'
			|| ( $ref ? $$list : $list ) !~ m/^(1|0)$/ )
		{
			die
			    qq{Optional[Bool]: invalid value $list for variable \$list in method _yaml_write_string_YAML_PP};
		}
		$list = !!( $ref ? $$list : $list ) ? 1 : 0;
	}

	my $code = q|my $wpp = YAML::PP->new;|;
	$code .= qq|$param = | if $param;
	$code .= qq|\$wpp->dump_string($content)|;
	$code = $list ? qq|do { $code },| : qq|$code;|;
	return $code;

}

sub yaml_write_file {
	my ( $self, $mg, $file, $content, $param, $list ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method yaml_write_file};
	}
	if ( !defined($file) || ref $file ) {
		$file = defined $file ? $file : 'undef';
		die
		    qq{Str: invalid value $file for variable \$file in method yaml_write_file};
	}
	if ( !defined($content) || ref $content ) {
		$content = defined $content ? $content : 'undef';
		die
		    qq{Str: invalid value $content for variable \$content in method yaml_write_file};
	}
	if ( defined $param ) {
		if ( ref $param ) {
			die
			    qq{Optional[Str]: invalid value $param for variable \$param in method yaml_write_file};
		}
	}
	if ( defined $list ) {
		my $ref = ref $list;
		if (   ( $ref || 'SCALAR' ) ne 'SCALAR'
			|| ( $ref ? $$list : $list ) !~ m/^(1|0)$/ )
		{
			die
			    qq{Optional[Bool]: invalid value $list for variable \$list in method yaml_write_file};
		}
		$list = !!( $ref ? $$list : $list ) ? 1 : 0;
	}

	unless ($CLASS_LOADED) {
		$mg->use($YAML_CLASS);
	}
	( my $uf = $YAML_CLASS ) =~ s/\:\:/_/g;
	my $cb = "_yaml_write_file_$uf";
	return __PACKAGE__->$cb( $mg, $file, $content, $param, $list );

}

sub _yaml_write_file_YAML {
	my ( $self, $mg, $file, $content, $param, $list ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method _yaml_write_file_YAML};
	}
	if ( !defined($file) || ref $file ) {
		$file = defined $file ? $file : 'undef';
		die
		    qq{Str: invalid value $file for variable \$file in method _yaml_write_file_YAML};
	}
	if ( !defined($content) || ref $content ) {
		$content = defined $content ? $content : 'undef';
		die
		    qq{Str: invalid value $content for variable \$content in method _yaml_write_file_YAML};
	}
	if ( defined $param ) {
		if ( ref $param ) {
			die
			    qq{Optional[Str]: invalid value $param for variable \$param in method _yaml_write_file_YAML};
		}
	}
	if ( defined $list ) {
		my $ref = ref $list;
		if (   ( $ref || 'SCALAR' ) ne 'SCALAR'
			|| ( $ref ? $$list : $list ) !~ m/^(1|0)$/ )
		{
			die
			    qq{Optional[Bool]: invalid value $list for variable \$list in method _yaml_write_file_YAML};
		}
		$list = !!( $ref ? $$list : $list ) ? 1 : 0;
	}

	my $code = q||;
	$code .= qq|$param = | if $param;
	$code .= qq|YAML::DumpFile($file, $content)|;
	$code .= $list ? q|,| : q|;|;
	return $code;

}

sub _yaml_write_file_YAML_XS {
	my ( $self, $mg, $file, $content, $param, $list ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method _yaml_write_file_YAML_XS};
	}
	if ( !defined($file) || ref $file ) {
		$file = defined $file ? $file : 'undef';
		die
		    qq{Str: invalid value $file for variable \$file in method _yaml_write_file_YAML_XS};
	}
	if ( !defined($content) || ref $content ) {
		$content = defined $content ? $content : 'undef';
		die
		    qq{Str: invalid value $content for variable \$content in method _yaml_write_file_YAML_XS};
	}
	if ( defined $param ) {
		if ( ref $param ) {
			die
			    qq{Optional[Str]: invalid value $param for variable \$param in method _yaml_write_file_YAML_XS};
		}
	}
	if ( defined $list ) {
		my $ref = ref $list;
		if (   ( $ref || 'SCALAR' ) ne 'SCALAR'
			|| ( $ref ? $$list : $list ) !~ m/^(1|0)$/ )
		{
			die
			    qq{Optional[Bool]: invalid value $list for variable \$list in method _yaml_write_file_YAML_XS};
		}
		$list = !!( $ref ? $$list : $list ) ? 1 : 0;
	}

	my $code = q||;
	$code .= qq|$param = | if $param;
	$code .= qq|DumpFile($file, $content)|;
	$code .= $list ? q|,| : q|;|;
	return $code;

}

sub _yaml_write_file_YAML_PP {
	my ( $self, $mg, $file, $content, $param, $list ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method _yaml_write_file_YAML_PP};
	}
	if ( !defined($file) || ref $file ) {
		$file = defined $file ? $file : 'undef';
		die
		    qq{Str: invalid value $file for variable \$file in method _yaml_write_file_YAML_PP};
	}
	if ( !defined($content) || ref $content ) {
		$content = defined $content ? $content : 'undef';
		die
		    qq{Str: invalid value $content for variable \$content in method _yaml_write_file_YAML_PP};
	}
	if ( defined $param ) {
		if ( ref $param ) {
			die
			    qq{Optional[Str]: invalid value $param for variable \$param in method _yaml_write_file_YAML_PP};
		}
	}
	if ( defined $list ) {
		my $ref = ref $list;
		if (   ( $ref || 'SCALAR' ) ne 'SCALAR'
			|| ( $ref ? $$list : $list ) !~ m/^(1|0)$/ )
		{
			die
			    qq{Optional[Bool]: invalid value $list for variable \$list in method _yaml_write_file_YAML_PP};
		}
		$list = !!( $ref ? $$list : $list ) ? 1 : 0;
	}

	my $code = q|my \$wpp = YAML::PP->new;|;
	$code .= qq|$param = | if $param;
	$code .= qq|\$wpp->load_file($file, $content);|;
	$code = $list ? qq|do { $code },| : qq|$code;|;
	return $code;

}

1;

__END__

=head1 NAME

Hades::Macro::YAML - Hades macro helpers for YAML

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Quick summary of what the module does:

	Hades->run({
		eval => q|
			macro {
				YAML
			}
			Kosmos { 
				geras $file :t(Str) :d('path/to/file.yml') { 
					€yaml_load_file($file);
				}
			}
		|;
	});

	... generates ...

=head1 SUBROUTINES/METHODS

=head2 new

Instantiate a new Hades::Macro::YAML object.

	Hades::Macro::YAML->new

=head2 yaml_load_string

call yaml_load_string method. Expects param $mg to be a Object, param $str to be a Str, param $param to be a Optional[Str], param $list to be a Optional[Bool].

	$obj->yaml_load_string($mg, $str, $param, $list)

=head2 _yaml_load_string_YAML

call _yaml_load_string_YAML method. Expects param $mg to be a Object, param $str to be a Str, param $param to be a Optional[Str], param $list to be a Optional[Bool].

	$obj->_yaml_load_string_YAML($mg, $str, $param, $list)

=head2 _yaml_load_string_YAML_XS

call _yaml_load_string_YAML_XS method. Expects param $mg to be a Object, param $str to be a Str, param $param to be a Optional[Str], param $list to be a Optional[Bool].

	$obj->_yaml_load_string_YAML_XS($mg, $str, $param, $list)

=head2 _yaml_load_string_YAML_PP

call _yaml_load_string_YAML_PP method. Expects param $mg to be a Object, param $str to be a Str, param $param to be a Optional[Str], param $list to be a Optional[Bool].

	$obj->_yaml_load_string_YAML_PP($mg, $str, $param, $list)

=head2 yaml_load_file

call yaml_load_file method. Expects param $mg to be a Object, param $file to be a Str, param $param to be a Optional[Str], param $list to be a Optional[Bool].

	$obj->yaml_load_file($mg, $file, $param, $list)

=head2 _yaml_load_file_YAML

call _yaml_load_file_YAML method. Expects param $mg to be a Object, param $file to be a Str, param $param to be a Optional[Str], param $list to be a Optional[Bool].

	$obj->_yaml_load_file_YAML($mg, $file, $param, $list)

=head2 _yaml_load_file_YAML_XS

call _yaml_load_file_YAML_XS method. Expects param $mg to be a Object, param $file to be a Str, param $param to be a Optional[Str], param $list to be a Optional[Bool].

	$obj->_yaml_load_file_YAML_XS($mg, $file, $param, $list)

=head2 _yaml_load_file_YAML_PP

call _yaml_load_file_YAML_PP method. Expects param $mg to be a Object, param $file to be a Str, param $param to be a Optional[Str], param $list to be a Optional[Bool].

	$obj->_yaml_load_file_YAML_PP($mg, $file, $param, $list)

=head2 yaml_write_string

call yaml_write_string method. Expects param $mg to be a Object, param $content to be a Str, param $param to be a Optional[Str], param $list to be a Optional[Bool].

	$obj->yaml_write_string($mg, $content, $param, $list)

=head2 _yaml_write_string_YAML

call _yaml_write_string_YAML method. Expects param $mg to be a Object, param $content to be a Str, param $param to be a Optional[Str], param $list to be a Optional[Bool].

	$obj->_yaml_write_string_YAML($mg, $content, $param, $list)

=head2 _yaml_write_string_YAML_XS

call _yaml_write_string_YAML_XS method. Expects param $mg to be a Object, param $content to be a Str, param $param to be a Optional[Str], param $list to be a Optional[Bool].

	$obj->_yaml_write_string_YAML_XS($mg, $content, $param, $list)

=head2 _yaml_write_string_YAML_PP

call _yaml_write_string_YAML_PP method. Expects param $mg to be a Object, param $content to be a Str, param $param to be a Optional[Str], param $list to be a Optional[Bool].

	$obj->_yaml_write_string_YAML_PP($mg, $content, $param, $list)

=head2 yaml_write_file

call yaml_write_file method. Expects param $mg to be a Object, param $file to be a Str, param $content to be a Str, param $param to be a Optional[Str], param $list to be a Optional[Bool].

	$obj->yaml_write_file($mg, $file, $content, $param, $list)

=head2 _yaml_write_file_YAML

call _yaml_write_file_YAML method. Expects param $mg to be a Object, param $file to be a Str, param $content to be a Str, param $param to be a Optional[Str], param $list to be a Optional[Bool].

	$obj->_yaml_write_file_YAML($mg, $file, $content, $param, $list)

=head2 _yaml_write_file_YAML_XS

call _yaml_write_file_YAML_XS method. Expects param $mg to be a Object, param $file to be a Str, param $content to be a Str, param $param to be a Optional[Str], param $list to be a Optional[Bool].

	$obj->_yaml_write_file_YAML_XS($mg, $file, $content, $param, $list)

=head2 _yaml_write_file_YAML_PP

call _yaml_write_file_YAML_PP method. Expects param $mg to be a Object, param $file to be a Str, param $content to be a Str, param $param to be a Optional[Str], param $list to be a Optional[Bool].

	$obj->_yaml_write_file_YAML_PP($mg, $file, $content, $param, $list)

=head1 ACCESSORS

=head2 macro

get or set macro.

	$obj->macro;

	$obj->macro($value);

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-hades::macro::yaml at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hades-Macro-YAML>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hades::Macro::YAML

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Hades-Macro-YAML>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hades-Macro-YAML>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Hades-Macro-YAML>

=item * Search CPAN

L<https://metacpan.org/release/Hades-Macro-YAML>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

 
