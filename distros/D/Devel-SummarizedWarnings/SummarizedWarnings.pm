package Devel::SummarizedWarnings;
use strict;
use vars qw(@LOGGED_WARNINGS $INSTALLED_HANDLER $VERSION);

sub install_handler {
    my $old_handler = $SIG{'__WARN__'};
    my $new_handler =
	( $old_handler
	  ? sub { &$old_handler; &append_to_warning_log; }
	  : \&append_to_warning_log );
    
    $INSTALLED_HANDLER = $SIG{'__WARN__'} = $new_handler;
    
    return;
}

# Modify this globally
BEGIN {
    $VERSION = 0.01;
    install_handler();
}

END {
    dump_warnings();
}

sub append_to_warning_log {
    push @LOGGED_WARNINGS, @_;
}

sub dump_warnings {
    local $^W;
    if ( $SIG{'__WARN__'} != $INSTALLED_HANDLER ) {
        push
	    @LOGGED_WARNINGS,
	    __PACKAGE__ . " was disabled prior to summarization\n";
    }

    # Summarize the saved warnings
    my %order;
    my %sum;
    while ( my $warning = shift @LOGGED_WARNINGS ) {
	my $msg;
	my $line;
        if ( not $warning =~ /^(.*) at .+? line (\d+)\.$/s ) {
	    $warning =~ s/\n$//;
	    $msg = $warning;
	    $line = 'NoSuchLine';
        } else {
	    $msg  = $1;
	    $line = $2;
        }
	$sum{$msg}{$line}++;
	
	if ( not exists $order{$msg} ) {
	    $order{$msg} = 1 + %order;
	}
    }

    # Reformat the summarization
    my @out;
    for ( sort { $order{$a} <=> $order{$b} }
	  keys %order ) {
        my $wrn = $sum{$_};
        if ( exists $wrn->{'NoSuchLine'} ) {
            push
		@out,
	        $_
                . ( $wrn->{'NoSuchLine'} > 1
                    ? " (x$wrn->{'NoSuchLine'})"
                    : '' );
        } else {
            push
		@out,
		"$_ on line@{[1 < keys %$wrn ? 's' : '']} "
                . join( 2 == keys %$wrn ? ' and ' : ', ',
			map "$_@{[ $wrn->{$_} == 1
                                   ? ''
                                   : qq[ (x$wrn->{$_})]]}",
			sort { $a <=> $b }
                        keys %$wrn );
        }
    }
    
    local $\ = "\n";
    print STDERR for @out;
}

1;

__END__

=head1 NAME

Devel::SummarizedWarnings - Causes warnings to be summarized

=head1 SYNOPSIS

 use Devel::SummarizedWarnings;
 use warnings;

 for ( 0 .. 10 ) {
     $k = 0 + undef . $_;
 }

 $k = 1 + undef . $_;

 warn "Seagulls!\n";

produces the output

 Warning: Use of "undef" without parens is ambiguous on lines 5 and 8
 Use of uninitialized value in addition (+) on lines 5 (x11) and 8
 Use of uninitialized value in concatenation (.) or string on line 8
 Seagulls!

instead of

 Warning: Use of "undef" without parens is ambiguous at w.pl line 5.
 Warning: Use of "undef" without parens is ambiguous at w.pl line 8.
 Use of uninitialized value in addition (+) at w.pl line 5.
 Use of uninitialized value in addition (+) at w.pl line 5.
 Use of uninitialized value in addition (+) at w.pl line 5.
 Use of uninitialized value in addition (+) at w.pl line 5.
 Use of uninitialized value in addition (+) at w.pl line 5.
 Use of uninitialized value in addition (+) at w.pl line 5.
 Use of uninitialized value in addition (+) at w.pl line 5.
 Use of uninitialized value in addition (+) at w.pl line 5.
 Use of uninitialized value in addition (+) at w.pl line 5.
 Use of uninitialized value in addition (+) at w.pl line 5.
 Use of uninitialized value in addition (+) at w.pl line 5.
 Use of uninitialized value in addition (+) at w.pl line 8.
 Use of uninitialized value in concatenation (.) or string at w.pl line 8.
 Seagulls!

=head1 DESCRIPTION

This module traps all warnings and summarizes them when the your perl script
exits. Warning trapping can be interrupted and resumed by removing/installing
the Devel::SummarizedWarnings::append_to_warning_log handler into
$SIG{'__WARN__'}.

Trapped warnings are stored in @Devel::SummarizedWarnings::LOGGED_WARNINGS.

=head1 AUTHOR

Joshua b. Jore E<lt>jjore@cpan.orgE<gt>

=cut
