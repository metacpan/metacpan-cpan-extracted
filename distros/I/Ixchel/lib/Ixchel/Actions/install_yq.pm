package Ixchel::Actions::install_yq;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use Ixchel::functions::install_yq;

=head1 NAME

Ixchel::Actions::install_yq :: Install installs yq

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'instal_yq', opts=>{});


This installs mikefarah/yq. Will use packages if possible, otherwise will
grab the binary from github.

=head1 FLAGS

=head2 -p <path>

Where to install it to if not using packages.

Default: /usr/bin/yq

=head -n

Don't install via packages.

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

	$self->{results}={
		errors      => [],
		status_text => '',
		ok          => 0,
	};

	return $self;
} ## end sub new

sub action {
	my $self = $_[0];

	$self->status_add(status=>'Installing yq');

	eval{
		install_yq(path=>$self->{opts}{p}, no_pkg=>$self->{opts}{no_pkg});
	};
	if ($@) {
		$self->status_add(status=>'Failed to install yq ... '.$@, error=>1);
	}else {
		$self->status_add(status=>'yq installed');
	}

	return $self->{results};
} ## end sub action

sub help {
	return 'Install yq.
';
} ## end sub help

sub short {
	return 'Install yq.';
}

sub opts_data {
	return '
p=s
no_pkg
';
}

sub status_add {
        my ( $self, %opts ) = @_;

        if ( !defined( $opts{status} ) ) {
                return;
        }

        if ( !defined( $opts{error} ) ) {
                $opts{error} = 0;
        }

        if ( !defined( $opts{type} ) ) {
                $opts{type} = 'install_yq';
        }

		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
		my $timestamp = sprintf ( "%04d-%02d-%02dT%02d:%02d:%02d",
									   $year+1900,$mon+1,$mday,$hour,$min,$sec);

        my $status = '['.$timestamp.'] ['.$opts{type}.', ' . $opts{error} . '] ' . $opts{status};

        print $status."\n";

        $self->{results}{status_text} = $self->{results}{status_text} . $status;

        if ( $opts{error} ) {
                push( @{ $self->{results}{errors} }, $opts{status} );
        }
} ## end sub status_add

1;
