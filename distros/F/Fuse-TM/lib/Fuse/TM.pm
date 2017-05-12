package Fuse::TM;
# $Id: TM.pm,v 1.4 2009-12-09 06:35:01 az Exp $ 

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
$VERSION = qw(('$Revision: 1.4 $'))[1];

use POSIX  qw(:errno_h);
use Fuse qw(:all);
use Fcntl qw(:mode);
use File::Basename;
use File::Spec;
use Cwd qw(realpath);
use TM 1.43;
use TM::Index::Match;
use TM::Index::Characteristics;
use TM::Literal;
use Data::Dumper;
use Getopt::Std;
use Carp qw(verbose);

=pod

=head1 NAME

Fuse::TM - Access a Topic Map as a Filesystem

=head1 SYNOPSIS

 use Fuse::TM;
 use TM;

 my $map; 
 # map must be created/synced in somehow, see TM(1).

 my $tmfs=Fuse::TM->new(tm=>$map,rw=>1,debug=>1);

 # this blocks until the filesystem is unmounted, 
 # see fusermount.
 $tmfs->mount("/tmp/somedir"); 

See also the L<tmfs(1)> front-end.

=head1 DESCRIPTION

This package provides access to a Topic Map in form of a filesystem. 
Read-write access to the map is supported.

=head1 Filesystem Layout

The mountpoint will be populated with exactly two directories, F<topics>
and F<assocs>.

=head2 Topics

The topics in the map are modelled as directories, one per topic,
under the F<topics> directory. 
Each topic directory contains a number of sub-directories and some files,
all of which have fixed names. The following list details those elements:

=over 1

=item F<instance> 

is a subdir which contains symlinks to all topics that are
instances of this topic. The topic ids are used as names 
for the symlinks. If no instances are present then the directory is empty.

=item F<isa>

is a subdir which contains symlinks to all topics this 
topic is an instance of (=classes).
The topic ids are used as names for the symlinks.
If no parent classes are present then the directory is empty.

=item F<instances> 

is a read-only file that contains the topic ids of instances
of this topic, one per line. The file is empty if no
instances are present.

=item F<isas>

is a read-only file that contains the topic ids of all topics 
this one is an instance of (=classes), one per line. The file is empty if no
classes are present.

=item F<involved> 

is a read-only subdir which contains symlinks to all 
associations where this topic is involved (as a player, 
role or type). The names of the symlinks are of the 
format I<N:T>, with N an arbitrary number and T 
either "role", "player" or "type" depending on the involvement 
of the topic. The dir is empty if no involvements are present.

=item F<name>

is a subdir that contains all basenames of this topic. The basenames 
are presented in separate files, with all filenames following 
the format I<N[@S][:T]>. N is a running number, S is the scope topic id if 
the basename is (non-universally) scoped, and T is the type topic id if 
the basename is (non-trivially) typed.
The content of the file is the basename text. The dir is empty if no
basenames are present.

=item F<oc>

is a subdir that contains all occurrences attached to this topic. The occurrences
are presented in separate files whose names follow the same scheme as basenames.
The file content is the occurrence (text or URI). The dir is empty if 
no occurrences are present.

=item F<~>

is a file that contains all subject indicator URIs for this topic, one URI per line.
Present but empty if no subject indicators exist.

=item F<=>

is a symlink that points to a subject locator topic (=reified by this topic).
If the topic reifies another topic or association in the same map, then the 
symlink points to that object. If the reified topic is given as URI, then the symlink will point 
to that URI (and thus likely dangle).
The symlink is not present if this topic doesn't reify another.

=back 

=head2 Associations

Isa (class/instance) associations are presented as characteristics attached to
the relevant topics (see isa/instance above). 

All other, general, associations are modelled as directories under the F<assocs> directory.
For each association type there is a subdir under F<assocs> with the 
type topic id as name. Within that, each thusly typed association instance
is represented as a subdir with a running number as name.

This association instance directory contains one symlink named F<.type> pointing
back to the type topic for this association. 
For each role in the association there is a subdir named after the role topic id,
which contains symlinks for all the player topics of this role. 

=cut

my $td="topics";
my $ad="assocs";

=pod

=head1 METHODS

=over 1

=item new()

$tmfs=Fuse::TM->new(tm=>$tmobj,I<option=E<gt>value,...>);

The constructor requires a TM map object and accepts the following other options,
to be given as key/value pairs:

=over 1

=item debug

Debugging: if set to 1, Fuse::TM internal debugging is enabled (to STDERR).
If set to 2, Fuse debugging is enabled additionally. Default: undef.

=item rw

Read-write mode: if set to 1 the filesystem is mounted read-write
and changes are written out the the map on unmounting. Defaults to undef: read-only mode.

=item autocreate

Autocreate implied topics. If set to 1 and read-write mode is active, then non-existent
topics are automatically created when a write action implies their existence. 
Default: undef. 

For example writing to the file F<topics/x/oc/1:something> will create the topic
"something" if it didn't exist because the filename implies the occurrence 
to be of type "something".

=item hide

Hide infrastructure items. If set to 1 infrastructure topics and associations are suppressed.
See L<TM::PSI> for details of what infrastructure elements are automatically created
(and subject to the hide option). Default: undef. 

=item output

Output URI. If read-write mode is active and there were changes then the updated map
is written on unmount. This option controls whether the original map is overwritten (default)
or whether the new map is saved someplace else. The output parameter must follow the URI
format described in L<TM::Serializable> (i.e. io:stdout or file:something).

=item outputdriver

TM Driver to use for the output. Defaults to the driver of the input map.
Can be set to the name of a TM class that supports sync_out (i.e. TM::Materialized::*, 
TM::Serializable::* or TM::Synchronizable::*). 

=back

The constructor will croak() if problems are encountered.

=cut

sub new
{
    my ($class,%o)=@_;

    # options:
    # tm
    # debug
    # rw
    # autocreate
    # hide
    # output
    # outputdriver

    Carp::croak("no/invalid map object given!\n")
	if (ref($o{tm}) !~ /^TM::(Materialized|Synchronizable|Serializable)/);
    my $now=$o{tm}->mtime||time;
    my $self=
    {
	tm=>$o{tm},
	output=>$o{output},
	outputdriver=>$o{outputdriver},
	debug=>$o{debug},
	rw=>$o{rw},
	autocreate=>($o{rw} && $o{autocreate}),
	hide=>$o{hide},
	mtime=>$now,
    };

    return bless $self,$class;
}

=pod

=item mount()

$tmfs->mount("/some/mount/dir");

Calls Fuse to mount the filesystem at the specified mount point, which must
be an existing directory. This function blocks until the filesystem is
unmounted. If read-write mode is enabled, then the updated map will be saved
on unmount. mount will croak() if problems are encountered.

=back 

=cut 

sub mount
{
    my ($self,$mountpt)=@_;

    Carp::croak("invalid object argument\n") if (!ref($self) || !$self->isa(__PACKAGE__));
    Carp::croak("invalid mountpoint \"$mountpt\"\n")
	if (!$mountpt || !-d $mountpt);

    $self->{tm}->sync_in;
    $self->debug("done reading, starting indexing\n");
    new TM::Index::Match($self->{tm});
    new TM::Index::Characteristics($self->{tm});
    $self->debug("building fs datastructure\n");
    $self->maptofs;
    $self->{mountpoint}=$mountpt;

    $self->debug("ready.\nmounting on $mountpt\n");
    $mountpt=realpath($mountpt);	# absolutize the mountpoint, for symlink lookups later 
    Fuse::main(mountpoint=>$mountpt,
	       debug=>$self->{debug}>1?1:0,
	       getattr=>sub { return $self->tm_getattr(@_); },
	       getdir=>sub { return $self->tm_getdir(@_); },
	       read=>sub { return $self->tm_read(@_); },
	       readlink=>sub { return $self->tm_readlink(@_); },
	       $self->{rw}?
	       ( write=>sub { return $self->tm_write(@_);},
		 release=>sub { return $self->tm_release(@_); },
		 chmod=>sub { return $self->tm_dummy(@_); },
		 chown=>sub { return $self->tm_dummy(@_); },
		 utime=>sub { return $self->tm_dummy(@_); },
		 truncate=>sub { return $self->tm_truncate(@_); },
		 rename=>sub { return $self->tm_rename(@_); },
		 mkdir=>sub { return $self->tm_mkdir(@_); },
		 symlink=>sub { return $self->tm_symlink(@_); },
		 unlink=>sub { return $self->tm_unlink(@_); },
		 rmdir=>sub { return $self->tm_rmdir(@_); },
		 mknod=>sub { return $self->tm_mknod(@_); }
		 ):()
	       );
    
    if ($self->{rw})
    {
	$self->debug("unmounting, r/w-mode\n");
	if (keys %{$self->{dirty}})
	{
	    my $d=$self->{outputdriver};
	    if ($d)
	    {
		$self->debug("changing output driver to '$d'");
		Class::Trait->apply($self->{tm},$d);
	    }

	    my $n=$self->{output};
	    if ($n)
	    {
		$self->debug("changing output to '$n'\n");
		$self->{tm}->url($n);
	    }
	    $self->debug("writing map out\n");
	    $self->{tm}->sync_out;
	    $self->debug("done.\n");
	}
	else
	{
	    $self->debug("no dirty data needs syncing, done.\n");
	}
    }
    else
    {
	$self->debug("unmounted, r/o-mode, done.\n");    
    }
    return 0;
}

# converts map content into fs-like structure, stores resulting data in self->{fsdata}
# this conversion of the whole map into an fs-like tree happens because:
# . repeating tm->match calls is prohibitively expensive (regardless of tm indices)
# . we need to keep track of assocs anyway, as they are not externally addressable
# . the collection of topic/assoc data needs to be done for every lookup

# datastructure: /topics/tn/thingie/whatever => hashref or arrayref
# hashref: this is a dir, hash: files as keys
# arrayref: this is a leaf file, array: [value(ref),tmlid,stat]
# for dirs we use a dummy "." file with value = dir content arrayref.
# tmlid if a/v is name of corresponding toplet/assertion, stat is statarray
# for assocs: /assocs/atype/number/role/players, otherwise the same
sub maptofs
{
    my ($self)=@_;
    Carp::croak("invalid object argument\n") if (!ref($self) || !$self->isa(__PACKAGE__));

    my $tm=$self->{tm};
    my %d;
    $self->{fsdata}=\%d;	# needs to be set before using the mk* methods
    
    if ($self->{hide})		# determine what to hide
    {
	for ($tm->toplets(\ '+infrastructure'),$tm->asserts(\ '+infrastructure'))
	{
	    $self->{infrastuff}->{$_->[TM->LID]}=1;
	}
    }

    # first pass: collect all the topicy things
    # this makes topics and their fs locations known for later stages
    for my $m ($tm->toplets)
    {
	my ($t,$sloc,$sin)=@{$m};
	my $n=$self->lid2name($t);
	$d{$td}->{$n}=$self->mktopichier($m); # does not cover slocs and dirs are semi-blank
    }
    # first pass over the assertions
    for my $m ($tm->asserts)
    {
	$self->mkasshier(undef,0,$m);
    }
    # second pass: fixup directory modes
    # fixup subject locators
    # make content for instances and isas files
    my @cand=(\%d);
    while (my $e=pop @cand)
    {
	if (ref($e) eq "HASH")	# a dir, look at its contents and update the "." entry with them
	{
	    # topic? run topic fixerupper
	    # other stuff: just scan the dirs
	    if ($e->{"~"})	# only present with topics
	    {
		$self->fixuptopic($e);
	    }
	    else
	    {
		push @cand,values %$e; # check recursively
		$self->scandir($e);
	    }
	}
    }
    return \%d;
}

# scans dir contents non-recursively, updates dir node with content listing
sub scandir
{
    my ($self,$dirn)=@_;
    Carp::croak("invalid object argument\n") if (!ref($self) || !$self->isa(__PACKAGE__));
    
    # dir mode for blank dirs (ie. no subdirs)
    my @dirmode=(0,1,S_IFDIR|S_IRUSR|S_IXUSR|S_IRGRP|S_IXGRP|S_IROTH|S_IXOTH,2,
		 0,0,0,0,$self->{mtime},$self->{mtime},$self->{mtime},0,0);
    $dirmode[2]|=S_IWUSR if ($self->{rw});

    my $dircontent=[];
    push @$dircontent,"." if (!$dirn->{"."});
    push @$dircontent,"..",sort keys %$dirn;
    my @mode=@dirmode;
    $mode[3]+=(grep(ref($dirn->{$_}) eq "HASH", keys %$dirn)); # number of subdirs
    $dirn->{"."}=[$dircontent,$dirn->{"."}->[1],\@mode];
    return $dirn;
}

# creates topic dir hierarchy for a given existing toplet
# does NOT cover assertions of any kind, leaves directory entries blank, slocs are unresolved plain
# returns said hierarchy. needs to be followed up by fixuptopic after matching assertions are covered
sub mktopichier
{
    my ($self,$toplet)=@_;
    Carp::croak("invalid object argument\n") if (!ref($self) || !$self->isa(__PACKAGE__));
    Carp::croak ("invalid argument ".Dumper($toplet)) if (ref($toplet) ne "ARRAY" || @$toplet!=3);

    # subdirs present in every topic dir
    my @dirkeys=qw(isa instance oc name involved);
    # files present in every topic dir
    # note: ~, = handled dynamically
    my @filekeys=qw(isas instances);

    my ($t,$sloc,$sin)=@{$toplet};
    my $tnode={"."=>[undef,$t,undef]};

    # general priming
    map { $tnode->{$_}=$self->makefilenode(undef,$t) } (@filekeys);
    map { $tnode->{$_}={"."=>[undef,$t,undef]} } (@dirkeys);

    # subject indicators
    $tnode->{"~"}=$self->makefilenode((@$sin?join("\n",(@$sin,undef)):undef),$t);
    # subject locator is stored as plain file, for now
    $tnode->{"="}=$self->makefilenode($sloc,$t) if ($sloc);

    return $tnode;
}

# resolves slocs, does instances/isas, involved assocs scans relevant directories
# operates on self->{fsdata}
sub fixuptopic
{
    my ($self,$tnode)=@_;
    Carp::croak("invalid object argument\n") if (!ref($self) || !$self->isa(__PACKAGE__));
    Carp::croak ("invalid argument ".Dumper($tnode)) if (!$tnode || ref($tnode) ne "HASH");

    my $lid=$tnode->{"."}->[1];	# id is always present

    # does this contain an sloc we need to resolve?
    if ($tnode->{"="} && S_ISREG($tnode->{"="}->[2]->[2])) # only unresolved slocs are regular files
    {
	my $link=$tnode->{"="}->[0];

	# if it's local: make it a working symlink
	# alid2path remembers assertions
	my $target=$self->{alid2path}->{$link};
	undef $target if ref($target); # isa/instance are represented in two locs 

	my $deboned=$self->unbase($link);
	$target="/$td/$deboned" if (!$target && $self->{fsdata}->{$td}->{$deboned});
	
	$tnode->{"="}=$self->makelinknode(($target?"../..$target":$link),$lid);
    }
    
    # gen list of instances/isas
    for my $comp qw(instance isa)
    {
	my $tcomp=$comp."s";
	my @things=sort(grep($_ ne ".", keys %{$tnode->{$comp}}));
	$tnode->{$tcomp}=$self->makefilenode(join("\n",@things,undef),$lid) if (@things);
    }
    
    # now scan relevant dirs
    for my $k (qw(isa instance oc name involved))
    {
	$self->scandir($tnode->{$k});
    }
    $self->scandir($tnode);
    return $tnode;
}	   
   
sub makelinknode
{
    my ($self,$target,$lid)=@_;
    Carp::croak("invalid object argument\n") if (!ref($self) || !$self->isa(__PACKAGE__));
    Carp::croak ("invalid arguments ".Dumper(\$target,\$lid)) if (!$target || !$lid);

    # link: size must reference actual link target text
    my @linkmode=(0,1,S_IFLNK|S_IRWXU|S_IRWXG|S_IRWXO,1,
		  0,0,0,0,$self->{mtime},$self->{mtime},$self->{mtime},0,0);

    $linkmode[7]=length($target);
    return [$target,$lid,\@linkmode];
}

sub makefilenode
{
    my ($self,$content,$lid)=@_;
    Carp::croak("invalid object argument\n") if (!ref($self) || !$self->isa(__PACKAGE__));
    Carp::croak ("invalid lid argument $lid") if (!$lid);

    # file mode: must be fixed with actual size info!
    my @filemode=(0,1,S_IFREG|S_IRUSR|S_IRGRP|S_IROTH,1,
		  0,0,0,0,$self->{mtime},$self->{mtime},$self->{mtime},0,0);
    $filemode[2]|=S_IWUSR if ($self->{rw});
    $filemode[7]=length($content);
    return [$content,$lid,\@filemode];
}

# creates named (blank) topic, sets it up in the map and builds relevant fsdata structures
# optionally adds subject address and/or subject indicators.
# note: neither sloc nor sins can be removed via TM.
sub maketopic
{
    my ($self,$tn,$sloc,$sins)=@_;
    Carp::croak("invalid object argument\n") if (!ref($self) || !$self->isa(__PACKAGE__));
    Carp::croak ("invalid topic argument $tn") if (!$tn);

    $tn=$self->unbase($tn); 		# for convenience in updating sins/slocs
    my $tm=$self->{tm};

    my $lid=$tm->internalize(($tm->baseuri.$tn)=>$sloc);
    my @sin; @sin=@$sins if $sins;
    for my $s (@sin)
    {
	$tm->internalize($lid=>\ "$s");
    } 
    my $toplet=$tm->toplet($lid);

    my $tnode=$self->mktopichier($toplet);
    $self->fixuptopic($tnode);

    $self->{fsdata}->{$td}->{$tn}=$tnode;
    $self->scandir($self->{fsdata}->{$td});
    $self->{dirty}->{$tnode}=0;
}

# creates fsdata hierarchy for the given assertion
# attaches this in the appropriate spot(s) in fsdata (as given)

# this is necessary because the caller won't know where this ass is supposed to go,
# and because the ass may be reflected in multiple spots (isa!).

# if a name is given, that name is used for attaching where possible
# updates all relevant dirs, returns nothing.
sub mkasshier
{
    my ($self,$name,$isdirty,$m)=@_;
    Carp::croak("invalid object argument\n") if (!ref($self) || !$self->isa(__PACKAGE__));
    Carp::croak("invalid arguments ".Dumper(\$name,\$isdirty,$m)) if (ref($m) ne "Assertion");
    my $tm=$self->{tm};

    my ($kind,$type,$scope,$lid)=($self->unbase(@{$m}[TM->KIND,TM->TYPE,TM->SCOPE]),$m->[TM->LID]);
    my $rawtype=$m->[TM->TYPE];
    my $d=$self->{fsdata};
    if ($kind==TM->ASSOC)
    {
	# class-instance: ignore name, attach to involved topics - but only if not reified!
	# if reified, we need to create an explicit assoc dir to represent the reificiation
	if ($type eq "isa" && !$tm->is_reified($lid))	
	{
	    my ($p,$c,$raw);
	    $raw=($tm->get_x_players($m,"class"))[0];
	    $p=$self->lid2name($raw);
    
	    $raw=($tm->get_x_players($m,"instance"))[0];
	    $c=$self->lid2name($raw);
	    
	    $d->{$td}->{$p}->{"instance"}->{$c}=$self->makelinknode("../../$c",$lid);
	    $self->{dirty}->{$d->{$td}->{$p}}=0 if ($isdirty);
	    $self->scandir($d->{$td}->{$p}->{"instance"});
	    $d->{$td}->{$c}->{"isa"}->{$p}=$self->makelinknode("../../$p",$lid);
	    $self->{dirty}->{$d->{$td}->{$c}}=0 if ($isdirty);
	    $self->scandir($d->{$td}->{$c}->{"isa"});

	    $self->{alid2path}->{$lid}=["/$td/$p/instance/$c","/$td/$c/isa/$p"];
	}
	else	# general assoc, attach in assoc area with given tag name (or next free tag)
	{
	    my $istype=$self->lid2name($rawtype);

	    my $tag=defined $name?$name:nextfreetag($d->{$ad}->{$type});

	    my $an= $d->{$ad}->{$type}->{$tag} || {"."=>[undef,$lid,undef]};
	    $d->{$ad}->{$type}->{$tag} ||= $an;
	    $d->{$ad}->{$type}->{"."}||=[undef,$rawtype,undef];

	    $an->{".type"}=$self->makelinknode("../../../$td/$istype",$rawtype); # .type has topic id

	    # also attach to involved and to type-topic
	    my $itag=nextfreetag($d->{$td}->{$istype}->{"involved"}).":type";
  	    my $thisasslink=$self->makelinknode("../../../$ad/$type/$tag",$lid);
	    $d->{$td}->{$istype}->{"involved"}->{$itag}=$thisasslink;

	    # need to handle newly created, blank assocs cleanly: fallback ()
	    # get_role_s doesn't return unique roles :-((
	    my %messyroles;
	    for my $role ($tm->get_role_s($m)?@{$tm->get_role_s($m)}:())
	    {

		next if ($messyroles{$role});
		$messyroles{$role}=1;

		my $short=$self->unbase($role);
		$an->{$short}={"."=>[undef,$role,undef]};

		my $ishort=$self->lid2name($role);
		my $rtag=nextfreetag($d->{$td}->{$ishort}->{"involved"}).":role";
		$d->{$td}->{$ishort}->{"involved"}->{$rtag}=$thisasslink;

		for ($tm->get_x_players($m,$role))
		{
		    my $player=$self->unbase($_);
		    my $target=$self->lid2name($_);
		    $an->{$short}->{$player}=$self->makelinknode("../../../../$td/$target",$_);
		    
		    my $ptag=nextfreetag($d->{$td}->{$target}->{"involved"}).":player";
		    $d->{$td}->{$target}->{"involved"}->{$ptag}=$thisasslink;
		    $self->scandir($d->{$td}->{$target}->{"involved"});
		}
		$self->scandir($an->{$short});
	    }
	    $self->scandir($an);
	    $self->scandir($d->{$td}->{$istype}->{"involved"});
	    $self->scandir($d->{$ad}->{$type});
	    $self->{alid2path}->{$lid}="/$ad/$type/$tag";
	    $self->{dirty}->{$an}=0 if ($isdirty);
	}
    }
    elsif ($kind==TM->NAME || $kind==TM->OCC)
    {
	my $key=($kind==TM->NAME?"name":"oc");
	my $tname=$self->unbase(($tm->get_x_players($m,"thing"))[0]);
	    
	my $fn=$name;
	if (!defined $name)	# invent appropriate tag
	{
	    $fn=nextfreetag($d->{$td}->{$tname}->{$key});
	    my $deftype=$key eq "oc"?"occurrence":"name";
	    $fn.=":$type" if ($type && $type ne $deftype);
	    $fn.="\@$scope" if ($scope && $scope ne "us");
	}
	$self->{alid2path}->{$lid}="/$td/$tname/$key/$fn";
	
	my $r=($tm->get_x_players($m,"value"))[0]->[0];
	$r.="\n" if ($r && $r!~/\n$/); #  fs objects get trailing newline, tm stays clean of that
	$d->{$td}->{$tname}->{$key}->{$fn}=$self->makefilenode($r,$lid);
	$self->scandir($d->{$td}->{$tname}->{$key});
	$self->{dirty}->{$d->{$td}->{$tname}}=0 if ($isdirty);
    }
}

# returns the next free tag for this dir node
sub nextfreetag
{
    my ($node)=@_;
    my $r=1;
    
    return $r if (!$node);
    while (grep($_ =~ /^$r($|\D)/, keys %{$node})) { $r++; };
    return $r;
}

# verifies a path being correct, returns stat-array of thing, 
# or content/getdir if asked for
# returns (status,..stuff) with zero-status good
sub retrieve
{
    my ($self,$file,$wantcontent)=@_;
    Carp::croak("invalid object argument\n") if (!ref($self) || !$self->isa(__PACKAGE__));

    my ($found,$obj)=$self->lookup($file);
    return -ENOENT() if (!$found);

    # obj should point to dir (=hash) or file (=array)
    if (ref($obj) eq "HASH")
    {
	# get dir listing, contained in pseudo-file "."
	my $aref=$obj->{"."}->[$wantcontent?0:2];
	&Carp::croak("object unretrievable: ".Dumper($obj)) 
	    if (ref($aref) ne "ARRAY");
	return (0,@$aref);
      }
    elsif (ref($obj) eq "ARRAY")
    {
	return (0,$wantcontent?$obj->[0]:@{$obj->[2]})
    }
    else
    {
	Carp::croak("dud object pointer ".Dumper($obj));
    }
}

# find an existing file node, return its reference and the parent container node
# returns 0,undef if no object can be found.
sub lookup
{
    my ($self,$file)=@_;
    Carp::croak("invalid object argument\n") if (!ref($self) || !$self->isa(__PACKAGE__));
    
    my @pathcomps=split(m!/!,$file);
    shift @pathcomps;			# file paths are absolute
    my $obj=$self->{fsdata};
    my @nodes=($obj);

    while (defined(my $next=shift @pathcomps))
    {
	return 0 if (!$obj->{$next});
	$obj=$obj->{$next};
	unshift @nodes,$obj;
    }
    return (1,@nodes[0..1]);
}

# checks xml/topic naming constraints
# returns 1 if fine, undef otherwise.
sub validname
{
    my ($n)=@_;

    return 1 if ($n=~/^[a-z_:][0-9a-z_.:-]*$/i);
    return undef;
}

# take oc/bn, decomposes into components, checks for validity
# autocreates nonex scope/type topics if allowed to
# returns status, 1 is ok; and name components. does not return default scope or type!
sub split_and_complete
{
    my ($self,$fn)=@_;
    Carp::croak("invalid object argument\n") if (!ref($self) || !$self->isa(__PACKAGE__));
    
    my ($tag,$type,$scope);
    
    $fn=~s/(\@([^:@]+))// && ($scope=$2);
    $fn=~s/(:([^:@]+))// && ($type=$2);
    $tag=$fn if ($fn=~/^\d+$/);

    return 0 if (!defined($tag));
    for my $ac (\$type,\$scope)
    {
	next if (!$$ac || $self->{fsdata}->{$td}->{$$ac});
	return 0 if (!$self->{autocreate} || !validname($$ac));
	$self->maketopic($$ac);
    }
    return (1,$tag,$type,$scope);
}

# returns absolute, cleaned path. 
# necessary because file::spec::rel2abs doesn't deal with ../ and cwd::realpath 
# traverses the fs, forcing us into deadlock.
sub cleanpath
{
    my ($target)=@_;
    # damn rel2abs does NOT collapse x/../, but at least cleans ./ and /// and so on...sigh.
    # and cwd::realpath locks us up because it actually traverses the filesystem.
    my @dc=split(m!/!,$target);
    for (my $i=0;$i<$#dc;)
    {
	if ($dc[$i+1] eq "..")
	{
	    splice(@dc,$i,2);
	    --$i;
	}
	else
	{
	    ++$i;
	}
    }
    return join("/",@dc);
}

# renames or removes a topic from the map, cleaning up all the mess left behind.
# returns undef if impossible to remove (topic is used as assoc type or assoc role), 1 if fine.
# input are topic names. removes if no new name given. new name mustn't pre-exist
# and a topic for it will be created and inserted in the relevant places.
sub remove_rename
{
    my ($self,$rip,$revenant)=@_;
    Carp::croak("invalid object argument\n") if (!ref($self) || !$self->isa(__PACKAGE__));
    my $tm=$self->{tm};

    return 1 if ($rip && $rip eq $revenant); # pathological case...
    # fail on pre-existing new topic or non-existent old
    return undef if ($self->{fsdata}->{$td}->{$revenant} 
		     || !$self->{fsdata}->{$td}->{$rip} || $revenant && !validname($revenant));
    
    my $lid=$self->{fsdata}->{$td}->{$rip}->{"."}->[1];
    Carp::croak("internal inconsistency: topic $rip has no topic id\n") if (!$lid);

    # for removals: we need to keep the map consistent, so this topic's traces must go, everywhere
    # used as scope: change to us
    # as occ/name type: change to appropriate default
    # as instance/class: remove
    # as player in assoc: remove
    # as role or assoc type: REFUSE the removal, because there's no sensible automatic way to fix this

    if (!$revenant) 
    {
	return undef if ($self->{fsdata}->{$ad}->{$rip} && keys %{$self->{fsdata}->{$ad}->{$rip}}); # assoc type or role
	for my $type (grep($_ ne ".", keys %{$self->{fsdata}->{$ad}}))
	{
	    for my $tag (grep($_ ne ".", keys %{$self->{fsdata}->{$ad}->{$type}}))
	    {
		return undef if $self->{fsdata}->{$ad}->{$type}->{$tag}->{$rip};
	    }
	}
    }
    else
    {
	my $oldtop=$tm->toplet($lid);
	$self->maketopic($revenant,$oldtop->[TM->ADDRESS],$oldtop->[TM->INDICATORS]);
    }

    my @involved;
    for my $a ($tm->match(TM->FORALL,anyid=>$lid))
    {
	my $who=$self->{alid2path}->{$a->[TM->LID]};
	Carp::croak("internal inconsistency: assertion $a->[TM->LID] without fs object\n") if (!$who);
	push @involved,ref($who)?@{$who}:$who; # isa/instance represented in two places
    }

    for my $p (@involved)
    {
	my ($found,$obj,$parent)=$self->lookup($p);
	next if (!$found);	# isas/instances are dual, removing one does the other
	
	# what is the type of involvement?
	my @pc=reverse(split(m!/!,$p)); pop @pc;
	if (@pc==4 && $pc[-1] eq $td)
	{
	    # "direct", ie. topic is player, or oc/name of topic: remove the path
	    if ($pc[-2] eq $rip)
	    {
		return undef if ($self->tm_unlink($p));
	    }
	    # not "ours", but topic is scope or type of assertion? rename that, then.
	    elsif (grep($_ eq $pc[-3],qw(oc name)))
	    {
		my ($status,$tag,$type,$scope)=$self->split_and_complete($pc[0]);
		my $newname=join("/",undef,@pc[-1,-2,-3],undef).$tag;
		
		# new topic? bring it in where appropriate
		$type=$revenant if ($revenant && $type eq $rip);
		$scope=$revenant if ($revenant && $scope eq $rip);
		
		$newname.=":$type" if ($type && $type ne $rip);
		$newname.="\@$scope" if ($scope && $scope ne $rip);

		return undef if ($self->tm_rename($p,$newname));
	    }
	    # note: the dual instance/isa is not explicitely handled
	}
	elsif (@pc==3 && $pc[-1] eq $ad)
	{
	    my $anode=$self->{fsdata}->{$ad}->{$pc[-2]}->{$pc[-3]};
	    for my $role (grep($_ !~ /^\./, keys %{$anode}))
	    {
		if ($anode->{$role}->{$rip})
		{
		    return undef if ($self->tm_unlink("$p/$role/$rip"));
		    return undef if ($revenant && $self->tm_symlink("../../../../$td/$revenant","$p/$role/$revenant"));
		}
	    }
	}
    }

    # update or get rid of reification (X reifies removed/renamed topic)
    for my $t (grep($_->[TM->ADDRESS] eq $lid,($tm->toplets)))
    {
	my $loc="/$td/".$self->unbase($t->[TM->LID])."/=";
	return undef if ($self->tm_unlink($loc));
	return undef if ($revenant && $self->tm_symlink("../$revenant",$loc));
    }
    $self->{dirty}->{$lid}=0;	# key is not relevant 

    # finally remove the topic and its fsdata entries
    # note: sloc and sin objects belonging to rip vanish automatically
    $tm->externalize($lid);
    delete $self->{fsdata}->{$td}->{$rip};
    $self->scandir($self->{fsdata}->{$td});
    return 1;
}

sub debug
{
    my ($self,@in)=@_;
    Carp::croak("invalid object argument\n") if (!ref($self) || !$self->isa(__PACKAGE__));

    return if (!$self->{debug});
    push @in,"\n" if ($in[-1]!~/\n$/);
    print STDERR scalar(localtime)," ",@in;
}


# apply infrastructure and baseuri heuristic
# to create suitable topic name from lid
sub lid2name
{
    my ($self,$lid)=@_;
    Carp::croak("invalid object argument\n") if (!ref($self) || !$self->isa(__PACKAGE__));

    return  ($self->{infrastuff}->{$lid}?".":"").$self->unbase($lid);
}

# nuke tm baseuri
sub unbase
{
    my ($self,@in)=@_;
    Carp::croak("invalid object argument\n") if (!ref($self) || !$self->isa(__PACKAGE__));

    my $base=$self->{tm}->baseuri;
    map { s/^$base//; } (@in);
    return (wantarray?@in:$in[0]);
}

sub tm_getattr 
{
    my ($self,$file) = @_;
    Carp::croak("invalid object argument\n") if (!ref($self) || !$self->isa(__PACKAGE__));
    my (@list,$errcode);

    $self->debug("getattr on $file\n");    
    ($errcode,@list)=$self->retrieve($file,0);
    $self->debug( "returning errorcode $errcode\n");
    return ($errcode) if ($errcode);
    return @list;
}

sub tm_getdir 
{
    my ($self,$file)=@_;
    Carp::croak("invalid object argument\n") if (!ref($self) || !$self->isa(__PACKAGE__));
    my (@list,$errcode);

    $self->debug( "getdir on $file\n");    
    ($errcode,@list)=$self->retrieve($file,1);
    $self->debug( "returning: ".join(" ",@list)." and error code $errcode\n");
    return (@list,$errcode);
}

sub tm_readlink
{
    my ($self,$file)=@_;
    Carp::croak("invalid object argument\n") if (!ref($self) || !$self->isa(__PACKAGE__));
    my ($content,$errcode);

    $self->debug("readlink on $file\n");    
    ($errcode,$content)=$self->retrieve($file,1);
    $self->debug( "returns code $errcode result $content\n");
    return $errcode||$content;
}    
    
# return an error numeric, or binary/text string.  (note: 0 means EOF, "0" will
# give a byte (ascii "0") to the reading program)
sub tm_read
{
    my ($self,$file,$buf,$off)=@_;
    Carp::croak("invalid object argument\n") if (!ref($self) || !$self->isa(__PACKAGE__));
    my ($content,$errcode);

    $self->debug("reading $file offset $off\n");    
    ($errcode,$content)=$self->retrieve($file,1);
    return $errcode if ($errcode);
    return -EINVAL() if ($off>length($content));
    return 0 if $off == length($content);
    return substr($content,$off,$buf);
}

# overwrite the contents of a file
# works only for existing files, and not all of them.
sub tm_write
{
    my ($self,$file,$buf,$off)=@_;
    Carp::croak("invalid object argument\n") if (!ref($self) || !$self->isa(__PACKAGE__));

    $self->debug("writing to $file at $off");
    
    # find the thing
    my ($found,$obj)=$self->lookup($file);
    return -ENOENT() if (!$found);
    return -EINVAL() if (ref($obj) ne "ARRAY" 	# dirs are hashes
			 || !S_ISREG($obj->[2]->[2])); 

    # isas and instances: are read-only
    return -EPERM() if ($file=~m!/(isas|instances)$!);

    # leaves us: subj indicators ~, names and occurrences
    my $current=$obj->[0];
    my ($before,$after);
    $before=substr($current,0,$off) if ($off>0);
    $after=substr($current,$off+length($buf)) if ($off+length($buf)<length($current));
    
    $obj->[0]=$before.$buf.$after;
    $obj->[2]->[7]=length($obj->[0]);
    $self->{dirty}->{$obj}=1;
    return length($buf);
}

# called on (devices and) regular files only, for us that's names/ocs, sins.
sub tm_mknod
{
    my ($self,$file,$mode,$dev)=@_;
    Carp::croak("invalid object argument\n") if (!ref($self) || !$self->isa(__PACKAGE__));
    $self->debug("mknod on $file, mode $mode dev $dev");

    my $tm=$self->{tm};

    # suitable type? we make regular files only.
    return -EPERM() if (!S_ISREG($mode) || $dev);

    # only creatable files: name and oc nodes, others auto-instantiated
    my ($alreadythere)=$self->lookup($file);
    return -EEXIST() if $alreadythere;
    
    my ($localname,@rest)=reverse(split(m!/!,$file));
    pop @rest;			# was abs path starting at mountpoint
    
    if (@rest==3 && $rest[2] eq $td && $self->{fsdata}->{$td}->{$rest[1]} && $rest[0]=~/^(oc|name)$/)
    {
	my ($status,$tag,$type,$scope)=$self->split_and_complete($localname);
	return -EFAULT() if (!$status);
	my $kind=$rest[0] eq "oc"?TM->OCC:TM->NAME;
	$type||=($kind eq TM->OCC?"occurrence":"name");
	$scope||="us";
	
	# now make the assertion
	my ($okass)=$tm->assert(Assertion->new(kind=>$kind,
				type=>$self->{fsdata}->{$td}->{$type}->{'.'}->[1],
				scope=>$self->{fsdata}->{$td}->{$scope}->{'.'}->[1],
				roles=>['thing','value'],
				players=>[ $self->{fsdata}->{$td}->{$rest[1]}->{'.'}->[1], 
					   TM::Literal->new("","xsd:string")])); 
	$self->mkasshier($localname,1,$okass);
	return 0;
    }
    return -EPERM();
}
    
# cut off a file's content, marks it as dirty
sub tm_truncate
{
    my ($self,$file,$length)=@_;
    Carp::croak("invalid object argument\n") if (!ref($self) || !$self->isa(__PACKAGE__));

    # find the thing
    my ($found,$obj)=$self->lookup($file);
    return -ENOENT() if (!$found);
    return -EINVAL() if (ref($obj) ne "ARRAY" 	# dirs are hashes
			 || !S_ISREG($obj->[2]->[2]));

    # isas and instances: are read-only
    return -EPERM() if ($file=~m!/(isas|instances)$!);

    # leaves us: subj indicators ~, names and occurrences
    my $current=$obj->[0];
    my $curlen=length($current);
    my $tmobj=$obj->[1];
    
    $self->debug("truncating $file at offset $length");
    $self->{dirty}->{$obj}=1;

    if ($length<$curlen)
    {
	$current=substr($current,0,$length);
    }
    elsif ($length>$curlen)
    {
	$current.="\0" x ($length-$curlen);
    }
    $obj->[0]=$current;
    $obj->[2]->[7]=$length;
    return 0;
}

# saves dirty file objects back into the topicmap, updates relevant stat buffer(s)
# applies primarily to ~, names and occurrences (everything else are links, dirs and filenames)
# minor problem: cannot return errors (would have to use flush for that)
sub tm_release
{
    my ($self,$file)=@_;
    Carp::croak("invalid object argument\n") if (!ref($self) || !$self->isa(__PACKAGE__));
    my $tm=$self->{tm};
    
    $self->debug("releasing $file");    
    my ($found,$obj)=$self->lookup($file);
    Carp::croak("release on nonexistent file $file!\n") if (!$found);

    if ($obj && $self->{dirty}->{$obj})
    {
	# a subject indicator?
	if ($file=~m!/~$!)
	{
	    my $t=$tm->toplet($obj->[1]);
	    $t->[TM->INDICATORS]=[split(/\n/,$obj->[0])];
	}
	# or a name/occurrence?
	else
	{
	    my $a=$tm->retrieve($obj->[1]);
	    my $content=$obj->[0]; # mapcontent without trailing newlines, please
	    chomp $content;

	    my $flavour="xsd:string";
	    $flavour="xsd:uri" 
		if ($a->[TM->KIND] eq TM->OCC && $content =~ m!^[a-zA-Z]+:.+$!i);
	    $a->[TM->PLAYERS]->[1]=TM::Literal->new($content,$flavour);
	}
	$self->{dirty}->{$obj}=0;
	$obj->[2]->[7]=length($obj->[0]);
    }
    return 0;
}

# works on: names and ocs, but only when things stay with the same topic,
# topic dirs
sub tm_rename
{
    my ($self,$old,$new)=@_;
    Carp::croak("invalid object argument\n") if (!ref($self) || !$self->isa(__PACKAGE__));
    $self->debug("rename $old to $new\n");
    my $tm=$self->{tm};

    my ($found,$oo,$parent)=$self->lookup($old);
    my ($newfound,$newo,$newparent)=$self->lookup($new);
    return -ENOENT() if (!$found);
    if (ref($oo) eq "ARRAY")	# files: ~, oc, names, or links: =, instances, players etc.
    {
	return -EFAULT() if ($old=~m!/~$!  # sins stay sins
			     || S_ISLNK($oo->[2]->[2]) # link renaming is no good idea either
			     || (dirname($new) ne dirname($old))); # no moving of names/ocs across topics.

	#  is the requested new name acceptable?
	my $localname=basename($new);
	my ($status,$tag,$type,$scope)=$self->split_and_complete($localname);
	return -ENOENT() if (!$status);
	
	# find object at the new name; scope and type are already guaranteed to exist
	if ($newfound)
	{
	    # make room, remove the new object from both map and fsdata
	    $tm->retract($newo->[1]);
	    # it is highly unlikely that somebody managed to cook up an assoc reifier for this
	    # oc/name assertion but BSTS
	    for my $t (grep($_->[TM->ADDRESS] eq $newo->[1],($tm->toplets)))
	    {
		return undef if ($self->tm_unlink("/$td/".$self->unbase($t->[TM->LID])."/="));
	    }
	    delete $newparent->{$localname};
	}

	# update name/oc in the map and rename it in fsdata
	my $ass=$tm->retrieve($oo->[1]);
	$scope||="us";
	$type||=($ass->[TM->KIND] eq TM->OCC?"occurrence":"name");

	$ass->[TM->SCOPE]=$self->{fsdata}->{$td}->{$scope}->{"."}->[1];
	$ass->[TM->TYPE]=$self->{fsdata}->{$td}->{$type}->{"."}->[1];

	$parent->{$localname}=$oo;
	delete $parent->{basename($old)};
	$self->scandir($parent);
	$self->{dirty}->{$oo}=0;

	return 0;
    }
    else			# dirs
    {
	my @oldp=reverse(split(m!/!,$old)); pop @oldp;
	my @newp=reverse(split(m!/!,$new)); pop @newp;
	return -EFAULT() if (@oldp!=2 || @newp!=2 
			     || $oldp[-1] ne $td || $newp[-1] ne $td);
	return -EPERM() if (!validname($newp[0]));
	return ($self->remove_rename($oldp[0],$newp[0])?0:-EBUSY());
    }
    return -EPERM();
}

sub tm_mkdir
{
    my ($self,$file,$mode)=@_;
    Carp::croak("invalid object argument\n") if (!ref($self) || !$self->isa(__PACKAGE__));
    my $tm=$self->{tm};

    $self->debug("mkdir $file mode $mode");

    my ($found)=$self->lookup($file);
    return -EEXIST() if ($found);

    # where are we?
    my ($n,@rest)=reverse(split(m!/!,$file));
    pop @rest;


    # in topics list: fine, make said topic
    if (@rest==1 && $rest[0] eq $td)
    {
	return -EFAULT() if (!validname($n));
	$self->maketopic($n);
	return 0;
    }
    # new assoc-type dir
    elsif (@rest==1 && $rest[-1] eq $ad)
    {
	if (!$self->{fsdata}->{$td}->{$n})
	{
	    return -ENOENT() if (!$self->{autocreate} || !validname($n));
	    $self->maketopic($n);
	}

	$self->{fsdata}->{$ad}->{$n}=
	{"."=>[undef,$self->{fsdata}->{$td}->{$n}->{"."}->[1],undef]};
	$self->scandir($self->{fsdata}->{$ad}->{$n});
	$self->scandir($self->{fsdata}->{$ad});
	return 0;
    }
    # new assoc tagdir
    elsif (@rest==2 && $rest[-1] eq $ad)
    {
	my $type=$rest[0];
	if ($type && $self->{fsdata}->{$ad}->{$type})
	{
	    return -EFAULT() if ($n!~/^\d+$/);
	    
	    # make new semiblank assertion
	    # kind, type-lid, no roles or players
	    my ($okass)=$tm->assert(Assertion->new(kind=>TM->ASSOC,
				    type=>$self->{fsdata}->{$td}->{$type}->{"."}->[1]));
	    $self->mkasshier($n,1,$okass);
	    return 0;
	}
	return -ENOENT();
    }
    # new role dir, /a/type/tag/new role 
    elsif  (@rest==3 && $rest[-1] eq $ad)
    {
	my ($tag,$type)=@rest[0..1];
	if ($type && $self->{fsdata}->{$ad}->{$type} && defined($tag) 
	    && $self->{fsdata}->{$ad}->{$type}->{$tag} && defined $n)
	{
	    # roletopic exists? 
	    if (!$self->{fsdata}->{$td}->{$n})
	    {
		return -ENOENT() if (!$self->{autocreate} || !validname($n)); # no autocreation
		$self->maketopic($n);
	    }
	    # create dummy role dir, assoc changes happen on player symlink
	    $self->{fsdata}->{$ad}->{$type}->{$tag}->{$n}=
	    {"."=>[undef,$self->{fsdata}->{$td}->{$n}->{"."}->[1],undef]}; 
	    $self->scandir($self->{fsdata}->{$ad}->{$type}->{$tag}->{$n});
	    $self->scandir($self->{fsdata}->{$ad}->{$type}->{$tag});
	    return 0;
	}
	return -ENOENT();
    }		    
    return -EPERM();		# not a spot where dirs can be made, sorry.
}

# newpath is given rel to our moutpoint and cleaned, oldpath is verbatim
sub tm_symlink
{
    my ($self,$target,$anchor)=@_;
    Carp::croak("invalid object argument\n") if (!ref($self) || !$self->isa(__PACKAGE__));
    my $tm=$self->{tm};

    $self->debug("symlink from $anchor to $target");
    my ($aname,@arest)=reverse(split(m!/!,$anchor)); pop @arest;

    my $mountpt=$self->{mountpoint};
    # first check/mangle the target, which is given verbatim...
    my $cleantarget=cleanpath(File::Spec->rel2abs($target,$mountpt.dirname($anchor))); 
    my $isuri=($target=~m!^[a-zA-Z]+:.+$!i);

    return -EFAULT() if (!$isuri && $cleantarget!~/^$mountpt/); # links can't point outside our area...    

    my $localized="/".File::Spec->abs2rel($cleantarget,$mountpt);
    my ($targetfound,$tobj)=$self->lookup($localized);
    my ($tname,@trest)=reverse(split(m!/!,$localized)); pop @trest;

    return -ENOENT() if (!$isuri && !$targetfound); # the link may point to topic/assoc or an uri only

    # topic-symlinks must have matching names for source and target
    return -EPERM() if ($aname ne "=" && $tname ne $aname);

    # the anchor mustn't pre-exist
    return -EEXIST() if (($self->lookup($anchor))[0]);

    # depending on where the anchor is, different targets are allowed
    # anchor =, sloc: only url or local topic or local assoc
    if ($aname eq "=" && @arest==2 && $arest[1] eq $td)
    {
	my $tnode=$self->{fsdata}->{$td}->{$arest[0]};
	return -ENOENT() if (!$tnode);
	my $lid=$tnode->{"."}->[1];

	# subject address can be uri, topic or assoc
	if (!$isuri)
	{
	    # is the target an assoc dir or a topic dir?
	    return -ENOENT() if (($trest[-1] eq $td && @trest!=1)
				 || ($trest[-1] eq $ad && @trest!=2));
	    $target=$tobj->{"."}->[1]; # actual topic/assoc lid
	}

	my $toplet=$tm->toplet($lid);
	$toplet->[TM->ADDRESS]=$target;
	$tnode->{"="}=$self->makefilenode($target,$lid);
	$self->fixuptopic($tnode);
	$self->{dirty}->{$tnode}=0;
	$self->debug("postlink: ".Dumper($tnode,$toplet));
	return 0;
    }
    # instance/isa: can only point to another topic
    elsif ($arest[-1] eq $td && @arest==3 && grep($arest[0] eq $_,qw(isa instance)))
    {
	# must point to topic, not to a url and not an assoc either
	return -EPERM() if ($isuri || $trest[-1] ne $td);

	my $atnode=$self->{fsdata}->{$td}->{$arest[1]}; # anchor topic
	my $alid=$atnode->{"."}->[1];

	my @players=($alid,$tobj->{"."}->[1]); # where we attach to, and where we point to

	my ($nass)=$tm->assert(Assertion->new(kind=>TM->ASSOC,
					    type=>"isa",
					    scope=>"us",
					    roles=>[qw(class instance)],
					    players=>[$arest[0] eq "isa"?reverse(@players):@players]));
	$self->mkasshier(undef,1,$nass); # fstag names n/a
	$self->fixuptopic($atnode);
	return 0;
    }
    # assoc player: can only point to another topic
    elsif ($arest[-1] eq $ad && @arest==4)
    {
	my ($aplayer,$arole,$atag,$atype)=($aname,@arest);

	return -EPERM() if ($isuri || $trest[-1] ne $td);
	
	# everything up to role must exist
	return -ENOENT() if (!$self->{fsdata}->{$ad}->{$atype} 
			     || !$self->{fsdata}->{$ad}->{$atype}->{$atag}
			     || !$self->{fsdata}->{$ad}->{$atype}->{$atag}->{$arole}); 

	my $a=$tm->retrieve($self->{fsdata}->{$ad}->{$atype}->{$atag}->{"."}->[1]);

	# attach this player/role combo to this existing assertion
	# (may be blankish one created earlier)
	push @{$a->[TM->ROLES]},$self->{fsdata}->{$td}->{$arole}->{"."}->[1];
	push @{$a->[TM->PLAYERS]},$tobj->{"."}->[1];
	$self->mkasshier($atag,1,$a);
	return 0;
    }
    return -EPERM();		# can't do this, sorry.
}

sub tm_unlink
{
    my ($self,$path)=@_;
    Carp::croak("invalid object argument\n") if (!ref($self) || !$self->isa(__PACKAGE__));
    my $tm=$self->{tm};

    $self->debug("unlink $path");
    my ($found,$obj,$parent)=$self->lookup($path);
    return -ENOENT() if (!$found);
    return -EISDIR() if (ref($obj) ne "ARRAY");	# not a leaf file

    my ($localname,@rest)=reverse(split(m!/!,$path));
    pop @rest;			# path is absolute, no need to keep the undef tail

    if ($rest[-1] eq $td)
    {
	if ($localname eq "=")
	{
	    my $toplet=$tm->toplet($obj->[1]);
	    delete $toplet->[TM->ADDRESS];
	}
	elsif ($rest[0] =~ /^(oc|name)$/)
	{
	    $tm->retract($obj->[1]);
	    delete $self->{alid2path}->{$obj->[1]};
	}
	elsif ($rest[0] =~ /^(isa|instance)$/)
	{
	    # need to remove both this link as well as the opposite one...
	    my $othertype=$rest[0] eq "isa"?"instance":"isa";
	    my $tn=$rest[1];
	    delete $self->{fsdata}->{$td}->{$localname}->{$othertype}->{$tn};
	    $self->fixuptopic($self->{fsdata}->{$td}->{$localname});
	    
	    delete $self->{alid2path}->{$obj->[1]};
	    $tm->retract($obj->[1]);
	    # but dirty-marking this side is enough
	}
	else
	{
	    # fixme: lowprio: better to allow dud removals for rm -rf or not?
	    # $self->debug("not allowed to remove: $path");
	    # return -EPERM();
	    $self->debug("dummy removal of $path");
	    return 0;
	}

	# common deletion code: cleanup the fs-part of things
	delete $parent->{$localname};
	$self->fixuptopic($parent);
	$self->{dirty}->{$parent}=0;
	return 0;
    }
    elsif ($rest[-1] eq $ad)
    {
	# fixme lowprio: better to allow dud removals for rm -rf or not?
	# 	return -EPERM() if ($localname eq ".type");
	if ($localname eq ".type")
	{
	    $self->debug("dummy removal of $path");
	    return 0;
	}
	
	my $aid=$self->{fsdata}->{$ad}->{$rest[2]}->{$rest[1]}->{"."}->[1];
	my $a=$tm->retrieve($aid);
	Carp::croak("internal inconsistency: no assoc for $aid") if (!$a);

	# keep other roles and players intact
	my (@np,@nr,$pn);
	$pn=$self->{fsdata}->{$td}->{$localname}->{"."}->[1];
	for my $i (0..$#{$a->[TM->PLAYERS]})
	{
	    if ($a->[TM->PLAYERS]->[$i] eq $pn)
	    {
		# get rid of involvement links
		my $pnode=$self->{fsdata}->{$td}->{$localname};
		map { delete $pnode->{"involved"}->{$_} 
		      if (/^\d:player$/ && $pnode->{"involved"}->{$_}->[1] eq $aid); } 
		(keys %{$pnode->{"involved"}});
		$self->scandir($pnode->{"involved"});
		next;
	    }
	    unshift @np,$a->[TM->PLAYERS]->[$i];
	    unshift @nr,$a->[TM->ROLES]->[$i];
	}
	$a->[TM->PLAYERS]=\@np;
	$a->[TM->ROLES]=\@nr;
	
	delete $parent->{$localname};
	$self->scandir($parent);
	$self->{dirty}->{$parent}=0;
	return 0;
    }
    return -EPERM();
}

sub tm_rmdir
{
    my ($self,$path)=@_;
    Carp::croak("invalid object argument\n") if (!ref($self) || !$self->isa(__PACKAGE__));
    my $tm=$self->{tm};

    $self->debug("rmdir $path");
    my ($found,$obj,$parent)=$self->lookup($path);
    return -ENOENT() if (!$found);
    return -EISDIR() if (ref($obj) ne "HASH");	# not a directory

    my ($localname,@rest)=reverse(split(m!/!,$path));
    pop @rest;			# path is absolute, no need to keep the undef tail

    if ($rest[-1] eq $ad)
    {
	my $inv;
	# roledir? can be removed if empty
	if (@rest == 3)
	{
	    return -ENOTEMPTY() if (keys(%{$obj})!=1); # the . entry
	    $inv="role";
	}
	# tagdir? can be removed if empty except for .type
	elsif (@rest==2)
	{
	    return -ENOTEMPTY() if (keys(%{$obj})!=2); # ., .type
	    # removing a tagdir means removing the relevant assoc itself
	    my $a=$obj->{'.'}->[1];
	    $tm->retract($a);
	    # now check if something was reifying this assoc and clean that up
	    for my $t (grep($_->[TM->ADDRESS] eq $a,($tm->toplets)))
	    {
		return -EFAULT() if ($self->tm_unlink("/$td/".$self->unbase($t->[TM->LID])."/="));
	    }
	    $self->{dirty}->{$a}=0;	# key is not relevant 
	    $inv="type";
	}
	# typedir
	elsif (@rest==1)
	{
	    return -ENOTEMPTY() if (keys(%{$obj})!=1); # the . entry
	}
	else
	{
	    $self->debug("dud rmdir call, path $path");
	    return -EPERM(); # something bad happened 
	}
	
	# get rid of involvements, not for typedir-removal: involvements apply 
	# only to specific assocs
	if ($inv)
	{
	    my ($compare,$node);
	    if ($inv eq "type")
	    {
		$node=$self->{fsdata}->{$td}->{$self->lid2name($parent->{"."}->[1])}; # localname is assoc tag, 
		# parent (or .type child) has the type lid
		$compare=$obj->{"."}->[1];
	    }
	    else
	    {
		$node=$self->{fsdata}->{$td}->{$localname}; # localname is role, which is the topic we look for
		$compare=$parent->{"."}->[1];
	    }
	    &Carp::croak("internal inconsistency: assoc has no type name ".Dumper($obj)) 
		if (ref($node) ne "HASH");

	    map { delete $node->{"involved"}->{$_} 
		  if (/^\d:$inv$/ && $node->{"involved"}->{$_}->[1] eq $compare); } 
	    (keys %{$node->{"involved"}});
	    $self->scandir($node->{"involved"});
	}
	# common code: nuke the fs object, rescan parent dir
	delete $parent->{$localname};
	$self->scandir($parent);
	return 0;
    }
    elsif ($rest[-1] eq $td)
    {
	# fixme: lowprio: should i allow a dummy removal of the aspect dirs and files? 
	# that way, one could safely rm -rf and a stray rmdir would 
	# only topics< themselves are removable, none of their aspect-dirs
	if (@rest eq 2 && grep($localname eq $_,qw(instance isa name oc involved)))
	{
	    $self->debug("dummy rmdir of $path");
	    return 0;
	}
	return -EPERM() if (@rest!=1); 
	
	return -EBUSY() if (!$self->remove_rename($localname,undef));
	return 0;
    }
    return -EPERM();
}

# for utime, chmod, chown and other, nonimplemented but commonly used functions
sub tm_dummy
{
    my ($self)=@_;
    Carp::croak("invalid object argument\n") if (!ref($self) || !$self->isa(__PACKAGE__));

    $self->debug("dummy called with args ".Dumper(\@_)."\n");
    return 0;
}

=pod 

=head1 LIMITATIONS

=head2 Filesystem Attributes

File ownership is not modelled at all: all files and dirs belong to uid 0, root. 

Permissions are not modelled fully: in read-only mode all files are mode 0444 and
dirs 0555. In read-write mode all files are mode 0644 and dirs 0755. 

Mode or ownership changes are not supported.

=head2 Write Support

Until the filesystem is unmounted any modifications are kept in memory only.

Overwriting files is only allowed for names, occurrences and subject indicators. 
Attempts to write to other files will result in EPERM errors.

Creating new files or renaming them is only allowed for names and occurrences. 
Attempting others will result in an EPERM. Renaming works for names or occurrences
if they stay with the same topic, or for topics. Nothing else can be renamed and
EFAULT errors will result if you try.

Renaming of topics is possible (and all involved others are updated accordingly).
Neither fixed topic characteristic dirs (e.g. oc, name, isa) nor 
association instance dirs can be renamed.

(Re)Naming something with an unacceptable name will cause ENOENT errors.

Symbolic links cannot point outside the current map's filesystem, 
with the sole exception being a subject locator URI symlink.

Removing a topic is not possible if it is used as an association type
or association role: EBUSY will be the result if you try. To remove an 
association type topic first all association instances must be removed.

Removing of a topic clears up all involvements: if used as a scope the scope
will be changed to universal, if used as a type the type will be cleared, if 
used as role player then this player vanishes.

=head1 SEE ALSO

L<TM(3)>, L<tmfs(1)>

=head1 AUTHOR

Alexander Zangerl, <alphazulu@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 Alexander Zangerl

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut


1;



