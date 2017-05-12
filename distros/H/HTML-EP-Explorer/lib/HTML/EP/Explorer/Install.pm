use strict;
use HTML::EP::Install ();
use File::Basename ();
use File::Path ();
use ExtUtils::MakeMaker ();
use Exporter ();
use Symbol ();


package HTML::EP::Explorer::Install;

use vars qw(@EXPORT @ISA);
@EXPORT = qw(Install);
@ISA = qw(Exporter);


sub Install {
    require HTML::EP::Explorer::Config;
    my $cfg = $HTML::EP::Explorer::Config::config;
    HTML::EP::Install::InstallHtmlFiles('html', $cfg->{'html_base_dir'});
    # Create an empty config.pm and make it owned by the HTTPD user.
    my $config_path = File::Spec->catfile($cfg->{'html_base_dir'}, "admin",
					  "config.pm");
    if (!-f $config_path) {
	my $uid = getpwnam($cfg->{'httpd_user'});
	print "Creating empty config file $config_path, owned by $uid.\n";
	(open(FILE, ">>$config_path") and close(FILE))
	    or die "Failed to create $config_path: $!";
	chown($uid, 0, $config_path)
	    or die "Cannot change ownership of $config_path to $uid,0: $!";
	chmod(0600, $config_path)
	    or die "Cannot change permissions of $config_path: $!";
    }
    my $cache_path = File::Spec->catdir($cfg->{'html_base_dir'}, "status");
    if (!-d $cache_path) {
	my $uid = getpwnam($cfg->{'httpd_user'});
	print "Creating empty status directory $cache_path, owned by $uid.\n";
	(mkdir $cache_path, 0700)
	    or die "Failed to create status directory $cache_path: $!";
	chown($uid, 0, $cache_path)
	    or die "Cannot change ownership of $cache_path to $uid,0: $!";
    }
}


sub new {
    my $proto = shift;
    my $file = shift() || "lib/HTML/EP/Explorer/Config.pm";
    my $cfg = eval {
	require HTML::EP::Explorer::Config;
	$HTML::EP::Explorer::Config::config;
    } || {};
    bless($cfg, (ref($proto) || $proto));

    my $config = $main::config  ||  ! -f $file;
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
	     ($cfg->{'html_base_dir'} || "/home/httpd/html/explorer"));
    }
    if ($cfg->{'install_html_files'}  &&
	($config  ||  !$cfg->{'html_cgi_dir'})) {
	$cfg->{'html_cgi_dir'} = ExtUtils::MakeMaker::prompt
	    ("Directory for installing CGI binaries",
	     $cfg->{'html_cgi_dir'} || "$cfg->{'html_base_dir'}/cgi");
    }
    if ($config  ||  !$cfg->{'httpd_user'}) {
	$cfg->{'httpd_user'} = ExtUtils::MakeMaker::prompt
	    ("UID the httpd is running as",
	     ($cfg->{'httpd_user'} || "nobody"));
    }
    $cfg;
}

sub Save {
    my $self = shift; my $file = shift() || "lib/HTML/EP/Explorer/Config.pm";
    require Data::Dumper;
    my $dump = Data::Dumper->new([$self], ["config"]);
    $dump->Indent(1);
    my $d = "package HTML::EP::Explorer::Config;\nuse vars qw(\$config);\n"
	. $dump->Dump();
    print "Creating configuration:\n$d\n" if $main::debug;
    my $dir = File::Basename::dirname($file);
    File::Path::mkpath($dir, 0, 0755) unless -d $dir;
    my $fh = Symbol::gensym();
    (open($fh, ">$file")  and  (print $fh $d)  and  close($fh))
	or die "Failed to create $file: $!";
    $self;
}

sub Config {
    my($proto, $file) = @_ ? @_ : @ARGV;
    my $self = shift->new($file);
    my $c = ref $self;
    ($c =~ s/Install$/Config/)
	or die "Cannot handle class name $c: Must end with Install";
    $c =~ s/\:\:/\//g;
    $c .= ".pm";
    $self->Save($INC{$c} || $file)
}

1;
