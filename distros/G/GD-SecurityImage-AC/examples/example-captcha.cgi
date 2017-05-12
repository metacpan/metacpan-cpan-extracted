#!/usr/bin/perl -wT

###
# Note: It isn't a requirement of GD::Security::AC itself
# that CGI::Minimal and Class::ParmList be used, that is
# just how I coded up the example.

use strict;

use GD::SecurityImage::AC;
use CGI::Minimal;
use Class::ParmList qw (simple_parms);

our $Captcha_Data_Folder   = '/var/www/databases/captchas';
our $Captcha_Output_Folder = '/var/www/html/images/captchas';
our $Captcha_Output_URI    = '/images/captchas';
our $Captcha_Length        = 5;
our $Captcha_Expire        = 1800; # 30 minutes
our $Captcha_Lines         = 4;
our $Captcha_Scrambled     = 1;
our $Captcha_Font          = 'Giant'; # Possible are 'Small','Large', 'MediumBold', 'Giant'
our $Captcha_Style         = 'default'; # Possible are 'default','rect','box','circle','ellipse','ec','blank'
our $Captcha_Text_Color    = '#505050';
our $Captcha_Line_Color    = '#505050';
our $Captcha_Bg_Color      = '#FFFFFF';

my $output = eval {
    my $cgi     = CGI::Minimal->new;
    my $request = $cgi->param('request');
    $request    = defined($request) ? $request : '';
    my $actions_table = {
        ''            => \&show_captcha,
        'show'        => \&show_captcha,
        'validate'    => \&validate_captcha,
        'bad_request' => \&bad_request,
    };
    my $action = exists($actions_table->{$request}) ? $actions_table->{$request} : $actions_table->{'bad_request'};
    my $output = &$action({ cgi => $cgi });
    return $output;
};

if (defined ($output) && ($output ne '')) {
   print $output;

} else {
    print "Content-Type: text/plain\015\012\015\012Script Error\n$@\n";

}

#################

sub show_captcha {
    my ($cgi) = simple_parms(['cgi'], @_);

    my ($new_captcha_md5, $new_captcha_image) = new_captcha();
    my $output =<<"EOT";
Content-Type: text/html; charset=utf-8

<html>
 <head>
  <title>CAPTCHA Example</title>
 </head>
 <body>
  <p>
  <img src="$new_captcha_image" />
  </p>
  <form method="POST">
   <input type="hidden" name="request" value="validate" />
   <input type="hidden" name="captcha_md5" value="$new_captcha_md5" />
   <input type="text" size="10" name="captcha_value" value="" />
   <input type="submit" name="Submit CAPTCHA" />
  </form>
 </body>
</html>
EOT

}

#################

sub validate_captcha {
    my ($cgi) = simple_parms(['cgi'], @_);

    my $captcha_value       = $cgi->param('captcha_value');
    my $captcha_md5         = $cgi->param('captcha_md5');
    my $captcha_results     = check_captcha({ 'value' => $captcha_value, 'md5sum' => $captcha_md5 });
    my $captcha_result_desc = {
        1  => 'passed',
        0  => 'error: file error (code not checked)',
        -1 => 'failed: code expired',
        -2 => 'failed: invalid code (not in database)',
        -3 => 'failed: invalid code (bad checksum)',
    };
    my $result_desc = $captcha_result_desc->{$captcha_results};

    my ($new_captcha_md5, $new_captcha_image) = new_captcha();
    my $output =<<"EOT";
Content-Type: text/html; charset=utf-8

<html>
 <head>
  <title>CAPTCHA Example</title>
 </head>
 <body>
 <p>
  Result: $result_desc
 </p>
  <p>
  <img src="$new_captcha_image" />
  </p>
  <form method="POST">
   <input type="hidden" name="request" value="validate" />
   <input type="hidden" name="captcha_md5" value="$new_captcha_md5" />
   <input type="text" size="10" name="captcha_value" value="" />
   <input type="submit" name="Submit CAPTCHA" />
  </form>
 </body>
</html>
EOT

}

#################

sub bad_request {
    my ($cgi) = simple_parms(['cgi'], @_);
    my $request = $cgi->param('request');
    my $output =<<"EOT";
Content-Type: text/plain\015\012\015\012
Unrecognized request of '$request'.

EOT
    return $output;

}

################
# Checks the captcha for validity.
#
sub check_captcha {
    my ($raw_value, $raw_md5sum) = simple_parms(['value','md5sum'], @_);

    my ($captcha_md5)   = $raw_md5sum =~ m/^([a-zA-Z0-9]{1,50})$/s;
    $captcha_md5        = defined($captcha_md5) ? $captcha_md5 : '';
    my ($captcha_value) = $raw_value =~ m/^([a-zA-Z0-9]{1,50})$/s;
    $captcha_value      = defined($captcha_value) ? $captcha_value : '';
    my $captcha         = captcha();
    my $result          = $captcha->check_code($captcha_value, $captcha_md5);
    return $result;
}

################

sub new_captcha {
    my $captcha = captcha();
    my $md5sum  = $captcha->generate_code($Captcha_Length);
    my $image_uri = "$Captcha_Output_URI/${md5sum}.png";
    return ($md5sum, $image_uri);
}

################

# Comment out 'gd_font' and uncomment 'font' and 'create' to use a true-type font
# instead of the GD built-on fonts

sub captcha {
    my $captcha = Authen::Captcha->new(
        data_folder   => $Captcha_Data_Folder,
        output_folder => $Captcha_Output_Folder,
        expire        => $Captcha_Expire,
    )->gdsi( 
        new => {
            bgcolor  => $Captcha_Bg_Color,
            lines    => $Captcha_Lines,
            gd_font  => $Captcha_Font,
#            font     => '/var/www/databases/captchas/LucidaSansDemiBold.ttf',
            ptsize   => 16,
            height   => 60,
            width    => 200,
            scramble => $Captcha_Scrambled,
        },
#        create => [ 'ttf' => $Captcha_Style, $Captcha_Text_Color, $Captcha_Line_Color],
    );
    return $captcha;
}
