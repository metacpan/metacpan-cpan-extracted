#!/usr/bin/perl -c

package Exception::Warning;

=head1 NAME

Exception::Warning - Convert simple warn into real exception object

=head1 SYNOPSIS

  # Convert warn into exception and throw it immediately
  use Exception::Warning '%SIG' => 'die';
  eval { warn "Boom!"; };
  print ref $@;        # "Exception::Warning"
  print $@->warning;   # "Boom!"

  # Convert warn into exception without die
  use Exception::Warning '%SIG' => 'warn', verbosity => 4;
  warn "Boom!";   # dumps full stack trace

  # Can be used in local scope only
  use Exception::Warning;
  {
      local $SIG{__WARN__} = \&Exception::Warning::__WARN__;
      warn "Boom!";   # warn via exception
  }
  warn "Boom!";       # standard warn

  # Run Perl with verbose warnings
  $ perl -MException::Warning=%SIG,warn,verbosity=>3 script.pl

  # Run Perl which dies on first warning
  $ perl -MException::Warning=%SIG,die,verbosity=>3 script.pl

  # Run Perl which ignores any warnings
  $ perl -MException::Warning=%SIG,warn,verbosity=>0 script.pl

  # Debugging with increased verbosity
  $ perl -MException::Warning=:debug script.pl

=head1 DESCRIPTION

This class extends standard L<Exception::Base> and converts warning into
real exception object.  The warning message is stored in I<warning>
attribute.

=for readme stop

=cut

use 5.006;

use strict;
use warnings;

our $VERSION = '0.0401';


=head1 INHERITANCE

=over 2

=item *

extends L<Exception::Base>

=back

=cut

# Extend Exception::Base class
BEGIN {

=head1 CONSTANTS

=over

=item ATTRS : HashRef

Declaration of class attributes as reference to hash.

See L<Exception::Base> for details.

=back

=head1 ATTRIBUTES

This class provides new attributes.  See L<Exception::Base> for other
descriptions.

=over

=cut

    my %ATTRS = ();
    my @ATTRS_RO = ();

=item warning : Str {ro}

Contains the message which is set by C<$SIG{__WARN__}> hook.

=cut

    push @ATTRS_RO, 'warning';

=item message : Str = "Unknown warning"

Contains the message of the exception.  This class overrides the default value
from L<Exception::Base> class.

=cut

    $ATTRS{message} = 'Unknown warning';

=item string_attributes : ArrayRef[Str] = ["message", "warning"]

Meta-attribute contains the format of string representation of exception
object.  This class overrides the default value from L<Exception::Base>
class.

=cut

    $ATTRS{string_attributes} = [ 'message', 'warning' ];

=item default_attribute : Str = "warning"

Meta-attribute contains the name of the default attribute.  This class
overrides the default value from L<Exception::Base> class.

=back

=cut

    $ATTRS{default_attribute} = 'warning';

    use Exception::Base 0.21;
    Exception::Base->import(
        'Exception::Warning' => {
            has   => { ro => \@ATTRS_RO },
            %ATTRS,
        },
        '+ignore_package' => [ 'Carp' ],
    );
};


## no critic qw(RequireArgUnpacking)
## no critic qw(RequireCarping)

=head1 IMPORTS

=over

=item use Exception::Warning '%SIG';

=item use Exception::Warning '%SIG' => 'warn';

Changes C<$SIG{__WARN__}> hook to C<Exception::Warning::__WARN__>.

=item use Exception::Warning '%SIG' => 'die';

Changes C<$SIG{__WARN__}> hook to C<Exception::Warning::__DIE__> function.

=item use Exception::Warning ':debug';

Changes C<$SIG{__WARN__}> hook to C<Exception::Warning::__WARN__> and sets
verbosity level to 4 (maximum).

=cut

sub import {
    my ($pkg, @args) = @_;

    my @params;

    while (defined $args[0]) {
        my $name = shift @args;
        if ($name eq ':debug') {
            $name = '%SIG';
            @args = ('warn', 'verbosity', 4, @args);
        };
        if ($name eq '%SIG') {
            my $type = 'warn';
            if (defined $args[0] and $args[0] =~ /^(die|warn)$/) {
                $type = shift @args;
            };
            # Handle warn hook
            if ($type eq 'warn') {
                # is 'warn'
                ## no critic qw(RequireLocalizedPunctuationVars)
                $SIG{__WARN__} = \&__WARN__;
            }
            else {
                # must be 'die'
                ## no critic qw(RequireLocalizedPunctuationVars)
                $SIG{__WARN__} = \&__DIE__;
            };
        }
        else {
            # Other parameters goes to SUPER::import
            push @params, $name;
            push @params, shift @args if defined $args[0] and ref $args[0] eq 'HASH';
        };
    };

    if (@params) {
        return $pkg->SUPER::import(@params);
    };

    return 1;
};


=item no Exception::Warning '%SIG';

Undefines C<$SIG{__DIE__}> hook.

=back

=cut

sub unimport {
    my $pkg = shift;

    while (my $name = shift @_) {
        if ($name eq '%SIG') {
            # Undef die hook
            ## no critic qw(RequireLocalizedPunctuationVars)
            $SIG{__WARN__} = '';
        };
    };

    return 1;
};


# Warning hook with die
sub __DIE__ {
    if (not ref $_[0]) {
        # Do not recurse on Exception::Died & Exception::Warning
        die $_[0] if $_[0] =~ /^Exception::(Died|Warning): /;

        # Simple warn: recover warning message
        my $message = $_[0];
        $message =~ s/\t\.\.\.caught at (?!.*\bat\b.*).* line \d+( thread \d+)?\.\n?$//s;
        while ($message =~ s/\t\.\.\.propagated at (?!.*\bat\b.*).* line \d+( thread \d+)?\.\n$//s) { };
        $message =~ s/( at (?!.*\bat\b.*).* line \d+( thread \d+)?\.)?\n$//s;

        my $e = __PACKAGE__->new;
        $e->{warning} = $message;
        die $e;
    }
    # Otherwise: throw unchanged exception
    die $_[0];
};


# Warning hook with warn
sub __WARN__ {
    if (not ref $_[0]) {
        # Some optimalization
        return if __PACKAGE__->ATTRS->{verbosity}->{default} == 0;

        # Simple warn: recover warning message
        my $message = $_[0];
        $message =~ s/\t\.\.\.caught at (?!.*\bat\b.*).* line \d+( thread \d+)?\.$//s;
        while ($message =~ s/\t\.\.\.propagated at (?!.*\bat\b.*).* line \d+( thread \d+)?\.\n$//s) { };
        $message =~ s/( at (?!.*\bat\b.*).* line \d+( thread \d+)?\.)?\n$//s;

        my $e = __PACKAGE__->new;
        $e->{warning} = $message;
        warn $e;
    }
    else {
        # Otherwise: throw unchanged exception
        warn $_[0];
    };
    return;
};


1;


=begin umlwiki

= Class Diagram =

[                         <<exception>>
                        Exception::Warning
 --------------------------------------------------------------
 +message : Str = "Unknown warning"
 +warning : Str {ro}
 #default_attribute : Str = "warning"
 #string_attributes : ArrayRef[Str] = ["message", "warning"]
 --------------------------------------------------------------
 <<utility>> -__DIE__()
 <<utility>> -__WARN__()
 <<constant>> +ATTRS() : HashRef                               ]

[Exception::Warning] ---|> [Exception::Base]

=end umlwiki

=head1 PERFORMANCE

The C<Exception::Warning> module can change C<$SIG{__WARN__}> hook.  It costs
a speed for simple warn operation.  It was tested against unhooked warn.

  -------------------------------------------------------
  | Module                              |         run/s |
  -------------------------------------------------------
  | undef $SIG{__WARN__}                |      276243/s |
  -------------------------------------------------------
  | $SIG{__WARN__} = sub { }            |      188215/s |
  -------------------------------------------------------
  | Exception::Warning '%SIG'           |        1997/s |
  -------------------------------------------------------
  | Exception::Warning '%SIG', verb.=>0 |       26934/s |
  -------------------------------------------------------

It means that C<Exception::Warning> is significally slower than simple warn.
It is usually used only for debugging purposes, so it shouldn't be an
important problem.

=head1 SEE ALSO

L<Exception::Base>.

=head1 BUGS

If you find the bug or want to implement new features, please report it at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Exception-Warning>

=for readme continue

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright (C) 2008, 2009 by Piotr Roszatycki <dexter@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>
