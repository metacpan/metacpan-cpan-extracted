#  ToDo
# + Move Error.pm code into module
# + 'with' clashes with Moose
# + Remove Simple
# + Support $_ as error topic
#
# - Add system error classes
# - Support autodie
# - Move most Error stuff into errors package
# - Replace ObjectifyCallback
#
# == Tests
# + otherwise
# + except
# + -with_using
# + $_ is used
#
# - assert function works
# - $@ is always undef
# - nesting of try stuff
# - works with Moose
# - works with Error
# - with becomes using if with already exists

#------------------------------------------------------------------------------
use strict; use warnings;
package errors;
our $VERSION = '0.13';

sub import {
    my ($class, $directive) = @_;
    if (not $directive) {
        $class->export_commands(
            qw(try with except otherwise finally assert)
        );
    }
    elsif ($directive eq '-with_using') {
        $class->export_commands(
            qw(try using except otherwise finally assert)
        );
    }
    elsif ($directive eq '-class') {
        my ($class, %fields) = @_[2..$#_];
        my $isa = $fields{-isa} || 'Exception';
        no strict 'refs';
        @{$class . '::ISA'} = ($isa);
    }
    else {
        die "Invalid usage of errors module: 'use errors @_[1..$#_]'";
    }
}

sub export_commands {
    my ($class, @exports) = @_;
    local @errors::subs::EXPORT = @exports;
    local $Exporter::ExportLevel += 2;
    errors::subs->import();
}

#------------------------------------------------------------------------------
# Inspired by code from Jesse Glick and Peter Seibel

package errors::subs;

use Exporter ();
our @ISA = qw(Exporter);

sub objectify {
    my $msg = shift;
    return RuntimeError->new($msg);
}

sub run_clauses ($$$\@) {
    my($clauses,$err,$wantarray,$result) = @_;
    my $code = undef;

    $err = objectify($err) unless ref($err);

    CATCH: {

        # catch
        my $catch;
        if(defined($catch = $clauses->{'catch'})) {
            my $i = 0;

            CATCHLOOP:
            for( ; $i < @$catch ; $i += 2) {
                my $pkg = $catch->[$i];
                unless(defined $pkg) {
                    #except
                    splice(@$catch,$i,2,$catch->[$i+1]->($err));
                    $i -= 2;
                    next CATCHLOOP;
                }
                elsif(Scalar::Util::blessed($err) && $err->isa($pkg)) {
                    $code = $catch->[$i+1];
                    while(1) {
                        my $more = 0;
                        local($Exception::THROWN, $@);
                        $_ = $@ = $err;
                        my $ok = eval {
                            $@ = $err;
                            if($wantarray) {
                                @{$result} = $code->($err,\$more);
                            }
                            elsif(defined($wantarray)) {
                                @{$result} = ();
                                $result->[0] = $code->($err,\$more);
                            }
                            else {
                                $code->($err,\$more);
                            }
                            1;
                        };
                        if( $ok ) {
                            next CATCHLOOP if $more;
                            undef $err;
                        }
                        else {
                            $err = $@ || $Exception::THROWN;
                                $err = objectify($err)
                                        unless ref($err);
                        }
                        last CATCH;
                    };
                }
            }
        }

        # otherwise
        my $owise;
        if(defined($owise = $clauses->{'otherwise'})) {
            my $code = $clauses->{'otherwise'};
            my $more = 0;
        local($Exception::THROWN, $@);
            $_ = $@ = $err;
            my $ok = eval {
                $@ = $err;
                if($wantarray) {
                    @{$result} = $code->($err,\$more);
                }
                elsif(defined($wantarray)) {
                    @{$result} = ();
                    $result->[0] = $code->($err,\$more);
                }
                else {
                    $code->($err,\$more);
                }
                1;
            };
            if( $ok ) {
                undef $err;
            }
            else {
                $err = $@ || $Exception::THROWN;

                $err = objectify($err)
                        unless ref($err);
            }
        }
    }
    undef $_;
    undef $@;
    return $err;
}

sub try (&;$) {
    my $try = shift;
    my $clauses = @_ ? shift : {};
    my $ok = 0;
    my $err = undef;
    my @result = ();

    my $wantarray = wantarray();

    do {
        local $Exception::THROWN = undef;
        local $@ = undef;

        $ok = eval {
            if($wantarray) {
                @result = $try->();
            }
            elsif(defined $wantarray) {
                $result[0] = $try->();
            }
            else {
                $try->();
            }
            1;
        };

        $err = $@ || $Exception::THROWN
            unless $ok;
    };

    $err = run_clauses($clauses,$err,wantarray,@result)
    unless($ok);

    $clauses->{'finally'}->()
        if(defined($clauses->{'finally'}));

    if (defined($err))
    {
        if (Scalar::Util::blessed($err) && $err->can('throw'))
        {
            throw $err;
        }
        else
        {
            die $err;
        }
    }

    wantarray ? @result : $result[0];
}

# Each clause adds a sub to the list of clauses. The finally clause is
# always the last, and the otherwise clause is always added just before
# the finally clause.
#
# All clauses, except the finally clause, add a sub which takes one argument
# this argument will be the error being thrown. The sub will return a code ref
# if that clause can handle that error, otherwise undef is returned.
#
# The otherwise clause adds a sub which unconditionally returns the users
# code reference, this is why it is forced to be last.
#
# The catch clause is defined in Exception.pm, as the syntax causes it to
# be called as a method

sub with (&;$) {
    @_
}

sub using (&;$) {
    @_
}

sub finally (&) {
    my $code = shift;
    my $clauses = { 'finally' => $code };
    $clauses;
}

# The except clause is a block which returns a hashref or a list of
# key-value pairs, where the keys are the classes and the values are subs.

sub except (&;$) {
    my $code = shift;
    my $clauses = shift || {};
    my $catch = $clauses->{'catch'} ||= [];

    my $sub = sub {
        my $ref;
        my(@array) = $code->($_[0]);
        if(@array == 1 && ref($array[0])) {
            $ref = $array[0];
            $ref = [ %$ref ]
                if(UNIVERSAL::isa($ref,'HASH'));
        }
        else {
            $ref = \@array;
        }
        @$ref
    };

    unshift @{$catch}, undef, $sub;

    $clauses;
}

sub otherwise (&;$) {
    my $code = shift;
    my $clauses = shift || {};

    if(exists $clauses->{'otherwise'}) {
        require Carp;
        Carp::croak("Multiple otherwise clauses");
    }

    $clauses->{'otherwise'} = $code;

    $clauses;
}

sub assert($$) {
    my ($value, $msg) = @_;
    return $value if $value;
    throw AssertionError($msg);
    die($msg);
}

#------------------------------------------------------------------------------
package Exception;

use overload (
        '""'       => 'stringify',
        '0+'       => 'value',
        'bool'     => sub { return 1; },
        'fallback' => 1
);

$Exception::Depth = 0;        # Depth to pass to caller()
$Exception::Debug = 0;        # Generate verbose stack traces
$Exception::THROWN = undef;   # last error thrown, a workaround until die $ref works

my $LAST;                # Last error created
my %ERROR;               # Last error associated with package

# Exported subs are defined in errors::subs

use Scalar::Util ();

# I really want to use last for the name of this method, but it is a keyword
# which prevent the syntax  last Exception

sub prior {
    shift; # ignore

    return $LAST unless @_;

    my $pkg = shift;
    return exists $ERROR{$pkg} ? $ERROR{$pkg} : undef
        unless ref($pkg);

    my $obj = $pkg;
    my $err = undef;
    if($obj->isa('HASH')) {
        $err = $obj->{'__Error__'}
            if exists $obj->{'__Error__'};
    }
    elsif($obj->isa('GLOB')) {
        $err = ${*$obj}{'__Error__'}
            if exists ${*$obj}{'__Error__'};
    }

    $err;
}

sub flush {
    shift; #ignore

    unless (@_) {
       $LAST = undef;
       return;
    }

    my $pkg = shift;
    return unless ref($pkg);

    undef $ERROR{$pkg} if defined $ERROR{$pkg};
}

# Return as much information as possible about where the error
# happened. The -stacktrace element only exists if $Exception::DEBUG
# was set when the error was created

sub stacktrace {
    my $self = shift;

    return $self->{'-stacktrace'}
        if exists $self->{'-stacktrace'};

    my $text = exists $self->{'-text'} ? $self->{'-text'} : "Died";

    $text .= sprintf(" at %s line %d.\n", $self->file, $self->line)
        unless($text =~ /\n$/s);

    $text;
}


sub associate {
    my $err = shift;
    my $obj = shift;

    return unless ref($obj);

    if($obj->isa('HASH')) {
        $obj->{'__Error__'} = $err;
    }
    elsif($obj->isa('GLOB')) {
        ${*$obj}{'__Error__'} = $err;
    }
    $obj = ref($obj);
    $ERROR{ ref($obj) } = $err;

    return;
}


sub new {
    my $self = shift;
    my($pkg,$file,$line) = caller($Exception::Depth);

    my $err = bless {
        '-package' => $pkg,
        '-file'    => $file,
        '-line'    => $line,
        ((@_ % 2) ? ('-text') : ()),
        @_
    }, $self;

    $err->associate($err->{'-object'})
        if(exists $err->{'-object'});

    # To always create a stacktrace would be very inefficient, so
    # we only do it if $Exception::Debug is set

    if($Exception::Debug) {
        require Carp;
        local $Carp::CarpLevel = $Exception::Depth;
        my $text = defined($err->{'-text'}) ? $err->{'-text'} : "Exception";
        my $trace = Carp::longmess($text);
        # Remove try calls from the trace
        $trace =~ s/(\n\s+\S+__ANON__[^\n]+)?\n\s+eval[^\n]+\n\s+errors::subs::try[^\n]+(?=\n)//sog;
        $trace =~
        s/(\n\s+\S+__ANON__[^\n]+)?\n\s+eval[^\n]+\n\s+errors::subs::run_clauses[^\n]+\n\s+errors::subs::try[^\n]+(?=\n)//sog;
        $err->{'-stacktrace'} = $trace
    }

    $@ = $LAST = $ERROR{$pkg} = $err;
}

# Throw an error. this contains some very gory code.

sub throw {
    my $self = shift;
    local $Exception::Depth = $Exception::Depth + 1;

    # if we are not rethrow-ing then create the object to throw
    $self = $self->new(@_) unless ref($self);

    die $Exception::THROWN = $self;
}

# catch clause for
#
# try { ... } catch CLASS with { ... }

sub catch {
    my $pkg = shift;
    my $code = shift;
    my $clauses = shift || {};
    my $catch = $clauses->{'catch'} ||= [];

    unshift @$catch,  $pkg, $code;

    $clauses;
}

# Object query methods

sub object {
    my $self = shift;
    exists $self->{'-object'} ? $self->{'-object'} : undef;
}

sub file {
    my $self = shift;
    exists $self->{'-file'} ? $self->{'-file'} : undef;
}

sub line {
    my $self = shift;
    exists $self->{'-line'} ? $self->{'-line'} : undef;
}

sub text {
    my $self = shift;
    exists $self->{'-text'} ? $self->{'-text'} : undef;
}

# overload methods

sub stringify {
    my $self = shift;
    defined $self->{'-text'} ? $self->{'-text'} : "Died";
}

sub value {
    my $self = shift;
    exists $self->{'-value'} ? $self->{'-value'} : undef;
}

#------------------------------------------------------------------------------
package RuntimeError;
our @ISA = 'Exception';

package AssertionError;
our @ISA = 'Exception';

1;
