package Dist::Zilla::Plugin::RPM::Push;
# ABSTRACT: Dist::Zilla plugin to build RPMs and push them into a repository

use Moose;
use Moose::Autobox;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

our $VERSION = '0.010'; # VERSION

with 'Dist::Zilla::Role::Releaser',
     'Dist::Zilla::Role::FilePruner';

has spec_file => (
    is      => 'ro',
    isa     => 'Str',
    default => 'build/dist.spec',
);

has build => (
    is      => 'ro',
    isa     => enum([qw/source all/]),
    default => 'all',
);

has sign => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has ignore_build_deps => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has push_packages => ( is => 'ro', isa => 'Bool', default => 0 );
has push_command => ( is => 'ro', isa => 'Str', default => 'rhnpush -s' );

use constant _CoercedRegexp => do {
    my $tc = subtype as 'RegexpRef';
    coerce $tc, from 'Str', via { qr/$_/ };
    $tc;
};

has push_ignore_packages => (
    is      => 'ro', isa => _CoercedRegexp, coerce => 1, default => '.src.rpm$' );

use Carp;
use File::Temp ();
use Path::Class qw(dir);
use Text::Template ();
use IPC::Run;

sub prune_files {
    my($self) = @_;
    my $spec = $self->spec_file;
    for my $file ($self->zilla->files->flatten) {
        if ($file->name eq $self->spec_file) {
            $self->zilla->prune_file($file);
        }
    }
    return;
}

has '_rpmbuild_options' => (
	is => 'ro', isa => 'ArrayRef[Str]', lazy => 1,
	default => sub {
		my $self = shift;
		return( [
			$self->sign ? '--sign' : (),
			$self->ignore_build_deps ? '--nodeps' : (),
		] );
	},
);

has '_rpmbuild_stage' => (
	is => 'ro', isa => 'Str', lazy => 1,
	default => sub {
		my $self = shift;

		if ($self->build eq 'source') {
			return('-bs');
		} elsif ($self->build eq 'all') {
			return('-ba');
		}

		$self->log_fatal(q{invalid build type }.$self->build);
	},
);


has '_rpmbuild_command' => (
	is => 'ro',
	isa => 'ArrayRef[Str]',
	lazy => 1,
	default => sub {
		my $self = shift;
		return( [
			'rpmbuild',
			$self->_rpmbuild_stage,
			@{$self->_rpmbuild_options},
			$self->_tmpspecfile->stringify,
		] );
	},
);

has '_tmpdir' => (
	is => 'ro', isa => 'File::Temp::Dir', lazy => 1,
	default => sub {
		my $self = shift;
		return File::Temp->newdir();
	},
);

has '_tmpspecfile' => (
	is => 'ro', isa => 'Path::Class::File', lazy => 1,
	default => sub {
		my $self = shift;
    		return dir($self->_tmpdir)->file($self->zilla->name . '.spec');
	},
);

sub _write_spec {
	my ($self, $archive) = @_;
	my $fh = $self->_tmpspecfile->openw();
	$fh->print($self->mk_spec($archive));
	$fh->flush;
	$fh->close;
	return;
}

has '_sourcedir' => (
	is => 'ro', isa => 'Str', lazy => 1,
	default => sub {
		my $self = shift;
		my $sourcedir = qx/rpm --eval '%{_sourcedir}'/
			or $self->log_fatal(q{couldn't determine RPM sourcedir});
		$sourcedir =~ s/[\r\n]+$//;
		$sourcedir .= '/';
		return($sourcedir);
	},
);


sub release {
    my($self,$archive) = @_;

    $self->_write_spec($archive);

    if(! -f $archive ) {
	    $self->log_fatal('archive '.$archive.' does not exist!');
    }

    system('cp',$archive,$self->_sourcedir)
        && $self->log_fatal('cp failed');

    if ($ENV{DZIL_PLUGIN_RPM_PUSH_TEST}) {
        $self->log("test: would have executed ".join(' ', @{$self->_rpmbuild_command}));
	return;
    }

    $self->_execute_rpmbuild;
    $self->log('RPMs build: '.join(', ', @{$self->_packages_build} ));

    if( $self->push_packages ) {
        $self->_execute_push_command;
    }

    return;
}

has '_packages_build' => ( is => 'ro', isa => 'ArrayRef[Str]', lazy => 1, default => sub { [] } );

sub _execute_rpmbuild {
	my $self = shift;
	my ($in, $out, $err);
	my $lang = $ENV{'LANG'};
	$ENV{'LANG'} = 'C';
	$self->log('building RPM...');
	IPC::Run::run( $self->_rpmbuild_command, \$in, \$out, \$err )
		or $self->log_fatal('rpmbuild failed: '.$err);
	foreach my $line ( split(/\n/, $out ) ) {
		if( $line =~ m/^Wrote: (.*)$/) {
			push(@{$self->_packages_build}, $1);
		}
	}
	$ENV{'LANG'} = $lang;
	return;
}

has _packages_to_push => (
	is => 'ro', isa => 'ArrayRef[Str]', lazy => 1,
	default => sub {
		my $self = shift;
		my $regex = $self->push_ignore_packages;
		return( [ grep { $_ !~ m/$regex/ } @{$self->_packages_build} ] );
	},
);

has _push_command => (
	is => 'ro', isa => 'ArrayRef', lazy => 1,
	default => sub {
		my $self = shift;
		return( [ split(/ /, $self->push_command) ] );
	},
);

sub _execute_push_command {
	my $self = shift;
	my ($in, $out, $err);

	$in = join("\n", @{$self->_packages_to_push});

	$self->log('pushing packages: '.join(', ', @{$self->_packages_to_push}));
	IPC::Run::run( $self->_push_command, \$in, \$out, $err )
		or $self->log_fatal('push command failed: '.$err);

	return;
}

sub mk_spec {
    my($self,$archive) = @_;
    my $t = Text::Template->new(
        TYPE       => 'FILE',
        SOURCE     => $self->zilla->root->file($self->spec_file),
        DELIMITERS => [ '<%', '%>' ],
    ) || $self->log_fatal($Text::Template::ERROR);
    return $t->fill_in(
        HASH => {
            zilla   => \($self->zilla),
            archive => \$archive,
        },
    ) || $self->log_fatal($Text::Template::ERROR);
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Dist::Zilla::Plugin::RPM::Push - Dist::Zilla plugin to build RPMs and push them into a repository

=head1 SYNOPSIS

In your dist.ini:

    [RPM::Push]
    spec_file = build/dist.spec
    sign = 1
    ignore_build_deps = 0

    push_packages = 0
    push_command = rhnpush -s
    push_ignore_packages = .src.rpm$
    
=head1 DESCRIPTION

This plugin is a Releaser for Dist::Zilla that builds an RPM of your
distribution.
It keeps track of build RPM files and can be used to push generated
packages into a repository.

=head1 ATTRIBUTES

=over

=item spec_file (default: "build/dist.spec")

The spec file to use to build the RPM.

The spec file is run through L<Text::Template|Text::Template> before calling
rpmbuild, so you can substitute values from Dist::Zilla into the final output.
The template uses <% %> tags (like L<Mason|Mason>) as delimiters to avoid
conflict with standard spec file markup.

Two variables are available in the template:

=over

=item $zilla

The main Dist::Zilla object

=item $archive

The filename of the release tarball

=back

=item sign (default: False)

If set to a true value, rpmbuild will be called with the --sign option.

=item ignore_build_deps (default: False)

If set to a true value, rpmbuild will be called with the --nodeps option.

=item push_packages (default: false)

This allowes you to specify a command to push your generated RPM packages to a repository.
RPM filenames are writen one-per-line to stdin.

=item push_command (default: rhnpush -s)

Command used to push packages.

=item push_ignore_packages (default: .src.rpm$)

A regular expression for packages which should NOT be pushed.

=back

=head1 SAMPLE SPEC FILE TEMPLATE

    Name: <% $zilla->name %>
    Version: <% (my $v = $zilla->version) =~ s/^v//; $v %>
    Release: 1

    Summary: <% $zilla->abstract %>
    License: GPL+ or Artistic
    Group: Applications/CPAN
    BuildArch: noarch
    URL: <% $zilla->license->url %>
    Vendor: <% $zilla->license->holder %>
    Source: <% $archive %>
    
    BuildRoot: %{_tmppath}/%{name}-%{version}-BUILD
    
    %description
    <% $zilla->abstract %>
    
    %prep
    %setup -q
    
    %build
    perl Makefile.PL
    make test
    
    %install
    if [ "%{buildroot}" != "/" ] ; then
        rm -rf %{buildroot}
    fi
    make install DESTDIR=%{buildroot}
    find %{buildroot} | sed -e 's#%{buildroot}##' > %{_tmppath}/filelist
    
    %clean
    if [ "%{buildroot}" != "/" ] ; then
        rm -rf %{buildroot}
    fi
    
    %files -f %{_tmppath}/filelist
    %defattr(-,root,root)

=head1 SEE ALSO

L<Dist::Zilla|Dist::Zilla>

=cut

1;
