package Log::Log4perl::Layout::ColoredPatternLayout;

use strict;
use warnings;
use base 'Log::Log4perl::Layout::PatternLayout';
use Term::ANSIColor 'colored';

# Tom Gracey May 2018
# Most of what follows is taken from the original
# Log::Log4perl::Layout::PatternLayout
# See comments and manpage

our $VERSION = '0.01';

use constant _INTERNAL_DEBUG => 0;

our $TIME_HIRES_AVAILABLE_WARNED = 0;
our $HOSTNAME;
our %GLOBAL_USER_DEFINED_CSPECS = ();

our $CSPECS = 'cCdFHIlLmMnpPrRtTxX%';

no strict qw(refs);

##################################################
sub new {
##################################################
# this overrides 'new' in Log::Log4perl::Layout::PatternLayout
# (sub was taken from Log::Log4perl version 1.49)
# - but with very sparse changes
# changed/added lines are marked
# Tom Gracey May 2018

    my $class = shift;
    $class = ref ($class) || $class;

    my $options       = ref $_[0] eq "HASH" ? shift : {};
    my $layout_string = @_ ? shift : '%m%n';
    
    my $self = {
        format                => undef,
        info_needed           => {},
        stack                 => [],
        CSPECS                => $CSPECS,
        dontCollapseArrayRefs => $options->{dontCollapseArrayRefs}{value},
        last_time             => undef,
        undef_column_value    => 
            (exists $options->{ undef_column_value } 
                ? $options->{ undef_column_value } 
                : "[undef]"),
    };

    $self->{timer} = Log::Log4perl::Util::TimeTracker->new(
        time_function => $options->{time_function}
    );

    # The following lines added TG May 2018
    if(exists $options->{ColorMap}->{value}){ 
        $self->{color_map} = $options->{ColorMap}->{value};
    }
    # End of added lines TG 

    if(exists $options->{ConversionPattern}->{value}) {
        $layout_string = $options->{ConversionPattern}->{value};
    }

    if(exists $options->{message_chomp_before_newline}) {
        $self->{message_chomp_before_newline} = 
          $options->{message_chomp_before_newline}->{value};
    } else {
        $self->{message_chomp_before_newline} = 1;
    }

    bless $self, $class;

    #add the global user-defined cspecs
    foreach my $f (keys %GLOBAL_USER_DEFINED_CSPECS){
            #add it to the list of letters
        $self->{CSPECS} .= $f;
             #for globals, the coderef is already evaled, 
        $self->{USER_DEFINED_CSPECS}{$f} = $GLOBAL_USER_DEFINED_CSPECS{$f};
    }

    #add the user-defined cspecs local to this appender
    foreach my $f (keys %{$options->{cspec}}){
        $self->add_layout_cspec($f, $options->{cspec}{$f}{value});
    }

    # non-portable line breaks
    $layout_string =~ s/\\n/\n/g;
    $layout_string =~ s/\\r/\r/g;

    $self->define($layout_string);

    return $self;
}


##################################################
sub render {
##################################################
#
# Tom Gracey May 2018
# Same situaton as 'new' (see above)
# ie 'render' is overridden but only minor changes
# made, which are marked below
#
    my($self, $message, $category, $priority, $caller_level) = @_;

    $caller_level = 0 unless defined  $caller_level;

    my %info    = ();

    $info{m}    = $message;
        # See 'define'
    chomp $info{m} if $self->{message_chompable};

    my @results = ();

    my $caller_offset = Log::Log4perl::caller_depth_offset( $caller_level );

    if($self->{info_needed}->{L} or
       $self->{info_needed}->{F} or
       $self->{info_needed}->{C} or
       $self->{info_needed}->{l} or
       $self->{info_needed}->{M} or
       $self->{info_needed}->{T} or
       0
      ) {

        my ($package, $filename, $line, 
            $subroutine, $hasargs,
            $wantarray, $evaltext, $is_require, 
            $hints, $bitmask) = caller($caller_offset);

        # If caller() choked because of a whacko caller level,
        # correct undefined values to '[undef]' in order to prevent 
        # warning messages when interpolating later
        unless(defined $bitmask) {
            for($package, 
                $filename, $line,
                $subroutine, $hasargs,
                $wantarray, $evaltext, $is_require,
                $hints, $bitmask) {
                $_ = '[undef]' unless defined $_;
            }
        }

        $info{L} = $line;
        $info{F} = $filename;
        $info{C} = $package;

        if($self->{info_needed}->{M} or
           $self->{info_needed}->{l} or
           0) {
            # To obtain the name of the subroutine which triggered the 
            # logger, we need to go one additional level up.
            my $levels_up = 1; 
            {
                my @callinfo = caller($caller_offset+$levels_up);

                if(_INTERNAL_DEBUG) {
                    callinfo_dump( $caller_offset, \@callinfo );
                }

                $subroutine = $callinfo[3];
                    # If we're inside an eval, go up one level further.
                if(defined $subroutine and
                   $subroutine eq "(eval)") {
                    print "Inside an eval, one up\n" if _INTERNAL_DEBUG;
                    $levels_up++;
                    redo;
                }
            }
            $subroutine = "main::" unless $subroutine;
            print "Subroutine is '$subroutine'\n" if _INTERNAL_DEBUG;
            $info{M} = $subroutine;
            $info{l} = "$subroutine $filename ($line)";
        }
    }

    $info{X} = "[No curlies defined]";
    $info{x} = Log::Log4perl::NDC->get() if $self->{info_needed}->{x};
    $info{c} = $category;
    $info{d} = 1; # Dummy value, corrected later
    $info{n} = "\n";
    $info{p} = $priority;
    $info{P} = $$;
    $info{H} = $HOSTNAME;

    my $current_time;

    if($self->{info_needed}->{r} or $self->{info_needed}->{R}) {
        if(!$TIME_HIRES_AVAILABLE_WARNED++ and 
           !$self->{timer}->hires_available()) {
            warn "Requested %r/%R pattern without installed Time::HiRes\n";
        }
        $current_time = [$self->{timer}->gettimeofday()];
    }

    if($self->{info_needed}->{r}) {
        $info{r} = $self->{timer}->milliseconds( $current_time );
    }
    if($self->{info_needed}->{R}) {
        $info{R} = $self->{timer}->delta_milliseconds( $current_time );
    }

        # Stack trace wanted?
    if($self->{info_needed}->{T}) {
        local $Carp::CarpLevel =
              $Carp::CarpLevel + $caller_offset;
        my $mess = Carp::longmess(); 
        chomp($mess);
        # $mess =~ s/(?:\A\s*at.*\n|^\s*Log::Log4perl.*\n|^\s*)//mg;
        $mess =~ s/(?:\A\s*at.*\n|^\s*)//mg;
        $mess =~ s/\n/, /g;
        $info{T} = $mess;
    }

        # As long as they're not implemented yet ..
    $info{t} = "N/A";

    my @ops; #Added TG May 2018 - we need a key for substituting color values

        # Iterate over all info fields on the stack
    for my $e (@{$self->{stack}}) {
        my($op, $curlies) = @$e;

        my $result;

        if(exists $self->{USER_DEFINED_CSPECS}->{$op}) {
            next unless $self->{info_needed}->{$op};
            $self->{curlies} = $curlies;
            $result = $self->{USER_DEFINED_CSPECS}->{$op}->($self, 
                              $message, $category, $priority, 
                              $caller_offset+1);
        } elsif(exists $info{$op}) {
            $result = $info{$op};
            if($curlies) {
                $result = $self->curly_action($op, $curlies, $info{$op},
                                              $self->{printformat}, \@results);
            } else {
                # just for %d
                if($op eq 'd') {
                    $result = $info{$op}->format($self->{timer}->gettimeofday());
                }
            }
        } else {
            warn "Format %'$op' not implemented (yet)";
            $result = "FORMAT-ERROR";
        }

        $result = $self->{undef_column_value} unless defined $result;

        push @results, $result;
        push @ops,$op; # Added TG May 2018 - collect op codes for key
    }

      # dbi appender needs that
    if( scalar @results == 1 and
        !defined $results[0] ) {
        return undef;
    }
    return +$self->_color_message(\@ops,\@results); # Changed TG May 2018
}

##################################################
sub _color_message {
##################################################
#
# Tom Gracey May 2018
# Deliver a colored message from an array of 
# op codes and accompaning results. Get color 
# mappings from $self->{color_map}
#
# Slightly more difficult than it seems due to
# ANSI color characters playing havoc with 
# formatting. It is necessary to substitute in the
# uncolored values first, then substitute the uncolored
# param for the colored one.
#
# But that could also cause problems if an uncolored
# string appears in the formatting string as well as
# the parameter. (You'd end up with 2 colored 
# strings instead of the desired 1)
#
# So to catch this issue, break up the formatting string
# so that parameters appear once per fragment and
# at the front of the string, then perform 1 
# substitution only per fragment. Finally rebuild.

    my ($self,$ops,$results) = @_;

    my @sfrags;
    my $counter = 0;
    foreach my $psection (split(/%%/,$self->{printformat})){

        my @pitems = split(/%(?!%)/,$psection);
        foreach my $i (1..$#pitems){
           $pitems[$i] = '%'.$pitems[$i];
        }

        my @ifrags;
        for my $i (1..$#pitems){
            my $ifrag = sprintf( $pitems[$i], $results->[$counter] );
            my $color = $self->{color_map}->{ $ops->[$counter] };
            if ( $color ){
                if ( ref $color eq ref (sub{}) ){
                    $color = $color->($results->[$counter]);
                }
                my $orig_res = $results->[$counter];
                my $new_res = colored( $results->[$counter], $color );
                $ifrag =~ s/\Q$orig_res\E/$new_res/;
            }
            push (@ifrags,$ifrag);
            $counter++;
        }
        push(@sfrags,$pitems[0].join('',@ifrags));
    }
    return +join('%',@sfrags);
}

1;

=head1 NAME

Log::Log4perl::Layout::ColoredPatternLayout - multicolor log messages

=head1 SYNOPSIS


    # in the logger config:

    log4j.appender.appndr1.layout.ColorMap = sub{
        return {
            d => 'blue on_white',
            m => 'blue',
            p => sub { 
                my $colors = {
                    trace => "green",
                    debug => "bold green",
                    info => "white",
                    warn => "yellow",
                    error => "red",
                    fatal => "bold red"
                };
                return +$colors->{ lc($_[0]) };
            }
        };
    }

    log4j.appender.appndr1.layout.ConversionPattern
        = '%d %-5p: %m%n'


    # .. and log as usual in your code

    $logger->debug("A debug message");

    # Logs a debug message with the following colors:
    #
    # 2018-05-02 12:22:16 DEBUG A debug message
    #
    # ^^^^^^^^^^^^^^^^^^^ ^^^^^ ^^^^^^^^^^^^^^^  
    #         1             2          3
    #
    # 1 = blue on_white
    # 2 = bold green
    # 3 = blue    


    $logger->info("An info message");

    # Logs an info message with the following colors:
    #
    # 2018-05-02 12:22:16 INFO  An info message
    #
    # ^^^^^^^^^^^^^^^^^^^ ^^^^^ ^^^^^^^^^^^^^^^  
    #         1             2          3
    #
    # 1 = blue on_white
    # 2 = white
    # 3 = blue

    

=head1 DESCRIPTION

There's no doubt Log::Log4perl is a fantastic logging system. It's a great weight off ones mind not having to worry (much!) about logging since Log::Log4perl seems to pretty much cover every eventuality and is very well battletested.

An appender does exist which can colorise the whole message based on its log level (L<Log::Log4perl::Appender::ScreenColoredLevel>). However, I wanted to colorise individual I<parts> of a message, rather than the whole thing. It can be easier on the eye, and save screen space by reducing the need for separators. 

I started with the assumpion that I could do this in a similar way to <Log::Log4perl::Appender::ScreenColoredLevel> - ie by creating an appender. However, unfortunately the C<log> sub only appears to get handed the final formatted message, rather than the message components. There doesn't seem to be any way to access this information from the inherited class.

So instead this module inherits from L<Log::Log4perl::Layout::PatternLayout> in order to solve the conundrum. It can be used as a replacement for L<Log::Log4perl::Layout::PatternLayout> - but remember it only makes sense with I<screen> type appenders (otherwise ANSI color characters will be written to places where they shouldn't be).

=head1 USAGE

Usage is straightforward. Declare a I<color map> in your config - basically a hash which maps formatting codes (C<%p>, C<%d>, etc.) to ansi colors. (See L<Term::ANSIColor> for valid color values). See the synopsis for an example.

A value in the color map can be a simple string C<green>, C<bold blue> etc. - or a sub that returns a string

    log4j.appender.appndr1.layout.ColorMap = sub {
        return {
            p => 'blue',    # simple string

            F => sub {      # sub returning simple string

                my ($filename) = @_;
            
                my $color = $filename = 'important.file'?'red':'white'
            
                return $color;
            }

        };    
    };

In this example if the filename where the logging event occurs (corrsponding to C<%F>) happens to be C<important.file> then this will get printed to the terminal in red, while other filenames will be plain white.

color map subs get passed a single parameter, containing the value of the variable corresponding to the formatting code which you can use to determine the output color (e.g. C<DEBUG>, C<INFO> for C<%p>, a date for <%d> etc).

=head1 CAVEATS

=over

=item 1.

As mentioned previously, this is for screen output only. Use C<Log::Log4perl::Layout::PatternLayout> for anything else.

=item 2.

You can only colorise parts of the string corresponding to a formatting code. e.g. if your formatting string is:

    log4j.appender.appndr1.layout.ConversionPattern
        = '[%d] %-5p: %m%n'

then there is no way to colorise those square brackets. Sorry! However, perhaps with color the brackets are not necessary?

=item 3.

This won't work with L<Log::Log4perl::Appender::ScreenColoredLevel>

=item 4.

I'm not entirely comfortable with the fact this inherits from L<Log::Log4perl::Layout::PatternLayout>, and less comfortable still that it overrides C<new> and another big subroutine C<render> just to make minor changes. Unfortunately this seems necessary because those subs are large and the required info is buried somewhere in the middle. Thus an update to L<Log::Log4perl::Layout::PatternLayout> has the potential to break this module. Should this happen I will attempt to review the method in general and fix where possible. But no guarantees.

Of course if <Log::Log4perl::Appender> does get modified so it receives more information at some point in the future, then this module may not be necessary.

=back

=head1 SEE ALSO

L<Log::Log4perl>
L<Log::Log4perl::Appender::Screen>
L<Log::Log4perl::Appender::ScreenColoredLevel>
L<Log::Log4perl::Layout>
L<Log::Log4perl::Layout::PatternLayout>
L<Log::Log4perl::Layout::SimpleLayout>
L<Term::ANSIColor>

=head1 AUTHOR

Tom Gracey E<lt>tomgracey@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Tom Gracey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
