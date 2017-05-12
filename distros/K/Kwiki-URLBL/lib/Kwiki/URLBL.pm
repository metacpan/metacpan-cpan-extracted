package Kwiki::URLBL;

use strict;
use vars qw($VERSION);
$VERSION = '0.02';

use Kwiki::Plugin -Base;
use Kwiki::Installer -base;

our $VERSION = '0.05';

const class_id    => 'urlbl';
const class_title => 'URL Blacklist DNS';
const config_file => 'urlbl.yaml';

sub register {
    require URI::Find;
    my $registry = shift;
    $registry->add(hook => 'edit:save', pre => 'urlbl_hook');
    $registry->add(action => 'blacklisted_url');
}

sub urlbl_hook {
    my $hook = pop;
    my $old_page = $self->hub->pages->new_page($self->pages->current->id);
    my $this     = $self->hub->urlbl;
    my @old_urls = $this->get_urls($old_page->content);
    my @urls     = $this->get_urls($self->cgi->page_content);
    my @new_urls = $this->get_new_urls(\@old_urls, \@urls);
    if (@new_urls && $this->is_blocked(\@new_urls)) {
        $hook->cancel();
        return $self->redirect("action=blacklisted_url");
    }
}

sub get_urls {
    require URI::Find;
    my ($content) = @_;
    my @list;
    my $finder = URI::Find->new( sub {
        my($uri, $orig_uri) = @_;
        push @list, $uri;
        return $orig_uri;
    });
    $finder->find(\$content);
    return @list;
}

sub get_new_urls {
    my ($old_urls, $urls) = @_;
    my @new_urls;
    my %old = map { $_ => 1 } @$old_urls;
    foreach my $url (@$urls) {
        push @new_urls, $url unless $old{$url};
    }
    return @new_urls;
}

sub is_blocked {
    require Net::DNS::Resolver;
    my ($new_urls) = @_;
    my @dnsbl = split /,\s*/, $self->config->urlbl_dns;
    my $res   = Net::DNS::Resolver->new;
    for my $url (@$new_urls) {
        my $uri = URI->new($url);
        my $domain = $uri->host;
        $domain =~ s/^www\.//;
        for my $dns (@dnsbl) {
            warn "looking up $domain.$dns";
            my $q = $res->search("$domain.$dns");
            return 1 if $q && $q->answer;
        }
    }
    return;
}

sub blacklisted_url {
    return $self->render_screen(
        content_pane => 'blacklisted_url.html',
    );
}

1;
__DATA__

=head1 NAME

Kwiki::URLBL - Block edit based on added URLs by checking URL DNSBL

=head1 SYNOPSIS

  > echo Kwiki::URLBL >> plugins
  > kwiki -update

=head1 DESCRIPTION

Kwiki::URLBL is a Kwiki Plugin to block Wiki edit based on added URLs by cheking URL based DNS Blacklists like L<http://www.surbl.org/>, L<http://bsb.empty.us/> and L<http://bulkfeeds.net/app/blacklist>.

=head1 CONFIGURATION

You can manually list URLBL DNS services in C<config.yaml> file:

  urlbl_dns: sc.surbl.org, bsb.spamlookup.net, rbl.bulkfeeds.jp

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@gmail.comE<gt>

Most of the code is taken from L<Kwiki::URLBlock> by Jon Asulud.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Kwiki::URLBlock>, L<Kwiki::DNSBL>

=cut

__template/tt2/blacklisted_url.html__
<div class="error">
<p>You were blocked from editing because your edit contains Blacklisted URLs.</p>
</div>
__config/urlbl.yaml__
urlbl_dns: sc.surbl.org, bsb.spamlookup.net, rbl.bulkfeeds.jp
