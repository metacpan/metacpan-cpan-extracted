# -*- perl -*-

use strict;
use File::Path ();
use File::Find ();
use File::Copy ();
use File::Spec ();
use Cwd();


package HTML::EP::Install;

use vars qw($VERSION $install_files $install_cgi_files);

$VERSION = '0.02';
$install_files = '\.(?:html?|ep|gif|jpe?g)$';
$install_cgi_files = '\.(?:cgi|pl)$';


sub InstallFiles {
    my($fromDir, $toDir, $extension, $mode) = @_ ? @_ : @ARGV;
    $mode = 0644 unless $mode;
    my $current_dir = Cwd::cwd();
    chdir $fromDir || die "Failed to change directory to $fromDir: $!";
    my $copySub = sub {
	return unless $_ =~ /$extension/;
	my $file = $_;
	my $target_dir = File::Spec->catdir($toDir, $File::Find::dir);
	(File::Path::mkpath($target_dir, 0, 0755)
	 or die "Failed to create $target_dir: $!")
	    unless -d $target_dir;
	my $target_file = File::Spec->catfile($target_dir, $file);
	File::Copy::copy($file, $target_file)
	    || die "Failed to copy $File::Find::name to $target_file: $!";
	chmod($mode, $target_file);
    };
    File::Find::find($copySub, ".");
    chdir $current_dir || die "Failed to change directory to $current_dir: $!";
}

sub InstallHtmlFiles {
    my($fromDir, $toDir) = @_ ? @_ : @ARGV;
    InstallFiles($fromDir, $toDir, $install_files);
}

sub InstallCgiFiles {
    my($fromDir, $toDir) = @_ ? @_ : @ARGV;
    InstallFiles($fromDir, $toDir, $install_cgi_files, 0755);
}
