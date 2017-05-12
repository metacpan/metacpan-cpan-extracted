#
# copyright (c) 2005, Eric Rollins, all rights reserved, worldwide
#
#

package Genezzo::Contrib::Clustered;

#use 5.008004;
use strict;
use warnings;
use Genezzo::Util;
use Genezzo::Block::Util;
use Genezzo::Contrib::Clustered::GLock::GTXLock;
use Genezzo::Contrib::Clustered::GLock::GLock;
use Data::Dumper;
use FreezeThaw;
use IO::File;
use Genezzo::Block::RDBlock;
use warnings::register;
use Carp qw(:DEFAULT cluck);

our $VERSION = '0.34';

our $ReadBlock_Hook;
our $DirtyBlock_Hook;
our $Commit_Hook;
our $Rollback_Hook;
our $Execute_Hook;

# Constant blocks. 
our $COMMITTED_BUFF;
our $ROLLEDBACK_BUFF;
our $PENDING_BUFF;
our $CLEAR_BUFF;

our $COMMITTED_CODE;
our $ROLLEDBACK_CODE;
our $PENDING_CODE;
our $CLEAR_CODE;

our $UNDO_BLOCKSIZE;

# Can be set externally for testing.
our $starting_pid;
# If true pad out undo blocks to only fit two rows per block.
our $pad_undo;

####################################################################
# Called by BufCa::BCFile::_filewriteblock.
# Sets proc_num in block.
sub _init_filewriteblock
{
    my $self = shift;
    if(!defined($self->{MARK})){cluck("missing MARK");}

    my $cl_ctx = $self->{cl_ctx};
    my ($wrapped_self, $fname, $fnum, $fh, $bnum, $refbuf, $hdrsize, 
	$bce) = @_;

    if(!defined($self->{init_done}) || !$self->{init_done}){
        $self->_init();
    }

    return 1
        unless (defined($bce));

    my $bceInfo = $bce->GetInfo();

    return 1
	unless (defined($bceInfo));

    if (exists($bceInfo->{mailbox})
	&& exists($bceInfo->{mailbox}->{'Genezzo::Block::RDBlock'}))
    {
	my $rdblock = $bceInfo->{mailbox}->{'Genezzo::Block::RDBlock'};
	$rdblock->_set_meta_row("PID", [$cl_ctx->{proc_num}]);
    }

    return 1;
}

####################################################################
# Replaces Genezzo::BufCa::BCFile::_filereadblock.
sub ReadBlock
{
    my $self = shift;
    if(!defined($self->{MARK})){cluck("missing MARK");}
    my ($wrapped_self, $fname, $fnum, $fh, $bnum, $refbuf_in, $hdrsize) = @_;

    whisper "Genezzo::Contrib::Clustered::ReadBlock(filenum => $fnum, blocknum => $bnum)\n";
    #print STDERR "Genezzo::Contrib::Clustered::ReadBlock(filenum => $fnum, blocknum => $bnum)\n";

    if(!defined($self->{init_done}) || !$self->{init_done}){
        $self->_init();
    }

    my $gtxLock = $self->{cl_ctx}->{gtxLock};
    # Add in fnum later...
    $gtxLock->lock(lock => $bnum, shared => 1);
    
    # Avoid processing DirtyBlock during read.
    $self->{inReadBlock} = 1;

    my ($block_pid, $refbuf, $blocksize) = 
	$self->GetBlockWithPID($fnum, $bnum);

    if(($block_pid != 0) && ($block_pid != $self->{cl_ctx}->{proc_num})){
	# Need to rollback or commit the block.
	# Promote lock to EX.
	$gtxLock->lock(lock => $bnum, shared => 0);

	my $block_tx_state = $ROLLEDBACK_CODE;

	if($block_pid != -1){
	    # We can read state unlocked, since if tx was in progress
	    # block would be locked (&& it is a single-char read).
	    my $block_tx_state = $self->ReadTransactionState($block_pid);
	}
	
	if(($block_tx_state eq $COMMITTED_CODE)||
	   ($block_tx_state eq $CLEAR_CODE))  # shouldn't have PID!
	{
	    $self->ClearPID($fnum, $bnum, $refbuf, $blocksize);
	    $self->ReadOrWriteBlock($fnum, $bnum, "WRITE_TAIL", $refbuf);
	    $self->ReadOrWriteBlock($fnum, $bnum, "WRITE", $refbuf);
	}else{
	    # ROLLEDBACK_CODE || PENDING_CODE
	    $refbuf = $self->CopyBlockToOrFromTail($fnum,$bnum,"FROM");
	}
    }

    my $ret = 1;
    # $ret = &$ReadBlock_Hook(@_);
    # For now we don't read (above) directly into $refbuf_in, as
    # I'm not sure if buf can be tied to RDBlock multiple times 
    # (in GetBlockWithPID).
    $$refbuf_in = $$refbuf;

    $self->{inReadBlock} = 0;

    return $ret;
}

####################################################################
# Wraps Genezzo::BufCa::DirtyScalar::STORE.
sub DirtyBlock
{
    my $self = shift;
    if(!defined($self->{MARK})){cluck("missing MARK");}
    my $cl_ctx = $self->{cl_ctx};

    my $h;
    my $dirty;

    if($_[0]->{bce}){
        $h = $_[0]->{bce}->GetInfo();
	# Can't rely on dirty to make decisions, since it is cleared 
	# whenever block is written out of buffer cache
	# (on cache full, sync, etc.).
        $dirty = $_[0]->{bce}->_dirty();
    }

    if(!defined($self->{init_done}) || !$self->{init_done}){
        $self->_init();
    }
 
    if(!$self->{inReadBlock} &&
       defined($h) && 
        ((!(defined($h->{filenum}))) || (!(defined($h->{blocknum})))))
    {
	# One cause is in-memory index initialization.
	# Dict::_loadDictMemStructs=>Index::btHash::STORE...
        #whisper 
	#    "G:C:C::DirtyBlock bad undefined ($self->{inReadBlock})\n";
	#cluck "bad undefined";
    }

    if(!$self->{inReadBlock} &&
       defined($h) && 
       defined($h->{filenum}) && defined($h->{blocknum}))
    {
        whisper "Genezzo::Contrib::Clustered::DirtyBlock(filenum => $h->{filenum}, blocknum => $h->{blocknum}, dirty => $dirty)\n";
	#print STDERR "Genezzo::Contrib::Clustered::DirtyBlock(filenum => $h->{filenum}, blocknum => $h->{blocknum}, dirty => $dirty)\n";

	my $blockKey = $h->{filenum} . "_" . $h->{blocknum};

        if(!defined($cl_ctx->{dirty_blocks}->{$blockKey})){
	    if(!($cl_ctx->{have_begin_trans})){
		$self->BeginTransaction();
		$cl_ctx->{have_begin_trans} = 1;
	    }

            whisper "adding blockKey $blockKey\n";
	    $cl_ctx->{dirty_blocks}->{$blockKey} = { f => $h->{filenum},
                                                     b => $h->{blocknum}};

            my $gtxLock = $cl_ctx->{gtxLock};
	    # add in fnum later...
	    $gtxLock->lock(lock => $h->{blocknum}, shared => 0);

	    $self->CopyBlockToOrFromTail($h->{filenum}, $h->{blocknum}, "TO");
	    $self->AddAndWriteUndo($h->{filenum}, $h->{blocknum});
        }
    }

    return &$DirtyBlock_Hook(@_);
}

####################################################################
# DOES NOT WORK; NOT CURRENTLY USED
# Called by BufCa::BufCaElt::_dirty
sub BufCaElt_DirtyBlock
{
    my $self = shift;
    if(!defined($self->{MARK})){cluck("missing MARK");}
    my $cl_ctx = $self->{cl_ctx};

    my $h;
    my $dirty;
    my $bce = shift;

    if($bce){
        $h = $bce->GetInfo();

	# Can't rely on dirty to make decisions, since it is cleared 
	# whenever block is written out of buffer cache
	# (on cache full, sync, etc.).
	$dirty = $bce->{dirty};

	if(!$dirty){
	    return;
	}
    }

    if(!defined($self->{init_done}) || !$self->{init_done}){
        $self->_init();
    }
 
    if(!$self->{inReadBlock} &&
       defined($h) && 
        ((!(defined($h->{filenum}))) || (!(defined($h->{blocknum})))))
    {
	# One cause is in-memory index initialization.
	# Dict::_loadDictMemStructs=>Index::btHash::STORE...
        #whisper 
	#    "G:C:C::DirtyBlock bad undefined ($self->{inReadBlock})\n";
	#cluck "bad undefined";
    }

    if(!$self->{inReadBlock} &&
       defined($h) && 
       defined($h->{filenum}) && defined($h->{blocknum}))
    {
        whisper "Genezzo::Contrib::Clustered::DirtyBlock(filenum => $h->{filenum}, blocknum => $h->{blocknum}, dirty => $dirty)\n";
	#print STDERR "Genezzo::Contrib::Clustered::DirtyBlock(filenum => $h->{filenum}, blocknum => $h->{blocknum}, dirty => $dirty)\n";

	my $blockKey = $h->{filenum} . "_" . $h->{blocknum};

        if(!defined($cl_ctx->{dirty_blocks}->{$blockKey})){
	    if(!($cl_ctx->{have_begin_trans})){
		$self->BeginTransaction();
		$cl_ctx->{have_begin_trans} = 1;
	    }

            whisper "adding blockKey $blockKey\n";
	    $cl_ctx->{dirty_blocks}->{$blockKey} = { f => $h->{filenum},
                                                     b => $h->{blocknum}};

            my $gtxLock = $cl_ctx->{gtxLock};
	    # add in fnum later...
	    $gtxLock->lock(lock => $h->{blocknum}, shared => 0);

	    $self->CopyBlockToOrFromTail($h->{filenum}, $h->{blocknum}, "TO");
	    $self->AddAndWriteUndo($h->{filenum}, $h->{blocknum});
        }
    }
}

####################################################################
sub ClearPID
{
    my ($self, $fnum, $bnum, $refbuf, $blocksize) = @_;
    if(!defined($self->{MARK})){cluck("missing MARK");}

    if(!$self->VerifyChecksum($refbuf, $blocksize)){
	return;  # Don't mess with corrupted block.
    }

    my %tied_hash = ();
    my $tie_val =
        tie %tied_hash, 'Genezzo::Block::RDBlock', (refbufstr => $refbuf,
						    blocksize => $blocksize);
    $tie_val->_set_meta_row("PID", [0]);
    $self->UpdateChecksum($fnum, $bnum, $refbuf, $blocksize);
}

####################################################################
# Passed to ApplyFuncToUndo.
sub CommitFunc
{
    my ($self, $fileno, $blockno) = @_;
    if(!defined($self->{MARK})){cluck("missing MARK");}
    my $affected = 0;

    my $gtxLock = $self->{cl_ctx}->{gtxLock};  # Locks needed for startup case;
                                               # otherwise redundant.
    # Lock block SH.
    $gtxLock->lock(lock => $blockno, shared => 1); 

    my ($data_block_pid, $refbuf, $blocksize) = 
	$self->GetBlockWithPID($fileno, $blockno);

    if($data_block_pid == $self->{cl_ctx}->{proc_num})
    {
	# Only commit your own PID, as someone else (in crash case)
	# may have already recovered and used block.
	# Promote lock to EX.
	$gtxLock->lock(lock => $blockno, shared => 0);	    
	$self->ClearPID($fileno, $blockno, $refbuf, $blocksize);
	$self->ReadOrWriteBlock($fileno, $blockno, "WRITE_TAIL", $refbuf);
	$self->ReadOrWriteBlock($fileno, $blockno, "WRITE", $refbuf);
	$affected = 1;
    }elsif($data_block_pid == -1){
        # Promote lock to EX.
        $gtxLock->lock(lock => $blockno, shared => 0);
	# before-image should contain desired data
	$self->CopyBlockToOrFromTail($fileno,$blockno,"FROM");	
	$affected = 1;
    }

    # At startup could release each lock here.
    return $affected;
}

####################################################################
# Wraps Genezzo::GenDBI::Kgnz_Execute.
# Experimental; trying out catching deadlock error.
sub Execute
{
    my $self = shift;
    if(!defined($self->{MARK})){cluck("missing MARK");}
    my $ret;

    eval {
	$ret = &$Execute_Hook(@_);
    };

    if($@){
	if($@ =~ /DEADLOCK/){
	    print STDERR "ERROR:  Deadlock has occurred. Exiting...\n";
	    CORE::exit();
	}else{
	    die $@;
	}
    }

    return $ret;
}

####################################################################
# Wraps Genezzo::GenDBI::Kgnz_Commit.
sub Commit
{
    my $self = shift;
    if(!defined($self->{MARK})){cluck("missing MARK");}
    my $cl_ctx = $self->{cl_ctx};

    whisper "Genezzo::Contrib::Clustered::Commit()\n";

    my @tmpArgs = @_;
    my $wrapped_self = shift @tmpArgs;

    if(!defined($self->{init_done}) || !$self->{init_done}){
        $self->_init();
    }

    # Assume this writes all blocks in buffer cache to disk.
    my $ret = &$Commit_Hook(@_);

    $self->WriteTransactionState($COMMITTED_BUFF);

    # Could use $cl_ctx->{dirty_blocks} to find all affected blocks.
    # For Now use undo from disk.
    # Clear undo proc id in all blocks.
    $self->ApplyFuncToUndo(\&CommitFunc);

    # TODO: Release all blocks in buffer cache (how?).

    my $gtxLock = $self->{cl_ctx}->{gtxLock};
    # Current buffer cache doesn't release blocks on commit, so
    # demote instead of release all locks.
    # $gtxLock->unlockAll();
    $gtxLock->demoteAll();
    $cl_ctx->{dirty_blocks} = {};

    $self->ResetUndo();
    $self->WriteTransactionState($CLEAR_BUFF);
    $self->{cl_ctx}->{have_begin_trans} = 0;

    return $ret;
}

####################################################################
# Wraps Genezzo::GenDBI::Kgnz_Rollback.
sub Rollback
{
    my $self = shift;
    if(!defined($self->{MARK})){cluck("missing MARK");}
    my $cl_ctx = $self->{cl_ctx};

    whisper "Genezzo::Contrib::Clustered::Rollback()\n";

    my @tmpArgs = @_;
    my $wrapped_self = shift @tmpArgs;

    if(!defined($self->{init_done}) || !$self->{init_done}){
        $self->_init();
    }

    $self->WriteTransactionState($ROLLEDBACK_BUFF);

    $self->Rollback_Internal();

    $self->ResetUndo();
    $self->WriteTransactionState($CLEAR_BUFF);
    $cl_ctx->{have_begin_trans} = 0;

    my $gtxLock = $self->{cl_ctx}->{gtxLock};
    $gtxLock->unlockAll();
    $cl_ctx->{dirty_blocks} = {};

    my $ret = &$Rollback_Hook(@_);

    # We shouldn't be generating bogus undo anymore.  
    # Leave this in just in case.
    $self->ResetUndo();
    $self->WriteTransactionState($CLEAR_BUFF);
    $cl_ctx->{have_begin_trans} = 0;
    $cl_ctx->{dirty_blocks} = {};
    # We have accumulated more locks during the rollback.
    # These proctect the dictionary tables which were reloaded.
    # They also include block zero (directory & space management), etc.
    # TODO:  We can't free the locks, as the blocks would be unprotected.
    #$gtxLock->unlockAll();
    $gtxLock->demoteAll();

    return $ret;
}

####################################################################
# For each block in undo, for each row in block, apply func.
sub ApplyFuncToUndo
{
    my ($self, $func) = @_;
    if(!defined($self->{MARK})){cluck("missing MARK");}
    # func takes args of form:  my ($self, $fileno, $blockno) = @_;
    my $affected = 0;
    my $cl_ctx = $self->{cl_ctx};

    whisper "Genezzo::Contrib::Clustered::ApplyFuncToUndo()\n";
    # For each block in undo, for each row in block, apply func.
    my $undo_blockid;
    my $tx_id;

    for($undo_blockid = 0; 
	$undo_blockid < ($cl_ctx->{undoHeader}->{blocks_per_proc})/2;
	$undo_blockid++)
    {
        # TODO: Read both of paired undo blocks and choose good one.
        whisper 
	    "G:C:C:ApplyFuncToUndo undo_blockid = $undo_blockid\n";
	# utilize paired blocks later...
	my $offset = $undo_blockid * 2;
	
	my $blk = ($cl_ctx->{proc_undo_blocknum} + $offset)*$UNDO_BLOCKSIZE;
	$self->{undo_file}->sysseek($blk, 0)
	    or die "bad seek - file undo block $blk: $! \n";

	my $buff;

	Genezzo::Util::gnz_read ($self->{undo_file}, $buff, $UNDO_BLOCKSIZE)
	    == $UNDO_BLOCKSIZE
	    or die 
            "bad read - file undo : block $blk : $! \n";
    
	my %tied_hash = ();
	my $tie_val =
        tie %tied_hash, 'Genezzo::Block::RDBlock', (refbufstr => \$buff,
						    blocksize => 
						    $UNDO_BLOCKSIZE);

	my $frozen_row = $tied_hash{1}; 
	my ( $row ) = FreezeThaw::thaw $frozen_row;
	
	if($undo_blockid == 0){
	    $tx_id = $row->{tx};
	}else{
	    if($tx_id != $row->{tx}){
		last;
	    }
	}

	my $rownum = 2;

	while(1){
	    $frozen_row = $tied_hash{$rownum};

	    if(!defined($frozen_row)){
		last;
	    }

	    ( $row ) = FreezeThaw::thaw $frozen_row;

	    whisper 
		"G:C:C:ApplyFuncToUndo file ($row->{f}) block ($row->{b})\n";

	    # Apply func.
	    $affected += &$func($self, $row->{f}, $row->{b});

	    $rownum++;
	}

	if($rownum == 2){
	    # block is empty, so don't go on to next
	    last;
	}
    }

    whisper "G:C:C:ApplyFuncToUndo() finished\n";
    return $affected;
}

####################################################################
# Returns (PID, refbuf, datablocksize).
# PID is 0 for none found, -1 for checksum failure (after 3 tries).
sub GetBlockWithPID
{
    my ($self, $fileno, $blockno) = @_;
    if(!defined($self->{MARK})){cluck("missing MARK");}

    my $retry;
    my $pass = 0;
    my $refbuf;
    my $datablocksize;

    for($retry = 0; $retry < 3; $retry++){
        # Check for pid in block before rolling back.	    
        # pre-read block into temp rdblock to check if undo needed
        ($refbuf, $datablocksize) = 
            $self->ReadOrWriteBlock($fileno, $blockno, "READ");

        $pass = $self->VerifyChecksum($refbuf, $datablocksize);

        if($pass){
            last;
        }

        if($retry == 1){
	    sleep(1);
	}
    }

    if(!$pass){
	print STDERR "GetBlockWithPID ($fileno,$blockno) failed checksum!\n";
	return (-1, $refbuf, $datablocksize);
    }

    my %data_tied_hash = ();
    my $data_tie_val =
	tie %data_tied_hash, 
	'Genezzo::Block::RDBlock', (refbufstr => $refbuf,
				    blocksize => $datablocksize);
    my $data_pid_row = $data_tie_val->_get_meta_row("PID");
    my $data_block_pid = 0;

    if(defined($data_pid_row)){
	$data_block_pid = $data_pid_row->[0];
    }

    whisper "G:C:C:GetBlockWithPID data block pid = $data_block_pid\n";
    return ($data_block_pid, $refbuf, $datablocksize);
}    

####################################################################
# Passed to ApplyFuncToUndo.
sub RollbackFunc
{
    my ($self, $fileno, $blockno) = @_;
    if(!defined($self->{MARK})){cluck("missing MARK");}
    my $affected = 0;
    my $cl_ctx = $self->{cl_ctx};

    my $gtxLock = $cl_ctx->{gtxLock};  # Locks needed for startup case;
                                       # otherwise redundant.
    # Lock block SH.
    $gtxLock->lock(lock => $blockno, shared => 1); 

    my ($data_block_pid) = $self->GetBlockWithPID($fileno, $blockno);

    if(($data_block_pid == $cl_ctx->{proc_num}) ||
       ($data_block_pid == -1))
    {
	# Only recover your own PID, as someone else (in crash case)
	# may have already recovered and used block.
	# Promote lock to EX.
	$gtxLock->lock(lock => $blockno, shared => 0);	    
	$self->CopyBlockToOrFromTail($fileno, $blockno, "FROM");
	$affected = 1;
    }

    # At startup could release each lock here.
    return $affected;
}

####################################################################
sub Rollback_Internal
{
    my ($self) = @_;
    if(!defined($self->{MARK})){cluck("missing MARK");}

    whisper "G:C:C:Rollback_Internal()\n";
    # for each block in undo, for each row in block, replace disk contents

    my $affected = $self->ApplyFuncToUndo(\&RollbackFunc);

    whisper "G:C:C:Rollback_Internal() finished\n";
    return $affected;
}

####################################################################
sub Sync
{
    my ($self, $fh) = @_;

    if($Genezzo::Util::USE_FSYNC){
	$fh->sync;
    }else{
	# Otherwise assume autoflush(1) has been called.
    }
}

####################################################################
# returns IO::File
sub OpenFile
{
    my ($self, $full_filename) = @_;

    my $fh = new IO::File "+<$full_filename"
	or die "open $full_filename failed: $!\n";

    if(!$Genezzo::Util::USE_FSYNC){
	# Yes, this is probably terrible perfomance.  
	# For now just want to pass CPAN Testers on non-Cygwin Win32.
	$fh->autoflush(1);
    }

    return $fh;
}

####################################################################
# Copies before image of block to end of file.
# direction TO:    copy from body to tail
#           FROM:  copy from tail to body
# Optionally call xform_func with block contents before write (unused).
# returns $refbuf.
sub CopyBlockToOrFromTail
{
    my ($self, $fileno, $blockno, $direction, $xform_func) = @_;
    if(!defined($self->{MARK})){cluck("missing MARK");}
    my $cl_ctx = $self->{cl_ctx};

    whisper "G:C:C:CopyBlockToOrFromTail $direction\n";

    my $fh = $cl_ctx->{open_files}->{$fileno};
    my $full_filename = 
	$cl_ctx->{undoHeader}->{files}->{$fileno}->{full_filename};

    if(!defined($fh)){
        whisper "G:C:C:CopyBlockToOrFromTail opening $fileno\n";
        $fh = $self->OpenFile($full_filename);
	$cl_ctx->{open_files}->{$fileno} = $fh;
    }

    my $file_blocksize = 
	$cl_ctx->{undoHeader}->{files}->{$fileno}->{blocksize};
    my $file_numblocks = 
	$cl_ctx->{undoHeader}->{files}->{$fileno}->{numblocks};
    my $file_hdrsize = $cl_ctx->{undoHeader}->{files}->{$fileno}->{hdrsize};

    my $src_offset;
    my $dst_offset;

    if($direction eq "TO"){
        $src_offset = $file_hdrsize + ($file_blocksize * $blockno);
	# not clear if numblocks includes header; lets be safe
	$dst_offset = $src_offset + ($file_numblocks * $file_blocksize);
    }elsif($direction eq "FROM"){
        $dst_offset = $file_hdrsize + ($file_blocksize * $blockno);
	# not clear if numblocks includes header; lets be safe
	$src_offset = $dst_offset + ($file_numblocks * $file_blocksize);
    }else{
        die "invalid direction $direction in CopyBlockToOrFromTail";
    }

    $fh->sysseek ($src_offset, 0 )
        or die "bad seek - file $full_filename : src $src_offset : $!";

    my $buf;

    Genezzo::Util::gnz_read ($fh, $buf, $file_blocksize)
        == $file_blocksize
        or die 
            "bad read - file $full_filename : src $src_offset : $! \n";

    if(defined($xform_func)){
	&$xform_func($self, $fileno, $blockno, \$buf, $file_blocksize);
    }

    $fh->sysseek ($dst_offset, 0 )
        or die "bad seek - file $full_filename : dst $dst_offset : $!";

    Genezzo::Util::gnz_write ($fh, $buf, $file_blocksize)
	== $file_blocksize
        or die 
	"bad write - file $full_filename : dst $dst_offset : $! \n";

    #if($direction eq "TO"){
        $self->Sync($fh);
    #}

    return \$buf;
}

####################################################################
# Reads block from file, or writes block to file.
# Direction READ: read block and return (refbuf, file_blocksize)  
#           WRITE: write writebuf to file
#           WRITE_TAIL write writebuf to tail of file
sub ReadOrWriteBlock
{
    my ($self, $fileno, $blockno, $direction, $refbuf) = @_;
    if(!defined($self->{MARK})){cluck("missing MARK");}
    my $cl_ctx = $self->{cl_ctx};

    whisper "G:C:C:ReadOrWriteBlock $direction\n";

    my $fh = $cl_ctx->{open_files}->{$fileno};
    my $full_filename = 
	$cl_ctx->{undoHeader}->{files}->{$fileno}->{full_filename};

    if(!defined($fh)){
        whisper "G:C:C:ReadOrWriteBlock opening $fileno\n";
        $fh = $self->OpenFile($full_filename);
	$cl_ctx->{open_files}->{$fileno} = $fh;
    }

    my $file_blocksize = 
	$cl_ctx->{undoHeader}->{files}->{$fileno}->{blocksize};
    my $file_numblocks = 
	$cl_ctx->{undoHeader}->{files}->{$fileno}->{numblocks};
    my $file_hdrsize = $cl_ctx->{undoHeader}->{files}->{$fileno}->{hdrsize};

    my $offset;

    $offset = $file_hdrsize + ($file_blocksize * $blockno);

    if($direction eq "WRITE_TAIL"){
	$direction = "WRITE";
	$offset += ($file_blocksize * $file_numblocks);
    }

    $fh->sysseek ($offset, 0 )
        or die "bad seek - file $full_filename : src $offset : $!";

    if($direction eq "READ"){
	my $buf;

	Genezzo::Util::gnz_read ($fh, $buf, $file_blocksize)
	    == $file_blocksize
	    or die 
            "bad read - file $full_filename : $offset : $! \n";
	
	return (\$buf, $file_blocksize);
    }elsif($direction eq "WRITE"){
	Genezzo::Util::gnz_write ($fh, $$refbuf, $file_blocksize)
	    == $file_blocksize
	    or die 
	    "bad write - file $full_filename : $offset : $! \n";
  
	$self->Sync($fh);
    }else{
        die "invalid direction $direction in ReadOrWriteBlock";
    }
}

####################################################################
sub WriteTransactionState
{
    my ($self, $state_buff) = @_;
    if(!defined($self->{MARK})){cluck("missing MARK");}
    my $undo_file = $self->{undo_file};

    my $blk = $self->{cl_ctx}->{proc_state_blocknum}*$UNDO_BLOCKSIZE;
    $undo_file->sysseek($blk, 0)
	or die "bad seek - file undo block $blk: $! \n";
    Genezzo::Util::gnz_write($undo_file, $state_buff, $UNDO_BLOCKSIZE)
	or die "bad write - file undo block $blk: $! \n";
    $self->Sync($undo_file);
}

####################################################################
# returns single character code
sub ReadTransactionState
{
    my ($self, $pid) = @_;  # if undefined uses $cl_ctx->{proc_num}
    if(!defined($self->{MARK})){cluck("missing MARK");}
    my $undo_file = $self->{undo_file};
    my $cl_ctx = $self->{cl_ctx};
    my $buf;

    if(!defined($pid)){
	$pid = $cl_ctx->{proc_num};
    }

    # Was $self->{cl_ctx}->{proc_state_blocknum}.
    my $blk = ($pid +1)*$UNDO_BLOCKSIZE;
    $undo_file->sysseek($blk, 0)
	or die "bad seek - file undo block $blk: $! \n";
    Genezzo::Util::gnz_read($undo_file, $buf, $UNDO_BLOCKSIZE)
	or die "bad write - file undo block $blk: $! \n";

    my $ch = substr($buf,0,1);

    # Handle corruped byte case.
    if(($ch ne $COMMITTED_CODE) && ($ch ne $CLEAR_CODE) &&
       ($ch ne $ROLLEDBACK_CODE) && ($ch ne $PENDING_CODE))
    {
	$ch = $ROLLEDBACK_CODE;
    }

    return $ch;
}

####################################################################
sub ResetUndo
{
    my ($self) = @_;
    if(!defined($self->{MARK})){cluck("missing MARK");}
    my $cl_ctx = $self->{cl_ctx};

    $cl_ctx->{tx_id} = $cl_ctx->{tx_id} + 1;

    $cl_ctx->{current_undo_blockid} = 0;

    # create empty undo block
    $self->CreateUndoBlock();
    # write it out
    $self->WriteUndoBlock();
}

####################################################################
sub BeginTransaction
{
    my ($self) = @_;
    if(!defined($self->{MARK})){cluck("missing MARK");}
    my $cl_ctx = $self->{cl_ctx};

    whisper "Genezzo::Contrib::Clustered::BeginTransaction\n";
    # Increment transaction id.
    $cl_ctx->{tx_id} = $cl_ctx->{tx_id} + 1;
    # Mark transaction pending.
    $self->WriteTransactionState($PENDING_BUFF);

    $cl_ctx->{current_undo_blockid} = 0;

    # Create empty undo block.
    $self->CreateUndoBlock();
    # Write it out.
    $self->WriteUndoBlock();
}    

####################################################################   
sub CreateUndoBlock
{
    my ($self) = @_;
    if(!defined($self->{MARK})){cluck("missing MARK");}
    my $cl_ctx = $self->{cl_ctx};

    my $buff = "\0" x $UNDO_BLOCKSIZE;
    my %tied_hash = ();
    my $tie_val =
        tie %tied_hash, 'Genezzo::Block::RDBlock', (refbufstr => \$buff,
						    blocksize => 
						    $UNDO_BLOCKSIZE);
    $cl_ctx->{current_undo_block} = $tie_val;
    $cl_ctx->{current_undo_block_buf} = \$buff;
    # Add tx id.
    # This should be metadata; for now store it as 1st row.
    my $row = { "tx" => $cl_ctx->{tx_id} };
    my $frozen_row = FreezeThaw::freeze $row;
    $cl_ctx->{current_undo_block}->HPush($frozen_row);
}

####################################################################
sub AddAndWriteUndo
{
    my ($self,$fileno, $blockno) = @_;
    if(!defined($self->{MARK})){cluck("missing MARK");}
    my $cl_ctx = $self->{cl_ctx};

    whisper "G:C:C:AddAndWriteUndo\n";

    my $row;

    if($pad_undo == 0){
	$row = { "f" => $fileno,
		    "b" => $blockno };
    }else{
	my $pad = "X" x ($UNDO_BLOCKSIZE/3);
	$row = { "f" => $fileno,
		    "b" => $blockno,
		    "pad" => $pad };
    }

    my $frozen_row = FreezeThaw::freeze $row;
    my $newkey = $cl_ctx->{current_undo_block}->HPush($frozen_row);
   
    if(defined($newkey)){
        $self->WriteUndoBlock();
	return;
    }

    # Current block is full (and already written).
    # Create new block.

    $self->CreateUndoBlock();
    # move to next block
    $cl_ctx->{current_undo_blockid} += 1;

    if($pad_undo) {
	#print STDERR 
	#    "Moving to next undo block ($cl_ctx->{current_undo_blockid})\n";
	#cluck "Moving";
    }

    my $offset = $cl_ctx->{current_undo_blockid}*2;

    if(($offset) >= ($cl_ctx->{undoHeader}->{blocks_per_proc}-1))
    {
        die("Undo Full:  undo offset $offset >= block_per_proc $cl_ctx->{undoHeader}->{blocks_per_proc} - 1\n");
    }

    $newkey = $cl_ctx->{current_undo_block}->HPush($frozen_row);
    $self->WriteUndoBlock();
}

####################################################################
sub WriteUndoBlock
{
    my ($self) = @_;
    if(!defined($self->{MARK})){cluck("missing MARK");}
    my $cl_ctx = $self->{cl_ctx};
    my $undo_file = $self->{undo_file};

    whisper "G:C:C:WriteUndoBlock\n";
    # note paired blocks means we multiply blockid by 2
    my $offset = $cl_ctx->{current_undo_blockid} * 2;

    if($offset >= ($cl_ctx->{undoHeader}->{blocks_per_proc}-1)){
        die("Undo Full:  undo offset $offset >= block_per_proc $cl_ctx->{undoHeader}->{blocks_per_proc} - 1\n");
    }
    
    my $blk = ($cl_ctx->{proc_undo_blocknum} + $offset)*$UNDO_BLOCKSIZE;
    $undo_file->sysseek($blk, 0)
	or die "bad seek - file undo block $blk: $! \n";

    # TODO: Add a checksum so we can tell which block is good.
    my $bp = $cl_ctx->{current_undo_block_buf};
    Genezzo::Util::gnz_write($undo_file, $$bp, $UNDO_BLOCKSIZE)
        == $UNDO_BLOCKSIZE
	or die "bad write of undo to undo : $! \n";
    # write it again to block+1 (paired writes)
    Genezzo::Util::gnz_write($undo_file, $$bp, $UNDO_BLOCKSIZE)
        == $UNDO_BLOCKSIZE
        or die "bad write (2) of undo to undo : $! \n";
    $self->Sync($undo_file);
}

####################################################################
# Returns 1 for success, 0 for failure.
sub VerifyChecksum
{
    my ($self, $refbuf, $blocksize) = @_;
    if(!defined($self->{MARK})){cluck("missing MARK");}
    
    my @cksums = Genezzo::Block::Util::GetChecksums($refbuf, $blocksize);
    # test if the calculated checksum matches the stored checksum
    unless ((scalar(@cksums) == 2) &&
	    ($cksums[0] == $cksums[1]))
    {
	return 0;
    }

    return 1;
}

####################################################################
sub UpdateChecksum
{
    my ($self, $fnum, $bnum, $refbuf, $blocksize) = @_;
    if(!defined($self->{MARK})){cluck("missing MARK");}

    Genezzo::Block::Util::UpdateBlockFooter($refbuf, $blocksize);
}

####################################################################
# Not shareable as constant when they contain PID!
sub InitConstBuff()
{
    my ($self, $bufref, $code) = @_;

    my $buff = $code;
    $buff = $buff. ("-" x 9);
    # Can't store PID if shared between procs.
    my $procstr = sprintf("%10d", $self->{cl_ctx}->{proc_num});
    #my $procstr = sprintf("%10d", 0);
    $buff = $buff . $procstr;
    $buff = $buff . ( "=" x ($UNDO_BLOCKSIZE - 20) );
    $$bufref = $buff;
}

####################################################################
sub _init
{
    my $self = shift;
    if(!defined($self->{MARK})){cluck("missing MARK");}
    my $cl_ctx = $self->{cl_ctx};

    if(defined($self->{init_done}) && $self->{init_done}){
        return;
    }

    #cluck "_init";

    whisper "Genezzo::Contrib::Clustered::_init called\n";

    my $dict = $self->{dict};
    my $undo_filename = $dict->{fileheaderinfo}->{undo_filename};

    die unless(defined($undo_filename));

    my $fhts;   # gnz_home table space

    if(getUseRaw()){
        $fhts = $dict->{gnz_home};
    }else{
        $fhts = File::Spec->catdir($dict->{gnz_home}, "ts");
    }

    my $full_filename =
        File::Spec->rel2abs(
            File::Spec->catfile($fhts, $undo_filename));

    $self->{undo_file} = $self->OpenFile($full_filename);

    # Construct an empty byte buffer.
    my $buff;

    Genezzo::Util::gnz_read($self->{undo_file}, $buff, $UNDO_BLOCKSIZE) 
        == $UNDO_BLOCKSIZE
    	or die "bad read - file $full_filename: $!\n";
    
    my %tied_hash = ();
    my $tie_val =
        tie %tied_hash, 'Genezzo::Block::RDBlock', (refbufstr => \$buff,
						    blocksize => 
						    $UNDO_BLOCKSIZE);
    
    my $frozen_undoHeader = $tied_hash{1};
    my ( $undoHeader ) = FreezeThaw::thaw $frozen_undoHeader;
    $cl_ctx->{undoHeader} = $undoHeader;

    my $try_proc_num = $starting_pid;

    my $pid_param;
    my $fhdefs = $dict->{fhdefs};

    if(defined($fhdefs)){
	$pid_param = $fhdefs->{_pid};
    }

    if(defined($pid_param)){
	$try_proc_num = $pid_param;
    }

    # determine if this proc_num is free
    while(1){
	if($try_proc_num >= $cl_ctx->{undoHeader}->{procs}){
	    Carp::croak(
	        "Maximum processes ($cl_ctx->{undoHeader}->{procs}) exceeded");
	}

	my $lockname = "SVR" . $try_proc_num;
	my $curLock = 
	    Genezzo::Contrib::Clustered::GLock::GLock->new(
	        lock => $lockname, block => 0);
	if(defined($curLock->lock(shared => 0))){
	    last;  # Obtained lock.
	}
	
	$try_proc_num++;
    }

    $cl_ctx->{proc_num} = $try_proc_num;
    print STDERR "Genezzo::Contrib::Clustered Assigned Process Number = $try_proc_num to OS process $$\n";
 
    $cl_ctx->{proc_state_blocknum} = 
	$cl_ctx->{proc_num} + 1;  # 1 for undoHeader
    $cl_ctx->{proc_undo_blocknum} = 
        1 + $cl_ctx->{undoHeader}->{procs} + 
	($cl_ctx->{undoHeader}->{blocks_per_proc} * $cl_ctx->{proc_num});

    $self->InitConstBuff(\$COMMITTED_BUFF, $COMMITTED_CODE);
    $self->InitConstBuff(\$ROLLEDBACK_BUFF, $ROLLEDBACK_CODE);
    $self->InitConstBuff(\$PENDING_BUFF, $PENDING_CODE);
    $self->InitConstBuff(\$CLEAR_BUFF, $CLEAR_CODE);

    # Hashed on fileno.
    # Contains IO::File.
    $cl_ctx->{open_files} = {};

    # Hashed on $fileno_$blockno.
    # contents are { f => $fileno, b => $blockno } 
    $cl_ctx->{dirty_blocks} = {};

    my $gtxLock = Genezzo::Contrib::Clustered::GLock::GTXLock->new();
    $cl_ctx->{gtxLock} = $gtxLock;

    # Startup recovery.
    my $tx_state = $self->ReadTransactionState();

    if(($tx_state eq $PENDING_CODE) || ($tx_state eq $ROLLEDBACK_CODE)){
        my $affected = $self->Rollback_Internal();
	
	if($affected > 0) {
	    print STDERR "rollback at startup necessary!\n";
	    print STDERR "PLEASE TYPE ROLLBACK COMMAND\n";
	    # note here no rollback work will occur, but system will restart
	    # from disk (verify)
	}
    }elsif($tx_state eq $COMMITTED_CODE){
	# need to clear PID in blocks
	$self->ApplyFuncToUndo(\&CommitFunc);
    }

    $self->WriteTransactionState($CLEAR_BUFF);

    # Rollback_Internal and Commit accumulate locks.
    # Keep them.
    # $gtxLock->unlockAll();	
    $gtxLock->demoteAll();

    $cl_ctx->{tx_id} = 0; 

    whisper "G:C:C:_init begin init undo\n";
    # Init all undo blocks.
    $self->CreateUndoBlock();
    my $tmp_undo_blockid;

    for($tmp_undo_blockid = 0; 
	$tmp_undo_blockid < ($cl_ctx->{undoHeader}->{blocks_per_proc}/2);
	$tmp_undo_blockid++)
    {
	$cl_ctx->{current_undo_blockid} = $tmp_undo_blockid;
	$self->WriteUndoBlock();
    }

    whisper "G:C:C:_init end init undo\n";

    $cl_ctx->{tx_id} = 1; 
    $cl_ctx->{have_begin_trans} = 0;

    whisper "Genezzo::Contrib::Clustered::_init finished\n";
    $self->{init_done} = 1;
}

####################################################################
sub new
{
    whoami;
    my $invocant = shift;
    my $class = ref($invocant) || $invocant ;
    my $self = {};
    $self->{MARK} = 1;

    # Clustered context.
    $self->{cl_ctx} = {};

    # Flag to avoid processing write to buffer during read.
    $self->{inReadBlock} = 0;

    $self->{init_done} = 0;

    $self->{dict} = shift @_;
    # greet $self->{dict}->{prefs};

    return bless $self, $class;

}

####################################################################
sub SysHookInit
{
    goto &new

}

####################################################################
BEGIN
{
    # Rollback at start will obtain shared locks for all blocks in buffer
    # cache.
    print STDERR "Genezzo::Contrib::Clustered will be installed (please type rollback)\n"; 

    $COMMITTED_BUFF = "";
    $ROLLEDBACK_BUFF = "";
    $PENDING_BUFF = "";
    $CLEAR_BUFF = "";

    $COMMITTED_CODE = "C";
    $ROLLEDBACK_CODE = "R";
    $PENDING_CODE = "P";
    $CLEAR_CODE = "-";

    $UNDO_BLOCKSIZE = $Genezzo::Block::Std::DEFBLOCKSIZE;

    $starting_pid = 1;
    $pad_undo = 0;
}

1;
__END__

=head1 NAME

Genezzo::Contrib::Clustered - Shared data cluster support for Genezzo

=head1 SYNOPSIS

  genprepundo.pl

  gendba.pl
  >@havok.sql
  >@syshook.sql
  >@clustered.sql

=head1 DESCRIPTION

Genezzo is an extensible database with SQL and DBI.  It is written in Perl.
Basic routines inside Genezzo are overridden via Havok SysHooks.  Override
routines provide support for shared data clusters.  Routines
provide transactions, distributed locking, undo, and recovery.  

=head2 Undo File Format

All blocks are $Genezzo::Block::Std::DEFBLOCKSIZE 

=head3 Header 
 
  (block 0)

Frozen data structure stored via Genezzo::Block::RDBlock->HPush()

  {
     "procs" => $processes,
     "blocks_per_proc" => $blocks_per_process,
     "files" => {
	 per fileidx =>
	 { fileidx, filename, full_filename, blocksize, numblocks, hdrsize }
     }
  };

=head3 Process Status Block 

  (block 1 to $processes+1)

 ----------processid(10)================= to end of block

 1st character is status:

    - = clear
    C = committed
    R = rolledback
    P = pending

=head3 Undo Blocks 

  (array of $blocks_per_process * $processes)

These are written paired (for recoverability), so only half number is 
actually available.

Undo blocks contain multiple rows.  1st row is {"tx"}, a transaction id.
following rows are {"f" = $fileno, "b" = $blockno}.  All are
Frozen data structures stored via Genezzo::Block::RDBlock->HPush().

The list of fileno/blockno indicate which blocks should be replaced if
the transaction rolls back, or which blocks should have the process id
cleared if the transaction commits.

At process startup undo blocks for the process are initially all written 
with tx 0, so we can distinguish when we move to a block left over from 
a previous transaction.

=head2 Before-Image Block Storage

The before image of each block is written at the tail of the file where
it originates, at position $declared_file_length + $blocknum.  So when
this module is enabled data files actually grow to twice their declared
size.  Note dynamic data file growth (increase_by) is not supported 
with this module.

While a transaction is in progress blocks in the main portion of the
file will contain the process id (PID) of the active process. 
Before-image blocks at the tail of the file should always have PIDs 
of 0 (or unset).

=head1 FUNCTIONS

=over 4

=item ReadBlock

Replaces Genezzo::BufCa::BCFile::_filereadblock

=item DirtyBlock

Wraps Genezzo::BufCa::DirtyScalar::STORE

=item _init_filewriteblock

Called by Genezzo::BufCa::BCFile::_filewriteblock

=item Commit

Wraps Genezzo::GenDBI::Kgnz_Commit

=item Rollback

Wraps Genezzo::GenDBI::Kgnz_Rollback

=item Execute

Wraps Genezzo::GenDBI::Kgnz_Execute (experimental!)

=back

=head2 EXPORT

none

=head1 LIMITATIONS

This is pre-alpha software; don't use it to store any data you hope
to see again!

See README for current TODO list.

=head1 SEE ALSO

L<http://www.genezzo.com>

L<http://eric_rollins.home.mindspring.com/genezzo/ClusteredGenezzoDesign.html>

L<http://eric_rollins.home.mindspring.com/genezzo/cluster.html>

L<http://opendlm.sourceforge.net/>

=head1 AUTHOR

Eric Rollins, rollins@acm.org

=head1 COPYRIGHT AND LICENSE

    Copyright (C) 2005 by Eric Rollins.  All rights reserved.

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

Address bug reports and comments to rollins@acm.org

=cut
