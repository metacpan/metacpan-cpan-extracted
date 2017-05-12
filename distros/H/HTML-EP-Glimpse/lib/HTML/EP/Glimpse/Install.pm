# -*- perl -*-
#
#   HTML::EP::Glimpse - A simple search engine using Glimpse
#
#
#   Copyright (C) 1998    Jochen Wiedmann
#                         Am Eisteich 9
#                         72555 Metzingen
#                         Germany
#
#                         Phone: +49 7123 14887
#                         Email: joe@ispsoft.de
#
#   All rights reserved.
#
#   You may distribute this module under the terms of either
#   the GNU General Public License or the Artistic License, as
#   specified in the Perl README file.
#
############################################################################

use strict;
use HTML::EP::Install ();
use File::Basename ();
use File::Path ();
use ExtUtils::MakeMaker ();
use Exporter ();
use Symbol ();


package HTML::EP::Glimpse::Install;

use vars qw(@EXPORT @ISA $VERSION);
@EXPORT = qw(Install Config);
@ISA = qw(Exporter);
$VERSION = '0.02';

sub Install {
    require HTML::EP::Glimpse::Config;
    my $cfg = $HTML::EP::Glimpse::Config::config;
    my $basedir = $cfg->{'html_base_dir'};
    print "Copying HTML files from directory 'html' to $basedir.\n";
    HTML::EP::Install::InstallHtmlFiles('html', $basedir);

    # Create the "var" directory and make it owned by the web servers UID
    my $vardir = File::Spec->catdir($basedir, "admin", "var");
    my($user, $passwd, $uid, $gid) = getpwnam($cfg->{'httpd_user'});
    die "No such user: $cfg->{'httpd_user'}" unless defined $uid;
    if (-d $vardir) {
	my ($dev, $ino, $mode,$nlink,$u,$g) = stat $vardir;
	print STDERR "Warning: Directory $vardir is not owned by the httpd",
	    " user, $cfg->{'httpd_user'}\n" unless $u == $uid;
	print STDERR "Warning: Directory $vardir is not writable and readable",
	    " by the owner" unless ($mode & 0700) == 0700;
    } else {
	print "Creating directory $vardir, mode 0700, owned by $cfg->{'httpd_user'}.\n";
	File::Path::mkpath($vardir, 0, 0700);
	chown $uid, $gid, $vardir;
    }
}


sub PathOf {
    my $self = shift; my $prog = shift;
    foreach my $dir (File::Spec->path()) {
	my $f = File::Spec->catfile($dir, $prog);
	return $f if -x $f;
    }
    File::Spec->catfile("/usr/bin", $prog);
}

sub new {
    my $proto = shift();
    my $file = shift() || "lib/HTML/EP/Glimpse/Config.pm";
    my $cfg = eval {
	require HTML::EP::Glimpse::Config;
	$HTML::EP::Glimpse::Config::config;
    } || {};
    bless($cfg, (ref($proto) || $proto));

    my $config = shift();
    $config = (! -f $file ) unless defined $config;

    if ($config  ||  !defined($cfg->{'install_html_files'})) {
	my $reply = ExtUtils::MakeMaker::prompt
	    ("Install HTML files",
	     (!defined($cfg->{'install_html_files'}) ||
	      $cfg->{'install_html_files'}) ? "y" : "n");
	$cfg->{'install_html_files'} = ($reply =~ /y/i);
    }
    if ($cfg->{'install_html_files'}  &&
	($config  ||  !$cfg->{'html_base_dir'})) {
	$cfg->{'html_base_dir'} = ExtUtils::MakeMaker::prompt
	    ("Directory for installing HTML files",
	     ($cfg->{'html_base_dir'} || "/home/httpd/html/Glimpse"));
	$cfg->{'vardir'} = File::Spec->catdir($cfg->{'html_base_dir'},
					      'admin', 'var');
    }
    if ($config  ||  !$cfg->{'httpd_user'}) {
	$cfg->{'httpd_user'} = ExtUtils::MakeMaker::prompt
	    ("UID the httpd is running as",
	     ($cfg->{'httpd_user'} || "nobody"));
    }
    if ($config  ||  !$cfg->{'glimpse_path'}) {
	$cfg->{'glimpse_path'} = ExtUtils::MakeMaker::prompt
	    ("Path of the glimpse binary",
	     $cfg->{'glimpse_path'} || $cfg->PathOf("glimpse"))
		|| die "Missing path of glimpse binary";
    }
    print STDERR "Warning: Program $cfg->{'glimpse_path'} not found."
	unless -x $cfg->{'glimpse_path'};
    if ($config  ||  !$cfg->{'glimpseindex_path'}) {
	$cfg->{'glimpseindex_path'} = ExtUtils::MakeMaker::prompt
	    ("Path of the glimpseindex binary",
	     $cfg->{'glimpseindex_path'} || $cfg->PathOf("glimpseindex"))
		|| die "Missing path of glimpseindex binary";
    }
    $cfg;
}

sub Save {
    my $self = shift; my $file = shift() || "lib/HTML/EP/Glimpse/Config.pm";
    require Data::Dumper;
    my $d = "package HTML::EP::Glimpse::Config;\nuse vars qw(\$config);\n"
	. Data::Dumper->new([$self], ["config"])->Indent(1)->Dump();
    print "Creating configuration:\n$d\n" if $main::debug;
    my $dir = File::Basename::dirname($file);
    File::Path::mkpath($dir, 0, 0755) unless -d $dir;
    my $fh = Symbol::gensym();
    (open($fh, ">$file")  and  (print $fh $d)  and  close($fh))
	or die "Failed to create $file: $!";
    $self;
}

sub Config {
    my($proto, $file);
    if (@_) {
	($proto, $file) = @_;
    } else {
	($file) = @ARGV;
	$proto = "HTML::EP::Glimpse::Install";
    }
    my $self = $proto->new($file, 1);
    my $c = ref $self;
    ($c =~ s/Install$/Config/)
	or die "Cannot handle class name $c: Must end with Install";
    $c =~ s/\:\:/\//g;
    $c .= ".pm";
    $self->Save($file || $INC{$c});
}

1;
