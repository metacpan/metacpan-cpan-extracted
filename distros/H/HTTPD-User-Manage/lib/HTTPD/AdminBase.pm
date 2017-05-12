# $Id: AdminBase.pm,v 1.1.1.1 2001/02/20 02:32:11 lstein Exp $
package HTTPD::AdminBase;
use strict;

use Carp ();
use Fcntl ();
use Symbol qw(gensym);
use File::Basename;
use Fcntl qw(:DEFAULT :flock);
use vars qw($VERSION);
$VERSION = (qw$Revision: 1.1.1.1 $)[1];

#generic contructor stuff

my $Debug = 0;
my %Default = (DBTYPE => "DBM",
	       SERVER => "_generic",
	       DEBUG  => $Debug,
	       LOCKING => 1,
	       READONLY => 0,
	       );

my %ImplementedBy = ();

sub new {
    my($class) = shift;
    my $attrib = { %Default, @_ };
    for (keys %$attrib) { $attrib->{"\U$_"} = delete $attrib->{$_}; }
    $Debug = $attrib->{DEBUG} if defined $attrib->{DEBUG};

    #who's gonna do all the work?
    my $impclass = $class->implementor(@{$attrib}{qw(DBTYPE SERVER)});
    unless ($impclass) {
	Carp::croak(sprintf "%s not implemented for Server '%s' and DBType '%s'",
	               $class, @{$attrib}{qw(SERVER DBTYPE)});
    }
    #the final product
    return new $impclass ( %{$attrib} );
}

sub close { $_[0] = undef }

sub dbtype {
    my($self,$dbtype) = @_;
    my $old = $self->{DBTYPE};
    return $old unless $dbtype;
    Carp::croak("Can't modify DBType attribute");
    #I think it makes more sense 
    #just to create a new instance in your script
    my $base = $self->baseclass(3); #snag HTTPD::(UserAdmin|GroupAdmin)::(DBM|Text|SQL)
    $self->close;
    $self = $base->new( %{$self}, DBType => $dbtype );
    return $old;
}

#implementor code derived from URI::URL
sub implementor {
    my($self,$dbtype,$server,$impclass) = @_;
    my $class = ref $self || $self;
    my $ic;
    if(ref $self) {
	($server,$dbtype) = @{$self}{qw(SERVER DBTYPE)};
    }

    $server = (defined $server) ? lc($server) : '_generic';
    $dbtype = (defined $dbtype) ? $dbtype     : 'DBM';
    my $modclass = join('::', $class,$dbtype,$server);
    if ($impclass) {
        $ImplementedBy{$modclass} = $impclass;
    }

    return $ic if $ic = $ImplementedBy{$modclass};

    #first load the database class
    $ic = $self->load($class, $dbtype);

    # now look for a server subclass
    $ic = $self->load($ic, $server);

    if ($ic) {
        $ImplementedBy{$ic} = $ic;
    }
    $ic;
}

sub load {
    my($self) = shift;
    my($ic,$module);
    if(@_ > 1) { $ic = join('::', @_) }
    else       { $ic = $_[0] }
    no strict 'refs';
    unless (defined @{"${ic}::ISA"}) {
	# Try to load it
	($module = $ic) =~ s,::,/,g;
	$module =~ /^[^<>|;]+$/; $module = $&; #untaint
	eval { require "$module.pm"; };
	print STDERR "loading $ic $@\n" if $Debug;
	$ic = '' unless defined @{"${ic}::ISA"};
    }
    $ic;
}

sub support {
    my($self,%support) = @_;
    my $class = ref $self || $self; 
    my($code,$db,$srv);
    foreach $srv (keys %support) {
	no strict 'refs';
	foreach $db (@{$support{$srv}}) {
	    @{"$class\:\:$db\:\:$srv\:\:ISA"} = qq($class\:\:$db\:\:_generic);
	}
    }
}

sub _check {
    my($self) = shift;
    foreach (@_) {
	next if defined $self->{$_};
	Carp::croak(sprintf "cannot construct new %s object without '%s'", ref $self || $self, $_);
    }
}

sub _elem {
    my($self, $element, $val) = @_;
    my $old = $self->{$element};
    return $old unless $val;
    $self->{$element} = $val; 
    return $old;
}

#DBM stuff
sub _tie {
    my($self, $key, $file) = @_;
    printf STDERR "%s->_tie($file)\n", ref $self || $self if $Debug;
    Carp::confess 
	qq{Invalid HTTPD::AdminBase call: self="$self" key="$key" file="$file" \$self->{$key}="$self->{$key}"} 
    unless defined $key and defined $file;
    $self->{$key} ||= {};
    my($d,$f,$fl,$m) = ($self->{'_DBMPACK'}, $file, @{$self}{qw(_FLAGS MODE)});

    tie %{$self->{$key}}, $d, $f, $fl, $m
 	or Carp::croak("tie failed (args[$d,$f,$fl,$m]): $!");    
}

sub _untie {
    my($self, $key) = @_;
    untie %{$self->{$key}};
}

my(%DBMFiles) = ();
my(%DBMFlags) = (
	     GDBM => { 
		 rwc => sub { GDBM_File::GDBM_WRCREAT() },
		 rw  => sub { GDBM_File::GDBM_READER()|GDBM_File::GDBM_WRITER() },
		 w   => sub { GDBM_File::GDBM_WRITER() },
		 r   => sub { GDBM_File::GDBM_READER() },
	     },
	     DEFAULT => { 
		 rwc => sub { O_RDWR|O_CREAT },
		 rw  => sub { O_RDWR },
		 w   => sub { O_WRONLY },
		 r   => sub { O_RDONLY },
	     },
);

sub _dbm_init {
    my($self,$dbmf) = @_;
    $self->{DBMF} = $dbmf if defined $dbmf;
    my($flags, $dbmpack);
    unless($dbmpack = $DBMFiles{$self->{DBMF}}) {
	$DBMFiles{$dbmpack} = $dbmpack = "$self->{DBMF}_File";
	$self->load($dbmpack) or Carp::croak("can't load '$dbmpack'");
    }

    @{$self}{qw(_DBMPACK _FLAGS)} = ($dbmpack, $self->flags);
    1;
}

sub lock {
    my($self,$timeout,$file) = @_;
    my($FH) = $self->{'_LOCKFH'} = $self->gensym;
    return 1 unless $self->{LOCKING};
    $timeout = $timeout || 10;

    unless($file = $file || "$self->{DB}.lock") {
	Carp::croak("can't set lock, no file specified!");
    }
    unless ( -w dirname($self->{'_LOCKFILE'} = $file)) {
	print STDERR "lock: can't write to '$file' " if $Debug;
	#for writing lock files under CGI and such
	$self->{'_LOCKFILE'} = $file = 
	    sprintf "%s/%s-%s", $self->tmpdir(), "HTTPD", basename($file);
	print STDERR "trying '$file' instead\n" if $Debug;
    }

    $file =~ /^([^<>;|]+)$/ or Carp::croak("Bad file name '$file'"); $file = $1; #untaint

    open($FH, ">$file") || Carp::croak("can't open '$file' $!");

    while(! flock($FH, LOCK_EX|LOCK_NB) ) {
	sleep 1;
	if(--$timeout < 0) {
	    print STDERR "lock: timeout, can't lock $file \n";
	    return 0;
	}
    }
    print STDERR "lock-> $file\n" if $Debug;
    1;
}

sub unlock { 
    my($self) = @_;
    return 1 unless $self->{LOCKING};
    my $FH = $self->{'_LOCKFH'};
    flock($FH, LOCK_UN);
    CORE::close($FH);
    unlink $self->{'_LOCKFILE'};
    print STDERR "unlock-> $self->{'_LOCKFILE'}\n" if $Debug;
    1;
}

#hmm, this doesn't seem right
sub tmpdir {
    my($self) = @_;
    return $self->{TMPDIR} if defined $self->{TMPDIR};
    my $dir;
    foreach ( qw(/tmp /usr/tmp /var/tmp) ) {
	last if -d ($dir = $_);
    }
    $self->{TMPDIR} = $dir;
}

sub import {}
sub DESTROY { warn "in AdminBase::DESTROY" }
sub class { ref $_[0] || $_[0] }
sub readonly { shift->flags == Fcntl::O_RDONLY() }
sub debug   { shift->_elem('DEBUG',   @_) }
sub path    { shift->_elem('PATH',    @_) }
sub locking { shift->_elem('LOCKING', @_) }
sub flags { 
    my($self, $mode) = @_; 
    my $flags;
    my $key = $self->{DBMF} || "DEFAULT";
    $mode ||= $self->{FLAGS};
    $self->{FLAGS} = $mode;
    $key = "DEFAULT" unless defined $DBMFlags{$key};
    if(defined $DBMFlags{$key}->{$mode}) {
	$flags = &{$DBMFlags{$key}->{$mode}};
    }
    return $flags;
}
#fallback, only implemented with DBType => Text
sub commit { (1,''); }

sub baseclass {
    my($self, $n) = @_;
    my $class = join '::', (split(/::/, (ref $self || $self)))[0 .. $n - 1];
    #print "baseclass got '$class' from '$self'\n";
    $class;
}

1;

