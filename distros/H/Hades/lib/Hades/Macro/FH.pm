package Hades::Macro::FH;
use strict;
use warnings;
use base qw/Hades::Macro/;
our $VERSION = 0.22;

sub new {
	my ( $cls, %args ) = ( shift(), scalar @_ == 1 ? %{ $_[0] } : @_ );
	my $self      = $cls->SUPER::new(%args);
	my %accessors = (
		macro => {
			default =>
			    [qw/open_write open_read close_file read_file write_file/],
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

sub open_write {
	my ( $self, $mg, $file, $variable, $error ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method open_write};
	}
	if ( !defined($file) || ref $file ) {
		$file = defined $file ? $file : 'undef';
		die
		    qq{Str: invalid value $file for variable \$file in method open_write};
	}
	$variable = defined $variable ? $variable : "\$fh";
	if ( !defined($variable) || ref $variable ) {
		$variable = defined $variable ? $variable : 'undef';
		die
		    qq{Str: invalid value $variable for variable \$variable in method open_write};
	}
	$error = defined $error ? $error : "cannot open file for writing";
	if ( !defined($error) || ref $error ) {
		$error = defined $error ? $error : 'undef';
		die
		    qq{Str: invalid value $error for variable \$error in method open_write};
	}

	return qq|open my $variable, ">", $file or die "$error: \$!";|;

}

sub open_read {
	my ( $self, $mg, $file, $variable, $error ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method open_read};
	}
	if ( !defined($file) || ref $file ) {
		$file = defined $file ? $file : 'undef';
		die
		    qq{Str: invalid value $file for variable \$file in method open_read};
	}
	$variable = defined $variable ? $variable : "\$fh";
	if ( !defined($variable) || ref $variable ) {
		$variable = defined $variable ? $variable : 'undef';
		die
		    qq{Str: invalid value $variable for variable \$variable in method open_read};
	}
	$error = defined $error ? $error : "cannot open file for reading";
	if ( !defined($error) || ref $error ) {
		$error = defined $error ? $error : 'undef';
		die
		    qq{Str: invalid value $error for variable \$error in method open_read};
	}

	return qq|open my $variable, "<", $file or die "$error: \$!";|;

}

sub close_file {
	my ( $self, $mg, $file, $variable ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method close_file};
	}
	if ( !defined($file) || ref $file ) {
		$file = defined $file ? $file : 'undef';
		die
		    qq{Str: invalid value $file for variable \$file in method close_file};
	}
	$variable = defined $variable ? $variable : "\$fh";
	if ( !defined($variable) || ref $variable ) {
		$variable = defined $variable ? $variable : 'undef';
		die
		    qq{Str: invalid value $variable for variable \$variable in method close_file};
	}

	return qq|close $variable|;

}

sub read_file {
	my ( $self, $mg, $file, $variable, $error ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method read_file};
	}
	if ( !defined($file) || ref $file ) {
		$file = defined $file ? $file : 'undef';
		die
		    qq{Str: invalid value $file for variable \$file in method read_file};
	}
	$variable = defined $variable ? $variable : "\$fh";
	if ( !defined($variable) || ref $variable ) {
		$variable = defined $variable ? $variable : 'undef';
		die
		    qq{Str: invalid value $variable for variable \$variable in method read_file};
	}
	$error = defined $error ? $error : "cannot open file for reading";
	if ( !defined($error) || ref $error ) {
		$error = defined $error ? $error : 'undef';
		die
		    qq{Str: invalid value $error for variable \$error in method read_file};
	}

	return
	      qq|open my $variable, "<", $file or die "$error: \$!";|
	    . qq|my \$content = do { local \$/; <$variable> };|
	    . qq|close $variable;|;

}

sub write_file {
	my ( $self, $mg, $file, $content, $variable, $error ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method write_file};
	}
	if ( !defined($file) || ref $file ) {
		$file = defined $file ? $file : 'undef';
		die
		    qq{Str: invalid value $file for variable \$file in method write_file};
	}
	if ( !defined($content) || ref $content ) {
		$content = defined $content ? $content : 'undef';
		die
		    qq{Str: invalid value $content for variable \$content in method write_file};
	}
	$variable = defined $variable ? $variable : "\$wh";
	if ( !defined($variable) || ref $variable ) {
		$variable = defined $variable ? $variable : 'undef';
		die
		    qq{Str: invalid value $variable for variable \$variable in method write_file};
	}
	$error = defined $error ? $error : "cannot open file for writing";
	if ( !defined($error) || ref $error ) {
		$error = defined $error ? $error : 'undef';
		die
		    qq{Str: invalid value $error for variable \$error in method write_file};
	}

	return
	      qq|open my $variable, ">", $file or die "$error: \$!";|
	    . qq|print $variable $content;|
	    . qq|close $variable;|;

}

1;

__END__

=head1 NAME

Hades::Macro::FH - Hades macro helpers for FH

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Quick summary of what the module does:

	Hades->run({
		eval => q|
			macro {
				FH [ alias => { read_file => [qw/rf/], write_file => [qw/wf/] } ]
			}
			Kosmos { 
				geras $file :t(Str) :d('path/to/file.txt') { 
					€rf($file);
					$content = 'limos';
					€wf($file, $content);
				}
			}
		|;
	});

	... generates ...

	package Kosmos;
	use strict;
	use warnings;
	our $VERSION = 0.01;

	sub new {
		my ( $cls, %args ) = ( shift(), scalar @_ == 1 ? %{ $_[0] } : @_ );
		my $self      = bless {}, $cls;
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

	sub geras {
		my ( $self, $file ) = @_;
		$file = defined $file ? $file : 'path/to/file.txt';
		if ( !defined($file) || ref $file ) {
			$file = defined $file ? $file : 'undef';
			die qq{Str: invalid value $file for variable \$file in method geras};
		}

		open my $fh, "<", $file or die "cannot open file for reading: $!";
		my $content = do { local $/; <$fh> };
		close $fh;
		$content = 'limos';
		open my $wh, ">", $file or die "cannot open file for writing: $!";
		print $wh $content;
		close $wh;

	}

	1;

	__END__

=head1 SUBROUTINES/METHODS

=head2 new

Instantiate a new Hades::Macro::FH object.

	Hades::Macro::FH->new

=head2 open_write

call open_write method. Expects param $mg to be a Object, param $file to be a Str, param $variable to be a Str, param $error to be a Str.

	$obj->open_write($mg, $file, $variable, $error)

=head2 open_read

call open_read method. Expects param $mg to be a Object, param $file to be a Str, param $variable to be a Str, param $error to be a Str.

	$obj->open_read($mg, $file, $variable, $error)

=head2 close_file

call close_file method. Expects param $mg to be a Object, param $file to be a Str, param $variable to be a Str.

	$obj->close_file($mg, $file, $variable)

=head2 read_file

call read_file method. Expects param $mg to be a Object, param $file to be a Str, param $variable to be a Str, param $error to be a Str.

	$obj->read_file($mg, $file, $variable, $error)

=head2 write_file

call write_file method. Expects param $mg to be a Object, param $file to be a Str, param $content to be a Str, param $variable to be a Str, param $error to be a Str.

	$obj->write_file($mg, $file, $content, $variable, $error)

=head1 ACCESSORS

=head2 macro

get or set macro.

	$obj->macro;

	$obj->macro($value);

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-hades::macro::fh at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hades-Macro-FH>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hades::Macro::FH

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Hades-Macro-FH>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hades-Macro-FH>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Hades-Macro-FH>

=item * Search CPAN

L<https://metacpan.org/release/Hades-Macro-FH>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

 
