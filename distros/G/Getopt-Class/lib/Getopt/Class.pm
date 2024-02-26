##----------------------------------------------------------------------------
## Getopt::Long with Class - ~/lib/Getopt/Class.pm
## Version v1.0.0
## Copyright(c) 2024 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2020/04/25
## Modified 2024/02/23
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
    use vars qw( $VERSION );
    use Clone;
    use DateTime;
    use DateTime::Format::Strptime;
	use Devel::Confess;
    use Getopt::Long;
    use Module::Generic::Array;
    use Module::Generic::File qw( file );
    use Module::Generic::Scalar;
    use Nice::Try;
    use Scalar::Util;
    our $VERSION = 'v1.0.0';
};

use strict;
use warnings;

sub init
{
    my $self  = shift( @_ );
    my $param = shift( @_ ) || return( $self->error( "No hash parameter was provided." ) );
    return( $self->error( "Hash of parameters provided ($param) is not an hash reference." ) ) if( !$self->_is_hash( $param ) );
    $self->SUPER::init( $param ) || return( $self->pass_error );
    $self->{configured} = 0;
    $self->{classes} = {};
    $self->{missing} = [];
    $self->{colour_open} = '<';
    $self->{colour_close} = '>';
    my $dict = $param->{dictionary} || return( $self->error( "No dictionary was provided to initiate Getopt::Long" ) );
    return( $self->error( "Dictionary provided is not a hash reference." ) ) if( !$self->_is_hash( $dict ) );
    $self->dictionary( $dict );
    
    # Set the aliases hash reference used to contain each of the option aliases,e ach pointing to the same dictionary definition
    $self->{aliases} = {};
    
    # Tie'ing will make sure that values set for a key or its aliases are populated to other aliases
    # Getopt::Long already does it, but this takes care of synchronising values for all aliases AFTER Getopt::Long has processed the options
    # So that if the user change an option value using an alias:, e.g.:
    # last_name => { type => 'string', alias => [qw( surname )] }
    # last_name and surname would have the same value set thanks to Getopt::Long
    # --last-name = 'Einstein';
    # But if, after, the user does something like:
    # $opts->{surname} = 'Doe';
    # $opts->{last_name} would still be 'Einstein'
    # Getopt::Class::Alias ensures the values for aliases and original key are the same seamlessly
    # The way tie works means we must tie en empty hash, because we cannot tie an already populated hash sadly enough
    my %options = ();
    my $tie = tie( %options, 'Getopt::Class::Alias', 
    {
        dict => $dict,
        aliases => $self->{aliases},
        # debug => $self->{debug} 
    }) || return( $self->error( "Unable to get a Getopt::Class::Alias tie object: ", Getopt::Class::Alias->error ) );
    
    $self->{configure_options} = [qw( no_ignore_case no_auto_abbrev auto_version auto_help )];
    my $opts = \%options;
    my $params = [];

    foreach my $k ( sort( keys( %$dict ) ) )
    {
        my $k2_dash = $k;
        $k2_dash =~ tr/_/-/;
        my $k2_under = $k;
        $k2_under =~ tr/-/_/;
        
        my $def = $dict->{ $k };
        next if( $def->{__no_value_assign} );

        # Do some pre-processing work for booleans
        if( $def->{type} eq 'boolean' && !exists( $def->{mirror} ) )
        {
            my $mirror_opt;
            # If this is a boolean, add their counterpart, if necessary
            if( substr( $k, 0, 5 ) eq 'with_' && 
                !exists( $dict->{ 'without_' . substr( $k, 5 ) } ) )
            {
                $mirror_opt = 'without_' . substr( $k, 5 );
            }
            elsif( substr( $k, 0, 8 ) eq 'without_' && 
                   !exists( $dict->{ 'with_' . substr( $k, 8 ) } ) )
            {
                $mirror_opt = 'with_' . substr( $k, 8 );
            }
            elsif( substr( $k, 0, 7 ) eq 'enable_' && 
                   !exists( $dict->{ 'disable_' . substr( $k, 7 ) } ) )
            {
                $mirror_opt = 'disable_' . substr( $k, 7 );
            }
            elsif( substr( $k, 0, 8 ) eq 'disable_' && 
                   !exists( $dict->{ 'enable_' . substr( $k, 8 ) } ) )
            {
                $mirror_opt = 'enable_' . substr( $k, 8 );
            }
            
            if( defined( $mirror_opt ) )
            {
                my $false = 0;
                my $val = exists( $def->{default} )
#                     ? ( Scalar::Util::reftype( $def->{default} // '' ) eq 'SCALAR' || ref( $def->{default} // '' ) eq 'CODE' )
                    ? ( $self->_is_scalar( $def->{default} ) || $self->_is_code( $def->{default} ) || ref( $def->{default} ) )
                        ? $def->{default}
                        : \$def->{default}
                    : exists( $def->{code} )
                        ? $def->{code}
                        : \$false;
                my $copy = Clone::clone( $def );
                $dict->{ $mirror_opt } = $copy;
                $def->{mirror} = { name => $mirror_opt, toggle => sub
                {
                    my( $value ) = @_;
                    $opts->{ $mirror_opt } = int( !$value );
                }};
                $def->{mirror}->{default} = delete( $def->{default} ) if( exists( $def->{default} ) && defined( $def->{default} ) );
                # A code is used for this boolean, so we create an anon sub that call this sub just like Getopt::Long would
                if( ref( $val ) eq 'CODE' )
                {
                    $copy->{mirror} = { name => $k, toggle => sub
                    {
                        my( $value ) = @_;
                        $val->( $k, int( !$value ) );
                    }};
                }
                # Otherwise, we create a sub that set the mirror value
                else
                {
                    $copy->{mirror} = { name => $k, toggle => sub
                    {
                        my( $value ) = @_;
                        $opts->{ $k } = int( !$value );
                    }};
                }
                $copy->{mirror}->{default} = int( !$def->{mirror}->{default} ) if( exists( $def->{mirror}->{default} ) );
                # We remove it, because they would be assigned by Getopt::Long even if not triggered and this would bother us.
                delete( $def->{default} );
                delete( $copy->{default} );
                $def->{default} = sub
                {
                    my( $option, $value ) = @_;
                    return if( $def->{mirror}->{is_set} );
                    $def->{mirror}->{value} = $value;
                    $def->{mirror}->{is_set}++;
                    $def->{mirror}->{toggle}->( $value );
                };
                $copy->{default} = sub
                {
                    my( $option, $value ) = @_;
                    return if( $copy->{mirror}->{is_set} );
                    $copy->{mirror}->{value} = $value;
                    $copy->{mirror}->{is_set}++;
                    $copy->{mirror}->{toggle}->( $value );
                };
                $def->{__no_value_assign} = 1;
            }
        }
    }
    
    # Build the options parameters
    foreach my $k ( sort( keys( %$dict ) ) )
    {
        my $k2_dash = $k;
        $k2_dash =~ tr/_/-/;
        my $k2_under = $k;
        $k2_under =~ tr/-/_/;
        
        my $def = $dict->{ $k };
        
        my $opt_name = [ $k2_under ];
        # If the dictionary element is given with dash, e.g. some-thing, we replace it with some_thing, which is our standard
        # and we set some-thing as an alias
        if( CORE::index( $k, '-' ) != -1 && $k eq $k2_dash )
        {
            $dict->{ $k2_under } = CORE::delete( $dict->{ $k } );
            $k = $k2_under;
        }
        # Add the dash option as an alias if it is not the same as the underscore one, such as when this is just one word, e.g. version
        CORE::push( @$opt_name, $k2_dash ) if( $k2_dash ne $k2_under );

        if( !ref( $def->{alias} ) && CORE::length( $def->{alias} ) )
        {
            $def->{alias} = [$def->{alias}];
        }
        # Add the given aliases, if any
        if( $self->_is_array( $def->{alias} ) )
        {
            push( @$opt_name, @{$def->{alias}} ) if( scalar( @{$def->{alias}} ) );
            # push( @$opt_name, $k2_under ) if( !scalar( grep( /^$k2_under$/, @{$def->{alias}} ) ) );
        }
        # Now, also add the original key-something and key_something to the alias, so we can find them from one of the aliases
        # When we do exec, we'll be able to find all the aliases
        $def->{alias} = [] if( !CORE::exists( $def->{alias} ) );
        CORE::push( @{$def->{alias}}, $k2_dash ) if( !scalar( grep( /^$k2_dash$/, @{$def->{alias}} ) ) );
        CORE::push( @{$def->{alias}}, $k2_under ) if( !scalar( grep( /^$k2_under$/, @{$def->{alias}} ) ) );
        $def->{alias} = Module::Generic::Array->new( $def->{alias} );
        
        my $opt = join( '|', @$opt_name );
        if( defined( $def->{default} ) && ( ref( $def->{default} ) || length( $def->{default} ) ) )
        {
            $opts->{ $k2_under } = $def->{default};
        }
        else
        {
            $opts->{ $k2_under } = '';
        }
        my $suff = '';
        if( $def->{type} eq 'string' || $def->{type} eq 'scalar' )
        {
            $suff = '=s';
        }
        elsif( $def->{type} eq 'string-hash' )
        {
            $suff = '=s%';
        }
        elsif( $def->{type} eq 'array' || 
            $def->{type} eq 'file-array' ||
            $def->{type} eq 'uri-array' )
        {
            $suff = '=s@';
            $opts->{ $k2_under } = [] unless( length( $def->{default} ) );
            $def->{min} = 1 if( !exists( $def->{min} ) && !exists( $def->{max} ) );
        }
        elsif( $def->{type} eq 'boolean' )
        {
            $suff = '!';
            if( exists( $def->{code} ) && 
                ref( $def->{code} ) eq 'CODE' &&
                # Will not override if a code ref is already assigned
                ref( $opts->{ $k2_under } // '' ) ne 'CODE' )
            {
                $opts->{ $k2_under } = $def->{code};
            }
        }
        elsif( $def->{type} eq 'hash' )
        {
            $suff = '=s%';
            $opts->{ $k2_under } = {} unless( length( $def->{default} ) );
        }
        elsif( $def->{type} eq 'code' && ref( $def->{code} ) eq 'CODE' )
        {
            $opts->{ $k2_under } = $def->{code};
        }
        elsif( $def->{type} eq 'integer' )
        {
            $suff = '=i';
        }
        elsif( $def->{type} eq 'decimal' || $def->{type} eq 'float' || $def->{type} eq 'number' )
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
            $opts->{ $k2_under } = $def->{code};
        }
        elsif( $def->{type} eq 'file' )
        {
            $suff = '=s';
        }
        elsif( $def->{type} eq 'uri' )
        {
            $suff = '=s';
        }
        
        if( $def->{min} )
        {
            # If there is no max, it would be for example s{1,}
            # 2nd formatter is %s because it could be blank. %d would translate to 0 when blank.
            no warnings 'uninitialized';
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
    my $dict = $self->class( $class ) || return;
    my $v = $self->get_class_values( $class ) || return;
    my $errors = 
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
                $errors->{regexp}->{ $f } = "$f ($n) " . $def->{error};
            }
            elsif( $def->{type} eq 'array' )
            {
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
            # Create the class if it doe snot exists yet
            $classes->{ $class } = {} if( !exists( $classes->{ $class } ) );
            my $this = $classes->{ $class };
            # Then add the property and it definition hash
            $this->{ $k2 } = $def;
            # If there are any alias, we add them too
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
    my $fields = [];
    my $ref = $self->class( $class );
    my $props = [ sort( keys( %$ref ) ) ];
    return( Module::Generic::Array->new( $props ) );
}

sub configure
{
    my $self = shift( @_ );
    return( $self ) if( $self->{configured} );
    my $conf = [];
    $conf = shift( @_ ) if( ref( $_[0] ) );
    $conf = $self->configure_options if( !scalar( @$conf ) );
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
    
    $tie->enable(1);
    $getopt->getoptions( $opts, @$params ) || do
    {
        my $usage = $self->usage;
        return( $usage->() ) if( ref( $usage ) eq 'CODE' );
        return;
    };
    
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
    
    # Make sure we can access each of the options dictionary definition not just from the original key, but also from any of it aliases
    my $aliases = $self->{aliases};
    foreach my $k ( keys( %$dict ) )
    {
        my $def = $dict->{ $k };
        $aliases->{ $k } = $def;
        foreach my $a ( @{$def->{alias}} )
        {
            $aliases->{ $a } = $def;
        }
    }
    $tie->enable(1);
    
    $self->postprocess;
    
    # return( $opts );
    # e return a Getopt::Class::Values object, so we can call the option values hash key as method:
    # $object->metadata / $object->metadata( $some_hash );
    # instead of:
    # $object->{metadata}
    # return( $opts );
    my $o = Getopt::Class::Values->new({
        data => $opts,
        dict => $dict,
        aliases => $aliases,
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
        my $ref = lc( Scalar::Util::reftype( $opts->{ $f } ) // '' );
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

sub postprocess
{
    my $self = shift( @_ );
    my $dict = $self->dictionary;
    my $opts = $self->options;
    foreach my $k ( sort( keys( %$dict ) ) )
    {
        my $def = $dict->{ $k };
        next if( !length( $opts->{ $k } ) && !$def->{default} );
        return( $self->error( "Dictionary is malformed with entry $k value not being an hash reference." ) ) if( ref( $def ) ne 'HASH' );
        
        if( ( $def->{type} eq 'date' || $def->{type} eq 'datetime' ) && length( $opts->{ $k } ) )
        {
            my $dt = $self->_parse_timestamp( $opts->{ $k } );
            return( $self->pass_error ) if( !defined( $dt ) );
            $opts->{ $k } = $dt if( $dt );
        }
        elsif( $def->{type} eq 'array' )
        {
            $opts->{ $k } = Module::Generic::Array->new( $opts->{ $k } );
        }
        elsif( $def->{type} eq 'hash' ||
               $def->{type} eq 'string-hash' )
        {
            $opts->{ $k } = $self->_set_get_hash_as_object( $k, $opts->{ $k } );
        }
        elsif( $def->{type} eq 'boolean' )
        {
            if( exists( $def->{mirror} ) && 
                exists( $def->{mirror}->{value} ) )
            {
                $opts->{ $k } = $def->{mirror}->{value};
            }
            $opts->{ $k } = ( $opts->{ $k } ? $self->true : $self->false );
        }
        elsif( $def->{type} eq 'string' || $def->{type} eq 'scalar' )
        {
            $opts->{ $k } = Module::Generic::Scalar->new( $opts->{ $k } );
        }
        elsif( $def->{type} eq 'integer' || $def->{decimal} )
        {
            # Even though this is a number, this was set as a scalar reference, so we need to dereference it
            if( $self->_is_scalar( $opts->{ $k } ) )
            {
                $opts->{ $k } = Module::Generic::Scalar->new( $opts->{ $k } );
            }
            else
            {
                $opts->{ $k } = $self->_set_get_number( $k, $opts->{ $k } );
            }
        }
        elsif( $def->{type} eq 'file' )
        {
            $opts->{ $k } = file( $opts->{ $k } );
        }
        elsif( $def->{type} eq 'file-array' )
        {
            my $arr = Module::Generic::Array->new;
            foreach( @{$opts->{ $k }} )
            {
                push( @$arr, file( $_ ) );
            }
            $opts->{ $k } = $arr;
        }
        elsif( $def->{type} eq 'uri' )
        {
            my $uri_class = exists( $def->{package} ) ? $def->{package} : 'URI';
            $opts->{ $k } = $uri_class->new( $opts->{ $k } );
        }
        elsif( $def->{type} eq 'uri-array' )
        {
            my $uri_class = exists( $def->{package} ) ? $def->{package} : 'URI';
            my $arr = Module::Generic::Array->new;
            foreach( @{$opts->{ $k }} )
            {
                push( @$arr, $uri_class->new( $_ ) );
            }
            $opts->{ $k } = $arr;
        }
   }
   return( $self );
}

sub required { return( shift->_set_get_array_as_object( 'required', @_ ) ); }

sub usage { return( shift->_set_get_code( 'usage', @_ ) ); }

# NOTE: Getopt::Class::Values package
package Getopt::Class::Values;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use Devel::Confess;
};

use strict;
use warnings;

sub new
{
    my $that = shift( @_ );
    my %hash = ();
    my $obj = tie( %hash, 'Getopt::Class::Repository' );
    my $self = bless( \%hash => ( ref( $that ) || $that ) )->init( @_ );
    $obj->enable( 1 );
    return( $self );
}

sub debug { return( shift->_set_get_number( 'debug', @_ ) ); }

sub init
{
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;
    $self->{data} = {};
    $self->{dict} = {};
    $self->{aliases} = {};
    # Can only set properties that exist
    $self->{_init_strict} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error( $self->error ) );
    return( $self->error( "No dictionary as provided." ) ) if( !$self->{dict} );
    return( $self->error( "No dictionary as provided." ) ) if( !$self->{aliases} );
    return( $self->error( "Dictionary provided is not an hash reference." ) ) if( !$self->_is_hash( $self->{dict} ) );
    return( $self->error( "Aliases provided is not an hash reference." ) ) if( !$self->_is_hash( $self->{aliases} ) );
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

sub verbose { return( shift->_set_get_number( 'verbose', @_ ) ); }

# NOTE: AUTOLOAD
AUTOLOAD
{
    my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
    no overloading;
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;
    # Options dictionary
    my $dict = $self->{dict};
    # Values provided on command line
    my $data = $self->{data};
    # printf( STDERR "AUTOLOAD: \$data has %d items and property '$method' has value '%s'\n", scalar( keys( %$self ) ), $self->{ $method } );
    # return if( !CORE::exists( $data->{ $method } ) );
    return if( !CORE::exists( $self->{ $method } ) );
    my $f = $method;
    # Dictionary definition for this particular option field
    my $def = $dict->{ $f };
    if( !exists( $def->{type} ) || 
        !defined( $def->{type} ) )
    {
        CORE::warn( "Property \"${f}\" has no defined type. Using scalar.\n" ) if( $self->{warnings} );
        return( $self->_set_get_scalar( $f, @_ ) );
    }
    elsif( $def->{type} eq 'boolean' || ( $self->_is_object( $self->{ $f } ) && $self->{ $f }->isa( 'Module::Generic::Boolean' ) ) )
    {
        return( $self->_set_get_boolean( $f, @_ ) );
    }
    elsif( $def->{type} eq 'string' ||
        $def->{type} eq 'scalar' ||
        Scalar::Util::reftype( $self->{ $f } ) eq 'SCALAR' )
    {
        return( $self->_set_get_scalar_as_object( $f, @_ ) );
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
    elsif( $def->{type} eq 'file' )
    {
        return( $self->_set_get_file( $f, @_ ) );
    }
    elsif( $def->{type} eq 'file-array' )
    {
        if( @_ )
        {
            my $arr = Module::Generic::Array->new;
            foreach( @_ )
            {
                push( @$arr, file( $_ ) );
            }
            $self->{ $f } = $arr;
        }
        return( $self->_set_get_array_as_object( $f ) );
    }
    elsif( $def->{type} eq 'uri' )
    {
        my $uri_class = exists( $def->{package} ) ? $def->{package} : 'URI';
        return( $self->_set_get_uri( { field => $f, class => $uri_class }, @_ ) );
    }
    elsif( $def->{type} eq 'uri-array' )
    {
        my $uri_class = exists( $def->{package} ) ? $def->{package} : 'URI';
        if( @_ )
        {
            my $arr = Module::Generic::Array->new;
            foreach( @_ )
            {
                push( @$arr, $uri_class->new( $_ ) );
            }
            $self->{ $f } = $arr;
        }
        return( $self->_set_get_uri( { field => $f, class => $uri_class } ) );
    }
    elsif( $def->{type} eq 'uri' )
    {
        return( $self->_set_get_uri( $f, @_ ) );
    }
    elsif( $def->{type} eq 'uri-array' )
    {
        if( @_ )
        {
            my $arr = Module::Generic::Array->new;
            foreach( @_ )
            {
                push( @$arr, file( $_ ) );
            }
            $self->{ $f } = $arr;
        }
        return( $self->_set_get_array_as_object( $f ) );
    }
    else
    {
        CORE::warn( "I do not know what to do with this property \"$f\" type \"$def->{type}\". Using scalar.\n" ) if( $self->{warnings} );
        return( $self->_set_get_scalar( $f, @_ ) );
    }
};

# NOTE: Getopt::Class::Repository package
package Getopt::Class::Repository;
BEGIN
{
    use strict;
    use warnings;
    use Scalar::Util;
    use Devel::Confess;
    use constant VALUES_CLASS => 'Getopt::Class::Value';
};

# tie( %self, 'Getopt::Class::Repository' );
# Used by Getopt::Class::Values to ensure that whether the data are accessed as methods or as hash keys,
# in either way it returns the option data
# Actually option data are stored in the Getopt::Class::Values object data property
sub TIEHASH
{
    my $self  = shift( @_ );
    my $class = ref( $self ) || $self;
    return( bless( { data => {} } => $class ) );
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
    # print( STDERR "FETCH($caller)[enable=$self->{enable}] <- '$key''\n" );
    if( caller eq VALUES_CLASS || !$self->{enable} )
    {
        # print( STDERR "FETCH($caller)[enable=$self->{enable}] <- '$key' <- '$self->{$key}'\n" );
        return( $self->{ $key } )
    }
    else
    {
        # print( STDERR "FETCH($caller)[enable=$self->{enable}] <- '$key' <- '$self->{$key}'\n" );
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
        return( scalar( keys( %$self ) ) );
    }
    else
    {
        return( scalar( keys( %$data ) ) );
    }
}

sub STORE
{
    my $self  = shift( @_ );
    my $data = $self->{data};
    my( $key, $val ) = @_;
    # print( STDERR "STORE($caller)[enable=$self->{enable}] -> '$key'\n" );
    if( caller eq VALUES_CLASS || !$self->{enable} )
    {
        # print( STDERR "STORE($caller)[enable=$self->{enable}] -> '$key' -> '$val'\n" );
        $self->{ $key } = $val;
    }
    else
    {
        # print( STDERR "STORE($caller)[enable=$self->{enable}] -> '$key' -> '$val'\n" );
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

# NOTE: Getopt::Class::Alias package
# This is an alternative to perl feature of refealiasing
# https://metacpan.org/pod/perlref#Assigning-to-References
package Getopt::Class::Alias;
BEGIN
{
    use strict;
    use warnings;
    use parent -norequire, qw( Getopt::Class::Repository Module::Generic );
    use Scalar::Util;
    use Devel::Confess;
};

# tie( %$opts, 'Getopt::Class::Alias', $dictionary );
sub TIEHASH
{
    # $this is actually the HASH tied
    my $this  = shift( @_ );
    my $class = ref( $this ) || $this;
    # Valid options are:
    # dict: options dictionary
    # debug
    my $opts  = {};
    $opts = shift( @_ ) if( @_ );
    # print( STDERR __PACKAGE__ . "::TIEHASH() called with following arguments: '", join( ', ', @_ ), "'.\n" );
    my $call_offset = 0;
    while( my @call_data = caller( $call_offset ) )
    {
        # printf( STDERR "[$call_offset] In file $call_data[1] at line $call_data[2] from subroutine %s has bitmask $call_data[9]\n", (caller($call_offset+1))[3] );
        unless( $call_offset > 0 && $call_data[0] ne $class && (caller($call_offset-1))[0] eq $class )
        {
            # print( STDERR "Skipping package $call_data[0]\n" );
            $call_offset++;
            next;
        }
        last if( $call_data[9] || ( $call_offset > 0 && (caller($call_offset-1))[0] ne $class ) );
        $call_offset++;
    }
    # print( STDERR "Using offset $call_offset with bitmask ", ( caller( $call_offset ) )[9], "\n" );
    my $bitmask = ( caller( $call_offset - 1 ) )[9];
    my $offset = $warnings::Offsets{uninitialized};
    # print( STDERR "Caller (2)'s bitmask is '$bitmask', warnings offset is '$offset' and vector is '", vec( $bitmask, $offset, 1 ), "'.\n" );
    my $should_display_warning = vec( ( $bitmask // 0 ), $offset, 1 );
    
    my $dict = $opts->{dict} || return( __PACKAGE__->error( "No dictionary was provided to Getopt::Class:Alias" ) );
    if( Scalar::Util::reftype( $dict ) ne 'HASH' )
    {
        #warn( "Dictionary provided is not an hash reference.\n" ) if( $should_display_warning );
        #return;
        return( __PACKAGE__->error({ message => "Dictionary provided is not an hash reference.", no_return_null_object => 1 }) );
    }
    elsif( !scalar( keys( %$dict ) ) )
    {
        #warn( "The dictionary hash reference provided is empty.\n" ) if( $should_display_warning );
        #return;
        return( __PACKAGE__->error( "The dictionary hash reference provided is empty." ) );
    }
    
    my $aliases = $opts->{aliases} || do
    {
        #warn( "No aliases map was provided to Getopt::Class:Alias\n" ) if( $should_display_warning );
        #return;
        return( __PACKAGE__->error( "No aliases map was provided to Getopt::Class:Alias" ) );
    };
    if( Scalar::Util::reftype( $aliases ) ne 'HASH' )
    {
        #warn( "Aliases map provided is not an hash reference.\n" ) if( $should_display_warning );
        #return;
        return( __PACKAGE__->error( "Aliases map provided is not an hash reference." ) );
    }
    my $hash = 
    {
    data => {},
    dict => $dict,
    aliases => $aliases,
    warnings => $should_display_warning,
    debug => ( $opts->{debug} || 0 ),
    # _data_repo => 'data',
    colour_open => '<',
    colour_close => '>',
    };
    return( bless( $hash => $class ) );
}

sub FETCH
{
    my $self = shift( @_ );
    my $data = $self->{data};
    # my $dict = $self->{dict};
    my $key  = shift( @_ );
    # my $def = $dict->{ $key };
    return( $data->{ $key } );
}

sub STORE
{
    my $self  = shift( @_ );
    my $class = ref( $self );
    my $data = $self->{data};
    # Aliases contains both the original dictionary key and all its aliases
    my $aliases = $self->{aliases};
    my( $pack, $file, $line ) = caller;
    my( $key, $val ) = @_;
    $self->message_colour( 3, "Called from line $line in file \"$file\" for property \"<green>$key</>\" with reference (<black on white>", ref( $val ), "</>) and value \"<red>" . ( $val // 'undef' ) . "</>\">" );
    my $dict = $self->{dict};
    my $enabled = $self->{enable};
    my $fallback = sub
    {
        my( $k, $v ) = @_;
        $data->{ $k } = $v;
    };
    if( $enabled && CORE::exists( $aliases->{ $key } ) )
    {
        my $def = $aliases->{ $key } || do
        {
            CORE::warn( "No dictionary definition found for \"$key\".\n" ) if( $self->{warnings} );
            return( $fallback->( $key, $val ) );
        };
        if( !$self->_is_array( $def->{alias} ) )
        {
            CORE::warn( "I was expecting an array reference for this alias, but instead got '$def->{alias}'.\n" ) if( $self->{warnings} );
            return( $fallback->( $key, $val ) );
        }
        my $alias = $def->{alias} || do
        {
            CORE::warn( "No alias property found. This should not happen.\n" ) if( $self->{warnings} );
            return( $fallback->( $key, $val ) );
        };
        # $self->messagef_colour( 3, 'Found alias "{green}' . $alias . '{/}" with %d elements: {green}"%s"{/}', scalar( @$alias ), $alias->join( "', '" ) );
        $self->messagef_colour( 3, "Found alias '<green>$alias</>' with %d elements: <green>'%s'</>", scalar( @$alias ), $alias->join( "', '" ) );
        if( Scalar::Util::reftype( $alias ) ne 'ARRAY' )
        {
            CORE::warn( "Alias property is not an array reference. This should not happen.\n" ) if( $self->{warnings} );
            return( $fallback->( $key, $val ) );
        }
        $self->message_colour( 3, "Setting primary property \"<green>${key}</>\" to value \"<black on white>" . ( $val // '' ) . "</>\"." );
        $data->{ $key } = $val;
        foreach my $a ( @$alias )
        {
            next if( $a eq $key );
            # We do not set the value, if for some reason, the user would have removed this key
            $self->message_colour( 3, "Setting alias \"<green>${a}</>\" to value \"<val black on white>", ( $val // '' ), "</>\" (ref=", ref( $val // '' ), ")." );
            # $data->{ $a } = $val if( CORE::exists( $data->{ $a } ) );
            $data->{ $a } = $val;
        }
    }
    else
    {
        $data->{ $key } = $val;
    }
}

1;
# NOTE: POD
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
        # Can be enabled with --enable-recurse
        disable_recurse => { type => 'boolean', default => 1 },
        # Can be disabled also with --disable-logging
        enable_logging  => { type => 'boolean', default => 0 },
        help            => { type => 'code', code => sub{ pod2usage(1); }, alias => '?', action => 1 },
        man             => { type => 'code', code => sub{ pod2usage( -exitstatus => 0, -verbose => 2 ); }, action => 1 },
        quiet           => { type => 'boolean', default => 0, alias => 'silent' },
        verbose         => { type => 'boolean', default => \$VERBOSE, alias => 'v' },
        version         => { type => 'code', code => sub{ printf( "v%.2f\n", $VERSION ); }, action => 1 },
    
        api_server      => { type => 'string', default => 'api.example.com' },
        api_version     => { type => 'string', default => 1 },
        as_admin        => { type => 'boolean' },
        dry_run         => { type => 'boolean', default => 0 },
        
        # Can be enabled also with --with-zlib
        without_zlib    => { type => 'integer', default => 1 },
    
        name            => { type => 'string', class => [qw( person product )] },
        created         => { type => 'datetime', class => [qw( person product )] },
        define          => { type => 'string-hash', default => {} },
        langs           => { type => 'array', class => [qw( person product )], re => qr/^[a-z]{2}([_|-][A-Z]{2})?/, min => 1, default => [qw(en)] },
        currency        => { type => 'string', class => [qw(product)], name => 'currency', re => qr/^[a-z]{3}$/, error => "must be a three-letter iso 4217 value" },
        age             => { type => 'integer', class => [qw(person)], name => 'age', },
        path            => { type => 'file' },
        skip            => { type => 'file-array' },
        url             => { type => 'uri', package => 'URI' },
        urls            => { type => 'uri-array', package => 'URI::Fast' },
    };
    
    # Assuming command line arguments like:
    prog.pl --create-user --name Bob --langs fr ja --age 30 --created now --debug 3 \
            --path ./here/some/where --skip ./bad/directory ./not/here ./avoid/me/

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
        $opts->langs->push( 'en_GB' ) if( !$opts->langs->length );
        printf( "Created on %s\n", $opts->created->iso8601 );
    }

=head1 VERSION

    v1.0.0

=head1 DESCRIPTION

L<Getopt::Class> is a lightweight wrapper around L<Getopt::Long> that implements the idea of class of properties and makes it easier and powerful to set up L<Getopt::Long>. This module is particularly useful if you want to provide several sets of options for different features or functions of your program. For example, you may have a part of your program that deals with user while another deals with product. Each of them needs their own properties to be provided.

=head1 CONSTRUCTOR

=head2 new

To instantiate a new L<Getopt::Class> object, pass an hash reference of following parameters:

=over 4

=item * C<dictionary>

This is required. It must contain a key value pair where the value is an anonymous hash reference that can contain the following parameters:

=over 8

=item * C<alias>

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

=item * C<default>

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

=item * C<error>

A string to be used to set an error by L</"check_class_data">. Typically the string should provide meaningful information as to what the data should normally be. For example:

    my $dict =
    {
    currency => { type => 'string', class => [qw(product)], name => 'currency', re => qr/^[a-z]{3}$/, error => "must be a three-letter iso 4217 value" },
    };

=item * C<max>

This is well explained in L<Getopt::Long/"Options with multiple values">

It serves "to specify the minimal and maximal number of arguments an option takes".

=item * C<min>

Same as above

=item * C<re>

This must be a regular expression and is used by L</"check_class_data"> to check the sanity of the data provided by the user.
So, for example:

    my $dict =
    {
    currency => { type => 'string', class => [qw(product)], name => 'currency', re => qr/^[a-z]{3}$/, error => "must be a three-letter iso 4217 value" },
    };

then the user calls your program with, among other options:

    --currency euro

would set an error that can be retrieved as an output of L</"check_class_data">

=item * C<required>

Set this to true or false (1 or 0) to instruct L</"check_class_data"> whether to check if it is missing or not.

This is an alternative to the L</"required"> method which is used at an earlier stage, during L</"exec">

=item * C<type>

Supported types are:

=over 12

=item * C<array>

This type will set the resulting value to be a L<Module::Generic::Array> object of values provided.

=item * C<boolean>

If type is C<boolean> and the key is either C<with>, C<without>, C<enable>, C<disable>, their counterpart will automatically be available as well, such as you can do, as show in the excerpt in the synopsis above:

    --enable-recurse --with-zlib

Be careful though. If, in your dictionary, as shown in the synopsis, you defined C<without_zlib> with a default value of true, then using the option C<--with-zlib> will set that value to false. So in your application, you would need to check like this:

    if( $opts->{without_zlib} )
    {
        # Do something
    }
    else
    {
        # Do something else
    }

=item * C<code>

Type code implies an anonymous sub routine and should be accompanied with the attribute I<code>, such as:

    { type => 'code', code => sub{ pod2usage(1); exit( 0 ) }, alias => '?', action => 1 },

=item * C<datetime>

This type will set the resulting value to be a L<DateTime> object of the value provided.

=item * C<decimal>

This type will set the resulting value to be a L<Module::Generic::Number> object of the value provided.

=item * C<file>

This type will mark the value as a directory or file path and will become a L<Module::Generic::File> object.

This is particularly convenient when the user provided you with a relative path, such as:

    ./my_prog.pl --debug 3 --path ./here/

And if you are not very careful and inadvertently change directory like when using L<File::Find>, then this relative path could lead to some unpleasant surprise.

Setting this argument type to C<file> ensure the resulting value is a L<Module::Generic::File>, whose underlying file or directory will be resolved to their absolute path.

=item * C<file-array>

Same as C<file> argument type, but allows multiple value saved as an array. For example:

    ./my_prog.pl --skip ./not/here ./avoid/me/ ./skip/this/directory

This would result in the option property C<skip> being an L<array object|Module::Generic::Array> containing 3 entries.

=item * C<hash>

Type C<hash> is convenient for free key-value pair such as:

    --define customer_id=10 --define transaction_id 123

would result for C<define> with an anonymous hash as value containing C<customer_id> with value C<10> and C<transaction_id> with value C<123>

=item * C<integer>

This type will set the resulting value to be a L<Module::Generic::Number> object of the value provided.

=item * C<scalar>

This type will set the resulting value to be a L<Module::Generic::Scalar> object of the value provided.

=item * C<string>

Same as C<scalar>. This type will set the resulting value to be a L<Module::Generic::Scalar> object of the value provided.

=item * C<string-hash>

=item * C<uri>

This type will mark the value as a directory or file path and will become a L<URI> object, by default.

You can override this default pacage, by using C<package> property, such as:

    url => { type => 'uri', package => 'URI' }

=item * C<uri-array>

Same as C<uri> argument type, but allows multiple value saved as an array. For example:

    ./my_prog.pl --uris https://example.com/some/where https://example.com/some/where/else

This would result in the option property C<uris> being an L<array object|Module::Generic::Array> containing 2 entries.

=back

Also as seen in the example above, you can add additional properties to be used in your program, here such as C<action> that could be used to identify all options that are used to trigger an action or a call to a sub routine.

=back

=item * C<debug>

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

L<Getopt::Long>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
