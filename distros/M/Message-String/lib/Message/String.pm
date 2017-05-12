use strict;
use warnings;

package Message::String;
our $VERSION = '0.1.9'; # VERSION
# ABSTRACT: A pragma to declare and organise messaging.
use Clone           ( 'clone' );
use DateTime        ();
use List::MoreUtils ( 'distinct' );
use Scalar::Util    ( 'reftype' );
use Sub::Util       ( 'set_subname' );
use IO::Stty        ();
use namespace::clean;
use overload ( fallback => 1, '""' => 'to_string' );

BEGIN {
    # Set up "messages" pragma as a "Message::String" alias.
    *message:: = *Message::String::;

    # ... and prevent Perl from having a hissy-fit the first time
    # a "use message ..." directive is encountered.
    $INC{'message.pm'} = "(set by @{[__PACKAGE__]})";

    # We're eating-our-own-dog-food at the end of this module, but we
    # will still need these three subroutines declaring before we can
    # use them.
    sub C_EXPECT_HAREF_OR_KVPL;
    sub C_BAD_MESSAGE_ID;
    sub C_MISSING_TEMPLATE;

    # Messages types:
    #
    #  A (Severity 1: Alert)
    #  C (Severity 2: Critical)
    #  E (Severity 3: Error)
    #  W (Severity 4: Warning)
    #  N (Severity 5: Notice)
    #  I (Severity 6: Info)
    #  D (Severity 7: Diagnostic, or Debug)
    #  R (Severity 1: Response, or Prompt)
    #  M (Severity 6: Other, or Miscellaneous)
    #
    # Listed in that order for no other reason than it spells DINOCREW,
    # which is kind of sad but easy to remember. Messages are handled
    # in different ways and according to type and some of the more
    # important type characteristics are defined in this table:
    #
    # level
    #   The verbosity or severity level. By default these align with
    #   syslog message levels, with the exception of package-spefic
    #   types 'M' and 'R'.
    # timestamp
    #   Embed a timestamp in formatted message. May be '0' (No - default),
    #   '1' (Yes, using default "strftime" format), or a custom "strftime"
    #   format string.
    # tlc
    #   Nothing quite as nice as Tender Love and Care, but the three-letter
    #   code that can be embedded in the formatted message (e.g. 'NTC'
    #   would, by default, be rendered as '*NTC*').
    # id
    #   A boolean determining whether or not the message identifer is
    #   embedded withing the text of the formatted message.
    # issue
    #   A reference to the method that the issuer will use to get the
    #   rendered message out into the cold light of day.
    # aliases
    #   A reference to a list of longer codes that the message constructor
    #   will fallback to when attempting to discern the message's type from
    #   its identifier. It first tries to determine if the message id is
    #   suffixed by a type code following a dash, digit or underscore. Then
    #   it checks for a type code followed by a dash, digit, or underscore.
    #   If neith of those checks is conclusive, it then checks to see if the
    #   id ends or begins with one of the type aliases listed in this table,
    #   and if that is also inconclisove then 'M' (Other) is assumed.
    #<<<
    my $types = {
        A => { 
            level   => 1, timestamp => 0, tlc => '', id => 1,
            issue => \&_alert, 
            aliases => [qw/ALT ALR ALERT/]
        },
        C => {
            level => 2, timestamp => 0, tlc => '', id => 1,
            issue => \&_crit, 
            aliases => [qw/CRT CRITICAL CRIT FATAL FTL/]
        },
        E => {
            level => 3, timestamp => 0, tlc => '', id => 0,
            issue => \&_err, 
            aliases => [qw/ERR ERROR/]
        },
        W => {
            level => 4, timestamp => 0, tlc => '', id => 0,
            issue => \&_warning, 
            aliases => [qw/WRN WARNING WNG WARN/]
        },
        N => {
            level => 5, timestamp => 0, tlc => '', id => 0,
            issue => \&_notice, 
            aliases => [qw/NTC NOTICE NOT/]
        },
        I => { 
            level   => 6, timestamp => 0, tlc => '', id => 0, 
            issue => \&_info, 
            aliases => [qw/INF INFO/]
        },
        D => {
            level => 7, timestamp => 0, tlc => '', id => 0, 
            issue => \&_diagnostic, 
            aliases => [qw/DEB DEBUG DGN DIAGNOSTIC/]
        },
        R => {
            level => 1, timestamp => 0, tlc => '', id => 0,
            issue => \&_prompt, 
            aliases => [qw/RSP RESPONSE RES PROMPT PRM INPUT INP/]
        },
        M => {
            level => 6, timestamp => 0, tlc => '', id => 0,
            issue => \&_other, 
            aliases => [qw/MSG MESSAGE OTHER MISC OTH OTR MSC/]
        },
    };
    #>>>

    # _initial_types
    #   In list context, returns the initial list of message type codes
    #   as an array.
    #   In scalar context, returns the initial list of message type codes
    #   as a string suitable for use in a Regex character class ([...]).
    my @base_types = sort { $a cmp $b } keys %$types;
    my $base_types = join '', @base_types;

    sub _initial_types
    {
        return wantarray ? @base_types : $base_types;
    }

    # _types
    #   Some of our methods require access to data presented in the message
    #   types table, defined above (see "$types"), either to manipulate it
    #   or simply to use the values. Many of these methods may be used as
    #   class and instance methods ('_type_level', '_type_id', to name two
    #   of them). Most of the time, this table is the single source of
    #   truth, that is unless AN INSTANCE attempts to use one of those
    #   methods to modifiy the data. Under those specific circumstances,
    #   the the message instance's gets its own copy of the type table
    #   loaded into its 'types' attribute before being modified --
    #   copy on write semantics, if you will -- and that data, not the global
    #   data, is used by that instance. That local data is purged if the
    #   instance ever changes its message type. It is the job of this method
    #   to copy (if required) the data required by an instance and/or return
    #   that data as an instance's view of its context, or to return the a
    #   reference to the global data.
    sub _types
    {
        my ( $invocant, $bool_copy ) = @_;
        return $types unless ref $invocant;
        return $types unless $bool_copy || exists $invocant->{types};
        $invocant->{types} = clone( $types )
            unless exists $invocant->{types};
        return $invocant->{types};
    }

    # _reset
    #   If called as an instance method, restores the instance to a reasonably
    #   pristine state.
    #   If called as a class method, restores the global type data to its
    #   pristine state.
    my $types_backup = clone( $types );

    sub _reset
    {
        my ( $invocant ) = @_;
        if ( ref $invocant ) {
            for my $key ( keys %$invocant ) {
                delete $invocant->{$key}
                    unless $key =~ m{^(?:template|level|type|id)$};
            }
            my $type = $invocant->type;
            $type = 'M'
                unless defined( $type ) && exists $types->{$type};
            $invocant->level( $types->{$type}{level} );
        }
        else {
            $types = clone( $types_backup );
        }
        return $invocant;
    }

    # _message_types
    #   In list context, returns the current list of message type codes
    #   as an array.
    #   In scalar context, returns the current list of message type codes
    #   as a string suitable for use in a Regex character class ([...]).
    sub _message_types
    {
        my ( $invocant ) = @_;
        my $types = $invocant->_types;
        my @types = sort { $a cmp $b } keys %$types;
        return @types
            if wantarray;
        return join '', @types;
    }

    # _type_level
    #   Inspect or change the "level" setting (verbosity level) for a
    #   message type.
    # * Be careful when calling this as an instance method as copy-on-
    #   write semantics come into play (see "_types" for more information).
    sub _type_level
    {
        my ( $invocant, $type, $value ) = @_;
        if ( @_ > 1 && defined( $type ) ) {
            my $types = $invocant->_types( @_ > 2 );
            $type = uc( $type );
            if ( @_ > 2 ) {
                return $invocant
                    if !ref( $invocant ) && $type =~ m{^[ACEW]$};
                $types->{$type}{level}
                    = ( 0 + $value ) || $types->{$type}{level};
                $invocant->level( $types->{ $invocant->{type} }{level} )
                    if ref $invocant;
                return $invocant;
            }
            return $types->{$type}{level}
                if exists $types->{$type};
        }
        return undef;
    }

    # _type_id
    #   Inspect or change the "id" setting (whether the id appears in the
    #   formatted text) for a message type.
    # * Be careful when calling this as an instance method as copy-on-
    #   write semantics come into play (see "_types" for more information).
    sub _type_id
    {
        my ( $invocant, $type, $value ) = @_;
        if ( @_ > 1 && defined( $type ) ) {
            my $types = $invocant->_types( @_ > 2 );
            $type = uc( $type );
            if ( @_ > 2 ) {
                $types->{$type}{id} = !!$value;
                return $invocant;
            }
            if ( $type eq '1' || $type eq '0' || $type eq '' ) {
                $types->{$_}{id} = !!$type for keys %$types;
                return $invocant;
            }
            return $types->{$type}{id}
                if exists $types->{$type};
        }
        return undef;
    }

    # _type_timestamp
    #   Inspect or change the "timestamp" setting (whether and how the time
    #   appears in the formatted text) for a message type.
    # * Be careful when calling this as an instance method as copy-on-
    #   write semantics come into play (see "_types" for more information).
    sub _type_timestamp
    {
        my ( $invocant, $type, $value ) = @_;
        if ( @_ > 1 && defined( $type ) ) {
            my $types = $invocant->_types( @_ > 2 );
            $type = uc( $type );
            if ( @_ > 2 ) {
                $types->{$type}{timestamp} = $value || '';
                return $invocant;
            }
            if ( $type eq '1' || $type eq '0' || $type eq '' ) {
                $types->{$_}{timestamp} = $type for keys %$types;
                return $invocant;
            }
            return $types->{$type}{timestamp}
                if exists $types->{$type};
        }
        return undef;
    }

    # _type_tlc
    #   Inspect or change the "tlc" setting (whether and what three-letter code
    #   appears in the formatted text) for a message type.
    # * Be careful when calling this as an instance method as copy-on-
    #   write semantics come into play (see "_types" for more information).
    sub _type_tlc
    {
        my ( $invocant, $type, $value ) = @_;
        if ( @_ > 1 && defined( $type ) ) {
            my $types = $invocant->_types( @_ > 2 );
            $type = uc( $type );
            if ( @_ > 2 ) {
                $value ||= '';
                $value = substr( $value, 0, 3 )
                    if length( $value ) > 3;
                $types->{$type}{tlc} = $value;
                return $invocant;
            }
            return $types->{$type}{tlc}
                if exists $types->{$type};
        }
        return undef;
    }

    # _type_aliases
    #   Inspect or change the "aleiases" setting for a message type.
    # * Be careful when calling this as an instance method as copy-on-
    #   write semantics come into play (see "_types" for more information).
    sub _type_aliases
    {
        my ( $invocant, $type, $value ) = @_;
        if ( @_ > 1 && defined( $type ) ) {
            my $types = $invocant->_types( @_ > 2 );
            $type = uc( $type );
            if ( @_ > 2 ) {
                my $tlc = $invocant->_type_tlc( $type );
                $value = []
                    unless $value;
                $value = [$value]
                    unless ref $value;
                $types->{$type}{aliases} = $value;
                return $invocant;
            }
            if ( exists $types->{$type} ) {
                return @{ $types->{$type}{aliases} } if wantarray;
                return $types->{$type}{aliases};
            }
        }
        return wantarray ? () : undef;
    }

    # _types_by_alias
    #   In list context, returns a hash of aliases and their correspondin
    #   message type codes.
    sub _types_by_alias
    {
        my ( $invocant ) = @_;
        my $types = $invocant->_types;
        my %long_types;
        for my $type ( keys %$types ) {
            %long_types
                = ( %long_types, map { $_ => $type } @{ $types->{$type}{aliases} } );
            $long_types{ $types->{$type}{tlc} } = $type
                if $types->{$type}{tlc};
        }
        return wantarray ? %long_types : \%long_types;
    }

    # _update_type_on_id_change
    #   Check or change whether or not message types are set automatically
    #   when message ids are set. The cascade is enabled by default.
    my $auto_type = 1;

    sub _update_type_on_id_change
    {
        my ( $invocant, $value ) = @_;
        return $auto_type
            unless @_ > 1;
        $auto_type = !!$value;
        return $invocant;
    }

    my $auto_level = 1;

    # _update_level_on_type_change
    #   Check or change whether or not message levels are set automatically
    #   when message types are set. The cascade is enabled by default.
    sub _update_level_on_type_change
    {
        my ( $invocant, $value ) = @_;
        return $auto_level
            unless @_ > 1;
        $auto_level = !!$value;
        return $invocant;
    }

    # _minimum_verbosity
    #   Returns the minimum verbosity level, always the same level as
    #   error messages.
    my $min_verbosity = __PACKAGE__->_type_level( 'E' );

    sub _minimum_verbosity {$min_verbosity}

    # _verbosity
    #   Returns the current verbosity level, which is greater than or
    #   equal to the severity level of all messages to be issued.
    my $cur_verbosity = __PACKAGE__->_type_level( 'D' );

    sub verbosity
    {
        my ( $invocant, $value ) = @_;
        return $cur_verbosity
            unless @_ > 1;
        if ( $value =~ /^\d+$/ ) {
            $cur_verbosity = 0 + $value;
        }
        else {
            my $types = $invocant->_types;
            $value = uc( $value );
            if ( length( $value ) > 1 ) {
                my $long_types = $invocant->_types_by_alias;
                $value = $long_types->{$value} || 'D';
            }
            $value = $types->{$value}{level}
                if index( $invocant->_message_types, $value ) > -1;
            $cur_verbosity = 0 + ( $value || 0 );
        }
        $cur_verbosity = $min_verbosity
            if $cur_verbosity < $min_verbosity;
        return $invocant;
    }

    # _default_timestamp_format
    #   Check or change the default timestamp format.
    my $timestamp_format = '%a %x %T';

    sub _default_timestamp_format
    {
        my ( $invocant, $value ) = @_;
        return $timestamp_format
            unless @_ > 1;
        $timestamp_format = $value || '';
        return $invocant;
    }

    # _alert
    #   The handler used by the message issuer ("issue") to deliver
    #   an "alert" message.
    sub _alert
    {
        my ( $message ) = @_;
        @_ = $message->{output};
        require Carp;
        goto &Carp::confess;
    }

    # _crit
    #   The handler used by the message issuer ("issue") to deliver
    #   a "critical" message.
    sub _crit
    {
        my ( $message ) = @_;
        @_ = $message->{output};
        require Carp;
        goto &Carp::confess;
    }

    # _err
    #   The handler used by the message issuer ("issue") to deliver
    #   an "error" message.
    sub _err
    {
        my ( $message ) = @_;
        @_ = $message->{output};
        require Carp;
        goto &Carp::croak;
    }

    # _warning
    #   The handler used by the message issuer ("issue") to deliver
    #   a "warning" message.
    sub _warning
    {
        my ( $message ) = @_;
        @_ = $message->{output};
        require Carp;
        goto &Carp::carp;
    }

    # _notice
    #   The handler used by the message issuer ("issue") to deliver
    #   a "notice" message.
    sub _notice
    {
        my ( $message ) = @_;
        print STDERR "$message->{output}\n";
        return $message;
    }

    # _info
    #   The handler used by the message issuer ("issue") to deliver
    #   an "info" message.
    sub _info
    {
        my ( $message ) = @_;
        print STDOUT "$message->{output}\n";
        return $message;
    }

    # _diagnostic
    #   The handler used by the message issuer ("issue") to deliver
    #   a "diagnostic" message.
    #
    #   Diagnostic messages are, by default, issueted using a TAP-friendly
    #   prefix ('# '), making them helpful in test modules.
    sub _diagnostic
    {
        my ( $message ) = @_;
        print STDOUT "# $message->{output}\n";
        return $message;
    }

    # _prompt
    #   The handler used by the message issuer ("issue") to deliver
    #   a "response" message.
    #
    #   Response messages are displayed and will block until a response
    #   is received from stdin. The response is accessible via the
    #   message's response method and, initially, also via Perl's "$_"
    #   variable.
    *Message::String::INPUT = \*STDIN;

    sub _prompt
    {
        my ( $message ) = @_;
        print STDOUT "$message->{output}";
        my $oldmode;
        if ( $message->{readmode} ) {
            $oldmode = IO::Stty::stty( \*Message::String::INPUT, '-g' );
            IO::Stty::stty( \*Message::String::INPUT, $message->{readmode} );
        }
        chomp( $message->{response} = <INPUT> );
        if ( $oldmode ) {
            IO::Stty::stty( \*Message::String::INPUT, $oldmode );
        }
        $_ = $message->{response};
        return $message;
    }

    # _other
    #   The handler used by the message issuer ("issue") to deliver
    #   any other type of message.
    sub _other
    {
        my ( $message ) = @_;
        print STDOUT "$message->{output}\n";
        return $message;
    }

    # _should_be_issued
    #   Returns 1 if the issuer should go ahead and issue to an
    #   issueter to deliver the message.
    #   Returns 0 if the issuer should just quietly return the
    #   message object.
    #
    #   Messages are normally issueted (a) in void context (i.e. it is
    #   clear from their usage that the message should "do" something), and
    #   (b) if the message severity level is less than or equal to the
    #   current verbosity level.
    sub _should_be_issued
    {
        my ( $message, $wantarray ) = @_;
        return 0 if defined $wantarray;
        return 0 if $message->verbosity < $message->_type_level( $message->type );
        return 1;
    }

    # _issue
    #   The message issuer. Oversees formatting, decision as to whether
    #   to issue, or return message object, and how to issue.
    sub _issue
    {
        my ( $message ) = &_format;    # Simply call "_format" using same "@_"
        return $message unless $message->_should_be_issued( wantarray );
        my $types       = $message->_types;
        my $type        = $message->type;
        my $issue_using = $types->{$type}{issue}
            if exists $types->{$type};
        $issue_using = \&_other unless $issue_using;
        @_ = $message;
        goto &$issue_using;
    }

    # _format
    #   Format the message's "output" attribute ready for issue.
    sub _format
    {
        my ( $message, @args ) = @_;
        my $txt = '';
        $txt .= $message->_message_timestamp_text
            if $message->_type_timestamp( $message->type );
        $txt .= $message->_message_tlc_text
            if $message->_type_tlc( $message->type );
        $txt .= $message->_message_id_text
            if $message->_type_id( $message->type );
        if ( @args ) {
            $txt .= sprintf( $message->{template}, @args );
        }
        else {
            $txt .= $message->{template};
        }
        $message->output( $txt );
        return $message;
    }

    # _message_timestamp_text
    #   Returns the text used to represent time in the message's output.
    sub _message_timestamp_text
    {
        my ( $message )      = @_;
        my $timestamp_format = $message->_type_timestamp( $message->type );
        my $time             = DateTime->now;
        return $time->strftime( $message->_default_timestamp_format ) . ' '
            if $timestamp_format eq '1';
        return $time->strftime( $timestamp_format ) . ' ';
    }

    # _message_tlc_text
    #   Returns the text used to represent three-letter type code in the
    #   message's output.
    sub _message_tlc_text
    {
        my ( $message ) = @_;
        my $tlc = $message->_type_tlc( $message->type );
        return sprintf( '*%s* ', uc( $tlc ) );
    }

    # _prepend_message_id
    #   Returns the text used to represent the identity of the message
    #   being output.
    sub _message_id_text
    {
        my ( $message ) = @_;
        return sprintf( '%s ', uc( $message->id ) );
    }

    # id
    #   Set or get the message's identity. The identity must be a valid Perl
    #   subroutine identifier.

    my %bad_identifiers = map +( $_, 1 ), qw/
        BEGIN       INIT        CHECK       END         DESTROY
        AUTOLOAD    STDIN       STDOUT      STDERR      ARGV
        ARGVOUT     ENV         INC         SIG         UNITCHECK
        __LINE__    __FILE__    __PACKAGE__ __DATA__    __SUB__
        __END__     __ANON__
        /;

    sub id
    {
        my ( $message, $value ) = @_;
        return $message->{id}
            unless @_ > 1;
        my $short_types = $message->_message_types;
        my $type;
        if ( $value =~ m{(^.+):([${short_types}])$} ) {
            ( $value, $type ) = ( $1, $2 );
        }
        C_BAD_MESSAGE_ID( $value )
            unless $value && $value =~ /^[\p{Alpha}_\-][\p{Digit}\p{Alpha}_\-]*$/;
        C_BAD_MESSAGE_ID( $value )
            if exists $bad_identifiers{$value};
        if ( $message->_update_type_on_id_change ) {
            if ( $type ) {
                $message->type( $type );
            }
            else {
                if ( $value =~ /[_\d]([${short_types}])$/ ) {
                    $message->type( $1 );
                }
                elsif ( $value =~ /^([${short_types}])[_\d]/ ) {
                    $message->type( $1 );
                }
                else {
                    my %long_types = $message->_types_by_alias;
                    my $long_types = join '|',
                        sort { length( $b ) <=> length( $a ) } keys %long_types;
                    if ( $value =~ /(${long_types})$/ ) {
                        $message->type( $long_types{$1} );
                    }
                    elsif ( $value =~ /^(${long_types})/ ) {
                        $message->type( $long_types{$1} );
                    }
                    else {
                        $message->type( 'M' );
                    }
                }
            }
        }
        $message->{id} = $value;
        return $message;
    } ## end sub id
} ## end BEGIN

# _export_messages
#   Oversees the injection of message issuers into the target namespace.
#
#   If messages are organised into one or more tag groups, then this method
#   also ensuring that the target namespace is an Exporter before updating
#   the @EXPORT_OK, %EXPORT_TAGS in that namespace with details of the
#   messages being injected. To be clear, messages must be grouped before
#   this method stomps over the target namespace's @ISA, @EXPORT_OK, and
#   %EXPORT_TAGS.
#
#   The "main" namespace is an exception in that it never undergoes any
#   Exporter-related updates.
sub _export_messages
{
    no strict 'refs';
    my ( $package, $params ) = @_;
    my ( $ns, $messages, $export_tags, $export_ok, $export )
        = @{$params}{qw/namespace messages export_tags export_ok export/};
    for my $message ( @$messages ) {
        $message->_inject_into_namespace( $ns );
    }
    $package->_refresh_namespace_export_tags( $ns, $export_tags, $messages )
        if ref( $export_tags ) && @$export_tags;
    $package->_refresh_namespace_export_ok( $ns, $messages )
        if $export_ok;
    $package->_refresh_namespace_export( $ns, $messages )
        if $export;
    return $package;
}

# _inject_into_namespace_a_message
#   Clone the issuer and inject an appropriately named clone into
#   the tartget namespace. Cloning helps avoid the pitfalls associated
#   with renaming duplicate anonymous code references.
sub _inject_into_namespace
{
    no strict 'refs';
    my ( $message, $ns ) = @_;
    my ( $id, $type ) = @{$message}{ 'id', 'type' };
    my $sym = "$ns\::$id";
    $sym =~ s/-/_/g;
    # Clone the issuer, otherwise naming the __ANON__ function could
    # be a little dicey!
    my $clone = sub {
        # Must "close over" message to clone.
        @_ = ( $message, @_ );    # Make sure we pass the message on
        goto &_issue;             # ... and keep the calling frame in-tact!
    };
    # Name and inject the message issuer
    *$sym = set_subname( $sym => $clone );
    # Record the message provider and rebless the message
    $message->_provider( $ns )->_rebless( "$ns\::Message::String" );
    return $message;
}

# _refresh_namespace_export
#   Updates the target namespace's @EXPORT, adding the names of any
#   message issuers.
sub _refresh_namespace_export
{
    no strict 'refs';
    my ( $package, $ns, $messages ) = @_;
    return $package
        unless $package->_ensure_namespace_is_exporter( $ns );
    my @symbols = map { $_->{id} } @$messages;
    @{"$ns\::EXPORT"}
        = distinct( @symbols, @{"$ns\::EXPORT"} );
    return $package;
}

# _refresh_namespace_export_ok
#   Updates the target namespace's @EXPORT_OK, adding the names of any
#   message issuers.
sub _refresh_namespace_export_ok
{
    no strict 'refs';
    my ( $package, $ns, $messages ) = @_;
    return $package
        unless $package->_ensure_namespace_is_exporter( $ns );
    my @symbols = map { $_->{id} } @$messages;
    @{"$ns\::EXPORT_OK"}
        = distinct( @symbols, @{"$ns\::EXPORT_OK"} );
    return $package;
}

# _refresh_namespace_export_tags
#   Updates the target namespace's %EXPORT_TAGS, adding the names of any
#   message issuers.
sub _refresh_namespace_export_tags
{
    no strict 'refs';
    my ( $package, $ns, $export_tags, $messages ) = @_;
    return $package
        unless $package->_ensure_namespace_is_exporter( $ns );
    return $package
        unless ref( $export_tags ) && @$export_tags;
    my @symbols = map { $_->{id} } @$messages;
    for my $tag ( @$export_tags ) {
        ${"$ns\::EXPORT_TAGS"}{$tag} = []
            unless defined ${"$ns\::EXPORT_TAGS"}{$tag};
        @{ ${"$ns\::EXPORT_TAGS"}{$tag} }
            = distinct( @symbols, @{ ${"$ns\::EXPORT_TAGS"}{$tag} } );
    }
    return $package;
}

# _ensure_namespace_is_exporter
#   Returns 0 if the namespace is "main", and does nothing else.
#   Returns 1 if the namespace is not "main", and prepends "Exporter" to the
#   target namespace @ISA array.
sub _ensure_namespace_is_exporter
{
    no strict 'refs';
    my ( $invocant, $ns ) = @_;
    return 0 if $ns eq 'main';
    require Exporter;
    unshift @{"$ns\::ISA"}, 'Exporter'
        unless $ns->isa( 'Exporter' );
    return 1;
}

# _provider
#   Sets or gets the package that provided the message.
sub _provider
{
    my ( $message, $value ) = @_;
    return $message->{provider}
        unless @_ > 1;
    $message->{provider} = $value;
    return $message;
}

# _rebless
#   Re-blesses a message using its id as the class name, and prepends the
#   message's old class to the new namespace's @ISA array.
#
#   Optionally, the developer may pass a sequence of method-name and code-
#   reference pairs, which this method will set up in the message's new
#   namespace. This crude facility allows for existing methods to be
#   overriddden on a message by message basis.
#
#   Though not actually required by any of the code in this module, this
#   method has been made available to facilitate any special treatment
#   a developer may want for a particular message.
sub _rebless
{
    no strict 'refs';
    my ( $message, @pairs ) = @_;
    my $id = $message->id;
    my $class;
    if ( @pairs % 2 ) {
        $class = shift @pairs;
    }
    else {
        $class = join( '::', $message->_provider, $id );
    }
    push @{"$class\::ISA"}, ref( $message )
        unless $class->isa( ref( $message ) );
    while ( @pairs ) {
        my $method  = shift @pairs;
        my $coderef = shift @pairs;
        next unless $method && !ref( $method );
        next unless ref( $coderef ) && ref( $coderef ) eq 'CODE';
        my $sym = "$id\::$method";
        *$sym = set_subname( $sym, $coderef );
    }
    return bless( $message, $class );
}

# readmode
#   Set or get the message's readmode attribute. Typically, only Type R
#   (Response) messages will set this attribute.
sub readmode
{
    my ( $message, $value ) = @_;
    return exists( $message->{readmode} ) ? $message->{readmode} : 0
        unless @_ > 1;
    $message->{readmode} = $value || 0;
    return $message;
}

# response
#   Set or get the message's response attribute. Typically, only Type R
#   (Response) messages will set this attribute.
sub response
{
    my ( $message, $value ) = @_;
    return exists( $message->{response} ) ? $message->{response} : undef
        unless @_ > 1;
    $message->{response} = $value;
    return $message;
}

# output
#   Set or get the message's output attribute. Typically, only the message
#   formatter ("_format") would set this attribute.
sub output
{
    my ( $message, $value ) = @_;
    return exists( $message->{output} ) ? $message->{output} : undef
        unless @_ > 1;
    $message->{output} = $value;
    return $message;
}

# to_string
#   Stringify the message. Return the "output" attribute if it exists and
#   it has been defined, otherwise return the message's formatting template.
#   The "" (stringify) operator for the message's class has been overloaded
#   using this method.
sub to_string
{
    return $_[0]{output};
}

# template
#   Set or get the message's formatting template. The template is any valid
#   string that might otherwise pass for a "sprintf" format.
sub template
{
    my ( $message, $value ) = @_;
    return $message->{template}
        unless @_ > 1;
    C_MISSING_TEMPLATE( $message->id )
        unless $value;
    $message->{template} = $value;
    return $message;
}

# type
#   The message's 1-character type code (A, N, I, C, E, W, M, R, D).
sub type
{
    my ( $message, $value ) = @_;
    return $message->{type}
        unless @_ > 1;
    my $type = uc( $value );
    if ( length( $type ) > 1 ) {
        my $long_types = $message->_types_by_alias;
        $type = $long_types->{$type} || 'M';
    }
    if ( $message->_update_level_on_type_change ) {
        my $level = $message->_type_level( $type );
        $level = $message->_type_level( 'M' )
            unless defined $level;
        $message->level( $level );
    }
    delete $message->{types}
        if exists $message->{types};
    $message->{type} = $type;
    return $message;
}

# level
#   The message's severity level.
sub level
{
    my ( $message, $value ) = @_;
    return $message->{level} unless @_ > 1;
    if ( $value =~ /\D/ ) {
        my $type = uc( $value );
        if ( length( $type ) > 1 ) {
            my $long_types = $message->_types_by_alias;
            $type = $long_types->{$type} || 'M';
        }
        $value = $message->_type_level( $type );
        $value = $message->_type_level( 'M' )
            unless defined $value;
    }
    $message->{level} = $value;
    return $message;
}

BEGIN { *severity = \&level }

# _new_from_string
#   Create one or more messages from a string. Messages are separated by
#   newlines. Each message consists of a message identifier and a formatting
#   template, which are themselves separated by one or more spaces or tabs.
sub _new_from_string
{
    my ( $invocant, $string ) = @_;
    my @lines;
    for my $line ( grep { m{\S} && m{^[^#]} }
                   split( m{\s*\n\s*}, $string ) )
    {
        my ( $id, $text ) = split( m{[\s\t]+}, $line, 2 );
        if ( @lines && $id =~ m{^[.]+$} ) {
            $lines[-1] =~ s{\z}{ $text}s;
        }
        elsif ( @lines && $id =~ m{^[+]+$} ) {
            $lines[-1] =~ s{\z}{\n$text}s;
        }
        else {
            push @lines, ( $id, $text );
        }
    }
    return $invocant->_new_from_arrayref( \@lines );
}

# _new_from_arrayref
#   Create one or more messages from an array. Each element of the array is
#   an array of two elements: a message identifier and a formatting template.
sub _new_from_arrayref
{
    my ( $invocant, $arrayref ) = @_;
    return $invocant->_new_from_hashref( {@$arrayref} );
}

# _new_from_hashref
#   Create one or more messages from an array. Each element of the array is
#   an array of two elements: a message identifier and a formatting template.
sub _new_from_hashref
{
    my ( $invocant, $hashref ) = @_;
    return map { $invocant->_new( $_, $hashref->{$_} ) } keys %$hashref;
}

# _new
#   Create a new message from message identifier and formatting template
#   arguments.
sub _new
{
    my ( $class, $message_id, $message_template ) = @_;
    $class = ref( $class ) || $class;
    my $message = bless( {}, $class );
    $message->id( $message_id );
    s{\\n}{\n}g,
        s{\\r}{\r}g,
        s{\\t}{\t}g,
        s{\\a}{\a}g,
        s{\\s}{ }g for $message_template;
    $message->template( $message_template );

    if ( $message->type eq 'R' && $message->template =~ m{password}si ) {
        $message->readmode( '-echo' );
    }
    return $message;
}
# import
#   Import new messages into the caller's namespace.
sub import
{
    my ( $package, @args ) = @_;
    if ( @args ) {
        my ( @tags, @messages, $export, $export_ok );
        my $caller = caller;
        while ( @args ) {
            my $this_arg = shift( @args );
            my $ref_type = reftype( $this_arg );
            if ( $ref_type ) {
                if ( $ref_type eq 'HASH' ) {
                    push @messages, __PACKAGE__->_new_from_hashref( $this_arg );
                }
                elsif ( $ref_type eq 'ARRAY' ) {
                    push @messages, __PACKAGE__->_new_from_arrayref( $this_arg );
                }
                else {
                    C_EXPECT_HAREF_OR_KVPL;
                }
                $package->_export_messages(
                    { namespace   => $caller,
                      messages    => \@messages,
                      export_tags => \@tags,
                      export_ok   => $export_ok,
                      export      => $export,
                    }
                ) if @messages;
                @tags     = ();
                @messages = ();
                undef $export;
                undef $export_ok;
            }
            else {
                if ( $this_arg eq 'EXPORT' ) {
                    if ( @messages ) {
                        $package->_export_messages(
                            { namespace   => $caller,
                              messages    => \@messages,
                              export_tags => \@tags,
                              export_ok   => $export_ok,
                              export      => $export,
                            }
                        );
                        @messages = ();
                        @tags     = ();
                    }
                    $export = 1;
                    undef $export_ok;
                }
                elsif ( $this_arg eq 'EXPORT_OK' ) {
                    if ( @messages ) {
                        $package->_export_messages(
                            { namespace   => $caller,
                              messages    => \@messages,
                              export_tags => \@tags,
                              export_ok   => $export_ok,
                              export      => $export,
                            }
                        );
                        @messages = ();
                        @tags     = ();
                    }
                    $export_ok = 1;
                    undef $export;
                }
                elsif ( substr( $this_arg, 0, 1 ) eq ':' ) {
                    ( my $tag = substr( $this_arg, 1 ) ) =~ s/(?:^\s+|\s+$)//;
                    my @new_tags = split m{\s*[,]?\s*[:]}, $tag;
                    push @tags, @new_tags;
                    $package->_export_messages(
                        { namespace   => $caller,
                          messages    => \@messages,
                          export_tags => \@tags,
                          export_ok   => $export_ok,
                          export      => $export,
                        }
                    ) if @messages;
                    @messages  = ();
                    $export_ok = 1;
                    undef $export;
                }
                else {
                    if ( @args ) {
                        push @messages, __PACKAGE__->_new( $this_arg, shift( @args ) );
                    }
                    else {
                        push @messages, __PACKAGE__->_new_from_string( $this_arg );
                    }
                }
            } ## end else [ if ( $ref_type ) ]
        } ## end while ( @args )
        if ( @messages ) {
            $package->_export_messages(
                { namespace   => $caller,
                  messages    => \@messages,
                  export_tags => \@tags,
                  export_ok   => $export_ok,
                  export      => $export,
                }
            );
        }
    } ## end if ( @args )
    return $package;
} ## end sub import

use message {
    C_EXPECT_HAREF_OR_KVPL =>
        'Expected list of name-value pairs, or reference to an ARRAY or HASH of the same',
    C_BAD_MESSAGE_ID   => 'Message identifier "%s" is invalid',
    C_MISSING_TEMPLATE => 'Message with identifier "%s" has no template'
};

1;

=pod

=encoding utf8

=head1 NAME

Message::String - A pragma to declare and organise messaging.

=head1 VERSION

version 0.1.9

=head1 SYNOPSIS

This module helps you organise, identify, define and use messaging
specific to an application or message domain.

=head2 Using the pragma to define message strings

=over

=item The pragma's package name may be used directly:

    # Declare a single message
    use Message::String INF_GREETING => "Hello, World!";
    
    # Declare multiple messages
    use Message::String {
        INF_GREETING  => "I am completely operational, " .
                         "and all my circuits are functioning perfectly.",
        RSP_DO_WHAT   => "What would you have me do?\n",
        NTC_FAULT     => "I've just picked up a fault in the %s unit.",
        CRT_NO_CAN_DO => "I'm sorry, %s. I'm afraid I can't do that",
    };

=item Or, after loading the module, the C<message> alias may be used:

    # Load the module
    use Message::String;

    # Declare a single message
    use message INF_GREETING => "Hello, World!";

    # Declare multiple messages
    use message {
        INF_GREETING  => "I am completely operational, " .
                         "and all my circuits are functioning perfectly.",
        RSP_DO_WHAT   => "What would you have me do?\n",
        NTC_FAULT     => "I've just picked up a fault in the %s unit.",
        CRT_NO_CAN_DO => "I'm sorry, %s. I'm afraid I can't do that",
    };

(B<Note>: the C<message> pragma may be favoured in future examples.)

=back

=head2 Using message strings in your application

Using message strings in your code is really easy, and you have choice about
how to do so: 

=over

=item B<Example 1>

    # Ah, the joyless tedium that is composing strings using constants...
    $name = "Dave";
    print INF_GREETING, "\n";
    print RSP_DO_WHAT;
    chomp(my $response = <STDIN>);
    if ($response =~ /Open the pod bay doors/i) 
    {
        die sprintf(CRT_NO_CAN_DO, $name);
    }
    printf NTC_FAULT . "\n", 'AE-35';

Using messages this way can sometimes be useful but, on this occasion, aptly
demonstrates why constants get a bad rap. This pattern of usage works fine, 
though you could just have easily used the C<constant> pragma, or one of
the alternatives.

=item B<Example 2>

    $name = 'Dave';
    INF_GREETING;                   # Display greeting (stdout)
    RSP_DO_WHAT;                    # Prompt for response (stdout/stdin)
    if ( /Open the pod bay doors/ ) # Check response; trying $_ but
    {                               # RSP_DO_WHAT->response works, too!
        CRT_NO_CAN_DO($name);       # Throw hissy fit (Carp::croak)
    }
    NTC_FAULT('AE-35');             # Issue innocuous notice (stderr)

=back

C<Message::String> objects take care of things like printing info messages
to stdout; printing response messages to stdout, and gathering input from 
STDIN; putting notices on stderr, and throwing exceptions for critical 
errors. They do all the ancillary work so you don't have to; hiding away
oft used sprinklings that make code noisy. 

=head2 Exporting message strings to other packages

It is also possible to have a module export its messages for use by other
packages. By including C<EXPORT> or C<EXPORT_OK> in the argument list,
before your messages are listed, you can be sure that your package will
export your symbols one way or the other.

The examples below show how to export using C<EXPORT> and C<EXPORT_OK>; they
also demonstrate how to define messages using less onerous string catalogues
and, when doing so, how to split longer messages in order to keep the lengths
of your lines manageable:

=over

=item B<Example 1>

    package My::App::Messages;
    use Message::String EXPORT => << 'EOF';
    INF_GREETING  I am completely operational,
    ...           and all my circuits are functioning perfectly.
    RSP_DO_WHAT   What would you have me do?\n
    NTC_FAULT     I've just picked up a fault in the %s unit.
    CRT_NO_CAN_DO I'm sorry, %s. I'm afraid I can't do that
    EOF
    1;

    # Meanwhile, back at main::
    use My::App::Messages;                  # No choice. We get everything!

=item B<Example 2>

    package My::App::Messages;
    use Message::String EXPORT_OK => << 'EOF';
    INF_GREETING  I am completely operational,
    ...           and all my circuits are functioning perfectly.
    RSP_DO_WHAT   What would you have me do?\n
    NTC_FAULT     I've just picked up a fault in the %s unit.
    CRT_NO_CAN_DO I'm sorry, %s. I'm afraid I can't do that
    EOF
    1;

    # Meanwhile, back at main::
    use My::App::Messages 'INF_GREETING';   # Import what we need

(B<Note>: you were probably astute enough to notice that, despite the HEREDOC 
marker being enclosed in single quotes, there is a C<\n> at the end of one
of the message definitions. This isn't an error; the message formatter will
deal with that.)

It is also possible to place messages in one or more groups by including
the group tags in the argument list, before the messages are defined. Group
tags I<must> start with a colon (C<:>).

=item B<Example 3>

    package My::App::Messages;
    use My::App::Messages;
    use message ':MESSAGES' => {
        INF_GREETING  => "I am completely operational, " .
                         "and all my circuits are functioning perfectly.",
        RSP_DO_WHAT   => "What would you have me do?\n",
        NTC_FAULT     => "I've just picked up a fault in the %s unit.",
    };
    use message ':MESSAGES', ':ERRORS' => {
        CRT_NO_CAN_DO => "I'm sorry, %s. I'm afraid I can't do that",
    };
    1;

    # Meanwhile, back at main::
    use My::App::Messages ':ERRORS';    # Import the errors
    use My::App::Messages ':MESSAGE';   # Import everything

=back

Tagging messages causes your module's C<%EXPORT_TAGS> hash to be updated, 
with tagged messages also being added to your module's C<@EXPORT_OK> array.

There is no expectation that you will make your package a descendant of the
C<Exporter> class. Provided you aren't working in the C<main::> namespace
then the calling package will be made a subclass of C<Exporter> automatically,
as soon as it becomes clear that it is necessary.

=head2 Recap of the highlights

This brief introduction demonstrates, hopefully, that as well as being able 
to function like constants, message strings are way more sophisticated than
constants. 

Perhaps your Little Grey Cells have also helped you make a few important
deductions:

=over

=item * That the name not only identifies, but characterises a message.

=item * That different types of message exist.

=item * That handling is influenced by a message's type.

=item * That messages are simple text, or they may be parameterised.

=back

You possibly have more questions. Certainly, there is more to the story 
and these are just the highlights. The module is described in greater
detail below.

=head1 DESCRIPTION

The C<Message::String> pragma and its alias (C<message>) are aimed at the
programmer who wishes to organise, identify, define, use (or make available
for use) message strings specific to an application or other message
domain. C<Message::String> objects are not unlike constants, in fact, they
may even be used like constants; they're just a smidge more helpful.

Much of a script's lifetime is spent saying stuff, asking for stuff, maybe
even complaining about stuff; but, most important of all, they have to do
meaningful stuff, good stuff, the stuff they were designed to do.

The trouble with saying, asking for, and complaining about stuff is the
epic amount of repeated stuff that needs to be done just to do that kind
of stuff. And that kind of stuff is like visual white noise when it's
gets in the way of understanding and following a script's flow.

We factor out repetetive code into reusable subroutines, web content into 
templates, but we do nothing about our script's messaging. Putting up with
broken strings, quotes, spots and commas liberally peppered around the place
as we compose and recompose strings doesn't seem to bother us.

What if we could organise our application's messaging in a way that kept
all of that noise out of the way? A way that allowed us to access messages
using mnemonics but have useful, sensible and standard things happen when
we do so. This module attempts to provide the tooling to do just that.

=head1 METHODS

C<Message::String> objects are created and injected into the symbol table 
during Perl's compilation phase so that they are accessible at runtime. Once 
the import method has done its job there is very little that may be done to
meaningfully alter the identity, purpose or destiny of messages.

A large majority of this module's methods, including constructors, are
therefore notionally and conventionally protected. There are, however, a
small number of public methods worth covering in this document.

=head2 Public Methods

=head3 import

    message->import();
    message->import( @options, @message_group, ... );
    message->import( @options, \%message_group, ... );
    message->import( @options, \@message_group, ... );
    message->import( @options, $message_group, ... );

The C<import> method is invoked at compile-time, whenever a C<use message> 
or C<use Message::String> directive is encountered. It processes any options
and creates any requested messages, injecting message symbols into 
the caller's symbol table.

B<Options>

=over

=item C<EXPORT>

Ensures that the caller's C<@EXPORT> list includes the names of messages
defined in the following group.

    # Have the caller mandate that these messages be imported:
    #
    use message EXPORT => { ... };

=item C<EXPORT_OK>

Ensures that the caller's C<@EXPORT_OK> list includes the names of messages
defined in the following group. The explicit use of C<EXPORT_OK> is not
necessary when tag groups are being used and its use is implied.

    # Have the caller make these messages importable individually and
    # upon request:
    #
    use message EXPORT_OK => { ... };

=item C<:I<EXPORT-TAG>>

One or more export tags may be listed, specifying that the following group
of messages is to be added to the listed tag group(s). Any necessary updates
to the caller's C<%EXPORT_TAGS> hash and C<@EXPORT_OK> array are made. The
explicit use of C<EXPORT_OK> is unnecessary since its use is implied.
 
Tags may be listed separately or together in the same string. Regardless of 
how they are presented, each tag must start with a colon (C<:>).

    # Grouping messages with a single tag:
    #
    use message ':FOO' => { ... };

    # Four valid ways to group messages with multiple tags:
    #
    use message ':FOO',':BAR' => { ... };
    use message ':FOO, :BAR' => { ... };
    use message ':FOO :BAR' => { ... };
    use message ':FOO:BAR' => { ... };

    # Gilding-the-lily; not wrong, but not necessary:
    #
    use message ':FOO', EXPORT_OK => { ... };

=back

Tag groups and other export options have no effect if the calling package
is C<main::>.

If the calling package hasn't already been declared a subclass of C<Exporter>
then the C<Exporter> package is loaded and the caller's C<@ISA> array will
be updated to include it as the first element.

(B<To do>: I should try to make this work with C<L<Sub::Exporter>>.)

B<Defining Messages>

A message is comprised of two tokens:

=over

=item The Message Identifier

The message id should contain no whitespace characters, consist only of 
upper- and/or lowercase letters, digits, the underscore, and be valid
as a Perl subroutine name. The id should I<ideally> be unique; at the
very least, it B<must> be unique to the package in which it is defined.

As well as naming a message, the message id is also used to determine the
message type and severity. Try to organise your message catalogues using
descriptive and consistent naming and type conventions.

(Read the section about L<MESSAGE TYPES> to see how typing works.)

=item The Message Template

The template is the text part of the message. It could be a simple string,
or it could be a C<sprintf> format complete with one or more parameter
placeholders. A message may accept arguments, in which case C<sprintf> will
merge the argument values with the template to produce the final output.

=back

Messages are defined in groups of one or more key-value pairs, and the 
C<import> method is quite flexible about how they are presented for
processing.

=over

=item As a flat list of key-value pairs.

    use message 
        INF_GREETING  => "I am completely operational, " .
                         "and all my circuits are functioning perfectly.",
        RSP_DO_WHAT   => "What would you have me do?\n",
        NTC_FAULT     => "I've just picked up a fault in the %s unit.",
        CRT_NO_CAN_DO => "I'm sorry, %s. I'm afraid I can't do that";

=item As an anonymous hash, or hash reference.

    use message { 
        INF_GREETING  => "I am completely operational, " .
                         "and all my circuits are functioning perfectly.",
        RSP_DO_WHAT   => "What would you have me do?\n",
        NTC_FAULT     => "I've just picked up a fault in the %s unit.",
        CRT_NO_CAN_DO => "I'm sorry, %s. I'm afraid I can't do that",
    };

=item As an anonymous array, or array reference.

    use message [ 
        INF_GREETING  => "I am completely operational, " .
                         "and all my circuits are functioning perfectly.",
        RSP_DO_WHAT   => "What would you have me do?\n",
        NTC_FAULT     => "I've just picked up a fault in the %s unit.",
        CRT_NO_CAN_DO => "I'm sorry, %s. I'm afraid I can't do that",
    ];

=item As a string (perhaps using a HEREDOC).

    use message << 'EOF';
    INF_GREETING  I am completely operational,
    ...           and all my circuits are functioning perfectly.
    RSP_DO_WHAT   What would you have me do?\n
    NTC_FAULT     I've just picked up a fault in the %s unit.
    CRT_NO_CAN_DO I'm sorry, %s. I'm afraid I can't do that
    EOF

When defining messages in this way, longer templates may be broken-up (as
shown on the third line of the example above) by placing one or more dots
(C<.>) where a message id would normally appear. This forces the text
fragment on the right to be appended to the template above, separated 
by a single space. Similarly, the addition symbol (C<+>) may be used
in place of dot(s) if a newline is desired as the separator. This is
particularly helpful when using PerlTidy and shorter line lengths.

=back

Multiple sets of export options and message groups may be added to the
same import method's argument list:

    use message ':MESSAGES, :MISC' => (
        INF_GREETING  => "I am completely operational, " .
                         "and all my circuits are functioning perfectly.",
        RSP_DO_WHAT   => "What would you have me do?\n",
    ), ':MESSAGES, :NOTICES' => (
        NTC_FAULT     => "I've just picked up a fault in the %s unit.",
    ), ':MESSAGES, :ERRORS' => (
        CRT_NO_CAN_DO => "I'm sorry, %s. I'm afraid I can't do that",
    ); 

When a message group has been processed any export related options that
are currently in force will be reset; no further messages will be marked
as exportable until a new set of export options and messages is added to
the same directive.   

Pay attention when defining messages as simple lists of key-value pairs, as
any new export option(s) will punctuate a list of messages up to that point 
and they will be processed as a complete group.

The message parser will also substitute the following escape sequences
with the correct character shown in parentheses: 

=over

=item * C<\n> (newline)

=item * C<\r> (linefeed)

=item * C<\t> (tab)

=item * C<\a> (bell)

=item * C<\s> (space)

=back

=head3 id

    MESSAGE_ID->id;

Gets the message's identifier.

=head3 level

    MESSAGE_ID->level( $severity_int );
    MESSAGE_ID->level( $long_or_short_type_str );
    $severity_int = MESSAGE_ID->level;

Sets or gets a message's severity level.

The severity level is always returned as an integer value, while it may be
set using an integer value or a type code (long or short) with the desired
value. 

=over

=item B<Example>

    # Give my notice a higher severity, equivalent to a warning.

    NTC_FAULT->level(4);
    NTC_FAULT->level('W');
    NTC_FAULT->level('WARNING');

=back

(See L<MESSAGE TYPES> for more informtion about typing.)

=head3 output
    
    $formatted_message_str = MESSAGE_ID->output; 

Returns the formatted text produced last time a particular message was 
used, or it returnd C<undef> if the message hasn't yet been issued. The
message's C<output> value would also include the values of any parameters
passed to the message.  

=over

=item B<Example>

    # Package in which messages are defined.
    #
    package My::App::MsgRepo;
    use Message::String EXPORT_OK => {
        NTC_FAULT => 'I've just picked up a fault in the %s unit.',
    };

    1;

    # Package in which messages are required.
    #
    use My::App::MsgRepo qw/NTC_FAULT/;
    use Test::More;

    NTC_FAULT('AE-35');     # The message is issued...

    # Some time later...
    diag NTC_FAULT->output; # What was the last reported fault again?

    # Output:
    # I've just picked up a fault in the AE-35 unit.

=back

=head3 readmode

    MESSAGE_ID->readmode( $io_stty_sttymode_str );
    $io_stty_sttymode_str = MESSAGE_ID->readmode;

Uses L<C<IO::Stty>> to set any special terminal driver modes when getting the
response from C<STDIN>. The terminal driver mode will be restored to its
normal state after the input has completed for the message.

This method is intended for use with Type R (Response) messages,
specifically to switch off TTY echoing for password entry. You should,
however, never need to use explicitly if the text I<"password"> is contained
within the message's template, as its use is implied.

=over

=item B<Example>

    RSP_MESSAGE->readmode('-echo');

=back

=head3 response

    $response_str = MESSAGE_ID->response;

Returns the input given in response to the message last time it was used, or
it returns C<undef> if the message hasn't yet been isssued.

The C<response> accessor is only useful with Type R (Response) messages.

=over

=item B<Example>

    # Package in which messages are defined.
    #
    package My::App::MsgRepo;
    use Message::String EXPORT_OK => {
        INF_GREETING => 'Welcome to the machine.',
        RSP_USERNAME => 'Username: ',
        RSP_PASSWORD => 'Password: ',
    };

    # Since RSP_PASSWORD is a response and contains the word "password",
    # the response is not echoed to the TTY.
    #
    # RSP_PASSWORD->readmode('noecho') is implied.

    1;

    # Package in which messages are required.
    #
    use My::App::MsgRepo qw/INF_GREETING RSP_USERNAME RSP_PASSWORD/;
    use DBI;

    INF_GREETING;       # Pleasantries
    RSP_USERNAME;       # Prompt for and fetch username
    RSP_PASSWORD;       # Prompt for and fetch password

    $dbh = DBI->connect( 'dbi:mysql:test;host=127.0.0.1',
        RSP_USERNAME->response, RSP_PASSWORD->response )
      or die $DBI::errstr;

=back

=head3 severity

    MESSAGE_ID->severity( $severity_int );
    MESSAGE_ID->severity( $long_or_short_type_str );
    $severity_int = MESSAGE_ID->severity;

(An alias for the C<level> method.)

=head3 template

    MESSAGE_ID->template( $format_or_text_str );
    $format_or_text_str = MESSAGE_ID->template;

Sets or gets the message template. The template may be a plain string of 
text, or it may be a C<sprintf> format containing parameter placeholders.

=over

=item B<Example>

    # Redefine our message templates.

    INF_GREETING->template('Ich bin völlig funktionsfähig, und alle meine '
        . 'Schaltungen sind perfekt funktioniert.');
    CRT_NO_CAN_DO->template('Tut mir leid, %s. Ich fürchte, ich kann das '
        . 'nicht tun.');
    
    # Some time later...
    
    INF_GREETING;
    CRT_NO_CAN_DO('Dave');

=back

=head3 to_string

    $output_or_template_str = MESSAGE_ID->to_string;

Gets the string value of the message. If the message has been issued then
you get the message output, complete with any message parameter values. If 
the message has not yet been issued then the message template is returned.

Message objects overload the stringification operator ("") and it is this
method that will be called whenever the string value of a message is
required.

=over

=item B<Example>

    print INF_GREETING->to_string . "\n"; 
    
    # Or, embrace your inner lazy:

    print INF_GREETING . "\n";

=back

=head3 type

    MESSAGE_ID->type( $long_or_short_type_str );
    $short_type_str = MESSAGE_ID->type;

Gets or sets a message's type characteristics, which includes its severity
level.

=over

=item B<Example>

    # Check my message's type

    $code = NTC_FAULT->type;    # Returns "N"

    # Have my notice behave more like a warning.

    NTC_FAULT->type('W');
    NTC_FAULT->type('WARNING');

=back

=head3 verbosity

    MESSAGE_ID->type( $severity_int );
    MESSAGE_ID->type( $long_or_short_type_str );
    $severity_int = MESSAGE_ID->verbosity;

Gets or sets the level above which messages will B<not> be issued. Messages
above this level may still be generated and their values are still usable,
but they are silenced.

I<You cannot set the verbosity level to a value lower than a standard Type E
(Error) message.>

=over

=item B<Example>

    # Only issue Alert, Critical, Error and Warning messages.

    message->verbosity('WARNING');  # Or ...
    message->verbosity('W');        # Or ...
    message->verbosity(4);

=back

=head3 overloaded ""

    $output_or_template_str = MESSAGE_ID;

Message objects overload Perl's I<stringify> operator, calling the
C<to_string> method.

=head1 MESSAGE TYPES

Messages come in nine great flavours, each identified by a single-letter 
type code. A message's type represents the severity of the condition that
would cause the message to be issued:

=head3 Type Codes

    Type  Alt   Level /   Type
    Code  Type  Priority  Description
    ----  ----  --------  ---------------------
    A     ALT      1      Alert
    C     CRT      2      Critical
    E     ERR      3      Error
    W     WRN      4      Warning
    N     NTC      5      Notice
    I     INF      6      Info
    D     DEB      7      Debug (or diagnostic)
    R     RSP      1      Response
    M     MSG      6      General message

=head2 How messages are assigned a type

When a message is defined an attempt is made to discern its type by examining
it for a series of clues in the message's identifier:

=over

=item B<Step 1>: check for a suffix matching C</:([DRAWNMICE])$/>

The I<type override> suffix spoils the fun by removing absolutely all of
the guesswork from the process of assigning type characteristics. It is 
kind of ugly but removes absolutely all ambiguity. It is somewhat special
in that it does not form part of the message's identifier, which is great 
if you have to temporarily re-type a message but don't want to hunt down
and change every occurrence of its use.

This suffix is a great substitute for limited imaginative faculties when
naming messages.

=item B<Step 2>: check for a suffix matching C</[_\d]([WINDCREAM])$/>

This step, like the following three steps, uses information embedded within
the identifier to determine the type of the message. Since message ids are
meant to be mnemonic, at least some attempt should be made by message
authors to convey purpose and meaning in their choice of id. 

=item B<Step 3>: check for a prefix matching C</^([RANCIDMEW])[_\d]/>

=item B<Step 4>: check for a suffix matching C</(I<ALTERNATION>)$/>,
where the alternation set is comprised of long type codes (see
L<Long Type Codes>).

=item B<Step 5>: check for a prefix matching C</^(I<ALTERNATION>)/>,
where the alternation set is comprised of long type codes (see
L<Long Type Codes>).

=item B<Step 6>: as a last resort the message is characterised as Type-M 
(General Message).

=back 

=head3 Long Type Codes

In addition to single-letter type codes, some longer aliases may under some
circumstances be used in their stead. This can and does make some statements
a little less cryptic.

We can use one of this package's protected methods (C<_types_by_alias>) to
not only list the type code aliases but also reveal type code equivalence:

    use Test::More;
    use Data::Dumper::Concise;
    use Message::String;
    
    diag Dumper( { message->_types_by_alias } );
    
    # {
    #   ALERT => "A",
    #   ALR => "A",
    #   ALT => "A",
    #   CRIT => "C",
    #   CRITICAL => "C",
    #   CRT => "C",
    #   DEB => "D",
    #   DEBUG => "D",
    #   DGN => "D",
    #   DIAGNOSTIC => "D",
    #   ERR => "E",
    #   ERROR => "E",
    #   FATAL => "C",
    #   FTL => "C",
    #   INF => "I",
    #   INFO => "I",
    #   INP => "R",
    #   INPUT => "R",
    #   MESSAGE => "M",
    #   MISC => "M",
    #   MSC => "M",
    #   MSG => "M",
    #   NOT => "N",
    #   NOTICE => "N",
    #   NTC => "N",
    #   OTH => "M",
    #   OTHER => "M",
    #   OTR => "M",
    #   PRM => "R",
    #   PROMPT => "R",
    #   RES => "R",
    #   RESPONSE => "R",
    #   RSP => "R",
    #   WARN => "W",
    #   WARNING => "W",
    #   WNG => "W",
    #   WRN => "W"
    # }

=head2 Changing a message's type

Under exceptional conditions it may be necessary to alter a message's type,
and this may be achieved in one of three ways:

=over

=item 1. I<Permanently,> by choosing a more suitable identifier. 

This is the cleanest way to make such a permanent change, and has only one
disadvantage: you must hunt down code that uses the old identifier and change
it. Fortunately, C<grep> is our friend and constants are easy to track down.

=item 2. I<Semi-permanently,> by using a type-override suffix.

    # Change NTC_FAULT from being a notice to a response, so that it 
    # blocks for input. We may still use the "NTC_FAULT" identifier.

    use message << 'EOF';
    NTC_FAULT:R   I've just picked up a fault in the %s unit.
    EOF

Find the original definition and append the type-override suffix, which
must match regular expression C</:[CREWMANID]$/>, obviously being careful
to choose the correct type code. This has a cosmetic advantage in that the
suffix will be effective but not be part of the the id. The disadvantage is
that this can render any forgotten changes invisible, so don't forget to 
change it back when you're done.

=item 3. I<Temporarily,> at runtime, using the message's C<type> mutator:

    # I'm debugging an application and want to temporarily change
    # a message named APP234I to be a response so that, when it displays,
    # it blocks waiting for input -
    
    APP234I->type('R');         # Or, ...
    APP234I->type('RSP');       # Possibly much clearer, or ...
    APP234I->type('RESPONSE');  # Clearer still
    
=back

=head1 WHISTLES, BELLS & OTHER DOODADS

=head2 Customising message output

Examples shown below operate on a pragma level, which affects all messages.

Any particular message may override any of these settings simply by replacing
C<message> with C<I<MESSAGE_ID>>.

=head3 Embedding timestamps

    # Get or set the default timestamp format
    $strftime_format_strn = message->_default_timestamp_format;
    message->_default_timestamp_format($strftime_format_str);
    
    # Don't embed time data in messages of specified type
    message->_type_timestamp($type_str, '');

    # Embed time data in messages of specified type, using default format
    message->_type_timestamp($type_str, 1);
    
    # Embed time data in messages of specified type, using specified format
    message->_type_timestamp($type_str, $strftime_format_str);

    # Don't Embed time data in ANY message types.
    message->_type_timestamp('');

    # Embed time data in ALL message types, using default format
    message->_type_timestamp(1);
    
=head3 Embedding type information

    # Embed no additional type info in messages of a type
    message->_type_tlc($type_str, '');

    # Embed additional type info in messages of a type (3-letters max)
    message->_type_tlc($type_str, $three_letter_code_str);

    # Example
    message->_type_tlc('I', 'INF');
    
=head3 Embedding the message id

    # Embed or don't embed message ids in a type of message 
    message->_type_id($type_str, $bool);
    
    # Embed or don't embed message ids in all types of message 
    message->_type_id($bool);

=head1 REPOSITORY

=over 2

=item * L<https://github.com/cpanic/Message-String>

=item * L<http://search.cpan.org/dist/Message-String/lib/Message/String.pm>

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-message-string at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Message-String>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Message::String


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Message-String>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Message-String>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Message-String>

=item * Search CPAN

L<http://search.cpan.org/dist/Message-String/>

=back

=head1 ACKNOWLEDGEMENTS

Standing as we all do from time to time on the shoulders of giants:

=over

=item Dave RolskyI<, et al.>

For L<DateTime>

=item Graham BarrI<, et al.>

For L<Scalar::Util> and L<Sub::Util>

=item Jens ReshackI<, et al.>

For L<List::MoreUtils>.

=item Austin Schutz & Todd Rinaldo

For L<IO::Stty>.

=item Ray Finch

For L<Clone>

=item Robert SedlacekI<, et al.>

For L<namespace::clean>

=back

=head1 AUTHOR

Iain Campbell <cpanic@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
