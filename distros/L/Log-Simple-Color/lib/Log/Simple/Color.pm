package Log::Simple::Color;

use version; our $VERSION = qv('0.0.3');

use 5.008_001;
use strict;
use warnings;

my $win32;
my $ansi;
my $console;
my %default_color_of;
my %color_of;
my %msg;

my $default_level = 'info';
my %log_level_of = (
    debug   => 0,
    info    => 1,
    warning => 2,
    error   => 3,
);

my %default_msg = (
    debug => sub {
        my ( $self, @args ) = @_;
        return if $log_level_of{debug} < $log_level_of{$self->level};
        print "[DEBUG] ", @args, "\n";
    },
    info => sub {
        my ( $self, @args ) = @_;
        return if $log_level_of{info} < $log_level_of{$self->level};
        print "[INFO] ", @args, "\n";
    },
    warning => sub {
        my ( $self, @args ) = @_;
        return if $log_level_of{warning} < $log_level_of{$self->level};
        print "[WARNING] ", @args, "\n";
    },
    error => sub {
        my ( $self, @args ) = @_;
        return if $log_level_of{error} < $log_level_of{$self->level};
        print "[ERROR] ", @args, "\n";
    },
    default => sub {
        my ( $self, $mode, @args ) = @_;
        return if $log_level_of{default} < $log_level_of{$self->level};
        print "[$mode] ", @args, "\n";
    },
);

my %linux_msg = (
    debug => sub {
        my ( $self, @args ) = @_;
        return if $log_level_of{debug} < $log_level_of{$self->level};
        print @{ $color_of{debug} }, @args, @{ $color_of{default} }, "\n";
    },
    info => sub {
        my ( $self, @args ) = @_;
        return if $log_level_of{info} < $log_level_of{$self->level};
        print @{ $color_of{info} }, @args, @{ $color_of{default} }, "\n";
    },
    warning => sub {
        my ( $self, @args ) = @_;
        return if $log_level_of{warning} < $log_level_of{$self->level};
        print @{ $color_of{warning} }, @args, @{ $color_of{default} }, "\n";
    },
    error => sub {
        my ( $self, @args ) = @_;
        return if $log_level_of{error} < $log_level_of{$self->level};
        print @{ $color_of{error} }, @args, @{ $color_of{default} }, "\n";
    },
    default => sub {
        my ( $self, $mode, @args ) = @_;
        return if $log_level_of{default} < $log_level_of{$self->level};
        print "[$mode] ", @args, "\n";
    },
);

my %window_msg = (
    debug => sub {
        my ( $self, @args ) = @_;
        return if $log_level_of{debug} < $log_level_of{$self->level};
        $console->Attr(@{ $color_of{debug} });
        print @args, "\n";
        $console->Attr(@{ $color_of{default} });
    },
    info => sub {
        my ( $self, @args ) = @_;
        return if $log_level_of{info} < $log_level_of{$self->level};
        $console->Attr(@{ $color_of{info} });
        print @args, "\n";
        $console->Attr(@{ $color_of{default} });
    },
    warning => sub {
        my ( $self, @args ) = @_;
        return if $log_level_of{warning} < $log_level_of{$self->level};
        $console->Attr(@{ $color_of{warning} });
        print @args, "\n";
        $console->Attr(@{ $color_of{default} });
    },
    error => sub {
        my ( $self, @args ) = @_;
        return if $log_level_of{error} < $log_level_of{$self->level};
        $console->Attr(@{ $color_of{error} });
        print @args, "\n";
        $console->Attr(@{ $color_of{default} });
    },
    default => sub {
        my ( $self, $mode, @args ) = @_;
        return if $log_level_of{default} < $log_level_of{$self->level};
        print "[$mode] ", @args, "\n"
    },
);

if ($^O eq 'MSWin32') {
    eval 'use Win32::Console;';
    if (!$@) {
        $win32 = 1;

        $console = Win32::Console->new( eval 'STD_OUTPUT_HANDLE' );
        $default_color_of{default} = [ eval '$ATTR_NORMAL'         ];
        $default_color_of{debug}   = [ eval '$FG_CYAN'             ];
        $default_color_of{info}    = [ eval '$FG_YELLOW'           ];
        $default_color_of{warning} = [ eval '$FG_WHITE | $BG_BLUE' ];
        $default_color_of{error}   = [ eval '$FG_WHITE | $BG_RED'  ];

        $msg{debug}   = $window_msg{debug};
        $msg{info}    = $window_msg{info};
        $msg{warning} = $window_msg{warning};
        $msg{error}   = $window_msg{error};
        $msg{default} = $window_msg{default};
    }
    else {
        print "Recommand CPAN Perl Module: [Win32::Console]\n";
        $msg{debug}   = $default_msg{debug};
        $msg{info}    = $default_msg{info};
        $msg{warning} = $default_msg{warning};
        $msg{error}   = $default_msg{error};
        $msg{default} = $default_msg{default};
    }
}
else {
    eval 'use Term::ANSIColor qw(:constants);';
    if (!$@) {
        $ansi = 1;

        $default_color_of{default} = [ eval 'RESET'          ];
        $default_color_of{debug}   = [ eval 'CYAN'           ];
        $default_color_of{info}    = [ eval 'YELLOW'         ];
        $default_color_of{warning} = [ eval 'WHITE, ON_BLUE' ];
        $default_color_of{error}   = [ eval 'WHITE, ON_RED'  ];

        $msg{debug}   = $linux_msg{debug};
        $msg{info}    = $linux_msg{info};
        $msg{warning} = $linux_msg{warning};
        $msg{error}   = $linux_msg{error};
        $msg{default} = $linux_msg{default};
    }
    else {
        print "Recommand CPAN Perl Module: [Win32::Console]\n";
        $msg{debug}   = $default_msg{debug};
        $msg{info}    = $default_msg{info};
        $msg{warning} = $default_msg{warning};
        $msg{error}   = $default_msg{error};
        $msg{default} = $default_msg{default};
    }
}
%color_of = %default_color_of;

sub new {
    my ($class, %param) = @_;

    my $self = bless {
        level => $default_level,
    }, $class;

    $self->level($param{level}) if exists $param{level};

    return $self;
}

sub debug   { $msg{debug}->(@_) }
sub info    { $msg{info}->(@_) }
sub warning { $msg{warning}->(@_) }
sub error   { $msg{error}->(@_) }

sub level {
    my ( $self, $level ) = @_;

    return $self->{level} unless $level;

    if    ( $level =~ m/^debug$/i )   { $self->{level} = 'debug'; }
    elsif ( $level =~ m/^info$/i )    { $self->{level} = 'info'; }
    elsif ( $level =~ m/^warning$/i ) { $self->{level} = 'warning'; }
    elsif ( $level =~ m/^error$/i )   { $self->{level} = 'error'; }
    else                              { $self->{level} = 'info'; }
}

sub color {
    my ($self, @args) = @_;

    return unless @args >= 1;

    my $mode      = q{};
    my $fg        = q{};
    my $bg        = q{};
    my $dark      = 0;
    my $bold      = 0;
    my $underline = 0;
    my $default   = 0;
    my $reset     = 0;

    if (ref($args[0]) eq 'HASH') {
        my $param = $args[0];

        $mode      = $param->{mode}      if exists $param->{mode};
        $fg        = $param->{fg}        if exists $param->{fg};
        $bg        = $param->{bg}        if exists $param->{bg};
        $dark      = $param->{dark}      if exists $param->{dark};
        $bold      = $param->{bold}      if exists $param->{bold};
        $underline = $param->{underline} if exists $param->{underline};
        $default   = $param->{default}   if exists $param->{default};
        $reset     = $param->{reset}     if exists $param->{reset};
    }
    else {
        $mode = shift @args || q{};
        $fg   = shift @args || q{};
        $bg   = shift @args || q{};
    }

    return unless $mode =~ m/^(debug|info|warning|error)$/i;
    $mode = lc $mode;

    if ($default) {
        $color_of{$mode} = $default_color_of{$mode};
        return;
    }

    if ($reset) {
        $color_of{$mode} = [];
        return;
    }

    my @colors = @{$color_of{$mode}};

    if ($fg =~ m/^(black|white|red|green|yellow|blue|magenta|cyan)$/i) {
        $fg = uc $1;
    }

    if ($bg =~ m/^(black|white|red|green|yellow|blue|magenta|cyan)$/i) {
        $bg = uc $1;
    }

    if ($ansi) {
        push @colors, eval "$fg"       if $fg;
        push @colors, eval "ON_$bg"    if $bg;
        push @colors, eval "BOLD"      if $bold;
        push @colors, eval "DARK"      if $dark;
        push @colors, eval "UNDERLINE" if $underline;
    }
    elsif ($win32) {
        my $color = 0;
        if ($dark) {
            $fg = 'BROWN' if $fg =~ m/^yellow$/i;
            $bg = 'BROWN' if $bg =~ m/^yellow$/i;

            $color = $color ? $color | eval "\$FG_$fg" : eval "\$FG_$fg" if $fg;
            $color = $color ? $color | eval "\$BG_$bg" : eval "\$BG_$bg" if $bg;
        }
        else {
            $color = $color ? $color | eval "\$FG_LIGHT$fg" : eval "\$FG_LIGHT$fg"
                if $fg =~ m/^(red|green|yellow|blue|magenta|cyan)$/i;

            $color = $color ? $color | eval "\$BG_LIGHT$bg" : eval "\$BG_LIGHT$bg"
                if $bg =~ m/^(red|green|yellow|blue|magenta|cyan)$/i;
        }
        push @colors, $color;
    }

    $color_of{$mode} = \@colors;
}

1;
__END__

=encoding utf-8

=head1 NAME

Log::Simple::Color - Log messages with different color for console


=head1 VERSION

This document describes Log::Simple::Color version 0.0.3


=head1 SYNOPSIS

    use strict;
    use warnings;
    use Log::Simple::Color;
    
    my $log = Log::Simple::Color->new;
    
    print "current log level: ", $log->level, "\n";
    $log->level('debug');
    print "current log level: ", $log->level, "\n";
    
    $log->debug("This is a debug message");
    $log->info("This is an info message");
    $log->warning("This is a warning message");
    $log->error("This is an error message");
    
    $log->color(
        mode => 'debug',
        fg   => 'yellow',
        bg   => 'blue',
        bold => 1,
        dark => 1,
    );
    
    $log->debug("you can set different color");


=head1 DESCRIPTION

This is a simple logging module for coloring text.
You can set foreground color or background color for your text.
This module supports ANSI terminals and Win32 systems.


=head1 INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install


=head1 INTERFACE 

=head2 new

    my $log = Log::Simple::Color->new;

=head2 debug

    $log->debug("This is a debug message");

=head2 info

    $log->info("This is an info message");

=head2 warning

    $log->warning("This is a warning message");

=head2 error

    $log->error("This is an error message");

=head2 level

    $log->level;
    $log->level('warning');

=head2 color

    $log->color('debug', 'blue');
    $log->color('debug', 'blue', 'yellow');
    $log->color('debug', undef, 'yellow');
    $log->color(
        mode => 'info',
        fg   => 'blue',
        bg   => 'yellow',
    );


=head1 DEPENDENCIES

=over

=item *

Win32::Console - if OS is win32

=item *

Term::ANSIColor - if terminal supports ANSI

=back


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-log-simple-color@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Keedi Kim - 김도형  C<< <keedi@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008-2009, Keedi Kim - 김도형 C<< <keedi@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
