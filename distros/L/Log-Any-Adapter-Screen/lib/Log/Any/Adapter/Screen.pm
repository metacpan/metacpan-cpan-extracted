package Log::Any::Adapter::Screen;

our $DATE = '2018-12-22'; # DATE
our $VERSION = '0.140'; # VERSION

use 5.010001;
use strict;
use warnings;

use Log::Any;
use Log::Any::Adapter::Util qw(make_method);
use parent qw(Log::Any::Adapter::Base);

my $CODE_RESET = "\e[0m"; # PRECOMPUTED FROM: do { require Term::ANSIColor; Term::ANSIColor::color('reset') }
my $DEFAULT_COLORS = {alert=>"\e[31m",critical=>"\e[31m",debug=>"",emergency=>"\e[31m",error=>"\e[35m",info=>"\e[32m",notice=>"\e[32m",trace=>"\e[33m",warning=>"\e[1;34m"}; # PRECOMPUTED FROM: do { require Term::ANSIColor; my $tmp = {trace=>'yellow', debug=>'', info=>'green',notice=>'green',warning=>'bold blue',error=>'magenta',critical=>'red',alert=>'red',emergency=>'red'}; for (keys %$tmp) { if ($tmp->{$_}) { $tmp->{$_} = Term::ANSIColor::color($tmp->{$_}) } }; $tmp }

my $Time0;

my @logging_methods = Log::Any->logging_methods;
our %logging_levels;
for my $i (0..@logging_methods-1) {
    $logging_levels{$logging_methods[$i]} = $i;
}
# some common typos
$logging_levels{warn} = $logging_levels{warning};

sub _min_level {
    my $self = shift;

    return $ENV{LOG_LEVEL}
        if $ENV{LOG_LEVEL} && defined $logging_levels{$ENV{LOG_LEVEL}};
    return 'trace' if $ENV{TRACE};
    return 'debug' if $ENV{DEBUG};
    return 'info'  if $ENV{VERBOSE};
    return 'error' if $ENV{QUIET};
    $self->{default_level};
}

sub init {
    my ($self) = @_;
    $self->{default_level} //= 'warning';
    $self->{stderr}    //= 1;
    $self->{use_color} //= do {
        if (exists $ENV{NO_COLOR}) {
            0;
        } elsif (defined $ENV{COLOR}) {
            $ENV{COLOR};
        } else {
            (-t STDOUT);
        }
    };
    if ($self->{colors}) {
        require Term::ANSIColor;
        # convert color names to escape sequence
        my $orig = $self->{colors};
        $self->{colors} = {
            map {($_,($orig->{$_} ? Term::ANSIColor::color($orig->{$_}) : ''))}
                keys %$orig
            };
    } else {
        $self->{colors} = $DEFAULT_COLORS;
    }
    $self->{min_level} //= $self->_min_level;
    if (!$self->{formatter}) {
        if (($ENV{LOG_PREFIX} // '') eq 'elapsed') {
            require Time::HiRes;
            $Time0 //= Time::HiRes::time();
        }
        $self->{formatter} = sub {
            my ($self, $msg) = @_;
            my $env = $ENV{LOG_PREFIX} // '';
            if ($env eq 'elapsed') {
                my $time = Time::HiRes::time();
                $msg = sprintf("[%9.3fms] %s", ($time - $Time0)*1000, $msg);
            }
            $msg;
        };
    }
    $self->{_fh} = $self->{stderr} ? \*STDERR : \*STDOUT;
}

sub hook_before_log {
    return;
    #my ($self, $msg) = @_;
}

sub hook_after_log {
    my ($self, $msg) = @_;
    print { $self->{_fh} } "\n" unless $msg =~ /\n\z/;
}

for my $method (Log::Any->logging_methods()) {
    make_method(
        $method,
        sub {
            my ($self, $msg) = @_;

            return if $logging_levels{$method} <
                $logging_levels{$self->{min_level}};

            $self->hook_before_log($msg);

            if ($self->{formatter}) {
                $msg = $self->{formatter}->($self, $msg);
            }

            if ($self->{use_color} && $self->{colors}{$method}) {
                $msg = $self->{colors}{$method} . $msg . $CODE_RESET;
            }

            print { $self->{_fh} } $msg;

            $self->hook_after_log($msg);
        }
    );
}

for my $method (Log::Any->detection_methods()) {
    my $level = $method; $level =~ s/^is_//;
    make_method(
        $method,
        sub {
            my $self = shift;
            $logging_levels{$level} >= $logging_levels{$self->{min_level}};
        }
    );
}

1;
# ABSTRACT: Send logs to screen, with colors and some other features

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Adapter::Screen - Send logs to screen, with colors and some other features

=head1 VERSION

This document describes version 0.140 of Log::Any::Adapter::Screen (from Perl distribution Log-Any-Adapter-Screen), released on 2018-12-22.

=head1 SYNOPSIS

 use Log::Any::Adapter;
 Log::Any::Adapter->set('Screen',
     # min_level => 'debug', # default is 'warning'
     # colors    => { trace => 'bold yellow on_gray', ... }, # customize colors
     # use_color => 1, # force color even when not interactive
     # stderr    => 0, # print to STDOUT instead of the default STDERR
     # formatter => sub { "LOG: $_[1]" }, # default none
 );

=head1 DESCRIPTION

This Log::Any adapter prints log messages to screen (STDERR/STDOUT). The
messages are colored according to level (unless coloring is turned off). It has
a few other features: allow passing formatter, allow setting level from some
environment variables, add prefix/timestamps.

Parameters:

=over 4

=item * min_level => STRING

Set logging level. Default is warning. If LOG_LEVEL environment variable is set,
it will be used instead. If TRACE environment variable is set to true, level
will be set to 'trace'. If DEBUG environment variable is set to true, level will
be set to 'debug'. If VERBOSE environment variable is set to true, level will be
set to 'info'.If QUIET environment variable is set to true, level will be set to
'error'.

=item * use_color => BOOL

Whether to use color or not. Default is true only when running interactively (-t
STDOUT returns true).

=item * colors => HASH

Customize colors. Hash keys are the logging methods, hash values are colors
supported by L<Term::ANSIColor>.

The default colors are:

 method/level                 color
 ------------                 -----
 trace                        yellow
 debug                        (none, terminal default)
 info, notice                 green
 warning                      bold blue
 error                        magenta
 critical, alert, emergency   red

=item * stderr => BOOL

Whether to print to STDERR, default is true. If set to 0, will print to STDOUT
instead.

=item * formatter => CODEREF

Allow formatting message. If defined, message will be passed before being
colorized. Coderef will be passed:

 ($self, $message)

and is expected to return the formatted message.

The default formatter can optionally prefix the message with extra stuffs,
depending on the content of LOG_PREFIX environment variable, such as: elapsed
time (e.g. C<< [0.023ms] >>) if LOG_PREFIX is C<elapsed>.

NOTE: Log::Any 1.00+ now has a proxy object which allows
formatting/customization of message before it is sent to adapter(s), so
formatting does not have to be done on a per-adapter basis. As an alternative to
this attribute, you can also consider using the proxy object or the (upcoming?)
global proxy object.

=item * default_level => STR (default: warning)

If no level-setting environment variables are defined, will default to this
level.

=back

=for Pod::Coverage ^(init|hook_.+)$

=head1 ENVIRONMENT

=head2 NO_COLOR

If defined, will disable color. Consulted before L</COLOR>.

=head2 COLOR

Can be set to 0 to explicitly disable colors. The default is to check for C<<-t
STDOUT>>.

=head2 LOG_LEVEL => str

=head2 QUIET => bool

=head2 VERBOSE => bool

=head2 DEBUG => bool

=head2 TRACE => bool

These environment variables can set the default for C<min_level>. See
documentation about C<min_level> for more details.

=head2 LOG_PREFIX => str

The default formatter groks these variables. See documentation about
C<formatter> about more details.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Log-Any-Adapter-Screen>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Log-Any-Adapter-ScreenColoredLevel>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Log-Any-Adapter-Screen>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Originally inspired by L<Log::Log4perl::Appender::ScreenColoredLevel>. The old
name for this adapter is Log::Any::Adapter::ScreenColoredLevel but at some point
I figure using a shorter name is better for my fingers.

L<Log::Any>

L<Log::Log4perl::Appender::ScreenColoredLevel>

L<Term::ANSIColor>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2016, 2015, 2014, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
