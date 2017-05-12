#!/usr/bin/perl -w
# -> GD::SecurityImage demo program
# -> Burak Gursoy (c) 2004-2012. 
# See the document section after "__END__" for license and other information.
package Demo;
use 5.006;
use strict;
use warnings;
use CGI  qw( header escapeHTML );
use Cwd;
use Carp qw( croak );
use constant SALT_RANDOM   => 100;
use constant MAGICK_PTSIZE =>  12;
use constant GD_PTSIZE     =>   8;

my %config = (
   database   => 'gdsi',                 # database name (for session storage)
   table_name => 'sessions',             # only change this value, if you *really* have to use another table name. Also change the SQL code below.
   user       => 'root',                 # database user name
   pass       => q{},                    # database user's password
   font       => getcwd.'/StayPuft.ttf', # ttf font. change this to an absolute path if getcwd is failing
   itype      => 'png',                  # image format. set this to gif or png or jpeg
   use_magick => 0,                      # use Image::Magick or GD
   img_stat   => 1,                      # display statistics on the image?
   program    => q{},                    # if CGI.pm fails to locate program url, set this value.
);

# You'll need this to create the sessions table. 
#    CREATE TABLE sessions ( id char(32) not null primary key, a_session text )

# - - - - - - - - - - - - > S T A R T   P R O G R A M < - - - - - - - - - - - #

our $VERSION = '1.51';

use constant REQUIREDMODS => qw(
   DBI
   DBD::mysql
   Apache::Session::MySQL
   String::Random
   GD::SecurityImage
   Time::HiRes
);

BEGIN {
   my @errors;
   my $test = sub {
      # Storable' s [eval "use Log::Agent";] line breaks the handler,
      # since it is not a common module and does not exist generally...
      local $SIG{__DIE__};
      local $@;
      my $mod = shift;
      my $eok = eval "require $mod; 1;";
      push @errors, { module => $mod, error  => $@ } if $@ || ! $eok;
   };
   $test->($_) foreach REQUIREDMODS;
   if ( @errors ) {
      my $err = qq{<pre>This demo program needs several CPAN modules to run:\n\n};
      foreach my $e ( @errors ) {
         $err .= q~<b><span style="color:red">[FAILED]</span>~
               . qq~ $e->{module}</b>: $e->{error}<br />~;
      }
      print header . $err . '</pre>' or croak "Can not print to STDOUT: $!";
      exit;
   }
}

my $NOT_EXISTS = quotemeta 'Object does not exist in the data store';

run() if not caller; # if you require this, you'll need to call demo::run()

sub TEST_FONT_EXISTENCE {
   if ( not $config{use_magick} ) {
      if ( $config{font} =~ m{\s}xms ) {
         croak "The font path '$config{font}' has a space in it. GD hates spaces!";
      }
   }
   require IO::File;
   my $FONTFILE = IO::File->new;
   if ( $FONTFILE->open( $config{font} ) ) {
      $FONTFILE->close;
   }
   else {
      croak qq~I can not open/find the font file in '$config{font}': $!~;
   }
   return;
}

sub new {
   TEST_FONT_EXISTENCE();
   my $class = shift;
   my $self  = {
      ISDISPLAY => 0,
      SID       => undef,
      CPAN      => 'http://search.cpan.org/dist',
      IS_GD     => 0,
   };
   bless $self, $class;
   return $self;
}

sub config { return \%config }

sub run {
   local $SIG{__DIE__} = sub {
      print header . <<"ERROR" or croak "Can not print to STDOUT: $!";
         <h1 style="color:red;font-weight:bold"
            >FATAL ERROR</h1>
         @_
ERROR
      exit;
   };

   my $START = Time::HiRes::time();
   my $self  = shift || __PACKAGE__->new;

   GD::SecurityImage->import( use_magick => $config{use_magick} );

   $self->{IS_GD}   = $GD::SecurityImage::BACKEND eq 'GD';
   $self->{cgi}     = CGI->new;
   $self->{program} = $config{program};
   if ( ! $self->{program} ){
      # it is possible to get the url as "demo.pl??foo=bar"
      my $url = $self->{cgi}->can('self_url') ? $self->{cgi}->self_url
                                              : $self->{cgi}->url;
      ($self->{program}, my @jp) = split m{[?]}xms, $url;
   }

   my %options      = $self->all_options;
   my %styles       = $self->all_styles;
   my @optz         = keys %options;
   my @styz         = keys %styles;

   $self->{rnd_opt} = $options{ $optz[ int rand @optz ] };
   $self->{rnd_sty} = $styles{  $styz[ int rand @styz ] };

   # our database handle
   my $dbh = DBI->connect(
                "DBI:mysql:$config{database}",
                @config{ qw/ user pass / },
                {
                   RaiseError => 1,
                }
             );

   my %session;
   my $create_ses = sub { # fetch/create session
      my $sid = @_ ? undef : $self->{cgi}->cookie('GDSI_ID');
      tie %session, 'Apache::Session::MySQL', $sid, { ## no critic (Miscellanea::ProhibitTies)
         Handle     => $dbh,
         LockHandle => $dbh,
         TableName  => $config{table_name},
      };
   };

   my $eok = eval { $create_ses->(); 1; };

   # I'm doing a little trick to by-pass exceptions if the session id
   # coming from the user no longer exists in the database. 
   # Also, I'm not validating the session key here, you can also check
   # IP and browser string to validate the session. 
   # It is also possible to put a timeout value for security_code key.
   # But, all these and anything else are all beyond this demo...
   if ( $@ && $@ =~ m{ \A $NOT_EXISTS }xms ) {
      $create_ses->('new');
   }

   if ( ! $session{security_code} ) {
      $session{security_code} = $self->_random; # initialize random code
   }

   $self->{ISDISPLAY} = $self->{cgi}->param('display') || 0;
   $self->{SID}       = $session{_session_id};
   my $output         = q{}; # output buffer

   if ( $self->{ISDISPLAY} ) {
      $START = Time::HiRes::time();
      my($image, $mime, $random) = $self->create_image($session{security_code}, $START );
      $output  = $self->myheader(type => "image/$mime");
      $output .= $image;
      binmode STDOUT;
   }
   else {
      $output  = $self->myheader . $self->html_head;
      $output .= $self->{cgi}->param('process') ? $self->process( $session{security_code} )
               : $self->{cgi}->param('help')    ? $self->help
               :                                  $self->form();
      $output .= '<p>' . $self->backenduri . $self->html_foot($START) . '</p>';
      # make the code always random
      $session{security_code} = $self->_random;
   }

   untie %session;
   $dbh->disconnect;
   print $output or croak "Can not print to STDOUT: $!";
   exit;
}

sub process {
   my $self = shift;
   my $ses  = shift || croak 'Security_code from session is missing';
   my $code = $self->{cgi}->param('code') || q{};
   my $pass = $self->iseq( $code, $ses );
   return $pass ? $self->_congrats( $code, $ses )
                : $self->_failure(  $code, $ses )
                ;
}

sub backenduri {
   my $self = shift;
   my $rv   = q{Security image generated with <b>};
      $rv  .= $self->{IS_GD}
            ? qq~<a href="$self->{CPAN}/GD"         target="_blank">GD</a> v$GD::VERSION~
            : qq~<a href="$self->{CPAN}/PerlMagick" target="_blank">Image::Magick</a> v$Image::Magick::VERSION~;
   return $rv . '</b>';
}

sub _random { return String::Random->new->randregex('\d\d\d\d\d\d') }

sub _failure {
   my $self = shift;
   my $code = CGI::escapeHTML(shift || q{});
   my $ses  = shift || q{};
   my $rv   = <<"FAIL";
      <b>'${code}' != '${ses}'</b>
      <br />
      <span style="color:red;font-weight:bold">
      You have failed to identify yourself as a human!
      </span>
      <br />
FAIL
   $rv .= $self->form();
   return $rv;
}

sub _congrats {
   my $self = shift;
   my $form = shift || q{};
   my $ses  = shift || q{};
   return <<"PASS";
      <b>'$form' == '$ses'</b>
      <br />
      <span style="color:#009700;font-weight:bold">
      Congratulations! You have passed the test!
      </span>
      <br />
      <br />
      <a href="$self->{program}">Try again</a>
PASS
}

sub iseq {
   my $self = shift;
   my $form = shift || return;
   my $ses  = shift || return;
   return if $form =~ m{\D}xms;
   return $form eq $ses;
}

sub myheader {
   my($self, %o) = @_;
   my $display = $self->{ISDISPLAY};
   my $type    = $o{type} ? $o{type}
               : $display ? 'image/'.$config{itype}
               :            'text/html';
   my $c       = $self->{cgi}->cookie(
                    -name => 'GDSI_ID',
                    -value => $self->{SID},
                 );
   return $self->{cgi}->header(
      -type   => $type,
      -cookie => $c
   );
}

#--------------> FUNCTIONS <--------------#

sub help {
   my $self = shift;
   return <<"HELP";

If you want to change the image generation options, open this file with
a text editor and search for the <b>%config</b> hash.
Database options are used to access to a MySQL Database Server. MySQL is
used for session data storage.

<table border="1">

<tr>
   <td class="htitle">Parameter</td>
   <td class="htitle">Default</td>
   <td class="htitle">Explanation</td>
</tr>

<tr>
   <td> database   </td>
   <td><i>gdsi</i></td>
   <td>The database name we will use for session storage</td>
</tr>

<tr>
   <td> table_name </td>
   <td>sessions</td>
   <td>The name of the table for session storage. 
       Only change this value, if you *really* have to use 
       another table name. Also you must change the table
       generation (SQL) code.</td>
</tr>

<tr>
   <td> user </td>
   <td><i>root</i></td>
   <td>Database user name</td>
</tr>

<tr>
   <td> pass        </td>
   <td><i>&nbsp;</i></td>
   <td>Database password</td>
</tr>

<tr>
   <td> font       </td>
   <td><i>StayPuft.ttf</i></td>
   <td>TTF font for SecurityImage generation. 
       Put the sample font into the same folder as 
       this program.</td>
</tr>

<tr>
   <td> itype      </td>
   <td><i>gif</i></td>
   <td>Image format. You can set this to <i>png</i>
   or <i>gif</i> or <i>jpeg</i>.</td>
</tr>

<tr>
   <td> use_magick </td>
   <td><i>FALSE</i></td>
   <td>False value: <b>GD</b> will be used; True value: <b>Image::Magick</b> 
       will be used. If you use GD, please do not use a prehistoric version.
       The module itself is highly compatible with older versions, but this demo 
       needs <b>\$GD::VERSION >= 1.31</b>
   </td>
</tr>

<tr>
   <td> img_stat   </td>
   <td><i>TRUE</i></td>
   <td>If has a true value, some statistics like "image generation" 
       and "total execution" times will be placed on the image. 
       The page you see this also shows that information, 
       but image generation is an <b><i>another</i></b> process and we can only
       show the stats this way. This option uses the minimal amount of space,
       but if you want to cancel it just give it a false value.
   </td>
</tr>

<tr>
   <td> program </td>
   <td> &#160; </td>
   <td> Program url is automatically set by CGI.pm. Bu this <i>may</i> fail
        in some environments. If the url is not set, you can not see the image. 
        Set this to the actual program url if there is a problem.
   </td>
</tr>

</table>

HELP
}

sub form {
   my $self = shift;
   # by-pass browser cache with this random fake value
   my $salt = '&salt=' . $$ . time . rand SALT_RANDOM;
   return <<"FORM";
   <form action="$self->{program}" method="post">
    <table border="0" cellpadding="2" cellspacing="1">
     <tr>
      <td>
       <b>Enter the security code:</b><br />
       <span class="small">to identify yourself as a human</span><br />
        <input type="text"   name="code"    value="" size="10">
              <input type="submit" name="submit"  value="GO!">
       <input type="hidden" name="process" value="true">
      </td>
      <td><img src="$self->{program}?display=1$salt" alt="Security Image"></td>
      <td>
      
      </td>
     </tr>
    </table>
   </form>
FORM
}

sub html_head {
   my $self = shift;
   return <<"HTML_HEAD";
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
"http://www.w3.org/TR/html4/loose.dtd">
<html>
   <head>
    <title>GD::SecurityImage v$GD::SecurityImage::VERSION - DEMO v$VERSION</title>
    <style type="text/css">
      body   {
            font-family : Verdana, serif;
            font-size   : 12px;
      }
      a:link    { color : #0066CC; text-decoration : none      }
      a:active  { color : #FF0000; text-decoration : none      }
      a:visited { color : #003399; text-decoration : none      }
      a:hover   { color : #009900; text-decoration : underline }
      .small {font-size:10px}
      .htitle {
      font-weight: bold;
      }
    </style>
    <script language='JavaScript'>

    function help () {
       window.open('$self->{program}?help=1',
                   'HELP',
                   'width=630,height=550,resizable=yes,scrollbars=yes');
    }
    </script>
   </head>
   <body>
    <h2><a href   = "$self->{CPAN}/GD-SecurityImage"
           target = "_blank"
           >GD::SecurityImage</a> v$GD::SecurityImage::VERSION - DEMO v$VERSION</h2>
HTML_HEAD
}

sub html_foot {
   my $self  = shift;
   my $START = shift;
   my $bench = sprintf 'Execution time: %.3f seconds',
                       Time::HiRes::time() - $START;
   return <<"HTML_FOOTER";
      <span class="small">
      | <a href="http://search.cpan.org/~burak" target="_blank">\$CPAN/Burak G&uuml;rsoy</a>
      | $bench
      | <a href="#" onClick="javascript:help()">?<a/></span>
      </body>
   </html>
HTML_FOOTER
}

sub create_image { # create a security image with random options and styles
   my $self  = shift;
   my $code  = shift;
   my $START = shift;
   my $s     = $self->{rnd_sty};
   my $i     = GD::SecurityImage->new(
      lines   => $s->{lines},
      bgcolor => $s->{bgcolor},
      %{ $self->{rnd_opt} },
   );
   $i->random   ($code)
      ->create  (ttf => $s->{name}, $s->{text_color}, $s->{line_color})
      ->particle($s->{dots} ? ($s->{particle}, $s->{dots})
                            : ($s->{particle})
      );
   if ($i->gdbox_empty) {
      croak qq~An error occurred while opening the font file '$config{font}'. ~
         .qq~Please set font option to an "exact" path, not relative. Error: $@~;
   }
   if ($config{img_stat}) {
      $i->info_text(
         x      => 'right',
         y      => 'up',
         gd     => 1,
         strip  => 1,
         color  => '#000000',
         scolor => '#FFFFFF',
         # low-level access to an object table is not a good thing,
         # since the author can change/delete it without notification 
         # in later releases ;)
         ptsize => $i->{IS_MAGICK} ? MAGICK_PTSIZE : GD_PTSIZE,
         text   => sprintf('Security Image generated at %.3f seconds',
                           Time::HiRes::time() - $START),
      );
   }
   my @image = $i->out(force => $config{itype});
   return @image;
}

# below is taken from the test api "tapi"

sub all_options {
   my $self = shift;
   my %gd = (
   gd_ttf => {
      width      => 220,
      height     => 90,
      send_ctobg => 1,
      font       => $config{font},
      ptsize     => 30,
   },
   gd_ttf_scramble =>  {
      width      => 360,
      height     => 110,
      send_ctobg => 1,
      font       => $config{font},
      ptsize     => 25,
      scramble   => 1,
   },
   gd_ttf_scramble_fixed =>  {
      width      => 360,
      height     => 90,
      send_ctobg => 1,
      font       => $config{font},
      ptsize     => 25,
      scramble   => 1,
      angle      => 30,
   },
   );
   my %magick = (
   magick => {
      width      => 250,
      height     => 100,
      send_ctobg => 1,
      font       => $config{font},
      ptsize     => 50,
   },
   magick_scramble => {
      width      => 350,
      height     => 100,
      send_ctobg => 1,
      font       => $config{font},
      ptsize     => 30,
      scramble   => 1,
   },
   magick_scramble_fixed => {
      width      => 350,
      height     => 80,
      send_ctobg => 1,
      font       => $config{font},
      ptsize     => 30,
      scramble   => 1,
      angle      => 32,
   },
   );
   return $self->{IS_GD} ? (%gd) : (%magick);
}

sub all_styles {
   ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
   return ec => {
      name       => 'ec',
      lines      => 16,
      bgcolor    => [ 0,   0,   0],
      text_color => [84, 207, 112],
      line_color => [ 0,   0,   0],
      particle   => 1000,
   },
   ellipse => {
      name       => 'ellipse',
      lines      => 15,
      bgcolor    => [208, 202, 206],
      text_color => [184,  20, 180],
      line_color => [184,  20, 180],
      particle   => 2000,
   },
   circle => {
      name       => 'circle',
      lines      => 40,
      bgcolor    => [210, 215, 196],
      text_color => [ 63, 143, 167],
      line_color => [210, 215, 196],
      particle   => 3500,
   },
   box => {
      name       => 'box',
      lines      => 6,
      text_color => [245, 240, 220],
      line_color => [115, 115, 115],
      particle   => 3000,
      dots       => 2,
   },
   rect => {
      name       => 'rect',
      lines      => 30,
      text_color => [ 63, 143, 167],
      line_color => [226, 223, 169],
      particle   => 2000,
   },
   default => {
      name       => 'default',
      lines      => 10,
      text_color => [ 68, 150, 125],
      line_color => [255,   0,   0],
      particle   => 5000,
   },
   ;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

demo.pl - GD::SecurityImage demo program.

=head1 SYNOPSIS

This is a CGI program. Run from web.

=head1 DESCRIPTION

This program demonstrates the abilities of C<GD::SecurityImage>.
It needs these CPAN modules: 

   DBI
   DBD::mysql
   Apache::Session::MySQL
   String::Random
   GD::SecurityImage	(with GD or Image::Magick)

and these CORE modules:

   CGI
   Cwd
   Time::HiRes

Also, be sure to use recent versions of GD. This demo needs at least
version C<1.31> of GD. And if you want to use C<Image::Magick> it must 
be C<6.0.4> or newer.

You'll also need a MySQL server to run the program. You must create 
a table with this SQL code:

   CREATE TABLE sessions (
      id char(32) not null primary key,
      a_session text
   );

If you want to use another table name (not C<sessions>), set the 
C<$config{table_name}> to the value you want and also modify the 
C<SQL> code above. With the default configuration option, this 
program assumes that you have a database named C<gdsi>. Change this
option to the database name you want to use.

Security images are generated with the sample ttf font "StayPuft.ttf".
Put it into the same folder as this program or alter C<$config{font}> value.
If you want to use another font file, you may need to alter the image 
generation options (see the C<%config> hash on top of the program code).

=begin html

<!-- this h1 part is for search.cpan.org -->
<h1>
<a class = 'u'
   href  = '#___top'
   title ='click to go to top of document'
   name  = "DEMO SCREENSHOTS"
>DEMO SCREENSHOTS</a>
</h1>

<p>
Here are some sample screen shots showing this demo in action.
</p>

<table border      = "0"
       cellpadding = "4"
       cellspacing = "1"
>
   <tr>
      <td style="text-align:center;font-weight:bold">
         <br />
         Enter demo.pl
         <br />
         <br />
      </td>
   </tr>
   <tr>
      <td><img border="0" src="http://img405.imageshack.us/img405/1967/demoentermc3.png" /></td>
   </tr>

   <tr>
      <td style="text-align:center;font-weight:bold">
         <br />
         Validation <span style="color:red">Failed</span>
         <br />
         <br />
      </td>
   </tr>
   <tr>
      <td><img border="0" src="http://img87.imageshack.us/img87/2049/demofailep8.png" /></td>
   </tr>

   <tr>
      <td style="text-align:center;font-weight:bold">
         <br />
         Validation <span style="color:green">Succeeded</span>
         <br />
         <br />
      </td>
   </tr>
   <tr>
      <td><img border="0" src="http://img405.imageshack.us/img405/7268/demopasskw8.png" /></td>
   </tr>

</table>

=end html

=begin html

<p>
All images in this document are generously hosted by
<a href="http://imageshack.us">ImageShack</a>
<a href="http://imageshack.us"><img src="http://imageshack.us/img/imageshack.png" border="0" /></a>
</p>

=end html

=head1 CAVEAT EMPTOR

Note that, this is only a demo. Use at your own risk!

=over 4

=item *

No security checks are performed.

=item *

This demo may not be secure or memory friendly.

=item *

You don't have to use the bundled sample font. If you don't like it, 
just use some other font that you like, but be sure to adjust several 
parameters for a I<human readable> graphic.

=item *

There are several pre-defined I<"styles"> for generating images. You 
can create your own style(s) playing with the parameters.

=item *

Do B<not> use this demo's code as a base for your application. Your own
implementation will probably be much more cleaner and shorter. This
demo includes dirty and undocumented code!

=back

=head1 SEE ALSO

L<GD::SecurityImage>.

=head1 AUTHOR

Burak GE<252>rsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004-2012 Burak Gürsoy. All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut
