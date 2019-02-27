# Author: Matthew Mallard
# Website: www.q-technologies.com.au
# Date: 6th October 2016

# ABSTRACT: Outputs messages in multiple colors





package Log::MixedColor;
use Moose;
use Moose::Exporter;
use MooseX::Aliases;
use 5.10.0;
use Term::ANSIColor;
use Module::Load::Conditional qw[ check_install ];

use constant DEBUG_MSG => "debug";
use constant ERROR_MSG => "error";

# We only need to activate storage when someone using us has already installed the module
# otherwise the following code can silently fail
if( check_install( module => 'MooseX::Storage' )){
    require MooseX::Storage;
    MooseX::Storage->import();
    with Storage(
        'format' => 'JSON',
        'io'     => 'File',
        traits   => ['DisableCycleDetection']
    );
}


has 'verbose' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    alias   => 'v',
);


has 'debug' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    alias   => 'd',
);


sub quote {
    my $self = shift;
    return '%%' . shift() . '##';
}
alias q => 'quote';


has 'quote_start' => (
    is      => 'rw',
    isa     => 'Str',
    default => '%%',
);



has 'quote_end' => (
    is      => 'rw',
    isa     => 'Str',
    default => '##',
);



sub info_msg {
    my $self = shift;
    chomp( my $msg = shift );
    my $level = shift;
    $level = "" if !$level;
    my $color    = $self->info_color;
    my $var_col  = $self->info_quote_color;
    my $prefix   = $self->info_prefix;
    my $say      = ( $self->verbose or $self->debug );
    my $extra_nl = "";
    my $excl     = "";
    my $fh       = *STDOUT;
    if( $level eq DEBUG_MSG ){
        $color   = $self->debug_color;
        $var_col = $self->debug_quote_color;
        $prefix  = $self->debug_prefix;
        $say     = $self->debug;
    } elsif( $level eq ERROR_MSG ){
        $color    = $self->err_color;
        $var_col  = $self->err_quote_color;
        $prefix   = $self->err_prefix;
        $say      = 1;
        $extra_nl = "\n";
        $excl     = "!";
        $fh       = *STDERR;
    }
    for( $msg ){
        my $code1 = color("reset") . color($var_col);
        my $code2 = color("reset") . color($color);
        s/%%/$code1/g;
        s/##/$code2/g;
    }
    $prefix = $prefix . " " if $prefix;
    say $fh $extra_nl 
      . color($color)
      . $prefix
      . $msg
      . $excl
      . color("reset")
      . $extra_nl
      if $say;
}
alias info => 'info_msg';


sub debug_msg {
    my $self = shift;
    my $msg  = shift;
    $self->info_msg( $msg, DEBUG_MSG ) if $self->debug;
}
alias dmsg => 'debug_msg';


sub err_msg {
    my $self = shift;
    my $msg  = shift;
    $self->info_msg( $msg, ERROR_MSG );
}
alias err  => 'err_msg';
alias warn => 'err_msg';


sub fatal_err {
    my $self = shift;
    my $msg  = shift;
    my $val  = shift;
    $val = 1 unless defined( $val );
    $self->info_msg( $msg, ERROR_MSG );
    exit $val if $self->fatal_is_fatal;
}
alias fatal => 'fatal_err';


has 'fatal_is_fatal' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1,
);


has 'info_color' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'green',
);

has 'debug_color' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'magenta',
);

has 'err_color' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'red',
);

has 'info_quote_color' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'black on_white',
);

has 'debug_quote_color' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'blue',
);

has 'err_quote_color' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'yellow',
);

has 'info_prefix' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'Info:',
);

has 'debug_prefix' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'Debug:',
);

has 'err_prefix' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'Error:',
);




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::MixedColor - Outputs messages in multiple colors

=head1 VERSION

version 1.000

=head1 SYNOPSIS

Output log messages in color while emphasizing parts of the message in a different color.
Although colour codes witin a message string can be done manually, this module is providing a 
simplified approach to colour logging hopefully saving time and code
(and colour codes can also be inserted manually if required - i.e. they won't be stripped).

    use Log::MixedColor;
    my $log = Log::MixedColor->new;

    $log->verbose(1);
    $log->info_msg( "This is a " . $log->quote('general info') . " message." );

    $log->debug(1);
    $log->debug_msg( "This is a " . $log->q('debug') . " message" );

There are four types of messages:

=over

=item * C<info_msg> (or C<info>) - displayed when debug or verbose are turned on

=item * C<debug_msg> (or C<dmsg>) - displayed when debug is turned on

=item * C<err_msg> (or C<err>) - displayed all the time on STDERR

=item * C<fatal_msg> (or C<fatal>) - displayed all the time on STDERR and will cause the script to exit

=back

The C<debug> and C<verbose> methods are intended so that the script utilising this module can
pass the command line option values specifying whether to operate the script logging in verbose or debug mode.

    use Getopt::Std;
    use Log::MixedColor;

    our( $opt_v, $opt_d );
    getopts('vd');

    my $log = Log::MixedColor->new( verbose => $opt_v, debug => $opt_d );

    $log->info_msg( "This is a " . $log->quote('general info') . " message." );
    $log->debug_msg( "This is a " . $log->q('debug') . " message" );

The debug log messages will only display when the script is run with C<-d> and the verbose messages will
be display when the script is run with C<-d> or C<-v>.

=head1 METHODS

=head2 new

Create the I<Log::MixedColor> object.  The following can be set at creation time (defaults shown):

    my $log = Log::MixedColor->new( 
        verbose        => 0,
        debug          => 0,
        fatal_is_fatal => 1
    );

which is equivalent to:

    my $log = Log::MixedColor->new;

=head2 verbose

Put the log object in verbose mode.

    $log->verbose(1);

=head2 v

Alias for C<verbose>.

=head2 debug

Put the log object in debug mode.

    $log->debug(1);

=head2 d

Alias for C<debug>.

=head2 quote

Quote a portion of the message in a different color to the rest of the message

    $log->debug_msg( "This is a ".$log->quote('quoted bit')." inside a message." );

Alternatively, instead of using this method, you could just use the quoting strings directly, e.g.:

    $log->debug_msg( "This is a %%quoted bit## inside a message." );

=head2 q

Alias for C<quote>.

=head2 quote_start

Sets the string used to denote the start of the text to be quoted in a different color. Default shown

    $log->quote_start( '%%' );

It needs to be different from that specified by C<quote_end>.

=head2 quote_end

Sets the string used to denote the end of the text to be quoted in a different color. Default shown.

    $log->quote_end( '##' );

It needs to be different from that specified by C<quote_start>.

=head2 info_msg

Display a message on C<STDOUT> when the log object is in debug or verbose mode.

    $log->info_msg( "This is a " . $log->quote('general') . " message." );

=head2 info

Alias for C<info_msg>.

=head2 debug_msg

Display a message on C<STDOUT> when the log object is in debug mode.

    $log->debug_msg( "This is a " . $log->quote('low level') . " message." );

=head2 dmsg

Alias for C<debug_msg>.

=head2 err_msg

Display a message on C<STDERR>.

    $log->err_msg( "This is a " . $log->quote('warning') . " message." );

=head2 err

Alias for C<err_msg>.

=head2 warn

Alias for C<err_msg>.

=head2 fatal_err

Display a message on C<STDERR> and then exit the script.

    $log->fatal_err( "This is a ".$log->quote('critical')." message so we have to stop.", 2 );

The optional second argument is the exit code the script will exit with.  It defaults to C<1>.

The I<exit> feature can be turned off by setting C<$log-E<gt>fatal_is_fatal> to false.

=head2 fatal

Alias for C<fatal_err>.

=head2 fatal_is_fatal

Determines whether the C<fatal_msg> method actually causes the script to exit.  It
will by default.

    $log->fatal_is_fatal(0);

Turning it off will make it equivalent to C<err_msg>, but might be helpful when developing a script
during which time you may not want it to be fatal, but you do when your script goes into production.

=head2 COLORS

To customise the colors, pass the color strings as recognised by L<Term::ANSIColor> to the following 
relevant methods or set the equivalent properties as part of C<new> (the default is shown in brackets):

=over

=item * C<info_color> (green)

=item * C<debug_color> (magenta)

=item * C<err_color> (red)

=item * C<info_quote_color> (black on_white)

=item * C<debug_quote_color> (blue)

=item * C<err_quote_color> (yellow)

=back

The C<fatal_err> method will use the same colours as the C<err_msg> method.

=head2 Message Prefixes

To allow for language variations and individual preferences the prefix before the output message can 
be customised with the following methods (defaults shown in brackets):

=over

=item * C<info_prefix> (Info:)

=item * C<debug_prefix> (Debug:)

=item * C<err_prefix> (Error:)

=back

The C<fatal_err> method will use the same prefix as the C<err_msg> method.

=head1 BUGS/FEATURES

Please report any bugs or feature requests in the issues section of GitHub: 
L<https://github.com/Q-Technologies/perl-Log-MixedColor>. Ideally, submit a Pull Request.

=head1 AUTHOR

Matthew Mallard <mqtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Matthew Mallard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
