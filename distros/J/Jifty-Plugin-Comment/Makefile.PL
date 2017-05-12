use inc::Module::Install;
name('Jifty-Plugin-Comment');
all_from('lib/Jifty/Plugin/Comment.pm');

requires('Jifty' => '0.90409');
requires('HTML::Scrubber');
requires('MIME::Base64::URLSafe');
requires('Regexp::Common');
requires('Regexp::Common::URI');
requires('Regexp::Common::Email::Address');
requires('CGI::Cookie');

auto_install();
tests('t/*.t t/*/t/*.t');

install_share;

WriteAll;
