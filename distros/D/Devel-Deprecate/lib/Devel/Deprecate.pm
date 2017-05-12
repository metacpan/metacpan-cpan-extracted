package Devel::Deprecate;

use warnings;
use strict;

=head1 NAME

Devel::Deprecate - Create deprecation schedules in your code

=head1 VERSION

Version 0.01

=cut

use base 'Exporter';
use Carp ();
use DateTime;
use Scalar::Util qw(reftype blessed);
use vars qw($VERSION @EXPORT_OK);
$VERSION   = '0.01';
@EXPORT_OK = qw(deprecate);

=head1 SYNOPSIS

    use Devel::Deprecate 'deprecate';

    sub name {
        my ( $self ) = @_;

        deprecate(
            reason => 'Please use the set_name() method for setting names',
            warn   => '2008-11-01',    # also accepts DateTime objects
            die    => '2009-01-01',    # two month deprecation period
            if     => sub { return @_ > 1 },
        );
        if ( @_ > 1 ) {
            $self->{name} = $_[1];
            return $self;
        }
        return $self->{name};
    }

=head1 DESCRIPTION

Many times we find ourselves needing to deprecate code or have a deadline and
just don't have time to refactor.  Instead of trying to remember about this,
posting it to a wiki or sending an email, it's better to have an automatic way
to deprecate something.  This module allows you to do that and embeds the
deprecation directly in the code you wish to deprecate.

As we don't want to break production code, deprecations are only triggered
when running tests.

=head1 EXPORT

=head1 FUNCTIONS

=head2 C<deprecate>

 deprecate( reason => 'The foo() method does not appear to be used' );

 deprecate(
     reason => 'Please use the set_name() method for setting names',
     warn   => '2008-11-01',    # also accepts DateTime objects
     die    => '2009-01-01',    # two month deprecation period
     if     => sub { return @_ > 1 },
 );

This function is exported on demand.  It takes an even-sized list of key/value
pairs.  Its function is to spit out a warning (or croak) when deprecation
criteria are hit.  

Deprecation warnings or failures only occur when running tests (but see
L<PRODUCTION ENVIRONMENTS> below)
and are designed to be extremely noisy (and with a strack trace):

 # DEPRECATION WARNING
 #
 #     Package:     Our::Customer
 #     File:        lib/Our/Customer.pm
 #     Line:        58
 #     Subroutine:  Our::Customer::name
 #
 #     Reason:      Please use the set_name() method for setting names
 #
 #     This warning becomes FATAL on (2009-01-01)

And after the due date:

 # DEPRECATION FAILURE
 #
 #     Package:     Our::Customer
 #     File:        lib/Our/Customer.pm
 #     Line:        58
 #     Subroutine:  Our::Customer::name
 #
 #     Reason:      Please use the set_name() method for setting names
 #
 #     This deprecation became fatal on (2009-01-01)

Allowed key/value pairs:

=over 4

=item * C<reason>

This is the only required key.

This should be a human readable string explaining why the deprecation is
needed.

 reason => 'This module should be replaced by the Our::Improved::Module'

If C<deprecate()> is called with only a reason, it begins issuing deprecation
warnings immediately.

=item * C<warn>

Optional.  If not present, deprecation warnings start immediately.

This should be a string in 'YYYY-MM-DD' format or a C<DateTime> object
indicating when the deprecation warnings should start.

 warn => '2008-06-06'
 # or ...
 warn => DateTime->new( year => 2008, month => 06, day => 06 )

=item * C<die>

Optional.  If not present, deprecation warnings never become fatal.

This should be a string in 'YYYY-MM-DD' format or a C<DateTime> object
indicating when the deprecation warnings should become fatal.

 die => '2009-06-06'
 # or ...
 die => DateTime->new( year => 2009, month => 06, day => 06 )

=item * C<if>

Optional.  May be a boolean value or a code reference.

 if => ( @_ > 1 )
 # or
 if => sub { @_ > 1 }

If the 'if' condition evaluates to false, no deprecation action action is
taken.

If the 'if' argument is a code reference, it will receive the C<deprecate()>
argument list has a hash reference in C<$_[0]>, minus the 'if' key/value pair.

=back

=head1 PRODUCTION ENVIRONMENTS

Don't break them.  Just don't.  People get mad at you and scratch you off
their Christmas card list.  To ensure that C<Devel::Deprecate> doesn't break
production environments, C<deprecate()> returns immediately if
C<$ENV{HARNESS_ACTIVE}> evaluates as false, thus ensuring that deprecations
are generally only triggered by tests.

However, sometimes you might find this variable set in production code, so you
can still disable this module by setting the C<$ENV{PERL_DEVEL_DEPRECATE_OFF}>
variable to a true value.

Failing that, simply omit the C<die> key.  Then, at most you'll get lots of
warnings and never a fatal error.

=head1 SCHEDULING DEPRECATIONS

Typically you'll just want something like the following in your code:

 deprecate( reason => 'Use CGI.pm instead of cgi-lib.pl' );

That issues noisy warnings about a deprecation, but at times you'll want to
schedule a deprecation period.  Perhaps the deprecation won't even start until
a new software package is installed in three months and it's agreed that the
"old" interface is to be supported for six months.  Assuming today is the
first day of 2008, you might write a deprecation like this:

 use Devel::Deprecate 'deprecate';

 sub report : Path('/report/sales') {
     deprecate(
         reason => 'Pointy-haired bosses bought a reporting package',
         warn   => '2008-04-01',
         die    => '2008-10-01',
     );
     ...

That subroutine I<should> only run while testing (see 
L<PRODUCTION ENVIRONMENTS>) and will likely annoy the heck our of developers
with verbose error messages.  Of course, that's the point.  The deprecation
period, however, should be carefully thought you.  In fact, you may wish to
omit it entirely to ensure that the deprecation is never a fatal error.

Alternately, you might write it like this:

 sub report : Path('/report/sales') {
     deprecate(
         reason => 'Pointy-haired bosses bought a reporting package',
         die    => '2008-10-01',
         if     => \&other_software_is_installed,
     );
     ...

With this, the deprecation warnings begin if and only if the
C<other_software_is_installed> subroutine returns true.  Further, even the
C<die> will be be triggered unless this condition holds.

=cut

sub deprecate {
    return if !$ENV{HARNESS_ACTIVE};             # only in testing
    return if $ENV{PERL_DEVEL_DEPRECATE_OFF};    # or let 'em force it
    if ( @_ % 2 ) {
        Carp::croak("deprecate() called with odd number of elements in hash assignment");
    }
    my %arg_for = @_;
    unless ( exists $arg_for{reason} ) {
        Carp::croak("deprecate() called without a 'reason' argument");
    }

    if (exists $arg_for{if}) {
        my $should_deprecate = delete $arg_for{if};

        if ('CODE' eq ( reftype $should_deprecate || '' )) {
            return unless $should_deprecate->(\%arg_for);
        }
        return unless $should_deprecate;
    }

    my $reason          = delete $arg_for{reason};

    _check_dates(\%arg_for);
    my $warn = _date(delete $arg_for{warn});
    my $die = _date(delete $arg_for{die});

    my $should_warn = _should_warn($warn);
    my $should_die  = _should_die($die);

    # parting is such sweet sorrow -- and the default
    $should_warn    = 0 if $should_die;

    _warn($reason, $die) if $should_warn;
    _die($reason, $die) if $should_die;
}

sub _check_dates {
    my $args = shift;
    return unless my $warn = _date($args->{warn});
    return unless my $die  = _date($args->{die});
    if ( $die <= $warn ) {
        Carp::croak("deprecate() die date ($args->{die}) must be after warn date ($args->{warn})");
    }
}

sub _should_warn {
    my $date = _date(shift);
    return 1 unless defined $date;   # warn by default
    return $date <= DateTime->today;
}

sub _should_die {
    my $date = _date(shift);
    return unless defined $date;     # do not die by default
    return $date <= DateTime->today;
}

sub _date {
    my $date = shift;
    return unless defined $date;   # it's OK if they haven't passed on
    return $date if blessed $date and $date->isa('DateTime');
    if ( $date =~ /\A(\d\d\d\d)-(\d\d)-(\d\d)\z/ ) {
        return DateTime->new(
            year  => $1,
            month => $2,
            day   => $3,
        );
    }
    Carp::croak("Cannot parse unknown date format ($date)");
}

sub _warn {
    my ( $reason, $die ) = @_;

    my ( $package, $filename, $line ) = caller(1);

    # need to get past deprecate()
    my ( undef, undef, undef, $subroutine ) = caller(2);
    $subroutine ||= 'n/a';
    my $padding = ' ' x 18;
    $reason =~ s/\n/\n#$padding/g;

    $reason = <<"    END";
# DEPRECATION WARNING
# 
#     Package:     $package
#     File:        $filename
#     Line:        $line
#     Subroutine:  $subroutine
#     
#     Reason:      $reason
    END

    if ( $die ) {
        $die = $die->ymd;
        $reason = <<"        END";
$reason#
#     This warning becomes FATAL on ($die)
        END
    }
    Carp::cluck($reason);
}

sub _die {
    my ( $reason, $die ) = @_;

    my ( $package, $filename, $line ) = caller(1);

    # need to get past deprecate()
    my ( undef, undef, undef, $subroutine ) = caller(2);
    $subroutine ||= 'n/a';
    my $padding = ' ' x 18;
    $reason =~ s/\n/\n#$padding/g;

    $reason = <<"    END";
# DEPRECATION FAILURE
# 
#     Package:     $package
#     File:        $filename
#     Line:        $line
#     Subroutine:  $subroutine
#     
#     Reason:      $reason
    END

    if ( $die ) {
        $die = $die->ymd;
        $reason = <<"        END";
$reason#
#     This deprecation became fatal on ($die)
        END
    }
    Carp::confess($reason);
}

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-devel-deprecate at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-Deprecate>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Devel::Deprecate

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devel-Deprecate>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Devel-Deprecate>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Devel-Deprecate>

=item * Search CPAN

L<http://search.cpan.org/dist/Devel-Deprecate>

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item * L<http://databaserefactoring.com/>.  

The "Refactoring Databases" book explained the rationale as to why we want
automated deprecation periods.

=item * L<http://www.perlmonks.org/?node_id=682407>

Several helpful comments on the Perl Monks discussion, particularly comments
by Jenda about not breaking production code.

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Curtis "Ovid" Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
