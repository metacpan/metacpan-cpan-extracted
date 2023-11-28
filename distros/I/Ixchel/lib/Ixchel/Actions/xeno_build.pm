package Ixchel::Actions::xeno_build;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use String::ShellQuote;
use Rex::Commands::Gather;
use File::Temp qw/ tempdir /;
use Rex::Commands::Pkg;
use LWP::Simple;
use Ixchel::functions::perl_module_via_pkg;
use Ixchel::functions::install_cpanm;
use Ixchel::functions::python_module_via_pkg;
use Ixchel::functions::install_pip;
use Cwd;

=head1 NAME

Ixchel::Actions::xeno_build :: Builds and installs stuff based on the supplied hash.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

=head1 OPTIONS

=head2 build_hash

A build hash containing the options to use for installing and building.

=head1 BUILD HASH

=head2  BUILD OPTIONS AND VALUES

=head3 options

    - .options.build_dir :: Build dir to use. If not defined, .config.xeno_options.build_dir
            is used. If that is undef, '/tmp/' is used.
        - Default :: undef

    . options.tmpdir :: The path for a automatically created tmpdir under .options.build_dir.
            This will be removed one once xeno_build has finished running. This allows for easy cleanup
            when using templating with fetch and exec when using templating. This is created via
            L<File::Temp>->newdir.

    - .options.$var :: Additional variable to define.

=head3 order

An array of the order it should process the steps in. The default is as below.

    fetch
    pkgs
    perl
    python
    exec

So lets say you have a .exec in the hash, but .order does not contain 'exec' any place in
the array, then whatever is in .exec will not be processed.

If you want to run exec twice with different values, you can create .exec0 and .exec with
the desired stuff and set the order like below.

    exec0
    pkgs
    exec

First .exec0, then pkgs, and then .exec will be ran. The type is determined via removing
the end from it via the regexp s/[0-9]*$//. So .perl123 would be ran as perl type.

Unknown types will result in an error.

=head3 vars

This is a hash of variables to pass to the template as var.

=head3 templated_vars

These are vars that are to be templated. The output is copied to
the matching name to under vars.

=head2  TYPES

    - .$type.for :: 'for' may be specified for any of the types. It is a
            array of OS families it is for.
        - Default :: undef

=head3 fetch

    - .fetch.items.$name.url :: URL to fetch.

    - .fetch.items.$name.dst :: Where to write it to.

    - .fetch.template :: If the url and dst should be treated as a template.
        - Default :: 0

.fetch.items is a hash for the purpose of allowing it to easily be referenced later in exec. If .fetch.items.$name.url or
.fetch.items.$name.dst is templated, the template output is saved as that variable so it can easily be used in exec.

Variables for template are as below.

    - config :: Ixchel config.

    - options :: Stuff defined via .options.

    - os :: OS as per L<Rex::Commands::Gather>.

=head3 pkgs

    - .pkgs.present :: A hash of arrays. The keys are the OS seen by
            L<Rex::Commands::Gather> and values in the array will be ensured to be
            present via L<Rex::Commands::Pkg>.
        - Default :: undef

    - .pkgs.latest :: A hash of arrays. The keys are the OS seen by
            L<Rex::Commands::Gather> and values in the array will be ensured to be
            latest via L<Rex::Commands::Pkg>.
        - Default :: undef

    - .pkgs.absent :: A hash of arrays. The keys are the OS seen by
            L<Rex::Commands::Gather> and values in the array will be ensured to be
            absent via L<Rex::Commands::Pkg>.

So if you want to install apache24 and exa on FreeBSD and jq on Debian, it would be like below.

    {
        pkgs => {
            latest => {
                FreeBSD => [ 'apache24', 'exa' ],
                Debian => [ 'jq' ],
            },
        },
    }

=head3 perl

    - .perl.modules :: A array of modules to to install via cpanm.
        - Default :: []

    - .perl.reinstall :: A Perl boolean for if it should --reinstall should be passed.
        - Default :: 0

    - .perl.notest :: A Perl boolean for if it should --notest should be passed.
        - Default :: 0

    - .perl.force :: A Perl boolean for if it should --force should be passed.
        - Default :: 0

    - .perl.install :: Ensures that cpanm is installed, which will also ensure that Perl is installed.
            If undef or 0, then cpanm won't be installed and will be assumed to already be present. If
            set to true, it will be installed if anything is specificed in .perl.modules.
        - Default :: 1

    - .perl.cpanm_install :: Install cpanm even if .cpanm.modules does not contain any modules.
        - Default :: 0

    - .perl.pkgs :: A list of modules to install via packages if possible.
        - Default :: []

    - perl.pkgs_always_try :: A Perl boolean for if the array for .cpanm.modules should be appended to
            .cpanm.pkgs.
        - Default :: 1

    - perl.pkgs_require :: A list of modules to install via packages. Will fail if any of these fail.
        - Default :: []

For the packages, if you want to make sure the package DB is up to date, you will want to set
.pkgs.update_package_db_force to "1".

=head3 python

Install python stuff.

    - .python.pip_install :: A Perl boolean for if it should install python. By default only installs
            python and pip if .python.pip[0] or .python.pkgs[0] is defined.
        - Default :: 1

    - .python.modules :: A array items to install via pip.
        - Default :: []

    - .python.pkgs :: A array items to install via packages if possible.
        - Default :: []

    - .python.pkgs_require :: A array items that must be install via pkgs.
        - Default :: []

    - python.pkgs_always_try :: If pkgs should always be tried first prior to pip.
        - Default :: 1

=head3 exec

    - .exec.commands :: A array of hash to use for running commands.
        - Default :: []

    - .exec.command :: A command to run.
        - Default :: undef

    . exec.dir :: Directory to use. If undef, this will use .options.tmpdir .
        - Default :: undef

   - .exec.exits :: A array of acceptable exit values. May start with >, >=, <, or <= .
       - Default :: [0]

   - .exec.template :: If the command in question should be treated as a TT template.
       - Default :: [0]

Either .exec.commands or .exec.command must be used. If .exec.commands is used, each value in
the array is a hash using the same keys, minus .commands, as .exec. So if .exec.commands[0].exits
is undef, then .exec.exits is used as the default.

If .exec.commands[0] or .exec.command is undef, then nothing will be ran and even if .exec exists.
Similarly if .command for a hash under .exec.commands, then nothing will be ran for that hash,
it will be skipped.

=head2 TEMPLATES

Template is done via L<Template> with the base variables being available.

    - config :: The Ixchel config.

    - env :: Enviromental variables.

    - os :: The OS or OS family.

    - vars :: Variables as set in .vars in the build hash.

    - templated_vars :: Templates used for crreating some vars under vars.

    - is_systemd :: If the system looks like it is systemd or not. The value is a boolean
        of 0 or 1.

    - tmpdir :: The path of the tmpdir.

    - options :: The contents of .options .

    - $type_items :: .fetch.items if it exists. $type will be the name of the fetch type entry.
        so 'fetch' will result in 'fetch_items' and 'fetch1' will result in 'fetch1_items'. If
        any of the items were templated, the value here will be the results of the templating.

The following functions are available.

    - shell_quote :: shell_quote from String::ShellQuote

=head1 RESULT HASH REF

    .errors :: A array of errors encountered.
    .status :: A string description of what was done and the results.
    .ok :: True if everyting okay.

=head1 Determining OS

L<Rex::Commands::Gather> is used for this.

First the module get_operating_system is used. Then the following is ran.

    if (is_freebsd) {
        $self->{os}='FreeBSD';
    }elsif (is_debian) {
        $self->{os}='Debian';
    }elsif (is_redhat) {
        $self->{os}='Redhat';
    }elsif (is_arch) {
        $self->{os}='Arch';
    }elsif (is_suse) {
        $self->{os}='Suse';
    }elsif (is_alt) {
        $self->{os}='Alt';
    }elsif (is_netbsd) {
        $self->{os}='NetBSD';
    }elsif (is_openbsd) {
        $self->{os}='OpenBSD';
    }elsif (is_mageia) {
        $self->{os}='Mageia';
    }elsif (is_void) {
        $self->{os}='Void';
    }else{
        $self->{os}=get_operating_system;
    }

Which will set it to that if one of those matches.

=head1 EXAMPLE

Below is a example for installing Sagan on Debian and FreeBSD.

    ---
    templated_vars:
      github_ref: '[% IF env.sagan_github_ref %][% env.sagan_github_ref %][% ELSE %]main[% END %]'
    fetch:
      items:
        sagan:
          url: '[% IF env.sagan_url  %][% env.sagan_url %][% ELSE %]https://api.github.com/repos/quadrantsec/sagan/tarball/[% vars.github_ref %][% END %]'
          dst: 'sagan.tgz'
      template: 1
    exec:
      commands:
        - command: 'tar -zxvf sagan.tgz'
        - command: 'mv `ls -d *sagan-*` sagan'
        - command: autoreconf -vfi -I m4
          dir: sagan
        - command: ./configure --enable-bluedot --enable-geoip --enable-redis --enable-esmtp --enable-gzip
        - command: make -j5
        - command: make install
        - command: make -j5
          dir: cd tools
        - command: make install
        - command: '[% IF env.sagan_restart %]killall SaganMain[% ELSE %]echo not restarting[% END %]'
      template: 1
    pkgs:
      present:
        FreeBSD:
          - liblognorm
          - pcre
          - libesmtp
          - hiredis
          - json-c
          - libmaxminddb
        Debian:
          - liblognrom-dev
          - libpcre3-dev
          - build-eesential
          - libesmtp-dev
          - libhiredis-dev
          - libjson-c-dev
          - libmaxminddb-dev

=cut

sub new {
	my ( $empty, %opts ) = @_;

	my $self = {
		config        => {},
		vars          => {},
		arggv         => [],
		opts          => {},
		os            => $^O,
		template_vars => {
			shell_quote    => \&shell_quote,
			env            => \%ENV,
			vars           => {},
			templated_vars => {},
		},
	};
	bless $self;
	# in two places as .template_vars will get passed to TT
	$self->{template_vars}{config} = $self->{config};
	# having it in two places for the purposes of simplicity
	$self->{template_vars}{os} = $self->{os};

	if (is_freebsd) {
		$self->{os} = 'FreeBSD';
	} elsif (is_debian) {
		$self->{os} = 'Debian';
	} elsif (is_redhat) {
		$self->{os} = 'Redhat';
	} elsif (is_arch) {
		$self->{os} = 'Arch';
	} elsif (is_suse) {
		$self->{os} = 'Suse';
	} elsif (is_alt) {
		$self->{os} = 'Alt';
	} elsif (is_netbsd) {
		$self->{os} = 'NetBSD';
	} elsif (is_openbsd) {
		$self->{os} = 'OpenBSD';
	} elsif (is_mageia) {
		$self->{os} = 'Mageia';
	} elsif (is_void) {
		$self->{os} = 'Void';
	} else {
		$self->{os} = get_operating_system;
	}

	$self->{template_vars}{os} = $self->{os};

	# set is_systemd template var
	if ( $^O eq 'linux' && ( -f '/usr/bin/systemctl' || -f '/bin/systemctl' ) ) {
		$self->{template_vars}{is_systemd} = 1;
	} else {
		$self->{template_vars}{is_systemd} = 0;
	}

	if ( defined( $opts{config} ) ) {
		$self->{config} = $opts{config};
	}
	$self->{template_vars} = $self->{config};

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
		errors => [],
		status => '',
		ok     => 0,
	};

	# if this is not set, no reason to continue
	if ( !defined( $self->{opts}{xeno_build} ) ) {
		push( @{ $self->{results}{errors} }, '.opts.xeno_build was not set' );
		return $self->{results};
	}

	# copy vars under xeno_build if it exists
	if ( defined( $self->{opts}{xeno_build}{vars} ) ) {
		$self->{template_vars}{vars} = $self->{opts}{xeno_build}{vars};
	}

	# process templated_vars
	if ( defined( $self->{opts}{xeno_build}{templated_vars} ) ) {
		my @templated_vars = sort( keys( %{ $self->{opts}{xeno_build}{templated_vars} } ) );
		$self->status_add( type => 'templated_vars', status => 'Vars to tempplate: ' . join( ',', @templated_vars ) );
		eval {
			foreach my $var (@templated_vars) {
				my $output       = '';
				my $var_template = $self->{opts}{xeno_build}{templated_vars}{$var};
				$self->status_add(
					type   => 'templated_vars',
					status => 'Templated Var "' . $var . '": ' . $var_template
				);
				$self->{t}->process( \$var_template, $self->{template_vars}, \$output )
					|| die $self->{t}->error;
				$self->{opts}{xeno_build}{vars}{$var} = $output;
				$self->status_add( type => 'templated_vars', status => 'Updated Var "' . $var . '": ' . $output );
			} ## end foreach my $var (@templated_vars)
		};
		if ($@) {
			$self->status_add( type => 'templated_vars', error => 1, status => 'Vars templating failed... ' . $@ );
			return $self->{results};
		}
		$self->{template_vars}{vars} = $self->{opts}{xeno_build}{vars};
	} ## end if ( defined( $self->{opts}{xeno_build}{templated_vars...}))

	# define the order if not specified
	if ( !defined( $self->{opts}{xeno_build}{order} ) ) {
		$self->{opts}{xeno_build}{order} = [ 'fetch', 'pkgs', 'perl', 'python', 'exec', ];
	}
	$self->status_add( status => 'Order: ' . join( ', ', @{ $self->{opts}{xeno_build}{order} } ) );

	# set default options if needed
	if ( !defined( $self->{opts}{xeno_build}{options} ) ) {
		$self->{opts}{xeno_build}{options} = {};
	}
	# if the build_dir is not set, set it
	if ( !defined( $self->{opts}{xeno_build}{options}{build_dir} ) ) {
		# if .xeno_build.build_dir is set in the config, use it
		if ( defined( $self->{config}{xeno_build}{build_dir} ) ) {
			$self->{opts}{xeno_build}{options}{build_dir} = $self->{config}{xeno_build}{build_dir};
		} else {
			# if that is undef, use /tmp/
			$self->{opts}{xeno_build}{options}{build_dir} = '/tmp/';
		}
	}

	# create the tmpdir under the build dir
	$self->{opts}{xeno_build}{options}{tmpdir}
		= File::Temp->newdir( DIR => $self->{opts}{xeno_build}{options}{build_dir} );
	# now that options are setup, save it as a usable template variable
	$self->{template_vars}{options} = $self->{opts}{xeno_build}{options};
	$self->{template_vars}{tmpdir}  = $self->{opts}{xeno_build}{options}{tmpdir};
	$self->status_add( status => 'Build Dir, .options.build_dir: ' . $self->{opts}{xeno_build}{options}{build_dir} );
	$self->status_add( status => 'Temp Dir, .options.tmpdir: ' . $self->{opts}{xeno_build}{options}{tmpdir} );

	eval { chdir( $self->{opts}{xeno_build}{options}{tmpdir} ); };
	if ($@) {
		$self->status_add(
			status => 'Failed to chdir to "' . $self->{opts}{xeno_build}{options}{tmpdir} . '"',
			error  => 1,
		);
		return $self->{results};
	}

	# figure out the types we are going to use
	my @types;
	foreach my $type ( @{ $self->{opts}{xeno_build}{order} } ) {
		# make sure it is known
		if (   $type !~ /^fetch[0-9]*$/
			&& $type !~ /^pkgs[0-9]*$/
			&& $type !~ /^perl[0-9]*$/
			&& $type !~ /^python[0-9]*$/
			&& $type !~ /^exec[0-9]*$/ )
		{
			$self->status_add( status => '"' . $type . '" is not of a known type', error => 1 );
			return $self->{results};
		}
		# if it exists, add it to the @types array
		if ( defined $self->{opts}{xeno_build}{$type} ) {
			push( @types, $type );
		}
	} ## end foreach my $type ( @{ $self->{opts}{xeno_build}...})

	foreach my $type (@types) {
		$self->status_add( status => 'Starting type "' . $type . '"...' );

		my $for_this_system = 1;

		if ( defined( $self->{opts}{xeno_build}{$type}{for} ) ) {
			$for_this_system = 0;
			my @for_oses = @{ $self->{opts}{xeno_build}{$type}{for} };
			$self->status_add( type => $type, status => 'For OSes: ' . join( ',', @for_oses ) );
			foreach my $for_os_check (@for_oses) {
				if ( $for_os_check eq $self->{os} ) {
					$self->status_add( type => $type, status => 'For matched' );
					$for_this_system = 1;
				}
			}
		} ## end if ( defined( $self->{opts}{xeno_build}{$type...}))

		if ( $type =~ /^fetch[0-9]*$/ && $for_this_system ) {
			##
			##
			##
			## start of fetch
			##
			##
			##

			# get the names of the items to fetch
			my @fetch_names;
			if ( defined( $self->{opts}{xeno_build}{$type}{items} ) ) {
				@fetch_names = keys( %{ $self->{opts}{xeno_build}{$type}{items} } );
			}
			if ( defined( $fetch_names[0] ) ) {
				$self->status_add( type => $type, status => 'Items to fetch: ' . join( ', ', @fetch_names ) );
			} else {
				$self->status_add( type => $type, status => 'Nothing to fetch.' );
			}
			# figure out if we should template it or not
			my $template_it = 0;
			if ( defined( $self->{opts}{xeno_build}{$type}{template} ) ) {
				$template_it = $self->{opts}{xeno_build}{$type}{template};
			}
			foreach my $fetch_name (@fetch_names) {
				$self->status_add( type => $type, status => 'Fetching ' . $fetch_name );

				# make sure we have both url and dst for the fetch item
				foreach my $fetch_value ( 'url', 'dst' ) {
					if ( !defined( $self->{opts}{xeno_build}{$type}{items}{$fetch_name}{$fetch_value} ) ) {
						$self->status_add(
							type   => $type,
							status => 'Fetch "' . $fetch_name . '" missing ' . $fetch_value,
							error  => 1
						);
						return $self;
					}
				} ## end foreach my $fetch_value ( 'url', 'dst' )

				$self->status_add( type => $type, status => 'Fetching ' . $fetch_name );
				my $url = $self->{opts}{xeno_build}{$type}{items}{$fetch_name}{url};
				my $dst = $self->{opts}{xeno_build}{$type}{items}{$fetch_name}{dst};
				$self->status_add( type => $type, status => 'Fetch "' . $fetch_name . '" URL: ' . $url );
				$self->status_add( type => $type, status => 'Fetch "' . $fetch_name . '" DST: ' . $dst );
				$self->status_add(
					type   => $type,
					status => 'Fetch "' . $fetch_name . '" Template: ' . $template_it
				);
				if ($template_it) {
					# template the url
					my $output = '';
					eval {
						$self->{t}->process( \$url, $self->{template_vars}, \$output ) || die $self->{t}->error;
						$url = $output;
					};
					if ($@) {
						$self->status_add(
							type   => $type,
							status => 'Templating failed for "' . $fetch_name . ' for the URL"... ' . $@,
							error  => 1,
						);
						return $self->{results};
					}
					$self->{opts}{xeno_build}{$type}{items}{url} = $url;

					# template the dst
					$output = '';
					eval {
						$self->{t}->process( \$dst, $self->{template_vars}, \$output ) || die $self->{t}->error;
						$dst = $output;
					};
					if ($@) {
						$self->status_add(
							type   => $type,
							status => 'Templating failed for "' . $fetch_name . ' for the URL"... ' . $@,
							error  => 1,
						);
						return $self->{results};
					}
					$self->{opts}{xeno_build}{$type}{items}{dst} = $dst;
					$self->status_add(
						type   => $type,
						status => 'Fetch "' . $fetch_name . '" URL Template Results: ' . $url
					);
					$self->status_add(
						type   => $type,
						status => 'Fetch "' . $fetch_name . '" DST Template Results: ' . $dst
					);
				} ## end if ($template_it)
				my $return_code = getstore( $url, $dst );
				$self->status_add(
					type   => $type,
					status => 'Fetch "' . $fetch_name . '" Return Code: ' . $return_code
				);
			} ## end foreach my $fetch_name (@fetch_names)

			# save the fetched items as a template var for possible later usage
			$self->{template_vars}{ $type . '_items' } = $self->{opts}{xeno_build}{$type}{items};
		} elsif ( $type =~ /^pkgs[0-9]*$/ && $for_this_system ) {
			##
			##
			##
			## start of pkgs
			##
			##
			##

			# handle pkgs.absent
			if ( defined( $self->{opts}{xeno_build}{$type}{absent}{ $self->{os} }[0] ) ) {
				foreach my $pkg ( @{ $self->{opts}{xeno_build}{$type}{absent}{ $self->{os} } } ) {
					eval { pkg( $pkg, ensure => 'absent' ); };
					if ($@) {
						$self->status_add(
							type   => $type,
							status => 'Failed uninstalling ' . $pkg . ' for ' . $self->{os},
							error  => 1,
						);
						return $self->{results};
					}
				} ## end foreach my $pkg ( @{ $self->{opts}{xeno_build}{...}})
			} ## end if ( defined( $self->{opts}{xeno_build}{$type...}))

			# handle .pkgs.present
			if (   defined( $self->{opts}{xeno_build}{$type}{present}{ $self->{os} } )
				&& defined( $self->{opts}{xeno_build}{$type}{present}{ $self->{os} }[0] ) )
			{
				foreach my $pkg ( @{ $self->{opts}{xeno_build}{$type}{present}{ $self->{os} } } ) {
					$self->status_add(
						type   => $type,
						status => 'Ensuring ' . $pkg . ' for ' . $self->{os} . ' is present',
					);
					eval { pkg( $pkg, ensure => 'present' ); };
					if ($@) {
						$self->status_add(
							type   => $type,
							status => 'Failed installing ' . $pkg . ' for ' . $self->{os},
							error  => 1,
						);
						return $self->{results};
					}
				} ## end foreach my $pkg ( @{ $self->{opts}{xeno_build}{...}})
			} ## end if ( defined( $self->{opts}{xeno_build}{$type...}))

			# handle .pkgs.latest
			if (   defined( $self->{opts}{xeno_build}{$type}{latest}{ $self->{os} } )
				&& defined( $self->{opts}{xeno_build}{$type}{latest}{ $self->{os} }[0] ) )
			{
				eval {
					$self->status_add( type => $type, status => 'updating DB' );
					update_package_db;
				};
				if ($@) {
					$self->status_add( type => $type, status => 'Pkgs DB update failed...' . $@, error => 1, );
				}
				foreach my $pkg ( @{ $self->{opts}{xeno_build}{$type}{latest}{ $self->{os} } } ) {
					$self->status_add(
						type   => $type,
						status => 'Ensuring latest ' . $pkg . ' for ' . $self->{os} . ' is installed',
					);
					eval { pkg( $pkg, ensure => 'latest' ); };
					if ($@) {
						$self->status_add(
							type   => $type,
							status => 'Failed installing latest ' . $pkg . ' for ' . $self->{os},
							error  => 1,
						);
						return $self->{results};
					}
				} ## end foreach my $pkg ( @{ $self->{opts}{xeno_build}{...}})
			} ## end if ( defined( $self->{opts}{xeno_build}{$type...}))
		} elsif ( $type =~ /^perl[0-9]*$/ && $for_this_system ) {
			##
			##
			##
			## start of perl
			##
			##
			##

			my @modules;
			if ( defined( $self->{opts}{xeno_build}{$type}{modules} ) ) {
				push( @modules, @{ $self->{opts}{xeno_build}{$type}{modules} } );
			}
			$self->status_add(
				type   => $type,
				status => 'Perl modules to install: ' . join( ', ', @modules ),
			);

			# get a list of modules to install via pkgs
			my @pkgs;
			if ( defined( $self->{opts}{xeno_build}{$type}{pkgs} ) ) {
				push( @pkgs, @{ $self->{opts}{xeno_build}{$type}{pkgs} } );
				$self->status_add(
					type   => $type,
					status => 'Perl modules to try to install via pkgs: ' . join( ', ', @pkgs ),
				);
			}

			# pkgs_always_try is true, push the modules to onto the heap
			if (
				(
					defined( $self->{opts}{xeno_build}{$type}{pkgs_always_try} )
					&& $self->{opts}{xeno_build}{$type}{pkgs_always_try}
				)
				|| ( !defined( $self->{opts}{xeno_build}{$type}{pkgs_always_try} ) )
				)
			{
				push( @pkgs, @modules );
				$self->status_add(
					type   => $type,
					status => 'pkgs_always_try=1 set',
				);
			} ## end if ( ( defined( $self->{opts}{xeno_build}{...})))

			# used for checking if the module was installed or not via pkg
			my %modules_installed;

			# handle Perl modules that must be installed via pkg
			my @pkgs_require;
			if ( defined( $self->{opts}{xeno_build}{$type}{pkgs_require} ) ) {
				push( @pkgs_require, @{ $self->{opts}{xeno_build}{$type}{pkgs_require} } );
				$self->status_add(
					type   => $type,
					status => 'Perl modules required to be installed via pkgs: ' . join( ', ', @pkgs_require ),
				);
			}
			foreach my $module ( @pkgs_require, ) {
				$self->status_add(
					type   => $type,
					status => 'Trying to install Perl ' . $module . ' via pkg',
				);
				my $returned = perl_module_via_pkg( module => $module );
				# if this fails, set error and return as the module is required to be installed via pkg and we can't
				if ($returned) {
					$self->status_add(
						type   => $type,
						status => 'Perl module required to be installed via pkgs installed: ' . $module,
					);
					$modules_installed{$module} = 1;
				} else {
					$self->status_add(
						type   => $type,
						status => 'Perl module required to be installed via pkgs failed: ' . $module,
						error  => 1,
					);
					return $self->{results};
				}
			} ## end foreach my $module ( @pkgs_require, )

			# try via pkg modules that can be attempted to be installed that way
			foreach my $module (@pkgs) {
				$self->status_add(
					type   => $type,
					status => 'Trying to install Perl ' . $module . ' via pkg',
				);
				my $returned = perl_module_via_pkg( module => $module );
				if ($returned) {
					$self->status_add(
						type   => $type,
						status => 'Perl module to be installed via pkgs installed: ' . $module,
					);
					$modules_installed{$module} = 1;
				}
			} ## end foreach my $module (@pkgs)

			my $installed_cpanm;
			# if we don't want to install cpanm, set it as already as being installed
			if ( defined( $self->{opts}{xeno_build}{$type}{cpanm_install} )
				&& $self->{opts}{xeno_build}{$type}{cpanm_install} )
			{
				eval { install_cpanm; };
				if ($@) {
					$self->status_add(
						type   => $type,
						status => 'Failed installing cpanm for ' . $self->{os} . ' ... ' . $@,
						error  => 1,
					);
					return $self->{results};
				}
				$installed_cpanm = 1;
			} ## end if ( defined( $self->{opts}{xeno_build}{$type...}))

			# try to install each module
			foreach my $module (@modules) {
				# if this is defined, it was installed via pkg, so we don't need to try it again
				if ( !defined( $modules_installed{$module} ) ) {
					if ( !$installed_cpanm ) {
						eval { install_cpanm; };
						if ($@) {
							$self->status_add(
								type   => $type,
								status => 'Failed installing cpanm for ' . $self->{os} . ' ... ' . $@,
								error  => 1,
							);
							return $self->{results};
						}
					} ## end if ( !$installed_cpanm )

					my @cpanm_args = ('cpanm');
					if ( defined( $self->{opts}{xeno_build}{$type}{reinstall} )
						&& $self->{opts}{xeno_build}{$type}{reinstall} )
					{
						push( @cpanm_args, '--reinstall' );
					}
					if ( defined( $self->{opts}{xeno_build}{$type}{notest} )
						&& $self->{opts}{xeno_build}{$type}{notest} )
					{
						push( @cpanm_args, '--notest' );
					}
					if ( defined( $self->{opts}{xeno_build}{$type}{install_force} )
						&& $self->{opts}{xeno_build}{$type}{install_force} )
					{
						push( @cpanm_args, '--force' );
					}
					push( @cpanm_args, $module );
					$self->status_add(
						type   => $type,
						status => 'invoking cpanm: ' . join( ' ', @cpanm_args ),
					);
					system(@cpanm_args);
					if ( $? != 0 ) {
						$self->status_add(
							type   => $type,
							status => 'cpanm failed: ' . join( ' ', @cpanm_args ),
							error  => 1,
						);
						return $self->{results};
					}
				} ## end if ( !defined( $modules_installed{$module}...))
			} ## end foreach my $module (@modules)
		} elsif ( $type =~ /^python[0-9]*$/ && $for_this_system ) {
			##
			##
			##
			## start of python
			##
			##
			##

			# keeps track of what was installed
			my %installed;

			# tracks if pip was already installed or not
			my $pip_installed = 0;
			if ( defined( $self->{opts}{xeno_build}{$type}{pip_install} )
				&& !$self->{opts}{xeno_build}{$type}{pip_install} )
			{
				$pip_installed = 1;
			}

			# holds a list of package to be installed
			my @modules;
			if (   defined( $self->{opts}{xeno_build}{$type}{pip} )
				&& defined( $self->{opts}{xeno_build}{$type}{pip}[0] ) )
			{
				push( @modules, @{ $self->{opts}{xeno_build}{$type}{pip} } );
			}

			# handle stuff that is required to be installed via packages
			if (   defined( $self->{opts}{xeno_build}{$type}{pkgs_require} )
				&& defined( $self->{opts}{xeno_build}{$type}{pkgs_require}[0] ) )
			{
				my @pkgs_require;
				push( @pkgs_require, @{ $self->{opts}{xeno_build}{$type}{pkgs_require} } );
				foreach my $module (@pkgs_require) {
					eval { python_module_via_pkg( module => $module ) };
					if ($@) {
						$self->status_add(
							type   => $type,
							error  => 1,
							status => 'Failed to install required python module "' . $module . '" pkgs... ' . $@,
						);
						return $self->{results};
					}
				} ## end foreach my $module (@pkgs_require)
			} ## end if ( defined( $self->{opts}{xeno_build}{$type...}))

			# try to add packages for various modules
			my @pkgs;
			if (   defined( $self->{opts}{xeno_build}{$type}{pkgs} )
				&& defined( $self->{opts}{xeno_build}{$type}{pkgs}[0] ) )
			{
				push( @pkgs, @{ $self->{opts}{xeno_build}{$type}{pkgs} } );
			}
			if ( defined( $pkgs[0] ) ) {
				foreach my $module (@pkgs) {
					eval { python_module_via_pkg( module => $module ) };
					if ($@) {
						push( @modules, $pkg );
					} else {
						$installed{$module} = 1;
					}
				}
			} ## end if ( defined( $pkgs[0] ) )

			# install all modules for python via pip, including ones that could not be installed via packages
			foreach my $module (@modules) {
				if ( !$installed{$module} ) {
					if ( !$pip_installed ) {
						eval { install_pip; };
						if ($@) {
							$self->status_add(
								type   => $type,
								status => 'Installing pip failed... ' . $@,
								error  => 1,
							);
							return $self->{results};
						}
						my @pip_cmd;
						my $pip3 = `which pip3 2> /dev/null`;
						if ( $? == 0 ) {
							push( @pip_cmd, 'pip3', 'install', $module );
						} else {
							push( @pip_cmd, 'pip', 'install', $module );
						}
						$self->status_add(
							type   => $type,
							status => 'invoking pip: ' . join( ' ', @pip_cmd ),
						);
						system(@pip_cmd);
						if ( $? != 0 ) {
							$self->status_add(
								type   => $type,
								status => 'pip failed: ' . join( ' ', @pip_cmd ),
								error  => 1,
							);
							return $self->{results};
						}
					} ## end if ( !$pip_installed )
				} ## end if ( !$installed{$module} )
			} ## end foreach my $module (@modules)

		} elsif ( $type =~ /^exec[0-9]*$/ && $for_this_system ) {
			##
			##
			##
			## start of exec
			##
			##
			##
			my @commands;
			# if we have the default command, add it to the stack
			if ( defined( $self->{opts}{xeno_build}{$type}{command} ) ) {
				push( @commands, { command => $self->{opts}{xeno_build}{$type}{command} } );
			}

			# if .exec.commands exists shove it onto the stack
			if (   defined( $self->{opts}{xeno_build}{$type}{commands} )
				&& defined( $self->{opts}{xeno_build}{$type}{commands}[0] ) )
			{
				push( @commands, @{ $self->{opts}{xeno_build}{$type}{commands} } );
			}

			# process each command
			my @to_possibly_copy = ( 'command', 'exits', 'template', 'for', 'dir' );
			my $command_int      = 0;
			foreach my $command_hash (@commands) {
				if (   defined( $self->{opts}{xeno_build}{$type}{command} )
					|| defined( $command_hash->{command} ) )
				{
					foreach my $to_copy (@to_possibly_copy) {
						if (  !defined( $command_hash->{$to_copy} )
							&& defined( $self->{opts}{xeno_build}{$type}{$to_copy} ) )
						{
							$command_hash->{$to_copy} = $self->{opts}{xeno_build}{$type}{$to_copy};
						} elsif ( !defined( $command_hash->{$to_copy} )
							&& !defined( $self->{opts}{xeno_build}{$type}{$to_copy} ) )
						{
							if ( $to_copy eq 'exits' ) {
								$command_hash->{exits} = [0];
							} elsif ( $to_copy eq 'template' ) {
								$command_hash->{template} = 0;
							} elsif ( $to_copy eq 'for' ) {
								$command_hash->{for} = [];
							}
						} ## end elsif ( !defined( $command_hash->{$to_copy} )...)
					} ## end foreach my $to_copy (@to_possibly_copy)

					$self->status_add(
						type   => $type,
						status => 'exec[' . $command_int . '] command: ' . $command_hash->{command},
					);

					$self->status_add(
						type   => $type,
						status => 'exec['
							. $command_int
							. '] ok exits: '
							. join( ',', @{ $command_hash->{exits} } ),
					);

					# if requested to template it, process the command and dir
					if ( $command_hash->{template} ) {
						eval {
							my $output  = '';
							my $command = $command_hash->{command};
							$self->{t}->process( \$command, $self->{template_vars}, \$output )
								|| die $self->{t}->error;
							$command_hash->{command} = $output;

							$output = '';
							my $dir = $command_hash->{dir};
							$self->{t}->process( \$dir, $self->{template_vars}, \$output )
								|| die $self->{t}->error;
							$command_hash->{dir} = $output;
						};
						if ($@) {
							$self->status_add(
								type   => $type,
								status => 'Templating failed... ' . $@,
								error  => 1,
							);
							return $self->{results};
						}
						$self->status_add(
							type   => $type,
							status => 'Templated: ' . $command_hash->{command},
						);
					} ## end if ( $command_hash->{template} )

					# chdir to the dir specified if needed
					if ( $command_hash->{dir} ) {
						eval { chdir( $command_hash->{dir} ); };
						if ($@) {
							$self->status_add(
								type   => $type,
								status => 'Failed to chdir to "' . $command_hash->{dir} . '"',
								error  => 1,
							);
							return $self->{results};
						}
					} ## end if ( $command_hash->{dir} )

					# if the current dir
					if ( getcwd ne $self->{opts}{xeno_build}{options}{tmpdir} ) {
						$self->status_add( type => $type, status => 'exec[' . $command_int . '] dir: ' . getcwd, );
					}

					system( $command_hash->{command} );
					my $exit_code;
					if ( $? == -1 ) {
						$exit_code = -1;
					} else {
						$exit_code = $? >> 8;
					}
					my $exit_code_matched = 0;
					foreach my $desired_exit_code ( @{ $command_hash->{exits} } ) {
						if ( $exit_code == $desired_exit_code ) {
							$exit_code_matched = 1;
						}
					}
					if ( !$exit_code_matched ) {
						$self->status_add(
							type   => $type,
							status => 'Exit code mismatch... desired='
								. join( ',', @{ $command_hash->{exits} } )
								. ' actual='
								. $exit_code
								. ' command="'
								. $command_hash->{command} . '"',
							error => 1,
						);
						return $self->{results};
					} ## end if ( !$exit_code_matched )

				} ## end if ( defined( $self->{opts}{xeno_build}{$type...}))

				$command_int++;
			} ## end foreach my $command_hash (@commands)

		} elsif ( !$for_this_system ) {
			$self->status_add( type => $type, status => 'Not for this system' );
		}
	} ## end foreach my $type (@types)

	chdir( $self->{opts}{xeno_build}{options}{tmpdir} . '/..' );

	return $self->{results};
} ## end sub action

sub help {
	return 'Builds/installs stuff based on a passed hash ref.

Not usable directly. Use xeno action.

See perldoc Ixchel::Actions::xeno_build for more details.
';
}

sub short {
	return 'Builds/installs stuff based on a passed hash ref. Not usable directly. Use xeno action.';
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
		$opts{type} = 'xeno_build';
	}

	my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime(time);
	my $timestamp = sprintf( "%04d-%02d-%02dT%02d:%02d:%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec );

	my $status = '[' . $timestamp . '] [' . $opts{type} . ', ' . $opts{error} . '] ' . $opts{status};

	print $status. "\n";

	$self->{results}{status} = $self->{results}{status} . $status;

	if ( $opts{error} ) {
		push( @{ $self->{results}{errors} }, $opts{status} );
		chdir( $self->{opts}{xeno_build}{options}{tmpdir} . '/..' );
	}
} ## end sub status_add

1;
