package Getopt::Module;

use strict;
use warnings;

use vars qw($VERSION @EXPORT_OK);

use Carp qw(confess);
use Exporter qw(import);
use Scalar::Util;

$VERSION   = '0.0.2';
@EXPORT_OK = qw(GetModule);

my $MODULE_RE = qr{
    ^                 # match the beginning of the string
    (-)?              # optional: leading hyphen: use 'no' instead of 'use'
    (\w+(?:::\w+)*)   # required: Module::Name
    (?:(=|\s+) (.+))? # optional: args prefixed by '=' e.g. 'Module=arg1,arg2' or \s+ e.g. 'Module qw(foo bar)'
    $                 # match the end of the string
}x;

# return true if $ref ISA $class - works with non-references, unblessed references and objects
sub _isa($$) {
    my ($ref, $class) = @_;
    return Scalar::Util::blessed(ref) ? $ref->isa($class) : ref($ref) eq $class;
}

# dump value like Data::Dump/Data::Dumper::Concise
sub _pp($) {
    my $value = shift;
    require Data::Dumper;
    local $Data::Dumper::Deepcopy = 1;
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Purity = 0;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Useqq = 1;
    return Data::Dumper::Dumper($value);
}

sub GetModule($@) {
    my $target = shift;
    my $params;

    if (@_ == 1) {
        $params = shift;

        unless (_isa($params, 'HASH')) {
            confess "invalid parameter; expected HASH or HASHREF, got ", _pp(ref($params));
        }
    } elsif ((@_ % 2) == 0) {
        $params = { @_ };
    } else {
        confess "invalid parameters; expected hash or hashref, got odd number of arguments > 1";
    }

    my $no_import = $params->{no_import};
    my $separator = defined($params->{separator}) ? $params->{separator} : ' ';

    return sub {
        my $name = shift;
        my $value = shift;

        confess 'invalid option definition: option must target a scalar ("foo=s") or array ("foo=@")'
            unless (defined($value) && (@_ == 0));
        confess sprintf("invalid value for %s option: %s", $name, _pp($value))
            unless ($value =~ $MODULE_RE);

        my ($hyphen, $module, $args_start, $args) = ($1, $2, $3, $4);
        my ($statement, $method, $eval);

        if ($hyphen) {
            $statement = 'no';
            $method = 'unimport';
        } else {
            $statement = 'use';
            $method = 'import';
        }

        if ($args_start) { # this takes precedence over no_import - see perlrun
            $args = '' unless (defined $args);

            if ($args_start eq '=') {
                $eval = "$statement $module split(/,/,q\0$args\0);"; # see perl.c
            } else { # space: arbitrary expression
                $eval = "$statement $module $args;";
            }
        } else {
            if ($no_import) {
                $eval = "$statement $module ();";
            } else {
                $eval = "$statement $module;";
            }
        }

        my $spec = {
            args      => $args,
            eval      => $eval,
            method    => $method,
            module    => $module,
            name      => $name,
            statement => $statement,
            value     => $value,
        };

        if (_isa($target, 'ARRAY')) {
            push @$target, $eval;
        } elsif (_isa($target, 'SCALAR')) { # SCALAR ref
            if (defined($$target) && length($$target)) {
                $$target .= "$separator$eval";
            } else {
                $$target = $eval;
            }
        } elsif (_isa($target, 'HASH')) {
            $target->{$module} ||= [];
            push @{ $target->{$module} }, $eval;
        } elsif (_isa($target, 'CODE')) {
            $target->($name, $eval, $spec);
        } else {
            confess "invalid target type - expected array ref, code ref, hash ref or scalar ref, got: ", ref($target);
        }

        return $spec; # ignored by Getopt::Long, but useful for testing
    };
}

1;

__END__

=head1 NAME

Getopt::Module - handle -M and -m options like perl

=head1 SYNOPSIS

    use Getopt::Long;
    use Getopt::Module qw(GetModule);

    my ($modules, $eval);

    GetOptions(
        'M|module=s' => GetModule(\$modules),
        'm=s'        => GetModule(\$modules, no_import => 1),
        'e|eval=s'   => \$eval,
    );

    my $sub = eval "sub { $modules $eval }";

=cut

=pod

    command -Mautobox::Core -MBar=baz,quux -e '$_->split(...)->map(...)->join(...)'

=head1 DESCRIPTION

This module provides a convenient way for command-line Perl scripts to handle C<-M>
and C<-m> options in the same way as perl.

=head1 EXPORTS

None by default.

=head2 GetModule

B<Signature>: (ArrayRef | CodeRef | HashRef | ScalarRef [, Hash | HashRef ]) -> CodeRef

    my $sub = GetModule($target, %options);

Takes a target and an optional hash or hashref of L<options|/"OPTIONS"> and returns a subroutine that can be used
to handle a L<Getopt::Long> option. The option's value is parsed and its components (module name,
import type and parameters) are assigned to the target in the following ways.

=head3 TARGETS

=head4 ScalarRef

C<eval>able C<use>/C<no> statements are appended to the referenced scalar, separated by the L<"separator"> option.
If no separator is supplied, it defaults to a single space (" ") e.g.:

Command:

    command -MFoo=bar -M-Baz=quux

Usage:

    my $statements;

    GetOptions(
        'M|module=s' => GetModule(\$statements),
    );

Result (C<$statements>):

    "use Foo qw(bar); no Baz qw(quux);"

=head4 ArrayRef

The C<use>/C<no> statement is pushed onto the arrayref e.g.:

Command:

    command -MFoo=bar,baz -M-Quux

Usage:

    my $modules = [];

    GetOptions(
        'M|module=s' => GetModule($modules),
    );

Result (C<$modules>):

    [ "use Foo qw(bar baz);", "no Quux;" ]

=head4 HashRef

Pushes the statement onto the arrayref pointed to by C<$hash-E<gt>{ $module_name }>, creating it if it doesn't exist. e.g.:

Command:

    command -MFoo=bar -M-Foo=baz -MQuux

Usage:

    my $modules = {};

    GetOptions(
        'M|module=s' => GetModule($modules);
    );

Result (C<$modules>):

    {
        Foo  => [ "use Foo qw(bar);", "no Foo qw(baz);" ],
        Quux => [ "use Quux;" ],
    }

=head4 CodeRef

The coderef is passed 3 parameters:

=over

=item * name

The name of the L<Getopt::Long> option e.g. C<M>.

=item * eval

The option's value as a C<use> or C<no> statement e.g: "use Foo qw(bar baz);".

=item * spec

A hashref that makes the various components of the option available e.g.:

Command:

    command -MFoo=bar,baz

Usage:

    sub process_module { ... }

    GetOptions(
        'M|module=s' => GetModule(\&process_module);
    );

The following hashref would be passed as the third argument to the C<process_module> sub:

    {
        args      => 'bar,baz',              # the supplied import/unimport args; undef if none are supplied
        eval      => 'use Foo qw(bar baz);', # the evalable statement representing the option's value
        method    => 'import',               # the method call represented by the statement: either "import" or "unimport"
        module    => 'Foo'                   # the module name
        name      => 'M',                    # the Getopt::Long option name
        statement => 'use',                  # the statement type: either "use" or "no"
        value     => 'Foo=bar,baz',          # The Getopt::Long option value
    }

=back

=head3 OPTIONS

=head4 no_import

By default, if no C<import>/C<unimport> parameters are supplied e.g.:

    command -MFoo

the C<use>/C<no> statement omits the parameter list:

    use Foo;

If no parameters are supplied and C<no_import> is set to a true value, the resulting statement disables the
C<import>/C<unimport> method call by passing an empty list e.g:

    use Foo ();

This corresponds to perl's C<-m> option.

=head4 separator

The separator used to separate statements assigned to the scalar-ref target. Default: a single space (" ").

=head1 VERSION

0.0.2

=head1 SEE ALSO

=over

=item * L<Getopt::ArgvFile>

=item * L<Getopt::Long>

=item * L<perlrun>

=back

=head1 AUTHOR

chocolateboy <chocolate@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by chocolateboy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
