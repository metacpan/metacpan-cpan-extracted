package ExtUtils::DynaGlue;

use strict;
use vars qw($VERSION @xs_sections @pm_sections);

use IO::File ();
use Config;

#$Id: DynaGlue.pm,v 1.10 1996/11/27 19:31:16 dougm Exp $
$VERSION = (qw$Revision: 1.10 $)[1] . "a";

sub new {
    my $class = shift;
    my $self = bless {
	TEMPLATE_VERSION => '0.01',
	EXT => (-d 'ext' ? 'ext/' : '') ,
	AUTHOR => _author(),
	EMAIL => _email(),
	PREFIX => undef,
	CONST_XSUBS => undef,
	CONST_XSUBS_HASH => {},
	CONST_NAMES => [],
	PREFIX_NAMES => {},
	XS_SECTIONS => [],
	PM_SECTIONS => [],
	NAME => "",
	FULLPATH => undef,
	FLAGS => undef,
	PATH_H => undef,
	SCAN => {
	},
	DO_SCAN => 0,
	@_,
    } => $class;

    $self->path_h($self->{PATH_H}, $self->{DO_SCAN})
	if $self->{PATH_H};
    $self->name($self->{NAME} || $self->{PATH_H});
    $self->module($self->name);
    $self->modparts($self->name);
    $self;
}

sub _author {
    my $name = (getpwuid($>))[6] || $ENV{NAME} || "A. U. Thor";
    $name =~ s/,.*//;
    while($name =~ s/\([^\(]*\)//) { 1; } 
    $name;
}

{
    no strict;
    eval { use Mail::Util qw(mailaddress); };
    *mailaddress = sub {'a.u.thor@a.galaxy.far.far.away'} if $@;
}

sub _email {
    return mailaddress();
}

sub author { shift->_elem('AUTHOR', @_) }
sub email  { shift->_elem('EMAIL', @_) }
sub do_scan { shift->_elem('DO_SCAN', @_) }
sub no_xs { shift->_elem('NO_XS', @_) }
sub no_const { shift->_elem('NO_CONST', @_) }
sub no_auto { shift->_elem('NO_AUTO', @_) }
sub no_pod { shift->_elem('NO_POD', @_) }
sub module { shift->_elem('MODULE', @_) }
sub prefix { shift->_elem('PREFIX', @_) }
sub modfname { shift->_elem('modfname', @_) }
sub fullpath { shift->_elem('FULLPATH', @_) }
sub flags { shift->_elem('FLAGS', @_) }
sub extralibs { shift->_elem('EXTRALIBS', @_) }
sub ext { shift->_elem('EXT', @_) }
sub template_version { shift->_elem('TEMPLATE_VERSION', $_[0] || '0.01') }

sub const_xsubs {
    my $self = shift;
    my $subs = $_[0] || $self->{CONST_XSUBS};
    if($subs) {
	unless(ref $subs) {
	    $subs = [split /,+/, $subs];
	}
	$self->{CONST_XSUBS_HASH} = { map {$_,1} @$subs };
    }
    $self->{CONST_XSUBS_HASH};
}

sub path_h {
    my $self = shift;
    my($path_h, $do_scan) = @_;
    $do_scan ||= $self->{DO_SCAN};
    my(@idx) = ('PATH_H');
    push @idx, 'FULLPATH' if wantarray;
    return (@{$self}{@idx}) unless $path_h;
    $path_h .= ".h" unless $path_h =~ /\.h$/;

    my $fullpath = $path_h;
    $path_h =~ s/,.*$// if $do_scan;
    if ($^O eq 'VMS') {  # Consider overrides of default location
	if ($path_h !~ m![:>\[]!) {
	    my($hadsys) = ($path_h =~ s!^sys/!!i);
	    if ($ENV{'DECC$System_Include'})     { $path_h = "DECC\$System_Include:$path_h";    }
	    elsif ($ENV{'DECC$Library_Include'}) { $path_h = "DECC\$Library_Include:$path_h";   }
	    elsif ($ENV{'GNU_CC_Include'})       { $path_h = 'GNU_CC_Include:' .
	                                            ($hadsys ? '[vms]' : '[000000]') . $path_h; }
	    elsif ($ENV{'VAXC$Include'})         { $path_h = "VAXC\$_Include:$path_h";          }
	    else                                 { $path_h = "Sys\$Library:$path_h";            }
	}
    }
    elsif ($^O eq 'os2') {
	$path_h = "/usr/include/$path_h" 
	  if $path_h !~ m#^([a-z]:)?[./]#i and -r "/usr/include/$path_h"; 
    }
    else { 
      $path_h = "/usr/include/$path_h" 
	if $path_h !~ m#^[./]# and -r "/usr/include/$path_h"; 
    }
    $self->{PATH_H} = $path_h;
    $self->{FULLPATH} = $fullpath;
    return(@{$self}{@idx});
}

sub constants {
    my($self, $path_h, $opt_p) = @_;
    unless($self->{SCANNED}++) {
	$path_h ||= $self->path_h;
    }
    return($self->{CONST_NAMES}, $self->{PREFIX_NAMES}) unless $path_h;
    $opt_p ||= $self->prefix;
    my(%const_names, %prefix);
    # Scan the header file (we should deal with nested header files)
    # Record the names of simple #define constants into const_names
    # Function prototypes are not (currently) processed.
    local *CH; 
    open(CH, "<$path_h") || die "Can't open $path_h: $!\n";

    local($/) = "\n";
    while (<CH>) {
	if (/^#[ \t]*define\s+([\$\w]+)\b\s*[^("]/) {
	    #print "Matched $_ ($1)\n" if $opt_d;
	    $_ = $1;
	    next if /^_.*_h_*$/i; # special case, but for what?
	    if (defined $opt_p) {
		if (!/^$opt_p(\d)/) {
		    ++$self->{PREFIX_NAMES}{$_} if s/^$opt_p//;
		}
		else {
		    warn "can't remove $opt_p prefix from '$_'!\n";
		}
	    }
	    $const_names{$_}++;
	}
      }
    close(CH);
    $self->{CONST_NAMES} = [sort keys %const_names];

    return($self->{CONST_NAMES}, $self->{PREFIX_NAMES});
}

sub name {
    my($self, $name) = @_;
    return $self->{NAME} unless $name;
    $name =~ s/\.h$//;
    if( $name !~ /::/ ){
	$name =~ s#^.*/##;
	$name = "\u$name";
    }
    $self->{NAME} = $name;
}

sub modparts {
    my($self, $module) = @_;
    $module ||= $self->module;
    my($nested, @modparts, $modfname, $modpname);
    if( $module =~ /::/ ){
	$nested = 1;
	@modparts = split(/::/,$module);
	$modfname = $modparts[-1];
	$modpname = join('/',@modparts);
    }
    else {
	$nested = 0;
	@modparts = ();
	$modfname = $modpname = $module;
    }
    @{$self}{qw(modfname modpname modparts)} = 
	($modfname, $modpname, [@modparts]);
}

sub mkdirs {
    my($self, $modpname, $modparts) = @_;
    if( scalar @$modparts ){
	my $modpath = "";
	foreach (@$modparts){
	    mkdir("$modpath$_", 0777);
	    $modpath .= "$_/";
	}
    }
    mkdir($modpname, 0777);
}

sub function_scan {
    my($self, $fullpath, $addflags) = @_;
    return($self->fdecls, $self->parsed_fdecls) unless $fullpath;
    require C::Scan;		# Run-time directive
    require Config;		# Run-time directive
    #warn "Scanning typemaps...\n";
    $self->get_typemap();
    my $c;
    my $filter;
    my $filename = $self->path_h;
    $addflags ||= '';
    if ($fullpath =~ /,/) {
      $filename = $`;
      $filter = $';
    }
    #warn "Scanning $filename for functions...\n";
    my $c = new C::Scan 'filename' => $filename, 'filename_filter' => $filter,
    'add_cppflags' => $addflags;
    $c->set('includeDirs' => ["$Config::Config{archlib}/CORE"]);
    
    ($self->{SCAN}{fdecls}, $self->{SCAN}{parsed_fdecls}) = 
	($c->get('fdecls'), $c->get('parsed_fdecls'));
}

sub fdecls { $_[0]->{SCAN}{fdecls} }
sub parsed_fdecls { $_[0]->{SCAN}{parsed_fdecls} }

# Should be called before any actual call to normalize_type().
sub get_typemap {
    my($self) = @_;
    $self->{SCAN}{std_types} = {};
    $self->{SCAN}{types_seen} = {};
    # We do not want to read ./typemap by obvios reasons.
    my @tm =  qw(../../../typemap ../../typemap ../typemap);
    my $stdtypemap =  "$Config::Config{privlib}/ExtUtils/typemap";
    unshift @tm, $stdtypemap;
    my $proto_re = "[" . quotemeta('\$%&*@;') . "]" ;
    my($image, $typemap, $type);
    local *TYPEMAP;

    foreach $typemap (@tm) {
	next unless -e $typemap ;
	# skip directories, binary files etc.
	warn " Scanning $typemap\n";
	warn("Warning: ignoring non-text typemap file '$typemap'\n"), next 
	    unless -T $typemap ;
	open(TYPEMAP, $typemap) 
	    or warn ("Warning: could not open typemap file '$typemap': $!\n"), next;
	my $mode = 'Typemap';
	while (<TYPEMAP>) {
	    next if /^\s*\#/;
	    if (/^INPUT\s*$/)   { $mode = 'Input'; next; }
	    elsif (/^OUTPUT\s*$/)  { $mode = 'Output'; next; }
	    elsif (/^TYPEMAP\s*$/) { $mode = 'Typemap'; next; }
	    elsif ($mode eq 'Typemap') {
		next if /^\s*($|\#)/ ;
		if ( ($type, $image) = 
		    /^\s*(.*?\S)\s+(\S+)\s*($proto_re*)\s*$/o
		    # This may reference undefined functions:
		    and not ($image eq 'T_PACKED' and $typemap eq $stdtypemap)) {
		    $self->normalize_type($type);
		}
	    }
	}
	close(TYPEMAP) or die "Cannot close $typemap: $!";
    }
    %{$self->{SCAN}{std_types}} = %{$self->{SCAN}{types_seen}};
    %{$self->{SCAN}{types_seen}} = ();
}

sub normalize_type {
    my($self, $type) = @_;
    my $ignore_mods = '(?:\b(?:__const__|static|inline|__inline__)\b\s*)*';
    $type =~ s/$ignore_mods//go;
    $type =~ s/([\]\[()])/ \1 /g;
    $type =~ s/\s+/ /g;
    $type =~ s/\s+$//;
    $type =~ s/^\s+//;
    $type =~ s/\b\*/ */g;
    $type =~ s/\*\b/* /g;
    $type =~ s/\*\s+(?=\*)/*/g;
    $self->{SCAN}{types_seen}{$type}++ 
	unless $type eq '...' or $type eq 'void' or $self->{SCAN}{std_types}{$type};
    $type;
}

sub print_decl {
    my $self = shift;
    #my $fh = shift;
    my $decl = shift;
    my ($type, $name, $args) = @$decl;
    my $retval;
    return if $self->{seen_decl}{$name}++; # Need to do the same for docs as well?

    my @argnames = map {$_->[1]} @$args;
    my @argtypes = map { $self->normalize_type( $_->[0] ) } @$args;
    my @argarrays = map { $_->[4] || '' } @$args;
    my $numargs = @$args;
    if ($numargs and $argtypes[-1] eq '...') {
	$numargs--;
	$argnames[-1] = '...';
    }
    local $" = ', ';
    $type = $self->normalize_type($type);
  
  $retval .= <<"EOP";

$type
$name(@argnames)
EOP
    my $arg;
  for $arg (0 .. $numargs - 1) {
    $retval .= <<"EOP";
	$argtypes[$arg]	$argnames[$arg]$argarrays[$arg]
EOP
  }
    return $retval;
}

sub pm_open {
    my($self, $file) = @_;
    $file ||= join '.', $self->modfname, "pm";
    warn "Writing $file for module $self->{MODULE}\n" if $self->{VERBOSE};
    return new IO::File ">$file";
}

sub pm_top_sec {
    my($self) = @_;
    my $module = $self->module;

    return <<"END";
package $module;

use strict;

END
}

sub pm_use_vars_sec {
    my($self, @vars) = @_;
    my $use_carp;
    if( $self->no_xs || $self->no_const || $self->no_auto ) {
	# we won't have our own AUTOLOAD(), so won't have $AUTOLOAD
	unshift @vars, qw($VERSION @ISA @EXPORT);
    }
    else {
	unshift @vars, qw($VERSION @ISA @EXPORT $AUTOLOAD);
	$use_carp = "use Carp;\n";
    }
	return <<"END";
${use_carp}use vars qw(@vars);
END
}

sub pm_requires {
    my($self, @requires) = @_;
    
    unshift @requires, 'Exporter';
    unshift @requires, 'DynaLoader' unless $self->no_xs;

# require autoloader if XS is disabled.
# if XS is enabled, require autoloader unless autoloading is disabled.
    unshift @requires, 'AutoLoader' if( $self->no_xs || (! $self->no_auto) );
    
    [@requires];
}

sub pm_requires_sec {
    join "\n", (map { "require $_;" } @{ shift->pm_requires(@_) }), "";
}

sub pm_isa {
    my($self, @isa) = @_;
    if( $self->no_xs || ($self->no_const && ! $self->no_auto) ){
	# we won't have our own AUTOLOAD(), so we'll inherit it.
	if(! $self->no_xs ) { # use DynaLoader, unless XS was disabled
	    push @isa, qw(Exporter AutoLoader DynaLoader);
	}
	else {
	    push @isa, qw(Exporter AutoLoader);
	}
    }
    else {
	# 1) we have our own AUTOLOAD(), so don't need to inherit it.
	# or
	# 2) we don't want autoloading mentioned.
	if( ! $self->no_xs ){ # use DynaLoader, unless XS was disabled
	    push @isa, qw(Exporter DynaLoader);
	}
	else{
	    push @isa, qw(Exporter);
	}
    }
    [@isa];
}

sub pm_isa_sec {
    "\n\n\@ISA = qw(@{ shift->pm_isa(@_) });\n";
}

sub pm_export {
    my($self, @export) = @_;
    my($const, $prefix) = $self->constants;
    push @$const, @export;
    $const;
}

sub pm_export_sec {
    my($self) = shift;
    local($") = "\n\t";
    my(@export) = @{ $self->pm_export(@_) };

    return <<"END";

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

\@EXPORT = qw(
	@export	      
);

END
}

sub pm_version {
    my($self) = @_;
    $self->{VERSION} || $self->template_version;
};

sub pm_version_sec {
    my($self) = @_;
    my $version = $self->pm_version;
    return <<"END";

\$VERSION = '$version';

END
}

sub pm_autoload_sec {
    my($self) = @_;

    my $module = $self->module;
    return if $self->no_const or $self->no_xs;
    return <<"END"; 
sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my \$constname;
    (\$constname = \$AUTOLOAD) =~ s/.*:://;
    my \$val = constant(\$constname, \@_ ? \$_[0] : 0);
    if (\$! != 0) {
	if (\$! =~ /Invalid/) {
	    \$AutoLoader::AUTOLOAD = \$AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined $module macro \$constname";
	}
    }
    eval "sub \$AUTOLOAD () { \$val }";
    goto &\$AUTOLOAD;
}

END
}

sub pm_bootstrap_sec {
    my($self) = @_;
    my $module = $self->module;

    return if $self->no_xs;
    # print bootstrap, unless XS is disabled
    return <<"END";

bootstrap $module \$VERSION;
END
}


sub pm_bottom_sec {
    my($self) = @_;
    my $after;
    if( $self->no_pod ){ # if POD is disabled
	$after = '__END__';
    }
    else {
	$after = '=cut';
    }
    
    return <<"END";

# Preloaded methods go here.

# Autoload methods go after $after, and are processed by the autosplit program.

1;
__END__
END

}

sub pm_const_doc {
    my($self) = @_;
    my $const_names = $self->pm_export;

    if (@$const_names and not $self->no_pod) {
	return <<EOD;
\n=head1 Exported constants

  @{[join "\n  ", @$const_names]}

EOD
    }
}

sub pm_fdecl_doc {
    my($self) = @_;
    my $fdecls = $self->fdecls;
    if (defined $fdecls and @$fdecls and not $self->no_pod) {
	return <<EOD;
\n=head1 Exported functions

  @{[join "\n  ", @$fdecls]}

EOD
    }
}

sub pm_pod_sec {
    my($self) = @_;
    my $module = $self->module;
    my $const_doc = $self->pm_const_doc || '';
    my $fdecl_doc = $self->pm_fdecl_doc || '';
    my $author = $self->author;
    my $email = $self->email;
    return if $self->no_pod;
    my $pod = <<"END";
## Below is the stub of documentation for your module. You better edit it!
#
#=head1 NAME
#
#$module - Perl extension for blah blah blah
#
#=head1 SYNOPSIS
#
#  use $module;
#  blah blah blah
#
#=head1 DESCRIPTION
#
#Stub documentation for $module was created by h2xs. It looks like the
#author of the extension was negligent enough to leave the stub
#unedited.
#
#Blah blah blah.
#$const_doc$fdecl_doc
#=head1 AUTHOR
#
#$author <$email>
#
#=head1 SEE ALSO
#
#perl(1).
#
#=cut
END

    $pod =~ s/^\#//gm;
    return $pod;
}

@pm_sections = qw{
  top
  use_vars
  requires
  isa
  export
  version
  autoload
  bootstrap
  bottom
  pod
};

sub pm_sections {
    my($self) = shift;
    if(scalar @_) {
	$self->{PM_SECTIONS} = [@_];
    }
    return @{$self->{PM_SECTIONS}} ? $self->{PM_SECTIONS} : [@pm_sections];
}

sub write_pm {
    my($self, $file) = @_;
    my $pm = $self->pm_open($file) or die "Can't create $file $!";
    my $sec;
    foreach (@{ $self->pm_sections }) {
	$sec = join "_", 'pm', $_, 'sec';
	$pm->print($self->$sec());
    }
    $pm->close;
}

sub xs_open {
    my($self, $file) = @_;
    $file ||= join '.', $self->modfname, "xs";
    return undef if $self->no_xs;
    warn "Writing $file for module $self->{MODULE}\n" if $self->{VERBOSE};
    return new IO::File ">$file";
}

sub xs_includes_sec {
    my($self) = @_;
    my $path_h = $self->path_h;
    my $string = <<END;
#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

END
    if( $path_h ){
	my($h) = $path_h;
	$h =~ s#^/usr/include/##;
	if ($^O eq 'VMS') { $h =~ s#.*vms\]#sys/# or $h =~ s#.*[:>\]]##; }
        $string .= <<"END";
#include <$h>

END
    }
    return $string;
}

sub xs_not_here_func {
    my($self) = @_;
    my $module = $self->module;

    return <<"END";
static int
not_here(s)
char *s;
{
    croak("$module::%s not implemented on this architecture", s);
    return -1;
}
END
}

sub xs_constant_func {
    my($self) = @_;

    my $retval = <<'END';
static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
END

    my(@AZ, @az, @under, $letter, $name, $macro);
    my($const_names, $prefix) = $self->constants;

    foreach(@$const_names){
	@AZ = 'A' .. 'Z' if !@AZ && /^[A-Z]/;
	@az = 'a' .. 'z' if !@az && /^[a-z]/;
	@under = '_'  if !@under && /^_/;
    }

    my $opt_p = $self->prefix;
    my $const_xsub = $self->const_xsubs;
    foreach $letter (@AZ, @az, @under) {

	last if $letter eq 'a' && !@$const_names;

	$retval .= "    case '$letter':\n";
	my $i = 0;
	while (substr($const_names->[$i],0,1) eq $letter) {
	    $name = $const_names->[$i];
	    $i++;
	    $macro = $prefix->{$name} ? "$opt_p$name" : $name;
	    next if $const_xsub->{$macro};
	$retval .= <<"END";
	if (strEQ(name, "$name"))
#ifdef $macro
	    return $macro;
#else
	    goto not_there;
#endif
END
        }
	$retval .= <<"END";
	break;
END
    }

    $retval .= <<"END";
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

END
    return $retval;
}

sub xs_constants_sec {
    my($self) = @_;
    return if $self->no_const;
    join '', map { $self->$_() } qw{
	xs_not_here_func
	xs_constant_func
    };    
}

sub xs_decl_sec {
    my($self) = @_;
    my $opt_p = $self->prefix;
    my $module = $self->module;
    my $pre = "\tPREFIX = $opt_p" if defined $opt_p;
# Now switch from C to XS by issuing the first MODULE declaration:
    return <<"END";

MODULE = $module		PACKAGE = $module${pre}

END
}

sub xs_const_subs {
    my($self) = @_;
    my $const_xsub = $self->const_xsubs;
    my $module = $self->module;
    my $retval;
    foreach (sort keys %$const_xsub) {
	$retval .= <<"END";
char *
$_()

    CODE:
#ifdef $_
    RETVAL = $_;
#else
    croak("Your vendor has not defined the $module macro $_");
#endif

    OUTPUT:
    RETVAL

END
    }
    return $retval;
}

sub xs_constant_sub {
    my($self) = @_;
# If a constant() function was written then output a corresponding
# XS declaration:
    return if $self->no_const;
    return <<'END';
double
constant(name,arg)
	char *		name
	int		arg

END
}

sub xs_scanned_subs {
    my($self) = @_;
    return unless $self->do_scan;
    my($fdecls, $fdecls_parsed) = 
	$self->function_scan($self->fullpath, $self->flags);
    return join '', 
       map { $self->print_decl($_) } @$fdecls_parsed;  
}

sub xs_subs_sec {
    my($self) = @_;
    join '', map { $self->$_() } qw{
	xs_constant_sub
	xs_const_subs
        xs_scanned_subs    
    };    
}

@xs_sections = qw{
   includes
   constants
   decl
   subs
};

sub xs_sections {
    my($self) = shift;
    if(scalar @_) {
	$self->{XS_SECTIONS} = [@_];
    }
    return @{$self->{XS_SECTIONS}} ? $self->{XS_SECTIONS} : [@xs_sections];
}

sub write_xs {
    my($self, $file) = @_;
    return if $self->no_xs;
    my $xs = $self->xs_open($file) or die "Can't create $file $!";
    my $sec;
    foreach (@{ $self->xs_sections }) {
	$sec = join "_", 'xs', $_, 'sec';
	$xs->print($self->$sec());
    }
    $xs->close;
}

# XXX need to fine-grain the rest of these write_* methods

sub write_typemap {
    my($self, $file) = @_;
    $file ||= "typemap";
    warn "Writing $file for module $self->{MODULE}" if $self->{VERBOSE};
    my(%types_seen) = $self->{SCAN}{types_seen};
    local *TM;
    if (%types_seen) {
	my $type;
	open TM, ">$file" or die "Cannot open typemap file for write: $!";

	for $type (keys %types_seen) {
	    print TM $type, "\t" x (6 - int((length $type)/8)), "T_PTROBJ\n"
        }

	close TM or die "Cannot close typemap file for write: $!";
	return 1;
    }
}

sub write_makefilepl {
    my($self, $file) = @_;
    $file ||= "Makefile.PL";
    warn "Writing $file for module $self->{MODULE}" if $self->{VERBOSE};
    local *PL;
    my $module = $self->module;
    my $modfname = $self->modfname;
    my $extralibs = $self->extralibs;

    open(PL, ">$file") || 
	die "Can't create $file: $!\n";

    print PL <<'END';
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
END
    print PL "WriteMakefile(\n";
    print PL "    'NAME'	=> '$module',\n";
    print PL "    'VERSION_FROM' => '$modfname.pm', # finds \$VERSION\n"; 
    unless($self->no_xs){ # print C stuff, unless XS is disabled
	print PL "    'LIBS'	=> ['$extralibs'],   # e.g., '-lm' \n";
	print PL "    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' \n";
	print PL "    'INC'	=> '',     # e.g., '-I/usr/include/other' \n";
    }
    print PL ");\n";
    close(PL) || die "Can't close $file: $!\n";
}

sub write_test {
    my($self, $file) = @_;
    $file ||= "test.pl";
    warn "Writing $file for module $self->{MODULE}" if $self->{VERBOSE};
    local *EX;
    my $module = $self->module;

    open(EX, ">$file") || die "Can't create $file: $!\n";
    print EX <<'_END_';
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
_END_
print EX <<_END_;
use $module;
_END_
print EX <<'_END_';
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

_END_
    close(EX) || die "Can't close $file: $!\n";
}

sub write_changes {
    my($self, $file) = @_;
    $file ||= 'Changes';
    my $module = $self->module;
    my $version = $self->template_version;
    warn "Writing $file for module $self->{MODULE}" if $self->{VERBOSE};
    local *EX;
    open(EX, ">$file") || die "Can't create $file: $!\n";
    print EX "Revision history for Perl extension $module.\n\n";
    print EX "$version  ",scalar localtime,"\n";
    print EX "\t- original version; created by ExtUtils::DynaGlue $VERSION\n\n";
    close(EX) || die "Can't close $file: $!\n";
}

sub write_manifest {
    my($self, $dir) = @_;
    $dir ||= '';
    $dir .= "/" if $dir;
    local(*MANI, *D);
    warn "Writing MANIFEST for module $self->{MODULE}" if $self->{VERBOSE};
    open(MANI,">${dir}MANIFEST") or die "Can't create ${dir}MANIFEST: $!";
    my(@files) = glob($dir . "*");
    if (!@files) {
	eval {opendir(D,$dir);};
	unless ($@) { @files = readdir(D); closedir(D); }
    }
    if (!@files) { @files = map {chomp && $_} `ls $dir`; }
    print MANI join("\n",@files);
    close MANI;
}

sub _elem {
    my($self, $elem, $val) = @_;
    return $self->{$elem} unless $val;
    $self->{$elem} = $val;
}


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

ExtUtils::DynaGlue - Methods for generating Perl extension files

=head1 SYNOPSIS

  use ExtUtils::DynaGlue ();

=head1 DESCRIPTION


=head1 AUTHOR

Doug MacEachern <dougm@osf.org> 
based on h2xs written by Larry Wall and others

=head1 SEE ALSO

perl(1).

=cut
