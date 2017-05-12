#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/Havok/RCS/SQLScalar.pm,v 1.24 2007/11/18 08:16:56 claude Exp claude $
#
# copyright (c) 2005, 2006, 2007 Jeffrey I Cohen, all rights reserved, worldwide
#
#
package Genezzo::Havok::SQLScalar;
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(&sql_func_chomp 
             &sql_func_chop
             &sql_func_chr
             &sql_func_crypt
             &sql_func_index
             &sql_func_lc
             &sql_func_lcfirst
             &sql_func_length
             &sql_func_ord
             &sql_func_pack
             &sql_func_reverse
             &sql_func_rindex
             &sql_func_sprintf
             &sql_func_substr
             &sql_func_uc
             &sql_func_ucfirst
             &sql_func_abs
             &sql_func_atan2
             &sql_func_cos
             &sql_func_exp
             &sql_func_hex
             &sql_func_int
             &sql_func_log10
             &sql_func_oct
             &sql_func_rand
             &sql_func_sin
             &sql_func_sqrt
             &sql_func_srand
             &sql_func_perl_join
             
             &sql_func_concat
             &sql_func_greatest
             &sql_func_initcap
             &sql_func_least
             &sql_func_lower
             &sql_func_lpad
             &sql_func_ltrim
             &sql_func_replace
             &sql_func_rpad
             &sql_func_rtrim
             &sql_func_soundex
             &sql_func_translate
             &sql_func_upper

             &sql_func_cosh
             &sql_func_ceil
             &sql_func_floor
             &sql_func_ln
             &sql_func_logn
             &sql_func_mod
             &sql_func_power
             &sql_func_round
             &sql_func_sign
             &sql_func_sinh
             &sql_func_tan
             &sql_func_tanh
             &sql_func_trunc

             &sql_func_ascii
             &sql_func_instr        
             &sql_func_nvl         

             &sql_func_quurl
             &sql_func_quurl2
             &sql_func_unquurl

             );

use Genezzo::Util;
use Genezzo::Havok::Utils;

use strict;
use warnings;

use Carp;

our $VERSION;
our $MAKEDEPS;

BEGIN {
    $VERSION = do { my @r = (q$Revision: 1.24 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

    my $pak1  = __PACKAGE__;
    $MAKEDEPS = {
        'NAME'     => $pak1,
        'ABSTRACT' => ' ',
        'AUTHOR'   => 'Jeffrey I Cohen (jcohen@cpan.org)',
        'LICENSE'  => 'gpl',
        'VERSION'  =>  $VERSION,
        }; # end makedeps

    $MAKEDEPS->{'PREREQ_HAVOK'} = {
        'Genezzo::Havok::UserFunctions' => '0.0',
    };

    # DML is an array, not a hash

    my $now = 
    do { my @r = (q$Date: 2007/11/18 08:16:56 $ =~ m|Date:(\s+)(\d+)/(\d+)/(\d+)(\s+)(\d+):(\d+):(\d+)|); sprintf ("%04d-%02d-%02dT%02d:%02d:%02d", $r[1],$r[2],$r[3],$r[5],$r[6],$r[7]); };


    my %tabdefs = ();
    $MAKEDEPS->{'TABLEDEFS'} = \%tabdefs;

    my @perl_funcs = qw(
                        chomp
                        chop
                        chr
                        crypt
                        index
                        lc
                        lcfirst
                        length
                        ord
                        pack
                        reverse
                        rindex
                        sprintf
                        substr
                        uc
                        ucfirst
                        abs
                        atan2
                        cos
                        exp
                        hex
                        int
                        log10
                        oct
                        rand
                        sin
                        sqrt
                        srand

                        perl_join
                        );

    my @sql_funcs = qw(
                       concat
                       greatest
                       initcap
                       least
                       lower
                       lpad
                       ltrim
                       replace
                       rpad
                       rtrim
                       soundex
                       translate
                       upper

                       cosh
                       ceil
                       floor
                       ln
                       logn
                       mod
                       power
                       round
                       sign
                       sinh
                       tan
                       tanh
                       trunc
                       
                       ascii
                       instr
                       nvl
                       );

    my @gnz_funcs = qw(
                       quurl
                       quurl2
                       unquurl
                       );


    # NOTE: should really use "select add_user_function", not
    # _build_sql_for_user_function, but the parsing and dynamic load
    # dramatically slows the db init.

    my @ins1;
    my $ccnt = 6; # skip util functions and syshelp
    for my $pfunc (@perl_funcs)
    {
        my %attr = (module => $pak1, 
                    function => "sql_func_" . $pfunc,
                    creationdate => $now,
                    xid => $ccnt);

        my $bigstr = 
            Genezzo::Havok::Utils::_build_sql_for_user_function(%attr);

        push @ins1, $bigstr;
        $ccnt++;
    }
    for my $pfunc (@sql_funcs)
    {
        my %attr = (module => $pak1, 
                    function => "sql_func_" . $pfunc,
                    creationdate => $now,
                    xid => $ccnt);

        if ($pfunc =~ m/^(greatest|least)$/i)
        {
            $attr{argstyle} = "HASH";
        }
        else
        {
            delete $attr{argstyle} if (exists($attr{argstyle}));
        }

        my $bigstr = 
            Genezzo::Havok::Utils::_build_sql_for_user_function(%attr);

        push @ins1, $bigstr;
        $ccnt++;
    }
    for my $pfunc (@gnz_funcs)
    {
        my %attr = (module => $pak1, 
                    function => "sql_func_" . $pfunc,
                    creationdate => $now,
                    xid => $ccnt);

        my $bigstr = 
            Genezzo::Havok::Utils::_build_sql_for_user_function(%attr);

        push @ins1, $bigstr;
        $ccnt++;
    }

    # add help for all functions
    push @ins1, "select add_help(\'$pak1\') from dual";

    # register havok module

    push @ins1, "select register_havok_package(" .
        "\'modname=" . $pak1 .  "\', ".
        "\'creationdate=" . $now .  "\', ".
        "\'version=" . $VERSION .  "\'".
        ") from dual";

    # if check returns 0 rows then proceed with install
    $MAKEDEPS->{'DML'} = [
                          { check => [
                                      "select * from user_functions where xname = \'$pak1\'"
                                      ],
                            install => \@ins1
                            }
                          ];


#    print Data::Dumper->Dump([$MAKEDEPS]);
}

sub MakeYML
{
    use Genezzo::Havok;

    my $makedp = $MAKEDEPS;

    return Genezzo::Havok::MakeYML($makedp);
}

sub getpod
{
    my $bigHelp;
    ($bigHelp = <<EOF_HELP) =~ s/^\#//gm;
#=head1 SQL_Functions
#
#=head2  chomp : chomp(char_str)
#
#Return the string with the trailing newline removed.
#
#=head2  chop : chop(char_str)
#
#Return the string with the last character removed.
#
#=head2  chr : chr(number)
#
#Returns the character represented by the number in the character set.
#
#=head2  crypt : crypt(plaintext, salt)
#
#Returns the plaintext string encrypted with the C crypt routine.
#
#=head2  index : index(char_str, substr[, start_position])
#
#Returns the position (0-based) of the first character of the substring
#in the string, or -1 if not found, starting at start_position.
#Start_position defaults to zero if not specified.
#
#=head2  lc : lc(char_str)
#
#Returns the lowercased char_str.
#
#=head2  lcfirst : lcfirst(char_str)
#
#Returns char_str with only the first character lowercased.
#
#=head2  length : length(char_str)
#
#Returns the number of characters in char_str.
#
#=head2  ord : ord(char_str)
#
#Returns the numeric encoding of the first character of char_str.
#
#=head2  pack : pack(template_str, list_of_values)
#
#Converts a list of values into a string using the perl pack function.
#
#=head2  reverse : reverse(char_str)
#
#Returns the string in reverse order.
#
#=head2  rindex : rindex(char_str, substr[, start_position])
#
#Like index, but backwards: finds the last occurrence of the substr in
#char_str.
#
#=head2  sprintf : sprintf(format_str, list_of_values)
#
#Returns a string formatted using the C sprintf.
#
#Note that the sprintf format string must be single-quoted (SQL-style),
#not double-quoted.
#
#=head2  substr : substr(char_str, offset_position[, length])
#
#Returns the substring of char_str, starting at the offset, of the
#specified length.  If length is omitted the it returns from the offset
#to the end of the string.  Special rules for negative offset, length.
#
#=head2  uc : uc(char_str)
#
#Returns the uppercased char_str.
#
#=head2  ucfirst : ucfirst(char_str)
#
#Returns char_str with only the first character uppercased.
#
#=head2  abs : abs(number)
#
#Absolute value
#
#=head2  atan2 : atan2(numberY, numberX)
#
#Arctangent (in radians)
#
#=head2  cos : cos(number)
#
#Cosine (in radians).
#
#=head2  exp : exp(n)
#
#Returns e**n
#
#=head2  hex : hex(char_str)
#
#Treats char_str as a hexadecimal value and converts to number.
#
#=head2  int : int(number)
#
#Returns the integer portion of number.
#
#=head2  oct : oct(char_str)
#
#Treats char_str as a octal value and converts to number.
#
#=head2  rand : rand(number)
#
#Returns returns a random number N, where 0 <= N < number.  Note that N
#is not an integer, so use an expression like int(rand(Max_N)) to
#obtain integer values where 0 <= N <= (Max_N - 1).
#
#=head2  sin : sin(number)
#
#Sine (in radians)
#
#=head2  sqrt : sqrt(number)
#
#Square root.
#
#=head2  srand : srand(number)
#
#Set the random seed.
#
#=head2  perl_join : perl_join(join_exp, char_str1, char_str2...)
#
#The perl string join, renamed to avoid conflict with the SQL
#relational join.  Concatenates the strings with the join_expr. 
#Example:  perl_join(':', 'foo', 'bar', 'baz') returns 'foo:bar:baz'.
#
#=head2  concat : concat(char_str1, char_str2...)
#
#Concatenate strings
#
#=head2  greatest : greatest(item1, item2...)
#
#Find the greatest element in a list
#
#=head2  initcap : initcap(char_str)
#
#Return the string with the initial letter of each word capitalized,
#where words are defined as contiguous groups of alphanumeric chars
#separated by non-word chars.
#
#=head2  least : least(item1, item2...)
#
#Find the smallest element in a list
#
#=head2  lower : lower(char_str)
#
#Return the string with all letters lowercase
#
#=head2  lpad : lpad(char_str1, n [, char_str2])
#
#Returns the string char_str1 padded out on the left to length n with
#copies of char_str2.  If char_str2 is not specified blanks are used.
#If char_str1 is larger than length n it is truncated to fit.
#
#=head2  ltrim : ltrim(char_str [, set])
#
#Returns the string which is trimmed on the left up to the first
#character which is not in the specified set.  If set is unspecified,
#blanks are trimmed.
#
#=head2  soundex : soundex(char_str)
#
#Knuth's soundex from L<Text::Soundex>.
#
#=head2  replace : replace(char_str, search_str [, replace_str])
#
#Returns char_str with all occurrences of the search_str replaced by
#replace_str.  If the replace_str is unspecified or null, it removes
#all occurrences of the search_str.
#
#=head2  rpad : rpad(char_str1, n [, char_str2])
#
#Returns the string char_str1 padded out on the right to length n with
#copies of char_str2.  If char_str2 is not specified blanks are used.
#If char_str1 is larger than length n it is truncated to fit.
#
#=head2  rtrim : rtrim(char_str [, set])
#
#Returns the string which is trimmed on the right up to the first
#character which is not in the specified set.  If set is unspecified,
#blanks are trimmed.
#
#=head2  translate : translate(char_str, search_str, replace_str)
#
#Similar to perl transliteration tr/ (see L<perlop(1)> ), returns a
#string where all occurrences of a character in the search string are
#replaced with the corresponding character in the replace string.
#
#=head2  upper : upper(char_str)
#
#Returns the string with all characters uppercase.
#
#=head2  cosh : cosh(n)
#
#Hyperbolic cosine
#
#=head2  ceil : ceil(n)
#
#Returns the smallest integer greater than or equal to n
#
#=head2  floor : floor(n)
#
#Returns the largest integers less than or equal to n
#
#=head2  ln : ln(n)
# 
#Natural log.
#
#=head2  log10 : log10(n)
#
#Log base 10.
#
#=head2  logN : logN(base_N, num)
#
#Returns the Log base base_N on num.
#
#=head2  mod : mod(m,n)
#
#Returns the remainder of m divided by n.
#
#=head2  power : power(m,n)
#
#Returns m**n
#
#=head2  round : round(num [, m])
#
#Return num rounded to m places to the right of the decimal point.  M=0
#if not specified.  If m is negative num is rounded to the left of the
#decimal point.
#
#
#=head2  sign : sign(n)
#
#Similar to "spaceship", returns -1 for N < 0, 0 for N==0, and 1 for N > 0.
#
#=head2  sinh : sinh(n)
#
#Hyperbolic sine.
#
#=head2  tan : tan(n)
#
#tangent
#
#=head2  tanh : tanh(n)
#
#Hyperbolic tangent.
#
#=head2  trunc : trunc(num [, m])
#
#Return num truncated to m places to the right of the decimal point.
#M=0 if not specified.  If m is negative num is truncated to the left
#of the decimal point.
#
#=head2  ascii : ascii(char_str)
#
#Return the ascii value of the first char of the string.
#
#=head2  instr : instr(char_str, substring [, position [, occurrence]])
#
#Returns the index (1 based, not zero based) of the substring in the
#char_str, starting at position.  If occurrence and position are not
#specified they default to one: instr returns the index of the first
#occurrence of the substring.  If occurrence is specified instr returns
#the index of the Nth occurrence.  If position is negative instr begins
#the search from the tail end of char_str.
#
#=head2  nvl : nvl(char_str1, char_str2)
#
#Returns char_str2 if char_str1 is NULL, else returns char_str1
#
#=head2  quurl : quurl(char_str)
#
#"Quote URL" - Replace all non-alphanumeric chars in a string with
#'%hex' values, similar to the standard URL-style quoting.
#
#=head2  quurl2 : quurl2(char_str)
#
#"Quote URL" - Replace most non-alphanumeric chars in a string with
#'%hex' values, leaving spaces and most punctuation (with the exception
#of '%') untouched.
#
#=head2  unquurl : unquurl(char_str)
#
#Convert a "quoted url" string back.
#
#=head2 now : now()
#
#Return the current date in ISO 8601 format.
#
#=head2 sysdate : sysdate()
#
#Return the current date in ISO 8601 format.
#
EOF_HELP

    my $msg = $bigHelp;

    return $msg;

} # end getpod

# perl scalar functions
# CHAR
sub sql_func_chomp
{
    # can't have full chomp semantics in sql...
    my $foo = shift;
    chomp($foo);
    return $foo;
}
sub sql_func_chop
{
    # can't have full chop semantics in sql...
    my $foo = shift;
    chop($foo);
    return $foo;
}
sub sql_func_chr
{
    my $num = shift;
    return chr($num);
}
sub sql_func_crypt
{
    my ($plain, $salt) = @_;

    # XXX XXX
    return undef
        unless (defined($salt));

    return crypt $plain, $salt;
}
sub sql_func_index
{
    my $str = shift;
    my $substr = shift;
    my $pos = shift;
    $pos = 0 unless (defined($pos));
    return index $str, $substr, $pos;
}
sub sql_func_lc
{
    my $str = shift;
    return lc($str);
}
sub sql_func_lcfirst
{
    my $str = shift;
    return lcfirst($str);
}
sub sql_func_length
{
    my $str = shift;
    return length($str);
}
sub sql_func_ord
{
    my $str = shift;
    return ord($str);
}
sub sql_func_pack
{
    # Note: pack  prototype expects a scalar for first arg, so
    # supplying an array causes it to get evaluated in the scalar
    # context, which is wrong.  Shift off the format first.
    my $fformat = shift @_;
    my $foo = pack($fformat, @_);
    return $foo;
}

sub sql_func_reverse
{
return reverse(@_);
}
sub sql_func_rindex
{
    my $str = shift;
    my $substr = shift;
    my $pos = shift;
    $pos = length($str) unless (defined($pos));
    return rindex $str, $substr, $pos;
}
sub sql_func_sprintf
{
    # Note: sprintf prototype expects a scalar for first arg, so
    # supplying an array causes it to get evaluated in the scalar
    # context, which is wrong.  Shift off the format first.
    my $fformat = shift @_;
    my $foo = sprintf($fformat, @_);
    return $foo;
}

sub sql_func_substr
{
    my ($exp1, $off1, $len1) = @_;

    return substr $exp1, $off1, $len1
        if (defined($len1));
    return substr $exp1, $off1;

}
sub sql_func_uc
{
    my $str = shift;
    return uc($str);
}
sub sql_func_ucfirst
{
    my $str = shift;
    return ucfirst($str);
}

# perl scalar functions
# NUM
sub sql_func_abs
{
    my $num = shift;
    return abs($num);
}
sub sql_func_atan2
{
    my $yval = shift;
    my $xval = shift;
    return atan2 $yval, $xval;
}
sub sql_func_cos
{
    my $num = shift;
    return cos($num);
}

# natural log base e
sub sql_func_exp
{
    my $num = shift;
    return exp($num);
}
sub sql_func_hex
{
    my $num = shift;
    return hex($num);
}
# XXX XXX: bad name?
sub sql_func_int
{
    my $num = shift;
    return int($num);
}

# Note: need to disambiguate, because perl "log" is natural log, 
#       but sql "log" is log10
sub sql_func_log10
{
    my $n = shift;
    return log($n)/log(10);
}
sub sql_func_logn
{
    my ($base, $num) = @_;
    
    return undef
        unless (defined($base) && defined($num));

    return log($num)/log($base);
}
sub sql_func_oct
{
    my $num = shift;
    return oct($num);
}
sub sql_func_rand
{
    my $num = shift;
    return rand($num);
}
sub sql_func_sin
{
    my $num = shift;
    return sin($num);
}
sub sql_func_sqrt
{
    my $num = shift;
    return sqrt($num);
}
sub sql_func_srand
{
    my $num = shift;
    return srand($num);
}

# more perl
sub sql_func_perl_join
{
    my $p1 = shift;
    return join($p1, @_);
}

# SQL scalar functions
# CHAR
sub sql_func_concat
{
    return join('',@_);
}

sub sql_func_greatest
{
    my $maxval = shift;

    for my $val (@_)
    {
        if ($val gt $maxval)
        {
            $maxval = $val;
        }
    }
    return $maxval;
}

sub sql_func_initcap
{
    my $str = shift;

    # find all the words in the string, and capitalize the first
    # letter of each one (add underscore to non-word chars)
    my @foo = split(/\W|_/, $str);

    for my $val (@foo)
    {
        next unless (defined($val));

        # shouldn't need to use quotemeta because split should extra
        # only valid words -- no metachars
        my $ucfval = ucfirst($val);

        # replace each word (bounded by end of line, underscore, or
        # some non-word char) with its titlecase equivalent
        $str =~ s/(^|\W|_)($val)(\W|_|$)/$1$ucfval$3/gm;
    }

    return ($str);
}

sub sql_func_least
{
    my $minval = shift;

    for my $val (@_)
    {
        if ($val lt $minval)
        {
            $minval = $val;
        }
    }
    return $minval;
}

sub sql_func_lower
{
    my $str = shift;
    return lc($str);
}

sub sql_func_lpad
{
    my ($str, $len, $pattern) = @_;

    # error
    return undef
        unless (defined($str) && defined($len));

    my $outi = $str;

    if (defined($pattern) && length($pattern))
    {
        my $repeat = 0;

        my $orig_len = length($str);

        if ($orig_len < $len)
        {
            $repeat = 1 + ($len - $orig_len)/ length($pattern);
        }

        $outi = reverse($str);

        my $revpat = reverse($pattern);
        $outi .= ($revpat x $repeat) ;

        $outi = reverse(substr($outi, 0, $len));

    }
    else
    {
        # blank pad
        my $tmplate = "A$len";
        my $revstr = reverse($str);
        $outi = reverse(pack($tmplate, $revstr));
    }
    return $outi;

}

sub sql_func_ltrim
{
    my ($str, $pattern) = @_;

    # error
    return undef
        unless (defined($str));

    my $outi = $str;

    if (defined($pattern))
    {
        # pattern is a set of individual matching characters
        my @foo = split(/ */, $pattern);
        my $qmp = join('|', map(quotemeta, @foo));
        my $tmplate = '^(' . $qmp. ')*';
        $outi =~ s/$tmplate// ;

    }
    else
    {
        my $tmplate = '^\s*';
        $outi =~ s/$tmplate// ;
    }
    return $outi;
}

sub sql_func_replace
{
    my ($str, $search_str, $replace_str) = @_;

    # error
    return undef
        unless (defined($str) && defined($search_str));

    my $outi = $str;

    if (defined($replace_str))
    {
        my $qmp1 = quotemeta($search_str);
        my $qmp2 = quotemeta($replace_str);
        $outi =~ s/$qmp1/$qmp2/gm ;
    }
    else
    {
        my $qmp1 = quotemeta($search_str);

        $outi =~ s/$qmp1//gm ;
    }
    return $outi;
}

sub sql_func_rpad
{
    my ($str, $len, $pattern) = @_;

    # error
    return undef
        unless (defined($str) && defined($len));

    my $outi = $str;

    if (defined($pattern) && length($pattern))
    {
        my $repeat = 0;

        my $orig_len = length($str);

        if ($orig_len < $len)
        {
            $repeat = 1 + ($len - $orig_len)/ length($pattern);
        }
        $outi .= ($pattern x $repeat);
        $outi = substr($outi, 0, $len);

    }
    else
    {
        # blank pad
        my $tmplate = "A$len";
        $outi = pack($tmplate, $str);
    }
    return $outi;

}

sub sql_func_rtrim
{
    my ($str, $pattern) = @_;

    # error
    return undef
        unless (defined($str));

    my $outi = $str;

    if (defined($pattern))
    {
        # pattern is a set of individual matching characters
        my @foo = split(/ */, $pattern);
        my $qmp = join('|', map(quotemeta, @foo));

        my $tmplate = '(' . $qmp. ')*$';
        $outi =~ s/$tmplate// ;

    }
    else
    {
        my $tmplate = '\s*$';
        $outi =~ s/$tmplate// ;
    }
    return $outi;
}

sub sql_func_soundex
{
    my $str = shift;

    use Text::Soundex;

    return soundex($str);
}

sub sql_func_translate
{
    my ($str, $search_str, $replace_str) = @_;

    # error
    return undef
        unless (defined($str) && 
                defined($search_str) && defined($replace_str));

    my $outi = $str;

#    my $qmp1 = quotemeta($search_str);
#    my $qmp2 = quotemeta($replace_str);

    # translate is built at compile time, not subject to 
    # double quote interpolation, so must use eval
    eval "\$outi =~ tr/$search_str/$replace_str/" ;

    return $outi;
}

sub sql_func_upper
{
    my $str = shift;
    return uc($str);
}


# SQL scalar functions
# num
sub sql_func_ceil
{
    return POSIX::ceil(@_);
}

sub sql_func_cosh
{
    # from Math::Complex - hyperbolic cosine cosh(z) = (exp(z) + exp(-z))/2.
    my $num = shift;
    return ((exp($num) + exp((-1) * $num))/2);
}


sub sql_func_floor
{
    return POSIX::floor(@_);
}

sub sql_func_ln
{
    my $n = shift;
    return log($n);
}

sub sql_func_mod
{
    my ($mm, $nn) = @_;

    return undef
        unless (defined($mm) && defined($nn));

    return $mm if ($nn == 0);

    return $mm % $nn;
    
    # XXX XXX: what about negative mod?
}

sub sql_func_power
{
    my ($mm, $nn) = @_;

    return undef
        unless (defined($mm) && defined($nn));

    return $mm ** $nn;
}

# XXX XXX
sub sql_func_round
{
    my ($num, $decplace) = @_;

    return undef
        unless (defined($num));

    # XXX XXX: just call trunc($num+0.5, $decplace) ??

    $decplace = 0 unless (defined($decplace));

    if (0 == $decplace)
    {
        # add 1/2 then take the "floor" to get round up/round down behavior
        return POSIX::floor($num + 0.5);
    }
    if ($decplace > 0)
    {
        return ((sql_func_round($num * (10**$decplace)))
                /
                (10**$decplace)
                );
    }
    # negative decimal places round the left side of the decimal point
    $decplace *= -1;
    return ((sql_func_round($num / (10**$decplace)))
            *
            (10**$decplace)
            );

}

# XXX XXX
sub sql_func_sign
{
    my $num = shift;

    return undef unless (defined($num));

    # 0 if num == 0, 1 if num > 0, -1 if num < 0

    return ($num <=> 0);
}


sub sql_func_sinh
{
    # from Math::Complex - hyperbolic sine sinh(z) = (exp(z) - exp(-z))/2.
    my $num = shift;
    return ((exp($num) - exp((-1) * $num))/2);
}

sub sql_func_tan
{
    my $num = shift;
    return (sin($num)/cos($num));
}

sub sql_func_tanh
{
    # from Math::Complex - hyperbolic tangent tanh(z) = sinh(z) / cosh(z).
    my $num = shift;
    return (sql_func_sinh($num) / sql_func_cosh($num));
}

# XXX XXX
sub sql_func_trunc
{
    my ($num, $decplace) = @_;

    return undef
        unless (defined($num));

    $decplace = 0 unless (defined($decplace));

    if (0 == $decplace)
    {
        return POSIX::floor($num);
    }
    if ($decplace > 0)
    {
        return (
                (POSIX::floor(($num) * (10**$decplace))) /
                (10**$decplace));
    }
    # negative decimal places round the left side of the decimal point
    $decplace *= -1;
    return (
            (POSIX::floor(($num) / (10**$decplace))) *
            (10**$decplace));

}



# SQL scalar functions
# CONVERSION
sub sql_func_ascii
{
    my $str = shift;
    return ord($str);
}

sub sql_func_instr
{
    # XXX XXX: need to handle occurrence!!
    my ($str, $substr, $pos, $occurrence) = @_;
    $pos = 0 unless (defined($pos));
    $occurrence = 1 unless (defined($occurrence));

    # XXX XXX
    return undef unless ($occurrence > 0);

    if ($pos >= 0)
    {
        # instr starts at 1, and index starts at zero
        $pos-- if ($pos);

        my $foundit = (index $str, $substr, $pos);

        while (($occurrence > 1) && ($foundit > -1))
        {
            $pos = $foundit + 1;
            $foundit = (index $str, $substr, $pos);
            $occurrence--;
        }

        return ($foundit + 1);
    }
    else
    {
        # oof! weird semantics...
        $str = reverse($str);
        $substr = reverse($substr);
        # instr starts at 1, and index starts at zero
        $pos++;
        $pos *= -1;

        my $foundit = (index $str, $substr, $pos);

        while (($occurrence > 1) && ($foundit > -1))
        {
            $pos = $foundit + 1;
            $foundit = (index $str, $substr, $pos);
            $occurrence--;
        }

        # going backwards, so we are positioned at end of substr, not
        # the beginning.  Need to subtract the length
        
        return 0
            if ($foundit < 0);

#        return (($foundit - length($substr)) + 1);
        return (((length($str) - $foundit) - length($substr)) + 1);
    }

}
sub sql_func_nvl
{
    my $s1 = shift;
    my $s2 = shift;

    if (defined($s1))
    {
        return $s1;
    }
    return $s2;
}

# Genezzo custom functions

# only allow alphanums, and quote all other chars as hex string
sub sql_func_quurl
{
    my $str = shift;

    $str =~ s/([^a-zA-Z0-9])/uc(sprintf("%%%02lx",  ord $1))/eg;
    return $str;
}

# more "relaxed" version of quurl function -- allow basic punctuation
# with the exception of "%" and quote characters
sub sql_func_quurl2
{
    my $str = shift;

    my $pat1 = '[^a-zA-Z0-9' .
        quotemeta(' ~!@#$^&*()-_=+{}|[]:;<>,.?/') . ']';
    $str =~ s/($pat1)/uc(sprintf("%%%02lx",  ord $1))/eg;
    return $str;
}

# unconvert quoted strings 
sub sql_func_unquurl
{
    my $str = shift;

    $str =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
    return $str;
}

sub HavokInit
{
#    whoami;
    my %optional = (phase => "init");
    my %required = (dict  => "no dictionary!",
                    flag  => "no flag"
                    );

    my %args = (%optional,
		@_);
#		
    my @stat;

#    push @stat, 0, $args{flag};
    push @stat, 1, $args{flag};
#    whoami (%args);

    return @stat
        unless (Validate(\%args, \%required));

    return @stat;
}

sub HavokCleanup
{
#    whoami;
    return HavokInit(@_, phase => "cleanup");
}


END { }       # module clean-up code here (global destructor)

## YOUR CODE GOES HERE

1;  # don't forget to return a true value from the file

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::Havok::SQLScalar - scalar SQL functions

=head1 SYNOPSIS

HavokUse("Genezzo::Havok::SQLScalar")

=head1 DESCRIPTION

=head1 ARGUMENTS

=head1 FUNCTIONS

=head2 perl functions

See L<perlfunc(1)> for descriptions.

=over 4

=item  chomp(char_str)

Return the string with the trailing newline removed.

=item  chop(char_str)

Return the string with the last character removed.

=item  chr(number)

Returns the character represented by the number in the character set.

=item  crypt(plaintext, salt)

Returns the plaintext string encrypted with the C crypt routine.

=item  index(char_str, substr[, start_position])

Returns the position (0-based) of the first character of the substring
in the string, or -1 if not found, starting at start_position.
Start_position defaults to zero if not specified.

=item  lc(char_str)

Returns the lowercased char_str.

=item  lcfirst(char_str)

Returns char_str with only the first character lowercased.

=item  length(char_str)

Returns the number of characters in char_str.

=item  ord(char_str)

Returns the numeric encoding of the first character of char_str.

=item  pack(template_str, list_of_values)

Converts a list of values into a string using the perl pack function.

=item  reverse(char_str)

Returns the string in reverse order.

=item  rindex(char_str, substr[, start_position])

Like index, but backwards: finds the last occurrence of the substr in
char_str.

=item  sprintf(format_str, list_of_values)

Returns a string formatted using the C sprintf.

Note that the sprintf format string must be single-quoted (SQL-style),
not double-quoted.

=item  substr(char_str, offset_position[, length])

Returns the substring of char_str, starting at the offset, of the
specified length.  If length is omitted the it returns from the offset
to the end of the string.  Special rules for negative offset, length.

=item  uc(char_str)

Returns the uppercased char_str.

=item  ucfirst(char_str)

Returns char_str with only the first character uppercased.

=item  abs(number)

Absolute value

=item  atan2(numberY, numberX)

Arctangent (in radians)

=item  cos(number)

Cosine (in radians).

=item  exp(n)

Returns e**n

=item  hex(char_str)

Treats char_str as a hexadecimal value and converts to number.

=item  int(number)

Returns the integer portion of number.

=item  oct(char_str)

Treats char_str as a octal value and converts to number.

=item  rand(number)

Returns returns a random number N, where 0 <= N < number.  Note that N
is not an integer, so use an expression like int(rand(Max_N)) to
obtain integer values where 0 <= N <= (Max_N - 1).

=item  sin(number)

Sine (in radians)

=item  sqrt(number)

Square root.

=item  srand(number)

Set the random seed.

=item  perl_join(join_expr, char_str1, char_str2[, char_str3...])

The perl string join, renamed to avoid conflict with the SQL
relational join.  Concatenates the strings with the join_expr. 
Example:  perl_join(':', 'foo', 'bar', 'baz') returns 'foo:bar:baz'.

=back

=head2 SQL string functions

=over 4

=item  concat(char_str1, char_str2...)

Concatenate strings

=item  greatest(item1, item2...)

Find the greatest element in a list

=item  initcap(char_str)

Return the string with the initial letter of each word capitalized,
where words are defined as contiguous groups of alphanumeric chars
separated by non-word chars.

=item  least(item1, item2...)

Find the smallest element in a list

=item  lower(char_str)

Return the string with all letters lowercase

=item  lpad(char_str1, n [, char_str2])

Returns the string char_str1 padded out on the left to length n with
copies of char_str2.  If char_str2 is not specified blanks are used.
If char_str1 is larger than length n it is truncated to fit.

=item  ltrim(char_str [, set])

Returns the string which is trimmed on the left up to the first
character which is not in the specified set.  If set is unspecified,
blanks are trimmed.

=item  soundex(char_str)

Knuth's soundex from L<Text::Soundex>.

=item  replace(char_str, search_str [, replace_str])

Returns char_str with all occurrences of the search_str replaced by
replace_str.  If the replace_str is unspecified or null, it removes
all occurrences of the search_str.

=item  rpad(char_str1, n [, char_str2])

Returns the string char_str1 padded out on the right to length n with
copies of char_str2.  If char_str2 is not specified blanks are used.
If char_str1 is larger than length n it is truncated to fit.

=item  rtrim(char_str [, set])

Returns the string which is trimmed on the right up to the first
character which is not in the specified set.  If set is unspecified,
blanks are trimmed.

=item  translate(char_str, search_str, replace_str)

Similar to perl transliteration tr/ (see L<perlop(1)> ), returns a
string where all occurrences of a character in the search string are
replaced with the corresponding character in the replace string.

=item  upper(char_str)

Returns the string with all characters uppercase.

=back

=head2 SQL math functions

=over 4

=item  cosh(n)

Hyperbolic cosine

=item  ceil(n)

Returns the smallest integer greater than or equal to n

=item  floor(n)

Returns the largest integers less than or equal to n

=item  ln(n)
 
Natural log.

=item  log10(n)

Log base 10.

=item  logN(base_N, num)

Returns the Log base base_N on num.

=item  mod(m,n)

Returns the remainder of m divided by n.

=item  power(m,n)

Returns m**n

=item  round(num [, m])

Return num rounded to m places to the right of the decimal point.  M=0
if not specified.  If m is negative num is rounded to the left of the
decimal point.


=item  sign(n)

Similar to "spaceship", returns -1 for N < 0, 0 for N==0, and 1 for N > 0.

=item  sinh(n)

Hyperbolic sine.

=item  tan(n)

tangent

=item  tanh(n)

Hyperbolic tangent.

=item  trunc(num [, m])

Return num truncated to m places to the right of the decimal point.
M=0 if not specified.  If m is negative num is truncated to the left
of the decimal point.


=back

=head2 SQL conversion functions

These functions return a value of a different type than their
operands.

=over 4

=item  ascii(char_str)

Return the ascii value of the first char of the string.

=item  instr(char_str, substring [, position [, occurrence]])

Returns the index (1 based, not zero based) of the substring in the
char_str, starting at position.  If occurrence and position are not
specified they default to one: instr returns the index of the first
occurrence of the substring.  If occurrence is specified instr returns
the index of the Nth occurrence.  If position is negative instr begins
the search from the tail end of char_str.

=item  nvl(char_str1, char_str2)

Returns char_str2 if char_str1 is NULL, else returns char_str1

=back

=head2 Genezzo functions

=over 4

=item  quurl(char_str)

"Quote URL" - Replace all non-alphanumeric chars in a string with
'%hex' values, similar to the standard URL-style quoting.

=item  quurl2(char_str)

"Quote URL" - Replace most non-alphanumeric chars in a string with
'%hex' values, leaving spaces and most punctuation (with the exception
of '%') untouched.

=item  unquurl(char_str)

Convert a "quoted url" string back.

=back

=head2 EXPORT

=over 4


=back


=head1 LIMITATIONS


In Perl, "log" is a natural log, but the standard SQL log function is
log base N.  To prevent confusion in usage, Genezzo supplies a natural
log function "ln", a base 10 function "log10", and a log of variable
base called "logN".

The current implementation does not do any compile-time type checking
of arguments for any functions.

=head1 AUTHOR

Jeffrey I. Cohen, jcohen@genezzo.com

=head1 SEE ALSO

L<perl(1)>.

Copyright (c) 2005, 2006, 2007 Jeffrey I Cohen.  All rights reserved.

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
