package Exporter::ConditionalSubs;

use strict;
use warnings;

require Exporter;
our @ISA = qw( Exporter );

#------------------------------------------------------------
#
# This section lifted directly from Debug::Show v0.0
#
# https://metacpan.org/pod/Debug::Show
#
# Thanks to Zefram
#
use B::CallChecker qw( cv_set_call_checker );
BEGIN {
    # B::Generate provides a broken version of B::COP->warnings, which
    # makes B::Deparse barf [rt.cpan.org #70396], and of B::SVOP->sv,
    # which makes B::Concise emit rubbish [rt.cpan.org #70398].
    # This works around it by restoring the non-broken versions,
    # provided that B::Generate hasn't already been loaded.  If it
    # was loaded by someone else, better hope they worked around it
    # the same way.
    require B;
    my $cop_warnings = \&B::COP::warnings;
    my $svop_sv = \&B::SVOP::sv;
    require B::Generate;
    no warnings "redefine";
    *B::COP::warnings = $cop_warnings;
    *B::SVOP::sv = $svop_sv;
    B::Generate->VERSION(1.33);
}
#------------------------------------------------------------

use Carp qw( croak );

=head1 NAME

Exporter::ConditionalSubs - Conditionally export subroutines

=head1 VERSION

Version 1.01

=cut

our $VERSION = '1.01';

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
are replaced with stubs that get optimized away by the compiler.

You can specify either C<-if> or C<-unless>, but not both.  Croaks if
both are specified, or if you specify the same option more than once.

=cut

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
                    cv_set_call_checker(\&$symbol, sub ($$$) {
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
                    }, \!1);
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

=head1 SEE ALSO

L<Exporter>

L<B::CallChecker>

L<B::Generate>

=head1 AUTHOR

Larry Leszczynski, C<< <larryl at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests at:
L<https://github.com/GrantStreetGroup/Exporter-ConditionalSubs>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Exporter::ConditionalSubs

You can also look for information at:

=over 4

=item * GitHub

L<https://github.com/GrantStreetGroup/Exporter-ConditionalSubs>

=item * MetaCPAN

L<https://metacpan.org/pod/Exporter::ConditionalSubs>

=item * AnnoCPAN, Annotated CPAN documentation

L<http://annocpan.org/dist/Exporter-ConditionalSubs>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Exporter-ConditionalSubs>

=back

=head1 AUTHOR

Larry Leszczynski, C<< <larryl at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

Thanks to Grant Street Group L<http://www.grantstreet.com> for funding
development of this code.

Thanks to Tom Christiansen (C<< <tchrist@perl.com> >>) for help with the
symbol table hackery.

Thanks to Zefram (C<< <zefram@fysh.org> >>) for the pointer to his
L<Debug::Show> hackery.

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Grant Street Group

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;

