package Devel::SimpleTrace;
use strict;

{
    no strict;
    $VERSION = '0.08';
}

# Install warn() and die() substitutes
$SIG{'__WARN__'} = \&_do_warn;
$SIG{'__DIE__' } = \&_do_die;

my $stderr = '';
my $in_eval = 0;
my %options = (
    showrefs => 0, 
);


# 
# import()
# ------
sub import {
    my $class = shift;
    
    for my $opt (@_) {
        exists $options{$opt} ? $options{$opt} = not $options{$opt}
                              : CORE::warn "warning: Unknown option: $opt\n"
    }
}


# 
# _use_data_dumper()
# ----------------
sub _use_data_dumper {
    require Data::Dumper;
    import Data::Dumper;
    $Data::Dumper::Indent = 1;      # no fancy indent
    $Data::Dumper::Terse  = 1;      # don't use $VAR unless needed
    $Data::Dumper::Sortkeys = 1;    # sort keys
    #$Data::Dumper::Deparse = 1;     # deparse code refs
    {
        local $^W = 0; 
        *Devel::SimpleTrace::_use_data_dumper = sub {};
    }
}


# 
# _do_warn()
# --------
sub _do_warn {
    local $SIG{'__WARN__'} = 'DEFAULT';
    
    my $msg = join '', @_;
    $msg =~ s/ at (.+?) line (\d+)\.$//;
    $stderr .= $msg;
    $stderr .= "\n" if substr($msg, -1, 1) ne "\n";
    
    _stack_trace($1, $2);
    
    print STDERR $stderr;
    $stderr = '';
    $in_eval = 0;
}


# 
# _do_die()
# -------
sub _do_die {
    local $SIG{'__WARN__'} = 'DEFAULT';
    local $SIG{'__DIE__' } = 'DEFAULT';
    
    CORE::die @_ if ref $_[0] and not $options{showrefs};
    CORE::die @_ if index($_[0], "\n\tat ") >= 0;
    my @args = @_;
    
    _use_data_dumper() if ref $args[0];
    my $msg = join '', map { ref $_ ? "Caught exception object: $_\: ".Dumper($_) : $_ } @args;
    $msg =~ s/ at (.+?) line (\d+)\.$//;
    $stderr .= $msg;
    $stderr .= "\n" if substr($msg, -1, 1) ne "\n";
    
    _stack_trace($1, $2);
    
    if($in_eval) {
        $@ = $stderr;
        $stderr = '';
        $in_eval = 0;
        CORE::die $@
        
    } else {
        print STDERR $stderr;
        $stderr = '';
        exit -1
    }
}


# 
# _stack_trace()
# ------------
sub _stack_trace {
    my($file,$line) = @_;
    $file ||= '';  $line ||= '';
    $file =~ '(eval \d+)' and $file = '<eval>';
    
    my $level = 2;
    my @stack = ( ['', $file, $line] );  # @stack = ( [ function, file, line ], ... )
    
    while(my @context = caller($level++)) {
        $context[1] ||= '';  $context[2] ||= '';
        $context[1] =~ '(eval \d+)' and $context[1] = '<eval>' and $in_eval = 1;
        $context[3] eq '(eval)' and $context[3] = '<eval>' and $in_eval = 1;
        $stack[-1][0] = $context[3];
        push @stack, [ '', @context[1, 2] ];
    }
    $stack[-1][0] = (caller($level-2))[0].'::' || 'main::';
    
    for my $func (@stack) {
        $$func[1] eq '' and $$func[1] = 'unknown source';
        $$func[2] and $$func[1] .= ':';
        $stderr .= "\tat $$func[0]($$func[1]$$func[2])\n";
    }
}


1;

__END__

=head1 NAME

Devel::SimpleTrace - See where you code warns and dies using stack traces

=head1 VERSION

Version 0.08

=head1 SYNOPSIS

On the command-line:

    perl -wMDevel::SimpleTrace program_with_strange_errors.pl

Inside a module:

    use Devel::SimpleTrace;


=head1 DESCRIPTION

This module can be used to more easily spot the place where a program 
or a module generates errors. Its use is extremely simple, reduced 
to just C<use>ing it. 

This is achieved by modifying the functions C<warn()> and C<die()> 
in order to replace the standard messages by complete stack traces 
that precisely indicates how and where the error or warning occurred. 
Other than this, their use should stay unchanged, even when using 
C<die()> inside C<eval()>. 


=head1 OPTIONS

Options can be set at import time using: 

    perl -wMDevel::SimpleTrace=option1,option2

or 

    use Devel::SimpleTrace qw(option1 option2);

Available options are: 

=over 4

=item C<showrefs>

Using this option will tell C<Devel::SimpleTrace> to stringify objects and 
references passed in argument to C<die()>. This option is disabled by default 
in order to leave objects and references untouched. 

=back


=head1 EXAMPLE

For example, C<HTTP::Proxy> 0.14 suffered from strange warnings, and 
its author Philippe Bruhat had a hard time trying to understand where 
they could come from. 

    getsockname() on closed socket Symbol::GEN7 at /System/Library/Perl/darwin/IO/Socket.pm line 186.
    Use of uninitialized value in numeric ne (!=) at /Library/Perl/HTTP/Daemon.pm line 53.

Hmm.. There's obviously something wrong here, but spotting the right 
line is not easy. 

Re-running the same script, unchanged, by just adding C<-MDevel::SimpleTrace> 
to C<perl> arguments produces the following output: 

    getsockname() on closed socket Symbol::GEN7
            at IO::Socket::sockname(/System/Library/Perl/darwin/IO/Socket.pm:186)
            at IO::Socket::INET::sockport(/System/Library/Perl/IO/Socket/INET.pm:231)
            at HTTP::Daemon::url(/Library/Perl/HTTP/Daemon.pm:52)
            at HTTP::Daemon::ClientConn::get_request(/Library/Perl/HTTP/Daemon.pm:139)
            at HTTP::Proxy::serve_connections(/Library/Perl/HTTP/Proxy.pm:500)
            at HTTP::Proxy::start(/Library/Perl/HTTP/Proxy.pm:392)
            at t::Utils::fork_proxy(t/Utils.pm:72)
            at main::(t/50standard.t:138)
    Use of uninitialized value in numeric ne (!=)
            at HTTP::Daemon::url(/Library/Perl/HTTP/Daemon.pm:53)
            at HTTP::Daemon::ClientConn::get_request(/Library/Perl/HTTP/Daemon.pm:139)
            at HTTP::Proxy::serve_connections(/Library/Perl/HTTP/Proxy.pm:500)
            at HTTP::Proxy::start(/Library/Perl/HTTP/Proxy.pm:392)
            at t::Utils::fork_proxy(t/Utils.pm:72)
            at main::(t/50standard.t:138)

Aha! Much better. Finding the bug is now a trivial task C<;-)>


=head1 DIAGNOSTICS

=over 4

=item Unknown option: %s

B<(W)> This warning occurs if you try to set an unknown option. 

=back


=head1 CAVEATS

This module is currently not compatible with other modules that also 
work by overriding C<die()> and C<warn()>, like C<CGI::Carp>. 


=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni E<lt>sebastien@aperghis.netE<gt>


=head1 BUGS

Please report any bugs or feature requests to
C<bug-Devel-SimpleTrace@rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-SimpleTrace>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.


=head1 COPYRIGHT & LICENSE

Devel::SimpleTrace is Copyright (C)2004-2011 SE<eacute>bastien Aperghis-Tramoni.

This program is free software. You can redistribute it and/or modify it 
under the same terms as Perl itself. 

=cut
