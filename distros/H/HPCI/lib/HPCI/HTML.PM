package HPCI::HTML;

### INCLUDES ######################################################################################

# safe Perl
use warnings;
use strict;
use Carp;
use File::Path qw(make_path remove_tree);
use DateTime;
use MooseX::Types::Path::Class qw(Dir File);

use Moose;

has 'html_report_name' => (
	is        => 'ro',
	isa       => 'Str',
	init_arg  => undef,  # TODO: not supported yet
	predicate => 'generate_html_report',
);

has 'html_report_parent_url' => (
	is      => 'ro',
	isa     => 'Str',
	lazy    => 1,
	default => 'https://boutroslab.res.oicr.on.ca/NightlyBuildReport/Resources/ogeeze/reports',
);

has 'html_report_url' => (
	is      => 'ro',
	isa     => 'Str',
	lazy    => 1,
	init_arg => undef,
	default => sub {
		my $self = shift;
		return $self->html_report_parent_url . '/' . $self->html_report_name;
	},
);

has 'html_report_parent_directory' => (
	is      => 'ro',
	isa     => 'Path::Class::Dir',
	coerce  => 1,
	lazy    => 1,
	default => sub {
		Dir->new(
			'/.mounts/labs/boutroslab/public/NightlyBuildReport/Resources/ogeeze/reports'
		);
	},
);

has 'html_report_directory' => (
	is      => 'ro',
	isa     => 'Path::Class::Dir',
	coerce  => 1,
	lazy    => 1,
	default => sub {
		my $self = shift;
		my $clean_name = $self->html_report_name;
		$clean_name    =~ s/[^A-Za-z0-9\-\.\_]//g;
		my $username   = getpwent();
		$self->html_report_parent_directory->subdir( "$username-$clean_name" );
	},
);

has 'html_report_filename' => (
	is      => 'ro',
	isa     => 'Str',
	lazy    => 1,
	default => "report.html",
);

has 'html_report_path' => (
	is       => 'ro',
	isa      => 'Str',
	lazy     => 1,
	init_arg => undef,
	default  => sub {
		my $self = shift;
		my $dir  = $self->html_report_directory;
		make_path($dir->stringify);
		return $dir->file( $self->html_report_filename )->stringify;
	},
);

1;
