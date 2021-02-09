#!/usr/bin/perl
#===========================================================================
#  push.cgi
#
#  This is a perl CGI script to show the web push notifications
#  feature. 
#
#  Usage:
#    [USER END]
#    On a modern web browser:
#    Connect to https://whatever-site-and-path/push.cgi and allow push notifications
#
#    [APP END]
#    From a shell script:
#    Issue the command 'perl push.cgi cmd=send text="Hello world"'
#
#    You can also open push.cgi?cmd=send from a browser, but if it is the same
#    user end browser, you miss some of the magic
#
#  Notes:
#   This is just a minimal setup, only to show the app end part
#
#  Requirements:
#   This script should be run under https in order to comply to
#   the callback components policy of the browser's subscription
#   service
#
#   Copyright 2021 Erich Strelow
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#============================================================================

use strict 'vars';
use warnings;

#You may change this according to your host. The script neede RW access
use constant APP_CONF => 'push.conf';
#This is the app wide authentication key
my $server_key = { public => 'BCAI00zPAbxEVU5w8D1kZXVs2Ro--FmpQNMOd0S0w1_5naTLZTGTYNqIt7d97c2mUDstAWOCXkNKecqgS4jARA8',
   private => 'M6xy5prDBhJNlOGnOkMekyAQnQSWKuJj1cD06SUQTow'};

use CGI;
use Config::IniFiles;
use JSON;
use HTTP::Request::Webpush;
use LWP::UserAgent;
use MIME::Base64 qw( encode_base64url decode_base64url);

my $req=new CGI;

my $cmd=$req->param('cmd') || $req->url_param('cmd');


#=======================================================================================
# Worker JS Script. This gets installed in the UA operating system in order to
# receive push messages
#=======================================================================================
my $worker= <<'EOJ';
// Register event listener for the 'push' event.
self.addEventListener('push', function(event) {
  // Retrieve the textual payload from event.data (a PushMessageData object).
  // Other formats are supported (ArrayBuffer, Blob, JSON), check out the documentation
  // on https://developer.mozilla.org/en-US/docs/Web/API/PushMessageData.
  const payload = event.data ? event.data.text() : 'no payload';

  // Keep the service worker alive until the notification is created.
  event.waitUntil(
    self.registration.showNotification('HTTP::Request::Webpush example', {
      body: payload,
    })
  );
});
EOJ


#=======================================================================================
# Subscription  HTML/JS Script. This is the end user HTML page that
# launches the subcription the first time
#=======================================================================================
sub renderpush {

   my $path=$req->url();
   my $cmd=$req->url(-relative => 1);
   my $worker = "$path?cmd=service-worker.js";
   my $subscribe= "$path?cmd=subscribe";

   print <<"EOH";
<div class='push'>
<a href="#" onclick='return subscribe()'>Activate push notifications</a>
<script type='text/javascript'>
function isSupported() {
  if (!('serviceWorker' in navigator)) {
    // Service Worker isn't supported on this browser, disable or hide UI.
    return false;
  }

  if (!('PushManager' in window)) {
    // Push isn't supported on this browser, disable or hide UI.
    return false;
  }

  return true;
}

// Web-Push
// Public base64 to Uint
function urlBase64ToUint8Array(base64String) {
    var padding = '='.repeat((4 - base64String.length % 4) % 4);
    var base64 = (base64String + padding)
        .replace(/\-/g, '+')
        .replace(/_/g, '/');

    var rawData = window.atob(base64);
    var outputArray = new Uint8Array(rawData.length);

    for (var i = 0; i < rawData.length; ++i) {
        outputArray[i] = rawData.charCodeAt(i);
    }
    return outputArray;
}

async function subscribe() {
  const result = await Notification.requestPermission();
  if (result == 'granted') {
    var r=await navigator.serviceWorker.register('$worker');
    var m=r.pushManager;
    const subscribeOptions = {
       userVisibleOnly: true,
       applicationServerKey: urlBase64ToUint8Array(
        '$server_key->{public}'
      )
    };

    var s= await m.subscribe(subscribeOptions); 
    var w=fetch('$subscribe', {
       method: 'POST',
       headers: {
         'Content-Type': 'application/json'
       },
       body: JSON.stringify(s)
        });
    }

   return true;
}
</script>

EOH
}

sub subscribe($) {

   my $opt=shift();
   my $conf=Config::IniFiles->new(-file => APP_CONF, -nocase => 1);
   die "Configuration fail" unless ($conf);
   $conf->newval('subscription','data',$opt);
   $conf->RewriteConfig;
   my $success='{ "data": { "success": "true" } }';
   print $req->header(-type => 'application/json', -Content_length => length($success));


}

sub postpush($$) {

   my $session=shift();
   my $text=shift();

   my $conf=Config::IniFiles->new(-file => APP_CONF, -nocase => 1);
   die "Configuration fail" unless($conf);
   my $json=$conf->val($session,'data');
   my $keys=from_json($json);

   my $send=HTTP::Request::Webpush->new(subscription => $keys);
   $send->authbase64($server_key->{public}, $server_key->{private});
   $send->content($text);
   $send->subject('mailto:estrelow@cpan.org');
   $send->encode();
   $send->header('TTL' => '90');

   my $ua = LWP::UserAgent->new;
   my $response = $ua->request($send);
   print $req->header("text/plain");

   print "Message sent\n";
   print $response->code();
   print "\n";
   print $response->decoded_content;
   print $response->header('Location');
   print "\n";
   print $response->header('Link');

}


if ($cmd eq 'service-worker.js') {
   print $req->header(-type       => 'application/javascript', -Content_length => length($worker));
   print $worker;
} elsif ($cmd eq 'subscribe') {
   subscribe($req->param('POSTDATA'));
}  elsif ($cmd eq 'send') {
   my $text= $req->param('text') || 'Hello world';
   postpush('subscription',$text);

}   else {
   print $req->header('text/html');
   renderpush;
}

