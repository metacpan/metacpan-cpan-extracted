package Dist::Inkt::Role::WriteMakefilePL;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.025';

use Moose::Role;
use Types::Standard -types;
use Data::Dump 'pp';
use namespace::autoclean;

sub DYNAMIC_CONFIG_PATH () { 'meta/DYNAMIC_CONFIG.PL' };

has has_shared_files => (
	is      => 'ro',
	isa     => Bool,
	lazy    => 1,
	builder => '_build_has_shared_files',
);

sub _build_has_shared_files
{
	my $self = shift;
	!! $self->sourcefile('share')->is_dir;
}

has directories_containing_tests => (
	is      => 'ro',
	isa     => ArrayRef,
	lazy    => 1,
	builder => '_build_directories_containing_tests',
);

sub _build_directories_containing_tests
{
	my $self = shift;
	my $rule = Path::Iterator::Rule->new->file->name('*.t');
	my %dirs;
	$dirs{ Path::Tiny->new($_)->relative($self->rootdir)->dirname }++
		for $rule->all( $self->sourcefile('t') );
	[ sort keys %dirs ];
}

has needs_conflict_check_code => (
	is      => 'ro',
	isa     => Bool,
	lazy    => 1,
	builder => '_build_needs_conflict_check_code',
);

sub _build_needs_conflict_check_code
{
	my $self = shift;
	!!grep {
		exists $self->metadata->{prereqs}{$_}
		and exists $self->metadata->{prereqs}{$_}{conflicts}
		and !!scalar keys %{ $self->metadata->{prereqs}{$_}{conflicts} }
	} qw( configure build runtime test develop );
}

has needs_optional_features_code => (
	is      => 'ro',
	isa     => Bool,
	lazy    => 1,
	builder => '_build_needs_optional_features_code',
);

sub _build_needs_optional_features_code
{
	my $self = shift;
	!! %{ $self->metadata->{optional_features} || {} };
}

has needs_fix_makefile_code => (
	is      => 'ro',
	isa     => Bool,
	lazy    => 1,
	builder => '_build_needs_fix_makefile_code',
);

sub _build_needs_fix_makefile_code
{
	my $self = shift;
	!! $self->sourcefile('inc')->is_dir;
}

after PopulateMetadata => sub {
	my $self = shift;
	$self->metadata->{prereqs}{configure}{requires}{'ExtUtils::MakeMaker'} = '6.17'
		if !defined $self->metadata->{prereqs}{configure}{requires}{'ExtUtils::MakeMaker'};
	$self->metadata->{prereqs}{configure}{requires}{'File::ShareDir::Install'} = '0.02'
		if $self->has_shared_files
		&& !defined $self->metadata->{prereqs}{configure}{requires}{'File::ShareDir::Install'};
	$self->metadata->{prereqs}{configure}{recommends}{'CPAN::Meta::Requirements'} = '2.000'
		if $self->needs_conflict_check_code;
	$self->metadata->{dynamic_config} = 1
		if $self->sourcefile(DYNAMIC_CONFIG_PATH)->exists;
	$self->metadata->{dynamic_config} = 1
		if $self->needs_optional_features_code;
};

after BUILD => sub {
	my $self = shift;
	unshift @{ $self->targets }, 'MakefilePL';
};

sub Build_MakefilePL
{
	my $self = shift;
	my $file = $self->targetfile('Makefile.PL');
	$file->exists and return $self->log('Skipping %s; it already exists', $file);
	$self->log('Writing %s', $file);
	
	chomp(
		my $dump = pp( $self->metadata->as_struct({version => '2'}) )
	);

	my $dynamic_config = do
	{
		my $dc = $self->sourcefile(DYNAMIC_CONFIG_PATH);
		$dc->exists ? "\ndo {\n${\ $dc->slurp_utf8 }\n};" : '';
	};

	$self->rights_for_generated_files->{'Makefile.PL'} ||= [
		'Copyright 2020 Toby Inkster.',
		"Software::License::Perl_5"->new({ holder => 'Toby Inkster', year => '2020' }),
	] if !$dynamic_config;

	my $share = '';
	if ($self->has_shared_files)
	{
		$share = "\nuse File::ShareDir::Install;\n"
			. "install_share 'share';\n"
			. "{ package MY; use File::ShareDir::Install qw(postamble) };\n";
	}
	
	my $conflict_check    = $self->needs_conflict_check_code    ? $self->conflict_check_code    : '';
	my $optional_features = $self->needs_optional_features_code ? $self->optional_features_code : '';
	my $fix_makefile      = $self->needs_fix_makefile_code      ? $self->fix_makefile_code : '';
	my $tests             = join(q[ ], map "$_\*.t", @{ $self->directories_containing_tests });
	
	my $makefile = do { local $/ = <DATA> };
	$makefile =~ s/%%%METADATA%%%/$dump/;
	$makefile =~ s/%%%SHARE%%%/$share/;
	$makefile =~ s/%%%TESTS%%%/$tests/;
	$makefile =~ s/%%%DYNAMIC_CONFIG%%%/$dynamic_config/;
	$makefile =~ s/%%%CONFLICT_CHECK%%%/$conflict_check/;
	$makefile =~ s/%%%OPTIONAL_FEATURES%%%/$optional_features/;
	$makefile =~ s/%%%FIX_MAKEFILE%%%/$fix_makefile/;
	$file->spew_utf8($makefile);
}

sub conflict_check_code
{
	<<'CODE'
for my $stage (keys %{$meta->{prereqs}})
{
	my $conflicts = $meta->{prereqs}{$stage}{conflicts} or next;
	eval { require CPAN::Meta::Requirements } or last;
	$conflicts = 'CPAN::Meta::Requirements'->from_string_hash($conflicts);
	
	for my $module ($conflicts->required_modules)
	{
		eval "require $module" or next;
		my $installed = eval(sprintf('$%s::VERSION', $module));
		$conflicts->accepts_module($module, $installed) or next;
		
		my $message = "\n".
			"** This version of $meta->{name} conflicts with the version of\n".
			"** module $module ($installed) you have installed.\n";
		die($message . "\n" . "Bailing out")
			if $stage eq 'build' || $stage eq 'configure';
		
		$message .= "**\n".
			"** It's strongly recommended that you update it after\n".
			"** installing this version of $meta->{name}.\n";
		warn("$message\n");
	}
}
CODE
}

sub optional_features_code
{
	<<'CODE'

if ($ENV{MM_INSTALL_FEATURES})
{
	my %features = %{ $meta->{optional_features} };
	my @features = sort {
		$features{$b}{x_default} <=> $features{$a}{x_default} or $a cmp $b
	} keys %features;
	
	for my $feature_id (@features)
	{
		my %feature = %{ $features{$feature_id} };
		
		next unless prompt(
			sprintf('Install %s (%s)?', $feature_id, $feature{description} || 'no description'),
			$feature{x_default} ? 'Y' : 'N',
		) =~ /^Y/i;
		
		$features{$feature_id}{x_selected} = 1;
		
		for my $stage (keys %{$feature{prereqs}})
		{
			for my $level (keys %{$feature{prereqs}{$stage}})
			{
				for my $module (keys %{$feature{prereqs}{$stage}{$level}})
				{
					$meta->{prereqs}{$stage}{$level}{$module}
						= $feature{prereqs}{$stage}{$level}{$module};
				}
			}
		}
	}
}
else
{
	print <<'MM_INSTALL_FEATURES';

** Setting the MM_INSTALL_FEATURES environment variable to true
** would allow you to choose additional features.

MM_INSTALL_FEATURES
}
CODE
}

sub fix_makefile_code
{
	<<'CODE'

sub FixMakefile
{
	return unless -d 'inc';
	my $file = shift;
	
	local *MAKEFILE;
	open MAKEFILE, "< $file" or die "FixMakefile: Couldn't open $file: $!; bailing out";
	my $makefile = do { local $/; <MAKEFILE> };
	close MAKEFILE or die $!;
	
	$makefile =~ s/\b(test_harness\(\$\(TEST_VERBOSE\), )/$1'inc', /;
	$makefile =~ s/( -I\$\(INST_ARCHLIB\))/ -Iinc$1/g;
	$makefile =~ s/( "-I\$\(INST_LIB\)")/ "-Iinc"$1/g;
	$makefile =~ s/^(FULLPERL = .*)/$1 "-Iinc"/m;
	$makefile =~ s/^(PERL = .*)/$1 "-Iinc"/m;
	
	open  MAKEFILE, "> $file" or die "FixMakefile: Couldn't open $file: $!; bailing out";
	print MAKEFILE $makefile or die $!;
	close MAKEFILE or die $!;
}

FixMakefile($mm->{FIRST_MAKEFILE} || 'Makefile');
CODE
}

1;

__DATA__
use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = %%%METADATA%%%;
%%%OPTIONAL_FEATURES%%%
my %dynamic_config;%%%DYNAMIC_CONFIG%%%
%%%CONFLICT_CHECK%%%
my %WriteMakefileArgs = (
	ABSTRACT   => $meta->{abstract},
	AUTHOR     => ($EUMM >= 6.5702 ? $meta->{author} : $meta->{author}[0]),
	DISTNAME   => $meta->{name},
	VERSION    => $meta->{version},
	EXE_FILES  => [ map $_->{file}, values %{ $meta->{x_provides_scripts} || {} } ],
	NAME       => do { my $n = $meta->{name}; $n =~ s/-/::/g; $n },
	test       => { TESTS => "%%%TESTS%%%" },
	%dynamic_config,
);

$WriteMakefileArgs{LICENSE} = $meta->{license}[0] if $EUMM >= 6.3001;

sub deps
{
	my %r;
	for my $stage (@_)
	{
		for my $dep (keys %{$meta->{prereqs}{$stage}{requires}})
		{
			next if $dep eq 'perl';
			my $ver = $meta->{prereqs}{$stage}{requires}{$dep};
			$r{$dep} = $ver if !exists($r{$dep}) || $ver >= $r{$dep};
		}
	}
	\%r;
}

my ($build_requires, $configure_requires, $runtime_requires, $test_requires);
if ($EUMM >= 6.6303)
{
	$WriteMakefileArgs{BUILD_REQUIRES}     ||= deps('build');
	$WriteMakefileArgs{CONFIGURE_REQUIRES} ||= deps('configure');
	$WriteMakefileArgs{TEST_REQUIRES}      ||= deps('test');
	$WriteMakefileArgs{PREREQ_PM}          ||= deps('runtime');
}
elsif ($EUMM >= 6.5503)
{
	$WriteMakefileArgs{BUILD_REQUIRES}     ||= deps('build', 'test');
	$WriteMakefileArgs{CONFIGURE_REQUIRES} ||= deps('configure');
	$WriteMakefileArgs{PREREQ_PM}          ||= deps('runtime');	
}
elsif ($EUMM >= 6.52)
{
	$WriteMakefileArgs{CONFIGURE_REQUIRES} ||= deps('configure');
	$WriteMakefileArgs{PREREQ_PM}          ||= deps('runtime', 'build', 'test');	
}
else
{
	$WriteMakefileArgs{PREREQ_PM}          ||= deps('configure', 'build', 'test', 'runtime');	
}

{
	my ($minperl) = reverse sort(
		grep defined && /^[0-9]+(\.[0-9]+)?$/,
		map $meta->{prereqs}{$_}{requires}{perl},
		qw( configure build runtime )
	);
	
	if (defined($minperl))
	{
		die "Installing $meta->{name} requires Perl >= $minperl"
			unless $] >= $minperl;
		
		$WriteMakefileArgs{MIN_PERL_VERSION} ||= $minperl
			if $EUMM >= 6.48;
	}
}

%%%SHARE%%%
my $mm = WriteMakefile(%WriteMakefileArgs);
%%%FIX_MAKEFILE%%%
exit(0);

