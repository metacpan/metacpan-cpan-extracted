package Exporter::ConditionalSubs;

use strict;
use warnings;

require Exporter;
our @ISA = qw( Exporter );

use Carp qw( croak );

# ABSTRACT: Conditionally export subroutines
use version;
our $VERSION = 'v1.11.1'; # VERSION

#pod =head1 SYNOPSIS
#pod
#pod Allows subroutines to be conditionally exported.  If the condition
#pod is satisfied, the subroutine will be exported as usual.  But if not,
#pod the subroutine will be replaced with a stub that gets optimized away
#pod by the compiler.  When stubbed out, not even the arguments to the
#pod subroutine will get evaluated.
#pod
#pod This allows for e.g. assertion-like behavior, where subroutine calls
#pod can be left in the code but effectively ignored under certain conditions.
#pod
#pod First create a module that C<ISA> L<Exporter::ConditionalSubs>:
#pod
#pod     package My::Assertions;
#pod
#pod     require Exporter::ConditionalSubs;
#pod     our @ISA = qw( Exporter::ConditionalSubs );
#pod
#pod     our @EXPORT    = ();
#pod     our @EXPORT_OK = qw( _assert_non_empty );
#pod
#pod     sub _assert_non_empty
#pod     {
#pod         carp "Found empty value" unless length(shift // '') > 0;
#pod     }
#pod
#pod Then, specify an C<-if> or C<-unless> condition when C<use>ing that module:
#pod
#pod     package My::App;
#pod
#pod     use My::Assertions qw( _assert_non_empty ), -if => $ENV{DEBUG};
#pod
#pod     use My::MoreAssertions -unless => $ENV{RUNTIME} eq 'prod';
#pod
#pod     # Coderefs work too:
#pod     use My::OtherAssertions -if => sub { ... some logic ... };
#pod
#pod     _assert_non_empty($foo);    # this subroutine call might be a no-op
#pod
#pod
#pod This is a subclass of L<Exporter> and works just like it, with the
#pod addition of support for the C<-if> and C<-unless> import arguments.
#pod
#pod =head1 SUBROUTINES
#pod
#pod =head2 import
#pod
#pod Works like the L<Exporter> C<import()> function, except that it checks
#pod for an optional C<-if> or C<-unless> import arg, followed by either
#pod a boolean, or a coderef that returns true/false.
#pod
#pod If the condition evaluates to true for C<-if>, or false for C<-unless>,
#pod then any subs are exported as-is.  Otherwise, any subs in C<@EXPORT_OK>
#pod are replaced with stubs that get optimized away by the compiler (with
#pod one exception - see L</CAVEATS> below).
#pod
#pod You can specify either C<-if> or C<-unless>, but not both.  Croaks if
#pod both are specified, or if you specify the same option more than once.
#pod
#pod =cut

sub import
{
    my ($package, @args) = @_;

    # By default we are going to export subs as-is and not optimize them away:
    my $should_export_subs = 1;

    my @export_args = ($package);

    # Copy args until we come across "-if" or "-unless":
    #
    while (@args && ($args[0] || '') !~ /^-(?:if|unless)$/) {
        push @export_args, shift @args;
    }

    # If any args remain, it must be because we found "-if" or "-unless".
    # We expect the next arg to be the condition boolean or coderef:
    #
    if (@args) {
        my $thing = shift @args;    # i.e. "-if" or "-unless"
        unless (@args) {
            croak "$package->import failed: " .
                    qq{"$thing" must be followed by boolean or coderef};
        }
        my $condition = shift @args;

        # Go ahead and evaluate the condition if it's a coderef:
        $condition = $condition->() if ref($condition) eq 'CODE';

        # We might decide against importing subs, depending on the condition:
        $should_export_subs = $thing eq '-if' ? $condition : !$condition;

        # Copy any remaining args:
        #
        while (@args) {
            if ($args[0] && $args[0] =~ /^-(?:if|unless)$/) {
                croak "$package->import failed: " .
                        qq{Cannot use "$args[0]" after "$thing"};
            }
            push @export_args, shift @args;
        }
    }

    # Pulling in B::CallChecker and/or B::Generate to optimize away
    # the exported symbols can break test coverage metrics generated
    # by Devel::Cover.  We probably want to check coverage on the actual
    # exports anyway, so if Devel::Cover is in play assume we *should*
    # export everything:
    #
    # (took this conditional logic directly from Devel::Cover)
    #
    $should_export_subs = 1 if (
        $INC{'Devel/Cover.pm'}                                ||
        ($ENV{HARNESS_PERL_SWITCHES} || "") =~ /Devel::Cover/ ||
        ($ENV{PERL5OPT}              || "") =~ /Devel::Cover/
    );

    # If the "if" condition is false, or the "unless" condition is true,
    # replace any exportable subs with something that will get optimized away:
    #
    my %their_original_coderefs;
    unless ($should_export_subs) {

        no strict 'refs';
        my $stash = *{ $package . "::" };

        my @their_export_oks = @{ ($stash->{EXPORT_OK} || []) };
        for my $export_name (@their_export_oks) {

            my $globref = $stash->{$export_name};
            if ($globref && *$globref{CODE}) {

                my $symbol = $package . "::" . $export_name;

                # Save a copy of the original code:
                $their_original_coderefs{$symbol} = \&$symbol;

                require B::CallChecker;
                require B::Generate;

                # Replace the sub being imported with a void prototype sub
                # that gets optimized away:
                #
                {
                    no warnings 'redefine';
                    no warnings 'prototype';

                    *$symbol = sub () {0};

                    #---------------------------------------------------------
                    #
                    # This section lifted almost as-is from Debug::Show v0.0
                    #
                    # https://metacpan.org/pod/Debug::Show
                    #
                    # Thanks to Zefram
                    #
                    B::CallChecker::cv_set_call_checker(
                        \&$symbol,
                        sub ($$$) {
                            my($entersubop, undef, undef) = @_;
                            # B::Generate doesn't offer a way to explicitly free ops.
                            # We ought to be able to implicitly free $entersubop via
                            # constant folding, by something like
                            #
                            #     return B::LOGOP->new("and", 0,
                            #         B::SVOP->new("const", 0, !1),
                            #         $entersubop);
                            #
                            # but empirically that causes memory corruption and it's
                            # not clear why.  For the time being, leak $entersubop.
                            return B::SVOP->new("const", 0, !1);
                        },
                        \!1
                    );
                    #
                    #---------------------------------------------------------
                }
            }
        }
    }

    # Let Export handle everything else as usual:
    $package->export_to_level(1, @export_args);

    # Restore coderefs in the original package with their saved version:
    #
    while (my ($symbol, $coderef) = each %their_original_coderefs) {
        no strict 'refs';
        no warnings 'redefine';
        no warnings 'prototype';
        *$symbol = $coderef;
    }
}

#pod =head1 CAVEATS
#pod
#pod This module uses L<B::CallChecker> and L<B::Generate> under the covers
#pod to optimize away the exported subroutines.  Loading one or the other
#pod of those modules can potentially break test coverage metrics generated
#pod by L<Devel::Cover> in mysterious ways.
#pod
#pod To avoid this problem, subroutines are never optimized away
#pod if L<Devel::Cover> is in use, and are always exported as-is
#pod regardless of any C<-if> or C<-unless> conditions.  (You probably
#pod want L<Devel::Cover> to assess the coverage of your real exported
#pod subroutines in any case.)
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Exporter>
#pod
#pod L<B::CallChecker>
#pod
#pod L<B::Generate>
#pod
#pod =head1 ACKNOWLEDGEMENTS
#pod
#pod Thanks to Grant Street Group L<http://www.grantstreet.com> for funding
#pod development of this code.
#pod
#pod Thanks to Tom Christiansen (C<< <tchrist@perl.com> >>) for help with the
#pod symbol table hackery
#pod and Larry Leszczynski, C<< <larryl at cpan.org> >> for writing most of
#pod the code.
#pod
#pod Thanks to Zefram (C<< <zefram@fysh.org> >>) for the pointer to his
#pod L<Debug::Show> hackery.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Exporter::ConditionalSubs - Conditionally export subroutines

=head1 VERSION

version v1.11.1

=head1 SYNOPSIS

Allows subroutines to be conditionally exported.  If the condition
is satisfied, the subroutine will be exported as usual.  But if not,
the subroutine will be replaced with a stub that gets optimized away
by the compiler.  When stubbed out, not even the arguments to the
subroutine will get evaluated.

This allows for e.g. assertion-like behavior, where subroutine calls
can be left in the code but effectively ignored under certain conditions.

First create a module that C<ISA> L<Exporter::ConditionalSubs>:

    package My::Assertions;

    require Exporter::ConditionalSubs;
    our @ISA = qw( Exporter::ConditionalSubs );

    our @EXPORT    = ();
    our @EXPORT_OK = qw( _assert_non_empty );

    sub _assert_non_empty
    {
        carp "Found empty value" unless length(shift // '') > 0;
    }

Then, specify an C<-if> or C<-unless> condition when C<use>ing that module:

    package My::App;

    use My::Assertions qw( _assert_non_empty ), -if => $ENV{DEBUG};

    use My::MoreAssertions -unless => $ENV{RUNTIME} eq 'prod';

    # Coderefs work too:
    use My::OtherAssertions -if => sub { ... some logic ... };

    _assert_non_empty($foo);    # this subroutine call might be a no-op

This is a subclass of L<Exporter> and works just like it, with the
addition of support for the C<-if> and C<-unless> import arguments.

=head1 SUBROUTINES

=head2 import

Works like the L<Exporter> C<import()> function, except that it checks
for an optional C<-if> or C<-unless> import arg, followed by either
a boolean, or a coderef that returns true/false.

If the condition evaluates to true for C<-if>, or false for C<-unless>,
then any subs are exported as-is.  Otherwise, any subs in C<@EXPORT_OK>
are replaced with stubs that get optimized away by the compiler (with
one exception - see L</CAVEATS> below).

You can specify either C<-if> or C<-unless>, but not both.  Croaks if
both are specified, or if you specify the same option more than once.

=head1 CAVEATS

This module uses L<B::CallChecker> and L<B::Generate> under the covers
to optimize away the exported subroutines.  Loading one or the other
of those modules can potentially break test coverage metrics generated
by L<Devel::Cover> in mysterious ways.

To avoid this problem, subroutines are never optimized away
if L<Devel::Cover> is in use, and are always exported as-is
regardless of any C<-if> or C<-unless> conditions.  (You probably
want L<Devel::Cover> to assess the coverage of your real exported
subroutines in any case.)

=head1 SEE ALSO

L<Exporter>

L<B::CallChecker>

L<B::Generate>

=head1 ACKNOWLEDGEMENTS

Thanks to Grant Street Group L<http://www.grantstreet.com> for funding
development of this code.

Thanks to Tom Christiansen (C<< <tchrist@perl.com> >>) for help with the
symbol table hackery
and Larry Leszczynski, C<< <larryl at cpan.org> >> for writing most of
the code.

Thanks to Zefram (C<< <zefram@fysh.org> >>) for the pointer to his
L<Debug::Show> hackery.

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 - 2020 by Grant Street Group.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
