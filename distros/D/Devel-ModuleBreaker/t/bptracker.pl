#! /usr/bin/perl
# bptracker.pl [options]
# - a script that can report on breakpoints
#   that have been set.
#
# usage:
#     perl -I... -M<modules-to-load> -d:XXXBreaker=<expr> t/bptracker.pl [-c | -f | -s]
#
#    -c :  report count of breakpoints set by Devel::XXXBreaker module
#    -f :  report count of breakpoints set in each source file
#    -s :  report subroutines that have breakpoints set by Devel::XXXBreaker module
#          NOTE: -s option works for subs where first line of code is on same line as
#                the sub declaration. e.g., sub foo { 42 }  will work,  
#                sub foo { <newline> 42 <newline> }  will not.

use lib qw(blib/arch blib/lib lib t .);

BEGIN {
    @DB::typeahead = ("c","q");
    open $DB::OUT, '>', $^O eq 'MSWin32' ? 'nul' : '/dev/null';
}


# define subs at run-time so they won't be breakpoint
# candidates in Devel::SubBreaker

*list_bp = sub {
    return unless $INC{"perl5db.pl"};
    open FOO,">","bp.$$";
    {
        local $DB::OUT = *FOO;
        DB::cmd_L();
    }
    close FOO;
    open FOO, "<", "bp.$$";
    my @bp = <FOO>;
    close FOO;
    unlink "bp.$$";

    my @out;
    $_ = "";
    my $file = "";
    foreach my $bp (@bp) {
        chomp $bp;
        if ($bp =~ /:\s*$/) {
            $file = $bp;
            $_ = "$file;";
            next;
        }
        if ($bp =~ / break if /) {
            push @out, "$_\n";
            $_ = "$file;";
        } else {
            $_ .= "\n$bp";
        }
    }
    @out;
};

*list_bp_subs = sub {
    my @out = main::list_bp();
    return map { /sub ([a-z]+\d+) / ; $1 ? $1 : () } @out;
};

*list_bp_file = sub {
    my @out = main::list_bp();
    my %f;
    $f{$_}++ for map { /^(.*?):;/s; $1 ? $1 : () } @out;
    %f;
};

if ("@ARGV" =~ /-s/) {
    print join "\n",sort(list_bp_subs()), "";
} elsif ("@ARGV" =~ /-f/) {
    my %cnt = list_bp_file(), "";
    foreach my $f (sort keys %cnt) {
        print "$f,$cnt{$f}\n";
    }
} elsif ("@ARGV" =~ /-c/) {
    my @out = list_bp();
    print 0+@out,"\n";
} else {
    print join "\n\n", list_bp(), "";
}
