package Ixchel::Actions::lilith_install;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use Ixchel::functions::perl_module_via_pkg;
use base 'Ixchel::Actions::base';

=head1 NAME

Ixchel::Actions::lilith_install - Installs Lilith using packages as much as possible.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 CLI SYNOPSIS

ixchel -a lilith_install

=head1 CODE SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'lilith_install', opts=>{});

    if ($results->{ok}) {
        print $results->{status_text};
    }else{
        die('Action errored... '.joined("\n", @{$results->{errors}}));
    }

=head1 RESULT HASH REF

    .errors :: A array of errors encountered.
    .status_text :: A string description of what was done and the results.
    .ok :: Set to zero if any of the above errored.

=cut

sub new_extra { }

sub action_extra {
	my $self = $_[0];

	$self->status_add( status => 'Installing Lilith depends via packages' );

	my @depends = (
		'TOML',                   'DBI',             'JSON',         'File::ReadBackwards',
		'Digest::SHA',            'POE',             'File::Slurp',  'MIME::Base64',
		'Gzip::Faster',           'DBD::Pg',         'Data::Dumper', 'Text::ANSITable',
		'Net::Server::Daemonize', 'Sys::Syslog',     'YAML::PP',     'File::Slurp',
		'TOML',                   'Term::ANSIColor', 'MIME::Base64', 'Time::Piece::Guess'
	);

	$self->status_add( status => 'Perl Depends: ' . join( ', ', @depends ) );

	my @installed;
	my @failed;

	foreach my $depend (@depends) {
		my $status;
		$self->status_add( status => 'Trying to install ' . $depend . ' as a package...' );
		eval { $status = perl_module_via_pkg( module => $depend ); };
		if ($@) {
			push( @failed, $depend );
			$self->status_add( status => $depend . ' could not be installed as a package' );
		} else {
			push( @installed, $depend );
			$self->status_add( status => $depend . ' could not be installed as a package' );
		}
	} ## end foreach my $depend (@depends)

	$self->status_add( status => 'cpanm Lilith starting ...' );
	my $output=`cpanm Lilith 2>&1`;
	$self->status_add( status => "cpanm Lilith finished ... \n".$output );
	if ( $? != 0 ) {
		$self->status_add( status => 'Failed to install Lilith via cpanm', error => 1 );
	} else {
		$self->status_add( status => 'Lilith installed' );
	}

	$self->status_add( status => 'Installed via Packages: ' . join( ', ', @installed ) );
	$self->status_add( status => 'Needed via cpanm: ' . join( ', ', @failed ) );

	return undef;
} ## end sub action

sub short {
	return 'Installs Lilith using packages as much as possible.';
}

sub opts_data {
	return '
';
}

1;
