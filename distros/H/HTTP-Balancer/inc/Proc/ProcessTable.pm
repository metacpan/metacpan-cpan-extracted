#line 1
package Proc::ProcessTable;

use 5.006;

use strict;
use Carp;
use Fcntl;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
    
);
$VERSION = '0.47';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
    if ($! =~ /Invalid/) {
        $AutoLoader::AUTOLOAD = $AUTOLOAD;
        goto &AutoLoader::AUTOLOAD;
    }
    else {
        croak "Your vendor has not defined Proc::ProcessTable macro $constname";
    }
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap Proc::ProcessTable $VERSION;

# Preloaded methods go here.
use Proc::ProcessTable::Process;
use File::Find;

my %TTYDEVS;
our $TTYDEVSFILE = "/tmp/TTYDEVS"; # Where we store the TTYDEVS hash

sub new 
{
  my ($this, %args) = @_;
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;

  mutex_new(1);
  if ( exists $args{cache_ttys} && $args{cache_ttys} == 1 )
  { 
    $self->{cache_ttys} = 1 
  }

  if ( exists $args{enable_ttys} && (! $args{enable_ttys}))
  {
    $self->{enable_ttys} = 0;
    if ($self->{'cache_ttys'}) {
      carp("cache_ttys specified with enable_ttys, cache_ttys a no-op");
    }
  }
  else
  {
    $self->{enable_ttys} = 1;
  }

  my $status = $self->initialize;
  mutex_new(0);
  if($status)
  {
    return $self; 
  }
  else
  {
    return undef;
  }
}

sub initialize 
{
  my ($self) = @_;

  if ($self->{enable_ttys})
  {

    # Get the mapping of TTYs to device nums
    # reading/writing the cache if we are caching
    if( $self->{cache_ttys} )
    {

      require Storable;

      if( -r $TTYDEVSFILE )
      {
        $_ = Storable::retrieve($TTYDEVSFILE);
        %Proc::ProcessTable::TTYDEVS = %$_;
      }
      else
      {
        $self->_get_tty_list;
        my $old_umask = umask;
        umask 022;

        sysopen( my $ttydevs_fh, $TTYDEVSFILE, O_WRONLY | O_EXCL | O_CREAT )
          or die "$TTYDEVSFILE was created by other process";
        Storable::store_fd( \%Proc::ProcessTable::TTYDEVS, $ttydevs_fh );
        close $ttydevs_fh;

        umask $old_umask;
      }
    }
    else
    {
      $self->_get_tty_list;
    }
  }

  # Call the os-specific initialization
  $self->_initialize_os;

  return 1; 
}

###############################################
# Generate a hash mapping TTY numbers to paths.
# This might be faster in Table.xs,
# but it's a lot more portable here
###############################################
sub _get_tty_list 
{
  my ($self) = @_;
  undef %Proc::ProcessTable::TTYDEVS;
  find({ wanted => 
       sub{
     $File::Find::prune = 1 if -d $_ && ! -x $_;
     my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
        $atime,$mtime,$ctime,$blksize,$blocks) = stat($File::Find::name);
     $Proc::ProcessTable::TTYDEVS{$rdev} = $File::Find::name
       if(-c $File::Find::name);
       }, no_chdir => 1},
       "/dev" 
      );
}

# Apparently needed for mod_perl
sub DESTROY {}

1;
__END__

#line 263


