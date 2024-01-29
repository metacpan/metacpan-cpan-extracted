package Ixchel::Actions::base;

use 5.006;
use strict;
use warnings;

=head1 NAME

Ixchel::Actions::base - Base module for actions.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    package Ixchel::Actions::install_cpanm;

    use strict;
    use warnings;
    use Ixchel::functions::install_cpanm;
    use base 'Ixchel::Actions::base';

    sub new_extra {
    }

    sub action {
	    my $self = $_[0];

	    $self->status_add(status=>'Installing cpanm via packges');

	    eval{
		    install_cpanm;
	    };
	    if ($@) {
		    $self->status_add(status=>'Failed to install cpanm via packages ... '.$@, error=>1);
	    }else {
		    $self->status_add(status=>'cpanm installed');
	    }

	    if (!defined($self->{results}{errors}[0])) {
		   $self->{results}{ok}=1;
	    }else {
		   $self->{results}{ok}=0;
	    }

        return $self->{results};
    }

    sub short {
	    return 'Install cpanm via packages.';
    }

=head2 DESCRIPTION

=head1 RESULT HASH REF

    .errors :: A array of errors encountered.
    .status_text :: A string description of what was done and the results.
    .ok :: Set to zero if any of the above errored.

=cut

=head1 METHODS

=head2 new

This initiates the action. At the ned of the new method, $self->new_extra; is called.
This method should exist in the action package. It is for anything else that needs done
for new. If nothing it should just be empty.

The returned object has the following keys.

    - $self->{config} :: The config hash for Ixchel.

    - $self->{vars} :: The value of vars passed to the new method.

    - $self->{opts} :: Decoded opts as specifed via opts data.

    - $self->{argv} :: Left over arguments post decoding opts.

    - $self->{ixchel} :: The calling Ixchel object.

    - $self->{share_dir} :: Location of the share dir.

    - $self->{type} :: The type that will be used with status_add.

    - $self->{t} :: The Template object Initiated via Ixchel.

=cut

sub new {
	my ( $empty, %opts ) = @_;

	my $class = shift;

	my $self = {
		config   => {},
		vars     => {},
		arggv    => [],
		opts     => {},
		no_print => 0,
	};
	bless $self, $class;

	$self->{type} = ref($self);
	$self->{type} =~ s/^Ixchel\:\:Actions\:\://;

	if ( defined( $opts{config} ) ) {
		$self->{config} = $opts{config};
	}

	if ( defined( $opts{t} ) ) {
		$self->{t} = $opts{t};
	} else {
		die('$opts{t} is undef');
	}

	if ( defined( $opts{share_dir} ) ) {
		$self->{share_dir} = $opts{share_dir};
	}

	if ( defined( $opts{opts} ) ) {
		$self->{opts} = \%{ $opts{opts} };
	}

	if ( defined( $opts{argv} ) ) {
		$self->{argv} = $opts{argv};
	}

	if ( defined( $opts{vars} ) ) {
		$self->{vars} = $opts{vars};
	}

	if ( defined( $opts{ixchel} ) ) {
		$self->{ixchel} = $opts{ixchel};
	}

	$self->{results} = {
		errors      => [],
		status_text => '',
		ok          => 0,
	};

	$self->new_extra;

	return $self;
} ## end sub new

=head2 action

Will call $self->action_extra.

Upon undef it will check if $self->{results}{errors}[0]
is defined and if it is not $self->{results}{ok} is set
to 1.

Upon $self->{results} being returned, it makes it checks if
$results->{errors} is defined, is a array and then if
it is a array it will check $results->{errors}[0] is defined
for setting $results->{ok} before returning $results.

Any other results return will be returned as is.

Or as code it does...

    if (   defined($results)
        && ref($results) eq 'HASH'
        && defined( $self->{results}{errors} )
        && ref( $results->{results}{errors} ) eq 'ARRAY' )
    {
        if ( !defined( $self->{results}{errors}[0] ) ) {
            $self->{results}{ok} = 1;
        }
        return $self->{results};
    }elsif (!defined($results)) {
        if ( !defined( $self->{results}{errors}[0] ) ) {
            $self->{results}{ok} = 1;
        }
        return $self->{results};
    }

    return $results;

=cut

sub action {
	my ($self) = @_;

	my $results;
	eval { $results = $self->action_extra; };
	if ($@) {
		$self->status_add( error => 1, '$self->action_extra died... ' . $@ );
		return $self->{results};
	}

	if (   defined($results)
		&& ref($results) eq 'HASH'
		&& defined( $self->{results}{errors} )
		&& ref( $results->{results}{errors} ) eq 'ARRAY' )
	{
		if ( !defined( $self->{results}{errors}[0] ) ) {
			$self->{results}{ok} = 1;
		}
		return $self->{results};
	} elsif ( !defined($results) ) {
		if ( !defined( $self->{results}{errors}[0] ) ) {
			$self->{results}{ok} = 1;
		}

		return $self->{results};
	}

	return $results;
} ## end sub action

=head2 status_add

Adds a item to $self->{results}{status_text}.

The following are required.

    - status :: Status to add.
        Default :: undef

The following are optional.

    - error :: A Perl boolean for if it is a error or not. If true
            it will be pushed to the array $self->{results}{errors}.
        Default :: undef

    - type :: What to display the current type as in the status line.
        Default :: $action

    $self->status_add(status=>'Some status');

    $self->status_add(error=>1, status=>'Some error');

=cut

sub status_add {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{status} ) ) {
		return;
	}

	if ( !defined( $opts{error} ) ) {
		$opts{error} = 0;
	}

	if ( !defined( $opts{type} ) ) {
		$opts{type} = $self->{type};
	}

	my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime(time);
	my $timestamp = sprintf( "%04d-%02d-%02dT%02d:%02d:%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec );

	my $status = '[' . $timestamp . '] [' . $opts{type} . ', ' . $opts{error} . '] ' . $opts{status};

	if ( !$self->{no_print} ) {
		print $status. "\n";
	}

	$self->{results}{status_text} = $self->{results}{status_text} . $status;

	if ( $opts{error} ) {
		push( @{ $self->{results}{errors} }, $opts{status} );

		eval { $self->status_add_error_extra; };
	}
} ## end sub status_add

=head2 short

The default short just returns ''.

=cut

sub short {
	return '';
}

=head2 opts_data

The default opts_data returns "\n".

=cut

sub opts_data {
	return '
';
}

1;
