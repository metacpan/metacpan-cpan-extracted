package Kwiki::Technorati;
use Kwiki::Plugin '-Base';
use Kwiki::Installer '-base';

const class_id             => 'technorati';
const class_title          => 'Technorati';
const technorati_base_url  => 'http://api.technorati.com/cosmos';
const default_cache_expire => '1 h';
const no_key_error         => { error => 'No technorati key' };
const config_file          => 'technorati.yaml';

our $VERSION = '0.04';

sub register {
    my $registry = shift;
    $registry->add(prequisite => 'fetchrss');
    $registry->add(wafl => technorati => 'Kwiki::TechnoratiPhrase::Wafl');
}

# XXX technorati comes with lots of repeats
sub clean_cosmos {
   my $cosmos = shift;
   return unless exists($cosmos->{items});
   my $items = $cosmos->{items};
   my %seen;
   my $newitems;
   foreach my $item (@$items) {
       next if $seen{$item->{link}};
       $seen{$item->{link}} = 1;
       push(@$newitems, $item);
   }
   $cosmos->{items} = $newitems;
}

sub get_technorati_cosmos {
    my $search_url = CGI::escape(shift);

    my $technorati_key = $self->hub->config->technorati_key;

    return $self->no_key_error unless $technorati_key;

    my $techno_url = $self->technorati_base_url . '?' .
        "key=$technorati_key&url=$search_url&type=link&format=rss&limit=10";

    $self->hub->fetchrss->timeout($self->hub->config->technorati_timeout);
    $self->hub->fetchrss->get_rss($techno_url, $self->default_cache_expire);
}
    
##########################################################################
package Kwiki::TechnoratiPhrase::Wafl;
use base 'Spoon::Formatter::WaflPhrase';
use Spoon::Formatter;

sub html {
    my $url = $self->arguments;
    my $cosmos = $self->hub->technorati->get_technorati_cosmos($url, 1);
    $self->hub->technorati->clean_cosmos($cosmos);
    $self->hub->template->process('fetchrss.html', full => 1, %$cosmos);
}

package Kwiki::Technorati;

1;

__DATA__

=head1 NAME

Kwiki::Technorati - Wafl Phrase for including Technorati Cosmos in a Kwiki Page

=head1 DESCRIPTION

  {technorati <query url>}

Kwiki::Technorati uses Kwiki::FetchRSS to retrieve the Technorati cosmos
for the given url. The cosmos provides a list of other web pages that 
have recently mentioned the website at the url.

To use this wafl, you must have technorati_key set in your config.yaml.
You can obtain a key from L<http://www.technorati.com/>

You can see Kwiki::Technorati in action at L<http://www.burningchrome.com/wiki/>

This code needs some feedback to find its way in life.

=head1 AUTHORS

Adina Levin

Chris Dent, E<lt>cdent@burningchrome.comE<gt>

=head1 SEE ALSO

L<Kwiki>
L<Kwiki::FetchRSS>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005, Socialtext, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__config/technorati.yaml__
technorati_key:
technorati_timeout: 60
