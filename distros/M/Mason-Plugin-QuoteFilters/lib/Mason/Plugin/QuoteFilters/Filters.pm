package Mason::Plugin::QuoteFilters::Filters;

use Mason::PluginRole;

our $VERSION = 0.002;# VERSION

sub Q {
    return sub {
        my $text = $_[0];
        $text =~ s/'/\\'/g;
        return "'$text'";
    };
}

sub QQ {
    return sub {
        my $text = $_[0];
        $text =~ s/"/\\"/g;
        return qq{"$text"};
    };
}

1;
