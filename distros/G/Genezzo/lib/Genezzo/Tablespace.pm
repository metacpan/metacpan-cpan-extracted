#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/RCS/Tablespace.pm,v 7.14 2007/06/26 08:19:09 claude Exp claude $
#
# copyright (c) 2003-2006 Jeffrey I Cohen, all rights reserved, worldwide
#
#
package Genezzo::Tablespace;  # assumes Some/Module.pm
use Genezzo::Util;

use strict;
use warnings;

use Carp;
use Genezzo::Util;
use Genezzo::TSHash;
use Genezzo::Row::RSIdx1;
use Genezzo::Row::RSTab;
use Genezzo::BufCa::BCFile;
use Genezzo::Dict;
use Genezzo::Block::Util;
use File::Spec;
use warnings::register;

BEGIN {
    use Exporter   ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    # set the version for version checking
#    $VERSION     = 1.00;
    # if using RCS/CVS, this may be preferred
    $VERSION = do { my @r = (q$Revision: 7.14 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

    @ISA         = qw(Exporter);
#    @EXPORT      = qw(&func1 &func2 &func4 &func5);
    @EXPORT      = ( );
    %EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

    # your exported package globals go here,
    # as well as any optionally exported functions
#    @EXPORT_OK   = qw($Var1 %Hashit &func3 &func5);
    @EXPORT_OK   = ( );

}

our @EXPORT_OK;

# non-exported package globals go here

our $GZERR = sub {
    my %args = (@_);

    return 
        unless (exists($args{msg}));

    if (exists($args{self}))
    {
        my $self = $args{self};
        if (defined($self) && exists($self->{GZERR}))
        {
            my $err_cb = $self->{GZERR};
            return &$err_cb(%args);
        }
    }

    my $warn = 0;
    if (exists($args{severity}))
    {
        my $sev = uc($args{severity});
        $sev = 'WARNING'
            if ($sev =~ m/warn/i);

        # don't print 'INFO' prefix
        if ($args{severity} !~ m/info/i)
        {
            printf ("%s: ", $sev);
            $warn = 1;
        }

    }
    # XXX XXX XXX
    print __PACKAGE__, ": ",  $args{msg};
#    print $args{msg};
#    carp $args{msg}
#      if (warnings::enabled() && $warn);
    
};

# initialize package globals, first exported ones

# then the others (which are still accessible as $Some::Module::stuff)

# all file-scoped lexicals must be created before
# the functions below that use them.

# file-private lexicals go here

# list of compatible database formats
my %compatible_format = (
                         0.32 => [0.31],
                         0.33 => [0.31, 0.32],
                         0.34 => [0.35, 0.36, 0.37, 0.38],
                         0.35 => [0.34, 0.36, 0.37, 0.38],
                         0.36 => [0.34, 0.35, 0.37, 0.38],
                         0.37 => [0.34, 0.35, 0.36, 0.38],
                         0.38 => [0.34, 0.35, 0.36, 0.37],
                         0.48 => [0.49, 0.50],
                         0.49 => [0.48, 0.50],
                         0.50 => [0.48, 0.49],
                         );

# make all your functions, whether exported or not;

sub new 
{
    my $invocant = shift;
    my $class = ref($invocant) || $invocant ; 
    my $self = { };

    my %required = (
                    name => "no tablespace name !",
                    tsid => "no tsid !",
                    gnz_home => "no gnz_home !",
                    dict => "no dict! "
                    );

    my %optional = (
                    bc_size   => 64, # number of blocks in buffer cache
                    blocksize => $Genezzo::Util::DEFBLOCKSIZE, # default size
                    dbfile    => "default"
                    );

    my %args = (%optional,
                @_);
    
    return 0
        unless (Validate(\%args, \%required));

    my $dbfile = $args{dbfile};

    if(getUseRaw()){   # no way to tell if it was really specified...
	if($dbfile eq "default"){
	    $dbfile = "raw1";    # FIXME
	}
    }

    $self->{the_ts} = {};
    $self->{dict} = $args{dict}; 
    $self->{tsid} = $args{tsid};

    my $ts = $self->{the_ts};

    $self->{NAME} = $args{name};

    $self->{gnz_home} = $args{gnz_home};
    my $ts_prefix;

    if(getUseRaw()){
	$ts_prefix = $args{gnz_home};  
    }else{
	$ts_prefix = File::Spec->catdir($args{gnz_home} , 'ts');
    }

    $self->{ts_prefix} = $ts_prefix;

    $self->{files} = {

        # NOTE: filearr and used/unused should use dict _tsfiles fileidx
        # we cheat a bit at startup because first file is fileidx 1...

        filearr => [],  # array of ts file info [name, #bytes, #blocks]
        unused  => [],  # array of unused files (by _tsfiles fileidx)
        used    => []   # array of used files   (by _tsfiles fileidx)
        };

    $self->{blocksize} = $args{blocksize};
    $self->{bc_size}   = $args{bc_size};

    if(getUseRaw()){
	$self->{dbfile}    = 
	    File::Spec->catfile(
				$ts_prefix,
				$dbfile);
    }else{
	$self->{dbfile}    = 
	    File::Spec->catfile(
				$ts_prefix,
				$dbfile  . '.dbf');
    }

    if ((exists($args{GZERR}))
        && (defined($args{GZERR}))
        && (length($args{GZERR})))
    {
        # NOTE: don't supply our GZERR here - will get
        # recursive failure...
        $self->{GZERR} = $args{GZERR};
    }
    
    return bless $self, $class;

} # end new

sub name
{
    my $self = shift;

    $self->{NAME} = shift if @_ ;

    return $self->{NAME};

} # end name

sub tables ()
{
    my $self = shift;

    $self->{tabsp_tables} = shift if @_ ;

    return $self->{tabsp_tables};

}

sub make_fac2 {
    my $tclass = shift;
    my %args = (
                @_);

    if (exists($args{hashref}))
    {    
        carp "cannot supply hashref to factory method - deleting !\n"
            if warnings::enabled();

        delete $args{hashref};
    }

    my %td_hash1  = ();

#    my $filenum =  0;

    my $newfunc = 
        sub {

#            whoami @_;
            my %args2 = (
                        @_);

            my $tiehash1 = 
                tie %td_hash1, $tclass, %args2;

            return $tiehash1;
        };
    return $newfunc;
}

#
# invoked from Dict::_get_table
#
sub TableHash ()
{
    my $self = shift;
    my $ts = $self->{the_ts};

    my %required = (
                    tname    => "no table name !",
                    dbh_ctx  => "no dbh context !"
                    );

    my %optional = (
                    htype       => "DISK", # set hash type on creation
                    object_type => "TABLE"
                    );

    my %args = (%optional,
                @_);
#		tname

#   greet %args;

    return undef
        unless (Validate(\%args, \%required));

    my %td_hash;

    my $tname = $args{tname};
    my $htype = $args{htype};

    unless (exists($self->{tabsp_tables}->{$tname}))
    {

        if (uc($htype) =~ m/MEMORY/)
        {
            $self->{tabsp_tables}->{$tname} 
            = { type => "MEMORY",
                rows => {}
            };
        }
        else
        {
            $self->{tabsp_tables}->{$tname} 
            = { type  => "DISK",
                desc => {}
            };
        }

    }

#    greet  $self->{tabsp_tables}->{$tname};
    $htype = $self->{tabsp_tables}->{$tname}->{type};

    my $tiehash = ();
        
    if (uc($htype) =~ m/MEMORY/)
    {
        $tiehash = 
            tie %td_hash, 'Genezzo::TSHash', 
        (hashref => $self->{tabsp_tables}->{$tname}->{rows}) ;
    }
    else
    {

        my %nargs = (
                     tablename => $tname,
                     tso       => $self,
                     GZERR     => $self->{GZERR},
                     bufcache  => $ts->{bc},
                     dbh_ctx   => $args{dbh_ctx},
                     object_type => $args{object_type}
                     );

        if (defined($args{object_id}))
        {
            $nargs{object_id} = $args{object_id};
        }

        if ($args{object_type} =~ m/^TABLE/)
        {
            my $fac2 = make_fac2('Genezzo::Row::RSFile');
            $nargs{factory} = $fac2;
            
            $tiehash = 
                tie %td_hash, 'Genezzo::Row::RSTab', %nargs;
        }
        elsif ($args{object_type} =~ m/^IDXTAB/)
        {
#            whoami;

            unless (defined($args{pkey_type}))
            {
                my $msg = "missing pkey argument\n";
                my %earg = (self => $self, msg => $msg,
                            severity => 'warn');
               
                &$GZERR(%earg)
                    if (defined($GZERR));

                return undef;
            }

            # get type of primary key for comparison functions...
            $nargs{key_type} = $args{pkey_type};

            $nargs{blocksize} = $self->{blocksize};
            $tiehash = 
                tie %td_hash, 'Genezzo::Row::RSIdx1', %nargs;
        }
        elsif ($args{object_type} =~ m/^INDEX/)
        {
 #           whoami;

            unless (defined($args{pkey_type}))
            {
                my $msg = "missing pkey argument\n";
                my %earg = (self => $self, msg => $msg,
                            severity => 'warn');
               
                &$GZERR(%earg)
                    if (defined($GZERR));

                return undef;
            }

            # get type of primary key for comparison functions...
            $nargs{key_type} = $args{pkey_type};

            $nargs{blocksize} = 
                (defined($args{blocksize})) ? 
                ($args{blocksize}) : $self->{blocksize};

            $nargs{unique_key} = 
                (defined($args{unique_key})) ? ($args{unique_key}) : 1;
            
            $nargs{BT_Index_Class} = 
                (defined($args{BT_Index_Class})) ? 
                ($args{BT_Index_Class}) : "Genezzo::Index::bt3";

            $nargs{BT_Fetch_Fix} = 1;

#            whoami %nargs;

            $tiehash = 
                tie %td_hash, 'Genezzo::Index::btHash', %nargs;
        }
        else
        {
            my $tt = $args{object_type};

            my $msg = "invalid object type $tt\n";
            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
               
            &$GZERR(%earg)
                if (defined($GZERR));

            return undef;
        }

    }

    return \%td_hash;
}


sub TSSave ()
{
    my $self = shift;

#    whoami;

    my $ts = $self->{the_ts};

    my $bc = $ts->{bc};

    if ($bc)
    {
        $bc->Flush(@_);
        delete $ts->{bc}; # remove bc from ts hash before dumping ts to disk
    }

    $ts->{bc} = $bc;
} # end tssave

sub TSRollback ()
{
    my $self = shift;

#    whoami;

    my $ts = $self->{the_ts};

    my $bc = $ts->{bc};

    if ($bc)
    {
        $bc->Rollback(@_);
        delete $ts->{bc}; # remove bc from ts hash before dumping ts to disk
    }

    $ts->{bc} = $bc;
} # end tsrollback

sub TSLoad ()
{
    my $self = shift;

#    whoami @_;

    # XXX : clean this up - LOADTYPE, bcfile info
    my %args = @_;
    my $init = 0;
    my $preload = 0;

#    greet %args;

    # when creating a new db, 
    # first INIT from Dict::_get_table, _DictDefineCoreTabs, _DictDBInit

    # normal operation:
    # PRELOAD from Dict::_get_table, _DictDefineCoreTabs, doDictPreLoad

    # last  INIT from Dict::_get_table, _loadDictMemStructs, DictStartup

    # standard load from _reloadTS, DictStartup

    if (exists($args{loadtype}))
    {
        $init = 1
            if ($args{loadtype} =~ m/INIT/);

        if ($args{loadtype} =~ m/PRELOAD/)
        {
            $preload = 1;
            $init    = 1;
        }
    } # else normal load...

    my $ts = $self->{the_ts};

    if ($init)
    {
        whisper "init the SYSTEM tablespace";

        my $defdbfile = $self->{dbfile};

        unless (defined($ts->{bc}))
        {
            my $fh;
            open ($fh, "< $defdbfile")
                or die "Could not open $defdbfile for read : $! \n";

            my @hdrinfo =
                Genezzo::Util::FileGetHeaderInfo(filehandle => $fh, 
                                                 filename   => $defdbfile);

            unless (scalar(@hdrinfo) > 2)
            {
                my $deadmess =
                    "File $defdbfile not valid for Genezzo version ";
                $deadmess .= $Genezzo::GenDBI::VERSION;
                die $deadmess;
            }

#            greet @hdrinfo;

            my $h1 = pop @hdrinfo;

#            greet $h1;

            unless (exists($h1->{V}) # V for Version
                    && ($h1->{V} eq $Genezzo::GenDBI::VERSION))
            {
                my $is_compatible = 0;
                my $oldversion = $h1->{V} || "(unknown)";

                # check the compatible format list and see if can use
                # datafile from an older version
                if (exists($compatible_format{$Genezzo::GenDBI::VERSION}))
                {
                    my $vlist = $compatible_format{$Genezzo::GenDBI::VERSION};

                    for my $vv (@{$vlist})
                    {
                        if ($vv eq $oldversion)
                        {
                            # found a match
                            $is_compatible = 1;
                            last;
                        }
                    }
                }

                # either die with incompatibility, or print info msg

                my $msg =
                    "File $defdbfile version $oldversion is ";
                $msg .=  "not "
                    unless ($is_compatible);
                $msg .= "compatible with Genezzo version "
                    . $Genezzo::GenDBI::VERSION;

                die $msg
                    unless ($is_compatible);

                # old version is compatible
                my %earg = (self => $self, msg => $msg,
                            severity => 'info');
               
                &$GZERR(%earg)
                    if (defined($GZERR));
            }

            # XXX XXX XXX XXX : reset the blocksize using the
            # fileheader --- may need to fix the dictionary as well --
            # need to propagate to other functions.
            # XXX XXX XXX: Reset dictionary blocksize

            $self->{blocksize} = $hdrinfo[2];
            $self->{dict}->{blocksize}  = $hdrinfo[2]; # NOTE: reset dictionary
            $self->{dict}->{headersize} = $hdrinfo[0]; # NOTE: reset dictionary
            $self->{dict}->{fileheaderinfo} = $h1;

            close ($fh);
        }

        # Note: get the default db file size from dict so block zero
        # information is correct if building new file
        my $deffilesize = $self->{dict}->{dbsize};
        my $hdrsize     = $self->{dict}->{headersize};
        my $numblocks   = ($deffilesize-$hdrsize)/$self->{blocksize};

        my $numused =
            push (@{$self->{files}->{filearr}}, 
                  [
                   $defdbfile,
                   $deffilesize,
                   $numblocks,
                   ]);
        
        # NB: numused = 1, which is fileidx of first file
        push (@{$self->{files}->{used}}, $numused); # list of used file array

        # XXX: need to add allfileused to list of core tables
        foreach my $tname qw(_tspace _tsfiles _tab1 _col1 allfileused)
        {
            unless (exists($self->{tabsp_tables}->{$tname}))
            {
                # XXX: load the core tables using first file of tablespace
                $self->{tabsp_tables}->{$tname} = { type  => "DISK",
                                                    desc => {
                                                        filesused => [1]
                                                        }
                                                };
                # XXX: preload uses in memory hashes
                if ($preload)
                {
                    $self->{tabsp_tables}->{$tname}->{type} = "MEMORY";
                    $self->{tabsp_tables}->{$tname}->{rows} = {};
                }

            }
        }

    }
    else
    { # not init

        my $dict = $self->{dict};

        whisper "load alltsfiles array";
        my $alltsfiles = $dict->DictTableGetTable(tname => "_tsfiles");
        unless (defined($alltsfiles))
        {
            whisper "failed to load tsfiles!";
            return 0;
        }
        
        my @filearr;
        my @usearr;
        my @unusearr;

        my $getcol = $dict->_get_col_hash("_tsfiles"); 

        # XXX XXX: a good place for a filter "WHERE tsid = ..."
        while (my ($kk, $vv) = each(%{$alltsfiles}))
        {
#            whisper "$kk ";
            my $tsid = $vv->[$getcol->{tsid}];

            next
                unless ($tsid =~ m/$self->{tsid}/);

            my $used    = $vv->[$getcol->{used}];
            my $fileidx = $vv->[$getcol->{fileidx}];
            if ($used =~ m/Y/)
            {
                push @usearr, $fileidx;
            }
            else
            {
                push @unusearr, $fileidx;
            }

            $fileidx--; # subtract 1 to start at array 0 for file #1
            # load file array with name, size, numblocks 
            my $fullpath =
                File::Spec->catfile(
                                    $self->{ts_prefix},
                                    $vv->[$getcol->{filename}]
                                    );

            $filearr[$fileidx] = [
                                  $fullpath,
                                  $vv->[$getcol->{filesize}],
                                  $vv->[$getcol->{numblocks}] ]

        }

        $self->{files}->{filearr} = \@filearr;
        # sort using numeric comparison
        $self->{files}->{used}    = [sort {$a <=> $b} @usearr];
        $self->{files}->{unused}  = [sort {$a <=> $b} @unusearr];

        greet "filearr", $self->{files}->{filearr};
        greet "used", $self->{files}->{used};
        greet "unused", $self->{files}->{unused};

        whisper "load tab array";
        my $alltab = $dict->DictTableGetTable(tname => "_tab1");
        unless (defined($alltab))
        {
            whisper "failed to load tables! ";
            return 0;
        }
        
        $getcol = $dict->_get_col_hash("_tab1");         

        $self->{tnamebytid} = {};

        # load the temporary hash and switch with current tablespace
        # info when complete
        my %tstabhash; # temporary hash for table information

        while (my ($kk, $vv) = each(%{$alltab}))
        {
#            whisper "$kk ";
            my $tsid   = $vv->[$getcol->{tsid}];

            next
                unless ($tsid =~ m|$self->{tsid}|);

            my $tabrid = $kk; 
            my $tname  = $vv->[$getcol->{tname}];
            my $objid  = $vv->[$getcol->{tid}];

            $self->{tnamebytid}->{$objid} = $tname;

            {
                # BUILD A TABLE HASH
#                whisper "$tname : $tid ";
                $tstabhash{$tname} = { type  => "DISK",
                                       table_rid => $tabrid,
                                       object_id => $objid,
                                       desc => {
                                           filesused => []
                                           }
                                   };

            }
        } # end while alltab
        
        whisper "load allfileused array";
        my $allfu = $dict->DictTableGetTable(tname => "allfileused");
        unless (defined($allfu))
        {
            whisper "failed to load file used! ";
#            whisper caller(2); # dict::_init, dict::_reloadts
            return 0;
        }
        
        $getcol = $dict->_get_col_hash("allfileused");         

#        whisper "pre allfu";
        while (my ($kk, $vv) = each(%{$allfu}))
        {
#            whisper "$kk ";
            my $fileidx = $vv->[$getcol->{fileidx}];
            my $objid   = $vv->[$getcol->{tid}];

#            whisper "allfu $tid $fileidx";
            next
                unless (exists($self->{tnamebytid}->{$objid}));
            my $tname =  $self->{tnamebytid}->{$objid};

            push (@{$tstabhash{$tname}->{desc}->{filesused}},
                  $fileidx);
        } # end while allfu

#        greet $self->{tnamebytid};

        # XXX: replace the table information with newly loaded info
        # from dictionary
        $self->{tabsp_tables} = \%tstabhash;

#        greet $self->{tabsp_tables};

    } # end not init

    unless (defined($ts->{bc}))
    {
        # XXX: don't create a new buffer cache if reloading...
        $ts->{bc} = 
          Genezzo::BufCa::BCFile->new(
                                      blocksize => $self->{blocksize},
                                      numblocks => $self->{bc_size},
                                      tsname    => $self->{NAME}
                                      );

        unless (defined($ts->{bc}))
        {
            my $deadmess =
                "Failed to allocate buffercache ";
            die $deadmess;
        }
    }

    my $filearr = $self->{files}->{filearr};
    if (defined($filearr))
    {
        my $ccnt = 1;

        foreach my $filestuff (@{$filearr})
        {
            my $filename;
            
            if (defined($filestuff) && scalar(@{$filestuff}))
            {
                $filename = $filestuff->[0];
                my $fileno;

                $fileno = $ts->{bc}->FileReg(FileName   => $filename,
                                             FileNumber => $ccnt)
                    if (defined($filename));

                # XXX XXX: fileno should match filearr index entry...
                whisper "registered $filename as $fileno   ($ccnt)";
            }
            $ccnt++;
        }

    }

    return 1;

} # end TSLoad

# invoked from Row::RSFile
sub TSGrowFile
{
    whoami;
    my $self = shift;
    my %required = (
                    smf => "no smf!",
                    tablename => "no tablename!",
                    object_id => "no object_id!", 
#                    bc  => "no bc!",
                    );

    my %args = ( # %optional,
                @_);

    return 0
        unless (Validate(\%args, \%required));

    my $smf  = $args{smf};
#    my $bc   = $args{bc};
    my $tablename = $args{tablename};
    my $object_id = $args{object_id};
    my $dict = $self->{dict};

    my ($fileno, $filename, $numbytes, $numblocks, @currExtent) 
        = $smf->_file_info(tablename => $tablename,
                           object_id => $object_id);
#    greet $fileno, $filename, $numbytes, $numblocks;

    my $filearr = $self->{files}->{filearr};

    greet $fileno, $filearr->[$fileno - 1];
    return 0
        unless (defined($filearr->[$fileno - 1]));

    if ($filename ne $filearr->[$fileno - 1]->[0])
    {
        greet "$filename does not match $filearr->[$fileno - 1]->[0]";
    }
    elsif ($numbytes != $filearr->[$fileno - 1]->[1])
    {
        greet "$numbytes does not match $filearr->[$fileno - 1]->[1]";
    }
    elsif ($numblocks != $filearr->[$fileno - 1]->[2])
    {
        greet "$numblocks does not match $filearr->[$fileno - 1]->[2]";
    }
    else
    {
        greet "match!";
        greet $fileno, $filename, $numbytes, $numblocks;
    }

    my $fileinfo = $dict->DictFileInfo(filenumber => $fileno);

#    greet $fileinfo;

    # fileinfo is _tsfiles row
    my $getcol = $dict->_get_col_hash("_tsfiles"); 

    if (defined($fileinfo->[$getcol->{increase_by}]) 
        && length($fileinfo->[$getcol->{increase_by}])) # increase by
    {
        use POSIX ; #  need some rounding
        
        my $inc        = $fileinfo->[$getcol->{increase_by}];
        my $blocksize  = $fileinfo->[$getcol->{blocksize}];
        my $new_numblocks;

#        greet $inc;

        if ($inc =~ m/^(.*)\%$/)
        { # pct increase
            my @ggg = ($inc =~ m/^(.*)\%$/);
            my $pct = shift @ggg;
            $pct = $pct/100;
#            whisper "pct: $pct";

            return 0
                unless ($pct); # check for 0%

            $new_numblocks = POSIX::floor($pct * $numblocks);

            unless ($new_numblocks)
            { # make sure at least 1 block for teeny pct increase
                $new_numblocks++;
            }
        }
        else # increase by fixed amount of bytes
        {
#            whisper "fixed: $inc";
            $new_numblocks = POSIX::floor($inc/$blocksize); 
            return 0
                unless ($new_numblocks);
        }

        # XXX XXX XXX XXX XXX XXX: increase size by minimum of new
        # extent, taking into account the pct increase...
        if ($new_numblocks < (2 * $currExtent[1]))
        {
            whisper "need to match increased extent size";
            $new_numblocks = 2 * $currExtent[1];
        }

        my @newinfo = $smf->SMGrowFile(filenumber => $fileno, 
                                       numblocks  => $new_numblocks,
                                       blocksize  => $blocksize);
#        greet @newinfo;

        if ((scalar(@newinfo) > 1) 
            && ($newinfo[1] > 0)) # new num blocks
        {
            my $new_numbytes = $blocksize * $newinfo[1];

#            greet $fileinfo;

            $fileinfo->[$getcol->{filesize}]  += $new_numbytes;
            $fileinfo->[$getcol->{numblocks}] += $newinfo[1];  # new num blocks

            my $stat = $dict->DictFileInfo(filenumber => $fileno,
                                           rowval     => $fileinfo);

            return 0
                unless (defined($stat));
            
            greet $filearr->[$fileno - 1];

            $filearr->[$fileno - 1]->[1] += $new_numbytes;
            $filearr->[$fileno - 1]->[2] += $newinfo[1];

            greet $filearr->[$fileno - 1];

            return 1;
        }

    }
    else
    {
        greet "no grow!";
    }

    return 0;
} # end TSGrowFile

sub TSExtendFile ()
{
    my ($self, $fileh, $blocksize, $numblks, $tsfile) = @_;

    my $packstr  = "\0" x $blocksize ; # fill with nulls

    my $refbuf = \$packstr;

    # set the checksum in the footer
    Genezzo::Block::Util::UpdateBlockFooter($refbuf, $blocksize);

    for (my $cnt = 0; $cnt < $numblks; $cnt++)
    {
        my $stat = gnz_write ($fileh, $packstr, $blocksize);
        unless (defined($stat))
        {
            die "write to file $tsfile failed: $! \n";
            return 0;
        }
        if ($stat < $blocksize)
        {
            die "incomplete write to file $tsfile - $stat bytes out of $blocksize \n";
            return $cnt;
        }
    }

    return $numblks;
}

sub TSAddFile ()
{
    my $self = shift;

    my $ts = $self->{the_ts};
    my $ts_prefix = $self->{ts_prefix};

    my %optional = (align_hdr => 1);
    my %required = (
                    filename => "no file name !",
                    filesize => "file size not specified !"
                    );

    my %args = (%optional,
                @_);

    my @file_stat;

    return @file_stat
        unless (Validate(\%args, \%required));

    my $blocksize = $self->{blocksize} ;

#    my ($filesizenum, $filesizesuffix) = ($args{filesize} =~ m/(^\d+)/

    my $tsfile = 
        File::Spec->file_name_is_absolute($args{filename}) ?
        ($args{filename}) :
        File::Spec->rel2abs(
                            File::Spec->catfile(
                                                $ts_prefix,
                                                $args{filename}
                                                ));

    if (-e $tsfile && !getUseRaw())
    {
        my $msg = "file $tsfile already exists\n";
        my %earg = (self => $self, msg => $msg,
                    severity => 'warn');
               
        &$GZERR(%earg)
            if (defined($GZERR));

        return @file_stat;
    }

    my ($numblks, $len_hdr, $true_size);
    {
        use POSIX ; #  need some rounding

        # NOTE: no spaces or "="s allowed in header tokens

        my $hstr = "GNZO V=" . $Genezzo::GenDBI::VERSION;   # V for version
        $hstr   .=   " bsz=" . $blocksize;
        $hstr   .=     " S=" . $Genezzo::GenDBI::RELSTATUS; # S for status
        $hstr   .=     " D=" . $Genezzo::GenDBI::RELDATE;   # D for date
        $hstr   .=  " M1=00";  # file header mod status (base 36)

        if ((exists($args{defs}))
            && (defined($args{defs})))
        {
            while (my ($kk, $vv) = each (%{$args{defs}}))
            {
                # ignore duplicates of standard set of tokens
                next if ($kk =~ m/^(V|bsz|S|D|M1)$/);
                # URL-style substitution to handle spaces, weird chars
                $kk =~ s/([^a-zA-Z0-9])/uc(sprintf("%%%02lx",  ord $1))/eg;
                $vv =~ s/([^a-zA-Z0-9])/uc(sprintf("%%%02lx",  ord $1))/eg;
                $hstr .= " " . $kk ."=" . $vv;
            }
        }

        # add some space to make at least 64 bytes.
        $hstr .= " " x (64 - length($hstr)) 
            if (length($hstr) < 64);

        if (getUseRaw() || $args{align_hdr})
        {
            # header alignment for raw io            
            my $min_al = $Genezzo::Util::ALIGN_BLOCKSIZE; 
            my $little_bit = length(pack("xN", 0));

            while (length($hstr) > ($min_al - $little_bit))
            {
                $min_al += $Genezzo::Util::ALIGN_BLOCKSIZE; 
            }

            # decrease available space by null terminator 
            # and header checksum so total header is align blocksize
            $min_al -= $little_bit;

            # add some space to make at least min_al bytes.
            $hstr .= " " x ($min_al - length($hstr)) 
                if (length($hstr) < $min_al);
        }

        my $cksum = unpack("%32C*", $hstr) % 65535;

        # write a null terminated string followed by checksum
        my $pack_hdr;
        if (0) # XXX XXX: can fix later
        {
            $pack_hdr = pack("Z*N", $hstr, $cksum) ;
        }
        else
        {
            # Z template is fixed in 5.7
            # ascii string, null byte, checksum
            $pack_hdr = pack("A*xN", $hstr, $cksum) ;
        }

        # number of available blocks total file minus header, divided
        # by blocksize
        $len_hdr = length($pack_hdr);
        $numblks = POSIX::floor(($args{filesize} - $len_hdr) / $blocksize) ;

        # calculate the true file size
        $true_size = $len_hdr + ($numblks * $blocksize);

        my $msg = "creating $tsfile...$numblks blocks + ";
        $msg   .= "$len_hdr bytes header\n";
        my %earg = (self => $self, msg => $msg,
                    severity => 'info');
               
        &$GZERR(%earg)
            if (defined($GZERR));

        my $outifile;
        open ($outifile, "> $tsfile")
            or die "Could not open $tsfile for writing : $! \n";

        my $hdr = gnz_write ($outifile, $pack_hdr, length($pack_hdr));
#      greet $hdr;

        unless ($self->TSExtendFile ($outifile, $blocksize, $numblks, 
                                     $tsfile))
        {
            my $msg = "failed to allocate $numblks blocks for file $tsfile\n";
            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
               
            &$GZERR(%earg)
                if (defined($GZERR));

            close ($outifile);
            return @file_stat;
        }
        
        close ($outifile);
    }

    # XXX XXX XXX XXX XXX: make used and unused dict _tsfiles
    # fileidx, versus a local array index.  That's what gets
    # loaded from the dictionary, anyway

    my $dict = $self->{dict};

    my %nargs = (
                 tsname     => $self->{NAME},
                 filename   => $args{filename}, # Note: not the full filespec
                 filesize   => $true_size,
                 blocksize  => $blocksize,
                 numblocks  => $numblks,
                 headersize => $len_hdr
                 );
    
    if (exists($args{increase_by}))
    {
        $nargs{increase_by} = $args{increase_by};
    }

    my $fileidx = $dict->_DictTSAddFile(%nargs);
    unless ($fileidx)
    {
        my $msg = "could not add file " . $args{filename} . "\n";
        my %earg = (self => $self, msg => $msg,
                    severity => 'warn');
        
        &$GZERR(%earg)
            if (defined($GZERR));

        return @file_stat;
    }

    if (1) # XXX XXX - use fileidx as array offset
    {
        $self->{files}->{filearr}->[$fileidx - 1] =
            [$tsfile, $true_size, $numblks];
        # list of unused file array        
        push (@{$self->{files}->{unused}}, $fileidx); 
    }
    else # OBSOLETE
    { # old style, not using tsfiles...
        my $numused =
            push (@{$self->{files}->{filearr}}, 
                  [$tsfile, $true_size, $numblks]);

        greet "numused",$numused;
        greet "fileidx",$fileidx;
        
        push (@{$self->{files}->{unused}}, 
              $numused); # list of unused file array
    }

    @file_stat = ($fileidx, $true_size, $len_hdr);
    return @file_stat;
} # end TSAddFile


# force a table to use a db file -- useful for init, startup
sub TSForceFile ()
{
    my $self = shift;
    my $ts = $self->{the_ts};

#    whoami;

    my %required = (tablename  => "no tablename! ",
                    filenumber => "no filenumber! ",
                    );

    my %args = (                    
                @_);

#    greet %args;

    return 0
        unless (Validate(\%args, \%required));

    my $tname  = $args{tablename};
    my $fileno = $args{filenumber};

#    greet $self->{tabsp_tables};

#    return 0
#        unless (exists($self->{tabsp_tables}->{$tname}));

    $self->{tabsp_tables}->{$tname}->{desc} = { filesused => [$fileno] };

    return 1;
}


#
# invoked from Row::RSTab
sub TSTableAFU ()
{
    my $self = shift;
    my $ts = $self->{the_ts};

#    whoami @_;

    my %required = (tablename  => "no tablename! ",
                    object_id  => "no object id! ",
                    );

    my %args = (                    
                @_);

    return undef
        unless (Validate(\%args, \%required));

    my $dict  = $self->{dict};
    my $tname = $args{tablename};

    return undef
        unless exists($self->{tabsp_tables}->{$tname});

    my @outi;
    $outi[1] = $self->{tabsp_tables}->{$tname}->{desc};

    return \@outi
        unless (exists($dict->{afu_tid_tv}));

    my $afu = $dict->{afu_tid_tv};

    return \@outi
        unless (defined($afu));

    my $objid = $args{object_id};

    my $sth = # prepare a search statement
        $afu->SQLPrepare(
                         start_key 
                         => [$objid, 0],
                         stop_key  
                         => 
                         [($objid+1), 0]);

    return \@outi
        unless ($sth->SQLExecute());

    $outi[0] = $sth;

    return \@outi;
}
#
# associate a table with a file
#
# invoked from Row::RSTab
sub TSTableUseFile ()
{
    my $self = shift;
    my $ts = $self->{the_ts};

#    whoami;

    my %required = (tablename  => "no tablename! ",
                    object_id  => "no object id! ",
                    filenumber => "no filenumber! ",
                    );

    my %args = (                    
                @_);

    return 0
        unless (Validate(\%args, \%required));

    my $tablename = $args{tablename};

    unless (exists($self->{tabsp_tables}->{$tablename}))
    {
        my $msg = "no href for $tablename  !!!\n";
        my %earg = (self => $self, msg => $msg,
                    severity => 'warn');
        
        &$GZERR(%earg)
            if (defined($GZERR));
            
        return 0;
    }

    # get "href" filesused information from tabsp_tables...
    my $href = $self->{tabsp_tables}->{$tablename}->{desc};

    $href->{filesused} = [] 
        unless (exists($href->{filesused}));

    # ("seen" test moved from RSTab) push if not there
    my %seen;
    for my $val (@{$href->{filesused}})
    {
        $seen{$val}++;
    }            

    my $fileno = $args{filenumber};

    return 1
        if ($seen{$fileno});

    push (@{$href->{filesused}}, $fileno);

    # XXX XXX try to avoid deep recursion 

    {
        my $dict = $self->{dict};
        my $stat = $dict->DictTableUseFile(tname => $tablename,
                                           object_id  => $args{object_id},
                                           filenumber => $args{filenumber});

        return 0
            unless ($stat);
    
    }

    return 1;
}

#
# get the last used file in the tablespace, or advance to the use the
# next unused file
#
# invoked from Row::RSTab::make_new_chunk
sub TS_get_fileno ()
{
    my $self = shift;

#    whoami;
    
    my $ts = $self->{the_ts};

    my %required = (
                    );

    my %args = (                    
                nextfile => 0,
                @_);

    return 0
        unless (Validate(\%args, \%required));

    
#  "TS_get_fileno: ", Data::Dumper->Dump([%args]), "\n";

    greet "filearr", $self->{files}->{filearr};
    greet "used", $self->{files}->{used};
    greet "unused", $self->{files}->{unused};

    # get the index of the last used file
    my $lastidx = scalar(@{$self->{files}->{used}});

    # get a new file if never had one
    $args{nextfile} = 1
        unless ($lastidx);

    $lastidx--;

    return ($self->{files}->{used}->[$lastidx])
        unless ($args{nextfile});

    my $nextfilenum;
    for my $ii (1..2)
    {
        # shift off the left, push on the right...
        $nextfilenum = 
            shift (@{$self->{files}->{unused}}); # list of unused files

        if (defined($nextfilenum))
        {
            push (@{$self->{files}->{used}}, $nextfilenum);
            last;
        }
        else
        {
            last unless ($self->TSGrowTablespace());
        }
    }
    return $nextfilenum;
}

sub TSGrowTablespace
{
    whoami;
    my $self = shift;
    # name, tsid
    my %nargs;
    $nargs{tsname} = $self->{NAME};
    $nargs{tsid}   = $self->{tsid};
    greet %nargs;
    return ($self->{dict}->DictGrowTablespace(%nargs));
}

sub TSFileInfo ()
{
    my $self = shift;
    
    my $ts = $self->{the_ts};

    my %required = (
                    );

    my %args = (                    
                fileno => 0,
                @_);

#    "TSFileInfo: ", Data::Dumper->Dump([%args]), "\n";

    return undef
        unless (Validate(\%args, \%required));

    my $filearr = $self->{files}->{filearr};
    my $maxidx = scalar(@{$filearr});

    return undef
        unless ($maxidx);

    my $fileidx = $args{fileno};

    unless (defined($fileidx))
    {
        my $msg = "null file idx!\n";
        my %earg = (self => $self, msg => $msg,
                    severity => 'warn');
        
        &$GZERR(%earg)
            if (defined($GZERR));

#        {
#            local $Genezzo::Util::QUIETWHISPER = 0;
#            local $Genezzo::Util::WHISPERDEPTH = 10;
#            whoami("nfi");
#        }

        return undef;
    }

#    local $Genezzo::Util::QUIETWHISPER = 1; # XXX: quiet the whispering

    whisper "fileinfo: $fileidx";

    return undef
        if (($fileidx > $maxidx) 
            || ($fileidx <= 0));

    # return a copy of the info so we don't munge the real values...
    my $foo = $filearr->[$fileidx - 1]; # NOTE: subtract one to put
                                        # file #1 in position zero
    unless (defined($foo))
    {
        my $msg = "invalid array ref for file index $fileidx\n";
        my %earg = (self => $self, msg => $msg,
                    severity => 'warn');
        
        &$GZERR(%earg)
            if (defined($GZERR));

        return undef;
    }
    my @retarr = @{$foo};

    push @retarr, $fileidx;
        
    return (\@retarr);
    
}

sub TSDropTable ()
{
    my $self = shift;
    
    my $ts = $self->{the_ts};
    
    my %optional = (
                    silent_exists => 1,
                    silent_notexists => 0,
                    str_exists => "Dropped table THETABLENAME in tablespace ",
                    str_notexists => 
                    "No such table THETABLENAME in tablespace "
                    );
    
    my %required = (
                    tablename => "no table name !"
                    );

    my %args = (%optional,
                @_);

    return 0
        unless (Validate(\%args, \%required));

    my $tabi = $self->tables();
    my $tablename = $args{tablename};

    if (exists($tabi->{$tablename}))
    {
        delete $tabi->{$tablename};
        unless ($args{silent_exists})
        {
            my $outstr = $args{str_exists} ;
            $outstr =~ s/THETABLENAME/$tablename/;

            my $msg = $outstr .  $self->name() . "\n" ; 
            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
        
            &$GZERR(%earg)
                if (defined($GZERR));
        }
    }
    else
    {
        unless ($args{silent_notexists})
        {
            my $outstr = $args{str_notexists} ;
            $outstr =~ s/THETABLENAME/$tablename/;

            my $msg = $outstr .  $self->name() . "\n" ; 
            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
        
            &$GZERR(%earg)
                if (defined($GZERR));
        }
    }

    return (1);
} # end TSDropTable ()



END { }       # module clean-up code here (global destructor)


1;  # don't forget to return a true value from the file

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::Tablespace - a class that defines a tablespace, the relationship
between a collection of files on disk and a set of tables in the
dictionary.

=head1 SYNOPSIS


=head1 DESCRIPTION

=head1 ARGUMENTS

=head1 CONCEPTS

A Tablespace is a storage unit for a table or many tables, and a table
only exists in a single tablespace.  Each tablespace is composed of
one or more datafiles, and each datafile is only associated with a
single tablespace.

The tablespace object (tso) is used to co-ordinate several major
file/storage subsystems.  For example, each datafile has local state
information (free space, used extents) controlled by space management
(SpaceMan::SMFile), but the overall information about a table and its
datafiles is stored in the dictionary tables.  Finally, the buffer
cache is used to mediate access to the actual disk files, dealing with
issues like locking, concurrency, and caching.  When a table is
updated, it uses the buffer cache to write to a datafile.  If the
current datafile is full, the table will use the tso to find the next
available file, and the tso will update the dictionary to note that
the file is in use.  The tso also propogates storage management
preferences stored in the dictionary to the file space management,
controlling extent size growth.



=head1 FUNCTIONS

=head1 LIMITATIONS

=head1 TODO

=over 4

=item  filearr, used, unused: should match dict _tsfiles fileidx - done 3.21?

=item notion of buffercache associated the tablespace object --
possible multiple active bc's, with different
characteristics/semantics, e.g. a bc for temp space with different
blocksize, lacking txn recovery?  Need to guarantee that all clients
of a tso use the same bc for consistency/locking/txn support

=item  use compatibility matrix to drive automatic upgrade capability

=back

=head1 AUTHOR

Jeffrey I. Cohen, jcohen@genezzo.com

=head1 SEE ALSO

L<Genezzo::PushHash::PushHash>,
L<Genezzo::Dict>,
L<perl(1)>.

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
