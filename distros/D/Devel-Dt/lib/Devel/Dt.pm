package Devel::Dt;
BEGIN {
  $Devel::Dt::VERSION = '0.04';
}
# ABSTRACT: Kind of emulates command line flag -Dt on normal perl

use warnings;
use strict;
use B ();
use B::Utils ();
use Runops::Trace ();
# use Data::Dump::Streamer ();
use IO::Handle;

my $Dumper;
my $CurrentFile;
my $CurrentLine;
my $OutputHandle;

sub dt {
    my ( $op, $arity, @args ) = @_;
    my $name  = $op->oldname;
    my $class = B::class( $op );

    my $dumped = '';
    if ( @args ) {
	$dumped = "@args";
	# $dumped = $Dumper->Data( \ @args );
    }

    if ( 'COP' eq $class ) {
	$CurrentFile = $op->file;
	$CurrentLine = $op->line;
    }
    
    $OutputHandle->printf( "(%s:%s)  %s=0x%0x\n", $CurrentFile, $CurrentLine, $name, $$op, $dumped )
	or warn "Can't write to $OutputHandle: $!";

    return;
}

BEGIN {
    $CurrentFile = $CurrentLine = '?';

    $OutputHandle = \ *STDERR;

    # $Dumper = Data::Dump::Streamer->new;
    # 
    # $Dumper->Names( 'args' );
    # $Dumper->Purity( 0 );
    # $Dumper->Declare( 0 );
    # $Dumper->KeyOrder( 'smart' );

    Runops::Trace::enable_global_tracing( \&dt );
}


() = -.0

__END__
=pod

=head1 NAME

Devel::Dt - Kind of emulates command line flag -Dt on normal perl

=head1 VERSION

version 0.04

=head1 SYNOPSIS

Use the module and it'll immediately begin acting like you'd started
your perl with -Dt.

 perl -MDevel::Dt -e 'print q(hi)'

The above program results in the following output. There is an
outstanding bug that the arguments to the operations aren't being
dumped.

 (?:?)  leavesub=0x84f6778
 (?:?)  const=0x84f6620
 (?:?)  negate=0x84f67f8
 (?:?)  enter=0x817cc78
 (-e:1)  nextstate=0x816d480
 (-e:1)  pushmark=0x8165818
 (-e:1)  const=0x816d618
 (-e:1)  print=0x816d568
 (-e:1)  leave=0x816d4b8

=head1 FUNCTIONS

=over

=item dt( ... )

A L<Runops::Trace> hook, installed as a mandatory hook.

=back

=head1 AUTHOR

Joshua ben Jore, C<< <jjore at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-devel-dt at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-Dt>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Devel::Dt

You can also look for information at:

=over

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devel-Dt>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Devel-Dt>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Devel-Dt>

=item * Search CPAN

L<http://search.cpan.org/dist/Devel-Dt>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 Joshua ben Jore, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Josh Jore <jjore@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Josh Jore.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

