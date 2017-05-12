package Declare::Opts;
use strict;
use warnings;

our $VERSION = "0.009";

use Carp qw/croak/;

use Exporter::Declare qw{
    import
    gen_default_export
    default_export
};

gen_default_export 'OPTS_META' => sub {
    my ( $class, $caller ) = @_;
    my $meta = $class->new();
    $meta->{class} = $caller;
    return sub { $meta };
};

default_export opt        => sub { caller->OPTS_META->opt( @_ )   };
default_export parse_opts => sub { caller->OPTS_META->parse( @_ ) };
default_export opt_info   => sub { caller->OPTS_META->info        };

sub class   { shift->{class}   }
sub opts    { shift->{opts}    }
sub default { shift->{default} }

sub new {
    my $class = shift;
    my ( %opts ) = @_;

    my $self = bless { opts => {}, default => {} } => $class;
    $self->opt( $_, $opts{$_} ) for keys %opts;

    return $self;
}

sub valid_opt_params {
    return qr/^(alias|list|bool|default|check|transform|description)$/;
}

sub opt {
    my $self = shift;
    my ( $name, %config ) = @_;

    croak "opt '$name' already defined"
        if $self->opts->{$name};

    for my $prop ( keys %config ) {
        next if $prop =~ $self->valid_opt_params;
        croak "invalid opt property: '$prop'";
    }

    $config{name} = $name;

    croak "'check' cannot be used with 'bool'"
        if $config{bool} && $config{check};

    croak "'transform' cannot be used with 'bool'"
        if $config{bool} && $config{transform};

    croak "opt properties 'list' and 'bool' are mutually exclusive"
        if $config{list} && $config{bool};

    if (exists $config{default}) {
        croak "References cannot be used in default, wrap them in a sub."
            if ref $config{default} && ref $config{default} ne 'CODE';
        $self->default->{$name} = $config{default};
    }

    if ( exists $config{check} ) {
        my $ref = ref $config{check};
        croak "'$config{check}' is not a valid value for 'check'"
            if ($ref && $ref !~ m/^(CODE|Regexp)$/)
            || (!$ref && $config{check} !~ m/^(file|dir|number)$/);
    }

    if ( exists $config{alias} ) {
        my $aliases = ref $config{alias} ?   $config{alias}
                                         : [ $config{alias} ];

        $config{_alias} = { map { $_ => 1 } @$aliases };

        for my $alias ( @$aliases ) {
            croak "Cannot use alias '$alias', name is already taken by another opt."
                if $self->opts->{$alias};

            $self->opts->{$alias} = \%config;
        }
    }

    $self->opts->{$name} = \%config;
}

sub parse {
    my $self = shift;
    my @opts = @_;

    my $params = [];
    my $flags = {};
    my $no_flags = 0;

    while ( my $opt = shift @opts ) {
        if ( $opt eq '--' ) {
            $no_flags++;
        }
        elsif ( $opt =~ m/^-+([^-=]+)(?:=(.+))?$/ && !$no_flags ) {
            my ( $key, $value ) = ( $1, $2 );

            my $name = $self->_flag_name( $key );
            my $values = $self->_flag_value(
                $name,
                $value,
                \@opts
            );

            if( $self->opts->{$name}->{list} ) {
                push @{$flags->{$name}} => @$values;
            }
            else {
                $flags->{$name} = $values->[0];
            }
        }
        else {
            push @$params => $opt;
        }
    }

    # Add defaults for opts not provided
    for my $opt ( keys %{ $self->default } ) {
        next if exists $flags->{$opt};
        my $val = $self->default->{$opt};
        $flags->{$opt} = ref $val ? $val->() : $val;
    }

    return ( $params, $flags );
}

sub info {
    my $self = shift;
    return {
        map { $self->opts->{$_}->{name} => $self->opts->{$_}->{description} || "No Description" }
            keys %{ $self->opts }
    };
}

sub _flag_value {
    my $self = shift;
    my ( $flag, $value, $opts ) = @_;

    my $spec = $self->opts->{$flag};

    if ( $spec->{bool} ) {
        return [$value] if defined $value;
        return [$spec->{default} ? 0 : 1];
    }

    my $val = defined $value ? $value : shift @$opts;

    my $out = $spec->{list} ? [ split /\s*,\s*/, $val ]
                            : [ $val ];

    $self->_validate( $flag, $spec, $out );

    return $out unless $spec->{transform};
    return [ map { $spec->{transform}->($_) } @$out ];
}

sub _validate {
    my $self = shift;
    my ( $flag, $spec, $value ) = @_;

    my $check = $spec->{check};
    return unless $check;
    my $ref = ref $check || "";

    my @bad;

    if ( $ref eq 'Regexp' ) {
        @bad = grep { $_ !~ $check } @$value;
    }
    elsif ( $ref eq 'CODE' ) {
        @bad = grep { !$check->( $_ ) } @$value;
    }
    elsif ( $check eq 'file' ) {
        @bad = grep { ! -f $_ } @$value;
    }
    elsif ( $check eq 'dir' ) {
        @bad = grep { ! -d $_ } @$value;
    }
    elsif ( $check eq 'number' ) {
        @bad = grep { m/\D/ } @$value;
    }

    return unless @bad;
    my $type = $ref || $check;
    die "Validation Failed for '$flag=$type': " . join( ", ", @bad ) . "\n";
}

sub _flag_name {
    my $self = shift;
    my ( $key ) = @_;

    # Exact match
    return $self->opts->{$key}->{name}
        if $self->opts->{$key};

    my %matches = map { $self->opts->{$_}->{name} => 1 }
        grep { m/^$key/ }
            keys %{ $self->opts };
    my @matches = keys %matches;

    die "partial option '$key' is ambiguous, could be: " . join( ", " => @matches ) . "\n"
        if @matches > 1;

    die "unknown option '$key'\n"
        unless @matches;

    return $matches[0];
}

1;

__END__

=pod

=head1 NAME

Declare::Opts - (Deprecated) Simple and Sane Command Line Argument processing

=head1 DESCRIPTION

Deprecated: see L<Declare::CLI>

Declare-Opts is a sane and declarative way to define and consume command line
options. Any number of dashes can be used, it is not picky about -opt or
--opt. You can use '-opt value' or '-opt=value', it will just work. Shortest
unambiguous substring of any opt name can be used to specify the option.

=head1 WHY NOT GETOPT?

The Getopt ecosystem is bloated. Type getopt into search.cpan.org and you will
be given pages and pages of results. Normally this would be a good thing, the
issue is that each package provides specialised functionality, and most cannot
operate together.

The Getopt ecosystem is also very crufty. Getopt is an old module that uses
many outdated practices, and an even more outdated interface. Unfortunately
this has been carried forward into the new getopt modules, possibly for
compatability/familiarity reasons.

Declare::Opts is a full on break from the Getopt ecosystem. Designed from
scratch using modern practices and interface design.

=head1 SYNOPSIS

=head2 DECLARATIVE

Code:

    #!/usr/bin/env perl
    use Declare::Opts;

    # Define a simple opt, any value works:
    opt 'simple';

    # Define a boolean opt
    opt with_x => ( bool => 1 );

    # Define a list
    opt items => ( list => 1 );

    # Other Options
    opt complex => (
        alias       => $name_or_array_of_names,
        default     => $val_or_sub,
        check       => $bultin_regex_or_sub,
        transform   => sub { my $opt = shift; ...; return $opt },
        description => "This is a complex option",
    );

    # Get the (opts => descriptions) hash, useful for a help() function
    my $info = opt_info();

    #########################
    # Now process some opts #
    #########################

    my ( $args, $opts ) = parse_opts( @ARGV );

    # $args contains the items from @ARGV that are not specified opts (or their
    # values)
    # $opts is a hashref containing the opts and their values.


Command Line:

    ./my_command.pl -simple simple_value -with_x --items "a,b, c"

The shortest unambiguous string can be used for each parameter. For instance we
only have one option defined above that starts with 's', that is 'simple':

    ./my_command.pl -s simple_value

=head2 OBJECT ORIENTED

    require Declare::Opts;

    # Create
    my $opts = Declare::Opts->new( %opts );

    # Add an opt
    $opts->opt( $name, %config );

    # Get info
    my $info = $opts->info;

    # Parse some opts
    my ( $args_array, $opts_hash ) = $opts->parse( @ARGV );

=head1 META OBJECT

When you import Declare::Opts a meta-object is created in your package. The
meta object can be accessed via the OPTS_META() method/function. This object is
an instance of Declare::Opts and can be manipulated just like any Declare::Opts
object.

=head1 EXPORTS

=over 4

=item opt( $name, %config );

=item opt name => ( %config );

Define an option

=item my $info = opt_info();

Get a ( name => description ) hashref for use in help output.

=item my ( $args, $opts ) = parse_opts( @OPTS );

Parse some options. $list contains the options leftovers (those that do not
start with '-'), $opts is a hashref containing the values of all the dashed
opts.

=back

=head1 METHODS

=over 4

=item $class->new( %opts );

Create a new instance.

=item my $class = $opts->class;

If the object was created as a meta-object this will contain the class to which
it applies. When created directly this will always be empty.

=item $opts->opt( $name, %config );

Define an option

=item my $info = $opts->info();

Get a ( name => description ) hashref for use in help output.

=item my ( $args_array, $opts_hash ) = $opts->parse( @OPTS );

Parse some options. $list contains the options leftovers (those that do not
start with '-'), $opts is a hashref containing the values of all the dashed
opts.

=back

=head1 OPTION PROPERTIES

=over 4

=item alias => $name

=item alias => [ $name1, $name2 ]

Set aliases for the option.

=item list => $true_or_false

If true, the option can be provided on the command line any number of times,
and comma seperated lists will be split for you.

=item bool => $true_or_false

If true, the option does not require a value and turns the option on or off.
A value can be specified using the '--opt=VAL' format. However '--opt val' will
not treat 'val' as the option value.

=item default => $scalar

=item default => sub { ... }

Set the default value. If the opt is not specified on the command line this
value will be used. If the value is not a simple scalar it must be wrapped in a
code block.

=item check => 'builtin'

=item check => qr/.../

=item check => sub { my $val = shift; ...; return $bool }

Used to validate option values. Can be a coderef, a regexp, or one of these bultins:

    'number'    The value(s) must be numeric (only contains digit characters)
    'file'      The value(s) must be a file (uses -f check)
    'dir'       The value(s) must be a directory (-d check)

=item transform => sub { my $orig = shift; ...; return $new }

Function to transform the provided value into something else. Applies to eahc
item of a list when list is true.

=item description => $description_string

Used to describe an option, useful for help() output.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2012 Chad Granum

Declare-Opts is free software; Standard perl licence.

Declare-Opts is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.

