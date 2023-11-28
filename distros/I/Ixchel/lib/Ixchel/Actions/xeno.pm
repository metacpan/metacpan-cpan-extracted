package Ixchel::Actions::xeno;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use JSON::Path;
use YAML::XS qw(Load);

=head1 NAME

Ixchel::Actions::xeno :: Invokes xeno_build with the specified hash.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'suricata_outputs', opts=>{np=>1, w=>1, });

    print Dumper($results);

=head1 FLAGS

=head2 --xb <file>

Read this YAML file to use for with xeno_build.

=head1 RESULT HASH REF

    .errors :: A array of errors encountered.
    .status_text :: A string description of what was done and the results.
    .ok :: Set to zero if any of the above errored.

=cut

sub new {
	my ( $empty, %opts ) = @_;

	my $self = {
		config => {},
		vars   => {},
		arggv  => [],
		opts   => {},
	};
	bless $self;

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

	return $self;
} ## end sub new

sub action {
	my $self = $_[0];

	$self->{results} = {
		errors      => [],
		status_text => '',
		ok          => 0,
	};

	# if neither are defined error and return
	if ( !defined( $self->{opts}{xb} ) ) {
		my $error = 'Neither --xb specified';
		warn($error);
		push( @{ $self->{results}{errors} }, $error );
		return $self->{results};
	}

	# set the proxy proxy info if we have any in the config
	if ( defined( $self->{config}{proxy} ) ) {
		if ( defined( $self->{config}{proxy}{ftp} ) && $self->{config}{proxy}{ftp} ne '' ) {
			$ENV{FTP_PROXY} = $self->{config}{proxy}{ftp};
			$ENV{ftp_proxy} = $self->{config}{proxy}{ftp};
		}
		if ( defined( $self->{config}{proxy}{http} ) && $self->{config}{proxy}{http} ne '' ) {
			$ENV{HTTP_PROXY} = $self->{config}{proxy}{http};
			$ENV{http_proxy} = $self->{config}{proxy}{http};
		}
		if ( defined( $self->{config}{proxy}{https} ) && $self->{config}{proxy}{https} ne '' ) {
			$ENV{HTTPS_PROXY} = $self->{config}{proxy}{https};
			$ENV{https_proxy} = $self->{config}{proxy}{https};
		}
	} ## end if ( defined( $self->{config}{proxy} ) )

	my $xeno_build;
	if ( defined( $self->{opts}{xb} ) ) {
		my $xeno_build_file;
		if ( -f $self->{opts}{xb} ) {
			$xeno_build_file = $self->{opts}{xb};
		} elsif ( -f $self->{share_dir} . '/' . $self->{opts}{xb} ) {
			$xeno_build_file = $self->{share_dir} . '/' . $self->{opts}{xb};
		} elsif ( -f $self->{share_dir} . '/' . $self->{opts}{xb} . '.yaml' ) {
			$xeno_build_file = $self->{share_dir} . '/' . $self->{opts}{xb} . '.yaml';
		}
		eval{
			my $raw_config = read_file($xeno_build_file) || die( 'Failed to read "' . $xeno_build_file . '"' );
			$xeno_build = Load($raw_config);
		};
		if ($@) {
			my $error =  'xeno_build errored: '.$@;
			warn($error);
			push( @{ $self->{results}{errors} }, $error );
			return $self->{results};
		}
	} ## end if ( defined( $self->{opts}{xb} ) )

    return $self->{ixchel}->action(action=>'xeno_build', opts=>{xeno_build=>$xeno_build});
} ## end sub action

sub help {
	return 'Invoke xeno_build on the specified hash.

--xb <file>    Read this YAML file in and use it as the hash for xeno_build.
';
}

sub short {
	return 'Invoke xeno_build on the specified hash.';
}

sub opts_data {
	return '
xb=s
';
}

1;
