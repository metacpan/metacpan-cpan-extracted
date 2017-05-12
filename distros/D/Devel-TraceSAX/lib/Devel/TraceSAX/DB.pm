package Devel::TraceSAX::DB;

use strict;
use Devel::TraceCalls qw( trace_calls );
use XML::SAX::EventMethodMaker qw( sax_event_names );
use UNIVERSAL;

sub debugging() { 0 }

##
## WARNING: UGLY CODE AHEAD. I'm still debugging this.
##

## Note that we ignore some common words in methods.
my @scan_methods = grep !/set_handler|warning|error|parse/, sort @Devel::TraceSAX::methods;
my $methods = join "|", map quotemeta, @scan_methods;
$methods = qr/^(?:$methods)(?!\n)$/;

my $depth = -1;

sub _find_packages {
    my ( $name, $namespace ) = @_;

    ## Avoid scanning a few often used packages for efficiency's sake
    return ()
        if $name =~ m{^(
            [a-z0-9_]+       ## pragmas
            |Devel
            |UNIVERSAL
            |Regexp
            |Exporter
            |AutoLoader
            |DynaLoader
            |SelfLoader
            |XSLoader
            |IO
            |Carp
            |CORE
            |DB
            |Data::Dumper
            |Symbol
            |File::Spec
        )($|::)}x;

    ++$depth if debugging;
    warn "  " x $depth, "Scanning $name\n" if debugging;

    my $found;
    my @pkgs;
    warn "  " x $depth, join( ", ", keys %$namespace ), "\n" if debugging;
    for ( keys %$namespace ) {
    warn "  " x $depth, "...$name$_\n" if debugging;
        if ( /::$/ ) {
            next if $_ =~ /^[a-z0-9_]+::$/; ## Ignore main:: & pragmas
            no strict "refs";
            push @pkgs, _find_packages( $name.$_, \%{$name.$_} );
        }
        elsif ( ! $found && $_ =~ $methods ) {
            warn " " x $depth, "MATCH ${name}::$_\n" if debugging;
            $found = 1;
        }
    }

    $found ||= grep UNIVERSAL::can( $name, $_ ), @scan_methods;

    if ( $found ) {
        warn " " x $depth, "FOUND $name\n" if debugging;
        push @pkgs, $name;
        $pkgs[-1] =~ s/::$//;
    }
    else {
        warn " " x $depth, "missed $name\n" if debugging;
    }

    warn " " x $depth, "pkgs = (", join( ", ", @pkgs ), ")\n" if debugging;

    --$depth if debugging;
    return @pkgs;
}

##
## -d:TraceSAX and -MDevel::TraceSAX support
##
my $always_dump;


sub DB::DB {
    ## Do nothing.
}

##
## Scan all loaded packages
##
my @pkgs = _find_packages( "", \%main:: );
#warn "Checking: ", join( ", ", @pkgs ), "\n" if @pkgs;

trace_calls map {
    Class        => $_,
    Subs         => \@Devel::TraceSAX::methods,
    LogFormatter => \&Devel::TraceSAX::log_formatter,
}, @pkgs;

sub parse_d_colon_import_args {
}

##
## Intercept future package loads.
##
## TODO: This will miss any classes that aren't under the loaded class'
## namespace.  We may want to rescan the entire namespace each load
## as an option.
##
use vars qw( %in_process );

*CORE::GLOBAL::require = sub (*) {
    package Devel::TraceSAX::DB;
    my $what = @_ ? shift : $_;

    ++$depth if debugging;
    warn " " x $depth, "require $what\n" if debugging;

    if ( $in_process{$what} ) {
        --$depth if debugging;
        warn " " x $depth, "...not really (already requiring it)" if debugging;
        return undef;
    }
    $in_process{$what} = 1;
    Devel::TraceCalls::hide_package;

    my $r;
    eval {
        if ( $what =~ /^[\d.]+$/ ) {
            ## pass through version numbers
            $r = eval "CORE::require $what; 1" or die $@;
        }
        elsif ( $what =~ /^[\w:]+(?!\n)$/ ) {
            ## A module?
            $r = eval "CORE::require $what; 1" or die $@;
            my @pkgs = do {
                no strict "refs";
                _find_packages( $what, \%{"${what}::"} );
            };

            trace_calls map {
                Class        => $_,
                Subs         => \@Devel::TraceSAX::methods,
                LogFormatter => \&Devel::TraceSAX::log_formatter,
            }, @pkgs if @pkgs;
        }
        elsif ( $what !~ /^[^[:print:]]/ ) {
            ## pass through file names.  should maybe take a look
            ## and see if the file name declared any new packages.
            $r = eval "CORE::require '$what'; 1" or die $@;
        }
        else {
            $r = CORE::require $what ;
        }
    };
    my $x = $@;

    Devel::TraceCalls::unhide_package;

    delete $in_process{$what};
    --$depth if debugging;

    die $x if $x;
    return $r;
};

1;
