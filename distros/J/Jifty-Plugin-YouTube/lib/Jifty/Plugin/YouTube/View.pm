package Jifty::Plugin::YouTube::View;
use warnings;
use strict;

use Jifty::View::Declare -base;
use Jifty::View::Declare::Helpers;

template '/_youtube' => page { } content {
    # basic wrapper
    my $hash = get('hash');
    return unless( $hash ) ;
    div { { class is 'youtube-wrapper' };
        show '/youtube_widget', $hash;
    };
};

template 'youtube_widget' => sub {
    my ($self, $hash , $options ) = @_;
    $options ||= {};
    my $default_options = {
        allowFullScreen => 'true',
        allowscriptaccess => 'always',
    };
    map { $options->{$_} ||= $default_options->{$_} } keys %$default_options;
    my $params = join "\n",map {  qq|<param name="$_" value="@{[ $options->{$_} ]}"></param>|  }  keys %$options;
    outs_raw(qq|
    <object width="425" height="344">
        <param name="movie" value="http://www.youtube.com/v/$hash&hl=en&fs=1"></param>
        $params
        <embed
            src="http://www.youtube.com/v/$hash&hl=en&fs=1"
            type="application/x-shockwave-flash" allowscriptaccess="always"
            allowfullscreen="true" 
            width="425" height="344"></embed>
    </object>
    |);
};

1;

