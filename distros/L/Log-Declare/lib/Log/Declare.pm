package Log::Declare;
# ABSTRACT: A high performance Perl logging module.

use 5.10.0; # for //
use strict;
use warnings;

use Devel::Declare::Lexer;
use Devel::Declare::Lexer::Token::Raw;
use POSIX qw(strftime);
use Data::Dumper; # for d: statements

our $VERSION = '0.10';

my %LEVEL = (
    ALL     => -1,
    TRACE   =>  1,
    DEBUG   =>  2,
    INFO    =>  3,
    WARN    =>  4,
    ERROR   =>  5,
    AUDIT   =>  6,
    OFF     =>  7,
    DISABLE =>  7,
);

# XXX be careful about removing/renaming this: it's required by MojoX::Log::Declare
our @level_priority = qw(audit error warn info debug trace);

my ($LEVEL, $LEVEL_NAME);
__PACKAGE__->startup_level($ENV{'LOG_DECLARE_STARTUP_LEVEL'} || 'ERROR'); # sets $LEVEL and $LEVEL_NAME

my $log_statement = "Log::Declare->log('%s', [%s], %s)%s";

unless($ENV{LOG_DECLARE_NO_STARTUP_NOTICE}) {
    Log::Declare->log('INFO', ['LOGGER'], "Got logger startup level of $LEVEL_NAME");
}

# this provides a way to globally override the behaviour of the injected keywords.
# if replaced by e.g. a sub which returns 0, the level will be completely disabled and
# the log writer won't be called. The original implementations can be restored at any
# time by deleting the hooks.
# XXX be careful about removing/renaming this: it's required for namespace hooks (see
# the NAMESPACES section in the POD).
our %levels;

# define the exported trace, debug &c. subs. These delegate to the hooked implementations
# in %levels (if defined); otherwise they return true/false if the level is enabled/disabled
my %EXPORT;
for my $name (@level_priority) {
    my $hook;
    my $level = $LEVEL{uc $name};
    # goto &sub: make sure caller() works as expected in the hooked sub
    $EXPORT{$name} = sub { ($hook = $levels{$name}) ? goto &$hook : $level >= $LEVEL };
}

BEGIN {
    my $callback = sub {
        my ($stream_r) = @_;
        my @stream = @$stream_r;

        # Get the declarator
        my $decl = $stream[0];

        shift @stream; # remove the declarator
        while (ref($stream[0]) =~ /Devel::Declare::Lexer::Token::Whitespace/) {
            shift @stream; # remove the whitespace
        }

        if(ref($stream[$#stream]) =~ /Devel::Declare::Lexer::Token::Newline/) {
            pop @stream; # remove the newline
        }
        pop @stream; # remove the semicolon

        # Work backwards from the end looking for if statement
        my $nested = 0;
        my $ifStart = -1;
        for(my $i = $#stream; $i >= 0; $i--) {
            my $token = $stream[$i];

            if(ref($token) =~ /Devel::Declare::Lexer::Token::RightBracket/ &&
               $token->{value} =~ /\]/) {
                $nested++;
                next;
            }
            if(ref($token) =~ /Devel::Declare::Lexer::Token::LeftBracket/ &&
               $token->{value} =~ /\[/) {
                $nested--;
                next;
            }
            if($nested == 0 && ref($token) =~ /Devel::Declare::Lexer::Token::Bareword/ &&
                ($token->{value} eq 'if' || $token->{value} eq 'unless')) {
                $ifStart = $i;
                last;
            }
        }

        # Extract the conditional tokens
        my @condTokens;
        if($ifStart > -1) {
            my $soc = $ifStart;
            my $eoc = $#stream;
            @condTokens = @stream[$soc .. $eoc];
            @stream = @stream[0 .. $ifStart - 1];
        }

        # Work backwards from the end looking for categories
        $nested = 0;
        my $catStart = -1;
        for(my $i = $#stream; $i >= 0; $i--) {
            my $token = $stream[$i];

            if(ref($token) =~ /Devel::Declare::Lexer::Token::RightBracket/ &&
               $token->{value} =~ /\]/) {
                $nested++;
                next;
            }
            if(ref($token) =~ /Devel::Declare::Lexer::Token::LeftBracket/ &&
               $token->{value} =~ /\[/) {
                $nested--;
                if($nested == 0) {
                    if($stream[$i-1] && ref($stream[$i-1]) !~ /Devel::Declare::Lexer::Token::Whitespace/) {
                        next;
                    }
                    $catStart = $i;
                    last;
                }
                next;
            }
        }

        # Extract the category tokens
        my @catTokens;
        if($catStart > -1) {
            my $soc = $catStart + 1;
            my $eoc = $#stream - 1;
            @catTokens = @stream[$soc .. $eoc];
            @stream = @stream[0 .. $catStart - 1];
        }

        # Convert the tokens into a list of category names
        my @categories;
        if(scalar @catTokens) {
            my $buf = '';
            for my $token (@catTokens) {
                if(ref($token) =~ /Devel::Declare::Lexer::Token::Comma/) {
                    push @categories, (uc "\"$buf\"") if $buf;
                    $buf = '';
                    next;
                }
                next if $buf eq '' && ref($token) =~ /Devel::Declare::Lexer::Token::Whitespace/;
                $buf .= $token->{value};
            }
            push @categories, uc("\"$buf\"") if $buf;
        }
        push @categories, "\"GENERAL\"" if scalar @categories == 0;

        # Create a new stream from whats left
        my @ns = ();
        tie @ns, "Devel::Declare::Lexer::Stream";

        # See how many arguments we have
        my $nest = 0;
        my $bits = 0;

        for my $tok (@stream) {
            if(ref($tok) =~ /Devel::Declare::Lexer::Token::LeftBracket/) {
                $nest++;
                next;
            }
            if(ref($tok) =~ /Devel::Declare::Lexer::Token::RightBracket/) {
                $nest++;
                next;
            }
            if($nest == 0 && ref($tok) =~ /Devel::Declare::Lexer::Token::Operator/ &&
                $tok->{value} =~ /,/) {
                $bits++;
            }
        }

        # Reconstruct the log statement
        my $level = $decl->{value};
        my $cats = join ', ', @categories;
        my $inner = join '', map { $_->get } @stream;

        # Handle prefixes
        $inner =~ s/([\s,])d:([\\\$\@\%\&\*]+[^\s,]+)/$1Data::Dumper::Dumper($2)/g;
        $inner =~ s/([\s,])r:([\\\$\@\%\&\*]+[^\s,]+)/$1ref($2)/g;

        my $msg = '';
        if ($bits) {
            $msg = 'sprintf(' if $bits;
            $msg .= $inner;
            $msg .= ')' if $bits;
        } else {
            $msg = $inner;
        }
        my $cond = ' ' . join '', map { $_->get } @condTokens;

        my $output = Devel::Declare::Lexer::Token::Raw->new(
            value => sprintf($log_statement, $level, $cats, $msg, $cond)
        );

        return [
            $decl,
            Devel::Declare::Lexer::Token::Whitespace->new(value => ' '), $output,
            Devel::Declare::Lexer::Token::EndOfStatement->new,
            Devel::Declare::Lexer::Token::Newline->new
        ];
    };

    # Setup callbacks for each of the keywords
    Devel::Declare::Lexer::lexed(audit => $callback);
    Devel::Declare::Lexer::lexed(info  => $callback);
    Devel::Declare::Lexer::lexed(warn  => $callback);
    Devel::Declare::Lexer::lexed(error => $callback);
    Devel::Declare::Lexer::lexed(debug => $callback);
    Devel::Declare::Lexer::lexed(trace => $callback);
}

# -----------------------------------------------------------------------------

# set the global log level
# FIXME this should be called level
sub startup_level {
    my $self = shift;

    if (@_) {
        my $level = shift // '';
        $LEVEL_NAME = uc $level;
        # ALL: be forgiving if the name is invalid/mistyped (see below)
        $LEVEL = $LEVEL{$LEVEL_NAME} // $LEVEL{ALL};
    } else {
        return $LEVEL_NAME;
    }
}

# -----------------------------------------------------------------------------

sub log_statement {
    my ($self, $statement) = @_;

    return $log_statement unless $statement;
    $log_statement = $statement;
    return $log_statement;
}

# -----------------------------------------------------------------------------

sub log {
    my ($self, $level_name, $categories, $message) = @_;

    $level_name = uc($level_name // '');

    # be forgiving if the log level is mistyped/invalid: it's going
    # to be easier to remove an unwanted log message than to track
    # down a bug that isn't being logged because of a typo
    my $level = $LEVEL{$level_name} // $LEVEL;

    return unless $level >= $LEVEL;

    if($categories) {
        $categories = scalar @$categories > 0 ? (join ', ', @$categories) : '';
        $categories = " [$categories]";
    }

    my $ts = strftime $ENV{'LOG_DECLARE_DATE_FORMAT'} // "%a %b %e %H:%M:%S %Y",
                      ($ENV{'LOG_DECLARE_USE_LOCALTIME'} ? localtime : gmtime);

    $message .= "\n" if substr($message,-1) ne "\n";

    return CORE::print STDERR "$$ [$ts] [$level_name]$categories $message";
}

# -----------------------------------------------------------------------------

sub capture {
    my ($self, $capture, $coderef) = @_;

    {
        no strict 'refs';
        *{$capture} = sub {
            my $logger = shift;
            @_ = $coderef->(@_) if $coderef;
            $self->log('debug', [ref($logger)], @_);
        };
    }
}

# -----------------------------------------------------------------------------

sub import {
    my ($class, @tags) = @_;

    my $caller = caller;
    Log::Declare->do_import($caller, @tags);
}

# -----------------------------------------------------------------------------

sub export_to_level {
    my ($class, $level, @tags) = @_;

    my $caller = caller($level);
    Log::Declare->do_import($caller, @tags);
}

# -----------------------------------------------------------------------------

sub do_import {
    my ($class, $caller, @tags) = @_;

    my %t = map { $_ => 1 } @tags;
    return if $t{':nosyntax'};

    # Inject each of the keywords into the caller's namespace
    for my $name (@level_priority) {
        Devel::Declare::Lexer::import_for($caller, {
            $name => $EXPORT{$name}
        }) if !$t{":no$name"};
    }
}

# -----------------------------------------------------------------------------

=pod

=head1 NAME

Log::Declare - A high performance Perl logging module

=head1 OVERVIEW

Creates syntactic sugar for logging using categories with sprintf support.

Complex logging statements can be written without impacting on performance
when those log levels are disabled.

For example, using a typical logger, this would incur a penalty even if
the logging is disabled:

    $self->log(Dumper $myobject);

but with Log::Declare we incur almost no performance penalty if 'info' level is
disabled, since the following log statement:

    info Dumper $myobject [mycategory];

gets rewritten as:

    info && $Log::Declare::logger->log('info', ['mycategory'], Dumper $myobject);

which means if 'info' returns 0, nothing else gets evaluated.

=head1 SYNOPSIS

    use Log::Declare;
    use Log::Declare qw/ :nosyntax /; # disables syntactic sugar
    use Log::Declare qw/ :nowarn :noerror ... /; # disables specific sugar

    # with syntactic sugar
    debug "My debug message" [category];
    error "My error message: %s", $error [category1, category2];

    # auto-dump variables with Data::Dumper
    debug "Using sprintf format: %s", d:$error [category];

    # auto-ref variables with ref()
    debug "Using sprintf format: %s", r:$error [category];

    # capture other loggers (loses Log::Declare performance)
    Log::Declare->capture('Test::Logger::log');
    Log::Declare->capture('Test::Logger::log' => sub {
        my ($logger, @args) = @_;
        # manipulate logger args here
        return @args;
    });

=head1 NAMESPACES

If you're using a namespace-aware logger, Log::Declare can use your logger's
namespacing to determine log levels. For example:

    $Log::Declare::levels{'debug'} = sub {
        Log::Log4perl->get_logger(caller)->is_debug;
    };

=cut

1;

