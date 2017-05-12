#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/RCS/Util.pm,v 7.19 2007/01/23 08:52:30 claude Exp claude $
#
# copyright (c) 2003-2007 Jeffrey I Cohen, all rights reserved, worldwide
#
#
package Genezzo::Util;  # assumes Some/Module.pm

use strict;
use warnings;

use Carp;
use Data::Dumper ;

##use bignum;

BEGIN {
    use Exporter   ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    # set the version for version checking
#    $VERSION     = 1.00;
    # if using RCS/CVS, this may be preferred
    $VERSION = do { my @r = (q$Revision: 7.19 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

    @ISA         = qw(Exporter);
    @EXPORT      = qw(&whisper &whoami &greet 
                      &Validate &FlatSave &FlatLoad 
                      &HumanNum &NumVal &checkKeyVal
                      &PackRowCheck &PackRow &UnPackRow &PackRow2
                      &getUseRaw &setUseRaw &gzn_read &gnz_write
                      &get_gzerr_status &set_gzerr_status
                      &add_gzerr_outfile &drop_gzerr_outfile
                      );
    %EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

    # your exported package globals go here,
    # as well as any optionally exported functions
#    @EXPORT_OK   = qw($Var1 %Hashit &func3 &func5);
    @EXPORT_OK   = qw($QUIETWHISPER $WHISPERDEPTH $DEFBLOCKSIZE $USECARP 
                      $DEFDBSIZE $MINBLOCKSIZE $MAXBLOCKSIZE $MAXDBSIZE
                      $MAXOPENFILES $MAXEXTENTSIZE
                      $UNPACK_TEMPL_ARR $WHISPER_PRINT $UTIL_EPRINT 
                      $WHISPERPREFIX $RAW_IO);

}

our @EXPORT_OK;

our $UNPACK_TEMPL_ARR;

our $PACK_NUMCOL    = 'w';    # pack the number of columns in a row
our $UnPACKVAL_TYPE = 'w/a';  # unpack a column value
our $PACKVAL_STR    = $UnPACKVAL_TYPE . '*'; # add the wildcard to consume
                                             # remaining values...
sub _numcol_len
{
    my $numcols = $_[0];

    # XXX XXX: no speed up for this optimization ?

    if (($PACK_NUMCOL eq 'w')) # BER ints
    {
        # just lookup byte length in table
#        return 0 if ($numcols < 1);    # ??
        return 1 if ($numcols < 128);    # 2**(7*1)
        return 2 if ($numcols < 16384);  # 2**(7*2)

        # tops out at 147 bytes for 2**1022 (about 4.5e307)

        # [Frank Tipler] According to the Bekenstein Bound we need
        # about 10^45 bytes per human simulation, and 10^123 for the
        # visible universe.  All possible variants of the known
        # universe requires 10^(10^123) bytes, so need to update
        # pack_numcol and unpackval_type after the singularity.

    }

    # else calculate length...
    return length(pack($PACK_NUMCOL, $numcols)); # byte length of 
                                                 # the column count
}

sub PackBits
{
    my $numcols = shift;
    return (8 * (($numcols < 7) ? 1 : (int(($numcols+1)/8) + 1)));
}

BEGIN {

    # Build an array of common unpack templates, versus constructing
    # the templates dynamically in UnPackRow

    $UNPACK_TEMPL_ARR = [];
    $PACK_NUMCOL    = 'w';    # pack the number of columns in a row
    $UnPACKVAL_TYPE = 'w/a';  # unpack a column value
    $PACKVAL_STR    = $UnPACKVAL_TYPE . '*'; # add the wildcard to consume
                                             # remaining values...

    for my $numcols (1..100)
    {
        my $templ;

        my $skippy = _numcol_len($numcols); # byte length of the column count

        $templ     = "x$skippy "; # unpack template to skip column count bytes

        my $nullvec_len = PackBits($numcols) / 8; # byte length of null vector

        # build string to unpack each column
        $templ  .= "a$nullvec_len ";               # unpack the null bitvec
        $templ  .= "$UnPACKVAL_TYPE " x $numcols;  # unpack other cols

        $UNPACK_TEMPL_ARR->[$numcols] = $templ;
    }

}

our $USE_FSYNC;

BEGIN {
    use Config;

    # Win32: handle missing fsync problem
    if (exists($Config{d_fsync})
        && ($Config{d_fsync} eq "define"))
    {
#        print "\nuse fsync\n";
        $USE_FSYNC = 1;
    }
    else
    {
        $USE_FSYNC = 0;
    }

}

# non-exported package globals go here


# initialize package globals, first exported ones
#my $Var1   = '';
#my %Hashit = ();

our $QUIETWHISPER = 0; # XXX XXX XXX XXX
our $WHISPERDEPTH = 1;
our $WHISPERPREFIX = "whisper: ";

our $RAW_IO          = 0;   # use "cooked" file systems by default
our $ALIGN_BLOCKSIZE = 4096; # header alignment for raw io

our $DEFBLOCKSIZE = 4096;
our $DEFDBSIZE    = 80 * $DEFBLOCKSIZE ; # 327680 was 163840

our $MINBLOCKSIZE = 1024; # 512;

our $MAXBLOCKSIZE = 65536;
our $MAXDBSIZE    = 2**31; # 2 Gig # XXX : 4 gig ok all platforms?

our $MAXOPENFILES  = 100;   # number of open files in buffer cache
our $MAXEXTENTSIZE = 1024;  # max number of blocks in an extent

our $USECARP = 1;

our $WHISPER_PRINT   = sub { print @_ ; };
our $UTIL_EPRINT = sub { print @_ ; };

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

sub whowasi { (caller(1))[3] . '()' }

# use the magic goto
sub whisper { goto &_realwhisper unless $QUIETWHISPER }
sub _realwhisper 
{ 
    my $outmess = shift @_;

    return unless (defined($outmess));

    my $wprefix = $WHISPERPREFIX;

    # print all the args space delimited

    if (scalar(@_))
    {
        $outmess .= ' ';
        if (scalar(@_) > 1)
        {
            $outmess .= join(' ',@_);
        }
        else
        {
            $outmess .= $_[0];
        }

    }
    # add a newline if necessary
    $outmess .= "\n" unless $outmess=~/\n$/;

    # treat string as multiple lines, and prefix each with "whisper:" prefix
    $outmess =~ s/^/$wprefix/gm 
        if (defined($wprefix));

    # taken from carp::heavy
    if (1)
    {
        # print high-end chars as 'M-<char>'
        $outmess =~ s/([\200-\377])/sprintf("M-%c",ord($1)&0177)/eg;
        # print remaining control chars as ^<char>
        $outmess =~ s/([\0-\11])/sprintf("^%c",ord($1)^64)/eg;
        # ignore newline (^J = octal 12)
        $outmess =~ s/([\13-\37\177])/sprintf("^%c",ord($1)^64)/eg;
    }
    # treat string as multiple lines, and prefix each with "whisper:" prefix
#    $outmess =~ s/\^J/\n$wprefix/gm ;

    &$WHISPER_PRINT( $outmess );
}

sub whoami  
{ 
    return if $QUIETWHISPER;

    my $maxdepth = $WHISPERDEPTH;

    foreach my $calldepth (1..$maxdepth)
    {
        my $outi = (caller($calldepth))[3]  || 'MAIN?';  
        $outi .= '()';

        if (1 == $calldepth)
        {
            whisper $outi, @_; 
        }
        else
        {
            whisper ' ' x ($calldepth - 1), $outi; 
        }
    }
}
sub greet   
{ 
    return if $QUIETWHISPER;

    my $maxdepth = $WHISPERDEPTH;

    foreach my $calldepth (1..$maxdepth)
    {
        my $outi = (caller($calldepth))[3]  || 'MAIN?';  
        $outi .= '()';

        if (1 == $calldepth)
        {
            whisper $outi, " : \n", Dumper(@_); 
        }
        else
        {
            whisper ' ' x ($calldepth - 1), $outi; 
        }
    }
}

sub Validate 
{
#    greet @_;

    my ($package, $filename, $line) = caller(1);

    my @param = @_;

    my %args = %{$param[0]};

    my %required = %{$param[1]};

#    print Dumper(%args);
#    print Dumper(%required);

    while (my ($kk, $vv) = each (%required))
    {
#        print "$kk => ", Dumper($vv);
        unless (exists ($args{$kk}))
        {
            # add a newline if necessary
            $vv .= "\n" unless $vv=~/\n$/;

            if ($USECARP)
            {
                carp $vv;
            }
            else
            {
                my $m1 = "$package $filename $line: " . $vv;
                &$UTIL_EPRINT( $m1 );
            }
            return 0;
        }
    }

    return 1;
};

sub _notnum
{
    unless (scalar(@_))
    {
        whisper "no value supplied!";
        return 0;
    }
    unless (defined($_[0]))
    {
        whisper "undef value supplied!";
        return 0;
    }


    # natural? numbers (non-negative integers)
    return ($_[0] !~ /\d+/);
}
sub _notnummsg
{
    return "no values supplied!"
        unless (2 == scalar(@_));
    
    my ($nname, $val) = @_;
    return undef
        unless _notnum($val);
    
#Argument "sdf" isn't numeric in array element at ./t2.pl line 61.
    my $emsg = 
        "Non-numeric value (" . $val . ") for " . $nname; 

    return $emsg;
}

# convert human numbers (e.g. 2G) to pure numbers
# Note: now supports decimal point in specification, e.g. 1.4K or 0.5G
sub HumanNum
{
    my ($package, $filename, $line) = caller(1);

    my %required = (
                    val  => "no value supplied",
                    name => "no name supplied"
                    );

    my %args = (
                verbose => 1,
                units  => "bytes",
                @_);

    return undef
        unless (Validate(\%args, \%required));

    my $numregexp = '^-?(?:\d+(?:\.\d*)?|\.\d+)$';

    my $emsg = ();
    my $val = $args{val};
    my $nam = $args{name};
    my $outi;

# courtesy of /usr/share/units.dat (see units -V)
#yotta-                  1e24     # Greek or Latin octo, "eight"
#zetta-                  1e21     # Latin septem, "seven"
#exa-                    1e18     # Greek hex, "six"
#peta-                   1e15     # Greek pente, "five"
#tera-                   1e12     # Greek teras, "monster"
#giga-                   1e9      # Greek gigas, "giant"
#mega-                   1e6      # Greek megas, "large"
#kilo-                   1e3      # Greek chilioi, "thousand"

# k = 1024, M = k * k = k^2, G = k * M = k^3, T = k * G=k^4, 

# NOTE: computer usage doesn't match SI prefixes...
    my %unitsprefix = (
                       Y => [ 80, "Yotta"],
                       Z => [ 70, "Zetta"],
                       E => [ 60, "Exa" ],
                       P => [ 50, "Peta"],
# XXX: 2^49 is about as high as we go...
                       T => [ 40, "Tera"],
                       G => [ 30, "Giga"],
                       M => [ 20, "Mega"],
                       K => [ 10, "Kilo"]
                       );

    return $val
        if ($val =~ m/$numregexp/);

    {
        if ($val =~ m/^\d+(\.\d*)?[kmgtpezy]$/i)
        {
            my @ggg = ($val =~ m/(\d+(\.\d*)?)([kmgtpezy])/i);
            
#            greet @ggg;

            $outi = $ggg[0];
            if (scalar(@ggg) > 2)
            {
#                $outi .= "." . $ggg[1];
                shift @ggg;
            }

            if (scalar(@ggg) > 1)
            {
                my $suffix = (2**($unitsprefix{uc($ggg[1])}->[0]));

                # check the suffix for exponential notation to see if
                # we lose precision, eg: 2**50 = 1125899906842624 with
                # bignum else it returns 1.12589990684262e+15

                if ($suffix !~ m/e/i) 
                {
                    # if suffix is still an integer then multiply

                    $outi *= $suffix;
                }
                else
                {

                    $emsg = "$nam ($val) too large - ";

                    #        Peta                              bytes 
                    $emsg .= $unitsprefix{uc($ggg[1])}->[1] . $args{units};
                    
                    #          (2^50) > 2^49
                    $emsg .= " (2^" . $unitsprefix{uc($ggg[1])}->[0];
                    $emsg .= ") not supported";

                }
            }

        }
        else
        {
            $emsg = "illegal numeric format ($val) for $nam";

        }
    }
    return $outi unless (defined($emsg));

    return 0 unless ($args{verbose});

    if ($USECARP)
    {
        carp $emsg;
    }
    else
    {
        my $m1 = "$package $filename $line: " . $emsg;
        &$UTIL_EPRINT( $m1 );
    }
    return undef;
}

sub NumVal 
{
#    greet @_;

    my ($package, $filename, $line) = caller(1);

    my %required = (
                    val  => "no value supplied",
                    name => "no name supplied"
                    );

    my %args = (
                verbose => 1,
                @_);

    return 0
        unless (Validate(\%args, \%required));

    my $emsg = ();

    my $optional_args = {
        MIN => {
            typ  => "_MINIMUM_",
            msg  => " less than minimum ",
            # 0 is supplied value, 1 is specified minimum
            comp => sub { return $_[0] < $_[1] ; }
        }, # end min
        MAX => {
            typ  => "_MAXIMUM_",
            msg  => " exceeds maximum ",
            # 0 is supplied value, 1 is specified maximum
            comp => sub { return $_[0] > $_[1] ; }
        } # end max
    };


  L_mmm:
    {
        $emsg = _notnummsg($args{name}, $args{val});
        last L_mmm if (defined($emsg));

        foreach my $vv (keys (%{$optional_args}))
        { # big for
            if (exists($args{$vv}))
            { # exists check
                my $tval  = $args{$vv};
                # e.g. tname = _MINIMUM_
                my $tname = $optional_args->{$vv}->{typ};
                $tname .= " " . $args{name}; 
                my $tmsg = _notnummsg($tname, $tval);
                if (defined($tmsg))
                { # is bound a number
                    if (defined($emsg))
                    {
                        $emsg .= "\n" ;
                        $emsg .= $tmsg;
                    }
                    else
                    {
                        $emsg = $tmsg;
                    }
                }
                else
                { # bound is a legit number

                    my $newsub = $optional_args->{$vv}->{comp};

                    if (&$newsub($args{val}, $args{$vv}))
                    { # within bounds?
                        if (defined($emsg))
                        {
                            $emsg .= "\n" ;
                            $emsg .= 
                                "Numeric value (" . $args{val} ;
                        }
                        else
                        {
                            $emsg = 
                                "Numeric value (" . $args{val} ;
                        }
                        $emsg .= 
                            ") for " . $args{name}; 
                        # e.g. " execeeds maximum "
                        $emsg .= 
                            $optional_args->{$vv}->{msg} . 
                                "(". $args{$vv} . ")";

                    }
                } # end bound is a legit number
            } # end exists check
        } # end big for
    }

    return 1 unless (defined($emsg));

    return 0 unless ($args{verbose});

    if ($USECARP)
    {
        carp $emsg;
    }
    else
    {
        my $m1 = "$package $filename $line: " . $emsg;
        &$UTIL_EPRINT( $m1 );
    }
    return 0;
}


sub FlatSave 
{
#    whoami;

    my ($cpackage, $cfilename, $cline) = caller;

    my %optional = (
                    type => $cpackage,
                    implementation => $cfilename
                    );

    my %required = (
                    outfile => "no output file supplied! \n" ,
                    inhash => "no input hash supplied! \n",
                    );

    my %args = (%optional,
		@_);

#    print Dumper(%args);

    return 0
        unless (Validate(\%args, \%required));

    my %hashreq = (
                   name => "no name supplied! \n",
                   package_version => "no package_version supplied! \n",
                   rcs_header => "no rcs_header supplied! \n",
                   rcs_revision => "no rcs_revision supplied! \n",
                   );

    my $inhash = $args{inhash};

#    greet $inhash;

    return 0
        unless (Validate($inhash, \%hashreq));

    {
        my $outfile = $args{outfile};

        open (DICOUT, "> $outfile ") 
            or die "Could not tee open $outfile for writing : $! \n";

        $inhash->{type} = $args{type};
        $inhash->{implementation} = $args{implementation};

        my $bighash = \$inhash;
        {
            $| = 1; # force flush
            print DICOUT  Data::Dumper->Dump([$bighash], [qw(*bighash )]); 
            $| = 1;
            close (DICOUT);
        }
    }

    return (1);


} # end dictsave

sub FlatLoad
{
#    whoami;

    my %optional = (
                    );

    my %required = (
                    infile => "no input file supplied! \n" ,
                    outhash => "no output hash supplied! \n",
                    );

    my %args = (%optional,
		@_);

#    print Dumper(%args);

    return 0
        unless (Validate(\%args, \%required));

    my $inifile = $args{infile};

    open (INIFILE, "< $inifile" ) 
        or die "Could not open $inifile for reading : $! \n";

    # $$$ $$$ undefine input record separator (\n")
    # and slurp entire file into variable
    local $/;
    undef $/;

    my $whole_file = <INIFILE>;
    close (INIFILE);

#        print $whole_file;
        
    my $bighash = ();

    {
        eval "$whole_file";
    }

    my $outhash = $args{outhash};
    while (my ($kk, $vv) = each (%{${$bighash}}))
    {
#            print "$kk => ", Dumper($vv);
        $outhash->{$kk} = $vv;
    }

    print "Name : ", $outhash->{name}, "\n";
    print "Type : ", $outhash->{type}, "\n";
    print "Package Version : ",  $outhash->{package_version}, "\n\n";

    print "RCS Header : \n\t", $outhash->{rcs_header}, "\n\n";

    return (1);
}

sub checkKeyVal
{
#    greet @_;
    my ($package, $filename, $line) = caller(1);

    my %required = (
                    kvpair    => "no value supplied",
                    validlist => "no valid list supplied"
                    );

    my %args = (
                verbose => 1,
                @_);

    return undef
        unless (Validate(\%args, \%required));

    my $kvpair     = $args{kvpair};
    my $validlist  = $args{validlist};

    my $emsg;
    my @subop  = (split('=', $kvpair));

    if (2 == scalar(@subop))
    {
        if (defined($validlist))
        {
            my $pat = join ('|' , @{$validlist});

            unless ($subop[0] =~ /$pat/o)
            {
                $emsg = "key (" . $subop[0] . ") not in list (" . $pat . ")";
            }
        }
        else
        {
                $emsg = "list of valid keys not supplied";
        }
    }
    else
    {
        $emsg = "could not split " . $kvpair;
    }

    return \@subop unless (defined($emsg));

    return undef unless ($args{verbose});

    if ($USECARP)
    {
        carp $emsg;
    }
    else
    {
        my $m1 = "$package $filename $line: " . $emsg;
        &$UTIL_EPRINT( $m1 );
    }
    return undef;
}


# Basic row packing format is a column count followed by a list of
# length/value pairs:
#
# number of cols [ +1] , (column length/column value)...
#
# An extra first column, a bitvec, is added to deal with nulls.
#
sub PackRowCheck
{
    my ($value, $maxsize) = @_;

    my $numcols = scalar (@{$value});

#    my $numbits = 8 * (($numcols < 8) ? 1 : (int($numcols/8) + 1));
    my $numbits = PackBits($numcols);

    my $nullstr = pack("B*", "0"x$numbits);

    my $packstr;
    my $headstr = pack($PACK_NUMCOL, $numcols);

    if (defined($maxsize))
    {
        $maxsize -= length($nullstr);
        $maxsize -= length($headstr);
    }

    if ($numcols)
    {
        my $colcnt = 0;

        foreach my $elt (@{$value})
        {
            if (defined($elt))
            {
                if (defined($maxsize))
                {
                    my $len = length($elt);
                    return undef       # too small
                        if ($len > $maxsize);
                    $maxsize -= $len;
                }
                $packstr .= pack($PACKVAL_STR, $elt);
            }
            else
            {
                vec($nullstr, $colcnt+1, 1) = 1;
                $packstr .= pack($PACKVAL_STR, "");
            }
            $colcnt++;
        }
    }
#    print unpack("b*", $nullstr), "\n";
#    $headstr .= pack($PACKVAL_STR, $nullstr);
    $headstr .= $nullstr;
    $headstr .= $packstr
        if (defined($packstr));
    return $headstr;

} # end PackRowCheck
sub PackRow
{
    my $value = shift;

    my $numcols = scalar (@{$value});

#    my $numbits = 8 * (($numcols < 8) ? 1 : (int($numcols/8) + 1));
    my $numbits = PackBits($numcols);

    my $nullstr = pack("B*", "0"x$numbits);

    my $packstr;
    my $headstr = pack($PACK_NUMCOL, $numcols);
    
    if ($numcols)
    {
        my $colcnt = 0;

        foreach my $elt (@{$value})
        {
            if (defined($elt))
            {
                $packstr .= pack($PACKVAL_STR, $elt);
            }
            else
            {
                vec($nullstr, $colcnt+1, 1) = 1;
                $packstr .= pack($PACKVAL_STR, "");
            }
            $colcnt++;
        }
    }
#    print unpack("b*", $nullstr), "\n";
#    $headstr .= pack($PACKVAL_STR, $nullstr);
    $headstr .= $nullstr;
    $headstr .= $packstr
        if (defined($packstr));
    return $headstr;

} # end PackRow

=head1 PackRow2

PackRow2 takes list of items and packs them (non-destructively) into a
string of <= maxsize bytes.  If offset is not specified, it builds the
string starting with the last item in the list, prepending it with
each preceding item until it runs out of space or the list is fully
consumed.  If the packer runs out of space, it returns the offset into
the list where it stopped.  The offset may be supplied as an argument
to this function, and the packer will pack the remainder of the list
starting at the offset, working back to the beginning of the list.
The final argument to the packer is a "next pointer", a string that
identifies the location of the next part of a row split into multiple
pieces.  Since the packer processes a list from back to front, the
address of the "next" piece can be obtained before constructing the
preceding piece.  If the packer can process a complete list, it
returns an array containing a single packed string, a byte string
consisting of a count of the number of packed items, followed by
length/value pairs for each item.  If the packer runs out of space, it
returns an array of the packed string and the offset of the remaining
items

For example, given the list @a = qw(alpha bravo charlie delta), and a
maxsize=15, PackRow2 returns a packed string (something like
x01x05delta) and the offset 3, indicating that the last item in the
list was processed, and the packer ran out of space at the third item.
The packed string could be stored in a pushhash, which would return an
index, e.g. "5/2", suitable for a next pointer.  Packing the remainder
of the string generates another packed string
(e.g. x02x07charliex035/2) and the offset 2.  The packing and storage
process continues until the entire list is consumed.

=head2 advanced topics

=over 4

=item null vector

The packed string always contains a bitstring to identify null
columns, which is used by UnPackRow to correctly distinguish between
nulls and zero length strings.

=item next pointer

Since the next pointer is used to find the next part of a split row,
it must always remain whole -- if it was split, how could you find the
next piece?  The next pointer is a convention supported by
PackRow/UnPackRow to facilitate the construction of methods that
manipulate split rows.  The packing function only flattens an array
into a byte string or series of strings; it does not provide any
intrinsic support to traverse these strings.  Functions that
manipulate packed rows may use additional structures to support
multi-part rows, such as external metadata in the block row directory,
or specialized metadata columns embedded in the row itself.


=item column splitting (fragmentation)

The packer can support rows with individual columns that exceed the
maxsize.  The offset can simultaneously maintain the current column
position, as well as the current character offset in that column.
It's wicked complicated.  Generally, we say that a row is split into
row pieces, and the row pieces are chained (via the next pointers),
which lets us reconstruct a complete row.  Individual columns that are
split are said to be fragmented.

=back

=head2 future work

The packer could be extended to support more complex structures than
arrays of scalars.  In lieu of this ability, these structures can be
flattened using Data::Dumper or YAML to large strings.

=cut

#
# val, maxsize,
# offset, next
#
sub PackRow2
{
    use POSIX ; #  need some rounding
#    whoami;
    my ($value, $maxsize, $offset, $next) = @_ ;
#    greet @_;
    my @outi;

    # Note: maxsize must be an integer -- round down
    $maxsize = POSIX::floor($maxsize); 


    # Need to support an offset that allows a split column, not just a
    # split row.

    # Column Offset / Substr Offset
    my ($coloff, $suboff) = split('/', $offset);
    my @subargs;
    if (defined($suboff))
    {
        # substr (col, 0, $suboff)
        push @subargs, 0;
        push @subargs, $suboff;
    }

    # Note: if offset indicates that column was split then mark
    # next ptr

    my $gotnext = (defined($next)); # have a next ptr at end...

    # the next ptr is always the last column in a packed row, which
    # means it is the first column packed.  It *must* fit without
    # fragmentation.

    my $numcols = scalar (@{$value});
    if (defined($coloff))
    {
        if ($coloff > $numcols)
        {
            whisper "offset $coloff greater than $numcols";
            return undef;
        }
        $numcols = $coloff;
    }

    # XXX: should fix this to allow negative offsets, like standard
    # arrays.  Just scalar(val) + $numcols if numcols < 0 ? Need to
    # fix offset to be zero based, not one based, in that case
    $numcols++
        if ($gotnext); # add one for next ptr, which is last col...

#    my $numbits = 8 * (($numcols < 8) ? 1 : (int($numcols/8) + 1));
    my $numbits = PackBits($numcols);
    my $nullstr = pack("B*", "0"x$numbits); # bitvec of null columns

    my ($packstr, $prevpack, $max2);
    my $headstr = pack($PACK_NUMCOL, $numcols);

    my $colcnt = 0;
    
    if (defined($maxsize))
    {
        if (0) # ($maxsize < 30) # don't fragment too small...
        {
            return undef;
        }

        $max2  = $maxsize; # adjust max2 to reflect space left
#        greet $max2;

        # size of column count is constant (len headstr)
        # size of nullstr at least 1 byte...
        $max2 -= length($headstr) + length(pack($PACKVAL_STR, $nullstr)); 
#        greet $max2;

    }

    if ($numcols)
    {
        my $cnt8 = 1; # every 8 cols increment the size of the nullstr,
                      # i.e., decrement max2.  Start off with 1 bit deficit,
                      # since used bit zero for metadata indicator.

        $colcnt = $numcols;

        # Note: treat first pass thru loop special to deal with next
        # ptr, if one exists.  Note that colcnt was already
        # incremented for an extra (next) column, so offset and
        # nullstr positioning should work.
        my $firstpass = $gotnext; 

      L_allcols:
        while ($colcnt > 0)
        {
            my $elt = $firstpass ? $next : ($value->[$colcnt - 1]);
            unless (defined($elt))
            {
#                vec($nullstr, ($colcnt - 1), 1) = 1;
                vec($nullstr, $colcnt, 1) = 1;
                $elt = "";
            }

          L_trypack:
            for my $trypack (1..2)
            {
                if (!$firstpass && scalar(@subargs)) # take substring
                {
                    # Note: but don't take substr of next ptr
                    # (firstpass)
                    
                    {
                        my $pack1 = substr($elt, $subargs[0], $subargs[1]);
                  
#                        greet "foo:", $colcnt, $elt,$trypack,$pack1, @subargs;
      
                        $packstr = pack($PACKVAL_STR, $pack1);
                    }

                }
                else # no substring
                {
                    $packstr = pack($PACKVAL_STR, $elt);
                }

                # max length check
                if (   (defined($max2)) 
                    && (length($packstr) > $max2)
                       )
                {
#                    greet "max: ", $trypack, $max2, $packstr;

                    # XXX: assert trypack == 1 --> 1st try only!!

                    if ($firstpass)
                    {
                        # can't partially pack the next ptr
                        whisper "error: no room for next ptr!";
                        return undef;
                    }

                    # TODO XXX XXX: subtle issue if can pack next ptr, but
                    # cannot pack substring of last element.  Need to
                    # process subargs specially?  
                    # Return subargs[0]+subargs[1]?

                    # don't split column unless greater than 30 bytes

                    if ($max2 <= 6) # need some minimum space
                    {
                        # reset the packed string and 
                        # break if no space left...
                        $packstr = $prevpack; 
                        last L_allcols; 
                    }

                    # else try to pack a substring

                    # NOTE: do substr in reverse, too

                    if (scalar(@subargs))
                    {
                        my $sublen = $subargs[1] - $subargs[0];       

                        my $subadjust = $sublen - ($max2 - 6);

                        $subargs[0] += $subadjust;
                        $subargs[1] -= $subadjust;
#                        greet "z:", @subargs;
                            
                    } # end got subargs
                    else
                    {
                        my $sublen = length($elt) - $max2;
                        $sublen += 6;
                        push @subargs, $sublen;

                        # XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX
                        # XXX XXX: subtle fencepost error here -- need
                        # to figure this out!  (... + 1) because
                        # substr is zero-based, not 1-based?
                        push @subargs, ($max2 - 6) + 1;
#                        greet "c:", @subargs;
                    }

                    # try again
                    next L_trypack;

                } # end if max2 and len > max2

                if ($trypack > 1)
                {
                    # Note: only do a 2nd try for a column split, so
                    # we must be out of space to pack any more
                    # columns.  Complete the pack string with the
                    # previous packed, and exit the loop over all
                    # columns.
                    $packstr .= $prevpack
                        if (defined($prevpack));

                    # don't increment col cnt, just end
                    last L_allcols;
                }

                # else normal, nonsplit case -- pack succeeded
                @subargs = ()           # clear the subargs
                    if (!$firstpass);   # as long as this wasn't the nextp

                # if we get here, we are done.
                last L_trypack;
            } # end for trypack

#            greet $packstr, $prevpack;

            $max2 -= length($packstr)
                if (defined($max2));

            $packstr .= $prevpack
                if (defined($prevpack));
            $prevpack = $packstr;

            $colcnt--;
            $cnt8++;
            if ($cnt8 >= 8)
            {
                $cnt8 = 0;
                $max2--
                    if (defined($max2));
            }

            $firstpass = 0;
        } # end while colcnt
    } # end if numcols

    if ($colcnt > 0)
    { # split row
#        whisper "overflow";
#    print unpack("b*", $nullstr), "\n";

        my $packcols = $numcols - $colcnt;

        if (scalar(@subargs))
        {
#            greet "ov: ",$packcols, $numcols, $colcnt, @subargs;
            $packcols++; # increase the "packed" columns, even though
                         # we didn't pack a complete column
        }

#        my $packbits = 8 * (($packcols < 8) ? 1 : (int($packcols/8) + 1));
        my $packbits = PackBits($packcols);

        my $nstr = pack("B*", "0"x$packbits); # bitvec of null columns
        my $c2 = $numcols;

        # next ptr thing...
        my $firstpass = $gotnext; 

        while ($c2 > 0)
        {
            my $elt = $firstpass ? $next : $value->[$c2 - 1];
            unless (defined($elt))
            {
#                vec($nstr, (($c2 - $colcnt) - 1), 1) = 1;
                vec($nstr, ($c2 - $colcnt), 1) = 1;
            }
            $c2--;
            $firstpass = 0;
        }

        return undef
            unless (defined($packstr));
        my $headstr = pack($PACK_NUMCOL, $packcols);
#        $headstr .= pack($PACKVAL_STR, $nstr);
        $headstr .= $nstr;
        $headstr .= $packstr
            if (defined($packstr));
        push @outi, $headstr;
        if (scalar(@subargs))
        {
            # XXX XXX: push substr if substr
            $colcnt .= '/' . $subargs[0];
        }
        push @outi, $colcnt;
        if (scalar(@subargs))
        {
            push @outi, "F"; # fragmented
        }

    } # end split row
    else
    {
#        whisper "fits";
#    print unpack("b*", $nullstr), "\n";
#        $headstr .= pack($PACKVAL_STR, $nullstr);
        $headstr .= $nullstr;
        $headstr .= $packstr
            if (defined($packstr));
        push @outi, $headstr;
    }

    return @outi;

} # end packrow2

sub UnPackRow
{
    my ($packstr, $templ_arr) = @_;

#   whoami;
    # whisper "bad!" unless (defined($packstr));

    my $numcols = unpack($PACK_NUMCOL, $packstr);

    my @outarr ;

#    return @outarr
#        unless ($numcols);

    my $templ;
    
    if (defined($templ_arr)) # see if unpack template was predefined
    {
        if (exists($templ_arr->[$numcols]))
        {
            $templ = $templ_arr->[$numcols];
        }
    }

    unless (defined($templ))
    {
        my $skippy = _numcol_len($numcols); # byte length of the column count

        $templ     = "x$skippy "; # unpack template to skip column count bytes

        my $nullvec_len = PackBits($numcols) / 8; # byte length of null vector

        # build string to unpack each column
        $templ  .= "a$nullvec_len ";               # unpack the null bitvec
        $templ  .= "$UnPACKVAL_TYPE " x $numcols;  # unpack other cols
    }
    # skip the column count before each col
    @outarr = unpack($templ, $packstr);

    my $nullstr = shift @outarr;

 #   prints co1,col2...   
#    print unpack("b*", $nullstr), "\n";
    foreach my $colcnt (0..($numcols - 1))
    {
        if (vec($nullstr, $colcnt+1, 1) == 1)
        {
#            print "$colcnt\n";
#   print unpack("b*", $nullstr), "\n";
            $outarr[$colcnt] = undef;
        }
    }

    return (@outarr);
}

sub FileGetHeaderInfo
{
#    whoami;
    my %optional = (
                    fh_offset => 0
                    );
    my %required = (
                    filehandle => "no filehandle!",
                    filename   => "no filename!"
                    );

    my %args = (%optional,
                @_);

    die unless (exists($args{filehandle}));
    die unless (exists($args{filename}));
                    
    my $fh        = $args{filehandle};
    my $fname     = $args{filename};
    my $fh_offset = $args{fh_offset};

    my $buf;
    my $maxHeadersize = $ALIGN_BLOCKSIZE; # was 2048;
    my $hdrsize       = 0;

    $fh_offset = 0 # seek starts at beginning of file
        unless (defined($fh_offset));

    sysseek ($fh, $fh_offset, 0 )
        or die "bad seek - file $fname : $! \n";

    gnz_read ($fh, \$buf, $maxHeadersize)
        == $maxHeadersize
            or die "bad read - file $fname : $! \n";

    my @val;

    if (0) # wait until Z template is fixed in 5.7
    {
        @val = unpack("Z*N", $buf);

#        greet @val;
    }
    else
    {      # find the null terminator, grab the string and checksum
#        greet $buf;
        my @ggg =  split(/\0/, $buf, 2);

#        greet @ggg;

        die "no null terminator!"
            unless (scalar(@ggg) > 1);

        $val[0] = $ggg[0];
        $val[1] = unpack("N", $ggg[1]);
#        greet @val;
    }

    my $hstr  = shift @val;
    my $cksum = shift @val;

    warn "invalid checksum for file header - file $fname\n"
        unless ($cksum == (unpack("%32C*", $hstr) % 65535));

    my @tok = split(/\s+/, $hstr);

    my $filetype = shift @tok;
    my ($version, $blocksize);

    return undef
        unless (defined($filetype) && ($filetype =~ m/^GNZO$/));

    my %h1;

    for my $t1 (@tok)
    {
        my @kv = split(/=/, $t1);
#        print $kv[0]," ",$kv[1],"\n";

        my $kk = $kv[0];
        my $vv = $kv[1];
        # URL-style substitution to handle spaces, weird chars
        $kk =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
        $vv =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;

        $h1{$kk} = $vv; # hash of all key values
    }

    $version   = $h1{V};
    $blocksize = $h1{bsz};

    # add 1 byte for null terminator
    $hdrsize = length($hstr) + length(pack("N", 0)) + 1;
    $hdrsize = 64                   # boost to minimum of 64
        if ($hdrsize < 64);
#    print "hdr: ", $hdrsize, "\n";

  # $hdrsize += $fh_offset; # need overall offset to block zero for BCFile...

    return ($hdrsize, $version, $blocksize, \%h1);
}

sub FileSetHeaderInfo
{
#    whoami;
    my %optional = (
                    fh_offset => 0
                    );
    my %required = (
                    filehandle => "no filehandle!",
                    filename   => "no filename!",
                    newkey     => "no key!",
                    newval     => "no val!"
                    );

    my %args = (%optional,
                @_);

    die unless (exists($args{filehandle}));
    die unless (exists($args{filename}));
    die unless (exists($args{newkey}));
    die unless (exists($args{newval}));
                    
    my $fh        = $args{filehandle};
    my $fname     = $args{filename};
    my $fh_offset = $args{fh_offset};

    my ($hdrsize, $version, $blocksize, $h1) =
        FileGetHeaderInfo(filehandle => $fh, 
                          filename   => $fname,
                          fh_offset  => $fh_offset);

#    print "\n$hdrsize\n";

    my $buf;

    sysseek ($fh, $fh_offset, 0 )
        or die "bad seek - file $fname : $! \n";

    gnz_read ($fh, \$buf, $hdrsize)
        == $hdrsize
            or die "bad read - file $fname : $! \n";

    my @val;

    if (0) # wait until Z template is fixed in 5.7
    {
        @val = unpack("Z*N", $buf);

#        greet @val;
    }
    else
    {      # find the null terminator, grab the string and checksum
#        greet $buf;
        my @ggg =  split(/\0/, $buf, 2);

#        greet @ggg;

        die "no null terminator!"
            unless (scalar(@ggg) > 1);

        $val[0] = $ggg[0];
        $val[1] = unpack("N", $ggg[1]);
#        greet @val;
    }

    my $hstr  = shift @val;
    my $cksum = shift @val;

    my $kk = $args{newkey};
    my $vv = $args{newval};
    # URL-style substitution to handle spaces, weird chars
    $kk =~ s/([^a-zA-Z0-9])/uc(sprintf("%%%02lx",  ord $1))/eg;
    $vv =~ s/([^a-zA-Z0-9])/uc(sprintf("%%%02lx",  ord $1))/eg;

    if (exists($h1->{$args{newkey}}))
    {
        # update an existing pair
        my $oldval = $h1->{$args{newkey}};
        $oldval =~ s/([^a-zA-Z0-9])/uc(sprintf("%%%02lx",  ord $1))/eg;

        my $oldpair = " " . $kk ."=" . $oldval . " ";
        my $kvpair = " " . $kk ."=" . $vv . " ";

        my $len_dif = length($oldpair) - length($kvpair);
        
        if ($len_dif >= 0) 
        {
            # old pair is longer

            if ($len_dif)
            {
                # add extra space if necessary
                $hstr .= " " x $len_dif ;
            }
        }
        else
        {
            # new pair is longer
            
            $len_dif *= -1; # normalize

            # check if have enough trailing space for new val
            my $spacelist = " " x ($len_dif + 1);

            return undef
                unless ($hstr =~ m/$spacelist/);

            # truncate the spaces to preserve header length
            my $one_space = " ";
            $hstr =~ s/$spacelist/$one_space/;

        }
        # finally, update the values
        $hstr =~ s/$oldpair/$kvpair/;

        return undef
            unless ($hstr =~ m/$kvpair/);

    }
    else
    {
        # replace trailing spaces with new pair
        my $kvpair = " " . $kk ."=" . $vv . " ";
        my $spacelist = " " x length($kvpair);

        $hstr =~ s/$spacelist/$kvpair/;

        return undef
            unless ($hstr =~ m/$kvpair/);
    }

    $cksum = unpack("%32C*", $hstr) % 65535;

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

    sysseek ($fh, $fh_offset, 0 )
        or die "bad seek - file $fname : $! \n";

    my $hdr = gnz_write ($fh, $pack_hdr, length($pack_hdr));

    return $pack_hdr;

}

sub GetIndexKeys
{
    my $filter = shift;

    return undef
        unless (exists($filter->{idxfilter}));

    {
        my @arr1 = @{$filter->{idxfilter}};
        #    greet @arr1;

        my $sval = 0; # 0 = seek first idx col
                      # 1 = match relop
                      # 2 = find literal for index key

        my (@startkey, @stopkey);
        my $prevtoken;

        my $colnum;

        for my $token (@arr1)
        {
            unless (defined($token))
            {
                $sval = 0;
                next;
            }

            if (0 == $sval)
            {
                if (exists($token->{col}))
                {
                    $colnum = $token->{col};
                    $sval++;
                }
            }
            elsif (1 == $sval)
            {
                if (exists($token->{op}))
                {
                    $prevtoken = $token;
                    $sval++;
                }
                else
                {
                    $sval = 0;
                }
            }
            elsif (2 == $sval)
            {
                if (exists($token->{literal}))
                {
                    my $t_lit = $token->{literal};
                    my @cleankey;
                    
                    # remove double/single quotes for char strings

                    @cleankey = ($t_lit =~ m/^\"(.*)\"$/);
                    
                    if (scalar(@cleankey))
                    {
                        $t_lit = shift @cleankey;
                    }
                    else 
                    {
                        @cleankey = ($t_lit =~ m/^\'(.*)\'$/);
                        $t_lit = shift @cleankey
                            if (scalar(@cleankey));
                    }

                    if ($t_lit =~ /^\(/)
                    {
                        whisper "expression";
                        $sval = 0;
                        next;
                    }
                    
                    # XXX XXX XXX XXX XXX
                    #if ($self->{pkey_type} eq "n")
                    #{
                    #    # check for numbers...
                    #    unless ($t_lit =~ /\d+/)
                    #    {
                    #        whisper "not a number";
                    #        $sval = 0;
                    #        next;
                    #    }
                    #}
                    # XXX XXX XXX XXX
                    
                    if ($prevtoken->{op} =~ m/^(==|eq)$/)
                    { # equality
                        $startkey[$colnum] = $t_lit;
                        $stopkey[$colnum] = $t_lit;

                        # only need a single equality predicate --
                        # short circuit here
#                        last;
                    }
                    elsif ($prevtoken->{op} =~ m/^(<|lt|le|<=)$/)
                    { # stopkey
#                            if (defined($iKey[1])
 #                               && 
                        $stopkey[$colnum] = $t_lit;
                    }
                    elsif ($prevtoken->{op} =~ m/^(>|gt|ge|>=)$/)
                    { # startkey
                        $startkey[$colnum] = $t_lit;

                    }
                }
                $sval = 0;
            } # end if 2 == sval
            
        } # end for

        my @foo;
        push @foo, \@startkey;
        push @foo, \@stopkey;
        return @foo;

    }

    return undef;

} # end GetIndexKeys


# Raw IO functions

sub setUseRaw
{
    my $val = shift;

    if ($val && !$RAW_IO)
    {
        $RAW_IO = 1;
        my $raw_io_class = "Genezzo::RawIO";
        if (eval "require $raw_io_class")
        {
            my $s1;
            ($s1 = <<'EOF_S1') =~ s/^\#//gm;            
#sub Genezzo::Util::gnz_read_impl(*\$$)
#{
#    my ($filehandle, $scalar, $length) = @_;
#
#    return Genezzo::RawIO::gnz_raw_read($filehandle, $$scalar, $length);
#}
EOF_S1

            my $s2;
            ($s2 = <<'EOF_S2') =~ s/^\#//gm;            
#sub Genezzo::Util::gnz_write_impl(*$$)
#{
#    my ($filehandle, $scalar, $length) = @_;
#
#    return Genezzo::RawIO::gnz_raw_write($filehandle, $scalar, $length);
#}
EOF_S2
            unless (eval $s1)
            {
                carp "$@";
            }
            unless (eval $s2)
            {
                carp "$@";
            }
        }
        else
        {
            croak "failed to load - $raw_io_class\n$@";
        }
    }
    return $RAW_IO;
}
sub getUseRaw
{
    return $RAW_IO;
}

sub gnz_read_impl(*\$$)
{
    my ($filehandle, $scalar, $length) = @_;

    return sysread($filehandle, $$scalar, $length);
}

sub gnz_write_impl(*$$)
{
    my ($filehandle, $scalar, $length) = @_;

    return syswrite($filehandle, $scalar, $length);
}

sub gnz_read(*\$$)
{
    my ($filehandle, $scalar, $length) = @_;

    return gnz_read_impl($filehandle, $$scalar, $length);
}

sub gnz_write(*$$)
{
    my ($filehandle, $scalar, $length) = @_;

    return gnz_write_impl($filehandle, $scalar, $length);
}


# add a message to the mailbag (create the mailbag if necessary)
#
# To: a package name
# From: an object
# Msg:  a message
#
# behavior is rather open.  one message is 'RSVP', where the
# destination should call the FROM object's RSVP method, supplying
# its package name and the destination object
sub AddMail
{
    my %required = (
                    To => "no destination!",
                    From => "no source!",
                    Msg  => "no message!"
                    );
    my %optional = (
                    MailBag => []
                    );

    my %args = (
#                %optional,
		@_);

    return undef
        unless (Validate(\%args, \%required));

#    whoami;

    my $mailbag = $args{MailBag};

    my $newmsg = {};
    $newmsg->{To} = $args{To};
    $newmsg->{From} = $args{From};
    $newmsg->{Msg} = $args{Msg};

    push @{$mailbag}, $newmsg;

    return $mailbag;
}

# get our messages from the Mailbag.  All mail whose TO address
# matches the supplied ADDRESS is copied onto a separate message list
sub CheckMail
{
    my %required = (
                    MailBag => "no mailbag!",
                    Address => "no address!"
                    );
#    my %optional = (
#                    );

    my %args = (
#                %optional,
		@_);

    return undef
        unless (Validate(\%args, \%required));

    my $new_mailbag = [];

#    whoami;

    for my $msg (@{$args{MailBag}})
    {
        if ($msg->{To} eq $args{Address})
        {
            push @{$new_mailbag}, $msg;
        }
    }
    
    return $new_mailbag;

} # end checkmail


# GenDBI has a closure wrapping GZERR which controls whether the
# message is printed
sub get_gzerr_status
{
    my %required = (
                    GZERR => "no gzerr!",
                    self  => "no self!"
                    );
#    my %optional = (
#                    );

    my %args = (
#                %optional,
		@_);

    return undef
        unless (Validate(\%args, \%required));

    my $gzerr_cb = $args{GZERR};

    my $msg = "get status: 1\n";
    my %earg = (self => $args{self}, msg => $msg, severity => 'info', 
                no_info => 1,
                get_status => 1);

    return &$gzerr_cb(%earg);
    
}
sub set_gzerr_status
{
    my %required = (
                    GZERR => "no gzerr!",
                    status => "no status!",
                    self  => "no self!"
                    );
#    my %optional = (
#                    );

    my %args = (
#                %optional,
		@_);

    return undef
        unless (Validate(\%args, \%required));

    my $gzerr_cb = $args{GZERR};

    my $msg = "set status: $args{status}\n";
    my %earg = (self => $args{self}, msg => $msg, severity => 'info', 
                no_info => 1,
                set_status => $args{status});

    return &$gzerr_cb(%earg);
}

# add another output file (besides STDOUT) for gzerr
sub add_gzerr_outfile
{
    my %required = (
                    GZERR => "no gzerr!",
                    filename => "no filename!",
                    fh => "no fh!",
                    self  => "no self!"
                    );
#    my %optional = (
#                    );

    my %args = (
#                %optional,
		@_);

    return undef
        unless (Validate(\%args, \%required));

    my $gzerr_cb = $args{GZERR};

    my $msg = "add outfile: $args{filename}\n";
    my %earg = (self => $args{self}, msg => $msg, severity => 'info', 
                no_info => 1,
                add_file => $args{filename},
                fh => $args{fh}
                );

    return &$gzerr_cb(%earg);
}

sub drop_gzerr_outfile
{
    my %required = (
                    GZERR => "no gzerr!",
                    filename => "no filename!",
                    self  => "no self!"
                    );
#    my %optional = (
#                    );

    my %args = (
#                %optional,
		@_);

    return undef
        unless (Validate(\%args, \%required));

    my $gzerr_cb = $args{GZERR};

    my $msg = "drop outfile: $args{filename}\n";
    my %earg = (self => $args{self}, msg => $msg, severity => 'info', 
                no_info => 1,
                drop_file => $args{filename},
                );

    return &$gzerr_cb(%earg);
}


END { }       # module clean-up code here (global destructor)

## YOUR CODE GOES HERE

1;  # don't forget to return a true value from the file

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::Util - Utility functions

=head1 TODO

=over 4

=item Should bundle all data file utility functions, such as FileGetHeaderInfo,
SetHeaderInfo, etc, under separate Util::DataFile module

=item FileGetHeaderInfo: need to handle case of header which exceeds a 
single block.  Probably should keep increasing the buffer size until
find null terminator (within reason).

=item packrow: store metadata in col0 vs trailing col with next ptr

=item packrow: check pack format for a zero len row of zero cols. 
Does it need a nullvec?

=item packrow/unpackrow: in Perl 5.8 could use the nifty repeating
      templates to our advantage.

=item packrow: could generate skiplists as col zero metadata tracking byte
      position and column numbers to speed lookups

=back

=head1 AUTHOR

Jeffrey I. Cohen, jcohen@genezzo.com

=head1 SEE ALSO

L<perl(1)>.

Copyright (c) 2003-2007 Jeffrey I Cohen.  All rights reserved.

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
