package IPC::ForkPipe;

use 5.008008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
    pipe_to_fork pipe_from_fork	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    pipe_to_fork pipe_from_fork
);

our $VERSION = '0.02';


# Code ganked from http://perldoc.perl.org/perlfork.html

# simulate open(FOO, "|-")
sub pipe_to_fork ($) {
    my $parent = shift;
    pipe my $child, $parent or die;
    my $pid = fork();
    return unless defined $pid;
    if ($pid) {
        close $child;
    }
    else {
        close $parent;
        open(STDIN, "<&=" . fileno($child)) or die;
    }
    return $pid;
}

# simulate open(FOO, "-|")
sub pipe_from_fork ($) {
    my $parent = shift;
    pipe $parent, my $child or die;
    my $pid = fork();
    return unless defined $pid;
    if ($pid) {
        close $child;
    }
    else {
        close $parent;
        open(STDOUT, ">&=" . fileno($child)) or die;
    }
    return $pid;
}

1;
__END__

=begin POD

=head1 NAME

IPC::ForkPipe - Perl extension for safely forking with a pipe

=head1 SYNOPSIS

    use IPC::ForkPipe;
    use Symbol;
    
    my $pipe = gensym;
    my $pid = pipe_from_fork( $pipe );
    die "Unable to fork: $!" unless defined $pid;
    if( $pid ) {    # parent
        while( <$pipe> ) {
            # handle output from pipe process
        }
    }
    else {          # child
        print "Hello world\n";
    }


    # equiv to open("| some-prog" );
    my $pipe = gensym;
    my $pid = pipe_to_fork( $pipe );
    die "Unable to fork: $!" unless defined $pid;
    unless( $pid ) {    # child
        exec "some-prog";
    }

    print $pipe "Hello world\n";

   
=head1 DESCRIPTION

Win32 does not suport the C<open(FH,"-|"> and C<open(FH,"|-"> constructs. 
This module implements pure-perl functions to do the same thing.

=head1 FUNCTIONS

=head2 pipe_from_fork

    my $pid = pipe_from_fork( $fh );

Equivalent to C<$pid = open $fh, "-|">.

=head2 pipe_to_fork

    my $pid = pipe_to_fork( $fh );

Equivalent to C<$pid = open $fh, "|-">.



=head1 EXPORT

L</pipe_to_fork>, L</pipe_from_fork>.


=head1 SEE ALSO

L<IPC::Open3>, L<Forks::Super>.

=head1 AUTHOR

Philip Gwyn, E<lt>gwyn-at-cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Philip Gwyn

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
