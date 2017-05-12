use strict;
use warnings;

package Getopt::Long::Spec::Parser;
{
  $Getopt::Long::Spec::Parser::VERSION = '0.002';
}

# ABSTRACT: Parse a Getopt::Long option spec into a set of attributes
use Carp;
use Data::Dumper;

# holds the current opt spec, used for error and debugging code...
my $CUR_OPT_SPEC;

# holds the parameters for the current parse
my $CUR_OPTS;

sub new {
    my ( $class, %params ) = @_;
    my $self = bless {%params}, $class;
    return $self;
}

sub parse {
    my ( $self, $spec, $params ) = @_;

    # temporary globals...
    $CUR_OPT_SPEC = $spec;
    $CUR_OPTS = { %{ $params || {} }, %{ ref( $self ) ? $self : {} } };

    print "DEBUG: spec: [$spec]\n" if $CUR_OPTS->{debug};
    print "DEBUG: params: " . Dumper $CUR_OPTS if $CUR_OPTS->{debug};

    croak "Invalid option specification: [$spec]"
        if $spec !~ /^ ([|a-zA-Z_-]+) ([=:!+]?) (.*) /x;

    my $name_spec = $1;
    my $opt_type  = $2 ? $2 : '';
    my $arg_spec  = $3 ? $3 : '';

    my %name_params = $self->_process_name_spec( $name_spec );
    my %arg_params = $self->_process_arg_spec( $opt_type, $arg_spec );

    ### It is necessary to compute these here for compat. with GoL
    ### I feel that this block should be relocated... but WHERE?
    if ( $arg_params{negatable} ) {
        my @neg_names = $self->_generate_negation_names(
            $name_params{long},
            $name_params{short},
            @{ $name_params{aliases} },
        );
        push @{ $name_params{negations} }, @neg_names;
    }

    undef $CUR_OPT_SPEC;  # done with global var.
    undef $CUR_OPTS;      # ditto

    my %result = ( %name_params, %arg_params );

    return wantarray ? %result : \%result;
}

our $NAME_SPEC_QR = qr{
    ( [a-zA-Z_-]+ )            # option name as $1
    (
      (?: [|] [a-zA-Z?_-]+ )*  # aliases as $2 (split on |)
    )
}x;

sub _process_name_spec {
    my ( $self, $spec ) = @_;

    croak "Could not parse the name part of the option spec [$CUR_OPT_SPEC]."
        if $spec !~ $NAME_SPEC_QR;

    my %params;

    $params{long}    = $1;
    $params{aliases} = [
        grep { defined $_ }
            map {
                  ( length( $_ ) == 1 and !$params{short} )
                ? ( $params{short} = $_ and undef )
                : $_
            }
            grep { $_ }
            split( '[|]', $2 )
    ];

    return %params;
}

our $ARG_SPEC_QR = qr{
    (?:
        ( [siof] )    # value_type as $1
      | ( \d+ )       # default_num as $2 (not always valid)
      | ( [+] )       # increment type as $3    (not always valid)
    )
    ( [@%] )?         # destination data type as $4
    (?:
        [{]
        (\d+)?        # min_vals as $5
        (?:
            [,]
            (\d*)?    # max_vals as $6
        )?
        [}]
    )?
}x;

sub _process_arg_spec {
    my ( $self, $opt_type, $arg_spec ) = @_;

    # do some validation and set some params based on the option type
    my %params = $self->_process_opt_type( $opt_type, $arg_spec );

    return %params unless $arg_spec;

    # parse the arg spec...
    croak "Could not parse the argument part of the option spec [$CUR_OPT_SPEC]\n"
        if $arg_spec !~ $ARG_SPEC_QR;
    my $val_type      = $1;                # [siof]
    my $default_num   = $2;                # \d+
    my $incr_type     = $3;                # \+
    my $dest_type     = $4;                # [@%]
    $params{min_vals} = $5 if defined $5;  # \d+
    $params{max_vals} = $6 if defined $6;  # \d+

    croak "can't use an + here unless opt_type is ':'\n"
        if defined $incr_type and $opt_type ne ':';
    if ( defined $incr_type ) {
        $params{opt_type} = 'incr';
    }

    croak "can't use a default number unless opt_type is ':'\n"
        if defined $default_num and $opt_type ne ':';
    if ( defined $default_num ) {
        $params{default_num} = $default_num;
    }

    croak "can't specify a val_type unless opt_type is ':' or '='\n"
        if defined $val_type and $opt_type !~ /[:=]/;

    croak "repeat can only be used with a required value\n"
        if ( exists $params{min_vals} or exists $params{max_vals} )
        and $opt_type ne '=';

    # one repetition value, no comma...
    if ( exists $params{min_vals} and !exists $params{max_vals} ) {
        $params{num_vals} = delete $params{min_vals};
    }

    if ( $val_type ) {
        $params{val_type} =
              $val_type eq 's' ? 'string'
            : $val_type eq 'i' ? 'integer'
            : $val_type eq 'o' ? 'extint'
            : $val_type eq 'f' ? 'real'
            : die "This should never happen. Ever.";
        $params{opt_type} = 'simple';
    }

    if ( defined $dest_type ) {
        $params{dest_type} =
              $dest_type eq '%' ? 'hash'
            : $dest_type eq '@' ? 'array'
            : croak "Invalid destination type [$dest_type]\n";
    }

    return %params;
}

# About the optiontype...
#   = - option requires an argument
#   : - option argument optional (defaults to '' or 0)
#   ! - option is a flag and may be negated (0 or 1)
#   + - option is an int starting at 0 and incremented each time specified
#     - option is a flag to be turned on when used
sub _process_opt_type {
    my ( $self, $opt_type, $arg_spec ) = @_;

    my %params;

    # set params and do some checking based on what we now know...
    if ( $opt_type =~ /[+!]|^$/ ) {
        if ( $arg_spec ) {
            croak "Invalid option spec [$CUR_OPT_SPEC]: option type "
                . "[$opt_type] does not take an argument spec.";
        }
        if ( $opt_type eq '+' ) {
            $params{opt_type} = 'incr';
        }
        if ( $opt_type eq '!' ) {
            $params{opt_type}  = 'flag';
            $params{negatable} = 1;
        }
        if ( $opt_type eq '' ) {
            $params{opt_type} = 'flag';
        }
        return %params;
    }

    $params{opt_type} = 'simple';

    if ( $opt_type eq '=' ) {
        $params{val_required} = 1;
    }
    elsif ( $opt_type eq ':' ) {
        $params{val_required} = 0;
    }
    else {
        croak "Invalid option spec [$CUR_OPT_SPEC]: option type [$opt_type] is invalid.\n";
    }

    if ( !$arg_spec ) {
        croak "Invalid option spec [$CUR_OPT_SPEC]: option type "
            . "[$opt_type] requires an argument spec.\n";
    }

    return %params;
}

### if the spec shows that negation is allowed,
### generate "no* names" for each name and alias.
sub _generate_negation_names {
    my ( $self, @names ) = @_;
    my @neg_names = map { ( "no-$_", "no$_" ) } grep { length } @names;
    return @neg_names;
}

1 && q{there's nothing like re-inventing the wheel!};  # truth


=pod

=head1 NAME

Getopt::Long::Spec::Parser - Parse a Getopt::Long option spec into a set of attributes

=head1 VERSION

version 0.002

=head1 SYNOPSIS

This module parses an option specification as would normally be used with
Getopt::Long, and produces a hash showing the meaning/parameters the spec
describes... if that makes any sense at all...

Perhaps a little code snippet.

    use Getopt::Long::Spec::Parser;

    my $parser = Getopt::Long::Spec::Parser->new();
    my %spec_info = $parser->parse( 'foo|f=s@{1,5}' );

    # OR...

    my %spec_info =
        Getopt::Long::Spec::Parser->parse( 'foo|f=s@{1,5}' );

%spec_info should be a hash containing info about the parsed Getopt::Long
option specification

=head1 METHODS

=head2 new

construct a new parser.

    my $parser = Getopt::Long::Spec::Parser->new();
    # OR...
    my $parser = Getopt::Long::Spec::Parser->new(
        debug => 1,
    );

=head2 parse

parse an option specification

    my %spec_info = $parser->parse( 'foo' );
    # OR...
    my %spec_info = Getopt::Long::Spec::Parser->parse( 'foo' );

return the info parsed from the spec as a hash, or hashref,
depending on context.

In scalar context, returns a hashref, in list context, returns a hash.

=head1 NOTES on PARSING Getopt::Long OPTION SPECIFICATIONS

Described as a grammar:

  opt_spec  ::=  name_spec (arg_spec)?  # if no arg_spec, option is a flag.

  name_spec ::=  opt_name ("|" opt_alias)*
  opt_alias ::=  /\w+/
  opt_name  ::=  /\w+/

  arg_spec  ::= "="  val_type                (dest_type)? (repeat)?  # simple required
              | ":" (val_type | /\d+/ | "+") (dest_type)?            # simple optional
              | "!"                                                  # flag negatable
              | "+"                                                  # flag incremental

  arg_type  ::=  "s" | "i" | "o" | "f"              # string, integer, extint, float
  dest_type ::=  "@" | "%"                          # array or hash
  repeat    ::=  "{" (min_val)? ("," max_val)? "}"  # multiple-values per use
  min_vals  ::=  /\d+/
  max_vals  ::=  /\d*/

=head1 AUTHOR

Stephen R. Scaffidi <sscaffidi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Stephen R. Scaffidi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

