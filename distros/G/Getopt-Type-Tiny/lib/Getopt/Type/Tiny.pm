package Getopt::Type::Tiny;

# ABSTRACT: Clean Getopt::Long wrapper with Type::Tiny support

use v5.20.0;
use warnings;
use experimental 'signatures';

use Type::Library -extends => [
    qw(
      Types::Standard
      Types::Common::Numeric
      Types::Common::String
    )
];

use Getopt::Long 'GetOptionsFromArray';
use Pod::Usage qw(pod2usage);
use Carp       qw(croak);

our $VERSION = '0.03';

push our @EXPORT_OK, qw(get_opts);

sub _infer_getopt_modifier ( $type, $coerce = 0 ) {

    # Use display_name since parameterized types have __ANON__ as name
    my $name = $type->display_name;

    # Check if it's ArrayRef or HashRef
    return unless $name =~ /^(ArrayRef|HashRef)/;

    my $container = $1;
    my $suffix    = $container eq 'ArrayRef' ? '@' : '%';

    # Get inner type parameter
    my $param = $type->type_parameter;
    return unless $param;    # Bare ArrayRef/HashRef - will error later

    # Check ancestry (order matters: Int before Num since Int is subtype of Num)
    my $sigil
      = $param->is_a_type_of(Int)       ? 'i'
      : $param->is_a_type_of(Num)       ? 'f'
      : $param->is_a_type_of(Str)       ? 's'
      : $param->equals(Any)             ? 's'
      : $coerce && $param->has_coercion ? 's'
      :                                   undef;

    return unless $sigil;
    return "=$sigil$suffix";
}

sub _validate_multi_value_type ( $name, $type, $coerce = 0 ) {

    # Use display_name since parameterized types have __ANON__ as name
    my $type_name = $type->display_name;

    # Only validate ArrayRef and HashRef
    return unless $type_name =~ /^(ArrayRef|HashRef)/;

    my $container = $1;
    my $param     = $type->type_parameter;

    unless ($param) {
        my $suffix = $container eq 'ArrayRef' ? '@' : '%';
        croak <<"END_ERROR";
Unsupported type '$type_name' for option '$name'.

ArrayRef and HashRef require a type parameter (e.g., ArrayRef[Str]).

To fix this, either:
  1. Use explicit GetOpt::Long syntax: '$name=s$suffix' => { isa => $type_name }
  2. Specify the inner type: ArrayRef[Str], ArrayRef[Int], or ArrayRef[Num]
END_ERROR
    }

    my $is_supported
      = $param->is_a_type_of(Int)
      || $param->is_a_type_of(Num)
      || $param->is_a_type_of(Str)
      || $param->equals(Any)
      || $coerce && $param->has_coercion;

    unless ($is_supported) {
        my $suffix = $container eq 'ArrayRef' ? '@' : '%';
        croak <<"END_ERROR";
Unsupported type '$type_name' for option '$name'.

GetOpt::Long only supports ArrayRef and HashRef with inner types that are
subtypes of Str, Int, or Num.

To fix this, either:
  1. Use explicit GetOpt::Long syntax: '$name=s$suffix' => { isa => $type_name }
  2. Simplify your type to ArrayRef[Str], ArrayRef[Int], or ArrayRef[Num]
END_ERROR
    }
}

sub get_opts (@arg_specs) {

    # forces Carp to ignore this package
    local $Carp::Internal{ +__PACKAGE__ } = 1;
    my %opt_for;         # store the options
    my @getopt_specs;    # the option specs
    my %defaults;        # default values
    my %renames;         # rename option keys
    my %types;           # type constraints
    my %coerce;          # should coerce?
    my %required;        # required options

    while (@arg_specs) {
        my $this_getopt_spec = shift @arg_specs;
        my $options          = is_HashRef( $arg_specs[0] ) ? shift @arg_specs : {};

        my ($name) = $this_getopt_spec =~ /^([\w_]+)/;

        if ( exists $options->{isa} ) {
            $types{$name} = $options->{isa};

            if ( $options->{coerce} && !$types{$name}->has_coercion ) {
                croak("Cannot coerce to a type without a coercion");
            }

            # Validate multi-value types (croaks if unsupported)
            _validate_multi_value_type(
                $name, $types{$name},
                $options->{coerce}
            );

            # Check for multi-value type inference
            my $inferred_modifier
              = _infer_getopt_modifier( $types{$name}, $options->{coerce} );

            if ($inferred_modifier) {

                # Multi-value type detected
                if ( $this_getopt_spec =~ /=[a-z][@%]$/ ) {

                    # Explicit modifier exists - check for mismatch
                    my ($explicit_modifier) = $this_getopt_spec =~ /(=[a-z][@%])$/;
                    if ( $explicit_modifier ne $inferred_modifier
                        && !$options->{nowarn} )
                    {
                        warn "Option '$name' has explicit spec '$explicit_modifier' but type '"
                          . $types{$name}->display_name
                          . "' suggests '$inferred_modifier'.\n"
                          . "Type::Tiny will still validate the values. "
                          . "Use 'nowarn => 1' to suppress this warning.\n";
                    }
                }
                else {
                    # No explicit modifier - append inferred one
                    $this_getopt_spec .= $inferred_modifier;
                }
            }
            elsif ($types{$name}->name ne 'Bool'
                && $this_getopt_spec !~ /=/ )
            {

                # Non-Bool scalar type without modifier
                if ( $this_getopt_spec =~ s/=[a-z]$/=s/ ) {

                    # Replaced explicit type with =s
                }
                else {
                    $this_getopt_spec .= '=s';
                }
            }
        }
        push @getopt_specs, $this_getopt_spec;

        if ( exists $options->{default} && exists $options->{required} ) {
            croak("Option '$name' cannot be both required and have a default value");
        }
        if ( exists $options->{default} ) {
            $defaults{$name} = $options->{default};
        }
        elsif ( exists $options->{isa} ) {

            # Auto-default for ArrayRef and HashRef
            my $type_name = $options->{isa}->display_name;
            if ( $type_name =~ /^ArrayRef/ ) {
                $defaults{$name} = [];
            }
            elsif ( $type_name =~ /^HashRef/ ) {
                $defaults{$name} = {};
            }
        }
        $renames{$name}  = $options->{rename} if exists $options->{rename};
        $required{$name} = $options->{required}
          if exists $options->{required};
        $coerce{$name} = $options->{coerce} if exists $options->{coerce};

        # If no type is specified and the option doesn't have =s or =i,
        # assume Bool
        $types{$name} //= Bool unless $this_getopt_spec =~ /=/;
    }

    # this has proven so incredibly useful that it's now a default,
    # but perhaps it should be optional. Will need to think of the cleanest
    # interface for that.
    push @getopt_specs, 'help|?';
    push @getopt_specs, 'man';

    # Note: this will mutate @ARGV if any options are present
    my $result = GetOptionsFromArray( \@ARGV, \%opt_for, @getopt_specs );

    if ( $opt_for{help} ) {
        pod2usage(1);
    }

    if ( $opt_for{man} ) {
        pod2usage( -exitval => 0, -verbose => 2 );
    }

    unless ($result) {
        croak( pod2usage(2) );
    }

    # Apply defaults
    for my $name ( keys %defaults ) {
        next if exists $opt_for{$name};
        $opt_for{$name}
          = is_CodeRef( $defaults{$name} )
          ? $defaults{$name}->()
          : $defaults{$name};
    }

    # Type checking
    for my $name ( keys %types ) {
        my $type   = $types{$name};
        my $coerce = $coerce{$name};
        if ( exists $opt_for{$name} && !$type->check( $opt_for{$name} ) ) {
            if ($coerce) {
                my $new_val = $type->coerce( $opt_for{$name} );
                if ( $type->check($new_val) ) {
                    $opt_for{$name} = $new_val;
                    next;
                }
            }
            croak( "Invalid value for option '$name': " . $type->get_message( $opt_for{$name} ) );
        }
    }

    # Check required options
    for my $name ( keys %required ) {
        if ( $required{$name} && !exists $opt_for{$name} ) {
            croak("Required option '$name' is missing");
        }
    }

    # Rename keys
    for my $name ( keys %renames ) {
        $opt_for{ $renames{$name} } = delete $opt_for{$name}
          if exists $opt_for{$name};
    }

    return %opt_for;
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Getopt::Type::Tiny - Clean Getopt::Long wrapper with Type::Tiny support

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use Getopt::Type::Tiny qw(get_opts Str Int);
    my %opts = get_opts(
        foo => { isa => Str },
        bar => { isa => Int, default => 42 },
        'verbose|v', # defaults to Bool
    );
    
    # %opts now contains the parsed options:
    # (
    #    foo     => 'value of foo',
    #    bar     => 42,
    #    verbose => 1,
    # )    

=head1 DESCRIPTION

This module is a thin wrapper around L<Getopt::Long> that adds support for
L<Type::Tiny> type constraints. It is intended to be a clean and simple way to
parse command line options with type constraints.

=head1 FUNCTIONS

=head2 get_opts

    my %opts = get_opts(
        foo => { isa => Str },
        bar => { isa => Int, default => 42 },
        'verbose|v', # defaults to Bool
    );

Parses the command line options and returns a hash of the parsed options. The
arguments to C<get_opts> are a list of option specifications.

=head1 OPTION SPECIFICATIONS

Option specifications are passed to C<get_opts> as a list of key/value pairs. If no
option spec is passed, the option is assumed to be a boolean option:

    my %options = get_opts( qw/
      dryrun
      enabled
      verbose
    / );

=over 4

=item isa

The C<isa> key specifies the type constraint for the option. This can be any
L<Types::Standard>, L<Types::Common::Numeric>, or L<Types::Common::String>
type.  If more complex types are needed, you can create your own type
constraints with L<Type::Tiny>.

=item coerce

The C<coerce> key enables type coercions, if the type indicated by C<isa>
supports coercions.

=item default

The C<default> key specifies the default value for the option. If the option is
not present on the command line, this value will be used.

=item rename

The C<rename> key specifies a new name for the option. The value of the option
will be stored in the hash under this new name.

=item required

The C<required> key specifies that the option is required. If the option is not
present on the command line, an error will be thrown.

=back

=head1 HELP OPTIONS

By default, C<get_opts> will add a C<--help|?> and C<man> options that use
L<Pod::Usage> to display the usage message and exit. The C<--help> and C<-?>
options will display a brief usage message and exit. The C<--man> option will
display the full documentation and exit.

=head1 MULTI-VALUE OPTIONS

Multi-value options (arrays and hashes) are automatically detected from
C<ArrayRef> and C<HashRef> types:

    my %opts = get_opts(
        servers => { isa => ArrayRef[Str] },    # --servers=a --servers=b
        config  => { isa => HashRef[Int] },     # --config=k1=1 --config=k2=2
    );

=head2 Supported Types

The following type mappings are supported:

    ArrayRef[Str]  => =s@    ArrayRef[Int]  => =i@    ArrayRef[Num]  => =f@
    HashRef[Str]   => =s%    HashRef[Int]   => =i%    HashRef[Num]   => =f%

Subtypes are also supported (e.g., C<ArrayRef[PositiveInt]> maps to C<=i@>).
C<ArrayRef[Any]> and C<HashRef[Any]> map to string modifiers.

=head2 Auto-Defaults

C<ArrayRef> types default to C<[]> and C<HashRef> types default to C<{}> when
no default is specified. You can override this with an explicit C<default> or
use C<required =E<gt> 1>.

=head2 Explicit Syntax

You can still use explicit L<Getopt::Long> syntax if needed:

    'servers=s@' => { isa => ArrayRef[Str] }

If the explicit syntax differs from what would be inferred, a warning is issued.
Use C<nowarn =E<gt> 1> to suppress it:

    'servers=s@' => { isa => ArrayRef[Int], nowarn => 1 }

=head1 AUTHOR

Curtis "Ovid" Poe <curtis.poe@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Curtis "Ovid" Poe.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
