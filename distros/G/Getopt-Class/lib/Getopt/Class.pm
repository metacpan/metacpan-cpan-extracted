##----------------------------------------------------------------------------
## Getopt::Long with Class - ~/lib/Getopt/Class.pm
## Version v0.102.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2020/04/25
## Modified 2020/05/02
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Getopt::Class;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use Getopt::Long;
    use TryCatch;
    use DateTime;
    use DateTime::Format::Strptime;
    use Scalar::Util;
	use Devel::Confess;
    our $VERSION = 'v0.102.0';
};

sub init
{
    my $self  = shift( @_ );
    my $param = shift( @_ ) || return( $self->error( "No hash parameter was provided." ) );
    return( $self->error( "Hash of parameters provided ($param) is not an hash reference." ) ) if( !$self->_is_hash( $param ) );
    $self->SUPER::init( $param );
    $self->{configured} = 0;
    $self->{classes} = {};
    $self->{missing} = [];
    $self->{colour_open} = '<';
    $self->{colour_close} = '>';
    
    my $dict = $param->{dictionary} || return( $self->error( "No dictionary was provided to initiate Getopt::Long" ) );
    return( $self->error( "Dictionary provided is not a hash reference." ) ) if( !$self->_is_hash( $dict ) );
    $self->dictionary( $dict );
    
    ## Tie'ing will make sure that values set for a key or its aliases are populated to other aliases
    ## Getopt::Long already does it, but this takes care of synchronising values for all aliases AFTER Getopt::Long has processed the options
    ## So that if the user change an option value using an alias:, e.g.:
    ## last_name => { type => 'string', alias => [qw( surname )] }
    ## last_name and surname would have the same value set thanks to Getopt::Long
    ## --last-name = 'Einstein';
    ## But if, after, the user does something like:
    ## $opts->{surname} = 'Doe';
    ## $opts->{last_name} would still be 'Einstein'
    ## Getopt::Class::Alias ensures the values for aliases and original key are the same seamlessly
    ## The way tie works means we must tie en empty hash, because we cannot tie an already populated hash sadly enough
    my %options = ();
    my $tie = tie( %options, 'Getopt::Class::Alias', 
    {
        dict => $dict,
        debug => $self->{debug} 
    }) || return( $self->error( "Unable to get a Getopt::Class::Alias tie object." ) );
    $self->message( 3, "Tie object is: '$tie'." );
    
    $self->{configure_options} = [qw( no_ignore_case no_auto_abbrev auto_version auto_help )];
    my $opts = \%options;
    my $params = [];
    ## Build the options parameters
    foreach my $k ( sort( keys( %$dict ) ) )
    {
        my $k2_dash = $k;
        $k2_dash =~ tr/_/-/;
        my $k2_under = $k;
        $k2_under =~ tr/-/_/;
        
        my $def = $dict->{ $k };
        
        my $opt_name = [ $k2_under ];
        ## If the dictionary element is given with dash, e.g. some-thing, we replace it with some_thing, which is our standard
        ## and we set some-thing as an alias
        if( $k eq $k2_dash )
        {
            $dict->{ $k2_under } = CORE::delete( $dict->{ $k } );
            $k = $k2_under;
        }
        ## Add the dash option as an alias if it is not the same as the underscore one, such as when this is just one word, e.g. version
        CORE::push( @$opt_name, $k2_dash ) if( $k2_dash ne $k2_under );
        
        if( !ref( $def->{alias} ) && CORE::length( $def->{alias} ) )
        {
            $def->{alias} = [$def->{alias}];
        }
        ## Add the given aliases, if any
        if( $self->_is_array( $def->{alias} ) )
        {
            push( @$opt_name, @{$def->{alias}} ) if( scalar( @{$def->{alias}} ) );
            ## push( @$opt_name, $k2_under ) if( !scalar( grep( /^$k2_under$/, @{$def->{alias}} ) ) );
        }
        ## Now, also add the original key-something and key_something to the alias, so we can find them from one of the aliases
        ## When we do exec, we'll be able to find all the aliases
        $def->{alias} = [] if( !CORE::exists( $def->{alias} ) );
        CORE::push( @{$def->{alias}}, $k2_dash ) if( !scalar( grep( /^$k2_dash$/, @{$def->{alias}} ) ) );
        CORE::push( @{$def->{alias}}, $k2_under ) if( !scalar( grep( /^$k2_under$/, @{$def->{alias}} ) ) );
        $def->{alias} = Module::Generic::Array->new( $def->{alias} );
        
        my $opt = join( '|', @$opt_name );
        if( length( $def->{default} ) )
        {
            $opts->{ $k2_dash } = $def->{default};
        }
        else
        {
            $opts->{ $k2_dash } = '';
        }
        my $suff = '';
        if( $def->{type} eq 'string' )
        {
            $suff = '=s';
        }
        elsif( $def->{type} eq 'string-hash' )
        {
            $suff = '=s%';
        }
        elsif( $def->{type} eq 'array' )
        {
            $suff = '=s@';
            $opts->{ $k2_dash } = [] unless( length( $def->{default} ) );
        }
        elsif( $def->{type} eq 'boolean' )
        {
            $suff = '!';
        }
        elsif( $def->{type} eq 'hash' )
        {
            $suff = '=s%';
            $opts->{ $k2_dash } = {} unless( length( $def->{default} ) );
        }
        elsif( $def->{type} eq 'code' && ref( $def->{code} ) eq 'CODE' )
        {
            $opts->{ $k2_dash } = $def->{code};
        }
        elsif( $def->{type} eq 'integer' )
        {
            $suff = '=i';
        }
        elsif( $def->{type} eq 'decimal' )
        {
            $suff .= '=f';
        }
        elsif( $def->{type} eq 'date' || $def->{type} eq 'datetime' )
        {
            $suff = '=s';
        }
        elsif( $def->{type} eq 'code' )
        {
            return( $self->error( "Type is code, but there is no property code for this option \"$k\"." ) ) if( !CORE::exists( $def->{code} ) );
            return( $self->error( "Type is code, but the property code is not a code reference for this option \"$k\"." ) ) if( ref( $def->{code} ) ne 'CODE' );
            $opts->{ $k2_dash } = $def->{code};
        }
        
        if( $def->{min} )
        {
            ## If there is no max, it would be for example s{1,}
            ## 2nd formatter is %s because it could be blank. %d would translate to 0 when blank.
            $suff .= sprintf('{%d,%s}', @$def{ qw( min max ) } );
        }
        
        if( $def->{re} && ref( $def->{re} ) ne 'Regexp' )
        {
            return( $self->error( "Regular expression provided for property \"$k\" ($def->{re}) is not a proper regular expression. I was expecting something like qr// and of type 'Regexp'." ) );
        }
        push( @$params, $opt . $suff );
    }
    $self->options( $opts );
    $self->parameters( $params );
    $self->{getopt} = Getopt::Long::Parser->new;
    return( $self );
}

sub check_class_data
{
    my $self  = shift( @_ );
    my $class = shift( @_ ) || return( $self->error( "No class was provided to return its definition" ) );
    return( $self->error( "Class provided '$class' is not a string." ) ) if( ref( $class ) );
    my $p = {};
    $p = shift( @_ ) if( scalar( @_ ) && $self->_is_hash( $_[0] ) );
    $self->message( 3, "Checking data for class '$class'." );
    my $dict = $self->class( $class ) || return;
    $self->message( 3, "Dictionary data for class '$class' is: ", sub{ $self->dumper( $dict ) } );
    my $v = $self->get_class_values( $class ) || return;
    $self->message( 3, "Collected data is: ", sub{ $self->dumper( $v ) } );
    my $error = 
    {
    missing => {},
    regexp => {},
    };
    foreach my $f ( sort( keys( %$dict ) ) )
    {
        my $def = $dict->{ $f };
        my $n = $def->{name} ? $def->{name} : $f;
        $def->{error} ||= "does not match requirements";
        if( !!$p->{required} && $def->{required} )
        {
            if( ( $def->{type} =~ /^(?:boolean|decimal|integer|string)/ && !length( $v->{ $f } ) ) || 
                ( ( $def->{type} eq 'hash' || $def->{type} eq 'string-hash' ) && !scalar( keys( %{$v->{ $f }} ) ) ) ||
                ( $def->{type} eq 'array' && !scalar( @{$v->{ $f }} ) ) )
            {
                $errors->{missing}->{ $f } = "$f ($n) is missing";
                next;
            }
        }
        if( $def->{re} )
        {
            if( $def->{type} eq 'string' && length( $v->{ $f } ) && $v->{ $f } !~ /$def->{re}/ )
            {
                ## $self->message( 3, "Regular expression for $f is $def->{re}" );
                $errors->{regexp}->{ $f } = "$f ($n) " . $def->{error};
            }
            elsif( $def->{type} eq 'array' )
            {
                $self->message( 3, "Checking array data" );
                my $sub_err = [];
                foreach my $this ( @{$v->{ $f }} )
                {
                    if( $this !~ /$def->{re}/ )
                    {
                        push( @$sub_err, $this );
                    }
                }
                $errors->{regexp}->{ $f } = join( ', ', @$sub_err ) . ' ' . $def->{error};
            }
        }
        elsif( $def->{type} eq 'decimal' && $v->{ $f } !~ /^\d+(\.\d{1,12})?$/ )
        {
            $errors->{regexp}->{ $f } = "$f ($n) " . $def->{error};
        }
    }
    return( $errors );
}

sub class
{
    my $self  = shift( @_ );
    my $class = shift( @_ ) || return( $self->error( "No class was provided to return its definition" ) );
    return( $self->error( "Class provided '$class' is not a string." ) ) if( ref( $class ) );
    $self->message( 3, "Getting class dictionary for '$class'." );
    my $classes = $self->classes;
    return( $self->error( "I was expecting an hash reference for the classes dictionaries but got '$classes' instead." ) ) if( !ref( $classes ) );
    return( $self->error( "No class \"$class\" was found." ) ) if( scalar( keys( %$classes ) ) && !exists( $classes->{ $class } ) );
    my $dict = $self->dictionary;
    return( $self->error( "No dictionary data could be found!" ) ) if( !scalar( keys( %$dict ) ) );
    foreach my $k ( sort( keys( %$dict ) ) )
    {
        my $def = $dict->{ $k };
        next if( !exists( $def->{class} ) );
        my $class_names = $def->{class};
        my $k2 = $k;
        $k2 =~ tr/-/_/;
        foreach my $class ( @$class_names )
        {
            ## $self->message( 3, "Adding class $class" ) if( !exists( $classes->{ $class } ) );
            ## Create the class if it doe snot exists yet
            $classes->{ $class } = {} if( !exists( $classes->{ $class } ) );
            my $this = $classes->{ $class };
            ## Then add the property and it definition hash
            $this->{ $k2 } = $def;
            ## If there are any alias, we add them too
            if( $def->{alias} && scalar( @{$def->{alias}} ) )
            {
                foreach my $f ( @{$def->{alias}} )
                {
                    my $f2 = $f;
                    $f2 =~ tr/-/_/;
                    $this->{ $f } = $this->{ $f2 } = $def;
                }
            }
        }
    }
    return( $self->error( "No class \"$class\" was found." ) ) if( !exists( $classes->{ $class } ) );
    return( $classes->{ $class } );
}

sub classes { return( shift->_set_get_hash( 'classes', @_ ) ); }

sub class_properties
{
    my $self  = shift( @_ );
    my $class = shift( @_ );
    return( $self->error( "No class was provided to list its properties." ) ) if( !length( $class ) );
    $self->message( "Showing all properties for class \"$class\"." );
    my $fields = [];
    my $ref = $self->class( $class );
    my $props = [ sort( keys( %$ref ) ) ];
    return( Module::Generic::Array->new( $props ) );
}

sub configure
{
    my $self = shift( @_ );
    return( $self ) if( $self->{configured} );
    $self->message( 3, "Called to configure Getopt::Long" );
    my $conf = [];
    $conf = shift( @_ ) if( ref( $_[0] ) );
    $conf = $self->configure_options if( !scalar( @$conf ) );
    $self->message( 3, "Using configuration parameters: '", join( "', '", @$conf ), "'." );
    my $getopt = $self->getopt || return( $self->error( "No Getopt::Long::Parser object found." ) );
    try
    {
        $getopt->configure( @$conf );
        $self->{configured} = 1;
    }
    catch( $e )
    {
        return( $self->error( "An error occurred while configuration Getlong::Opt: $e" ) );
    }
    return( $self );
}

sub configure_errors { return( shift->_set_get_array_as_object( 'configure_errors', @_ ) ); }

sub configure_options { return( shift->_set_get_array_as_object( 'configure_options', @_ ) ); }

sub dictionary { return( shift->_set_get_hash( 'dictionary', @_ ) ); }

sub exec
{
    my $self = shift( @_ );
    $self->configure || return;
    my $errors = [];
    my $missing = [];
    my $dict = $self->dictionary;
    return( $self->error( "The data returned by dictionary() is not an hash reference." ) ) if( !$self->_is_hash( $dict ) );
    return( $self->error( "Somehow, the dictionary hash is empty!" ) ) if( !scalar( keys( %$dict ) ) );
    my $opts = $self->options;
    return( $self->error( "The data returned by options() is not an hash reference." ) ) if( !$self->_is_hash( $opts ) );
    return( $self->error( "Somehow, the options hash is empty!" ) ) if( !scalar( keys( %$opts ) ) );
    my $params = $self->parameters;
    return( $self->error( "Data returned by parameters() is not an array reference" ) ) if( !$self->_is_array( $params ) );
    return( $self->error( "Somehow, the parameters array is empty!" ) ) if( !scalar( @$params ) );
    my $getopt = $self->getopt || return( $self->error( "No Getopt::Long object found." ) );
    my $required = $self->required;
    return( $self->error( "Data returned by required() is not an array reference" ) ) if( !$self->_is_array( $required ) );
    my $tie = tied( %$opts ) || return( $self->error( "Unable to get the tie object for the options value hash." ) );
    
    local $Getopt::Long::SIG{ '__DIE__' } = sub
    {
        push( @$errors, join( '', @_ ) );
    };
    local $Getopt::Long::SIG{ '__WARN__' } = sub
    {
        push( @$errors, join( '', @_ ) );
    };
    $self->configure_errors( $errors );
    
    $self->message( 3, "Enabling aliasing." );
    $tie->enable( 1 );
    $getopt->getoptions( $opts, @$params ) || do
    {
        my $usage = $self->usage;
        return( $usage->() ) if( ref( $usage ) eq 'CODE' );
        return;
    };
    $self->message( 3, "Options data is: ", sub{ $self->dumper( $opts ) } );
    
    foreach my $key ( @$required )
    {
        if( exists( $opts->{ $key } ) &&
            ( !defined( $opts->{ $key } ) || 
              !length( $opts->{ $key } ) || 
              $opts->{ $key } =~ /^[[:blank:]]*$/ ||
              ( ref( $opts->{ $key } ) eq 'SCALAR' && 
                ( !length( ${$opts->{ $key }} ) || ${$opts->{ $key }} =~ /^[[:blank:]]*$/ ) 
              ) ||
              (
                ref( $opts->{ $key } ) eq 'ARRAY' &&
                !scalar( @{$opts->{ $key }} )
              )
            ) 
        )
        {
            push( @$missing, $key );
        }
    }
    $self->missing( $missing );
    
    ## Maybe I should remove this block of code since it is not really necessary
    ## init() takes care of declaring necessary aliases to Getopt::Long
#     foreach my $k ( sort( keys( %$opts ) ) )
#     {
#         next if( index( $k, '-' ) == -1 );
#         my $k2 = $k;
#         $k2 =~ tr/-/_/;
#         $opts->{ $k2 } = $opts->{ $k };
#     }
    
    ## Enable our aliases value auto-propagation
#     $tie->enable( 1 );
    ## This only process data and does not check their validity beyond what Getopt::Long has already done
    foreach my $k ( sort( keys( %$dict ) ) )
    {
#         my $k2_dash = $k;
#         $k2_dash =~ tr/_/-/;
#         my $k2_under = $k;
#         $k2_under =~ tr/-/_/;
#         next if( !length( $opts->{ $k2_dash } ) && !length( $opts->{ $k2_under } ) );
#         my $def = ( $dict->{ $k2_under } || $dict->{ $k2_dash } );
        
        next if( !length( $opts->{ $k } ) );
        my $def = $dict->{ $k };
        return( $self->error( "Dictionary is malformed with entry $k value not being an hash reference." ) ) if( ref( $def ) ne 'HASH' );
        ## If there are aliases, make sure the value submitted is also available with the aliases
#         if( $def->{alias} )
#         {
#             ## Hopefully, this should trigger the tie::STORE method
#             ## $opts->{ $k } = $opts->{ $k };
#             ## _message( 3, "Processing optiona $k with value \"$opts->{$k}\" with aliases: '", join( "', '", @{$def->{alias}} ), "'." );
#             $tie->enable( 0 );
#             foreach my $f ( @{$def->{alias}} )
#             {
#                 my $f2_dash = $f;
#                 my $f2_under = $f;
#                 $f2_dash =~ tr/_/-/;
#                 $f2_under =~ tr/-/_/;
#                 $opts->{ $f2_dash } = $opts->{ $k } unless( length( $opts->{ $f2_dash } ) );
#                 $opts->{ $f2_under } = $opts->{ $k } unless( length( $opts->{ $f2_under } ) );
#             }
#             $tie->enable( 1 );
#         }
        
        ## Not needed anymore, because FETCH in Getopt::Class::Alias will return automatically the dereferenced value of the scalar
#         if( ref( $def->{default} ) eq 'SCALAR' )
#         {
#             $opts->{ $k2_dash } = $opts->{ $k2_under } = $opts->{ $k } = ${$opts->{ $k }};
#         }
        
        if( ( $def->{type} eq 'date' || $def->{type} eq 'datetime' ) && length( $opts->{ $k } ) )
        {
            $self->message( 3, "Found a date/datetime field \"$k\"." );
            if( $opts->{ $k } =~ /^\d+$/ )
            {
                try
                {
                    my $dt = DateTime->from_epoch( epoch => $opts->{ $k } );
                    $opts->{ $k } = $dt;
#                     $opts->{ $k2_dash } = $dt;
#                     $opts->{ $k2_under } = $dt;
                }
                catch( $e )
                {
                    return( $self->error( "An unexpected error occurred while converting date provided for \"$k\" (", $v->{ $k }, "): $e" ) );
                }
            }
            elsif( $def->{type} eq 'date' && $opts->{ $k } =~ /^(?<year>\d{4})-(?<month>\d{1,2})-(?<day>\d{1,2})$/ )
            {
                try
                {
                    my $dt = DateTime->new(
                        year => int( $+{year} ),
                        month => int( $+{month} ),
                        day => int( $+{day} ),
                        hour => 0,
                        minute => 0,
                        second => 0,
                        time_zone => 'local',
                    );
#                     $opts->{ $k2_dash } = $dt;
#                     $opts->{ $k2_under } = $dt;
                    $opts->{ $k } = $dt;
                    ## my $ts = $dt->epoch;
                }
                catch( $e )
                {
                    return( $self->error( "An unexpected error occurred while converting date provided for \"$k\" (", $v->{ $k }, "): $e" ) );
                }
            }
            elsif( $def->{type} eq 'datetime' && $opts->{ $k } =~ /^(?<year>\d{4})-(?<month>\d{1,2})-(?<day>\d{1,2})(?:T|\s)(?<hour>\d{1,2})\:(?<minute>\d{1,2})\:(?<second>\d{1,2})$/ )
            {
                try
                {
                    my $dt = DateTime->new(
                        year => int( $+{year} ),
                        month => int( $+{month} ),
                        day => int( $+{day} ),
                        hour => int( $+{hour} ),
                        minute => int( $+{minute} ),
                        second => int( $+{second} ),
                        time_zone => 'local',
                    );
#                     $opts->{ $k2_dash } = $dt;
#                     $opts->{ $k2_under } = $dt;
                    $opts->{ $k } = $dt;
                    ## my $ts = $dt->epoch;
                }
                catch( $e )
                {
                    return( $self->error( "An unexpected error occurred while converting date provided for \"$k\" (", $v->{ $k }, "): $e" ) );
                }
            }
            elsif( $opts->{ $k } eq 'now' || $opts->{ $k } eq 'today' )
            {
                my $dt = DateTime->now( time_zone => 'local' );
#                 $opts->{ $k2_dash } = $dt;
#                 $opts->{ $k2_under } = $dt;
                $opts->{ $k } = $dt;
            }
            else
            {
                return( $self->error( "Unsuported value for date or datetime \"$k\": ", $v->{ $k }, ". Please use a unix timestamp (i.e. an integer) or an iso 8601 type like 2019-12-25 or 2019-12-25T07:30:10" ) );
            }
            ## Default format for stringification is the unix timestamp
            my $fmt = DateTime::Format::Strptime->new(
                pattern => '%s',
                locale => 'en_GB',
                time_zone => 'local',
            );
#             $opts->{ $k2_dash }->set_formatter( $fmt );
#             $opts->{ $k2_under }->set_formatter( $fmt );
            $opts->{ $k }->set_formatter( $fmt );
        }
        elsif( $def->{type} eq 'array' )
        {
#             $opts->{ $k2_dash } = $opts->{ $k2_under } = Module::Generic::Array->new( $opts->{ $k } );
            $opts->{ $k } = Module::Generic::Array->new( $opts->{ $k } );
        }
        elsif( $def->{type} eq 'hash' ||
               $def->{type} eq 'string-hash' )
        {
#             $opts->{ $k2_dash } = $opts->{ $k2_under } = $self->_set_get_hash_as_object( $k2_under, $opts->{ $k } );
            $self->message( 3, "Setting hash as object for property '$k' and with data: ", sub{ $self->dumper( $opts->{ $k } ) } );
            $opts->{ $k } = $self->_set_get_hash_as_object( $k, $opts->{ $k } );
        }
        elsif( $def->{type} eq 'boolean' )
        {
#             $opts->{ $k2_dash } = $opts->{ $k2_under } = ( $opts->{ $k } ? $self->true : $self->false );
            $self->message( 3, "Processing boolean value for \"$k\" and current value '", $opts->{ $k }, "'." );
            $opts->{ $k } = ( $opts->{ $k } ? $self->true : $self->false );
            $self->message( 3, "Setting boolean value for \"$k\" with value '", $opts->{ $k }, "'" );
        }
        elsif( $def->{type} eq 'string' )
        {
#             $opts->{ $k2_dash } = $opts->{ $k2_under } = Module::Generic::Scalar->new( $opts->{ $k } );
            $opts->{ $k } = Module::Generic::Scalar->new( $opts->{ $k } );
        }
        elsif( $def->{type} eq 'integer' || $def->{decimal} )
        {
#             $opts->{ $k2_dash } = $opts->{ $k2_under } = $self->_set_get_number( $k, $opts->{ $k } );
            ## Even though this is a number, this was set as a scalar reference, so we need to dereference it
            if( $self->_is_scalar( $opts->{ $k } ) )
            {
                $opts->{ $k } = Module::Generic::Scalar->new( $opts->{ $k } );
            }
            else
            {
                $opts->{ $k } = $self->_set_get_number( $k, $opts->{ $k } );
            }
        }
        
#         $tie->enable( 0 );
#         my $k2_dash = $k;
#         $k2_dash =~ tr/_/-/;
#         my $k2_under = $k;
#         $k2_under =~ tr/-/_/;
#         $opts->{ $k2_dash } = $opts->{ $k } if( $k2_dash ne $k );
#         $opts->{ $k2_under } = $opts->{ $k } if( $k2_under ne $k );
#         $self->message_colour( 3, "Set field \"<green>${k2_dash}</>\" to \"<red>$opts->{$k}</>\"." );
#         $self->message_colour( 3, "Set field \"<green>${k2_under}</>\" to \"<red>$opts->{$k}</>\"." );
#         if( $def->{alias} )
#         {
#             ## Hopefully, this should trigger the tie::STORE method
#             ## $opts->{ $k } = $opts->{ $k };
#             ## _message( 3, "Processing optiona $k with value \"$opts->{$k}\" with aliases: '", join( "', '", @{$def->{alias}} ), "'." );
#             foreach my $f ( @{$def->{alias}} )
#             {
#                 my $f2_dash = $f;
#                 my $f2_under = $f;
#                 $f2_dash =~ tr/_/-/;
#                 $f2_under =~ tr/-/_/;
#                 $opts->{ $f2_dash } = $opts->{ $k } unless( length( $opts->{ $f2_dash } ) );
#                 $opts->{ $f2_under } = $opts->{ $k } unless( length( $opts->{ $f2_under } ) );
#             }
#         }
        $tie->enable( 1 );
    }
    
    $tie->enable( 0 );
    ## Make sure we can access each of the options dictionary definition not just from the original key, but also from any of it aliases
    my $done = {};
    foreach my $k ( keys( %$dict ) )
    {
        next if( $done->{ $k } );
        my $def = $dict->{ $k };
        my $aliases = $def->{alias};
        foreach my $a ( @$aliases )
        {
            next if( $a eq $k || $done->{ $a } );
            $dict->{ $a } = $def;
            $done->{ $a }++;
        }
        $done->{ $k }++;
    }
    $tie->enable( 1 );
    $self->message( 3, "Options data are now: ", sub{ $self->dumper( $opts ) } );
    ## return( $opts );
    ## e return a Getopt::Class::Values object, so we can call the option values hash key as method:
    ## $object->metadata / $object->metadata( $some_hash );
    ## instead of:
    ## $object->{metadata}
    ## return( $opts );
    my $o = Getopt::Class::Values->new({
        data => $opts,
        dict => $dict,
        debug => $self->{debug},
    }) || return( $self->pass_error( Getopt::Class::Values->error ) );
    return( $o );
}

sub get_class_values
{
    my $self  = shift( @_ );
    my $class = shift( @_ ) || return( $self->error( "No class was provided to return its definition" ) );
    return( $self->error( "Class provided '$class' is not a string." ) ) if( ref( $class ) );
    my $this_dict = $self->class( $class ) || return;
    my $opts = $self->options;
    return( $self->error( "The data returned by options() is not an hash reference." ) ) if( !$self->_is_hash( $opts ) );
    return( $self->error( "Somehow, the options hash is empty!" ) ) if( !scalar( keys( %$opts ) ) );
    my $v = {};
    $v = shift( @_ ) if( scalar( @_ ) && $self->_is_hash( $_[0] ) );
    foreach my $f ( sort( keys( %$this_dict ) ) )
    {
        my $ref = lc( Scalar::Util::reftype( $opts->{ $f } ) );
        if( $ref eq 'hash' )
        {
            $v->{ $f } = $opts->{ $f } if( scalar( keys( %{$opts->{ $f }} ) ) > 0 );
        }
        elsif( $ref eq 'array' )
        {
            $v->{ $f } = $opts->{ $f } if( scalar( @{$opts->{ $f }} ) > 0 );
        }
        elsif( !length( $ref ) )
        {
            $v->{ $f } = $opts->{ $f } if( length( $opts->{ $f } ) );
        }
    }
    return( $v );
}

sub getopt { return( shift->_set_get_object( 'getopt', 'Getopt::Long::Parser', @_ ) ); }

sub missing { return( shift->_set_get_array_as_object( 'missing', @_ ) ); }

sub options { return( shift->_set_get_hash( 'options', @_ ) ); }

sub parameters { return( shift->_set_get_array_as_object( 'parameters', @_ ) ); }

sub required { return( shift->_set_get_array_as_object( 'required', @_ ) ); }

sub usage { return( shift->_set_get_code( 'usage', @_ ) ); }

package Getopt::Class::Values;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
};

sub new
{
    my $that = shift( @_ );
    my %hash = ();
    my $obj = tie( %hash, 'Getopt::Class::Repository' );
    my $self = bless( \%hash => ( ref( $that ) || $that ) )->init( @_ );
    $obj->enable( 1 );
    return( $self );
}

sub init
{
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;
    $self->{data} = {};
    $self->{dict} = {};
    ## Can only set properties that exist
    $self->{_init_strict} = 1;
    $self->SUPER::init( @_ );
    # $self->{_data_repo} = 'data';
    return( $self->error( "No dictionary as provided." ) ) if( !$self->{dict} );
    return( $self->error( "Dictionary provided is not an hash reference." ) ) if( !$self->_is_hash( $self->{dict} ) );
    scalar( keys( %{$self->{dict}} ) ) || return( $self->error( "No dictionary data was provided." ) );
    return( $self->error( "Data provided is not an hash reference." ) ) if( !$self->_is_hash( $self->{data} ) );
    my $call_offset = 0;
    while( my @call_data = caller( $call_offset ) )
    {
        unless( $call_offset > 0 && $call_data[0] ne $class && (caller($call_offset-1))[0] eq $class )
        {
            $call_offset++;
            next;
        }
        last if( $call_data[9] || ( $call_offset > 0 && (caller($call_offset-1))[0] ne $class ) );
        $call_offset++;
    }
    my $bitmask = ( caller( $call_offset ) )[9];
    my $offset = $warnings::Offsets{uninitialized};
    my $should_display_warning = vec( $bitmask, $offset, 1 );
    $self->{warnings} = $should_display_warning;
    return( $self );
}

AUTOLOAD
{
    my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
    # my( $class, $method ) = our $AUTOLOAD =~ /^(.*?)::([^\:]+)$/;
    no overloading;
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;
    ## Options dictionary
    my $dict = $self->{dict};
    ## Values provided on command line
    ## my $data = $self->{data};
    ## printf( STDERR "AUTOLOAD: \$data has %d items and property '$method' has value '%s'\n", scalar( keys( %$self ) ), $self->{ $method } );
    ## return if( !CORE::exists( $data->{ $method } ) );
    return if( !CORE::exists( $self->{ $method } ) );
    my $f = $method;
    ## Dictionary definition for this particular option field
    my $def = $dict->{ $f };
    if( $def->{type} eq 'string' ||
        Scalar::Util::reftype( $self->{ $f } ) eq 'SCALAR' )
    {
        return( $self->_set_get_scalar_as_object( $f, @_ ) );
    }
    elsif( $def->{type} eq 'boolean' )
    {
        $self->message( 3, "Returning boolean value for '$f': '", $data->{ $f }, "'." );
        return( $self->_set_get_boolean( $f, @_ ) );
    }
    elsif( $def->{type} eq 'integer' ||
           $def->{type} eq 'decimal' )
    {
        return( $self->_set_get_number( $f, @_ ) );
    }
    elsif( $def->{type} eq 'date' ||
           $def->{type} eq 'datetime' )
    {
        return( $self->_set_get_datetime( $f, @_ ) );
    }
    elsif( $def->{type} eq 'array' )
    {
        return( $self->_set_get_array_as_object( $f, @_ ) );
    }
    elsif( $def->{type} eq 'hash' || 
           $def->{type} eq 'string-hash' )
    {
        return( $self->_set_get_hash_as_object( $f, @_ ) );
    }
    elsif( $def->{type} eq 'code' )
    {
        return( $self->_set_get_code( $f, @_ ) );
    }
    else
    {
        warn( "I do not know what to do with this property \"$f\" type \"$def->{type}\". Using scalar.\n" ) if( $self->{warnings} );
        return( $self->_set_get_scalar( $f, @_ ) );
    }
};

package Getopt::Class::Repository;
BEGIN
{
    use strict;
    use warnings;
    use parent -norequire, qw( Tie::Hash );
    use Scalar::Util;
    use constant VALUES_CLASS => 'Getopt::Class::Value';
};

## tie( %self, 'Getopt::Class::Repository' );
## Used by Getopt::Class::Values to ensure that whether the data are accessed as methods or as hash keys,
## in either way it returns the option data
## Actually option data are stored in the Getopt::Class::Values object data property
sub TIEHASH
{
    my $self  = shift( @_ );
    my $class = ref( $self ) || $self;
    return( bless( {} => $class ) );
}

sub CLEAR
{
    my $self = shift( @_ );
    my $data = $self->{data};
    my $caller = caller;
    %$data = ();
}

sub DELETE
{
    my $self = shift( @_ );
    my $data = $self->{data};
    my $key  = shift( @_ );
    if( caller eq VALUES_CLASS || !$self->{enable} )
    {
        CORE::delete( $self->{ $key } );
    }
    else
    {
        CORE::delete( $data->{ $key } );
    }
}

sub EXISTS
{
    my $self = shift( @_ );
    my $data = $self->{data};
    my $key  = shift( @_ );
    if( caller eq VALUES_CLASS || !$self->{enable} )
    {
        CORE::exists( $self->{ $key } );
    }
    else
    {
        CORE::exists( $data->{ $key } );
    }
}

sub FETCH
{
    my $self = shift( @_ );
    my $data = $self->{data};
    my $key  = shift( @_ );
    my $caller = caller;
    ## print( STDERR "FETCH($caller)[enable=$self->{enable}] <- '$key''\n" );
    if( caller eq VALUES_CLASS || !$self->{enable} )
    {
        ## print( STDERR "FETCH($caller)[enable=$self->{enable}] <- '$key' <- '$self->{$key}'\n" );
        return( $self->{ $key } )
    }
    else
    {
        ## print( STDERR "FETCH($caller)[enable=$self->{enable}] <- '$key' <- '$self->{$key}'\n" );
        return( $data->{ $key } );
    }
}

sub FIRSTKEY
{
    my $self = shift( @_ );
    my $data = $self->{data};
    my @keys = ();
    if( caller eq VALUES_CLASS || !$self->{enable} )
    {
        @keys = keys( %$self );
    }
    else
    {
        @keys = keys( %$data );
    }
    $self->{ITERATOR} = \@keys;
    return( shift( @keys ) );
}

sub NEXTKEY
{
    my $self = shift( @_ );
    my $data = $self->{data};
    my $keys = ref( $self->{ITERATOR} ) ? $self->{ITERATOR} : [];
    return( shift( @$keys ) );
}

sub SCALAR
{
    my $self  = shift( @_ );
    my $data = $self->{data};
    if( caller eq VALUES_CLASS || !$self->{enable} )
    {
        return( "$self" );
    }
    else
    {
        return( "$data" );
    }
}

sub STORE
{
    my $self  = shift( @_ );
    my $class = ref( $self );
    my $data = $self->{data};
    my $caller = caller;
    my( $key, $val ) = @_;
    ## print( STDERR "STORE($caller)[enable=$self->{enable}] -> '$key'\n" );
    if( caller eq VALUES_CLASS || !$self->{enable} )
    {
        ## print( STDERR "STORE($caller)[enable=$self->{enable}] -> '$key' -> '$val'\n" );
        $self->{ $key } = $val;
    }
    else
    {
        ## print( STDERR "STORE($caller)[enable=$self->{enable}] -> '$key' -> '$val'\n" );
        $data->{ $key } = $val;
    }
}

sub enable
{
    my $self = shift( @_ );
    if( @_ )
    {
        $self->{enable} = shift( @_ );
    }
    return( $self->{enable} );
}

## This is an alternative to perl feature of refealiasing
## https://metacpan.org/pod/perlref#Assigning-to-References
package Getopt::Class::Alias;
BEGIN
{
    use strict;
    use warnings;
    use parent -norequire, qw( Getopt::Class::Repository Module::Generic );
    use Scalar::Util;
};

## tie( %$opts, 'Getopt::Class::Alias', $dictionary );
sub TIEHASH
{
    my $self  = shift( @_ );
    my $class = ref( $self ) || $self;
    ## Valid options are:
    ## dict: options dictionary
    ## debug
    my $opts  = {};
    $opts = shift( @_ ) if( @_ );
    ## print( STDERR __PACKAGE__ . "::TIEHASH() called with following arguments: '", join( ', ', @_ ), "'.\n" );
    my $call_offset = 0;
    while( my @call_data = caller( $call_offset ) )
    {
        ## printf( STDERR "[$call_offset] In file $call_data[1] at line $call_data[2] from subroutine %s has bitmask $call_data[9]\n", (caller($call_offset+1))[3] );
        unless( $call_offset > 0 && $call_data[0] ne $class && (caller($call_offset-1))[0] eq $class )
        {
            ## print( STDERR "Skipping package $call_data[0]\n" );
            $call_offset++;
            next;
        }
        last if( $call_data[9] || ( $call_offset > 0 && (caller($call_offset-1))[0] ne $class ) );
        $call_offset++;
    }
    ## print( STDERR "Using offset $call_offset with bitmask ", ( caller( $call_offset ) )[9], "\n" );
    my $bitmask = ( caller( $call_offset - 1 ) )[9];
    my $offset = $warnings::Offsets{uninitialized};
    ## print( STDERR "Caller (2)'s bitmask is '$bitmask', warnings offset is '$offset' and vector is '", vec( $bitmask, $offset, 1 ), "'.\n" );
    my $should_display_warning = vec( $bitmask, $offset, 1 );
    
    my $dict = $opts->{dict} || do
    {
        warn( "No dictionary was provided to Getopt::Class:Alias\n" ) if( $should_display_warning );
        return;
    };
    if( ref( $dict ) ne 'HASH' )
    {
        warn( "Dictionary provided is not an hash reference.\n" ) if( $should_display_warning );
        return;
    }
    elsif( !scalar( keys( %$dict ) ) )
    {
        CORE::warn( "The dictionary hash reference provided is empty.\n" ) if( $should_display_warning );
        return;
    }
    my $hash = 
    {
    data => {},
    dict => $dict,
    warnings => $should_display_warning,
    debug => ( $opts->{debug} || 0 ),
    ## _data_repo => 'data',
    colour_open => '<',
    colour_close => '>',
    };
    return( bless( $hash => $class ) );
}

sub FETCH
{
    my $self = shift( @_ );
    my $data = $self->{data};
    ## my $dict = $self->{dict};
    my $key  = shift( @_ );
    ## my $def = $dict->{ $key };
    return( $data->{ $key } );
}

sub STORE
{
    my $self  = shift( @_ );
    my $class = ref( $self );
    my $data = $self->{data};
    my( $pack, $file, $line ) = caller;
    ## $self->message( 3, "Called with following parameters: '", join( "', '", @_ ), "'." );
    my( $key, $val ) = @_;
    $self->message_colour( 3, "Called from line $line in file \"$file\" for property \"<green>$key</>\" with reference (<black on white>", ref( $val ), "</>) and value \"<red>$val</>\">" );
    my $dict = $self->{dict};
    my $enabled = $self->{enable};
    if( $enabled )
    {
        $self->message( 3, "Aliasing is enabled. Value provided has reference (", ref( $val ), ")." );
        my $def = $dict->{ $key } ||
        return( $self->error( "No dictionary definition found for \"$key\"." ) );
        # $self->messagef( 3, "Found dictionary definition '$def' for %s with %d properties.", $key, scalar( keys( %$def ) ) );
        return( $self->error( "I was expecting an array reference for this alias, but instead got '$def->{alias}'." ) ) if( !$self->_is_array( $def->{alias} ) );
        my $alias = $def->{alias} || 
        return( "No alias property found. This should not happen." );
#         $self->messagef_colour( 3, 'Found alias "{green}' . $alias . '{/}" with %d elements: {green}"%s"{/}', scalar( @$alias ), $alias->join( "', '" ) );
        $self->messagef_colour( 3, "Found alias '<green>$alias</>' with %d elements: <green>'%s'</>", scalar( @$alias ), $alias->join( "', '" ) );
        if( Scalar::Util::reftype( $alias ) ne 'ARRAY' )
        {
            return( $self->error( "Alias property is not an array reference. This should not happen." ) );
        }
        $self->message_colour( 3, "Setting primary property \"<green>${key}</>\" to value \"<black on white>${val}</>\"." );
        $data->{ $key } = $val;
        foreach my $a ( @$alias )
        {
            next if( $a eq $key );
            ## We do not set the value, if for some reason, the user would have removed this key
            $self->message_colour( 3, "Setting alias \"<green>${a}</>\" to value \"<val black on white>${val}</>\"." );
            $data->{ $a } = $val if( CORE::exists( $data->{ $a } ) );
        }
    }
    else
    {
        $data->{ $key } = $val;
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

Getopt::Class - Extended dictionary version of Getopt::Long

=head1 SYNOPSIS

    use Getopt::Class;
    our $DEBUG = 0;
    our $VERBOSE = 0;
    our $VERSION = '0.1';
    my $dict =
    {
        create_user     => { type => 'boolean', alias => [qw(create_person create_customer)], action => 1 },
        create_product  => { type => 'boolean', action => 1 },
        debug           => { type => 'integer', default => \$DEBUG },
        help            => { type => 'code', code => sub{ pod2usage(1); }, alias => '?', action => 1 },
        man             => { type => 'code', code => sub{ pod2usage( -exitstatus => 0, -verbose => 2 ); }, action => 1 },
        quiet           => { type => 'boolean', default => 0, alias => 'silent' },
        verbose         => { type => 'boolean', default => \$VERBOSE, alias => 'v' },
        version         => { type => 'code', code => sub{ printf( "v%.2f\n", $VERSION ); }, action => 1 },
    
        api_server      => { type => 'string', default => 'api.example.com' },
        api_version     => { type => 'string', default => 1 },
        as_admin        => { type => 'boolean' },
        dry_run         => { type => 'boolean', default => 0 },
    
        name            => { type => 'string', class => [qw( person product )] },
        created         => { type => 'datetime', class => [qw( person product )] },
        define          => { type => 'string-hash', default => {} },
        langs           => { type => 'array', class => [qw( person product )], re => qr/^[a-z]{2}([_|-][A-Z]{2})?/, min => 1, default => [qw(en)] },
        currency        => { type => 'string', class => [qw(product)], name => 'currency', re => qr/^[a-z]{3}$/, error => "must be a three-letter iso 4217 value" },
        age             => { type => 'integer', class => [qw(person)], name => 'age', },
    };
    
    # Assuming command line arguments like:
    prog.pl --create-user --name Bob --langs fr ja --age 30 --created now --debug 3

    my $opt = Getopt::Class->new({
        dictionary => $dict,
    }) || die( Getopt::Class->error, "\n" );
    my $opts = $opt->exec || die( $opt->error, "\n" );
    $opt->required( [qw( name langs )] );
    my $err = $opt->check_class_data( 'person' );
    printf( "User is %s and is %d years old\n", $opts{qw( name age )} ) if( $opts->{debug} );

    # Get all the properties for class person
    my $props = $opt->class_properties( 'person' );

    # Get values collected for class 'person'
    if( $opts->{create_user} )
    {
        my $values = $opt->get_class_values( 'person' );
        # Having collected the values for our class of properties, and making sure all 
        # required are here, we can add them to database or make api calls, etc
    }
    elsif( $opts->{create_product} )
    {
        # etc...
    }
    
    # Or you can also access those values as object methods
    if( $opts->create_product )
    {
        $opts->langs->push( 'en_GB' ) if( !$opts->langs->lang );
        printf( "Created on %s\n", $opts->created->iso8601 );
    }

=head1 VERSION

    v0.102.0

=head1 DESCRIPTION

L<Getopt::Class> is a lightweight wrapper around L<Getopt::Long> that implements the idea of class of properties and makes it easier and powerful to set up L<Getopt::Long>. This module is particularly useful if you want to provide several sets of options for different features or functions of your program. For example, you may have a part of your program that deals with user while another deals with product. Each of them needs their own properties to be provided.

=head1 CONSTRUCTOR

=head2 new

To instantiate a new L<Getopt::Class> object, pass an hash reference of following parameters:

=over 4

=item I<dictionary>

This is required. It must contain a key value pair where the value is an anonymous hash reference that can contain the following parameters:

=over 8

=item I<alias>

This is an array reference of alternative options that can be used in an interchangeable way

    my $dict =
    {
    last_name => { type => 'string', alias => [qw( family_name surname )] },
    };
    # would make it possible to use either of the following combinations
    --last-name Doe
    # or
    --surname Doe
    # or
    --family-name Doe

=item I<default>

This contains the default value. For a string, this could be anything, and also a reference to a scalar, such as:

    our $DEBUG = 0;
    my $dict =
    {
    debug => { type => 'integer', default => \$DEBUG },
    };

It can also be used to provide default value for an array, such as:

    my $dict =
    {
    langs => { type => 'array', class => [qw( person product )], re => qr/^[a-z]{2}([_|-][A-Z]{2})?/, min => 1, default => [qw(en)] },
    };

But beware that if you provide a value, it will not superseed the existing default value, but add it on top of it, so

    --langs en fr ja

would not produce an array with C<en>, C<fr> and C<ja> entries, but an array such as:

    ['en', 'en', 'fr', 'ja' ]

because the initial default value is not replaced when one is provided. This is a design from L<Getopt::Long> and although I could circumvent this, I a not sure I should.

=item I<error>

A string to be used to set an error by L</"check_class_data">. Typically the string should provide meaningful information as to what the data should normally be. For example:

    my $dict =
    {
    currency => { type => 'string', class => [qw(product)], name => 'currency', re => qr/^[a-z]{3}$/, error => "must be a three-letter iso 4217 value" },
    };

=item I<max>

This is well explained in L<Getopt::Long/"Options with multiple values">

It serves "to specify the minimal and maximal number of arguments an option takes".

=item I<min>

Same as above

=item I<re>

This must be a regular expression and is used by L</"check_class_data"> to check the sanity of the data provided by the user.
So, for example:

    my $dict =
    {
    currency => { type => 'string', class => [qw(product)], name => 'currency', re => qr/^[a-z]{3}$/, error => "must be a three-letter iso 4217 value" },
    };

then the user calls your program with, among other options:

    --currency euro

would set an error that can be retrieved as an output of L</"check_class_data">

=item I<required>

Set this to true or false (1 or 0) to instruct L</"check_class_data"> whether to check if it is missing or not.

This is an alternative to the L</"required"> method which is used at an earlier stage, during L</"exec">

=item I<type>

Type can be I<array>, I<boolean>, I<code>, I<decimal>, I<hash>, I<integer>, I<string>, I<string-hash>

Type I<hash> is convenient for free key-value pair such as:

    --define customer_id=10 --define transaction_id 123

would result for C<define> with an anonymous hash as value containing C<customer_id> with value C<10> and C<transaction_id> with value C<123>

Type code implies an anonymous sub routine and should be accompanied with the attribute I<code>, such as:

    { type => 'code', code => sub{ pod2usage(1); exit( 0 ) }, alias => '?', action => 1 },

Also as seen in the example above, you can add additional properties to be used in your program, here such as I<action> that could be used to identify all options that are used to trigger an action or a call to a sub routine.

=back

=item I<debug>

This takes an integer, and is used to set the level of debugging. Anything under 3 will not provide anything meaningful.

=back

=head1 METHODS

=head2 check_class_data

Provided with a string corresponding to a class name, this will check the data provided by the user.

Currently this means it checks if the data is present when the attribute I<required> is set, and it checks the data against a regular expression if one is provided with the attribute I<re>

It returns an hash reference with 2 keys: I<missing> and I<regexp>. Each with an anonymous hash reference with key matching the option name and the value the error string. So:

    my $dict =
    {
    name => { type => 'string', class => [qw( person product )], required => 1 },
    langs => { type => 'array', class => [qw( person product )], re => qr/^[a-z]{2}([_|-][A-Z]{2})?/, min => 1, default => [qw(en)] },
    };

Assuming your user calls your program without C<--name> and with C<--langs FR EN> this would have L</"check_class_data"> return the following data structure:

    $errors =
    {
    missing => { name => "name (name) is missing" },
    regexp => { langs => "langs (langs) does not match requirements" },
    };

=head2 class

Provided with a string representing a property class, and this returns an hash reference of all the dictionary entries matching this class

=head2 classes

This returns an hash reference containing class names, each of which has an anonymous hash reference with corresponding dictionary entries

=head2 class_properties

Provided with a string representing a class name, this returns an array reference of options, a.k.a. class properties.

The array reference is a L<Module::Generic::Array> object.

=head2 configure

This calls L<Getopt::Long/"configure"> with the L</"configure_options">.

It can be overriden by calling L</"configure"> with an array reference.

If there is an error, it will return undef and set an L</"error"> accordingly.

Otherwise, it returns the L<Getopt::Class> object, so it can be chained.

=head2 configure_errors

This returns an array reference of the errors generated by L<Getopt::Long> upon calling L<Getopt::Long/"getoptions"> by L</"exec">

The array is an L<Module::Generic::Array> object

=head2 configure_options

This returns an array reference of the L<Getopt::Long> configuration options upon calling L<Getopt::Long/"configure"> by method L</"configure">

The array is an L<Module::Generic::Array> object

=head2 dictionary

This returns the hash reference representing the dictionary set when the object was instantiated. See L</"new"> method.

=head2 error

Return the last error set as a L<Module::Generic::Exception> object. Because the object can be stringified, you can do directly:

    die( $opt->error, "\n" ); # with a stack trace

or

    die( sprintf( "Error occurred at line %d in file %s with message %s\n", $opt->error->line, $opt->error->file, $opt->error->message ) );

=head2 exec

This calls L<Getopt::Long/"getoptions"> with the L</"options"> hash reference and the L</"parameters"> array reference and after having called L</"configure"> to configure L<Getopt::Long> with the proper parameters according to the dictionary provided at the time of object instantiation.

If there are any L<Getopt::Long> error, they can be retrieved with method L</"configure_errors">

    my $opt = Getopt::Class->new({ dictionary => $dict }) || die( Getopt::Class->error );
    my $opts = $opt->exec || die( $opt->error );
    if( $opt->configure_errors->length > 0 )
    {
        # do something about it
    }

If any required options have been specified with the method L</"required">, it will check any missing option then and set an array of those missing options that can be retrieved with method L</"missing">

This method makes sure that any option can be accessed with underscore or dash whichever, so a dictionary entry such as:

    my $dict =
    {
    create_customer => { type => 'boolean', alias => [qw(create_client create_user)], action => 1 },
    };

can be called by your user like:

    ---create-customer
    # or
    --create-client
    # or
    --create-user

because a duplicate entry with the underscore replaced by a dash is created (actually it's an alias of one to another). So you can say in your program:

    my $opts = $opt->exec || die( $opt->error );
    if( $opts->{create_user} )
    {
        # do something
    }

L</"exec"> returns an hash reference whose properties can be accessed directly, but those properties can also be accessed as methods.

This is made possible because the hash reference returned is a blessed object from L<Getopt::Class::Values> and provides an object oriented access to all the option values.

A string is an object from L<Module::Generic::Scalar>

    $opts->customer_name->index( 'Doe' ) != -1

A boolean is an object from L<Module::Generic::Boolean>

An integer or decimal is an object from L<Text::Number>

A date/dateime value is an object from L<DateTime>

    $opts->created->iso8601 # 2020-05-01T17:10:20

An hash reference is an object created with L<Module::Generic/"_set_get_hash_as_object">

    $opts->metadata->transaction_id

An array reference is an object created with L<Module::Generic/"_set_get_array_as_object">

    $opts->langs->push( 'en_GB' ) if( !$opts->langs->exists( 'en_GB' ) );
    $opts->langs->forEach(sub{
        $self->active_user_lang( shift( @_ ) );
    });

Whatever the object type of the option value is based on the dictionary definitions you provide to L</"new">

=head2 get_class_values

Provided with a string representing a property class, and this returns an hash reference of all the key-value pairs provided by your user. So:

    my $dict =
    {
    create_customer => { type => 'boolean', alias => [qw(create_client create_user)], action => 1 },
    name        => { type => 'string', class => [qw( person product )] },
    created     => { type => 'datetime', class => [qw( person product )] },
    define      => { type => 'string-hash', default => {} },
    langs       => { type => 'array', class => [qw( person product )], re => qr/^[a-z]{2}([_|-][A-Z]{2})?/, min => 1, default => [] },
    currency    => { type => 'string', class => [qw(product)], name => 'currency', re => qr/^[a-z]{3}$/, error => "must be a three-letter iso 4217 value" },
    age         => { type => 'integer', class => [qw(person)], name => 'age', },
    };

Then the user calls your program with:

    --create-user --name Bob --age 30 --langs en ja --created now

    # In your app
    my $opt = Getopt::Class->new({ dictionary => $dict }) || die( Getopt::Class->error );
    my $opts = $opt->exec || die( $opt->error );
    # $vals being an hash reference as a subset of all the values returned in $opts above
    my $vals = $opt->get_class_values( 'person' )
    # returns an hash only with keys name, age, langs and created

=head2 getopt

Sets or get the L<Getopt::Long::Parser> object. You can provide yours if you want but beware that certain options are necessary for L<Getopt::Class> to work. You can check those options with the method L</"configure_options">

=head2 missing

Returns an array of missing options. The array reference returned is a L<Module::Generic::Array> object, so you can do thins like

    if( $opt->missing->length > 0 )
    {
        # do something
    }

=head2 options

Returns an hash reference of options created by L</"new"> based on the dictionary you provide. This hash reference is used by L</"exec"> to call L<Getopt::Long/"getoptions">

=head2 parameters

Returns an array reference of parameters created by L</"new"> based on the dictionary you provide. This hash reference is used by L</"exec"> to call L<Getopt::Long/"getoptions">

This array reference is a L<Module::Generic::Array> object

=head2 required

Set or get the array reference of required options. This returns a L<Module::Generic::Array> object.

=head2 usage

Set or get the anonymous subroutine or sub routine reference used to show the user the proper usage of your program.

This is called by L</"exec"> after calling L<Getopt::Long/"getoptions"> if there is an error, i.e. if L<Getopt::Long/"getoptions"> does not return a true value.

If you use object to call the sub routine usage, I recommend using the module L<curry>

If this is not set, L</"exec"> will simply return undef or an empty list depending on the calling context.

=head1 ERROR HANDLING

This module never dies, or at least not by design. If an error occurs, each method returns undef and sets an error that can be retrieved with the method L</"error">

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Getopt::Longs>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
