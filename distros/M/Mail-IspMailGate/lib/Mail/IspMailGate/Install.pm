# -*- perl -*-
#
#    ispMailGate - delivery agent for filtering and scanning E-Mail
#
#
#    This program is designed for being included into a sendmail
#    configuration as a delivery agent. Mail is filtered by the
#    agent and fed into sendmail again for continued processing.
#
#    Currently available filters include
#
#        - a virus scanner (requires apropriate external binary)
#        - PGP en-/decryption
#        - compressing and decompressing with gzip or other external
#          binaries
#
#
#    Authors:    Amar Subramanian
#                Grundstr. 32
#                72810 Gomaringen
#                Germany
#
#                Email: amar@neckar-alb.de
#                Phone: +49 7072 920696
#
#         and    Jochen Wiedmann
#                Am Eisteich 9
#                72555 Metzingen
#                Germany
#
#                Email: joe@ispsoft.de
#                Phone: +49 7123 14887
#
#
#    Version history: 05-Sep-1999       Initial version (Jochen)
#
############################################################################

use strict;
use File::Path ();
use File::Find ();
use File::Copy ();
use File::Spec ();
use ExtUtils::MakeMaker ();
use Exporter ();
use Getopt::Long ();
use Cwd();


package Mail::IspMailGate::Install;

use vars qw($VERSION @ISA @EXPORT $config);

$VERSION = '1.1013';
@ISA = qw(Exporter);
@EXPORT = qw(Install);


sub Install {
    my $self = shift;
    require Mail::IspMailGate::Config;
    my $inc_path = $INC{'Mail/IspMailGate/Config.pm'};
    if (!$self) {
	$self = $Mail::IspMailGate::Config::config;
    }

    my $tmp_dir = $self->{'tmp_dir'};
    my $created = ! -d $tmp_dir;
    if ($created) {
	File::Path::mkpath($tmp_dir, 0, 0700);
    }
    my($dev,$ino,$mode,$nlink,$uid,$gid) = stat $tmp_dir;
    my $tuid = $self->{'mail_user'};
    if ($tuid !~ /^\d+$/) {
	$tuid = getpwnam($tuid)
	    or die "Failed to determine UID of $self->{'mail_user'}}.\n",
		"Check mail_user in $inc_path.\n";
    }
    my $tgid = $self->{'mail_group'};
    if ($tgid !~ /^\d+$/) {
	$tgid = getgrnam($tgid)
	    or die "Failed to determine GID of $self->{'mail_group'}.\n",
		"Check mail_group in $inc_path.\n";
    }

    if ($gid != $tgid  ||  $uid != $tuid) {
	if ($created) {
	    chown $tuid, $tgid, $tmp_dir;
	} else {
	    die "Directory $tmp_dir doesn't have user $self->{'mail_user'}\n",
		"or group $self->{'mail_group'}. Please fix that or change\n",
		"mail_user and mail_group in $inc_path.\n",
		"and reinstall.\n";
	}
    }

    if ($mode & 07777 != 0700) {
	die "Directory $tmp_dir has insecure permissions. Please change",
	    "that to -rwx------ and reinstall.\n";
    }

    $self;
}


sub Prompt {
    my($self, $query, $default) = @_;
    $main::prompt ? ExtUtils::MakeMaker::prompt($query, $default) : $default;
}

sub new {
    my $proto = shift; my $file = shift;
    $proto ||= "Mail::IspMailGate::Install";
    $file ||= "lib/Mail/IspMailGate/Config.pm";
    my $cfg = ref($proto) ? $proto : eval {
	require Mail::IspMailGate::Config;
	$Mail::IspMailGate::Config::config;
    } || {};
    bless($cfg, (ref($proto) || $proto));

    my %opt;
    Getopt::Long::GetOptions(\%opt, "tar-path=s", "sendmail-path=s",
			     "gzip-path=s", "unzip-path=s", "unarj-path=s",
			     "lha-path=s", "antivir-path=s", "pgp-path=s",
			     "tmp-dir=s", "unix-sock=s", "pid-file=s",
			     "facility=s", "mail-user=s", "mail-group=s",
			     "domain=s", "postmaster=s", "mail-host=s",
			     "my-mail=s");

    $config ||= -f $file;
    $cfg->{'VERSION'} = $VERSION;

    my $query_path = sub {
	my @args;
	if (ref($_[0]) eq 'ARRAY') {
	    push(@args, shift())
	}
	my $prog = (@_ > 1) ? shift() : $_[0];
	push(@args, @_);
	my $spath;
	if (ref($prog)) {
	    $spath = $prog;
	    $prog = shift;
	}
	my $var = $prog . "_path";
	if (exists($opt{$prog . "-path"})) {
	    $cfg->{$var} = $opt{$prog . "-path"};
	} elsif ($config  ||  !defined($cfg->{$var})) {
	    my $path = $cfg->{$var};
	    $path = $proto->PathOf(@args) unless defined $path;
	    $cfg->{$var} = $cfg->Prompt
		("Path of the $prog program ('none' to disable $prog):",
		 $path || 'none');
	}
	$cfg->{$var} = '' if $cfg->{$var} eq 'none';
    };
    &$query_path("tar", "gtar", "tar");
    &$query_path([File::Spec->path(), "/usr/sbin", "/usr/lib"], "sendmail");
    foreach my $prog (qw(gzip unzip unarj lha antivir pgp)) {
	&$query_path($prog);
    }

    if (exists($opt{'tmp-dir'})) {
	$cfg->{'tmp_dir'} = $opt{'tmp-dir'};
    } elsif ($config  ||  !$cfg->{'tmp_dir'}) {
	$cfg->{'tmp_dir'} = $cfg->Prompt
	    ("Directory for creating temporary files:",
	     ($cfg->{'tmp_dir'} || "/var/spool/ispmailgate"));
    }

    if (exists($opt{'unix-sock'})) {
	$cfg->{'unix_sock'} = $opt{'unix-sock'};
    } elsif ($config  ||  !$cfg->{'unix_sock'}) {
	$cfg->{'unix_sock'} = $cfg->Prompt
	    ("Path of Unix socket:",
	     ($cfg->{'unix_sock'} || "/var/run/ispmailgate.sock"));
    }
    if (exists($opt{'pid-file'})) {
	$cfg->{'pid_file'} = $opt{'pid-file'};
    } elsif ($config  ||  !$cfg->{'pid_file'}) {
	$cfg->{'pid_file'} = $cfg->Prompt
	    ("Path of PID file:",
	     ($cfg->{'pid_file'} || "/var/run/ispmailgate.pid"));
    }
    if (exists($opt{'facility'})) {
	$cfg->{'facility'} = $opt{'facility'};
    } elsif ($config  ||  !$cfg->{'facility'}) {
	$cfg->{'facility'} = $cfg->Prompt
	    ("Syslog facility (see /etc/syslog.conf):",
	     ($cfg->{'facility'} || "mail"));
    }
    if (exists($opt{'mail-user'})) {
	$cfg->{'mail_user'} = $opt{'mail-user'};
    } elsif ($config  ||  !$cfg->{'mail_user'}) {
	$cfg->{'mail_user'} = $cfg->Prompt
	    ("UID that sendmail is using for executing external programs:",
	     ($cfg->{'mail_user'} || "daemon"));
    }
    if ($opt{'mail-group'}) {
	$cfg->{'mail_group'} = $opt{'mail-group'};
    } elsif ($config  ||  !$cfg->{'mail_group'}) {
	$cfg->{'mail_group'} = $cfg->Prompt
	    ("GID that sendmail is using for executing external programs:",
	     ($cfg->{'mail_group'} || "mail"));
    }
    if ($opt{'domain'}) {
	$cfg->{'unqualified_domain'} = $opt{'domain'};
    } elsif ($config  ||  !$cfg->{'unqualified_domain'}) {
	$cfg->{'unqualified_domain'} = $cfg->Prompt
	    ("Our default domain:",
	     ($cfg->{'unqualified_domain'} || "ispsoft.de"));
    }
    if ($opt{'postmaster'}) {
	$cfg->{'postmaster'} = $opt{'postmaster'};
    } elsif ($config  ||  !$cfg->{'postmaster'}) {
	$cfg->{'postmaster'} = $cfg->Prompt
	    ("Admins email address:",
	     ($cfg->{'postmaster'} ||
	      "postmaster\@$cfg->{'unqualified_domain'}"));
    }
    if ($opt{'my-mail'}) {
	$cfg->{'my_mail'} = $opt{'my-mail'};
    } elsif ($config  ||  !$cfg->{'my_mail'}) {
	$cfg->{'my_mail'} = $cfg->Prompt
	    ("My email address, to use in reports:",
	     ($cfg->{'my_mail'} ||
	      "ispmailgate\@$cfg->{'unqualified_domain'}"));
    }
    if ($opt{'mail-host'}) {
	$cfg->{'mail_host'} = $opt{'mail-host'};
    } elsif ($config  ||  !$cfg->{'mail_host'}) {
	$cfg->{'mail_host'} = $cfg->Prompt
	    ("Mail host to use for delivering mails:",
	     ($cfg->{'mail_host'} || "localhost:26"));
    }
    

    $cfg->{'packer'} ||= {};
    if (!$cfg->{'gzip_path'}) {
	delete $cfg->{'packer'}->{'gzip'};
    } else {
	$cfg->{'packer'}->{'gzip'} =
	    { 'pos' => '$gzip_path -c',
	      'neg' => '$gzip_path -cd'
	    };
    }

    $cfg->{'virscan'} ||= {};
    if (!$cfg->{'antivir_path'}) {
	delete $cfg->{'virscan'}->{'scanner'};
    } else {
	$cfg->{'virscan'}->{'scanner'} =
	    '$antivir_path -rs -nolnk -noboot $ipaths';
    }
    $cfg->{'virscan'}->{'deflater'} = [];
    if ($cfg->{'gzip_path'}  &&  $cfg->{'tar_path'}) {
	push(@{$cfg->{'virscan'}->{'deflater'}},
	     { 'pattern' => '\\.(?:tgz|tar\\.gz|tar\\.[zZ])$',
	       'cmd' => '$gzip_path -cd $ipath | $tar_path -xf - -C $odir'
	     });
    }
    if ($cfg->{'gzip_path'}) {
	push(@{$cfg->{'virscan'}->{'deflater'}},
	     { pattern => '\\.(?:gz|[zZ])$',
	       cmd => '$gzip_path -cd $ipath >$opath',
	       extension => '\\.(?:.*?)'
	     });
    }
    if ($cfg->{'tar_path'}) {
	push(@{$cfg->{'virscan'}->{'deflater'}},
	     { pattern => '\\.tar$',
	       cmd => '$gzip_path -cd $ipath >$opath'
	     });
    }
    if ($cfg->{'unzip_path'}) {
	push(@{$cfg->{'virscan'}->{'deflater'}},
	     { pattern => '\\.zip$',
	       cmd => '$unzip_path $ipath -d $odir'
	     });
    }
    if ($cfg->{'lha_path'}) {
	push(@{$cfg->{'virscan'}->{'deflater'}},
	     { pattern => '\\.(?:lha|lzx)$',
	       cmd => '$lha_path $ipath w=$odir'
	     });
    }

    $cfg->{'default_filter'} ||= ['Mail::IspMailGate::Filter::Dummy'];
    if (!$cfg->{'recipients'}) {
	$cfg->{'recipients'} ||= [];
	push(@{$cfg->{'recipients'}},
	     { 'recipient' => "[\@\\.]$cfg->{'unqualified_domain'}\$",
	       'filters' => ['Mail::IspMailGate::Filter::VirScan']
	     });
    }

    $cfg->{'pgp'}->{'encrypt_command'} ||= '$pgp_path -fea $uid +verbose=0';
    $cfg->{'pgp'}->{'decrypt_command'} ||= '$pgp_path -f +verbose=0';

    $cfg;
}


use vars qw($Descriptions);
$Descriptions =
    { 'VERSION' => "# Config file version\n",
      'mail_host' =>
          "# Mail host (with optional :port) to use for final delivery\n",
      'mail_user' =>
          "# UID under which sendmail is executing external binaries\n",
      'mail_group' =>
          "# GID under which sendmail is executing external binaries\n",
      'postmaster' =>
          "# E-Mail address of the administrator\n",
      'tmp_dir' =>
          "# Directory to use for temporary files\n",
      'default_filter' =>
          "# List of filters to use by default\n",
      'unqualified_domain' =>
          "# Domain to assume for email adresses without \@domain\n",
      'antivir_path' =>
          "# Path of external virus scanner or empty\n",
      'lha_path' =>
          "# Path of the LhA binary (for extracting .lha files) or empty\n",
      'gzip_path' =>
          "# Path of the gzip binary (for extracting .gz files) or empty\n",
      'tar_path' =>
          "# Path of the tar binary (for extracting .tar files) or empty\n",
      'unarj_path' =>
          "# Path of the unarj binary (for extracting .arj files) or empty\n",
      'unzip_path' =>
          "# Path of the unzip binary (for extracting .zip files) or empty\n",
      'sendmail_path' =>
          "# Path of the sendmail binary or empty\n",
      'unix_sock' =>
          "# Path of the Unix socket to connect to a server\n",
      'facility' =>
          "# Facility to use for syslog\n",
      'recipients' =>
          "# List of senders/recipients and associated filters\n",
      'virscan' =>
          "# Configuration of the virus scanner\n",
      'packer' =>
          "# Configuration of the packer\n",
      'pgp' =>
          "# Configuration of the PGP module\n",
      'pid_file' =>
          "# PID file to use for the server\n"
    };
sub Description {
    my $self = shift; my $key = shift;
    exists($Descriptions->{$key}) ? $Descriptions->{$key} : '';
}

sub Save {
    my $self = shift; my $file = shift() || "lib/Mail/IspMailGate/Config.pm";
    require Data::Dumper;
    my $var = "Mail::IspMailGate::Config::config";
    my $dump = Data::Dumper->new([$self], [$var])->Indent(1)->Dump();
    if ($dump =~ /^(.*?\n)(  \'\w+\' =>.*\n)/s) {
	my $header = $1;
	my $list = $2;
	my %keys;
	while ($list =~ /\s\s\'(\w+)\'\s+=>\s+(
			\[\n.*?\n\s\s\]		|
			\{\n.*?\n\s\s\}		|
			.*?),?\n(.*)/sx) {
	    $keys{$1} = $2;
	    $list = $3;
	}
	$dump = $header . join("", map { $self->Description($_) .
					     "  '$_' => $keys{$_},\n"
					 } sort keys %keys) . $list;
    }
    $dump = "package Mail::IspMailGate::Config;\n\n" . $dump;

    print "Creating configuration:\n$dump\n" if $main::verbose;
    my $dir = File::Basename::dirname($file);
    File::Path::mkpath($dir, 0, 0755) unless -d $dir;
    my $fh = Symbol::gensym();
    (open($fh, ">$file")  and  (print $fh $dump)  and  close($fh))
	or die "Failed to create $file: $!";
    $self;
}


sub Config {
    my($proto, $file) = @_ ? @_ : ("Mail::IspMailGate::Install", @ARGV);
    if (!$file) {
	my $c = (ref($proto) || $proto);
	$c =~ s/Install$/Config/
	    or die "Cannot handle class name $c: Must end with Install";
	eval "require $c";
	$c =~ s/\:\:/\//g;
	$c .= ".pm";
	$file = $INC{$c} || "lib/Mail/IspMailGate/Config.pm";
    }
    my $self = $proto->new($file);
    $self->Save($file);
}


sub PathOf {
    my $proto = shift;
    my @path = ($_[0] && ref($_[0]) eq 'ARRAY') ?
	@{shift()} : File::Spec->path();
    foreach my $prog (@_) {
	foreach my $dir (@path) {
	    my $file = File::Spec->catfile($dir, $prog);
	    return $file if -x $file;
	}
    }
    return '';
}


1;
