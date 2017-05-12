# Based on makeconfig.pl from HTML::Mason

my $successMsg = <<EOF;
Edit lib/HTML/Bricks/Config.pm to read about these settings and change
them if desired.  When you run "make install" this file will be
installed alongside the other Mason libraries.
EOF
    
my $confFile = <<EOF;
#
# BRICKS SITE BUILDER
#
# Copyright (c) 2001 by Peter McDermott. All rights reserved.
# See LICENSE.TXT for usage and distribution terms

# This is the global configuration file for HTML::Bricks

\%HTML::Bricks::Config = (

    #
    # www user
    #
    # Some directories must be writable by Bricks Site Builder.  The
    # www_user is the username that the web server will be running
    # as.  It should be the same as the User directive in Apache's
    # conf/httpd.conf.
    #

    'www_user'                 => '%s',

    #
    # www group
    #
    # See www_user above.
    #

    'www_group'                => '%s',

    #
    # bricks root
    #
    # This is the base directory for the bricks site builder bricks and
    # user data.  A good location is /usr/local/bin/bricks.  It is separate
    # from the www space since it stores data that you don't necessarilly
    # want people to download via a HTTP request.  All user created assemblies
    # are stored here, as is the mappings table, and weblogs.
    #

    'bricks_root'              => '%s',

    #
    # document root
    #
    # This is the root directory for HTML documents and whatnot
    #

    'document_root'            => '%s',

    #
    # mason data directory
    #
    # This is the data directory for Mason.  Mason uses this directory to
    # store a cache of 'compiled' mason components.
    #

    'mason_data_root'          => '%s',

    #
    # admin user name
    #
    #

    'admin_user_name'          => '%s',

    #
    # encrypted admin password
    #

    'encrypted_admin_password' => '%s',
 
);
EOF

#-----------------------------------------------------------------------
sub have_pkg
{
    my ($pkg) = @_;
    eval { my $p; ($p = $pkg . ".pm") =~ s|::|/|g; require $p; };
    return ${"${pkg}::VERSION"} ? 1 : 0;
}

#-----------------------------------------------------------------------
sub chk_version
{
 my($pkg,$wanted,$msg) = @_;

 local($|) = 1;
 print "Checking for $pkg...";

 eval { my $p; ($p = $pkg . ".pm") =~ s#::#/#g; require $p; };

 my $vstr = ${"${pkg}::VERSION"} ? "found v" . ${"${pkg}::VERSION"}
				 : "not found";
 my $vnum = ${"${pkg}::VERSION"} || 0;

 print $vnum >= $wanted ? "ok\n" : " " . $vstr . "\n";

 $vnum >= $wanted;
}

#-----------------------------------------------------------------------
sub check_dir($)
{
  my $rary = shift;
  my $base;

  foreach (@$rary) {
    if ((-e $_) && (-d $_)) {
      $base = $_;
      last;
    }
  }

  return $base;
}

#-----------------------------------------------------------------------
sub check_file($)
{
  my $rary = shift;
  my $base;

  foreach (@$rary) {
    if (-e $_) {
      $base = $_;
      last;
    }
  }

  return $base;
}

#-----------------------------------------------------------------------
sub get_dir($$)
{
  my ($prompt, $default) = @_;
  my $dir_name;

  use Term::ReadLine;
  $term = new Term::ReadLine 'name';

  while(1) {
    print "\n$prompt [$default]: ";
    chomp($dir_name = <STDIN>);

    $dir_name = $default if $dir_name eq '';

    last if (-e $dir_name) && (-d $dir_name);

    print "Invalid directory name: \'$dir_name\'\n";
  }

  print "Directory \'$dir_name\' found\n";

  return $dir_name;

}

#-----------------------------------------------------------------------

my $numbers = '0123456789';
my $puncts  = '!@#$%^&*_-=+:.';  	# other puncts are valid but not generated
my $alphas  = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
my $pwchars = $numbers . $puncts . $alphas;

my $min_pw_len = 8;

sub gen_pw()
{
  my $pass;

  do {
    $pass = undef;

    for (my $i=0; $i < $min_pw_len; $i++) {
      $pass .= substr($pwchars,rand(length($pwchars)),1);
    }
  } while (! validate_pw($pass));

  return $pass;
}

#-----------------------------------------------------------------------
sub validate_pw($)
{
  my $pass = shift;

  return 0 if length($pass) < $min_pw_len;

  my $has_num;
  my $has_punct;

  for (my $i=0; $i < length($pass); $i++) {

    my $c = substr($pass,$i,1);

    if ((!$has_num) && (($c ge '0') && ($c le '9'))) {
      $has_num = 1;
      next;
    }
  
    if ((!$has_punct) && (($c <= 'A') || ($c >= 'z'))) {

      # anything not US ASCII or a number is punct.  Works OK.

      $has_punct = 1;
      next; 
    }
  }

  return 0 if (! $has_punct) || (! $has_num);

  return 1;
}


#-----------------------------------------------------------------------
sub make_config
{
    print "-"x40 . "\nCreating Bricks configuration file.\n";
    print "Checking for existing configuration...";

    eval {require 'HTML/Bricks/Config.pm'; };
    my $err = $@;
    my $status = (($err) ? 0 : (!defined(%HTML::Bricks::Config)) ? 1 : 2);

    print  (("not found.", "old-style Config.pm found.", "found.")[$status]);
    print "\n";

    my %c;
    %c = %HTML::Bricks::Config if $status==2;
    %c = %HTML::Bricks::Config if $status==1; # MAKE %C CONTAIN VALUES FROM OLD-STYLE CONFIG !!!

    my $modify = 0;
    if ( $status==2 ) {
      my $conf = sprintf($confFile, @c{ qw(
        www_user 
        www_group 
        bricks_root 
        document_root 
        mason_data_root 
        admin_user_name
        encrypted_admin_password)});

      print "\nYour settings are:\n";
      print join("\n",grep(/=>/,split("\n",$conf)))."\n\n";

      my $ans = "yes";
      print "\nKeep existing config [$ans]: ";
      chomp($ans = <STDIN>);
      $modify = $ans=~/n[o]?/i;
    }

    # Add 'standard' locations of Apache configuration file (I know only RedHat 7.x) [PFLEURY]

    my $apconfig = check_file( [
      '/etc/httpd/conf/httpd.conf', 
      '/usr/local/apache/conf/httpd.conf', 
      '/usr/local/bin/apache/conf/httpd.conf' ]);

    my $www_default=1;
    my $www_user        = $c{www_user}        || "nobody";
    my $www_group       = $c{www_group}       || "nobody";
    my $document_root   = $c{document_root}   || "/dir/to/nowhere";
    my $mason_data_root = $c{mason_data_root} || "/dir/to/nowhere";
    my $os = open(APC,$apconfig);

    if ($os) { # If file not found, do not ask here. Ask for specifics var values later.
      while ( $_=<APC> ) {
        s/#.*//o; # Remove comments...
        $www_user=$1  if /^\s*User\s+(\w[\w\d]*)/oi;
        $www_group=$1 if /^\s*Group\s+(\w[\w\d]*)/oi;
        $document_root=$1 if /^\s*DocumentRoot\s+(\S*)/oi;
        $document_root =~ s/([\"\'])(.*)\1/$2/o; # dequote

        # This is a mini-parser to discover the location of the Mason root

        $last_dir=$2 if /^\s*<Directory\s+(\")?(\S+)\1>/oi;
        $mason_data_root=$last_dir if /^\s*PerlHandler\s+HTML::Mason::Handler/oi; # CHECK THIS !!!
     }
     $www_default=0;
     close(APC);
    }

    if (!defined($c{www_user}) || $modify) {
      print "\n";
      print "Bricks Site Builder executes in the web server's process space.\n";
      print "During this time, it needs to be able to update data files.  To do\n";
      print "this, the directories containing those files must be writable by the\n";
      print "web server.\n";
      print "\n";
      print "Please enter the user and group names that the web server uses below.\n";

      if ($www_default) {
        print "These names are easily obtained by looking at the 'User' and 'Group'\n";
        print "settings in Apache's conf/httpd.conf.\n";
      } else {
        print "These names were obtained by looking at the 'User' and 'Group'\n";
        print "settings in Apache's $apconfig.\n";
      }

      print "\n";

      print "\nwww user name [$www_user]: ";
      chomp($c{www_user} = <STDIN>);
      $c{www_user} = $www_user if $c{www_user} eq '';

      print "\nwww group name [$www_group]: ";
      chomp($c{www_group} = <STDIN>);
      $c{www_group} = $www_group if $c{www_group} eq '';
    }


    if (!defined($c{mason_data_root}) || $modify) {
      if ($c{mason_data_root} =~ /(.*)\/data/) {
        $c{mason_data_root} = $1;
      }

      my $base = check_dir([
        $c{mason_data_root}, 
        $mason_data_root, 
        '/usr/local/bin/mason', 
        '/usr/local/mason']);

      $c{mason_data_root} = get_dir('Enter Mason base directory',$base);
      $c{mason_data_root} .= '/data';
    }

    if (!defined($c{bricks_root}) || $modify) {
      if ($c{bricks_root} =~ /(.*)\/bricks/) {
        $c{bricks_root} = $1;
      }

      my $base = check_dir([$c{bricks_root}, '/usr/local/bin', '/usr/local']);
      $base .= '/bricks';

      $c{bricks_root} = get_dir('Enter directory for installation of Bricks Site Builder',$base);
    }

    if (!defined($c{document_root}) || $modify){
      my $base = check_dir([
        $c{document_root}, 
        $document_root, 
        '/usr/local/www/htdocs', 
        '/usr/local/htdocs', 
        '/var/www/htdocs']);

      $c{document_root} = get_dir('Enter apache document root', $base);
    }

    if (!defined $c{admin_user_name} || $modify) {
      my $base = $c{admin_user_name} || "admin";
      print "\nAdministrator user name [$base]: ";
      chomp($c{admin_user_name} = <STDIN>);

      $c{admin_user_name} =  $c{admin_user_name} || $base;

      print "\n";
    }

    if (!defined($c{encrypted_admin_password}) || $modify) {

      print "\n";
      print "WARNING: The administrator password is stored as encrypted but visible text in Config.pm.\n\n";

      print "This makes the administrator password succeptible to dictionary attacks by anyone\n";
      print "with a shell account on your system, or anyone who can gain access to Config.pm.\n";
      print "For your security, only passwords with at least one number and at least one\n";
      print "punctuation mark and of a minimum length of $min_pw_len characters are allowed.\n\n";

      print "If you really want an unsafe password, modify Config.pm by hand.\n\n";

      my $default = gen_pw();

      print "The password \'$default\' has been randomly generated for you.\n\n";

      while(1) {
        system "stty -echo";
        print "Enter administrator password [$default]: ";
        chomp ($pw = <STDIN>);

        print "\n";

        if ($pw ne '') {
          print "Reenter administrator password: ";
          chomp ($pw2 = <STDIN>);
          print "\n";
        }
        else {
          $pw = $pw2 = $default;
        }

        system "stty echo";

        if ($pw ne $pw2) {
          print "Passwords don't match.\n\n";
          next;
        }
        elsif (! validate_pw($pw)) {
          print "Invalid password.\n\n";
          next;
        }

        last;
      }

      $c{encrypted_admin_password} = crypt($pw, join('',('.','/',0..9,'A'..'Z','a'..'z')[rand 64, rand 64]));
    }

    open(F,">lib/HTML/Bricks/Config.pm") or die "\nERROR: Cannot write lib/HTML/Bricks/Config.pm. Check directory permissions and rerun.\n";

    my $conf = sprintf($confFile, @c{ qw(
      www_user 
      www_group 
      bricks_root 
      document_root 
      mason_data_root 
      admin_user_name
      encrypted_admin_password)});

    print F $conf;
    print "\nWriting lib/HTML/Bricks/Config.pm.\n";
    close(F);

    print "\nYour settings are:\n";
    print join("\n",grep(/=>/,split("\n",$conf)))."\n\n";
    print $successMsg,"-"x20,"\n";

    return \%c;
}

1;
