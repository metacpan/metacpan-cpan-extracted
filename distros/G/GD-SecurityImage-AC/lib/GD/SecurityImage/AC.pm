package GD::SecurityImage::AC;
# drop-in replacement for Authen::Captcha
use strict;
use vars qw($VERSION);
use GD::SecurityImage;
use Digest::MD5 qw(md5_hex);
use File::Spec;
use Fcntl qw(:flock); # imports LOCK_NB, LOCK_EX, LOCK_SH, LOCK_UN (among other things)
use Symbol; # imports 'gensym'

BEGIN {
   $VERSION = '1.11';
   @Authen::Captcha::ISA = ('GD::SecurityImage::AC');
}

sub new {
   my $class = shift;
   my %opts  = scalar(@_) % 2 ? () : (@_);
   my $self  = {
                  gdsi        => { 
                                  map {$_ => ''} qw[new create particle]
                  },
                  GDSI_CALLED => 0,
   };
   bless $self, $class;
   foreach my $name (qw[keep_failures data_folder output_folder]) {
      $self->{'_'.$name} = $opts{$name} if $opts{$name};
   }
   $self->{_debug}         = $opts{debug}         if defined $opts{debug};
   foreach my $p ([expire => 300], [width => 100], [height => 32]) {
      $self->{"_".$p->[0]} = $opts{$p->[0]} && ($opts{$p->[0]} !~ /[^0-9]/) ? $opts{$p->[0]} : $p->[1];
   }
   $self->{_keep_failures} = $opts{keep_failures} ? 1 : 0;
   srand( time() ^ ($$ + ($$ << 15)) ) if $] < 5.005; # create a random seed if perl version less than 5.005
   return $self;
}

sub _lock_ex { shift->_lock(&LOCK_EX); }
sub _lock_sh { shift->_lock(&LOCK_SH); }
sub _lock_un { shift->_lock(&LOCK_UN); }

sub _lock { # Non-blocking locking with a timeout
   my $self = shift;

   my ($lock_mode) = @_;

   my $lock_handle  = $self->_lock_handle;
   my $timeout      = 10; # seconds
   my $count_timer  = 10 * $timeout;
   my $lock_result;
   while (! ($lock_result = flock ($lock_handle, $lock_mode | &LOCK_NB))) {
      if (! $count_timer--) {
         my $package = __PACKAGE__;
         die("${package}::_lock() - Failed to obtain lock in $timeout seconds: $!");
      }
      # sleep for 1/10th of a second before trying again
      select (undef,undef,undef,0.1);
   }
   return;
}

sub _lock_handle { # returns an open filehandle to use for locking
   my $self = shift;

   my $lock_handle = $self->{'_lock_handle'};
   return $lock_handle if defined ($lock_handle);
   my $lock_file = $self->_lock_file;
   $lock_handle  = gensym;
   if (! open ($lock_handle,"+>$lock_file")) {
      my $package = __PACKAGE__;
      die("${package}::_lock_handle() - Unable to open '$lock_file' for locking: $!");
   }
   
   $self->{'_lock_handle'} = $lock_handle;
   return $lock_handle;
}

sub _lock_file { # Returns the lock file path
   my $self = shift;

   my $package = __PACKAGE__;
   my $lock_file = $self->{_lock_file};
   return $lock_file if (defined $lock_file);
   my $data_folder = $self->{_data_folder};
   unless (defined ($data_folder)) {
      die("${package}::_lock_file() - 'data_folder' is not set")
   }
   unless (-e $data_folder && -d _) {
      die("${package}::_lock_file() - '$data_folder' either does not exist or is not a directory")
   }
   $lock_file = File::Spec->catfile($data_folder,'codes.lck');
   $self->{_lock_file} = $lock_file;
   return $lock_file;
}

sub _untaint { # This doesn't make things safe. It just removes the taint flag. Use wisely.
   my ($value) = @_;
   my ($untainted_value) = $value =~ m/^(.*)$/s;
   return $untainted_value;
}

sub gdsi {
   my $self = shift;
   my %opt  = scalar(@_) % 2 ? () : (@_);
      $self->{gdsi}{'new'}    = delete $opt{'new'}    if ($opt{'new'}    && ref $opt{'new'}    && ref $opt{'new'}    eq 'HASH' );
      $self->{gdsi}{create}   = delete $opt{create}   if ($opt{create}   && ref $opt{create}   && ref $opt{create}   eq 'ARRAY');
      $self->{gdsi}{particle} = delete $opt{particle} if ($opt{particle} && ref $opt{particle} && ref $opt{particle} eq 'ARRAY');
      $self->{GDSI_CALLED} = 1;
      $self;
}

sub create_image_file {
   my $self = shift;
   my $code = shift;
   my $md5  = shift; # junk
   my $i    = GD::SecurityImage->new($self->{gdsi}{'new'} ? %{$self->{gdsi}{'new'}} : (
                  # defaults
                  width      => $self->{_width} < 60 ? 60 : $self->{_width},
                  height     => $self->{_height},
                  gd_font    => 'giant',
                  lines      => 2,
                  send_ctobg => 0,
   ),             rndmax     => 1);
   $i->random($code);
   $i->create($self->{gdsi}{create}
      ? @{ $self->{gdsi}{create} }
      : (normal => 'default', '#6C7186', '#917862')
   );
   die "Error loading ttf font for GD: $@" if $i->gdbox_empty;
   $i->particle(@{ $self->{gdsi}{particle} }) if $self->{gdsi}{particle};

   my @data = $i->out(force => 'png');
   return $data[0];
}

sub database_file {
   my $self = shift;
   my $file = File::Spec->catfile($self->{_data_folder},'codes.txt');
   unless(-e $file) { # create database file if it doesn't already exist
      local *DATA;
      open   DATA, '>>'.$file or die "Can't create File: $file\n";
      close  DATA;
   }
   return $file;
}

sub database_data {
   my $self = shift;
   my $db   = $self->database_file;
   local *DATA;
   open   DATA, '<'.$db  or die "Can't open $db for reading: $!\n";
   my @data = <DATA>;
   close  DATA;
   return @data;
}

sub _unlink {
   my $file = shift or return;
   if (-e $file && !-d _) {
      return unlink($file);
   }
   return 1; # resume on unexistent file
}

sub check_code {
   my $self   = shift;
   my $code   = shift;
   my $crypt  = shift;
   my $db     = $self->database_file;
     ($code   = lc $code) =~ tr/01/ol/;
   my $md5    = _untaint(md5_hex($code)); # remove 0-1
   my $now    = time;
   my $rvalue = 0;
   my $passed = 0;
   my $new    = ''; # saved entries
   my $found;

   # make taint happy
   local $ENV{'PATH'} = '';
   local $ENV{'ENV'} = '';
   local $ENV{'IFS'} = '';
   local $ENV{'CDPATH'} = '';
   local $ENV{'BASH_ENV'} = '';

   $self->_lock_ex;

   foreach my $line ($self->database_data) {
      chomp $line;
      my ($data_time, $data_code) = split /::/, $line;
      my $png_file = File::Spec->catfile($self->{_output_folder}, _untaint($data_code) . '.png');
      if ($data_code eq $crypt) { # the crypt was found in the database
         if (($now - $data_time) > $self->{_expire}) { 
            $rvalue = -1; # the crypt was found but has expired
         } else {
            $found = 1;
         }
         if ( ($md5 ne $crypt) && ($rvalue != -1) && $self->{_keep_failures}) { # solution was wrong, not expired, and we're keeping failures
            $new .= $line."\n";
         } else {
            _unlink($png_file) or die "Can't remove [$png_file]: $!\n"; # remove the found crypt so it can't be used again
         }
      } elsif (($now - $data_time) > $self->{_expire}) {
         _unlink($png_file) or die "Can't remove [$png_file]: $!\n"; # removed expired crypt
      } else {
         $new .= $line."\n"; # crypt not found or expired, keep it
      }
   }

   # update database
   local *DATA;
   open   DATA, '>'.$db  or die "Can't open $db for writing: $!\n";
   # Turn on autoflush for our output handle. I have seen rare cases where locking fails because of perl buffers without this.
   my $temp_fh = select(DATA); $| = 1; select($temp_fh);
   print  DATA $new;
   close  DATA;

   $self->_lock_un;

   if ($md5 eq $crypt) { # solution was correct
      if ($found) {
         $rvalue = 1;  # solution was correct and was found in database - passed
      } elsif (!$rvalue) {
         $rvalue = -2; # solution was not found in database
      }
   } else {
      $rvalue = -3; # incorrect solution
   }
   return $rvalue;
}

sub generate_code {
   my $self  = shift;
   my $len   = shift;
   my $code  = '';
      $code .= chr( int(rand 4) == 0 ? (int(rand 7)+50) : (int(rand 25)+97)) for 1..$len;
   my $md5   = _untaint(md5_hex($code));
   my $now   = time;
   my $new   = "";
   my $db    = $self->database_file;

   # make taint happy
   local $ENV{'PATH'} = '';
   local $ENV{'ENV'} = '';
   local $ENV{'IFS'} = '';
   local $ENV{'CDPATH'} = '';
   local $ENV{'BASH_ENV'} = '';

   $self->_lock_ex;

   foreach my $line ($self->database_data) { # clean expired codes and images
      chomp $line;
      my ($data_time, $data_code) = split /::/, $line;
      $data_code =~ m/^([a-fA-F0-9]+)$/;
      $data_code = $1 or die "Bad session key!";
      $data_time =~ m/^([0-9]+)$/s;
      $data_time = $1 or die "Bad timeout data!";
      if (($now - $data_time) > $self->{_expire} || $data_code eq $md5) {   # remove expired captcha, or a dup
         my $png_file = File::Spec->catfile($self->{_output_folder}, _untaint($data_code) . ".png");
         _unlink($png_file) or die "Can't remove png file [$png_file]\n";
      } else {
         $new .= $line."\n";
      }
   }

   # first, test if we can open all files
   my $file = File::Spec->catfile($self->{_output_folder},$md5 . '.png');
   local  *DATA;
   local  *FILE;
   open    FILE, '>'.$file or die "Can't open $file for writing: $!\n";
   open    DATA, '>'.$db   or die "Can't open $db   for writing: $!\n";

   # Turn on autoflush for our output handles. I have seen rare cases where locking fails because of perl buffers without this.
   my $temp_fh = select(DATA); $| = 1; select(FILE); $| = 1; select($temp_fh);

   # save image data
   binmode FILE;
   print   FILE $self->create_image_file($code, $md5);
   close   FILE;

   # save the code to database
   print   DATA $new, $now,"::",$md5,"\n";
   close   DATA;

   $self->_lock_un;

   return  wantarray ? ($md5, $code) : $md5;
}

sub output_folder { my ($self, $val) = @_; $self->{"_output_folder"} = $val if defined $val; return $self->{"_output_folder"}; }
sub images_folder { my ($self, $val) = @_; $self->{"_images_folder"} = $val if defined $val; return $self->{"_images_folder"}; }
sub data_folder   { my ($self, $val) = @_; $self->{"_data_folder"}   = $val if defined $val; return $self->{"_data_folder"};   }
sub debug         { my ($self, $val) = @_; $self->{"_debug"}         = $val if defined $val; return $self->{"_debug"};         }
sub expire        { my ($self, $val) = @_; $self->{"_expire"} =  $val if $val and $val >= 0; return $self->{"_expire"}; }
sub width         { my ($self, $val) = @_; $self->{"_width"} =   $val if $val and $val >= 0; return $self->{"_width"};  }
sub height        { my ($self, $val) = @_; $self->{"_height"} =  $val if $val and $val >= 0; return $self->{"_height"}; }
sub version       { return $VERSION; }
sub keep_failures { my ($self, $val) = @_; $self->{"_keep_failures"} = $val ? 1 : 0 if defined $val; return $self->{"_keep_failures"}; }
sub create_sound_file { return 'there is no such thing!'; }
sub type          { return 'image' }

1;
