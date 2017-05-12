package MiniPAN;

use 5.005;
use strict;
use warnings;

use Spiffy -Base;
use Carp;
use File::Basename;
use File::Path qw(rmtree);
use LWP::UserAgent;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use Archive::Tar;


=head1 NAME

MiniPAN - A minimalistic installer of CPAN modules for the iPhone

=head1 VERSION

Version 0.04

=cut

our $VERSION     = '0.04';
our $CPAN_MIRROR = 'http://cpan.catalyst.net.nz/pub/CPAN/modules/';
our $BUILD_DIR   = $ENV{'HOME'} . '/.minipan/';
our $MOD_LIST    = '02packages.details.txt';

=head1 SYNOPSIS

	use MiniPAN;

	my $module = MiniPAN->new('Some::Module');
	$module->fetch();
	my @deps = $module->config();
	$module->install();

=head1 METHODS

=head2 new

	my $module = MiniPAN->new('Some::Module');

Creates a new MiniPAN object, takes the module name as a single argument.

=cut

sub new($$) {
	my ($class, $module) = @_;

	$module = _get_module_name($module);

	my $self = {
		module     => $module,
		mirror     => $CPAN_MIRROR,
		local_path => $BUILD_DIR . _get_local_path($module),
	};
	bless $self, $class;

	mkdir($BUILD_DIR) or die("coud not mkdir `$BUILD_DIR': $!\n")
		unless (-d $BUILD_DIR);

	return $self;
}

=head2 fetch

	$module->fetch();

Fetches and extracts the module source from CPAN mirror.

=cut

sub fetch {
	$self->{'server_path'} = 'by-authors/id/'
		. $self->_get_server_path($self->{'module'});

	unless (-d $self->{'local_path'}) {
		$self->_print('creating temp module dir');
		mkdir($self->{'local_path'})
			or croak("fetch: could not mkdir `" . $self->{'local_path'} . "': $!\n");
	}
	chdir($self->{'local_path'})
		or croak("fetch: could not chdir to `" . $self->{'local_path'} . "': $!\n");

	my ($filename, undef, $suffix) = fileparse($self->{'server_path'}, (".tar.gz"));
	if (-f $filename . $suffix) {
		$self->_print('source already downloaded');
	}
	else {
		$self->_print('fetching module source from: ' . $self->{'server_path'});
		$self->_download($self->{'server_path'}, $filename.$suffix);
	}

	$self->_print('extracting source');

	# remove old extracted sources
	rmtree($filename) if (-d $filename);

	my $tar = Archive::Tar->new();
	$tar->read($filename.$suffix, undef,{ extract => 1 })
		or croak("could not open/read `$filename$suffix': " . $tar->error . "\n");

	$self->{'src_dir'} = $self->{'local_path'} . "/$filename";
}

=head2 config

	my @deps = $module->config();

Runs the configure script (currently only modules with Makefile.PL and Build.PL supported)
and returns dependencies as an array.

=cut

sub config {
	my @deps;

	chdir($self->{'src_dir'})
		or croak("configure: could not chdir to `" . $self->{'src_dir'} . "': $!\n");

	if (-f 'Build.PL') {
		@deps = map { [ split(/\s+/o, $_) ]->[3] }
			grep(/ - ERROR: /om, `yes "\n" | perl Build.PL 2>&1`);
	}
	else {
		@deps = map { [ split(/\s+/o, $_) ]->[2] }
			grep(/Warning: prerequisite/om, `yes "\n" | perl Makefile.PL --skipdeps 2>&1 || yes "\n" | perl Makefile.PL 2>&1`);
	}

	$self->_print("required dependencies: " . join(", ", @deps)) if (@deps);

	return @deps;
}

=head2 install

	$module->install();

Compiles (if needed) and installs the module with sudo, so you need to have
sudo installed.

=cut

sub install {
	chdir($self->{'src_dir'})
		or croak("install: could not chdir to `" . $self->{'src_dir'} . "': $!\n");

	my $build_script = 'make';
	$build_script = './Build' if (-f 'Build');

	eval {
		$self->_print("building");
		system($build_script) == 0
			or die("build failed, see error(s) above\n");
		$self->_print("testing");
		system($build_script, 'test') == 0
			or die("testing failed, see error(s) above\n");
		$self->_print("installing");
		system('sudo', $build_script, 'install') == 0
			or die("install failed, see error(s) above\n");
	};
	$self->_print($@) and exit 1 if ($@);

	chdir($BUILD_DIR) or croak("clean: could not chdir to `$BUILD_DIR': $!\n");
	rmtree($self->{'src_dir'});
	$self->_print("temporary build dir removed");
}

sub _download {
	my ($url, $file) = @_;

	my $ua = LWP::UserAgent->new(agent => "MiniPan $VERSION");
	my $response = $ua->request(
		HTTP::Request->new(GET => $self->{'mirror'} . $url),
		$file,
	);
	croak("could not download `$file': " . $response->status_line)
		unless $response->is_success;
}

sub _get_module_name($) {
	my ($module) = @_;

	$module =~ s~/~::~og;
	$module =~ s~\.pm$~~o;

	croak("argument is not a module: $module\n")
		unless ($module =~ /^\w+(::\w+)*$/o);

	return $module;
}

sub _get_local_path($) {
	my ($dir) = @_;
	$dir =~ s~::~-~og;
	return $dir
}

sub _fetch_module_list {
	chdir($BUILD_DIR) or die("could not chdir to `$BUILD_DIR': $!\n");

	unless (-f $MOD_LIST) {
		print 'fetching module list from ' . $self->{'mirror'} . $MOD_LIST . ".gz\n";
		$self->_download("$MOD_LIST.gz", "$MOD_LIST.gz");
		gunzip "$MOD_LIST.gz" => $MOD_LIST
			or croak("gunzip failed: $GunzipError\n");
		unlink("$MOD_LIST.gz");
	}
}

sub _get_server_path {
	my $path;

	$self->_fetch_module_list();

	open(LIST, "< $BUILD_DIR$MOD_LIST")
		or croak("cannot open package list `$BUILD_DIR$MOD_LIST': $!\n");
	while(<LIST>) {
		next unless grep(/^$self->{'module'}\s/, $_);
		(undef, undef, $path) = split(/\s+/, $_);
	}
	close(LIST);

	croak($self->{'module'} . " does not exist on CPAN\n") unless ($path);

	$self->_print("path is: $path");

	return $path;
}

sub _print {
	my ($msg) = @_;
	print $self->{'module'} . " | $msg\n";
}

=head1 BUGS

Please report any bugs or feature requests to C<bug-minipan at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MiniPAN>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 TODO

=over 4

=item * (!) implement a much nicer way of recursive dependency installation

=item * use Term::ANSIColor

=item * refetch module list if it is older than a certain period

=item * more verbosity via flag

=back

=head1 SEE ALSO

minipan, CPAN

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MiniPAN


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MiniPAN>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MiniPAN>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MiniPAN>

=item * Search CPAN

L<http://search.cpan.org/dist/MiniPAN>

=back

=head1 AUTHOR

Tobias Kirschstein, C<< <mail at lev.geek.nz> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Tobias Kirschstein, all rights reserved.

This program is released under the following license: BSD

=cut

1; # End of MiniPAN
