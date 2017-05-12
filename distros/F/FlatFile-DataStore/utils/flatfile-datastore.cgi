#!/usr/local/bin/perl -T

use warnings;
use strict;
use URI::Escape;
use Data::Dumper;

use CGI qw/:standard -newstyle_urls/;
use CGI::Carp 'fatalsToBrowser';
$CGI::POST_MAX=1024 * 100;  # max 100K posts
$CGI::DISABLE_UPLOADS = 1;  # no uploads
my $CGI = CGI::->new();

use lib './perlib';
use Math::Int2Base qw( int2base base2int base_chars );

$|++;

my %Info;
display_page( 'FlatFile::DataStore URI Analysis' );

exit;

#---------------------------------------------------------------------
sub display_page {
    my( $title ) = @_;

    my $vars = { title => $title, url => $CGI->self_url() };
    my $loops = {};
    load_vars_loops( $vars, $loops );

    my $page = join '', <DATA>;
    print expand_template( $page, $vars, $loops );
}

#---------------------------------------------------------------------
sub load_vars_loops {
    my( $vars, $loops ) = @_;

    my %preamble = ( %{$Info{'preamble'}} );
    my %required = ( %{$Info{'required'}} );
    my %optional = ( %{$Info{'optional'}} );

    # note: this is a recommended -- but not at all required -- preamble order:
    for ( qw( indicator date keynum reclen transnum
              thisfnum thisseek prevfnum prevseek nextfnum nextseek
              user ) ) {
        push @{$loops->{'preamble_parameters'}}, { parm => $_ };
    }
    for ( qw( name recsep ) ) {
        push @{$loops->{'required_parameters'}}, { parm => $_ };
    }
    for ( qw( desc datamax keymax tocmax dirmax dirlev) ) {
        push @{$loops->{'optional_parameters'}}, { parm => $_ };
    }

    my %given;
    my @errors;

    for my $name ( $CGI->param ) {
        my $value = $CGI->param( $name );
        if( defined $value and $value ne '' ) {
            if( $preamble{ $name } ) {
                my( $msg, $errors, $summary ) = analysis( preamble => $name, $value );
                push @{$loops->{'preamble'}}, {
                    name     => $name,
                    value    => $value,
                    info     => $preamble{ $name },
                    analysis => $msg,
                    errors   => $errors,
                    summary  => $summary,
                    };
                $vars->{'errors'}++ if $errors;
            }
            elsif( $required{ $name } ) {
                my( $msg, $errors, $summary ) = analysis( required => $name, $value );
                push @{$loops->{'required'}}, {
                    name     => $name,
                    value    => $value,
                    info     => $preamble{ $name },
                    analysis => $msg,
                    errors   => $errors,
                    summary  => $summary,
                    };
                $vars->{'errors'}++ if $errors;
            }
            elsif( $optional{ $name } ) {
                my( $msg, $errors, $summary ) = analysis( optional => $name, $value );
                push @{$loops->{'optional'}}, {
                    name     => $name,
                    value    => $value,
                    info     => $optional{ $name },
                    analysis => $msg,
                    errors   => $errors,
                    summary  => $summary,
                    };
                $vars->{'errors'}++ if $errors;
            }
            else {
                push @errors, { name => $name, msg => "'$name' not allowed: $name=$value" };
            }
            push @errors, { name => $name, msg => "'$name' given more than once: $name=$value" }
                if $given{ $name }++;
            $vars->{'errors'} += @errors if @errors;
        }
    }
    for my $name ( grep {not $given{ $_ }} sort keys %optional ) {
        my( $msg, $errors, $summary ) = analysis( optional => $name );
        push @{$loops->{'optional'}}, {
            name     => $name,
            info     => $optional{ $name },
            analysis => $msg,
            errors   => $errors,
            summary  => $summary,
            };
        $vars->{'errors'}++ if $errors;
    }
    for my $name (
        grep {not $given{ $_ }} sort keys %preamble,
        grep {not $given{ $_ }} sort keys %required     ) {
        if( $preamble{ $name } ) {
            my( $msg, $errors, $summary ) = analysis( preamble => $name );
            push @{$loops->{'missing'}}, {
                name     => $name,
                info     => $preamble{ $name },
                analysis => $msg,
                errors   => $errors,
                summary  => $summary,
                };
            $vars->{'errors'}++ if $errors;
        }
        else {
            my( $msg, $errors, $summary ) = analysis( required => $name );
            push @{$loops->{'missing'}}, {
                name     => $name,
                info     => $required{ $name },
                analysis => $msg,
                errors   => $errors,
                summary  => $summary,
                };
            $vars->{'errors'}++ if $errors;
        }
    }
    for( $vars->{'errors'} ) {
        if( defined ) {
            if( $_ == 1 ) { $_ = "$_ error/warning."  }
            else          { $_ = "$_ errors/warnings." }
        }
        else              { $_ = "No errors." }
    }
}

#---------------------------------------------------------------------
sub analysis {
    my( $type, $name, $value ) = @_;
    my $ascii_chars = qr/^[ -~]+$/;
    my $escaped = uri_escape( $value );
    my $msg  = "($type) $name=$escaped";
       $msg .= " ($value)" if $value ne $escaped;
    my $has_value = defined $value and $value ne '';

    my @msg = ( $msg );
    my @errors;
    if( $type eq 'required' or $type eq 'preamble' ) {
        push @errors, { name => $name, msg => "Missing: '$name' is required." } unless $has_value;
    }

    if( $name eq 'name' ) {
        if( $has_value ) {
            if( $value =~ / / ) {
                push @errors, { name => $name, msg => "Name contains a space -- is this really necessary?" };
            }
            if( $value !~ $ascii_chars ) {
                push @errors, { name => $name, msg => "Name contains non-ascii characters -- is this really necessary?" };
            }
        }
    }
    elsif( $name eq 'desc' ) {
        if( length $value > 70 ) {
            push @errors, { name => $name, msg => "Desc is longer than 70 characters -- is this really necessary?" };
        }
    }
    elsif( $name eq 'indicator' ) {
        if( $has_value ) {
            my( $len, $chars ) = split /-/, $value, 2;
            push @errors, { name => $name, msg => qq/Length is '$len'. Only single-character indicators are supported./ } if $len != 1;
            my @c = split //, $chars;
            my %c = map { $_ => 1 } @c;
            my @n = keys %c;
            push @errors, { name => $name, msg => qq/Characters are '$chars'. Need five unique indicator characters./ } if @n != 5 or @c != 5;
            unless( @errors ) {
                my $i;
                for( qw( create oldupd update olddel delete ) ) {
                    push @msg, "$_: $c[ $i++ ]";
                }
            }
        }
    }
    elsif( $name eq 'date' ) {
        if( $has_value ) {
            push @errors, { name => $name, msg => "Must be either 8-yyyymmdd or 4-yymd." }
                unless $value eq '8-yyyymmdd' or $value eq '4-yymd';
        }
    }
    elsif( $name eq 'keynum' ) {
        if( $has_value ) {
            my( $len, $base ) = split /-/, $value;
            my $maxnum = substr( base_chars( $base ), -1) x $len;
            my $maxint = base2int $maxnum, $base;
            push @errors, { name => $name, msg => "Less than 100 records allowed -- is that intentional?" }
                if $maxint < 100;
            push @msg, "Allows for up to about ".commify( $maxint )." ($maxnum base-$base) records."
                unless @errors;
        }
    }
    elsif( $name eq 'reclen' ) {
        if( $has_value ) {
            my( $len, $base ) = split /-/, $value;
            my $maxnum = substr( base_chars( $base ), -1) x $len;
            my $maxint = base2int $maxnum, $base;
            push @errors, { name => $name, msg => "Records longer than 10 bytes not allowed -- is that intentional?" }
                if $maxint < 10;
            push @msg, "Allows for records up to about ".commify( $maxint )." ($maxnum base-$base) bytes long."
                unless @errors;
        }
    }
    elsif( $name eq 'recsep' ) {
        if( $has_value ) {
            my $ascii_chars = qr/^[\n-~]+$/;
            push @errors, { name => $name, msg => "Doesn't match qr/^[\\n-~]+\$/ -- is that intentional?" }
                unless $value =~ $ascii_chars;
        }
    }
    elsif( $name eq 'transnum' ) {
        if( $has_value ) {
            my( $len, $base ) = split /-/, $value;
            my $maxnum = substr( base_chars( $base ), -1) x $len;
            my $maxint = base2int $maxnum, $base;
            push @errors, { name => $name, msg => "No more than 10 transactions allowed -- is that intentional?" }
                if $maxint <= 10;
            push @msg, "Allows up to about ".commify( $maxint )." ($maxnum base-$base) transactions."
                unless @errors;
        }
    }
    elsif( $name eq 'thisfnum' ) {
        if( $has_value ) {
            my( $len, $base ) = split /-/, $value;

            push @errors, { name => $name, msg => "Length: '$len' too small (1 min)." } if $len < 1;
            push @errors, { name => $name, msg => "Base: '$base' too large (36 max)." } if $base > 36;

            my $maxnum = substr( base_chars( $base ), -1) x $len;
            my $maxint = base2int $maxnum, $base;
            push @msg, "Allows for up to ".commify( $maxint )." ($maxnum base-$base) data files."
                unless @errors;

            my $prevfnum = $CGI->param( 'prevfnum' );
            my $nextfnum = $CGI->param( 'nextfnum' );

            if( $prevfnum ) {
                push @errors, { name => $name, msg => "Does not match prevfnum ($prevfnum)." }
                    unless $value eq $prevfnum;
            }
            else {
                push @errors, { name => $name, msg => "Parm: prevfnum is missing." };
            }
            if( $nextfnum ) {
                push @errors, { name => $name, msg => "Does not match nextfnum ($nextfnum)" }
                    unless $value eq $nextfnum;
            }
            else {
                push @errors, { name => $name, msg => "Parm: nextfnum is missing." };
            }
        }
    }
    elsif( $name eq 'thisseek' ) {
        if( $has_value ) {
            my $prevseek = $CGI->param( 'prevseek' );
            my $nextseek = $CGI->param( 'nextseek' );

            my $datamax  = $CGI->param( 'datamax' );
            my $maxbytes = convert_datamax( $datamax );

            my( $len, $base ) = split /-/, $value;
            my $maxnum = substr( base_chars( $base ), -1) x $len;
            my $maxint = base2int $maxnum, $base;
            push @msg, "Allows for data files up to about ".commify( $maxint )." ($maxnum base-$base) bytes.";

            push @msg, "But this is restricted to ".commify( $maxbytes )." ($datamax) bytes by datamax."
                if $maxbytes and $maxbytes < $maxint;

            if( $prevseek ) {
                push @errors, { name => $name, msg => "does not match prevseek ($prevseek)" }
                    unless $value eq $prevseek;
            }
            else {
                push @errors, { name => $name, msg => "prevseek is missing" };
            }
            if( $nextseek ) {
                push @errors, { name => $name, msg => "does not match nextseek ($nextseek)" }
                    unless $value eq $nextseek;
            }
            else {
                push @errors, { name => $name, msg => "nextseek is missing" };
            }
        }
    }
    elsif( $name eq 'prevfnum' ) {
        if( $has_value ) {
            my( $len, $base ) = split /-/, $value;

            push @errors, { name => $name, msg => "Length: '$len' too small (1 min)." } if $len < 1;
            push @errors, { name => $name, msg => "Base: '$base' too large (36 max)." } if $base > 36;

            my $maxnum = substr( base_chars( $base ), -1) x $len;
            my $maxint = base2int $maxnum, $base;
            push @msg, "Allows for up to ".commify( $maxint )." ($maxnum base-$base) data files."
                unless @errors;

            my $nextfnum = $CGI->param( 'nextfnum' );
            my $thisfnum = $CGI->param( 'thisfnum' );

            if( $nextfnum ) {
                push @errors, { name => $name, msg => "Does not match nextfnum ($nextfnum)." }
                    unless $value eq $nextfnum;
            }
            else {
                push @errors, { name => $name, msg => "Parm: nextfnum is missing." };
            }
            if( $thisfnum ) {
                push @errors, { name => $name, msg => "Does not match thisfnum ($thisfnum)" }
                    unless $value eq $thisfnum;
            }
            else {
                push @errors, { name => $name, msg => "Parm: thisfnum is missing." };
            }
        }
    }
    elsif( $name eq 'prevseek' ) {
        if( $has_value ) {
            my $thisseek = $CGI->param( 'thisseek' );
            my $nextseek = $CGI->param( 'nextseek' );

            my $datamax  = $CGI->param( 'datamax' );
            my $maxbytes = convert_datamax( $datamax );

            my( $len, $base ) = split /-/, $value;
            my $maxnum = substr( base_chars( $base ), -1) x $len;
            my $maxint = base2int $maxnum, $base;
            push @msg, "Allows for data files up to about ".commify( $maxint )." ($maxnum base-$base) bytes.";

            push @msg, "But this is restricted to ".commify( $maxbytes )." ($datamax) bytes by datamax."
                if $maxbytes and $maxbytes < $maxint;

            if( $thisseek ) {
                push @errors, { name => $name, msg => "does not match thisseek ($thisseek)" }
                    unless $value eq $thisseek;
            }
            else {
                push @errors, { name => $name, msg => "thisseek is missing" };
            }
            if( $nextseek ) {
                push @errors, { name => $name, msg => "does not match nextseek ($nextseek)" }
                    unless $value eq $nextseek;
            }
            else {
                push @errors, { name => $name, msg => "nextseek is missing" };
            }
        }
    }
    elsif( $name eq 'nextfnum' ) {
        if( $has_value ) {
            my( $len, $base ) = split /-/, $value;

            push @errors, { name => $name, msg => "Length: '$len' too small (1 min)." } if $len < 1;
            push @errors, { name => $name, msg => "Base: '$base' too large (36 max)." } if $base > 36;

            my $maxnum = substr( base_chars( $base ), -1) x $len;
            my $maxint = base2int $maxnum, $base;
            push @msg, "Allows for up to ".commify( $maxint )." ($maxnum base-$base) data files."
                unless @errors;

            my $prevfnum = $CGI->param( 'prevfnum' );
            my $thisfnum = $CGI->param( 'thisfnum' );

            if( $prevfnum ) {
                push @errors, { name => $name, msg => "Does not match prevfnum ($prevfnum)." }
                    unless $value eq $prevfnum;
            }
            else {
                push @errors, { name => $name, msg => "Parm: prevfnum is missing." };
            }
            if( $thisfnum ) {
                push @errors, { name => $name, msg => "Does not match thisfnum ($thisfnum)" }
                    unless $value eq $thisfnum;
            }
            else {
                push @errors, { name => $name, msg => "Parm: thisfnum is missing." };
            }
        }
    }
    elsif( $name eq 'nextseek' ) {
        if( $has_value ) {
            my $thisseek = $CGI->param( 'thisseek' );
            my $prevseek = $CGI->param( 'prevseek' );

            my $datamax  = $CGI->param( 'datamax' );
            my $maxbytes = convert_datamax( $datamax );

            my( $len, $base ) = split /-/, $value;
            my $maxnum = substr( base_chars( $base ), -1) x $len;
            my $maxint = base2int $maxnum, $base;
            push @msg, "Allows for data files up to about ".commify( $maxint )." ($maxnum base-$base) bytes.";

            push @msg, "But this is restricted to ".commify( $maxbytes )." ($datamax) bytes by datamax."
                if $maxbytes and $maxbytes < $maxint;

            if( $thisseek ) {
                push @errors, { name => $name, msg => "does not match thisseek ($thisseek)" }
                    unless $value eq $thisseek;
            }
            else {
                push @errors, { name => $name, msg => "thisseek is missing" };
            }
            if( $prevseek ) {
                push @errors, { name => $name, msg => "does not match prevseek ($prevseek)" }
                    unless $value eq $prevseek;
            }
            else {
                push @errors, { name => $name, msg => "prevseek is missing" };
            }
        }
    }
    elsif( $name eq 'datamax' ) {
        if( $has_value ) {
            my $datamax = convert_datamax( $value );
            if( my $seek = $CGI->param( 'thisseek' ) ) {
                my( $len, $base ) = split /-/, $seek;
                my $maxnum = substr( base_chars( $base ), -1) x $len;
                my $maxint = base2int $maxnum, $base;
                push @errors, { name => $name, msg => "datamax too large (max is $maxint - see thisseek)" }
                    if $datamax > $maxint;
                push @errors, { name => $name, msg => "datamax less than 100,000 -- is that desired?" }
                    if defined $value and $datamax < 100_000;
            }
            else {
                push @errors, { name => $name, msg => "Can't analyze datamax without thisseek" };
            }
            push @msg, "Restricts data files to $datamax ($value) bytes."
                unless @errors;
        }
    }
    elsif( $name eq 'dirmax' ) {
        if( $has_value ) {
            push @msg, "$value files may be added to a directory before another directory is created.";
            my $dirlev   = $CGI->param( 'dirlev' );
               $dirlev ||= 1;
            my $plural = $dirlev==1? 0: 1;
            if( $plural ) {
                push @msg, "There are $dirlev levels of directories available (see dirlev), so about ".
                    commify($value**($dirlev+1))." files may be added in all.";
            }
            else {
                push @msg, "There is $dirlev level of directories available (see dirlev), so about ".
                    commify($value**($dirlev+1))." files may be added in all.";
            }
            push @msg, "This applies to data files, key files, and toc files.";
            push @errors, { name => $name, msg => "The value, $value, limits directories to less than 10 files -- is that intentional?" }
                if $value < 10;
        }
        else {
            push @msg, "No value given, so directories will be added to regardless of the number of files.";
            push @msg, "This applies to data files, key files, and toc files.";
        }
    }
    elsif( $name eq 'dirlev' ) {
        my $dirmax = $CGI->param( 'dirmax' );
        if( $dirmax ) {
            push @msg, "The parm, dirmax, says that ".commify($dirmax)." files may be added to a directory before another directory is created.";
        }
        my $dirlev = $has_value? $value: $dirmax? 1: '';
        if( $dirlev ) {
            if( $dirmax ) {
                my $plural = $dirlev==1? 0: 1;
                if( $plural ) {
                    push @msg, "There are $dirlev levels of directories available, so about ".
                        commify($dirmax**($dirlev+1))." files may be added in all.";
                }
                else {
                    push @msg, "There is $dirlev level of directories available, so about ".
                        commify($dirmax**($dirlev+1))." files may be added in all.";
                }
                push @msg, "This applies to data files, key files, and toc files.";
            }
            else {
                push @errors, { name => $name, msg => "This parm will be ignored, because there is no dirmax value." };
            }
        }
    }
    elsif( $name eq 'tocmax' ) {
        if( $has_value ) {
            push @msg,
                "A toc file may contain no more than ".commify( $value )." lines (one line per data file).",
                "If there are more data files than that, new toc files will be created.";
            push @errors, { name => $name, msg => "The value, $value, limits toc files to less than 10 lines -- is that intentional?" }
                if $value < 10;
        }
        else {
            push @msg, "No tocmax value is given, so toc files may grow indefinitely.";
        }
    }
    elsif( $name eq 'keymax' ) {
        if( $has_value ) {
            push @msg,
                "A key file may contain no more than ".commify( $value )." lines (one line per record).",
                "If there are more records than that, new key files will be created.";
            push @errors, { name => $name, msg => "The value, $value, limits key files to less than 10 lines -- is that intentional?" }
                if $value < 10;
        }
        else {
            push @msg, "No keymax value is given, so key files may grow indefinitely.";
        }
    }

    my $summary;
    my @err;
    if( @errors ) {
        push @msg, "ERRORS:\n";
        for( @errors ) {
            my $name = $_->{'name'};
            my $msg  = $_->{'msg'};
            push @err, qq'<a name="$name">$msg</a>';
        }
    }
    else {
        $summary = "\nLooks good."
    }
    return
        join( "\n" => @msg ),
        join( "\n" => @err ),
        $summary;
}

#---------------------------------------------------------------------
# convert_datamax(), convert user-supplied
#     datamax value into an integer: one can say, "500_000_000",
#     "500M", or ".5G" to mean 500,000,000 bytes

sub convert_datamax {
    my( $datamax ) = @_;

    # ignoring M/G ambiguities and using round numbers:
    my %sizes = ( M => 10**6, G => 10**9 );

    my $max = $datamax;
    $max =~ s/_//g;
    if( $max =~ /^([.0-9]+)([MG])/ ) {
        my( $n, $s ) = ( $1, $2 );
        $max = $n * $sizes{ $s };
    }

    return 0+$max;
}

#---------------------------------------------------------------------
sub commify {
    local $_  = shift;
    1 while s/^([-+]?\d+)(\d{3})/$1,$2/;
    return $_;
}

#---------------------------------------------------------------------
sub expand_template {
    my( $page, $vars, $loops ) = @_;

    1 while $page =~ s/{VAR:([^{}]+)}
        /$vars->{ $1 }/gx;
    1 while $page =~ s/{LOOP:([^{}]+)}(.*){END_LOOP:\1}
        /expand_loop( $2, $loops->{ $1 } )/gexs;

    return $page;
}

#---------------------------------------------------------------------
sub expand_loop {
    my( $text, $loops ) = @_;

    my @ret;
    for my $href ( @$loops ) {
        my $copy = $text;
        1 while $copy =~ s/{LVAR:([^{}]+)}/$href->{ $1 }/g;
        push @ret, $copy;
    }
    return join '' => @ret;
}

#---------------------------------------------------------------------
BEGIN {
%Info = (

required => {

name => <<__,
Name: short name for the data store.  Used for file names.

Example: name=myds
__

recsep => <<'__',
Recsep: record separator.  Usually \n or \r\n.  Is not
constrained by your platform (you could use \n on windows,
or \r\n on unix), but you might want to assume so just
to accommodate viewing the flat files directly.

Examples: recsep=%0A    (\n   -- LF    -- Unix-ish)
          recsep=%0D%0A (\r\n -- CR+LF -- DOS-ish)
          recsep=%0D    (\r   -- CR    -- Apple-ish)

Note that recsep need not be \n or \r or a combination.
It can be any (ascii) string, e.g., recsep=%0A---%0A
__
},

preamble => {

user => <<__,
User: specs for user data in preamble.  Has the form:

    length-charclass

The characters matched by charclass must be ascii.

Example: user=10-%20-%7E  (i.e., length:10 charclass:[ -~])
__

indicator => <<__,
Indicator: specs for CRUD indicators.  Has the form:

    length-charstring

The string, charstring, must contain 5 unique ascii characters.
Currently, length must be 1.

The 5 characters indicate (respectively):
    create: record was created and not updated
    oldupd: record was updated, and this is the old version
    update: record was updated, and this is the current version
    olddel: record was deleted, and this is the old version
    delete: record was deleted, and this is the "delete" record

Example: indicator=1-%2B%23%3D%2A%2D  (i.e. length:1 charstring:+#=*-)
__

date => <<__,
Date: specs for the date in the preamble.  Has the form:

    length-format

The string, format, must be either yyyymmdd or yymd, and the
length, respectively, 8 or 4.  The shorter date format uses
base62 to store the year, month, and day.

Examples: date=8-yyyymmdd
          date=4-yymd
__

keynum => <<__,
Keynum: specs for the key number.  Has the form:

    length-numberbase

The numberbase may range from 2 to 62, representing base-2
(i.e., binary) to base-62.  The length and numberbase define
the constraint on the maximum key number, i.e., the maximum
number of records in the data store.

Examples: keynum=6-10 (max ~1 million records)
          keynum=4-62 (max 14.7 million records)
__

reclen => <<__,
Reclen: specs for the record length.  Has the form:

    length-numberbase

The numberbase may range from 2 to 62. The length and
numberbase define the constraint on the maximum record
length (in bytes).

Examples: reclen=5-62 (max length ~916 million bytes)
          reclen=5-36 (max length ~60 million bytes)
          reclen=7-10 (max length ~10 million bytes)
__

transnum => <<__,
Transnum: specs for transaction number.  Has the form:

    length-numberbase

The numberbase may range from 2 to 62.  The length and
numberbase define the constraint on the maximum number
of transactions (creates, updates, deletes) for the
data store.

Examples: transnum=7-10 (max ~10 million transactions)
          transnum=6-62 (max ~900 million transactions)
__

thisfnum => <<__,
Thisfnum: specs for "this" file number.  Has the form:

    length-numberbase

The numberbase may range from 2 to 36, representing base-2
(i.e., binary) to base-36.  Note: 2 to 36, not 2 to 62, as
other specs allow.  Since the file numbers are used in file
names, restricting the range to base-36 means we don't get
file names that differ only in case (e.g., myds.A.data and
myds.a.data).

These specs and those for prevfnum and nextfnum must be
exactly the same, both length and numberbase.

The length and numberbase define the constraint on the
maximum number of data files in the data store.

Examples: thisfnum=1-10 (max 9 data files)
          thisfnum=1-62 (max 61 data files)
__

thisseek => <<__,
Thisseek: specs for "this" seek position.  Has the form:

    length-numberbase

The numberbase may range from 2 to 62.

These specs and those for prevseek and nextseek must be
exactly the same, both length and numberbase.

The length and numberbase define the constraint on the
maximum size (in bytes) of each of the data store's
data files.

Examples: thisseek=4-62 (max ~14 Megs)
          thisseek=5-62 (max ~.9 Gigs)
          thisseek=6-62 (max ~56 Gigs)
__

prevfnum => <<__,
Prevfnum: specs for "prev" file number.  Has the form:

    length-numberbase

The numberbase may range from 2 to 36.

These specs and those for thisfnum and nextfnum must be
exactly the same, both length and numberbase.

Examples: prevfnum=1-10
          prevfnum=1-62
__

prevseek => <<__,
Prevseek: specs for "prev" seek position.  Has the form:

    length-numberbase

The numberbase may range from 2 to 62.

These specs and those for thisseek and nextseek must be
exactly the same, both length and numberbase.

Examples: prevseek=4-62
          prevseek=5-62
          prevseek=6-62
__

nextfnum => <<__,
Nextfnum: specs for "next" file number.  Has the form:

    length-numberbase

The numberbase may range from 2 to 36.

These specs and those for thisfnum and prevfnum must be
exactly the same, both length and numberbase.

Examples: nextfnum=1-10
          nextfnum=1-62
__

nextseek => <<__,
Nextseek: specs for "next" seek position.  Has the form:

    length-numberbase

The numberbase may range from 2 to 62.

These specs and those for thisseek and prevseek must be
exactly the same, both length and numberbase.

Examples: nextseek=4-62
          nextseek=5-62
          nextseek=6-62
__
},

optional => {

desc => <<__,
Desc: short description for data store.  Not used internally.

Example: desc=My+Data+Store
__

dirmax => <<__,
Dirmax: maximum files in a directory.  This value is only
needed for particularly large data stores.  It lets you
limit how many data files (or key files or toc files) may
exist in a single directory.

If dirmax is not given, directories will keep being added to,
regardless of how many files are in them.

Example: dirmax=400
__

dirlev => <<__,
Dirlev: maximum number of directory levels.  This value is
only needed for particularly large data stores.

It lets you specify how many levels of directories to maintain.
Combined with dirmax, this will determine the total number of
data files that may be created.

If this value is 1, then dirmax**2 data files may be
created.  If this value is 2, then dirmax**3 data files
may be created.  Etc.

This value is ignored unless dirmax is also given.  If dirmax
is given and this value isn't, it defaults to 1.

Example: dirlev=3
__

tocmax => <<__,
Tocmax: maximum number of data file entries per toc (table
of contents) file.

This value is only needed for particularly large data stores.

A toc file contains one line per data file.  The tocmax value
will limit the number of lines per toc file, allowing this
information to span multiple toc files.

If no tocmax value is given, there will be only one toc
file, which will grow indefinitely.

Example: tocmax=1000  (only 1000 data files per toc file)
__

keymax => <<__,
Keymax: maximum number of key entries per key file.  The
key files are the indexes into the data files.

A key file contains one line per record.  The keymax value
will limit the number of lines per file, allowing theses
indexes to span multiple key files.

If no keymax value is given, there will be only one key
file, which will grow indefinitely.

Example: keymax=100000  (only 100,000 records per key file)
__

datamax => <<__,
Datamax: maximum number of bytes per data file.  In the
description of thisseek above, it says that the length and
numberbase of thisseek define the constraint on the maximum
size (in bytes) of each of the data store's data files.

If you want the maximum size to be smaller than that, you
can give a smaller datamax value.  For example, you might
say, thisseek=5-62 which would allow each data file to contain
about .9 Gigs of data.  But you might want to limit the
size of your data files to 500 Megs.  If so, you could say,
datamax=500000000 (or datamax=500_000_000 or datamax=500M
or datamax=.5G)

Example: datamax=5M
         datamax=1.9G
         datamax=42_000_000
__
},
);
}

__DATA__
Content-Type: text/html; charset=UTF-8

<html>
<head>
<title>{VAR:title}</title>
<style type="text/css">
body {
    font-family: sans-serif;
}
code {
    font-weight: bold;
}
pre {
    border: 1px solid #ccc;
    background: #eee;
    padding: .5em;
}
.url {
    border: 1px solid #9999ff;
    padding: .5em;
    background: #efeffa;
    width: 100%;
}
.errors {
    color: red;
}
.summary {
    color: green;
}
</style>
</head>
<body>

<h1>{VAR:title}</h1>
<a href="#missing">Missing</a> |
<a href="#required">Required</a> |
<a href="#preamble">Preamble</a> |
<a href="#optional">Optional</a>


<h2>Introduction</h2>
<ul>
<li>
The purpose of this page is to display, analyze, and help create the URI that will
serve as the confuration for a <a href="http://search.cpan.org/dist/FlatFile-DataStore/">FlatFile::DataStore</a>.
</li>
<li>
For pragmatic reasons, the user interface is extremely bare bones:
your input box is your browser's navigation bar above.
</li>
<li>
The URI below should (mostly) match the URI in the navigation bar above.
</li>
<li>
To change the output on this page, simply edit the parameters in the <i>above</i>
URI and go there.
</li>
<li>
To use the results, copy from the URI below, and paste into the [name].uri file.
</li>
</ul>

<form id="urlform" name="urlform" action="">
    <input class="url" name="url" value="{VAR:url}"
        onfocus="this.select();" onkeyup="this.select();">
</form>

<p>{VAR:errors}</p>

<h2>Parameters</h2>

<h3>Preamble Parameters (required)</h3>

<code>{LOOP:preamble_parameters}<a href="#{LVAR:parm}">{LVAR:parm}</a> {END_LOOP:preamble_parameters}</code>
<p>
Note: the order these appear in the URI determines the order they appear in the preamble.
The above order is a good place to start, but is not required.
</p>

<h3>Non-preamble Required Parameters</h3>

<code>{LOOP:required_parameters}<a href="#{LVAR:parm}">{LVAR:parm}</a> {END_LOOP:required_parameters}</code>

<h3>Optional Parameters</h3>

<code>{LOOP:optional_parameters}<a href="#{LVAR:parm}">{LVAR:parm}</a> {END_LOOP:optional_parameters}</code>

<h2><a name="missing">Missing Required Parameters</a></h2>

<dl>
{LOOP:missing}
<dt><a name="{LVAR:name}"><code>{LVAR:name}={LVAR:value}</code></a></dt>
<dd><pre>Analysis:
{LVAR:analysis}<span class="errors">{LVAR:errors}</span><span class="summary">{LVAR:summary}</span>
______________________________________________________________________

Information:
{LVAR:info}</pre></dd>
{END_LOOP:missing}
</dl>

<h2><a name="required">Required (non-preamble) Parameters</a></h2>

<dl>
{LOOP:required}
<dt><a name="{LVAR:name}"><code>{LVAR:name}={LVAR:value}</code></a></dt>
<dd><pre>Analysis:
{LVAR:analysis}<span class="errors">{LVAR:errors}</span><span class="summary">{LVAR:summary}</span>
______________________________________________________________________

Information:
{LVAR:info}</pre></dd>
{END_LOOP:required}
</dl>

<h2><a name="preamble">Preamble Parameters</a></h2>

<dl>
{LOOP:preamble}
<dt><a name="{LVAR:name}"><code>{LVAR:name}={LVAR:value}</code></a></dt>
<dd><pre>Analysis:
{LVAR:analysis}<span class="errors">{LVAR:errors}</span><span class="summary">{LVAR:summary}</span>
______________________________________________________________________

Information:
{LVAR:info}</pre></dd>
{END_LOOP:preamble}
</dl>

<h2><a name="optional">Optional Parameters</a></h2>

<dl>
{LOOP:optional}
<dt><a name="{LVAR:name}"><code>{LVAR:name}={LVAR:value}</code></a></dt>
<dd><pre>Analysis:
{LVAR:analysis}<span class="errors">{LVAR:errors}</span><span class="summary">{LVAR:summary}</span>
______________________________________________________________________

Information:
{LVAR:info}</pre></dd>
{END_LOOP:optional}
</dl>

</body>
</html>

