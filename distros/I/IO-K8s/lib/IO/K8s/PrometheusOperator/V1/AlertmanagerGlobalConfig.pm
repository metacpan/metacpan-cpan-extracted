package IO::K8s::PrometheusOperator::V1::AlertmanagerGlobalConfig;
# ABSTRACT: global defines the global parameters of the Alertmanager configuration.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s httpConfig     => '+IO::K8s::PrometheusOperator::V1::HTTPConfigWithProxy';
k8s jira           => '+IO::K8s::PrometheusOperator::V1::GlobalJiraConfig';
k8s mattermost     => '+IO::K8s::PrometheusOperator::V1::GlobalMattermostConfig';
k8s opsGenieApiKey => 'Core::V1::ConfigMapKeySelector';
k8s opsGenieApiUrl => 'Core::V1::ConfigMapKeySelector';
k8s pagerdutyUrl   => Str, { pattern => qr/^(http|https):\/\/.+$/ };
k8s resolveTimeout => Str, { pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/ };
k8s rocketChat     => '+IO::K8s::PrometheusOperator::V1::GlobalRocketChatConfig';
k8s slackApiUrl    => 'Core::V1::ConfigMapKeySelector';
k8s smtp           => '+IO::K8s::PrometheusOperator::V1::GlobalSMTPConfig';
k8s telegram       => '+IO::K8s::PrometheusOperator::V1::GlobalTelegramConfig';
k8s victorops      => '+IO::K8s::PrometheusOperator::V1::GlobalVictorOpsConfig';
k8s webex          => '+IO::K8s::PrometheusOperator::V1::GlobalWebexConfig';
k8s wechat         => '+IO::K8s::PrometheusOperator::V1::GlobalWeChatConfig';















1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::AlertmanagerGlobalConfig - global defines the global parameters of the Alertmanager configuration.

=head1 VERSION

version 1.108

=head2 httpConfig

httpConfig defines the default HTTP configuration.

=head2 jira

jira defines the default configuration for Jira.

=head2 mattermost

mattermost defines the default Mattermost Config

=head2 opsGenieApiKey

opsGenieApiKey defines the default OpsGenie API Key.

=head2 opsGenieApiUrl

opsGenieApiUrl defines the default OpsGenie API URL.

=head2 pagerdutyUrl

pagerdutyUrl defines the default Pagerduty URL.

=head2 resolveTimeout

resolveTimeout defines the default value used by alertmanager if the alert does
not include EndsAt, after this time passes it can declare the alert as resolved if it has not been updated.
This has no impact on alerts from Prometheus, as they always include EndsAt.

=head2 rocketChat

rocketChat defines the default configuration for Rocket Chat.

=head2 slackApiUrl

slackApiUrl defines the default Slack API URL.

=head2 smtp

smtp defines global SMTP parameters.

=head2 telegram

telegram defines the default Telegram config

=head2 victorops

victorops defines the default configuration for VictorOps.

=head2 webex

webex defines the default configuration for Webex.

=head2 wechat

wechat defines the default WeChat Config

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <getty@cpan.org>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
