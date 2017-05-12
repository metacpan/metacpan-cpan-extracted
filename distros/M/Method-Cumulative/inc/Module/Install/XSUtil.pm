#line 1
package Module::Install::XSUtil;

use 5.005_03;

$VERSION = '0.09';

use Module::Install::Base;
@ISA     = qw(Module::Install::Base);

use strict;

use Config;

use File::Spec;
use File::Find;

use constant _VERBOSE => $ENV{MI_VERBOSE} ? 1 : 0;

my %BuildRequires = (
	'Devel::PPPort'     => 3.19,
	'ExtUtils::ParseXS' => 2.20,
	'XSLoader'          => 0.08,
);

my %ToInstall;

sub _verbose{
	print STDERR q{# }, @_, "\n";
}

sub _xs_initialize{
	my($self) = @_;

	unless($self->{xsu_initialized}){

		$self->requires_external_cc();
		$self->build_requires(%BuildRequires);
		$self->makemaker_args(OBJECT => '$(O_FILES)');

		$self->{xsu_initialized} = 1;
	}
	return;
}

# GNU C Compiler
sub _is_gcc{
	return $Config{gccversion};
}

# Microsoft Visual C++ Compiler (cl.exe)
sub _is_msvc{
	return $Config{cc} =~ /\A cl \b /xmsi;
}

sub use_ppport{
	my($self, $dppp_version) = @_;

	$self->_xs_initialize();

	my $filename = 'ppport.h';

	$dppp_version ||= 0;
	$self->configure_requires('Devel::PPPort' => $dppp_version);

	print "Writing $filename\n";

	eval qq{
		use Devel::PPPort;
		Devel::PPPort::WriteFile(q{$filename});
		1;
	} or warn("Cannot create $filename: $@");

	
	if(-e $filename){
		$self->clean_files($filename);
		$self->cc_append_to_ccflags('-DUSE_PPPORT');
		$self->cc_append_to_inc('.');
	}
	return;
}

sub cc_warnings{
	my($self) = @_;

	$self->_xs_initialize();

	if(_is_gcc()){
		$self->cc_append_to_ccflags(qw(-Wall -Wextra));
	}
	elsif(_is_msvc()){
		$self->cc_append_to_ccflags('-W3');
	}
	else{
		# TODO: support other compilers
	}

	return;
}

sub cc_append_to_inc{
	my($self, @dirs) = @_;

	$self->_xs_initialize();

	for my $dir(@dirs){
		unless(-d $dir){
			warn("'$dir' not found: $!\n");
			exit;
		}

		_verbose "inc: -I$dir" if _VERBOSE;
	}

	my $mm    = $self->makemaker_args;
	my $paths = join q{ }, map{ s{\\}{\\\\}g; qq{"-I$_"} } @dirs;

	if($mm->{INC}){
		$mm->{INC} .=  q{ } . $paths;
	}
	else{
		$mm->{INC}  = $paths;
	}
	return;
}

sub cc_append_to_libs{
	my($self, @libs) = @_;

	$self->_xs_initialize();

	my $mm = $self->makemaker_args;

	my $libs = join q{ }, map{
		my($name, $dir) = ref($_) eq 'ARRAY' ? @{$_} : ($_, undef);

		$dir = qq{-L$dir } if defined $dir;
		_verbose "libs: $dir-l$name" if _VERBOSE;
		$dir . qq{-l$name};
	} @libs;

	if($mm->{LIBS}){
		$mm->{LIBS} .= q{ } . $libs;
	}
	else{
		$mm->{LIBS} = $libs;
	}

	return;
}

sub cc_append_to_ccflags{
	my($self, @ccflags) = @_;

	$self->_xs_initialize();

	my $mm    = $self->makemaker_args;

	$mm->{CCFLAGS} ||= $Config{ccflags};
	$mm->{CCFLAGS}  .= q{ } . join q{ }, @ccflags;
	return;
}

sub cc_define{
	my($self, @defines) = @_;

	$self->_xs_initialize();

	my $mm = $self->makemaker_args;
	if(exists $mm->{DEFINE}){
		$mm->{DEFINE} .= q{ } . join q{ }, @defines;
	}
	else{
		$mm->{DEFINE}  = join q{ }, @defines;
	}
	return;
}

sub requires_xs{
	my $self  = shift;

	return $self->requires() unless @_;

	$self->_xs_initialize();

	my %added = $self->requires(@_);
	my(@inc, @libs);

	my $rx_lib    = qr{ \. (?: lib | a) \z}xmsi;
	my $rx_dll    = qr{ \. dll          \z}xmsi; # for Cygwin

	while(my $module = each %added){
		my $mod_basedir = File::Spec->join(split /::/, $module);
		my $rx_header = qr{\A ( .+ \Q$mod_basedir\E ) .+ \. h(?:pp)?     \z}xmsi;

		SCAN_INC: foreach my $inc_dir(@INC){
			my @dirs = grep{ -e } File::Spec->join($inc_dir, 'auto', $mod_basedir), File::Spec->join($inc_dir, $mod_basedir);

			next SCAN_INC unless @dirs;

			my $n_inc = scalar @inc;
			find(sub{
				if(my($incdir) = $File::Find::name =~ $rx_header){
					push @inc, $incdir;
				}
				elsif($File::Find::name =~ $rx_lib){
					my($libname) = $_ =~ /\A (?:lib)? (\w+) /xmsi;
					push @libs, [$libname, $File::Find::dir];
				}
				elsif($File::Find::name =~ $rx_dll){
					# XXX: hack for Cygwin
					my $mm = $self->makemaker_args;
					$mm->{macro}->{PERL_ARCHIVE_AFTER} ||= '';
					$mm->{macro}->{PERL_ARCHIVE_AFTER}  .= ' ' . $File::Find::name;
				}
			}, @dirs);

			if($n_inc != scalar @inc){
				last SCAN_INC;
			}
		}
	}

	my %uniq = ();
	$self->cc_append_to_inc (grep{ !$uniq{ $_ }++ } @inc);

	%uniq = ();
	$self->cc_append_to_libs(grep{ !$uniq{ $_->[0] }++ } @libs);

	return %added;
}

sub cc_src_paths{
	my($self, @dirs) = @_;

	$self->_xs_initialize();

	my $mm     = $self->makemaker_args;

	my $XS_ref = $mm->{XS} ||= {};
	my $C_ref  = $mm->{C}  ||= [];

	my $_obj   = $Config{_o};

	my @src_files;
	find(sub{
		if(/ \. (?: xs | c (?: c | pp | xx )? ) \z/xmsi){ # *.{xs, c, cc, cpp, cxx}
			push @src_files, $File::Find::name;
		}
	}, @dirs);

	foreach my $src_file(@src_files){
		my $c = $src_file;
		if($c =~ s/ \.xs \z/.c/xms){
			$XS_ref->{$src_file} = $c;

			_verbose "xs: $src_file" if _VERBOSE;
		}
		else{
			_verbose "c: $c" if _VERBOSE;
		}

		push @{$C_ref}, $c unless grep{ $_ eq $c } @{$C_ref};
	}

	$self->cc_append_to_inc('.');

	return;
}

sub cc_include_paths{
	my($self, @dirs) = @_;

	$self->_xs_initialize();

	push @{ $self->{xsu_include_paths} ||= []}, @dirs;

	my $h_map = $self->{xsu_header_map} ||= {};

    foreach my $dir(@dirs){
		my $prefix = quotemeta( File::Spec->catfile($dir, '') );
		find(sub{
			return unless / \.h(?:pp)? \z/xms;

			(my $h_file = $File::Find::name) =~ s/ \A $prefix //xms;
			$h_map->{$h_file} = $File::Find::name;
		}, $dir);
	}

	$self->cc_append_to_inc(@dirs);

	return;
}

sub install_headers{
	my $self    = shift;
	my $h_files;
	if(@_ == 0){
		$h_files = $self->{xsu_header_map} or die "install_headers: cc_include_paths not specified.\n";
	}
	elsif(@_ == 1 && ref($_[0]) eq 'HASH'){
		$h_files = $_[0];
	}
	else{
		$h_files = +{ map{ $_ => undef } @_ };
	}

	$self->_xs_initialize();

	my @not_found;
	my $h_map = $self->{xsu_header_map} || {};

	while(my($ident, $path) = each %{$h_files}){
		$path ||= $h_map->{$ident} || File::Spec->join('.', $ident);

		unless($path && -e $path){
			push @not_found, $ident;
			next;
		}

		$ToInstall{$path} = File::Spec->join('$(INST_ARCHAUTODIR)', $ident);

		_verbose "install: $path as $ident" if _VERBOSE;
		$self->_extract_functions_from_header_file($path);
	}

	if(@not_found){
		die "Header file(s) not found: @not_found\n";
	}

	return;
}


# NOTE:
# This function tries to extract C functions from header files.
# Using heuristic methods, not a smart parser.
sub _extract_functions_from_header_file{
	my($self, $h_file) = @_;

	my @functions;

	my $contents = do {
		local *IN;
		local $/;
		open IN, "< $h_file" or die "Cannot open $h_file: $!";
		scalar <IN>;
	};

	# remove C comments
	$contents =~ s{ /\* .*? \*/ }{}xmsg;

	# remove cpp directives
	$contents =~ s{
		\# \s* \w+
			(?: [^\n]* \\ [\n])*
			[^\n]* [\n]
	}{}xmsg;

	# register keywords
	my %skip;
	@skip{qw(if while for int void unsignd float double bool char)} = ();


	while($contents =~ m{
			([^\\;\s]+                # type
			\s+
			([a-zA-Z_][a-zA-Z0-9_]*)  # function name
			\s*
			\( [^;#]* \)              # argument list
			[^;]*                     # attributes or something
			;)                        # end of declaration
		}xmsg){
			my $decl = $1;
			my $name = $2;

			next if exists $skip{$name};
			next if $name eq uc($name);  # maybe macros

			next if $decl =~ /\b typedef \b/xmsi;

			next if $decl =~ /\b [0-9]+ \b/xmsi; # integer literals
			next if $decl =~ / ["'] /xmsi;       # string/char literals
			#"

			push @functions, $name;

			_verbose "function: $name" if _VERBOSE;
	}

	$self->cc_append_to_funclist(@functions) if @functions;
	return;
}


sub cc_append_to_funclist{
	my($self, @functions) = @_;

	$self->_xs_initialize();

	my $mm = $self->makemaker_args;

	push @{$mm->{FUNCLIST} ||= []}, @functions;
	$mm->{DL_FUNCS} ||= { '$(NAME)' => [] };

	return;
}


package
	MY;

use Config;

# XXX: We must append to PM inside ExtUtils::MakeMaker->new().
sub init_PM{
	my $self = shift;

	$self->SUPER::init_PM(@_);

	while(my($k, $v) = each %ToInstall){
		$self->{PM}{$k} = $v;
	}
	return;
}

# append object file names to CCCMD
sub const_cccmd {
	my $self = shift;

	my $cccmd  = $self->SUPER::const_cccmd(@_);
	return q{} unless $cccmd;

	if (Module::Install::XSUtil::_is_msvc()){
		$cccmd .= ' -Fo$@';
	}
	else {
		$cccmd .= ' -o $@';
	}

	return $cccmd
}

1;
__END__

#line 578
