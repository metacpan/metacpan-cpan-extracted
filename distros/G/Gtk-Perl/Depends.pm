package ExtUtils::Depends;
use File::Basename;
use Carp;
use Cwd;
use IO::File;
use strict;
use vars qw($AUTOLOAD $VERSION);

$VERSION = 0.1;

sub new {
	my ($class, $package, @depends) = @_;
	my $self = {
		_name_ => $package,
		_depends_ => [@depends],
		_dtypemaps_ => [],
		_ddefines_ => [],
		_prefix_ => 'xs/',
		_install_ => [qw(typemaps defs)],
		_handler_ => {
			typemaps => \&basename,
			defs => \&basename,
			headers => sub {
				my $s = $_[0]; 
				$s =~ s(^[^<"]+/)(); #"
				return $s;
			},
		},
	};
	$class = ref($class) || $class;

	$self = bless $self, $class;

	$self->load(@depends) if @depends;
	return $self;
}

sub installdir {
	my $self = shift;
	my $dir = $self->{_name_};
	$dir =~ s/^(\w+::)+//;
	$dir =~ s(::)(/); #/
	$dir = '$(INST_ARCHLIBDIR)/'.$dir.'/Install/';
	return $dir;
}

sub set_prefix {
	my ($self, $prefix) = @_;
	$self->{_prefix_} = $prefix;
}

sub set_libs {
	my ($self, $libs) = @_;
	chomp($libs);
	$self->{_libs_} = $libs;
}

sub set_inc {
	my ($self, $inc) = @_;
	chomp($inc);
	$self->{_inc_} = $inc;
}

# load dependencies ...
sub load {
	my ($self, @depends) = @_;
	my ($dir, $module);
	
	for (@depends) {
		no strict 'refs';
		my ($name, $file);
		undef $dir;
		if (ref $_) {
			($name, $file) = %$_;
			my $dname = $name;
			my $i = 2;
			my $tmpdir = $file;
			$dname =~ s(::)(/); #/
			while ($i--) {
				$tmpdir = dirname($tmpdir);
				if ( -f "$tmpdir/Makefile.PL") {
					$dir = "$tmpdir/blib/lib/".$dname."/Install/";
					last;
				}
			}
		} else {
			$_.='::Install::Files';
			$module = $_.'.pm';
			$module =~ s(::)(/)g; #/
			$name = $_;
			$file = $module;
		}
		eval {require $file;};
		if ($@) {
			die "Cannot load $_: $@\n";
		}
		$dir ||= ${"${_}::CORE"} || $INC{$file};
		$dir = cwd().'/'.$dir unless $dir =~ m(^/);
		warn "Found $name in $dir\n";
		push @{$self->{_dtypemaps_}}, map {$dir.'/'.$_} @{"${_}::typemaps"};
		#push @{$self->{_ddefs_}}, @{"${_}::defs"};
		push @{$self->{_ddefines_}}, @{"${_}::defines"};
		$self->{_dlibs_} .= " ".${"${_}::libs"};
		$self->{_dinc_} .= " -I$dir ".${"${_}::inc"};
	}
}

sub add_pm {
	my ($self, %pm) = @_;
	foreach (keys %pm) {
		$self->{_pm_}->{$_} = $pm{$_};
	}
}

sub get_pm {
	my $self = shift;
	# maybe make a copy
	foreach ($self->get_headers) {
		next unless s/^"//;
		s/"$//;
		warn "FORCE installing header: $_\n";
		$self->{_pm_}->{$_} = $self->installdir().basename($_);
	}
	foreach ($self->get_typemaps) {
		$self->{_pm_}->{$_} = $self->installdir().basename($_);
	}
	return $self->{_pm_};
}

sub install {
	my $self = shift;
	my $dir = $self->installdir;
	foreach (@_) {
		$self->add_pm($_, $dir.basename($_));
	}
}

sub real_add {
	my ($self, $tag, @args) = @_;
	my $file;
	
	foreach (@args) {
		$file = $self->{_prefix_}.$_;
		if (-e || ! -e $file) {
			$file = $_;
		}
		$self->{$tag}->{$file} = $self->{_counter_}++;
	}
}

sub real_remove {
	my ($self, $tag, @args) = @_;
	my $file;
	
	foreach (@args) {
		$file = $self->{_prefix_}.$_;
		if (-e || ! -e $file) {
			$file = $_;
		}
		delete $self->{$tag}->{$file};
	}
}

sub real_get {
	my ($self, $tag) = @_;

	return sort {$self->{$tag}->{$a} <=> $self->{$tag}->{$b}} 
		keys %{$self->{$tag}};
}

sub AUTOLOAD {
	my $self = shift @_;
	my $method = $AUTOLOAD;
	my $tag;
	
	$method =~ s/^.*:://;
	if ($method =~ s/^(get|add|remove)_//) {
		no strict 'subs';
		$tag = $method;
		$method = "real_$1";
		return $self->$method ($tag, @_);
	}
	carp "No method '$method'\n";
}

sub DESTROY {}

sub sort_libs {
	my ($libs) = '';
	my (@libs, %seenlibs, @revlibs, @lflags);
	
	foreach (@_) {
		$libs .= ' ';
		$libs .= $_;
	}
	$libs =~ s/(^|\s)-[rR]\S+//g;
	
	@libs = split(/\s+/, $libs);
	%seenlibs = ();
	@revlibs=();
	@lflags=();

	foreach (@libs) {
		if (/^-l/) {
			unshift(@revlibs, $_);
		} else {
			unshift(@lflags, $_) unless $seenlibs{$_}++;
		}
	}
	@libs=();
	foreach (@revlibs) {
		unshift(@libs, $_) unless $seenlibs{$_}++;
	}
	return join(' ', @lflags, @libs);
}

sub get_makefile_vars {
	my $self = shift;
	my (%result);
	my ($xfiles, $object, $ldfrom, $clean) = $self->setup_xs();

	push @$clean, keys %{$self->{clean}};
	$result{PM} = $self->get_pm;
	$result{TYPEMAPS} = [@{$self->{_dtypemaps_}}, $self->get_typemaps];
	$result{DEFINE} = join(' ', @{$self->{_ddefines_}}, keys %{$self->{defines}});
	$result{OBJECT} = $object;
	#$result{LDFROM} = $ldfrom;
	$result{XS} = $xfiles;
	$result{INC} = join(' ', $self->{_dinc_}, $self->{_inc_});
	$result{LIBS} = [sort_libs($self->{_dlibs_}, $self->{_libs_})];
	$result{clean} = {FILES => join(' ', @$clean) };
	
	return %result;
}

sub setup_xs {
	my $self = shift;
	my $xfiles = {};
	my ($ldfrom, $object, @clean);
	
	$ldfrom = $object = '';
	foreach (keys %{$self->{xs}}) {
		my($xs) = $_;
		s/\.xs$/.c/;
		$xfiles->{$xs} = $_;
		push(@clean, $_);
		s/\.c$/.o/;
		push(@clean, $_);
		$object .= " $_";
		s(.*/)();
		$ldfrom .= " $_";
	}
	foreach (keys %{$self->{c}}) {
		s/\.c$/.o/i;
		push(@clean, $_);
		$object .= " $_";
	}
	return ($xfiles, $object, $ldfrom, [@clean]);
}

sub save_config {
	my ($self, $filename) = @_;
	my ($file, $mdir, $mdir2, $pm, $name);
	my (%installable, %handler);

	@installable{@{$self->{_install_}}} = ();
	%handler = %{$self->{_handler_}};

	$file = new IO::File ">$filename" || croak "Cannot open '$filename': $!";;
	$name = $mdir = $mdir2 = $self->{_name_};
	$pm = $self->{_pm_};
	
	$mdir =~ s/.*:://;
	$mdir2 =~ s.::./.g;
	
	$pm->{$filename} = '$(INST_ARCHLIBDIR)/'."$mdir/Install/Files.pm";

	print $file "#!/usr/bin/perl\n\npackage ${name}::Install::Files;\n\n";

	foreach my $tag (sort keys %{$self}) {
		next if $tag =~ /^_/;
		my %items = %{$self->{$tag}};
		print $file "\@$tag = qw(\n";
		foreach my $item (sort {$items{$a} <=> $items{$b}} keys %items) {
			my $s = exists $handler{$tag} ? $handler{$tag}->($item): $item;
			print $file "\t$s\n";
			$pm->{$item} = '$(INST_ARCHLIBDIR)/'. "$mdir/Install/" . $s if exists $installable{$tag};
		}
		print $file ");\n\n";
	}
	print $file "\$libs = '$self->{_libs_}';\n";
	print $file "\$inc = '$self->{_inc_}';\n";
	print $file <<"EOT";

	\$CORE = undef;
	foreach (\@INC) {
		if ( -f \$_ . "/$mdir2/Install/Files.pm") {
			\$CORE = \$_ . "/$mdir2/Install/";
			last;
		}
	}

	1;
EOT
	close($file);
}

sub write_ext {
	my ($self, $filename) = @_;
	my $file = new IO::File "> $filename" || carp "Cannot create $filename: $!";
	
	print $file "\n\n# Do not edit this file, as it is automatically generated by Makefile.PL\n\n";

	print $file "BOOT:\n{\n";

	foreach ($self->get_boot) {
        my($b) = $_;
        $b =~ s/::/__/g;
        $b = "boot_$b";
        print $file "extern void $b(CV *cv);\n";
	}
	foreach ($self->get_boot) {
        my($b) = $_;
        $b =~ s/::/__/g;
        $b = "boot_$b";
        print $file "callXS($b, cv, mark);\n";
	}

	print $file "}\n";
	close($file);

}

=head1 NAME

ExtUtils::Depends - Easily build XS extensions that depend on XS extensions

=head1 SYNOPSIS

	use ExtUtils::Depends;
	$package = new ExtUtils::Depends ('pkg::name', 'base::package')
	# set the flags and libraries to compile and link the module
	$package->set_inc("-I/opt/blahblah");
	$package->set_lib("-lmylib");
	# add a .c and an .xs file to compile
	$package->add_c('code.c');
	$package->add_xs('module-code.xs');
	# add the typemaps to use
	$package->add_typemaps("typemap");
	# safe the info
	$package->save_config('Files.pm');

	WriteMakefile(
		'NAME' => 'Mymodule',
		$package->get_makefile_vars()
	);

=head1 DESCRIPTION

This module tries to make it easy to build Perl extensions that use
functions and typemaps provided by other perl extensions. This means
that a perl extension is treated like a shared library that provides
also a C and an XS interface besides the perl one.
This works as long as the base extension is loaded with the RTLD_GLOBAL
flag (usually done with a 

	sub dl_load_flags {0x01}

in the main .pm file) if you need to use functions defined in the module.

=head1 AUTHOR

Paolo Molaro, lupus@debian.org

=head1 SEE ALSO

ExtUtils::MakeMaker.

=cut

