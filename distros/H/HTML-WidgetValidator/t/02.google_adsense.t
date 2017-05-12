use Test::Base;
use HTML::WidgetValidator;

sub validate {
  my $validateor = HTML::WidgetValidator->new(widgets => [ 'GoogleAdSense' ]);
  my $result  = $validateor->validate(shift);
  return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__

=== Google AdSense 1
--- input
<script type="text/javascript"><!--
google_ad_client = "pub-8519046100076293";
google_ad_width = 200;
google_ad_height = 200;
google_ad_format = "200x200_as";
google_ad_type = "image";
//2007-08-13: test2
google_ad_channel = "7750185192";
google_color_border = "5279E7";
google_color_bg = "FFFFFF";
google_color_link = "000000";
google_color_text = "000000";
google_color_url = "0000FF";
google_ui_features = "rc:6";
//-->
</script>
--- expected
Google AdSense

=== Google AdSense 2
--- input
<script type="text/javascript"
  src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
</script>
--- expected
Google AdSense

===  Google AdSense 3
--- input
<script type="text/javascript"><!--
google_ad_client = "pub-4438296558807254";
google_ad_width = 728;
google_ad_height = 15;
google_ad_format = "728x15_0ads_al_s";
google_cpa_choice = "CAEaCASDASDASjda1";
google_ad_channel = "";
google_color_border = "5279E7";
google_color_bg = "FFFFFF";
google_color_link = "0000FF";
google_color_text = "000000";
google_color_url = "008000";
//-->
</script>
--- expected
Google AdSense
