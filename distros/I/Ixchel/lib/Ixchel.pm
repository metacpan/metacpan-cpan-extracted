package Ixchel;

use 5.006;
use strict;
use warnings;
use Template;
use File::ShareDir ":ALL";
use Getopt::Long;
use Ixchel::DefaultConfig;
use Hash::Merge;

=head1 NAME

Ixchel - Automate various sys admin stuff.

=head1 VERSION

Version 0.7.0

=cut

our $VERSION = '0.7.0';

=head1 METHODS

=head2 new

Initiates a new instance of Ixchel.

One option argument is taken and that is a hash ref
named config.

    my $ixchel=Ixchel->new( config=>$config );

If config is defined, it will be merged with Ixchel::DefaultConfig via
Hash::Merge using the following behavior.

			{
				'SCALAR' => {
					'SCALAR' => sub { $_[1] },
					'ARRAY'  => sub { [ $_[0], @{ $_[1] } ] },
					'HASH'   => sub { $_[1] },
				},
				'ARRAY' => {
					'SCALAR' => sub { $_[1] },
					'ARRAY'  => sub { [ @{ $_[1] } ] },
					'HASH'   => sub { $_[1] },
				},
				'HASH' => {
					'SCALAR' => sub { $_[1] },
					'ARRAY'  => sub { [ values %{ $_[0] }, @{ $_[1] } ] },
					'HASH'   => sub { Hash::Merge::_merge_hashes( $_[0], $_[1] ) },
				},
			}

Using this, the passed config will be merged into the default config. Worth noting
that any arrays in the default config will be completely replaced by the array from
the passed config.

=cut

sub new {
	my ( $empty, %opts ) = @_;

	my $self = {
		t => Template->new(
			{
				EVAL_PERL    => 1,
				INTERPOLATE  => 0,
				POST_CHOMP   => 1,
				ABSOLUTE     => 1,
				RELATIVE     => 1,
				INCLUDE_PATH => dist_dir("Ixchel") . '/templates/',
			}
		),
		share_dir     => dist_dir("Ixchel"),
		options_array => undef,
		errors_count  => 0,
	};
	bless $self;

	my %default_config = %{ Ixchel::DefaultConfig->get };
	if ( defined( $opts{config} ) ) {
		my $merger = Hash::Merge->new('RIGHT_PRECEDENT');
		# make sure arrays from the actual config replace any arrays in the defaultconfig
		$merger->add_behavior_spec(
			{
				'SCALAR' => {
					'SCALAR' => sub { $_[1] },
					'ARRAY'  => sub { [ $_[0], @{ $_[1] } ] },
					'HASH'   => sub { $_[1] },
				},
				'ARRAY' => {
					'SCALAR' => sub { $_[1] },
					'ARRAY'  => sub { [ @{ $_[1] } ] },
					'HASH'   => sub { $_[1] },
				},
				'HASH' => {
					'SCALAR' => sub { $_[1] },
					'ARRAY'  => sub { [ values %{ $_[0] }, @{ $_[1] } ] },
					'HASH'   => sub { Hash::Merge::_merge_hashes( $_[0], $_[1] ) },
				},
			},
			'Ixchel',
		);
		my %tmp_config = %{ $opts{config} };
		my %tmp_shash  = %{ $merger->merge( \%default_config, \%tmp_config ) };

		$self->{config} = \%tmp_shash;
	} else {
		$self->{config} = \%default_config;
	}

	return $self;
} ## end sub new

=head2 action

The action to perform.

    - action :: The action to perform. This a required variable.
      Default :: undef

    - opts :: What to pass for opts. If not defined, GetOptions will be used to parse the options
              based on the options as defined by the action in question. If passing one manually this
              should be be a hash ref as would be return via GetOptions.
      Default :: undef

    - argv :: What to use for ARGV instead of @ARGV.
      Default :: undef

    - no_die_on_error :: If the return from the action is a hash ref, check if $returned->{errors} is a array
          if it is then it will die with those be used in the die message.
      Default :: 1

So if you want to render the template akin to '-a template -t extend_logsize' you can do it like below.

    my $rendered_template=$ixchel->action( action=>'template', opts=>{ t=>'extend_logsize' });

Now if we want to pass '--np' to not print it, we would do it like below.

    my $rendered_template=$ixchel->action( action=>'template', opts=>{ t=>'extend_logsize', np=>1 });

If the following values are defined, the matching ENVs are set.

    .proxy.ftp       ->  FTP_PROXY, ftp_proxy
    .proxy.http      ->  HTTP_PROXY, http_proxy
    .proxy.https     ->  HTTPS_PROXY, https_proxy
    .perl.cpanm_home ->  PERL_CPANM_HOME

Additionally any of the variables defined under .env will also be
set. So .env.TMPDIR will set $ENV{TMPDIR}.

=cut

sub action {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{action} ) ) {
		die('No action defined');
	}
	my $action = $opts{action};

	if ( !defined( $opts{no_die_on_error} ) ) {
		$opts{no_die_on_error} = 1;
	}

	# if custom opts are not defined, read the commandline args and fetch what we should use
	my $opts_to_use;
	if ( !defined( $opts{opts} ) ) {
		my %parsed_options;
		# split it appart and remove comments and blank lines
		my $opts_data;
		my $to_eval = 'use Ixchel::Actions::' . $action . '; $opts_data=Ixchel::Actions::' . $action . '->opts_data;';
		eval($to_eval);
		if ( defined($opts_data) ) {
			my @options = split( /\n/, $opts_data );
			@options = grep( !/^#/, @options );
			@options = grep( !/^$/, @options );
			GetOptions( \%parsed_options, @options );
		}
		$opts_to_use = \%parsed_options;
	} else {
		$opts_to_use = $opts{opts};
	}

	# if custom ARGV is specified, use taht
	my $argv_to_use;
	if ( defined( $opts{ARGV} ) ) {
		$argv_to_use = $opts{ARGV};
	} else {
		$argv_to_use = \@ARGV;
	}

	# pass various vars if specified
	my $vars;
	if ( defined( $opts{vars} ) ) {
		$vars = $opts{vars};
	}

	# set the enviromental variables if needed
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
	if ( defined( $self->{config}{perl}{cpanm_home} ) && $self->{config}{perl}{cpanm_home} ne '' ) {
		$ENV{PERL_CPANM_HOME} = $self->{config}{perl}{cpanm_home};
	}
	my @env_keys = keys( %{ $self->{config}{env} } );
	foreach my $env_key (@env_keys) {
		if ( defined( $self->{config}{env}{$env_key} ) && ref( $self->{config}{env}{$env_key} ) eq '' ) {
			$ENV{$env_key} = $self->{config}{env}{$env_key};
		}
	}

	my $action_return;
	my $action_obj;
	my $to_eval
		= 'use Ixchel::Actions::'
		. $action
		. '; $action_obj=Ixchel::Actions::'
		. $action
		. '->new(config=>$self->{config}, t=>$self->{t}, share_dir=>$self->{share_dir}, opts=>$opts_to_use, argv=>$argv_to_use, ixchel=>$self, vars=>$vars,);'
		. '$action_return=$action_obj->action;';
	eval($to_eval);
	if ($@) {
		die( 'Action eval failed... ' . $@ );
	}

	if ( $opts{no_die_on_error} ) {
		if (   ref($action_return) eq 'HASH'
			&& defined( $action_return->{errors} )
			&& ref( $action_return->{errors} ) eq 'ARRAY'
			&& defined( $action_return->{errors}[0] ) )
		{
			die( 'Action returned one or more errors... ' . join( "\n", @{ $action_return->{errors} } ) );
		}
	}

	return $action_return;
} ## end sub action

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ixchel at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ixchel>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ixchel


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Ixchel>

=item * Search CPAN

L<https://metacpan.org/release/Ixchel>

=item * Github

L<https://github.com/LilithSec/Ixchel>

=back

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007


=cut

1;    # End of Ixchel
