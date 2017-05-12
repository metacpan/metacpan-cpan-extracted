use inc::Module::Install;

name            ('Foorum');
author          ('Fayland Lam<fayland@gmail.com>');
abstract        ('Foorum - forum system based on Catalyst');
license         ('perl');
version_from    ('lib/Foorum.pm');

repository 'http://github.com/fayland/foorum/tree/master';

requires 'Template' => '2.20';
requires 'DBIx::Class' => '0.08107';
requires 'Catalyst' => '5.80005';
requires 'Moose'    => '0.75';
requires 'parent';
requires 'Digest';
requires 'DateTime';
requires 'Date::Calc';
requires 'Encode::Guess';
requires 'File::Path';
requires 'File::Copy';
requires 'List::Util';
requires 'List::MoreUtils';
requires 'Catalyst::View::TT' => '0.29';
requires 'Catalyst::View::JSON' => '0.25';
requires 'Catalyst::Model::DBIC::Schema' => '0.24';
requires 'Catalyst::Plugin::Static::Simple';
requires 'YAML::XS';
requires 'Catalyst::Plugin::ConfigLoader' => '0.23';
requires 'Cache::FileCache';
requires 'Catalyst::Plugin::Cache';
requires 'Catalyst::Plugin::PageCache' => '0.21';
requires 'Set::Object';
requires 'Catalyst::Plugin::Authentication' => '0.10011';
requires 'Catalyst::Plugin::Authentication::Credential::Password';
requires 'Catalyst::Authentication::Store::FromSub' => '0.01';
requires 'Catalyst::Plugin::Session' => '0.190';
requires 'Catalyst::Plugin::Session::State::Cookie' => '0.11';
requires 'Catalyst::Plugin::Session::Store::Delegate'; # for DBIC next line
requires 'Catalyst::Plugin::Session::Store::DBIC';
requires 'Catalyst::Plugin::Session::DynamicExpiry';
requires 'Catalyst::Plugin::FormValidator::Simple';
requires 'Catalyst::Plugin::Captcha';
requires 'Catalyst::Plugin::I18N' => '0.08';
requires 'Template::Plugin::FillInForm';
requires 'Template::Plugin::Date';
requires 'File::Remove';
requires 'HTML::Email::Obfuscate';
requires 'Locale::Country::Multilingual' => '0.03'; # for tw lang
#requires 'File::Slurp';
requires 'Net::IP::Match::Regexp';
requires 'Net::CIDR::Lite';
requires 'WWW::Contact' => '0.22'; # the last version

# search
requires 'Sphinx::Search';

# cron
requires 'TheSchwartz::Moosified' => '0.03';
requires 'Schedule::Cron';
if ($^O ne 'MSWin32') {
    feature 'Cron script run-once',
        -default          => 0,
        'Proc::PID::File' => 0,
        'File::HomeDir'   => 0;
} else {
    feature 'Cron script run-once',
        -default          => 0,
        'File::HomeDir'   => 0;
}

# debug options
feature 'Enable QueryLog debug for DBIx::Class Model?',
    -default => 0,
    'Catalyst::TraitFor::Model::DBIC::Schema::QueryLog' => 0;

# mail
requires 'MIME::Entity';
requires 'Email::Send';
feature 'Email::Send through Gmail',
    -default                 => 0,
    'Email::Send::SMTP::TLS' => 0;

# cron/misc|db
feature 'Be a Foorum developer',
    -default                => 0,
    'File::Next'            => 0,
    'CSS::Minifier'         => 0,
    'JavaScript::Minifier'  => 0,
    'Encode::HanConvert'    => 0,
    'Perl::Critic'          => 0,
    'Perl::Tidy'            => 0,
    'SQL::Translator'       => 0,
    'DBICx:::AutoDoc'       => 0,
    'Acme::PlayCode'        => '0.11',
    'Pod::From::GoogleWiki' => '0.05';

# formatter
requires 'Text::Textile';
requires 'Pod::Xhtml';
requires 'URI::Find::UTF8';
requires 'Text::GooglewikiFormat' => '0.05';

tests( join ' ', ( glob('t/*.t'), glob('t/*/*.t') ) );

#catalyst;
#install_script glob('script/*.pl');
auto_install;
WriteAll;
