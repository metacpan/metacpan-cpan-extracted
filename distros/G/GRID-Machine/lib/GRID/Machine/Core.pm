use strict;
use warnings;
use File::Temp;
use File::Spec;

sub getcwd { return getcwd() }

sub getpid #gm ( filter => 'result')
{
  $$;
}

sub chdir  { 
 my $dir = shift || $ENV{HOME};
 return chdir($dir) 
}

sub unlink  { 
 my @files = @_;

 return unless @files;
 return unlink(@files) 
}

sub mark_as_clean {
  my %arg = @_;
  my $files = $arg{files} || [];
  my $dirs  = $arg{dirs} || [];

  if (@$files) {
    # make them absolute paths
    my @absfiles = map { abs_path($_) } @$files;
    push @{SERVER()->cleanfiles}, @absfiles;
  }
  if (@$dirs) {
    my @absdirs = map { abs_path($_) } @$dirs;
    push @{SERVER()->cleandirs}, @absdirs;
  }
}

sub wrapexec {
  my $exec = shift;

  my $dir = getcwd;
  my $program =<< 'EOPROG'; 
chdir "<<$dir>>" || die "Can't change to dir <<$dir>>\n";
%ENV = (<<$ENV>>);
$| = 1;
my $success = !system("<<$exec>>");
warn "GRID::Machine::Core::wrapexec warning!. Execution of '<<$exec>>' returned Status: '$?'. Success value from system call: '$success'\n" unless $success;
unlink('<<$scriptname>>');
exit(0);
EOPROG

  $exec =~ /^\s*(\S+)/; # mmm.. no options?
  my $execname = $1;
  # Executable can be in any place of the PATH search 
  my $where = `which $execname 2>&1`;

  # skip if program 'which' can't be found otherwise check that $execname exists
  unless ($?) {
    die "Error. Can't find executable for command '$execname'. Where: '$where'\n" unless  $execname && $where =~ /\S/;
  }

  # name without path
  my ($name) = $execname =~ m{([\w.]+)$};
  $name ||= '';

  my $ENV = "'".(join "',\n  '", %ENV)."'";

  # Create a temp perl script with pattern /tmp/gridmachine_driver_${name}XXXXX
  my $filename = "gridmachine_driver_${name}";
  my $tmp = File::Temp->new( TEMPLATE => $filename.'XXXXX', DIR => File::Spec->tmpdir(), UNLINK => 0);
  my $scriptname = $tmp->filename;

  $program =~ s/<<\$dir>>/$dir/g;
  $program =~ s/<<\$ENV>>/$ENV/g;
  $program =~ s/<<\$exec>>/$exec/g;
  $program =~ s/<<\$scriptname>>/$scriptname/g;

  print($tmp $program) or die "Can't create script $scriptname";

  #push @{SERVER->cleanfiles}, $scriptname; # unless shift();
  close($tmp) or die "Can't close file $scriptname";

  return $scriptname;
}

sub umask  { 
 my $umask = shift;
 return umask($umask) if defined($umask);
 return umask();
}

sub mkdir  { 
 my $dir = shift or die "mkdir needs an argument\n";
 my $mask = shift;
 return mkdir($dir) unless defined($mask);
 return mkdir($dir, $mask);
}

sub system {
  my $program = shift;

  my $r = CORE::system($program, @_);
  SERVER->remotelog("system '$program @_' executed \$?= $?, \$\@ = '$@', ! = '$!'");
  $r;
  #return $?
}

sub qqx {
  my $wantarray = shift,
  my $sep = shift;
  my $program = shift;

  local $/ = $sep;
  return `$program` if $wantarray;
  scalar(`$program`);
}


sub slurp {
  my $filename = shift;

  local $/ = undef;

  open(my $f, "<", $filename) or die "Can't find file '$filename'\n";

  return scalar(<$f>);
}

sub glob {
  my $spec = shift;

  return glob($spec);
}

sub tar {
  my $file = shift;
  my $options = shift;

  CORE::system('tar', $options, ,'-f', $file);
  return $?
}

sub uname {
  use POSIX;
  return POSIX::uname();
}

sub version {
  my $module = shift;
  my $out = `$^X -M$module -e 'print $module->VERSION'`;
}

sub installed {
  my $module = shift;

  !CORE::system("$^X -M$module -e 0");
}

sub _stat {
  my $filehandle = shift;
 
  return stat($filehandle) if defined($filehandle);
  return stat();
}

LOCAL {
  for (qw(r w e x z s f d  t T B M A C)) {
    SERVER->sub( "_$_" => qq{
        my \$file = shift;

        return -$_ \$file;
      }
    );
  }
}

__END__

