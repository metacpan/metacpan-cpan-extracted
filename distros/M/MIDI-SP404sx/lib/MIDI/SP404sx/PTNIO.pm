package MIDI::SP404sx::PTNIO;
use strict;
use warnings;
use Data::Dumper;
use MIDI::SP404sx::Note;
use MIDI::SP404sx::Pattern;
use MIDI::SP404sx::Constants;
use Log::Log4perl qw(:easy);

my $BLOCK_SIZE=1024;

sub read_pattern {
    my $class = shift;
    my $file = shift;
    open my $fh, '<', $file or die $!;
    binmode($fh);
    my $buf;
    my $offset = 0;
    my @result;
    my $i = 0;

    ### this is just for formatted printing of the byte sequence
    # print join( "\t", qw(event next pad bank ? vel ? length) ), "\n";
    # print 1;
    ###

    while( read( $fh, $buf, $BLOCK_SIZE, $offset * $BLOCK_SIZE ) ){
	    for( split( //, $buf ) ) {
            my $hex = ord( $_ );

            ### this is just for formatted printing of the byte sequence
            # print "\t$hex";
            # $i++;
            # unless ( $i % 8 ) {
            #     print "\n";
            #     print $i/8 + 1;
            # }
            ###

            push @result, $hex;
	    }
	    $offset++;
    }
    close( $fh );
    return decode(@result);
}

sub decode {
    my @ints = @_;
    my ( $next, $pad, $bank, $velocity, $isnote, $length ) = ( 0, 1, 2, 4, 5, 6);
    my $pattern  = MIDI::SP404sx::Pattern->new( nlength => $ints[-7] );
    my $ppqn     = $MIDI::SP404sx::Constants::PPQ;
    my $position = 0;
    for ( my $i = 0; $i <= ( $#ints - 16 ); $i += 8 ) {
        if ( $ints[$isnote+$i] ) {
            my $channel = $ints[$bank+$i] ? 1 : 0;
            my $nlength = hex( sprintf('0x%02x%02x', $ints[$length+$i], $ints[$length+$i+1] ) ) / $ppqn;
            MIDI::SP404sx::Note->new(
                pitch    => $ints[$pad+$i],
                velocity => $ints[$velocity+$i],
                nlength  => $nlength,
                channel  => $channel,
                pattern  => $pattern,
                position => $position / $MIDI::SP404sx::Constants::PPQ,
            );
        }
        $position += $ints[$next+$i];
    }
    return $pattern;
}

#- next_sample
#- pad_code
#- bank_switch
#- unknown1
#- velocity
#- unknown2
#- length (note: 2 bytes)

sub write_pattern {
    my $class = shift;
    my ( $pattern, $outfile ) = @_;
    my $ppqn = $MIDI::SP404sx::Constants::PPQ;
    open my $out, '>:raw', $outfile or die "Unable to open: $!";
    my @notes = sort { $a->position <=> $b->position } $pattern->notes;
    for my $i ( 0 .. $#notes ) {
        my $n = $notes[$i];

        # generate spacers from start to first note
        if ( $i == 0 and $n->position != 0 ) {
            my ( $remainder, @spacers );
            ( $remainder, @spacers ) = _make_spacers( sprintf( "%.0f", ( $n->position * $ppqn ) ) );
            push @spacers, [ $remainder, 128, 0, 0, 0, 0, 0 ];
            _write_event( $out, @$_ ) for @spacers;
        }

        # generate spacers to next note or pattern end
        my ( $next_sample, @spacers );
        if ( my $o = $notes[$i+1] ) {
            my $raw = ( $o->position - $n->position ) * $ppqn;
            $next_sample = sprintf( "%.0f", $raw );
        }
        else {
            my $raw = ( ( $pattern->nlength * 4 ) - $n->position ) * $ppqn;
            $next_sample = sprintf( "%.0f", $raw );
        }
        ( $next_sample, @spacers ) = _make_spacers($next_sample);

        # write focal note
        _write_note( $out, $n, $next_sample );

        # write spacers
        _write_event( $out, @$_ ) for @spacers;
    }

    # write footer
    _write_event( $out, 0, 140,               0, 0, 0, 0, 0 );
    _write_event( $out, 0, $pattern->nlength, 0, 0, 0, 0, 0 );

    close $out;
}

sub _make_spacers {
    my $interval = shift;
    my @spacers;
    while( $interval > 255 ) {
        push @spacers, [ 255, 128, 0, 0, 0, 0, 0 ];
        $interval -= 255;
    }
    return $interval, @spacers;
}

sub _write_note {
    my ( $out, $n, $next ) = @_;
    my @fields;
    push @fields, $next;
    push @fields, $n->pitch;
    push @fields, ( $n->channel ? 64 : 0 );
    push @fields, 0;
    push @fields, $n->velocity;
    push @fields, 64;
    push @fields, sprintf( "%.0f", ( $n->nlength * $MIDI::SP404sx::Constants::PPQ ) );
    _write_event( $out, @fields );
}

sub _write_event {
    my ( $out, @fields ) = @_;
    for my $i ( 0 .. $#fields ) {
        if ( $i < $#fields ) {
            print $out pack( 'C', $fields[$i] );
        }
        else {
            print $out pack( 'S>', $fields[$i] );
        }
    }
}

1;