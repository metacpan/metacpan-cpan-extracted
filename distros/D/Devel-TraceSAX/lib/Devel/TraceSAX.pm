package Devel::TraceSAX;

=head1 NAME

Devel::TraceSAX - Trace SAX events

=head1 SYNOPSIS

  ## From the command line:
    perl -d:TraceSAX           script.pl
    perl -d:TraceSAX=-dump_all script.pl

  ## procedural:
    use Devel::TraceSAX;

    trace_SAX $obj1;

  ## Emitting additional messages
    use Devel::TraceSAX qw( emit_trace_SAX_message );

    emit_trace_SAX_message "this is a test";

=head1 DESCRIPTION

B<WARNING>: alpha code alert!!! This module and its API subject to change,
possibly radically :).

Traces SAX events in a program.  Works by applying Devel::TraceCalls to
a tracer on the desired classes for all known SAX event types (according to
XML::SAX::EventMethodMaker and XML::SAX::Machines).

=head2 Emitting messages if and only if Devel::TraceCalls is loaded

    use constant _tracing => defined $Devel::TraceSAX::VERSION;

    BEGIN {
        eval "use Devel::TraceCalls qw( emit_trace_SAX_message )"
            if _tracing;
    }

    emit_trace_SAX_message( "hi!" ) if _tracing;

Using the constant C<_tracing> allows expressions like

    emit_trace_SAX_message(...) if _tracing;

to be optimized away at compile time, resulting in little or no
performance penalty.

=cut

$VERSION=0.021;

@EXPORT = qw( trace_SAX emit_trace_SAX_message );
%EXPORT_TAGS = ( all => \@EXPORT_OK );

## TODO: Can't recall why this class isn't an exporter, need to try that.
@ISA = qw( Devel::TraceCalls );

use strict;
use Devel::TraceCalls qw( trace_calls );
use XML::SAX::EventMethodMaker qw( sax_event_names );
use UNIVERSAL;
use Exporter;

use vars qw( @methods );

sub empty($) { ! defined $_[0] || ! length $_[0] }

## When outputting strings, we usually use this to make invisible
## characters visible and to keep trace messages all on the same line.
## This does not put the quotation marks on the string because lots of
## things like PIs and comments don't use them.  This will yield some
## non-XMLish looking strings, but that's ok, we're going for
## readability for a perl programmer, not w3c compliance.
sub _esc {
    ## Some of these should never occur in XML.  But this isn't
    ## XML, it's SAX events and anything can happen (sometimes event
    ## legitamately, esp. with non XML data sources).
    local $_ = $_[0];
    s/\\/\\\\/g;
    s/\n/\\n/g;
    s/"/&quot;/g;
    s/([\000-\037])/sprintf "&#%02x;", $1/ge;
    return $_;
}


sub _dqify {
    local $_ = $_[0];
    s/\\/\\\\/g;
    $_ = _esc $_;
    return qq{"$_"};
}


@methods = (
    qw(
        new
        set_handler
        set_handlers
        set_aggregator
        start_manifold_document
        end_manifold_document
    ),
    sax_event_names "Handler", "ParseMethods"
);

##
## WARNING: UGLY CODE AHEAD. I'm still debugging this.
##

## Note that we ignore some common words in methods.
my @scan_methods = grep !/set_handler|warning|error|parse/, sort @methods;
my $methods = join "|", map quotemeta, @scan_methods;
$methods = qr/^(?:$methods)(?!\n)$/;

##
## -d:TraceSAX and -MDevel::TraceSAX support
##
my $always_dump;

sub import {
    my $self = shift;

    if ( ! (caller(0))[2] ) {
        require Devel::TraceSAX::DB;
        for ( @_ ) {
            if ( $_ eq "-dump_all" ) {
                $always_dump = 1;
            }
            else {
                warn "Devel::TraceSAX: unknown parameter '$_'\n";
            }
        }
        return;
    }

    my $meth = Exporter->can( "export_to_level" );
    $meth->( __PACKAGE__, 1, @_ );
}


## External API to add a SAX object instance
sub trace_SAX {
    my ( $processor, $id ) = @_;
    trace_calls {
        Objects      => [ $processor ],
        ObjectId     => $id,
        Subs         => \@methods,
        LogFormatter => \&log_formatter,
    };
}


## External API to add a SAX object instance
sub emit_trace_SAX_message {
    goto &Devel::TraceCalls::emit_trace_message;
}


sub log_formatter {
    my ( $tp, $r, $params ) = @_;

#warn Data::Dumper::Dumper( $tp, $r );

    my $short_sub_name = $r->{Name};
    $short_sub_name =~ s/.*://;

    if ( ! $always_dump
        && ( my $meth = __PACKAGE__->can( "format_$short_sub_name" ) )
    ) {
        return $meth->( @_ );
    }
    else {
        return undef;
    }

    return "FOO\n";
}


##
## Parser formatters
##
my %builtin_types = map { ( $_ => undef ) } qw(
    SCALAR
    ARRAY
    Regexp
    REF
    HASH
    CODE
);

sub _stringify_blessed_refs {
    my $s = shift;
    my $type = ref $s;

    return $s if ! $type || $type eq "Regexp" ;

    if ( $type eq "HASH" ) {
        $s = {
            map {
                ( $_  => _stringify_blessed_refs( $s->{$_} ) );
            } keys %$s
        };
    }
    elsif ( $type eq "ARRAY" ) {
        $s = [ map _stringify_blessed_refs( $_ ), @$s ];
    }
    elsif( $type eq "Regexp" ) {
        $s = "$s";
    }
    elsif ( !exists $builtin_types{$type} ) {
        ## A blessed ref...
        $s = $type;
    }

    return $s;
}


sub format_set_handler {
    my ( $tp, $r, $params ) = @_;

    return {
        Args => [
        ],
    };
}


sub format_start_element {
    my ( $tp, $r, $params ) = @_;

    return undef if @$params != 2;
    my $elt = $params->[1];
    return undef if ! defined( $elt ) || ref $elt ne "HASH";

    for ( keys %$elt ) {
        next if $_ eq "Name"
            || $_ eq "LocalName"
            || $_ eq "Prefix"
            || $_ eq "Attributes";
        return undef unless empty $elt->{$_};
    }

    return {
        Args => join( "",
            ": <",
            (
                (
                   defined $elt
                && ref $elt eq "HASH"
                && exists $elt->{Name}
                && defined $elt->{Name}
                )
                    ? ( defined $elt->{Name} ? _esc $elt->{Name} : "???" )
                    : "???"
            ),
            exists $elt->{Attributes} && defined $elt->{Attributes}
                ? map {
                    " " . _esc( $_->{Name} ) . "=" . _dqify $_->{Value} ;
                } values %{$elt->{Attributes}} 
                : (),
            ">"
        ),
    };
}


sub format_end_element {
    my ( $tp, $r, $params ) = @_;

    return undef if @$params != 2;
    my $elt = $params->[1];
    return undef if ! defined( $elt ) || ref $elt ne "HASH";

    for ( keys %$elt ) {
        next if $_ eq "Name"
            || $_ eq "LocalName"
            || $_ eq "Prefix"
            || $_ eq "Attributes";
        return undef unless empty $elt->{$_};
    }

    return {
        Args => join( "",
            ": </",
            (
                (
                   defined $elt
                && ref $elt eq "HASH"
                && exists $elt->{Name}
                && defined $elt->{Name}
                )
                    ? ( defined $elt->{Name} ? _esc $elt->{Name} : "???" )
                    : "???"
            ),
            ">"
        ),
    };
}

sub format_characters {
    my ( $tp, $r, $params ) = @_;

    return undef if @$params != 2;
    my $data = $params->[1];
    return undef if ! defined( $data ) || ref $data ne "HASH";
    return undef if ! exists $data->{Data} || ! defined $data->{Data};


    for ( keys %$data ) {
        next if $_ eq "Data";
        return undef;
    }

    return { Args => ": " . _dqify( $data->{Data} ) . "\n" };
}


sub format_comment {
    my ( $tp, $r, $params ) = @_;

    return undef if @$params != 2;
    my $data = $params->[1];
    return undef if ! defined( $data ) || ref $data ne "HASH";
    return undef if ! exists $data->{Data} || ! defined $data->{Data};

    for ( keys %$data ) {
        next if $_ eq "Data";
        return undef;
    }

    return { Args => ": <!--" . _esc( $data->{Data} ) . "-->\n" };
}


sub format_processing_instruction {
    my ( $tp, $r, $params ) = @_;

    return undef if @$params != 2;
    my $data = $params->[1];
    return undef if ! defined( $data ) || ref $data ne "HASH";
    return undef if ! exists $data->{Target} || ! defined $data->{Target};

    for ( keys %$data ) {
        next if $_ eq "Target";
        next if $_ eq "Data";
        return undef;
    }

    my $pi = $data->{Target};
    $pi .= " $data->{Data}"
        if exists $data->{Data} && ! empty $data->{Data};

    return { Args => ": <?" . _esc( $pi ) . "?>\n" };
}


sub format_parse {
    my ( $tp, $r, $params ) = @_;

    return undef if @$params != 2 || ref $params->[1] ne "HASH" ;

    return {
        Args => [
            $params->[0],
            _stringify_blessed_refs $params->[1],
        ]
    };
}

=head1 TODO

Add a lot more formatting clean-up.

=head1 LIMITATIONS

This module overloads CORE::GLOBAL::require when used from the command
line via -d: or -M.  For some reason this causes spurious warnings like

   Unquoted string "fields" may clash with future reserved word at /usr/local/lib/perl5/5.6.1/base.pm line 87.

That line looks like "require fields;", so it looks like the (*) prototype
on our CORE::GLOBAL::require = sub (*) {...} isn't having it's desired
effect.  It would be nice to clean these up.

=head1 AUTHOR

    Barrie Slaymaker <barries@slaysys.com>

=head1 LICENSE

You may use this under the terms of either the Artistic License or any
version of the BSD or GPL licenses :).

=cut

1;
