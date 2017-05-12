#line 1
#
# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/ExtUtils-Depends/lib/ExtUtils/Depends.pm,v 1.20 2008/09/06 18:13:47 kaffeetisch Exp $
#

package ExtUtils::Depends;

use strict;
use warnings;
use Carp;
use File::Find;
use File::Spec;
use Data::Dumper;

our $VERSION = '0.301';

sub import {
	my $class = shift;
	return unless @_;
        die "$class version $_[0] is required--this is only version $VERSION"
		if $VERSION < $_[0];
}

sub new {
	my ($class, $name, @deps) = @_;
	my $self = bless {
		name => $name,
		deps => {},
		inc => [],
		libs => '',

		pm => {},
		typemaps => [],
		xs => [],
		c => [],
	}, $class;

	$self->add_deps (@deps);

	# attempt to load these now, so we'll find out as soon as possible
	# whether the dependencies are valid.  we'll load them again in
	# get_makefile_vars to catch any added between now and then.
	$self->load_deps;

	return $self;
}

sub add_deps {
	my $self = shift;
	foreach my $d (@_) {
		$self->{deps}{$d} = undef
			unless $self->{deps}{$d};
	}
}

sub get_deps {
	my $self = shift;
	$self->load_deps; # just in case

	return %{$self->{deps}};
}

sub set_inc {
	my $self = shift;
	push @{ $self->{inc} }, @_;
}

sub set_libs {
	my ($self, $newlibs) = @_;
	$self->{libs} = $newlibs;
}

sub add_pm {
	my ($self, %pm) = @_;
	while (my ($key, $value) = each %pm) {
		$self->{pm}{$key} = $value;
	}
}

sub _listkey_add_list {
	my ($self, $key, @list) = @_;
	$self->{$key} = [] unless $self->{$key};
	push @{ $self->{$key} }, @list;
}

sub add_xs       { shift->_listkey_add_list ('xs',       @_) }
sub add_c        { shift->_listkey_add_list ('c',        @_) }
sub add_typemaps {
	my $self = shift;
	$self->_listkey_add_list ('typemaps', @_);
	$self->install (@_);
}

# no-op, only used for source back-compat
sub add_headers { carp "add_headers() is a no-op" }

####### PRIVATE
sub basename { (File::Spec->splitdir ($_[0]))[-1] }
# get the name in Makefile syntax.
sub installed_filename {
	my $self = shift;
	return '$(INST_ARCHLIB)/$(FULLEXT)/Install/'.basename ($_[0]);
}

sub install {
	# install things by adding them to the hash of pm files that gets
	# passed through WriteMakefile's PM key.
	my $self = shift;
	foreach my $f (@_) {
		$self->add_pm ($f, $self->installed_filename ($f));
	}
}

sub save_config {
	use Data::Dumper;
	use IO::File;

	my ($self, $filename) = @_;

	my $file = IO::File->new (">".$filename)
		or croak "can't open '$filename' for writing: $!\n";

	print $file "package $self->{name}\::Install::Files;\n\n";
	# for modern stuff
	print $file "".Data::Dumper->Dump([{
		inc => join (" ", @{ $self->{inc} }),
		libs => $self->{libs},
		typemaps => [ map { basename $_ } @{ $self->{typemaps} } ],
		deps => [keys %{ $self->{deps} }],
	}], ['self']);
	# for ancient stuff
	print $file "\n\n# this is for backwards compatiblity\n";
	print $file "\@deps = \@{ \$self->{deps} };\n";
	print $file "\@typemaps = \@{ \$self->{typemaps} };\n";
	print $file "\$libs = \$self->{libs};\n";
	print $file "\$inc = \$self->{inc};\n";
	# this is riduculous, but old versions of ExtUtils::Depends take
	# first $loadedmodule::CORE and then $INC{$file} --- the fallback
	# includes the Filename.pm, which is not useful.  so we must add
	# this crappy code.  we don't worry about portable pathnames,
	# as the old code didn't either.
	(my $mdir = $self->{name}) =~ s{::}{/}g;
	print $file <<"EOT";

	\$CORE = undef;
	foreach (\@INC) {
		if ( -f \$_ . "/$mdir/Install/Files.pm") {
			\$CORE = \$_ . "/$mdir/Install/";
			last;
		}
	}
EOT

	print $file "\n1;\n";

	close $file;

	# we need to ensure that the file we just created gets put into
	# the install dir with everything else.
	#$self->install ($filename);
	$self->add_pm ($filename, $self->installed_filename ('Files.pm'));
}

sub load {
	my $dep = shift;
	my @pieces = split /::/, $dep;
	my @suffix = qw/ Install Files /;
	my $relpath = File::Spec->catfile (@pieces, @suffix) . '.pm';
	my $depinstallfiles = join "::", @pieces, @suffix;
	eval {
		require $relpath 
	} or die " *** Can't load dependency information for $dep:\n   $@\n";
	#
	#print Dumper(\%INC);

	# effectively $instpath = dirname($INC{$relpath})
	@pieces = File::Spec->splitdir ($INC{$relpath});
	pop @pieces;
	my $instpath = File::Spec->catdir (@pieces);
	
	no strict;

	croak "No dependency information found for $dep"
		unless $instpath;

	if (not File::Spec->file_name_is_absolute ($instpath)) {
		$instpath = File::Spec->rel2abs ($instpath);
	}

	my @typemaps = map {
		File::Spec->rel2abs ($_, $instpath)
	} @{"$depinstallfiles\::typemaps"};

	{
		instpath => $instpath,
		typemaps => \@typemaps,
		inc      => "-I$instpath ".${"$depinstallfiles\::inc"},
		libs     => ${"$depinstallfiles\::libs"},
		# this will not exist when loading files from old versions
		# of ExtUtils::Depends.
		(exists ${"$depinstallfiles\::"}{deps}
		  ? (deps => \@{"$depinstallfiles\::deps"})
		  : ()), 
	}
}

sub load_deps {
	my $self = shift;
	my @load = grep { not $self->{deps}{$_} } keys %{ $self->{deps} };
	foreach my $d (@load) {
		my $dep = load ($d);
		$self->{deps}{$d} = $dep;
		if ($dep->{deps}) {
			foreach my $childdep (@{ $dep->{deps} }) {
				push @load, $childdep
					unless
						$self->{deps}{$childdep}
					or
						grep {$_ eq $childdep} @load;
			}
		}
	}
}

sub uniquify {
	my %seen;
	# we use a seen hash, but also keep indices to preserve
	# first-seen order.
	my $i = 0;
	foreach (@_) {
		$seen{$_} = ++$i
			unless exists $seen{$_};
	}
	#warn "stripped ".(@_ - (keys %seen))." redundant elements\n";
	sort { $seen{$a} <=> $seen{$b} } keys %seen;
}


sub get_makefile_vars {
	my $self = shift;

	# collect and uniquify things from the dependencies.
	# first, ensure they are completely loaded.
	$self->load_deps;
	
	##my @defbits = map { split } @{ $self->{defines} };
	my @incbits = map { split } @{ $self->{inc} };
	my @libsbits = split /\s+/, $self->{libs};
	my @typemaps = @{ $self->{typemaps} };
	foreach my $d (keys %{ $self->{deps} }) {
		my $dep = $self->{deps}{$d};
		#push @defbits, @{ $dep->{defines} };
		push @incbits, @{ $dep->{defines} } if $dep->{defines};
		push @incbits, split /\s+/, $dep->{inc} if $dep->{inc};
		push @libsbits, split /\s+/, $dep->{libs} if $dep->{libs};
		push @typemaps, @{ $dep->{typemaps} } if $dep->{typemaps};
	}

	# we have a fair bit of work to do for the xs files...
	my @clean = ();
	my @OBJECT = ();
	my %XS = ();
	foreach my $xs (@{ $self->{xs} }) {
		(my $c = $xs) =~ s/\.xs$/\.c/i;
		(my $o = $xs) =~ s/\.xs$/\$(OBJ_EXT)/i;
		$XS{$xs} = $c;
		push @OBJECT, $o;
		# according to the MakeMaker manpage, the C files listed in
		# XS will be added automatically to the list of cleanfiles.
		push @clean, $o;
	}

	# we may have C files, as well:
	foreach my $c (@{ $self->{c} }) {
		(my $o = $c) =~ s/\.c$/\$(OBJ_EXT)/i;
		push @OBJECT, $o;
		push @clean, $o;
	}

	my %vars = (
		INC => join (' ', uniquify @incbits),
		LIBS => join (' ', uniquify $self->find_extra_libs, @libsbits),
		TYPEMAPS => [@typemaps],
	);

	# we don't want to provide these if there is no data in them;
	# that way, the caller can still get default behavior out of
	# MakeMaker when INC, LIBS and TYPEMAPS are all that are required.
	$vars{PM} = $self->{pm}
		if %{ $self->{pm} };
	$vars{clean} = { FILES => join (" ", @clean), }
		if @clean;
	$vars{OBJECT} = join (" ", @OBJECT)
		if @OBJECT;
	$vars{XS} = \%XS
		if %XS;

	%vars;
}

sub find_extra_libs {
	my $self = shift;

	my %mappers = (
		MSWin32 => sub { $_[0] . '.lib' },
		cygwin  => sub { $_[0] . '.dll'},
	);
	my $mapper = $mappers{$^O};
	return () unless defined $mapper;

	my @found_libs = ();
	foreach my $name (keys %{ $self->{deps} }) {
		(my $stem = $name) =~ s/^.*:://;
		my $lib = $mapper->($stem);
		my $pattern = qr/$lib$/;

		my $matching_dir;
		my $matching_file;
		find (sub {
			if ((not $matching_file) && /$pattern/) {;
				$matching_dir = $File::Find::dir;
				$matching_file = $File::Find::name;
			}
		}, map { -d $_ ? ($_) : () } @INC); # only extant dirs

		if ($matching_file && -f $matching_file) {
			push @found_libs, ('-L' . $matching_dir, '-l' . $stem);
			next;
		}
	}

	return @found_libs;
}

1;

__END__

#line 552

