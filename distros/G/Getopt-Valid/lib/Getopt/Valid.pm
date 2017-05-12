package Getopt::Valid;

=head1 NAME

Getopt::Valid - Extended processing and validation of command line options

=head1 DESCRIPTION

Implements an extended getopt mechanism relying on L<Getopt::Long> but provides extended validation and filtering capabilities.

Useful for shell scripts.

I wrote this, because i need input validation / processing in most of my scripts. This keeps it formal and readable while
not making me re-implement the wheel over and over again.

The dependency footprint is rather small (only L<Getopt::Long>).

=head1 SYNOPSIS

    #!/usr/bin/perl
    
    use strict;
    use warnings;
    use Getopt::Valid;

    #
    # VALIDATION DEFINITION
    #

    my $validation_ref = {
        
        # name of the program
        name => 'MyScript', # fallback to $0, if not set
        
        # version info
        version => '1.0.1', # fallback to $main::VERSION or "unknown", if not set
        
        # the struct of the params
        struct => [
            
            # extended example
            'somestring|s=s' => {
                description => 'The description of somestring',
                constraint  => sub { my ( $val ) = @_; return index( $val, '123' ) > -1 },
                required    => 1,
            },
            
            # Example using only validator and fallback to default description.
            # This value is optional (mind: no "!")
            'otherstring|o=s' => qr/^([a-z]+)$/, # all lowercase words
            
            # Example of using integer key with customized description.
            # This value is optional (mind the "!")
            'someint|i=i!' => 'The description of someint',
            
            # Bool value using the default description
            'somebool|b' => undefm
            
            # the following is implicit, prints out the usag and exists.. can be overwritten
            #'help|h' => 'Show this help'
        ]
    };

    #
    # FUNCTIONAL USAGE
    #

    my $validated_args_ref = GetOptionsValid( $validation_ref )
        || die "Failed to validate input\n".
            join( "\nERRORS:\n", @Getopt::Valid::ERRORS, "\n\nUSAGE:\n", $Getopt::Valid::USAGE );
    
    # acces the user input
    print "Got $validated_args_ref->{ somestring }\n";
    
    
    #
    # OBJECT USAGE
    #

    my $opt = Getopt::Valid->new( $validation_ref );

    # collect data from @ARGV.. you could manipulate @ARGV and run again..
    $opt->collect_argv;

    # whether validates
    if ( $opt->validate ) {
        
        # acces valid input data
        print "Got ". $opt->valid_args->{ somestring }. "\n";
    }

    # oops, not valid
    else {
        
        # print errors
        print "Oops ". $opt->errors( " ** " ). "\n";
        
        # print usage
        print $opt->usage();
    }

=head1 VALIDATOR SYNTAX

=over

=item * name STRING

Name of the program. Use in help output.

Defaults to $0

=item * version VERSION STRING

Version of the program. Used in help output. Tries $main::VERSION, if not set.

Defaults to "unknown"

=item * underscore BOOL

Whether "-" characters in arguments shall be rewritten to "_" in the result.

Default: 0 (disabled)

=item * struct ARRAYREF

Structure of the arguments. The order will be respected in the help generation.

Can be written in 4 styles

=over

=item * SCALAR

    $struct_ref = [
        'argument-name|a=s' => 'Description text for help',
        'other-arg' => 'Description text for help'
    ];

=item * REGEXP

    $struct_ref = [
        'argument-name|a=s' => qr/(bla|blub),
    ];

=item * CODE

    $struct_ref = [
        'argument-name|a=s' => sub {
            my ( $value, $name, $validator ) = @_;
            warn "Checking '$name' = '$value'\n";
            return $value eq 'ok';
        }
    ];

=item * HASH

    $struct_ref = [
        'argument-name|a=s' => {
            
            # the description for the help
            description => 'Description text for help',
            
            # default value, if not given
            default => 'Some Default',
            
            # whether required (redundant for bool), default: 0
            required => 1|0,
            
            # constraint can be regexp or code-ref, see above
            constraint => sub { .. },
            
            # modify value before handing to constraint (if any)
            prefilter => sub {
                my ( $value, $name, $validator ) = @_;
                return "THE NEW $value\n";
            },
            
            # modify value after constraint check (if any). runs only if valid (or no constraint).
            postfilter => sub {
                my ( $value, $name, $validator ) = @_;
                return "THE NEW $value\n";
            },
            
            # trigger is called in any case, even if arg not given
            anytrigger => sub {
                my ( $value, $name, $validator ) = @_;
                return ; # ignored
            },
            
            # trigger is called if value is defined / given (independent if validated)
            settrigger => sub {
                my ( $value, $name, $validator ) = @_;
                return ; # ignored
            },
            
            # trigger is called if value is validated (or no validator is given)
            oktrigger => sub {
                my ( $value, $name, $validator ) = @_;
                return ; # ignored
            },
            
            # trigger is called if value is invalid (or no validator is given)
            oktrigger => sub {
                my ( $value, $name, $validator ) = @_;
                return ; # ignored
            },
        }
    ];

=back

=back

=cut

use strict;
use warnings;

use version 0.74; our $VERSION = qv( "v0.1.4" );

use Getopt::Long;

use base qw/ Exporter /;
our @EXPORT = qw/ GetOptionsValid /;

our $REQUIRED_STR = '[REQ]';
our @ERRORS;
our $ERROR;
our $USAGE = '';

=head1 EXPORTED METHODS

In functional context, you can access the errors via C<@Getopt::Valid::ERRORS> and the usage via C<$Getopt::Valid::USAGE>

=head2 GetOptionsValid $validator_ref

See L</VALIDATOR SYNTAX>

=cut

sub GetOptionsValid {
    my ( $args_ref ) = @_;
    my $self = Getopt::Valid->new( $args_ref );
    $self->collect_argv;
    $USAGE = $self->usage();
    if ( $self->validate() ) {
        return $self->valid_args;
    }
    return 0;
}

=head1 CLASS METHODS

=head2 new $validator_ref

Constructor. See L</VALIDATOR SYNTAX>

=cut

sub new {
    my ( $class, $args_ref ) = @_;
    $class = ref $class if ref $class;
    die "Usage: Getopt::Valid->new( { name => .., version => .., struct => [ .. ] } )"
        unless $args_ref && ref( $args_ref ) eq 'HASH' && $args_ref->{ struct } && ref( $args_ref->{ struct } ) eq 'ARRAY';
    ( bless {
        %$args_ref,
        collected_args => {},
        updated_struct => {},
        simple_struct  => {},
        order_struct   => []
    }, $class )->_parse_struct;
}

sub _parse_struct {
    my ( $self ) = @_;
    
    my ( %seen_short, %simple_struct, %updated_struct, @order_pre, @order_struct );
    my @struct = @{ $self->{ struct } };
    for ( my $i = 0; $i < @struct; $i += 2 ) {
        push @order_pre, $struct[ $i ];
    }
    
    my %struct = @struct;
    foreach my $key( @order_pre ) {
        my $kstruct = $struct{ $key };
        my $required = $key =~ s/!$//;
        my $error = 0;
        
        my ( $name, $short, $mode_op, $mode, $constraint, $prefilter, $postfilter,
            $description, $anytrigger, $settrigger, $oktrigger, $failtrigger, $default );
        if ( $key =~ /
            \A
            (.+?)       # name
            (?:\|(.+?))?   # short
            (?:
                (?:
                    ([=:])              # op
                    ([isfo]|[0-9]+)     # type
                |
                    (\+)                # increment type
                )
            )?$
            \z
        /x ) {
            $name = $1;
            $short = $2 || '';
            $mode_op = $3 || '';
            $mode = $4 || $5 || 'b';
        }
        else {
            die "Could not use key '$key' for validation! RTFM"
        }
        
        my $rstruct = ref( $kstruct ) || '';
        if ( $rstruct eq 'HASH' ) {
            $required = $kstruct->{ required } || 0 
                if defined $kstruct->{ required };
            $constraint = $kstruct->{ constraint }
                if defined $kstruct->{ constraint };
            $prefilter = $kstruct->{ prefilter }
                if defined $kstruct->{ prefilter };
            $postfilter = $kstruct->{ postfilter }
                if defined $kstruct->{ postfilter };
            $anytrigger = $kstruct->{ anytrigger }
                if defined $kstruct->{ anytrigger };
            $settrigger = $kstruct->{ settrigger }
                if defined $kstruct->{ settrigger };
            $oktrigger = $kstruct->{ oktrigger }
                if defined $kstruct->{ oktrigger };
            $failtrigger = $kstruct->{ failtrigger }
                if defined $kstruct->{ failtrigger };
            $description = $kstruct->{ description }
                if defined $kstruct->{ description };
            $default = $kstruct->{ default }
                if defined $kstruct->{ default };
        }
        elsif ( $rstruct eq 'Regexp' || $rstruct eq 'CODE' ) {
            $constraint = $kstruct;
        }
        elsif ( $rstruct ) {
            die "Invalid constraint for key $name. Neither regexp-ref nor code-ref nor scalar"
        }
        elsif ( defined $kstruct && length( $kstruct ) > 1 ) {
            $description = $kstruct;
        }
        
        $default = $mode eq 's' ? '' : 0
            unless defined $default;
        
        $description = "$name value"
            unless $description;
        
        $updated_struct{ $name } = {
            required    => $required,
            short       => $short,
            mode        => $mode,
            mode_op     => $mode_op,
            constraint  => $constraint,
            postfilter  => $postfilter,
            prefilter   => $prefilter,
            description => $description,
            anytrigger  => $anytrigger,
            settrigger  => $settrigger,
            oktrigger   => $oktrigger,
            failtrigger => $failtrigger,
            default     => $default
        };
        $simple_struct{ $key } = $name;
        push @order_struct, $name;
        $seen_short{ $short } ++;
    }
    
    unless ( defined $updated_struct{ help } ) {
        my ( $short, $key ) = $seen_short{ h } ? ( undef, 'help' ) : ( 'h', 'help|h' );
        $updated_struct{ help } = {
            required    => 0,
            short       => $short,
            mode        => 'b',
            mode_op     => '',
            constraint  => undef,
            postfilter  => undef,
            prefilter   => undef,
            description => 'Show this help',
            anytrigger  => undef,
            settrigger  => sub { print $_[-1]->usage; exit; },
            oktrigger   => undef,
            failtrigger => undef,
            default     => 0,
        };
        $simple_struct{ $key } = 'help';
        push @order_struct, 'help';
    }
    
    $self->{ updated_struct } = \%updated_struct;
    $self->{ simple_struct }  = \%simple_struct;
    $self->{ order_struct }   = \@order_struct;
    
    $self;
}

=head2 collect_argv

Collect args found in C<@ARGV> using L<Getopt::Long#GetOptions>

=cut

sub collect_argv {
    my ( $self ) = @_;
    my ( %struct, %args );
    while( my( $key, $name ) = each %{ $self->{ simple_struct } ||= {} } ) {
        $key =~ s/!$//;
        my $default = $self->{ updated_struct }->{ $name }->{ default };
        $struct{ $key } = \( $args{ $name } = $default );
    }
    
    # DIRY HACK
    #   don't want to have the output of Getopt::Long around here
    my $stderr = *STDERR;
    open my $null, '>', File::Spec->devnull;
    *STDERR = $null;
    GetOptions( %struct );
    *STDERR = $stderr;
    close $null;
    
    $self->args( \%args );
}

=head2 args

Set/get args. 

=cut

sub args {
    my ( $self, $args_ref ) = @_;
    $self->{ collected_args } = $args_ref
        if $args_ref;
    return $self->{ collected_args } ||= {};
}

=head2 validate

Performs validation of the input. Returns differently in array- or scalar-context.

=over

=item * Array context

Returns ( has_errors, hashref_of_valid_input )

    my ( $valid, $input_ref ) = $obj->validate();
    if ( $valid ) {
        print "All good, got arg 'some_arg': $input_ref->{ some_arg }\n";
    }

=item * Scalar context

Returns whether validation was successfull (or any error ocurred)

    if ( scalar $obj->validate() ) {
        print "All good, got arg 'some_arg': ". $opt->valid_args->{ some_arg }. "\n";
    }

=back

=cut

sub validate {
    my ( $self ) = @_;
    my $args_ref = $self->args;
    my ( @errors, %valid_args );
    while( my( $name, $ref ) = each %{ $self->{ updated_struct } ||= {} } ) {
        my $error = 0;
        my ( $required, $constraint, $description, $prefilter, $postfilter )
            = map { $ref->{ $_ } } qw/ required constraint description prefilter postfilter /;
        
        # get value
        my $value = defined $args_ref->{ $name }
            ? $args_ref->{ $name }
            : undef;
        
        # run pre filter
        $value = $prefilter->( $value, $name, $self )
            if $prefilter;
        
        # check: required
        if ( $required && ! $value ) {
            push @errors, sprintf( 'Required key "%s" not given', $name );
            $error++;
        }
        
        # check: constraint
        if ( $constraint && defined $value && ( ref( $value ) || length( $value ) ) ) {
            if ( ref( $constraint ) eq 'CODE' ) {
                unless ( $constraint->( $value, $name, $self ) ) {
                    push @errors, sprintf( 'Value of key "%s" is invalid', $name );
                    $error++;
                }
            }
            else {
                unless ( $value =~ $constraint ) {
                    push @errors, sprintf( 'Value of key "%s" is invalid', $name );
                    $error++;
                }
            }
        }
        
        # get triggers
        my ( $anytrigger, $settrigger, $oktrigger, $failtrigger )
            = map { $ref->{ $_ } } qw/ anytrigger settrigger oktrigger failtrigger /;
        
        # no error? valid value -> assi
        unless ( $error ) {
            $value = $postfilter->( $value )
                if $postfilter;
            $valid_args{ $name } = $value;
            
            # call ok trigger?
            $oktrigger->( $value, $name, $self )
                if $oktrigger;
        }
        
        # call fail trigger?
        elsif ( $failtrigger ) {
            $failtrigger->( $value, $name, $self );
        }
        
        # call any trigger?
        $anytrigger->( $value, $name, $self )
            if $anytrigger;
        
        # call set trigger?
        $settrigger->( $value, $name, $self )
            if $settrigger && $value;
    }
    
    
    if ( $self->{ underscore } ) {
        foreach my $k( keys %valid_args ) {
            ( my $ku = $k ) =~ s#\-#_#gms;
            $valid_args{ $ku } = delete $valid_args{ $k }
                if $ku ne $k;
        }
    }
    
    $self->{ valid_args } = \%valid_args;
    $self->{ errors } = \@errors;
    @ERRORS = @errors;
    $ERROR = join( ' ** ', @ERRORS );
    
    return wantarray ? ( @errors ? 0 : 1, \%valid_args ) : @errors ? 0 : 1;
}

=head2 valid_args

Returns validated args

=cut

sub valid_args {
    shift->{ valid_args };
}

=head2 usage

Returns usage as string

=cut

sub usage {
    my ( $self, $do_print ) = @_;
    my @output = (
        sprintf( 'Program: %s', $self->{ name } || $0 ),
        sprintf( 'Version: %s', $self->{ version } || eval { $main::VERSION } || 'unknown' ),
        '',
        'Usage: '. $0. ' <parameters>',
        '',
        'Parameter:'
    );
    my $mode_out = sub {
        my $m = shift;
        if ( $m eq 's' ) {
            return 'string';
        }
        elsif ( $m eq 'i' ) {
            return 'integer';
        }
        elsif ( $m eq 'f' ) {
            return 'real';
        }
        elsif ( $m eq 'o' ) {
            return 'octet or hex';
        }
        elsif ( $m =~ /^[0-9]|\+$/ ) {
            return 'optional:integer'
        }
        else {
            return 'bool';
        }
    };
    foreach my $name( @{ $self->{ order_struct } } ) {
        my $ref = $self->{ updated_struct }->{ $name };
        my @arg_out = ( '  --'. $name );
        push @arg_out, ' | -'. $ref->{ short } if $ref->{ short };
        push @arg_out, ' : '. $mode_out->( $ref->{ mode } );
        my $arg_out = join( '', @arg_out );
        $arg_out .= ' '. $REQUIRED_STR if $ref->{ required };
        push @output, $arg_out;
        
        my @description = ref( $ref->{ description } )
            ? ( map { '    '. $_ } @{ $ref->{ description } } )
            : ( '    '. $ref->{ description } );
        push @output, join( "\n", @description );
        push @output, '';
    }
    push @output, '';
    
    my $output = join( "\n", @output );
    print $output if $do_print;
    return $output;
}

=head2 errors

Returns errors as joined string or array of strings of the last valid-run

=cut

sub errors {
    my ( $self, $sep ) = @_;
    return ! $sep && wantarray
        ? @{ $self->{ errors } ||= [] }
        : join( $sep || "\n", @{ $self->{ errors } ||= [] } );
}

=head1 SEE ALSO

=over

=item * L<Getopt::Long>

=item * Latest release on Github L<http://github.com/ukautz/Getopt-Valid>

=back

=head1 AUTHOR

=over

=item * Ulrich Kautz <uk@fortrabbit.de>


=back

=head1 COPYRIGHT AND WARRANTY

Copyright (c) 2012 the L</AUTHOR> as listed above.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut

1;