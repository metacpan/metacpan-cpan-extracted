package IO::Die;

use strict;

#NOTE: This function does not attempt to support every possible way of calling
#Perl’s open() built-in, but to support the minimal syntax required to do
#everything that is useful to do with open(), with preference given to those
#forms that may (somewhat arbitrarily) be considered "better".
#
#For example, this function does NOT allow one-arg or two-arg open() except for
#the more "useful" cases like when MODE is '-|' or '|-'.
#
#On the other hand, open($fh, '-') seems harder to understand than its 3-arg
#equivalent, open($fh, '<&=', STDIN), so that two-arg form is unsupported.
#
#Current forms of open() that this supports are:
#   - any form of 3 or more arguments
#   - 2-arg when the MODE is '-|' or '|-'
#
#NOTE: Bareword file handles DO NOT WORK. (Auto-vivification does, though.)
#
sub open {
    my ( $NS, $mode, $expr, @list ) = ( shift, @_[ 1 .. $#_ ] );

    #https://github.com/pjcj/Devel--Cover/issues/125
    #my ( $NS, $handle_r, $mode, $expr, @list ) = ( shift, \shift, @_ );

    die "Avoid bareword file handles." if !ref $_[0] && defined $_[0] && length $_[0];
    die "Avoid one-argument open()." if !$mode;

    local ( $!, $^E );
    if ( !defined $expr ) {
        if ( $mode eq '|-' or $mode eq '-|' ) {

            #NOTE: Avoid // for compatibility with old Perl versions.
            my $open = CORE::open( $_[0], $mode );
            if ( !defined $open ) {
                $NS->__THROW('Fork');
            }

            return $open;
        }

        my $file = __FILE__;
        die "Avoid most forms of two-argument open(). (See $file and its tests for allowable forms.)";
    }

    my $ok = CORE::open( $_[0], $mode, $expr, @list ) or do {
        if ( $mode eq '|-' || $mode eq '-|' ) {
            my $cmd = $expr;

            #If the EXPR (cf. perldoc -f open) has spaces and no LIST
            #is given, then Perl interprets EXPR as a space-delimited
            #shell command, the first component of which is the actual
            #command.
            if ( !@list ) {
                ($cmd) = ( $cmd =~ m<\A(\S+)> );
            }

            $NS->__THROW( 'Exec', path => $cmd, arguments => \@list );
        }

        if ( 'SCALAR' eq ref $expr ) {
            $NS->__THROW('ScalarOpen');
        }

        $NS->__THROW( 'FileOpen', mode => $mode, path => $expr );
    };

    return $ok;
}

1;
