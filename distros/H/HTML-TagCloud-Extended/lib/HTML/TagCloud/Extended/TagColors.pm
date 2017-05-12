package HTML::TagCloud::Extended::TagColors;
use strict;
use Readonly;
use HTML::TagCloud::Extended::Exception;

Readonly my $DEFAULT_EARLIEST_LINK    => "cccccc";
Readonly my $DEFAULT_EARLIEST_VISITED => "cccccc";
Readonly my $DEFAULT_EARLIEST_HOVER   => "cccccc";
Readonly my $DEFAULT_EARLIEST_ACTIVE  => "cccccc";
Readonly my $DEFAULT_EARLIER_LINK     => "9999cc";
Readonly my $DEFAULT_EARLIER_VISITED  => "9999cc";
Readonly my $DEFAULT_EARLIER_HOVER    => "9999cc";
Readonly my $DEFAULT_EARLIER_ACTIVE   => "9999cc";
Readonly my $DEFAULT_LATER_LINK       => "9999ff";
Readonly my $DEFAULT_LATER_VISITED    => "9999ff";
Readonly my $DEFAULT_LATER_HOVER      => "9999ff";
Readonly my $DEFAULT_LATER_ACTIVE     => "9999ff";
Readonly my $DEFAULT_LATEST_LINK      => "0000ff";
Readonly my $DEFAULT_LATEST_VISITED   => "0000ff";
Readonly my $DEFAULT_LATEST_HOVER     => "0000ff";
Readonly my $DEFAULT_LATEST_ACTIVE    => "0000ff";
Readonly my $DEFAULT_HOT_LINK         => "ff0000";
Readonly my $DEFAULT_HOT_VISITED      => "ff0000";
Readonly my $DEFAULT_HOT_HOVER        => "ff0000";
Readonly my $DEFAULT_HOT_ACTIVE       => "ff0000";

sub new {
    my $class = shift;
    my $self  = bless {
        earliest => {
            link    => $DEFAULT_EARLIEST_LINK,
            visited => $DEFAULT_EARLIEST_VISITED,
            hover   => $DEFAULT_EARLIEST_HOVER,
            active  => $DEFAULT_EARLIEST_ACTIVE,
        },
        earlier => {
            link    => $DEFAULT_EARLIER_LINK,
            visited => $DEFAULT_EARLIER_VISITED,
            hover   => $DEFAULT_EARLIER_HOVER,
            active  => $DEFAULT_EARLIER_ACTIVE,
        },
        later => {
            link    => $DEFAULT_LATER_LINK,
            visited => $DEFAULT_LATER_VISITED,
            hover   => $DEFAULT_LATER_HOVER,
            active  => $DEFAULT_LATER_ACTIVE,
        },
        latest => {
            link    => $DEFAULT_LATEST_LINK,
            visited => $DEFAULT_LATEST_VISITED,
            hover   => $DEFAULT_LATEST_HOVER,
            active  => $DEFAULT_LATEST_ACTIVE,
        },
        hot => {
            link    => $DEFAULT_HOT_LINK,
            visited => $DEFAULT_HOT_VISITED,
            hover   => $DEFAULT_HOT_HOVER,
            active  => $DEFAULT_HOT_ACTIVE,
        }
    }, $class;
    return $self;
}

sub set {
    my ($self, @args) = @_;
    while ( my($type, $color) = splice(@args, 0, 2) ) {
        unless ( $type =~ /(?:earliest|earlier|later|latest|hot)/ ) {
            HTML::TagCloud::Extended::Exception->throw(
            qq/Choose type from [earliest earlier later latest]./
            );
        }
        if (ref $color eq 'HASH') {
            while ( my($attr, $code) = each %$color ) {
                unless ( $attr =~ /(?:link|visited|hover|active)/ ) {
                    HTML::TagCloud::Extended::Exception->throw(
                    qq/Choose attribute from [link visited hover active]./
                    );
                }
                $code =~ s/\#//;
                if ( $self->_check_color_code($code) ) {
                    $self->{$type}{$attr} = $code;
                } else {
                    HTML::TagCloud::Extended::Exception->throw(
                    qq/Wrong color-code format "$code"./
                    );
                }
            }
        } else {
            $color =~ s/\#//;
            if ( $self->_check_color_code($color) ) {
                $self->{$type}{link}    = $color;
                $self->{$type}{visited} = $color;
                $self->{$type}{hover}   = $color;
                $self->{$type}{active}  = $color;
            } else {
                HTML::TagCloud::Extended::Exception->throw(
                qq/Wrong color-code format "$color"./
                );    
            }
        }
    }
}

sub _check_color_code {
    my ($self, $code) = @_;
    return ( $code =~ /^[0-9a-fA-F]{6}$/ || $code =~ /^[0-9a-fA-F]{3}$/ )
        ? 1 : undef;
}

1;
__END__

