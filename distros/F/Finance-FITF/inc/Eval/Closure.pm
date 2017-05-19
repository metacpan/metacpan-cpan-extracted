#line 1
package Eval::Closure;
BEGIN {
  $Eval::Closure::VERSION = '0.06';
}
use strict;
use warnings;
use Sub::Exporter -setup => {
    exports => [qw(eval_closure)],
    groups  => { default => [qw(eval_closure)] },
};
# ABSTRACT: safely and cleanly create closures via string eval

use Carp;
use overload ();
use Scalar::Util qw(reftype);
use Try::Tiny;



sub eval_closure {
    my (%args) = @_;

    $args{source} = _canonicalize_source($args{source});
    _validate_env($args{environment} ||= {});

    $args{source} = _line_directive(@args{qw(line description)})
                  . $args{source}
        if defined $args{description} && !($^P & 0x10);

    my ($code, $e) = _clean_eval_closure(@args{qw(source environment)});

    if (!$code) {
        if ($args{terse_error}) {
            die "$e\n";
        }
        else {
            croak("Failed to compile source: $e\n\nsource:\n$args{source}")
        }
    }

    return $code;
}

sub _canonicalize_source {
    my ($source) = @_;

    if (defined($source)) {
        if (ref($source)) {
            if (reftype($source) eq 'ARRAY'
             || overload::Method($source, '@{}')) {
                return join "\n", @$source;
            }
            elsif (overload::Method($source, '""')) {
                return "$source";
            }
            else {
                croak("The 'source' parameter to eval_closure must be a "
                    . "string or array reference");
            }
        }
        else {
            return $source;
        }
    }
    else {
        croak("The 'source' parameter to eval_closure is required");
    }
}

sub _validate_env {
    my ($env) = @_;

    croak("The 'environment' parameter must be a hashref")
        unless reftype($env) eq 'HASH';

    for my $var (keys %$env) {
        croak("Environment key '$var' should start with \@, \%, or \$")
            unless $var =~ /^([\@\%\$])/;
        croak("Environment values must be references, not $env->{$var}")
            unless ref($env->{$var});
    }
}

sub _line_directive {
    my ($line, $description) = @_;

    $line = 1 unless defined($line);

    return qq{#line $line "$description"\n};
}

sub _clean_eval_closure {
     my ($source, $captures) = @_;

    my @capture_keys = sort keys %$captures;

    if ($ENV{EVAL_CLOSURE_PRINT_SOURCE}) {
        _dump_source(_make_compiler_source($source, @capture_keys));
    }

    my ($compiler, $e) = _make_compiler($source, @capture_keys);
    my $code;
    if (defined $compiler) {
        $code = $compiler->(@$captures{@capture_keys});
    }

    if (defined($code) && (!ref($code) || ref($code) ne 'CODE')) {
        $e = "The 'source' parameter must return a subroutine reference, "
           . "not $code";
        undef $code;
    }

    return ($code, $e);
}

{
    my %compiler_cache;

    sub _make_compiler {
        my $source = _make_compiler_source(@_);

        unless (exists $compiler_cache{$source}) {
            local $@;
            local $SIG{__DIE__};
            my $compiler = eval $source;
            my $e = $@;
            $compiler_cache{$source} = [ $compiler, $e ];
        }

        return @{ $compiler_cache{$source} };
    }
}

sub _make_compiler_source {
    my ($source, @capture_keys) = @_;
    my $i = 0;
    return join "\n", (
        'sub {',
        (map {
            'my ' . $_ . ' = ' . substr($_, 0, 1) . '{$_[' . $i++ . ']};'
         } @capture_keys),
        $source,
        '}',
    );
}

sub _dump_source {
    my ($source) = @_;

    my $output;
    if (try { require Perl::Tidy }) {
        Perl::Tidy::perltidy(
            source      => \$source,
            destination => \$output,
            argv        => [],
        );
    }
    else {
        $output = $source;
    }

    warn "$output\n";
}


1;

__END__
#line 322

