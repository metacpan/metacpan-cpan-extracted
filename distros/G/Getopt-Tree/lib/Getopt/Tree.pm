package Getopt::Tree;

use strict;
use Text::Wrap;
use Getopt::Long qw( :config no_auto_abbrev no_getopt_compat no_permute require_order no_ignore_case_always );
use File::Basename;

BEGIN {
    use Exporter ();
    our ( @ISA, @EXPORT );

    @ISA    = qw(Exporter);
    @EXPORT = qw/ parse_command_line print_usage /;
}

use vars qw( $VERSION );
$VERSION = '1.12';

use constant ABBR_PARAM_SEPARATOR        => ', ';
use constant ABBR_PARAM_SEPARATOR_LENGTH => length( ABBR_PARAM_SEPARATOR );
use constant DEPTH_STR                   => '  ';

our $USAGE_HEADER = '';
our $USAGE_FOOTER = '';
our $SWITCH_PREFIX_STR = '-';

=head1 NAME

Getopt::Tree - Get tree-like options (like the route command).

=head1 ABSTRACT

Getopt::Tree is a module to help parse and validate command line parameters
built on top of Getopt::Long. Getopt::Tree allows the developer to specify an
array parameters, including the name, abbreviation, type, description, and any
parameters that are applicable to and/or dependent on that parameter.

=head1 EXAMPLE

=head2 Simple "route" example

 # Accept the commands add, remove, print, and their associated dependent
 # options.
 my $p = [
     {
         name     => 'add',
         exists   => 1,
         descr    => 'Add a new route',
         params   => [
             {
                 name => 'gateway',
                 abbr => 'gw',
                 descr => 'Remote gateway for this network',
             },
             {
                 name => 'network',
                 abbr => 'net',
                 descr => 'Network address to add route for',
             },
             {
                 name => 'subnet',
                 abbr => 'mask',
                 descr => 'Subnet mask for the given network',
             },
         ],
     },
     {
         name     => 'remove',
         abbr     => 'delete',
         exists   => 1,
         descr    => 'Delete a route',
         params   => [
             {
                 name => 'network',
                 abbr => 'net',
                 descr => 'Network address to delete',
             },
             {
                 name => 'subnet',
                 abbr => 'mask',
                 descr => 'Subnet mask for the given network',
             },
         ],
     },
     {
         name     => 'print',
         exists   => 1,
         descr    => 'Display routing table',
     }, 
 ];
 
=head2 Complex example

 my $p = [
     # Required global parameter.
     { name => 'user', leaf => 1, eval => sub { my ( $p ) = @_; return 1 if $p =~ /^[a-z]+$/i; },
     # Optional global parameter.
     {
         name     => 'no-cache',
         abbr     => 'nc',
         exists   => 1,
         optional => 1,
         descr    => 'Don\'t cache your credentials in /tmp/.'
     },
     # Start of a branch. If one or more branches exist, at least one must be
     # followed.
     {
         name   => 'search',
         abbr   => 's',
         descr  => 'Search for ticket, list tickets in queue, or print contents of a ticket.',
         params => [
            {
                 name   => 'ticket', # field name
                 abbr   => 't',      # alternate name  
                 re     => TICKET_REGEX, # field must match re
                 descr  => 'The ticket number to search for.', # auto-doc
                 params => [
                     { # fields that are allowed if this field is set
                         name     => 'show-all-worklog-fields',
                         exists   => 1, # I just want a 1 or a 0 if set
                         optional => 1,
                         descr    => 'Show all worklog fields.'
                     },
                     {
                         name     => 'show-all-fields',
                         multi    => 1, # can be set multiple times, returns arrayref
                         exists   => 1, # unless exists is set too, then you just get the count
                         descr    => 'Show all ticket fields.'
                     },
                 ],
            },
         ],
     }
 ];
 my ( $operation, $params ) = parse_command_line( $p );
 if ( !$operation ) { print_usage( $p ); die; }
 print "Performing $operation!\n"

=head1 USAGE

Two functions are exported by default: L<parse_command_line> and
L<print_usage>.

=head2 Functions

=head3 parse_command_line

Parses the command line (@ARGV) based on the specified data structure.

Accepts two parameters. The first is a required array reference describing the
possible command line parameters. It returns three values, the "top level"
option, a hashref of the other specified options, and an arrayref of any
remaining unparsed options (similar to Getopt::Long).

The second parameter is an optional array reference or string from which the
parameters are to be read, rather than reading them from @ARGV. If a string is
passed, it will be converted to an array via C<Text::ParseWords::shellwords>.

If the command line was unable to be parsed (the passed data structure was
inconsistent, etc), parse_command_line will die with an appropriate error
message. If the command line was invalid (the user entered something that did
not meet the given requirements, etc) a warning will be printed and undef will
be returned.

=head3 print_usage

Prints usage information based on the specified data structure.

Takes two parameters, the first is a required array reference describing the
possible command line parameters, and the second is an optional file handle to
which the usage information will be printed. Alternately, in place of a
filehandle, a hashref of options can be passed. Valid options are:

=over 4

=item fh

The filehandle to print to. If not set, no output is printed.

=item return

A boolean value that determines whether or not the usage should be returned as
a string.

=item wrap_at

Number of characters to wrap the output at. Will be auto-detected from
$ENV{COLUMNS} if not set, defaults to 80 if auto-detection fails.

=item hide_top_line

Hides the top line of output which contains the program name how to pass
switches.

=back

Usage information is generated mostly from the "descr" fields in the data
structure, indentation is based on parameter dependence, parameters that accept
values are noted, and optional parameters are presented inside of brackets.

=head2 Configuration

The "expected command line configuration data structure" will be referred to as
"the data structure" because I can't think of a better name for it.

=head3 Concepts

The design is similar to the Unix "route" command, in which a "top level"
command (such as "add" or "delete") will have zero or more dependent parameters
(such as the "gateway" or "subnet"). Getopt::Tree uses Getopt::Long to actually
parse the command line, but adds a layer of logic on top to discover which
top level command and dependent options the user specified. Conflicting
options, parameter types, and usage document generation are all handled by
Getopt::Tree based on the data structure supplied by the developer.

Commands are separated into two types, top level and dependent. At least on top
level command is required. Once Getopt::Tree identifies the proper top level
command, it will look for the dependent commands that apply to the specified
top level command. Since each dependent command can also have dependent
commands, the process is repeated until no more commands are found.

Each set of dependents in the tree is considered a "level", with the top level
being the first set of entries in the structure, and each successive level
being composed of the dependents of the prior level. Note that a level could
simply be described as the distance to the top of a tree, where as a "branch"
would be the specific set of dependents for a given command, irrespective of
dependents of commands on the same level.

=head3 Data Structure

The data structure is composed of an array of hashrefs. Each hashref describes
a single parameter. Each hashref in the array contains various options
describing the parameter. Valid options are as follows:

=head4 name

Full parameter name. Required. Must not contain the characters "@", "|", or "="
and must not conflict with other names or abbreviations in the same branch.
This is the name that will be returned, if the parameter is set, by
L<parse_command_line>.

=head4 abbr

Parameter abbreviation. Will be accepted on the command line in place of the
proper name, but must obey the same rules as the proper name.

=head4 optional

Defines whether this parameter is optional. Boolean. Defaults to false, ie, the
parameter is required.

=head4 exists

Defines whether or not the parameter has a value or whether it should simply be
checked for existence.  Boolean. Defaults to false, ie, the parameter must have
a value.

=head4 leaf

Defines whether or not the parameter should be considered a "leaf" on the
current branch or not. A leaf is a required parameter at the current level and
has no dependents. Useful to place a required parameter that applies to
multiple branches without specifying the required parameter in each branch.
Conflicts with "optional" and "params".  Defaults to false, ie, this parameter
is not a leaf.

=head4 params

An optional arrayref of hashrefs representing parameters dependent on this
parameter. Format is exactly the same as for the primary data structure.

=head4 descr

Textural description of what the parameter is and does. Used as part of the
usage information. If not set, a placeholder is supplied.

=head4 multi

Defines whether or not this parameter can be specified multiple times or not.
Boolean. Defaults to false.

=head4 re

Defines a regular expression to match values against. The result of the first
capture of this expression will be treated as the value in place of the
user-specified value. If no capture is found or the match fails, the parameter
will be treated as invalid. Conflicts with "exists". If both "re" and "eval"
are specified, "re" will be processed first and the result passed to "eval".

=head4 eval

Defines a subroutine to be called to validate the value passed for this
parameter. The returned value from the subroutine will be used in place of the
user-specified value. If undef is returned, the parameter is treated as
invalid. Conflicts with "exists". If both "re" and "eval" are specified, "re"
will be processed first and the result passed to "eval".

=head1 VARIABLES

=head2 $Getopt::Tree::USAGE_HEADER

Text to be printed near the top of the "usage" output.

=head2 $Getopt::Tree::USAGE_HEADER

Text to be printed at the end of the "usage" output.

=head2 $Getopt::Tree::SWITCH_PREFIX_STR

Characters to prefix a switch. Defaults to a single hyphen ('-'). Can be set to
an empty string to use switchless options (Note: This option is not well
tested!).

=head1 NOTES

You can't have a dependent parameter of the same name as a non-optional
parameter higher in the tree.  If the parser sees a two instances of the same
parameter it will bail, so you have to make sure that there are no identically
named parameters in one part of the tree as in another part of the tree that
the parser passes through. Example:

 { name => 'bad' },
 { name => 'normal', params => [ { name => 'bad' }, { name => 'bad2' } ] }
 { name => 'normal2', params => [ { name => 'bad2' } ] }

Both of the 'bad' entries will collide when the user specifies 'normal', since
the parser passes through the top level and the normal->params level. However,
bad2 will never collide because the parser will never pass through both levels.

Also, identical abbreviations are not checked for or corrected. They will
probably cause problems.

=cut

# Process the name and abbreviations into something Getopt::Long would like.
sub process_getopt_params {
    my ( $param_array ) = @_;
    my @param_array;
    my $p_name;

    foreach my $param_ref ( @{$param_array} ) {
        if ( !$param_ref->{name} ) { die "Parameter lacks a name!"; }
        if ( $param_ref->{name} =~ /[=|@]/ ) { die "Parameter names should not contain [=|@]!"; }
        if ( $param_ref->{name} =~ /^-/ ) { die "Parameter names should not begin with a dash!"; }
        if ( $param_ref->{abbr} ) {
            if ( $param_ref->{abbr} =~ /[-=|]@/ ) { die "Parameter abbreviations should not contain [=|@]!"; }
            if ( $param_ref->{abbr} =~ /^-/ ) { die "Parameter abbreviations should not begin with a dash!"; }
            $p_name = $param_ref->{name} . '|' . $param_ref->{abbr};
        } else {
            $p_name = $param_ref->{name};
        }
        if ( $param_ref->{multi} ) {
            $p_name .= '=s@';
        } elsif ( !$param_ref->{exists} ) {
            $p_name .= '=s';
        }
        push @param_array, $p_name;
        if ( $param_ref->{params} ) { push @param_array, process_getopt_params( $param_ref->{params} ); }
    }
    return @param_array;
}

# Check to see if a given parameter is valid (handles exists, checks against passed regex,
# runs associated code blocks, etc).
# Returns ( status, value ). Sorry.
sub calc_param_value {
    my ( $top_level, $g_opts ) = @_;
    my $v = $g_opts->{ $top_level->{name} };

    # If all they want is 'exists', quickly check and return.
    if ( $top_level->{exists} ) {
        if ( $top_level->{multi} ) {
            if ( ref $v eq 'ARRAY' ) {
                return ( 1, scalar( @{$v} ) );
            } else {
                die "Should be an array?";
            }
        }
        return ( 1, 1 );
    }

    if ( $top_level->{re} ) {
        if ( $top_level->{multi} ) {
            my $result = [];
            if ( ref $v eq 'ARRAY' ) {
                foreach my $entry ( @{$v} ) {
                    $entry =~ $top_level->{re};
                    if ( !defined $1 ) { return ( 0, undef ); }
                    push @{$result}, $1;
                }
            } else {
                die "Should be an array?";
            }
            $v = $result;
        } else {
            $v =~ $top_level->{re};
            if ( !defined $1 ) { return ( 0, undef ); }
            $v = $1;
        }
    }
    if ( $top_level->{eval} ) {
        $v = $top_level->{eval}->( $v, $g_opts );
        if ( !defined $v ) { return ( 0, undef ); }
    }
    return ( 1, $v );
}

# Recursive function to check the user's input against our data structure.
sub check_parameter {
    my ( $g_opts, $params ) = @_;

    my @approved_flags;
    my $this_level;
    my $this_level_is_a_leaf = 1;
    # This is a bit of a pain, but we have to track existence of leaves
    # separately from regular parameters. Since we don't recurse into a leaf
    # like we do a branch, we can't let check_parameter() handle the existence
    # test for us.
    my %matched_leaves;

    foreach my $top_level ( @{$params} ) {
        if ( $top_level->{params} && $top_level->{leaf} ) {
            die "Invalid settings! You can not specify params and leaf!";
        }
        if ( !$top_level->{optional} && !$top_level->{leaf} ) {
            $this_level_is_a_leaf = 0;
        }
        # This level has a flag that was passed on the command line
        if ( defined $g_opts->{ $top_level->{name} } ) {
            # We only get one non-optional command per branch in the tree
            if ( $top_level->{optional} ) {
                my ( $status, $v ) = calc_param_value( $top_level, $g_opts );
                if ( !$status ) { warn "Invalid value for $top_level->{name}!\n"; return; }
                $g_opts->{ $top_level->{name} } = $v;
                push @approved_flags, $top_level->{name};
            } elsif ( $top_level->{leaf} ) {
                my ( $status, $v ) = calc_param_value( $top_level, $g_opts );
                if ( !$status ) { warn "Invalid value for $top_level->{name}!\n"; return; }
                $g_opts->{ $top_level->{name} } = $v;
                push @approved_flags, $top_level->{name};
                $matched_leaves{ $top_level->{name} } = 1;
            } else {
                if ( $this_level ) {
                    # Already got a required parameter for this level, can't accept two!
                    warn "Can not specify $this_level and $top_level->{name}\n";
                    return;
                }
                $this_level = $top_level->{name};

                my ( $status, $v ) = calc_param_value( $top_level, $g_opts );
                if ( !$status ) { warn "Invalid value for $top_level->{name}!\n"; return; }
                $g_opts->{ $top_level->{name} } = $v;
                push @approved_flags, $top_level->{name};
            }
            if ( $top_level->{params} && !$top_level->{leaf} ) {
                my ( $status, @a ) = check_parameter( $g_opts, $top_level->{params} );
                if ( !$status ) { return; }
                push @approved_flags, @a;
            }
        }
    }
    foreach my $l ( grep { $_->{leaf} } @{$params} ) {
        if ( !$matched_leaves{ $l->{name} } ) {
            warn "Missing the following parameter: $l->{name}\n";
            return;
        }
    }

    # We didn't match a parameter on this level and this level requires at
    # least one match!
    if ( ( !$this_level ) && ( !$this_level_is_a_leaf ) ) {
        my @missing = map { $_->{name} } @{$params};
        warn "Missing one (or more) of the following parameters: " . join( ', ', @missing ) . "\n";
        return;
    }

    return 1, @approved_flags;
}

# Sets up the recursive call to check_parameter. This handles the first
# parameter in a special manner. A lot of this is probably unnecessary. Returns
# two values, the first is the "operation name" (the name of the first level
# parameter we matched on) and the hash of parameter name => value pairs.
# This function is exported.
sub parse_command_line {
    my ( $params, $source ) = @_;
    my @getopt_params;
    my %g_opts;
    my $status;
    my $op_ref;
    my $argv_index = 0;
    my $op;
    my $remaining_options;

    if ( !$SWITCH_PREFIX_STR || $SWITCH_PREFIX_STR ne '-' ) {
        my $t = $SWITCH_PREFIX_STR || '(?:)';
        Getopt::Long::Configure( "prefix_pattern=$t" );
    }

    if ( !defined $source ) {
        $source = \@ARGV;
    } elsif ( !ref $source ) {
        require Text::ParseWords;
        $source = [ Text::ParseWords::shellwords($source) ];
    }

    # We can check our ARGV source for the first top level branch (non-optional
    # and non-leaf) here, and then use that when we process that branch (only)
    # below.
    ARGV_INDEX_LOOP: while ( 1 ) {
        $op = $source->[ $argv_index++ ];
        last if !defined $op;

        # If we encounter a value without a parameter before we find a top
        # level op, abort with an error. Any values tied to a parameter should
        # be skipped in the loop below.
        # Is this really necessary? Any problems would be caught below
        #  --jeagle 20110411
        #die "The command '$op' is not valid!\n" unless $op =~ /^-/;
        if ( $SWITCH_PREFIX_STR ) {
            $op =~ s/^\Q$SWITCH_PREFIX_STR\E//;
        }
        foreach my $known_ops ( @{$params} ) {
            if ( !$known_ops->{name} ) { die 'Invalid name!'; }
            if (   ( $op eq $known_ops->{name} )
                || ( ( $known_ops->{abbr} ) && ( $op eq $known_ops->{abbr} ) ) )
            {
                if ( ( $known_ops->{optional} ) || ( $known_ops->{leaf} ) ) {
                    if ( !$known_ops->{exists} ) {
                        $argv_index++;
                    }
                    next ARGV_INDEX_LOOP;
                }
                $op     = $known_ops->{name};
                $op_ref = $known_ops;
                last ARGV_INDEX_LOOP;
                #            if ( !$known_ops->{params} ) { return $op, { $op => 1 }; }
            }
        }
        if ( !$op_ref ) {
            warn "The command '$op' is unknown!\n";
            return;
        }
    }

    if ( !$op ) { return; }

    # Gather up all of the global non-branch parameters to pass to GetOptions.
    # While we're at it, check to make sure the parameters are correct
    my @global_options;
    foreach my $optional_ops ( @{$params} ) {
        next unless ( $optional_ops->{optional} ) || ( $optional_ops->{leaf} );
        if ( !$optional_ops->{name} ) { die 'Invalid name!'; }
        push @global_options, $optional_ops;
    }

    if ( @global_options ) { push @getopt_params, process_getopt_params( \@global_options ); }
    push @getopt_params, process_getopt_params( [$op_ref] );
    foreach my $p ( @getopt_params ) {
        my ( $root ) = $p =~ /^(.+)=?/;
        foreach my $k ( keys %g_opts ) {
            if ( $k =~ /^\Q$root\E/ ) {
                if ( $k ne $p ) {
                    die "Duplicate parameter $p (matched $k) with different type specifications!\n";
                }
            }
        }
    }
    undef %g_opts;

    eval {
        local $SIG{__WARN__} = sub { };
        # GetOptionsFromArray behaves badly unless called fully qualified. Not
        # interested in tracking down why.
        ( my $getopt_success, $remaining_options ) =
            Getopt::Long::GetOptionsFromArray( $source, \%g_opts, @getopt_params );
        return unless $getopt_success;
    };
    undef @getopt_params;

    # Find the top-level parameter we're going to work with.
    ( $status, @getopt_params ) = check_parameter( \%g_opts, [$op_ref] );
    return unless $status;

    if ( @global_options ) {
        ( $status, @global_options ) = check_parameter( \%g_opts, \@global_options );
        return unless $status;
        push @getopt_params, @global_options;
    }

    # By this point, %g_opts contains everything the user passed, and @global_options
    # is everything that should have been passed.

    my %good_values;
    my $all_good = 1;
    @good_values{@getopt_params} = ();
    foreach my $k ( keys( %g_opts ) ) {
        if ( !exists $good_values{$k} ) {
            warn "Invalid parameter: $k\n";
            $all_good = 0;
        }
    }

    if ( !$all_good ) {
        warn "Not all good!";
        return;
    }
    return $op, \%g_opts, $remaining_options;
}

# Pre-scan to get the width of all of the parameters
sub get_usage_param_width {
    my ( $params, $depth, $length ) = @_;
    if ( !defined $depth ) { $depth = 0; }
    my $param_length = ( $length || 1 );

    foreach my $top_level ( @{$params} ) {
        my $this_length = ( length( DEPTH_STR ) * $depth ) + length( $top_level->{name} ) + 1;
        if ( $top_level->{abbr} ) {
            $this_length += length( $top_level->{abbr} ) + ABBR_PARAM_SEPARATOR_LENGTH + 1;
        }
        if ( $top_level->{optional} ) {
            $this_length += 4;    # length of '[ ' . ' ]'
        }
        if ( !$top_level->{exists} ) {
            $this_length += 5;    # length of _<..>
        }

        if ( $this_length > $param_length ) {
            $param_length = $this_length;
        }
        if ( $top_level->{params} ) {
            $param_length = get_usage_param_width( $top_level->{params}, $depth + 1, $param_length );
        }
    }
    return $param_length;
}

sub print_actual_usage {
    my ( $params, $param_width, $depth ) = @_;
    if ( !defined $depth ) { $depth = 0; }
    my $d   = DEPTH_STR x $depth;
    my $out = '';
    my $switch_prefix = $SWITCH_PREFIX_STR || '';
    return '' unless ref $params eq 'ARRAY';

    # Print the parameters (recursively) with optional parameters first.
    foreach my $top_level (
        sort {
            if ( ( $a->{optional} || 0 ) == ( $b->{optional} || 0 ) )
            {
                return $a->{name} cmp $b->{name};
            } else {
                if ( $a->{optional} ) { return -1; }
                if ( $b->{optional} ) { return 1; }
                return 0;
            }
        } @{$params} )
    {
        # Don't show the leading dash on the first parameter (command).
        #my $param_desc = ( ( $depth == 0 && !$top_level->{optional} ) ? '' : '-' ) . $top_level->{name};
        my $param_desc = $switch_prefix . $top_level->{name};
        if ( $top_level->{abbr} ) {
            $param_desc = $param_desc . ABBR_PARAM_SEPARATOR
             #. ( ( $depth == 0 && !$top_level->{optional} ) ? '' : '-' )
             . $switch_prefix . $top_level->{abbr};
        }
        if ( !$top_level->{exists} ) {
            $param_desc .= ' <..>';
        }
        if ( $top_level->{optional} ) {
            $param_desc = '[ ' . $param_desc . ' ]';
        }
        $param_desc = sprintf( "%-${param_width}.${param_width}s  ", $d . $param_desc );

        $out .= wrap(
            $param_desc,
            ' ' x ( $param_width + 2 ),
            ( $top_level->{descr} || '(No description provided.)' ) ) . "\n";
        if ( $top_level->{params} ) {
            $out .= print_actual_usage( $top_level->{params}, $param_width, $depth + 1 );
        }
    }

    return $out;
}

# Calculate widths and set off the recursive call to print_actual_usage.
# This function is exported.
# Woah! Why did this get so complicated? Well, prior to 1.12 we accepted the
# second parameter as a filehandle to print to. In 1.12 I realized that was
# silly, and it would be better to just return the usage as a string. So now,
# for backward-compatability sake, we must support all of the options. Passing
# a filehandle causes us to print to that with an appropriate width. No
# filehandle will assume STDOUT as the filehandle. Passing a hash causes us to
# read various options from that hash.
sub print_usage {
    my ( $params, $fh_or_options )  = @_;
    my $param_width = get_usage_param_width( $params );
    my $options;

    if ( !defined $fh_or_options ) {
        $options = { fh => *STDERR, return => 0 };
    } elsif ( ref $fh_or_options eq 'HASH' ) {
        # Copy it in case the caller wants to re-use.
        $options = \%{ $fh_or_options };
    } else {
        $options = { fh => $fh_or_options, return => 0 };
    }
    if ( $options->{fh} && !$options->{wrap_at} ) {
        if ( ( -t $options->{fh} ) && ( defined $ENV{COLUMNS} ) ) {
            $options->{wrap_at} = $ENV{COLUMNS};
        }
    }
    if ( !$options->{wrap_at} || $options->{wrap_at} !~ /^\d{1,4}$/ ) {
        $options->{wrap_at} = 80;
    }

    local $Text::Wrap::unexpand = 0;
    local $Text::Wrap::columns  = $options->{wrap_at};
    my $usage_short = '';

    foreach my $p ( @{ $params } ) {
        if ( $p->{leaf} ) {
            $usage_short .= "-$p->{name} ";
        }
    }

    my $usage_str = '';

    if ( !$options->{hide_top_line} ) {
        $usage_str = 'Usage: ' .  basename( $0 ) .  wrap( '', '', " <command> ${usage_short}\[flags\]\n" ) . "\n";
    }

    if ( $USAGE_HEADER ) {
        $usage_str .= $USAGE_HEADER;
    }

    $usage_str .= "Options:\n" . print_actual_usage( $params, $param_width ), "\n";

    if ( $USAGE_FOOTER ) {
        $usage_str .= $USAGE_FOOTER;
    }

    if ( $options->{fh} ) { print {$options->{fh}} $usage_str; }
    if ( $options->{return} ) { return $usage_str; }
}

=head1 CHANGES

=head2 Version 1.12, 20100411, jeagle

Add ability to return usage as a string.

Add ability to set the prefix character via $Getopt::Tree::SWITCH_PREFIX_STR

Remove automatic -help flag.

Fix a silly bug causing parameter values that evaluate to false to fail.

=head2 Version 1.11, 20100917, jeagle

Appease older versions of Perl in print_usage's usage of square brackets in
a string.

=head2 Version 1.10, 20100709, jeagle

Correct handling of eval flags mixed with other flags.

Add optional destination filehandle to print_usage.

Clean up for export to CPAN.

=head2 Version 1.9, 20100428, jeagle

Show usage if no parameters are passed.

=head2 Version 1.8, 20100427, jeagle

Add $Version variable.

Give a better error message for parameters passed without a leading '-'.

=head2 Version 1.4, 20100427, jeagle

Add automatic -help flag parsing. This feature may cause problems if users
wanted to override '-help', so this may change in the future.

Show required leaf parmeters at the top usage line, reformat usage a little.

=cut

1;
