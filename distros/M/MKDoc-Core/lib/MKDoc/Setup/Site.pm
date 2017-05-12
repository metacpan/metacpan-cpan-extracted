=head1 NAME

MKDoc::Setup::Site - Installs a new MKDoc site somewhere on the system


=head1 SYNOPSIS

  perl -MMKDoc::Setup -e install_site /var/www/example.com


=head1 SUMMARY

L<MKDoc::Core> is an application framework which aims at supporting easy-ish
installation of multiple products onto multiple virtual hosts / websites.

Once you have installed the MKDoc master directory using L<MKDoc::Setup::Core>,
you can add additional sites using this setup module.


=head1 PRE-REQUISITES

First, you need to make sure that you have deployed the L<MKDoc::Core> master
repository using L<MKDoc::Setup::Core>.

Then, you need a domain name which points to the IP address of the machine on
which you are setting up the new site. If you have no domain name, you can add
one temporarily in your /etc/hosts file.

Finally, you need to choose a directory in which your L<MKDoc::Core> site is
going to live.

For the sake of the example, we'll assume that we are using a domain called
'www.example.com' which will live in /var/www/example.com.

Note that you do not need to be root to install a new site. It would be best if
you created /var/www/example.com as root and then changed the ownership to an
unprivileged user.


=head1 SETTING UP

First there is a file in your mkdoc-core directory called 'mksetenv.sh'. You
need to source this file.

  source /usr/local/mkdoc-core/mksetenv.sh

Then run the following command:

  perl -MMKDoc::Setup -e install_site /var/www/example.com

You should see the following screen:

  1. MKDoc Directory        /usr/local/mkdoc
  2. Site Directory         /var/www/mkdoc/example.com
  3. Server Name            www.example.com
  4. Log Directory          /var/www/mkdoc/example.com/log
  5. Domain Admin Email     tech@example.com

  D. Delete an option

  I. Install with the options above
  C. Cancel installation

  Input your choice:

Make sure that everything's OK and press 'i' to install the site.

Restart Apache:

  /usr/local/apache/bin/apachectl restart

Point your web browser to http://www.example.com/. If you see a page
which says 'it worked!' then congratulations, you have installed a
minimal L<MKDoc::Core> site.

If you so wish, you can now install more interesting modules such as
L<MKDoc::Auth> or L<MKDoc::Forum>.

=cut
package MKDoc::Setup::Site;
use strict;
use warnings;
use File::Spec;
use File::Touch;
use base qw /MKDoc::Setup/;


sub main::install_site
{
    $::SITE_DIR = shift (@ARGV);
    __PACKAGE__->new()->process();
}


sub keys  { qw /MKDOC_DIR SITE_DIR SERVER_NAME LOG_DIR ADMIN/ }


sub label
{
    my $self = shift;
    $_ = shift;
    /SERVER_NAME/ and return "Server Name";
    /ADMIN/       and return "Domain Admin Email";
    /MKDOC_DIR/   and return "MKDoc Directory";
    /SITE_DIR/    and return "Site Directory";
    /LOG_DIR/     and return "Log Directory";
    return;
}


sub initialize
{
    my $self = shift;

    my $MKDOC_DIR = $ENV{MKDOC_DIR} || '/usr/local/mkdoc';
    my $SITE_DIR  = File::Spec->rel2abs ( $::SITE_DIR || $ENV{SITE_DIR} || '.' );

    $MKDOC_DIR    =~ s/\/$//;
    $SITE_DIR     =~ s/\/$//;

    my $name = $SITE_DIR;
    $name    =~ s/^.*\///;
    $name    =~ s/^www\.//;

    my $SERVER_NAME = "www.$name";

    $self->{MKDOC_DIR}   = $MKDOC_DIR;
    $self->{SITE_DIR}    = $SITE_DIR;
    $self->{SERVER_NAME} = $SERVER_NAME;
    $self->{ADMIN}       = "tech\@$name";
    $self->{LOG_DIR}     = $ENV{LOG_SDIR} || $ENV{LOG_PREFIX} || "$SITE_DIR/log";
}


sub validate
{
    my $self = shift;

    $self->validate_mkdoc_dir()   &
    $self->validate_site_dir()    &
    $self->validate_server_name() &
    $self->validate_admin()       &
    $self->validate_log_dir();
}


sub validate_mkdoc_dir
{
    my $self = shift;
    my $MKDOC_DIR = $self->{MKDOC_DIR};

    $MKDOC_DIR || do {
        print $self->label ('MKDOC_DIR') . " cannot be undefined\n";
        return 0;
    };

    -e "$MKDOC_DIR/conf/httpd.conf" && -f "$MKDOC_DIR/conf/httpd.conf" || do {
        print <<EOF;
$MKDOC_DIR/conf/httpd.conf does not seem to exist.
It seems that the MKDoc directory you specified is incorrect.
EOF

        return 0;
    };

    return 1;
}


sub validate_site_dir
{
    my $self = shift;
    my $SITE_DIR = $self->{SITE_DIR};

    $SITE_DIR || do {
        print $self->label ('SITE_DIR') . " cannot be undefined\n";
        return 0;
    };

    return 1;
}


sub validate_server_name
{
    my $self = shift;
    my $SERVER_NAME = $self->{SERVER_NAME};

    $SERVER_NAME || do {
        print $self->label ('SERVER_NAME') . " cannot be undefined\n";
        return 0;
    };

    return 1;
}


sub validate_admin
{
    my $self = shift;
    my $ADMIN = $self->{ADMIN};

    $ADMIN || do {
        print $self->label ('ADMIN') . " cannot be undefined\n";
        return 0;
    };

    return 1;
}


sub validate_log_dir
{
    my $self = shift;
    my $LOG_DIR = $self->{LOG_DIR};

    $LOG_DIR || do {
        print $self->label ('LOG_DIR') . " cannot be undefined\n";
        return 0;
    };

    return 1;
}


sub install
{
    my $self = shift;
    $self->install_directories();
    $self->install_mksetenv();
    $self->install_httpd_conf();
    $self->install_httpd2_conf();
    $self->install_plugins();
    $self->install_register_site();
    $self->install_register2_site();
    exit (0);
}


sub install_directories
{
    print "Installing directories... ";
    my $self     = shift;
    my $SITE_DIR = $self->{SITE_DIR};
    my $LOG_DIR  = $self->{LOG_DIR};

    -d $SITE_DIR          or mkdir $SITE_DIR          or die "Cannot create $SITE_DIR";
    -d "$SITE_DIR/httpd"  or mkdir "$SITE_DIR/httpd"  or die "Cannot create $SITE_DIR/httpd";
    -d "$SITE_DIR/httpd2" or mkdir "$SITE_DIR/httpd2" or die "Cannot create $SITE_DIR/httpd2";
    -d "$SITE_DIR/init"   or mkdir "$SITE_DIR/init"   or die "Cannot create $SITE_DIR/init";
    -d "$SITE_DIR/plugin" or mkdir "$SITE_DIR/plugin" or die "Cannot create $SITE_DIR/plugin";
    -d "$SITE_DIR/cache"  or mkdir "$SITE_DIR/cache"  or die "Cannot create $SITE_DIR/plugin";
    -d $LOG_DIR           or mkdir $LOG_DIR           or die "Cannot create $LOG_DIR";

    chmod 0755, $SITE_DIR;
    chmod 0755, "$SITE_DIR/httpd";
    chmod 0755, "$SITE_DIR/httpd2";
    chmod 0755, $LOG_DIR;
    chmod 0777, "$SITE_DIR/cache";
    print "OK\n";
}


sub install_mksetenv
{
    print "Creating mksetenv.sh... ";
    my $self = shift;
    my $MKDOC_DIR   = $self->{MKDOC_DIR};
    my $SITE_DIR    = $self->{SITE_DIR};
    my $ADMIN       = $self->{ADMIN};
    my $SERVER_NAME = $self->{SERVER_NAME};

    open FP, ">$SITE_DIR/mksetenv.sh" or do {
        warn "Cannot open-write $SITE_DIR/mksetenv.sh - skipping";
        no warnings;
        close FP;
        return;
    };

    print FP <<EOF;
source $MKDOC_DIR/mksetenv.sh
export SITE_DIR="$SITE_DIR"
export SERVER_ADMIN="$ADMIN"
export SERVER_NAME="$SERVER_NAME"
EOF

    close FP;
    chmod 0644, "$SITE_DIR/mksetenv.sh";
    print "OK\n";
}


sub install_httpd_conf
{
    print "Installing httpd.conf files... ";
    my $self = shift;
    my $SITE_DIR = $self->{SITE_DIR};

    # base httpd.conf file, for backwards compatibility
    open FP, ">$SITE_DIR/httpd.conf";
    print FP "Include $SITE_DIR/httpd/httpd.conf\n";
    close FP;

    my $to_dir = "$SITE_DIR/httpd";
    for (@INC)
    {
        my $from_dir = "$_/MKDoc/Core/Site/httpd_conf";
        -d $from_dir || next;

        opendir DD, $from_dir or die "Cannot read-open $from_dir. Reason: $!";
        my @files = grep /\.conf$/, readdir (DD);
        close DD;

        for (@files) { $self->install_httpd_conf_file ("$from_dir/$_", "$to_dir/$_") }
        last;
    }

    print "OK\n";
}


sub install_httpd2_conf
{
    print "Installing httpd2.conf files... ";
    my $self = shift;
    my $SITE_DIR = $self->{SITE_DIR};

    my $to_dir = "$SITE_DIR/httpd2";
    for (@INC)
    {
        my $from_dir = "$_/MKDoc/Core/Site/httpd2_conf";
        -d $from_dir || next;

        opendir DD, $from_dir or die "Cannot read-open $from_dir. Reason: $!";
        my @files = grep /\.conf$/, readdir (DD);
        close DD;

        for (@files) { $self->install_httpd_conf_file ("$from_dir/$_", "$to_dir/$_") }
        last;
    }

    print "OK\n";
}


sub install_httpd_conf_file
{
    my $self   = shift;
    my $source = shift;
    my $target = shift;

    my $MKDOC_DIR   = $self->{MKDOC_DIR};
    my $SITE_DIR    = $self->{SITE_DIR};
    my $LOG_DIR     = $self->{LOG_DIR};
    my $SERVER_NAME = $self->{SERVER_NAME};
    my $ADMIN       = $self->{ADMIN};

    open  FP, "<$source" or die "Cannot open-read $source. Reason: $!";
    my $data = join '', <FP>;
    close FP;

    $data = eval "<<EOF;
$data
EOF
" || '';
    warn $@ if ($@);

    open  FP, ">$target" or die "Cannot open-write $target. Reason: $!";
    print FP $data;
    close FP;

    chmod 0644, $target;
}


sub install_plugins
{
    print "Deploying plugins... ";
    my $self = shift;
    my $SITE_DIR = $self->{SITE_DIR};

    # framework initialization
    touch ("$SITE_DIR/init/10000_MKDoc::Core::Init::Petal");

    # plugins
    touch ("$SITE_DIR/plugin/20000_MKDoc::Core::Plugin::Resources");
    touch ("$SITE_DIR/plugin/85000_MKDoc::Core::Plugin::It_Worked");
    touch ("$SITE_DIR/plugin/90000_MKDoc::Core::Plugin::Not_Found");
    print "OK\n";
}


sub install_register_site
{
    print "Registering site with Apache 1 config... ";
    my $self = shift;

    my $MKDOC_DIR = $self->{MKDOC_DIR};
    my $SITE_DIR  = $self->{SITE_DIR};

    my %pathes = ();
    my $http_conf_file = File::Spec->canonpath ($MKDOC_DIR . '/conf/httpd.conf');

    if (-e $http_conf_file)
    {
        open FP, "<$http_conf_file" || die "Cannot read-open $http_conf_file: Reason $@";
        %pathes = map { chomp(); $_ => 1 } <FP>;
        close FP;
    }

    $pathes{"Include $SITE_DIR/httpd.conf"} = 1;
    open FP, ">$http_conf_file" or die "Cannot write-open $http_conf_file. Reason: $!";
    {
        no warnings;
        print FP join "\n", sort keys %pathes;
    }
    print FP "\n";
    close FP;

    print "OK\n";
}


sub install_register2_site
{
    print "Registering site with Apache 2 config... ";
    my $self = shift;

    my $MKDOC_DIR = $self->{MKDOC_DIR};
    my $SITE_DIR  = $self->{SITE_DIR};

    my %pathes = ();
    my $http_conf_file = File::Spec->canonpath ($MKDOC_DIR . '/conf/httpd2.conf');

    if (-e $http_conf_file)
    {
        open FP, "<$http_conf_file" || die "Cannot read-open $http_conf_file: Reason $@";
        %pathes = map { chomp(); $_ => 1 } <FP>;
        close FP;
    }

    $pathes{"Include $SITE_DIR/httpd2/httpd.conf"} = 1;
    open FP, ">$http_conf_file" or die "Cannot write-open $http_conf_file. Reason: $!";
    {
        no warnings;
        print FP join "\n", sort keys %pathes;
    }
    print FP "\n";
    close FP;

    print "OK\n";
}


1;


__END__
