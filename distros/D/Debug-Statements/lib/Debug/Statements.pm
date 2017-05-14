# ABSTRACT:  Debug::Statements provides an easy way to insert and enable debug statements.
package Debug::Statements;
use warnings;
use strict;
use Carp;
use Time::HiRes qw(gettimeofday);
use Dumpvalue;
use Data::Dumper;
$Data::Dumper::Terse = 1;    # eliminate the $VAR1

use Exporter;
use base qw( Exporter );
our @EXPORT    = qw( d d0 d2 d3 D );
our @EXPORT_OK = qw( d d0 d1 d2 d3 ls D );

my $VERSION = '1.005';

my $printdebug = "DEBUG:  ";    # print statement begins with this
my $id         = 0;             # for debugging this module, turn on with d('', 10)
my $flag       = '$d';          # choose another variable besides '$d'
my $disable    = 0;             # disable all functionality (for performance)
if ( not eval "use PadWalker; 1" ) {  ## no critic
    $disable = 1;
    print "Did not find PadWalker so disabling Debug::Statements - d()\n";
    print "    Please install PadWalker from CPAN\n";
    eval 'sub d {}; sub d0 {}; sub d1 {} ; sub d2 {} ; sub d3 {} ; sub D {} ; sub ls {}';  ## no critic
}
my $truncateLines      = 10;
my $globalPrintCounter = 0;
my $evalcounter        = 0;
my %globalOpt;
$globalOpt{printSub} = 1;       # print name of subroutine 'b'
#$globalOpt{compress} = 1;       # compress array and hash 'z'
my $optionsTable = {
    'b' => 'printSub',
    'c' => 'Chomp',
    'e' => 'Elements',
    'n' => 'LineNumber',
    'q' => 'text',
    'r' => 'tRuncate',
    's' => 'Sort',
    't' => 'Timestamp',
    'x' => 'die',
    'z' => 'compress'
};

sub disable {
    $disable = 1;
    return;
}

sub enable {
    $disable = 0;
    return;
}

sub setPrintDebug {
    $printdebug = shift;
    return;
}

sub setFlag {
    $flag = shift;
    return;
}

sub setTruncate {
    $truncateLines = shift;
    return;
}

sub d {
    my ( $var, $options ) = @_;
    return if $disable;
    $options = "" if !$options;
    my $caller = ( caller(1) )[3] || "";
    dx( $caller, $var, "$options" );
    return;
}

sub d0 {
    my ( $var, $options ) = @_;
    return if $disable;
    $options = "" if !$options;
    my $caller = ( caller(1) )[3] || "";
    dx( $caller, $var, "0$options" );
    return;
}

sub D {
    # same as d0
    my ( $var, $options ) = @_;
    return if $disable;
    $options = "" if !$options;
    my $caller = ( caller(1) )[3] || "";
    dx( $caller, $var, "0$options" );
    return;
}

sub d1 {
    my ( $var, $options ) = @_;
    return if $disable;
    $options = "" if !$options;
    my $caller = ( caller(1) )[3] || "";
    dx( $caller, $var, "1$options" );
    return;
}

sub d2 {
    my ( $var, $options ) = @_;
    return if $disable;
    $options = "" if !$options;
    my $caller = ( caller(1) )[3] || "";
    dx( $caller, $var, "2$options" );
    return;
}

sub d3 {
    my ( $var, $options ) = @_;
    return if $disable;
    $options = "" if !$options;
    my $caller = ( caller(1) )[3] || "";
    dx( $caller, $var, "3$options" );
    return;
}

sub checkLevel {
    # Return if debug level is not high enough
    my ( $h, $level ) = @_;
    if ($id) { print "sub checkLevel()\n" }
    if ($id) { print "\n\ninternaldebug checkLevel:  Dumping \$h:\n"; Dumpvalue->new->dumpValue($h) }

    my $D;
    if ($id) { print "internaldebug checkLevel:  \$flag = '$flag'\n" }
    if ( $flag =~ /\S+::\S+/ ) {    ## problems here
        if ($id) { print "internaldebug checkLevel:  \$D is controlled by package variable $flag\n" }
        if ( !defined $flag ) {
            if ($id) { print "internaldebug checkLevel:  \$flag is not defined\n" }
            $D = 0;
        } else {
            $D = evlwrapper( $h, $flag, 'checkLevel $flag' );
        }
    } else {
        if ( !defined $h->{$flag} ) {
            if ($id) { print "internaldebug checkLevel:  \$h->{$flag} is not defined\n" }
            $D = 0;
        } elsif ( !defined ${ $h->{$flag} } ) {
            if ($id) { print "internaldebug checkLevel:  \$h->{$flag} is defined  but  \${\$h->{$flag}} is not defined\n" }
            $D = 0;
        } else {
            # This is the expected case
            $D = ${ $h->{$flag} };
        }
    }
    if ( !defined $D ) {
        if ($id) { print "internaldebug checkLevel:  \$D is undef\n" }
        $D = 0;
    }

    if ($id) { print "internaldebug checkLevel:  \$D = '$D'\n" }

    # If $d is negative, turn on $id (internal debug flag), and use the absolute value of $d
    if ( $D < 0 ) {
        if ( !$id ) { print "internaldebug checkLevel:  Turning on \$id with negative value\n" }
        $D  = abs($D);
        $id = 1;
    } else {
        if ($id) { print "internaldebug checkLevel:  Turning off \$id with positive value\n" }
        $id = 0;
    }

    if ( $D >= $level ) {
        return 1;
    } else {
        if ($id) { print "internaldebug checkLevel:  Returning because \$D < \$level\n" }
        return 0;
    }
}

sub dx {
    my ( $caller, $vars, $options ) = @_;

    if ($id) { print "\n\n\n\n\n\n\n\n--------------- sub dx() ---------------\n" }
    if ($id) { print "internaldebug:  \@_ = '@_'\n" }

    my $h = PadWalker::peek_my(2);
    if ($id) { print "\n\ninternaldebug:  Dumping \$h:\n"; Dumpvalue->new->dumpValue($h) }

    # Parse options
    my %opt = %globalOpt;
    $opt{level} = 1;
    if ($id) { print "internaldebug:  \$options = '$options'\n" }
    for my $o ( split //, $options ) {
        if ( $o =~ /([0-9])/ ) {
            $opt{level} = $1;
        } elsif ( $o =~ /[bcenqrstxz]/ ) {
            $opt{ $optionsTable->{$o} } = 1;
        } elsif ( $o =~ /[BCENQRSTXZ]/ ) {
            $opt{ $optionsTable->{ lc($o) } } = 0;
        } elsif ( $o eq '*' ) {
            %globalOpt = %opt;
        } else {
            print "WARNING:  Debug::Statements::d('variable', 'options) does not understand your option '$o'\n";
        }
    }
    if ($id) { print "\n\ninternaldebug:  Dumping \%opt:\n";       Dumpvalue->new->dumpValue( \%opt ) }
    if ($id) { print "\n\ninternaldebug:  Dumping \%globalOpt:\n"; Dumpvalue->new->dumpValue( \%globalOpt ) }

    return if not checkLevel( $h, $opt{level} );

    if ( !$globalPrintCounter ) {
        print "DEBUG:  Debug::Statements::d() is printing debug statements\n";
        my $windows = ($^O =~ /Win/) ? 1 : 0;
        my $originalCmdLine;
        if ($windows) {
            # Don't know how to do this on Windows
        } else {
            $originalCmdLine = qx/ps -o args $$/;
            $originalCmdLine =~ s/COMMAND\n//;
            chomp($originalCmdLine);
            print "DEBUG:  The debugged script was run as $originalCmdLine\n";
        }
    }

    $globalPrintCounter++;

    if ($id) { print "internaldebug:  \$caller = '$caller'\n" }

    if ( 0 == 1 ) { dumperTests($h) }

    if ( !defined $vars ) {
        print "WARNING:  Debug::Statements::d() was given a bare reference to an undefined variable instead of a single-quoted string\n";
        return;
    }

    # Remove parens at beginning/end of $vars
    if ($id) { print "\ninternaldebug:  \$vars = '$vars'\n" }
    my $ovars = $vars;
    $vars =~ s/^\(//;
    $vars =~ s/\)$//;
    if ($id) { print "internaldebug:  \$vars = '$vars'\n" }

    # Strip out prefix and suffix - d('\n$scalarvar @array\n\n')
    my ( $prefix, $suffix ) = ( "", "" );
    if ( $vars =~ s/^([^\$\@\%]+)(.*)/$2/ ) {
        $prefix = $1;
    }
    if ( $vars =~ s/(.*[\$\@\%][^\s\\]+)(.*)$/$1/ ) {    # avoid spaces and \n
        $suffix = $2;
    }
    if ($id) { print "internaldebug:  \$prefix = '$prefix'\n" }
    if ($id) { print "internaldebug:  \$vars = '$vars'\n" }
    if ($id) { print "internaldebug:  \$suffix = '$suffix'\n" }
    # Recover from problem while stripping prefix????   Try removing this
    while ( $prefix =~ s/([\$\@\%]\S+)\s*$// ) {
        $vars = "$1 $vars";
    }
    if ($id) { print "internaldebug:  \$prefix = '$prefix'\n" }
    if ($id) { print "internaldebug:  \$vars = '$vars'\n" }

    # Convert \n to newline
    #eval("\$prefix = \"$prefix\""); # too dangerous
    #eval("\$suffix = \"$suffix\"");
    $prefix = expandEscapes($prefix);
    $prefix =~ s/[ \t]+$//;
    $suffix = expandEscapes($suffix);
    if ($id) { print "internaldebug:  \$prefix = '$prefix'\n" }
    if ($id) { print "internaldebug:  \$suffix = '$suffix'\n" }

    # Print each $var
    my @vars = split /[, ]+/, $vars;
    if ($id) { print "internaldebug:  \@vars = '@vars'\n" }
    if ( @vars and not $opt{text} ) {
        if ($id) { print "internaldebug:  Iterating through vars\n" }
        for my $i ( 0 .. $#vars ) {
            # Print prefix only on 1st var, print suffix only on last var
            my $p = $i == 0 ? $prefix : "";
            if ($id) { print "internaldebug:  \$p = '$p'\n" }
            my $s = $i == $#vars ? $suffix : "";
            if ($id) { print "internaldebug:  \$s = '$s'\n" }
            #chomp($vars[$i]);
            if ($id) { print "internaldebug:  \$vars[$i] = '$vars[$i]'\n" }
            my $dump = dumpvar( $h, $caller, $vars[$i], \%opt );
            if ( $id and defined $dump ) { print "internaldebug:  \$dump = '$dump'\n" }
            printdebugsub( $caller, $opt{level}, $vars[$i], $dump, $p, $s, \%opt ) if defined $dump;
        }
    } else {
        if ($id) { print "internaldebug:  Just printing everything as text\n" }
        # No variables, just a print
        # SCALAR(0x6484b8)
        if ( $prefix =~ /^(SCALAR|ARRAY|HASH|REF|CODE|GLOB)\(0x/ ) {
            print "WARNING:  Debug::Statements::d() was given a reference to a variable instead of a single-quoted string\n";
            return;
        }
        #printdebugsub($caller, $opt{level}, "", "", $prefix, $suffix, \%opt);   #07/12/13
        printdebugsub( $caller, $opt{level}, "", "", "", $ovars, \%opt );
    }
    return;
}

# Find value of each variable (and checking for special vars)
sub dumpvar {
    my ( $h, $caller, $var, $opt ) = @_;
    if ($id) { print "sub dumpvar()\n" }

    # Convert ${var} to ${var}
    if ($id) { print "internaldebug dumpvar:  \$vvar = '$var'\n" }
    $var =~ s/^([\$\@\%]){(\S+)}$/$1$2/;
    if ($id) { print "internaldebug dumpvar:  \$vvar = '$var'\n" }

    # Convert $h->{'$listvar[0]'}      to  $h->{'@listvar'}[0]
    # Convert $h->{'$hashvar{one}'}    to  $h->{'%hashvar'}{one}
    # Convert $h->{'$listref->[1]'}    to  ${$h->{'$listref'}}->[1]
    # Convert $h->{'$hashref->{one}'}  to  ${$h->{'$hashref'}}->{'one'}

    my $sigil = ( split //, $var )[0];
    if ($id) { print "internaldebug dumpvar:  \$sigil = '$sigil'\n" }
    my $newsigil = $sigil;
    my $reference;

    # Ugly way to handle these:  $hash{$key} and $hash{$key}{$key2}
    # Will not work for more complicated cases like $hash{$hash2{$key}}
    while ( $var =~ /^(\$.*)(\$[a-zA-Z_]\w*)(.*)$/ ) {
        my ( $pre, $internalvar, $post ) = ( $1, $2, $3 );
        if ($id) { print "internaldebug dumpvar:  \$internalvar = $internalvar\n" }
        my $e = "\$h->{'$internalvar'}";
        if ($id) { print "internaldebug dumpvar:  \$e = $e\n" }
        my $reference = evlwrapper( $h, $e, 'dumpvar $hash{$key}' );
        if ($id) { print "internaldebug dumpvar:  \$reference = $reference\n" }
        #my $dump = cleanDump( $reference, undef );
        my $dump = Dumper($reference);
        $dump =~ s/^\\//;
        chomp $dump;
        if ($id) { print "internaldebug dumpvar:  \$dump = '$dump'\n" }
        $var = $pre . $dump . $post;
        if ($id) { print "internaldebug dumpvar:  \$var = '$var'\n" }
    }

    #               sig varbase       open    elem close
    if ( $var =~ /^(\$)([^\[\{\]\}]+)([\[\{])(\S+)([\]\}])$/ ) {
        # array or hash element starting with $
        my ( $sigil, $varbase, $opened, $element, $closed ) = ( $1, $2, $3, $4, $5 );
        if ($id) { print "internaldebug dumpvar:  (\$sigil, \$varbase, \$opened, \$element, \$closed) = ($sigil, $varbase, $opened, $element, $closed)\n" }

        if ($id) { print "internaldebug:  \$varbase = $varbase\n" }

        if ( $opened eq '[' and $closed eq ']' ) {
            if ($id) { print "internaldebug:  Found array\n" }
            #$reference = $h->{'@'.$varbase}[$element];
            #my $e = "\$h->{'\@'.\"$varbase\"}[$element]";
            #if ($id) { print "internaldebug:  \$e = $e\n" }
            #$reference = eval($e);
            if ( $element =~ /:/ ) {
                print "DEBUG sub $caller:  d() cannot be used on an array slice!  Found $var\n";
                return;
            } elsif ( $element =~ /[^-\d\[\]]/ ) {
                print "DEBUG sub $caller:  d() cannot be used on an array element with non-digits!  Found $var\n";
                return;
            } else {
                $newsigil = '@';
            }
        } elsif ( $opened eq '{' and $closed eq '}' ) {
            if ($id) { print "internaldebug dumpvar:  Found hash\n" }
            $element =~ s/"//g;
            #$reference = $h->{'%'.$varbase}{$element};
            #my $e = "\$h->{'\%'.\"$varbase\"}{$element}";
            #if ($id) { print "internaldebug:  \$e = $e\n" }
            #$reference = eval($e);
            $newsigil = '%';
        } else {
            print "DEBUG sub $caller:  WARNING:  Debug::Statements::d() did not understand opening/closing brackets $opened and $closed on $var\n";
            return;
        }
        if ($id) { print "internaldebug dumpvar:  \$newsigil = '$newsigil'\n" }
        my $e;

        if ( $varbase =~ s/->// ) {
            # ${$h->{'$listref'}}->[1]
            # ${$h->{'$hashref'}}->{'one'}
            $e = "\${\$h->{'\$$varbase'}}->$opened$element$closed";
            if ($id) { print "internaldebug dumpvar:  \$e = $e\n" }
        } else {
            #internaldebug:  $e = $h->{'@listvar'}[10]
            #internaldebug:  $e = $h->{'%hashvar'}{ten}
            #internaldebug:  $e = $h->{'@listvar'}[0]
            #internaldebug:  $e = $h->{'@nestedlist'}[1]
            #internaldebug:  $e = $h->{'@nestedlist'}[1][1]
            #internaldebug:  $e = $h->{'%hashvar'}{one}
            #internaldebug:  $e = $h->{'%hashvar'}{one}
            #internaldebug:  $e = $h->{'%nestedhash'}{flintstones}
            #internaldebug:  $e = $h->{'%nestedhash'}{flintstones}{pal
            $e = "\$h->{'$newsigil$varbase'}$opened$element$closed";
        }

        if ($id) { print "internaldebug dumpvar:  \$e = $e\n" }
        $reference = evlwrapper( $h, $e, 'dumpvar $e' );

    } else {
        # $_ @_ $1 $&
        if ( $var =~ /^(\$_|\@_|\$[1-9]\d*|\$\&)$/ ) {
            ( my $var2 = $var ) =~ s/^([\$\@\%])//;
            #my $sigil = $1;
            print "DEBUG sub $caller:  WARNING:  Debug::Statements::d() does not support Special variables such as $var\n";
            print "DEBUG sub $caller:            Use double-quotes as a workaround:  d(\"$var2 = $var\")\n";
            return;
        }
        # Special variables
        # Package variables
        elsif (( $var =~ /^(\$0|\$\$|\$\?|\$\.|\@ARGV|\$LIST_SEPARATOR|\$PROCESS_ID|\$PID|\$PROGRAM_NAME|\$REAL_GROUP_ID|\$GID|\$EFFECTIVE_GROUP_ID|\$EGID\|\$REAL_USER_ID|\$UID|\$EFFECTIVE_USER_ID|\$EID|\$SUBSCRIPT_SEPARATOR|\$SUBSEP|\%ENV|\@INC|\$INPLACE_EDIT|\$OSNAME|\%SIG|\$BASETIME|\$PERL_VERSION|\$EXECUTABLE_NAME|\$MATCH|\$PREMATCH|\$POSTMATCH|\$ARGV|\@ARGV|\$OUTPUT_FIELD_SEPARATOR|\$INPUT_LINE_NUMBER|\$NR|\$INPUT_RECORD_SEPARATOR|\$RS|\$OUTPUT_RECORD_SEPARATOR|\$ORS|\$OUTPUT_AUTOFLUSH)$/ )
            or ( $var =~ /^[\$\@\%]{?[a-zA-Z_][\w:{}\[\]]*$/ and $var =~ /::/ ) )
        {
            return handlelocalvar( $var, $opt );
        }
        # $list[1..3]
        elsif ( $var =~ /^(\@)([^\[\{\]\}]+)([\[\{])(\S*:\S*)([\]\}])$/ ) {
            print "DEBUG sub $caller:  d() cannot be used on an array slice!  Found $var\n";
            return;
        }
        # $scalar @list %hash
        elsif ( $var =~ /^[\$\@\%]{?[a-zA-Z_][\w{}\[\]]*$/ ) {
            # normal variable
            $reference = $h->{$var};
        }
        # $#list
        elsif ( $var =~ /^\$#/ ) {
            ( my $var2 = $var ) =~ s/^[\$\@\%]//;
            print "DEBUG sub $caller:  WARNING:  Debug::Statements::d() does not support \$# used in $var\n";
            print "DEBUG sub $caller:            Use double-quotes as a workaround:  d(\"$var2 = $var\")\n";
            return;
        }
        # anything else
        elsif ( $var =~ /^[\$\@\%]/ ) {
            ( my $var2 = $var ) =~ s/^([\$\@\%])//;
            #print "DEBUG sub $caller:  WARNING:  Debug::Statements::d() does not support special variables such as $var\n";
            #print "DEBUG sub $caller:            Use double-quotes as a workaround:  d(\"$var2 = $var\")\n";
            return handlelocalvar( $var, $opt );
        } else {
            if ($id) { print "internaldebug dumpvar:  \$var is bad!\n" }
            return;
        }
    }

    # Sanity check
    if ( !defined $reference ) {
        print "DEBUG sub $caller:  $var is not a defined local variable!\n";
        print "DEBUG sub $caller:      Check if you misspelled your variable name when you called d() or used the wrong sigil (\$/\@/\%)\n";
        #print "DEBUG sub $caller:      ! defined \$h->{$var}\n";
        return;
    }
    if ($id) { print "internaldebug dumpvar:  \$reference = '$reference'\n" }

    # Get value
    my $ref = ref($reference);
    if ($id) { print "internaldebug dumpvar:  \$ref = '$ref'\n" }
    my $dump = cleanDump( $reference, $opt );
    if ( $opt->{compress} ) {
        if ( $ref !~ /^SCALAR/ or $newsigil ne '$' ) {
            $dump =~ s/\s+/ /g;
        }
    }
    if ($id) { print "internaldebug dumpvar:  \$dump = '$dump'\n" }
    return $dump;
}

# Local variables and package variables are both considered local, and are in the scope of d()
sub handlelocalvar {
    my ( $var, $opt ) = @_;
    if ($id) { print "internaldebug handlelocalvar:  \$var = '$var'\n" }
    if ( $var =~ /^([\$\@\%])/ ) {
        my $sigil = $1;
        ( my $var2 = $var ) =~ s/^([\$\@\%])//;
        #print "\$var = $var\n";
        no strict 'refs';  ## no critic
        if ( $sigil eq '$' ) {
            #print "Dumper cleanvar>" . Dumper( %$var2 ) . "<\n";
            return cleanDump( \$$var2, $opt );
        } elsif ( $sigil eq '@' ) {
            #print "Dumper cleanvar>" . Dumper( %$var2 ) . "<\n";
            return cleanDump( \@$var2, $opt );
        } elsif ( $sigil eq '%' ) {
            #print "Dumper cleanvar>" . Dumper( %$var2 ) . "<\n";
            return cleanDump( \%$var2, $opt );
        } else {
            croak "Program bug:  \$sigil = $sigil" if $id;
        }
    } else {
        croak "Program bug:  \$var = $var" if $id;
    }
    return;
}

sub cleanDump {
    my ( $reference, $opt ) = @_;
    my $ref = ref($reference);
    if ($id) { print "internaldebug cleanDump \$ref = $ref\n" }
    $Data::Dumper::Sortkeys = 1;
    # $Data::Dumper::Terse = 0; # causes a hang

    if ( $opt->{compress} ) {
        $Data::Dumper::Indent = 1;    # 0=minimal 1=spaces 2=newlines(default) 3=addlSpaces
    } else {
        $Data::Dumper::Indent = 2;    # 0=minimal 1=spaces 2=newlines(default) 3=addlSpaces
    }

    my $dump;
    if ( $opt->{Sort} and $ref eq "ARRAY" ) {
        $dump = Dumper( [ sort { $a cmp $b } @$reference ] );    # to sort array
    } else {
        $dump = Dumper($reference);
    }
    if ($id) { print "internaldebug cleanDump:  \$dump = '$dump'\n" }
    $dump =~ s/^\\//;
    chomp $dump;

    if ( $opt->{Elements} ) {
        my $numElements;
        if ( $ref eq "ARRAY" ) {
            $numElements = scalar @$reference;
            $dump        = "($numElements) " . $dump;
        } elsif ( $ref eq "HASH" ) {
            $numElements = scalar keys %$reference;
            $dump        = "($numElements) " . $dump;
        } elsif ( $ref eq "SCALAR" ) {
            # do nothing
        } else {
            # do nothing
        }
    }

    if ( $opt->{tRuncate} ) {
        my $severalLines = '[^\n]*\n' x $truncateLines;
        if ( $dump =~ s/\A($severalLines).*$/$1/s ) {    # s allows . to match \n
            $dump .= "          ...\n";                  #        ]\n";
        }
    }

    return $dump;
}

sub printdebugsub {
    my ( $caller, $level, $var, $dump, $prefix, $suffix, $opt ) = @_;
    if ($id) { print "sub printdebugsub()\n" }

    # Variations:
    #     "DEBUG:  "            $printdebug GLOBAL  -> splits off $colon
    #     debug levels 1 2 3    $printlevel
    #     sub name
    #
    # Examples of desired output:
    #

    # Insert level if >=2
    my $printlevel = "";
    $printlevel = $level if $level >= 2;
    if ($id) { print "internaldebug printdebugsub:  \$printlevel = '$printlevel'\n" }

    # Handle option $Debug::Statements::printdebug
    my $printdebugsub = $printdebug;    # default is 'DEBUG:  '
    my $colon         = ":";
    if ($printdebug) {
        $printdebugsub =~ s/\s*$//;
        if ( $printdebugsub =~ s/([:-=>])$// ) {
            $colon = $1;
        }
        $printdebugsub .= $printlevel;
        if ($id) { print "internaldebug printdebugsub:  \$printdebugsub = '$printdebugsub'\n" }
    }
    if ($id) { print "internaldebug printdebugsub:  \$colon = '$colon'\n" }

    # Handle option 's' = printSub
    if ( $opt->{'printSub'} ) {
        my $printcaller = $caller;
        if ( $printcaller ne "" ) {
            $printcaller =~ s/^main:://;
            $printcaller =~ s/^Debug::Statements:://;
            $printcaller = "sub $printcaller";
        }
        if ($id) { print "internaldebug printdebugsub:  \$printcaller = '$printcaller'\n" }
        $printdebugsub .= " " if $printdebug and $printcaller ne "";
        $printdebugsub .= $printcaller;
        if ($id) { print "internaldebug printdebugsub:  \$printdebugsub = '$printdebugsub'\n" }
    }

    # Handle option 'c' = Chomp
    $dump =~ s/\n'$/'/ if $opt->{'Chomp'};

    # Handle option 't' = 'Timestamp'
    my $timestamp = "";
    $timestamp = " at " . localtime() . " " . gettimeofday() if $opt->{'Timestamp'};

    # Handle option 'n' = 'LineNumber'
    my $linenumber = "";
    if ( $opt->{'LineNumber'} ) {
        my $n = $. || 'undef';
        $linenumber = "At line $n:  ";
    }

    # Append colon
    $printdebugsub .= "$colon  " if $printdebug or $opt->{'printSub'};
    if ($id) { print "internaldebug printdebugsub:  \$printdebugsub = '$printdebugsub'\n" }

    if ($var) {
        print "$prefix$printdebugsub$linenumber$var = $dump$timestamp$suffix\n";
    } else {
        # no vars found, just print prefix and suffix
        print "$printdebugsub$prefix$timestamp$suffix\n";
    }

    croak if $opt->{die};

    return;
}

# ls($filename) 
# ls($filename, $level)
# ls("$filename1 filename2", $level)
sub ls {
    my ( $filenames, $level ) = @_;
    return if $disable;
    $level = 1 if !$level;
    if ($id) { print "internaldebug ls:  \$level = '$level'\n" }
    my $h = PadWalker::peek_my(1);
    return if not checkLevel( $h, $level );
    my $windows = ($^O =~ /Win/) ? 1 : 0;
    my $command;
    for my $file ( split /\s+/, $filenames ) {
        if ( $windows ) {
            $command = "dir $file";
        } else {
            $command = "ls -l $file";
        }
        if ($id) { print "internaldebug ls:  \$command = '$command'\n" }
        my $lsl;
        if ( -d $file or -f $file ) {
            $lsl = `$command`;
            chomp $lsl;
        } elsif ( -f $file ) {
            $lsl = `$command`;
            chomp $lsl;
        } else {
            if ( $file =~ /^\$/ ) {
                print "DEBUG:  WARNING:  Debug::Statements::ls() did not understand file name $file.  You probably need to remove the 'single quotes' around your variable\n";
                return;
            }
            $lsl = "$file does not exist!";
        }
        if ($id) { print "internaldebug ls:  \$lsl = '$lsl'\n" }
        my $caller = ( caller(1) )[3] || "";
        printdebugsub( $caller, $level, "ls -l", $lsl, "", "" );
    }
    return;
}

sub dumperTests {
    my $h = shift;
    # Used during development of this module
    print "internaldebug:  ----\n";
    print Dumper($h);                                         # good
    print Dumper( $h->{'@listvar'} );                         # good
    print Dumper( $h->{'$listvar[0]'} );                      # bad
    print Dumper( $h->{'@listvar'}[0] );                      # good
    print Dumper( $h->{'@listvar'}[3] );                      # good
                                                              #print Dumper($h->{'$listvar'}[1:3]);  # hash slice syntax error
                                                              #print Dumper($h->{'@listvar'}[1:3]);  # hash slice syntax error
    print Dumper( $h->{'%hashvar'} );                         # bad
    print Dumper( $h->{'$hashvar{one}'} );                    # bad
    print Dumper( $h->{'%hashvar'}{one} );                    # bad
    print Dumper( $h->{'@nestedlist'} );
    print Dumper( $h->{'$nestedlist[1][1]'} );                # bad
    print Dumper( $h->{'@nestedlist'}[1][1] );                # good
    print Dumper( $h->{'%nestedhash'} );                      # good
    print Dumper( $h->{'%nestedhash'}{flintstones}{pal} );    # good
    print Dumper( $h->{'%nestedhash'}{flintstones} );         # good
    print "internaldebug:  ----\n";
    return;
}

# Convert '\n' to "\n", convert '\t' to "\t"
sub expandEscapes {
    local $_ = shift;
    if ($id) { print "internaldebug:  sub expandEscapes()\n" }
    s{(\\n|\\t)}{qq["$1"]}geexs;
    return $_;
}

sub evlwrapper {
    my ( $h, $expression, $description ) = @_;
    if ($id) { print "internaldebug:  evaling ($evalcounter) $description\n" }
    $evalcounter++;
    return eval($expression);  ## no critic
}

1;

__END__

=head1 NAME

Debug::Statements - provides an easy way to insert and enable/disable debug statements.

=head1 SYNOPSIS

The C<d()> function prints the name of the variable AND its value.

This implementation been optimized to minimize your keystrokes.

=head2 Example code

    my $myvar = 'some value';
    my @list = ('zero', 1, 'two', "3");
    my %hash = ('one' => 2, 'three' => 4);
    
    use Debug::Statements;
    my $d = 1;
    d "Hello world";
    d '$myvar';
    d '@list %hash';

=head2 Output

    DEBUG sub mysub:  Hello world
    DEBUG sub mysub:  $myvar = 'some value'
    DEBUG sub mysub:  @list = [
      'zero',
      1,
      'two',
      '3'
    ]
    DEBUG sub mysub:  %hash = {
      'one' => 2,
      'three' => 4
    }


=head1 BACKGROUND

=head2 Advantages of debug statements
    
"The most effective debugging tool is still careful thought, coupled with judiciously placed print statements"
- Brian Kernighan, Unix for Beginners (1979)

=over

=item *
Familiarity - everyone has used them.

=item *
When strategically placed, they show the values of key variables as well as the flow of control.																													          

=item *
May be left in the code to facilitate debugging, when the code next needs to be enhanced.

=item *
May be turned on to help remotely debug problems.

=item *
Printing the names of executing subroutines can be particularly useful
when debugging large unfamiliar programs produced by multiple developers over the span of years.	

=item *
Can be used in conjuction with a debugger, which can be used to
change variables on-the-fly, step into libraries, or skip/repeat sections of code

=item *
If the results are saved to a file, file comparisons can be useful
during regression testing.

=back

=head2 Traditional debug statement example
    
    my $d = 1;
    my $myvar = 'some value';
    if ($d) { print "DEBUG sub xyz:  \$myvar is $myvar\n" }
    use Dumpvalue;
    if ($d) { print "\nDEBUG: Dumping \@list:\n"; Dumpvalue->new->dumpValue(\@list) }
    if ($d) { print "\nDEBUG: Dumping \%hash:\n"; Dumpvalue->new->dumpValue(\%hash) }

=head2 Disadvantages of traditional "print" debug statements

=over

=item *
Tedious, require many keystrokes to type

=item *
Reduces readability of the source code.

=item *
Print statements clutter the standard output

=item *
Need to be removed or commented out later

=item *
If some statements are mistakenly left in, the output can cause problems or confusion

=item *
The next time the code needs to be enhanced,
any removed print statements need to be re-inserted or uncommented

=back

=head1 Debug::Statements Example

C<Debug::Statements::d()> provides an easy way to insert and enable/disable debug statements.

    my $myvar = 'some value';
    use Debug::Statements;
    my $d = 1;
    d '$myvar';

=head2 Output
    
    DEBUG sub mysub:  $myvar = 'some value'

This is all you need to know to get started.

=head1 FEATURES

=head2 Arrays, hashes and refs

    d '@list';
    d '$list[2]';
    d '$list[$i]';
    d '%hash';
    d '$nestedhash{key}';
    d '$nestedhash{$key1}{$key2}';
    d '$listref';
    d '$arrayref';
    d '$arrayref->[2]';
    d '$hashref->{key}';
    d '$hashref->{$key}';

=head2 Plain text can be entered as a comment
    
    d 'Processing...';
    d "This comment prints the value of a variable: $myvar";

=head2 Multiple debug levels
    
    use Debug::Statements qw(d d2 d0 D);
    
    my $d = 1;
    d '$myvar';    # prints
    d2 '$myvar';   # does not print since $d < 2
    
    $d = 2;
    d '$myvar';    # prints
    d2 '$myvar';   # prints

    D '$myvar';    # always prints, even if $d is 0 or undef
                   # this is useful for short term debugging
                   # of existing code

    d0 '$myvar';   # same as D

=head2 Supports newlines or other characters before/after the variable
    
    d '\n $myvar';
    d '\n$myvar\n\n';
    d '\n-------\n@list\n--------\n';

=head2 Multiple variables can be printed easily
    
    d '$myvar $myvar2 $myvar3';
    or
    d '$myvar,$myvar2,$myvar3';
    or
    d '$myvar, $myvar2, $myvar3';
    or
    d '($myvar, $myvar2, $myvar3)';
    
Each of these examples prints one line each for $myvar, $myvar2, and $myvar3

=head2 Alternate syntax with parentheses
    
    d('$myvar');
    
=head1 OPTIONS

Options may be specifed with an 2nd argment to C<d()>

=over

B<b>
print suBroutine name (on by default)

B<c>
Chomp newline before printing, useful when printing captured $line from a parsed input file

B<e>
print # of Elements contained in top level of the array or hash

B<n>
print line Number $. of the input file

B<q>
treat the string as text, do not try to evaluate it.
This is useful if you are parsing another Perl script, and the text contains sigil characters C<$@%>

B<r>
tRuncate output (defaults to 10 lines)

B<s>
Sort contents of arrays (hashes are always sorted)

B<t>
print Timestamp using C<localtime()> and C<Time::HiRes::gettimeofday()>

B<x>
die when code reaches this line

B<z>
compress array and hash dumps to save screen space

=back

=head2 Examples

To print $line chomped and with line number and timestamp

   d('$line', 'cnt');
      
To print %hash in a compressed format
  
   d('%hash', 'z');

=head2 Negating options

To negate an option, capitialize it (use 'B' instead of 'b')

=head2 Persistent options
    
Options are only valid for the current debug statement

To make the current options global (peristent), append a star *

For example, to set timestamp globally
	
   d('$var', 't*');
	
For example, to unset timestamp globally
    
   '$var', 'T*');

=head1 REQUIREMENTS

B<L<PadWalker> must be installed>

In addition, the test suites require Test::Fatal, Test::More, and Test::Output
  
=head2 $d variable   

B<Your code must have a variable '$d' defined to enable the debug statements>

Exception:  C<D()> does not require the $d variable to exist.
It always prints.  See "Multiple debug levels" above.

$d was chosen because it is easy to type and intuitive

If your code already uses '$d' for another purpose,
this can be changed with C<Debug::Statements::setFlag()>

Your code must not already contain a local subroutine called 'd()',
since this function is imported

Consider enabling $d through the command line of your script
    
    use Getopt::Long;
    my %opt;
    my $d = 0;
    GetOptions( \%opt, 'd' => sub{$d=1}, 'dd' => sub{$d=2}, ... );

This provides an easy way for others to set your code into debug mode.
They can then capture stdout and email it to you.

=head2 Quoting

Calls to d() should use 'single quotes' instead of "double quotes"

Exception:  To produce custom output, call d() with double-quotes.
As is always the case with double-quotes in Perl,
variables will be interpolated into values before entering the d() subroutine.

=head3 Example #1

    d "Found pattern: $mynum in file $filename";
    
=head3 Output #1
    
    DEBUG sub mysub:  Found pattern asdf in file foo.txt

=head3 Example #2

    d "Found $key and replaced with $subtable_ref->{$key} on:  $line"
    
=head3 Output #2
    
    DEBUG sub mysub:  Found foo and replaced with bar on:  foobar

Remember that when using escaped \$ \@ \% within "double quotes",
this is equivalent to using $ @ % within 'single quotes'

This means that d() will try to print the names and values of those variables.
	
=head2 Functions

The module includes functions which affect global operation
    
   Debug::Statements::enable();             # enable operation (default)
   Debug::Statements::disable();            # disable operation, even if $d >= 1
   Debug::Statements::setFlag('$yourvar');  # default is '$d'
   Debug::Statements::setPrintDebug("");    # default is "DEBUG:  "
   Debug::Statements::setTruncate(10);      # default is 10 lines

=head1 LIMITATIONS

Not supported

=over

=item *
Array slices such as C<$listvar[1:3]>

=item *
Some special variables such as C<$1 $_ @_>
...but any of these can be printed by using "double quotes",
since this will cause Perl to evaluate the expression before calling d().  For example  d "@_"
        
=item *
The evaluation is of variables does not support the full range of Perl syntax.
Most cases work, for example:  C<d '$hash{$key}'>
However hashes used as hash keys will not work, for example:  C<d '$hash{$hash2{$key}}'>
As a workaround, use "double quotes":  C<d "\$hash{$hash2{$key}}"> instead.
The rule is similar for arrays

=back

=head1 Additional features

=head2 ls()

ls() is also provided for convenience, but not exported by default

    use Debug::Statements qw(d d0 d1 d2 d3 D ls);
    ls($myfilename);
    
When $d >= 1, prints an ls -l listing of $myfilename.

Note that ' ' is not used inside ls()

=head1 Perl versions

This module has been tested on

=over

=item *
Linux 5.8.6, 5.8.8, 5.12, 5.14, and 5.20

It will probably work as far back as 5.8.0

=item *
Windows 5.20

=back

=head1 GORY DETAILS
      
=head2 How it works

C<PadWalker::peek_my()> gets the value of $d and the contents of your variables
(from outside its scope!)  The variable values are stored in an internal hash reference

It does NOT change the values of your variables.

C<caller()[3]> gets the name of subroutine which encloses your code

C<Data::Dumper> pretty-prints the contents of your variable

=head2 Performance

For performance-critical applications,
frequent calls to C<PadWalker::peek_my()> and C<caller()> may be too intensive

=head3 Solutions

=over

=item *
Globally disable all functionality by calling C<Debug::Statements::disable();>
The PadWalker and caller functions will not be called.  Debug statements will not be printed.

=item *
OR comment out some of your calls to C<d()> within performance-critical loops

=item *
OR completely disable this code is to define you own empty d() subroutines.

    #use Debug::Statements qw(d d2);
    d{}; d2{};

=back

=head1 AUTHOR

Chris Koknat 2014 chris.koknat@gmail.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013-14 by Chris Koknat.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

