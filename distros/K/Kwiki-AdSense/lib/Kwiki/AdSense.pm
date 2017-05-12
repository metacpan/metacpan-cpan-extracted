package Kwiki::AdSense;
use Kwiki::Plugin -Base;
use mixin 'Kwiki::Installer';
our $VERSION = '0.11';

const class_id => 'adsense';
const config_file => 'adsense.yaml';

sub register {
    my $registry = shift;
    $registry->add(preload => 'adsense');
    $registry->add(widget => 'adsense', 
                   template => 'adsense.html',
                  );
    $registry->add(preference => $self->show_adsense);
}

sub show_adsense {
    my $p = $self->new_preference('show_adsense');
    $p->query('Show Google AdSense Ads?');
    $p->default(1);
    return $p;
}

__DATA__

=head1 NAME

Kwiki::AdSense - Google AdSense Plugin For Kwiki

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
__config/adsense.yaml__
adsense_client: pub-7894611526988241
adsense_width: 120
adsense_height: 600
adsense_format: 120x600_as
adsense_channel:
adsense_type: text
adsense_color_border: 336699
adsense_color_bg: FFFFFF
adsense_color_link: 0000FF
adsense_color_url: 000000
adsense_color_text: 000000
__template/tt2/adsense.html__
[% IF hub.users.current.preferences.show_adsense.value %]
<script type="text/javascript"><!--
google_ad_client = "[% adsense_client %]";
google_ad_width = [% adsense_width %];
google_ad_height = [% adsense_height %];
google_ad_format = "[% adsense_format %]";
google_ad_channel ="[% adsense_channel %]";
google_ad_type = "[% adsense_type %]";
google_color_border = "[% adsense_color_border %]";
google_color_bg = "[% adsense_color_bg %]";
google_color_link = "[% adsense_color_link %]";
google_color_url = "[% adsense_color_url %]";
google_color_text = "[% adsense_color_text %]";
//--></script>
<script type="text/javascript"
  src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
</script>
[% END %]
