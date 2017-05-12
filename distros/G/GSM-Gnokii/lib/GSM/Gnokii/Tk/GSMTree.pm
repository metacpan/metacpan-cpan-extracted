package GSM::Gnokii::Tk::GSMTree;

# Derived from DirTree.pm

use strict;
use warnings;

our $VERSION = "0.02";

use Carp;

use GSM::Gnokii;
use Tk;
use Tk::Widget;
use Tk::Derived;
use Tk::Tree;

use vars qw( @ISA );
@ISA = qw( Tk::Derived Tk::Tree );

Construct Tk::Widget "GSMTree";

use List::Util qw( first );
use Data::Peek;

my %def_conf = (
    root	=> undef,
    gsm		=> undef,
    memtype	=> "ME",
    );

sub Populate
{
    my ($w, $args) = @_;

    # print STDERR "Populate ...\n";
    my $data = $w->privateData;
    %$data = %def_conf;

    if (ref $args eq "HASH") {
	my %args = %$args;
	foreach my $arg (keys %args) {
	    (my $attr = $arg) =~ s/^-//;
	    exists $data->{$attr} and $data->{$attr} = delete $args{$arg};
	    }
	$args = { %args };
	}
    # DDumper { Data => $data, Args => $args };

    $w->SUPER::Populate ($args);
    $w->ConfigSpecs (
	-dircmd     => [qw( CALLBACK  dirCmd     DirCmd     DirCmd	)],
	-showhidden => [qw( PASSIVE   showHidden ShowHidden 0		)],
	-image      => [qw( PASSIVE   image      Image      folder	)],
	-directory  => [qw( SETMETHOD directory  Directory  .		)],
	-value      => "-directory"
	);

    $w->configure (
	-separator => "/",
	-itemtype  => "imagetext",
	);

    $data->{root} //= $w->add_to_tree ("/", $data->{memtype} // "ME");
    } # Populate

sub configure
{
    my ($w, %cnf) = @_;
    # print STDERR "configure ...\n";
    delete @cnf{map { ( $_, "-$_" ) } keys %{$w->privateData}};
    $w->SUPER::configure (%cnf);
    } # configure

my %mt = ( A => "ME", B => "SM" );
my %dt;
my %fi;

sub _cleanpath
{
    my $path = shift;
    $path =~ s{[/\\]+}{/}g;	# \\foo/bar//fse\boe => /foo/bar/fse/boe
    $path =~ s{/\.(/|$)}{/};	# /. & /./ => /
    $path =~ s{/+\*?$}{};	# /foo/ & /foo/* => /foo
    $path =~ s{^$}{/};
    $path;
    } # _cleanpath

sub DirCmd
{
    my ($w, $dir, $showhidden) = @_;
    my $pd = $w->privateData;
    my $mt = ($dir =~ s{^([AB]):}{}) ? $mt{$1} : $pd->{memtype} // "ME";
    $dir = _cleanpath ($dir);
    # print STDERR "DirCmd ($mt, $dir, 1)\n";
    my $dt;
    if ($dt{$mt}{$dir}) {
	# print STDERR "Get from cache\n";
	$dt = $dt{$mt}{$dir};
	}
    else {
	(my $gdir = $dir) =~ s{/+$}{};
	$gdir =~ s{/}{\\}g;
	$dt = $pd->{gsm}->GetDir ($mt, $gdir, 1) or return;
	ref $dt eq "HASH"                        or return;
	# Clean up
	if ($dt->{tree} && ref $dt->{tree} eq "ARRAY") {
	    my @tree = grep { $_->{id} } @{$dt->{tree}};
	    if (@tree) {
		$dt->{tree} = \@tree;
		}
	    else {
		delete $dt->{tree};
		}
	    }
	$dt{$mt}{$dir} = $dt;	# Cache!
	}
    my @names = map { $_->{name} } @{$dt{$mt}{$dir}{tree}//[]} or return;
    # print STDERR "Names: (@names)\n";
    $showhidden or @names = grep !m/^[.]/ => @names;
    return @names;
    } # DirCmd
*dircmd = \&DirCmd;

sub directory
{
    my ($w, $key, $val) = @_;
    # print STDERR "directory ...\n";
    # We need a value for -image, so its being undefined is probably caused
    # by order of handling config defaults so defer it.
    #$w->afterIdle ([$w, "set_dir" => $val]);
    } # directory

sub set_dir
{
    my ($w, $val) = @_;
    # print STDERR "set_dir ($val)\n";
    my $fulldir = _cleanpath ($val);


    my $parent = "/";
    my @dirs = ("");#$parent);
    for (split m{/+} => $fulldir) {
	length or next;
	push @dirs, $_;
	my $dir = _cleanpath (join "/" => @dirs);
	$dir eq "/" and next;
	$w->infoExists ($dir) or $w->add_to_tree ($dir, $_, $parent);
	$parent = $dir;
	}

    $w->OpenCmd ($parent);
    $w->setmode ($parent, "close");
    } # set_dir
*chdir = \&set_dir;

sub OpenCmd
{
    my ($w, $dir) = @_;

    # print STDERR "OpenCmd ($dir)\n";
    my $parent = $dir;
    foreach my $name ($w->dirnames ($parent)) {
	$name eq "." || $name eq ".." || $name eq "/" and next;
	my $subdir = _cleanpath ("$dir/$name");
	# print STDERR "> OpenCmd ($subdir)\n";
	# $dt{$mt}{$dir} or $w->DirCmd ($subdir, 0);
	if ($w->infoExists ($subdir)) {
	    $w->show (-entry => $subdir);
	    }
	else {
	    $w->add_to_tree ($subdir, $name, $parent);
	    }
	}
    } # OpenCmd
*opencmd = \&OpenCmd;

sub add_to_tree
{
    my ($w, $dir, $name, $parent) = @_;

    # printf STDERR "Add (%-20s  %-20s %s\n", $dir, $name, $parent // "--undef--";
    my $image;# = $w->cget ("-image");
#   UNIVERSAL::isa ($image, "Tk::Image") or
#	$image = $w->Getimage ($image);

    my $mode = "none";
    $w->has_subdir ($dir) and $mode = "open";

    my @args = (-image => $image, -text => $name);
    if ($parent) {    # Add in alphabetical order.
	foreach my $sib ($w->infoChildren ($parent)) {
	    if ($sib gt $dir) {
		push @args, (-before => $sib);
		last;
		}
	    }
	}

    $w->add ($dir, @args);
    $w->setmode ($dir, $mode);
    } # add_to_tree

sub has_subdir
{
    my ($w, $dir) = @_;
    my $mt = $w->privateData->{memtype};
    $dir = _cleanpath ($dir);
    # print STDERR "#"x78,"\n","Has subdir ($mt, $dir) ?\n";
    exists $dt{$mt}{$dir} or $w->DirCmd ($dir, 1);
    exists $dt{$mt}{$dir}{tree} and return 1;
    return 0;
    } # has_subdir

sub fileinfo
{
    my ($w, $dir) = @_;
    my $mt = $w->privateData->{memtype};
    my $e = _cleanpath ($dir);
    # print STDERR "Returning info on $mt $e\n";
    unless ($fi{$mt}{$e}) {
	my ($d, $n) = $e eq "/" ? ("/", "") : ($e =~ m{^(.*)/([^/]+)$});
	$d = _cleanpath ($d);
	my %di = %{$dt{$mt}{$d}};
	if (my ($f) = grep { $_->{name} eq $n } @{$di{tree}}) {
	    for (keys %$f) {
		$_ eq "tree" and next;
		$di{"f_$_"} = $f->{$_};
		}
	    }
	delete $di{tree};
	$fi{$mt}{$e} = \%di;
	}
    #DDumper $fi{$mt}{$e};
    return $fi{$mt}{$e};
    } # fileinfo

sub dirnames
{
    my ($w, $dir) = @_;
    # print STDERR "dirnames ($dir) ...\n";
    my @names = $w->Callback ("-dircmd", $dir, $w->cget ("-showhidden"));
    return (@names);
    } # dirnames

sub show_cache
{
    DDumper { Cache => \%dt };
    } # show_cache

1;
