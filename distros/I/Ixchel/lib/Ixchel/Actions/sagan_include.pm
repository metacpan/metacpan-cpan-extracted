package Ixchel::Actions::sagan_include;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use YAML::XS qw(Dump);
use File::Spec;
use base 'Ixchel::Actions::base';

=head1 NAME

Ixchel::Actions::sagan_include - Generates the instance specific include for a sagan instance.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 CLI SYNOPSIS

ixchel -a sagan_include [B<--np>] [B<-w>] [B<-i> <instance>]

=head1 CODE SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'sagan_include', opts=>{ w=>1, });

    print Dumper($results);

=head1 DESCRIPTION

Generates the Sagan include config.

The base include used is .sagan.config. If .sagan.multi_instance is set to 1,
then .sagan.instances.$instance is merged on top of it using L<HASH::Merge>
with RIGHT_PRECEDENT as below with arrays being replaced.

```
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
```

If told to write it out, .sagan.config_base is used as the base directory to write
to with the file name being 'sagan-include.yaml' or in the case of multi instance
"sagan-include-$instance.yaml".

.include is set to .sagan.config_base.'/sagan-rules.yaml' in the case of single
instance setups if .sagan.multi_instance is set to 1 then
.sagan.config_base."/sagan-rules-$instance.yaml"

=head1 FLAGS

=head2 -w

Write out the configs.

=head2 -i instance

A instance to operate on.

=head1 RESULT HASH REF

    .errors :: A array of errors encountered.
    .status_text :: A string description of what was done and teh results.
    .ok :: Set to zero if any of the above errored.

=cut

sub new_extra { }

sub action_extra {
	my $self = $_[0];

	my $config_base = $self->{config}{sagan}{config_base};

	if ( $self->{config}{sagan}{multi_instance} ) {
		my @instances;

		if ( defined( $self->{opts}{i} ) ) {
			@instances = ( $self->{opts}{i} );
		} else {
			@instances = keys( %{ $self->{config}{sagan}{instances} } );
		}
		foreach my $instance (@instances) {
			my $filled_in;
			eval {
				my $base_config = $self->{config}{sagan}{config};

				if ( !defined( $self->{config}{sagan}{instances}{$instance} ) ) {
					die( $instance . ' does not exist under .sagan.instances' );
				}

				my $config = $self->{config}{sagan}{instances}{$instance};

				my $merger = Hash::Merge->new('RIGHT_PRECEDENT');
				# # make sure arrays from the actual config replace any arrays in the defaultconfig
				# $merger->add_behavior_spec(
				# 	{
				# 		'SCALAR' => {
				# 			'SCALAR' => sub { $_[1] },
				# 			'ARRAY'  => sub { [ $_[0], @{ $_[1] } ] },
				# 			'HASH'   => sub { $_[1] },
				# 		},
				# 		'ARRAY' => {
				# 			'SCALAR' => sub { $_[1] },
				# 			'ARRAY'  => sub { [ @{ $_[1] } ] },
				# 			'HASH'   => sub { $_[1] },
				# 		},
				# 		'HASH' => {
				# 			'SCALAR' => sub { $_[1] },
				# 			'ARRAY'  => sub { [ values %{ $_[0] }, @{ $_[1] } ] },
				# 			'HASH'   => sub { Hash::Merge::_merge_hashes( $_[0], $_[1] ) },
				# 		},
				# 	},
				# 	'Ixchel',
				# 						   );
				my %tmp_config      = %{$config};
				my %tmp_base_config = %{$base_config};
				my $merged          = $merger->merge( \%tmp_base_config, \%tmp_config );

				$merged->{include} = File::Spec->canonpath( $config_base . '/sagan-rules-' . $instance . '.yaml' );

				$filled_in = '%YAML 1.1' . "\n" . Dump($merged);

				if ( $self->{opts}{w} ) {
					write_file( $config_base . '/sagan-include-' . $instance . '.yaml', $filled_in );
				}
			};
			if ($@) {
				$self->status_add(
					error  => 1,
					status => '-----[ Errored: '
						. $instance
						. ' ]-------------------------------------' . "\n" . '# '
						. $@ . "\n"
				);
			} else {
				$self->status_add( status => '-----[ '
						. $instance
						. ' ]-------------------------------------' . "\n"
						. $filled_in
						. "\n" );
			}

		} ## end foreach my $instance (@instances)
	} else {
		if ( defined( $self->{opts}{i} ) ) {
			$self->status_add(
				error  => 1,
				status => '-i may not be used in single instance mode, .sagan.multi_instance=0'
			);
			return undef;
		}

		my $filled_in;
		eval {
			my $config = $self->{config}{sagan}{config};

			$config->{include} = File::Spec->canonpath( $config_base . '/sagan-rules.yaml' );

			$filled_in = '%YAML 1.1' . "\n" . Dump($config);

			if ( $self->{opts}{w} ) {
				write_file( $config_base . '/include.yaml', $filled_in );
			}
		};
		if ($@) {
			$self->status_add(
				error  => 1,
				status => 'Errored ... ' . $@
			);
		} else {
			$self->status_add( status => "Filled in ... \n" . $filled_in );
		}
	} ## end else [ if ( $self->{config}{sagan}{multi_instance...})]

	return undef;
} ## end sub action_extra

sub short {
	return 'Generates the instance specific include for a sagan instance.';
}

sub opts_data {
	return 'i=s
w
';
}

1;
