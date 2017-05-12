use strict;
package Devel::Caller;
use warnings;
use B qw( peekop );
use PadWalker ();
use XSLoader;
use base qw( Exporter  );
use 5.008;

our $VERSION = '2.06';
XSLoader::load __PACKAGE__, $VERSION;

our @EXPORT_OK = qw( caller_cv caller_args caller_vars called_with called_as_method );

sub caller_cv {
    my $level = shift;
    my $cx = PadWalker::_upcontext($level + 1);
    return unless $cx;
    return _context_cv($cx);
}

our $DEBUG = 0;

# scan forward through the ops noting the pushmark or a padrange ops.
# These indicate the start of a subroutine call.  We're looking for the most
# recent one before the subroutine invocation (the entersub).
sub scan_forward {
    my $op = shift;
    die "was expecting a pushmark or a padrange, not a " . $op->name
      if ($op->name !~ /^(?:pushmark|padrange)$/);

    my @stack;
    for (; $op && $op->name ne 'entersub'; $op = $op->next) {
        print "SCAN ", peekop($op), "\n" if $DEBUG;
        if ($op->name eq "pushmark" or $op->name eq "padrange") {
            print "   PUSH\n" if $DEBUG;
            push @stack, $op;
        }
        elsif (0) { # op consumes a mark
            print "   POP\n" if $DEBUG;
            pop @stack;
        }
    }
    return pop @stack;
}

*caller_vars = \&called_with;
sub called_with {
    my $level = shift;
    my $want_names = shift;

    my $op  = _context_op( PadWalker::_upcontext( $level + 1 ));
    my $cv  = caller_cv( $level + 2 );
    my $pad = $cv ? B::svref_2object( $cv )->PADLIST : B::comppadlist;
    my $padn = $pad->ARRAYelt( 0 );
    my $padv = $pad->ARRAYelt( 1 );

    print "Context OP: ", peekop($op), "\n" if $DEBUG;
    $op = scan_forward( $op );
    print "Scanned forward to ", peekop($op), "\n" if $DEBUG;

    my @return;
    my $prev;

    # We're scanning through looking for ops which are pushing
    # variables onto the stack (/pad(sv|av|hv)/ push from the pad, 
    # /gvsv|rv2([ahg]v/ are from globs.
    for (; $op && $op->name ne 'entersub'; ($prev = $op) && ($op = $op->next)) {
        printf "Loop: %s %s targ: %d\n", peekop($op), $op->name, $op->targ if $DEBUG;

        if ($op->name eq "padrange") {
            # A padrange is a 5.17 optimisation that uses a single op to
            # load multiple pad variables onto the stack.  The old ops
            # are preserved and are reachable as the padrange's sibling
            # so that B::Deparse can pessimise it back to that state.
            #
            # http://perl5.git.perl.org/perl.git/commitdiff/0fe870f5
            # http://perl5.git.perl.org/perl.git/commitdiff/a7fd8ef6
            #
            # We could use the B::Deparse method, but it's probably simpler if
            # we just reassign $op.
            print "padrange, diverting down ", $prev->sibling, "\n" if $DEBUG;
            $op = $op->sibling;
        }

        if ($op->name =~ "pad(sv|av|hv)") {
            if ($op->next->next->name eq "sassign") {
                print "sassign in two ops, this is the target skipping\n" if $DEBUG;
                next;
            }

            print "Copying from pad\n" if $DEBUG;
            if ($want_names) {
                push @return, $padn->ARRAYelt( $op->targ )->PVX;
            }
            else {
                push @return, $padv->ARRAYelt( $op->targ )->object_2svref;
            }
            next;
        }
        elsif ($op->name =~ /gvsv|rv2(av|hv|gv)/) {
            if ($op->next->next->name eq "sassign") {
                print "sassign in two ops, this is the target, skipping\n" if $DEBUG;
                next;
            }

            my $consider = ($op->name eq "gvsv") ? $op : $prev;
            my $gv;

            if (ref $consider eq 'B::PADOP') {
                print "GV is really a padgv\n" if $DEBUG;
                $gv = $padv->ARRAYelt( $consider->padix );
                print "NEW GV $gv\n" if $DEBUG;
            }
            else {
                $gv = $consider->gv;
            }

            print "consider: $consider ", $consider->name, " gv $gv\n"
              if $DEBUG;

            if ($want_names) {
                my %sigils = (
                    "gvsv"  => '$',
                    "rv2av" => '@',
                    "rv2hv" => '%',
                    "rv2gv" => '*',
                   );

                push @return, $sigils{ $op->name } . $gv->STASH->NAME . "::" . $gv->SAFENAME;
            }
            else {
                my %slots = (
                    "gvsv"  => 'SCALAR',
                    "rv2av" => 'ARRAY',
                    "rv2hv" => 'HASH',
                    "rv2gv" => 'GLOB',
                   );
                push @return, *{ $gv->object_2svref }{ $slots{ $op->name} };
            }

            next;
        }
        elsif ($op->name eq "const") {
            if ($op->next->next->name eq "sassign") {
                print "sassign in two ops, this is the target, skipping\n" if $DEBUG;
                next;
            }

            push @return, $want_names ? undef : $op->sv;
            next;
        }
    }
    return @return;
}


sub called_as_method {
    my $level = shift || 0;
    my $op = _context_op( PadWalker::_upcontext( $level + 1 ));

    print "called_as_method: $op\n" if $DEBUG;
    die "was expecting a pushmark or pad, not a ". $op->name
      unless $op->name eq "pushmark";
    while (($op = $op->next) && ($op->name ne "entersub")) {
        print "method: ", $op->name, "\n" if $DEBUG;
        return 1 if $op->name =~ /^method(?:_named)?$/;
    }
    return;
}


sub caller_args {
    my $level = shift;
    package DB;
    () = caller( $level + 1 );
    return @DB::args
}

1;
__END__


=head1 NAME

Devel::Caller - meatier versions of C<caller>

=head1 SYNOPSIS

 use Devel::Caller qw(caller_cv);
 $foo = sub { print "huzzah\n" if $foo == caller_cv(0) };
 $foo->();  # prints huzzah

 use Devel::Caller qw(called_with);
 sub foo { print called_with(0,1); }
 foo( my @foo ); # should print '@foo'

=head1 DESCRIPTION

=over

=item caller_cv($level)

C<caller_cv> gives you the coderef of the subroutine being invoked at
the call frame indicated by the value of $level

=item caller_args($level)

Returns the arguments passed into the caller at level $level

=item caller_vars( $level, $names )
=item called_with($level, $names)

C<called_with> returns a list of references to the original arguments
to the subroutine at $level.  if $names is true, the names of the
variables will be returned instead

constants are returned as C<undef> in both cases

=item called_as_method($level)

C<called_as_method> returns true if the subroutine at $level was
called as a method.

=back

=head1 BUGS

All of these routines are susceptible to the same limitations as
C<caller> as described in L<perlfunc/caller>

The deparsing of the optree perfomed by called_with is fairly simple-minded
and so a bit flaky.

=over

=item

As a version 2.0 of Devel::Caller we no longer maintain compatibility with
versions of perl earlier than 5.8.2.  Older versions continue to be available
from CPAN and backpan.

=back

=head1 SEE ALSO

L<perlfunc/caller>, L<PadWalker>, L<Devel::Peek>

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net> with close reference to
PadWalker by Robin Houston

=head1 COPYRIGHT

Copyright (c) 2002, 2003, 2006, 2007, 2008, 2010, 2013 Richard Clamp.
All Rights Reserved.

This module is free software. It may be used, redistributed and/or
modified under the same terms as Perl itself.

=cut
