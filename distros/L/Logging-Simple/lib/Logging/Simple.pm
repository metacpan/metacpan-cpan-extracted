package Logging::Simple;
use 5.007;
use strict;
use warnings;

use Carp qw(croak confess);
use POSIX qw(strftime);
use Time::HiRes qw(time);

our $VERSION = '1.04';

BEGIN {

    sub _sub_names { return [qw(_0 _1 _2 _3 _4 _5 _6 _7)]; };
    my $sub_names = _sub_names();

    # build the level subs dynamically. The code in this BEGIN block represents
    # all logging subs

    {
        no strict 'refs';

        for (@$sub_names) {
            my $sub = $_;

            *$_ = sub {
                my ($self, $msg) = @_;

                return if $self->level == -1;

                $self->level($ENV{LS_LEVEL}) if defined $ENV{LS_LEVEL};

                if ($sub =~ /^_(\d)$/) {
                    if (defined $self->_log_only) {
                        return if $1 != $self->_log_only;
                    }
                    return if $1 > $self->level;
                }

                my $proc = join '|', (caller(0))[1..2];

                my %log_entry = (
                    label => $sub,
                    proc => $proc,
                    msg => $msg,
                );
                $self->_generate_entry(%log_entry);
            }
        }
    }
}
sub new {
    my ($class, %args) = @_;

    my $self = bless {}, $class;

    if (defined $args{level}) {
        $self->level($args{level});
    }
    else {
        my $lvl = defined $ENV{LS_LEVEL} ? $ENV{LS_LEVEL} : 4;
        $self->level($lvl);
    }

    if ($args{file}){
        $self->file($args{file}, $args{write_mode});
    }

    my $print = defined $args{print} ? $args{print} : 1;
    $self->print($print);

    $self->display(
            time  => 1,
            label => 1,
            name  => 1,
            pid   => 0,
            proc  => 0,
    );

    if (defined $args{display}){
        $self->display($args{display});
    }

    $self->name($args{name});

    return $self;
}
sub level {
    my ($self, $level) = @_;

    my %levels = $self->levels;

    $self->{level} = $ENV{LS_LEVEL} if defined $ENV{LS_LEVEL};
    my $lvl;

    if (defined $level && $level =~ /^-1$/){
        $self->{level} = $level;
    }
    elsif (defined $level){
        my $log_only;

        if ($level =~ /^=/){
            $level =~ s/=//;
            $log_only = 1;
        }
        if ($level =~ /^\d$/ && defined $levels{$level}){
            $self->{level} = $level;
        }
        else {
            warn "invalid level $level specified, using default of 4\n";
        }

        if ($log_only){
            $self->_log_only($self->{level});
        }
        else {
            $self->_log_only(-1);
        }
    }

    return $self->{level};
}
sub file {
    my ($self, $file, $mode) = @_;

    if (! defined $file){
        return $self->{file};
    }
    if ($file =~ /^0$/){
        if (tell($self->{fh}) != -1) {
            close $self->{fh};
        }
        delete $self->{file};
        delete $self->{fh};
        return;
    }
    if (defined $file && $self->{file} && $file ne $self->{file}){
        close $self->{fh};
    }
    $mode = 'a' if ! defined $mode;
    my $op = $mode =~ /^a/ ? '>>' : '>';

    open $self->{fh}, $op, $file or croak "can't open log file for writing: $!";
    $self->{file} = $file;

    return $self->{file};
}
sub name {
    my ($self, $name) = @_;
    $self->{name} = $name if defined $name;
    return $self->{name};
}
sub timestamp {
    my $t = time;
    my $date = strftime "%Y-%m-%d %H:%M:%S", localtime $t;
    $date .= sprintf ".%03d", ($t-int($t))*1000; # without rounding
    return $date;
}
sub levels {
    my ($self, $lvl) = @_;

    my %levels = $self->_levels;

    return $levels{$lvl} if defined $lvl;
    return %levels;
}
sub labels {
    my ($self, $labels) = @_;
    $self->_levels($labels);
}
sub display {
    my $self = shift;
    my ($tag, %tags);

    if (@_ == 1){
        $tag = shift;
    }
    else {
        %tags = @_;
    }

    if (defined $tag){
        if ($tag =~ /^0$/){
            for (keys %{ $self->{display} }){
                $self->{display}{$_} = 0;
            }
            return 0;
        }
        if ($tag =~ /^1$/){
            for (keys %{ $self->{display} }){
                $self->{display}{$_} = 1;
            }
            return 1;
        }

        return $self->{display}{$tag};
    }

    my %valid = (
        name => 0,
        time => 0,
        label => 0,
        pid => 0,
        proc => 0,
    );

    for (keys %tags) {
        if (! defined $valid{$_}){
            warn "$_ is an invalid tag...skipping\n";
            next;
        }
        $self->{display}{$_} = $tags{$_};
    }

    return %{ $self->{display} };
}
sub print {
    $_[0]->{print} = $_[1] if defined $_[1];
    return $_[0]->{print};
}
sub child {
    my ($self, $name) = @_;
    my $child = bless { %$self }, ref $self;
    $name = $self->name . ".$name" if defined $self->name;
    $child->name($name);
    return $child;
}
sub custom_display {
    my ($self, $disp) = @_;

    if (defined $disp) {
        if ($disp =~ /^0$/) {
            delete $self->{custom_display};
            return 0;
        }
        else {
            $self->{custom_display} = $disp;
        }
    }
    return $self->{custom_display};
}
sub fatal {
    my ($self, $msg) = @_;
    $self->display(1);
    confess("\n" . $self->_0("$msg"));
}
sub _generate_entry {
    # builds/formats the log entry line

    my $self = shift;
    my %entry = @_;

    my $label = $entry{label};
    my $proc = $entry{proc};
    my $msg = $entry{msg};

    my $subs = $self->_sub_names;
    if (! grep { $label eq $_ } @$subs){
        croak "_generate_entry() requires a label => sub/label param\n";
    }

    $label =~ s/_//;
    $label = $self->levels($label);

    $msg = $msg ? "$msg\n" : "\n";

    my $log_entry;
    $log_entry .= $self->custom_display if defined $self->custom_display;
    $log_entry .= "[".$self->timestamp()."]" if $self->display('time');
    $log_entry .= "[$label]" if $self->display('label');
    $log_entry .= "[".$self->name."]" if $self->display('name') && $self->name;
    $log_entry .= "[$$]" if $self->display('pid');
    $log_entry .= "[$proc]" if $self->display('proc');
    $log_entry .= " " if $log_entry;
    $log_entry .= $msg;

    return $log_entry if ! $self->print;

    if ($self->{fh}){
        print { $self->{fh} } $log_entry;
    }
    else {
        print $log_entry;
    }
}
sub _levels {
    # manages the level labels

    my ($self, $labels) = @_;

    if (ref $labels eq 'ARRAY'){
        croak "must supply exactly 8 custom labels\n" if @$labels != 8;
        my %custom_levels = map {$_ => $labels->[$_]} (0..7);
        $self->{labels} = \%custom_levels;
    }

    if (defined $labels && $labels == 0 || ! defined $self->{labels}) {
        $self->{labels} = {
            0 => 'lvl 0',
            1 => 'lvl 1',
            2 => 'lvl 2',
            3 => 'lvl 3',
            4 => 'lvl 4',
            5 => 'lvl 5',
            6 => 'lvl 6',
            7 => 'lvl 7',
        };
    }
    return %{ $self->{labels} };
}
sub _log_only {
    # are we logging only one level or not?

    my ($self, $level) = @_;
    if (defined $level && $level == -1){
        $self->{log_only} = undef;
    }
    else {
        $self->{log_only} = $level if defined $level;
    }
    return $self->{log_only};
}

1;
__END__

=head1 NAME

Logging::Simple - Simple debug logging by number, with customizable labels and
formatting

=for html
<a href="http://travis-ci.org/stevieb9/logging-simple"><img src="https://secure.travis-ci.org/stevieb9/logging-simple.png"/>
<a href='https://coveralls.io/github/stevieb9/logging-simple?branch=master'><img src='https://coveralls.io/repos/stevieb9/logging-simple/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>

=head1 SYNOPSIS

    use Logging::Simple;

    my $log = Logging::Simple->new(name => 'whatever'); # name is optional

    $log->_4("default level is 4, we'll only print levels 4 and below");

    # change level

    $log->level(7);

    # log only a single level

    $log->level('=3');

    # disable all levels

    $log->level(-1);

    # log to a file

    $log->file('file.log');
    $log->_0("this will go to file");
    $log->file(0); # back to STDOUT

    # log to a "memory file"

    my $memfile;
    $log->file(\$memfile);

    # don't print, return instead

    $log->print(0);
    my $log_entry = $log->_2("print disabled");

    # send in your own log entry labels for the levels. They will be mapped
    # 0 through 7

    $log->labels([qw(emerg alert crit error warn notice info debug)]);

    # using a child log

    my $log = Logging::Simple->new(name => 'main');
    $log->_0("parent log");

    testing();

    sub testing {
        my $log = $log->child('testing()');
        $log->_4("child log");
    }
    __END__
    [2016-04-21 16:31:30.039][lvl 0][main] parent log
    [2016-04-21 16:31:30.040][lvl 4][main.testing()] child log


=head1 DESCRIPTION

Lightweight (core-only) and very simple yet flexible debug tool for printing or
writing to file log type entries based on a configurable level (0-7).

Instead of named log facility methods, it uses numbers instead, preventing you
from having to remember name to number mapping.

It provides the ability to programmatically change which output tags to
display, provides the ability to create descendent children, easily
enable/disable file output, levels, display etc. with the ability to provide
custom labels.

=head2 Logging entry format

By default, log entries appear as such, with a timestamp, the name of the
facility, the name (if previously set) and finally the actual log entry
message.

    [2016-03-17 17:01:21.959][lvl 6][whatever] example output

All of the above tags can be enabled/disabled programatically at any time, and
there are others that are not enabled by default. You can even add your own
custom tag. See the C<display()> method in L</CONFIGURATION METHODS> for further
details.

=head1 CONFIGURATION METHODS

=head2 new(%args)

Builds and returns a new C<Logging::Simple> object. All arguments are optional,
and they can all be set using accessor methods after instantiation. These params
are:

    name        => $str  # optional, default is undef
    level       => $num  # default 4, options, 0..7, -1 to disable all
    file        => $str  # optional, default undef, send in a filename
    write_mode  => $str  # defaults to append, other option is 'write'
    print       => $bool # default on, enable/disable output and return instead
    display     => $bool # default on, enable/disable log message tags

=head2 name($name)

Returns the name of the log, if available. Send in a string to set it.

=head2 level($num)

Set and return the facility level. Will return the current value with a param
sent in or not. It can be changed at any time. Note that you can set this with
the C<LS_LEVEL> environment variable, at any time. the next method call
regardless of what it is will set it appropriately.

You can also send in C<-1> as a level to disable all levels, or send in the
level prepended with a C<=> to log *only* that level (eg:
C<$log-E<gt>level('=3')>.

=head2 file('file.log', 'mode')

By default, we write to STDOUT. Send in the name of a file to write there
instead. Mode is optional; we'll append to the file by default. Send in 'w' or
'write' to overwrite the file.

=head2 display(%hash|$bool)

List of log entry tags, and default printing status:

    name  => 1, # specified in new() or name()
    time  => 1, # timestamp
    label => 1, # the string value of the level being called
    pid   => 0, # process ID
    proc  => 0, # "filename|line number" of the caller

In hash param mode, send in any or all of the tags with 1 (enable) or 0
(disable).

You can also send in 1 to enable all of the tags, or 0 to disable them all.

=head2 labels($list|0)

Send in an array reference of eight custom labels. We will map them in order to
the levels 0 through 7, and your labels will be displayed in the log entries.

Send in C<0> to disable your custom labels.

=head2 custom_display($str|$false)

This will create a custom tag in your output, and place it at the first column
of the output. Send in 0 (false) to disable/clear it.

=head2 print($bool)

Default is enabled. If disabled, we won't print at all, and instead, return the
log entry as a scalar string value.

=head2 child($name)

This method will create a clone of the existing C<Logging::Simple> object, and
then concatenate the parent's name with the optional name sent in here for easy
identification in the logs.

All settings employed by the parent will be used in the child, unless explicity
changed via the methods.

In a module or project, you can create a top-level log object, then in all
subs, create a child with the sub's name to easily identify flow within the
log. In an OO project, stuff the parent log into the main object, and clone it
from there.

=head1 LOGGING METHODS

=head2 levels

All log facilities are called by their corresponing numbered sub, eg:

    $log->_0("level 0 entry");
    ...
    $log->_7("level 7 entry");

=head2 fatal($msg)

Log the message, along with the trace C<confess()> produces, and croak's
immediately.

=head1 HELPER METHODS

These methods may be handy to the end user, but aren't required for end-use.

=head2 levels($level)

Returns the hash of level_num => level_name mapping.

If the optional integer C<$level> is sent in, we'll return the level_name of
the level.

=head2 timestamp

Returns the current time in the following format: C<2016-03-17 17:51:02.241>

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
L<https://github.com/stevieb9/logging-simple/issues>

=head1 REPOSITORY

L<https://github.com/stevieb9/logging-simple>

=head1 BUILD RESULTS (THIS VERSION)

CPAN Testers: L<http://matrix.cpantesters.org/?dist=Logging-Simple>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Logging::Simple

=head1 SEE ALSO

There are too many other logging modules to list here, but the idea for this
one came from L<Log::Basic>. However, this one was written completely from
scratch.

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

