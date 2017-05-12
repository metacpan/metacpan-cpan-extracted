#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: lib/Dist/Zilla/Tester/DieHard.pm
#
#   Copyright © 2015, 2016 Van de Bugger.
#
#   This file is part of perl-Dist-Zilla-Tester-DieHard.
#
#   perl-Dist-Zilla-Tester-DieHard is free software: you can redistribute it and/or modify it under
#   the terms of the GNU General Public License as published by the Free Software Foundation,
#   either version 3 of the License, or (at your option) any later version.
#
#   perl-Dist-Zilla-Tester-DieHard is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Dist-Zilla-Tester-DieHard. If not, see <http://www.gnu.org/licenses/>.
#
#   ---------------------------------------------------------------------- copyright and license ---

#tt
#tt
#tt
#tt
#tt
#tt
#tt
#tt


#pod =for test_synopsis my ( %args, $expected_exception, $expected_messages );
#pod
#pod =head1 SYNOPSIS
#pod
#pod Use C<Dist::Zilla::Tester::DieHard> instead of C<Dist::Zilla::Tester>:
#pod
#pod     use Dist::Zilla::Tester::DieHard;   # instead of Dist::Zilla::Tester
#pod     use Test::Deep qw{ cmp_deeply };
#pod     use Test::Fatal;
#pod     use Test::More;
#pod
#pod     my $tzil = Builder->from_config( \%args );
#pod     my $ex = exception { $tzil->build(); };
#pod     is( $ex, $expected_exception, 'check status' );
#pod     cmd_deeply( $tzil->log_messages, $expected_messages, 'check log messages' );
#pod
#pod =head1 DESCRIPTION
#pod
#pod C<Dist::Zilla::Tester::DieHard> (or, for brevity just C<DieHard>) extends C<Dist::Zilla::Tester>.
#pod If C<Dist::Zilla> dies in construction, C<DieHard> catches the exception, saves the exception and
#pod C<Dist::Zilla> logger, and returns a "survivor" object.
#pod
#pod The returned survivor will fail in C<build> (or C<release>) method: it just rethrows the saved
#pod exception. However, such "delayed death" saves log messages for analysis:
#pod
#pod     my $tzil = Builder->from_config( … );
#pod         # ^ Construction never fails,
#pod         #   it always returns an object,
#pod         #   either builder or survivor.
#pod     my $ex = exception { $tzil->build(); }; # or $tzil->release();
#pod         # ^ Builder does build,
#pod         #   survivor rethrows the saved exception.
#pod     is( $ex, $expected_exception, 'check status' );
#pod     cmd_deeply( $tzil->log_messages, $expected_messages, 'check log messages' );
#pod         # ^ In *any* case we can check log messages.
#pod
#pod =head2 C<Survivor>
#pod
#pod C<Survivor> is shortened name of real class. Full class name is
#pod C<Dist::Zilla::Tester::DieHard::Survivor>.
#pod
#pod Following methods can be called on C<Survivor> object: C<clear_log_events>, C<log_events>,
#pod C<log_messages>.
#pod
#pod C<build>, C<release>
#pod methods rethrow the saved exception.
#pod
#pod =note Completeness
#pod
#pod Regular C<Dist::Zilla::Tester> (as of v5.039) is not documented, so and I have to study its sources
#pod to find out features it provides.
#pod
#pod I have implemented only part of C<Dist::Zilla::Tester> features, shown in L</"SYNOPSIS"> and
#pod L</"DESCRIPTION">. C<Minter> is not (yet?) implemented — I do not need it (yet?). Probably there
#pod are other not (yet?) implemented features I am not aware of.
#pod
#pod =note Implementation Detail
#pod
#pod Implementation is simpler if C<Survivor> saves not logger, but entire chrome (logger is a part of
#pod chrome). In such a case C<Survivor> can consume C<Dist::Zilla::Tester::_Role> and get bunch of
#pod methods "for free".
#pod
#pod =note C<most_recent_log_events> Function
#pod
#pod C<Dist::Zilla::Tester> 5.040 introduced C<most_recent_log_events> function which can be used to
#pod retrieve log events even if builder construction failed. However:
#pod
#pod =for :list
#pod 1.  This module was implemented and released before C<DIst::Zilla> 5.040.
#pod 2.  C<most_recent_log_events> is not documented.
#pod 3.  Using C<most_recent_log_events> requires revisiting existing test code, while C<DieHard> does
#pod     not.
#pod
#pod =cut

# --------------------------------------------------------------------------------------------------

package Dist::Zilla::Tester::DieHard;

use Moose;

# ABSTRACT: Die hard Dist::Zilla, but save the messages
our $VERSION = 'v0.6.4'; # VERSION
our $CLASS = __PACKAGE__;

extends 'Dist::Zilla::Tester';

#   Mimic the `Dist::Zilla::Tester` export.
use Sub::Exporter -setup => {
    exports => [
        Builder => sub { $_[ 0 ]->can( 'builder' ) },
    ],
    groups => [ default => [ qw{ Builder } ] ],
};

#pod =for Pod::Coverage builder
#pod
#pod =cut

sub builder {
    return $CLASS . '::Builder';
};

no Moose;

$CLASS->meta->make_immutable;

# --------------------------------------------------------------------------------------------------

{

package Dist::Zilla::Tester::DieHard::Builder;          ## no critic ( ProhibitMultiplePackages )

use Moose;
use namespace::autoclean;

## no critic ( ProhibitReusedNames )
our $VERSION = 'v0.6.4'; # VERSION
our $CLASS = __PACKAGE__;
## critic ( ProhibitReusedNames )

extends join( '::', qw{ Dist Zilla Tester _Builder } );
    # ^ Hide `Dist::Zilla::Tester::_Builder` from `AutoPrereqs`. If `…::_Builder` is added to
    #   prerequisities, `cpanm` starts downloading, testing and installing `Dist::Zilla`
    #   ignoring the fact that `Dist::Zilla` is already installed.

use Dist::Zilla::Chrome::Test;
use Try::Tiny;

our $Chrome;                            ## no critic ( ProhibitPackageVars )

around from_config => sub {
    my ( $orig, $self, @args ) = @_;
    local $Chrome;                      ## no critic ( RequireInitializationForLocalVars )
    my $builder;
    try {
        #   Try to create original `Dist::Zilla::Tester::_Builder` first.
        $builder = $self->$orig( @args );
    } catch {
        my $ex = $_;
        #   If an exception occurs before builder construction (i. e. in
        #   `Dist::Zilla::Tester::_Builder`'s `around from_config`), `$Chrome` will be undefined.
        #   Let's crate a new chrome object.
        if ( not defined( $Chrome ) ) {
            $Chrome = Dist::Zilla::Chrome::Test->new();
        };
        #   If creation failed due to exception, create stub object instead.
        $builder = Dist::Zilla::Tester::DieHard::Survivor->new(
            exception => $ex,       # Survivor object saves exception
            chrome    => $Chrome,   # and chrome.
        );
    };
    return $builder;
};

#   Saving builder's chrome is not trivial. `from_config` is a class method. Before
#   `$self->$orig()` call the builder does not exist yet, after call the builder does not exist
#   already. I need to catch the moment when the builder is already born but not yet died.
#   `BUILDARGS` method is called just before builder creation, so I can steal chrome from builder
#   constructor arguments.
#
#   To pass information (chrome reference) between object method `BUILDARGS` and class method
#   `from_config` I have to use global (class) variable.

around BUILDARGS => sub {
    my ( $orig, $self, @args ) = @_;
    $Chrome = $args[ 0 ]->{ chrome };
    return $self->$orig( @args );
};

$CLASS->meta->make_immutable;

};

# --------------------------------------------------------------------------------------------------

{

#   This is "survivor", which substitutes builder when its creation fails.

package Dist::Zilla::Tester::DieHard::Survivor;         ## no critic ( ProhibitMultiplePackages )

use Moose;
use namespace::autoclean;

with join( '::', qw{ Dist Zilla Tester _Role } );       # Hide from `AutoPrereqs`.

## no critic ( ProhibitReusedNames )
our $VERSION = 'v0.6.4'; # VERSION
our $CLASS = __PACKAGE__;
## critic ( ProhibitReusedNames )

has chrome => (
    isa         => 'Object',
    is          => 'ro',
);

has exception => (              # Survivor stores the exception killed the buider
    is          => 'ro',
    required    => 1,
);

my $rethrow = sub {
    my ( $self ) = @_;
    die $self->exception;               ## no critic ( RequireCarping )
};

#   Survivor mimics builder to some extent. I need only few methods:
for my $method ( qw{ build release } ) {
    no strict 'refs';                   ## no critic ( ProhibitNoStrict )
    *{ $method } = $rethrow;
};

$CLASS->meta->make_immutable;

}

# --------------------------------------------------------------------------------------------------

1;

# --------------------------------------------------------------------------------------------------

#pod =head1 COPYRIGHT AND LICENSE
#pod
#pod Copyright (C) 2015, 2016 Van de Bugger
#pod
#pod License GPLv3+: The GNU General Public License version 3 or later
#pod <http://www.gnu.org/licenses/gpl-3.0.txt>.
#pod
#pod This is free software: you are free to change and redistribute it. There is
#pod NO WARRANTY, to the extent permitted by law.
#pod
#pod
#pod =cut

#   ------------------------------------------------------------------------------------------------
#
#   file: doc/what.pod
#
#   This file is part of perl-Dist-Zilla-Tester-DieHard.
#
#   ------------------------------------------------------------------------------------------------

#pod =encoding UTF-8
#pod
#pod =head1 WHAT?
#pod
#pod C<Dist-Zilla-Tester-DieHard> (or shortly C<DieHard>) is a C<Dist::Zilla> testing tool, it extends standard
#pod C<Dist::Zilla::Tester>. If C<Dist::Zilla> dies in construction, C<DieHard> survives itself and
#pod saves the logger to let you analyze the messages.
#pod
#pod =cut

# end of file #
#   ------------------------------------------------------------------------------------------------
#
#   file: doc/why.pod
#
#   This file is part of perl-Dist-Zilla-Tester-DieHard.
#
#   ------------------------------------------------------------------------------------------------

#pod =encoding UTF-8
#pod
#pod =head1 WHY?
#pod
#pod Usually I test my C<Dist::Zilla> plugins in such a way:
#pod
#pod     ...
#pod     use Dist::Zilla::Tester;
#pod     use Test::Deep qw{ cmp_deeply };
#pod     use Test::Fatal;
#pod     use Test::More;
#pod
#pod     my $tzil = Builder->from_config( ... );
#pod     my $exception = exception { $tzil->build(); };
#pod     if ( $expected_success ) {
#pod         is( $exception, undef, 'status' );
#pod     } else {
#pod         like( $exception, qr{...}, 'status' );
#pod     };
#pod     cmd_deeply( $tzil->log_messages, $expected_messages, 'log messages' );
#pod     ...
#pod
#pod The approach works well, until C<Dist::Zilla> dies in C<from_config> (e. g. if a plugin throws an
#pod exception in its construction).
#pod
#pod A straightforward attempt to catch exception thrown in C<from_config>:
#pod
#pod     my $tzil;
#pod     my $exception = exception { $tzil = Builder->from_config( … ); };
#pod     if ( $expected_success ) {
#pod         is( $exception, undef, 'status' );
#pod     } else {
#pod         like( $exception, qr{…}, 'status' );
#pod     };
#pod
#pod works but… C<from_config> dies leaving C<$tzil> undefined, C<log_messages> method is called on
#pod undefined value definitely fails:
#pod
#pod     cmd_deeply( $tzil->log_messages, $expected_messages, 'log messages' );
#pod     #           ^^^^^^^^^^^^^^^^^^^
#pod     #           Oops: $tzil undefined.
#pod
#pod C<Dist::Zilla> dies, and all the messages logged by either C<Dist::Zilla> or its plugins are buried
#pod with C<Dist::Zilla>.
#pod
#pod Using C<Dist::Zilla::Tester::DieHard> instead of regular C<Dist::Zilla::Tester> solves this
#pod problem: even if a plugin throws an exception in constructor, C<< Builder->from_config >> does not
#pod die but returns a "survivor" object which can be used to retrieve log messages.
#pod
#pod =cut

# end of file #


# end of file #

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Tester::DieHard - Die hard Dist::Zilla, but save the messages

=head1 VERSION

Version v0.6.4, released on 2016-12-18 08:53 UTC.

=head1 WHAT?

C<Dist-Zilla-Tester-DieHard> (or shortly C<DieHard>) is a C<Dist::Zilla> testing tool, it extends standard
C<Dist::Zilla::Tester>. If C<Dist::Zilla> dies in construction, C<DieHard> survives itself and
saves the logger to let you analyze the messages.

=for test_synopsis my ( %args, $expected_exception, $expected_messages );

=head1 SYNOPSIS

Use C<Dist::Zilla::Tester::DieHard> instead of C<Dist::Zilla::Tester>:

    use Dist::Zilla::Tester::DieHard;   # instead of Dist::Zilla::Tester
    use Test::Deep qw{ cmp_deeply };
    use Test::Fatal;
    use Test::More;

    my $tzil = Builder->from_config( \%args );
    my $ex = exception { $tzil->build(); };
    is( $ex, $expected_exception, 'check status' );
    cmd_deeply( $tzil->log_messages, $expected_messages, 'check log messages' );

=head1 DESCRIPTION

C<Dist::Zilla::Tester::DieHard> (or, for brevity just C<DieHard>) extends C<Dist::Zilla::Tester>.
If C<Dist::Zilla> dies in construction, C<DieHard> catches the exception, saves the exception and
C<Dist::Zilla> logger, and returns a "survivor" object.

The returned survivor will fail in C<build> (or C<release>) method: it just rethrows the saved
exception. However, such "delayed death" saves log messages for analysis:

    my $tzil = Builder->from_config( … );
        # ^ Construction never fails,
        #   it always returns an object,
        #   either builder or survivor.
    my $ex = exception { $tzil->build(); }; # or $tzil->release();
        # ^ Builder does build,
        #   survivor rethrows the saved exception.
    is( $ex, $expected_exception, 'check status' );
    cmd_deeply( $tzil->log_messages, $expected_messages, 'check log messages' );
        # ^ In *any* case we can check log messages.

=head2 C<Survivor>

C<Survivor> is shortened name of real class. Full class name is
C<Dist::Zilla::Tester::DieHard::Survivor>.

Following methods can be called on C<Survivor> object: C<clear_log_events>, C<log_events>,
C<log_messages>.

C<build>, C<release>
methods rethrow the saved exception.

=head1 NOTES

=head2 Completeness

Regular C<Dist::Zilla::Tester> (as of v5.039) is not documented, so and I have to study its sources
to find out features it provides.

I have implemented only part of C<Dist::Zilla::Tester> features, shown in L</"SYNOPSIS"> and
L</"DESCRIPTION">. C<Minter> is not (yet?) implemented — I do not need it (yet?). Probably there
are other not (yet?) implemented features I am not aware of.

=head2 Implementation Detail

Implementation is simpler if C<Survivor> saves not logger, but entire chrome (logger is a part of
chrome). In such a case C<Survivor> can consume C<Dist::Zilla::Tester::_Role> and get bunch of
methods "for free".

=head2 C<most_recent_log_events> Function

C<Dist::Zilla::Tester> 5.040 introduced C<most_recent_log_events> function which can be used to
retrieve log events even if builder construction failed. However:

=over 4

=item 1

This module was implemented and released before C<DIst::Zilla> 5.040.

=item 2

C<most_recent_log_events> is not documented.

=item 3

Using C<most_recent_log_events> requires revisiting existing test code, while C<DieHard> does not.

=back

=head1 WHY?

Usually I test my C<Dist::Zilla> plugins in such a way:

    ...
    use Dist::Zilla::Tester;
    use Test::Deep qw{ cmp_deeply };
    use Test::Fatal;
    use Test::More;

    my $tzil = Builder->from_config( ... );
    my $exception = exception { $tzil->build(); };
    if ( $expected_success ) {
        is( $exception, undef, 'status' );
    } else {
        like( $exception, qr{...}, 'status' );
    };
    cmd_deeply( $tzil->log_messages, $expected_messages, 'log messages' );
    ...

The approach works well, until C<Dist::Zilla> dies in C<from_config> (e. g. if a plugin throws an
exception in its construction).

A straightforward attempt to catch exception thrown in C<from_config>:

    my $tzil;
    my $exception = exception { $tzil = Builder->from_config( … ); };
    if ( $expected_success ) {
        is( $exception, undef, 'status' );
    } else {
        like( $exception, qr{…}, 'status' );
    };

works but… C<from_config> dies leaving C<$tzil> undefined, C<log_messages> method is called on
undefined value definitely fails:

    cmd_deeply( $tzil->log_messages, $expected_messages, 'log messages' );
    #           ^^^^^^^^^^^^^^^^^^^
    #           Oops: $tzil undefined.

C<Dist::Zilla> dies, and all the messages logged by either C<Dist::Zilla> or its plugins are buried
with C<Dist::Zilla>.

Using C<Dist::Zilla::Tester::DieHard> instead of regular C<Dist::Zilla::Tester> solves this
problem: even if a plugin throws an exception in constructor, C<< Builder->from_config >> does not
die but returns a "survivor" object which can be used to retrieve log messages.

=for Pod::Coverage builder

=head1 AUTHOR

Van de Bugger <van.de.bugger@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015, 2016 Van de Bugger

License GPLv3+: The GNU General Public License version 3 or later
<http://www.gnu.org/licenses/gpl-3.0.txt>.

This is free software: you are free to change and redistribute it. There is
NO WARRANTY, to the extent permitted by law.

=cut
