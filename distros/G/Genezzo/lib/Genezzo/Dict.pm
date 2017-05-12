#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/RCS/Dict.pm,v 7.29 2007/06/26 08:13:35 claude Exp claude $
#
# copyright (c) 2003-2006 Jeffrey I Cohen, all rights reserved, worldwide
#
#
package Genezzo::Dict;  # assumes Some/Module.pm

use strict;
use warnings;

use Data::Dumper ;
use Genezzo::Util;
use Genezzo::Tablespace ;
use File::Spec;
use Genezzo::Index::btHash;
use Genezzo::Havok;
use Genezzo::BasicHelp;

BEGIN {
    our $VERSION;
    $VERSION = do { my @r = (q$Revision: 7.29 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

}

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
        else
        {
            if (exists($args{no_info}))
            {
                # don't print info if no_info set...
                return;
            }
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
my %p1_tab = (
                allfileused => "tid=c fileidx=n fileid=c"
                );

my %coretabs;
my %corecolnum;
my %coretid; # hash of table name to tid for _tab1/_col1

BEGIN {

    %coretid = (
                 _pref1   => 1,
                 _tspace  => 2,
                 _tsfiles => 3,
                 _tab1    => 4,
                 _col1    => 5,

                allfileused => 6 # XXX XXX: not true core
                );

    $coretabs{"_pref1"} = 
        [
         "pref_key=c", "pref_value=c",
         "creationdate=c", "pref_desc=c"
         ];

    $coretabs{"_tspace"} = 
        [
         "tsid=n",
         "tsname=c", "creationdate=c",
         "blocksize=n",
         "base_objid=n",
         "addfile=c"
         ];

    $coretabs{"_tsfiles"} = 
        [
         "tsid=n", "creationdate=c", "fileidx=n", 
         "filename=c", "filesize=n", "blocksize=n",
         "numblocks=n", "used=c", 
         "initial_size=n", 
#         "headersize=n",
         "increase_by=c", 
         ];

    $coretabs{"_tab1"} = 
        [
         "tid=n",
         "tsid=n",
         "tname=c", "owner=c", 
         "creationdate=c", 
         "numcols=n", # XXX XXX: is this necessary?
         "numfixed=n", "numvar=n",  # XXX XXX: move these to separate table?
         "object_type=c"
         ];

    $coretabs{"_col1"} = 
        [
         "tid=n", "tname=c", "colidx=n", "colname=c", 
         "coltype=c",
         "varlen=c", "nullable=c", "defaultval=c", "maxlen=n"
         ];

    # build hash for each table mapping column name to column number
    # (array-style, starting at zero)

    while ( my ($kk, $vv) = each (%coretabs))
    {
        $corecolnum{$kk} = {};
        for my $colnum (0..(scalar(@{$vv}) - 1))
        {
            my ($colname, $coltype) = split('=', $vv->[$colnum]);
            $corecolnum{$kk}->{$colname} = $colnum;
        }
    }

#    greet %corecolnum;

}

# Note: localtime, not GMT/UCT.  string sorting not suitable 
# for year < 1 and year > 9999
sub time_iso8601
{
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
        localtime(time);
    
    # example: 2002-12-19T14:02:57
    
    # year is YYYY-1900, mon in (0..11)

    my $tstr = sprintf ("%04d-%02d-%02dT%02d:%02d:%02d", 
                        ($year + 1900) , $mon + 1, $mday, $hour, $min, $sec);
    return $tstr;
}

sub HavokUse
{
    my %required = (
                    function_args => "no args!",
                    dict => "no dict!",
                    dbh => "no dbh!"
                    );

    my %args = ( # %optional,
                @_);

    return undef
        unless (Validate(\%args, \%required));

    my $fn_arg = $args{function_args};

    my %nargs;

    return undef
        unless (defined($fn_arg) && scalar(@{$fn_arg}));

    my $mod   = $fn_arg->[0];
    my $phase = $fn_arg->[1];
    my $dict  = $args{dict};
    my $dbh   = $args{dbh};

    $nargs{module} = $mod;
    $nargs{phase}  = $phase if (defined($phase));
    $nargs{dict}   = $dict;
    $nargs{dbh}    = $dbh;

    my $stat;
    my $gzerr_info_state = 1;

    $gzerr_info_state = Genezzo::Util::get_gzerr_status(GZERR => $GZERR,
                                                        self  => $dict)
        if (defined($GZERR));
    Genezzo::Util::set_gzerr_status(GZERR  => $GZERR, 
                                    status => 0,
                                    self   => $dict
                                    )
        if (defined($GZERR));

    $stat = Genezzo::Havok::HavokUse(%nargs);

    Genezzo::Util::set_gzerr_status(GZERR  => $GZERR, 
                                    status => $gzerr_info_state,
                                    self   => $dict)
        if (defined($GZERR));

    return $stat;
}


# make all your functions, whether exported or not;

# private
sub _init
{
    my $self = shift;
    my %optional = (
                    init_db => 0,       # initialize the database
                    force_init_db => 0, # blow away existing db
                    name      => "default",
                    dbsize    => $Genezzo::Util::DEFDBSIZE,
                    blocksize => $Genezzo::Util::DEFBLOCKSIZE,
                    use_havok => 1      # use havok if available
                    );

    my %required = (
                    gnz_home => "no gnz_home supplied !"
                    );

    my %args = (%optional,
                @_);

    return 0
        unless (Validate(\%args, \%required));

    my ($msg, %earg);

    $self->{gnz_home}    = $args{gnz_home};
    $self->{dbfile}      = $args{name} . ".dbf";


    # Get all command line definitions
    if ((exists($args{unknown_defs}))
        && (defined($args{unknown_defs})))
    {
        # unknown command line definitions
        $self->{unknown_defs} = $args{unknown_defs};
    }
    else 
    {
        $self->{unknown_defs} = {};
    }
    # Get all command line file header definitions
    if ((exists($args{fhdefs}))
        && (defined($args{fhdefs})))
    {
        # file header definitions
        $self->{fhdefs} = $args{fhdefs};
    }
    else
    {
        $self->{fhdefs} = {};
    }
    # get all actual file header info
    $self->{fileheaderinfo} = {}; # set when load SYSTEM tablespace
    # get dictionary preference table info
    $self->{prefs} = {};

    $self->{basichelp} = Genezzo::BasicHelp->new();

    # for raw filesystems we pretend /dev/raw is the home directory
    # and raw1 is the file.

    if($self->{gnz_home} eq "/dev/raw"){
        setUseRaw(1);
    }else{
        setUseRaw(0);
    }

    if(getUseRaw()){
        $self->{dbfile}      = "raw1";    # need to be able to change this
    }else{
        $self->{dbfile}      = $args{name} . ".dbf";
    }

    my $fhts;   # gnz_home table space

    if(getUseRaw()){
        $fhts = $self->{gnz_home};
    }else{
	$fhts = File::Spec->catdir($self->{gnz_home}, "ts");
    }

    $self->{dbfile_full} =
        File::Spec->rel2abs(
                            File::Spec->catfile(
                                                $fhts,
                                                $self->{dbfile})
                            );

    # convert file and blocksize specifications to pure numbers
    $self->{dbsize}      = HumanNum(val  => $args{dbsize},
                                    name => "db file size"); 
    $self->{blocksize}   = HumanNum(val  => $args{blocksize},
                                    name => "blocksize"); 

    if ($args{use_havok} eq "0")
    {
        whisper "havok is disabled";
        $self->{use_havok} = 0; # disable havok
    }
    else
    {
        $self->{use_havok} = 1;
    }

    return 0
        unless (defined($self->{dbsize}) 
                && defined($self->{blocksize}));

    return 0
        unless (NumVal(val  => $self->{blocksize},
                       name => "blocksize",
                       MIN  => $Genezzo::Util::MINBLOCKSIZE,
                       MAX  => $Genezzo::Util::MAXBLOCKSIZE));
    return 0
        unless (NumVal(val  => $self->{dbsize},
                       name => "db file size",
                       MIN  => 40 * $self->{blocksize}, # 40 blocks
                       MAX  => $Genezzo::Util::MAXDBSIZE));  

    $self->{use_constraints} = 0; # Note: used in get_table
    $self->{dictinit} = 0; 

    use File::Path;

    if ($args{force_init_db} > 0)
    {
        $args{init_db} = 1;

        if (-e $fhts)    
        {
            $msg = "\nFORCE: remove existing gnz_home\n\n";
            %earg = (self => $self, msg => $msg, severity => 'warn');

            &$GZERR(%earg)
                if (defined($GZERR));

            rmtree($fhts, 1, 1); # XXX XXX : what should permissions be?
        }
    }

    unless ((-e $self->{gnz_home})    
            && (-e $fhts))
    {
        unless ($args{init_db} > 0)
        {
            $msg = "no gnz_home at $self->{gnz_home}\n\n";
            %earg = (self => $self, msg => $msg, severity => 'fatal');

            &$GZERR(%earg)
                if (defined($GZERR));

            return 0;
        }

        $msg = "Create new gnz_home at $self->{gnz_home}\n";
        %earg = (self => $self, msg => $msg, severity => 'info');
        
        &$GZERR(%earg)
            if (defined($GZERR));

        my $fh   = $self->{gnz_home};
#        system "mkdir $fh";
#        system "mkdir $fhts";
        mkpath($fhts, 1, 0711); # XXX XXX : what should permissions be?
    }


    $self->{phase_three} = 0;

    my $gzerr_info_state = 1;

    $gzerr_info_state = Genezzo::Util::get_gzerr_status(GZERR => $GZERR,
                                                        self  => $self)
        if (defined($GZERR));
    Genezzo::Util::set_gzerr_status(GZERR => $GZERR, status => 0,
                                    self  => $self)
        if (defined($GZERR));

    my $clean_init = 1;

    if (defined($args{init_db}) && ($args{init_db} > 0))
    {
        $clean_init = 0;

        $self->{started}  = 1; # Note: pretend dictionary already started
        $self->{dictinit} = 1;

        # PHASE 0: create the basic dictionary tables

        goto L_bad_init_db 
            unless ($self->_DictDBInit());
        goto L_bad_init_db 
            unless ($self->DictSave());
        goto L_bad_init_db 
            unless ($self->_loadDictMemStructs ());

        if ($self->{dictinit})
        {
            # PHASE 1: create allfileused to register dict tables in
            # SYSTEM tablespace
            goto L_bad_init_db 
                unless ($self->_DictDBDefineTable(\%p1_tab));

            # add all current dictionary tables to allfileused
            while (my ($kk, $vv) = each (%{$self->{dict_tables}}))
            {
                goto L_bad_init_db
                    unless $self->DictTableAllTab(operation  => "usefile",
                                                  tname      => $kk,
                                                  filenumber => 1)
                                                  
            }
            $self->{dictinit} = 0; 

            # PHASE 2: create secondary dictionary tables and indexes

            my $cons1_def = 
                "cons_id=n cons_name=c cons_type=c tid=n " .
                "check_text=c check2=c ref_cons_name=c delete_rule=c status=c";

            my $ind1_def = 
                "iid=n tsid=n iname=c owner=c creationdate=c " .
                "numcols=n tid=n tname=c unique=c cons_id=n";


            # use "posn" vs "position", which is a SQL reserved word...
            my %p2_tab = 
                (
                 cons1      => $cons1_def,
                 cons1_cols => "cons_id=n tid=n colidx=n posn=n",

                 ind1       => $ind1_def,
                 ind1_cols  => "iid=n tid=n colidx=n posn=n",
                 );
            
            goto L_bad_init_db 
                unless ($self->_DictDBDefineTable(\%p2_tab));

            # Phase 3: Havok Table
#            my $havok_def = 
#                "hid=n modname=c owner=c creationdate=c";
#            my %p3_tab =
#                (
#                 havok => $havok_def
#                 );
#            goto L_bad_init_db 
#                unless ($self->_DictDBDefineTable(\%p3_tab));

            # define constraints on all tables
            goto L_bad_init_db 
                unless ($self->dictp2_define_cons());


        } # end self->dictinit
        goto L_bad_init_db 
            unless ($self->DictSave());

        $self->{phase_three} = 1;

        $clean_init = 1;

      L_bad_init_db:
        # skip the clean_init

    } # end defined init_db

    Genezzo::Util::set_gzerr_status(GZERR => $GZERR, 
                                    status => $gzerr_info_state,
                                    self  => $self)
        if (defined($GZERR));
    
    return 0
        unless ($clean_init);

    $self->{started} = 0;

    return ($self->doDictPreLoad ());


}


sub new 
{
    my $invocant = shift;
    my $class = ref($invocant) || $invocant ; 
    my $self = { };
    
    $self->{dict_tables}   = {};

    $self->{ts_tsid_idx}   = {}; # XXX XXX

    $self->{afu_tid_idx}   = {}; # XXX XXX - allfilesused
    $self->{tsf_fid_idx}   = {}; # XXX XXX - tsfiles 

    $self->{tablespaces} = {};

    my $newdict =  bless $self, $class;

    my %args = (@_);

    if ((exists($args{GZERR}))
        && (defined($args{GZERR}))
        && (length($args{GZERR})))
    {
        # NOTE: don't supply our GZERR here - will get
        # recursive failure...
        $self->{GZERR} = $args{GZERR};
        my $err_cb     = $self->{GZERR};
        # capture all standard error messages
        $Genezzo::Util::UTIL_EPRINT = 
            sub {
                &$err_cb(self     => $self,
                         severity => 'error',
                         msg      => @_); };
        
        $Genezzo::Util::WHISPER_PRINT = 
            sub {
                &$err_cb(self     => $self,
#                         severity => 'error',
                         msg      => @_); };
    }

    return undef
        unless ($self->_init(%args));

    return $newdict;

} # end new


sub GetDBH
{
    my $self = shift;

    return undef
        unless (exists($self->{dbh})
                && defined($self->{dbh}));

    return $self->{dbh};
}

sub SetDBH
{
    my $self    = shift;
    my $dbh     = shift;
    my $init_db = shift;

    return undef
        unless (defined($dbh));

    $self->{dbh} = $dbh;

    if ($init_db)
    {
        whisper "\ninit\n";
    }
#    $dbh->Parseall("s _tab1 *");

    if ($self->{phase_three})
    {
        $self->DictStartup();
        
        # phase three: recursive dictionary sql
        whisper "load recursive sql";

        my $dict_sql = "dict.sql";
        my $dict_fh; 

        my $subdir = "Genezzo";        
        my $dir_h;

        my @file_list;

        for my $dir (@INC) 
        {
            my $dspec = File::Spec->catdir($dir, $subdir);

            whisper "dir: $dspec";

            if ( opendir($dir_h, $dspec) ) 
            {
                my $fnam;
                while ($fnam  = readdir($dir_h))
                {
                    if ($fnam =~ m/^dict\.sql$/)
                    {
                        $fnam = 
                            File::Spec->rel2abs(
                                                File::Spec->catfile(
                                                                    $dir,
                                                                    $subdir,
                                                                    $dict_sql
                                                                    ));
                        whisper "fnam: $fnam";
                        push @file_list, $fnam;
                        last;
                    }
                } # end while
                closedir $dir_h;
            } # end if open
            last
                if (scalar(@file_list));
        } # end for my dir
        

        return undef
            unless (scalar(@file_list));
        $dict_sql = pop @file_list;

        return undef        
            unless (open ($dict_fh, "< $dict_sql" ) );
        
        if (1)
        {
            my ($msg, %earg);
            my $gzerr_info_state = 1;

            $gzerr_info_state = 
                Genezzo::Util::get_gzerr_status(GZERR => $GZERR, 
                                                self  => $self)
                if (defined($GZERR));
            Genezzo::Util::set_gzerr_status(GZERR => $GZERR, status => 0,
                                            self  => $self)
                if (defined($GZERR));

            my $prev_line = undef;  # accumulated input of 
                                    # multi-line statement

          L_w1:
            while (<$dict_fh>) {
                my $in_line = $_;
                if (defined($prev_line))
                {
#                        $prev_line .= "\n" ;
                        # input is already newline terminated
                }
                else
                {
                    next L_w1 if ($in_line =~ m/^REM/i);
                    next L_w1 unless ($in_line =~ m/\S/);

                    $prev_line = "" ;
                }
                $prev_line .= $in_line;

                if ($in_line !~ m/;$/)
                {
                    next L_w1;
                }
                else
                {
                    $prev_line =~ s/;(\s*)$//  # Note: remove the semicolon
                            ;
                }

                whisper "dict.sql: $prev_line";

                $dbh->Parseall ($prev_line);
                $prev_line = undef;
            } # end big while
            close ($dict_fh);


            # update the pref1 export_start_tid 

            my $last_dict_tid;
            {
                my $sth;
                $sth = $dbh->prepare("select count(*) from _tab1");

                $sth->execute();

                my @lastfetch = $sth->fetchrow_array();
    
                if (scalar(@lastfetch))
                {
                    $last_dict_tid = ($lastfetch[0]);
                }
                
                $sth = 
                    $dbh->prepare("update _pref1 set pref_value=$last_dict_tid where pref_key=\'export_start_tid\'");

                $sth->execute();
                
                ($self->DictSave());
            }

            Genezzo::Util::set_gzerr_status(GZERR  => $GZERR, 
                                            status => $gzerr_info_state,
                                            self   => $self)
                if (defined($GZERR));

        } # end 


        $self->DictShutdown();
        $self->{phase_three} = 0;
    } # end if phase_three

    return $dbh;
}

sub _sql_execute
{
#    greet (@_);
    my $self = shift;
    
    my %required = (sql_statement => "no sql!");

    my %args = (
#                %optional,
		@_
                );

    return undef
        unless (Validate(\%args, \%required));

    my $dbh = $self->{dbh};
    unless (defined($dbh))
    {
        my $msg = "recursive sql failure: no database handle";
        my %earg = (self => $self, msg => $msg,
                    severity => 'warn');
                
        &$GZERR(%earg)
            if (defined($GZERR));
        return undef;
    }

    my $sql = $args{sql_statement};

    my $sth = 
        $dbh->prepare($sql);
        
    unless (defined($sth) && ($sth->execute()))
    {
        my $msg = "recursive sql failure: $sql";
        my %earg = (self => $self, msg => $msg,
                    severity => 'warn');
                
        &$GZERR(%earg)
            if (defined($GZERR));
        return undef;
    }

    return $sth;

} # end _sql_execute

sub _get_tsid_by_name
{
    my $self = shift;
    my $tsname = shift;

    return undef
        unless (defined($tsname));

    if ($tsname eq 'SYSTEM')
    {
        return 1; # easy peasy: SYSTEM is tablespace # 1
    }

    my $sql = 'select tsid from _tspace where tsname = \'' .
        $tsname . '\'';

    my $sth =  $self->_sql_execute(sql_statement => $sql);
        
    return undef
        unless (defined($sth));
    my @ggg = $sth->fetchrow_array();

    return undef
        unless (scalar(@ggg));

    my $tsid = shift @ggg;
    
    return $tsid;
}

sub name
{
    my $self = shift;
    $self->{NAME} = shift if @_ ;

    return $self->{NAME};
} # end name

sub DictDump 
{
    my $self = shift;

    my @params = @_;

    # XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX
    # NOTE: dumper still prints - does not use gzerr!!
    # XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX

    if ((0 == scalar (@params)) || ($params[0] =~ m/ALL/i))
    {
        print Dumper(%{ $self->{dict_tables}}), "\n";
    }
    elsif ($params[0] =~ m/help/i)
    {
        my %legitdefs = (
                         all     => "dump dictionary table structs",
                         help    => "this message",
                         table   => "names of dictionary tables",
                         ts      => "dump tablespace structs (very long)",
                         tstab   => "dump loaded tablespace tables (short)",
                         prefs   => "startup prefs",
                         bc      => "buffer cache (per tablespace)",
                         tsidx   => "tablespace index information",
                         files   => "file headers and extent info"
                         );

        print "\n";
        while (my ($kk, $vv) = each (%legitdefs))
        {
            print "$kk:\t$vv\n";
        }
        print "\n";        
    }
    elsif ($params[0] =~ m/TABLE/i)
    {
        if (exists ($self->{dict_tables}))
        {
            my $tcount = 0;
            foreach my $kk (sort (keys %{$self->{dict_tables}} ))
            {
                $tcount++;
                print "$kk \n";
            }
            print "\n$tcount tables\n";
        }
        else
        {
            print "no tables ! \n";
        }
    }
    elsif ($params[0] =~ m/^TS$/i)
    {
        print Dumper($self->{tablespaces});
    }
    elsif ($params[0] =~ m/^TSTAB/i) # dump each ts object separately
    {
        while (my ($kk, $vv) = each (%{$self->{tablespaces}}))
        {
            print "tablespace: $kk\n";
          #  print Dumper($vv->{tsref});
            for my $jj (keys(%{$vv}))
            {
                print "  $jj\n";
                if ($jj eq 'table_cache')
                {
                    for my $tt (keys(%{$vv->{table_cache}}))
                    {
                        print "    $tt\n";
                    }
                }
            }
        }
    }
    elsif ($params[0] =~ m/^PREF/i) # dump prefs
    {
        print Dumper($self->{prefs});
        print Dumper($self->{fileheaderinfo});
        print Dumper($self->{unknown_defs});
        print Dumper($self->{fhdefs});
    }
    elsif ($params[0] =~ m/^BC/i) # dump buffer cache
    {
        while (my ($kk, $vv) = each (%{$self->{tablespaces}}))
        {
            print "tablespace: $kk\n";
            my $bc1;
            if (exists($vv->{tsref})
                && exists($vv->{tsref}->{the_ts})
                && exists($vv->{tsref}->{the_ts}->{bc}))
            {
                $bc1 = $vv->{tsref}->{the_ts}->{bc};

                my $h1 = $bc1->Dump();
                print Dumper($h1)
                    if (defined($h1));
            }
     
        }
    }
    elsif ($params[0] =~ m/^tsidx/i) # dump tablespace index information
    {
        print "ts_tsid\t", Dumper($self->{ts_tsid_idx});
        print "afu_tid\t", Dumper($self->{afu_tid_idx});
        print "tsf_fid\t", Dumper($self->{tsf_fid_idx});
    }
    elsif ($params[0] =~ m/^files/i) # dump block zero information
    {
        my $tsf   =  $self->_get_table(tname => "_tsfiles");

        return 0
            unless  (defined($tsf));

        return 0
            unless (exists($self->{tablespaces}->{SYSTEM}));

        my $ts1 = $self->{tablespaces}->{SYSTEM};

        return 0
            unless (exists($ts1->{tsref})
                    && exists($ts1->{tsref}->{the_ts})
                    && exists($ts1->{tsref}->{the_ts}->{bc}));

        my $bc1 = $ts1->{tsref}->{the_ts}->{bc};

        while (my ($kk, $vv) = each (%{$tsf}))
        {
            my $getcol  = $corecolnum{"_tsfiles"};
            my $fsize   = $vv->[$getcol->{filesize}];
            my $blksize = $vv->[$getcol->{blocksize}];
            my $filenum = $vv->[$getcol->{fileidx}];
            my $numblks = $vv->[$getcol->{numblocks}];

            my $fhts;     # gnz_home table space

	    if(getUseRaw()){
		$fhts = $self->{gnz_home};
	    }else{
                $fhts = File::Spec->catdir($self->{gnz_home}, "ts");
	    }

            my $fnam1   = $vv->[$getcol->{filename}];

            my $fname   = 
                File::Spec->file_name_is_absolute($fnam1) ?
                $fnam1 : 
                File::Spec->rel2abs(
                                    File::Spec->catfile(
                                                        $fhts,
                                                        $fnam1
                                                        ));

            print "\n$fname\n";

            my $smf = Genezzo::SpaceMan::SMFile->new($fname,
                                                     $fsize,
                                                     $numblks,
                                                     $bc1,
                                                     $filenum);
            $smf->dump()
                if (defined($smf));
        } # end while
    }
    else
    {
        return 0;
    }

    return 1;
}

##sub dicthook1 { print "original\n";}
sub DictStartup
{
    my $self = shift;

    my %required = (
                    );

    my %args = (
		@_);
#		tablespace, tname

    greet (%args);

#    return 0
#        unless (Validate(\%args, \%required));

    return 1
        if ($self->{started});

    $self->{started} = 1;

    my $tshref = $self->{tablespaces};
    
    my $tsname = "SYSTEM";
    # NOTE: clear out the tablespace info to force a
    # clean tablespace reload from _get_table.
    delete $tshref->{$tsname};

    return 0
        unless ($self->_loadDictMemStructs ());

    # XXX: reload the system tablespace
    return 0
        unless ($self->_reloadTS("SYSTEM"));

    # install constraints
    {
        my $tspace = "SYSTEM";
        my $tshref = $self->{tablespaces};
        my $ts_cache = $tshref->{$tspace}->{table_cache};

        while ( my ($tname, $thsh) = each(%{$ts_cache}))
        {
            my $tid = $self->{dict_tables}->{$tname}->{object_id};

#            greet $tname, $tid;
            my $cfn = $self->_make_constraint_check_fn($tid);
            if (defined($cfn))
            {
#                print "got constraint for $tname\n";
#                print ref($$thsh), "\n";
                my $realtie = tied(%{$$thsh});
                $realtie->_constraint_check($cfn);
            }
            else
            {
#                print "no constraint for $tname\n";
            }
        } # end for

        $self->{use_constraints} = 1; # Note: used in get_table
    }

    if (!$self->{phase_three} && $self->{use_havok})
    {
        $Genezzo::Havok::GZERR = 
            sub {
                my $err_cb = $self->{GZERR};
                return &$err_cb(@_);
            };
        return 0
            unless Genezzo::Havok::HavokInit(dict => $self, flag => 0);
    }

    # use sys_hook to define a dictionary startup hook
    if (!$self->{phase_three} && defined(&dicthook1))  
    {
        return 0
            unless (dicthook1(self => $self));
    }

    return 1;
} # end DictStartup

sub DictShutdown
{
    my $self = shift;

# "Shut it off, shut it off buddy now I shut you down"

    my %required = (
                    );

    my %args = (
		@_);
#		tablespace, tname

    greet (%args);

#    return 0
#        unless (Validate(\%args, \%required));

    return 1
        unless ($self->{started});

    $self->{started} = 0;
    $self->{use_constraints} = 0;
    return ($self->doDictPreLoad ());
}

# private
sub _DictDBDefineTable 
{
    my ($self, $inhash) = @_;

    while (my ($kk, $vv) = each (%{$inhash}))
    {
        my %coldatatype;
        my $colidx;
        my @coldefs = split(' ', $vv);

        %coldatatype = ();
        $colidx = 1;
            
        foreach my $col (@coldefs)
        {
            my ($colname, $dtype) = split('=', $col);
            $coldatatype{$colname} = [$colidx, $dtype];
            $colidx++;
        }
        return 0
            unless $self->DictTableCreate (tname => $kk,
                                           tabdef => \%coldatatype,
                                           tablespace => "SYSTEM",
                                           );
        
    }

    return 1;
}

#private
sub _DictDefineCoreTabs
{
    my ($self, $tsname, $deffile, $deffilsize, $makepref1, $hdrsize) = @_;

    # if makepref1 is set, build the preferences table, else use the
    # existing one in default.dbf
    if ($makepref1)
    {
        my %basicprefs = (
                          blocksize    => $self->{blocksize},
                          home         => $self->{gnz_home},
                          default_file => $deffile,
                          bc_size      => 40,
                          automount    => "TRUE", # "FALSE",
                          genezzo_version  => $Genezzo::GenDBI::VERSION,
                          export_start_tid => 1
                          );

        whisper "create _pref1...\n";
        my $tablename = "_pref1";

        my $ptable = $self->_get_table(tname => $tablename,
                                       object_id  => $coretid{$tablename},
                                       tablespace => $tsname);

        my $realtie = tied(%{$ptable});

        # ct _pref1 name=c value=c creationdate=c
        my $rowarr = [
                      "pref_key",
                      "pref_value",
                      time_iso8601(),    # creationdate
                      "init"
                      ];

        my $getcol = $corecolnum{"_pref1"};
        
        while (my ($kk, $vv) = each (%basicprefs))
        { 
            $rowarr->[$getcol->{pref_key}]   = $kk;
            $rowarr->[$getcol->{pref_value}] = $vv;
            unless (defined($realtie->HPush($rowarr)))
            {
                my $msg = "Failed to create table $tablename";
                my %earg = (self => $self, msg => $msg, severity => 'fatal');
                
                &$GZERR(%earg)
                    if (defined($GZERR));

                return 0;
            }
        }
        if (exists($self->{unknown_defs}))
        {
            $rowarr->[$getcol->{pref_desc}]   = "init - unknown";
            while (my ($kk, $vv) = each (%{$self->{unknown_defs}}))
            { 
                $rowarr->[$getcol->{pref_key}]   = $kk;
                $rowarr->[$getcol->{pref_value}] = $vv;
                unless (defined($realtie->HPush($rowarr)))
                {
                    my $msg = "Failed to create table $tablename";
                    my %earg = (self => $self, msg => $msg, 
                                severity => 'fatal');
                
                    &$GZERR(%earg)
                        if (defined($GZERR));

                    return 0;
                }
            }
        }
    }

    # create _tspace
    {
        whisper "create _tspace...\n";
        my $tablename = "_tspace";

        # XXX XXX XXX: get the tablespace blocksize!!
        my $blocksize = $self->{blocksize};
        
        my $tstable = $self->_get_table(tname => $tablename,
                                        object_id  => $coretid{$tablename},
                                        tablespace => $tsname);
        
        # ct _tspace tsid=n tsname=c creationdate=c 
        my $rowarr = [
                      1,        # first tablespace
                      $tsname,  # tablespace name
                      time_iso8601(),    # creationdate
                      $blocksize
                      ];
        
        my $realtie = tied(%{$tstable});
        unless (defined($realtie->HPush($rowarr)))
        {
            my $msg = "Failed to create table $tablename";
            my %earg = (self => $self, msg => $msg, severity => 'fatal');
            
            &$GZERR(%earg)
                if (defined($GZERR));
            
            return 0;
        }

    }
    
    # create _tsfiles
    {
        whisper "create _tsfiles...\n";
        my $tablename = "_tsfiles";
        
        # XXX XXX XXX: get the tablespace blocksize!!
        my $blocksize = $self->{blocksize};
        
        my $tstable = $self->_get_table(tname => $tablename,
                                        object_id  => $coretid{$tablename},
                                        tablespace => $tsname);

        $hdrsize = 0
            unless (defined($hdrsize));
        
        # ct _tsfiles tsid=c creationdate=c fileidx=n 
        # filename=c filesize=n blocksize=n numblocks=n used=c 
        my $rowarr = [
                      1,      # tablespace id
                      time_iso8601(), # creationdate
                      1,      # file index - 1st datafile
                      $deffile,     # default file name
                      $deffilsize,  # default file size
                      $blocksize,   # blocksize
                      (($deffilsize - $hdrsize )
                        / $blocksize), # number of blocks
                      "Y",          # Y if file in use
                      $deffilsize,  # initial file size
                      ];
        
        # XXX XXX: push @{$rowarr},  increase_by
        # do increase_by = N to perform linear growth,
        #    increase_by = (0.5*filesize) to get 50% growth

        my $realtie = tied(%{$tstable});

        unless (defined($realtie->HPush($rowarr)))
        {
            my $msg = "Failed to create table $tablename";
            my %earg = (self => $self, msg => $msg, severity => 'fatal');
            
            &$GZERR(%earg)
                if (defined($GZERR));
            
            return 0;
        }
    }
    
    # create _tab1
    {
        whisper "create _tab1...\n";
        my $tablename = "_tab1";
        
        my $tstable = $self->_get_table(tname => $tablename,
                                        object_id  => $coretid{$tablename},
                                        tablespace => $tsname);
                
        # ct _tab1 tid=c tsid=c tname=c owner=c 
        # creationdate=c numcols=n numfixed=n numvar=n

        my $rowarr = [
                      "sometid",   # table id
                      1,           # tablespace id 
                      "sometable", # note: change tablename
                      "SYSTEM",
                      time_iso8601(), 
                      2,       # note: change numcols
                      0,
                      2,       # note: change numvar (variable columns)
                      "TABLE"  # default object type is TABLE 
                      ];
        
        my $realtie = tied(%{$tstable});

        my $getcol = $corecolnum{"_tab1"};
        while (my ($tname, $tidcnt) = each(%coretid))
        {
            next # XXX: allfileused not true core...
                if ($tname =~ m/allfileused/); 

            my $colcnt = scalar(@{$coretabs{$tname}}); 

            $rowarr->[$getcol->{tid}]     = $tidcnt; 
            $rowarr->[$getcol->{tname}]   = $tname; 
            $rowarr->[$getcol->{numcols}] = $colcnt;
            $rowarr->[$getcol->{numvar}]  = $colcnt;

            unless (defined($realtie->HPush($rowarr)))
            {
                my $msg = "Failed to create table $tablename";
                my %earg = (self => $self, msg => $msg, severity => 'fatal');
                
                &$GZERR(%earg)
                    if (defined($GZERR));
                
                return 0;
            }
        }

    }

    # create _col1
    {
        whisper "create _col1...\n";
        my $tablename = "_col1";
        
        my $tstable = $self->_get_table(tname => $tablename,
                                        object_id  => $coretid{$tablename},
                                        tablespace => $tsname);
        
        # ct _col1 tid=c tname=c colidx=n colname=c type=c varlen=c 
        # nullable=c defaultval=c maxlen=n
        
        my $realtie = tied(%{$tstable});

        while ( my ($tname, $vv) = each(%coretabs))
        {
            my $objid  = $coretid{$tname}; # get real oid/tid
            my $colidx = 1;

            foreach my $coldef (@{$vv})
            {
#                print "$tid, $tname, $colidx, $coldef\n";
                my ($colname, $coltype) = split('=', $coldef);
                
                my $rowarr = [
                              $objid,
                              $tname, $colidx, $colname,
                              $coltype,
                              "Y", "N", "0", "30"
                              ];
                unless (defined($realtie->HPush($rowarr)))
                {
                    my $msg = "Failed to create table $tablename";
                    my %earg = (self => $self, msg => $msg, 
                                severity => 'fatal');
                    
                    &$GZERR(%earg)
                        if (defined($GZERR));
                    
                    return 0;
                }

                $colidx++;
            }
        }
    }

    return 1;

}

#private
sub _DictDBInit 
{
    my $self = shift;

    # don't need to init if dict file exists

    my $deffile = $self->{dbfile};
    my $deffile_full = $self->{dbfile_full};
    # XXX: Add FORCE for recreate...
    if (-e $deffile_full && !getUseRaw())
    {
        my $msg = "file $deffile_full already exists\n";
        my %earg = (self => $self, msg => $msg, 
                    severity => 'warn');
                    
        &$GZERR(%earg)
            if (defined($GZERR));

        return 0;
    }

    my $tshref = $self->{tablespaces};
    
    my $tsname = "SYSTEM";
    
    # load the tablespace object
    return 0
        if (exists ($tshref->{$tsname}));

    {
        use POSIX ; #  need some rounding

        $self->{blocksize} = POSIX::floor($self->{blocksize});
        $self->{dbsize}    = POSIX::floor($self->{dbsize});

        # Note: number of blocks must be an integer -- true dbsize
        # gets calculated in TSAddfile
    }

    my $ts1 = Genezzo::Tablespace->new(name      => $tsname,
                                       tsid      => 1,
                                       gnz_home  => $self->{gnz_home},
                                       blocksize => $self->{blocksize},
                                       bc_size   => $self->{prefs}->{bc_size},
                                       GZERR     => $self->{GZERR},
                                       dict      => $self);
    $tshref->{$tsname} = {
        tsref => $ts1,
    };

    my %af_args = (filename => $deffile,
                   filesize => $self->{dbsize});

    if (exists($self->{fhdefs}))
    {
        # optional file header definitions
        $af_args{defs} = $self->{fhdefs};
    }

    my @fstat = $ts1->TSAddFile(%af_args);

    return 0
        unless (scalar(@fstat));

    my $fileidx         = $fstat[0];
    $self->{dbsize}     = $fstat[1];
    $self->{headersize} = $fstat[2]; 

    my $deffilsize = $self->{dbsize};

    $ts1->TSSave();
    
    # NOTE: clear out the tablespace info to force a
    # clean tablespace reload from _get_table.
    $ts1 = ();
    delete $tshref->{$tsname};

    # define all the core tables, including pref1
    return $self->_DictDefineCoreTabs($tsname, $deffile, $deffilsize, 1, 
                                      $self->{headersize});
} # end dictdbinit

sub DictSave 
{
    my $self = shift;
    
    unless ($self->{started})
    {
        greet "dict not started";
        return 0;
    }
    
    while (my ($kk, $vv) = each (%{$self->{tablespaces}}))
    {
        whisper "tablespace: $kk\n";
        next unless (exists($vv->{tsref}));
        
        my $ts1 = $vv->{tsref};
        
        $ts1->TSSave(@_);

        my $msg = "saved tablespace $kk\n";
        my %earg = (self => $self, msg => $msg, 
                    severity => 'info');
        
        &$GZERR(%earg)
            if (defined($GZERR));
    }
    
    return 1;
    
} # end dictsave

sub DictRollback
{
    my $self = shift;

    unless ($self->{started})
    {
        greet "dict not started";
        return 0;
    }

    my $sys_ts = undef;
    
    while (my ($kk, $vv) = each (%{$self->{tablespaces}}))
    {
        whisper "tablespace: $kk\n";

        next unless (exists($vv->{tsref}));
        
        my $ts1 = $vv->{tsref};

        $sys_ts = $ts1
            if ($kk =~/^SYSTEM$/); # need to reload system tablespace
        
        $ts1->TSRollback(@_);
        greet $kk;
#        greet $self->_reloadTS($kk);

        $vv->{table_cache} = {}; # XXX XXX: blow out the table cache
                                 # to force reload

        my $msg = "rollback tablespace $kk\n";
        my %earg = (self => $self, msg => $msg, 
                    severity => 'info');
        
        &$GZERR(%earg)
            if (defined($GZERR));
    }

    if (defined($sys_ts))
    {

        # XXX XXX: somewhat abusive - rollback to SYSTEM requires a
        # reload of the entire dictionary
        $self->{started} = 0;
        $self->{use_constraints} = 0; # Note: need to shutoff constraints 
                                      # before startup
        return $self->DictStartup();
    }

    return 1;
    
} # end dictrollback

sub doDictPreLoad 
{
    my $self = shift;
    
    whisper "load prefs...\n";
    
    my $tsname = "SYSTEM";
    my $deffile = $self->{dbfile};
    my $deffilsize = $self->{dbsize};
    
    my $tshref = $self->{tablespaces};
    
    # NOTE: clear out the tablespace info to force a
    # clean tablespace reload from _get_table.
    
    if (exists( $tshref->{$tsname}))
    {
        delete $tshref->{$tsname};
    }
    
#    whisper "preload start";
    $self->{preload} = 1;
    
    return 0 # define all the core tables *except* pref1
        unless $self->_DictDefineCoreTabs($tsname, $deffile, 
                                          $deffilsize, 0,
                                          $self->{headersize});
    
    return 0 
        unless ($self->_loadDictMemStructs ());
    
#    print Dumper(%{ $self->{dict_tables}}), "\n";
    
    return 0
        unless ($self->_TSForceFile1("SYSTEM", "_pref1"));

    # XXX XXX: create a hash of methods associated with pref1, use the
    # key/val pairs to reset system preferences

    $self->{prefs} = {};

    my $hashi = $self->_get_table (tname => '_pref1') ;

    # XXX XXX: replace with filter and SQLFetch...
    while ( my ($kk, $vv) = each ( %{$hashi}))
    { 
        my $getcol  = $corecolnum{"_pref1"};
        my $pref_key = $vv->[$getcol->{pref_key}];
        my $pref_val = $vv->[$getcol->{pref_value}];

        $self->{prefs}->{$pref_key} = $pref_val;

        if ($pref_key =~ m/bc_size/)
        {
            my $tshref = $self->{tablespaces};
            my $tsname = 'SYSTEM';
            my $ts1 = $tshref->{$tsname}->{tsref};
#            greet $pref_val;
            my $bufsz = $ts1->{the_ts}->{bc}->Resize($pref_val);
            if ($pref_val ne $bufsz)
            {
                my $msg = "reset buffer cache to $bufsz from $pref_val";
                my %earg = (self => $self, msg => $msg, 
                            severity => 'info');
        
                &$GZERR(%earg)
                    if (defined($GZERR));
            }

            
#            last; # XXX XXX : need to reset pref1 hash to start at beginning
        }
    }
    
    $self->{preload} = 0;
#    whisper "preload end";
    return 1;
    
}

#private
sub _TSForceFile1
{
    my ($self, $tsname, $tablename) = @_;

    return 0
        unless (defined($tsname));

    return 0
        unless (exists($self->{tablespaces}));
    return 0
        unless (exists($self->{tablespaces}->{$tsname}));

    my $ts1 = $self->{tablespaces}->{$tsname}->{tsref};

    return 0
        unless (defined($ts1));
      
    # force the table to use file 1, i.e.
    #
    # $ts1->{tabsp_tables}->{$tablename}->{desc} = { filesused => [1] };
    #
    return ($ts1->TSForceFile(tablename => $tablename, filenumber => 1 ));
}

#private
sub _reloadTS
{
    my ($self, $tsname) = @_;

    return 0
        unless (defined($tsname));

    return 0
        unless (exists($self->{tablespaces}));
    return 0
        unless (exists($self->{tablespaces}->{$tsname}));

    my $ts1 = $self->{tablespaces}->{$tsname}->{tsref};

    return 0
        unless (defined($ts1));
      
    $ts1->TSLoad();

    return 1;
}

#private
sub _loadDictMemStructs 
{
    my $self = shift;

    whisper "loading dictionary memory structs...\n";

    # clean up first
    delete $self->{dict_tables};

    # indexes
    delete $self->{ts_tsid_idx};
    delete $self->{afu_tid_idx};
    delete $self->{tsf_fid_idx};

    # tied hashes for indexes
    delete $self->{ts_tsid_tv};
    delete $self->{afu_tid_tv};
    delete $self->{tsf_fid_tv};

    my (%tt2, %tt3, %tt4);
    $self->{ts_tsid_idx}   = \%tt2; # XXX XXX
    $self->{afu_tid_idx}   = \%tt3; # XXX XXX- define here, update in 
                                    # dicttablealltab
    $self->{tsf_fid_idx}   = \%tt4; # XXX XXX

    $self->{ts_tsid_tv}   = 
        tie %tt2, 'Genezzo::Index::btHash';
    my %t3arg = (
                 blocksize => $self->{blocksize},
                 key_type  => ["n", "n"]
                 );
    $self->{afu_tid_tv}   =
        tie %tt3, 'Genezzo::Index::btHash', %t3arg; 

    $self->{tsf_fid_tv}   = 
        tie %tt4, 'Genezzo::Index::btHash';

    my $alltspace =  $self->_get_table(tname => "_tspace");

    my $alltables =  $self->_get_table(tname => "_tab1");

    my ($prev_tsid, $prev_tsname); # cache the tablespace id and name

    while (my ($kk, $vv) = each (%{$alltspace}))
    {
        my $getcol = $corecolnum{"_tspace"};
        my $tsname = $vv->[$getcol->{tsname}];
        my $tsid   = $vv->[$getcol->{tsid}];

        $self->{ts_tsid_idx}->{$tsid}     = $kk;

        $prev_tsid   = $tsid;
        $prev_tsname = $tsname;
    }

    my $ts_getcol = $corecolnum{"_tspace"};

    while (my ($kk, $vv) = each (%{$alltables}))
    {
        my $getcol    = $corecolnum{"_tab1"};
        my $tsid      = $vv->[$getcol->{tsid}];

        my $tsname;  # get the tsname from _tspace

        if ($tsid eq $prev_tsid)
        {
            $tsname = $prev_tsname;
        }
        else
        {  # look it up using the index
            my $ts_rid = $self->{ts_tsid_idx}->{$tsid};
            my $tsrow  = $alltspace->{$ts_rid};

            $tsname    = $tsrow->[$ts_getcol->{tsname}];
        }
        my $tablename = $vv->[$getcol->{tname}];

#        greet $kk,  $tablename, $vv;

        # XXX XXX : need to identify which fields are used
        # BUILD A TABLE HASH
        $self->{dict_tables}->{$tablename} = {

            object_id     => $vv->[$getcol->{tid}],  # XXX XXX
            tablespace_id => $vv->[$getcol->{tsid}], # XXX XXX

            table_rid  => $kk,
            tabdef     => {} ,
            tablespace => $tsname,
            colridlist => [],

            object_type => $vv->[$getcol->{object_type}],  # XXX XXX

        };

        $prev_tsid   = $tsid;
        $prev_tsname = $tsname;
    }

    my $allcols =  $self->_get_table(tname => "_col1");

    while (my ($kk, $vv) = each (%{$allcols}))
    {
        my $getcol    = $corecolnum{"_col1"};
        my $objid     = $vv->[$getcol->{tid}];
        my $tablename = $vv->[$getcol->{tname}];
        my $colidx    = $vv->[$getcol->{colidx}];
        my $colname   = $vv->[$getcol->{colname}];
        my $coltype   = $vv->[$getcol->{coltype}];

        $self->{dict_tables}->{$tablename}->{'tabdef'}->{$colname} = 
            [
             $colidx, $coltype
             ];
        # save keys for column information
        $self->{dict_tables}->{$tablename}->{'colridlist'}->[$colidx] = $kk;
    }
#    print Dumper(%{ $self->{dict_tables}}), "\n";

    my $allfu =  $self->_get_table(tname => "allfileused");

    if (defined($allfu))
    {
#        greet "real afu index";

        while (my ($kk, $vv) = each (%{$allfu}))
        {
            # use _get_col_hash because allfileused not core
            my $getcol   = $self->_get_col_hash("allfileused"); 
            my $tid      = $vv->[$getcol->{tid}]; 
            my $fid      = $vv->[$getcol->{fileidx}]; 

            $self->{afu_tid_tv}->STORE([$tid, $fid], $kk); # insert
        }

        my $tsf   =  $self->_get_table(tname => "_tsfiles");

        while (my ($kk, $vv) = each (%{$tsf}))
        {
            my $getcol   = $corecolnum{"_tsfiles"};
            my $fid      = $vv->[$getcol->{fileidx}];

            $self->{tsf_fid_idx}->{$fid} = $kk;
        }
    }

    return 1;
} # end loaddictmemorystructs

# XXX: hash for required table name
my %req_tname = (
                 tname => "no table name!");

# callable as &$tabexists;  it cannot be prototyped.
my $tabexists = sub {
    my %optional = (
                    silent_exists    => 1,
                    silent_notexists => 0,
                    str_exists    => "table \'THETABLENAME\' already exists\n",
                    str_notexists => "table \'THETABLENAME\' does not exist\n" 
                    );

    my %required = (
                    %req_tname ,
                    dhash => "no dictionary hash !"
                    );

    my %args = (%optional,
		@_);
#		tname, dhash

#    greet (%args);

    return 0
        unless (Validate(\%args, \%required));

    my $self = $args{dhash};
    my $tablename = $args{tname} ;

    if ((exists ($self->{dict_tables})) &&
        exists ($self->{dict_tables}->{$tablename} ))
    {
        unless ($args{silent_exists})
        {
            my $outstr = $args{str_exists} ;
            $outstr =~ s/THETABLENAME/$tablename/;

            my %earg = (self => $self, msg => $outstr, 
                        severity => 'warn');
            
            &$GZERR(%earg)
                if (defined($GZERR));
        }
        return 1 ;
    }

    unless ($args{silent_notexists})
    {
        my $outstr = $args{str_notexists} ;
        $outstr =~ s/THETABLENAME/$tablename/;

        my %earg = (self => $self, msg => $outstr, 
                    severity => 'warn');
            
        &$GZERR(%earg)
            if (defined($GZERR));
    }
    return 0 ;

};

# nominally private to Dict
# loads ts and table objects (if necessary) and returns the table tied hash
sub _get_table
{
    my $self = shift;

    my %required = (
                    %req_tname,
                    tablespace => "no tablespace !"
                    );

    # in the normal case the table is stored to disk, but may use
    # in-memory tables during preload.
    my %optional = (
                    TableHashType => "DISK",   # store table on disk
                    object_type   => "TABLE",
                    tablespace    => "SYSTEM", # make easier for system tabs
                    dbh_ctx       => {}
                    );
    my %args = (
                %optional,
		@_);
#		tablespace, tname

#    greet (%args);

    return undef
        unless (Validate(\%args, \%required));

    my $tsname = $args{tablespace};
    my $tshref = $self->{tablespaces};

    my $tablename = $args{tname};

#    unless (defined($tsname))
#    {
#        use Carp;
#        greet $self->{dict_tables};
#        croak "agh";
#    }

    # load the tablespace object
    unless (exists ($tshref->{$tsname}))
    { 
        # NOTE: INIT if first load via SYSTEM tablespace
        my $init = ($tsname eq 'SYSTEM');
        my $tsid = $self->_get_tsid_by_name($tsname);
        
        unless (defined($tsid))
        {
            whisper "no tsid!";
            return undef;
        }

        my %tspace_args = (name      => $tsname,
                           tsid      => $tsid,
                           gnz_home  => $self->{gnz_home},
                           blocksize => $self->{blocksize},
                           GZERR     => $self->{GZERR},
                           dict      => $self);

        if (exists($self->{prefs})
            && exists($self->{prefs}->{bc_size}))
        {
            # set the buffer cache size if prefs are loaded
            $tspace_args{bc_size} = $self->{prefs}->{bc_size}
        }

        my $ts1 = Genezzo::Tablespace->new(%tspace_args);

        # XXX: need to perform special initialization for SYSTEM
        # tablespace that only loads the core tables.  dodictload will
        # reload tablespace using dictionary tables after core dict
        # tables are loaded. clear as mud.

        my $loadtype = "NORMAL";
        if ($init)
        {
            if ($self->{preload})
            {
                $loadtype = "PRELOAD";
            }
            else
            {
                $loadtype = "INIT";
            }
        }

        unless ($ts1->TSLoad(loadtype => $loadtype))
        {
            whisper "load failed";
            return undef;
        }

        $tshref->{$tsname} = {
            tsref => $ts1,     # tablespace object reference
            table_cache => {}  # cache of bound table hashes
        };

    }

    # XXX XXX : add support for filter? don't cache filtered tables?

    # load the table tied hash
    unless (exists ($tshref->{$tsname}->{table_cache}->{$tablename}))
    { 
        my $ts1 = $tshref->{$tsname}->{tsref};
        my %thargs = (tname       => $tablename,
                      htype       => $args{TableHashType},
                      object_type => $args{object_type},
                      dbh_ctx     => $args{dbh_ctx}
                      );

        if (defined($args{object_id}))
        {
            $thargs{object_id} = $args{object_id};
        }
        else
        { # fixup for core tables - get their tids from coretid
            if (exists($coretid{$tablename}))
            {
                $thargs{object_id} = $coretid{$tablename};
            }
            else
            {
                whisper "no object id for $tablename";
            }
        }

        # XXX XXX: switch this to use constraints/index defs versus first col
        if ($args{object_type} =~ m/^(IDXTAB|INDEX)$/)
        {
            my $allcols = $self->DictTableGetCols(tname => $tablename);

            my $is_IDXTAB = ($args{object_type} =~ m/IDXTAB/);
            my @pk_arr;
            
            return undef
                unless  (defined ($allcols));

            # construct "pkey_type", an array of the index key column
            # data types
            {
                while (my ($kk, $vv) = each (%{$allcols}))
                {
                    my ($colidx, $dtype) = @{$vv};

                    if (($colidx == 1) && $is_IDXTAB)
                    { # only single column for idxtab
                        $thargs{pkey_type} = $dtype;
                        last;
                    }
                    $pk_arr[$colidx - 1] = $dtype;
                }

                # for a normal index, all of the columns except for
                # the last one (which is the rid reference) are used
                # to construct the key.  
                # XXX XXX: For an idxtab, only the first column is the
                # key, and the rest is data.

                unless ($is_IDXTAB) 
                {
                    pop @pk_arr ; # last column is rid, not part of key
# XXX XXX XXX XXX unless not unique!!!!                    

#                    greet $tablename, @pk_arr;
                    $thargs{pkey_type} = \@pk_arr;                    
                }
            }
        } # end if index type

# XXX XXX XXX XXX XXX XXX index_load passes a boatload of args that get ignored!!!

        if (exists($args{unique_key}))
        {
            $thargs{unique_key} = $args{unique_key};
        }

        my $tabi = $ts1->TableHash(%thargs);

        return undef
            unless (defined($tabi));

#        greet tied(%{$tabi});

        $tshref->{$tsname}->{table_cache}->{$tablename} = \$tabi;

        if ($self->{use_constraints})
        {
            my $cfn = $self->_make_constraint_check_fn($args{object_id});
            if (defined($cfn))
            {
#                greet "got constraint for $tablename\n";
#                print ref($tabi), "\n";
                my $realtie = tied(%{$tabi});
                $realtie->_constraint_check($cfn);
            }
        }
    }

#    greet $self);
    return undef
        unless (exists ($tshref->{$tsname}->{table_cache}->{$tablename}));

    my $reftabi = $tshref->{$tsname}->{table_cache}->{$tablename};

#    greet ($tstables);

    return ($$reftabi);

} # end _get_table

sub DictObjectExists
{
#    greet (@_);
    my $self = shift;
    whoami;

    my %optional = (
                    object_type => "TABLE",
                    silent_exists    => 1,
                    silent_notexists => 0,
                    str_exists    => 
                    "OBJTYPE \'OBJNAME\' already exists\n",
                    str_notexists => 
                    "OBJTYPE \'OBJNAME\' does not exist\n" 
                    );

    my %required = (
                    object_name => "no object name !"
                    );
    my %args = (
                %optional,
		@_
                );

    return 0
        unless (Validate(\%args, \%required));
    
    my $object_type = $args{object_type};

    my %nargs = @_;
    if ($object_type =~ m/^TABLE$/i ) 
    {
        $nargs{tname} = $args{object_name};
        return &$tabexists(dhash => $self, %nargs);
    }

    if ($object_type =~ m/^TABLESPACE$/i )
    {
        my $tsname = $args{object_name};

        my $sth = 
            $self->_sql_execute(sql_statement =>
                                'select tsid, blocksize from _tspace' . 
                                ' where tsname = \'' . 
                                $tsname . '\'');    
        
        my @ggg;
        @ggg = $sth->fetchrow_array()
            if (defined($sth));

        if (scalar(@ggg))
        {
            greet "tablespace exists";
            unless ($args{silent_exists})
            {
                my $outstr = $args{str_exists} ;
                $outstr =~ s/OBJNAME/$tsname/;
                $outstr =~ s/OBJTYPE/$object_type/;

                my %earg = (self => $self, msg => $outstr, 
                            severity => 'warn');
            
                &$GZERR(%earg)
                    if (defined($GZERR));
            }
            return 1 ;
        }

        unless ($args{silent_notexists})
        {
            greet "tablespace does not exist";
            my $outstr = $args{str_notexists} ;
            $outstr =~ s/OBJNAME/$tsname/;
            $outstr =~ s/OBJTYPE/$object_type/;

            my %earg = (self => $self, msg => $outstr, 
                    severity => 'warn');
            
            &$GZERR(%earg)
                if (defined($GZERR));
        }
        return 0 ;
    } # end tablespace
    return 0 ;
} # end DictObjectExists

sub DictTableExists
{
#    greet (@_);
    my $self = shift;
    return &$tabexists(dhash => $self, @_);
}

# wrapper function for sequence numbers
sub DictGetNextVal
{
    my $self = shift;

    my %required = (
                    tname => "no tablename !",
                    tieval => "no tie val!"
                    );
    my %args = (
		@_
                );

    return (-1)
        unless (Validate(\%args, \%required));

    my $tablename = $args{tname} ;
    my $tv = $args{tieval} ;
#    my $currval = $args{currval};

    # XXX XXX: need max fileidx functions!
    # XXX XXX: need real sequence numbers
    my $currval = $tv->HCount();

    return ($currval + 1);

}

# perform operations against alltab and allcol
sub DictTableAllTab
{
    my $self = shift;

    my %required = (
                    operation => "no operation !",
                    tname => "no tablename !"
                    );
    my %args = (
		@_
                );

    return 0
        unless (Validate(\%args, \%required));

    my $tablename = $args{tname} ;

    my $ops = join '|', qw(insert update delete usefile);

    my $matchop = ($args{operation} =~ /$ops/o);

    unless ($matchop)
    {
        whisper "operation $args{operation} not in $ops" ;
        return 0;
    }

    if ($args{operation} =~ /insert/)
    { # insert
        my %req2 = (
                    tabdef     => "no tabdef !",
                    tablespace => "no tablespace !"
                    );
        return 0
            unless (Validate(\%args, \%req2)); 

        my $objtype = $args{object_type} || "TABLE"; # XXX XXX object type

        my $tablespace_id = $self->_get_tsid_by_name($args{tablespace});
        unless (defined($tablespace_id))
        {
            my $tsname = $args{tablespace};
            my $msg = "invalid tablespace: $tsname";
            my %earg = (self => $self, msg => $msg, 
                        severity => 'warn');
            
            &$GZERR(%earg)
                if (defined($GZERR));

            return 0 ;

        }
        $self->{dict_tables}->{$tablename}->{tablespace_id} = $tablespace_id;

        my $alltables =  $self->_get_table(tname => "_tab1");

        my $realtie = tied(%{$alltables});
        
        my $numcols = scalar(keys(%{$args{tabdef}}));

        my $nexttid = $self->DictGetNextVal(tname => "_tab1", 
                                            col   => "tid",
                                            tieval => $realtie);

        unless ($nexttid > -1)
        {
            my $msg = "invalid table id";
            my %earg = (self => $self, msg => $msg, 
                        severity => 'warn');
            
            &$GZERR(%earg)
                if (defined($GZERR));

            $self->DictTableAllTab(operation => "delete", 
                                   tname => $tablename);

            return 0 ;
        }

        $self->{dict_tables}->{$tablename}->{object_id} = $nexttid;

        my $rowarr = [
                      $nexttid,
                      $tablespace_id,
                      $tablename,
                      "SYSTEM",
                      time_iso8601(), 
                      $numcols,
                      0,
                      $numcols,
                      $objtype
                      ];
        my $t_rid = $realtie->HPush($rowarr);

        unless ($t_rid)
        {
            # NOTE: need to cleanup dict data structs on failure
            my $msg = "could not add table $tablename to _tab1\n";
            my %earg = (self => $self, msg => $msg, 
                        severity => 'warn');
            
            &$GZERR(%earg)
                if (defined($GZERR));

            $self->DictTableAllTab(operation => "delete", 
                                   tname => $tablename);

            return 0 ;
        }

        $self->{dict_tables}->{$tablename}->{table_rid} = $t_rid;

        my $allcols =  $self->_get_table(tname => "_col1");

        $realtie = tied(%{$allcols});

        while (my ($kk, $vv) = each (%{$args{tabdef}}))
        {
            my $colname  = $kk;
            my @rarr     = @{$vv}; # NOTE: COPY -- don't shift the 
                                   # actual COLDEF!!
            my $colidx   = shift @rarr;
            my $coltype  = shift @rarr;

            my $objid =  $self->{dict_tables}->{$tablename}->{object_id};

            my $rowarr = [
                          $objid,
                          $tablename, $colidx, $colname,
                          $coltype,
                          "Y", "N", "0", "30"
                          ];
         
            my $colrid = $realtie->HPush($rowarr);

            unless ($colrid)
            {

                # NOTE: need to cleanup alltab insert and previous
                # _col1 inserts

                my $msg = 
                    "could not add column $tablename . $colname to _col1\n";
                my %earg = (self => $self, msg => $msg, 
                            severity => 'warn');
            
                &$GZERR(%earg)
                    if (defined($GZERR));

                $self->DictTableAllTab(operation => "delete", 
                                       tname => $tablename);
                return 0;
            }
            $self->{dict_tables}->{$tablename}->{colridlist}->[$colidx]
                = $colrid;

        } # end while

        return 1;
    } # end insert

    if ($args{operation} =~ /delete/) # drop table - delete from dictionary
    { # delete
        my $allcols =  $self->_get_table(tname => "_col1");

        my $colarr = $self->{dict_tables}->{$tablename}->{colridlist};

        # skip colarr[0]
        shift @{$colarr};
        foreach my $colrid (@{$colarr})
        {
            if (exists ($allcols->{$colrid}))
            {
                delete $allcols->{$colrid};
            }
        }

        # drop all constraints
        $self->DictTableDropConstraint(tname => $tablename);

        my $alltables =  $self->_get_table(tname => "_tab1");

        my $t_rid = $self->{dict_tables}->{$tablename}->{table_rid};


        delete ($alltables->{$t_rid})
            if (exists ($alltables->{$t_rid}));

        # The table CLEAR operation frees space in every file, but the
        # allfileused table needs to be revised to reflect this

        my $allfileused =  $self->_get_table(tname => "allfileused");
        
        if (defined($allfileused))
        {
            my $objid =  $self->{dict_tables}->{$tablename}->{object_id};

            # XXX XXX: use the index!!

            if (exists($self->{afu_tid_tv}))
            {
                my $sth = # prepare a search statement
                    $self->{afu_tid_tv}->SQLPrepare(
                                                    start_key 
                                                    => [$objid, 0],
                                                    stop_key  
                                                    => 
                                                    [($objid+1), 0]);
                my @row;
                my @del_ary;
                my $delcount = 0;
                
                if ($sth->SQLExecute())
                {
                    @row = 
                        $sth->SQLFetch();

                    while (scalar(@row) > 1)
                    {
                        greet @row;

                        push @del_ary, $row[0];
                        my $kk = $row[1]; # get the rowid 

                        if (exists ($allfileused->{$kk}))
                        {
                            my $vv = $allfileused->{$kk};

                            greet $vv;

                            my $tid = shift (@{$vv});

                            if (($tid == $objid)
                                && (exists ($allfileused->{$kk}))) # redundant?
                            {
                                delete ($allfileused->{$kk});
                                $delcount++;
                            }
                        }
                        @row = 
                            $sth->SQLFetch();
                    } # end while row
                } # end if execute
                if ($delcount > 0)
                {
                    # delete the keys from the index
                    for my $kk (@del_ary)
                    {
                        greet $kk;
#                        delete                         
#                            $self->{afu_tid_idx}->{$kk};
                        $self->{afu_tid_tv}->DELETE($kk); 
                    }
                    return 1; # only return if deleted a row, 
                              # else fall thru to scan
                }

            } # end if index
#            else ?

            {

                # XXX XXX XXX: OBSOLETE? shouldn't need the scan anymore
                # XXX XXX : need an index here instead of this cheesy scan

                while (my ($kk, $vv) = each (%{$allfileused}))
                {
                    my $tid = shift (@{$vv});
                    if ($tid == $objid)
                    {
                        delete ($allfileused->{$kk})
                            if (exists ($allfileused->{$kk}));
                    }
                }
            }
        } # end if allfileused

        return 1;
    } # end delete

    if ($args{operation} =~ /usefile/)
    { # usefile
        my %req2 = (
                    filenumber => "no filenumber !"
                    );
        return 0
            unless (Validate(\%args, \%req2)); 

        my $fileno = $args{filenumber};
        my $objid  = $self->{dict_tables}->{$tablename}->{object_id};

        my $allfileused =  $self->_get_table(tname => "allfileused");

        my $realtie = tied(%{$allfileused});

        my $rowarr = [
                      $objid,
                      $fileno,
                      0
                      ];
        my $rrid = $realtie->HPush($rowarr);

        unless ($rrid)
        {
            my $msg =  "could not add file $fileno" .
                " for table $tablename to allfileused\n";
            my %earg = (self => $self, msg => $msg, 
                        severity => 'warn');
            
            &$GZERR(%earg)
                if (defined($GZERR));

            return 0 ;
        }

        # NOTE: update the index
        # XXX XXX: needs to be non-unique index!!
        $self->{afu_tid_tv}->STORE([$objid, $fileno], $rrid); # insert

        # XXX XXX XXX: update _tsfiles used

        if (exists($self->{tsf_fid_idx})
            && exists($self->{tsf_fid_idx}->{$fileno}))
        {
            my $alltsfiles =  $self->_get_table(tname => "_tsfiles");

            my $realtie = tied(%{$alltsfiles});
            my $rr1 = $self->{tsf_fid_idx}->{$fileno};
            
            if (defined($rr1) && exists($alltsfiles->{$rr1}))
            {
                my $vv      = $alltsfiles->{$rr1};
                my $getcol  = $corecolnum{"_tsfiles"};
                my $used    = $vv->[$getcol->{used}];

                unless ($used =~ m/Y/)
                {
                    $vv->[$getcol->{used}] = "Y";
                    greet $vv;
                    $alltsfiles->{$rr1} = $vv;
                }

            }
        }

        return 1;
    } # end usefile

    return 0;

}


############################################################################
#                                                                          #
#                   Start of Tablespace_functions                          #
#                                                                          #
#                                                                          #
# DictAddFile                                                              #
# _DictTSAddFile                                                           #
# DictTableUseFile                                                         #
# DictFileInfo                                                             #
# DictGrowTablespace                                                       #
# DictSetFileInfo                                                          #
# DictTSpaceCreate                                                         #
#                                                                          #
##++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++##

sub DictAddFile
{
    my $self = shift;

    whoami;

    if ($self->{dictinit})
    {
        whisper "initializing - skip addfile insert...";
        return 1;
    }

    unless ($self->{started})
    {
        my %earg = (self => $self, msg => "dict not started\n",
                    severity => 'warn');
            
        &$GZERR(%earg)
            if (defined($GZERR));

        return 0;
    }
    my %optional = (
                    tsname => "SYSTEM"
                    );

    my %args = (
                %optional,
		@_);
#		filename, filesize, tsname, increase_by

    my $alltsfiles =  $self->_get_table(tname => "_tsfiles");

    my $realtie = tied(%{$alltsfiles});

    my $fileidx =  $self->DictGetNextVal(tname => "_tsfiles",
                                         col   => "tsid",
                                         tieval => $realtie);

    unless ($fileidx > -1)
    {
        my %earg = (self => $self, msg => "invalid file index\n",
                    severity => 'warn');
        
        &$GZERR(%earg)
            if (defined($GZERR));

        return 0;
    }

    my $filesize = $args{filesize};
    if (defined($filesize))
    {
        # convert to a number if necessary
        my $fsize = HumanNum(val  => $filesize,
                             name => "file size"); 
        return 0
            unless (defined($fsize));
        $filesize = $fsize;
        
    }
    else
    {
        $filesize = 0;
        $filesize = $Genezzo::Util::DEFDBSIZE * (2**$fileidx)
            if ($fileidx < 20);
        $filesize = $Genezzo::Util::MAXDBSIZE
            if (($filesize > $Genezzo::Util::MAXDBSIZE ) || (0 == $filesize));
    }

    my $filename  = $args{filename};
    my $ts_prefix = File::Spec->catfile(
                                        $self->{gnz_home},
                                        "ts" );

    if (defined($filename))
    {

        if (File::Spec->file_name_is_absolute($filename))
        {
            my $rel_path = File::Spec->abs2rel( $filename, $ts_prefix ) ;

            greet $rel_path;
        }
    }
    else
    {
        # XXX XXX: use File::Temp - could pass open filehandle to TSAddFile

        my $name  = $fileidx;
        $filename = $name . ".dbf";
    }

    return 0
        unless (NumVal(val  => $filesize,
                       name => $filename,
                       MIN  => 4 * $self->{blocksize}, 
                       MAX  => $Genezzo::Util::MAXDBSIZE));  

    my $tshref = $self->{tablespaces};

    my $tsname = $args{tsname};


    unless (exists($tshref->{$tsname}))
    {
        my ($tsid, $blocksize);

        if (1) 
        {
            my $s1 = 
                'select tsid, blocksize from _tspace where tsname = \'' . 
                $tsname . '\'' ;

            my $sth = $self->_sql_execute(sql_statement => $s1);

            my @ggg;
            @ggg = $sth->fetchrow_array()
                if (defined($sth));

            unless (scalar(@ggg))
            {
                my $msg = "no such tablespace: $tsname \n" ;
                my %earg = (self => $self, msg => $msg,
                            severity => 'warn');
                
                &$GZERR(%earg)
                    if (defined($GZERR));
                return 0;
            }

            $tsid      = shift @ggg;
            $blocksize = shift @ggg;
        }

        # load the tablespace dictionary structures
        return undef
            unless $self->_dict_ts_guts($tsname, $tsid, $blocksize);
    }

    unless (exists($tshref->{$tsname}))
    {
        my $msg = "no such tablespace $tsname\n\n";
        my %earg = (self => $self, msg => $msg,
                    severity => 'warn');
            
        &$GZERR(%earg)
            if (defined($GZERR));

        return 0;
    }

    my $ts1 = $self->{tablespaces}->{$tsname}->{tsref};

    my %nargs = (filename  => $filename,
                 filesize  => $filesize);

    if (exists($args{increase_by}))
    {
        my $inc = $args{increase_by};

        # increase by is a percentage like "9.9%" or a byte value
        # like 32K or 10M
        unless ($inc =~ m/^\d+(\.\d*)?\%$/) 
        {
            $inc = HumanNum(val => $args{increase_by}, name => "increase by");
        }

        return 0
            unless (defined($inc));
        $nargs{increase_by} = $inc;

    }

    $ts1->TSAddFile(%nargs);
    
    $ts1->TSSave();

    return $fileidx;

}

# share with Tablespace.pm
sub _DictTSAddFile
{
    my $self = shift;

    whoami;

    if ($self->{dictinit})
    {
        whisper "initializing - skip addfile insert...";
        return 1;
    }

    unless ($self->{started})
    {
        my %earg = (self => $self, msg => "dict not started\n",
                    severity => 'warn');
            
        &$GZERR(%earg)
            if (defined($GZERR));

        return 0;
    }

    my %required = (
                    tsname     => "no tablespace !",
                    filename   => "no filename ! ",
                    filesize   => "no filesize ! ",
                    blocksize  => "no blocksize !",
                    numblocks  => "no num blocks !",
                    headersize => "no header size !"
                    );

    my %args = (
		@_);
#		filename, filesize, blocksize

    return 0
        unless (Validate(\%args, \%required));

    my $alltsfiles =  $self->_get_table(tname => "_tsfiles");

    my $realtie = tied(%{$alltsfiles});

    my $fileidx =  $self->DictGetNextVal(tname => "_tsfiles",
                                         col   => "tsid",
                                         tieval => $realtie);

    unless ($fileidx > -1)
    {
        my %earg = (self => $self, msg => "invalid file index\n",
                    severity => 'warn');
        
        &$GZERR(%earg)
            if (defined($GZERR));

        return 0;
    }

    my $tsname = $args{tsname};
    my $tablespace_id = $self->_get_tsid_by_name($tsname);

    unless (defined($tablespace_id))
    {
        my $msg = "invalid tablespace name $args{tsname}";
        my %earg = (self => $self, msg => $msg,
                    severity => 'warn');
            
        &$GZERR(%earg)
            if (defined($GZERR));

        return 0;
    }

    my $used = "N";
#    my $tsprefix =
#      File::Spec->catdir($self->{gnz_home} , 'ts');

    my $filename = $args{filename};
#        File::Spec->abs2rel( 
#                             $args{filename},
 #                            $tsprefix);

#    greet $args{filename}, $filename;

    my $filesize = $args{filesize};
    my $blocksize = $args{blocksize};

    my $rowarr = [
                  $tablespace_id,
                  time_iso8601(),
                  $fileidx,
                  $filename,
                  $filesize,
                  $blocksize,	
                  $args{numblocks},
                  $used,
                  $filesize
                  ];

    if (exists($args{increase_by}))
    {
        push @{$rowarr}, $args{increase_by};
    }

    my $rrid = $realtie->HPush($rowarr);

    unless ($rrid)
    {
        my $msg = "could not add file $filename"
            . " for tablespace $tsname to _tsfiles";
        my %earg = (self => $self, msg => $msg,
                    severity => 'warn');
            
        &$GZERR(%earg)
            if (defined($GZERR));
        
        return 0 ;
    }
    $self->{tsf_fid_idx}->{$fileidx} = $rrid;


    # Note: return the fileidx (> 0) on success
    
    return $fileidx;

} # dicttableaddfile

# invoked from Row::RSTab
# via Tablespace::TSTableUseFile 
sub DictTableUseFile
{
    my $self = shift;

    # XXX XXX XXX XXX XXX
#    local $Genezzo::Util::QUIETWHISPER = 0; # XXX: unquiet the whispering
#    whoami;

    if ($self->{dictinit})
    {
        whisper "initializing - skip usefile insert...";
        return 1;
    }
    unless ($self->{started})
    {
        my %earg = (self => $self, msg => "dict not started\n",
                    severity => 'warn');
            
        &$GZERR(%earg)
            if (defined($GZERR));

        return 0;
    }

    my %required = (
                    %req_tname, 
                    object_id  => "no object id! ",
                    filenumber => "no filenumber! "
                    );

    my %args = (
		@_);
#		tname, filenumber

#    greet %args;
    return 0
        unless (Validate(\%args, \%required));

    my $tablename = $args{tname} ;
    my $object_id = $args{object_id};

    if (exists($self->{afu_tid_idx}))
    {
        my $fileno = $args{filenumber};
#        my $objid  = $self->{dict_tables}->{$tablename}->{object_id};
        my $objid  = $object_id;

#        greet $tablename, $objid, $fileno;

        # XXX XXX: objid not defined at startup ??? problem removing
        # href in rstab due to deep recursion?

        if (defined($objid) && defined($fileno) && 
            $self->{afu_tid_tv}->EXISTS([$objid, $fileno]))
        {
#            greet $self->{afu_tid_tv}->FETCH([$objid, $fileno]);
#            return 2; # already in use
        }
        else
        {
            whisper "new file $fileno";
        }
    }
    else
    {
        greet "no afu tid idx!";
    }

    return $self->DictTableAllTab(operation => "usefile", %args);
}

# DictFileInfo: return the _tsfiles row for the specified filenumber.
#   if rowval argument is supplied, then update the _tsfiles row
sub DictFileInfo
{
    my $self = shift;

    whoami;

    if ($self->{dictinit})
    {
        whisper "initializing - can't get info...";
        return 1;
    }

    unless ($self->{started})
    {
        my %earg = (self => $self, msg => "dict not started\n",
                    severity => 'warn');
            
        &$GZERR(%earg)
            if (defined($GZERR));

        return 0;
    }
    my %required = (
                    filenumber => "no filenumber!"
                    );

#    my %optional = (
#                    );

    my %args = (
#                %optional,
		@_);
#		filenumber

    my $fileinfo;

    return undef
        unless (Validate(\%args, \%required));

    my $fileidx = $args{filenumber};

    return undef
        unless (exists($self->{tsf_fid_idx}->{$fileidx}));

    my $rrid = $self->{tsf_fid_idx}->{$fileidx};

    my $alltsfiles =  $self->_get_table(tname => "_tsfiles");

    $fileinfo = $alltsfiles->{$rrid};

#    greet $rrid, $fileinfo;

    if (defined($args{rowval}))
    {
        greet $args{rowval};
        # XXX: check status to see if fits...
        $alltsfiles->{$rrid} = $args{rowval};

#    my $realtie = tied(%{$alltsfiles});

    }

    return $fileinfo;

} # end DictFileInfo

sub DictGrowTablespace
{
    my $self = shift;

    whoami;

    if ($self->{dictinit})
    {
        whisper "initializing - can't grow tablespace...";
        return 0;
    }

    unless ($self->{started})
    {
        my %earg = (self => $self, msg => "dict not started\n",
                    severity => 'warn');
            
        &$GZERR(%earg)
            if (defined($GZERR));

        return 0;
    }
    my %required = (
                    tsname => "no tablespace name!",
                    tsid   => "no tsid!"
                    );

#    my %optional = (
#                    );

    my %args = (
#                %optional,
		@_);
#		tsname, tsid

    return 0
        unless (Validate(\%args, \%required));

    my $tsname = $args{tsname};
    my $tsid   = $args{tsid};

    unless (   exists($self->{ts_tsid_idx})
            && exists($self->{ts_tsid_idx}->{$tsid}))
    {
        my $msg = "invalid tablespace name $tsname, id $tsid";
        my %earg = (self => $self, msg => $msg,
                    severity => 'warn');
            
        &$GZERR(%earg)
            if (defined($GZERR));

        return 0;
    }

    my $alltspace =  $self->_get_table(tname => "_tspace");

    my $ts_rid = $self->{ts_tsid_idx}->{$tsid};
    my $tsrow  = $alltspace->{$ts_rid};

    return 0
        unless (defined($tsrow));

    my $getcol = $corecolnum{"_tspace"};
    my $addfile = $tsrow->[$getcol->{addfile}];
    return 0
        unless (defined($addfile)     # cannot be a
                && length($addfile)); # null or zero-length column

    my %nargs;
    my @af_args = split(' ', $addfile);

    for my $af_elt (@af_args)
    {
        next unless ($af_elt =~ m/=/);
        my ($nname, $vval) = split('=', $af_elt, 2);
        $nargs{$nname} = $vval;
    }
    # Note: if addfile col is just spaces, then use all default
    # addfile arguments
    $nargs{tsname} = $tsname;
    greet %nargs;
    return ($self->DictAddFile(%nargs));
} # end DictGrowTablespace

sub DictSetFileInfo
{
    my $self = shift;

    whoami;

    if ($self->{dictinit})
    {
        whisper "initializing - can't set file info...";
        return 0;
    }

    unless ($self->{started})
    {
        my %earg = (self => $self, msg => "dict not started\n",
                    severity => 'warn');
            
        &$GZERR(%earg)
            if (defined($GZERR));

        return 0;
    }
    my %optional = (tsname => "SYSTEM");
    my %required = (
                    newkey     => "no key!",
                    newval     => "no val!"
                    );
    my %args = (
                %optional,
		@_);

    return 0
        unless (Validate(\%args, \%required));

    my $tsname = $args{tsname};
    my $newkey = $args{newkey};
    my $newval = $args{newval};
    
    my $filename;

    if (exists($args{FileName}))
    {
        $filename = $args{FileName};
    }
    else
    {
        # use default dbf file

        my $fhts;   # gnz_home table space
        
        if(getUseRaw()){
            $fhts = $self->{gnz_home};
        }else{
            $fhts = File::Spec->catdir($self->{gnz_home}, "ts");
        }

        $filename = File::Spec->catdir($fhts, $self->{dbfile});
    }
    return undef
        unless (
                exists($self->{tablespaces}->{$tsname})
                && exists($self->{tablespaces}->{$tsname}->{tsref}));

    my $tsref = $self->{tablespaces}->{$tsname}->{tsref};
    
    return undef
        unless (exists($tsref->{the_ts})
                && exists($tsref->{the_ts}->{bc}));

    my $bc1 = $tsref->{the_ts}->{bc};

    my $file_info = $bc1->BCFileInfoByName(FileName => $filename);
    return undef
        unless (defined($file_info));

    my $foo = $bc1->FileSetHeaderInfoByName(FileName => $filename,
                                            newkey   => $newkey, 
                                            newval   => $newval);

    if (defined($foo))
    {
        # XXX XXX: should reload fileheader_info if updated SYSTEM
        # default datafile
    }
    return $foo;

} # end DictSetFileInfo

sub _dict_ts_guts
{
    my $self = shift;
    my ($tsname , $tsid, $blocksize) = @_;
    my $ts1;

    {
        my $tshref = $self->{tablespaces};
        my %tspace_args = (name      => $tsname,
                           tsid      => $tsid,
                           gnz_home  => $self->{gnz_home},
                           blocksize => $blocksize,
                           GZERR     => $self->{GZERR},
                           dict      => $self);

        if (exists($self->{prefs})
            && exists($self->{prefs}->{bc_size}))
        {
            # set the buffer cache size if prefs are loaded
            $tspace_args{bc_size} = $self->{prefs}->{bc_size}
        }

        $ts1 = Genezzo::Tablespace->new(%tspace_args);

        unless ($ts1->TSLoad(loadtype => "NORMAL"))
        {
            whisper "load failed";
            return undef;
        }

        $tshref->{$tsname} = {
            tsref => $ts1,     # tablespace object reference
            table_cache => {}  # cache of bound table hashes
        };

    }
    return $ts1;
}

sub DictTSpaceCreate
{
    my $self = shift;

    my %required = (
                    tablespace => "no tablespace !"
                    );

    my %optional = (
                    blocksize   => $self->{blocksize},
                    dbh_ctx     => {}
                    );


    my %args = (
                %optional,
		@_);
#    tablespace

#    greet (%args);

    return 0
        unless (Validate(\%args, \%required));

    unless ($self->{started} || $self->{preload} )
    {
        my %earg = (self => $self, msg => "dict not started\n",
                    severity => 'warn');
            
        &$GZERR(%earg)
            if (defined($GZERR));

        return 0;
    }

    my $tsname = $args{tablespace};

    # insert the tablespace
    my $tsid = $self->_get_tsid_by_name($tsname);

    if (defined($tsid))
    {
        my $msg = "tablespace $tsname already exists \n" ;
        my %earg = (self => $self, msg => $msg,
                    severity => 'warn');
            
        &$GZERR(%earg)
            if (defined($GZERR));
        return 0;
    }

    my $sth = $self->_sql_execute(sql_statement =>
                                  "select tsid from _tspace");    
    
    $tsid = -1;
    while (defined($sth))
    {
        my @ggg = $sth->fetchrow_array();

#         whisper $tsid, "\n";

        last
            unless (scalar(@ggg));
        # get max tsid
        $tsid = $ggg[0]
            if ($ggg[0] > $tsid);
# XXX XXX: need maxtsid function!!
    }
    $tsid++;
    unless ($tsid > 0)
    {
        my $msg = "bad tablespace id $tsid";
        my %earg = (self => $self, msg => $msg,
                severity => 'warn');
            
        &$GZERR(%earg)
            if (defined($GZERR));
        return 0;
    }


    my $hashi  = $self->DictTableGetTable (tname => "_tspace") ;
    my $tv = tied(%{$hashi});

    my $rowarr = [$tsid, $tsname, 
                  time_iso8601(),    # creationdate
                  $args{blocksize}
                  ];

    my $rid = $tv->HPush($rowarr);

    unless (defined($rid))
    {
        my $msg = "failed to create tablespace $tsname \n" ;
        my %earg = (self => $self, msg => $msg,
                    severity => 'info');
            
        &$GZERR(%earg)
            if (defined($GZERR));
        return 0;
    }

    return undef
        unless $self->_dict_ts_guts($tsname, $tsid, $args{blocksize});
#    my $alltspace =  $self->_get_table(tname => "_tspace");

    my $msg = "tablespace $tsname created \n" ;
    my %earg = (self => $self, msg => $msg,
                severity => 'info');
            
    &$GZERR(%earg)
        if (defined($GZERR));

    my @stat = (1, $tsname);
    return @stat ;
}

##------------------------------------------------------------------------##
#                                                                          #
#                 End of Tablespace_functions                              #
#                                                                          #
############################################################################

sub DictTableCreate
{
    my $self = shift;

    my %required = (
                    %req_tname, 
                    tabdef     => "no tabdef !",
                    tablespace => "no tablespace !"
                    );

    my %optional = (
                    object_type => "TABLE",
                    make_name   => 0, # make a new name if necessary
                    dbh_ctx     => {}
                    );


    my %args = (
                %optional,
		@_);
#		tname, tabdef, tablespace

#    greet (%args);

    return 0
        unless (Validate(\%args, \%required));

    unless ($self->{started} || $self->{preload} )
    {
        my %earg = (self => $self, msg => "dict not started\n",
                    severity => 'warn');
            
        &$GZERR(%earg)
            if (defined($GZERR));

        return 0;
    }

    my $make_name = $args{make_name};
    my $tablename = $args{tname} ;
    my $o_type    = lc($args{object_type}); # TABLE or INDEX

    # Note: check if index already exists
    if (($o_type ne "table") &&
        $self->DictTableExists(tname => $tablename,
                               # don't complain if can make new name...
                               silent_exists    => $make_name,
                               silent_notexists => 1,
                               str_exists =>
                               "$o_type THETABLENAME already exists\n"))
    {
        return 0 
            unless ($make_name);

        # for system-defined indexes on primary key/unique
        # constraints, use make_name to make a new unique index name.
        # XXX XXX: Slight race condition here - better to move logic
        # to dicttablealltab insert

        # XXX XXX: not sure why magic autoincrement operator doesn't
        # work here
        my $tcount = 1;
        my $t2 = sprintf("%s%02d", $tablename, $tcount);

        while (
               $self->DictTableExists(tname => $t2,
                                      # don't complain if can make new name...
                                      silent_exists    => $make_name,
                                      silent_notexists => $make_name,
                                      str_exists =>
                                      "$o_type THETABLENAME already exists\n")
               )
        {
            $tcount++;
            $t2 = sprintf("%s%02d", $tablename, $tcount);
            whisper "try $t2";
        }

        # reset the tablename
        $args{tname} = $t2;
        $tablename   = $t2;
    }

    $self->{dict_tables}->{$tablename} = 
    {
        tabdef      => $args{tabdef},
        tablespace  => $args{tablespace},
        colridlist  => [],
       
        object_type => $args{object_type}
    };

    unless ($self->DictTableAllTab(operation => "insert", %args))
    {
        # XXX: cleanup
        my $msg = "failed to create $o_type $tablename \n";
        my %earg = (self => $self, msg => $msg,
                    severity => 'warn');
            
        &$GZERR(%earg)
            if (defined($GZERR));

        delete $self->{dict_tables}->{$tablename} ;

        return 0;
    }

    my $msg = "$o_type $tablename created \n" ;
    my %earg = (self => $self, msg => $msg,
                severity => 'info');
            
    &$GZERR(%earg)
        if (defined($GZERR));

    my @stat = (1, $tablename);
    return @stat ;
}

sub DictTableDrop
{
    my $self = shift;

    my %args = (
		@_);
#		tname, 

#    whoami @_;

    return 0
        unless (Validate(\%args, \%req_tname));

    unless ($self->{started})
    {
        my %earg = (self => $self, msg => "dict not started\n",
                    severity => 'warn');
            
        &$GZERR(%earg)
            if (defined($GZERR));

        return 0;
    }

    my $tablename = $args{tname} ;

    return 0
        unless ($self->DictTableExists(tname => $tablename));

    my $objtype = $self->{dict_tables}->{$tablename}->{object_type};

    if ($objtype eq "INDEX")
    {
        return ($self->DictIndexDrop(index_name => $tablename));
    }

    return $self->_table_drop($tablename);
}

sub _table_drop
{
    my ($self, $tablename) = @_;

    my $o_type = lc($self->{dict_tables}->{$tablename}->{object_type});
    {
        my $tsname = $self->{dict_tables}->{$tablename}->{tablespace};
        my $object_id = $self->{dict_tables}->{$tablename}->{object_id};

        my $tstable = $self->_get_table(tname => $tablename,
                                        object_id => $object_id,
                                        tablespace => $tsname);

        my $ts1 = $self->{tablespaces}->{$tsname}->{tsref};
        
#        greet $$ts1;

        #  delete the table from the dictionary
        unless ($self->DictTableAllTab(operation => "delete", 
                                       tname => $tablename))
        {
            # XXX: cleanup
            my $msg = "failed to drop $o_type $tablename \n";
            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
            
            &$GZERR(%earg)
                if (defined($GZERR));

            return 0;
        }

        # CLEAR the table
#        $tstable = ();

        my $realtie = tied(%{$tstable});

#        greet $realtie;

        $realtie->CLEAR() if defined ($realtie);

        return 0
            unless ($ts1->TSDropTable(tablename => $tablename));

        delete $self->{dict_tables}->{$tablename} ;
        
        # fix the tablespaces to remove the tied table hash...
        delete $self->{tablespaces}->{$tsname}->{table_cache}->{$tablename};

        my $msg = "dropped $o_type $tablename \n" ;
        my %earg = (self => $self, msg => $msg,
                    severity => 'info');
            
        &$GZERR(%earg)
            if (defined($GZERR));
    }

    return 1 ;
}

sub DictTableGetCols
{
    my $self = shift;

    my %args = (
		@_);
#		tname
    return undef
        unless (Validate(\%args, \%req_tname));

    my $tablename = $args{tname} ;

    return undef
	unless (&$tabexists(dhash => $self,
                            tname => $tablename));

    # copy for safety - don't want to trash real tabdef
    my %tablehash = %{ $self->{dict_tables}->{$tablename}} ;

    unless (ref($tablehash{tabdef}) eq 'HASH')
    {
        my $msg = "expected hash ref for tabdef! \n";
        my %earg = (self => $self, msg => $msg,
                    severity => 'warn');
            
        &$GZERR(%earg)
            if (defined($GZERR));

	return 0;
    }

    return ($tablehash{tabdef});

}

sub DictTableAddConstraint
{
    my $self = shift;

    my %required = (
                    %req_tname, 
                    cons_type => "no constraint type !"
                    );

    my %args = (
		@_);
#		tname, 

#    whoami @_;

    return 0
        unless (Validate(\%args, \%required));

    unless ($self->{started})
    {
        my %earg = (self => $self, msg => "dict not started\n",
                    severity => 'warn');
            
        &$GZERR(%earg)
            if (defined($GZERR));

        return 0;
    }

    my $tablename = $args{tname} ;

    return 0
        unless ($self->DictTableExists(tname => $tablename));

    my $tspace  = $self->{dict_tables}->{$tablename}->{tablespace};
    my $tid     = $self->{dict_tables}->{$tablename}->{object_id};

    my $cons_name;
    if (exists($args{cons_name}))
    {
        $cons_name = $args{cons_name};            
    }

    if ($args{cons_type} =~ m/check/i)
    {
        unless (exists($args{where_clause}))
        {
            my $msg = "no CHECK text";
            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
            
            &$GZERR(%earg)
                if (defined($GZERR));

            return 0;
        }

        # get the original WHERE clause and the perl filter

        my $where_clause = $args{where_clause};
        my $where_filter = $args{where_filter};

        # insert the check constraint
        # XXX XXX: check for duplicate names? 

        my $hashi  = $self->DictTableGetTable (tname => "cons1") ;
        my $tv = tied(%{$hashi});

        my $consid =   $self->DictGetNextVal(tname => "cons1",
                                             col   => "cons_id",
                                             tieval => $tv);

        unless ($consid > -1)
        {
            my %earg = (self => $self, msg => "invalid constraint index\n",
                        severity => 'warn');
            
            &$GZERR(%earg)
                if (defined($GZERR));

            return 0;
        }

        unless (exists($args{cons_name}))
        {
            $cons_name = "SYS_C" . $consid;
        }

        my $constype = "CK";
        
        my @rowarr = ($consid, $cons_name, $constype, $tid, 
                      $where_filter, $where_clause);

#        greet @rowarr;

        unless ($self->RowInsert(tname => "cons1", rowval => \@rowarr))
        {
            # XXX XXX : cleanup!
            my $msg = "failed to add constraint $cons_name to table cons1\n";
            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
            
            &$GZERR(%earg)
                if (defined($GZERR));

            return 0;
        }
    }
    elsif ($args{cons_type} =~ m/primary|unique/i)
    {
        my $isPrimaryKey = ($args{cons_type} =~ m/primary/i);

        # XXX XXX XXX: need a unique index name!!
        my $index_name = $tablename . 
            ($isPrimaryKey ? '_pk' : '_uq');

        my $itype =
            ($isPrimaryKey ? "PRIMARY KEY" : "UNIQUE");

        my %nargs = (tname      => $tablename,
                     index_name => $index_name,
                     cols       => $args{cols},
                     tablespace => $tspace,
                     itype      => $itype,
                     make_name  => 1        # make a new name if necessary
                     );

        if (exists($args{cons_name}))
        {
            # get the constraint name if it exists
            $nargs{cons_name} = $cons_name;
        }


        # XXX XXX XXX: might specify alternate tspace in constraint def

        return ($self->DictIndexCreate(%nargs));

    }
    else
    {
        my $msg = "unknown constraint type: $args{cons_type}";
        my %earg = (self => $self, msg => $msg,
                    severity => 'warn');
            
        &$GZERR(%earg)
            if (defined($GZERR));

        return 0;
    }

    # reload the constraints if the table is cached

    my $tshref   = $self->{tablespaces};
    my $ts_cache = $tshref->{$tspace}->{table_cache};

    if (exists($ts_cache->{$tablename}))
    {
        greet "table in cache";
        my $thsh = $ts_cache->{$tablename};
        my $tid = $self->{dict_tables}->{$tablename}->{object_id};
        
#            greet $tname, $tid;
        my $cfn = $self->_make_constraint_check_fn($tid);
        if (defined($cfn))
        {
            whisper "got constraint for $tablename\n";
#                print ref($$thsh), "\n";
            my $realtie = tied(%{$$thsh});
            $realtie->_constraint_check($cfn);
        }
        else
        {
            whisper "no constraint for $tablename\n";
        }
    } # end if cached

    my @stat = (1, $cons_name);
    return @stat;
} # end DictTableAddConstraint

sub DictTableDropConstraint
{
    my $self = shift;

    my %required = (
                    );

    my %args = (
		@_);
#		cons_name OR tname OR tid

    whoami @_;

#    return 0
#        unless (Validate(\%args, \%required));

    unless ($self->{started})
    {
        my %earg = (self => $self, msg => "dict not started\n",
                    severity => 'warn');
            
        &$GZERR(%earg)
            if (defined($GZERR));

        return 0;
    }

    my $hashi  = $self->DictTableGetTable (tname => "cons1") ;
    my $tv = tied(%{$hashi});
    my @del_ary;

    if (exists($args{tname}))
    {
        my $tablename = $args{tname} ;

        unless ((exists ($self->{dict_tables})) &&
                exists ($self->{dict_tables}->{$tablename} ))
        {
            my $msg = "no such table $tablename\n";
            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
            
            &$GZERR(%earg)
                if (defined($GZERR));

            return 0;
        }

        my $tab_tid = $self->{dict_tables}->{$tablename}->{object_id};

        # XXX XXX: replace with filter and SQLFetch...
        while ( my ($kk, $vv) = each ( %{$hashi}))
        { 
            my $getcol  = $self->_get_col_hash("cons1"); 
            my $cons_id = $vv->[$getcol->{cons_id}]; 
            my $tid     = $vv->[$getcol->{tid}]; 

            if ($tid == $tab_tid)
            {
                my $stat = 
                    $self->_drop_constraint($vv);

                push @del_ary, $kk;
            }
        }
        
    }
    elsif (exists($args{cons_name}))
    {
        my $cons_name = $args{cons_name} ;
        
        # XXX XXX: replace with filter and SQLFetch...
        while ( my ($kk, $vv) = each ( %{$hashi}))
        { 
            my $getcol    = $self->_get_col_hash("cons1"); 
            my $cons_id   = $vv->[$getcol->{cons_id}]; 
            my $c_name    = $vv->[$getcol->{cons_name}]; 
            my $tid       = $vv->[$getcol->{tid}]; 

            if ($cons_name eq $c_name)
            {
                my $stat = 
                    $self->_drop_constraint($vv);

                push @del_ary, $kk;
            }
        }    
    }
    else
    {
        my $msg = "no constraint name specified\n";
        my %earg = (self => $self, msg => $msg,
                    severity => 'warn');
            
        &$GZERR(%earg)
            if (defined($GZERR));

        return 0;
    }
        
    for my $kk (@del_ary)
    {
        $tv->DELETE($kk);
    }

    return 1;
} # end DictTableDropConstraint

sub _drop_constraint
{
    my $self     = shift;

    whoami @_;

    my $vv = shift;
    greet $vv;

    my $getcol    = $self->_get_col_hash("cons1"); 
    my $cons_id   = $vv->[$getcol->{cons_id}]; 
    my $c_name    = $vv->[$getcol->{cons_name}]; 
    my $tid       = $vv->[$getcol->{tid}]; 
    my $c_text    = $vv->[$getcol->{check_text}]; 
    my $c_type    = $vv->[$getcol->{cons_type}];

    if ($c_type =~ m/(IK|PK|UQ)/)
    {
        my ($i_name, $iid) = split(":", $c_text, 2);
        my $stat = $self->DictIndexDrop(index_name => $i_name, 
                                        leave_cons1 => 1);
    }

    return 1;
}

# function to mimic $corecolnum - return a hash of colname:(colidx-1)
# pairs, suitable for retrieving columns from a fetched row
sub _get_col_hash
{
    my $self     = shift;
    my $tname    = shift;
    my $allcols  = $self->DictTableGetCols(tname => $tname);

    return undef
        unless (defined($allcols));

    my %outi;

    while (my ($kk, $vv) = each (%{$allcols}))
    {
        my ($colidx, $dtype) = @{$vv};

        $outi{$kk} = $colidx - 1;
    }

    return \%outi;
}

# returns the table tied hash
sub DictTableGetTable 
{
    my $self = shift;

    my %optional = (
                    dbh_ctx => {}
                    );
    my %args = (
                %optional,
		@_);
#		tname

    return undef
        unless (Validate(\%args, \%req_tname));

    my $tablename = $args{tname} ;
    my $dbh_ctx   = $args{dbh_ctx};

    return undef
	unless (&$tabexists(dhash => $self,
                            tname => $tablename));

    my $tsname  = $self->{dict_tables}->{$tablename}->{tablespace};
    my $objtype = $self->{dict_tables}->{$tablename}->{object_type};
    my $obj_id  = $self->{dict_tables}->{$tablename}->{object_id};

    my $tstable = $self->_get_table(tname       => $tablename, 
                                    tablespace  => $tsname,
                                    object_type => $objtype,
                                    object_id   => $obj_id,
                                    dbh_ctx     => $dbh_ctx
                                    );
    return ($tstable);
}

sub DictTableColExists
{
    my $self = shift;

    my %required = (
                    %req_tname, 
                    colname    => "no column name!"
                    );

    my %optional = (
                    silent_exists => 1,
                    silent_notexists => 0
                    );


    my %args = (
                %optional,
		@_);
#		tname, colname

    return 0
        unless (Validate(\%args, \%required));

    my $tablename = $args{tname} ;

    return 0
	unless (&$tabexists(dhash => $self,
                            tname => $tablename));


    my $thsh = $self->{dict_tables}->{$tablename};

    my $colname = $args{colname};

    unless (exists ($thsh->{tabdef}->{$colname}))
    {
        unless ($args{silent_notexists}) 
        {
            my $msg = "no such column \'$colname\' in table \'$tablename\' \n";
            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
            
            &$GZERR(%earg)
                if (defined($GZERR));
        }
        return 0;
    }
    my @farr;
    push @farr, @{ $thsh->{tabdef}->{$colname} };
    return wantarray ? @farr : $farr[0];

}

sub RowInsert # was realRowPush
{
    my $self = shift;
    my %required = (
                    %req_tname, 
                    rowval       => "no rowval!"
                    );

    my %optional = (
                    dbh_ctx   => {}
                    );

    my %args = (
                %optional,
		@_);
#		tname, rowval

    return 0
        unless (Validate(\%args, \%required));

    unless ($self->{started})
    {
        my %earg = (self => $self, msg => "dict not started\n",
                    severity => 'warn');
            
        &$GZERR(%earg)
            if (defined($GZERR));

        return 0;
    }

    my $tablename = $args{tname} ;

#    return 0
#	unless ($self->DictTableExists (tname => $tablename));

    my $tstable = $self->DictTableGetTable (tname   => $tablename,
                                            dbh_ctx => $args{dbh_ctx});

    return 0
        unless (defined($tstable));

    # $$$ $$$ need to copy here ? why?
#    my @rowarr = @{$args{rowval}};

    my $tv = tied(%{$tstable});

    # Use PushHash to choose rid's for new rows
#    $tstable->{"PUSH"} = \@rowarr;
#    my $rid = $tv->HPush(\@rowarr);
    my $rid = $tv->HPush($args{rowval});

    return (defined($rid));
}

sub RowUpdate 
{
    my $self = shift;
    my %required = (
                    %req_tname, 
                    rid          => "no rid!",
                    rowval       => "no rowval!"
                    );

    my %optional = (
                    dbh_ctx   => {}
                    );

    my %args = (
                %optional,
		@_);
#		tname, rid, rowval

    return 0
        unless (Validate(\%args, \%required));

    unless ($self->{started})
    {
        my %earg = (self => $self, msg => "dict not started\n",
                    severity => 'warn');
            
        &$GZERR(%earg)
            if (defined($GZERR));

        return 0;
    }

    my $tablename = $args{tname} ;

#    return 0
#	unless ($self->DictTableExists (tname => $tablename));

    my $rid = $args{rid};

    my $tstable = $self->DictTableGetTable (tname   => $tablename,
                                            dbh_ctx => $args{dbh_ctx}
                                            );

    return 0
        unless (defined($tstable));

    return 0
        unless (exists ($tstable->{$rid}));

    # $$$ $$$ need to copy here ? why?
#    my @rowarr = @{$args{rowval}};

    my $tv = tied(%{$tstable});

    # call STORE explicitly to test return value
#    $tstable->{$rid} = \@rowarr;
#    my $stat = $tv->STORE($rid, \@rowarr);
    my $stat = $tv->STORE($rid, $args{rowval});

    return (defined($stat));
}

sub RowDelete 
{
    my $self = shift;

    my %required = (
                    %req_tname, 
                    rid       => "no rid!"
                    );

    my %optional = (
                    dbh_ctx   => {}
                    );

    my %args = (
                %optional,
		@_);
#		tname, rid

    return 0
        unless (Validate(\%args, \%required));

    unless ($self->{started})
    {
        my %earg = (self => $self, msg => "dict not started\n",
                    severity => 'warn');
            
        &$GZERR(%earg)
            if (defined($GZERR));

        return 0;
    }

    my $tablename = $args{tname} ;

#    return 0
#	unless ($self->DictTableExists (tname => $tablename));

    my $rid = $args{rid};

    my $tstable = $self->DictTableGetTable (tname   => $tablename,
                                            dbh_ctx => $args{dbh_ctx}
                                            );

    return 0
        unless (defined($tstable));

    return 0
        unless (exists ($tstable->{$rid}));

    my $stat = delete $tstable->{$rid};
    return (defined($stat));

}

sub DictIndexCreate
{
    my $self = shift;

#    whoami;

    my %required = (
                    %req_tname, 
                    index_name => "no index name",
                    cols       => "no cols !",
                    tablespace => "no tablespace !"
                    );

    my %optional = (
                    dbh_ctx   => {},
                    itype     => "nonunique" ,
                    make_name => 0 # make a new name if necessary
                    );

    my %args = (
                %optional,
		@_);
#		tname, tablespace, index_name, cols array,

    my ($stat, $newname) = $self->_index_create(%args);

    return 0
        unless ($stat);

    my $tablename = $args{tname} ;
#    my $i_name = $args{index_name};
    my $i_name = $newname;
    my $tspace = $args{tablespace};

    my $unique = ($args{itype} =~ m/^(UNIQUE|PRIMARY)/);
    my $constype;

    if ($unique)
    {
        # unique or primary key
        $constype = ($args{itype} =~ m/^UNIQUE/) ? "UQ" : "PK";
    } 
    else
    {   # non-unique index
        $constype = "IK";
    }

    my $thsh   = $self->{dict_tables}->{$tablename};
    my $tid    = $thsh->{object_id};

    my $hashi  = $self->DictTableGetTable (tname => "cons1") ;
    my $tv = tied(%{$hashi});

    my $consid =   $self->DictGetNextVal(tname => "cons1",
                                         col   => "cons_id",
                                         tieval => $tv);

    unless ($consid > -1)
    {
        my %earg = (self => $self, msg => "invalid constraint index\n",
                    severity => 'warn');
            
        &$GZERR(%earg)
            if (defined($GZERR));

        return 0;
    }

    my $cons_name;
    if (exists($args{cons_name}))
    {
        $cons_name = $args{cons_name};            
    }
    else
    {
#            whisper "no constraint name";
        $cons_name = "SYS_C" . $consid;
#            return 0;
    }
        
    my @rowarr = ($consid, $cons_name, $constype, $tid);
    my $ihsh  = $self->{dict_tables}->{$i_name};
    my $iid   = $ihsh->{object_id};
            
    push @rowarr, $i_name . ':' . $iid;

    unless ($self->RowInsert(tname => "cons1", rowval => \@rowarr))
    {
        # XXX XXX : cleanup!
        return 0;
    }

    my $tablespace_id = $self->{dict_tables}->{$tablename}->{tablespace_id};
    my $colarr = $args{cols};

    my @irow  = (# index row
                 $iid,            # index id 
                 $tablespace_id,  # tablespace id
                 $i_name,         # index name 
                 "SYSTEM",        # owner
                 time_iso8601(),  # creationdate
                 scalar(@{$colarr}) + 1,  # numcols 
                 $tid, 
                 $tablename,
                 ($unique  ? "Y" : "N"),
                 $consid                # cons_id 
                 );

    unless ($self->RowInsert(tname => "ind1", rowval => \@irow))
    {
        # XXX XXX : cleanup!
        return 0;
    }

    my $posn   = 1;

  L_constraint_col:
    for my $conscol (@{$colarr})
    {
        # error if no such col
        unless (exists($thsh->{tabdef}->{$conscol}))
        {
            whisper "no such column $conscol in $tablename!!";
            next L_constraint_col;
        }
        my $refarr = 
            $thsh->{tabdef}->{$conscol};
        my ($colidx, $coltype) = @{$refarr};
        @rowarr   = ($consid, $tid, $colidx, $posn);
        my @icrow = ($iid,    $tid, $colidx, $posn);
        unless ($self->RowInsert(tname => "cons1_cols", 
                                 rowval => \@rowarr))
        {
            # XXX XXX: cleanup
            my $msg = "failed to add constraint $consid to table cons1_cols\n";
            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
            
            &$GZERR(%earg)
                if (defined($GZERR));

            return 0;
        }
        unless ($self->RowInsert(tname => "ind1_cols", 
                                 rowval => \@icrow))
        {
            my $msg = "failed to insert col $colidx for index $iid";
            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
            
            &$GZERR(%earg)
                if (defined($GZERR));

            return 0;
        }
        $posn++;
    }

    my $hashi2  = $self->DictTableGetTable (tname   => $tablename,
                                            dbh_ctx => $args{dbh_ctx}
                                            );
    my $tv2 = tied(%{$hashi2});
    
    my $cfn = $self->_make_constraint_check_fn($tid);
    if (defined($cfn))
    {
        whisper "got constraint for $tablename\n";
        $tv2->_constraint_check($cfn);
    }
    #              constraint name, index name,  
    my @stat = (1,   $cons_name,    $newname);
    return @stat;
} # end DictIndexCreate

sub DictIndexDrop
{
    my $self = shift;

    whoami @_;

#    my %required = (
#                    );

#    my %optional = (
#                    );

    my %args = (
		@_);
#		tname OR index_name

    my $hashi  = $self->DictTableGetTable (tname => "ind1") ;
    my $tv = tied(%{$hashi});
    my @del_ary;

    my $leave_cons1 = $args{leave_cons1};

    if (exists($args{tname}))
    {
        my $tablename = $args{tname} ;

        return 0
            unless ($self->DictTableExists(tname => $tablename));

        # XXX XXX: replace with filter and SQLFetch...
        while ( my ($kk, $vv) = each ( %{$hashi}))
        { 
            my $getcol  = $self->_get_col_hash("ind1"); 
            my $cons_id = $vv->[$getcol->{cons_id}]; 
            my $tid     = $vv->[$getcol->{tid}]; 
            my $tname   = $vv->[$getcol->{tname}]; 

            if ($tablename eq $tname)
            {
                my $stat = 
                    $self->_index_drop($vv, $leave_cons1);

                push @del_ary, $kk;
            }
        }
    }
    elsif (exists($args{index_name}))
    {
        my $index_name = $args{index_name} ;
        return 0
            unless ($self->DictTableExists(tname => $index_name));

        # XXX XXX: replace with filter and SQLFetch...
        while ( my ($kk, $vv) = each ( %{$hashi}))
        { 
            my $getcol  = $self->_get_col_hash("ind1"); 
            my $cons_id = $vv->[$getcol->{cons_id}]; 
            my $tid     = $vv->[$getcol->{tid}]; 
            my $iname   = $vv->[$getcol->{iname}]; 

            if ($index_name eq $iname)
            {
                my $stat = 
                    $self->_index_drop($vv, $leave_cons1);

                push @del_ary, $kk;
            }
        }
    }
    else
    {
        my $msg = "no index name!\n";
        my %earg = (self => $self, msg => $msg,
                    severity => 'warn');
            
        &$GZERR(%earg)
            if (defined($GZERR));

        return 0;
    }

    for my $kk (@del_ary)
    {
        $tv->DELETE($kk);
    }

    return 1;
} # end DictIndexDrop

sub _index_drop
{
    my $self = shift;
    my $vv  = shift;
    my $leave_cons1 = shift;
    greet $vv;

    my $getcol    = $self->_get_col_hash("ind1"); 
    my $cons_id   = $vv->[$getcol->{cons_id}]; 
    my $tid       = $vv->[$getcol->{tid}]; 
    my $index_id  = $vv->[$getcol->{iid}]; 
    my $iname     = $vv->[$getcol->{iname}]; 

    # drop the index and constraint columns
    
    for my $tname qw(ind1_cols cons1_cols cons1)
    {
        my $hashi  = $self->DictTableGetTable (tname => $tname) ;
        my $tv     = tied(%{$hashi});
        my @del_ary;

        if ($tname eq "cons1")
        {
            # don't delete the cons1 column if called from
            # drop_constraint
            next
                if (defined($leave_cons1));
        }

        # XXX XXX: replace with filter and SQLFetch...
        while ( my ($kk, $vv2) = each ( %{$hashi}))
        { 
            my $getcol2 = $self->_get_col_hash($tname); 

            if ($tname eq "ind1_cols")
            {
                my $iid  = $vv2->[$getcol2->{iid}];                 
                if ($iid == $index_id)
                {
                    push @del_ary, $kk;
                }
            }
            elsif ($tname =~ m/cons1/) # cons1_cols, cons1
            {
                my $cid  = $vv2->[$getcol2->{cons_id}];                 
                if ($cons_id == $cid)
                {
                    push @del_ary, $kk;
                }
            }

        }
        for my $kk (@del_ary)
        {
            $tv->DELETE($kk);
        }

    }

    # Drop the index
    return $self->_table_drop($iname);
}

sub _index_create
{
    my $self = shift;

#    whoami;

    my %required = (
                    %req_tname, 
                    index_name => "no index name",
                    cols       => "no cols !",
                    tablespace => "no tablespace !"
                    );

    my %optional = (
                    itype       => "UNIQUE",
                    load_only   => 0,
                    define_only => 0,
                    make_name   => 0 # make a new name if necessary
                    );


    my %args = (
                %optional,
		@_);
#		tname, tablespace, index_name, cols array,

#    greet (%args);

    return 0
        unless (Validate(\%args, \%required));

    unless ($self->{started} || $self->{preload} )
    {
        my %earg = (self => $self, msg => "dict not started\n",
                    severity => 'warn');
            
        &$GZERR(%earg)
            if (defined($GZERR));

        return 0;
    }

    my %idef = %args;
    $idef{do_create} = 0         # just get column definitions
        if ($args{load_only});   # if only loading an existing index
    my @index_col_info = $self->_index_define(%idef);
    return 0
        unless (scalar(@index_col_info) > 1);

    my $i_name    = shift @index_col_info; # args{index_name};
    my $tablename = $args{tname} ;
    my $tspace    = $args{tablespace};

    my $unique    = ($args{itype} =~ m/^(UNIQUE|PRIMARY)/);
#    my $unique = ($args{itype} eq "UNIQUE") ? 1 : 0;

    unless ($args{define_only})
    {
        unless ($self->_index_load($tablename, $unique, 
                                   $i_name, $tspace, @index_col_info))
        {
            my $msg = "index load failed - could not create index";
            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
            
            &$GZERR(%earg)
                if (defined($GZERR));

            $self->DictTableDrop(tname => $i_name);
            return 0;
        }
    }

    my @stat = (1, $i_name);
    return @stat;
}

sub _index_define
{
    my $self = shift;

#    whoami;

    my %required = (
                    %req_tname, 
                    index_name => "no index name",
                    cols       => "no cols !",
                    tablespace => "no tablespace !"
                    );

    my %optional = (
                    itype     => "UNIQUE",
                    do_create => 1,
                    make_name => 0, # make a new name if necessary
                    dbh_ctx   => {}
                    );

    my %args = (
                %optional,
		@_);
#		tname, tablespace, index_name, cols array,

#    whoami %args;

    return 0
        unless (Validate(\%args, \%required));

    unless ($self->{started} || $self->{preload} )
    {
        my %earg = (self => $self, msg => "dict not started\n",
                    severity => 'warn');
            
        &$GZERR(%earg)
            if (defined($GZERR));

        return 0;
    }

    my $tablename = $args{tname} ;
    my $i_name = $args{index_name};
    my $tspace = $args{tablespace};
    my $unique = ($args{itype} eq "UNIQUE") ? 1 : 0;

    my @index_key_types ;
    my @index_col_nums ;

    my $allcols = $self->DictTableGetCols(tname => $tablename);
        
    unless (defined($allcols))
    {
        my $msg = "failed to create index $i_name" .
            " - no such table $tablename \n";
        my %earg = (self => $self, msg => $msg,
                    severity => 'warn');
            
        &$GZERR(%earg)
            if (defined($GZERR));

        return 0;
    }

    my $collist = $args{cols};

    my %coldatatype = ();

    my $i_colidx = 1;

 #   greet $collist;
    for my $colname (@{$collist})
    {
        unless (exists($allcols->{$colname}))
        {
            my $msg =  "failed to create index $i_name - " .
                "no such column $colname in table $tablename \n";
            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
            
            &$GZERR(%earg)
                if (defined($GZERR));

            return 0;
        }
        my $colinfo = $allcols->{$colname};
#        greet $colinfo;
        my ($t_colidx, $dtype) = @{$colinfo};

        push @index_key_types, $dtype;
        push @index_col_nums,  $t_colidx;

        $coldatatype{$colname} = [$i_colidx, $dtype];
        $i_colidx++;
    }
    $coldatatype{"_trid"} = [$i_colidx, "c"]; # the table rowid

    my %nargs = (
                 tname       => $i_name,
                 tabdef      => \%coldatatype,
                 tablespace  => $tspace,
                 object_type => "INDEX",
                 make_name   => $args{make_name},
                 dbh_ctx     => $args{dbh_ctx}
                 );

    # XXX XXX XXX : use_keycount pkey_type
    $nargs{unique_key} = $unique;

#    whoami %nargs;
#    greet @index_key_types;
#    greet @index_col_nums;

    my ($stat, $newname);
    $newname = $i_name;   # get newname from dicttablecreate if creating...

    if ($args{do_create})
    {
        ($stat, $newname) = $self->DictTableCreate( %nargs);
        unless ($stat)
        {
            # XXX: cleanup
            my $msg = "failed to create index $i_name on table $tablename \n";
            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
            
            &$GZERR(%earg)
                if (defined($GZERR));

            return 0;
        }
    }

    my @outi;
    push @outi, $newname;
    push @outi, \@index_key_types;
    push @outi, \@index_col_nums;
    return @outi;

}

sub _index_load
{
#    whoami @_;
    my ($self, $tablename, $unique, $i_name, $tspace, 
        $index_key_types, $index_col_nums) = @_;

    # XXX XXX split into two phases for initial constraint load -
    # define all indexes first, then load

    my $tshref    = $self->{tablespaces};
    my $ts1       = $tshref->{$tspace}->{tsref};
    my $object_id = $self->{dict_tables}->{$i_name}->{object_id};

    # XXX XXX XXX XXX : the pernicious tablespace "href" 
    # need to create a descriptor -- normally done in
    # Tablespace::TableHash

#    $ts1->{tabsp_tables}->{$i_name}->{desc} = ()
#        unless (exists($ts1->{tabsp_tables}->{$i_name}->{desc}));

    my %btargs = (
                  # regular _get_table arguments
                  tname     => $i_name,
                  tablename => $i_name,
                  tablespace => $tspace,

                  object_id => $object_id, # semi-required

                  tso       => $ts1,       # unused?
                  bufcache  => $ts1->{the_ts}->{bc}, # unused? 
                  blocksize => $self->{blocksize}, # unused?

                  object_type    => "INDEX", # required
                  BT_Index_Class => "Genezzo::Index::bt3", # unused?

                  unique_key => $unique, # semi-required
                  key_type   => $index_key_types  # unused?
                  );

#    whoami %btargs;
#    greet $i_name;
#    my $bth = $self->DictTableGetTable (%btargs); # XXX XXX

    # Note: internal API takes extra args for index definition
    my $bth = $self->_get_table (%btargs);

    return 0
        unless (defined($bth));

    my $realtie = tied(%{$bth});

    my $bt = $realtie->_get_bt();

    my $allrows =  $self->DictTableGetTable(tname => $tablename);

    my @rowarr;

    my $rowcount = 0;

    while (my ($kk, $vv) = each (%{$allrows}))
    {
        @rowarr = ();

        for my $colnum (@{$index_col_nums})
        {
            push @rowarr, $vv->[$colnum - 1];
        }

        # XXX XXX XXX XXX: if not unique push @rowarr $kk, val = ()
            
        unless ( $bt->insert(\@rowarr, $kk))
        {
            my $msg =  "failed to insert row into index!\n" .
                "inserted $rowcount entries \n";
            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
            
            &$GZERR(%earg)
                if (defined($GZERR));

            return 0;
            last;
        }
        $rowcount++;
    }

    my $msg = "index $i_name on table $tablename created \n" .
        "inserted $rowcount entries \n";
    my %earg = (self => $self, msg => $msg,
                severity => 'info');
    
    &$GZERR(%earg)
        if (defined($GZERR));

    return 1 ;
}


# Phase 2 define constraints: add constraints for core tables when
# database is initialized
sub dictp2_define_cons
{
#    whoami;
    my $self = shift;

    my @allpk = (  # tablename, constraint type, [col1 (, col2...)] 
                   [ "_tab1",      "PK", ["tid"] ],
                   [ "_col1",      "PK", ["tid", "colidx"] ],
                   [ "_tspace",    "PK", ["tsid"] ],
                   [ "_tsfiles",   "PK", ["fileidx"] ] ,

                   [ "cons1",      "PK", ["cons_id"] ],
                   [ "cons1_cols", "PK", ["cons_id", "colidx"] ],
                   [ "ind1",       "PK", ["iid"] ],
                   [ "ind1_cols",  "PK", ["iid", "colidx"] ],
                   );
#    greet $allpk;

    my $consid = 1;

    my $ind_getcol = $self->_get_col_hash("ind1"); 


  L_primary_key_constraint:
    for my $pkcon (@allpk)
    {
        my $tname    = $pkcon->[0]; # tablename
        my $constype = $pkcon->[1]; # constraint type
        my $colarr   = $pkcon->[2]; # column names

        unless (exists($self->{dict_tables}->{$tname}))
        {
            my $msg = "no such table $tname for primary key constraint!";
            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
            
            &$GZERR(%earg)
                if (defined($GZERR));

            next L_primary_key_constraint;
        }

        my $thsh   = $self->{dict_tables}->{$tname};
        my $tid    = $thsh->{object_id};
        my @rowarr = ($consid, "SYS_C$consid", $constype, $tid);
        my @irow   = (   # index row
                      0,        # index id [replace]
                      1,        # tablespace id
                      0,        # index name [replace]
                      "SYSTEM", # owner
                      time_iso8601(),  # creationdate
                      0,               # numcols [replace]
                      $tid, 
                      $tname,
                      "Y",             # unique
                      0                # cons_id [replace]
                      );
        my ($i_name, $iid);

        { # create a primary key index
            $i_name = lc ($tname . "_" . $constype);

            unless ($self->_index_create(tname       => $tname,
                                         index_name  => $i_name,
                                         cols        => $colarr,
                                         tablespace  => "SYSTEM",
                                         define_only => 1))
            {
                my $msg = "failed to create primary key index " .
                    "$i_name on table $tname\n";
                my %earg = (self => $self, msg => $msg,
                            severity => 'warn');
            
                &$GZERR(%earg)
                    if (defined($GZERR));

                next L_primary_key_constraint;
            }
            my $ihsh  = $self->{dict_tables}->{$i_name};
            $iid      = $ihsh->{object_id};
            
            push @rowarr, $i_name . ':' . $iid;

            $irow[$ind_getcol->{iid}]     = $iid;        # index id
            $irow[$ind_getcol->{iname}]   = $i_name;     # index name
            $irow[$ind_getcol->{numcols}] = 1 + scalar(@{$colarr});
            $irow[$ind_getcol->{cons_id}] = $consid;               
        }
        unless ($self->RowInsert(tname => "cons1", rowval => \@rowarr))
        {
            my $msg = "failed to insert constraint $consid";
            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
            
            &$GZERR(%earg)
                if (defined($GZERR));

            return 0;
        }
        unless ($self->RowInsert(tname => "ind1", rowval => \@irow))
        {
            my $msg = "failed to insert index $irow[0]";
            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
            
            &$GZERR(%earg)
                if (defined($GZERR));

            return 0;
        }

        my $posn   = 1;
      L_constraint_col:
        for my $colname (@{$colarr})
        {
            # error if no such col
            unless (exists($thsh->{tabdef}->{$colname}))
            {
                my $msg = "no such column $colname in $tname!!";
                my %earg = (self => $self, msg => $msg,
                            severity => 'warn');
            
                &$GZERR(%earg)
                    if (defined($GZERR));

                next L_constraint_col;
            }
            my $refarr = 
                $thsh->{tabdef}->{$colname};
            my ($colidx, $coltype) = @{$refarr};
            @rowarr   = ($consid, $tid, $colidx, $posn);
            my @icrow = ($iid,    $tid, $colidx, $posn);

            unless ($self->RowInsert(tname => "cons1_cols", 
                                     rowval => \@rowarr))
            {
                my $msg = 
                    "failed to insert col $colidx for constraint $consid";
                my %earg = (self => $self, msg => $msg,
                            severity => 'warn');
                
                &$GZERR(%earg)
                    if (defined($GZERR));

                return 0;
            }
            unless ($self->RowInsert(tname => "ind1_cols", 
                                     rowval => \@icrow))
            {
                my $msg = "failed to insert col $colidx for index $iid";
                my %earg = (self => $self, msg => $msg,
                            severity => 'warn');
            
                &$GZERR(%earg)
                    if (defined($GZERR));

                return 0;
            }
            $posn++;
        }

        $consid++;
    } # end for

    # split index define and loading phases
    for my $pkcon (@allpk)
    {
        my $tname    = $pkcon->[0];
        my $constype = $pkcon->[1];
        my $colarr   = $pkcon->[2];

        unless (exists($self->{dict_tables}->{$tname}))
        {
            my $msg = "no such table $tname for primary key constraint!";
            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
            
            &$GZERR(%earg)
                if (defined($GZERR));

            next;
        }

        { # create a primary key index
            my $i_name = lc ($tname . "_" . $constype);

            unless ($self->_index_create(tname      => $tname,
                                         index_name => $i_name,
                                         cols       => $colarr,
                                         tablespace => "SYSTEM",
                                         load_only  => 1))
            {
                my $msg = "failed to create primary key index " .
                "$i_name on table $tname\n";
                my %earg = (self => $self, msg => $msg,
                            severity => 'warn');
            
                &$GZERR(%earg)
                    if (defined($GZERR));

                next;
            }
        }
    } # end for 

    return 1;
}

sub _make_constraint_check_fn
{
#    whoami;
    my ($self, $tid ) = @_;

    my $allcons =  $self->DictTableGetTable(tname => "cons1");    

    my @cons_func_list;

   # XXX XXX XXX XXX : sqlprepare start_key => [$tid]
    # stop_key => [$tid+1]
    # need to watch case of building constraint for cons1_cols, which
    # might be recursive...

    my %hsh_cons;

    my $getcol = $self->_get_col_hash("cons1"); 

    while (my ($kk, $vv) = each (%{$allcons}))
    {
        next 
            unless ($tid == $vv->[$getcol->{tid}]);

        my $consid     = $vv->[$getcol->{cons_id}];
        my $cons_name  = $vv->[$getcol->{cons_name}];
        my $cons_type  = $vv->[$getcol->{cons_type}];
        my $check_text = $vv->[$getcol->{check_text}];  # filter text or iid
        my $check_plaintext = $vv->[$getcol->{check2}]; # real plaintext

        my $cons_func = ();

        if ($cons_type =~ m/^(IK|PK|UQ)$/) # index or primary key or unique
        {

            my @iid = split(':', $check_text);

            $cons_func = $self->_make_cons_pk_check($tid, $consid, $cons_type,
                                                    $cons_name, @iid);
        }
        elsif ($cons_type =~ m/CK/)
        {
            $cons_func = $self->_make_cons_ck_check($tid, $consid, $cons_type,
                                                    $cons_name, 
                                                    $check_text,
                                                    $check_plaintext);
        }
        else
        {
            my $msg = "unknown type $cons_type";
            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
            
            &$GZERR(%earg)
                if (defined($GZERR));
        }

        unless (defined($cons_func))
        {
            my $msg = "could not create constraint $cons_name" .
                 " for table tid $tid\n";
            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
            
            &$GZERR(%earg)
                if (defined($GZERR));

            next;
        }

        # XXX XXX : would be nice to figure out why we get duplicate
        # rows from cons table -- should be able to just push the
        # cons_func into the func list...

        $hsh_cons{$cons_name} = $cons_func;
    }

    @cons_func_list = values (%hsh_cons);

    return undef
        unless (scalar(@cons_func_list));
    
    return ($self->_all_cons(\@cons_func_list));
}

# build hash of closures of all constraints combined
sub _all_cons
{
#    whoami;
    my ($self, $func_list) = @_;

    return undef
        unless (defined($func_list));

    my %cons_ck_fn;    

    # build callback using closure - pass in the btree, pkey_cols

    $cons_ck_fn{check_insert} = sub {
        for my $cons_check (@{$func_list})
        {
            if (exists($cons_check->{check_insert}))
            {
                my $cci = $cons_check->{check_insert};

                return 1
                    if (&$cci(@_));
            }
        }
        return 0;
    };
    $cons_ck_fn{index_insert} = sub {

        my $maxi = scalar(@{$func_list});

        return 0 unless ($maxi);

        my $maxj;

        for my $i (0..($maxi - 1))
        {
            my $cons_check = $func_list->[$i];
            if (exists($cons_check->{index_insert}))
            {
                my $cci = $cons_check->{index_insert};

                if (&$cci(@_))
                {
                    # Note: may need to do deletes if already did some
                    # inserts that succeeded
                    return 1
                        unless ($i); # no cleanup necessary if first
                                     # insert failed
                    $maxj = $i;
                    last;
                }

            }
        }
        return 0
            unless (defined($maxj));

        # Failure case: some inserts succeeded, last one failed...

        whisper "do cleanup";

        # remove the successful inserts...
        for my $j (0..($maxj - 1))
        {
            my $cons_check = $func_list->[$j];
            if (exists($cons_check->{delete}))
            {
                my $ccd = $cons_check->{delete};

                # XXX XXX: what if delete fails?
                whisper (&$ccd(@_));
            }
        }
        return 1;
    };

    # used by sub localDELETE
    $cons_ck_fn{delete} = sub {
        for my $cons_check (@{$func_list})
        {
            if (exists($cons_check->{delete}))
            {
                my $ccd = $cons_check->{delete};

#                return 0
#                    unless 
                whisper (&$ccd(@_)); # XXX XXX: get status?
            }
        }
        return 1;
        
    };

    $cons_ck_fn{update} = sub {
        my $stat = 0;
        for my $cons_check (@{$func_list})
        {
            if (exists($cons_check->{update}))
            {
                my $ccu = $cons_check->{update};

                $stat += (&$ccu(@_));
            }
        }
        return ($stat > 0);

    };

    $cons_ck_fn{getkeys} = sub {
        return undef; # XXX XXX : unused?
    };

    $cons_ck_fn{SQLPrepare} = sub {
        for my $cons_check (@{$func_list})
        {
            if (exists($cons_check->{SQLPrepare}))
            {
                my $ccSqlPrep = $cons_check->{SQLPrepare};
                # XXX XXX: just get the first one...
                return  (&$ccSqlPrep(@_));
            }
        }
        return undef;

    };

    return \%cons_ck_fn;    
}

# index (primary and unique) constraints
sub _make_cons_pk_check
{
#    whoami;
    my ($self, $tid, $consid, $cons_type, $cons_name, $i_name, $iid ) = @_;

    my $allconscols =  $self->DictTableGetTable(tname => "cons1_cols");    

    my @pkey_cols;

    # XXX XXX XXX XXX : sqlprepare start_key => [$consid, 0]
    # stop_key => [$consid+1, 0]
    # need to watch case of building constraint for cons1_cols, which
    # might be recursive...

    my $getcol = $self->_get_col_hash("cons1_cols"); 

    while (my ($kk, $vv) = each (%{$allconscols}))
    {
        next
            unless ($consid == $vv->[$getcol->{cons_id}]);

        my $colidx = $vv->[$getcol->{colidx}];
        my $posn   = $vv->[$getcol->{posn}];

        $pkey_cols[$posn-1] = $colidx;
    }

    my $tspace = $self->{dict_tables}->{$i_name}->{tablespace};
    my $tshref = $self->{tablespaces};
    my $ts1 = $tshref->{$tspace}->{tsref};
    my $object_id = $iid;
    my $tabdef = $self->{dict_tables}->{$i_name}->{tabdef};

    my @key_type;

    while (my ($kk, $vv) = each (%{$tabdef}))
    {
        my ($colidx, $coltype) = @{$vv};
        $key_type[$colidx - 1] = $coltype;
    }
    pop @key_type ; # last col was rid -- not part of key

#    greet $i_name, @key_type;

    # XXX XXX XXX XXX : the pernicious tablespace "href" 
    # need to create a descriptor -- normally done in
    # Tablespace::TableHash

#    $ts1->{tabsp_tables}->{$i_name}->{desc} = ()
#        unless (exists($ts1->{tabsp_tables}->{$i_name}->{desc}));

    my $unique = ($cons_type =~ m/(UQ|PK)/) ? 1 : 0;

    my %btargs = (
                  tname     => $i_name,
                  tablename => $i_name,
                  tablespace => $tspace,

                  object_id => $object_id,

                  tso       => $ts1,
                  bufcache  => $ts1->{the_ts}->{bc},
                  blocksize => $self->{blocksize},

                  object_type    => "INDEX",
                  BT_Index_Class => "Genezzo::Index::bt3",
 
                  unique_key => $unique,

                  key_type  => \@key_type
                  );

    # Note: internal API takes extra args for index definition
    my $bth = $self->_get_table (%btargs);

    return 0
        unless (defined($bth));

    my $realtie = tied(%{$bth});

    my $bt = $realtie->_get_bt();

    my %cons_ck_fn;

    $cons_ck_fn{c_name} = $cons_name;

    # build callback using closure - pass in the btree, pkey_cols

    $cons_ck_fn{index_insert} = sub {
        my ($keyval, $place) = @_;

#        greet $cons_name, $i_name;

        unless (defined($keyval))
        {
            my $msg = "bad value!\n";

            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
            
            &$GZERR(%earg)
                if (defined($GZERR));

            return 1;
        }

        if (scalar(@{$keyval}) < scalar(@pkey_cols))
        {
            my $msg = "missing key cols\n";

            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
            
            &$GZERR(%earg)
                if (defined($GZERR));

            return 1;
        } 

        my @rowarr;

        for my $colnum (@pkey_cols)
        {
            push @rowarr, $keyval->[$colnum - 1];
        }

       if ($cons_type eq "PK")
       { 
#           greet "pk:", $i_name, @rowarr, scalar(@rowarr);
           my $allnull = 1;
           for my $c1 (@rowarr)
           {
               if (defined($c1))
               {
                   $allnull = 0;
                   last;
               }
           }
           if ($allnull)
           {
               my $msg = 
                   "null key violated PRIMARY KEY constraint $cons_name\n";
               
               my %earg = (self => $self, msg => $msg,
                           severity => 'warn');
               
               &$GZERR(%earg)
                   if (defined($GZERR));

               return 1;
           }
       }
            
        unless ( $bt->insert(\@rowarr, $place))
        {
            my $msg = "violated constraint $cons_name\n";
               
            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
            
            &$GZERR(%earg)
                if (defined($GZERR));

            return 1;
        }
        return 0;
    };

    $cons_ck_fn{delete} = sub {
        my ($keyval, $place) = @_;

#        greet $cons_name, $i_name;

        unless (defined($keyval))
        {
            my $msg = "bad value!\n";
            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
               
            &$GZERR(%earg)
                if (defined($GZERR));

            return undef;
        }

        if (scalar(@{$keyval}) < scalar(@pkey_cols))
        {
            my $msg = "missing key cols\n";
            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
               
            &$GZERR(%earg)
                if (defined($GZERR));

            return undef;
        } 

        my @rowarr;

        for my $colnum (@pkey_cols)
        {
            push @rowarr, $keyval->[$colnum - 1];
        }
        if ($unique) # XXX XXX XXX XXX: unique index
        {
#            whisper "unique delete";
            return ($bt->delete(\@rowarr));
        }
        else
        {
#            whisper "non unique delete";
            return ($bt->delete(\@rowarr, $place));
        }
        
    };

    $cons_ck_fn{update} = sub {
        my ($keyval, $oldkeyval, $place, $op_list) = @_;

#        greet $cons_name, $i_name;

        unless (defined($keyval))
        {
            my $msg = "bad value!\n";
            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
               
            &$GZERR(%earg)
                if (defined($GZERR));

            return 0; # not an error for update - let fail on insert
        }

        if (scalar(@{$keyval}) < scalar(@pkey_cols))
        {
            my $msg = "missing key cols\n";
            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
               
            &$GZERR(%earg)
                if (defined($GZERR));

            return 0; # not an error for update - let fail on insert
        } 

        my (@rowarr1, @rowarr2);

        my $colcnt = 0;
        my $ccd = $cons_ck_fn{delete};
        my $cci = $cons_ck_fn{index_insert};

        for my $colnum (@pkey_cols)
        {
            if ($key_type[$colcnt] eq "n")
            { # numeric compare
                unless ($keyval->[$colnum - 1] ==
                        $oldkeyval->[$colnum - 1])
                {
                    push @{$op_list}, [$cons_name, $ccd, $cci]
                        if (defined($op_list));
                    return 1; # key mismatch
                }
            }
            else
            { # char compare
                unless ($keyval->[$colnum - 1] eq
                        $oldkeyval->[$colnum - 1])
                {
                    push @{$op_list}, [$cons_name, $ccd, $cci]
                        if (defined($op_list));
                    return 1; # key mismatch
                }
            }
            $colcnt++;
        }

        return 0; # keys match - no need to update
    };

    $cons_ck_fn{getkeys} = sub {
        my ($startvals, $stopvals) = @_;

        my (@startkey, @stopkey);

        # convert potential start/stop keys to index colidx order

        for my $colnum (@pkey_cols)
        {
            push @startkey, $startvals->[$colnum - 1]
                if (defined($startvals));
            push @stopkey,   $stopvals->[$colnum - 1]
                if (defined($stopvals));
        }

#        greet @startkey;
#        greet @stopkey;
        my @foo;
        push @foo, \@startkey;
        push @foo, \@stopkey;
        return @foo;
    };

    $cons_ck_fn{SQLPrepare} = sub {
        my ($startvals, $stopvals) = @_;

        my $getkeyfn = $cons_ck_fn{getkeys};

        return undef
            unless (defined($getkeyfn));

        my @both_keys = &$getkeyfn($startvals, $stopvals);
        
        return undef 
            unless (scalar(@both_keys));

        my @startkey = @{$both_keys[0]};
        my @stopkey  = @{$both_keys[1]};

#        greet @both_keys;

        return undef 
            if (scalar(@startkey) < scalar(@pkey_cols));
        return undef 
            if (scalar(@stopkey) < scalar(@pkey_cols));

        for my $ii (0..(scalar(@startkey) - 1))
        {
            return undef
                unless (defined($startkey[$ii])
                        && defined($stopkey[$ii])
                        && ($startkey[$ii] eq $stopkey[$ii]));
        }
        
        my %nargs;

        $nargs{start_key} = \@startkey;
        $nargs{stop_key}  = \@stopkey;
#        greet %nargs;

        return ($bt->SQLPrepare(%nargs));

    };


    return \%cons_ck_fn;

} # end make cons check

# check constraints
sub _make_cons_ck_check
{
#    whoami;
    my ($self, $tid, $consid, $cons_type, $cons_name, 
        $check_filter, $check_text ) = @_;

    my %cons_ck_fn;

    $cons_ck_fn{c_name} = $cons_name;

    # use WHERE clause code...

    my $filter;     # the anonymous subroutine which is the 
                    # result of eval of filterstring

    my $status = eval " $check_filter ";

    unless (defined($status))
    {
        my $msg = "";
#        warn $@ if $@;
        $msg .= $@ 
            if $@;

        $msg .= "\nbad filter:\n" .
            $check_filter . "\n" . $check_text . "\n";

        my %earg = (self => $self, msg => $msg,
                    severity => 'warn');
                    
        &$GZERR(%earg)
            if (defined($GZERR));

        return undef;
    }

    my $tabdef = (); # XXX XXX XXX: need tabdef?? 

    # build callback using closure 

    $cons_ck_fn{check_insert} = sub {
        my ($val, $place, $tablename) = @_;

#        greet $cons_name, $i_name;

        unless (defined($val))
        {
            my $msg = "bad value!\n";
            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
               
            &$GZERR(%earg)
                if (defined($GZERR));

            return 1;
        }

        # need the tablename to build get_alias_col hash
        my $get_alias_col = {};
        unless (defined($tablename))
        {
            my $msg = "no tablename!\n";
            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
               
            &$GZERR(%earg)
                if (defined($GZERR));

            return 1;
        }
        $get_alias_col->{$tablename} = $val;

        # Note: filter returns 1 for success, but callback returns 1
        # for failure

        unless (&$filter($tabdef, $place, $val, $get_alias_col))
        {
            my $msg = "violated constraint $cons_name\n" .
                "must satisfy $check_text\n";
            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
               
            &$GZERR(%earg)
                if (defined($GZERR));

            return 1;
        }
        return 0;
    };

    $cons_ck_fn{delete} = sub {
        return 1;
    };

    $cons_ck_fn{update} = sub {
        my ($newval, $oldval, $place, $op_list) = @_;

#        greet $cons_name, $i_name;

        my $ccd = $cons_ck_fn{delete};
        my $cci = $cons_ck_fn{check_insert};

        push @{$op_list}, [$cons_name, $ccd, $cci]
            if (defined($op_list));

        return 1; # XXX XXX XXX XXX

        # XXX XXX XXX XXX: could compare new/old values -- can avoid
        # calling insert callback if filter cols not modified

        unless (defined($newval))
        {
            my $msg = "bad value!\n";
            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
               
            &$GZERR(%earg)
                if (defined($GZERR));

            return 0; # not an error for update - let fail on insert
        }

        unless (&$filter($tabdef, $place, $newval))
        {
            my $msg = "violated constraint $cons_name\n";
            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
               
            &$GZERR(%earg)
                if (defined($GZERR));

            return 1;
        }
        return 0;
    };

    return \%cons_ck_fn;

} # end make cons check

sub DictHelpSearch
{
    my $self = shift;
    my $bh = $self->{basichelp};

    my $msg;

    # pass arguments to search_topic, else dump pod document
    if (scalar(@_))
    {
        $msg = $bh->search_topic(@_);
    }
    else
    {
        $msg = $bh->getpod2text();
        $msg .= "\n" if (defined($msg));
    }
    return $msg;
}

sub DictAddHelp
{
    my $self = shift;
    my $modname  = shift;
    my $bh = $self->{basichelp};

    unless (defined($modname) && length($modname))
    {
        my %earg = (#self => $self,
                    severity => 'warn',
                    msg => "no module name");

        &$GZERR(%earg)
            if (defined($GZERR));

        return 0;
    }

    if (eval "require $modname")
    {
        my $pod;
        my $estr = '$pod = ' . "$modname" . '::getpod();';

        eval $estr;

#        print $pod;
        
        $bh->pod2gnzhelp($pod);

#        print Data::Dumper->Dump([$bh]);

    }
    else
    {
        my %earg = (#self => $self,
                    severity => 'warn',
                    msg => "no such package - $modname");
        
        &$GZERR(%earg)
            if (defined($GZERR));
    
        return 0;
    }

    return 1;
}


END { }       # module clean-up code here (global destructor)

## YOUR CODE GOES HERE

1;  # don't forget to return a true value from the file

__END__

=head1 NAME

Genezzo::Dict.pm - The Genezzo data dictionary


=head1 SYNOPSIS

 use Genezzo::Dict;

 # create a new dictionary

 my $dictobj = Genezzo::Dict->new(
                  gnz_home => $gnz_home, 
                  init_db => $init);
 
 # see if a table exists

 if ($dictobj->DictTableExists (
                   tname => $tablename,
                   silent_exists => 0,
                   silent_notexists => 1 )))...

 # create a new table

 $dictobj->DictTableCreate (
                   tname => $tablename,
                   tabdef => \%coldatatype,
                   tablespace => "SYSTEM");

 # drop a table

 $dictobj->DictTableDrop (tname => $tablename);

 # save the state of the dictionary to disk

 $dictobj->DictSave();

 my $colhash = 
     $dictobj->DictTableGetCols (tname => $tablename);

 $dictobj->RowInsert (tname => $tablename, 
                      rowval => \@rowarr );

 $dictobj->RowDelete (tname => $tablename, 
                      rid => $rid);

 $dictobj->RowUpdate (tname => $tablename, 
                      rid => $rid,
                      rowval => \@rowarr);

 # return the table as a tied hash

 my $tablehash = 
     $dictobj->DictTableGetTable (tname => $tablename) ;

=head1 DESCRIPTION

The dictionary is a complete description of the Genezzo system,
recording information on table structure and physical layout.  It
provides an interface to create, destroy, query, and manipulate
tables.  

=head2 Dictionary concepts

=over 4

=item Tablespace -- a physical space to store the contents of tables.
A tablespace is a collection of files.  The default install of Genezzo
creates a single SYSTEM tablespace in a single file.  

=back

=head2 Core Tables 

The dictionary itself is just a set of tables stored in the system
tablespace.  Genezzo only uses six core tables to describe its basic
dictionary.  NOTE: Modifying any dictionary tables will framboozle
your nimwits.  You have been warned.

=over 4

=item _pref1 -- a set of key/value pairs that describe the database
configuration

=item _tspace -- the list of tablespaces for this Genezzo instance.

=item _tsfiles -- the list of files which compose each tablespace

=item _tab1 -- the list of tables and their associated tablespaces

=item _col1 -- the list of columns for each table

=item allfileused -- the list of files actually used by each table

=back

=head1 FUNCTIONS

I want to reduce the interface to a simple tied hash, something like:

=over 4

 my $errormsg;

 %args = (errormsg => \$errormsg );

 my $dicthash = DictGetDictHash(%args);

=back

Checking for the existance of a table would be something like:

=over 4

 my $tablename = "kitchentable";

 if (exists($dicthash->{tableinfo}->{$tablename}))
 {
    # do stuff...
 }
 else
 {
    # errormsg was reference in tie of dicthash, 
    # contains last error status
    print $errormsg;
 }

=back



=head2 EXPORT

=head1 TODO

=over 4

=item  pref1 - distinguish fixed/mutable parameters

=item  cons1 - distinguish user constraint names from system-defined names

=item  IDXTAB indexed tables don't give a constraint error, or primary
       key error.  They don't have constraints because they are themselves
       indexes.  Need to give better error message.

=item  Fix t/Cons1 constraint error

=item  DictTableAllTab: need index on allfileused for delete

=item  DictTableAllTab: update tsfiles for usefile
    
=item  need some combo _get_table/corecolnum/getcol - create
       a custom iterator that returns specified cols

=item  non-unique index support using bt2 use_keycount.  Need to
       separate notion of SQL uniqueness from btree concept of unique,
       since a non-unique SQL index is a unique btree with the rid as
       least-significant key col (vs rid as value col).

=item  need drop table/drop index linkage, delete constraints for
       table, etc

=item  constraints: can fix check constraint in update case --
       don't need to check insert if check columns aren't modified.

=item  constraints: need not null/foreign key constraints

=item  constraints: need to limit one primary key per table, prevent
       creation of duplicate indexes on same ordered key columns

=item  expose drop index, drop constraint.  tie drop index/drop table?

=item  check usage of HCount for max tid, max fileidx, max consid.
       This won't work if have deletions

=item DictTableUseFile: update space management to use this function correctly

=item DictDefineCoreTabs, tsfiles: need to save file headersize as a tsfile
      column.

=item deal with dict->{headersize} attribute in some rational way.  Currently
      set via tablespace->TSAddFile...

=back



=head1 AUTHOR

Jeffrey I. Cohen, jcohen@genezzo.com

=head1 SEE ALSO

perl(1).

Copyright (c) 2003, 2004, 2005, 2006 Jeffrey I Cohen.  All rights reserved.

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
