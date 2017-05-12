package Devel::REPL::Plugin::ModuleAutoLoader;
# ABSTRACT: Provide functionality to attmept to AutoLoad modules.

use strict;
use warnings;

our $VERSION = '1.0';

use Devel::REPL::Plugin;
use namespace::autoclean;

around 'execute' => sub {
    my ($orig, $_REPL, @args) = @_;

    my @command_result = $_REPL->$orig(@args);
    return @command_result
        if ref($command_result[0]) ne 'Devel::REPL::Error';

    my ($unloaded_module) = $command_result[0]->{message}
        =~ /perhaps you forgot to load "([\w:]+)"/;

    if ($unloaded_module) {
        eval "require $unloaded_module" or warn $@;
        return $_REPL->$orig(@args);
    }

    # If we didn't find a module to load, just return the Error.
    return @command_result;
};

1;

=pod

=head1 NAME

Devel::REPL::Plugin::ModuleAutoLoader - Autoloader Plugin for Devel::REPL

=head1 VERSION

Version 1.0

=head1 DESCRIPTION

Plugin for Devel::REPL that attempts automagically load modules used in a
line of code, that have yet to be loaded.

Just load this plugin either from the Devel::REPL shell, or within your repl.rc
file and it does the rest.

=head2 HIC SUNT DRACONES

While this plugin is handy for lazy developers such as myself, there is one
side effect that you should be aware of.

If the code contains a module that needs to be loaded, that statement will be
evaluated twice, this is the design of the plugin and not a bug.

So:

  $ my $foo = 1;
  1
  $ $foo++; my $DateTime->now();
  2016-07-05T14:51:50
  $ $foo
  3 # <-- Not what you'd expect!

Just something to be aware of. ;)

=head1 AUTHOR

James Ronan, C<< <james at ronanweb.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-devel-repl-plugin-moduleautoloader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-REPL-Plugin-ModuleAutoLoader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Devel::REPL::Plugin::ModuleAutoLoader


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devel-REPL-Plugin-ModuleAutoLoader>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Devel-REPL-Plugin-ModuleAutoLoader>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Devel-REPL-Plugin-ModuleAutoLoader>

=item * Search CPAN

L<http://search.cpan.org/dist/Devel-REPL-Plugin-ModuleAutoLoader/>

=back

The source code can be found on GitHub:
L<https://github.com/jamesronan/Devel-REPL-Plugin-ModuleAutoloader>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 James Ronan.

This program is released under the following license: perl_5

=cut

1; # End of Devel::REPL::Plugin::ModuleAutoLoader
