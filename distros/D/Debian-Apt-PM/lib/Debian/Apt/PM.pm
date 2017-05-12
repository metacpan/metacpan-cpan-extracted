package Debian::Apt::PM;

use warnings;
use strict;

our $VERSION = '0.09';

use 5.010;

use Moose;
use IO::Uncompress::Bunzip2 qw(bunzip2 $Bunzip2Error) ;
use IO::Any;
use Parse::Deb::Control 0.03;
use Dpkg::Version 'version_compare';
use AptPkg::Config '$_config';
use LWP::Simple 'mirror', 'RC_OK';
use Carp 'croak';
use JSON::Util;
use CPAN::Version;
use Storable 'dclone';
use List::MoreUtils 'uniq';
use File::is;

use Debian::Apt::PM::SPc;


has 'sources'         => (is => 'rw', isa => 'ArrayRef', lazy => 1, default => sub { [ glob($_[0]->cachedir.'/all.index') ] });
has '_modules_index'  => (is => 'rw', isa => 'HashRef', lazy => 1, default => sub { $_[0]->_create_modules_index });
has '_apt_config'     => (is => 'rw', lazy => 1, default => sub { $AptPkg::Config::_config->init; $AptPkg::Config::_config; });
has 'cachedir'        => (
	is      => 'rw',
	lazy    => 1,
	default => sub {
		Debian::Apt::PM::SPc->cachedir
		.'/apt/apt-pm/deb'
		.($_[0]->repo_type eq 'deb-src' ? '-src' : '' )
	}
);
has 'repo_type'             => (is => 'rw', lazy => 1, default => 'deb');
has 'packages_dependencies' => (is => 'rw', lazy => 1, default => sub { $_[0]->cachedir.'/../02packages.dependencies.txt' });
has 'packages_dependencies_url'
                            => (is => 'rw', lazy => 1, default => 'http://pkg-perl.alioth.debian.org/cpan2deb/CPAN/02packages.dependencies.txt.gz');

sub find {
	my $self        = shift;
	my $module      = shift;
	my $min_version = shift;

	die 'no modules in '.$self->repo_type." index. did you add/set apt sources.list?\n"
		unless scalar keys %{$self->_modules_index()};
	
	my $versions_info = $self->_modules_index()->{$module};
	return if not $versions_info;
	
	# clone the info
	$versions_info = dclone($versions_info);
	
	# if not min then we are done
	return $versions_info
		if not defined $min_version;

	# sort available versions and grep smaller than requested
	my @versions =
		sort { CPAN::Version->vcmp($a, $b) }
		keys %{$versions_info}
	;

	$versions_info->{'max'} = $versions_info->{$versions[-1]};
	@versions = grep { not CPAN::Version->vlt($_, $min_version) } @versions;
	$versions_info->{'min'} = (@versions ? $versions_info->{$versions[0]} : undef);
	
	return $versions_info;
}

sub update {
	my $self = shift;
	
	my @existing = glob($self->cachedir.'/*.bz2');
	foreach my $url ($self->_etc_apt_sources) {
		my $filename = $url;
		$filename =~ s/[^a-zA-Z0-9\-\.]/_/gxms;
		$filename = $self->cachedir.'/'.$filename;
		@existing = grep { $_ ne $filename } @existing;
		if (mirror($url, $filename) == RC_OK) {
			my $json_filename = $filename; $json_filename =~ s/\.bz2$/.json/;
			my $content;
			my $bz_content = IO::Any->slurp($filename);
			bunzip2 \$bz_content => \$content or die "bunzip2 failed: $Bunzip2Error\n";
			JSON::Util->encode([$self->_parse_perlpackages_content($content)], $json_filename);
		}
	}
	
	# remove no longer wanted indexes
	foreach my $old_filename (@existing) {
		my $json_filename = $old_filename; $json_filename =~ s/\.bz2$/.json/;
		unlink($old_filename, $json_filename);
	}

	my $index_filename = File::Spec->catfile($self->cachedir, 'all.index');
	my $aptpm = Debian::Apt::PM->new(
		cachedir => $self->cachedir,
		sources  => [ glob($self->cachedir.'/*.json') ],
	);
	JSON::Util->encode($aptpm->_create_modules_index, [$index_filename])
		if (not -f $index_filename) or File::is->older($index_filename, glob($self->cachedir.'/*.json')) or @existing;
	
	my $package_dependencies = $self->packages_dependencies;
	if ($package_dependencies =~ m/\.gz$/) {
		mirror($self->packages_dependencies_url, $package_dependencies);
	}
	else {
		mirror($self->packages_dependencies_url, $package_dependencies.'.gz');
		system('gzip', '-d', '-f', $package_dependencies.'.gz');
	}
}

sub clean {
	my $self = shift;
	
	foreach my $filename (glob($self->cachedir.'/*')) {
		unlink($filename) or warn 'failed to remove '.$filename."\n";
	}
	unlink($self->packages_dependencies);
}

sub resolve_install_depends {
	my $self      = shift;
	my $force_all = shift;
	my @modules = @_;

	my @depends = (
		map { $_->[1] ||= 0; $_; }
		map { [ split('/', $_) ] }
		@modules
	);
	my @debs_to_install;
	my @modules_to_install;
	my %visited_modules;
	while (@depends) {
		my @new_depends;
		foreach my $module (@depends) {
			my $module_name    = $module->[0];
			my $module_version = $module->[1];
			my $deb_version    = $self->find($module_name, $module_version);
			if (exists $deb_version->{'min'}) {
				push @debs_to_install, $deb_version->{'min'}->{'package'};
				next;
			}
			else {
				push @modules_to_install, $module_name;
			}
			
			my @module_depends =
				grep { ref $_ ? 1 : ((push @debs_to_install, $_) and 0) }
				$self->module_depends($module_name, $force_all, \%visited_modules)
			;
			
			push @new_depends, @module_depends;
		}
		@depends = @new_depends;
	}
	
	@debs_to_install    = reverse uniq @debs_to_install;
	@modules_to_install = reverse uniq @modules_to_install;
	
	return (\@debs_to_install, \@modules_to_install);
}

sub module_depends {
	my $self      = shift;
	my $module    = shift;
	my $force_all = shift // 1;
	my $visited   = shift || {};
	
	my $packages_file = $self->packages_dependencies;
	
	my $packages_file_fh = (
		$packages_file =~ m/\.gz$/
		? (IO::Uncompress::Gunzip->new($packages_file) or die 'failed to open '.$packages_file)
		: (IO::Any->read($packages_file) or die 'failed to open '.$packages_file)
	);
	while (my $line = <$packages_file_fh>) {
		last if $line =~ m/^\s*$/;
	}
	while (my $line = <$packages_file_fh>) {
		chomp $line;
		if ($line =~ m{^ $module \s+ [^\s]+ \s+ (.+) $}xms) {
			my $depends = $1;
			return
				if $depends eq 'undef';
			return
				uniq
				map { my $deb = $self->find($_->[0], $_->[1]); ($deb->{'min'} ? $deb->{'min'}->{'package'} : $_); }
				grep {
					my $module = bless {"ID" => $_->[0]}, 'CPAN::Module';
					my $inst_module_version = $module->inst_version;
					(
						defined $inst_module_version && (CPAN::Version->vcmp($inst_module_version, $_->[1]) >= 0)
						? 0 || $force_all
						: 1
					)
				}
				map { $_->[1] ||= 0; $_; }
				grep { $_->[0] ne 'perl' }
				map { [ split('/', $_) ] }
				map { $visited->{$_} = (); $_; }
				grep { not exists $visited->{$_} }
				split(/\s+/, $depends)
			;
		}
	}
	
	return;
}

sub _etc_apt_sources {
	my $self = shift;
	
	my $repo_type = $self->repo_type;
	$repo_type = 'deb'
		if ($repo_type ne 'deb-src');

	my $apt_config = $self->_apt_config;
	my @sources_files = (
		$self->_apt_config->get_file('Dir::Etc::sourcelist'),
		glob( $self->_apt_config->get_dir('Dir::Etc::sourceparts') . '/*.list' ),
    );
    
    my $sources_text = join(
    	"\n",
    	map {
			eval { IO::Any->slurp($_) }
		} @sources_files
    );

	my $arch = $apt_config->get('APT::Architecture');
	my @urls;
	foreach my $line (split("\n", $sources_text)) {
		given ($line) {
			when (/^\s*$/) {};          # skip empty lines
			when (/^\s*#/) {};          # skip comments
			when (/^ \s* $repo_type \s+ ([^ ]+) \s+ ([^ ]+) (?: \s+ (.+) | \/ \s*) $/xms) {
				my ($url, $path, $components_string) = ($1, $2, $3);
				my @components = grep { $_ } split(/\s+/, $components_string || '');
				
				if ($url !~ m{^(:? http:// | ftp:// | file://)}xms) {
					warn 'unsupported schema - '.$url;
					next;
				}
				
				if (@components) {
					push @urls, map {
						$url.'dists/'.$path.'/'.$_.'/binary-'.$arch.'/PerlPackages.bz2'
					} @components;
				}
				else {
					push @urls, $url.$path.'/PerlPackages.bz2';
				}
			};
			when (/^ \s* (?: deb | deb-src ) \s /xms) {}; # skip !$repo_type
			default { warn 'unknown sources.list line - '.$line };
		}
	}
	
	return uniq @urls;
}

sub _parse_perlpackages_content {
	my $self    = shift;
	my $content = shift;
	
	my @content_list;
	my $idx = Parse::Deb::Control->new($content);
	foreach my $entry ($idx->get_keys('Perl-Modules')) {
		my %modules = _parse_perl_modules($entry->{'para'}->{'Perl-Modules'});
		
		my %deb = (
			'version' => _trim($entry->{'para'}->{'Version'}),
			'package' => (
				$self->repo_type eq 'deb-src'
				? _trim($entry->{'para'}->{'Source'}) || _trim($entry->{'para'}->{'Package'})
				: _trim($entry->{'para'}->{'Package'})
			),
			'arch'         => _trim($entry->{'para'}->{'Architecture'}),
			'distribution' => _trim($entry->{'para'}->{'Distribution'}),
			'component'    => _trim($entry->{'para'}->{'Component'}),
		);
		
		push @content_list, { modules => \%modules, deb => \%deb };
	}
	
	return @content_list;
}

sub _create_modules_index {
	my $self = shift;
	my @sources = @{$self->sources};
	
	return {}
		if not @sources;
	
	my %modules_index;
	foreach my $src (@sources) {
		die $src." no such file. (run `apt-pm update` ?)\n"
			unless -f $src;
		
		my @content_list;
		given ($src) {
			when (m/\.bz2$/) {
				my $content;
				my $bz_content = IO::Any->slurp($src);
				bunzip2 \$bz_content => \$content or die "bunzip2 failed: $Bunzip2Error\n";
				@content_list = $self->_parse_perlpackages_content($content);
			}
			when (m/all\.index$/) {
				return JSON::Util->decode([$src]);
			}
			when (m/\.json$/) {
				@content_list = @{JSON::Util->decode([$src])};
			}
			default { @content_list = $self->_parse_perlpackages_content(IO::Any->slurp($src)); }
		}
		
		foreach my $entry (@content_list) {
			my %modules = %{$entry->{'modules'}};
			my %deb     = %{$entry->{'deb'}};
			while (my ($module_name, $version) = each %modules) {
				# resolve conflicts when two packages has the module with the same version
				if (exists $modules_index{$module_name}->{$version}) {
					my $old_version = $modules_index{$module_name}->{$version}->{'version'};
					my $new_version = $entry->{'deb'}->{'version'};
					
					# will not overwrite if the current package has older Debian version
					next
						if version_compare($old_version, $new_version) == -1;
				}
					
				$modules_index{$module_name}->{$version} =\%deb;
			}
		}
	}
	
	return \%modules_index;
}

sub _parse_perl_modules {
	my $text = shift || '';
	
	return
		map  { m/^(.+)\s+ \( \s* ([^\(]+) \s* \)/xms ? ( $1 => $2 ) : () }
		grep { $_ }                       # remove empty lines
		map { s/^\s*//; s/\s*$//; $_ }    # trim
		split("\n", $text)                # split on new lines
	;
}

sub _trim {
	my $text = shift;
	croak 'too much argauments' if @_;
	
	return '' if not defined $text;
	
	$text =~ s/^\s+//xms;
	$text =~ s/\s+$//xms;
	
	return $text;
}

1;


__END__

=head1 NAME

Debian::Apt::PM - locate Perl Modules in Debian repositories

=head1 NOTE

Needs following extra Debian packages C<libdpkg-perl> and C<libapt-pkg-perl>.

=head1 SYNOPSIS

command line:

	apt-pm update
	apt-pm find Moose
	dpkg-scanpmpackages /path/to/debian/repository
	
	# print out all dependencies of an unpacked distribution that are packaged for Debian
	perl -MDebian::Apt::PM -MModule::Depends -le \
		'$apm=Debian::Apt::PM->new();$md=Module::Depends->new->dist_dir(".")->find_modules; %r=(%{$md->requires},%{$md->build_requires}); while (($m, $v) = each %r) { $f=$apm->find($m, $v); print $f->{"min"}->{"package"} if $f->{"min"}  }' \
		| sort \
		| uniq \
		| xargs echo apt-get install
	# print out all dependencies of an unpacked distribution that are not packaged for Debian
	perl -MDebian::Apt::PM -MModule::Depends -le \
		'$apm=Debian::Apt::PM->new();$md=Module::Depends->new->dist_dir(".")->find_modules; %r=(%{$md->requires},%{$md->build_requires}); while (($m, $v) = each %r) { $f=$apm->find($m, $v); print $m, " ", $v if not $f->{"min"}  }'


Module:

	my $aptpm = Debian::Apt::PM->new(sources => [ 'PerlPackages.bz2' ])
	$aptpm->update;
	my %moose_locations = $aptpm->find('Moose');

=head1 USAGE

=head2 COMMAND-LINE USAGE

Add sources for Debian releases and components. Here is the complete list
that can be reduced just to the wanted ones:

	cat >> /etc/apt/sources.list << __END__
	# for apt-pm
	deb http://alioth.debian.org/~jozef-guest/pmindex/     lenny   main contrib non-free
	deb http://alioth.debian.org/~jozef-guest/pmindex/     squeeze main contrib non-free
	deb http://alioth.debian.org/~jozef-guest/pmindex/     wheezy  main contrib non-free
	deb http://alioth.debian.org/~jozef-guest/pmindex/     sid     main contrib non-free

	__END__

Fetch the indexes:

	apt-pm update

Look for the CPAN modules:

	apt-pm find Moose
	# libmoose-perl_0.17-1_all: Moose 0.17
	# libmoose-perl_0.94-1_i386: Moose 0.94
	# libmoose-perl_0.97-1_i386: Moose 0.97
	# libmoose-perl_0.54-1_all: Moose 0.54

Look for the non-CPAN modules:
	
	apt-pm find Purple        
	# libpurple0_2.4.3-4lenny5_i386: Purple 0.01
	
	apt-pm find Dpkg::Version
	# dpkg-dev_1.14.28_all: Dpkg::Version 0

=head1 METHODS

=head2 new()

Object constructor.

=head3 PROPERTIES

=over 4

=item sources

C<< isa => 'ArrayRef' >> of files that will be read to construct the lookup.
By default it is filled with files from F</var/cache/apt/apt-pm/>.

=item cachedir

Is the folder where indexes cache files will be stored.
Default is F</var/cache/apt/apt-pm/deb/>.

=item repo_type

C<deb|deb-src>

=item packages_dependencies

Path to C<02packages.dependencies.txt(.gz)?> file.

=back

=head2 find($module_name, [$min_version])

Returns hash with Perl versions as key and hash value having Debian version
and package name. Example:

	{
		'0.94' => {
			'version' => '0.94-1',
			'package' => 'libmoose-perl'
			'arch'    => 'i386'
		},
		'0.97' => {
			'version' => '0.97-1',
			'package' => 'libmoose-perl'
			'arch'    => 'i386'
		},
		'0.54' => {
			'version' => '0.54-1',
			'package' => 'libmoose-perl'
			'arch'    => 'i386'
		},
	};

If C<$min_version> is set, returns C<min> and C<max> keys. C<max> has always
the highest version:

	'max' => {
		'version' => '0.97-1',
		'package' => 'libmoose-perl'
		'arch'    => 'i386'
	},

C<min> is changing depending on C<$min_version>. Examples:

	$min_version = '0.01';
	'min' => {
		'version' => '0.54-1',
		'package' => 'libmoose-perl'
		'arch'    => 'i386'
	},
	$min_version = '0.93';
	'min' => {
		'version' => '0.94-1',
		'package' => 'libmoose-perl'
		'arch'    => 'i386'
	},
	$min_version = '1.00';
	'min' => undef,

=head2 update

Scans the F</etc/apt/sources.list> and F</etc/apt/sources.list.d/*.list>
repositories for F<PerlPackages.bz2> and prepares them to be used for find.
All F<PerlPackages.bz2> are stored to F</var/cache/apt/apt-pm/>.

It also fetches L<http://pkg-perl.alioth.debian.org/cpan2deb/CPAN/02packages.dependencies.txt.gz>
to be used by C<apt-cpan>.

=head2 clean

Remove all files from cache folder.

=head2 resolve_install_depends($force_all, @modules)

Returns two array references one with Debian packages, the other with CPAN
packages that needs to be installed on current system for the given list
of C<@modules>.

Option C<$force_all> (true/false) choose to include all dependencies not
just the ones that needs to be installed.

=head2 module_depends($module)

Return all Perl modules and Debian packages C<$module> has as dependency.

=head1 SEE ALSO

L<http://pkg-perl.alioth.debian.org/cpan2deb/>

=head1 AUTHOR

jozef@kutej.net, C<< <jkutej at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-debian-apt-pm at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Debian-Apt-PM>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Debian::Apt::PM


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Debian-Apt-PM>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Debian-Apt-PM>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Debian-Apt-PM>

=item * Search CPAN

L<http://search.cpan.org/dist/Debian-Apt-PM/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 jkutej@cpan.org.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
