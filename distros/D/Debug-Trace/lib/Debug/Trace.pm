#! perl

package Debug::Trace;

use 5.00503;		# Yes!
$VERSION = '0.05';

use strict;
#use warnings;		# Such a pity we cannot use this one...

use Data::Dumper;
use Carp;

my @debug;

sub import {
    shift;
    push @debug, [ scalar caller, @_ ];
}

# Fully qualify package names.
sub _q {
    my($name, $pkg) = @_;

    $name =~ /::/ ? $name : $pkg . "::" . $name;
}

# Nicely formatted argument values closure.
sub _mkv {
    my $config = shift;

    return sub {
	local $Data::Dumper::Indent    = $config->{ indent };
	local $Data::Dumper::Useqq     = $config->{ useqq };
	local $Data::Dumper::Maxdepth  = $config->{ maxdepth };
	local $Data::Dumper::Quotekeys = $config->{ quotekeys };
	local $Data::Dumper::Sortkeys  = $config->{ sortkeys };
	my $args = Data::Dumper->Dump([shift]);
	$args = $1 if $args =~ /\[(.*)\];/s;
	$args;
    };
}

# create appropriate output closure
sub _mkout {
    my $config = shift;

    my $trunc;
    if ( my $maxlen = $config->{maxlen} ) {
	$trunc = sub {
	    if ( length($_[0]) > $maxlen ) {
		return substr($_[0], 0, $maxlen - 3) . "...\n";
	    }
	    else {
		return $_[0];
	    }
	};
    }

    if ( $config->{'warn'} ) {
	return sub {
	    warn $trunc ? $trunc->(join("", @_)) : @_;
	};
    }
    else {
	return sub {
	    print STDERR $trunc ? $trunc->(join("", @_)) : @_;
	};
    }
}

# create appropriate "TRACE: called..." closure
sub _mkpre {
    my($config, $out) = @_;

    my $st = $config->{ stacktrace };
    if ( $config->{'caller'} ) {
	return sub {
	    my($pkg, $file, $line) = caller(1);
	    my(undef, undef, undef, $sub) = caller(2);
	    if ( $st ) {
		local $Carp::CarpLevel = 1;
		my $msg = Carp::longmess;
		$msg =~ s/^ at .*\n//;
		$msg =~ s/ called at .*?Trace\.pm line \d+\n\tDebug::Trace::__ANON__//g;
		$out->("TRACE:\t", @_, " called at ",
		       "$file line $line\n", $msg);
	    }
	    else {
		$out->("TRACE:\t", @_, " called at ",
		       "$file line $line ",
		       (defined $sub ? "sub $sub" : "package $pkg"),
		       "\n");
	    }
	};
    }
    else {
	return sub {
	    $out->("TRACE:\t", @_, "\n");
	};
    }
}

# Generate the closure to handle the tracing.
sub _s {
    my ($fqs, $cref, $config) = @_;

    my $out = _mkout($config);
    my $pre = _mkpre($config, $out);
    my $v = _mkv($config);

    sub {
	$pre->("$fqs(", $v->(\@_), ")");
	if ( !defined wantarray ) {
	    &$cref;
	    $out->("TRACE:\t$fqs() returned\n");
	}
	elsif ( wantarray ) {
	    my @r = &$cref;
	    $out->("TRACE:\t$fqs() returned: (", $v->(\@r), ")\n");
	    @r;
	}
	else {
	    my $r = &$cref;
	    $out->("TRACE:\t$fqs() returned: ", $v->([$r]), "\n");
	    $r;
	}
    };
}

# Better use CHECK, but this requires Perl 5.6 or later.
sub INIT {

    # configurable options
    my %config;

    _default_config(\%config);

    for my $d ( @debug ) {
	my($caller, @subs) = @$d;

	for my $s ( @subs ) {

	    # is it a config option?
	    if ( $s =~ /^:\w/ ) {
		_config_option(\%config, $s);
		next;
	    }

	    my $fqs = _q($s, $caller);
	    no strict 'refs';
	    my $cref = *{ $fqs }{CODE};
	    if ( !$cref ) {
		warn "Instrumenting unknown function $fqs\n" if $^W;
		next;
	    }
	    # no warnings 'redefine';
	    local($^W) = 0;
	    *{ $fqs } = _s($fqs, $cref, \%config);
	}
    }
}

# fill default config options
sub _default_config {
    my $config = shift;

    $config->{ 'warn' } = 1;
    $config->{ 'caller' } = 1;
    $config->{ stacktrace } = 0;
    $config->{ maxlen } = 0;

    # Data::Dumper specific options
    $config->{ indent } = 0;
    $config->{ useqq } = 1;
    $config->{ maxdepth } = 2;
    $config->{ quotekeys } = 0;
    $config->{ sortkeys } = 0;

    if ( my $e = $ENV{PERL5DEBUGTRACE} ) {
	for my $c ( split /[\s:]+(?!\()/, $e ) {
	    next unless $c;
	    _config_option($config, ":".$c);
	}
    }
}

# process one config option
sub _config_option {
    my $config = shift;
    $_ = lc(shift);

    if ( /^:no(\w+)$/ && exists $config->{$1} ) {
	$config->{$1} = 0;
    }
    elsif ( /^:(\w+)$/ && exists $config->{$1} ) {
	$config->{$1} = 1;
    }
    elsif ( /^:(\w+)\s*\((-?\d+)\)$/ && exists $config->{$1} ) {
	$config->{$1} = $2;
    }
    else {
	warn "Unrecognized Debug::Trace config option $_\n";
    }
}

1;

=head1 NAME

Debug::Trace - Perl extension to trace subroutine calls

=head1 SYNOPSIS

  perl -MDebug::Trace=foo,bar yourprogram.pl

=head1 DESCRIPTION

Debug::Trace instruments subroutines to provide tracing information
upon every call and return.

Using Debug::Trace does not require any changes to your sources. Most
often, it will be used from the command line:

  perl -MDebug::Trace=foo,bar yourprogram.pl

This will have your subroutines foo() and bar() printing call and
return information.

Subroutine names may be fully qualified to denote subroutines in other
packages than the default main::.

By default, the trace information is output using the standard warn()
function.

=head2 MODIFIERS

Modifiers can be inserted in the list of subroutines to change the
default behavior of this module. All modifiers can be used in three
ways:

=over 4

=item *

C<:>I<name> to enable a specific feature.

=item *

C<:no>I<name> to disable a specific feature.

=item *

C<:>I<name>C<(>I<value>C<)> to set a feature to a specific value. In
general, C<:>I<name> is equivalent to C<:>I<name>C<(1)>, while
C<:no>I<name> corresponds to C<:>I<name>C<(0)>.

=back

The following modifiers are recognized:

=over 4

=item :warn

Uses warn() to produce the trace output (default). C<:nowarn> Sends
trace output directly to STDERR.

=item :caller

Add basic call information to the trace message, including from where
the routine was called, and by whom. This is enabled by default.

=item :stacktrace

Add a stack trace (call history).

=item :maxlen(I<length>)

Truncate the length of the lines of trace information to I<length>
characters.

=back

The following modifiers can be used to control the way Data::Dumper
prints the values of parameters and return values. See also L<Data::Dumper>.

=over 4

=item :indent

Controls the style of indentation. It can be set to 0, 1, 2 or 3.
Style 0 spews output without any newlines, indentation, or spaces
between list items. C<:indent(0)> is the default.

=item :useqq

When enabled, uses double quotes for representing string values.
Whitespace other than space will be represented as C<[\n\t\r]>,
"unsafe" characters will be backslashed, and unprintable characters
will be output as quoted octal integers. This is the default,
use C<:nouseqq> to disable.

=item :maxdepth(I<depth>)

Can be set to a positive integer that specifies the depth beyond which
which we don't print structure contents. The default is 2, which means
one level of array/hashes in argument lists and return values is expanded.
If you use C<:nomaxdepth> or C<:maxdepth(0)>, nested structures are
fully expanded.

=item :quotekeys

Controls wether hash keys are always printed quoted. The default is
C<:noquotekeys>.

=item sortkeys

Controls whether hash keys are dumped in sorted order. The default is
C<:nosortkeys>.

=back

Modifiers apply only to the subroutines that follow in the list of
arguments.

=head1 METHODS

None, actually. Everything is handled by the module's import.

=head1 ENVIRONMENT VARIABLES

Environment variable C<PERL5DEBUGTRACE> can be used to preset initial
modifiers, e.g.:

    export PERL5DEBUGTRACE=":warn:indent(2):nomaxdepth:quotekeys"

=head1 SEE ALSO

L<Data::Dumper>, L<Carp>

=head1 AUTHOR

Jan-Pieter Cornet <jpc@cpan.org>;
Jos Boumans <kane@cpan.org>;
Johan Vromans <jv@cpan.org>;

This is an Amsterdam.pm production. See http://amsterdam.pm.org.

Current maintainer is Johan Vromans <jv@cpan.org>.

=head1 COPYRIGHT

Copyright 2002,2013 Amsterdam.pm. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
