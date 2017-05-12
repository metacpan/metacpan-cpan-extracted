package lists;
use utf8 qw(decode);
use HTML::Entities;

sub args {
    return (
        url_regex=>qr{
            \A                  # start of string
            (?:
                (?:
                    http://\w[\w\.]{1,20}\w
                )                  # optional external ref
                |
                (?:
                    /                   # 
                    \w                  # at least one normal character
                    [\w\-/]*            # 
                )
            )
            (?:\#[\w\-]+)?      # optional anchor
            \z                  # end of string
        }xms,
        tag_hierarchy => {
            h3 => '',
            p => '',
            ul => '',
            ol => '',
            img => '',
            div => '',
            li => ['ul', 'ol'],
            a => ['p', 'li'],
            em => ['p', 'li'],
            strong => ['p', 'li'],
        },
        img_height_default=>100,
        img_width_default=>200,
        text_manip=>sub {
            my $text = shift;
            utf8::decode($text);
            return encode_entities($text);
        },
        text_container=>sub {
            my $text = shift;
            return "<div>$text</div>";
        }
    );
}

1

