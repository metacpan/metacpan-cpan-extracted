package Ixchel::Actions::template;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use Ixchel::functions::sys_info;
use String::ShellQuote;
use File::Find::Rule;

=head1 NAME

Ixchel::Actions::template - Fill in a template.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 CLI SYNOPSIS

ixchel -a template B<-t> <template>

=head1 CODE SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'template', opts=>{np=>1, t=>$template_name});

    print Dumper($results);

=head1 DESCRIPTION

Fills in the specified template.

The templates in question are L<Template::Toolkit> templates.

The following are available for use in the template.


    - opts :: A hash with the various options specified. In the case of
            calling this from this CLI, see info on FLAGS.

    - config :: The Ixchel config hash.

    - argv :: @ARGV

	- vars :: Any additional variables passed. Only usable when calling
            via $ixchel->action and not the CLI.

The following functions are available.

    - shell_quote :: shell_quote from String::ShellQuote.
        - args :: String to quote.
        - return :: A quoted string.

    - file_exists :: Check if the specified path exists and is a file.
        - args :: A FS path, relattive or absolute.
        - return :: 0/1

    - dir_exists :: Check if the specified path exists and is a dir.
        - args :: A FS path, relattive or absolute.
        - return :: 0/1

    - get_sub_dirs :: Gets a array of directories using...
            File::Find::Rule->directory->maxdepth(1)->in( $_[0] );
        - args :: A FS path, relattive or absolute.
        - return :: An array of directories.

    - is_freebsd :: If the OS is FreeBSD or not.
        - args :: A FS path, relattive or absolute.
        - return :: 0/1

    - is_linux :: If the OS is Linux or not.
        - args :: A FS path, relattive or absolute.
        - return :: 0/1

    - is_systemd :: If the OS is Linux and if the init system is systemd.
        - args :: A FS path, relattive or absolute.
        - return :: 0/1

    - read_file :: Reads the specified file.
        - args :: A FS path, relattive or absolute.
        - return :: Contents of the specified file.

=head1 FLAGS

=head2 --np

Do not print the the filled in template.

=head2 -t

The name of the template to use.

This is resolved in order...

    ./$template
    /usr/local/etc/ixchel/templates/$template
    /usr/local/etc/ixchel/templates/$template.tt
    $share_dir/templates/$template
    $share_dir/templates/$template.tt

=cut

sub new {
	my ( $empty, %opts ) = @_;

	my $self = {
		config => {},
		vars   => {},
		arggv  => [],
		opts   => {},
		ixchel => $opts{ixchel},
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

	if ( defined( $opts{vars} ) ) {
		$self->{vars} = $opts{vars};
	}

	return $self;
} ## end sub new

sub action {
	my $self = $_[0];

	if ( !defined( $self->{opts}->{t} ) ) {
		die('No template specified via -t');
	}

	my $template = $self->{opts}->{t};

	my $template_file;
	if ( -f $template ) {
		$template_file = $template;
	} elsif ( -f '/usr/local/etc/ixchel/templates/' . $template ) {
		$template_file = '/usr/local/etc/ixchel/templates/' . $template;
	} elsif ( -f '/usr/local/etc/ixchel/templates/' . $template . '.tt' ) {
		$template_file = '/usr/local/etc/ixchel/templates/' . $template . '.tt';
	} elsif ( -f $self->{share_dir} . '/templates/' . $template ) {
		$template_file = $self->{share_dir} . '/templates/' . $template;
	} elsif ( -f $self->{share_dir} . '/templates/' . $template . '.tt' ) {
		$template_file = $self->{share_dir} . '/templates/' . $template . '.tt';
	} else {
		$self->{ixchel}{errors_count}++;
		die( 'Unable to locate template "' . $template . '" in either the current dir or ' . $self->{share_dir} );
	}

	my $vars = {
		opts        => $self->{opts},
		config      => $self->{config},
		argv        => $self->{argv},
		vars        => $self->{vars},
		sys_info    => sys_info,
		shell_quote => \&shell_quote,
		file_exists => sub {
			eval {
				if ( -f $_[0] ) {
					return 1;
				}
				return 0;
			};
		},
		dir_exists => sub {
			eval {
				if ( -d $_[0] ) {
					return 1;
				}
				return 0;
			};
		},
		get_sub_dirs => sub {
			eval {
				if ( !defined( $_[0] ) ) {
					return;
				}
				return File::Find::Rule->directory->maxdepth(1)->in( $_[0] );
			};
		},
		is_freebsd => sub {
			if ( $^O eq 'freebsd' ) {
				return 1;
			}
			return 0;
		},
		is_linux => sub {
			if ( $^O eq 'linux' ) {
				return 1;
			}
			return 0;
		},
		is_systemd => sub {
			if ( $^O eq 'linux' && ( -f '/usr/bin/systemctl' || -f '/bin/systemctl' ) ) {
				return 1;
			}
			return 0;
		},
		read_file => sub {
			eval { return read_file( $_[0] ); };
		},
	};

	my $template_data = read_file($template_file);
	if ( !defined($template_data) ) {
		$self->{ixchel}{errors_count}++;
		die( '"' . $template_file . '" could not be read' );
	}

	my $output = '';
	$self->{t}->process( \$template_data, $vars, \$output )
		|| die( 'Failed to process template... ' . $self->{t}->error );

	if ( !$self->{opts}->{np} ) {
		print $output;
	}

	return $output;
} ## end sub action

sub short {
	return 'Fills in a template.';
}

sub opts_data {
	return 't=s
np';
}

1;
