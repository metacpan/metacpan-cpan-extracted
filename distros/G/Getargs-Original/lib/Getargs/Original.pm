=head1 NAME

Getargs::Original - remember the original arguments a program was invoked
with

=head1 SYNOPSIS

In your main program:

 use Getargs::Original;

Later on somewhere else

 require Getargs::Original;
 exec @{ Getargs::Original->args };

=head1 DESCRIPTION

Common behaviour for a daemon is to re-exec itself upon receipt of a signal
(typically SIGHUP). It is also common to use modules like Getopt::Long to
parse command line arguments when the program first starts. To achieve both
of these tasks one must store the original contents of C<$0> and C<@ARGV>,
as argument processing usually removes elements from @ARGV.

B<Getargs::Original> simplifies this task by storing the contents of $0 and
@ARGV when it is first used in a program. Later on when the original
arguments are required, a singleton instance of B<Getargs::Original> can be
used to retrieve the arguments.

B<Getargs::Original> is not meant to be instantiated as an object. All of
the methods are called as class methods.

=begin testing

# damn lexical scoping in pod2test...
use vars qw|$dollar_zero @orig_argv|;

# stick a couple of things onto @ARGV
push @ARGV, qw|foo bar baz|;

# stash away our $0 and @ARGV for testing purposes
$dollar_zero = $0;
@orig_argv = @ARGV;

# use the module then clear out @ARGV
use_ok('Getargs::Original');
undef @ARGV;

# make sure that the program was stored
my $rx = qr/$dollar_zero/;
like( Getargs::Original->program, $rx, 'program name looks correct');

# make sure the args were stored
is_deeply( scalar Getargs::Original->args, \@orig_argv, 'args look correct');

=end testing

=cut

package Getargs::Original;

use strict;
use warnings;

our $VERSION = 0.001_000;

use File::Spec;

use Class::MethodMaker(
    static_list    => '_argv',
    static_get_set => [ qw|
        orig_program
        base_dir 
        resolved
    |],
);

# remember how this program was run
Getargs::Original->orig_program($0);
Getargs::Original->_argv_push($0, @ARGV);

=head1 RESOLVING THE PATH OF $0

In normal operation, the path of $0 is made absolute using
C<File::Spec-E<gt>rel2abs()>. Sometimes it is desireable for the canonical
name of the program run to be rooted in a particular directory.

Take for example a scenario where the canonical path to programs is
F</opt/foo/bin/> but F</opt/foo/> is a symlink to another filesystem which
can differ from machine to machine. When the full path to $0 is resolved,
the path will be the true filesystem and not F</opt/foo/>.

This distinction may not matter to most, but if system monitoring tools are
looking for a program to be running with a specific path then things will
break. F</opt/foo/bin/mumble.pl> is not the same as F</.d1/bin/mumble.pl>
after all.

To address this, B<Getargs::Original> provides a way to specify the base
directory used for resolution of C<$0>. By passing a directory to the
B<base_dir> method the resolved path to C<$0> will be calculated relative to
that directory.

=head1 METHODS

=head2 argv()

Returns the original value of $0 and @ARGV as a list reference in scalar
context and a list in array context.

If the B<base_dir()> method has been called then the first element of the
list returned will be a relative path rooted in the directory that
B<base_dir()> was called with. If B<base_dir()> has not been called then the
first element of the list will be the absolute path to $0.

Resolution of $0 is performed the first time that the B<argv()> method (or
the shortcuts described below) are called. As such if relative resolution is
desired then the B<base_dir()> method must be called prior to the first use
of B<argv()>, B<program()> or B<args()>.

=begin testing

# test without base dir set
Getargs::Original->resolved(0);
my $expected = File::Spec->rel2abs($0);
is( Getargs::Original->program, $expected,
    'program without base dir set is correct');

# test with base dir set    
Getargs::Original->resolved(0);
Getargs::Original->base_dir('foo');
$expected = File::Spec->catfile('foo', File::Spec->abs2rel($0, 'foo'));
is( Getargs::Original->program, $expected,
    'program with base dir set is correct');

# another base dir test (this may break on non-UNIX - have to
# see what CPAN-Testers comes up with)
Getargs::Original->resolved(0);
Getargs::Original->base_dir('/opt/foo/');
$expected = File::Spec->catfile('/opt/foo/', File::Spec->abs2rel($0, '/opt/foo/'));
is( Getargs::Original->program, $expected,
    'program with base dir set is correct');

=end testing

=cut

sub argv
{

    # if $0 has been resolved, just return the args
    return Getargs::Original->_argv if( Getargs::Original->resolved );
    
    # otherwise resolve $0 as relative or absolute
    my $program = Getargs::Original->orig_program;
    if( my $base_dir = Getargs::Original->base_dir ) {
        $program = File::Spec->catfile(
            $base_dir,
            File::Spec->abs2rel($program, $base_dir),
        );
    }
    else {
        $program = File::Spec->rel2abs($program);
    }
    
    # set the resolved value
    Getargs::Original->_argv_set(0, $program);
    
    # note that we have completed resolution
    Getargs::Original->resolved(1);
    
    # return the args
    return Getargs::Original->_argv;
    
}

=head2 program()

Returns the original value of $0.  A shortcut to saying

 $originalargs->argv->[0];

=for testing
Getargs::Original->clear_resolved;
Getargs::Original->clear_base_dir;
my $expected = File::Spec->rel2abs($0);
is( Getargs::Original->program, $expected, '$0 is correct');

=cut

sub program
{
    
    return Getargs::Original->argv->[0];
    
}

=head2 args()

Returns the original value of @ARGV.  A shortcut to saying

 my $numargs = $originalargs->_argv_count;
 $originalargs->argv->[1..$numargs]

As with B<argv()> arguments are returned as a list or list reference
depending on calling context.

=for testing
is_deeply( scalar Getargs::Original->args, \@orig_argv, 'args are correct');

=cut

sub args
{

    my $num_args = Getargs::Original->_argv_count - 1;
    my @args = Getargs::Original->_argv;
    @args = @args[1..$num_args];
    return wantarray ? @args : \@args;
    
}

=head2 base_dir()

Sets or gets the base directory used for resolution of $0. See L<"RESOLVING
THE PATH OF $0"> above for more detail. Returns the previous base directory.

=begin testing

# base dir shouldn't be defined yet
ok( ! defined Getargs::Original->base_dir, 'base dir not defined');

# set and test
Getargs::Original->base_dir('foo');
ok( defined Getargs::Original->base_dir, 'base dir is defined');
is( Getargs::Original->base_dir(), 'foo', 'base dir set to foo');

=end testing

=head2 resolved()

Sets or gets the flag indicating whether $0 has been resolved. Returns the
previous state of the flag.

Using this method as a set accessor should only be required if the B<argv()>
method or one of it's shortcuts was inadvertently called prior to the
B<base_dir()> method being called.

=begin testing

# reset state
Getargs::Original->resolved(0);
is( Getargs::Original->resolved, 0, '$0 has not been resolved');

# cause $0 to be resolved
Getargs::Original->argv;

# make sure things are now resolved
is( Getargs::Original->resolved, 1, '$0 has been resolved');

=end testing

=cut

# keep require happy
1;


__END__


=head1 AUTHOR

James FitzGibbon, E<lt>jfitz@CPAN.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2003 James FitzGibbon.  All Rights Reserved.

This module is free software; you may use it under the same terms as Perl
itself.

=cut

#
# EOF
