
package Microsoft::Teams::WebHook 1.01;

use v5.26;
use warnings;
use Object::Pad;

# ABSTRACT: Microsoft Teams WebHook with AdaptiveCards for formatting notifications

=encoding utf-8

=head1 SYNOPSIS

Sample usage to post notifications using Microsoft::Teams::WebHook

=head1 DESCRIPTION

Microsoft::Teams::WebHook

Set of helpers to send plain or AdaptiveCard notifications

=head1 Constructor attributes

=head2 url [required]

The backend C<url> for your Teams webhook

=head2 json [optional]

This is optional and allow you to provide an alternate JSON object
to format the output sent to post queries.

One JSON::MaybeXS with the flavor of your choice.
By default C<utf8 = 0, pretty = 1>.

=head2 auto_detect_utf8 [default=true] [optional]

You can provide a boolean to automatically try to detect utf8 strings
and enable the utf8 flag.

This is on by default but you can disable it by using

    my $hook = Slack::WebHook->new( ..., auto_detect_utf8 => 0 );

=cut

class Microsoft::Teams::WebHook {

  use DateTime;
  use DateTime::Format::Human::Duration;
  use Encode;
  use HTTP::Tiny;
  use JSON::XS;

  field $url : param;
  field $json : param             = undef;
  field $auto_detect_utf8 : param = 1;

  field $ua;
  field $started_at;

  ADJUST {
    $ua = HTTP::Tiny->new(
      default_headers => {
        'Content-Type' => 'application/json; charset=UTF-8'
      }
    );

    $json = JSON::XS->new->utf8(0)->pretty(1) unless (defined($json));
  }

#<<V perltidy can't handle Object::Pad's lexical methods
  method $http_post($data) {
    return $ua->post($url, {content => $json->encode($data)})
  }
#>>V

  sub encode_text_values ($data) {
    foreach my $field (qw{text title append}) {
      if (defined($data->{$field})) {
        Encode::_utf8_on($data->{$field})
          unless (Encode::is_utf8($data->{$field}));
      }
    }
  }

  sub merge_tpl (%params) {
    my $body = [
      map +{
        type  => 'TextBlock',
        text  => $_,
        wrap  => 1,
        color => $params{text_color}
      },
      ref($params{text}) eq 'ARRAY' ? $params{text}->@* : $params{text}
    ];

    if (defined($params{title})) {
      unshift(
        $body->@*, {
          type   => 'TextBlock',
          text   => $params{title},
          weight => 'bolder',
          size   => 'medium',
          wrap   => 1,
          style  => 'heading'
        }
      );
    }

    if (defined($params{append})) {
      push(
        $body->@*, {
          type    => 'RichTextBlock',
          inlines => [
            {
              type   => 'TextRun',
              text   => $params{append},
              italic => 1,
            }
          ]
        }
      );
    }

    return {
      type        => 'message',
      attachments => [
        {
          contentType => "application/vnd.microsoft.card.adaptive",
          contentUrl  => undef,
          content     => {
            '$schema' => 'http://adaptivecards.io/schemas/adaptive-card.json',
            type      => 'AdaptiveCard',
            version   => '1.5',
            msteams   => {
              width => 'Full'
            },
            body => $body
          }
        }
      ]
    };
  }

  method post ($message) {
    my $params = ref($message) eq 'HASH' ? $message : {text => $message};
    encode_text_values($params) if ($auto_detect_utf8);
    $self->$http_post($params);
  }

#<<V perltidy can't handle Object::Pad's lexical methods
  method $get_params(@params) {
    my %p = (@params == 1) ? (text => $params[0]) : @params;
    encode_text_values(\%p) if($auto_detect_utf8);
    return %p;
  }
#>>V

  method post_msg ($message, @list) {
    my %params = $self->$get_params($message, @list);
    $self->$http_post(merge_tpl(%params));
  }

  method post_ok ($message, @list) {
    my %params = $self->$get_params($message, @list);
    $params{text_color} = 'good' unless (exists($params{text_color}));
    $self->$http_post(merge_tpl(%params));
  }

  method post_warning ($message, @list) {
    my %params = $self->$get_params($message, @list);
    $params{text_color} = 'warning';
    $self->$http_post(merge_tpl(%params));
  }

  method post_info ($message, @list) {
    my %params = $self->$get_params($message, @list);
    $params{text_color} = 'accent';
    $self->$http_post(merge_tpl(%params));
  }

  method post_error ($message, @list) {
    my %params = $self->$get_params($message, @list);
    $params{text_color} = 'attention';
    $self->$http_post(merge_tpl(%params));
  }

  method post_start ($message, @list) {
    $started_at = DateTime->now();
    $self->post_info($message, @list);
  }

  method post_end ($message, @list) {
    my %params = $self->$get_params($message, @list);
    my %append;
    if (defined($started_at)) {
      my $dur = DateTime->now() - $started_at;
      %append     = (append => 'run time: ' . DateTime::Format::Human::Duration->new()->format_duration($dur));
      $started_at = undef;
    }
    $self->post_ok(%params, %append);
  }

}

=head1 METHODS

=head2 new( [url => "https://..." ] )

This is the constructor for L<Microsoft::Teams::WebHook>. You should provide the C<url> for your webhook.
You should visit the L<official Microsoft documentation page|https://learn.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/how-to/add-incoming-webhook?tabs=dotnet>
for information on how to create this URL.

=head2 post( $message )

The L<post> method allows you to post a single message without applying any formatting.
The return value is the return of L<HTTP::Tiny::post> which is one C<Hash Ref>.
The C<success> field will be true if the status code is 2xx.

The other C<post_*> methods format the message contents in L<AdaptiveCards|https://learn.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/how-to/connectors-using?tabs=cURL#send-adaptive-cards-using-an-incoming-webhook>
whereas this method allows you to send a simple, unformatted plaintext message 
or provide a C<HashRef> structure (which will be converted to a JSON string) for
custom C<AdaptiveCards>.

=head2 post_ok( $message, [ @list ])

Post a message to the Teams WebHook URL. There are two methods of calling a C<post_*> method.

You may either pass a simple string argument to the function

    Microsoft::Teams::WebHook->new(url => ...)->post_ok( q{posting a simple "ok" text} );

or you can pass a hash (not a hashref!) with a required C<text> key

    Microsoft::Teams::WebHook->new(url => ...)->post_ok(text => q{your notification message});

Using the latter form, you may also optionally add C<title> and C<text_color> (for C<post_ok> only!) keys
to set those additional parameters in the resulting AdaptiveCard. If C<text_color> is specified,
it must be one of the allowed AdaptiveCard colors (see L<documentation|https://adaptivecards.io/explorer/TextRun.html>) 
which as of this writing are: C<default>, C<dark>, C<light>, C<accent>, C<good>, C<warning>, and C<attention>.

    Microsoft::Teams::WebHook->new(url => ...)->post_ok(
      title      => q{YOUR NOTIFICATION TITLE},
      text       => q{your notification message},
      text_color => 'light'
    );

C<post_ok> defaults to C<good> text color if none is given.

The return value of the C<post_*> method is one L<HTTP::Tiny> response, a C<HashRef>
containing the C<success> field, which is true on success.

=head2 post_warning( $message, [ @list ])

Similar to L<post_ok>, but the color used to display the message is C<warning> and
cannot be overridden.

=head2 post_info( $message, [ @list ])

Similar to L<post_ok>, but the color used to display the message is C<accent> and
cannot be overridden.

=head2 post_error( $message, [ @list ])

Similar to L<post_ok>, but the color used to display the message is C<attention> and
cannot be overridden.

=head2 post_start( $message, [ @list ])

Similar to L<post_ok>, but the color used to display the message is C<accent> and
cannot be overridden. Additionally, this method starts a timer, which is used by 
L<post_end>.

=head2 post_warning( $message, [ @list ])

Similar to L<post_ok>, but the default color used to display the message is C<good>. 
An additional italicized, C<default>-colored line is appended to the AdaptiveCard
which displays a human-readable format of the elapsed time since C<post_start>
was called.

If C<post_start> was not previously called (or not called since the last C<post_end>)
the timer is considered to have no value and the elapsed time section will not 
be added.

=head1 CREDITS

This module is heavily based on the excellent work done on L<Slack::WebHook> 
(and as such intended to be largely drop-in compatible)

=head1 AUTHOR

Mark Tyrrell C<< <mark@tyrrminal.dev> >>

=head1 LICENSE

Copyright (c) 2024 Mark Tyrrell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

1;

__END__
