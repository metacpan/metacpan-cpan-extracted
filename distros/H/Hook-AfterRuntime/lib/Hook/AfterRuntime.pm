package Hook::AfterRuntime;
use strict;
use warnings;
use 5.006;

use B::Hooks::Parser;
use base 'Exporter';

our $VERSION = '0.006';
our @EXPORT = qw/after_runtime/;
our @IDS;
our $HOOK_ID = 'AAAAAAAA';

sub get_id {
    my $code = shift;
    push @IDS => $code;
    return $#IDS;
}

sub run {
    my $id = shift;
    $IDS[$id]->();
}

sub after_runtime(&) {  ## no critic
    my ( $code ) = @_;
    my $id = get_id( $code );

    B::Hooks::Parser::inject(
        "; my \$__ENDRUN" . $HOOK_ID++ . " = Hook::AfterRuntime->new($id);"
    );
}

sub new {
    my $class = shift;
    my ($id) = @_;
    bless( \$id, $class );
}

sub DESTROY {
    my $self = shift;
    run( $$self );
}

1;

=head1 NAME

Hook::AfterRuntime - Run code at the end of the compiling scope's runtime.

=head1 DESCRIPTION

Useful for creating modules that need a behavior to be added when a module that
uses them completes its runtime. Like L<B::Hooks::EndOfScope> except it
triggers for run-time instead of compile-time.

An example where it might be handy:

    #!/usr/bin/perl
    use strict;
    use warnings;
    use Moose;

    ...

    # It would be nice not to need this....
    __PACKAGE__->make_immutable;

=head1 SYNOPSYS

MooseX/AutoImmute.pm

    package MooseX::AutoImmute;
    use strict;
    use warnings;
    use Hook::AfterRuntime;

    sub import {
        my $class = shift;
        my $caller = caller;
        eval "package $caller; use Moose; 1" || die $@;
        after_runtime { $caller->make_immutable }
    }

    1;

t/mytest.t

    #!/usr/bin/perl
    use strict;
    use warnings;
    use MooseX::AutoImmute;

    ....

    #EOF
    # Package is now immutable automatically

=head1 CAVEATS

It is important to understand how Hook::AfterRuntime works in order to know its
limitations. When you use a module that calls after_runtime() in its import()
method, after_runtime() will inject code directly after your import statement:

    import MooseX::AutoImmute;

becomes:

    import MooseX::AutoImmute; my $__ENDRUNXXXXXXXX = Hook::AfterRuntime->new($id);

This creates a Hook::AfterRuntime object in the current scope. This object's id
is used to reference the code provided to after_runtime() in
MooseX::AutoImmute()'s import() method. When the object falls out of scope the
DESTROY() method kicks in and calls the referenced code. This occurs at the end
of the file when 'use' is called at the package level.

=head2 EDGE CASES

=over 4

=item Loading in a scope other than package level:

If you use the 'use' directive on a level other than the package level, the
behavior will trigger when the end of the scope is reached. If that is a
subroutine then it will trigger at the end of EVERY call to that subroutine.
B<You really should not import a class using Hook::AfterRuntime outside the
package level scope.>

    package XXX;

    sub thing {
        # Happens at compile time
        use Object::Using::AfterRuntime;

        # At runtime the hook behavior triggers here!
    }

    # hook behavior has not triggered

    thing()

    # Hook behavior has triggered

    1;

=item require, and use class ();

    When require and use class () are used the import method is not called,
    thus the hook is never installed.

=item class->import

    The hook affects the code that is currently compiling. calling
    class->import happens after the compilation phase. You must wrap the
    statement in a BEGIN {} to call import manually. Failure to do this will
    result in the hook triggering in the wrong class, or not at all.

=back

=head1 USER WARNING

When you write a class that depends on this hook you should insert the
following warning into the docs:

This class uses L<Hook::AfterRuntime>, it B<MUST> be imported at the package
level at compile time. This means 'use MODULE' or 'BEGIN { require MODULE;
MODULE->import() }'. Failure to use one of these correct forms will result in a
missing hook and unpredictable behavior.

=head1 SEE ALSO

=over 4

=item B::Hooks::EndOfScope

Does almost the same thing, except it is triggered after compile-time instead
of run-time.

=back

=head1 FENNEC PROJECT

This module is part of the Fennec project. See L<Fennec> for more details.
Fennec is a project to develop an extensible and powerful testing framework.
Together the tools that make up the Fennec framework provide a potent testing
environment.

The tools provided by Fennec are also useful on their own. Sometimes a tool
created for Fennec is useful outside the creator framework. Such tools are
turned into their own projects. This is one such project.

=over 2

=item L<Fennec> - The core framework

The primary Fennec project that ties them all together.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2018 Chad Granum

Hook-AfterRuntime is free software, you can redistribute it and/or modify it
under the same terms as the Perl 5 programming language system itself.

Hook-AfterRuntime is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
