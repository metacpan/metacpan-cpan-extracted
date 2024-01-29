package GDPR::IAB::TCFv2::Constants::Purpose;
use strict;
use warnings;

require Exporter;
use base qw<Exporter>;

use constant {
    InfoStorageAccess        => 1,
    BasicAdserving           => 2,
    PersonalizationProfile   => 3,
    PersonalizationSelection => 4,
    ContentProfile           => 5,
    ContentSelection         => 6,
    AdPerformance            => 7,
    ContentPerformance       => 8,
    MarketResearch           => 9,
    DevelopImprove           => 10,
    SelectContent            => 11,
};

use constant PurposeDescription => {
    InfoStorageAccess        => "Store and/or access information on a device",
    BasicAdserving           => "Use limited data to select advertising",
    PersonalizationProfile   => "Create profiles for personalised advertising",
    PersonalizationSelection =>
      "Use profiles to select personalised advertising",
    ContentProfile     => "Create profiles to personalise content",
    ContentSelection   => "Use profiles to select personalised content",
    AdPerformance      => "Measure advertising performance",
    ContentPerformance => "Measure content performance",
    MarketResearch     =>
      "Understand audiences through statistics or combinations of data from different sources",
    DevelopImprove => "Develop and improve services",
    SelectContent  => "Use limited data to select content",
};

our @EXPORT_OK = qw<
  InfoStorageAccess
  BasicAdserving
  PersonalizationProfile
  PersonalizationSelection
  ContentProfile
  ContentSelection
  AdPerformance
  ContentPerformance
  MarketResearch
  DevelopImprove
  SelectContent
  PurposeDescription
>;
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

1;

__END__
=head1 NAME

GDPR::IAB::TCFv2::Constants::Purpose - TCF v2.2 purposes

=head1 SYNOPSIS

    use strict;
    use warnings;
    
    use GDPR::IAB::TCFv2::Constants::Purpose qw<:all>;

    use feature 'say';
    
    say "Purpose id is ", InfoStorageAccess , ", and it means " . PurposeDescription->{InfoStorageAccess};
    # Output:
    # Purpose id is 1, and it means Store and/or access information on a device

=head1 CONSTANTS

All constants are integers.

To find the description of a given id you can use the hashref L</PurposeDescription>

=head2  InfoStorageAccess

Purpose id 1: Store and/or access information on a device.

Cookies, device or similar online identifiers (e.g. login-based identifiers, randomly assigned identifiers, network 
based identifiers) together with other information (e.g. browser type and information, language, screen size, supported 
technologies etc.) can be stored or read on your device to recognise it each time it connects to an app or to a 
website, for one or several of the purposes presented here.

Illustrations:

=over

=item *

Most purposes explained in this notice rely on the storage or accessing of information from your device when you use 
an app or visit a website. For example, a vendor or publisher might need to store a cookie on your device during your 
first visit on a website, to be able to recognise your device during your next visits (by accessing this cookie each 
time).

=back

=head2  BasicAdserving

Purpose id 2: Use limited data to select advertising

Advertising presented to you on this service can be based on limited data, such as the website or app you are using, your non-precise location, your device type or which content you are (or have been) interacting with (for example, to limit the number of times an ad is presented to you).

Illustrations:

=over

=item *

A car manufacturer wants to promote its electric vehicles to environmentally conscious users living in the city after office hours. The advertising is presented on a page with related content (such as an article on climate change actions) after 6:30 p.m. to users whose non-precise location suggests that they are in an urban zone.

=item *

A large producer of watercolour paints wants to carry out an online advertising campaign for its latest watercolour range, diversifying its audience to reach as many amateur and professional artists as possible and avoiding showing the ad next to mismatched content (for instance, articles about how to paint your house). The number of times that the ad has been presented to you is detected and limited, to avoid presenting it too often.

=back

=head2  PersonalizationProfile

Purpose id 3: Create profiles for personalised advertising

Information about your activity on this service (such as forms you submit, content you look at) can be stored and combined with other information about you (for example, information from your previous activity on this service and other websites or apps) or similar users. This is then used to build or improve a profile about you (that might include possible interests and personal aspects). Your profile can be used (also later) to present advertising that appears more relevant based on your possible interests by this and other entities.

Illustrations:

=over

=item *

If you read several articles about the best bike accessories to buy, this information could be used to create a profile about your interest in bike accessories. Such a profile may be used or improved later on, on the same or a different website or app to present you with advertising for a particular bike accessory brand. If you also look at a configurator for a vehicle on a luxury car manufacturer website, this information could be combined with your interest in bikes to refine your profile and make an assumption that you are interested in luxury cycling gear.

=item *

An apparel company wishes to promote its new line of high-end baby clothes. It gets in touch with an agency that has a network of clients with high income customers (such as high-end supermarkets) and asks the agency to create profiles of young parents or couples who can be assumed to be wealthy and to have a new child, so that these can later be used to present advertising within partner apps based on those profiles.

=back

=head2  PersonalizationSelection

Purpose id 4: Use profiles to select personalised advertising 

Advertising presented to you on this service can be based on your advertising profiles, which can reflect your activity on this service or other websites or apps (like the forms you submit, content you look at), possible interests and personal aspects.

Illustrations:

=over

=item *

An online retailer wants to advertise a limited sale on running shoes. It wants to target advertising to users who previously looked at running shoes on its mobile app. Tracking technologies might be used to recognise that you have previously used the mobile app to consult running shoes, in order to present you with the corresponding advertisement on the app.

=item *

A profile created for personalised advertising in relation to a person having searched for bike accessories on a website can be used to present the relevant advertisement for bike accessories on a mobile app of another organisation.

=back

=head2  ContentProfile
	
Purpose id 5: Create profiles to personalise content

Information about your activity on this service (for instance, forms you submit, non-advertising content you look at) can be stored and combined with other information about you (such as your previous activity on this service or other websites or apps) or similar users. This is then used to build or improve a profile about you (which might for example include possible interests and personal aspects). Your profile can be used (also later) to present content that appears more relevant based on your possible interests, such as by adapting the order in which content is shown to you, so that it is even easier for you to find content that matches your interests.

Illustrations:

=over

=item *

You read several articles on how to build a treehouse on a social media platform. This information might be added to a profile to mark your interest in content related to outdoors as well as do-it-yourself guides (with the objective of allowing the personalisation of content, so that for example you are presented with more blog posts and articles on treehouses and wood cabins in the future).

=item *

You have viewed three videos on space exploration across different TV apps. An unrelated news platform with which you have had no contact builds a profile based on that viewing behaviour, marking space exploration as a topic of possible interest for other videos.

=back

=head2  ContentSelection
	
Purpose id 6: Use profiles to select personalised content

Content presented to you on this service can be based on your content personalisation profiles, which can reflect your activity on this or other services (for instance, the forms you submit, content you look at), possible interests and personal aspects, such as by adapting the order in which content is shown to you, so that it is even easier for you to find (non-advertising) content that matches your interests.

Illustrations:

=over

=item *

You read articles on vegetarian food on a social media platform and then use the cooking app of an unrelated company. The profile built about you on the social media platform will be used to present you vegetarian recipes on the welcome screen of the cooking app.

=item* 

You have viewed three videos about rowing across different websites. An unrelated video sharing platform will recommend five other videos on rowing that may be of interest to you when you use your TV app, based on a profile built about you when you visited those different websites to watch online videos.

=back

=head2  AdPerformance

Purpose id 7: Measure advertising performance

Information regarding which advertising is presented to you and how you interact with it can be used to determine how well an advert has worked for you or other users and whether the goals of the advertising were reached. For instance, whether you saw an ad, whether you clicked on it, whether it led you to buy a product or visit a website, etc. This is very helpful to understand the relevance of advertising campaigns.

Illustrations:

=over

=item *

You have clicked on an advertisement about a "black Friday" discount by an online shop on the website of a publisher and purchased a product. Your click will be linked to this purchase. Your interaction and that of other users will be measured to know how many clicks on the ad led to a purchase.

=item *

You are one of very few to have clicked on an advertisement about an "international appreciation day" discount by an online gift shop within the app of a publisher. The publisher wants to have reports to understand how often a specific ad placement within the app, and notably the "international appreciation day" ad, has been viewed or clicked by you and other users, in order to help the publisher and its partners (such as agencies) optimise ad placements

=back

=head2  ContentPerformance

Purpose id 8: Measure content performance

Information regarding which content is presented to you and how you interact with it can be used to determine whether the (non-advertising) content e.g. reached its intended audience and matched your interests. For instance, whether you read an article, watch a video, listen to a podcast or look at a product description, how long you spent on this service and the web pages you visit etc. This is very helpful to understand the relevance of (non-advertising) content that is shown to you.

Illustrations:

=over

=item *

You have read a blog post about hiking on a mobile app of a publisher and followed a link to a recommended and related post. Your interactions will be recorded as showing that the initial hiking post was useful to you and that it was successful in interesting you in the related post. This will be measured to know whether to produce more posts on hiking in the future and where to place them on the home screen of the mobile app.

=item *

You were presented a video on fashion trends, but you and several other users stopped watching after 30 seconds. This information is then used to evaluate the right length of future videos on fashion trends

=back

=head2  MarketResearch

Purpose id 9: Understand audiences through statistics or combinations of data from different sources

Reports can be generated based on the combination of data sets (like user profiles, statistics, market research, analytics data) regarding your interactions and those of other users with advertising or (non-advertising) content to identify common characteristics (for instance, to determine which target audiences are more receptive to an ad campaign or to certain contents).

Illustrations:

=over

=item *

The owner of an online bookstore wants commercial reporting showing the proportion of visitors who consulted and left its site without buying, or consulted and bought the last celebrity autobiography of the month, as well as the average age and the male/female distribution of each category. Data relating to your navigation on its site and to your personal characteristics is then used and combined with other such data to produce these statistics.

=item *

An advertiser wants to better understand the type of audience interacting with its adverts. It calls upon a research institute to compare the characteristics of users who interacted with the ad with typical attributes of users of similar platforms, across different devices. This comparison reveals to the advertiser that its ad audience is mainly accessing the adverts through mobile devices and is likely in the 45-60 age range.

=back

=head2  DevelopImprove

Purpose id 10: Develop and improve services

Information about your activity on this service, such as your interaction with ads or content, can be very helpful to improve products and services and to build new products and services based on user interactions, the type of audience, etc. This specific purpose does not include the development or improvement of user profiles and identifiers.

Illustrations:

=over

=item *

A technology platform working withA technology platform working with a social media provider notices a growth in mobile app users, and sees based on their profiles that many of them are connecting through mobile connections. It uses a new technology to deliver ads that are formatted for mobile devices and that are low-bandwidth, to improve their performance. a social media provider notices a growth in mobile app users, and sees based on their profiles that many of them are connecting through mobile connections. It uses a new technology to deliver ads that are formatted for mobile devices and that are low-bandwidth, to improve their performance.

=item *

An advertiser is looking for a way to display ads on a new type of consumer device. It collects information regarding the way users interact with this new kind of device to determine whether it can build a new mechanism for displaying advertising on this type of device.

=back

=head2  SelectContent

Purpose id 11: Use limited data to select content.

Content presented to you on this service can be based on limited data, such as the website or app you are using, your non-precise location, your device type, or which content you are (or have been) interacting with (for example, to limit the number of times a video or an article is presented to you).

Illustrations:

=over

=item *

A travel magazine has published an article on its website about the new online courses proposed by a language school, to improve travelling experiences abroad. The school's blog posts are inserted directly at the bottom of the page, and selected on the basis of your non-precise location (for instance, blog posts explaining the course curriculum for different languages than the language of the country you are situated in).

=item *

A sports news mobile app has started a new section of articles covering the most recent football games. Each article includes videos hosted by a separate streaming platform showcasing the highlights of each match. If you fast-forward a video, this information may be used to select a shorter video to play next.

=back

=head2 PurposeDescription

Returns a hashref with a mapping between all purpose ids and their description.
