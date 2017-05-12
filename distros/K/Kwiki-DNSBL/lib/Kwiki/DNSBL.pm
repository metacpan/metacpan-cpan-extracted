package Kwiki::DNSBL;
use Kwiki::Plugin '-Base';
use Kwiki::Installer '-base';
use Net::DNSBLLookup;

const class_id             => 'dnsbl';
const class_title          => 'DNS Blackhole List';
our $VERSION = '0.01';

sub register {
    my $registry = shift;
    $registry->add(hook => 'edit:save', pre => 'dnsbl_hook');
    $registry->add(action => 'blocked_ip');
}

sub dnsbl_hook {
    my $hook = pop;
    my $edit_address = $self->pages->current->metadata->get_edit_address;
    if ($self->hub->dnsbl->check_dnsbl($edit_address)) {
	$hook->cancel();
	return $self->redirect("action=blocked_ip");
    }
}

sub check_dnsbl {
    my ($ip) = @_;
    my $dnsbl = Net::DNSBLLookup->new(timeout => 5);
    my $res = $dnsbl->lookup($ip);
    my ($proxy, $spam, $unknown) = $res->breakdown;
    if ($proxy || $spam || $unknown) {
	return 1;
    } else {
	return 0;
    }
}

sub blocked_ip {
    return $self->render_screen(
        content_pane => 'blocked_ip.html',
    );
}

__DATA__

=head1 NAME

Kwiki::DNSBL - Blocks edit from ip addresses in DNS Blackhole lists

=head1 DESCRIPTION

Much of the current WikiSpam comes from open proxies. This plugin
queries a number of DNS blackhole lists to check if users are using
an open proxy and blocks them if they do.

It uses L<Net::DNSBLLookup> which also queries blackhole lists that
report if an ip address is known to have an open e-mail relay. This
plugin blocks these users anyway, even though WikiSpam has nothing to
do with normal e-mail spam.

=head1 AUTHORS

Jon Aslund <aslund.org>, Jooon at #kwiki on Freenode

=head1 SEE ALSO

L<Kwiki>
L<Net::DNSBLLookup>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005, Jon Aslund

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
__template/tt2/blocked_ip.html__
<div class="error">
<p>You were blocked from editing because your ip address exists in one
or more DNS blackhole lists. These lists contains ip addresses that
are known to have open proxies or relay spam.</p>
</div>
