package File::VMSVersions;

use 5.6.0;
use strict;
use warnings;

use IO::Handle;
use File::Basename;
use File::Spec::Functions;
use Carp;
use Fcntl qw(:DEFAULT :flock);
use Data::Dumper;

our $VERSION = '0.1';

my $vcfilename = '.vcntl';

=head1 NAME

File::VMSVersions - Perl extension for opening files in a directory with
                    VMS like versioning

=head1 SYNOPSIS

  use File::VMSVersions;

  my $vdir = File::VMSVersions->new(
     -name  => "./mydir",
     -mode  => 'versions',
     -limit => 3,
  );

  foreach my $i (1..6) {
     my($fh, $fn) = $vdir->open('bla.dat', '>');
     die $fn unless $fh;
     print $fh "file number $i\n";
     print "created $fn\n";
     $fh->close;
  }

Now you should have the following files in ./mydir:

  .vcntl
  bla.dat;lck
  bla.dat;4
  bla.dat;5
  bla.dat;6

=head1 DESCRIPTION

The B<File::VMSVersions> module was developed for maintaining automatic
versioning of files in a directory. When you are using the module's routines for
opening files, it will keep a configurable amount of old versions. The versions
will be identified by a number that is added at the end of the filename after a
semicolon (i. e. F<'myfile.dat;7'>).

The configured options for a directory are saved in the file F<'.vcntl'>. They
are read each time the B<open> method is called and written when the B<new>
constructor or the B<config> method are called with according options.

F<'.vcntl'> consists of only one line with limit and mode separated by an '#'.
For example:

  20#days

  10#versions

It is ok to edit F<'.vcntl'> manually

=cut

=head1 CONSTRUCTOR

To create a new B<File::VMSVersions> call the B<new> contructor

   $obj = File::VMSVersions->new(
        -name  => <directory name>,
      [ -mode  => <'versions'|'days'>,
        -limit => <version limit>, ]
   );

You have to specify both B<-limit> and B<-mode> or none of them. If both
evaluate to false the file F<.vcntl> is read. Otherwise it will be replaced with
the new values. If the file doesn't exist when the configuration is read, there
is no version limit at all.

=cut

sub new {
   my($caller) = shift;
   my($class)  = ref($caller) || $caller;

   my %cfg = @_;

   $cfg{-name} or
      croak << '      END';
         usage: File::VMSVersions->new(
             -name  => <dirname>,
            [-mode  => <"days"|"versions">,
             -limit => <versionlimit>,]
         );
      END

   if ($cfg{-mode} xor $cfg{-limit}) {
      $cfg{-mode} ?
      croak("-limit not specified") :
      croak("-mode not specified");
   }

   %cfg = _config(%cfg);

   return(bless(\%cfg, $class));
}


=head1 METHODS

=over 4

=item B<<< $obj->open(<filename> [, <mode:'<|>|>>']> [, <version>]) >>>

Opens a version of a file. The default mode is '<' (read).

If version is not specified when reading, the last version will be opened.

If mode equals '>' (write) or '>>' (append), the specified version of the
desired file will be created or appended (append will create a new file if the
version doesn't exist).

If there is no version specified, the highest existing version will be
incremented by 1.

If the specified version is negative the nth last version will be opened.

B<open> returns a list with an indirect filehandle and the filename. On errors
the filehandle is undefined and the filename contains an error message.

=cut

sub open {
   my($self)            = shift;
   my($fn, $mode, $ver) = @_;

   $mode ||= '<';
   croak("illegal mode '$mode'") unless $mode =~ /^<|>|>>$/;

   $ver  ||= 0;

   my $fullfn = catfile($self->{-name}, $fn);

   # waiting for lock on lockfile in write mode
   my $lck;
   if ($mode =~ />/) {
      $lck = _getlock("$fullfn;lck");
   }

   # get version info
   my $info = $self->info($fn);

   my $purge = 0;

   if ($mode eq '>') {

      # negative versions in write mode make no sense
      # increase version anyway (like VMS)
      $ver = $info->{max} + 1 if $ver <= 0;
      $purge = 1;

   } else {
      if ($ver) {
         if ($ver > 0) {
            # ver too small -> set to minimum
            $ver = $info->{min} if $ver < $info->{min};
         } else {
            # get the desired version with negative array index
            $ver = $info->{$self->{-mode}}->[$ver-1];
            return(undef, "version >>$ver<< not found") unless defined($ver);
         }
         if ( !exists($info->{$ver}) and $mode eq '>>') {
            $purge = 1;
         }
      } else {
         $ver = $info->{max};
      }
   }

   CORE::open(my $fh, $mode, "$fullfn;$ver") or
      return(undef, "error opening $fullfn version $ver in mode $mode, $!");

   $self->purge($fn, $self->config()) if $purge;

   # releasing lock
   $lck->close if $lck;

   return($fh, "$fullfn;$ver");
}


=item B<<< $obj->purge(<filename>, [-mode => <mode>, -limit => <limit>] >>>

purges the versions of a file to the specified limit. When limit and mode are
not specified all but the last versions are purged. There is no need to call
B<purge> for normal versioning.

=cut

sub purge {
   my($self) = shift;
   my($fn, %cfg) = @_;

   croak("purge: no filename specified") unless $fn;

   my $fullfn = catfile($self->{-name}, $fn);

   if ($cfg{-mode} xor $cfg{-limit}) {
      $cfg{-mode} ?
      croak("-limit not specified") :
      croak("-mode not specified");
   }

   ($cfg{-limit}, $cfg{-mode}) = (1, 'versions') unless $cfg{-mode};

   my $info = $self->info($fn);

   print Dumper($info);
   print Dumper($self);
   print Dumper(\%cfg);

   foreach my $v ( @{$info->{$self->{-mode}}} ) {

      if ($cfg{-mode} eq 'versions') {

         last if ( $info->{count} <= $cfg{-limit} );

         if ( unlink("$fullfn;$v") ) {
            delete($info->{$v});
         } else {
            carp("couldn't purge $fullfn;$v");
         }

         $info->{count}--;

      } else {

         if ( $info->{$v} - $info->{d_max} > $cfg{-limit} ) {
            if ( unlink("$fullfn;$v") ) {
               delete($info->{$v});
            } else {
               carp("couldn't purge $fullfn;$v");
            }
         }

      }
   }
}


=item B<<< $obj->config([-mode => <mode>, -limit => <limit>]) >>>

Sets and/or returns limit and mode of the directory

=cut

sub config {
   my $self = shift;

   my %cfg = @_;

   if ($cfg{-limit} xor $cfg{-mode}) {
      croak('please specify both -limit and -mode or none of them!');
   }

   $cfg{-name} = $self->{-name};

   return(_config(%cfg));
}


sub _config {
   my(%cfg) = @_;

   my $vfn = catfile($cfg{-name}, $vcfilename);

   if ( $cfg{-limit} ) {

      croak("illegal mode >>$cfg{-mode}<<")   unless $cfg{-mode}  =~ /^days|versions$/;
      croak("illegal limit >>$cfg{-limit}<<") unless $cfg{-limit} =~ /^\d+$/;

      CORE::open(my $vfh, ">", $vfn) or croak("could not write $vfn, $!");
      print $vfh join('#', $cfg{-limit}, $cfg{-mode});
      $vfh->close;

   } else {

      if ( -f $vfn ) {
         CORE::open(my $vfh, "<", $vfn) or croak("couldn't read $vfn, $!");
         ( $cfg{-limit}, $cfg{-mode} ) = split(/#/, <$vfh>);
         $vfh->close;

         croak("illegal mode >>$cfg{-mode}<< from $vfn")
            unless $cfg{-mode}  =~ /^days|versions$/;
         croak("illegal limit >>$cfg{-limit}<< from $vfn")
            unless $cfg{-limit} =~ /^\d+$/;

      } else {
         ( $cfg{-limit}, $cfg{-mode} ) = (999999999999999, 'versions');
      }

   }

   return(%cfg);
}


=item B<<< $obj->info(<filename>) >>>

returns a hashref with version information for <filename>

=cut

sub info {
   my($self) = shift;
   my($fn)   = @_;

   $fn or croak "usage: info(<filename>)";

   my $fullfn = catfile($self->{-name}, $fn);

   my(%info, @tmp, $ver);

   foreach my $f (glob("$fullfn;*")) {
      $ver  = (split(/;/, $f))[-1];
      next unless $ver =~ /^\d+$/;
      $info{$ver} = -M $f;
   }

   @tmp = sort {$a <=> $b} keys(%info);
   $info{versions} = [@tmp];
   $info{count}    = @tmp;
   $info{min}      = $tmp[0]  || 0;
   $info{max}      = $tmp[-1] || 0;
   @tmp = sort {$info{$b} <=> $info{$a}} grep {/^\d+$/} keys(%info);
   $info{days}     = [@tmp];
   $info{d_min}    = $tmp[0]  ? $info{$tmp[0]}  : 0;
   $info{d_max}    = $tmp[-1] ? $info{$tmp[-1]} : 0;

   return(\%info);
}


sub _getlock {
   my($fn) = @_;

   my $mode = -e $fn ? '<' : '>';
   CORE::open(my $lck, $mode, $fn) or croak "couldn't open lock file $fn, $!";

   unless (flock($lck, LOCK_EX | LOCK_NB)) {
      flock($lck, LOCK_EX);
   }

   return($lck);
}


=head1 AUTHOR

Thomas Kratz, E<lt>ThomasKratz@web.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Thomas Kratz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
