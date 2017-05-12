use inc::Module::Install;

name 'Email-Abstract-QpsmtpdTransaction';
all_from 'lib/Email/Abstract/QpsmtpdTransaction.pm';

die "\nPlease install Qpsmtpd first. http://smtpd.develooper.com/\n"
    unless eval { require Qpsmtpd; 1 };

requires 'Email::Abstract';

auto_include;

WriteAll;
