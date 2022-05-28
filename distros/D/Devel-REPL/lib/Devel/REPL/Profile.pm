package Devel::REPL::Profile;
# ABSTRACT: Code to execute when re.pl starts

our $VERSION = '1.003029';

use Moose::Role;
requires 'apply_profile';
use namespace::autoclean;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::REPL::Profile - Code to execute when re.pl starts

=head1 VERSION

version 1.003029

=head1 SYNOPSIS

 package Devel::REPL::Profile::MyProject;

 use Moose;
 use namespace::autoclean;

 with 'Devel::REPL::Profile';

 sub apply_profile {
     my ($self, $repl) = @_;
     # do something here
 }

 1;

=head1 DESCRIPTION

For particular projects you might well end up running the same commands each
time the REPL shell starts up - loading Perl modules, setting configuration,
and so on.

A mechanism called I<profiles> exists to let you package and distribute these
start-up scripts, as Perl modules.

=head1 USAGE

Quite simply, follow the L</"SYNOPSIS"> section above to create a boilerplate
profile module. Within the C<apply_profile> method, the C<$repl> variable can
be used to run any commands as the user would, within the context of their
running C<Devel::REPL> shell instance.

For example, to load a module, you might have something like this:

 sub apply_profile {
     my ($self, $repl) = @_;
     $repl->eval('use Carp');
 }

As you can see, the C<eval> method is used to run any code. The user won't see
any output from that, and the code can "safely" die without destroying the
REPL shell. The return value of C<eval> will be the return value of the code
you gave, or else if it died then a C<Devel::REPL::Error> object is returned.

If you want to load a C<Devel::REPL> plugin, then use the following method:

 $repl->load_plugin('Timing');

The C<load_plugin> and C<eval> methods should cover most of what you would
want to do before the user has access to the shell. Remember that plugin
features are immediately available, so you can load for example the C<LexEnv>
plugin, and then declare C<my> variables which the user will have access to.

=head2 Selecting a Profile

To run the shell with a particular profile, use the following command:

 system$ re.pl --profile MyProject

Alternatively, you can set the environment variable C<DEVEL_REPL_PROFILE> to
MyProject.

When the profile name is unqualified, as in the above example, the profile is
assumed to be in the C<Devel::REPL::Profile::> namespace. Otherwise if you
pass something which contains the C<::> character sequence, it will be loaded
as-is.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-REPL>
(or L<bug-Devel-REPL@rt.cpan.org|mailto:bug-Devel-REPL@rt.cpan.org>).

There is also an irc channel available for users of this distribution, at
L<C<#devel> on C<irc.perl.org>|irc://irc.perl.org/#devel-repl>.

=head1 AUTHOR

Matt S Trout - mst (at) shadowcatsystems.co.uk (L<http://www.shadowcatsystems.co.uk/>)

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2007 by Matt S Trout - mst (at) shadowcatsystems.co.uk (L<http://www.shadowcatsystems.co.uk/>).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
