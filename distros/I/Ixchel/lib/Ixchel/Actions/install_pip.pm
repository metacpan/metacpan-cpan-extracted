package Ixchel::Actions::install_pip;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use Ixchel::functions::install_pip;

=head1 NAME

Ixchel::Actions::install_pip :: Install pip via packages.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'instal_cpanm', opts=>{});


=head1 FLAGS

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

	$self->status_add(status=>'Installing pip via packges');

	eval{
		install_pip;
	};
	if ($@) {
		$self->status_add(status=>'Failed to install pip via packages ... '.$@, error=>1);
	}else {
		$self->status_add(status=>'pip installed');
	}

	return $self->{results};
} ## end sub action

sub help {
	return 'Install pip via packages.
';
} ## end sub help

sub short {
	return 'Install pip via packages.';
}

sub opts_data {
	return '
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
                $opts{type} = 'install_cpanm';
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
