#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/BufCa/RCS/BCFile.pm,v 7.10 2006/08/02 05:40:10 claude Exp claude $
#
# copyright (c) 2003-2006 Jeffrey I Cohen, all rights reserved, worldwide
#
#
use strict;
use warnings;

package Genezzo::BufCa::BCFile;

use IO::File;
use IO::Handle;
use Genezzo::BufCa::BufCa;
use Genezzo::Block::Util;
use Genezzo::Util;
use Carp;
use File::Spec;
use warnings::register;

our @ISA = qw(Genezzo::BufCa::BufCa) ;

# non-exported package globals go here

our $USE_MAX_FILES = 1; # true if fixed number of open files

# initialize package globals, first exported ones
#my $Var1   = '';
#my %Hashit = ();

# then the others (which are still accessible as $Some::Module::stuff)
#$stuff  = '';
#@more   = ();

# all file-scoped lexicals must be created before
# the functions below that use them.

# file-private lexicals go here
#my $priv_var    = '';
#my %secret_hash = ();
# here's a file-private function as a closure,
# callable as &$priv_func;  it cannot be prototyped.
#my $priv_func = sub {
    # stuff goes here.
#};

# make all your functions, whether exported or not;
# remember to put something interesting in the {} stubs
#sub func1      {print "hi";}    # no prototype
#sub func2()    {}    # proto'd void
#sub func3($$)  {}    # proto'd to 2 scalars
#sub func5      {print "ho";}    # no prototype

sub _init
{
    #whoami;
    #greet @_;
    my $self = shift;

    $self->{ __PACKAGE__ . ":FN_ARRAY" } = [];    
    $self->{ __PACKAGE__ . ":FN_HASH"  } = {};    
    $self->{ __PACKAGE__ . ":HITLIST"  } = {};    
    $self->{bc} = Genezzo::BufCa::BufCa->new(@_);
    $self->{cache_hits}   =  0;
    $self->{cache_misses} =  0;
    $self->{read_only}    =  0; # TODO: set for read-only database support

    $self->{open_list}    = [];

    return 1;
}

sub new 
{
    my $invocant = shift;
    my $class = ref($invocant) || $invocant ; 
    my $self = {};

#    whoami;

    my %args = (@_);

    return undef
        unless (_init($self,%args));

    if (exists($args{tsname}))
    {
        $self->{tsname} = $args{tsname};
    }

    return bless $self, $class;

} # end new

sub _get_fn_array
{
    my $self = shift;
    my $fn_arr = $self->{ __PACKAGE__ . ":FN_ARRAY" };
    my $fn_hsh = $self->{ __PACKAGE__ . ":FN_HASH" };
    return $fn_arr;
}
sub _get_fn_hash
{
    my $self = shift;
    my $fn_arr = $self->{ __PACKAGE__ . ":FN_ARRAY" };
    my $fn_hsh = $self->{ __PACKAGE__ . ":FN_HASH" };
    return $fn_hsh;
}

sub Dump
{
    whoami;
    my $self = shift;
    my $hitlist = $self->{ __PACKAGE__ . ":HITLIST"  };    

    my $fn_arr = $self->{ __PACKAGE__ . ":FN_ARRAY" };
    my $fn_hsh = $self->{ __PACKAGE__ . ":FN_HASH" };

    my %hashi = (bc => $self->{bc}->Dump(),
                 cache_hits   => $self->{cache_hits},
                 cache_misses => $self->{cache_misses},
                 hitlist      => scalar keys %{$hitlist},
#                 fileinfo     => $fn_arr
                 open_list    => $self->{open_list}
                 );

    if (exists($self->{tsname}))
    {
        $hashi{tsname} = $self->{tsname} 
    }

    return \%hashi;
}


sub Resize
{
#    whoami;
    my $self = shift;
    return 0
        unless ($self->Flush());
    my $stat = $self->{bc}->Resize(@_);
#    greet $stat;
    return $stat;
}

sub FileReg
{
    my $self = shift;

    local $Genezzo::Util::QUIETWHISPER = 1; # XXX: quiet the whispering

    whoami @_;

    my %required = (
                    FileName   => "no FileName !",
                    FileNumber => "no FileNumber !"
                    );
    
    my %args = (
                @_);

    return undef
        unless (Validate(\%args, \%required));

    my $fn_arr = $self->{ __PACKAGE__ . ":FN_ARRAY" };
    my $fn_hsh = $self->{ __PACKAGE__ . ":FN_HASH" };

    my $filename = File::Spec->rel2abs($args{FileName});

    # XXX: need a lock here for multithread
    unless (exists($fn_hsh->{$filename}))
    {
        # array of hashes of file info
        my %th;
        my @headerinfo;
        $th{name} = $filename;

        # XXX: open all handles for now
        $th{fh} = new IO::File "+<$th{name}"
            or die "Could not open $th{name} for writing : $! \n";

        @headerinfo = 
            Genezzo::Util::FileGetHeaderInfo(filehandle => $th{fh}, 
                                             filename   => $th{name});

#        greet @headerinfo;
        return undef
            unless (scalar(@headerinfo));
        $th{hdrsize} = $headerinfo[0];

        my $fileno = $args{FileNumber};

        if ($USE_MAX_FILES)
        {
            # close everything
            $th{fh}->close;
            delete $th{fh};
        }
        else
        {
            push @{$self->{open_list}}, $fileno; # open file list
        }
        
#        greet $fileno;

        # XXX: NOTE: treat filename array as 1 based, vs 0 based 
        # -- use fn_arr[n-1]->name to get filename.
        
        $fn_hsh->{$filename} = $fileno;            
        $fileno--;
        $fn_arr->[$fileno] = \%th;
    }   

    return ($fn_hsh->{$filename})
}

sub _getOpenFileHandle
{
    my $self = shift;
    my %required = (
                    filenum  => "no filenum !"
                    );

    my %optional = (getscalar => 0); # return fname, fh, fhdrsize by default

    my %args = (%optional,
                @_);

    return undef
        unless (Validate(\%args, \%required));

    my $fnum = $args{filenum};

    my $fn_arr = $self->{ __PACKAGE__ . ":FN_ARRAY" };

    # XXX: NOTE: treat filename array as 1 based, vs 0 based 
    # -- use fn_arr[n-1]->name to get filename.

    my $entry  = $fn_arr->[$fnum-1];

    my $fname  = $entry->{name};

    unless (exists($entry->{fh})
            && (defined($entry->{fh})))
    {

        whisper "re-open $fname\n";

        while ($USE_MAX_FILES)
        {
            my $num_open_files = scalar(@{$self->{open_list}});

            last
                if ($num_open_files < $Genezzo::Util::MAXOPENFILES);
#                if ($num_open_files < 2);

            # randomly close one of the open files -- remove it from
            # the open list
            my $close_victim = int(rand($num_open_files));
                
            my @foo = splice(@{$self->{open_list}}, $close_victim, 1);

            last
                unless (scalar(@foo));

            my $close_fnum = $foo[0];

            my $close_entry  = $fn_arr->[$close_fnum-1];

            whisper "close $close_entry->{name}\n";

            next
                unless (exists($close_entry->{fh})
                        && defined($close_entry->{fh}));
            my $close_fh     = $close_entry->{fh};

            if ($Genezzo::Util::USE_FSYNC)
            {
                whisper "failed to sync $fname"
                    unless ($close_fh->sync); # should be "0 but true"
            }
            $close_fh->close;
            delete $close_entry->{fh};

            last;
        } # end while

        $entry->{fh} = new IO::File "+<$fname"
            or die "Could not open $fname for writing : $! \n";

        push @{$self->{open_list}}, $fnum; # open file list
    }
    my $fh     = $entry->{fh};
    my $fhdrsz = $entry->{hdrsize};

    return $entry
        if $args{getscalar};

    return ($fname, $fh, $fhdrsz);
}

sub BCFileInfoByName
{
    my $self = shift;

    whoami @_;

    my %required = (
                    FileName   => "no FileName !"
                    );
    
    my %args = (
                @_);

    return undef
        unless (Validate(\%args, \%required));

    my $fn_hsh = $self->{ __PACKAGE__ . ":FN_HASH" };

    my $filename = File::Spec->rel2abs($args{FileName});

    return undef
        unless (exists($fn_hsh->{$filename}));

    my $fileno = $fn_hsh->{$filename};

    return ($self->_getOpenFileHandle(filenum => $fileno, getscalar => 1));
}

sub FileSetHeaderInfoByName
{
    my $self = shift;

    whoami @_;

    my %required = (
                    FileName   => "no FileName !",
                    newkey     => "no key!",
                    newval     => "no val!"
                    );
    
    my %args = (
                @_);

    return undef
        unless (Validate(\%args, \%required));

    my $filename = $args{FileName};
    my $newkey   = $args{newkey};
    my $newval   = $args{newval};

    my $file_info = $self->BCFileInfoByName(FileName => $filename);

    return undef
        unless (defined($file_info));

    my $fh = $file_info->{fh};

    return Genezzo::Util::FileSetHeaderInfo(
                                            filehandle => $fh,
                                            filename   => $filename,
                                            newkey     => $newkey,
                                            newval     => $newval
                                            );
    
}

sub _filereadblock
{
#    whoami;
    my ($self, $fname, $fnum, $fh, $bnum, $refbuf, $hdrsize) = @_;

#    greet $fname, $fnum, $fh, $bnum,  $hdrsize; 
    
    my $blocksize = $self->{bc}->{blocksize};

    $fh->sysseek (($hdrsize+($bnum * $blocksize)), 0 )
        or die "bad seek - file $fname : $fnum, block $bnum : $! \n";

    # HOOK: PRE SYSREAD BLOCK

    Genezzo::Util::gnz_read ($fh, $$refbuf, $blocksize)
        == $blocksize
            or die "bad read - file $fname : $fnum, block $bnum : $! \n";

    # HOOK: POST SYSREAD BLOCK

    if (1)
    {
        my @cksums = Genezzo::Block::Util::GetChecksums($refbuf, $blocksize);
        # test if the calculated checksum matches the stored checksum
        unless ((scalar(@cksums) == 2) &&
                ($cksums[0] == $cksums[1]))
        {
            # XXX XXX: need failure or repair procedure - warn about
            # problem but ignore for now
            my $w1 = "bad read - invalid checksum for file $fname : "
                     . "$fnum, block $bnum : $! \n";
            warn $w1;
        }

    }

    # HOOK: post filereadblock
    
    return (1);
             
}

#sub _init_filewriteblock
#{
#    my ($self, $fname, $fnum, $fh, $bnum, $refbuf, $hdrsize, $bce) = @_;
#
#    return 1 
#        unless (defined($bce));
#
#    whoami;
#
#    if (1) 
#    {
#        my $foo = $bce->GetContrib();
#        
#        return 1
#            unless (defined($foo));
#
#        if (exists($foo->{mailbox})
#            && exists($foo->{mailbox}->{'Genezzo::Block::RDBlock'}))
#        {
#            my $rdblock = $foo->{mailbox}->{'Genezzo::Block::RDBlock'};
#            greet $rdblock->_set_meta_row("BCE", ["BCE","howdy"]);
#        }
#    }
#    return 1;
#}

sub _filewriteblock
{
    my $self = shift;
    my ($fname, $fnum, $fh, $bnum, $refbuf, $hdrsize, $bce) = @_;

    return 0
        if ($self->{read_only});

    my $blocksize = $self->{bc}->{blocksize};

    $fh->sysseek (($hdrsize+($bnum * $blocksize)), 0 )
        or die "bad seek - file $fname : $fnum, block $bnum : $! \n";

    # HOOK: init filewriteblock
    # use sys_hook to define 
    if (defined(&_init_filewriteblock))
    {
        return 0
            unless (_init_filewriteblock($self, @_));
    }

    # update the block header with filenum, blocknum and 
    # set the footer checksum
    Genezzo::Block::Util::UpdateBlockHeader($fnum, $bnum, $refbuf, $blocksize);

    if (1)
    {
        Genezzo::Block::Util::UpdateBlockFooter($refbuf, $blocksize);
    }

    # HOOK: PRE SYSWRITE BLOCK

    gnz_write ($fh, $$refbuf,  $blocksize)
        == $blocksize
    or die "bad write - file $fname : $fnum, block $bnum : $! \n";

    # HOOK: POST SYSWRITE BLOCK

    return (1);
}

sub ReadBlock 
{
    my $self   = shift;

#    whoami @_;

    my %required = (
                    filenum  => "no filenum !",
                    blocknum => "no blocknum !"
                    );
                    
#    my %optional ;# XXX XXX XXX: dbh_ctx

    my %args = (
                @_);

    return undef
        unless (Validate(\%args, \%required));

    my $fn_arr = $self->{ __PACKAGE__ . ":FN_ARRAY" };
    my $fnum   =  $args{filenum};

    return undef
        unless (NumVal(
                       verbose => warnings::enabled(),
                       name => "filenum",
                       val => $fnum,
                       MIN => 0,
                       MAX => (scalar(@{$fn_arr}) + 1))) ;

    my $hitlist = $self->{ __PACKAGE__ . ":HITLIST"  };    
    my $bnum  = $args{blocknum};

    # cache hit
    if (exists($hitlist->{"FILE:" . "$fnum" . ":". "$bnum"}))
    {
#        whisper "hit!";
        $self->{cache_hits} +=  1;

        my $bcblocknum = $hitlist->{"FILE:" . "$fnum" . ":". "$bnum"};
        return $self->{bc}->ReadBlock(blocknum => $bcblocknum);
    }

    # miss
#    whisper "miss!";
    $self->{cache_misses} +=  1;

    my $thing = $self->{bc}->GetFree();

    unless (2 == scalar(@{$thing}))
    {
        whisper "no free blocks!";

        greet $hitlist;
        return undef;
    }
    
    my $bceref     = pop (@{$thing});
    my $bcblocknum = pop (@{$thing});

    my $bce = $$bceref;

    if (1) # need to clean the hitlist even if not dirty
    {
#        greet $hitlist;

        if (exists($hitlist->{"BC:" . "$bcblocknum"}))
        {
            my $fileinfo = $hitlist->{"BC:" . "$bcblocknum"};

            my ($ofnum, $obnum) = ($fileinfo =~ m/FILE:(\d.*):(\d.*)/);
#            greet $fileinfo, $ofnum, $obnum;
            delete $hitlist->{$fileinfo};
#            greet $hitlist;
            if ($bce->_dirty())
            {
                my ($ofname, $ofh, $ofhdrsz) = 
                    $self->_getOpenFileHandle(filenum => $ofnum);

                return (undef)
                    unless (
                            $self->_filewriteblock(
                                                   $ofname, 
                                                   $ofnum, 
                                                   $ofh, 
                                                   $obnum, 
                                                   $bce->{bigbuf},
                                                   $ofhdrsz,
                                                   $bce
                                                   )
                            );
            }
        }
    }

    my $fileinfo = "FILE:" . "$fnum" . ":". "$bnum";
    $hitlist->{$fileinfo}             = $bcblocknum;
    $hitlist->{"BC:" . "$bcblocknum"} = $fileinfo;

    # get the hash of bce information and update with filenum, blocknum
    my $infoh = $bce->GetContrib();

    # update the GetContrib *before* the fileread so locking code has some
    # place to look up the information
    $infoh->{filenum}  = $fnum;
    $infoh->{blocknum} = $bnum;

    $bce->_fileread(1);

    my ($fname, $fh, $fhdrsz) = $self->_getOpenFileHandle(filenum => $fnum);
    my $readstat =  $self->_filereadblock($fname, $fnum, $fh, $bnum, 
                                          $bce->{bigbuf}, $fhdrsz);
    $bce->_fileread(0);
    # new block is not dirty
    $bce->_dirty(0);

    # XXX XXX XXX: error -- need to clean the hitlist!!
    return (undef)
        unless ($readstat);

#    greet $hitlist;
    return $self->{bc}->ReadBlock(blocknum => $bcblocknum);
} # end ReadBlock


sub WriteBlock 
{
    my $self   = shift;

#    whoami @_;

    my %required = (
                    filenum  => "no filenum !",
                    blocknum => "no blocknum !"
                    );

#    my %optional ;# XXX XXX XXX: dbh_ctx

    my %args = (
                @_);

    return undef
        unless (Validate(\%args, \%required));

    my $fn_arr = $self->{ __PACKAGE__ . ":FN_ARRAY" };
    my $fnum   =  $args{filenum};

    return undef
        unless (NumVal(
                       verbose => warnings::enabled(),
                       name => "filenum",
                       val => $fnum,
                       MIN => 0,
                       MAX => (scalar(@{$fn_arr}) + 1))) ;

    my $hitlist = $self->{ __PACKAGE__ . ":HITLIST"  };    
    my $bnum  = $args{blocknum};

    return 1
        unless (exists($hitlist->{"FILE:" . "$fnum" . ":". "$bnum"}));
    # cache hit

    my $bcblocknum = $hitlist->{"FILE:" . "$fnum" . ":". "$bnum"};
    my $bceref =  $self->{bc}->ReadBlock(blocknum => $bcblocknum);
    my $bce = $$bceref;

    if ($bce->_dirty())
    {
        my ($fname, $fh, $fhdrsz) = 
            $self->_getOpenFileHandle(filenum => $fnum);

        return (0)
            unless (
                    $self->_filewriteblock($fname, $fnum, $fh, $bnum, 
                                           $bce->{bigbuf}, $fhdrsz, $bce)
                    );
    }
    $bce->_dirty(0);

    return 1;

} # end WriteBlock

sub Flush 
{
    my $self   = shift;

    whoami;

    my $hitlist = $self->{ __PACKAGE__ . ":HITLIST"  };    
    my $fn_arr  = $self->{ __PACKAGE__ . ":FN_ARRAY" };

    unless ($Genezzo::Util::USE_FSYNC)
    {
        # Win32 problem:
        # no fsync, so have to autoflush everything, which may be much
        # more inefficient.
        for my $th (@{$fn_arr})
        {
            if (exists($th->{fh})
                && defined($th->{fh}))
            {
                $th->{fh}->autoflush(1);
            }
        }
    }

    my %sync_list;

    # HOOK: PRE FLUSH BCFILE

    while (my ($kk, $vv) = each (%{$hitlist}))
    {
        next if ($kk !~ /^FILE/);

        my ($fnum, $bnum) = ($kk =~ m/FILE:(\d.*):(\d.*)/);

        my $bceref =  $self->{bc}->ReadBlock(blocknum => $vv);
        my $bce = $$bceref;

        if ($bce->_dirty())
        {
            my ($fname, $fh, $fhdrsz) = 
                $self->_getOpenFileHandle(filenum => $fnum);

            $sync_list{$fnum} = 1;

            whisper "write dirty block : $fname - $fnum : $bnum";

            return (0)
                unless (
                        $self->_filewriteblock($fname, $fnum, $fh, $bnum, 
                                               $bce->{bigbuf}, $fhdrsz, $bce)
                        );
        }
        $bce->_dirty(0);
    }


    if ($Genezzo::Util::USE_FSYNC)
    {
##        print "\nsync here!\n";
        
        for my $fnum (keys (%sync_list))
        {
            # sync the file handles - normally, can bcfile can buffer
            # writes, but in this case we want to assure they get written
            # before commit
            #
            # Note: sync is an IO::Handle method inherited by IO::File
            my ($fname, $fh, $fhdrsz) = 
                $self->_getOpenFileHandle(filenum => $fnum);

            whisper "failed to sync $fname"
                unless ($fh->sync); # should be "0 but true"
        }
    }
    else
    {
##        print "\nno sync here!\n";
        # Win32 problem:
        # cleanup the autoflush
        for my $th (@{$fn_arr})
        {
            if (exists($th->{fh})
                && defined($th->{fh}))
            {
                $th->{fh}->autoflush(0);
            }
        }

            
    }

    # HOOK: POST FLUSH BCFILE

    return 1;
#    greet $hitlist;
    
} # end flush

sub Rollback 
{
    my $self   = shift;

    whoami;

    my $hitlist = $self->{ __PACKAGE__ . ":HITLIST"  };    
    my $fn_arr  = $self->{ __PACKAGE__ . ":FN_ARRAY" };

    # HOOK: PRE ROLLBACK BCFILE

    while (my ($kk, $vv) = each (%{$hitlist}))
    {
        next if ($kk !~ /^FILE/);

        my ($fnum, $bnum) = ($kk =~ m/FILE:(\d.*):(\d.*)/);

        my $bceref =  $self->{bc}->ReadBlock(blocknum => $vv);
        my $bce = $$bceref;

        if ($bce->_dirty())
        {
            my ($fname, $fh, $fhdrsz) = 
                $self->_getOpenFileHandle(filenum => $fnum);

            whisper "replace dirty block : $fname - $fnum : $bnum";

            $bce->_dirty(0);

            return (0)
                unless (
                        $self->_filereadblock($fname, $fnum, $fh, $bnum, 
                                              $bce->{bigbuf}, $fhdrsz)
                        );
        }
    }

    # HOOK: POST ROLLBACK BCFILE

    return 1;
#    greet $hitlist;
    
}

sub BCGrowFile
{
    whoami;
    my ($self, $filenumber, $startblock, $numblocks) = @_;

    my $fnum      = $filenumber;
    my $fn_arr    = $self->{ __PACKAGE__ . ":FN_ARRAY" };
    my $blocksize = $self->{bc}->{blocksize};

    my ($fname, $fh, $fhdrsz) = 
        $self->_getOpenFileHandle(filenum => $fnum);
 
    my $packstr  = "\0" x $blocksize ; # fill with nulls

    my @outi;

    push @outi, $startblock;

    for my $ii (0..($numblocks - 1))
    {
        my $bnum = $startblock + $ii;
#        greet "new block $bnum";
        return @outi
            unless (
                    $self->_filewriteblock($fname, $fnum, $fh, $bnum, 
                                           \$packstr, $fhdrsz)
                    );
        $outi[1] = $ii + 1; # number of blocks added
    }
    return @outi; # starting block number, number of new blocks
}

sub DESTROY
{
    my $self   = shift;
#    whoami;

    if (exists($self->{bc}))
    {
        $self->{bc} = ();
    }

}

END { }       # module clean-up code here (global destructor)

## YOUR CODE GOES HERE

1;  # don't forget to return a true value from the file

=head1 NAME

 Genezzo::BufCa::BCFile.pm - A simple in-memory buffer cache for 
 multiple files for a single process, without locking.    

=head1 SYNOPSIS

 use Genezzo::BufCa::BCFile;
 
 # get a buffer cache
 my $bc = Genezzo::BufCa::BCFile->new(blocksize => 10, numblocks => 5);

 # register a file
 my $fileno = Genezzo::BufCa::BCFile->FileReg(FileName => 'file.dat');

 # get back some block 
 $bceref = $bc->ReadBlock(filenum  => $fileno,
                          blocknum => $blocknum);
 $bce = $$bceref;

=head1 DESCRIPTION

 The file buffer cache is a simple module designed to form the
 basis of a more complicated multi-process buffer cache
 with locking.  The buffer cache contains a number of Buffer Cache
 Elements (BCEs), a special wrapper class for simple byte buffers
 (blocks).  See L<Genezzo::BufCa::BufCa>.

 Note that this module does not perform space management or allocation 
 within the files -- it only reads and writes the blocks.  The caller
 is responsible for managing the contents of the file.
 
=head1 FUNCTIONS
  
=over 4

=item new

 Takes arguments blocksize (required, in bytes), numblocks (10 by
 default).  Returns a new buffer cache of the specified number of
 blocks of size blocksize.

=item BCFileInfoByName
 Return the file state information.

=item FileSetHeaderInfoByName
 Update the datafile header.

=item FileReg

 Register a file with the cache -- returns a file number.  Reregistering
 a file should return the same number.

=item ReadBlock  

 Takes argument blocknum, which must be a valid block number, and
 the argument filenum, which must be a valid file number.  If the
 block is in memory it returns the bceref.  If the block is not in
 the cache it fetches it from disk into an unused block.  If the 
 unused block is dirty, then ReadBlock writes it out first.  
 Fails if all blocks are in use.

=item WriteBlock 

 Write a block to disk.  Not really necessary -- ReadBlock will
 flush some dirty blocks to disk automatically, and Flush
 will write all dirty blocks to disk.  

=item Flush

 Write all dirty blocks to disk.

=item Rollback

 Discard all dirty blocks and replace with blocks from disk..

=back

=head2 EXPORT

 None by default.

=head1 LIMITATIONS

Currently requires 2 blocks per open file.

=head1 TODO

=over 4

=item  note that _fileread could just be part of GetContrib

=item  need to move TSExtendFile functionality here if want to overload
       syswrite with encryption

=item  read_only database support

=item  buffer cache block zero should contain description of buffer cache 
       layout

=item  need a way to free blocks associated with a file that is not
       currently in use

=back


=head1 AUTHOR

 Jeffrey I. Cohen, jcohen@genezzo.com

=head1 SEE ALSO

perl(1).

Copyright (c) 2003-2006 Jeffrey I Cohen.  All rights reserved.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

Address bug reports and comments to: jcohen@genezzo.com

For more information, please visit the Genezzo homepage 
at L<http://www.genezzo.com>

=cut
