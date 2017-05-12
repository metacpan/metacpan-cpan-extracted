package Debug::Xray; 
use strict;
use warnings;

use feature qw(state);

use Exporter qw(import);

our $VERSION     = 0.05;
our @ISA         = qw(Exporter);
our @EXPORT_OK;

no Carp::Assert;
use Hook::LexWrap;
use Data::Dumper;
use PPI;
use PadWalker qw(var_name);
use Debug::Xray::WatchScalar qw( set_log_handler TIESCALAR STORE FETCH );


# TODO Oranize subs into EXPORT_TAGS
# CONFIGURATION
push @EXPORT_OK, qw{
    &set_debug_verbose
    &set_debug_quiet
    &watch_subs
    &watch_all_subs
};


# TRACK SUBROUTINE EXECUTION
push @EXPORT_OK, qw{
    &start_sub
    &end_sub
    &dprint
};

# WATCH VARIABLE ROUTINES
push @EXPORT_OK, qw{
    &add_watch_var
};

# TESTING OF THIS MODULE
push @EXPORT_OK, qw{
    &is_carp_debug
};

# WARNING AND ERROR HANDLING
push @EXPORT_OK, qw{
    &debug_warn_handling
    &default_warn_handling
    &debug_error_handling
    &default_error_handling
};


my $Verbose = 1;
my $SUB_NEST_LIMIT = 200;

my $LogFile = '/home/dave/Desktop/Jobs/computer_exercises/perl/debug/Debug.log';

my $VOID_CONTEXT_ERROR_MESSAGE =    'The caller of this function must assign the return value. ' . 
                                    'The hooks remain in effect only when the returned value is in lexical scope.';

my @SubStack;

Debug::Xray::WatchScalar->set_log_handler(\&dprint);

sub set_debug_verbose   { $Verbose = 1 };
sub set_debug_quiet     { $Verbose = 0 };
sub is_verbose          { return $Verbose };
sub is_carp_debug {
    return 1 if DEBUG;
    return 0;
}


# MESSAGE PRINT ROUTINES

sub dprint($) {
    return unless $Verbose;

    my ($mesg) = shift;                                                
    my $print_line = _indentation() . $mesg;

    print "$print_line\n";

    _log_to_file($print_line) if $LogFile;
    return $print_line;
}


sub _log_to_file {
    assert ( $#_==0, 'Parms' ) if DEBUG;
    state $HLog;

    unless ($HLog) {open ( $HLog, ">$LogFile" ) or die "Could not open log file $LogFile: $!"};

    my $print_line = shift;
    print $HLog "$print_line\n";
}



sub debug_warn_handling {
    $SIG{__WARN__} = sub { &_warn_handler(@_); };

}
sub default_warn_handling {
    $SIG{__WARN__} = 'DEFAULT';
}


sub debug_error_handling {
    $SIG{__DIE__} = sub { &_error_handler(@_); };
}
sub default_error_handling {
    $SIG{__DIE__} = 'DEFAULT';
}

# TODO Call Stack for error handlers
sub _warn_handler {
    my @msgs = @_;
    
    for my $msg (@msgs) {
        dprint ("Warning: $msg");
    }
    #return @_;
}

sub _error_handler {
    my @msgs = @_;
    for my $msg (@msgs) {
        dprint ("Error: $msg");
    }
    #return @_;
}




sub start_sub {
    return unless $Verbose;

    my $msg = shift || (caller(1))[3];
    assert ( $#SubStack < $SUB_NEST_LIMIT, "Too many subs on stack " . Dumper \@SubStack) if DEBUG;
    assert ( defined $msg ) if DEBUG;
    
    dprint "SUB: $msg";
    push @SubStack, $msg;
}


sub end_sub {
    return unless $Verbose;

    my $msg = shift || (caller(1))[3];
    assert ( $msg !~ m/start_sub/) if DEBUG;
    assert ( $msg !~ m/end_sub/) if DEBUG;
    assert ( $SubStack[$#SubStack] eq $msg, 
        "Stack of size $#SubStack out of synch. Popping $SubStack[$#SubStack], expected $msg\nStack is " . 
        Dumper (\@SubStack) . "\n" ) if DEBUG;

    pop @SubStack;

    dprint "END: $msg";
}


sub _indentation() {
    return "    " x ($#SubStack+1);
}



# SUBROUTINE HOOK ROUTINES

sub watch_subs { # NOTE: Hooks stay in effect within the lexical scope of the return value
    assert ( defined wantarray, $VOID_CONTEXT_ERROR_MESSAGE ) if DEBUG;

    my @sub_names = @_;

    my $hooks;
    for my $sub_name (@sub_names) {
        push @$hooks, wrap $sub_name,
             pre  => sub { start_sub ($sub_name) },
             post => sub { end_sub ($sub_name) };
    }

    return $hooks;
}


sub watch_all_subs {  # NOTE: Hooks stay in effect within the lexical scope of the return value
    assert ( defined wantarray, $VOID_CONTEXT_ERROR_MESSAGE ) if DEBUG;

    my @caller = caller();
    my $Document = PPI::Document->new("$caller[1]");
    my $sub_nodes = $Document->find( 
        sub { $_[1]->isa('PPI::Statement::Sub') }
    );
    
    my @sub_names;
    for my $sub_node (@$sub_nodes) {
        next if $sub_node->name eq 'BEGIN';
        push @sub_names, $caller[0].'::'.$sub_node->name;
    }    

    return watch_subs(@sub_names);
}


sub add_watch_var {
    assert ( $#_==0, 'Parms' ) if DEBUG;
    my $var_ref = shift;
    my $var_name =  var_name(1, $var_ref);
    assert ( $var_name, "var_name has a value: $var_name]" ) if DEBUG;

    if ($var_name =~ /^\$/) {
        tie $$var_ref, 'Debug::Xray::WatchScalar', $var_name, $$var_ref; 
    }
    elsif ($var_name =~ /^\@/) { die 'Not implemented yet' }
    elsif ($var_name =~ /^\%/) { die 'Not implemented yet' }
    else  { die "Invalid variable name '$var_name'" if DEBUG }

    return $var_name if DEBUG;
  }


__END__

=head1 NAME

Debug::Xray - Debugging tool to trace, log, and watch variables

=head1 VERSION

Version 0.05


=head1 SYNOPSIS

Debug::Xray allows you to easily instrument your code and log what happens. 
If you log subroutines, logging messages will be suitably indented.

    use Debug::Xray;

    my $watcher = Debug::Xray::watch_all_subs();
    my $var;
    add_watch_var($var);

=head1 EXPORT

# SIGNAL HANDLING
    &debug_warn_handling
    &default_warn_handling
    &debug_error_handling
    &default_error_handling

# LOGGING
    &start_sub
    &end_sub
    &dprint
    &set_debug_verbose
    &set_debug_quiet

# WATCH ROUTINES
    &add_watch_var
    &watch_subs
    &watch_all_subs

# TESTING OF THIS MODULE
    &is_carp_debug


=head1 SUBROUTINES


=head2 debug_warn_handling()

The C<debug_warn_handling> subroutine causes the debugging warning processing to come into effect. Warnings will be logged. 
Logging is written to standard input and optionally to a file.

=head2 default_warn_handling()

The C<default_warn_handling> subroutine causes the standard warning processing to come into effect.

=head2 debug_error_handling()

The C<debug_error_handling> subroutine causes the debugging error processing to come into effect. Hopefully, all errors are logged.
Logging is written to standard input and optionally to a file.

=head2 default_error_handling()

The C<default_error_handling> subroutine causes the standard error processing to come into effect.

=head2 start_sub()

The C<start_sub> subroutine logs the start of a subroutine. You may insert this at the start of a subroutine or have it done automatically
via the watch methods. Logging is written to standard input and optionally to a file.

=head2 end_sub()

The C<end_sub> subroutine logs the end of a subroutine. You may insert this at the end of a subroutine or have it done automatically
via the watch methods. Logging is written to standard input and optionally to a file.

=head2 dprint($mesg)

The C<dprint> subroutine logs whatever you pass to it. Currently, it takes a single scalar, so if you need to concatenate with '.' 
rather than ','. Logging is written to standard input and optionally to a file.

=head2 set_debug_verbose()

The C<set_debug_verbose> subroutine causes logging to be written to standard input and optionally to a file.

=head2 set_debug_quiet()

The C<set_debug_quiet> subroutine turns off all debug logging.


=head2 add_watch_var($var)

The C<add_watch_var> subroutine causes logging of all changes or access to the variable being watched.

=head2 watch_subs( subroutine list )

The C<watch_subs> subroutine causes logging of entries to and exits from subroutines passed in. The subroutines may be quoted.

=head2 watch_all_subs()

The C<watch_all_subs> subroutine causes logging of entries to and exits from all subroutines in the scope of the call.


=head2 is_carp_debug()

The C<is_carp_debug> subroutine is for debugging purposes.


NOTE: The log file is active if it is hard-coded at the top of this module. This will be fixed.


=head1 AUTHOR

Dave Carvell, C<< <dave_carvell at yahoo.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-debug-xray at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Debug-Xray>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Debug::Xray


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Debug-Xray>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Debug-Xray>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Debug-Xray>

=item * Search CPAN

L<http://search.cpan.org/dist/Debug-Xray/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Dave Carvell.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Debug::Xray
