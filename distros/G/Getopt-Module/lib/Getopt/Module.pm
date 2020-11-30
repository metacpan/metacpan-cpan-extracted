package Getopt::Module;

use strict;
use warnings;

use vars qw($VERSION @EXPORT_OK);

use Carp qw(confess);
use Exporter qw(import);
use Scalar::Util;

# XXX this declaration must be on a single line
# https://metacpan.org/pod/version#How-to-declare()-a-dotted-decimal-version
use version; our $VERSION = version->declare('v1.0.0');

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
            confess 'invalid parameter; expected HASH or HASHREF, got ', _pp(ref($params));
        }
    } elsif ((@_ % 2) == 0) {
        $params = { @_ };
    } else {
        confess 'invalid parameters; expected hash or hashref, got odd number of arguments > 1';
    }

    my $no_import = $params->{no_import};
    my $separator = defined($params->{separator}) ? $params->{separator} : ' ';

    return sub {
        my $name = shift;
        my $value = shift;

        confess 'invalid option definition: option must target a scalar ("foo=s") or array ("foo=@")'
            unless (defined($value) && (@_ == 0));
        confess sprintf('invalid value for %s option: %s', $name, _pp($value))
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
        } elsif ($no_import) {
            $eval = "$statement $module ();";
        } else {
            $eval = "$statement $module;";
        }

        my $parsed = {
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
            $target->($name, $eval, $parsed);
        } else {
            confess 'invalid target type - expected array ref, code ref, hash ref or scalar ref, got: ', ref($target);
        }

        return $parsed; # ignored by Getopt::Long, but useful for testing
    };
}

1;
