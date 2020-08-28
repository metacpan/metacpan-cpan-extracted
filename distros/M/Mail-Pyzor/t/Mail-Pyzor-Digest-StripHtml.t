#!/usr/local/cpanel/3rdparty/bin/perl -w

# Copyright 2018 cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# Apache 2.0 license.

package t::Mail::Pyzor::Digest::StripHtml;

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use parent qw( MailPyzorTestBase );

use Test::More;
use Test::FailWarnings;

use Data::Dumper ();
use Encode       ();
use IPC::Run     ();

use Mail::Pyzor::Digest::StripHtml ();

__PACKAGE__->new()->runtests() if !caller;

#----------------------------------------------------------------------

use constant _STRIP_TESTS => [
    [
        'pyzor test',

        # cf. https://github.com/SpamExperts/pyzor/blob/master/tests/unit/test_digest.py
        <<END,

<html><head><title>Email spam</title></head><body>
<p><b>Email spam</b>, also known as <b>junk email</b> 
or <b>unsolicited bulk email</b> (<i>UBE</i>), is a subset of 
<a href="/wiki/Spam_(electronic)" title="Spam (electronic)">electronic spam</a> 
involving nearly identical messages sent to numerous recipients by <a href="/wiki/Email" title="Email">
email</a>. Clicking on <a href="/wiki/Html_email#Security_vulnerabilities" title="Html email" class="mw-redirect">
links in spam email</a> may send users to <a href="/wiki/Phishing" title="Phishing">phishing</a> 
web sites or sites that are hosting <a href="/wiki/Malware" title="Malware">malware</a>.</body></html>

END
    ],
    [
        'pyzor <style> test',
        <<END,
<html><head></head><sTyle>Some random style</stylE>
<body>This is a test.</body></html>
END
    ],
    [
        'pyzor <script> test',
        <<END,
<html><head></head><SCRIPT>Some random script</SCRIPT>
<body>This is a test.</body></html>
END
    ],
    [
        'UTF-8 multi-byte characters',
        '<html><head><title>Email spam</title></head><body>éééé</body></html>',
    ],
    [
        'HTML entities',
        '<td >23&nbsp; é &eacute; &fake; &dagger;45</td>',
    ],
    [
        'trim &',
        '<span>&</span>',
    ],
    [
        'trim inside',
        '<span> 123 </span>',
    ],
    [
        'trim outside',
        ' <span> 123 </span> ',
    ],
    [
        'HTML non-entity',
        '<span>&123;</span>',
    ],
    [
        'HTML non-entity (garble)',
        '<span>&,+;</span>',
    ],
    [
        'HTML entity, missing trailing semicolon',
        '<span>&dagger</span>123',
    ],
    [
        'HTML entity, comma instead of semicolon',
        '<span>&dagger,</span>123',
    ],
    [
        'HTML entity, space instead of semicolon',
        '<span>&dagger </span>123',
    ],
    [
        'incomplete decimal entity nestled to hex word',
        '&#12deadbeef',
    ],
    [
        'fudged numeric entity',
        '&#xzz;',
    ],
    [
        'entity potpourri',
        '&----------------; &#123; &#xabcd; &#xzz; &qwe;',
        todo => 'discrepancy between /usr/bin/python and latest 2.7',
    ],
    [
        'entity potpourri 2',
        '&#123; &#xabcd; &#xzz; &qwe;',
    ],
    [
        'lots of nbsp',
        '| New Account Info&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|',
    ],
    [
        'copyright symbol plus literal nbsp (bytes)',
        "<p style=\"font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;font-size:12px;color:#666666; padding: 0; margin: 0;\">Copyright\302\251\302\2402018 cPanel, Inc.<p>",
    ],
    [
        'copyright symbol plus literal nbsp (characters)',
        Encode::encode( 'utf-8', "<p style=\"font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;font-size:12px;color:#666666; padding: 0; margin: 0;\">Copyright\302\251\302\2402018 cPanel, Inc.<p>" ),
    ],
    [
        'big hunk of HTML, bytes',
        "<body style=\"background:#F4F4F4\">\r\n    <div style=\"margin:0;padding:0;background:#F4F4F4\">\r\n        <table cellpadding=\"10\" cellspacing=\"0\" border=\"0\" width=\"100%\" style=\"width:0 auto;\">\r\n            <tbody>\r\n                <tr>\r\n                    <td align=\"center\">\r\n                        <table cellpadding=\"0\" cellspacing=\"0\" border=\"0\" width=\"680\" style=\"border:0;width:0 auto;max-width:680px;\">\r\n                            <tbody>\r\n                                <tr>\r\n                                                                        <td width=\"680\" height=\"25\" style=\"font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;font-size:16px;color:#333333\">\r\n                                                                                                                                hambone.tld: The AutoSSL certificate expires on Oct 3, 2018 at 10:16:13 PM UTC. At the time of this notice, the certificate will expire in 18 hours, 55 minutes, and 54 seconds.                                                                            </td>\r\n                                                                    </tr>\r\n                                <tr>\r\n                                                                        <td style=\"padding: 15px 0 20px 0; background-color: #FFFFFF; border: 2px solid #E8E8E8; border-bottom: 2px solid #FF6C2C;\">\r\n                                        <table width=\"680\" border=\"0\" cellpadding=\"0\" cellspacing=\"0\" style=\"background:#FFFFFF;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;\">\r\n                                            <tbody>\r\n                                                <tr>\r\n                                                    <td width=\"15\">\r\n                                                    </td>\r\n                                                    <td width=\"650\">\r\n                                                        <table cellpadding=\"0\" cellspacing=\"0\" border=\"0\" width=\"100%\">\r\n                                                            <tbody>\r\n                                                                <tr>\r\n                                                                    <td>\r\n                                                                        \r\n<p>\r\n    AutoSSL did <strong>not</strong> renew the certificate for \342\200\234hambone.tld\342\200\235. <strong>You must take action to keep this site secure.</strong></p>\r\n\r\n<p>The \342\200\234cPanel\342\200\235 AutoSSL provider could <strong>not</strong> renew the SSL certificate without a reduction of coverage because of the following problems:\r\n        <div style=\"margin:10px;border:1px solid #000; \">\r\n            <div style=\"padding:5px;border-bottom:1px solid #000;background-color: #E8E8E8\">\r\n                <strong>\342\233\224 webdisk.hambone.tld</strong>\r\n                <span style=\"font-size:11px\">(checked on Oct 3, 2018 at 3:20:13 AM UTC)</span>\r\n            </div>\r\n            <div><pre style=\"white-space:pre-wrap; margin:5px;\">HTTP DCV: \342\200\234webdisk.hambone.tld\342\200\235 is not a registered internet domain.</pre></div>\r\n        </div>\r\n        <div style=\"margin:10px;border:1px solid #000; \">\r\n            <div style=\"padding:5px;border-bottom:1px solid #000;background-color: #E8E8E8\">\r\n                <strong>\342\233\224 mail.hambone.tld</strong>\r\n                <span style=\"font-size:11px\">(checked on Oct 3, 2018 at 3:20:13 AM UTC)</span>\r\n            </div>\r\n            <div><pre style=\"white-space:pre-wrap; margin:5px;\">HTTP DCV: \342\200\234mail.hambone.tld\342\200\235 is not a registered internet domain.</pre></div>\r\n        </div>\r\n        <div style=\"margin:10px;border:1px solid #000; \">\r\n            <div style=\"padding:5px;border-bottom:1px solid #000;background-color: #E8E8E8\">\r\n                <strong>\342\233\224 hambone.tld</strong>\r\n                <span style=\"font-size:11px\">(checked on Oct 3, 2018 at 3:20:13 AM UTC)</span>\r\n            </div>\r\n            <div><pre style=\"white-space:pre-wrap; margin:5px;\">HTTP DCV: \342\200\234hambone.tld\342\200\235 is not a registered internet domain.</pre></div>\r\n        </div>\r\n        <div style=\"margin:10px;border:1px solid #000; \">\r\n            <div style=\"padding:5px;border-bottom:1px solid #000;background-color: #E8E8E8\">\r\n                <strong>\342\233\224 www.hambone.tld</strong>\r\n                <span style=\"font-size:11px\">(checked on Oct 3, 2018 at 3:20:13 AM UTC)</span>\r\n            </div>\r\n            <div><pre style=\"white-space:pre-wrap; margin:5px;\">HTTP DCV: \342\200\234www.hambone.tld\342\200\235 is not a registered internet domain.</pre></div>\r\n        </div>\r\n        <div style=\"margin:10px;border:1px solid #000; \">\r\n            <div style=\"padding:5px;border-bottom:1px solid #000;background-color: #E8E8E8\">\r\n                <strong>\342\233\224 cpanel.hambone.tld</strong>\r\n                <span style=\"font-size:11px\">(checked on Oct 3, 2018 at 3:20:13 AM UTC)</span>\r\n            </div>\r\n            <div><pre style=\"white-space:pre-wrap; margin:5px;\">HTTP DCV: \342\200\234cpanel.hambone.tld\342\200\235 is not a registered internet domain.</pre></div>\r\n        </div>\r\n        <div style=\"margin:10px;border:1px solid #000; \">\r\n            <div style=\"padding:5px;border-bottom:1px solid #000;background-color: #E8E8E8\">\r\n                <strong>\342\233\224 webmail.hambone.tld</strong>\r\n                <span style=\"font-size:11px\">(checked on Oct 3, 2018 at 3:20:13 AM UTC)</span>\r\n            </div>\r\n            <div><pre style=\"white-space:pre-wrap; margin:5px;\">HTTP DCV: \342\200\234webmail.hambone.tld\342\200\235 is not a registered internet domain.</pre></div>\r\n        </div></p><p>For the most current status, navigate to the \342\200\234<a href=\"https://felipe64.dev.cpanel.net:2083/?goto_app=SSL_TLS_Status\">SSL/TLS Status</a>\342\200\235 interface. You can also exclude domains from future renewal attempts, which would cease future notifications.</p>\r\n\r\n<p>\r\n          The following domains will lose SSL coverage when the certificate expires:    </p>\r\n\r\n<ul>\r\n            <li>\r\n            <a href=\"https://hambone.tld\">hambone.tld</a>\r\n        </li>\r\n            <li>\r\n            <a href=\"https://mail.hambone.tld\">mail.hambone.tld</a>\r\n        </li>\r\n            <li>\r\n            <a href=\"https://www.hambone.tld\">www.hambone.tld</a>\r\n        </li>\r\n    </ul>\r\n\r\nThe certificate that is installed on this website contains the following properties:   <table style=\"\r\n        margin:5px auto;\r\n        border: 1px solid #333333;\r\n        padding:0;\"\r\n        cellpadding=\"0\" cellspacing=\"0\" >\r\n                        <tr style=\"background-color:#FFFFFF;\">\r\n                        <td style=\"\r\n                                font-weight:bold;                font-family: 'Courier New', Courier, monospace;\r\n                padding: 5px;\r\n                                                padding-left:10px;\" >\r\n                Expiration:            </td>\r\n                        <td style=\"\r\n                                font-family: 'Courier New', Courier, monospace;\r\n                padding: 5px;\r\n                                padding-right:10px;                \" >\r\n                Wednesday, October 3, 2018 at 10:16:13 PM UTC            </td>\r\n                    </tr>\r\n                <tr style=\"background-color:#F4F4F4;\">\r\n                        <td style=\"\r\n                                font-weight:bold;                font-family: 'Courier New', Courier, monospace;\r\n                padding: 5px;\r\n                                                padding-left:10px;\" >\r\n                Domain Names:            </td>\r\n                        <td style=\"\r\n                                font-family: 'Courier New', Courier, monospace;\r\n                padding: 5px;\r\n                                padding-right:10px;                \" >\r\n                    <table class=\"domains-list\" style=\"margin-bottom: 0\">\r\n                    <tr>\r\n                <td style=\"padding:3px 3px 3px 0;\">hambone.tld</td>\r\n            </tr>\r\n                    <tr>\r\n                <td style=\"padding:3px 3px 3px 0;\">mail.hambone.tld</td>\r\n            </tr>\r\n                    <tr>\r\n                <td style=\"padding:3px 3px 3px 0;\">www.hambone.tld</td>\r\n            </tr>\r\n            </table>\r\n            </td>\r\n                    </tr>\r\n                <tr style=\"background-color:#FFFFFF;\">\r\n                        <td style=\"\r\n                                font-weight:bold;                font-family: 'Courier New', Courier, monospace;\r\n                padding: 5px;\r\n                                                padding-left:10px;\" >\r\n                Subject:            </td>\r\n                        <td style=\"\r\n                                font-family: 'Courier New', Courier, monospace;\r\n                padding: 5px;\r\n                                padding-right:10px;                \" >\r\n                    <table class=\"distinguished-name\" style=\"margin-bottom: 0\">\r\n                    <tr>\r\n                <td style=\"padding:3px 3px 3px 0;\">commonName</td>\r\n                <td style=\"padding:3px;\">hambone.tld</td>\r\n            </tr>\r\n            </table>\r\n            </td>\r\n                    </tr>\r\n                <tr style=\"background-color:#F4F4F4;\">\r\n                        <td style=\"\r\n                                font-weight:bold;                font-family: 'Courier New', Courier, monospace;\r\n                padding: 5px;\r\n                                                padding-left:10px;\" >\r\n                Issuer:            </td>\r\n                        <td style=\"\r\n                                font-family: 'Courier New', Courier, monospace;\r\n                padding: 5px;\r\n                                padding-right:10px;                \" >\r\n                    <table class=\"distinguished-name\" style=\"margin-bottom: 0\">\r\n                    <tr>\r\n                <td style=\"padding:3px 3px 3px 0;\">commonName</td>\r\n                <td style=\"padding:3px;\">hambone.tld</td>\r\n            </tr>\r\n            </table>\r\n            </td>\r\n                    </tr>\r\n           </table>\r\n\r\n<p></p>\r\n                                                                    </td>\r\n                                                                </tr>\r\n                                                                <tr>\r\n                                                                    <td>\r\n                                                                        <div style=\"font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;border-top: 2px solid #E8E8E8; padding-top:5px; margin-top: 5px; font-size:12px; color: #666666;\">\r\n            <p style=\"padding:0 0 0 0; margin: 5px 0 0 0;\">\r\n        The system generated this notice on Wednesday, October 3, 2018 at 3:20:18 AM UTC.    </p>\r\n</div>                                                                                                                                                 <p>\r\n                                                                                                                                                        You can disable the \342\200\234AutoSSL cannot request a certificate because all of the website\342\200\231s domains have failed DCV (Domain Control Validation).\342\200\235 type of notification through the cPanel interface: <a target=\"_blank\" href=\"https://felipe64.dev.cpanel.net:2083/?goto_app=ContactInfo_Change\">https://felipe64.dev.cpanel.net:2083/?goto_app=ContactInfo_Change</a>                                                                                                                                                    </p>\r\n                                                                        <p>\r\n    Do not reply to this automated message.</p>\r\n                                                                    </td>\r\n                                                                </tr>\r\n                                                            </tbody>\r\n                                                        </table>\r\n\r\n                                                    </td>\r\n                                                    <td width=\"15\">\r\n                                                    </td>\r\n                                                </tr>\r\n                                            </tbody>\r\n                                        </table>\r\n                                    </td>\r\n                                                                    </tr>\r\n                                <tr>\r\n                                    <td align=\"center\" style=\"padding-top: 10px;\">\r\n                                                                            <img src=\"cid:auto_cid_107541364\" height=\"25\" width=\"25\" style=\"border:0;line-height:100%;border:0\" alt=\"cP\">\r\n                                        <p style=\"font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;font-size:12px;color:#666666; padding: 0; margin: 0;\">Copyright\302\251\302\2402018 cPanel, Inc.<p>\r\n                                                                        </td>\r\n                                </tr>\r\n                            </tbody>\r\n                        </table>\r\n                    </td>\r\n                </tr>\r\n            </tbody>\r\n        </table>\r\n    </div>\r\n</body>",
    ],
    [
        'big hunk of HTML, decoded UTF-8',
        Encode::decode(
            'utf-8',
            "<body style=\"background:#F4F4F4\">\r\n    <div style=\"margin:0;padding:0;background:#F4F4F4\">\r\n        <table cellpadding=\"10\" cellspacing=\"0\" border=\"0\" width=\"100%\" style=\"width:0 auto;\">\r\n            <tbody>\r\n                <tr>\r\n                    <td align=\"center\">\r\n                        <table cellpadding=\"0\" cellspacing=\"0\" border=\"0\" width=\"680\" style=\"border:0;width:0 auto;max-width:680px;\">\r\n                            <tbody>\r\n                                <tr>\r\n                                                                        <td width=\"680\" height=\"25\" style=\"font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;font-size:16px;color:#333333\">\r\n                                                                                                                                hambone.tld: The AutoSSL certificate expires on Oct 3, 2018 at 10:16:13 PM UTC. At the time of this notice, the certificate will expire in 18 hours, 55 minutes, and 54 seconds.                                                                            </td>\r\n                                                                    </tr>\r\n                                <tr>\r\n                                                                        <td style=\"padding: 15px 0 20px 0; background-color: #FFFFFF; border: 2px solid #E8E8E8; border-bottom: 2px solid #FF6C2C;\">\r\n                                        <table width=\"680\" border=\"0\" cellpadding=\"0\" cellspacing=\"0\" style=\"background:#FFFFFF;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;\">\r\n                                            <tbody>\r\n                                                <tr>\r\n                                                    <td width=\"15\">\r\n                                                    </td>\r\n                                                    <td width=\"650\">\r\n                                                        <table cellpadding=\"0\" cellspacing=\"0\" border=\"0\" width=\"100%\">\r\n                                                            <tbody>\r\n                                                                <tr>\r\n                                                                    <td>\r\n                                                                        \r\n<p>\r\n    AutoSSL did <strong>not</strong> renew the certificate for \342\200\234hambone.tld\342\200\235. <strong>You must take action to keep this site secure.</strong></p>\r\n\r\n<p>The \342\200\234cPanel\342\200\235 AutoSSL provider could <strong>not</strong> renew the SSL certificate without a reduction of coverage because of the following problems:\r\n        <div style=\"margin:10px;border:1px solid #000; \">\r\n            <div style=\"padding:5px;border-bottom:1px solid #000;background-color: #E8E8E8\">\r\n                <strong>\342\233\224 webdisk.hambone.tld</strong>\r\n                <span style=\"font-size:11px\">(checked on Oct 3, 2018 at 3:20:13 AM UTC)</span>\r\n            </div>\r\n            <div><pre style=\"white-space:pre-wrap; margin:5px;\">HTTP DCV: \342\200\234webdisk.hambone.tld\342\200\235 is not a registered internet domain.</pre></div>\r\n        </div>\r\n        <div style=\"margin:10px;border:1px solid #000; \">\r\n            <div style=\"padding:5px;border-bottom:1px solid #000;background-color: #E8E8E8\">\r\n                <strong>\342\233\224 mail.hambone.tld</strong>\r\n                <span style=\"font-size:11px\">(checked on Oct 3, 2018 at 3:20:13 AM UTC)</span>\r\n            </div>\r\n            <div><pre style=\"white-space:pre-wrap; margin:5px;\">HTTP DCV: \342\200\234mail.hambone.tld\342\200\235 is not a registered internet domain.</pre></div>\r\n        </div>\r\n        <div style=\"margin:10px;border:1px solid #000; \">\r\n            <div style=\"padding:5px;border-bottom:1px solid #000;background-color: #E8E8E8\">\r\n                <strong>\342\233\224 hambone.tld</strong>\r\n                <span style=\"font-size:11px\">(checked on Oct 3, 2018 at 3:20:13 AM UTC)</span>\r\n            </div>\r\n            <div><pre style=\"white-space:pre-wrap; margin:5px;\">HTTP DCV: \342\200\234hambone.tld\342\200\235 is not a registered internet domain.</pre></div>\r\n        </div>\r\n        <div style=\"margin:10px;border:1px solid #000; \">\r\n            <div style=\"padding:5px;border-bottom:1px solid #000;background-color: #E8E8E8\">\r\n                <strong>\342\233\224 www.hambone.tld</strong>\r\n                <span style=\"font-size:11px\">(checked on Oct 3, 2018 at 3:20:13 AM UTC)</span>\r\n            </div>\r\n            <div><pre style=\"white-space:pre-wrap; margin:5px;\">HTTP DCV: \342\200\234www.hambone.tld\342\200\235 is not a registered internet domain.</pre></div>\r\n        </div>\r\n        <div style=\"margin:10px;border:1px solid #000; \">\r\n            <div style=\"padding:5px;border-bottom:1px solid #000;background-color: #E8E8E8\">\r\n                <strong>\342\233\224 cpanel.hambone.tld</strong>\r\n                <span style=\"font-size:11px\">(checked on Oct 3, 2018 at 3:20:13 AM UTC)</span>\r\n            </div>\r\n            <div><pre style=\"white-space:pre-wrap; margin:5px;\">HTTP DCV: \342\200\234cpanel.hambone.tld\342\200\235 is not a registered internet domain.</pre></div>\r\n        </div>\r\n        <div style=\"margin:10px;border:1px solid #000; \">\r\n            <div style=\"padding:5px;border-bottom:1px solid #000;background-color: #E8E8E8\">\r\n                <strong>\342\233\224 webmail.hambone.tld</strong>\r\n                <span style=\"font-size:11px\">(checked on Oct 3, 2018 at 3:20:13 AM UTC)</span>\r\n            </div>\r\n            <div><pre style=\"white-space:pre-wrap; margin:5px;\">HTTP DCV: \342\200\234webmail.hambone.tld\342\200\235 is not a registered internet domain.</pre></div>\r\n        </div></p><p>For the most current status, navigate to the \342\200\234<a href=\"https://felipe64.dev.cpanel.net:2083/?goto_app=SSL_TLS_Status\">SSL/TLS Status</a>\342\200\235 interface. You can also exclude domains from future renewal attempts, which would cease future notifications.</p>\r\n\r\n<p>\r\n          The following domains will lose SSL coverage when the certificate expires:    </p>\r\n\r\n<ul>\r\n            <li>\r\n            <a href=\"https://hambone.tld\">hambone.tld</a>\r\n        </li>\r\n            <li>\r\n            <a href=\"https://mail.hambone.tld\">mail.hambone.tld</a>\r\n        </li>\r\n            <li>\r\n            <a href=\"https://www.hambone.tld\">www.hambone.tld</a>\r\n        </li>\r\n    </ul>\r\n\r\nThe certificate that is installed on this website contains the following properties:   <table style=\"\r\n        margin:5px auto;\r\n        border: 1px solid #333333;\r\n        padding:0;\"\r\n        cellpadding=\"0\" cellspacing=\"0\" >\r\n                        <tr style=\"background-color:#FFFFFF;\">\r\n                        <td style=\"\r\n                                font-weight:bold;                font-family: 'Courier New', Courier, monospace;\r\n                padding: 5px;\r\n                                                padding-left:10px;\" >\r\n                Expiration:            </td>\r\n                        <td style=\"\r\n                                font-family: 'Courier New', Courier, monospace;\r\n                padding: 5px;\r\n                                padding-right:10px;                \" >\r\n                Wednesday, October 3, 2018 at 10:16:13 PM UTC            </td>\r\n                    </tr>\r\n                <tr style=\"background-color:#F4F4F4;\">\r\n                        <td style=\"\r\n                                font-weight:bold;                font-family: 'Courier New', Courier, monospace;\r\n                padding: 5px;\r\n                                                padding-left:10px;\" >\r\n                Domain Names:            </td>\r\n                        <td style=\"\r\n                                font-family: 'Courier New', Courier, monospace;\r\n                padding: 5px;\r\n                                padding-right:10px;                \" >\r\n                    <table class=\"domains-list\" style=\"margin-bottom: 0\">\r\n                    <tr>\r\n                <td style=\"padding:3px 3px 3px 0;\">hambone.tld</td>\r\n            </tr>\r\n                    <tr>\r\n                <td style=\"padding:3px 3px 3px 0;\">mail.hambone.tld</td>\r\n            </tr>\r\n                    <tr>\r\n                <td style=\"padding:3px 3px 3px 0;\">www.hambone.tld</td>\r\n            </tr>\r\n            </table>\r\n            </td>\r\n                    </tr>\r\n                <tr style=\"background-color:#FFFFFF;\">\r\n                        <td style=\"\r\n                                font-weight:bold;                font-family: 'Courier New', Courier, monospace;\r\n                padding: 5px;\r\n                                                padding-left:10px;\" >\r\n                Subject:            </td>\r\n                        <td style=\"\r\n                                font-family: 'Courier New', Courier, monospace;\r\n                padding: 5px;\r\n                                padding-right:10px;                \" >\r\n                    <table class=\"distinguished-name\" style=\"margin-bottom: 0\">\r\n                    <tr>\r\n                <td style=\"padding:3px 3px 3px 0;\">commonName</td>\r\n                <td style=\"padding:3px;\">hambone.tld</td>\r\n            </tr>\r\n            </table>\r\n            </td>\r\n                    </tr>\r\n                <tr style=\"background-color:#F4F4F4;\">\r\n                        <td style=\"\r\n                                font-weight:bold;                font-family: 'Courier New', Courier, monospace;\r\n                padding: 5px;\r\n                                                padding-left:10px;\" >\r\n                Issuer:            </td>\r\n                        <td style=\"\r\n                                font-family: 'Courier New', Courier, monospace;\r\n                padding: 5px;\r\n                                padding-right:10px;                \" >\r\n                    <table class=\"distinguished-name\" style=\"margin-bottom: 0\">\r\n                    <tr>\r\n                <td style=\"padding:3px 3px 3px 0;\">commonName</td>\r\n                <td style=\"padding:3px;\">hambone.tld</td>\r\n            </tr>\r\n            </table>\r\n            </td>\r\n                    </tr>\r\n           </table>\r\n\r\n<p></p>\r\n                                                                    </td>\r\n                                                                </tr>\r\n                                                                <tr>\r\n                                                                    <td>\r\n                                                                        <div style=\"font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;border-top: 2px solid #E8E8E8; padding-top:5px; margin-top: 5px; font-size:12px; color: #666666;\">\r\n            <p style=\"padding:0 0 0 0; margin: 5px 0 0 0;\">\r\n        The system generated this notice on Wednesday, October 3, 2018 at 3:20:18 AM UTC.    </p>\r\n</div>                                                                                                                                                 <p>\r\n                                                                                                                                                        You can disable the \342\200\234AutoSSL cannot request a certificate because all of the website\342\200\231s domains have failed DCV (Domain Control Validation).\342\200\235 type of notification through the cPanel interface: <a target=\"_blank\" href=\"https://felipe64.dev.cpanel.net:2083/?goto_app=ContactInfo_Change\">https://felipe64.dev.cpanel.net:2083/?goto_app=ContactInfo_Change</a>                                                                                                                                                    </p>\r\n                                                                        <p>\r\n    Do not reply to this automated message.</p>\r\n                                                                    </td>\r\n                                                                </tr>\r\n                                                            </tbody>\r\n                                                        </table>\r\n\r\n                                                    </td>\r\n                                                    <td width=\"15\">\r\n                                                    </td>\r\n                                                </tr>\r\n                                            </tbody>\r\n                                        </table>\r\n                                    </td>\r\n                                                                    </tr>\r\n                                <tr>\r\n                                    <td align=\"center\" style=\"padding-top: 10px;\">\r\n                                                                            <img src=\"cid:auto_cid_107541364\" height=\"25\" width=\"25\" style=\"border:0;line-height:100%;border:0\" alt=\"cP\">\r\n                                        <p style=\"font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;font-size:12px;color:#666666; padding: 0; margin: 0;\">Copyright\302\251\302\2402018 cPanel, Inc.<p>\r\n                                                                        </td>\r\n                                </tr>\r\n                            </tbody>\r\n                        </table>\r\n                    </td>\r\n                </tr>\r\n            </tbody>\r\n        </table>\r\n    </div>\r\n</body>"
        ),
    ],
];

sub new {
    my ($class) = @_;

    my $self = $class->SUPER::new();

    $self->num_method_tests( 'test_strip', 0 + @{ _STRIP_TESTS() } );

    return $self;
}

sub _get_expected {
    my ($html) = @_;

    my $path = "$FindBin::Bin/support/normalize_html_part.py";

    utf8::encode($html) if utf8::is_utf8($html);

    my $out = q<>;
    my $err = q<>;
    IPC::Run::run(
        [ Test::Mail::Pyzor::python_bin(), $path ],
        \$html,
        \$out,
        \$err,
    );

    warn $err if length $err;

    return $out;
}

sub test_strip : Tests() {
    my ($self) = @_;

  SKIP: {
        $self->_skip_if_no_python_pyzor( $self->num_tests() );

        for my $t ( @{ _STRIP_TESTS() } ) {
            my ( $label, $in, %opts ) = @$t;

            my $got = Mail::Pyzor::Digest::StripHtml::strip($in);

            my $expect = _get_expected($in);

          TODO: {
                local $TODO = $opts{'todo'};

                utf8::is_utf8($_) && utf8::encode($_) for ( $got, $expect );

                is(
                    $got,
                    $expect,
                    $label,
                  )
                  or do {
                    diag Test::Mail::Pyzor::dump($got);
                    diag Test::Mail::Pyzor::dump($expect);
                  };
            }
        }
    }

    return;
}

1;
