package Getopt::Modular;
$Getopt::Modular::VERSION = '0.13';
#ABSTRACT: Modular access to Getopt::Long

use warnings;
use strict;

use Getopt::Long;
use List::MoreUtils qw(any uniq);
use Scalar::Util qw(reftype looks_like_number);
use Exception::Class
    'Getopt::Modular::Exception' => {
        description => 'Exception in commandline parsing/handling',
        fields => [ qw(type option value warning valid expected) ],
    },
    'Getopt::Modular::Internal' => {
        description => 'Internal Exception in commandline parsing/handling',
        fields => [ qw(type option) ]
    };
use Carp;


sub import
{
    my $class = shift;
    while (@_)
    {
        my $opt = shift;
        if ($opt eq '-namespace')
        {
            my $ns = shift || die "No namespace given";

            # I could do this without eval, but I'm too lazy today.
            eval qq{
                package $ns;
                \@${ns}::ISA = List::MoreUtils::uniq('Getopt::Modular', \@${ns}::ISA);
                1; } or die $@;
        }
        elsif ($opt eq '-getOpt')
        {
            my $package = caller || 'main';

            # again, too lazy right now.
            eval qq{
                package $package;
                sub getOpt { Getopt::Modular->getOpt(\@_) }
                1; } or die $@;
        }
    }
}


my $global;
sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;

    # do we have a global one yet?
    $global ||= $self;

    if (any {'global' eq lc} @_)
    {
        $global = $self;
        @_ = grep { 'global' ne lc } @_;
    }

    $self->setBoolHelp(qw(off on));

    $self->init(@_);

    $self;
}

sub _self_or_global
{
    my $underscore = shift;
    my $self = $underscore->[0];

    # is it an object? use it.
    eval { ref $self && $self->isa(__PACKAGE__) } && return shift @$underscore;

    # passed in via class method?  skip it.
    eval { not ref $self && $self->isa(__PACKAGE__) } && shift @$underscore;

    # have global? use it.
    $global ? $global :
        # otherwise, create new.
        $self->new();
}

sub _accepts_opt
{
    my $self = _self_or_global(\@_);
    my $opt  = shift;
    return exists $self->{accept_opts}{$opt};
}

sub _opt
{
    my $self = _self_or_global(\@_);
    my $opt  = shift;
    
    if (@_)
    {
        $self->{accept_opts}{$opt} = shift;
        return;
    }

    unless (exists $self->{accept_opts}{$opt})
    {
        Getopt::Modular::Internal->throw(
                                         type    => 'unknown-option',
                                         message => "Unknown option: $opt",
                                         option  => $opt,
                                        );
    }
    return $self->{accept_opts}{$opt};
}


sub init
{
    my $self = shift;
    $self->setMode(@_) if @_;
    1;
}


my %_known_modes = map { $_ => 1 } qw(
    strict
);

sub setMode
{
    my $self = _self_or_global(\@_);

    foreach my $mode (@_)
    {
        if ($_known_modes{$mode})
        {
            $self->{mode}{$mode}++;
        }
        else
        {
            croak "Unknown mode: $@";
        }
    }
}


sub setBoolHelp
{
    my $self = _self_or_global(\@_);
    $self->{bool_strings} = [ @_[0,1] ];
}


sub acceptParam
{
    my $self = _self_or_global(\@_);
    while (@_)
    {
        my $param = shift;
        my $opts = shift;

        my $aliases = exists $opts->{aliases} ? ref $opts->{aliases} ? $opts->{aliases} : [ $opts->{aliases} ] : [];

        if ($param =~ /\|/)
        {
            ($param, my @aliases) = split /\|/, $param;
            unshift @$aliases, @aliases;
        }

        # if any of the aliases have pipes, split them up.  Needed to provide
        # the help screen.
        $opts->{aliases} = [
                            uniq
                            eval { 
                                my $o = $self->_accepts_opt($param) ? $self->_opt($param) : {};
                                @{$o->{aliases} || []};
                            },
                            map { split /\|/, $_ } @$aliases
                           ];

        # check if this flag already exists (other than as main name)
        for (@{$opts->{aliases}})
        {
            if (exists $self->{all_opts}{$_} and
                $self->{all_opts}{$_} ne $param)
            {
                croak "$_ already used by $self->{all_opts}{$_}";
            }
            # save this as the owner
            $self->{all_opts}{$_} = $param;
        }

        delete $self->{unacceptable}{$param};
        if ($self->_accepts_opt($param))
        {
            my $opt = $self->_opt($param);
            @{$self->_opt($param)}{keys %$opts} = values %$opts;
        }
        else
        {
            # set some defaults ...
            $opts->{spec} ||= '';

            $self->_opt($param, $opts);
        }
    }
}


sub unacceptParam
{
    my $self = _self_or_global(\@_);
    for my $param (@_)
    {
        $self->{unacceptable}{$param} = 1;
        my @x =
        delete @{$self->{all_opts}}{@{$self->{accept_opts}{$param}{aliases}}};
    }
}


sub parseArgs
{
    my $self = _self_or_global(\@_);

    # first, gather up for the call to Getopt::Long.
    my %opts;
    my $accept    = $self->{accept_opts};
    my $unaccept  = $self->{unacceptable};
    my @params = map {
        my $param = join '|', $_, @{$accept->{$_}{aliases}};
        $param . ($accept->{$_}{spec} || '');
    } grep {
        # skip unaccepted parameters
        $unaccept and not $unaccept->{$_}
    } keys %$accept;

    # parse them
    my $warnings;
    my $success = do {
        local $SIG{__WARN__} = sub { $warnings .= "@_";};
        Getopt::Long::Configure("bundling");
        GetOptions(\%opts, @params);
    };
    if (not $success)
    {
        Getopt::Modular::Exception->throw(
                                          message => "Bad command-line: $warnings",
                                          type => 'getopt-long-failure',
                                          warning => $warnings,
                                         );
    }

    # now validate everything that was passed in, and save it.
    for my $opt (keys %$accept)
    {
        if (exists $opts{$opt})
        {
            $self->setOpt($opt, $opts{$opt});
        }
        # if it's mandatory, get it - that will call the default and
        # set it.
        elsif ($accept->{$opt}{mandatory})
        {
            # setting via default.
            $self->getOpt($opt);
        }
    }

    # if passed in a hash ref to populate, fill it.
    if (@_ && ref $_[0] eq 'HASH')
    {
        my $opts = shift;
        for my $opt (keys %{$self->{accept_opts}})
        {
            $opts->{$opt} = $self->getOpt($opt);
        }
    }
}


sub getOpt
{
    my $self = _self_or_global(\@_);
    my $opt  = shift || Getopt::Modular::Exception->throw(
                                                          message => 'No option given?',
                                                          type => 'dev-error',
                                                         );

    if (not exists $self->{accept_opts}{$opt})
    {
        if ($self->{mode}{strict})
        {
            Getopt::Modular::Exception->throw(
                                              message => "No such option: $opt",
                                              type    => 'no-such-option',
                                              option  => $opt,
                                              value   => undef,
                                             );
        }
    }

    # If we don't have it yet, check if there's a default.
    if (not exists $self->{options}{$opt} and
        exists $self->{accept_opts}{$opt} and
        exists $self->{accept_opts}{$opt}{default})
    {
        my @default = $self->{accept_opts}{$opt}{default};
        if (ref $default[0] and ref $default[0] eq 'CODE')
        {
            @default = $default[0]->();
        }
        $self->setOpt($opt, @default);
    }

    # should have one now ... check and return
    if (exists $self->{options}{$opt})
    {
        if (wantarray)
        {
            return 
                ref $self->{options}{$opt} eq 'ARRAY' ? @{$self->{options}{$opt}} : 
                ref $self->{options}{$opt} eq 'HASH'  ? %{$self->{options}{$opt}} : 
            $self->{options}{$opt};
        }
        return $self->{options}{$opt}
    }

    return;
}

sub _getType
{
    my $self = _self_or_global(\@_);
    my $opt  = shift;

    unless (exists $self->_opt($opt)->{_GMTYPE})
    {
        my $type = $self->_opt($opt)->{spec};
        $self->_opt($opt)->{_GMTYPE} = ''; #scalar
        if ($type =~ /\@/)
        {
            $self->_opt($opt)->{_GMTYPE} = 'ARRAY';
        }
        elsif ($type =~ /\%/)
        {
            $self->_opt($opt)->{_GMTYPE} = 'HASH';
        }
    }
    $self->_opt($opt)->{_GMTYPE}
}

sub _bool_val
{
    # technically, perl allows anything to be boolean.
    #my ($opt,$val) = @_;
}

sub _int_val
{
    my ($opt,$val) = @_;
    if ($val !~ /^[-+]?\d+$/)
    {
        Getopt::Modular::Exception->throw(
                                          message => "Trying to set '$opt' (an integer-only parameter) to '$val'",
                                          type    => 'set-int-failure',
                                          option  => $opt,
                                          value   => $val
                                         );
    }
}

sub _real_val
{
    my ($opt,$val) = @_;

    unless (looks_like_number $val)
    {
        Getopt::Modular::Exception->throw(
                                          message => "Trying to set '$opt' (a real-number parameter) to '$val'",
                                          type    => 'set-real-failure',
                                          option  => $opt,
                                          value   => $val
                                         );
    }
}

my %_valtypes = (
                 '!' => { val => \&_bool_val },
                 '+' => { val => \&_int_val },
                 's' => { val => sub {} },
                 'i' => { val => \&_int_val },
                 'o' => { val => \&_int_val },
                 'f' => { val => \&_real_val },
                );

sub _setOpt
{
    my $self = _self_or_global(\@_);
    my $opt  = shift;
    my $val  = shift;

    # check known types before passing on to user-specified validation.

    my $type = $self->_opt($opt)->{spec};
    if ($type eq '' || $type eq '!') # boolean
    {
        _bool_val($opt,$val);
        # extra information should not be stored in a boolean.
        $val = !!$val;
    }
    else
    {
        for (split //, $type)
        {
            if (my $info = $_valtypes{$_})
            {
                if ($type =~ /\@/)
                {
                    $info->{val}->($opt,$_) for @$val;
                }
                elsif ($type =~ /\%/)
                {
                    $info->{val}->($opt,$_) for values %$val;
                }
                else
                {
                    $info->{val}->($opt,$val);
                }
            }
        }
    }

    if ($self->_opt($opt)->{validate})
    {
        local $_ = $val;
        unless ($self->_opt($opt)->{validate}->())
        {
            if (ref $val)
            {
                $val = join ',', @$val if ref $val eq 'ARRAY';
                $val = join ',', map { "$_=$val->{$_}" } sort keys %$val if ref $val eq 'HASH';
            }
            Getopt::Modular::Exception->throw(
                                              message => "'$val' is an invalid value for $opt",
                                              type    => 'validate-failure',
                                              option  => $opt,
                                              value   => $val,
                                             );
        }
    }

    if (my $valid = $self->_opt($opt)->{valid_values})
    {
        if (ref $valid eq 'CODE')
        {
            my @valid = $valid->();
            $valid = \@valid;
            $self->_opt($opt)->{valid_values} = $valid; # cache for next time.
        }

        if (ref $valid eq 'ARRAY')
        {
            unless (any { $_ eq $val } @$valid)
            {
                Getopt::Modular::Exception->throw(
                                                  message => "'$val' is an invalid value for $opt",
                                                  type    => 'validate-failure',
                                                  option  => $opt,
                                                  value   => $val,
                                                  valid   => $valid,
                                                 );
            }
        }
        else
        {
            Getopt::Modular::Exception->throw(
                                              message => "'valid_values requires either an array ref or a code ref to generate the list of valid values.",
                                              type => 'valid-values-error',
                                              option => $opt,
                                             );
        }
    }

    $self->{options}{$opt} = $val;
}


sub setOpt
{
    my $self = _self_or_global(\@_);
    my $opt  = shift;
    my $val  = do {
        if (ref $_[0])
        {
            Getopt::Modular::Exception->throw(
                                              type    => 'wrong-type',
                                              message => "Wrong type of data for $opt.  Expected: " .
                                              ($self->_getType($opt) || 'SCALAR') .
                                              " got: " . (reftype $_[0] || 'SCALAR'),
                                              expected => ($self->_getType($opt) || 'SCALAR'),
                                              option => $opt,
                                              value => $_[0],
                                             )
                unless $self->_getType($opt) eq reftype $_[0];

            # if it's a reference, pass it in unchanged.
            shift;
        }
        else
        {
            # scalars get passed in, but hashes and arrays need to
            # be referencised.

            ! $self->_getType($opt) ? shift  :
                $self->_getType($opt) eq 'HASH'  ? { @_ } : [ @_ ];
        }
    };

    $self->_setOpt($opt, $val);
}


sub getHelpRaw
{
    my $self = _self_or_global(\@_);

    # get the list of parameters ...
    my $accept    = $self->{accept_opts};
    my $unaccept  = $self->{unacceptable};
    my @params = sort grep {
        # skip unaccepted parameters
        $unaccept and not $unaccept->{$_}
    } keys %$accept;

    # start figuring it out.
    my @raw;
    for my $param (@params)
    {
        my %opt;

        my $param_info = $accept->{$param};
        my @keys = ($param, @{$param_info->{aliases}||[]});

        # booleans get the "no" version.
        if ($param_info->{spec} =~ /!/)
        {
            @keys = map { length > 1 ? ($_, "no$_") : $_ } @keys;
        }

        # anything with more than one letter gets a double-dash.
        @keys = map { length > 1 ? "--$_" : "-$_" } @keys;
        $opt{param} = \@keys;

        $opt{help} = ref $param_info->{help} ?
            $param_info->{help}->() : $param_info->{help};

        # determine default (or set value)
        my $default;
        eval {
            $opt{default} = $self->getOpt($param);

            my $type = $self->_opt($param)->{spec};
            if ($type eq '' || $type eq '!') # boolean
            {
                my $bools = ( $self->_opt($param)->{help_bool} or $self->{bool_strings} );

                $opt{default} = $bools->[$opt{default} ? 1 : 0];
            }
        };

        # determine valid values.
        eval {
            $opt{valid_values} = $self->_opt($param)->{valid_values};

            no warnings;
            # if it's not a code ref, the eval will exit, but we'll already
            # have what we want anyway.
            $opt{valid_values} = [ $opt{valid_values}->() ];
        };

        # is it hidden?  It's still part of the raw output.
        $opt{hidden} = $param_info->{hidden} if exists $param_info->{hidden};

        push @raw, \%opt;
    }
    return @raw;
}


sub getHelp
{
    my $self = _self_or_global(\@_);
    my @raw = grep { not $_->{hidden} } $self->getHelpRaw;
    my $cbs = shift || {};

    require Text::Table;

    my $tb = Text::Table->new();
    for my $param (@raw)
    {
        my $opt = join ",\n  ", @{$param->{param}};
        my $txt = $param->{help};
        no warnings 'uninitialized';

        $txt .= "\n " . ($cbs->{current_value} || sub { "Current value: [". shift(). "]" })->($param->{default}) if exists $param->{default};

        if ($param->{valid_values})
        {
            # if it's a code ref, de-ref it.  If not, ignore the exception.
            eval { $param->{valid_values} = [ $param->{valid_values}->() ] };
            $txt .= "\n " . ($cbs->{valid_values} || sub { "Valid values: [". join(',', @_). "]" })->(@{$param->{valid_values}});
        }

        $tb->add($opt, $txt);
    }
    $tb;
}


sub getHelpWrap
{
    my $self = _self_or_global(\@_);
    my $width = (@_ && not ref $_[0]) ? shift : 80;
    my $cbs = shift || {};
    my @raw = grep { not $_->{hidden} } $self->getHelpRaw;

    require Text::Table;

    my $wrap = eval {
        require Text::WrapI18N;
        sub {
            local $Text::WrapI18N::columns = shift;
            local $Text::WrapI18N::unexpand;

            Text::WrapI18N::wrap('', '', @_);
        };
    } || do {
        require Text::Wrap;
        sub {
            local $Text::Wrap::columns = shift;
            local $Text::Wrap::unexpand;

            Text::Wrap::wrap('', '', @_);
        }
    };

    my $tb = Text::Table->new();
    my $load_data = sub {
        my $tb    = shift;
        my $param = shift;

        my $opt = join ",\n  ", @{$param->{param}};
        my $txt = shift;

        my $available = shift;

        no warnings 'uninitialized';

        $txt .= "\n " . ($cbs->{current_value} || sub { "Current value: [". shift(). "]" })->($param->{default}) if exists $param->{default};
        $txt .= "\n " . ($cbs->{valid_values} || sub { "Valid values: [". join(',', @_). "]" })->(@{$param->{valid_values}}) if $param->{valid_values};

        # wrap all lines
        $txt = $wrap->($available, $txt) if $available;

        $tb->add($opt, $txt);
    };

    for my $param (@raw)
    {
        $load_data->($tb, $param, $param->{help});
    }

    if ($tb->width > $width)
    {
        # rebuild, wrapped.
        my @colrange = $tb->colrange(0);
        my $available = $width - $colrange[1] - 1; # 1 for extra space between columns

        $tb->clear();
        for my $param (@raw)
        {
            $load_data->($tb, $param, $param->{help}, $available);
        }
    }

    # if the current value or valid values are a block of text too long, we don't want all
    # lines to be too long, so clobber the extra spaces that Text::Table puts in at the end.
    (my $txt = "".$tb) =~ s/\s+$//msg;
    $txt .= "\n";
    $txt;
}


1; # End of Getopt::Modular

__END__

=pod

=encoding UTF-8

=head1 NAME

Getopt::Modular - Modular access to Getopt::Long

=head1 VERSION

version 0.13

=head1 SYNOPSIS

Perhaps a little code snippet.

    use Getopt::Modular;

    Getopt::Modular->acceptParam(
                                  foo => {
                                      default => 3,
                                      spec    => '=s',
                                      validate => sub {
                                          3 <= $_ &&
                                          $_ <= determine_max_foo();
                                      }
                                  }
                                 );
    Getopt::Modular->parseArgs();
    my $foo = Getopt::Modular->getOpt('foo');

=head1 PURPOSE

There are a few goals in this module.  The first is to find a way to
allow a bunch of custom modules to specify what options they want to take.
This allows you to reuse modules in multiple environments (applications)
without having to repeat a bunch of code for handling silly things like
the parameters themselves, their defaults, validation, etc.  You also don't
need to always be aware of what parameters a module may take if it merely
grabs them from the global environment.

I find I'm reusing modules that should be user-configurable (via the 
commandline) in multiple applications a lot.  By separating this out, I
can just say "use Module;" and suddenly my new application takes all the
parameters that Module requires (though I can modify this on a case-by-
case basis in my application).  This allows me to keep the information
about a variable in close proximity to its use (i.e., the same file).

There is a lot of information here that otherwise would need to be handled
with special code.  This can greatly simplify things:

=over 4

=item * consistency

Because the same parameters are used in multiple applications with the
same meaning, spelling, valid values, etc., it makes all your applications
consistent and thus easy to learn together.

=item * help

The online help is a big challenge in any application.  This module will
handle the help for your parameters by using what is provided to it from
each module.  Again, the help for a parameter will be the same in all your
applications, maintaining consistency.

Further, the help will be right beside the parameter.  No more looking
through hundreds or thousands of lines of pod and code trying to match
up parameters and help, wondering if you missed something.  Now you only
have to address about 5-10 lines of code at a time wondering if you missed
something.

=item * defaults

Defaults right beside the parameter.  Again, you only need to address 5-10
lines of code to look for parameter and its default.  They aren't
separated any longer.  Now, it's true that you don't necessarily need
to have defaults far removed with L<Getopt::Long>, but that really does
depend on what you're doing.

Further, the defaults can be I<dynamic>.  That means you can put in a code
reference to determine the default.  Your default may depend on other
parameters, or it may depend on external environment (Is the destination
directory writable?  What is the current hostname?  What time is it?).
You can grab your default from a webserver from another continent (not
recommended).  It doesn't matter.  But you can have that code right there
with the parameter, making it easy to compartmentalise.

You do not need to have dynamic defaults.  Some would argue that dynamic
defaults make applications more difficult for the user to know what will
happen.  Not only do I think that good dynamic defaults can help the
application Do The Right Thing, but that the developer of the application
should be able to choose, thus defaults I<can> be dynamic, even if that
is not necessarily useful to your application.

In one application, my goal was to minimise any requirement to pass in
parameters, thus having defaults that made sense, but to Do The Right Thing,
which was usually different between different environments.  As one
example, a flag to specify mod_perl vs FastCGI vs CGI could be:

    'cgi-style' => {
        default => sub {
            if (detect_mod_perl()) {
                return 'mod_perl';
            } elsif (detect_fastcgi()) {
                return 'fastcgi';
            } else {
                return 'cgi';
        }
    }

This would Do The Right Thing, but you can override it during testing
with a simple command line parameter.

=item * validation

Like everything above, the validation of a parameter is right beside the
parameter, making it easy to address the entirety of a parameter all in
a single screen (usually much less) of code.

Validation is also automatically run against both the default (same idea
as having tests for your perl modules: sanity test that your default is
valid) when no parameter is given, and any programmatic changes to a
value.  Without this, I was always forgetting to validate my option changes.
This automates that.

=back

All this, the power of L<Getopt::Long>, and huge thanks from whomever
inherits your code for keeping everything about --foo in a single place.

The downside is that you need to ensure all modules that may require
commandline parameters are loaded before you actually parse the commandline.
For me, this has meant that my test harness needs to either ask for
the module to test via environment variable or needs to pre-parse the
commandline (kind of defeating the purpose of the module).  I've opted for
checking for the module via C<$ENV{MODULE}>, loading it, and then parsing
the commandline.

Also, another downside is that parameters are not positional.  That is,
C<--foo 3 --bar 5> is the same as C<--bar 5 --foo 3>.  The vast majority
of software seems to agree that these are the same.

=head1 IMPORTS

As the module is intended to be used as a singleton (most of the time), and
all methods are class (not object) methods, there really isn't much to import.
However, typing out "Getopt::Modular->getOpt" all the time can be cumbersome.
So a few pieces of syntactical sugar are provided.  Note that as sugar can
be bad for you, these are made optional.

=over 4

=item * -namespace

By specifying C<-namespace =E<gt> "GM">, you can abbreviate all class calls
from C<Getopt::Modular> to simply C<GM>.  Another alternative is to simply
create your own subclass of Getopt::Modular with a simple, short name, and
use that.

This only has to be done once per application.

=item * -getOpt

This will import getOpt as a simple function (not a class method) into your
namespace.  This can be done for any namespace that needs the getOpt function
imported.

=back

Arguably, more could be added.  However, as most of the calls into this
module will be getting (not setting, etc.), this is seen as the biggest
sugar for least setup.

=head1 FUNCTIONS

=head2 new

Construct a new options object.  If you just need a single, global options
object, you don't need to call this.  By default, all methods can be called
as package functions, automatically instantiating a default global object.

Takes as parameters all modes accepted by setMode, as well as a 'global'
mode to specify that this newly-created options object should become the
global object, even if a global object already exists.

Note that if no global object exists, the first call to new will create it.

=head2 init

Overridable method for initialisation.  Called during object creation to allow
default parameters to be set up prior to any other module adding parameters.

Default action is to call $self->setMode(@_), though normally you'd set
any mode(s) in your own init anyway.

=head2 setMode

Sets option modes.

Currently, the only supported mode is:

=over 4

=item strict

Don't allow anyone to request an option that doesn't exist.  This will catch
typos.  However, if you have options that may not exist in this particular
program that may get called by one of your other modules, this may cause
problems in that your code may die unexpectedly.

Since this is a key feature to this option approach, the default is not
strict.  If you always knew all your options up front, you could just
define them and be done with it.  But then you would likely be able to just
go with L<Getopt::Long> anyway.

=back

=head2 setBoolHelp

Sets the names used by getHelp and getHelpRaw for boolean values.  When your
user checks the help for your application, we display the default or current
values - but "0" and "1" don't make any sense for booleans for users.  So
we, by default, use "on" and "off".  You can change this default.  You can
further override it on a parameter-by-parameter basis.

Pass in two strings: the off or false value, and the on or true value.
(Mnemonic: index 0 is false, index 1 is true.)

=head2 acceptParam

Set up to accept parameters.  All parameters will be passed to L<Getopt::Long>
for actual parsing.

e.g.,

    Getopt::Modular->acceptParam('fullname' => {
        aliases => [ 'f', 'fn' ],
        spec => '=s@', # see Getopt::Long for argument specification
        help => 'use fullname to do blah...',
        default => 'baz',
        validate => sub {
            # verify that the value passed in is ok
        },
    });

You can pass in more than one parameter at a time.

Note that B<order matters>.  That is, the order that parameters are told to
Getopt::Modular is the same order that parameters will be validated when
accepted from the commandline, B<regardless of the order the user passes them
in>.  If this is no good to you, then you may need to find another method
of handling arguments.  If one parameter depends on another, e.g., for
the default or validation, be sure to C<use> the module that declares that
parameter prior to calling C<acceptParam> to ensure that the other parameter
will be registered first and thus parsed/handled first.

The parameter name is given separately.  Note that whatever this is will be
the name used when you retrieve the option.  I suggest you use the longest
name here to keep the rest of your code readable, but you can use the shortest
name or whatever you want.

Acceptable options are:

=over 4

=item aliases

In Getopt::Long, these would be done like this:

    'fullname|f|fn'

Here, we separate them out to make them easier to read.  They are combined
back into a single string for Getopt::Long.  Optionally, you can simply provide
C<'fullname|f|fn'> as the parameter name, and it will be split apart.  In this
case, the name used to retrieve the value will be the first string given.

=item spec

This is the part that tells Getopt::Long what types to accept.  This can be a
quick check against what can be accepted (numeric, string, boolean) or may be
more informative (such as taking a list).  While this is mostly used to pass
in to Getopt::Long, it is also used for context in the help option, or in
returning options back to whoever needs them, such as knowing whether the given
values can be a list, or if it's simply a boolean.

=item help

This is either a string, or a code ref that returns a string to display to the
user for help.  The reason why a code ref is allowed is in case the help string
is dynamic based on the parameters that are given.  For example, you may want
to provide different help for the current flag based on the valid of some other
flag.

If this is a code ref, it is not passed any parameters, and $_ is not set reliably.

=item help_bool

This is an array reference with the two values of boolean you want to use.
It overrides the global strings.  e.g., [ qw(false true) ].  The unset value
is first (mnemonic: index 0 is false, 1 is true).

These strings are only used if this option is a boolean, and only in the
help output.

=item default

This is either a scalar, an array ref (if C<spec> includes C<@>), a hash ref
(if C<spec> includes C<%>), or a code ref that returns the appropriate type.
A code ref can provide the opportunity to change the default for a given
parameter based on the values of other parameters.  Note that you can only rely
on the values of parameters that have already been validated, i.e., parameters
that were given to acceptParam earlier than this one.  That's because ones
given later would not have had their values set from the command line yet.

This is checked/called only once, maximum, per process, as once the default is
retrieved, it is stored as if it were set by the user via the command line.  It
may be called either as part of the help display, or it may be called the first
time the code requests the value of this parameter.  If the current code path
does not check this value, the default will not be checked or called even if
the parameter is not passed in on the command line.

If this is a code ref, it is not passed any parameters, and $_ is not set
reliably.

=item validate

This is a code ref that validates the parameter being passed in against not only
valid values, but the current state of the parameters.  This includes validation
of the default value.

You can use this callback to ensure that the current values are allowed given
all the parameters validates so far.  That is, you can call getOpt on any previous
parameter to check their values make sense given the current value.  If it doesn't,
simply die with the error message.  Do not call exit, because this is called in
an eval block for displaying help, and it's perfectly reasonable that a user
requests help when some values are invalid.

The value(s) being validated are passed in via $_, which may be a reference
if the type is an array or hash.

You may throw an exception in case of error, or you can simply return false
and a generic exception will be thrown on your behalf.  Obviously throwing
your own exception with a useful error message for the user is the better
choice.

If this key is not present, then anything Getopt::Long accepts (due to the specification)
will be accepted as valid.

=item valid_values

If the list of valid values is limited and finite, it may be easier to
just specify them.  Then Getopt::Modular can verify the value provided is
in the list.  It can also use the list in the help.

This parameter needs to be either an array ref, or a CODE ref that generates
the list (lazy).  Note that the CODE ref will only be called once, so don't
count on it being dynamic, too.

=item mandatory

If this is set to a true value, then during parameter validation, this option
will always be set, either via the command line, or via checking/calling default
(which will then be validated).  The purpose of this is to ensure the validate
code is called during the parsing of arguments even if the parameter was not
passed in on the command line.  If you have no default and your validate
rejects an empty value, this can, in effect, make the parameter mandatory for
the user.

=item hidden

If this is set to a true value, then C<getHelp> and C<getHelpWrap>,
but not C<getHelpRaw>, will not return this item in its output.  Useful
for debugging or other "internal" parameters.

=back

=head2 unacceptParam

Sometimes you may load a module that has a parameter, but in this
particular case, you don't want the user to be able to specify it.  Either
you want the default to always be used, or you want to set it to something
explicitly.  You can set the parameter to be "un"accepted, thereby eliminating
it from the list of options the user can pass in.

However, this will not remove it from the list that Getopt::Modular
will recognise inside the code.  That is, Getopt::Modular->getOpt() will
still accept that parameter, and setOpt will still allow you to set it
programmatically.

To re-accept an unaccepted parameter, simply call acceptParam, passing
in the parameter name and an empty hash of options, and all the old values
will be used.

=head2 parseArgs

Once all parameters have been accepted (and, possibly, unaccepted), you must
call parseArgs to perform the actual parsing.

Optionally, if you pass in a hash ref, it will be populated with every
parameter.  This is intended to provide a stop-gap for migration from
L<Getopt::Long>::GetOptions wherein you can provide your options hash
and use that directly.

    GM->parseArgs(\my %opts);

The downside to this is that it will determine all values during parsing
rather than deferring until the value is actually required.  Most of the
time, this will be okay, but if some defaults take a long time to resolve
or validate, e.g., network activities such as looking up users via LDAP,
requesting a value from a wiki page, or even just reading a file over NFS,
sshfs, Samba, or similar, that time will be wasted if the value isn't actually
required during this execution based on other parameters.

=head2 getOpt

Retrieve the desired option.  This will "set" any option that has not
been retrieved before, and was not on the command line, by calling the default.

If you need to know the difference between an implicit default and an
explicit default, you need to do that in your default code.  That said,
you should think twice about that: is it intuitive to the user that
there should be a difference between "--foo 3" and not specifying --foo
at all when the default is 3?

=head2 setOpt

Programmatic changing of options.  This should not be done until after
the options have been parsed: defaults are set through the default flag,
not by setting the option first.

Note that this will pass the value through the validation code, if any, so
be sure you set the values to something that make sense.  Will throw an
exception if the value cannot be set, e.g., it is invalid.

=head2 getHelpRaw

This function will go through all the parameters and construct a list
of hashes for constructing your own help.  It's also the internal function
used by getHelp to create its help screen.

Each hash has the following keys:

=over 4

=item param

Array ref of parameter names.  This is what the user passes in, e.g., "-f" or
"--foo".

=item help

The string associated with the parameter (if this was a code ref, the code
is called, and this is the return from there).

=item default

If there is a default (that doesn't die when validated), or if the value
was already on the command line, that value.  If the default does die, then
this key will be absent (i.e., no default, or mandatory, or however you
want to interpret this).

=back

=head2 getHelp

Returns a string representation of the above raw help.  If you need to
translate extra strings, an extra hash-ref of callbacks will be used.  For
example:

    GM->getHelp({
        current_value => sub {
            lookup_string("Current value: '[_1]'", shift // '');
        },
        # only needed if you use the valid_value key at the moment, but
        # could be extended later.
        valid_values => sub {
            lookup_string("Valid values: '[_1]'", join ',', @_);
        },
    });

Callbacks:

=over 4

=item current_value

Receives the current value (may be undef).

=item valid_values

Receives all valid values.

=back

=head2 getHelpWrap

Similar to getHelp, this uses L<Text::WrapI18N>, if available, otherwise
L<Text::Wrap>, to automatically wrap the text on for help, making it easier
to write.

Default screen width is 80 - you can pass in the columns if you prefer.

A second parameter is the same as getHelp above with callbacks for translations.

Examples:

    print GM->getHelpWrap(70, { ... }); # specify cols and callbacks
    print GM->getHelpWrap({ ... }); # implicit cols (80), explicit callbacks
    print GM->getHelpWrap(70); # implicit cols, default English text
    print GM->getHelpWrap(); # implicit all.

=head1 EXCEPTIONS

Various exceptions can be thrown of either C<Getopt::Modular::Exception> or
C<Getopt::Modular::Internal> types.  All exceptions have a "type" field which
you can retrieve with the C<-E<gt>type> method (see L<Exception::Class>).  This
is intended to facilitate translations.  Rather than using the exception message
contained in this object, you can substitute with your own translated text.

Exception types:

=over 4

=item unknown-option

Internal error: an option was used, for example as one of the aliases, that didn't
resolve.  I don't think this should happen.

=item getopt-long-failure

Getopt::Long returned a failure.  The warnings produced by Getopt::Long have been
captured into the warnings of this exception (C<$e-E<gt>warnings>), but they are
likely also English-only.

=item dev-error

getOpt didn't get any parameters.  Probably doesn't need translating unless
you are doing something odd (but has a type so you I<can> do something odd).

=item valid-values-error

The valid_values key for an option wasn't either an array ref or a code ref.

=item no-such-option

Strict mode is on, and you asked getOpt for an option that G::M doesn't
know about.

=item set-int-failure

Called setOpt on an integer value (types +, i, or o), without giving an integer.

=item set-real-failure

Called setOpt on an real value (type f), without giving a number.

=item validate-failure

The validation for this value failed.  The option and value fields are filled in.

=item wrong-type

When calling setOpt, trying to set a value of the wrong type (a hash reference to
a list, for example)

=back

=head1 AUTHOR

Darin McBride, C<< <dmcbride at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-getopt-modular at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Getopt-Modular>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Getopt::Modular

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Getopt-Modular>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Getopt-Modular>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Getopt-Modular>

=item * Search CPAN

L<http://search.cpan.org/dist/Getopt-Modular>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008, 2012 Darin McBride, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Darin McBride <dmcbride@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Darin McBride.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
