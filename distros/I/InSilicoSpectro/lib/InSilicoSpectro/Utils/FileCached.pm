use strict;

package InSilicoSpectro::Utils::FileCached;
require Exporter;
use Carp;

=head1 NAME

InSilicoSpectro::Utils::FileCached

=head1 SYNOPSIS


=head1 DESCRIPTION

Virtual class. for caching into files object and stored them into a LIFO queue


=head1 FUNCTIONS

=head3 queueSize(nbobj=>int)

Set the queue size in muber of object;

=head3 queueOverflow()

return true/false if the queue is overflowed (then the oldest one(s) must be ejected)

=head3 verbose([boolean])

get/set verbose mode

=head3 FC_tempdir()

get the temporary file (or create one on the first call)

=head3 queueDump()

dump on STDOUT the list of managed object in memory (not the persistent ones)

=head3 dump_all()

List all the object registered and if they are in file or memory. Report looks like

=begin verbatim

0       InSilicoSpectro::Spectra::MSSpectra     /tmp/File-Cached-SdcHzV/jINw2UcEwD.fccached
1       InSilicoSpectro::Spectra::MSSpectra     /tmp/File-Cached-SdcHzV/2cbf6OmXW2.fccached
2       InSilicoSpectro::Spectra::MSMSSpectra   in_mem
3       InSilicoSpectro::Spectra::MSSpectra     /tmp/File-Cached-SdcHzV/39pt9eatID.fccached
4       InSilicoSpectro::Spectra::MSSpectra     /tmp/File-Cached-SdcHzV/dxH7SET4LD.fccached
5       InSilicoSpectro::Spectra::MSSpectra     /tmp/File-Cached-SdcHzV/m7j9tNyzAl.fccached
6       InSilicoSpectro::Spectra::MSSpectra     /tmp/File-Cached-SdcHzV/X6k6VNsDV2.fccached
7       InSilicoSpectro::Spectra::MSSpectra     /tmp/File-Cached-SdcHzV/5vos3j9q7w.fccached
8       InSilicoSpectro::Spectra::MSSpectra     in_mem
9       InSilicoSpectro::Spectra::MSSpectra     in_mem
10      InSilicoSpectro::Spectra::MSSpectra     in_mem


=end verbatim

=head1 METHODS

=head3 $obj->FC_persistent([boolean]);

Get/set if the object is to be persistent (i.e. to be managed by the queue). Set persitency at new time

=head3 $obj->FC_save();

Serialize and save the object into a file.

=head3 $obj->FC_load();

Load object from the file, push it on the first position; remove file;

=head3 $obj->FC_file();

Get the file for the object (create on in the tempdir is none was defined);

=head3 $obj->FC_key();

returns the unique incremented key


=head3 $obj->FC_eject();

Get the object out from the queue, save it on the disk;

Empty the object but the FileCached attributes

=head3 $ojb->FC_refresh();

Push the object on the first position of the queue

=head3 $obj->FC_getme();

Returns myself + refresh


=head1 VARIABLES

=head3 REMOVE_TEMP_FILES=bool

set to true (default) to remove temporary files at the process end

=head3 QUEUE_MAX_LEN=int

Set the size for the queue of memory resident object (to be set before starting to instanciate objects)

=head1 EXAMPLES


=head1 SEE ALSO

=head1 COPYRIGHT

Copyright (C) 2004-2006  Geneva Bioinformatics www.genebio.com

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=head1 AUTHORS

Alexandre Masselot, www.genebio.com

=cut

use File::Temp qw /tempdir tempfile/;
use Data::Serializer;

our (@ISA, @EXPORT, @EXPORT_OK);
@ISA = qw(Exporter);

our $REMOVE_TEMP_FILES=1;
our $QUEUE_MAX_LEN=500;

@EXPORT = qw($REMOVE_TEMP_FILES $QUEUE_MAX_LEN &verbose &queueMaxSize &dump_all $keyCpt);
@EXPORT_OK = ();

our %key2queueEl;
our %serializeParams;#=(serializer=>'Data::Dumper');
our %dictionary;

our ($queueHead, $queueTail);
our $queueLen=0;

our $keyCpt=0;

our ($verbose, $tempDir);

sub new{
    my $pkg=shift;
    my %h=@_;
    my $self={
	      FC_key=>$keyCpt++,
	     };
    bless $self, $pkg;
    unless ($h{persistent}){
      $self->queueShift;
    }else{
      $self->FC_persistent(1);
    }
    $dictionary{$self->FC_key}=$self;
#     warn $dictionary{$self->FC_key}." == ".$self;
#     Carp::confess ("".$dictionary{$self->FC_key} eq "".$self) unless("".$dictionary{$self->FC_key} eq "".$self);
    return $self;
}


sub verbose{
  my $v=shift;
  if(defined $v){
    $verbose=$v;
  }
  return $v;
}

sub FC_tempdir{
  unless ($tempDir){
    $tempDir=tempdir(File::Spec->tmpdir()."/File-Cached-XXXXXX", CLEANUP=>$REMOVE_TEMP_FILES, UNLINK=>$REMOVE_TEMP_FILES);
    warn "tempdir=$tempDir" if $verbose;
  }
  return $tempDir;
}
sub FC_getme{
  my $self=shift;

  return $self if $self->FC_persistent;
  #warn "FC_getme\t".$self->FC_key."\t(".$self->FC_file.") [$self] \n" if $verbose;

  if($self->FC_file){
    $self->FC_load;
  }else{
    $self->FC_refresh;
  }
  return $self;
}

sub FC_save{
  my $self=shift;
  my ($fh, $fname)=tempfile(DIR=>FC_tempdir(), UNLINK=>$REMOVE_TEMP_FILES, SUFFIX=>".fccached");
  my $serializer = Data::Serializer->new(%serializeParams);
  $serializer->store($self, $fh);
  close $fh;
  $self->FC_file($fname);
  #warn "FC\t".$self->FC_key." [$self] save in $fname\n";

  foreach (keys %$self){
    next if /^FC_/;
    delete $self->{$_};
  }
}

sub FC_file{
  my $self=shift;
  if(exists $_[0]){
    $self->{FC_file}=shift;
  }
  return $self->{FC_file};
}

sub FC_persistent{
  my $self=shift;
  if(exists $_[0]){
    $self->{FC_persistent}=shift;
    if($self->{FC_persistent}){
      $self->queueRemove;
    }
  }
  return $self->{FC_persistent};
}

sub FC_key{
  my $self=shift;
  return $self->{FC_key};
}

sub FC_load{
  my $self=shift;
  my $fname=$self->FC_file or croak "cannot FC_load an object when file does not exits";
  my $serializer = Data::Serializer->new(%serializeParams);
  my $h=$serializer->retrieve($fname) or croak "could not retrieved from serialized file [$fname]: $!";
  foreach (keys %$h){
    $self->{$_}=$h->{$_};
  }
  #warn "FC\t".$self->FC_key." [$self] retrieved from $fname\n";
  #  TODO check if has side effect not to delete the file?
  #unlink $fname;
  delete $self->{FC_file};
  $self->queueShift;

}

sub FC_eject{
  my $self=shift;
  delete $queueTail->{prev}{next};
  delete $key2queueEl{$queueTail->{object}->FC_key};
  $queueTail->{object}->FC_save;
  $queueTail=$queueTail->{prev};
  delete $queueTail->{next};
  $queueLen--;
}

sub FC_refresh{
  my $self=shift;
  return if $queueHead->{object}->FC_key==$self->FC_key;
  if($self->FC_file){
    $self->FC_load;
  }else{
  
    my $qel=$key2queueEl{$self->FC_key};
    my $second=$queueHead;
    $qel->{prev}{next}= $qel->{next};
    $qel->{next}{prev}=$qel->{prev} if  $qel->{next};
    $queueTail=$qel->{prev} if $queueTail==$qel;

    $queueHead=$qel;
    # HEHEHE just commentedq
    #$self->queueShift;
    $queueHead->{next}=$second;
    $second->{prev}=$queueHead;
    $queueHead->{prev}=undef;
  
  }
}

#
sub queueShift{
  my $self=shift;
  my $h={
	 object=>$self,
	 prev=>undef,
	 next=>undef,
	};
  if( exists $key2queueEl{$self->FC_key}){
    Carp::cluck "[".$self->FC_key."] AREADY IN QUEUE!";
  }else{
    $key2queueEl{$self->FC_key}=$h;
    if ($queueHead){
      $queueHead->{prev}=$h;
      $h->{next}=$queueHead;
      $queueHead=$h;
    }else{
      $queueHead=$h;
      $queueTail=$h;
    }
    $dictionary{$self->FC_key}=$self;

    $queueLen++;
    if(queueOverflow()){
      warn "queueOverflow" if $verbose>2;
      $queueTail->{object}->FC_eject;
    }
  }
}

sub queueRemove{
  my $self=shift;
  if(exists $key2queueEl{$self->FC_key}){
    my $qel=$key2queueEl{$self->FC_key};
    $qel->{prev}{next}=$qel->{next} if $qel->{prev};
    $qel->{next}{prev}=$qel->{prev} if $qel->{next};
    $queueHead= $qel->{next} if($qel==$queueHead);
    $queueTail= $qel->{prev} if($qel==$queueTail);
    delete $qel->{prev};
    delete $qel->{next};
    delete $key2queueEl{$self->FC_key};
    $queueLen--;
  }

}

sub queueMaxSize{
  my %h=@_;
  if($h{nbobj}>0){
    $QUEUE_MAX_LEN=$h{nbobj};
  }
  return $QUEUE_MAX_LEN;
}

sub queueOverflow{
  return scalar(keys %key2queueEl)>$QUEUE_MAX_LEN;
}

sub queueDump{
  return unless $queueHead;
  print "queue len=$queueLen\n";
  my $qel=$queueHead;

  while ($qel){
    Carp::cluck unless $qel->{object};
    print $qel->{object}->FC_key;
    print "*" if $qel->{object}->FC_persistent;

    print "\t".ref($qel->{object})."\t".($qel->{prev} or 'NOPREV')."\t".($qel->{next} or 'NONEXT')."\t[".$qel->{object}->FC_persistent."]\n";
    $qel=$qel->{next};
  }
}

sub dump_all{
  foreach (sort {$a <=> $b} keys %dictionary){
    print "$_\t".$dictionary{$_}."\t".$dictionary{$_}->FC_key;
    print "*" if $dictionary{$_}->FC_persistent;
    print "\t".($dictionary{$_}->FC_file or "in_mem")."\n";
  }
}

return 1;
