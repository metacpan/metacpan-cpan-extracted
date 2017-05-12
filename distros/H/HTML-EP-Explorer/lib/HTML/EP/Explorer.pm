# -*- perl -*-
#
#   HTML::EP::Explorer - A Perl package for browsing filesystems and
#       executing actions on files.
#
#
#   This module is
#
#           Copyright (C) 1999     Jochen Wiedmann
#                                  Am Eisteich 9
#                                  72555 Metzingen
#                                  Germany
#
#                                  Email: joe@ispsoft.de
#
#   All Rights Reserved.
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   $Id: Explorer.pm,v 1.2 1999/11/04 12:24:10 joe Exp $
#

use strict;

use Cwd ();
use File::Spec ();
use HTML::EP ();
use HTML::EP::Locale ();
use HTML::EP::Session ();


package HTML::EP::Explorer;

@HTML::EP::Explorer::ISA = qw(HTML::EP::Session HTML::EP::Locale HTML::EP);
$HTML::EP::Explorer::VERSION = '0.1006';

sub init {
    my $self = shift;
    $self->HTML::EP::Session::init(@_);
    $self->HTML::EP::Locale::init(@_);
}

sub _ep_explorer_init {
    my $self = shift; my $attr = shift;
    return '' if $self->{_ep_explorer_init_done};
    $self->print("_ep_explorer_init: attr = (", join(",", %$attr), ")\n")
	if $self->{'debug'};
    $self->{_ep_explorer_init_done} = 1;
    my $cgi = $self->{'cgi'};
    $attr->{'class'} ||= "HTML::EP::Session::Cookie";
    $attr->{'id'} ||= "explorer-session";
    $attr->{'path'} ||= "/";
    $attr->{'expires'} ||= "+10y";
    eval { $self->_ep_session($attr) };
    my $session = $self->{$attr->{'var'} || 'session'};
    if ($self->{debug}) {
	require Data::Dumper;
	$self->print("Session = ", Data::Dumper::Dumper($session), "\n");
    }
    if (!$attr->{'noprefs'} and
	($@  or  !exists($session->{'prefs'}))) {
	# First time run, open the prefs page.
	my $prefs = $attr->{'prefs_page'} || "prefs.ep";
	my $return_to = $attr->{'return_to'} || $self->{'env'}->{'PATH_INFO'};
	$self->print("_ep_explorer_init: Redirecting to $prefs, returning to $return_to\n")
	    if $self->{'debug'};
	$cgi->param('return_to', $return_to);
	$self->{'_ep_output'} .= $self->_ep_include({file => $prefs});
	$self->_ep_exit({});
    }
    '';
}

sub InitialConfig {
    my $self = shift;
    { 'actions' => [],
      'filetypes' => [
        { 'name' => $self->{'_ep_language'} eq 'de' ?
	  'Alle Dateien (*)' : 'All Files (*)',
	  'icon' => '/icons/unknown.gif',
	  're' => '.*'
	}],
      'directories' => [
	{ 'name' => 'Root-Directory (/)',
	  'dir' => '/'
	}]
    }
}


sub ReadArray {
    my $self = shift;  my $prefix = shift;
    my $cgi = $self->{'cgi'};
    my %hash;
    foreach my $key ($cgi->param()) {
	next unless $key =~ /^$prefix(.*)/;
	$self->print("ReadArray: Found key $key, saving as $1 (",
		     join(",", $cgi->param($key)), "\n") if $self->{'debug'};
	$hash{$1} = [$cgi->param($key)];
    }
    my @array;
    while (@{$hash{'name'}}) {
	my %h;
	while (my($var, $val) = each %hash) {
	    $h{$var} = shift @$val;
	}
	push(@array, \%h) if $h{'name'};
    }
    \@array;
}


sub ReadDirectories {
    my $dirs = shift()->ReadArray('explorer_directory_');
    my $pwd;
    foreach my $dir (@$dirs) {
	# Don't save the name, that the user gave us. Save the physical
	# filesystem path, so that we can later compare it to paths
	# requested by other users, if "Allow access to other directories"
	# is off.
	$pwd = Cwd::cwd() unless $pwd;
	chdir($dir->{'dir'}) or die "Failed to change directory to $dir: $!";
	$dir->{'dir'} = Cwd::cwd();
    }
    chdir $pwd if $pwd;
    $dirs;
}


sub ReadConfig {
    my $self = shift; my $config = shift;
    my $cgi = $self->{'cgi'};

    foreach my $var ($cgi->param()) {
	next unless $var =~ /^explorer_config_(.*)/;
	my $v = $1;
	$config->{$v} = $cgi->param($var);
    }

    $config->{'actions'} = $self->ReadArray('explorer_action_');
    $config->{'status_actions'} = $self->ReadArray('explorer_status_action_');
    $config->{'filetypes'} = $self->ReadArray('explorer_filetype_');
    $config->{'directories'} = $self->ReadDirectories();
    $config;
}


sub _ep_explorer_config {
    my $self = shift;  my $attr = shift;
    my $debug = $self->{'debug'};
    my $cgi = $self->{'cgi'};
    my $file = $attr->{'file'} || "config.pm";
    $self->{'config'} = eval { require $file } || $self->InitialConfig();
    if ($attr->{'maysafe'} && $cgi->param('save')) {
	$self->print("_ep_explorer_config: Saving.\n") if $debug;
	$self->{'config'} = $self->ReadConfig($self->{'config'});
	require Data::Dumper;
	my $fh = Symbol::gensym();
	my $dump = Data::Dumper->new([$self->{'config'}])->Indent(1)->Terse(1);
	$self->print("_ep_explorer_config: Got\n", $dump->Dump(), "\n")
	    if $debug;
	(open($fh, ">$file") and (print $fh $dump->Dump()) and close($fh))
	    or die "Failed to create $file: $!";
    }
    $self->{'actions'} = $self->{'config'}->{'actions'};
    $self->{'status_actions'} = $self->{'config'}->{'status_actions'};
    $self->{'directories'} = $self->{'config'}->{'directories'};
    $self->{'filetypes'} = $self->{'config'}->{'filetypes'};
    $self->{'num_directories'} = @{$self->{'directories'}};
    '';
}

sub ReadPrefs {
    my $self = shift; my $prefs = shift;
    my $cgi = $self->{'cgi'};
    foreach my $var ($cgi->param()) {
	next unless $var =~ /^explorer_prefs_(.*)/;
	my $vr = $1;
	my $val = $cgi->param($var);
	$prefs->{$vr} = $val;
    }
    $prefs;
}

sub _ep_explorer_prefs {
    my $self = shift;  my $attr = shift;
    my $debug = $self->{'debug'};
    $attr->{'noprefs'} = 1;
    $self->_ep_explorer_init($attr);
    my $session = $self->{$attr->{'var'} ||= 'session'};
    my $cgi = $self->{'cgi'};
    my $return;
    if (($return = $cgi->param('save_and_return'))  ||
	 $cgi->param('save')) {
	$self->print("_ep_explorer_prefs: Saving.\n") if $debug;
	$session->{'prefs'} = $self->ReadPrefs($session->{'prefs'});
	if ($debug) {
	    require Data::Dumper;
	    $self->print("_ep_explorer_save: Got\n",
			 Data::Dumper->new([$session->{'prefs'}])
			     ->Indent(1)->Terse(1)->Dump(), "\n");
	}
	$attr->{'locked'} = 1;
	$self->_ep_session_store($attr);
    }
    if ($return  and  (my $return_to = $cgi->param('return_to'))) {
	$self->print("Returning to $return_to\n") if $debug;
	$self->{'_ep_output'} .=
	    $self->_ep_include({'file' => $return_to});
	$self->print("Done including $return_to\n") if $debug;
	$self->_ep_exit({});
    }
    '';
}

sub _ep_explorer_basedir {
    my $self = shift; my $attr = shift;
    return if $self->{'basedir'};
    my $cgi = $self->{'cgi'};
    my $session = $self->{'session'};
    my $debug = $self->{'debug'};
    my $basedir = $cgi->param('basedir') || $session->{'basedir'}
        || $attr->{'basedir'} || $self->{'directories'}->[0]
	|| $ENV{'DOCUMENT_ROOT'};
    $basedir = HTML::EP::Explorer::Dir->new($basedir)->{'dir'};
    chdir($basedir)
	or die "Failed to change directory to $basedir: $!";
    $basedir = Cwd::cwd();
    if (!$session->{'basedir'} or $session->{'basedir'} ne $basedir) {
	$self->{'modified'} = 1;
	$session->{'basedir'} = $basedir;
    }
    foreach my $dir (@{$self->{'directories'}}) {
	$self->print("Checking whether $dir->{'dir'} is $basedir.\n")
	    if $debug;
	if ($dir->{'dir'} eq $basedir) {
	    $self->{'in_top_dir'} = 1;
	    $self->{'in_base_dir'} = $dir;
	    $self->{'display_dir'} = "/";
	    $self->print("Yes, it is.\n") if $debug;
	    last;
	}
    }
    if (!$self->{'in_top_dir'}) {
	$self->{'in_top_dir'} = ($basedir eq File::Spec->rootdir());
	foreach my $dir (@{$self->{'directories'}}) {
	    $self->print("Checking whether $basedir is below $dir->{'dir'}.\n")
		if $debug;
	    if ($basedir =~ /^\Q$dir->{'dir'}\E(\/.*)$/) {
		$self->{'in_base_dir'} = $dir;
		$self->{'display_dir'} = $1;
		$self->print("Yes, it is.\n") if $debug;
		last;
	    }
	}
	if (!$self->{'in_base_dir'}) {
	    die "Directory $basedir is outside of the permitted area."
		if $self->{'config'}->{'dirs_restricted'};
	    $self->{'display_dir'} = $basedir;
	}
    }
    $self->print("Basedir is $basedir.\n") if $debug;
    $self->{'basedir'} = $basedir;
    '';
}

sub _ep_explorer_sortby {
    my $self = shift; my $attr = shift;
    my $cgi = $self->{'cgi'};
    my $session = $self->{'session'};
    my $sortby = $cgi->param('sortby') || $session->{'sortby'} ||
	$attr->{'sortby'} || "name";
    if (!$session->{'sortby'}  ||  $session->{'sortby'} ne $sortby) {
	$self->{'modified'} = 1;
	$session->{'sortby'} = $sortby;
    }
    $self->print("Sorting by $sortby.\n") if $self->{'debug'};
    $self->{'sortby'} = $sortby;
    '';
}

sub _ep_explorer_filetype {
    my $self = shift; my $attr = shift;
    my $cgi = $self->{'cgi'};
    my $debug = $self->{'debug'};
    my $session = $self->{'session'};
    my $filetype = $cgi->param('filetype') || $session->{'filetype'}
	|| $attr->{'filetype'} || '';
    $self->print("Looking for file type $filetype\n") if $debug;
    my $found;
    foreach my $ft (@{$self->{'filetypes'}}) {
	if ($filetype eq $ft->{'name'}) {
	    $found = $ft;
	    last;
	}
    }
    if ($found) {
	$self->print("Found it.\n") if $debug;
    } elsif (@{$self->{'filetypes'}}) {
	$found = $self->{'filetypes'}->[0];
	$self->print("Choosing default file type $found->{'name'}\n")
	    if $debug;
    } else {
	$self->print("No file type found.\n");
    }

    $found->{'selected'} = 'SELECTED' if $found;
    my $name = $found ? $found->{'name'} : '';
    if (!defined($session->{'filetype'}) ||
	$session->{'filetype'} ne $name) {
	$self->{'modified'} = 1;
	$session->{'filetype'} = $name;
    }
    $self->print("Filetype is $found->{'name'}.\n")
	if $self->{'debug'} and $found;
    $self->{'filetype'} = $found;
    '';
}

sub _ep_explorer_browse {
    my $self = shift; my $attr = shift;
    my $cgi = $self->{'cgi'};
    my $debug = $self->{'debug'};
    my $session = $self->{'session'};
    $self->{'modified'} = 0;
    my $dir_template = $self->{'dir_template'}
	or die "Missing template variable: dir_template";
    my $item = $attr->{'item'} || die "Missing item name";

    $self->_ep_explorer_basedir($attr);
    $self->_ep_explorer_filetype($attr);
    $self->_ep_explorer_sortby($attr);

    my $dir = HTML::EP::Explorer::Dir->new($self->{'basedir'});
    my $list = $dir->Read($self->{'filetype'}->{'re'});
    my $sortby = $self->{'sortby'};
    my $updir;
    if ($list->[0]->IsDir()
	and  $list->[0]->{'name'} eq File::Spec->updir()) {
	$updir = shift @$list;
    }
    $self->print("Sorting by $sortby.\n") if $debug;
    if ($sortby eq 'type') {
	@$list = sort {
	    if ($a->IsDir()) {
		$b->IsDir() ? $a->{'name'} cmp $b->{'name'} : -1;
	    } elsif ($b->IsDir()) {
		return 1;
	    } else {
		my $ae = ($a =~ /\.(.*?)$/) ? $1 : '';
		my $be = ($b =~ /\.(.*?)$/) ? $1 : '';
		($ae cmp $be) || ($a->{'name'} cmp $b->{'name'});
	    }
	} @$list;
    } elsif ($sortby eq 'uid') {
	@$list = sort { (getpwuid($a->{'uid'}) || '') cmp
			(getpwuid($b->{'uid'}) || '')} @$list;
    } elsif ($sortby eq 'gid') {
	@$list = sort { (getgrgid($a->{'gid'}) || '') cmp
			(getgrgid($b->{'gid'}) || '')} @$list;
    } elsif ($sortby =~ /^(?:size|[amc]time)$/) {
	@$list = sort { $a->{$sortby} <=> $b->{$sortby} } @$list;
    } else {
	@$list = sort { $a->{$sortby} cmp $b->{$sortby} } @$list;
    }
    unshift(@$list, $updir)
	if $updir and !$self->{'in_top_dir'};
    my $output = '';
    $self->{'i'} = 0;
    foreach my $i (@$list) {
	$self->{$item} = $i;
	$output .= $i->AsHtml($self, $item);
	++$self->{'i'};
    }

    $self->_ep_session_store($attr) if $self->{'modified'};
    $output;
}

sub _format_ACTIONS {
    my $self = shift; my $item = shift;

    my $str = '';
    foreach my $action (@{$self->{'actions'}}) {
	$self->{'action'} = $action;
	$self->{'icon'} = $action->{'icon'} ?
	    qq{<img src="$action->{'icon'}" alt="$action->{'name'}">} :
	    $action->{'name'};
	$str .= $self->ParseVars($self->{'action_template'});
    }

    $str;
}

sub FindAction {
    my $self = shift; my $attr = shift;
    my $cgi = $self->{'cgi'};
    my $name = $cgi->param('faction') || $attr->{'faction'} ||
	die "Missing action name";
    my $debug = $self->{'debug'};
    $self->print("FindAction: Looking for $name\n") if $debug;
    my $action;
    foreach my $a (@{$self->{'actions'}}) {
	if ($a->{'name'} eq $name) {
	    $action = $a;
	    last;
	}
    }
    $self->{'action'} = $action or die "Unknown action: $name";
    $self->print("Selected action is $action->{'name'}\n") if $debug;
    $action;
}

sub FindStatusAction {
    my $self = shift;  my $script = shift;  my $attr = shift;
    my $debug = $self->{'debug'};
    $self->print("FindStatusAction: Looking for $script\n") if $debug;
    my $action;
    foreach my $sa (@{$self->{'status_actions'}}) {
	if ($sa->{'name'} eq $script) {
	    $self->print("FindStatusAction: Returning ",
			 join(",", %$sa), "\n") if $debug;
	    return $sa;
	}
    }
    die "FindStatusAction: Unknown script $script";
}


sub _ep_explorer_logfile {
    my $self = shift; my $attr = shift;
    my $debug = $self->{'debug'};
    my $action = $self->FindAction({});
    my $fh = Symbol::gensym();
    require Fcntl;
    $self->print("Opening logfile: $action->{'logfile'}\n") if $debug;
    sysopen($fh, $action->{'logfile'}, Fcntl::O_RDONLY())
	or die "Failed to open logfile $action->{'logfile'}: $!";
    $self->Stop();
    my $cgi = $self->{'cgi'};
    $self->print($cgi->header('-type' => 'text/plain'));
    $self->print("\n");
    seek($fh, -2000, 2);
    $| = 1;
    my $pos;
    local $/ = undef;
    while(1) {
	$pos = tell($fh);
	if (eof($fh)) {
	    sleep 15;
	    seek($fh, $pos, 0);
	} else {
	    my $line = <$fh>;
	    if (!defined($line)) {
		$self->print("Failed to read: $!");
		last;
	    } else {
		$self->print($line);
	    }
	}
    }
    '';
}


sub _ep_explorer_queue {
    my $self = shift;  my $attr = shift;
    my $cgi = $self->{'cgi'};
    my $debug = $self->{'debug'};
    my $action = $self->FindAction($attr);

    my $ignore_cache;
    if (my $script = $cgi->param('script')) {
	my $status_action = $self->FindStatusAction($script, $attr);
        my %env = %ENV;
        $env{'job'} = quotemeta($cgi->param('job'));
        $env{'user'} = quotemeta($self->User());
        foreach my $var (split(/\n/, $action->{'vars'})) {
	    if ($var =~ /^\s*(.*?)\s*=\s*(.*?)\s*$/) {
		$env{$1} = $2;
	    }
        }
        local %ENV = %env;
	if ($debug) {
	    my $command = $status_action->{'script'};
	    $command =~ s/\$(\w+)/$ENV{$1}/g;
	    $self->print("_ep_explorer_queue: Executing command ($command)\n");
	}
        system "$status_action->{'script'} >/dev/null";
	$ignore_cache = 1;
    }

    my $input;
    my $file = File::Spec->catfile("status",
				   $cgi->escape($action->{'name'}));
    if (!$ignore_cache  &&  $self->{'config'}->{'cache'}) {
	my($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime,
	   $mtime) = stat $file;
	my $regen_time = $mtime + $self->{'config'}->{'cache'};
	$self->print("Cache file $file ",
		     -f _ ? "exists.\n" : "doesn't exist.\n",
		     -f _ ? "Modification time is $mtime, current time is " .
		            time() . ", regeneration time is $regen_time\n"
		          : "") if $debug;
	if (-f _  &&  $regen_time > time()) {
	    $self->print("Trying to load cache file $file.\n") if $debug;
	    require Fcntl;
	    my $fh = Symbol::gensym();
	    if (open($fh, "<$file")  and  flock($fh, Fcntl::LOCK_SH())) {
		local $/ = undef;
		$input = <$fh>;
	    }
	    $self->print($input ? "Got:\n$input\n" : "Not successful ($!)\n")
		if $debug;
	}
    }
    if (!$input) {
	my $command = $action->{'status'};
	local $ENV{'user'} = quotemeta($self->User());
	$input = `$command 2>&1`;
	if ($self->{'config'}->{'cache'}) {
	    require Fcntl;
	    my $fh = Symbol::gensym();
	    if (sysopen($fh, $file, Fcntl::O_RDWR()|Fcntl::O_CREAT())
		and flock($fh, Fcntl::LOCK_EX())) {
		print $fh $input;
		truncate($fh, length($input));
	    }
	}
    }

    my @status;
    foreach my $line (split(/\n/, $input)) {
	if ($line =~ /^(\S+)\s+(\S+)\s+(\d+)\s+(\S.*?)\s+(\d+)\s+bytes/) {
	    push(@status, { 'rank' => $1,
			    'owner' => $2,
			    'job' => $3,
			    'file' => $4,
			    'size' => $5 });
	}
    }
    $self->{'status'} = \@status;
    $self->{'status_num'} = @status;
    '';
}

sub _ep_explorer_action {
    my $self = shift;  my $attr = shift;
    my $cgi = $self->{'cgi'};
    my $debug = $self->{'debug'};
    my $name = $cgi->param('faction') || $attr->{'faction'}
	|| die "Missing action name";
    my $action = $self->FindAction($attr);

    my @files;
    my $file;
    if (($file = $cgi->param('files'))  ||  ($file = $attr->{'files'})) {
	@files = split(" ", $file);
    } elsif (($file = $cgi->param('file')) || ($file = $attr->{'file'})) {
	@files = $file;
    } else {
	die "Missing file name";
    }
    $self->print("Selected files are:\n", map{"  $_\n"} @files) if $debug;

    my $command = $action->{'script'};
    my $files;
    if ($command =~ /\$files/) {
	# Can handle multiple files
	$files = join(" ", map {
	    quotemeta(HTML::EP::Explorer::File->new($_)->{'file'})
	} @files);
	$command =~ s/\$files/$files/sg;
	$command .= " 2>&1" if $attr->{'execute'};
    } else {
	my @commands;
	foreach my $file (@files) {
	    my $c = $command;
	    my $f = quotemeta(HTML::EP::Explorer::File->new($file)->{'file'});
	    $c =~ s/\$file/$f/sg;
	    push(@commands, $attr->{'execute'} ? "$c 2>&1" : $c);
	}
	$command = join(";", @commands);
    }
    $self->print("Selected command is $command\n") if $debug;
    local $ENV{'user'} = quotemeta($self->User());
    local $ENV{'files'} = $files if $files;
    if ($attr->{'execute'}) {
	return `$command`;
    } else {
	return $command;
    }
}

sub User {
    $ENV{'REMOTE_USER'} || "anonymous";
}

sub _format_MODE {
    my $self = shift; my $mode = shift;
    (($mode & 0400) ? "r" : "-") .
    (($mode & 0200) ? "w" : "-") .
    (($mode & 04000) ? "s" : (($mode & 0100) ? "x" : "-")) .
    (($mode & 040)  ? "r" : "-") .
    (($mode & 020)  ? "w" : "-") .
    (($mode & 02000) ? "s" : (($mode & 010) ? "x" : "-")) .
    (($mode & 04)   ? "r" : "-") .
    (($mode & 02)   ? "w" : "-") .
    (($mode & 01)   ? "x" : "-");
}

sub _format_UID {
    my $self = shift; my $uid = shift;
    my $u = getpwuid($uid);
    defined $u ? $u : $uid;
}

sub _format_GID {
    my $self = shift; my $gid = shift;
    my $g = getgrgid($gid);
    defined $g ? $g : $gid;
}

sub _format_DATE {
    my $self = shift; my $time = shift;
    return '' unless $time;
    return $self->_format_TIME(scalar(localtime($time)));
}

sub _format_SELECTED {
    my $self = shift; shift() ? "SELECTED" : "";
}

package HTML::EP::Explorer::File;

sub new {
    my $proto = shift;  my $file = shift;
    $file =~ s/^file://;
    my $self = { 'file' => $file, @_ };
    $self->{'name'} ||= File::Basename::basename($file);
    $self->{'url'} ||= "file:$file";
    bless($self, (ref($proto) || $proto));
}

sub IsDir { 0 }

sub AsHtml {
    my $self = shift;  my $ep = shift;
    foreach my $ft (@{$ep->{'filetypes'}}) {
	if ($ft->{'icon'}  &&  $self->{'name'} =~ /$ft->{'re'}/) {
	    $self->{'icon'} = $ft->{'icon'};
	    last;
	}
    }
    $self->{'icon'} = "unknown.gif" unless $self->{'icon'};
    $ep->ParseVars($ep->{'file_template'}
		   or die "Missing template variable: file_template");
}


package HTML::EP::Explorer::Dir;

sub new {
    my $proto = shift;  my $dir = shift;
    $dir =~ s/^file://;
    my $self = { 'dir' => $dir, @_ };
    $self->{'name'} ||= File::Basename::basename($dir);
    $self->{'url'} ||= "file:$dir";
    bless($self, (ref($proto) || $proto));
}

sub IsDir { 1 }

sub AsHtml {
    my $self = shift;  my $ep = shift;
    $ep->ParseVars($ep->{'dir_template'}
		   or die "Missing template variable: dir_template");
}

sub Read {
    my $self = shift;  my $re = shift;
    my $fh = Symbol::gensym();
    my $pwd = Cwd::cwd();
    my $curdir = File::Spec->curdir();
    my $dir = $self->{'dir'};
    my @list;
    chdir $dir or die "Failed to change directory to $dir: $!";
    opendir($fh, $curdir) or die "Failed to open directory $dir: $!";
    while (defined(my $f = readdir($fh))) {
	next if $f eq $curdir;
	my($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size,
	   $atime, $mtime, $ctime, $blksize) = stat $f;
	if (-f _) {
	    push(@list,
		 HTML::EP::Explorer::File->new(File::Spec->catfile($dir, $f),
					       'name' => $f,
					       'mode' => $mode,
					       'uid' => $uid,
					       'gid' => $gid,
					       'size' => $size,
					       'mtime' => $mtime,
					       'ctime' => $ctime,
					       'atime' => $atime))
		if !$re || $f =~ /$re/;
	} elsif (-d _) {
	    push(@list,
		 HTML::EP::Explorer::Dir->new(File::Spec->catdir($dir, $f),
					      'name' => $f,
					      'mode' => $mode,
					      'uid' => $uid,
					      'gid' => $gid,
					      'size' => $size,
					      'mtime' => $mtime,
					      'ctime' => $ctime,
					      'atime' => $atime))
	}
    }
    closedir $fh;
    chdir $pwd;
    \@list;
}


1;

__END__

=pod

=head1 NAME

  HTML::EP::Explorer - Web driven browsing of a filesystem


=head1 SYNOPSIS

  <ep-explorer-browse>


=head1 DESCRIPTION

This application was developed for DHW, a german company that wanted to
give its users access to files stored on a file server via certain
applications defined by an administrator. (See

  http://www.dhw.de/

if you are interested in the sponsor.) The rough idea is as follows:

The users are presented a view similar to that of the Windows Explorer
or an FTP servers directory listing. On the top they have a list of
so-called actions. The users may select one or more files and then
execute an action on them.


=head1 INSTALLATION

The system is based on my embedded HTML system HTML::EP. It should be
available at the same place where you found this file, or at any CPAN
mirror, in particular

  ftp://ftp.funet.fi/pub/languages/perl/CPAN/authors/id/JWIED/

The installation of HTML::EP is described in detail in the README, I
won't explain it here. However, in short it is just as installing
HTML::EP::Explorer: Assumed you have a file

  HTML-EP-Explorer-0.1003.tar.gz

then you have to execute the following steps:

  gzip -cd HTML-EP-Explorer-0.1003.tar.gz | tar xf -
  perl Makefile.PL
  make		# You will be prompted some questions here
  make test
  make install

Installation will in particular create a file

  lib/HTML/EP/Explorer/Config.pm

which will contain your answers to the following questions:

=over 8

=item *

  Install HTML files?

If you say I<y> here (the default), the installation script will
install some HTML files at a location choosed by you. Usually you
will say yes, because the system is pretty useless without it's
associated HTML files. However, if you already did install the
system and modified the HTML files you probably want to avoid
overriding them. In that case say I<n>.

=item *

  Directory for installing HTML files?

If you requested installing the HTML files, you have to choose a
location. By default the program suggests

  F</home/httpd/html/explorer>

which is fine on a Red Hat Linux box. Users of other systems will modify
this to some path below your your web servers root directory.

=item *

  Directory for installing CGI binaries?

If HTML files are installed, you must install some CGI binaries too.
This question allows you to select an installation path, by default
the subdirectory F<cgi> within the directory for installing HTML
files.

Note that you need to configure the httpd so that it treats this
directory as a CGI directory. For example Apache users may add the
following to F<srm.conf>:

  ScriptAlias /home/httpd/html/explorer/cgi

=item *

  UID the httpd is running as?

The explorer scripts need write access to some files, in particular the
configuration created by the site administrator. To enable write access,
these files are owned by the Unix user you enter here, by default the
user I<nobody>.

In most cases this will be the same user that your httpd is running as,
but it might be different, for example if your Apache is using the
suexec feature. Contact your webmaster for details.

=back

If you didn't already do so, configure your web server for feeding
files with extension I<.ep> into the CGI binary I<ep.cgi> or into
the mod_perl module I<Apache::EP>. The README of HTML::EP tells you
how. See L<HTML::EP(3)>.

That's it! Assuming the directory F</home/httpd/html/explorer> is
reachable as F</explorer> in your browser, point it to

  http://localhost/explorer/

You should now see a directory listing. If so, proceed to
L<CONFIGURATION>.


=head1 CONFIGURATION

Besides the questions you already answered when installing the explorer,
the system is configurable via any Web browser. Assuming the Explorer
is reachable below http://localhost/explorer/, Point your browser to

  http://localhost/explorer/admin/prefs.ep


=head2 Security considerations

The first thing you probably notice is that you need not supply a password
for accessing this page. This should be changed. A typical configuration
requests that only the user root can visit this page. For example, with
Apache, you could insert the following into your httpd.conf:

  <Location /explorer/admin>
    AuthUserFile /etc/passwd
    AuthName "Explorer Administration"
    AuthTyoe basic
    require user root
  </Location>

(Of course one can discuss whether this is a secure thing, as it could
allow deducing the root password by using some sort of crack mechanism.
On the systems where I use it there ary typically lots of other
possibilities for doing the same ... :-)


=head2 E-Mail address of the administrator

From time to time the system will use this address for sending emails
to you.


=head2 Actions

This is the explorers heart. Actions are merely shell scripts, to which
the files will be fed, that your users have selected.

To create an action, fill out the following fields:

=over

=item Name

This is some short text that your users will see on the web frontend.
For example, it could be I<Printing on the LaserJet>.

=item Icon

This (optional) entry means that the explorer will use the named image
file to display it instead of the name above. For example, this could
be a small gif with the word I<LaserJet> on it.

You must supply an URL here. If you are using Apache, then a lot of
nice icons are accessible in your httpd's icons directory. See the
README file.

=item Script

This is a shell command that the explorer will execute for performing
the action. The command may use the variables I<file> (the filename)
or I<user> (the users name). For example, one could use

  lpr -Plaserjet -U $user $file

The user name is deduced by looking at the environment variable
I<REMOTE_USER>: If your directory I</explorer> is password protected,
then this variable will contain the users name as set by the web
server. If the variable is empty, then the user name I<anonymous>
is used.

Don't try to protect the user or file name with quotes: The Explorer
will use Perl's I<quotemeta> function to secure these variables. For
example, if your tricky users supply a file name

  `rm -rf /`

then the Explorer will run the command

  lpr -Plaserjet -U anonymous \`rm\ -rf \/\`

which is safe. See L<perlsec> for more details on security considerations
with Perl.

If your script command is able to process multiple files with one command,
then you may prefer

  lpr -Plaserjet -U $user $files

The Explorer will detect that you are using B<$files> and not B<$file>
and will run a single command.

=item Status script

Similar to the action script, this one will try to guess the current status.
A typical command might be

  lpq -Plaserjet -U $user

The status script is suggested to produce output looking like that of
lpq.

=item Logfile

Path of a logfile to view

=back

Note that you see only one (empty) action at the start: If you
fill it out and hit I<Save settings>, then a second (empty) row
will appear automatically. To be precise, you will always have
one empty row at the bottom.

Actions can be removed by just blanking out the name and hitting
I<Save settings>.


=head2 Status cache

To save CPU time, you might like to make use of the Status cache.
By setting this variable to a certain number of seconds, say 300,
the Explorer will not always run the status script. Instead it
will create a cache file in the subdirectory F<status> and save
the status script's output there. When the status is queried the
next time, this cache file will be used, unless the cache file's
modification time is more that the given number of seconds in the
past. In that case a new cache file will be created by running
the status script again.


=head2 Initial directories

In most cases you are not interested in giving your users access to
the whole directory tree. For example, if your users use a Samba
server to place files on your machine, than the Explorer should
probably restrict your users to the Samba servers files.

To create an initial directory, fill out the following fields:

=over

=item Name

This is a verbose name that your users will see instead of the directory
path. For example, it could be a Samba share name.

=item Directory

The real directory path.

=back

By default your users will still be able to access files outside of
the initial directories and these paths are only suggestions. This
can be changed by disabling I<Allow access to other directories>.

Again, you will always see one empty directory at the bottom of the
list. To create a new directory just fill this out and hit I<Save
Settings>. Wipe out the name for removing an existing directory.


=head2 File types

People are used to see only certain files when selecting them for
actions. For example, when opening an existing document in Microsoft
Word, then you will by default see only files with extension I<.doc>.

A file type can be created by filling out the following fields:

=over

=item Name

This is a description of the file type, that your users will see. For
example, it could be

  PostScript files (*.ps)

or

  All Files (*)

=item Icon

This is an (optional) icon to use for showing the file type. For
example, it could be

  /icons/ps.gif

or

  /icons/unknown.gif

(Note that these are indeed meaningful settings with any default
Apache installation, because Apache has a lot of icons included.
See the file icons/README from the Apache distribution.)

=item Regular Expression

This is a Perl Regular Expression which files must match in order
to be of this type. For example it could be

  \.ps$
  \.pdf$
  \.(?:ps|pdf)$
  .*

for PostScript files, PDF files, PostScript or PDF files or all files.
See L<perlre(3)> for details on Perl's regular expressions.

=back


=head1 MODIFYING THE EXPLORER

When modifying the explorer, you should know about the following
methods:


=head2 Initializing the Explorer

Probably any HTML page using the explorer system should contain
the following:

  <ep-package name=HTML::EP::Explorer accept="de,en">
  <ep-explorer-init noprefs=0>

The I<_ep_explorer_init> method is initializing the users cookie.
First it verifies, whether the user already has an explorer cookie
set. If not, the user will be redirected to the I<prefs.ep> page,
unless the attribute I<noprefs> is set. This page will allow him
to fix his personal settings and return to the calling page.

The explorer class is a subclass of both I<HTML::EP::Locale> and
I<HTML::EP::Session>. That means that the locale settings are
still valid in the I<ep-package> call (in particular the I<accept>
attribute that tells this page is ready for either german, aka de,
or english). Likewise the attributes of I<ep-session> are valid
in the I<ep-explorer-init> call. L<HTML::EP(3)>.
L<HTML::EP::Session(3)>.


=head2 Reading and/or writing the admin settings

Within F<admin/prefs.ep> and some other pages, you find the following
call:

  <ep-explorer-config file="config.pm" maysafe=0>

which read the admin settings from an external file, by default
F<config.pm>. The settings will instead be read from the CGI
input and saved into the same file, if the CGI variable I<save>
and the attribute I<maysafe> are true. (The latter should happen
within the F<amdin> dirctory only.)

The method will set the following EP variables:

=over

=item $config$

The config hash ref, as read from the file F<config.pm>.

=item $actions$

The list of actions. Shortcut for $config->actions$.
An action looks like

  { 'name' => 'Print to lp',
    'icon' => '/icons/lp.gif', # May be undef
    'script' => 'lpr -Plp -U $user $file'
  }

=item $directories$

The list of directories. Shortcut for
B<$self-E<gt>{'config'}-E<gt>{'directories'}>. A directory looks like

  { 'name' => 'Root directory',
    'dir' => '/'
  }

=item $filetypes$

The list of file types. Shortcut for
B<$self-E<gt>{'config'}-E<gt>{'filetypes'}>. A file type looks like

  { 'name' => 'PostScript files (*.ps)'
    'icon' => '/icons/ps.gif', # May be undef
    're' => '\.ps$'
  }

=item $num_directories$

The number of elements in B<$self-E<gt>{'directories'}>. May be 0.

=back


=head2 Reading and/or writing the users settings

The users settings can be read and/or written by calling

  <ep-explorer-prefs>

This will call I<_ep_explorer_init> internally, by setting the
I<noprefs> attribute to true. If either of the CGI variables
I<save> or I<save_and_return> is set, it will read the users
new settings from the CGI environment by running
B<$self-E<gt>ReadPrefs> and store the session (that is, return
a cookie) by calling I<ep-session-store>.

If the current oage is called from another page (that is, the
CGI variable I<return_to> is set to the calling page) and the
CGI variable I<save_and_return> is set, then the calling page
is included with I<ep-include>.


=head2 Setting the Explorers current directory

The method

  <ep-explorer-basedir>

will read the users current directory from the session or CGI
variable I<basedir>. The current directory will be compared
against the list of initial directories and the following
EP variables will be set:

=over

=item $basedir$

The selected current directory. If this is different from
B<$session->basedir> then the latter will be modified and
B<$modified$> will be set.

=item $in_top_dir$

True, if the current directory is one of the initial directories
or in F</>, False otherwise.

=item $in_base_dir$

If the current directory is below one of the initial directories,
then this variable will contain the associated element from the
directory list. That is $in_base_dir->name$ is set to the name
of this initial directory and $in_base_dir->dir$ the path.

Otherwise the variable is set to undef. If this is the case and
the administrator has set "Allow access outside initial directories"
to True, then a system error is triggered.

=item $display_dir$

If $in_base_dir$ is set, then this variable is set to the current
directories path, relative to the directory from $in_base_dir$.
For example, if you are in F</usr/local/bin> and the initial
directory is F</usr/local>, then the display directory is F</bin>.

=back


=head2 Setting the sorting mode

The method

  <ep-explorer-sortby>

attempts to guess the requested sorting mode from the CGI or
session variable I<sortby>. The guessed mode (by default I<name>)
will be stored in $sortby$. If this is different from $session->sortby$,
then the latter becomes set to the new value and $modified$ is set.


=head2 Setting the file type

The method

  <ep-explorer-filetype>

attempts to guess the file type that the user requests (That is,
whether the user wants to see only certain files.) by looking at
the CGI or session variable I<filetype>. By default the first
file type from the list $filetypes$ is choosen. If no list is set,
then all files become selected.

If a file type was choosen, the file type is stored in $filetype$.
and $filetype->selected$ is set to true. (Note, you must not call
I<ep-explorer-config> later!) If $filetype->name$ is different from
$session->filetype$, then the latter is modified and $modified$ is
set to true.


=head2 Creating the directory listing

The listing becomes created with

  <ep-set var=dir_template>
    <tr><td><!-- HTML code for listing a directory
    		 You may assume that $l$ is an instance of
                 HTML::EP::Explorer::Dir.
              -->
        </td></tr>
  </ep-set>
  <ep-set var=file_template>
    <tr><td><!-- HTML code for listing a file
    		 You may assume that $l$ is an instance of
                 HTML::EP::Explorer::File.
              -->
        </td></tr>
  </ep-set>
  <ep-explorer-browse basedir="$env->DOCUMENT_ROOT$" item=l>

The method is calling I<ep-explorer-basedir>, I<ep-explorer-filetype>
and I<ep-explorer-sortby> internally. Then a directory listing is
created and sorted, according to these methods results.

Finally, HTML code is generated for any item in the list by using
the templates $dir_template$ or $file_template$, depending on the
items type.


=head2 Performing an action

The method

  <p>I will execute the following command:</p>
  <pre>
    <ep-explorer-action action="myaction" file="myfile" execute=0>
  </pre>
  Here you can see the output:
  <pre>
    <ep-explorer-action action="myaction" file="myfile" execute=1>
  </pre>

performs an action, as requested by the user. The method is reading
an action name from the CGI variable I<faction> or the attribute
I<faction>. The corresponding action, if any, is stored in $action$.
If no action is found, a system error is triggered.

Then the method is looking for either of the CGI variable I<files>
or the attribute I<files>. If this is set, it is treated as a blank
separated list of file names. (Tab, Carriage return etc. are counting
as blanks.)

Otherwise the method expects a single file name in the CGI variable
I<file> or the attribute I<file>. If neither is set, a system error
is triggered.

If the attribute I<execute> is set to false, then no commands
are executed. Instead the method returns the commands being executed.
Otherwise the command is executed and the output returned.


=head1 AUTHOR AND COPYRIGHT

This module is

    Copyright (C) 1998-1999	Jochen Wiedmann
                          	Am Eisteich 9
                          	72555 Metzingen
                          	Germany

                          	Phone: +49 7123 14887
                          	Email: joe@ispsoft.de

All rights reserved.

You may distribute this module under the terms of either
the GNU General Public License or the Artistic License, as
specified in the Perl README file.


=head1 SEE ALSO

L<HTML::EP(3)>, L<HTML::EP::Session(3)>

=cut
